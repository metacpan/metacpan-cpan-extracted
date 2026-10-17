package Claude::Agent::Error::PermissionDenied;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Error;

BEGIN {
    Object::Proto::define('Claude::Agent::Error::PermissionDenied',
        extends => 'Claude::Agent::Error',
        'tool_name:Str:predicate',
        'tool_input:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Error::PermissionDenied - Permission denied exception

=head1 DESCRIPTION

Thrown when a tool permission is denied.
Stringifies as C<PermissionDenied: message>.

=head1 ATTRIBUTES

=head2 message

The error description. Required.

=head2 tool_name

Name of the tool that was denied. Optional; C<has_tool_name> reports whether it was given.

=head2 tool_input

Input that was provided to the tool. Optional; C<has_tool_input> reports whether it was given.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
