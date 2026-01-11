package Claude::Agent::Permission::Context;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'session_id?' => Str,
    'cwd?'        => Str,
    'tool_name!'  => Str,
    'tool_input!';

=head1 NAME

Claude::Agent::Permission::Context - Permission context for Claude Agent SDK

=head1 DESCRIPTION

Context information passed to the can_use_tool callback.

=head2 ATTRIBUTES

=over 4

=item * session_id - Current session ID

=item * cwd - Current working directory

=item * tool_name - Name of the tool requesting permission

=item * tool_input - Input parameters for the tool

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
