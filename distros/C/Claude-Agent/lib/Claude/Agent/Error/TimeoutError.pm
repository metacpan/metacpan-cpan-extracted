package Claude::Agent::Error::TimeoutError;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::TimeoutError',
        extends => 'Claude::Agent::Error',
        'timeout_ms:Num:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::TimeoutError - Timeout exception

=head1 DESCRIPTION

Thrown when an operation times out.
Stringifies as C<TimeoutError: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head2 timeout_ms

Timeout value in milliseconds. Optional; C<has_timeout_ms> reports whether it was given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
