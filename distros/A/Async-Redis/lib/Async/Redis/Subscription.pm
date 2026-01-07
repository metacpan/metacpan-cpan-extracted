package Async::Redis::Subscription;

use strict;
use warnings;
use 5.018;

use Future;
use Future::AsyncAwait;

our $VERSION = '0.001';

sub new {
    my ($class, %args) = @_;

    return bless {
        redis            => $args{redis},
        channels         => {},      # channel => 1 (for regular subscribe)
        patterns         => {},      # pattern => 1 (for psubscribe)
        sharded_channels => {},      # channel => 1 (for ssubscribe)
        _message_queue   => [],      # Buffer for messages
        _waiters         => [],      # Futures waiting for messages
        _closed          => 0,
    }, $class;
}

# Track a channel subscription
sub _add_channel {
    my ($self, $channel) = @_;
    $self->{channels}{$channel} = 1;
}

sub _add_pattern {
    my ($self, $pattern) = @_;
    $self->{patterns}{$pattern} = 1;
}

sub _add_sharded_channel {
    my ($self, $channel) = @_;
    $self->{sharded_channels}{$channel} = 1;
}

sub _remove_channel {
    my ($self, $channel) = @_;
    delete $self->{channels}{$channel};
}

sub _remove_pattern {
    my ($self, $pattern) = @_;
    delete $self->{patterns}{$pattern};
}

sub _remove_sharded_channel {
    my ($self, $channel) = @_;
    delete $self->{sharded_channels}{$channel};
}

# List subscribed channels/patterns
sub channels { keys %{shift->{channels}} }
sub patterns { keys %{shift->{patterns}} }
sub sharded_channels { keys %{shift->{sharded_channels}} }

sub channel_count {
    my ($self) = @_;
    return scalar(keys %{$self->{channels}})
         + scalar(keys %{$self->{patterns}})
         + scalar(keys %{$self->{sharded_channels}});
}

# Receive next message (async iterator pattern)
async sub next {
    my ($self) = @_;

    # Check if subscription is closed
    return undef if $self->{_closed};

    # Return buffered message if available
    if (@{$self->{_message_queue}}) {
        return shift @{$self->{_message_queue}};
    }

    # Read directly from redis
    my $redis = $self->{redis};

    while (1) {
        my $frame = await $redis->_read_pubsub_frame();

        last unless $frame && ref $frame eq 'ARRAY';

        my $type = $frame->[0] // '';

        if ($type eq 'message') {
            return {
                type    => 'message',
                channel => $frame->[1],
                data    => $frame->[2],
            };
        }
        elsif ($type eq 'pmessage') {
            return {
                type    => 'pmessage',
                pattern => $frame->[1],
                channel => $frame->[2],
                data    => $frame->[3],
            };
        }
        elsif ($type eq 'smessage') {
            return {
                type    => 'smessage',
                channel => $frame->[1],
                data    => $frame->[2],
            };
        }
        elsif ($type =~ /^(un)?p?s?subscribe$/) {
            # Subscription confirmation - continue reading
            next;
        }
        else {
            # Unknown - continue
            next;
        }
    }

    return undef;
}

# Backward-compatible wrapper
async sub next_message {
    my ($self) = @_;
    my $msg = await $self->next();
    return undef unless $msg;

    # Convert new format to old format for compatibility
    return {
        channel => $msg->{channel},
        message => $msg->{data},
        pattern => $msg->{pattern},
        type    => $msg->{type},
    };
}

# Internal: called when message arrives
sub _deliver_message {
    my ($self, $msg) = @_;

    if (@{$self->{_waiters}}) {
        # Someone is waiting - deliver directly
        my $waiter = shift @{$self->{_waiters}};
        $waiter->done($msg);
    }
    else {
        # Buffer the message
        push @{$self->{_message_queue}}, $msg;
    }
}

# Unsubscribe from specific channels
async sub unsubscribe {
    my ($self, @channels) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@channels) {
        # Partial unsubscribe
        await $redis->_send_command('UNSUBSCRIBE', @channels);

        # Read confirmations
        for my $ch (@channels) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_channel($ch);
        }
    }
    else {
        # Full unsubscribe - all channels
        my @all_channels = $self->channels;

        if (@all_channels) {
            await $redis->_send_command('UNSUBSCRIBE');

            # Read all confirmations
            for my $ch (@all_channels) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_channel($ch);
            }
        }
    }

    # If no subscriptions remain, close and exit pubsub mode
    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Unsubscribe from patterns
async sub punsubscribe {
    my ($self, @patterns) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@patterns) {
        await $redis->_send_command('PUNSUBSCRIBE', @patterns);

        for my $p (@patterns) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_pattern($p);
        }
    }
    else {
        my @all_patterns = $self->patterns;

        if (@all_patterns) {
            await $redis->_send_command('PUNSUBSCRIBE');

            for my $p (@all_patterns) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_pattern($p);
            }
        }
    }

    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Unsubscribe from sharded channels
async sub sunsubscribe {
    my ($self, @channels) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@channels) {
        await $redis->_send_command('SUNSUBSCRIBE', @channels);

        for my $ch (@channels) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_sharded_channel($ch);
        }
    }
    else {
        my @all = $self->sharded_channels;

        if (@all) {
            await $redis->_send_command('SUNSUBSCRIBE');

            for my $ch (@all) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_sharded_channel($ch);
            }
        }
    }

    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Close subscription
sub _close {
    my ($self) = @_;

    $self->{_closed} = 1;
    $self->{redis}{in_pubsub} = 0;

    # Cancel any waiters
    for my $waiter (@{$self->{_waiters}}) {
        $waiter->done(undef) unless $waiter->is_ready;
    }
    $self->{_waiters} = [];
}

sub is_closed { shift->{_closed} }

# Get all subscriptions for reconnect replay
sub get_replay_commands {
    my ($self) = @_;

    my @commands;

    my @channels = $self->channels;
    push @commands, ['SUBSCRIBE', @channels] if @channels;

    my @patterns = $self->patterns;
    push @commands, ['PSUBSCRIBE', @patterns] if @patterns;

    my @sharded = $self->sharded_channels;
    push @commands, ['SSUBSCRIBE', @sharded] if @sharded;

    return @commands;
}

1;

__END__

=head1 NAME

Async::Redis::Subscription - PubSub subscription handler

=head1 SYNOPSIS

    my $sub = await $redis->subscribe('channel1', 'channel2');

    while (my $msg = await $sub->next) {
        say "Channel: $msg->{channel}";
        say "Data: $msg->{data}";
    }

    await $sub->unsubscribe('channel1');
    await $sub->unsubscribe;  # all remaining

=head1 DESCRIPTION

Manages Redis PubSub subscriptions with async iterator pattern.

=head1 MESSAGE STRUCTURE

    {
        type    => 'message',      # or 'pmessage', 'smessage'
        channel => 'channel_name',
        pattern => 'pattern',      # only for pmessage
        data    => 'payload',
    }

=cut
