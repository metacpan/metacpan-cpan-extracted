package Claude::Agent::Hook;

use 5.020;
use strict;
use warnings;

use Exporter qw(import);
use Const::XS qw(const);
use Claude::Agent::Hook::Matcher;
use Claude::Agent::Hook::Context;
use Claude::Agent::Hook::Result;

const our $PRE_TOOL_USE        => 'PreToolUse';
const our $POST_TOOL_USE       => 'PostToolUse';
const our $POST_TOOL_USE_FAIL  => 'PostToolUseFailure';
const our $NOTIFICATION        => 'Notification';
const our $USER_PROMPT_SUBMIT  => 'UserPromptSubmit';
const our $SESSION_START       => 'SessionStart';
const our $SESSION_END         => 'SessionEnd';
const our $STOP                => 'Stop';
const our $STOP_FAILURE        => 'StopFailure';
const our $SUBAGENT_START      => 'SubagentStart';
const our $SUBAGENT_STOP       => 'SubagentStop';
const our $PRE_COMPACT         => 'PreCompact';
const our $POST_COMPACT        => 'PostCompact';
const our $PERMISSION_REQUEST  => 'PermissionRequest';
const our $PERMISSION_DENIED   => 'PermissionDenied';
const our $CONFIG_CHANGE       => 'ConfigChange';
const our $WORKTREE_CREATE     => 'WorktreeCreate';
const our $WORKTREE_REMOVE     => 'WorktreeRemove';
const our $ELICITATION         => 'Elicitation';
const our $ELICITATION_RESULT  => 'ElicitationResult';
const our $INSTRUCTIONS_LOADED => 'InstructionsLoaded';
const our $CWD_CHANGED         => 'CwdChanged';
const our $FILE_CHANGED        => 'FileChanged';
const our $TASK_COMPLETED      => 'TaskCompleted';
const our $TEAMMATE_IDLE       => 'TeammateIdle';
const our $SETUP               => 'Setup';

const our @EVENTS => (
    $PRE_TOOL_USE, $POST_TOOL_USE, $POST_TOOL_USE_FAIL, $NOTIFICATION,
    $USER_PROMPT_SUBMIT, $SESSION_START, $SESSION_END, $STOP, $STOP_FAILURE,
    $SUBAGENT_START, $SUBAGENT_STOP, $PRE_COMPACT, $POST_COMPACT,
    $PERMISSION_REQUEST, $PERMISSION_DENIED, $CONFIG_CHANGE, $WORKTREE_CREATE,
    $WORKTREE_REMOVE, $ELICITATION, $ELICITATION_RESULT, $INSTRUCTIONS_LOADED,
    $CWD_CHANGED, $FILE_CHANGED, $TASK_COMPLETED, $TEAMMATE_IDLE, $SETUP,
);

our @EXPORT_OK = qw(
    $PRE_TOOL_USE $POST_TOOL_USE $POST_TOOL_USE_FAIL $NOTIFICATION
    $USER_PROMPT_SUBMIT $SESSION_START $SESSION_END $STOP $STOP_FAILURE
    $SUBAGENT_START $SUBAGENT_STOP $PRE_COMPACT $POST_COMPACT
    $PERMISSION_REQUEST $PERMISSION_DENIED $CONFIG_CHANGE $WORKTREE_CREATE
    $WORKTREE_REMOVE $ELICITATION $ELICITATION_RESULT $INSTRUCTIONS_LOADED
    $CWD_CHANGED $FILE_CHANGED $TASK_COMPLETED $TEAMMATE_IDLE $SETUP
    @EVENTS
);

our %EXPORT_TAGS = (events => \@EXPORT_OK);

1;

__END__

=head1 NAME

Claude::Agent::Hook - Hook system for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Hook qw(:events);
    use Claude::Agent::Options;

    my $options = Claude::Agent::Options->new(
        hooks => {
            $PRE_TOOL_USE => [
                Claude::Agent::Hook::Matcher->new(
                    matcher => 'Bash',
                    hooks   => [sub {
                        my ($input, $tool_use_id, $context) = @_;
                        my $command = $input->{tool_input}{command} // '';
                        if ($command =~ /rm -rf/) {
                            return Claude::Agent::Hook::Result->deny(
                                reason => 'Dangerous command blocked',
                            );
                        }
                        return Claude::Agent::Hook::Result->proceed;
                    }],
                ),
            ],
            $STOP => [
                Claude::Agent::Hook::Matcher->new(
                    hooks => [sub {
                        my ($input, $tool_use_id, $context) = @_;
                        return Claude::Agent::Hook::Result->proceed;
                    }],
                ),
            ],
        },
    );

=head1 DESCRIPTION

Hooks are Perl callbacks the CLI runs at points in its own loop. They are
registered with the CLI when a query starts, the CLI decides when each
matcher applies, and it calls back over the SDK control channel with the
same input a hook command would read on standard input. A hook can let the
event proceed, change a tool's input, allow or deny a tool, add context,
or stop the turn.

=head1 CALLBACKS

    sub {
        my ($input, $tool_use_id, $context) = @_;
        ...
        return Claude::Agent::Hook::Result->proceed;
    }

C<$input> is the CLI's hook input: C<hook_event_name>, C<session_id>,
C<transcript_path>, C<cwd>, C<permission_mode>, and for tool events
C<tool_name>, C<tool_input> and C<tool_use_id>, plus event-specific keys
such as C<prompt> (UserPromptSubmit) or C<tool_response> (PostToolUse).
C<$tool_use_id> is the tool use the event concerns, or undef. C<$context>
is a L<Claude::Agent::Hook::Context>, which also carries the event loop
and the query.

The callback returns a hashref in the CLI's hook output shape, most easily
built with L<Claude::Agent::Hook::Result>, or a L<Future> that resolves to
one. A hashref of the 0.13 shape (C<decision> of C<continue>, C<allow> or
C<deny>) is translated with a warning. A callback that dies or whose
Future fails is reported to the CLI as a hook error.

=head1 EVENTS

Each constant is exported on request, or all of them with the C<:events>
tag; C<@EVENTS> lists them.

=over 4

=item * PreToolUse - before a tool runs; may allow, deny, ask or change the input

=item * PostToolUse - after a tool succeeds; may add context or replace the output

=item * PostToolUseFailure - after a tool fails

=item * Notification - the CLI wants to tell the person something

=item * UserPromptSubmit - a prompt was submitted; may block it or add context

=item * SessionStart, SessionEnd, Setup

=item * Stop, StopFailure - the model stopped; may block the stop

=item * SubagentStart, SubagentStop

=item * PreCompact, PostCompact

=item * PermissionRequest, PermissionDenied

=item * ConfigChange, InstructionsLoaded, CwdChanged, FileChanged

=item * WorktreeCreate, WorktreeRemove

=item * Elicitation, ElicitationResult

=item * TaskCompleted, TeammateIdle

=back

=head1 CLASSES

=over 4

=item * L<Claude::Agent::Hook::Matcher> - which tools a set of callbacks applies to

=item * L<Claude::Agent::Hook::Context> - what a callback receives

=item * L<Claude::Agent::Hook::Result> - what a callback returns

=item * L<Claude::Agent::Hook::Registry> - how a query registers and runs them

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
