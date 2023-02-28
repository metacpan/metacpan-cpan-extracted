package BoardStreams::Client::Stream;

use Mojo::Base 'Mojo::EventEmitter', -signatures, -async_await;

use BoardStreams::Client::StructDiff 'patch_state';
use BoardStreams::Util 'eqq';

use RxPerl::Mojo ':all';
use Storable 'dclone';

our $VERSION = "v0.0.36";

has name => sub { die 'missing name' };
has manager => sub { die 'missing manager' };

has 'initial_states_o';
has 'events_patches_o';
has 'events_with_ids_o';
has 'events_o';
has 'state' => undef;
has 'state_o';

sub new ($class, $name, $manager) {
    my $self = $class->SUPER::new(
        name    => $name,
        manager => $manager,
    );

    $self->{last_id} = undef;

    $self->{desired_join_state_o} = rx_behavior_subject->new(0); # user's stated wishes (defined)
    $self->{join_state_o} = rx_behavior_subject->new(0); # joined || leaving
    $self->{future_state_o} = rx_behavior_subject->new(0); # joining || joined

    # derived
    $self->{stabilized_join_state_1} = rx_behavior_subject->new(0);
    $self->{stabilized_join_state_2} = rx_behavior_subject->new(0);

    $self->{EPSs_o} = rx_subject->new; # stream of event patches and states
    $self->initial_states_o(
        $self->{EPSs_o}->pipe(
            op_filter(sub { $_->{type} eq 'state' }),
            op_map(sub { $_->{data} }),
            op_share(),
        )
    );
    $self->events_patches_o(
        $self->{EPSs_o}->pipe(
            op_filter(sub { $_->{type} eq 'eventPatch' }),
            op_map(sub {
                +{
                    id => $_->{id},
                    exists($_->{event}) ? (event => $_->{event}) : (),
                    exists($_->{patch}) ? (patch => $_->{patch}) : (),
                };
            }),
            op_share(),
        )
    );
    $self->events_with_ids_o(
        $self->events_patches_o->pipe(
            op_filter(sub { defined $_->{event} }),
            op_map(sub {
                +{ $_->%{qw/ id event /} };
            }),
        )
    );
    $self->events_o(
        $self->events_with_ids_o->pipe(
            op_map(sub { $_->{event} }),
        )
    );
    $self->state_o(rx_replay_subject->new(1));

    # set stream's state on every state & eventPatch message
    # useful because the type of state might change, and because
    # of initial_states_o

    # TODO: all these need to be destroyed, because we will have circular references (memory leak)
    $self->state_o->subscribe(sub ($s) { $self->state($s) });
    $self->state_o->subscribe(sub ($state) { $self->emit('state', $state) });
    $self->events_patches_o->subscribe(sub ($event_patch) { $self->emit('event_patch', $event_patch) });
    $self->events_with_ids_o->subscribe(sub ($event_with_id) { $self->emit('event_with_id', $event_with_id) });
    $self->events_o->subscribe(sub ($event) { $self->emit('event', $event) });
    $self->initial_states_o->subscribe(sub ($i_state) { $self->emit('initial_state', $i_state) });

    # send join or leave request (returns state and past events)
    my sub send_join_or_leave ($desired_join_state) {
        $manager->do_request(
            '!open',
            $desired_join_state ? 'join' : 'leave',
            $desired_join_state ? {
                name    => $name,
                last_id => $self->{last_id},
            } : $name,
        );
    }

    my $ep_repository = [];

    # these subscriptions will be unsubscribed from on channel destruction
    $self->{subscriptions_to_destroy} = [

        # keep state and state_o up to date
        rx_merge(
            $self->initial_states_o->pipe(
                op_map(sub { [$_, undef] }),
            ),

            $self->events_patches_o->pipe(
                op_filter(sub { exists $_->{patch} }),
                op_map(sub { [undef, $_->{patch}] }),
            ),
        )->pipe(
            op_scan(sub ($acc, $init_and_diff, @) {
                my ($initial_state, $diff) = @$init_and_diff;

                if (defined $initial_state) { return $initial_state; }
                return dclone([patch_state($acc, $diff)])->[0];
            }, undef),
            op_tap(sub ($x) { $self->state($x) }),
        )->subscribe($self->state_o),

        # on disconnect, set not-joined (left)
        $manager->connected_o->pipe(
            op_filter(sub { ! $_ }),
        )->subscribe(sub {
            $self->{future_state_o}->next(0);
            $self->{join_state_o}->next(0);
        }),

        # fill ep_repository if we must with incoming event-patches
        $manager->{incoming_o}->pipe(
            op_filter(sub ($msg, @) {
                eqq($msg->{stream}, $name) and eqq($msg->{type}, 'eventPatch');
            }),
            op_map(sub { dclone($_) }),
        )->subscribe(sub ($ep) {
            delete $ep->{stream};
            if ($ep_repository) {
                push @$ep_repository, $ep;
            } elsif ($self->{join_state_o}) {
                if ($ep->{id} > $self->{last_id}) {
                    $self->{EPSs_o}->next($ep);
                    $self->{last_id} = $ep->{id};
                }
            }
        }),

        # set or remove ep_repository
        $self->{join_state_o}->pipe(
            op_combine_latest_with($self->{future_state_o}),
            op_filter(sub {
                my ($present) = @$_;
                return ! $present;
            }),
        )->subscribe(sub ($pair) {
            my (undef, $future) = @$pair;
            if ($future) { $ep_repository //= [] }
            else { $ep_repository = undef }
        }),

        # set stabilized join states
        $self->{join_state_o}->pipe(
            op_combine_latest_with($self->{future_state_o}),
            op_map(sub {
                my ($present, $future) = @$_;
                return $present == $future ? $present : undef;
            }),
            op_switch_map(sub ($x, @) {
                if (! defined $x) {
                    return rx_of(undef);
                } else {
                    return rx_of($x)->pipe(
                        op_delay(0.1),
                    );
                }
            }),
            op_distinct_until_changed(),
        )->subscribe($self->{stabilized_join_state_1}),

        $self->{join_state_o}->pipe(
            op_combine_latest_with(
                $self->{future_state_o},
                $manager->connected_o,
                $self->{desired_join_state_o},
            ),
            op_switch_map(sub ($quad, @) {
                my ($present, $future, $connected, $desired) = @$quad;
                return $desired ? rx_of(undef) : rx_of(0)->pipe(op_delay(0.1)) if ! $connected;
                return $present == $future ? rx_of($present)->pipe(op_delay(0.1)) : rx_of(undef);
            }),
            op_distinct_until_changed(),
        )->subscribe($self->{stabilized_join_state_2}),

        # send join or leave requests at the right times, and process results
        $self->{desired_join_state_o}->pipe(
            op_combine_latest_with($manager->connected_o),
            op_concat_map(sub ($pair, @) {
                my ($desired, $connected) = @$pair;

                $connected or return rx_EMPTY;
                $desired == $self->{desired_join_state_o}->get_value or return rx_EMPTY;
                $desired != $self->{future_state_o}->get_value or return rx_EMPTY;
                $self->{future_state_o}->next($desired);

                return rx_from(
                    send_join_or_leave($desired)->then(
                        sub ($state_and_past_events) {
                            +{
                                ok                    => 1,
                                desired               => $desired,
                                state_and_past_events => $state_and_past_events,
                            };
                        },
                        sub {
                            +{
                                ok      => 0,
                                desired => $desired,
                            };
                        },
                    )
                );
            }),
        )->subscribe(sub ($obj) {
            my ($ok, $desired, $state_and_past_events) = $obj->@{qw/ ok desired state_and_past_events /};
            if ($ok) {
                if ($desired) {
                    # push to EPSs_o and set join_state
                    my ($events, $state_obj) = $state_and_past_events->@{qw/ events state /};
                    my ($state, $state_id) = $state_obj->@{qw/ data id /};

                    $state_id >= ($self->{last_id} // 0) or die 'state.id < self.last_id';
                    foreach my $pair (@$events) {
                        my ($event, $event_id) = $pair->@{qw/ event id /};
                        $event_id > ($self->{last_id} // 0) or return;
                        $self->{EPSs_o}->next({
                            type  => 'eventPatch',
                            id    => $event_id,
                            event => $event,
                        });
                    }

                    $self->{EPSs_o}->next({
                        type => 'state',
                        id   => $state_id,
                        data => $state,
                    });

                    $self->{last_id} = $state_id;

                    foreach my $ep (@$ep_repository) {
                        if ($ep->{id} > $self->{last_id}) {
                            $self->{EPSs_o}->next($ep);
                            $self->{last_id} = $ep->{id};
                        }
                    }

                    undef $ep_repository;
                }
                $self->{join_state_o}->next($desired);
            } else {
                $self->{future_state_o}->next($self->{join_state_o}->get_value);
            }
        }),
    ];

    return $self;
}

async sub destroy ($self) {
    $self->{desired_join_state_o}->next(0);
    await first_value_from(
        $self->{stabilized_join_state_1}->pipe(
            op_filter(sub { eqq($_, 0) }),
        )
    );
    $_->unsubscribe foreach $self->{subscriptions_to_destroy}->@*;
    $_->complete foreach (
        $self->@{qw/
            desired_join_state_o join_state_o future_state_o
            stabilized_join_state_1 stabilized_join_state_2
            EPSs_o
        /},
        $self->state_o,
    );
}

async sub join_or_leave ($self, $value) {
    $self->{desired_join_state_o}->next($value);
    my $eventual_state = await first_value_from(
        $self->{'stabilized_join_state_' . ($value ? 2 : 1)}->pipe(
            op_filter(sub { defined $_ }),
        )
    );
    if ($eventual_state == $value) { return }
    my $verb = $value ? 'join' : 'leave';
    if ($self->{desired_join_state_o}->get_value != $value) {
        die "$verb cancelled";
    }
    die "Couldn't $verb";
}

sub join ($self) {
    $self->join_or_leave(1);
}

sub leave ($self) {
    $self->join_or_leave(0);
}

async sub do_action ($self, $action_name, $payload = undef, $opts = {}) {
    my $wait_for_join = $opts->{wait_for_join};
    my $stabilized_state = await first_value_from(
        $self->{'stabilized_join_state_' . ($wait_for_join ? 2 : 1)}->pipe(
            op_filter(sub { defined $_ }),
        )
    );
    $stabilized_state or die "not joined stream, can't do action";

    $self->manager->do_action($self->name, $action_name, $payload);
}

async sub do_request ($self, $request_name, $payload = undef, $opts = {}) {
    my $wait_for_join = $opts->{wait_for_join};
    my $stabilized_state = await first_value_from(
        $self->{'stabilized_join_state_' . ($wait_for_join ? 2 : 1)}->pipe(
            op_filter(sub { defined $_ }),
        )
    );
    $stabilized_state or die "not joined stream, can't do request";

    return $self->manager->do_request($self->name, $request_name, $payload);
}

1;
