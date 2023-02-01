package Mojolicious::Plugin::BoardStreams;

use Mojo::Base 'Mojolicious::Plugin', -signatures, -async_await;

use BoardStreams::Registry;
use BoardStreams::DBUtil qw/
    query_throwing_exception_object_p exists_p
    row_exists query_throwing_exception_object
/;
use BoardStreams::Util qw/
    trim :bool unique_id hashify next_tick_p sleep_p
    encode_json decode_json
/;
use BoardStreams::Exceptions qw/ jsonrpc_error /;
use BoardStreams::REs;
use BoardStreams::DBMigrations;

use Mojo::IOLoop;
use RxPerl::Mojo ':all';
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Safe::Isa;
use Text::Trim;
use Struct::Diff 'diff';
use List::AllUtils 'pairs', 'min';
use Crypt::Digest::SHA256 'sha256_b64u';
use Storable 'dclone';
use Carp 'croak';

no autovivification;

use experimental 'isa';

use constant UNIQUE_STREAM_NAME_INDEX => 'bs_streams_uidx_name';
use constant {
    DEFAULT_HEARTBEAT_INTERVAL => 5,
    DEFAULT_REPAIR_INTERVAL    => 40,
    DEFAULT_PING_INTERVAL      => 15,
    DEFAULT_NOTIFY_SIZE_LIMIT  => 8_000,
    MAX_WEBSOCKET_SIZE         => 262_144,
};

our $VERSION = "v0.0.32";

has _listener_observables => sub { +{} };

my $MAX_WEBSOCKET_SIZE = MAX_WEBSOCKET_SIZE;

our @CARP_NOT;

