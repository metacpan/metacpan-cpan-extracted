package Mojolicious::Plugin::BoardStreams;

use Mojo::Base 'Mojolicious::Plugin', -signatures, -async_await;

use BoardStreams::Registry;
use BoardStreams::ListenerObservable 'get_listener_observable';
use BoardStreams::Transaction;
use BoardStreams::Exception 'db_duplicate_error';
use BoardStreams::Util 'string', ':bool', 'next_tick_p';
use BoardStreams::DBMigrations;

use Mojo::Pg;
use Mojo::JSON 'to_json', 'from_json', 'encode_json', 'decode_json';
use Mojo::WebSocket 'WS_PING';
use Mojo::IOLoop;
use RxPerl::Mojo ':all';
use Safe::Isa;
use Syntax::Keyword::Try;
use Data::GUID;
use List::AllUtils qw/ max min /;
use Time::HiRes ();
use Sys::Hostname; # exports 'hostname' function
use Carp 'croak';
use Encode 'encode_utf8';

use experimental 'postderef';

our $VERSION = "v0.0.22";

use constant {
    DEFAULT_CLEANUP_INTERVAL          => 5,
    DEFAULT_HEARTBEAT_INTERVAL        => 5,
    DEFAULT_HEARTBEAT_TIMEOUT         => 5,
    DEFAULT_PREFIX                    => 'bs',
    DEFAULT_PING_INTERVAL             => 15,
    DEFAULT_NOTIFY_PAYLOAD_SIZE_LIMIT => 8000,
    MAX_WEBSOCKET_SIZE                => 262_144,
};

my $WORKERS_CHANNEL = '_bs:workers';
my $CLEANUP_CHANNEL = '_bs:cleanup';

