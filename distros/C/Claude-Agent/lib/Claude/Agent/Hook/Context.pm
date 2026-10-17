package Claude::Agent::Hook::Context;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Hook::Context',
        'hook_event_name:predicate',
        'session_id:predicate',
        'cwd:predicate',
        'transcript_path:predicate',
        'permission_mode:predicate',
        'tool_name:predicate',
        'tool_input:predicate',
        'tool_use_id:predicate',
        'loop:predicate',
        'query:weak:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Hook::Context - Context passed to hook callbacks

=head1 DESCRIPTION

The third argument of a hook callback. The CLI's fields are copied from
the hook input for convenience; C<loop> and C<query> are the Perl side's.

=head1 ATTRIBUTES

Every attribute is optional and has a C<has_*> predicate.

=head2 hook_event_name

The event, for example C<PreToolUse>.

=head2 session_id

The session the event belongs to.

=head2 cwd

The session's working directory.

=head2 transcript_path

Path of the session transcript.

=head2 permission_mode

The permission mode in force.

=head2 tool_name

The tool, for tool events.

=head2 tool_input

The tool's input, for tool events.

=head2 tool_use_id

The tool use the event concerns.

=head2 loop

The L<IO::Async::Loop> the query runs on, for callbacks that return a
L<Future>.

=head2 query

The L<Claude::Agent::Query> the event arrived on.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
