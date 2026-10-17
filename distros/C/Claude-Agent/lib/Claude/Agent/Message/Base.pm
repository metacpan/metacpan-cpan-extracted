package Claude::Agent::Message::Base;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Message::Base',
        'type:Str:required',
        'uuid:predicate',
        'session_id:predicate',
        'parent_tool_use_id:predicate',
        'agent_id:predicate',
        'raw:HashRef:default({})',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Message::Base - Base class for message types

=head1 DESCRIPTION

Base class providing the attributes every message from the CLI carries. A
message whose type has no class of its own is returned as a plain Base
object, with the full decoded hash in C<raw>.

=head1 ATTRIBUTES

=head2 type

The message type: C<user>, C<assistant>, C<system>, C<result>,
C<stream_event>, C<tool_progress>, C<rate_limit_event>, or any newer type
the CLI emits.

=head2 uuid

Unique message identifier.

=head2 session_id

Session identifier.

=head2 parent_tool_use_id

Set when the message belongs to a subagent, naming the Task tool use that
started it.

=head2 agent_id

The subagent that produced the message, when there is one.

=head2 raw

The decoded message exactly as the CLI sent it, with its original keys. A
field the class does not declare is reachable here, for example
C<$msg-E<gt>raw-E<gt>{apiKeySource}>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored. Every
attribute except C<type> is optional and has a C<has_*> predicate.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
