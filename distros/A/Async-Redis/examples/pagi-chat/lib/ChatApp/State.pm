package ChatApp::State;

#
# Redis-backed State Management
#
# This replaces the in-memory state from PAGI's websocket-chat-v2 example
# with Redis, enabling multi-worker deployments.
#
# Key differences:
# - Sessions stored in Redis hashes
# - Room membership in Redis sets
# - Messages in Redis lists
# - PubSub for cross-worker broadcasting
#

use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use Future::Selector;
use Exporter 'import';
use JSON::MaybeXS;
use Time::HiRes qw(time);
use Scalar::Util qw(weaken);
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

our @EXPORT_OK = qw(
    init_redis get_redis get_pubsub
    get_session create_session update_session remove_session
    get_session_by_name set_session_connected set_session_disconnected
    is_session_connected
    get_room add_room remove_room get_all_rooms
    add_user_to_room remove_user_from_room get_room_users
    add_message get_room_messages
    get_stats generate_id sanitize_username sanitize_room_name
    subscribe_broadcasts register_local_session unregister_local_session
    broadcast_to_room broadcast_global add_local_room
    add_background_task
);

my $JSON = JSON::MaybeXS->new->utf8->canonical;

# Redis connections (per-worker)
my $redis;
my $pubsub;
my $pubsub_subscription;

# Background task selector (per-worker)
my $background_selector;

# Local session callbacks (for this worker only)
# Redis PubSub delivers to all workers, but we only call callbacks for OUR clients
my %local_sessions;

use constant {
    MAX_MESSAGES_PER_ROOM => 100,
    SESSION_TTL           => 86400,    # 24 hours
    BROADCAST_CHANNEL     => 'chat:broadcast',
};

# Track server start time for uptime
my $server_start_time = time();

# Initialize Redis connections for this worker
async sub init_redis {
    my (%args) = @_;

    require Async::Redis;

    my $host = $args{host} // $ENV{REDIS_HOST} // 'localhost';
    my $port = $args{port} // $ENV{REDIS_PORT} // 6379;

    # Main connection for commands
    $redis = Async::Redis->new(host => $host, port => $port);
    await $redis->connect;

    # Separate connection for PubSub
    my $pubsub_redis = Async::Redis->new(host => $host, port => $port);
    await $pubsub_redis->connect;
    $pubsub = await $pubsub_redis->subscribe(BROADCAST_CHANNEL);

    # Initialize background task selector and start the runner
    $background_selector = Future::Selector->new;
    _start_selector_runner();

    # Start periodic stats timer (every 10 seconds)
    _start_stats_timer();

    # Initialize default rooms
    await add_room('general', 'system');
    await add_room('random', 'system');
    await add_room('help', 'system');

    print STDERR "Worker $$: Redis state initialized\n";
    return $redis;
}

sub get_redis { $redis }
sub get_pubsub { $pubsub }

# Background selector runner
my $selector_runner_future;

# Periodic stats timer
my $stats_timer;

# Start the selector with the PubSub listener as the main long-running task
sub _start_selector_runner {
    # Add the broadcast listener as a long-running task
    # Use gen => to provide a generator that creates the future
    # (f => expects a completed future, gen => expects a coderef)
    $background_selector->add(
        data => 'pubsub-listener',
        gen  => sub { _broadcast_listener() },
    );

    # Run the selector in the background
    $selector_runner_future = $background_selector->run->on_fail(sub {
        my ($err) = @_;
        warn "[selector] Runner failed: $err";
    })->retain;
}

# Start periodic stats timer using IO::Async
sub _start_stats_timer {
    my $loop = IO::Async::Loop->new;

    $stats_timer = IO::Async::Timer::Periodic->new(
        interval => 10,  # Send stats every 10 seconds
        on_tick  => sub {
            return unless %local_sessions;  # Skip if no clients
            # Chain async operations: get_stats -> broadcast
            # Retain the Future to keep it alive
            get_stats()->then(sub {
                my ($stats) = @_;
                my $msg = $JSON->encode({
                    global  => 1,
                    payload => {
                        type         => 'stats',
                        users_online => $stats->{users_online},
                        rooms_count  => $stats->{rooms_count},
                        uptime       => $stats->{uptime},
                    },
                });
                return $redis->publish(BROADCAST_CHANNEL, $msg);
            })->on_fail(sub {
                my ($err) = @_;
                warn "[stats] Timer error: $err";
            })->retain;
        },
    );

    $loop->add($stats_timer);
    $stats_timer->start;
}

