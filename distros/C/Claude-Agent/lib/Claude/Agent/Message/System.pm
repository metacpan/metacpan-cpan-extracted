package Claude::Agent::Message::System;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::System',
        extends => 'Claude::Agent::Message::Base',
        'subtype:Str:required',
        'data:predicate',
        'slash_commands:predicate',
        'claude_code_version:predicate',
        'tools:predicate',
        'output_style:predicate',
        'plugins:predicate',
        'model:predicate',
        'mcp_servers:predicate',
        'api_key_source:predicate',
        'skills:predicate',
        'permission_mode:predicate',
        'cwd:predicate',
        'agents:predicate',
        'state:predicate',
    );
}

sub get_session_id {
    my ($self) = @_;
    return $self->session_id // ($self->has_data && $self->data ? $self->data->{session_id} : undef);
}

1;

__END__

=head1 NAME

Claude::Agent::Message::System - System message type

=head1 DESCRIPTION

Represents a system message: session initialisation, status changes,
compaction boundaries and the other events the CLI reports outside the
conversation itself.

=head1 ATTRIBUTES

=head2 type

Always C<system>.

=head2 subtype

The kind of system message. Known values include C<init>, C<status>,
C<compact_boundary>, C<session_state_changed>, C<api_retry>,
C<task_started>, C<task_progress>, C<task_notification>,
C<permission_denied>, C<elicitation> and C<files_persisted>. Hook
lifecycle subtypes are delivered as L<Claude::Agent::Message::HookEvent>.

=head2 data

Additional data specific to the subtype.

=head2 slash_commands

Available slash commands (init).

=head2 claude_code_version

Version of the Claude Code CLI (init).

=head2 tools

Available tools (init).

=head2 output_style

Output formatting style (init).

=head2 plugins

Loaded plugins (init).

=head2 model

Active model name (init).

=head2 mcp_servers

MCP server status entries (init). An array of C<{name, status}> hashes on
current CLIs; older CLIs sent a hash.

=head2 api_key_source

Source of the API key (init).

=head2 skills

Available skills (init).

=head2 permission_mode

Current permission mode (init).

=head2 cwd

Working directory of the session (init).

=head2 agents

Available agent definitions (init).

=head2 state

The session state (C<session_state_changed>): C<running>, C<idle> or
C<requires_action>.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>. Fields the CLI sends under other
names, such as C<capabilities> or C<plugin_errors>, are in C<raw>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 get_session_id

    my $id = $msg->get_session_id;

The session id from the message, falling back to C<data-E<gt>{session_id}>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
