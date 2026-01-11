package Claude::Agent::Subagent;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'description!' => Str,     # When to use this agent
    'prompt!'      => Str,     # System prompt for the agent
    'tools?'       => ArrayRef[Str],  # Allowed tools (inherits if not set)
    'model?'       => Str;     # Model override ('sonnet', 'opus', 'haiku', 'inherit')

=head1 NAME

Claude::Agent::Subagent - Subagent definitions for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Subagent;
    use Claude::Agent::Options;

    my $options = Claude::Agent::Options->new(
        allowed_tools => ['Read', 'Glob', 'Grep', 'Task'],
        agents => {
            'code-reviewer' => Claude::Agent::Subagent->new(
                description => 'Expert code review specialist. Use for quality, security, and maintainability reviews.',
                prompt      => 'You are a code review specialist with expertise in security, performance, and best practices.',
                tools       => ['Read', 'Glob', 'Grep'],
                model       => 'sonnet',
            ),
            'test-runner' => Claude::Agent::Subagent->new(
                description => 'Runs and analyzes test suites. Use for test execution and coverage analysis.',
                prompt      => 'You are a test execution specialist.',
                tools       => ['Bash', 'Read', 'Grep'],
            ),
        },
    );

=head1 DESCRIPTION

Subagents are separate agent instances that your main agent can spawn to handle
focused subtasks. Use subagents to:

=over 4

=item * Isolate context for focused subtasks

=item * Run multiple analyses in parallel

=item * Apply specialized instructions without bloating the main prompt

=item * Restrict tool access for safety

=back

=head2 HOW IT WORKS

When you define subagents and include 'Task' in allowed_tools, Claude can invoke
subagents via the Task tool. Claude decides which subagent to use based on the
description field, or you can explicitly request one by name in your prompt.

=head1 ATTRIBUTES

=head2 description

Natural language description of when to use this agent. Claude uses this to
decide when to delegate tasks to the subagent. Write clear, specific descriptions
so Claude can match tasks appropriately.

=head2 prompt

The agent's system prompt defining its role and behavior. This is the context
and instructions the subagent receives.

=head2 tools

ArrayRef of allowed tool names. If omitted, the subagent inherits all tools
from the parent (except Task - subagents cannot spawn their own subagents).

Common tool combinations:

=over 4

=item * Read-only analysis: ['Read', 'Grep', 'Glob']

=item * Test execution: ['Bash', 'Read', 'Grep']

=item * Code modification: ['Read', 'Edit', 'Write', 'Grep', 'Glob']

=back

=head2 model

Model override for this agent. Options:

=over 4

=item * 'sonnet' - Use Claude Sonnet

=item * 'opus' - Use Claude Opus

=item * 'haiku' - Use Claude Haiku

=item * 'inherit' - Use the same model as parent (default)

=back

=head1 METHODS

=head2 to_hash

    my $hash = $subagent->to_hash;

Convert to a hashref for passing to the SDK.

=cut

sub to_hash {
    my ($self) = @_;

    my $hash = {
        description => $self->description,
        prompt      => $self->prompt,
    };

    $hash->{tools} = $self->tools if $self->has_tools;
    $hash->{model} = $self->model if $self->has_model;

    return $hash;
}

1;

__END__

=head1 EXAMPLES

=head2 Security Review Agent

    Claude::Agent::Subagent->new(
        description => 'Security code reviewer for vulnerability analysis',
        prompt      => <<'PROMPT',
You are a security specialist. When reviewing code:
- Identify security vulnerabilities (OWASP Top 10)
- Check for injection risks
- Verify input validation
- Look for authentication/authorization issues
Be thorough but concise in your feedback.
PROMPT
        tools => ['Read', 'Grep', 'Glob'],
        model => 'opus',  # Use stronger model for security
    );

=head2 Documentation Generator

    Claude::Agent::Subagent->new(
        description => 'Documentation specialist for generating API docs',
        prompt      => 'Generate clear, comprehensive API documentation.',
        tools       => ['Read', 'Glob'],
    );

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
