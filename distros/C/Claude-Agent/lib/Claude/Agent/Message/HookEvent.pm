package Claude::Agent::Message::HookEvent;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::System;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::HookEvent',
        extends => 'Claude::Agent::Message::System',
        'hook_event_name:predicate',
        'hook_name:predicate',
        'hook_id:predicate',
        'outcome:predicate',
        'output:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Message::HookEvent - Hook lifecycle event

=head1 DESCRIPTION

A system message with subtype C<hook_started>, C<hook_progress> or
C<hook_response>. The CLI always emits them for session start hooks and,
with the C<include_hook_events> option, for every hook.

=head1 ATTRIBUTES

=head2 subtype

C<hook_started>, C<hook_progress> or C<hook_response>.

=head2 hook_event_name

The event the hook ran for, for example C<PreToolUse>.

=head2 hook_name

The hook's name as the CLI reports it.

=head2 hook_id

Identifies one hook run across its started/progress/response messages.

=head2 outcome

The hook's outcome (C<hook_response>).

=head2 output

The hook's output (C<hook_response>).

=head2 type, uuid, session_id, parent_tool_use_id, agent_id, raw, data, slash_commands, claude_code_version, tools, output_style, plugins, model, mcp_servers, api_key_source, skills, permission_mode, cwd, agents, state

Inherited from L<Claude::Agent::Message::System> and
L<Claude::Agent::Message::Base>. Fields not listed here are in C<raw>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
