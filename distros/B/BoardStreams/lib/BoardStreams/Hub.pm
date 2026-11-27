use v5.44;
use experimental 'class';

# The server side of BoardStreams: registers channel handlers, talks to
# browsers over WebSockets, and keeps channel state and events in
# PostgreSQL so that they survive disconnections and restarts.
class BoardStreams::Hub {
    our $VERSION = "v0.0.58";

    use Future::AsyncAwait future_class => "Mojo::Promise";
    use Mojo::IOLoop;
    use Mojo::JSON qw(encode_json from_json to_json);
    use Mojo::Log;
    use Mojo::Promise;
    use Scalar::Util qw(blessed weaken);

    use BoardStreams ();
    use BoardStreams::Context;
    use BoardStreams::Diff qw(diff);
    use BoardStreams::Rejection;
    use BoardStreams::Update;

    use constant NOTIFY_NAME => 'boardstreams';
    use constant PUMP_BATCH  => 500;
    use constant CONTROL_NAME => 'boardstreams_control';
    use constant CONTROL_MAX  => 7000;    # PostgreSQL allows notifications of just under 8000 bytes

    field $pg :param :reader;
    field $log :param = Mojo::Log->new;
    field $retention :param = 3600;       # seconds that events and request ids are kept
    field $retry_delay :param = 1;        # seconds between retries when PostgreSQL is unreachable
    field $heartbeat_interval :param = 25;    # seconds between heartbeats to each browser
    field $identify :param = undef;       # sub ($c) returning who a connection belongs to
    field $listener_check_interval :param = 5;    # seconds between checks that notifications still arrive

    field @specs;         # registered channels, each { pattern, regex, ... }
    field %conns;         # connection id => { c => controller, channels => { name => 1 }, user => ... }
    field %members;       # channel => { connection id => last sequence number sent }
    field %pumping;       # channel => 1 while delivering, 2 if asked again meanwhile
    field %joining;       # channel => { join number => \$stale } for joins reading the channel's row
    field $next_join = 0;
    field $next_conn = 0;
    field $migrated = 0;
    field $started = 0;
    field $wired = 0;
    field $hearing = 0;       # true while this process receives PostgreSQL notifications
    field $token;             # tells this process's own echoes from those of others
    field $echo_sent = 0;
    field $echo_awaited;      # number of the echo that has not come back yet
    field $scope;             # the PostgreSQL schema the tables are in
    field $outdated = 0;      # schema version that a newer process announced, if above this code's
    field $stopping = 0;      # true once this process has begun to stop gracefully
    field $on_finish;         # this hub's subscriber to the event loop's finish event

    my $SCHEMA = <<~'SQL';
        -- 1 up
        create table bs_channel (
            name  text primary key,
            seq   bigint not null default 0,
            state jsonb not null
        );
        create table bs_event (
            channel    text not null,
            seq        bigint not null,
            diff       jsonb,
            events     jsonb not null,
            created_at timestamptz not null default now(),
            primary key (channel, seq)
        );
        create index bs_event_created_at on bs_event (created_at);
        create table bs_request (
            id         text primary key,
            channel    text not null,
            seq        bigint not null default 0,
            response   jsonb,
            created_at timestamptz not null default now()
        );
        create index bs_request_created_at on bs_request (created_at);
        -- 1 down
        drop table bs_request;
        drop table bs_event;
        drop table bs_channel;
        -- 2 up
        delete from bs_event e where not exists (select 1 from bs_channel c where c.name = e.channel);
        delete from bs_request r where not exists (select 1 from bs_channel c where c.name = r.channel);
        alter table bs_event add constraint bs_event_channel_fkey
            foreign key (channel) references bs_channel (name) on delete cascade;
        alter table bs_request add constraint bs_request_channel_fkey
            foreign key (channel) references bs_channel (name) on delete cascade;
        create index bs_request_channel on bs_request (channel);
        -- A deleted channel that is created again must not reuse sequence
        -- numbers, or a browser returning with an old number would be sent
        -- updates of the new channel as if they continued the old one. So
        -- every new channel starts above the highest number that any
        -- deleted channel ever reached, which this one row keeps.
        create table bs_floor (
            only_row boolean primary key default true check (only_row),
            seq      bigint not null default 0
        );
        insert into bs_floor default values;
        create function bs_channel_deleted() returns trigger language plpgsql
            set search_path from current as $body$
        begin
            update bs_floor set seq = greatest(seq, old.seq + 1);
            return old;
        end
        $body$;
        create trigger bs_channel_deleted after delete on bs_channel
            for each row execute function bs_channel_deleted();
        -- 2 down
        drop trigger bs_channel_deleted on bs_channel;
        drop function bs_channel_deleted();
        drop table bs_floor;
        drop index bs_request_channel;
        alter table bs_request drop constraint bs_request_channel_fkey;
        alter table bs_event drop constraint bs_event_channel_fkey;
        SQL

