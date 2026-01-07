package ChatApp::WebSocket;

#
# WebSocket Chat Handler - Redis-backed version
#
# Adapted from PAGI's websocket-chat-v2 to use Redis for state,
# enabling multi-worker deployments.
#

use strict;
use warnings;
use Future::AsyncAwait;
use URI::Escape qw(uri_unescape);
use PAGI::WebSocket;

use ChatApp::State qw(
    get_session create_session update_session
    get_session_by_name set_session_connected set_session_disconnected
    get_room add_room get_all_rooms
    add_user_to_room remove_user_from_room get_room_users
    add_message get_room_messages get_stats
    sanitize_username sanitize_room_name
    register_local_session unregister_local_session
    broadcast_to_room broadcast_global add_local_room
    add_background_task
);

sub handler {
    return async sub {
        my ($scope, $receive, $send) = @_;

        my $ws = PAGI::WebSocket->new($scope, $receive, $send);

        # Extract session info from query string
        my $qs = $scope->{query_string} // '';
        my ($session_id) = $qs =~ /(?:^|&)session=([^&]*)/;
        my ($raw_name)   = $qs =~ /(?:^|&)name=([^&]*)/;
        my ($last_msg_id) = $qs =~ /(?:^|&)lastMsgId=(\d+)/;

        $session_id  = uri_unescape($session_id // '');
        $raw_name    = uri_unescape($raw_name // '');
        $last_msg_id = int($last_msg_id // 0);

        await $ws->accept;

        # Check for existing session (reconnection)
        my $session = $session_id ? await get_session($session_id) : undef;

        if ($session) {
            # Resume existing session
            await set_session_connected($session_id, sub { $ws->send_json($_[0]) });

            my @rooms = keys %{$session->{rooms}};
            my $current_room = $rooms[0] // 'general';

            # Get users for the current room
            my $users = await get_room_users($current_room);

            await $ws->send_json({
                type       => 'resumed',
                session_id => $session_id,
                name       => $session->{name},
                rooms      => \@rooms,
                users      => $users,
                current_room => $current_room,
            });

            # Re-register local room membership
            for my $room (@rooms) {
                add_local_room($session_id, $room);
            }
        }
        else {
            # New session
            my $username = sanitize_username($raw_name || 'Anonymous');
            $session_id ||= ChatApp::State::generate_id();

            $session = await create_session($session_id, $username, sub { $ws->send_json($_[0]) });

            my $rooms = await get_all_rooms();

            await $ws->send_json({
                type       => 'connected',
                session_id => $session_id,
                name       => $username,
                rooms      => [sort keys %$rooms],
            });

            # Auto-join general room
            await _join_room($ws, $session_id, 'general');
        }

        # Send initial stats
        await _send_stats($ws);

        # Handle disconnect
        $ws->on_close(sub {
            my ($code, $reason) = @_;

            # Handle disconnect in a single background task to ensure proper ordering
            add_background_task(
                (async sub {
                    my $sess = await get_session($session_id);
                    return unless $sess;

                    # First, leave all rooms and broadcast to each
                    for my $room_name (keys %{$sess->{rooms}}) {
                        # Remove from room FIRST (updates Redis)
                        await remove_user_from_room($session_id, $room_name, 1);

                        # Get updated user list (without the leaving user)
                        my $users = await get_room_users($room_name);

                        # Broadcast to remaining users in the room
                        await broadcast_to_room($room_name, {
                            type  => 'user_left',
                            room  => $room_name,
                            user  => $sess->{name},
                            users => $users,
                        }, $session_id);
                    }

                    # Then mark session as disconnected
                    await set_session_disconnected($session_id);
                })->(),
                "disconnect and broadcast leave for $session_id"
            );
        });

        # Message loop
        await $ws->each_json(async sub {
            my ($msg) = @_;
            await _handle_message($ws, $session_id, $msg);
        });
    };
}

async sub _handle_message {
    my ($ws, $session_id, $msg) = @_;

    my $session = await get_session($session_id);
    return unless $session;

    my $type = $msg->{type} // 'message';

    if ($type eq 'message') {
        await _handle_chat_message($ws, $session_id, $msg);
    }
    elsif ($type eq 'join') {
        await _join_room($ws, $session_id, $msg->{room});
    }
    elsif ($type eq 'leave') {
        await _leave_room($ws, $session_id, $msg->{room});
    }
    elsif ($type eq 'pm') {
        await _handle_private_message($ws, $session_id, $msg);
    }
    elsif ($type eq 'get_rooms') {
        await _send_room_list($ws);
    }
    elsif ($type eq 'get_users') {
        await _send_user_list($ws, $msg->{room});
    }
    elsif ($type eq 'get_history') {
        await _send_history($ws, $msg->{room});
    }
    elsif ($type eq 'ping') {
        await update_session($session_id, { last_seen => time() });
        await $ws->send_json({ type => 'pong', ts => $msg->{ts} });
    }
    elsif ($type eq 'typing') {
        await _handle_typing($ws, $session_id, $msg);
    }
}

async sub _handle_chat_message {
    my ($ws, $session_id, $msg) = @_;

    my $session = await get_session($session_id) or return;
    my $room_name = $msg->{room} // 'general';
    my $text = $msg->{text} // '';

    unless ($session->{rooms}{$room_name}) {
        return await $ws->send_json({
            type    => 'error',
            message => "You are not in room: $room_name",
        });
    }

    # Handle slash commands
    if ($text =~ m{^/(\w+)(?:\s+(.*))?$}) {
        return await _handle_command($ws, $session_id, $1, $2, $room_name);
    }

    return unless length $text;

    my $stored = await add_message($room_name, $session->{name}, $text, 'message');

    await broadcast_to_room($room_name, {
        type => 'message',
        room => $room_name,
        from => $session->{name},
        text => $text,
        ts   => $stored->{ts},
        id   => $stored->{id},
    });
}

async sub _handle_command {
    my ($ws, $session_id, $cmd, $args, $room_name) = @_;

    my $session = await get_session($session_id) or return;
    $args //= '';

    if ($cmd eq 'help') {
        await $ws->send_json({
            type => 'system',
            room => $room_name,
            text => "Available commands:\n" .
                "/help - Show this help\n" .
                "/rooms - List all rooms\n" .
                "/users - List users in current room\n" .
                "/join <room> - Join or create a room\n" .
                "/leave - Leave current room\n" .
                "/pm <user> <message> - Send private message\n" .
                "/me <action> - Send action message\n",
        });
    }
    elsif ($cmd eq 'rooms') {
        await _send_room_list($ws);
    }
    elsif ($cmd eq 'users') {
        await _send_user_list($ws, $room_name);
    }
    elsif ($cmd eq 'join' && $args) {
        my $new_room = sanitize_room_name($args);
        await _join_room($ws, $session_id, $new_room);
    }
    elsif ($cmd eq 'leave') {
        await _leave_room($ws, $session_id, $room_name);
    }
    elsif ($cmd eq 'pm' && $args =~ /^(\S+)\s+(.+)$/) {
        await _handle_private_message($ws, $session_id, { to => $1, text => $2 });
    }
    elsif ($cmd eq 'me' && $args) {
        my $action_text = "* $session->{name} $args";
        my $stored = await add_message($room_name, $session->{name}, $action_text, 'action');
        await broadcast_to_room($room_name, {
            type => 'action',
            room => $room_name,
            from => $session->{name},
            text => $action_text,
            ts   => $stored->{ts},
            id   => $stored->{id},
        });
    }
    else {
        await $ws->send_json({
            type    => 'error',
            message => "Unknown command: /$cmd. Type /help for available commands.",
        });
    }
}

async sub _join_room {
    my ($ws, $session_id, $room_name) = @_;

    my $session = await get_session($session_id) or return;
    $room_name = sanitize_room_name($room_name);

    if ($session->{rooms}{$room_name}) {
        return await $ws->send_json({
            type    => 'error',
            message => "You are already in room: $room_name",
        });
    }

    await add_user_to_room($session_id, $room_name);

    my $history = await get_room_messages($room_name, 50);
    my $users = await get_room_users($room_name);

    await $ws->send_json({
        type    => 'joined',
        room    => $room_name,
        history => $history,
        users   => $users,
    });

    await broadcast_to_room($room_name, {
        type  => 'user_joined',
        room  => $room_name,
        user  => $session->{name},
        users => $users,
    }, $session_id);

    # Broadcast updated stats to all users
    await _broadcast_stats();
}

async sub _leave_room {
    my ($ws, $session_id, $room_name) = @_;

    my $session = await get_session($session_id) or return;

    if ($room_name eq 'general') {
        return await $ws->send_json({
            type    => 'error',
            message => "You cannot leave the general room",
        });
    }

    unless ($session->{rooms}{$room_name}) {
        return await $ws->send_json({
            type    => 'error',
            message => "You are not in room: $room_name",
        });
    }

    await remove_user_from_room($session_id, $room_name);

    await $ws->send_json({
        type => 'left',
        room => $room_name,
    });

    my $users = await get_room_users($room_name);
    await broadcast_to_room($room_name, {
        type  => 'user_left',
        room  => $room_name,
        user  => $session->{name},
        users => $users,
    });

    # Broadcast updated stats to all users
    await _broadcast_stats();
}

async sub _handle_typing {
    my ($ws, $session_id, $msg) = @_;

    my $session = await get_session($session_id) or return;
    my $room_name = $msg->{room} // 'general';
    my $is_typing = $msg->{typing} ? 1 : 0;

    # Only broadcast if user is in the room
    return unless $session->{rooms}{$room_name};

    await broadcast_to_room($room_name, {
        type   => 'typing',
        room   => $room_name,
        user   => $session->{name},
        typing => $is_typing,
    }, $session_id);
}

async sub _handle_private_message {
    my ($ws, $session_id, $msg) = @_;

    my $session = await get_session($session_id) or return;
    my $to_name = $msg->{to} // '';
    my $text = $msg->{text} // '';

    return unless length $to_name && length $text;

    my $target = await get_session_by_name($to_name);

    unless ($target) {
        return await $ws->send_json({
            type    => 'error',
            message => "User not found: $to_name",
        });
    }

    # For PMs, we need to send directly to the target's worker
    # This is a simplification - in production you'd use Redis PubSub per-user
    # For now, broadcast on a special PM channel
    await broadcast_to_room("_pm:$target->{id}", {
        type => 'pm',
        from => $session->{name},
        text => $text,
        ts   => time(),
    });

    await $ws->send_json({
        type => 'pm_sent',
        to   => $to_name,
        text => $text,
        ts   => time(),
    });
}

async sub _send_room_list {
    my ($ws) = @_;

    my $rooms = await get_all_rooms();
    await $ws->send_json({
        type  => 'room_list',
        rooms => [
            map {
                { name => $_, users => scalar(keys %{$rooms->{$_}{users}}) }
            }
            sort keys %$rooms
        ],
    });
}

async sub _send_user_list {
    my ($ws, $room_name) = @_;

    my $users = await get_room_users($room_name);
    await $ws->send_json({
        type  => 'user_list',
        room  => $room_name,
        users => $users,
    });
}

async sub _send_history {
    my ($ws, $room_name) = @_;

    my $messages = await get_room_messages($room_name, 100);
    await $ws->send_json({
        type     => 'history',
        room     => $room_name,
        messages => $messages,
    });
}

async sub _send_stats {
    my ($ws) = @_;

    my $stats = await get_stats();
    await $ws->send_json({
        type         => 'stats',
        users_online => $stats->{users_online},
        rooms_count  => $stats->{rooms_count},
        uptime       => $stats->{uptime},
    });
}

async sub _broadcast_stats {
    my $stats = await get_stats();
    await broadcast_global({
        type         => 'stats',
        users_online => $stats->{users_online},
        rooms_count  => $stats->{rooms_count},
        uptime       => $stats->{uptime},
    });
}

1;

__END__

=head1 NAME

ChatApp::WebSocket - Redis-backed WebSocket chat handler

=head1 DESCRIPTION

Handles WebSocket chat with Redis-backed state and PubSub broadcasting.
Enables multi-worker deployments.

=cut
