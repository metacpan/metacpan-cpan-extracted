package BoardStreams::Client::Channel;

use Mojo::Base 'Mojo::EventEmitter', -signatures, -async_await;

use BoardStreams::Client::Utils 'unique_id', 'observable_to_promise';
use BoardStreams::Client::StructDiff 'patch_state';

use RxPerl::Mojo ':all';
use Mojo::IOLoop;
use Data::Dump 'dump';
use Storable 'dclone';
use Scalar::Util 'weaken';

our $VERSION = "v0.0.9";

has 'name';
has 'events_patches_o';
has 'initial_states_o';
has 'state_o';
has 'events_o';

sub new ($class, $name, $manager, $messages_to_server_o) {
    my $self = $class->SUPER::new(
        name => $name,
    );
    weaken($self->{manager} = $manager);
    $self->{uuid} = unique_id();
    $self->{messages_o} = rx_subject->new;
    $self->{messages_to_server_o} = $messages_to_server_o;
    $self->{last_id} = undef;

    # debug
    $self->{messages_o}->subscribe(sub ($msg) {
        say "input: ", dump $msg;
    }) if $ENV{BS_DEBUG};

    # calculated public observables
    $self->events_patches_o( rx_subject->new );
    $self->initial_states_o( rx_subject->new );
    $self->state_o( rx_replay_subject->new(1) );
    $self->events_o( rx_subject->new );

    $self->events_o->subscribe(sub ($event) { $self->emit(event => $event) });
    $self->state_o->subscribe(sub ($state) { $self->emit(state => $state) });
    $self->events_patches_o->subscribe(sub ($event_patch) {
        $self->emit(event_patch => $event_patch);
    });
    $self->initial_states_o->subscribe(sub ($i_state) {
        $self->emit(initial_state => $i_state);
    });

    # events-patches sent during a join
    my @pre_ep;

    my @system_subscriptions;

    # on each disconnect:
    $self->{manager}{wses}->pipe(
        op_filter(sub { ! $_[0] }),
    )->subscribe(sub {
        undef @pre_ep;
        $_->unsubscribe foreach @system_subscriptions;
        undef @system_subscriptions;
    });

    # on each connect, but also if created while WS was connected...
    $self->{manager}{wses}->pipe(
        op_filter(sub { $_[0] }),
    )->subscribe(sub {
        # send JOIN cmd to server
        $self->{messages_to_server_o}->next({
            type        => 'join',
            channel     => $self->name,
            channelUUID => $self->{uuid},
            sinceId     => $self->{last_id},
        });

        # calculated observables
        my $events_patches_o = $self->{messages_o}->pipe(
            op_filter(sub ($msg, @) { $msg->{type} eq 'event_patch' }),
            op_share(),
        );
        my $initial_states_o = $self->{messages_o}->pipe(
            op_filter(sub ($msg, @) { $msg->{type} eq 'state' }),
            op_share(),
        );

        # eventsPatches & states = eps_o
        my $eps_o = rx_merge(
            $events_patches_o->pipe(
                op_filter(sub ($msg, @) { ! $msg->{immediate} }),
                op_tap(sub ($msg) { push @pre_ep, $msg }),
                op_filter(sub { 0 }),
                op_take_until($initial_states_o),
            ),

            $events_patches_o->pipe(
                op_filter(sub ($msg, @) { $msg->{immediate} }),
                op_take_until($initial_states_o),
            ),

            $events_patches_o->pipe(
                op_skip_until($initial_states_o),
                op_filter(sub ($ep_msg, @) { $ep_msg->{id} > $self->{last_id} }),
            ),

            $initial_states_o->pipe(
                op_switch_map(sub ($state_msg) {
                    return rx_concat(
                        rx_of($state_msg),
                        rx_EMPTY->pipe(op_delay(0)),
                        rx_from(
                            [grep { $_->{id} > $state_msg->{id} } @pre_ep]
                        ),
                    );
                }),
            )
        )->pipe(
            op_share(),
        );

        my $s1 = $eps_o->pipe(
            op_filter(sub ($msg, @) { $msg->{type} eq 'state' }),
            op_map(sub ($msg, @) { $msg->{data} }),
        )->subscribe($self->initial_states_o);

        my $s2 = $eps_o->pipe(
            op_filter(sub ($msg, @) { $msg->{type} eq 'event_patch' }),
            op_map(sub ($msg, @) { $msg->{data} }),
        )->subscribe($self->events_patches_o);

        my $s3 = $eps_o->subscribe(sub ($msg) {
            $self->{last_id} = $msg->{id};
        });

        push @system_subscriptions, $s1, $s2, $s3;
    });

    $self->initial_states_o->subscribe(sub ($state) {
        $self->state_o->next($state);
    }); # line 121 on BSChannel.js

    $self->events_patches_o->pipe(
        op_map(sub ($data, @) { $data->{patch} }),
        op_filter(sub ($p, @) { defined $p }),
        op_with_latest_from($self->state_o),
        op_map(sub ($ps, @) {
            my ($p, $s) = @$ps;
            return patch_state(dclone($s), $p);
        }),
    )->subscribe(sub ($state) { $self->state_o->next($state) });

    $self->events_patches_o->pipe(
        op_map(sub ($data, @) { $data->{event} }),
        op_filter(sub ($event, @) { defined $event }),
    )->subscribe(sub ($event) {  $self->events_o->next($event) });

    return $self;
}

sub do_action ($self, $action_name, $payload = undef) {
    my $data = [$action_name];
    if (@_ >= 3) {
        push @$data, $payload;
    }
    $self->{messages_to_server_o}->next({
        type    => 'action',
        channel => $self->name,
        data    => $data,
    });
}

sub leave ($self) {
    $self->{manager}->remove_channel_from_memory($self);

    foreach my $key (qw/ messages_o messages_to_server_o /) {
        $self->{$key}->complete;
    }

    foreach my $prop (qw/ events_patches_o initial_states_o state_o events_o /) {
        $self->$prop->complete;
    }
}

async sub do_request ($self, $request_name, $payload = undef) {
    my $request_id = unique_id();
    my $data = [$request_name];
    if (@_ >= 3) {
        push @$data, $payload;
    }
    $self->{messages_to_server_o}->next({
        type      => 'request',
        channel   => $self->name,
        requestId => $request_id,
        data      => $data,
    });

    my $o = $self->{messages_o}->pipe(
        op_filter(sub ($msg, @) {
            return $msg->{type} eq 'response' && $msg->{requestId} eq $request_id;
        }),
        op_take(1),
    );
    my $response = await observable_to_promise($o);

    return $response->{result} if exists $response->{result};
    die $response->{error} if exists $response->{error};
    die 'missing result or error';
}

1;
