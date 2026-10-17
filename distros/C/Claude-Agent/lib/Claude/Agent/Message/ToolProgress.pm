package Claude::Agent::Message::ToolProgress;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::ToolProgress',
        extends => 'Claude::Agent::Message::Base',
        'tool_use_id:predicate',
        'tool_name:predicate',
        'elapsed_time_seconds:predicate',
        'task_id:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Message::ToolProgress - Long-running tool progress event

=head1 DESCRIPTION

Emitted while a tool call is still running, so a consumer can show that
the agent is busy.

=head1 ATTRIBUTES

=head2 type

Always C<tool_progress>.

=head2 tool_use_id

The tool use being reported on.

=head2 tool_name

The tool's name.

=head2 elapsed_time_seconds

How long the tool has been running.

=head2 task_id

The background task, when the tool runs one.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>. The CLI's full payload is in C<raw>;
the attributes above are the fields observed so far.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