    # The newest schema version this code knows.
    my ($SCHEMA_VERSION) = sort { $b <=> $a } $SCHEMA =~ /^-- (\d+) up$/mg;

    # Registers handlers for a channel name, or for a family of names when
    # the pattern contains "*". A "*" stands for any run of characters other
    # than ":", possibly none: "chat:*" covers "chat:lobby" and "chat:" but
    # not "chat:eu:lobby", which needs "chat:*:*". A "**" stands for any
    # run of characters at all, so "chat:**" covers all three. Everything
    # else in a pattern is literal. If several patterns cover a name, the
    # most specific wins: an exact name, then the pattern with the most
    # literal characters, then the one with the fewest "**", then the one
    # registered first.
    #   join          => sub ($ctx) { ... }  true to accept; $ctx->reject($reason) to refuse
    #   actions       => { name => sub ($ctx, $payload) { ... } }
    #   requests      => { name => sub ($ctx, $payload) { ...; return $response_payload } }
    #   initial_state => { ... }
    # Handlers may be async subs.
    method channel ($pattern, %spec) {
        my @parts = split /(\*\*|\*)/, $pattern, -1;
        my $regex = join '', map { $_ eq '**' ? '.*' : $_ eq '*' ? '[^:]*' : quotemeta } @parts;
        push @specs, {
            %spec,
            pattern => $pattern,
            regex   => qr/\A$regex\z/s,
            literal => length(join '', grep { !/\A\*\*?\z/ } @parts),
            deep    => scalar(grep { $_ eq '**' } @parts),
        };
        return $self;
    }

    # Creates the tables unless they exist. Called at startup by the plugin
    # (unless it is told to be lazy) and in any case before the first use
    # of the tables in each process, so it never has to be called by hand.
    method migrate {
        return 1 if $migrated;
        $pg->migrations->name('boardstreams')->from_string($SCHEMA)->migrate;
        $migrated = 1;
        # Processes still running older code would go on using the tables
        # the old way; tell them at once (and again with every echo).
        eval {
            $pg->db->query('select pg_notify(?, ?)', CONTROL_NAME,
                to_json({ op => 'schema', schema => $SCHEMA_VERSION, scope => $self->_scope }));
        };
        return 1;
    }

    # Notifications are heard by every session of the database, including
    # other applications that keep their own BoardStreams tables in another
    # schema of it. Control messages carry the schema they are about.
    method _scope {
        return $scope //= $pg->db->query('select current_schema()')->array->[0];
    }

    # A database handle, for work that needs the tables.
    method _db {
        die "BoardStreams: the database is at schema version $outdated, which this code is too old for\n" if $outdated;
        $self->migrate;
        return $pg->db;
    }

