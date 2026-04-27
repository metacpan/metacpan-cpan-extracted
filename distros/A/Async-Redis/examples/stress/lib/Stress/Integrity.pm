package Stress::Integrity;
use strict;
use warnings;
use Time::HiRes qw(time);

sub new {
    my ($class) = @_;
    return bless {
        kv_last                  => {},
        pubsub_last              => {},
        chaos_window_until       => 0,
        violations               => [],
        pattern_published        => {},
        pattern_received         => {},
        pattern_published_chaos  => {},
        queue_pushed             => 0,
        queue_popped             => 0,
    }, $class;
}

sub enter_chaos_window {
    my ($self, $secs) = @_;
    my $end = time + $secs;
    $self->{chaos_window_until} = $end if $end > $self->{chaos_window_until};
    return;
}

sub in_chaos_window {
    my ($self) = @_;
    return time < $self->{chaos_window_until};
}

sub note_kv_observation {
    my ($self, $bucket, $seq) = @_;
    my $prev = $self->{kv_last}{$bucket};
    if (defined $prev && $seq < $prev) {
        $self->_record('kv_seq_regression', { bucket => $bucket, prev => $prev, got => $seq });
        return;
    }
    $self->{kv_last}{$bucket} = $seq;
    return;
}

sub note_pubsub_observation {
    my ($self, $channel, $seq) = @_;
    my $prev = $self->{pubsub_last}{$channel};
    if (defined $prev && $seq < $prev) {
        $self->_record('pubsub_seq_regression', { channel => $channel, prev => $prev, got => $seq });
        return;
    }
    $self->{pubsub_last}{$channel} = $seq;
    return;
}

sub note_pattern_published {
    my ($self, $msg_id) = @_;
    if ($self->in_chaos_window) {
        $self->{pattern_published_chaos}{$msg_id} = 1;
    } else {
        $self->{pattern_published}{$msg_id} = 1;
    }
    return;
}

sub note_pattern_received {
    my ($self, $msg_id) = @_;
    $self->{pattern_received}{$msg_id} = 1;
    return;
}

sub note_queue_pushed { $_[0]->{queue_pushed}++; return; }

sub note_queue_popped {
    my ($self) = @_;
    $self->{queue_popped}++;
    if ($self->{queue_popped} > $self->{queue_pushed}) {
        $self->_record('queue_conservation', {
            pushed => $self->{queue_pushed},
            popped => $self->{queue_popped},
        });
    }
    return;
}

sub _record {
    my ($self, $type, $detail) = @_;
    push @{ $self->{violations} }, {
        type   => $type,
        detail => $detail,
        t      => time,
    };
    return;
}

sub violations { return @{ $_[0]->{violations} } }

sub snapshot {
    my ($self) = @_;
    my %by_type;
    $by_type{ $_->{type} }++ for @{ $self->{violations} };

    my $drops_outside = 0;
    for my $id (keys %{ $self->{pattern_published} }) {
        $drops_outside++ unless $self->{pattern_received}{$id};
    }

    return {
        kv_seq_regressions             => $by_type{kv_seq_regression}     // 0,
        pubsub_seq_regressions         => $by_type{pubsub_seq_regression} // 0,
        queue_conservation_violations  => $by_type{queue_conservation}    // 0,
        pattern_drops_outside_chaos    => $drops_outside,
        queue_pushed                   => $self->{queue_pushed},
        queue_popped                   => $self->{queue_popped},
    };
}

1;
