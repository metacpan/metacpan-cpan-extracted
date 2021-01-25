package Mojolicious::Plugin::BoardStreams;

use Mojo::Base 'Mojolicious::Plugin', -signatures, -async_await;

use BoardStreams::Registry;
use BoardStreams::ListenerObservable 'get_listener_observable';
use BoardStreams::Exception 'db_duplicate_error';
use BoardStreams::Util 'string', ':bool';

use Mojo::Pg;
use Mojo::JSON 'to_json', 'from_json', 'encode_json';
use Mojo::WebSocket 'WS_PING';
use Mojo::IOLoop;
use RxPerl::Mojo ':all';
use Crypt::PRNG 'rand';
use Safe::Isa;
use Syntax::Keyword::Try;
use Struct::Diff 'diff';
use Time::HiRes ();
use Storable 'dclone';

use experimental 'postderef';

sub register ($self, $app, $config) {
    # Database stuff
    my $db_string = $config->{'db_string'} or die "missing db_string configuration option";
    my $pg = Mojo::Pg->new($db_string);
    $app->helper('bs.db' => sub { $pg->db });
    $app->helper('bs.pubsub' => sub { $pg->pubsub });
    $app->helper('bs.pubsub_db' => sub { $pg->pubsub->db });

    my $pubsub_connected_o = rx_behavior_subject->new(false);
    my $pubsub_connected;

    Mojo::IOLoop->next_tick(sub {
        $pubsub_connected_o->subscribe(sub {
            $pubsub_connected = $_[0];
        });
        rx_from_event($pg->pubsub, 'reconnect')->subscribe(sub {
            $pubsub_connected_o->next(1);
        });
        rx_from_event($pg->pubsub, 'disconnect')->subscribe(sub {
            $pubsub_connected_o->next(0);
        });

        # close worker gracefully, if...
        rx_merge(
            # ...ever disconnect from pubsub
            $pubsub_connected_o->pipe(
                op_pairwise,
                op_filter(sub {
                    my ($prev, $curr) = $_[0]->@*;
                    return $prev && !$curr;
                }),
                op_delay(1),
            ),

            # ...or if haven't connected to pubsub in first three seconds
            rx_timer(3)->pipe(
                op_take_until(
                    $pubsub_connected_o->pipe(op_filter(sub {$_[0]}))
                ),
            ),
        )->subscribe(sub { Mojo::IOLoop->stop_gracefully });

        # detect disconnects by opening a permanent dummy listen
        $pg->pubsub->listen('!system' => sub ($pubsub, $payload) {});
    });

    # on graceful stop, boot all clients
    my @boot_emitters;
    Mojo::IOLoop->next_tick(sub {
        for my $i (1 .. 10) {
            push @boot_emitters, rx_from_event(Mojo::IOLoop->singleton, 'finish')->pipe(
                op_delay(2 * $i / 10),
            );
        }
    });

    $app->helper('bs.add_action', sub ($c, $channel_name, $action_name, $action_sub) {
        BoardStreams::Registry->add_action($channel_name, $action_name, $action_sub);
    });

    $app->helper('bs.add_request', sub ($c, $channel_name, $request_name, $request_sub) {
        BoardStreams::Registry->add_request($channel_name, $request_name, $request_sub);
    });

    $app->helper('bs.create_channel_or_die', sub ($c, $channel_name, $state = undef, $type = '') {
        my $sth;
        try {
            $sth = $app->bs->db->dbh->prepare('INSERT INTO "channel" (name, type, state) VALUES (?, ?, ?)');
            $sth->execute($channel_name, $type, to_json($state));
        } catch {
            my $err = $@;
            # look up 23505 in: https://www.postgresql.org/docs/current/errcodes-appendix.html
            if ($sth->state eq '23505') {
                db_duplicate_error;
            } else {
                die $err;
            }
        }
    });

    $app->helper('bs.create_channel', sub ($c, $channel_name, $state = undef, $type = '') {
        my $sth;
        try {
            my $db = $app->bs->db;
            ! $db->select('channel',
                ['id'],
                { name => $channel_name },
            )->hash or return;
            $sth = $db->dbh->prepare('INSERT INTO "channel" (name, type, state) VALUES (?, ?, ?)');
            $sth->execute($channel_name, $type, to_json($state));
        } catch {
            my $err = $@;
            # look up 23505 in: https://www.postgresql.org/docs/current/errcodes-appendix.html
            die $err unless $sth->state eq '23505';
        }
    });

    $app->helper('bs.lock_state', sub ($c, $channel_name, $sub) {
        my $db = $app->bs->db; # NOTE: Is $app here a circular reference? Does it matter?
        my $tx = $db->begin;
        my ($channel_id, $state) = $db->select('channel',
            [qw/ id state /],
            { name => $channel_name },
            { for => 'update' },
        )->hash->@{qw/ id state /}; # NOTE: is it possible that the row does not exist?
        $state = from_json $state;
        my ($event, $new_state) = $sub->(dclone([$state])->[0]);
        if (! defined $event and ! defined $new_state) { return; }
        my $diff = defined $new_state ? diff($state, $new_state, noO => 1, noU => 1) : undef;
        my ($event_id, $dt) = $db->insert('event_patch',
            {
                channel_id => $channel_id,
                event      => to_json($event),
                patch      => to_json($diff),
                has_event  => int(defined $event),
            },
            { returning => ['id', 'datetime'] },
        )->hash->@{qw/ id datetime /};
        $db->update('channel',
            {
                event_id => $event_id,
                last_dt  => $dt,
                defined $new_state ? (state => to_json $new_state) : (),
            },
            { id => $channel_id },
        );
        $db->notify($channel_name => encode_json {
            id    => int $event_id,
            data  => {
                event => $event,
                patch => $diff,
            },
        });
        $tx->commit;

        return $new_state;
    });

    # ping every 15 seconds
    my $ping_o = rx_defer(sub {
        rx_timer(rand(15), 15);
    })->pipe(
        op_share(),
    );

    $app->helper('bs.on_join', sub ($c, $channel_name, $join_sub) {
        BoardStreams::Registry->add_join($channel_name, $join_sub);
    });

    $app->helper('bs.on_leave', sub ($c, $channel_name, $leave_sub) {
        BoardStreams::Registry->add_leave($channel_name, $leave_sub);
    });

    $app->helper('bs.initialize_client', sub ($self) {
        # reject connection, if pubsub is not active
        return $self->rendered(500) if not $pubsub_connected;

        # ping client at regular intervals, until client disconnects
        $ping_o->pipe(
            op_take_until(
                rx_from_event($self->tx, 'finish'),
            ),
        )->subscribe(sub {
            $self->send([1, 0, 0, 0, WS_PING, 'Hello World!']);
        });

        # leave soon if worker stops gracefully
        $boot_emitters[int rand @boot_emitters]->subscribe(sub {
            $self->finish;
        });

        # trap incoming messages
        $self->on(json => async sub ($c, $hash) {

            # join
            if ($hash->{type} eq 'join') {
                my $channel_name = string $hash->{channel};
                my $channel_uuid = string $hash->{channelUUID};
                my $since_id = $hash->{sinceId};
                $since_id = int $since_id if defined $since_id;

                # join handler
                my $join_handler = BoardStreams::Registry->get_join($channel_name) or return;
                my $attrs = { since_id => $since_id, is_reconnect => defined $since_id };
                my $join_ret = eval { $join_handler->($channel_name, $c, $attrs) };
                if ($join_ret->$_can('then')) {
                    $join_ret = eval { await $join_ret };
                }
                $join_ret or return;
                my $limit = $join_ret->{limit} // 0;

                my $was_added = BoardStreams::Registry->add_pair($c, $channel_name);
                if ($was_added) {
                    my $o = get_listener_observable($c, $channel_name);
                    my $s = $o->subscribe();
                    $c->stash->{subscriptions}{channels}{$channel_name} = $s;
                }

                # NOTE: in the async case in the future, make sure the subscription is still there
                # after the query, before sending state to user

                my $db = $c->bs->db;
                my ($channel_id, $event_id, $state) = $db->select('channel',
                    [qw/ id event_id state /],
                    { name => $channel_name },
                )->hash->@{qw/ id event_id state /};

                # fetch & send most recent events
                if ($event_id and $limit ne '0') {
                    my $latest_event_rows = $db->select('event_patch',
                        [qw/ id event /],
                        {
                            channel_id => $channel_id,
                            has_event  => 1,
                            id         => {
                                '<=', $event_id,
                                # $since_id defaults to 0
                                defined $since_id ? ('>', $since_id) : (),
                            },
                        },
                        {
                            order_by => { -desc => 'id' },
                            $limit eq 'all' ? () : (limit => $limit),
                        },
                    )->hashes->reverse;

                    foreach my $event_row (@$latest_event_rows) {
                        $c->send({json => {
                            type        => 'event_patch',
                            channel     => $channel_name,
                            channelUUID => $channel_uuid,
                            immediate   => true,
                            id          => int $event_row->{id},
                            data        => {
                                event => from_json($event_row->{event}),
                            },
                        }});
                    }
                }

                $c->send({json => {
                    type        => 'state',
                    channel     => $channel_name,
                    channelUUID => $channel_uuid,
                    id          => int $event_id,
                    data        => from_json($state),
                }});
            }

            # leave
            if ($hash->{type} eq 'leave') {
                my $channel_name = string $hash->{channel};
                BoardStreams::Registry->remove_pair($c, $channel_name);
                my $s = delete $c->stash->{subscriptions}{channels}{$channel_name};
                $s->unsubscribe() if defined $s;
                my $leave_sub = BoardStreams::Registry->get_leave($channel_name);
                $leave_sub->($channel_name, $c) if $leave_sub;
            }

            # action
            if ($hash->{type} eq 'action') {
                my $channel_name = string $hash->{channel};
                my ($action_name, $payload) = $hash->{data}->@*;
                my $action_sub = BoardStreams::Registry->get_action($channel_name, $action_name);
                $action_sub->($channel_name, $c, $payload);
            }

            # request
            if ($hash->{type} eq 'request') {
                my $channel_name = string $hash->{channel};
                my ($request_name, $payload) = $hash->{data}->@*;
                my $request_id = string $hash->{requestId};
                my $request_sub = BoardStreams::Registry->get_request($channel_name, $request_name);
                my $t0 = Time::HiRes::time();
                my @return_value;
                my $ok = eval { @return_value = $request_sub->($channel_name, $c, $payload); 1 };
                my $err; $err = $@ if ! $ok;
                my $duration = sprintf("%.1fms", (Time::HiRes::time() - $t0) * 1e3);
                if ($return_value[0]->$_can('then')) {
                    $ok = eval { @return_value = await $return_value[0]; 1 };
                    $err = $@ if !$ok;
                }

                if ($ok) {
                    return if ! @return_value;
                }
                if (! $ok) {
                    $err = "$err" if not eval { to_json $err; 1 };
                }

                if ($ok) {
                    $c->send({json => {
                        type      => 'response',
                        channel   => $channel_name,
                        requestId => $request_id,
                        result    => $return_value[0],
                        duration  => $duration,
                    }});
                } else {
                    $c->send({json => {
                        type      => 'response',
                        channel   => $channel_name,
                        requestId => $request_id,
                        error     => $err,
                        duration  => $duration,
                    }});
                }
            }
        });

        # on finish, leave all channels
        $self->on(finish => sub ($c, @) {
            BoardStreams::Registry->remove_user($c);
            my @channel_names = keys $c->stash->{subscriptions}{channels}->%*;
            foreach my $channel_subscription (values $c->stash->{subscriptions}{channels}->%*) {
                $channel_subscription->unsubscribe();
            }
            delete $c->stash->{subscriptions}{channels};
            foreach my $channel_name (@channel_names) {
                my $leave_sub = BoardStreams::Registry->get_leave($channel_name);
                $leave_sub->($channel_name, $c) if $leave_sub;
            }
        });
    });

    $app->helper('bs.joined', sub ($c, $channel_name) {
        return BoardStreams::Registry->has_pair($c, $channel_name);
    });
}

1;