package Claude::Agent::Permission::Context;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Permission::Context',
        'tool_name:Str:required',
        'tool_input:required',
        'session_id:predicate',
        'cwd:predicate',
        'tool_use_id:predicate',
        'agent_id:predicate',
        'suggestions:predicate',
        'blocked_path:predicate',
        'decision_reason:predicate',
        'title:predicate',
        'display_name:predicate',
        'description:predicate',
        'query:weak:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Permission::Context - Context passed to the can_use_tool callback

=head1 DESCRIPTION

The third argument of a C<can_use_tool> callback: what the CLI said when
it asked whether the tool may run.

=head1 ATTRIBUTES

=head2 tool_name

The tool being asked about. Required.

=head2 tool_input

The tool's input. Required; an empty hashref when the tool takes none.

=head2 session_id

The session the request belongs to.

=head2 cwd

The working directory of the session.

=head2 tool_use_id

The id of the tool use, matching the assistant message's tool_use block.

=head2 agent_id

The subagent asking, when it is not the main conversation.

=head2 suggestions

ArrayRef of the permission rule updates the CLI would offer in its own
prompt, each in the CLI's C<PermissionUpdate> shape. Pass any of them back
in an allow result's C<updated_permissions> to make the decision stick.

=head2 blocked_path

The path a file tool was refused for, when that is why the CLI asked.

=head2 decision_reason

The CLI's reason for asking.

=head2 title, display_name, description

Text the CLI would show in its own prompt.

=head2 query

The L<Claude::Agent::Query> the request arrived on.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
