package BoardStreams::Client::Manager;

use Mojo::Base 'Mojo::EventEmitter', -signatures;

use BoardStreams::Client::Stream;
use BoardStreams::Client::WebSockets 'make_websockets_observable';
use BoardStreams::Client::Util 'unique_id';
use BoardStreams::Util 'decode_json', 'eqq';

use RxPerl::Mojo ':all';
use Mojo::UserAgent;

no autovivification;

has url => sub { die 'missing url' };
has ua => sub { Mojo::UserAgent->new };
has 'connected_o';

our $VERSION = "v0.0.31";

sub new ($class, $url) {
    my $self = $class->SUPER::new(url => $url);

    # to send structured data to the webserver, next send$
    $self->{send_o} = rx_subject->new;

    # long incoming messages are divided into chunks
    my $ongoing_messages = {};

    # by setting pleaseBeConnected$, one initiates
    # WS connection attempts
    $self->{please_be_connected} = rx_subject->new;
    my $websocket_o = $self->{please_be_connected}->pipe(
        op_switch_map(sub ($be_connected) {
            if ($be_connected) {
                return make_websockets_observable($self->url, $self);
            }
            return rx_of(undef);
        }),
        op_distinct_until_changed(),
        op_tap(sub { $ongoing_messages = {} }),
        op_share(),
    );

    # connect send_o to the latest websocket
    $self->{send_o}->pipe(
        op_with_latest_from($websocket_o),
    )->subscribe(sub ($data_ws) {
        my ($data, $ws) = @$data_ws;
        $ws or die 'Attempted to send data while not connected';
        $ws->send({ json => $data });
    });

    # read incoming messages
    $self->{incoming_o} = rx_subject->new;
    $websocket_o->pipe(
        op_filter(sub { defined $_ }),
        op_switch_map(sub ($ws) { rx_from_event($ws, 'binary') }),
        op_switch_map(sub ($binary_part) {
            if (my ($bytes_prefix, $remaining) = $binary_part =~ /^\:(.+?)\:\ (.*)\z/) {
                my ($identifier, $i, $is_final) = $bytes_prefix =~ /^(\S+)\ ([0-9]+)(\$)?\z/;

                if ($i == 0) {
                    $ongoing_messages->{$identifier} = {
                        i     => 0,
                        bytes => $remaining,
                    };
                } else {
                    if ($i == ($ongoing_messages->{$identifier}{i} // -2) + 1) {
                        delete $ongoing_messages->{$identifier};
                    }

                    if (my $ong = $ongoing_messages->{$identifier}) {
                        $ong->{i} = $i;
                        substr($ong->{bytes}, length($ong->{bytes}), 0) = $remaining;
                    }
                }

                if ($is_final and $i == ($ongoing_messages->{$identifier}{i} // -1)) {
                    my $data = decode_json $ongoing_messages->{$identifier}{bytes};
                    delete $ongoing_messages->{$identifier};
                    return rx_of($data);
                }

                return rx_EMPTY;
            }

            # if message is not a part
            return rx_of(decode_json $binary_part);
        }),
    )->subscribe($self->{incoming_o});

    # incoming JSON-RPC responses
    $self->{responses_o} = $self->{incoming_o}->pipe(
        op_filter(sub {
            eqq($_->{jsonrpc}, '2.0')
                and (exists $_->{result} or exists $_->{error})
        }),
        op_share(),
    );

    my $config_o = $self->{incoming_o}->pipe(
        op_filter(sub { eqq $_->{type}, 'config' }),
        op_map(sub { $_->{data} }),
        op_share(),
    );

    # create connected_o to show websocket connection status (after config is received)
    $self->connected_o( rx_behavior_subject->new(0) );
    rx_merge(
        $config_o->pipe(
            op_map_to(1),
        ),
        $websocket_o->pipe(
            op_filter(sub { ! $_ }),
            op_map_to(0),
        ),
    )->pipe(
        op_distinct_until_changed(),
    )->subscribe($self->connected_o);
    $self->connected_o->subscribe(sub ($status) { $self->emit('connected', $status) });

    # ping
    $config_o->pipe(
        op_map(sub ($config, @) { $config->{pingInterval} - rand() }),
        op_switch_map(sub ($iv) {
            rx_timer($iv * rand(), $iv)->pipe(
                op_take_until($self->connected_o->pipe(op_filter(sub { ! $_ }))),
            ),
        }),
    )->subscribe(sub { $self->send({ type => 'ping' }) });

    # timeout
    $config_o->pipe(
        op_switch_map(sub ($config) {
            $self->{incoming_o}->pipe(
                op_start_with(undef),
                op_switch_map(sub {
                    rx_of(1)->pipe(
                        op_delay($config->{pingInterval} + 10),
                        op_take_until(
                            $self->connected_o->pipe(op_filter(sub { !$_ }))
                        ),
                    );
                }),
            );
        }),
        op_with_latest_from($websocket_o),
    )->subscribe(sub ($conf_ws) {
        my (undef, $ws) = @$conf_ws;
        $ws && $ws->finish; # TODO: or maybe some other way to close (?)
    });

    return $self;
}

sub connect ($self) {
    $self->{please_be_connected}->next(1);
}

sub disconnect ($self) {
    $self->{please_be_connected}->next(0);
}

sub send ($self, $data) {
    $self->connected_o->get_value or eqq($data->{type}, 'ping')
        or die "Can't send data because websocket not available";

    $self->{send_o}->next($data);
}

sub do_action ($self, $stream_name, $action_name, $payload = undef) {
    $self->send({
        jsonrpc => '2.0',
        method  => 'doAction',
        params  => [$stream_name, $action_name, $payload],
    });
}

sub do_request ($self, $stream_name, $request_name, $payload = undef) {
    my $id = unique_id;

    $self->send({
        jsonrpc => '2.0',
        method  => 'doRequest',
        params  => [ $stream_name, $request_name, $payload ],
        id      => $id,
    });

    return first_value_from(
        $self->{responses_o}->pipe(
            op_filter(sub { eqq($_->{jsonrpc}, '2.0') and $_->{id} eq $id }),
            op_take_until($self->connected_o->pipe(op_filter(sub { ! $_ }))),
            op_switch_map(sub ($data) {
                if (exists $data->{result}) { return rx_of($data->{result}) }
                return rx_throw_error($data->{error});
            }),
        ),
    );
}

sub new_stream ($self, $stream_name) {
    return BoardStreams::Client::Stream->new($stream_name, $self);
}

1;
