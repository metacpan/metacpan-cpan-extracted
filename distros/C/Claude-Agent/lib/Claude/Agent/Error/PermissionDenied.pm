package Claude::Agent::Error::PermissionDenied;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Error',
    'tool_name?' => Str,
    'tool_input?';

=head1 NAME

Claude::Agent::Error::PermissionDenied - Permission denied exception

=head1 DESCRIPTION

Thrown when a tool permission is denied.

=head2 ATTRIBUTES

=over 4

=item * message - Error description

=item * tool_name - Name of the tool that was denied

=item * tool_input - Input that was provided to the tool

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
