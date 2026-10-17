package Claude::Agent::Error::CLINotFound;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::CLINotFound',
        extends => 'Claude::Agent::Error',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::CLINotFound - CLI not found exception

=head1 DESCRIPTION

Thrown when the Claude CLI executable cannot be found.
Stringifies as C<CLINotFound: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