sub register ($self, $app, $config) {
    # config options
    my $HEARTBEAT_INTERVAL = $config->{heartbeat_interval} // DEFAULT_HEARTBEAT_INTERVAL;
    my $REPAIR_INTERVAL = $config->{repair_interval} // DEFAULT_REPAIR_INTERVAL;
    my $PING_INTERVAL = $config->{ping_interval} // DEFAULT_PING_INTERVAL;
    my $NOTIFY_SIZE_LIMIT = ($config->{notify_size_limit} // DEFAULT_NOTIFY_SIZE_LIMIT) - 1;

    my $pg = $config->{Pg};
    my $registry = BoardStreams::Registry->new;
    my $worker_id;   # UUID
    my $am_repairer; # is this worker process the repairer?
    my $is_finished; # is this worker process shutting down?
    my $can_accept_clients = 0;

    # Migrate database to newest schema
    BoardStreams::DBMigrations->apply_migrations($pg);

    $app->helper('bs.worker_id' => sub ($c) { $worker_id });

    my sub stop_gracefully {
        Mojo::IOLoop->stop_gracefully unless $is_finished;
    }

    my sub get_pg_channel_name ($stream_name) {
        return sha256_b64u("boardstreams.$stream_name");
    }

    my $on_client_finish_sub = async sub ($c) {
        $registry->is_conn_registered($c) or return;
        $registry->unregister_conn($c);
        await first_value_from(
            $registry->pending_joins->{$c}->pipe(
                op_filter(sub { $_ == 0 }),
            ),
        );
        await next_tick_p; # to allow pending join handlers to send their return values
        my $streams_and_counts_of_conn = $registry->get_streams_and_counts_of_conn($c) or return;

        my $db = dynamically $BoardStreams::db = $pg->db;

        PAIR:
        foreach my $stream_name (keys %$streams_and_counts_of_conn) {
            $registry->is_member_of($c, $stream_name) or next PAIR;

            my $tx = $db->begin;

            await exists_p(
                $db,
                'bs_streams',
                { name => $stream_name },
                { for => 'update' },
            ) or next PAIR;

            $registry->is_member_of($c, $stream_name) or next PAIR;

            if (my $leave_sub = $registry->get_leave($stream_name)) {
                my $left_completely;
                while (! $left_completely) {
                    $left_completely = $registry->remove_membership($c, $stream_name)
                        and (delete $registry->conn_subscriptions->{$c}{$stream_name})->unsubscribe;

                    try {
                        my $result = $leave_sub->($c, $stream_name);
                        await $result if $result->$_can('then');
                    } catch ($e) {
                        $c->log->fatal("Couldn't execute leave sub, stopping worker: $e");
                        # so as to not leave the streams in an inconsistent state
                        stop_gracefully();
                    };
                }
            } else {
                1 until $registry->remove_membership($c, $stream_name);
                (delete $registry->conn_subscriptions->{$c}{$stream_name})->unsubscribe;
            }

            $tx->commit;
        }
    };

    # all workers execute this at the beginning
    Mojo::IOLoop->next_tick(sub {
        $worker_id = unique_id;

        # set $can_accept_clients
        {
            my $pubsub_connected_o = rx_merge(
                rx_from_event($pg->pubsub, 'reconnect')->pipe(op_map_to(1)),
                rx_from_event($pg->pubsub, 'disconnect')->pipe(op_map_to(0)),
            )->pipe(op_start_with(0));

            # stop & kick everyone on these events
            rx_merge(
                # if disconnect from pg
                $pubsub_connected_o->pipe(
                    op_pairwise(),
                    op_filter(sub {
                        my ($prev, $curr) = @$_;
                        return $prev && ! $curr;
                    })
                ),

                # if not connected to pg the first three seconds
                rx_timer(3)->pipe(
                    op_take_until(
                        $pubsub_connected_o->pipe(op_filter(sub { $_ })),
                    ),
                ),
            )->subscribe(sub {
                $can_accept_clients = 0;
                stop_gracefully();
            });

            # allow connections on...
            $pubsub_connected_o->pipe(
                op_filter(sub { $_ }),
            )->subscribe(sub { $can_accept_clients = 1 });
        }

        # this is to... (?)
        $pg->pubsub->listen('boardstreams.dummy' => sub {});

        # create worker row
        $pg->db->insert(
            'bs_workers',
            {
                id           => $worker_id,
                dt_heartbeat => \'CURRENT_TIMESTAMP',
            },
            { on_conflict => undef },
        )->rows or stop_gracefully();

        # store heartbeat, shutdown if worker row is missing
        rx_timer(rand($HEARTBEAT_INTERVAL), $HEARTBEAT_INTERVAL)->subscribe(async sub {
            # update heartbeat or stop and finish
            (await $pg->db->update_p(
                'bs_workers',
                { dt_heartbeat => \'CURRENT_TIMESTAMP' },
                { id => $worker_id },
            ))->rows or stop_gracefully();
        });

        # elect repairer if needed, and repair
        rx_timer(rand($REPAIR_INTERVAL), $REPAIR_INTERVAL)->subscribe(async sub {
            my $db = $pg->db;

            # revolt against absent ruler
            await $db->delete_p(
                'bs_workers',
                {
                    is_repairer  => 1,
                    dt_heartbeat => { '<', \["NOW() - INTERVAL '1 SECOND' * ?", 2 * $HEARTBEAT_INTERVAL] }
                }
            );

            my $repairer_row = (await $db->select_p(
                'bs_workers',
                'id',
                { is_repairer => 1 },
            ))->hashes->[0];

            if ($repairer_row) {
                $am_repairer = $repairer_row->{id} eq $worker_id;
            } else {
                $am_repairer = 1 if (await $db->update_p(
                    'bs_workers',
                    { is_repairer => 1 },
                    { id => $worker_id },
                    { on_conflict => undef },
                ))->rows;
            }

            if ($am_repairer) {
                await $app->bs->repair_p;
            }
        });

        # on ioloop finish, make clients leave and remove worker row
        rx_from_event(Mojo::IOLoop->singleton, 'finish')->pipe(
            op_take(1),
        )->subscribe(async sub {
            $is_finished = 1;
            # this is to make clients leave their streams before before deleting worker row, to avoid
            # having the repairer repairing w/o reason
            $_->finish foreach $registry->get_all_conns->@*;
            foreach my $conn ($registry->get_all_conns->@*) {
                await $on_client_finish_sub->($conn);
            };

            await $pg->db->delete_p(
                'bs_workers',
                { id => $worker_id },
            );
        });
    });

    # repair all streams that need repairing
    $app->helper('bs.repair_p' => async sub ($c) {
        my $db = dynamically $BoardStreams::db = $pg->db;

        await $db->delete_p(
            'bs_workers',
            { dt_heartbeat => { '<', \["NOW() - INTERVAL '1 SECOND' * ?", 2 * $HEARTBEAT_INTERVAL] } },
        );

        my @dead_worker_ids = (await $db->select_p(
            [
                'bs_guards',
                [-left, 'bs_workers', id => 'worker_id'],
            ],
            [\'DISTINCT bs_guards.worker_id'],
            { 'bs_workers.id' => undef },
        ))->hashes->map(sub {$_->{worker_id}})->@* or return;

        while (1) {
            my $tx = $db->begin;

            # lock one stream that needs repair
            my $stream_row = (await $db->select_p(
                [
                    'bs_guards',
                    ['bs_streams', id => 'stream_id'],
                ],
                ['bs_streams.id', 'bs_streams.name'],
                { 'bs_guards.worker_id' => {-in, \@dead_worker_ids} },
                {
                    limit => 1,
                    for => 'update',
                },
            ))->hashes->[0] or last;
            my ($stream_id, $stream_name) = $stream_row->@{qw/ id name /};

            my @new_dead_worker_ids_for_stream;
            my $get_dead_worker_ids = async sub {
                my $results = await $db->select_p(
                    [
                        'bs_guards',
                        [-left, 'bs_workers', id => 'worker_id'],
                    ],
                    [\'DISTINCT bs_guards.worker_id'],
                    {
                        'bs_guards.stream_id' => $stream_id,
                        'bs_workers.id'       => undef,
                    },
                );
                @new_dead_worker_ids_for_stream = $results->arrays->map(sub {$_->[0]})->@*;
                return { map {( $_ => 1 )} @new_dead_worker_ids_for_stream };
            };

            # repair stream
            if (my $stream_repair_sub = $registry->get_repair($stream_name)) {
                my $ret = $stream_repair_sub->($c, $stream_name, $get_dead_worker_ids);
                await $ret if $ret->$_can('then');
            }

            # delete guards pointing to this stream
            await $db->delete_p(
                'bs_guards',
                {
                    stream_id => $stream_id,
                    worker_id => {-in, \@new_dead_worker_ids_for_stream},
                },
            ) if @new_dead_worker_ids_for_stream;

            $tx->commit;
        }
    });

    # send JSON, but only if transaction is not destroyed
    async sub _send_p ($c, $data) {
        my sub get_max_size {
            my $tx = $c->tx or return $MAX_WEBSOCKET_SIZE;
            return min($tx->max_websocket_size, $MAX_WEBSOCKET_SIZE);
        }

        my $message = encode_json $data;
        my $whole_length = length $message;
        if ($whole_length <= get_max_size) {
            $c->tx or return !!0; # check if transaction is destroyed
            $c->send({ binary => $message });
            return 1;
        }

        my $identifier = $c->stash->{'boardstreams.outgoing_uuid'}++;

        for (my ($i, $cursor, $sent_ending) = (0, 0, 0); ! $sent_ending; $i++) {
            my $bytes_prefix;
            my $ending_prefix = ":$identifier $i\$: ";
            my $max_size = get_max_size;
            if (length($ending_prefix) + $whole_length - $cursor <= $max_size) {
                $bytes_prefix = $ending_prefix;
                $sent_ending = 1;
            } else {
                $bytes_prefix = ":$identifier $i: ";
            }

            my $max_sublength = $max_size - length $bytes_prefix;
            my $substring = $cursor <= $whole_length ? substr($message, $cursor, $max_sublength) : '';
            $cursor += $max_sublength;

            $c->tx or return !!0; # check if transaction is destroyed
            $c->send({ binary => $bytes_prefix . $substring });

            # don't cause other threads to hang if message is very large
            await next_tick_p unless $sent_ending;
        }

        return 1;
    }

    $app->helper('bs.init_client_p' => async sub ($c) {
        $can_accept_clients or return $c->rendered(503);

        $registry->conn_subscriptions->{$c} = {};
        $registry->pending_joins->{$c} = rx_behavior_subject->new(0);
        $registry->register_conn($c);
        $c->stash->{'boardstreams.outgoing_uuid'} = 'a';

        $c->on(finish => async sub ($_c, @) {
            await $on_client_finish_sub->($_c);
        });

        await sleep_p(0.25); # mojo issue 1895

        $c->on(text => async sub ($_c, $bytes) {
            my $data = decode_json $bytes;

            my $id;

            # pong and return on ping
            if (($data->{type} // '') eq 'ping') {
                await _send_p($_c, { type => 'pong' });
                return;
            }

            try {
                defined $data->{jsonrpc} and $data->{jsonrpc} eq '2.0'
                    or die 'incoming message is not jsonrpc 2.0';

                (my $method, my $params, $id) = $data->@{qw/ method params id /};

                ! $is_finished or die jsonrpc_error 503, 'this server worker stopped, please try again';
                $registry->is_conn_registered($_c)
                    or die jsonrpc_error 503, "can't receive because connection is closing";

                if ($method eq 'doAction') {
                    # params
                    my ($stream_name, $action_name, $payload) = @$params;

                    # validation
                    ! defined $id or die "action '$action_name' on stream '$stream_name' contains extra id ($id)\n";
                    $registry->is_member_of($_c, $stream_name)
                        or die "Connection has not joined '$stream_name' but tried to do action '$action_name'\n"
                        unless $stream_name eq '!open';

                    # fetch + act
                    my $action_sub = $registry->get_action($stream_name, $action_name)
                        or die "invalid action '$action_name' on stream '$stream_name'\n";

                    my $ret = $action_sub->($_c, $stream_name, $payload);
                    await $ret if $ret->$_can('then');
                } elsif ($method eq 'doRequest') {
                    # params
                    my ($stream_name, $request_name, $payload) = @$params;

                    # validation
                    defined $id and ! length ref $id
                        or die "request '$request_name' on stream '$stream_name' has missing or invalid id ("
                            . ($id // 'undef') . ")\n";
                    $registry->is_member_of($_c, $stream_name)
                        or die jsonrpc_error(
                            403,
                            "Connection has not joined '$stream_name' but tried to do request '$request_name'"
                        )
                        unless $stream_name eq '!open';

                    # fetch + act
                    my $request_sub = $registry->get_request($stream_name, $request_name)
                        or die "invalid request '$request_name' on stream '$stream_name'\n";

                    my $result = $request_sub->($_c, $stream_name, $payload);
                    $result = await $result if $result->$_can('then');

                    # respond
                    await _send_p($_c, {
                        jsonrpc => '2.0',
                        result  => $result,
                        id      => $id,
                    });
                } else {
                    die jsonrpc_error -32_601, 'invalid method', { method => $method };
                }
            } catch ($e) {
                $_c->log->error(trim "$e");
                if (defined $id) {
                    my $jsonrpc_error =
                        $e isa 'BoardStreams::Error::JSONRPC' ? $e
                        : jsonrpc_error 500, trim("$e");

                    await _send_p($_c, {
                        jsonrpc => '2.0',
                        error   => $jsonrpc_error,
                        id      => $id,
                    });
                }
            };
        }) if $c->tx;

        await _send_p($c, {
            type => 'config',
            data => {
                pingInterval => 0 + $PING_INTERVAL,
            },
        });
    });

    $app->hook(around_action => async sub ($next, $c, $action, $last) {
        if ($last and $c->stash->{'boardstreams.endpoint'}) {
            $c->render_later;
            try {
                my $ret = $next->();
                await $ret if $ret->$_can('then');
                return await $c->bs->init_client_p;
            } catch ($e) {
                await sleep_p(1.5);
                await _send_p($c, { type => 'connection failure', requestId => scalar eval {$c->req->request_id} });
                $c->finish if $c->tx;
                $c->log->error($e);
                die $e;
            };
        } else {
            return $next->();
        }
    });

    $app->helper('bs.create_stream_p' => async sub ($c, $stream_name, $starting_state, %opts) {
        local @CARP_NOT = qw/ Mojolicious::Renderer /,
            croak 'Not in an event loop, using bs->create_stream_p; use bs->create_stream instead'
            unless Mojo::IOLoop->is_running;

        # opts can be: type, keep_events
        my $type = $opts{type};
        my $keep_events = exists $opts{keep_events} ? int(!!$opts{keep_events}) : 1;

        # validate params
        $stream_name =~ $BoardStreams::REs::STREAM_NAME
            or croak "invalid stream name: '$stream_name'";
        defined $starting_state
            or croak "starting state not defined";

        my $db = $BoardStreams::db // $pg->db;

        # TODO: Consider locking this row for update
        return !!0 if await exists_p($db, 'bs_streams', { name => $stream_name });

        my $savepoint_name = unique_id;
        my ($in_txn) = eval {
            await $db->query_p(qq{SAVEPOINT "$savepoint_name"});
            1
        };

        try {
            await query_throwing_exception_object_p($db, 'insert_p', [
                'bs_streams',
                {
                    name        => $stream_name,
                    state       => { -json => $starting_state },
                    type        => $type,
                    keep_events => $keep_events,
                },
            ]);

            return 1;
        } catch ($e) {
            die $e
                unless $e isa 'BoardStreams::Error::DB::Duplicate'
                    and $e->data->{key_name} eq UNIQUE_STREAM_NAME_INDEX;

            await $db->query_p(qq{ROLLBACK TO "$savepoint_name"}) if $in_txn;
            return !!0;
        };
    });

    $app->helper('bs.create_stream' => async sub ($c, $stream_name, $starting_state, %opts) {
        local @CARP_NOT = qw/ Mojolicious::Renderer /,
            croak 'In an event loop, using bs->create_stream; use await bs->create_stream_p instead'
            if Mojo::IOLoop->is_running;

        # opts can be: type, keep_events
        my $type = $opts{type};
        my $keep_events = exists $opts{keep_events} ? int(!!$opts{keep_events}) : 1;

        # validate params
        $stream_name =~ $BoardStreams::REs::STREAM_NAME
            or croak "invalid stream name: '$stream_name'";
        defined $starting_state
            or croak "starting state not defined";

        my $db = $BoardStreams::db // $pg->db;

        # TODO: Consider locking this row for update
        return !!0 if row_exists($db, 'bs_streams', { name => $stream_name });

        my $savepoint_name = unique_id;
        my ($in_txn) = eval { $db->query(qq{SAVEPOINT "$savepoint_name"}); 1 };

        try {
            query_throwing_exception_object($db, 'insert', [
                'bs_streams',
                {
                    name        => $stream_name,
                    state       => { -json => $starting_state },
                    type        => $type,
                    keep_events => $keep_events,
                },
            ]);

            return 1;
        } catch ($e) {
            die $e
                unless $e isa 'BoardStreams::Error::DB::Duplicate'
                    and $e->data->{key_name} eq UNIQUE_STREAM_NAME_INDEX;

            $db->query(qq{ROLLBACK TO "$savepoint_name"}) if $in_txn;
            return !!0;
        };
    });

    $app->helper('bs.lock_stream_p' => async sub ($c, $stream_name, $sub) {
        await $c->bs->do_txn_p(async sub ($db) {
            my $stream_row = (await $db->select_p(
                'bs_streams',
                [qw/ id state keep_events /],
                { name => $stream_name },
                { for => 'update' },
            ))->expand->hashes->[0] or die "Couldn't find stream '$stream_name' in database to lock\n";
            my ($stream_id, $old_state, $keep_events) = $stream_row->@{qw/ id state keep_events /};

            my ($new_event, $new_state, $extra_guards) = $sub->((dclone [$old_state])->[0]);
            ($new_event, $new_state, $extra_guards) = await $new_event if $new_event->$_can('then');

            my $new_event_id;
            $new_event_id = (await $db->insert_p(
                'bs_events',
                {
                    stream_id => $stream_id,
                    data      => { -json => $new_event },
                },
                { returning => 'id' },
            ))->hashes->[0]{id} if $keep_events and defined $new_event;

            if ($new_event_id or defined $new_state) {
                $new_event_id //= (await $db->query_p("SELECT nextval('bs_events_id_seq')"))->arrays->[0][0];

                await $db->update_p(
                    'bs_streams',
                    {
                        defined $new_state ? (state => { -json => $new_state }) : (),
                        event_id => $new_event_id,
                        last_dt  => \'CURRENT_TIMESTAMP',
                    },
                    { id => $stream_id },
                );
            }

            my $diff;
            if (defined $new_state) {
                delete $old_state->{_secret} if ref $old_state eq 'HASH';
                delete $new_state->{_secret} if ref $new_state eq 'HASH';
                $diff = diff($old_state, $new_state, noO => 1, noU => 1);
                $diff = undef if ! %$diff;
            }

            if (defined $extra_guards) {
                if ($extra_guards > 0) {
                    await $db->insert_p(
                        'bs_guards',
                        {
                            worker_id => $worker_id,
                            stream_id => $stream_id,
                            count     => $extra_guards,
                        },
                        {
                            on_conflict => [
                                [ 'worker_id', 'stream_id' ] => { count => \'bs_guards.count + EXCLUDED.count' },
                            ],
                        }
                    );
                } elsif ($extra_guards < 0) {
                    my $guard_row = (await $db->update_p(
                        'bs_guards',
                        { count => \['"count" - ?', abs($extra_guards)] },
                        {
                            worker_id => $worker_id,
                            stream_id => $stream_id,
                        },
                        { returning => 'count' },
                    ))->hashes->[0] or croak "missing guard row";

                    if (! $guard_row->{count}) {
                        await $db->delete_p(
                            'bs_guards',
                            {
                                worker_id => $worker_id,
                                stream_id => $stream_id,
                                count     => 0, # because user may have forgotten to start a txn
                            },
                        );
                    }
                }
            }

            if (defined $diff or defined $new_event) {
                my $pg_channel = get_pg_channel_name($stream_name);
                my $notification = encode_json({
                    id    => int $new_event_id,
                    event => $new_event,
                    patch => $diff,
                });
                my $whole_length = length $notification;
                if ($whole_length <= $NOTIFY_SIZE_LIMIT) {
                    $db->notify($pg_channel, $notification);
                } else {
                    # send notification in chunks
                    for (my ($i, $cursor, $sent_ending) = (0, 0, 0); ! $sent_ending; $i++) {
                        my $bytes_prefix;
                        my $ending_bytes_prefix = ":$new_event_id $i\$: ";
                        # this assumes that length $ending_bytes_prefix < $NOTIFY_SIZE_LIMIT
                        if (length($ending_bytes_prefix) + $whole_length - $cursor <= $NOTIFY_SIZE_LIMIT) {
                            $bytes_prefix = $ending_bytes_prefix;
                            $sent_ending = 1;
                        } else {
                            $bytes_prefix = ":$new_event_id $i: ";
                        }

                        my $max_sublength = $NOTIFY_SIZE_LIMIT - length $bytes_prefix;
                        my $substring = $cursor <= $whole_length ? substr($notification, $cursor, $max_sublength) : '';
                        $cursor += $max_sublength;

                        $db->notify($pg_channel, $bytes_prefix . $substring);

                        # don't cause other threads to hang if notification is very large
                        await next_tick_p unless $sent_ending;
                    }
                }
            }
        });

        return undef;
    });

    $app->helper('bs.set_action' => sub ($c, $stream_name, $action_name, $sub) {
        $registry->set_action_request(
            action => $stream_name, $action_name, $sub
        );
    });

    $app->helper('bs.set_request' => sub ($c, $stream_name, $request_name, $sub) {
        $registry->set_action_request(
            request => $stream_name, $request_name, $sub
        );
    });

    $app->helper('bs.set_join' => sub ($c, $stream_name, $sub) {
        $registry->set_action_request(
            join_leave => $stream_name, 'join', $sub
        );
    });

    $app->helper('bs.set_leave' => sub ($c, $stream_name, $sub) {
        $registry->set_action_request(
            join_leave => $stream_name, 'leave', $sub
        );
    });

    $app->helper('bs.set_repair' => sub ($c, $stream_name, $sub) {
        $registry->set_action_request(
            join_leave => $stream_name, 'repair', $sub
        );
    });

    $app->helper('bs.get_state_p' => async sub ($c, $stream_name) {
        my $db = $BoardStreams::db // $pg->db;

        my $stream_row = (await $db->select_p(
            'bs_streams',
            [qw/ state /],
            { name => $stream_name },
            { for => 'update' },
        ))->expand->hashes->[0] or return undef;

        return $stream_row->{state};
    });

    # join
    $app->bs->set_request('!open', 'join', async sub ($c, $, $payload) {
        my ($stream_name, $last_id) = $payload->@{qw/ name last_id /};

        # fetch + act
        my $join_sub = $registry->get_join($stream_name)
            or die "stream '$stream_name' has no join method\n";

        my $db = dynamically $BoardStreams::db = $pg->db;
        my $tx = $db->begin;

        await exists_p(
            $db,
            'bs_streams',
            { name => $stream_name },
            { for => 'update' },
        ) or die "stream '$stream_name' does not exist\n";

        $registry->inc_pending_joins_by($c, 1);
        my $result = do {
            try {
                my $result = $join_sub->($c, $stream_name, {
                    is_reconnect => defined $last_id,
                });
                $result = await $result if $result->$_can('then');
                $result;
            } catch ($e) {
                $registry->inc_pending_joins_by($c, -1);
                die $e;
            };
        };

        $result or die jsonrpc_error 403, 'joining not allowed';

        return do {
            try {
                if (my $is_first_join = $registry->add_membership($c, $stream_name)) {
                    my $o = $c->bs->_get_listener_observable($stream_name);
                    my $s = $o->subscribe();
                    $registry->conn_subscriptions->{$c}{$stream_name} = $s;
                }

                my $limit = eval { $result->{limit} } // 0;

                my $stream_row = (await $db->select_p(
                    'bs_streams',
                    [qw/ id event_id state /],
                    { name => $stream_name },
                ))->expand->hashes->[0] or die "Stream $stream_name does not exist in database";
                my ($stream_id, $stream_event_id, $stream_state) = $stream_row->@{qw/ id event_id state /};
                my $past_event_rows = !$limit ? [] : (await $db->select_p(
                    'bs_events',
                    [qw/ id data /],
                    {
                        stream_id => $stream_id,
                        id        => { '<=', $stream_event_id },
                        defined($last_id) ? (id => { '>', $last_id }) : (),
                    },
                    {
                        order_by => { -desc, 'id' },
                        $limit ne 'all' ? (limit => $limit) : (),
                    }
                ))->expand->hashes->reverse;

                $tx->commit;

                delete $stream_state->{_secret} if ref $stream_state eq 'HASH';

                +{
                    state  => {
                        id   => int $stream_event_id,
                        data => $stream_state,
                    },
                    events => [
                        map +{
                            id    => int $_->{id},
                            event => $_->{data},
                        }, @$past_event_rows
                    ],
                };
            } catch ($e) {
                my $is_last_leave = $registry->remove_membership($c, $stream_name);
                if ($is_last_leave and exists $registry->conn_subscriptions->{$c}{$stream_name}) {
                    (delete $registry->conn_subscriptions->{$c}{$stream_name})->unsubscribe();
                }
                die $e;
            } finally {
                $registry->inc_pending_joins_by($c, -1);
            };
        };
    });

    $app->bs->set_request('!open', 'leave', async sub ($c, $, $payload) {
        my $stream_name = $payload;

        my $db = dynamically $BoardStreams::db = $pg->db;
        my $tx = $db->begin;

        await exists_p(
            $db,
            'bs_streams',
            { name => $stream_name },
            { for => 'update' },
        ) or return;

        if (my $leave_sub = $registry->get_leave($stream_name)) {
            if (my $is_last_leave = $registry->remove_membership($c, $stream_name)) {
                (delete $registry->conn_subscriptions->{$c}{$stream_name})->unsubscribe;
            }

            try {
                my $result = $leave_sub->($c, $stream_name);
                await $result if $result->$_can('then');
            } catch ($e) {
                $c->log->fatal("Couldn't execute leave sub, stopping worker: $e");
                # so as to not leave the streams in an inconsistent state
                stop_gracefully();
                die "$e";
            };

            $tx->commit;
        } else {
            if (my $is_last_leave = $registry->remove_membership($c, $stream_name)) {
                (delete $registry->conn_subscriptions->{$c}{$stream_name})->unsubscribe;
            }
        }

        return 'ok';
    });

    $app->helper('bs._get_listener_observable' => sub ($c, $stream_name) {
        return $self->_listener_observables->{$stream_name} //= rx_observable->new(sub ($subscriber) {
            my $pg_channel = get_pg_channel_name($stream_name);
            my ($acc_event_id, $acc_string, $acc_i) = (0, '', -1);
            my $cb = $pg->pubsub->listen($pg_channel => sub ($, $payload) {
                my $msg;
                if ($payload =~ s/^\:([0-9]+) ([0-9]+)(\$)?\: //) {
                    my ($event_id, $i, $is_final) = ($1, $2, $3);
                    $event_id >= $acc_event_id or die 'event_id < acc_event_id';
                    $event_id == $acc_event_id or ($acc_event_id, $acc_string, $acc_i) = ($event_id, '', -1);
                    $i == $acc_i + 1 or return; # on listen, maybe we receive second part of old message
                    $acc_string .= $payload;
                    if ($is_final) {
                        $msg = decode_json $acc_string;
                        ($acc_string, $acc_i) = ('', -2); # -2 is closed to appends
                    } else {
                        $acc_i = $i;
                    }
                } else {
                    $msg = decode_json $payload;
                    my ($event_id) = $msg->{id};
                    $event_id > $acc_event_id or die 'event_id <= acc_event_id';
                    ($acc_event_id, $acc_string, $acc_i) = ($event_id, '', -2);
                }
                $subscriber->next($msg) if defined $msg;
            });

            return sub {
                $pg->pubsub->unlisten($pg_channel => $cb);
                delete $self->_listener_observables->{$stream_name};
            };
        })->pipe(
            # wait until all clients have been sent their message before going on to the next msg
            op_concat_map(sub ($payload, @) {
                my @conns = $registry->get_conns_of_stream($stream_name)->@*;
                my $msg = {
                    type   => 'eventPatch',
                    stream => $stream_name,
                    # payload is +{id, event, patch}
                    %$payload,
                };
                return rx_merge(
                    map rx_from(_send_p($_, $msg)), @conns
                );
            }),
            op_share(),
        );
    });

    $app->helper("bs.delete_events_p", async sub ($c, $stream_name, %opts) {
        # opts can be: keep_num and/or keep_dur
        my @until_ids;

        my $db = $pg->db;

        my $stream_row = (await $db->select_p(
            'bs_streams',
            'id',
            { name => $stream_name },
        ))->hashes->[0] or return;
        my $stream_id = $stream_row->{id};

        if (defined $opts{keep_num}) {
            my $until_row = (await $db->select_p(
                'bs_events',
                'id',
                { stream_id => $stream_id },
                {
                    order_by => { -desc, 'id' },
                    offset   => $opts{keep_num},
                    limit    => 1,
                },
            ))->hashes->[0];
            my $until_id = $until_row ? $until_row->{id} : 0;
            push @until_ids, $until_id;
        }

        if (defined $opts{keep_dur}) {
            my $until_row = (await $db->select_p(
                'bs_events',
                'id',
                {
                    stream_id => $stream_id,
                    datetime  => { '<', \["CURRENT_TIMESTAMP - INTERVAL '1 SECOND' * ?", $opts{keep_dur}] },
                },
                {
                    order_by => { -desc, 'datetime' },
                    limit    => 1,
                }
            ))->hashes->[0];
            my $until_id = $until_row ? $until_row->{id} : 0;
            push @until_ids, $until_id;
        }

        my $until_id = min @until_ids;

        await $db->delete_p(
            'bs_events',
            {
                stream_id => $stream_id,
                defined($until_id) ? (id => {'<=', $until_id}) : (),
            },
        );
    });

    my $deleting_streams = {};
    $app->helper("bs.delete_stream_p", async sub ($c, $stream_name) {
        return 0 if $deleting_streams->{$stream_name};
        dynamically $deleting_streams->{$stream_name} = 1;

        await $c->bs->do_txn_p(async sub ($db) {
            await exists_p(
                $db,
                'bs_streams',
                { name => $stream_name },
                { for => 'update' },
            ) or return 0;


            if (my $leave_sub = $registry->get_leave($stream_name)) {
                foreach my $conn ($registry->get_conns_of_stream($stream_name)->@*) {
                    my $left_completely;
                    while (! $left_completely) {
                        $left_completely = $registry->remove_membership($conn, $stream_name)
                            and (delete $registry->conn_subscriptions->{$conn}{$stream_name})->unsubscribe;

                        try {
                            my $result = $leave_sub->($conn, $stream_name);
                            await $result if $result->$_can('then');
                        } catch ($e) {
                            $c->log->fatal("Couldn't execute leave sub, stopping worker: $e");
                            # so as to not leave the streams in an inconsistent state
                            stop_gracefully();
                        };
                    }
                }
            } else {
                foreach my $conn ($registry->get_conns_of_stream($stream_name)->@*) {
                    1 until $registry->remove_membership($conn, $stream_name);
                    (delete $registry->conn_subscriptions->{$conn}{$stream_name})->unsubscribe;
                }
            }

            await $db->delete_p(
                'bs_streams',
                { name => $stream_name },
            );
        });

        delete $deleting_streams->{$stream_name};

        return 1;
    });

    $app->helper('bs.do_txn_p', async sub ($c, $sub) {
        my $tx;
        dynamically $BoardStreams::db = do { my $db = $pg->db; $tx = $db->begin; $db }
            if ! $BoardStreams::db;
        my $db = $BoardStreams::db;

        my $ret = $sub->($db);
        await $ret if $ret->$_can('then');

        $tx->commit if $tx;
    });
}

1;