    # Changes a channel's state and/or emits events on it, as one atomic
    # step with one sequence number. The callback receives a
    # BoardStreams::Update. Returns a promise of the channel's sequence
    # number afterwards.
    method update ($channel, $cb, %opt) {
        return (async sub {
            my $db = $self->_db;
            my $tx = $db->begin;
            my $row = await $self->_row($db, $channel, ' for update');
            my $seq = $row->{seq} + 0;

            my $update = BoardStreams::Update->new(state => from_json($row->{state}));
            await Mojo::Promise->resolve($cb->($update));
            my $diff   = diff(from_json($row->{state}), $update->state);
            my @events = $update->events;

            if ($diff or @events) {
                $seq++;
                await $db->query_p('update bs_channel set seq = ?, state = ? where name = ?',
                    $seq, { json => $update->state }, $channel);
                await $db->query_p('insert into bs_event (channel, seq, diff, events) values (?, ?, ?, ?)',
                    $channel, $seq, ($diff ? { json => $diff } : undef), { json => \@events });
                await $db->query_p('select pg_notify(?, ?)', NOTIFY_NAME, "$seq $channel");
            }
            if (defined(my $id = $opt{request_id})) {
                my $inserted = (await $db->query_p(
                    'insert into bs_request (id, channel, seq) values (?, ?, ?) on conflict (id) do nothing',
                    $id, $channel, $seq))->rows;
                die BoardStreams::Hub::Duplicate->new unless $inserted > 0;
            }
            $tx->commit;

            $self->_pump($channel);
            return $seq;
        })->();
    }

    method emit ($channel, $name, $payload = undef) {
        return $self->update($channel, sub ($u) { $u->emit($name, $payload) });
    }

    # Promise of { seq => ..., state => ... } for a channel.
    method snapshot ($channel) {
        return (async sub {
            my $row = await $self->_row($self->_db, $channel, '');
            return { seq => $row->{seq} + 0, state => from_json($row->{state}) };
        })->();
    }

    # The row of a channel, created first if the channel does not exist.
    # It can be deleted again before it is read, hence the retries.
    method _row ($db, $channel, $lock) {
        return (async sub {
            for my $attempt (1 .. 5) {
                my $row = (await $db->query_p(
                    "select seq, state::text as state from bs_channel where name = ?$lock", $channel))->hash;
                return $row if $row;
                await $db->query_p(
                    'insert into bs_channel (name, seq, state) select ?, seq, ?::jsonb from bs_floor
                     on conflict (name) do nothing',
                    $channel, { json => $self->_initial_state($channel) });
            }
            die "BoardStreams: channel $channel keeps disappearing\n";
        })->();
    }

    # Deletes a channel: its state, its history and its recorded requests.
    # Every member, on all server processes, is removed and told so with
    # the reason, as with kick_all. If the channel is used again it starts
    # afresh from its initial state. Returns a promise of whether there
    # was anything to delete.
    method delete_channel ($channel, $reason = 'deleted', $data = undef) {
        return (async sub {
            my $message = { op => 'deleted', channel => $channel, reason => $reason, data => $data, scope => $self->_scope };
            die "BoardStreams: the reason and data of a deletion must be small\n"
                if length(encode_json($message)) > CONTROL_MAX;
            my $db = $self->_db;
            my $tx = $db->begin;
            my $deleted = (await $db->query_p('delete from bs_channel where name = ?', $channel))->rows;
            # Sent by the same transaction, so that no process hears of the
            # deletion before it can see it.
            await $db->query_p('select pg_notify(?, ?)', CONTROL_NAME, to_json($message));
            $tx->commit;
            return $deleted > 0 ? 1 : 0;
        })->();
    }

    # Deletes events and request ids older than the retention period.
    method purge {
        # Nothing this process could have written yet; do not create the
        # tables just to find them empty.
        return Mojo::Promise->resolve unless $migrated;
        return Mojo::Promise->all(
            map { $pg->db->query_p("delete from $_ where created_at < now() - ? * interval '1 second'", $retention) }
                qw(bs_event bs_request));
    }

    # Removes a user from a channel, on whichever server processes their
    # browsers are connected to. The browser is told that its membership
    # ended, with the reason, and gets nothing further from the channel.
    # Nothing stops it from asking to join again: that is for the join
    # handler to refuse. Returns a promise.
    method kick ($user, $channel, $reason = 'kicked', $data = undef) {
        return $self->_control({ op => 'kick', user => "$user", channel => $channel, reason => $reason, data => $data });
    }

