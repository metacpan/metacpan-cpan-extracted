package Claude::Agent::Message::User;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::User',
        extends => 'Claude::Agent::Message::Base',
        'message:HashRef:required',
        'tool_use_result:predicate',
        'origin:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Message::User - User message type

=head1 DESCRIPTION

Represents a user message in the conversation. The CLI emits one for every
tool result it feeds back to the model, and, with C<--replay-user-messages>,
for every prompt written to it.

=head1 ATTRIBUTES

=head2 type

Always C<user>.

=head2 message

HashRef with C<role> and C<content> keys. C<content> is a string or an
array of content blocks.

=head2 tool_use_result

Tool use result data, for messages that carry a tool result.

=head2 origin

Where the message came from, when the CLI says.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
