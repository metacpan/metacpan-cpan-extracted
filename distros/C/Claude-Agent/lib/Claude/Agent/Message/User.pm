package Claude::Agent::Message::User;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Message::Base',
    'message!' => HashRef,       # Contains role and content
    'tool_use_result?' => Any;   # Tool use result data (for tool result messages)

=head1 NAME

Claude::Agent::Message::User - User message type

=head1 DESCRIPTION

Represents a user message in the conversation.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'user'

=item * uuid - Unique message identifier

=item * session_id - Session identifier

=item * message - HashRef with 'role' and 'content' keys

=item * parent_tool_use_id - Optional, set if message is within a subagent

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