    # Removes everyone from a channel, on all server processes: every
    # member's browser is told that its membership ended, with the reason,
    # exactly as with kick. The channel's state and history stay as they
    # are, and browsers may ask to join again. Returns a promise.
    method kick_all ($channel, $reason = 'kicked', $data = undef) {
        return $self->_control({ op => 'kick_all', channel => $channel, reason => $reason, data => $data });
    }

    # Closes every WebSocket connection of a user, on whichever server
    # processes they are. The browser is told the reason first, and the
    # client does not reconnect. Returns a promise.
    method disconnect ($user, $reason = 'disconnected', $data = undef) {
        return $self->_control({ op => 'disconnect', user => "$user", reason => $reason, data => $data });
    }

    # The same two, for one connection of this process (used by
    # BoardStreams::Context).
    method kick_connection ($id, $channel, $reason = 'kicked', $data = undef) {
        my $conn = $conns{$id} or return;
        return unless delete $conn->{channels}{$channel};
        $self->_send($id, { type => 'rejected', channel => $channel, reason => $reason, data => $data });
        $self->_leave($id, $channel);
        return 1;
    }

    method disconnect_connection ($id, $reason = 'disconnected', $data = undef) {
        my $conn = $conns{$id} or return;
        $self->_send($id, { type => 'disconnect', reason => $reason, data => $data });
        # Forget the connection now, so that nothing more is sent on it.
        delete $conns{$id};
        $self->_leave($id, $_) for keys $conn->{channels}->%*;
        $conn->{c}->finish(4000);
        return 1;
    }

    # Tells every server process, this one included, to act on a user.
    method _control ($message) {
        return (async sub {
            $message->{scope} = $self->_scope;
            die "BoardStreams: the reason and data of a kick or disconnect must be small\n"
                if length(encode_json($message)) > CONTROL_MAX;
            await $pg->db->query_p('select pg_notify(?, ?)', CONTROL_NAME, to_json($message));
            return;
        })->();
    }

