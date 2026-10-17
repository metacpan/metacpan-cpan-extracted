package Claude::Agent::Error::JSONDecodeError;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::JSONDecodeError',
        extends => 'Claude::Agent::Error',
        'line:Str:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::JSONDecodeError - JSON parsing exception

=head1 DESCRIPTION

Thrown when JSON parsing fails.
Stringifies as C<JSONDecodeError: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head2 line

The line that failed to parse. Optional; C<has_line> reports whether it was given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