# Add a fire-and-forget background task to the selector
# Pass a coderef that returns a future, not the future itself
sub add_background_task {
    my ($gen, $description) = @_;
    $description //= 'background task';

    return unless $background_selector;

    # gen => expects a coderef that generates futures
    # It will be called once, and again if the future completes (until it returns undef)
    my $called = 0;
    $background_selector->add(
        data => $description,
        gen  => sub {
            return undef if $called++;  # One-shot: only generate once
            return ref($gen) eq 'CODE' ? $gen->() : $gen;
        },
    );
}

# Long-running broadcast listener (async sub with while loop)
async sub _broadcast_listener {
    print STDERR "[pubsub] Worker $$: Broadcast listener started\n";

    while (my $msg = await $pubsub->next_message) {
        next unless $msg->{type} eq 'message';

        my $data = eval { $JSON->decode($msg->{message}) };
        next unless $data;

        my $payload = $data->{payload};

        # Global broadcast - deliver to ALL local sessions
        if ($data->{global}) {
            for my $session_id (keys %local_sessions) {
                my $local = $local_sessions{$session_id};
                next unless $local && $local->{send_cb};

                eval { $local->{send_cb}->($payload) };
                warn "[pubsub] Worker $$: send_cb error: $@" if $@;
            }
        }
        # Room broadcast - deliver to local sessions in this room
        else {
            my $room_name = $data->{room};
            my $exclude_id = $data->{exclude_id};

            for my $session_id (keys %local_sessions) {
                next if defined $exclude_id && $session_id eq $exclude_id;

                my $local = $local_sessions{$session_id};
                next unless $local && $local->{rooms}{$room_name} && $local->{send_cb};

                eval { $local->{send_cb}->($payload) };
                warn "[pubsub] Worker $$: send_cb error: $@" if $@;
            }
        }
    }
}

# Register a local session (called when client connects to THIS worker)
sub register_local_session {
    my ($session_id, $send_cb) = @_;
    $local_sessions{$session_id} = {
        send_cb => $send_cb,
        rooms   => {},
    };
}

# Track room membership locally
sub add_local_room {
    my ($session_id, $room_name) = @_;
    $local_sessions{$session_id}{rooms}{$room_name} = 1 if $local_sessions{$session_id};
}

sub remove_local_room {
    my ($session_id, $room_name) = @_;
    delete $local_sessions{$session_id}{rooms}{$room_name} if $local_sessions{$session_id};
}

sub unregister_local_session {
    my ($session_id) = @_;
    delete $local_sessions{$session_id};
}

# Broadcast to room via Redis PubSub (reaches all workers)
async sub broadcast_to_room {
    my ($room_name, $payload, $exclude_id) = @_;

    my $msg = $JSON->encode({
        room       => $room_name,
        exclude_id => $exclude_id,
        payload    => $payload,
    });

    await $redis->publish(BROADCAST_CHANNEL, $msg);
}

# Broadcast to all connected users globally via Redis PubSub
async sub broadcast_global {
    my ($payload) = @_;

    my $msg = $JSON->encode({
        global     => 1,
        payload    => $payload,
    });

    await $redis->publish(BROADCAST_CHANNEL, $msg);
}

sub generate_id {
    require Digest::SHA;
    return Digest::SHA::sha256_hex(time() . $$ . rand());
}

sub sanitize_username {
    my ($name) = @_;
    $name //= '';
    $name =~ s/[^\w]/_/g;
    $name = substr($name, 0, 20);
    $name = 'User' . int(rand(1000)) if length($name) < 2;
    return $name;
}