    method _controlled ($message) {
        return unless ref $message eq 'HASH' and defined $message->{op};
        if ($message->{op} eq 'kick_all' or $message->{op} eq 'deleted') {
            my $channel = $message->{channel} // return;
            if ($message->{op} eq 'deleted') {
                $$_ = 1 for values %{ $joining{$channel} // {} };
            }
            $self->kick_connection($_, $channel, $message->{reason}, $message->{data})
                for keys %{ $members{$channel} // {} };
            return;
        }
        return unless defined $message->{user};
        my @ids = grep { defined $conns{$_}{user} and $conns{$_}{user} eq $message->{user} } keys %conns;
        for my $id (@ids) {
            if ($message->{op} eq 'kick') {
                $self->kick_connection($id, $message->{channel}, $message->{reason}, $message->{data});
            }
            elsif ($message->{op} eq 'disconnect') {
                $self->disconnect_connection($id, $message->{reason}, $message->{data});
            }
        }
    }

    # Takes over a WebSocket connection. Call from a websocket route.
    method serve ($c) {
        $self->_start;
        # A process that cannot hear PostgreSQL would miss updates, kicks
        # and disconnects, so it serves nobody. The browser keeps trying.
        return $c->finish(1013) if $outdated or !$hearing;
        # Nor does a process that is on its way out; the browser will find
        # another, or the one that replaces this.
        return $c->finish(1001) if $stopping;
        $self->_watch_for_stop;
        my $id = ++$next_conn;
        my $user = $identify ? $identify->($c) : undef;
        $conns{$id} = { c => $c, channels => {}, user => (defined $user ? "$user" : undef) };
        $c->inactivity_timeout($heartbeat_interval * 2 + 10);
        # Two signs of life per interval: a WebSocket ping, whose automatic
        # pong tells this side that the browser is there, and a heartbeat
        # message, which is the only one of the two that the browser's
        # JavaScript can see.
        my $beat = sub (@extra) {
            $c->send([1, 0, 0, 0, 9, '']);
            $c->send({ json => { type => 'heartbeat', interval => $heartbeat_interval, @extra } });
        };
        # The first heartbeat also announces the protocol version; a client
        # that speaks another refuses to go on.
        $beat->(protocol => BoardStreams::PROTOCOL_VERSION);
        my $ping = Mojo::IOLoop->recurring($heartbeat_interval => sub { $beat->() });

        $c->on(json => sub ($c, $msg) {
            return unless ref $msg eq 'HASH' and defined $msg->{type} and defined $msg->{channel};
            my $type = $msg->{type};
            my $p = $type eq 'join'    ? $self->_join($id, $msg)
                  : $type eq 'leave'   ? $self->_leave($id, $msg->{channel})
                  : $type eq 'action'  ? $self->_call($id, $msg, 'actions')
                  : $type eq 'request' ? $self->_call($id, $msg, 'requests')
                  :                      undef;
            $p->catch(sub ($err) { $log->error("BoardStreams: $type failed: $err") }) if blessed $p;
        });
        $c->on(finish => sub {
            Mojo::IOLoop->remove($ping);
            my $conn = delete $conns{$id} or return;
            $self->_leave($id, $_) for keys $conn->{channels}->%*;
        });
        return $self;
    }

    method _spec ($channel) {
        my ($exact) = grep { $_->{pattern} eq $channel } @specs;
        return $exact if $exact;
        # Perl's sort is stable, so the earliest registered wins a full tie.
        my ($best) = sort { $b->{literal} <=> $a->{literal} or $a->{deep} <=> $b->{deep} }
            grep { $channel =~ $_->{regex} } @specs;
        return $best;
    }

    method _initial_state ($channel) {
        my $spec = $self->_spec($channel);
        return $spec && $spec->{initial_state} ? $spec->{initial_state} : {};
    }

    method _send ($id, $msg) {
        my $conn = $conns{$id} or return;
        $conn->{c}->send({ json => $msg });
    }

    # Starts the per-process machinery; must run inside the worker's event loop.
    method _start {
        return if $started++;
        $token = join '-', $$, int rand 1e9;
        $self->_listen;
        Mojo::IOLoop->recurring($listener_check_interval => sub { $self->_check_listener });
        Mojo::IOLoop->recurring(($retention / 10 > 60 ? $retention / 10 : 60) => sub {
            $self->purge->catch(sub ($err) { $log->warn("BoardStreams: purge failed: $err") });
        });
    }

    method _listen {
        my $pubsub = $pg->pubsub;
        unless ($wired++) {
            $pubsub->reconnect_interval($retry_delay);
            $pubsub->on(disconnect => sub { $self->_deaf('lost its PostgreSQL connection') });
            $pubsub->on(reconnect  => sub { $self->_hears });
        }
        my $ok = eval {
            $pubsub->db;    # connects, or dies before any listener is added
            my $mine = $self->_scope;
            $pubsub->json(CONTROL_NAME)->listen(CONTROL_NAME, sub ($pubsub, $message) {
                return unless ref $message eq 'HASH' and ($message->{scope} // '') eq $mine;
                my $op = $message->{op} // '';
                $self->_retire($message->{schema}) if ($message->{schema} // 0) > $SCHEMA_VERSION;
                return if $op eq 'schema';
                return $self->_controlled($message) unless $op eq 'echo';
                undef $echo_awaited
                    if defined $echo_awaited and $message->{token} eq $token and $message->{n} == $echo_awaited;
            });
            $pubsub->listen(NOTIFY_NAME, sub ($pubsub, $payload) {
                my ($seq, $channel) = split / /, $payload, 2;
                my $of = $members{$channel} or return;
                $self->_pump($channel) if grep { $_ < $seq } values %$of;
            });
            1;
        };
        return if $ok;
        $log->warn("BoardStreams: cannot reach PostgreSQL yet: $@");
        Mojo::IOLoop->timer($retry_delay => sub { $self->_listen });
    }

    method _hears {
        $log->info('BoardStreams: hearing PostgreSQL, accepting browsers') unless $hearing;
        $hearing = 1;
        undef $echo_awaited;
    }

    # While this process cannot hear PostgreSQL it would miss updates,
    # kicks and disconnects. Instead of catching up later, it lets go of
    # every browser now: they reconnect, to this process once it hears
    # again or to another one, and every join handler runs afresh.
    method _deaf ($why) {
        return unless $hearing;
        $hearing = 0;
        undef $echo_awaited;
        $log->warn(sprintf 'BoardStreams: %s; closing %d connection(s) until it is back', $why, scalar keys %conns);
        $self->_drop_all;
    }

    method _drop_all ($code = 1013) {
        for my $id (keys %conns) {
            my $conn = delete $conns{$id};
            $self->_leave($id, $_) for keys $conn->{channels}->%*;
            $conn->{c}->finish($code);
        }
    }

    # A graceful stop (the QUIT signal, a hypnotoad hot deployment, a
    # worker that has served its share of connections) waits for the
    # connections of this process to end, and WebSockets never end by
    # themselves. The event loop announces such a stop with its finish
    # event, so this hub listens for it. It has to do so in the process
    # that holds the connections, which need not be the one that built the
    # hub, and again if the loop was reset meanwhile; so this is called
    # for every new connection and subscribes when it finds itself absent.
    method _watch_for_stop {
        my $loop = Mojo::IOLoop->singleton;
        $on_finish //= do {
            weaken(my $hub = $self);
            sub { $hub->_stop if $hub };
        };
        $loop->on(finish => $on_finish) unless grep { $_ == $on_finish } $loop->subscribers('finish')->@*;
    }

    # Lets go of every browser, so that the process can exit. They are
    # not told to stay away: to them this is a lost connection like any
    # other, and they reconnect, to whichever process answers.
    method _stop {
        return if $stopping++;
        my @transactions = map { $_->{c}->tx } values %conns;
        $log->info(sprintf 'BoardStreams: stopping gracefully; closing %d connection(s)', scalar @transactions);
        $self->_drop_all(1001);
        # A browser that does not answer the close must not hold the
        # process up either.
        Mojo::IOLoop->timer(1 => sub {
            Mojo::IOLoop->remove($_->connection) for grep { !$_->is_finished } @transactions;
        });
    }

    # A process running newer code has changed the tables. This code would
    # go on using them the old way, so it stops: it lets go of every
    # browser, refuses new ones and refuses to touch the tables, until the
    # process is restarted with the new code.
    method _retire ($newer) {
        return if $outdated;
        $outdated = $newer;
        $log->error(sprintf 'BoardStreams: the database has moved to schema version %d, but this process runs code for version %d. '
                . 'It has closed its %d connection(s) and serves nobody until restarted with the new code',
            $newer, $SCHEMA_VERSION, scalar keys %conns);
        $self->_drop_all;
    }

    # A connection can die without the socket noticing, so this process
    # keeps sending itself a notification and makes sure it arrives.
    method _check_listener {
        return unless $hearing;
        if (defined $echo_awaited) {
            $self->_deaf('stopped receiving PostgreSQL notifications');
            # Have the listener start over on a fresh connection.
            eval { $pg->pubsub->db->disconnect };
            return;
        }
        my $n = $echo_awaited = ++$echo_sent;
        eval {
            my %echo = (op => 'echo', token => $token, n => $n, scope => $self->_scope);
            $echo{schema} = $SCHEMA_VERSION if $migrated;
            $pg->db->query_p('select pg_notify(?, ?)', CONTROL_NAME, to_json(\%echo))->catch(sub { });
        };
    }

    method _join ($id, $msg) {
        my $channel = $msg->{channel};
        return (async sub {
            my $spec = $self->_spec($channel);
            my $reject = sub ($reason, $data = undef) {
                $self->_send($id, { type => 'rejected', channel => $channel, reason => $reason, data => $data });
            };
            return $reject->('unknown_channel') unless $spec and $spec->{join};
            my $conn = $conns{$id} or return;

            my $ctx = BoardStreams::Context->new(
                hub => $self, c => $conn->{c}, channel => $channel, connection => $id, user => $conn->{user});
            my $accepted = eval { await Mojo::Promise->resolve($spec->{join}->($ctx)) };
            if (my $err = $@) {
                return $reject->($err->reason, $err->data) if _is_rejection($err);
                $log->error("BoardStreams: join handler for $channel died: $err");
                return $reject->('internal_error');
            }
            return $reject->('forbidden') unless $accepted;

            $conn->{channels}{$channel} = 1;
            unless (eval { await $self->_enter($id, $channel, $msg->{since}); 1 }) {
                # Most likely PostgreSQL is unreachable: drop the connection
                # so that the browser retries, instead of leaving it joined
                # to nothing.
                $log->warn("BoardStreams: cannot join $channel: $@");
                $conn->{c}->finish(1013) if $conns{$id};
            }
        })->();
    }

    # Sends a browser what it needs to be up to date on a channel (the
    # updates it missed, or failing that the whole state) and makes it a
    # member from that point on.
    method _enter ($id, $channel, $since, $gap = 0) {
        return (async sub {
            my ($snapshot, $seq, $updates);
            while (1) {
                # If the channel is deleted while this join reads it, what
                # it read belongs to a channel that no longer exists. The
                # deletion notice finds this mark and sets it.
                my $stale  = 0;
                my $number = ++$next_join;
                $joining{$channel}{$number} = \$stale;
                my $ok = eval {
                    $snapshot = await $self->snapshot($channel);
                    $seq      = $snapshot->{seq};
                    undef $updates;
                    if (defined $since and $since =~ /\A[0-9]+\z/ and !$gap) {
                        if    ($since == $seq) { $updates = [] }
                        elsif ($since < $seq) {
                            my $rows = await $self->_updates($channel, $since, $seq);
                            $updates = $rows if @$rows == $seq - $since;
                        }
                        $gap = 1 unless $updates;
                    }
                    1;
                };
                my $err = $@;
                delete $joining{$channel}{$number};
                delete $joining{$channel} unless $joining{$channel}->%*;
                die $err unless $ok;
                last unless $stale;
                # Read again; whatever the browser had before is history.
                $gap = 1 if defined $since;
            }

            my %msg = (type => 'joined', channel => $channel, seq => $seq);
            if   ($updates) { $msg{updates} = $updates }
            else            { $msg{state} = $snapshot->{state}; $msg{gap} = \1 if $gap }

            my $conn = $conns{$id} or return;
            return unless $conn->{channels}{$channel};    # left meanwhile
            $members{$channel}{$id} = $seq;
            $self->_send($id, \%msg);
            $self->_pump($channel);
        })->();
    }

    method _updates ($channel, $after, $upto = undef) {
        return $self->_db->query_p(
            'select seq, diff::text as diff, events::text as events from bs_event
             where channel = ? and seq > ? and seq <= ? order by seq limit ?',
            $channel, $after, $upto // $after + PUMP_BATCH, PUMP_BATCH
        )->then(sub ($results) {
            return $results->hashes->map(sub {
                return {
                    seq    => $_->{seq} + 0,
                    events => from_json($_->{events}),
                    (defined $_->{diff} ? (diff => from_json($_->{diff})) : ()),
                };
            })->to_array;
        });
    }

    method _leave ($id, $channel) {
        delete $conns{$id}{channels}{$channel} if $conns{$id};
        my $of = $members{$channel} or return;
        delete $of->{$id};
        delete $members{$channel} unless %$of;
        return;
    }

    # Delivers committed updates of a channel to its members on this
    # process, strictly in sequence order. Runs once per channel at a time.
    method _pump ($channel) {
        return unless $members{$channel};
        return $pumping{$channel} = 2 if $pumping{$channel};
        $pumping{$channel} = 1;

        (async sub {
            while (my $of = $members{$channel}) {
                $pumping{$channel} = 1;
                my ($from) = sort { $a <=> $b } values %$of;
                my $rows = await $self->_updates($channel, $from);
                $of = $members{$channel} or last;

                for my $id (keys %$of) {
                    for my $row (@$rows) {
                        next if $row->{seq} <= $of->{$id};
                        last if $row->{seq} != $of->{$id} + 1;
                        $self->_send($id, { type => 'update', channel => $channel, %$row });
                        $of->{$id} = $row->{seq};
                    }
                }

                # A member whose next update no longer exists (purged) is
                # given the whole state again, flagged as a gap.
                if (@$rows) {
                    my $last = $rows->[-1]{seq};
                    for my $id (grep { $of->{$_} < $last } keys %$of) {
                        delete $of->{$id};
                        $self->_enter($id, $channel, undef, 1)->catch(sub ($err) {
                            $log->warn("BoardStreams: cannot resync $channel: $err");
                            $conns{$id}{c}->finish(1013) if $conns{$id};
                        });
                    }
                    delete $members{$channel} unless %$of;
                }
                last if @$rows < PUMP_BATCH and $pumping{$channel} == 1;
            }
            delete $pumping{$channel};
        })->()->catch(sub ($err) {
            $log->warn("BoardStreams: cannot read updates of $channel, retrying: $err");
            Mojo::IOLoop->timer($retry_delay => sub {
                delete $pumping{$channel};
                $self->_pump($channel);
            });
        });
        return;
    }

    # Runs an action or request handler, at most once per unique id.
    method _call ($id, $msg, $kind) {
        my ($channel, $name, $msg_id) = @$msg{qw(channel name id)};
        my $is_request = $kind eq 'requests';
        return (async sub {
            my $reply = sub ($res, $seq) {
                return $self->_send($id, { type => 'ack', id => $msg_id }) unless $is_request;
                $self->_send($id, { type => 'response', id => $msg_id, seq => $seq, %$res });
            };
            my $failure = sub ($reason, $data = undef) {
                return { ok => \0, error => { reason => $reason, data => $data } };
            };

            return $reply->($failure->('not_joined'), 0) unless $conns{$id} and $conns{$id}{channels}{$channel};
            my $spec    = $self->_spec($channel);
            my $handler = defined $name ? $spec->{$kind}{$name} : undef;
            return $reply->($failure->("unknown_" . ($is_request ? 'request' : 'action')), 0) unless $handler;

            if (defined $msg_id) {
                my $stored = await $self->_stored($msg_id);
                return $reply->(@$stored) if $stored;
            }

            my $conn = $conns{$id} or return;
            my $ctx  = BoardStreams::Context->new(
                hub => $self, c => $conn->{c}, channel => $channel, request_id => $msg_id,
                connection => $id, user => $conn->{user});
            my $res;
            if (eval { $res = { ok => \1, payload => await Mojo::Promise->resolve($handler->($ctx, $msg->{payload})) }; 1 }) { }
            elsif (blessed $@ and $@->isa('BoardStreams::Hub::Duplicate')) {
                # Another copy of this message got there first.
                my $stored = await $self->_stored($msg_id);
                return $reply->(@$stored) if $stored;
                $res = $failure->('internal_error');
            }
            elsif (_is_rejection($@)) { $res = $failure->($@->reason, $@->data) }
            else {
                $log->error("BoardStreams: $kind handler '$name' on $channel died: $@");
                $res = $failure->('internal_error');
            }

            my $seq = $ctx->seq;
            if (defined $msg_id) {
                eval {
                    my $row = (await $self->_db->query_p(
                        'insert into bs_request (id, channel, seq, response) values (?, ?, ?, ?)
                         on conflict (id) do update set response = excluded.response returning seq',
                        $msg_id, $channel, $seq, { json => $res }))->hash;
                    $seq = $row->{seq} + 0;
                    1;
                } or $log->warn("BoardStreams: cannot record outcome of $msg_id: $@");
            }
            $reply->($res, $seq);
        })->();
    }

    # The recorded outcome of an already handled message, as [$response, $seq].
    # If the first copy changed the channel but its outcome was never
    # recorded (the process died in between), the best that can be said is
    # that it succeeded.
    method _stored ($msg_id) {
        return $self->_db->query_p('select seq, response::text as response from bs_request where id = ?', $msg_id)
            ->then(sub ($results) {
                my $row = $results->hash or return undef;
                my $res = defined $row->{response} ? from_json($row->{response}) : { ok => \1, payload => undef };
                return [$res, $row->{seq} + 0];
            });
    }

    sub _is_rejection ($err) { blessed $err and $err->isa('BoardStreams::Rejection') }
}

class BoardStreams::Hub::Duplicate { }

1;
