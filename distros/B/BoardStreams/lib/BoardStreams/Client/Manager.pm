package BoardStreams::Client::Manager;

use Mojo::Base 'Mojo::EventEmitter', -signatures;

use BoardStreams::Client::WebSocket 'make_websocket_observable';
use BoardStreams::Client::Channel;
use BoardStreams::Client::StructDiff 'patch_state';

use Mojo::JSON 'decode_json', 'encode_json';
use RxPerl::Mojo ':all';
use Data::Dump 'dump';
use List::Util 'min';
use Carp 'croak';

our $VERSION = "v0.0.23";

has 'url';
has 'connection_status_o';

my @WAIT_TIMES = (1, 1, 3, 5);

sub new ($class, $url) {
    my $self = $class->SUPER::new(url => $url);

    $self->{wses} = rx_behavior_subject->new(undef);
    $self->connection_status_o(
        $self->{wses}->pipe(
            op_map(sub { !!$_[0] }),
            op_distinct_until_changed(),
        )
    );
    $self->connection_status_o->subscribe(sub ($value) {
        $self->emit('connection_status', $value);
    });

    my $wait_times_cursor = 0;

    rx_defer(sub {
        $wait_times_cursor = min($wait_times_cursor, $#WAIT_TIMES);
        my $wait_time = $WAIT_TIMES[$wait_times_cursor];
        $wait_times_cursor++;
        say "Waiting for ${wait_time}ms";

        return rx_concat(
            rx_EMPTY->pipe(op_delay($wait_time)),
            make_websocket_observable($self->url),
            rx_of(undef),
        )->pipe(
            op_tap(sub ($x) {
                if ($x) {
                    $wait_times_cursor = 0;
                }
            }),
        );
    })->pipe(
        op_repeat(),
        op_distinct_until_changed(),
    )->subscribe(sub { $self->{wses}->next($_[0]) });

    # set & keep updated $self->{ws}
    $self->{ws} = undef;

    my %ongoing_messages;
    my $msgs_from_ws_o = $self->{wses}->pipe(
        op_switch_map(sub ($x) {
            $self->{ws} = $x;
            undef %ongoing_messages;
            return rx_EMPTY if ! $x;
            return rx_from_event($self->{ws}, 'binary');
        }),
        op_switch_map(sub ($bytes) {
            $bytes =~ s/^\:([^:]+)\: //s;
            if (defined(my $bytes_prefix = $1)) {
                my ($identifier, $i) = $bytes_prefix =~ /^(.*)\s(\S+)\z/;
                if ($i eq '0') {
                    $ongoing_messages{$identifier} = $bytes;
                } elsif ($i =~ /^\d+\z/) {
                    $ongoing_messages{$identifier} .= $bytes;
                } elsif ($i eq 'end') {
                    $ongoing_messages{$identifier} .= $bytes;
                    my $data = decode_json(delete $ongoing_messages{$identifier});
                    return rx_of($data);
                }
                return rx_EMPTY;
            }
            my $data = decode_json($bytes);
            return rx_of($data);
        }),
        op_share(),
    );

    $msgs_from_ws_o->pipe(
        op_filter(sub ($data, @) { exists $data->{channel} }),
    )->subscribe(sub ($data) {
        my $channel_name = $data->{channel};
        my $channel_uuid = $data->{channelUUID};
        if (my $channels_set = $self->{channels}{$channel_name}) {
            foreach my $channel (values %$channels_set) {
                next unless !$channel_uuid or $channel->{uuid} eq $channel_uuid;
                $channel->{messages_o}->next($data);
            }
        }
    });

    $msgs_from_ws_o->pipe(
        op_filter(sub ($data, @) { ($data->{type} // '') eq 'configuration' }),
        op_switch_map(sub ($config) {
            my $ping_interval = $config->{pingInterval};
            return rx_timer(rand($ping_interval), $ping_interval)->pipe(
                op_take_until(
                    $self->{wses}->pipe( op_filter(sub ($ws, @) { ! $ws }) )
                ),
            );
        }),
    )->subscribe(sub { $self->send({type => 'ping'}) });

    $self->{channels} = {};

    return $self;
}

sub send ($self, $msg) {
    if ($self->{ws}) {
        $self->{ws}->send({ binary => encode_json $msg });
        # debug
        say "output: ", dump $msg if $ENV{BS_DEBUG};
    } else {
        croak "no websocket connection to send through";
    }
}

sub send_leave ($self, $channel_name) {
    $self->send({
        type    => 'leave',
        channel => $channel_name,
    }) unless ! $self->{ws};
}

sub join_channel ($self, $channel_name) {
    $self->{channels}{$channel_name} //= {};
    my $messages_to_server_o = rx_subject->new;
    $messages_to_server_o->subscribe(sub ($msg) {
        $self->send($msg);
    });
    my $channel =
        BoardStreams::Client::Channel->new($channel_name, $self, $messages_to_server_o);
    $self->{channels}{$channel_name}{$channel} = $channel;

    return $channel;
}

sub remove_channel_from_memory ($self, $channel) {
    my $channel_name = $channel->name;
    my $set = $self->{channels}{$channel_name};
    return unless $set;
    my $existed = delete $set->{$channel};
    if ($existed and ! %$set) {
        $self->send_leave($channel_name);
        delete $self->{channels}{$channel_name};
    }
}

1;