sub sanitize_room_name {
    my ($name) = @_;
    $name //= '';
    $name =~ s/[^\w-]/_/g;
    $name = lc(substr($name, 0, 30));
    $name = 'room' . int(rand(1000)) if length($name) < 2;
    return $name;
}

# Session management (Redis hashes)
async sub get_session {
    my ($session_id) = @_;
    return unless $session_id;

    my $data = await $redis->hgetall("session:$session_id");
    return unless $data && %$data;

    # Deserialize rooms
    $data->{rooms} = $data->{rooms} ? $JSON->decode($data->{rooms}) : {};
    $data->{connected} = $data->{connected} ? 1 : 0;

    return $data;
}

async sub get_session_by_name {
    my ($name) = @_;

    # Scan for session with this name (not efficient, but works for demo)
    my $cursor = "0";
    do {
        my $result = await $redis->scan($cursor, MATCH => 'session:*', COUNT => 100);
        $cursor = $result->[0];
        my $keys = $result->[1] // [];

        for my $key (@$keys) {
            my $session = await $redis->hgetall($key);
            if ($session && $session->{name} eq $name && $session->{connected}) {
                $session->{rooms} = $session->{rooms} ? $JSON->decode($session->{rooms}) : {};
                return $session;
            }
        }
    } while ($cursor && $cursor ne "0");

    return;
}

async sub create_session {
    my ($session_id, $name, $send_cb) = @_;

    my $session = {
        id        => $session_id,
        name      => $name,
        connected => 1,
        joined_at => time(),
        last_seen => time(),
        rooms     => {},
    };

    await $redis->hmset("session:$session_id",
        id        => $session_id,
        name      => $name,
        connected => 1,
        joined_at => $session->{joined_at},
        last_seen => $session->{last_seen},
        rooms     => '{}',
    );
    await $redis->expire("session:$session_id", SESSION_TTL);
    await $redis->sadd('connected:sessions', $session_id);

    # Track locally for this worker
    register_local_session($session_id, $send_cb);

    return $session;
}

async sub update_session {
    my ($session_id, $updates) = @_;

    my @args;
    for my $key (keys %$updates) {
        my $val = $updates->{$key};
        $val = $JSON->encode($val) if ref $val;
        push @args, $key, $val;
    }

    await $redis->hmset("session:$session_id", @args) if @args;
    await $redis->expire("session:$session_id", SESSION_TTL);
}

async sub set_session_connected {
    my ($session_id, $send_cb) = @_;

    await update_session($session_id, { connected => 1, last_seen => time() });
    await $redis->sadd('connected:sessions', $session_id);
    register_local_session($session_id, $send_cb);

    return await get_session($session_id);
}

async sub set_session_disconnected {
    my ($session_id) = @_;

    await update_session($session_id, { connected => 0 });
    await $redis->srem('connected:sessions', $session_id);
    unregister_local_session($session_id);
}

async sub is_session_connected {
    my ($session_id) = @_;
    my $connected = await $redis->hget("session:$session_id", 'connected');
    return $connected ? 1 : 0;
}

async sub remove_session {
    my ($session_id) = @_;

    my $session = await get_session($session_id);
    return unless $session;

    # Leave all rooms
    for my $room_name (keys %{$session->{rooms}}) {
        await remove_user_from_room($session_id, $room_name, 1);
    }

    await $redis->del("session:$session_id");
    await $redis->srem('connected:sessions', $session_id);
    unregister_local_session($session_id);

    return $session;
}

# Room management
async sub get_room {
    my ($name) = @_;

    my $exists = await $redis->exists("room:$name");
    return unless $exists;

    my $data = await $redis->hgetall("room:$name:meta");
    return {
        name       => $name,
        created_at => $data->{created_at} // time(),
        created_by => $data->{created_by} // 'system',
    };
}

async sub add_room {
    my ($name, $created_by) = @_;
    $created_by //= 'system';

    my $exists = await $redis->exists("room:$name");
    return if $exists;

    await $redis->hmset("room:$name:meta",
        name       => $name,
        created_at => time(),
        created_by => $created_by,
    );
    await $redis->sadd("rooms", $name);

    return { name => $name, created_by => $created_by };
}

