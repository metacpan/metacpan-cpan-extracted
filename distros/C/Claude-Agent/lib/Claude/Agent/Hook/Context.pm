package Claude::Agent::Hook::Context;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'session_id?' => Str,
    'cwd?'        => Str,
    'tool_name?'  => Str,
    'tool_input?';

=head1 NAME

Claude::Agent::Hook::Context - Hook context for Claude Agent SDK

=head1 DESCRIPTION

Context information passed to hook callbacks.

=head2 ATTRIBUTES

=over 4

=item * session_id - Current session ID

=item * cwd - Current working directory

=item * tool_name - Name of the tool being called

=item * tool_input - Input parameters for the tool

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
