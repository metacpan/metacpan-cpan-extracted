package Claude::Agent::Message::Base;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'type!'     => Str,
    'uuid?'     => Str,
    'session_id?',
    'parent_tool_use_id?',
    'request_id?' => Str,    # For permission/hook requests
    'request?'    => Any;    # Request data for hooks/permissions

=head1 NAME

Claude::Agent::Message::Base - Base class for message types

=head1 DESCRIPTION

Base class providing common attributes for all message types.

=head2 ATTRIBUTES

=over 4

=item * type - Message type (user, assistant, system, result)

=item * uuid - Unique message identifier

=item * session_id - Session identifier

=item * parent_tool_use_id - Optional, set if message is within a subagent

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
