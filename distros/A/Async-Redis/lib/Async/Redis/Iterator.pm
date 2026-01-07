package Async::Redis::Iterator;

use strict;
use warnings;
use 5.018;

use Future::AsyncAwait;

sub new {
    my ($class, %args) = @_;

    return bless {
        redis   => $args{redis},
        command => $args{command} // 'SCAN',
        key     => $args{key},        # For HSCAN/SSCAN/ZSCAN
        match   => $args{match},
        count   => $args{count},
        type    => $args{type},       # For SCAN TYPE filter
        cursor  => 0,
        done    => 0,
    }, $class;
}

async sub next {
    my ($self) = @_;

    # Already exhausted
    return undef if $self->{done};

    my @args;

    # Build command args based on scan type
    if ($self->{command} eq 'SCAN') {
        @args = ($self->{cursor});
    }
    else {
        # HSCAN, SSCAN, ZSCAN take key first, then cursor
        @args = ($self->{key}, $self->{cursor});
    }

    # Add MATCH pattern if specified
    if (defined $self->{match}) {
        push @args, 'MATCH', $self->{match};
    }

    # Add COUNT hint if specified
    if (defined $self->{count}) {
        push @args, 'COUNT', $self->{count};
    }

    # Add TYPE filter for SCAN (Redis 6.0+)
    if ($self->{command} eq 'SCAN' && defined $self->{type}) {
        push @args, 'TYPE', $self->{type};
    }

    # Execute scan command
    my $result = await $self->{redis}->command($self->{command}, @args);

    # Result is [cursor, [elements...]]
    my ($new_cursor, $elements) = @$result;

    # Update cursor
    $self->{cursor} = $new_cursor;

    # Check if iteration complete (cursor returned to 0)
    if ($new_cursor eq '0' || $new_cursor == 0) {
        $self->{done} = 1;
    }

    # Return batch (may be empty)
    # Return undef only when done AND no elements in final batch
    return $elements && @$elements ? $elements : ($self->{done} ? undef : []);
}

sub reset {
    my ($self) = @_;
    $self->{cursor} = 0;
    $self->{done} = 0;
}

sub cursor { shift->{cursor} }
sub done   { shift->{done} }

1;

__END__

=head1 NAME

Async::Redis::Iterator - Cursor-based SCAN iterator

=head1 SYNOPSIS

    my $iter = $redis->scan_iter(match => 'user:*', count => 100);

    while (my $batch = await $iter->next) {
        for my $key (@$batch) {
            say $key;
        }
    }

=head1 DESCRIPTION

Iterator provides async cursor-based iteration over Redis SCAN commands:

- SCAN: Iterate all keys
- HSCAN: Iterate hash fields
- SSCAN: Iterate set members
- ZSCAN: Iterate sorted set members with scores

=head2 Behavior

- Returns batches of elements, not individual items
- Cursor managed internally
- C<next> returns undef when iteration complete
- Safe during key modifications (may see duplicates or miss keys)
- C<count> is a hint, not a guarantee

=cut