sub register ($self, $app, $config) {
    my $worker_uuid = Data::GUID->new->as_base64;

    # config params
    my $cleanup_interval = $config->{cleanup_interval} // DEFAULT_CLEANUP_INTERVAL;
    my $heartbeat_interval = $config->{heartbeat_interval} // DEFAULT_HEARTBEAT_INTERVAL;
    my $heartbeat_timeout = $config->{heartbeat_timeout} // DEFAULT_HEARTBEAT_TIMEOUT;
    my $bs_prefix = $config->{prefix} // DEFAULT_PREFIX;
    my $ping_interval = $config->{ping_interval} // DEFAULT_PING_INTERVAL;
    my $notify_payload_size_limit = ($config->{notify_payload_size_limit} // DEFAULT_NOTIFY_PAYLOAD_SIZE_LIMIT) - 1;

    # Database stuff
    my $db_string = $config->{'db_string'} or die "missing db_string configuration option";
    my $pg = Mojo::Pg->new($db_string);
    BoardStreams::DBMigrations->apply_migrations($pg);
    $app->helper("$bs_prefix.pg" => sub { $pg });
    $app->helper("$bs_prefix.db" => sub { $pg->db });
    $app->helper("$bs_prefix.pubsub" => sub { $pg->pubsub });
    my $event_patch_sequence_name = $app->$bs_prefix->db->query("
        SELECT pg_get_serial_sequence('event_patch', 'id')
    ")->array->[0];

    my sub get_time {
        return $app->$bs_prefix->db->query("SELECT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)")
            ->array->[0];
    }

    my $pubsub_connected_o = rx_behavior_subject->new(0);
    my $pubsub_connected;

    my @boot_emitters;
    my $last_heartbeat_dt;

    my sub calculate_hb_expiry_dur () {
        state $hb_e_d = $heartbeat_interval + $heartbeat_timeout;
    }

    # on workers startup:
    Mojo::IOLoop->next_tick(sub {
        srand();

        my $graceful_stop_o = rx_from_event(Mojo::IOLoop->singleton, 'finish')->pipe(
            op_share(),
        );

        # on graceful stop, boot all clients
        for my $i (1 .. 10) {
            push @boot_emitters, $graceful_stop_o->pipe(
                op_delay(2 * $i / 10),
                op_share(),
            );
        }

        # remove any heartbeat record
        $graceful_stop_o->subscribe(sub {
            # don't prevent other callbacks if this dies
            eval {
                $app->$bs_prefix->lock_state($WORKERS_CHANNEL, sub ($state) {
                    delete $state->{$worker_uuid};
                    return undef, $state;
                }, no_ban => 1);
            };
        });

        # register heartbeat at start, or gracefully stop
        try {
            $app->$bs_prefix->lock_state($WORKERS_CHANNEL, sub ($state) {
                $last_heartbeat_dt = int get_time;
                $state->{$worker_uuid} = {
                    uuid      => $worker_uuid,
                    pid       => $$,
                    heartbeat => $last_heartbeat_dt,
                    hostname  => hostname,
                    banned    => false,
                };
                return undef, $state;
            }, no_ban => 1);
        } catch {
            Mojo::IOLoop->stop_gracefully;
        };

        # register heartbeat every X seconds, or gracefully stop
        rx_timer(rand($heartbeat_interval), $heartbeat_interval)->pipe(
            op_take_until($graceful_stop_o),
        )->subscribe(sub {
            try {
                $app->$bs_prefix->lock_state($WORKERS_CHANNEL, sub ($state) {
                    my $me = $state->{$worker_uuid};
                    if (! $me or $me->{banned}) {
                        Mojo::IOLoop->stop_gracefully;
                        return undef, undef;
                    }
                    $last_heartbeat_dt = int get_time;
                    $me->{heartbeat} = $last_heartbeat_dt;
                    return undef, $state;
                }, no_ban => 1);
            } catch {
                Mojo::IOLoop->stop_gracefully;
            };
        });

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

        # if no notifications from _bs:workers in a while, stop gracefully
        rx_observable->new(sub ($subscriber) {
            try {
                $pg->pubsub->listen($WORKERS_CHANNEL => sub ($pubsub, $payload) {
                    $subscriber->next();
                });
            } catch {
                Mojo::IOLoop->stop_gracefully;
            };
        })->pipe(
            op_switch_map(sub {
                return rx_timer(calculate_hb_expiry_dur());
            }),
        )->subscribe(sub {
            Mojo::IOLoop->stop_gracefully;
        });

        # one process needs to call "global_cleanup" every "cleanup_interval" seconds:
        if ($cleanup_interval) {
            rx_defer(sub {
                return rx_timer($cleanup_interval * 0.5 + rand($cleanup_interval));
            })->pipe(
                op_repeat(),
                op_take_until($graceful_stop_o),
            )->subscribe(async sub {
                my $t0 = Time::HiRes::time();
                my $cleanup_state = $app->$bs_prefix->get_state($CLEANUP_CHANNEL);
                return unless $t0 >= $cleanup_state->{last_cleanup} + $cleanup_interval;

                my $me_is_cleanup_executor = 0;

                my $txn = $app->$bs_prefix->begin;
                $txn->db->select('channel',
                    'id',
                    { name => $CLEANUP_CHANNEL },
                    { for => \'update skip locked' },
                )->hash or return;
                $txn->lock_state($CLEANUP_CHANNEL, sub ($state) {
                    return undef, undef if Time::HiRes::time() < $state->{last_cleanup} + $cleanup_interval;

                    $state->{last_cleanup} = $t0;
                    $me_is_cleanup_executor = 1;

                    return undef, $state;
                });
                return unless $me_is_cleanup_executor;
                await $app->$bs_prefix->global_cleanup;
                $txn->commit;
            });
        }

        # Remove this code when this issue has been addressed:
        #  https://github.com/mojolicious/mojo-pg/issues/77
        $app->$bs_prefix->pubsub->listen('dummy_notification' => sub {});
        rx_timer(rand(0.5), 0.5)->pipe(
            op_take_until($graceful_stop_o),
        )->subscribe(sub {
            $app->$bs_prefix->pubsub->notify('dummy_notification' => '{}');
        });
    });

    $app->helper("$bs_prefix.on_action", sub ($c, $channel_name, $action_name, $action_sub) {
        BoardStreams::Registry->add_action($channel_name, $action_name, $action_sub);
    });

    $app->helper("$bs_prefix.on_request", sub ($c, $channel_name, $request_name, $request_sub) {
        BoardStreams::Registry->add_request($channel_name, $request_name, $request_sub);
    });

    $app->helper("$bs_prefix.create_channel_or_die", sub ($c, $channel_name, $state = undef, $attrs = {}) {
        ! $c->$bs_prefix->db->select('channel',
            'id',
            { name => $channel_name },
        )->hash or db_duplicate_error;
        my $type = $attrs->{type} // '';
        my $keep_events = exists $attrs->{keep_events} ? to_bool $attrs->{keep_events} : true;
        my $sth;
        try {
            $sth = $c->$bs_prefix->db->dbh->prepare('
                INSERT INTO "channel" (name, type, state, keep_events) VALUES (?, ?, ?, ?)
            ');
            $sth->execute($channel_name, $type, to_json($state), $keep_events);
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

    $app->helper("$bs_prefix.create_channel", sub ($c, $channel_name, $state = undef, $attrs = {}) {
        try {
            $c->$bs_prefix->create_channel_or_die($channel_name, $state, $attrs);
            return 1;
        } catch {
            my $e = $@;
            if ($e->$_isa('BoardStreams::Exception::DbError::Duplicate')) {
                return !!0;
            }
            die $e;
        };
    });

    $app->helper("$bs_prefix.begin", sub ($c) {
        my $db = $c->$bs_prefix->db;

        return BoardStreams::Transaction->new(
            bs_prefix                 => $bs_prefix,
            c                         => $c,
            notify_payload_size_limit => $notify_payload_size_limit,
            event_patch_sequence_name => $event_patch_sequence_name,
        );
    });

    $app->helper("$bs_prefix.lock_state", sub ($c, $channel_names, $sub, %opts) {
        my $txn = $c->$bs_prefix->begin;
        my $ret = $txn->lock_state($channel_names, $sub, %opts);
        $txn->commit;
        return $ret;
    });

    $app->helper("$bs_prefix.on_join", sub ($c, $channel_name, $join_sub) {
        BoardStreams::Registry->add_join($channel_name, $join_sub);
    });

    $app->helper("$bs_prefix.on_leave", sub ($c, $channel_name, $leave_sub) {
        BoardStreams::Registry->add_leave($channel_name, $leave_sub);
    });

    $app->helper("$bs_prefix.on_cleanup", sub ($c, $channel_name, $cleanup_sub) {
        BoardStreams::Registry->add_cleanup($channel_name, $cleanup_sub);
    });

    # NOTE: turn this sub into async later
    $app->helper("$bs_prefix.send", sub ($c, $data, $identifier, %opts) {
        # opts can be: binary

        my sub get_max_size {
            return min($c->tx->max_websocket_size, MAX_WEBSOCKET_SIZE);
        }

        my $bytes = $opts{binary} ? $data : encode_json $data;
        my $bytes_length = length($bytes);
        if ($bytes_length < get_max_size) {
            $c->send({binary => $bytes});
            return;
        }

        $identifier =~ s/\:/{}/g;
        my $ending_bytes_prefix = encode_utf8 ":$identifier end: ";
        my $sent_ending = 0;
        for (my ($i, $cursor) = (0, 0); ! $sent_ending; $i++) {
            my $max_size = get_max_size;
            my $remaining_length = $bytes_length - $cursor;
            my $bytes_prefix;
            if (length($ending_bytes_prefix) + $remaining_length <= $max_size) {
                $bytes_prefix = $ending_bytes_prefix;
                $sent_ending = 1;
            } else {
                $bytes_prefix = encode_utf8 ":$identifier $i: ";
            }

            my $sublength = $max_size - length $bytes_prefix;
            my $substring = $remaining_length >= 0 ? substr($bytes, $cursor, $sublength) : '';
            $cursor += $sublength;

            my $piece = $bytes_prefix . $substring;
            $c->send({binary => $piece});
        }
    });

    $app->helper("$bs_prefix.initialize_client", sub ($self) {
        # reject connection, if pubsub is not active
        return $self->rendered(500) if not $pubsub_connected;

        # send initial configuration
        $self->send({binary => encode_json({
            type => 'configuration',
            pingInterval => $ping_interval,
        })});

        # disconnect soon if worker stops gracefully
        $boot_emitters[int rand @boot_emitters]->subscribe(sub {
            $self->finish;
        });

        # trap incoming messages
        $self->on(binary => async sub ($c, $bytes) {
            my $hash = decode_json($bytes);

            # join
            if ($hash->{type} eq 'join') {
                my $channel_name = string $hash->{channel};
                my $channel_uuid = string $hash->{channelUUID};
                my $since_id = $hash->{sinceId};
                $since_id = int $since_id if defined $since_id;

                # join handler
                my $join_handler = BoardStreams::Registry->get_join($channel_name) or return;
                if (BoardStreams::Registry->has_pair($c, $channel_name)) {
                    # not first join, so use a join handler that does nothing
                    $join_handler = sub {
                        return { limit => 0 };
                    };
                }
                $c->$bs_prefix->channel_exists($channel_name) or return;
                my $attrs = { since_id => $since_id, is_reconnect => int(defined $since_id) };

                my $o = get_listener_observable($c, $channel_name, $bs_prefix);
                my $s = $o->subscribe();

                my $join_ret = eval { $join_handler->($channel_name, $c, $attrs) };
                if ($join_ret->$_can('then')) {
                    $join_ret = eval { await $join_ret };
                }
                if (! $join_ret) {
                    $s->unsubscribe();
                    return;
                }
                my $limit = eval { $join_ret->{limit} } // 0;

                my $was_added = BoardStreams::Registry->add_pair($c, $channel_name);
                if ($was_added) {
                    $c->stash->{subscriptions}{channels}{$channel_name} = $s;
                } else {
                    $s->unsubscribe();
                }

                # NOTE: in the async case in the future, make sure the subscription is still there
                # after the query, before sending state to user

                my $db = $c->$bs_prefix->db;
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
                        $c->$bs_prefix->send({
                            type        => 'event_patch',
                            channel     => $channel_name,
                            channelUUID => $channel_uuid,
                            immediate   => true,
                            id          => int $event_row->{id},
                            data        => {
                                event => from_json($event_row->{event}),
                            },
                        }, "imm-event_patch-$channel_name-$channel_uuid");
                    }
                }

                $c->$bs_prefix->send({
                    type        => 'state',
                    channel     => $channel_name,
                    channelUUID => $channel_uuid,
                    id          => int $event_id,
                    data        => from_json($state),
                }, "state-$channel_name-$channel_uuid");
            }

            # leave
            if ($hash->{type} eq 'leave') {
                my $channel_name = string $hash->{channel};
                return unless $c->$bs_prefix->joined($channel_name);
                BoardStreams::Registry->remove_pair($c, $channel_name);
                my $s = delete $c->stash->{subscriptions}{channels}{$channel_name};
                $s->unsubscribe() if defined $s;
                my $leave_sub = BoardStreams::Registry->get_leave($channel_name);
                $leave_sub->($channel_name, $c) if $leave_sub;
            }

            # action
            if ($hash->{type} eq 'action') {
                my $channel_name = string $hash->{channel};
                return unless $c->$bs_prefix->joined($channel_name);
                my ($action_name, $payload) = $hash->{data}->@*;
                my $action_sub = BoardStreams::Registry->get_action($channel_name, $action_name);
                $action_sub->($channel_name, $c, $payload);
            }

            # request
            if ($hash->{type} eq 'request') {
                my $channel_name = string $hash->{channel};
                my ($request_name, $payload) = $hash->{data}->@*;
                my $request_id = string $hash->{requestId};
                my $request_sub;
                $c->$bs_prefix->joined($channel_name) or $request_sub //= sub {
                    die { 'system' => 'not_joined' };
                };
                $request_sub //= BoardStreams::Registry->get_request($channel_name, $request_name);
                $request_sub //= sub {
                    die { 'system' => 'invalid_request_name' };
                };
                my $t0 = Time::HiRes::time();
                my $return_value;
                my $ok = eval { $return_value = $request_sub->($channel_name, $c, $payload); 1 };
                my $err; $err = $@ if ! $ok;
                my $duration = sprintf("%.1fms", (Time::HiRes::time() - $t0) * 1e3);
                if ($return_value->$_can('then')) {
                    $ok = eval { $return_value = await $return_value; 1 };
                    $err = $@ if !$ok;
                }

                if (! $ok) {
                    $err = "$err" if not eval { to_json $err; 1 };
                }

                if ($ok) {
                    $c->$bs_prefix->send({
                        type      => 'response',
                        channel   => $channel_name,
                        requestId => $request_id,
                        result    => $return_value,
                        duration  => $duration,
                    }, "response-$channel_name-$request_id");
                } else {
                    $c->$bs_prefix->send({
                        type      => 'response',
                        channel   => $channel_name,
                        requestId => $request_id,
                        error     => $err,
                        duration  => $duration,
                    }, "response-$channel_name-$request_id");
                }
            }

            # on $hash->{type} eq 'ping', do nothing
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
                eval { $leave_sub->($channel_name, $c) } if $leave_sub;
                if (my $err = $@) {
                    $c->app->log->error("Error while leaving channel $channel_name: $err");
                }
            }
        });
    });

    $app->helper("$bs_prefix.joined", sub ($c, $channel_name) {
        return BoardStreams::Registry->has_pair($c, $channel_name);
    });

    $app->helper("$bs_prefix.worker_uuid", sub ($c) {
        return $worker_uuid;
    });

    $app->helper("$bs_prefix.get_state", sub ($c, $channel_name) {
        my $db = $c->$bs_prefix->db;
        my $hash = $db->select('channel',
            ['state'],
            { name => $channel_name },
        )->hash;

        return $hash ? from_json($hash->{state}) : undef;
    });

    $app->helper("$bs_prefix.alive_workers", sub ($c) {
        my $workers_state = $c->$bs_prefix->get_state($WORKERS_CHANNEL);
        return {
            map {( $_, 1 )}
                grep ! $workers_state->{$_}{banned},
                keys %$workers_state
        };
    });

    $app->helper("$bs_prefix.global_cleanup", async sub ($c) {
        my $workers_state = $c->$bs_prefix->get_state($WORKERS_CHANNEL);
        my $time = get_time;
        foreach my $worker (values %$workers_state) {
            next if $time <= $worker->{heartbeat} + calculate_hb_expiry_dur();

            my $db = $c->$bs_prefix->db;

            # 0. set 'banned' property of worker to true
            $c->$bs_prefix->lock_state($WORKERS_CHANNEL, sub ($state) {
                $state->{$worker->{uuid}}{banned} = true
                    if exists $state->{$worker->{uuid}};
                return undef, $state;
            }, no_ban => 1);

            # 1. find channel names from "guards" table
            my $worker_uuid = $worker->{uuid};
            my @channels = $db->query(q{
                SELECT c.id, c.name
                    FROM guards g JOIN channel c ON (c.id = g.channel_id)
                    WHERE g.worker_uuid = ?
            }, $worker_uuid)->hashes->@*;

            # 2. call cleanup subs (deleting guards rows in the process)
            CHANNEL:
            foreach my $channel (@channels) {
                await next_tick_p();
                my $txn = $c->$bs_prefix->begin;
                my $db = $txn->db;
                my $channel_name = $channel->{name};

                # lock channel to prevent lock_state from modifying guard counts
                $db->select('channel',
                    'id',
                    { name => $channel_name },
                    { for => 'update' },
                )->hash or next CHANNEL;
                my $guard_row = $db->select('guards',
                    ['counter'],
                    {
                        worker_uuid => $worker_uuid,
                        channel_id  => $channel->{id},
                    },
                    { for => 'update' },
                )->hash or next CHANNEL;
                my $guards_counter = $guard_row->{counter};

                # call cleanup sub
                if (my $cleanup_sub = BoardStreams::Registry->get_cleanup($channel_name)) {
                    my $alive_workers = $c->$bs_prefix->alive_workers;
                    $cleanup_sub->($channel_name, $txn, $alive_workers);
                }

                $db->update('guards',
                    { counter => \"counter - $guards_counter" },
                    {
                        worker_uuid => $worker_uuid,
                        channel_id => $channel->{id},
                    },
                );
                $db->delete('guards',
                    {
                        worker_uuid => $worker_uuid,
                        channel_id  => $channel->{id},
                        counter     => {'<=', 0},
                    },
                );
                $txn->commit;
            }

            # 3. delete worker from :heartbeats
            $c->$bs_prefix->lock_state($WORKERS_CHANNEL, sub ($state) {
                delete $state->{$worker->{uuid}};
                return undef, $state;
            }, no_ban => 1);
        }
        my $duration = get_time() - $time;
        $c->app->log->warn('Channels cleanup took ' . (0 + sprintf("%.2f", $duration)) . ' seconds')
            if $duration > 1;
    });

    $app->helper("$bs_prefix.delete_events", sub ($c, $channel_name, %opts) {
        # opts can be: keep_num and/or keep_dur
        my @until_ids;

        my $channel_id = $c->$bs_prefix->db->select('channel',
            ['id'],
            { name => $channel_name },
        )->hash->{id} or return;

        if (defined $opts{keep_num}) {
            my $until_hash = $c->$bs_prefix->db->select('event_patch',
                ['id'],
                {
                    channel_id => $channel_id,
                },
                {
                    order_by => { -desc => 'id' },
                    offset   => $opts{keep_num},
                    limit    => 1,
                },
            )->hash;
            my $until_id = $until_hash ? $until_hash->{id} : 0;
            push @until_ids, $until_id;
        }

        if (defined $opts{keep_dur}) {
            $opts{keep_dur} .= ' SECOND' if $opts{keep_dur} =~ /^\d+\z/;
            my $interval = $c->$bs_prefix->db->dbh->quote( $opts{keep_dur} );
            my $until_hash = $c->$bs_prefix->db->select('event_patch',
                ['id'],
                {
                    channel_id => $channel_id,
                    datetime   => { '<', \"current_timestamp - INTERVAL $interval" },
                },
                {
                    order_by => { -desc => 'datetime' },
                    limit    => 1,
                },
            )->hash;
            my $until_id = $until_hash ? $until_hash->{id} : 0;
            push @until_ids, $until_id;
        }

        my $until_id = min @until_ids;

        $c->$bs_prefix->db->delete('event_patch',
            {
                channel_id => $channel_id,
                defined($until_id) ? (id => { '<=', $until_id }) : (),
            }
        );
    });

    $app->helper("$bs_prefix.channel_exists", sub ($c, $channel_name) {
        my $hash = $c->$bs_prefix->db->select('channel', 'id', { name => $channel_name })->hash;
        return !! $hash;
    });

    # system channels
    {
        $app->$bs_prefix->create_channel($WORKERS_CHANNEL, {}, { keep_events => 0 });
        $app->$bs_prefix->create_channel($CLEANUP_CHANNEL, { last_cleanup => 0 }, { keep_events => 0 });
    }
}

1;