async sub remove_room {
    my ($name) = @_;
    return if $name eq 'general';  # Can't delete general

    await $redis->del("room:$name:meta", "room:$name:users", "room:$name:messages");
    await $redis->srem("rooms", $name);
}

async sub get_all_rooms {
    my $names = await $redis->smembers("rooms");
    my %rooms;

    # Defensive: ensure $names is an array ref
    return \%rooms unless $names && ref($names) eq 'ARRAY';

    for my $name (@$names) {
        my $members = await $redis->smembers("room:$name:users");
        $members = [] unless $members && ref($members) eq 'ARRAY';
        $rooms{$name} = {
            name  => $name,
            users => { map { $_ => 1 } @$members },
        };
    }

    return \%rooms;
}

async sub add_user_to_room {
    my ($session_id, $room_name) = @_;

    # Ensure room exists
    await add_room($room_name);

    # Add to room's user set
    await $redis->sadd("room:$room_name:users", $session_id);

    # Update session's room list
    my $session = await get_session($session_id);
    if ($session) {
        $session->{rooms}{$room_name} = 1;
        await update_session($session_id, { rooms => $session->{rooms} });
        add_local_room($session_id, $room_name);
    }

    # Note: join messages are broadcast in real-time via WebSocket, not stored
}

async sub remove_user_from_room {
    my ($session_id, $room_name, $silent) = @_;

    my $session = await get_session($session_id);

    await $redis->srem("room:$room_name:users", $session_id);

    if ($session) {
        delete $session->{rooms}{$room_name};
        await update_session($session_id, { rooms => $session->{rooms} });
        remove_local_room($session_id, $room_name);
        # Note: leave messages are broadcast in real-time via WebSocket, not stored
    }

    # Clean up empty non-default rooms
    my $count = await $redis->scard("room:$room_name:users");
    if ($count == 0 && $room_name !~ /^(general|random|help)$/) {
        await remove_room($room_name);
    }
}

async sub get_room_users {
    my ($room_name) = @_;

    my $user_ids = await $redis->smembers("room:$room_name:users");
    my @users;

    # Defensive: ensure $user_ids is an array ref
    return \@users unless $user_ids && ref($user_ids) eq 'ARRAY';

    for my $session_id (@$user_ids) {
        my $session = await get_session($session_id);
        next unless $session && $session->{connected};
        push @users, {
            id   => $session_id,
            name => $session->{name},
        };
    }

    return \@users;
}

# Message storage
async sub add_message {
    my ($room_name, $from, $text, $type) = @_;
    $type //= 'message';

    my $msg_id = await $redis->incr("room:$room_name:msg_counter");

    my $msg = {
        id   => $msg_id,
        from => $from,
        text => $text,
        type => $type,
        ts   => time(),
    };

    await $redis->rpush("room:$room_name:messages", $JSON->encode($msg));
    await $redis->ltrim("room:$room_name:messages", -MAX_MESSAGES_PER_ROOM, -1);

    return $msg;
}

async sub get_room_messages {
    my ($room_name, $limit) = @_;
    $limit //= 50;

    my $messages = await $redis->lrange("room:$room_name:messages", -$limit, -1);
    return [ map { $JSON->decode($_) } @$messages ];
}

async sub get_stats {
    # Count connected sessions using dedicated SET (fast O(1))
    my $online = await $redis->scard('connected:sessions') // 0;

    # Count rooms
    my $rooms_count = await $redis->scard('rooms') // 0;

    return {
        users_online => $online,
        rooms_count  => $rooms_count,
        uptime       => int(time() - $server_start_time),
    };
}

1;

__END__

=head1 NAME

ChatApp::State - Redis-backed state for multi-worker chat

=head1 DESCRIPTION

Replaces in-memory state with Redis, enabling the chat to run across
multiple worker processes. Uses Redis PubSub for real-time broadcasting.

=cut
