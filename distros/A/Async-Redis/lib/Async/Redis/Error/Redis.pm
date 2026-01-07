package Async::Redis::Error::Redis;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

use parent 'Async::Redis::Error';

sub type { shift->{type} }

# Parse error type from Redis error message
# Redis errors are formatted as: "ERRORTYPE message text"
sub from_message {
    my ($class, $message) = @_;

    my $type = 'ERR';  # default
    if ($message =~ /^([A-Z]+)\s/) {
        $type = $1;
    }

    return $class->new(
        message => $message,
        type    => $type,
    );
}

# Predicate methods for common error types
sub is_wrongtype { uc(shift->{type} // '') eq 'WRONGTYPE' }
sub is_oom       { uc(shift->{type} // '') eq 'OOM' }
sub is_busy      { uc(shift->{type} // '') eq 'BUSY' }
sub is_noscript  { uc(shift->{type} // '') eq 'NOSCRIPT' }
sub is_readonly  { uc(shift->{type} // '') eq 'READONLY' }
sub is_loading   { uc(shift->{type} // '') eq 'LOADING' }
sub is_noauth    { uc(shift->{type} // '') eq 'NOAUTH' }
sub is_noperm    { uc(shift->{type} // '') eq 'NOPERM' }

# Fatal errors should not be retried
sub is_fatal {
    my $self = shift;
    my $type = uc($self->{type} // '');

    # These are deterministic failures - retrying won't help
    return 1 if $type =~ /^(WRONGTYPE|OOM|NOSCRIPT|NOAUTH|NOPERM|ERR)$/;

    return 0;
}

# Transient errors may succeed on retry
sub is_transient {
    my $self = shift;
    my $type = uc($self->{type} // '');

    # These may succeed if retried after a delay
    return 1 if $type =~ /^(BUSY|LOADING|READONLY|CLUSTERDOWN)$/;

    return 0;
}

1;

__END__

=head1 NAME

Async::Redis::Error::Redis - Redis server error exception

=head1 DESCRIPTION

Thrown when Redis returns an error response (RESP type '-').

=head1 METHODS

=head2 from_message($message)

Class method to create error from Redis error message, parsing
the error type from the message prefix.

    my $error = Async::Redis::Error::Redis->from_message(
        'WRONGTYPE Operation against key holding wrong type'
    );
    say $error->type;  # 'WRONGTYPE'

=head2 Predicates

=over 4

=item is_wrongtype - Key holds wrong type for operation

=item is_oom - Out of memory

=item is_busy - Server busy (Lua script running)

=item is_noscript - Script SHA not found

=item is_readonly - Write on read-only replica

=item is_loading - Server still loading dataset

=item is_noauth - Authentication required

=item is_noperm - ACL permission denied

=item is_fatal - Error is deterministic, retry won't help

=item is_transient - Error may succeed on retry

=back

=cut
