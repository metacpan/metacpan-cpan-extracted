package Claude::Agent::Options;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    # Tool configuration
    'allowed_tools?'    => ArrayRef[Str],    # Tools Claude can use
    'disallowed_tools?' => ArrayRef[Str],    # Tools Claude cannot use

    # System prompt configuration
    'system_prompt?' => Str | HashRef,        # String or hashref with preset

    # Permission settings
    'permission_mode?' => Enum['default', 'acceptEdits', 'bypassPermissions', 'dontAsk', 'plan'],

    # MCP server configuration
    'mcp_servers?' => HashRef,                # Server name => config hashref

    # Hook configuration
    'hooks?' => HashRef,                      # Event name => arrayref of matchers

    # Permission callback
    'can_use_tool?' => CodeRef,               # Coderef for permission prompts

    # Working directory
    'cwd?' => Str,                            # Working directory for agent

    # Model configuration
    'model?' => Str,                          # Model name (e.g., 'claude-sonnet-4-5')

    # Turn limits
    'max_turns?' => Int,                      # Maximum conversation turns

    # Session management
    'resume?'       => Str,                   # Session ID to resume
    'fork_session?' => Bool,                  # Fork session when resuming (default false)

    # Subagent definitions
    'agents?' => HashRef,                     # Agent name => AgentDefinition

    # Structured output
    'output_format?',                         # JSON schema for structured outputs

    # Settings sources
    'setting_sources?' => ArrayRef[Str],     # 'user', 'project', 'local'

    # Sandbox settings
    'sandbox?',                               # Sandbox configuration

    # Include partial messages during streaming
    'include_partial_messages?' => Bool,

    # Continue conversation from previous messages
    'continue_conversation?' => Bool,

    # Query timeout in seconds (default 600 = 10 minutes)
    'query_timeout?' => Int,

    # Dry-run mode - preview tool calls without executing writes
    'dry_run?' => Bool,

    # Dry-run callback for custom handling
    'on_dry_run?' => CodeRef;

=head1 NAME

Claude::Agent::Options - Configuration options for Claude Agent queries

=head1 SYNOPSIS

    use Claude::Agent::Options;

    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'bypassPermissions',
        model           => 'claude-sonnet-4-5',
        max_turns       => 10,
    );

=head1 DESCRIPTION

This module defines all configuration options that can be passed to the
C<query()> function in L<Claude::Agent>.

=head1 ATTRIBUTES

=head2 allowed_tools

ArrayRef of tool names that Claude is allowed to use.

=head2 disallowed_tools

ArrayRef of tool names that Claude is not allowed to use.

=head2 system_prompt

Custom system prompt. Can be a string or a hashref with a C<preset> key.

=head2 permission_mode

Controls how permissions are handled. Valid values:

=over 4

=item * C<default> - Normal permission behavior

=item * C<acceptEdits> - Auto-accept file edits

=item * C<bypassPermissions> - Bypass all permission checks

=item * C<dontAsk> - Auto-deny tools unless explicitly allowed

=back

=head2 mcp_servers

HashRef of MCP server configurations. Keys are server names, values are
configuration hashrefs.

=head2 hooks

HashRef of hook configurations. Keys are event names (e.g., 'PreToolUse'),
values are arrayrefs of L<Claude::Agent::Hook::Matcher> objects.

=head2 can_use_tool

Coderef callback for permission prompts. Called when Claude needs permission
to use a tool.

    can_use_tool => sub {
        my ($tool_name, $input, $context) = @_;
        # Return Claude::Agent::Permission->allow(...) or ->deny(...)
    }

=head2 cwd

Working directory for the agent.

=head2 model

Model name to use (e.g., 'claude-sonnet-4-5', 'claude-opus-4').

=head2 max_turns

Maximum number of conversation turns before stopping.

=head2 resume

Session ID to resume a previous conversation.

=head2 fork_session

Boolean. If true, forking the session when resuming creates a new session ID.

=head2 agents

HashRef of subagent definitions. Keys are agent names, values are
L<Claude::Agent::Subagent> objects.

=head2 output_format

Configuration for structured outputs. Should be a hashref with:

    output_format => {
        type   => 'json_schema',
        schema => { ... JSON Schema ... }
    }

=head2 setting_sources

ArrayRef specifying which settings files to load. Valid values:
'user', 'project', 'local'.

=head2 sandbox

Sandbox configuration settings.

=head2 include_partial_messages

Boolean. If true, include partial messages during streaming.

=head2 continue_conversation

Boolean. If true, continue from previous conversation messages.

=head2 query_timeout

Timeout in seconds for the C<next()> method to wait for messages.
Defaults to 600 seconds (10 minutes). Set to a lower value for
interactive applications, or higher for complex long-running queries.

The MCP tool handler timeout can be configured via the
C<CLAUDE_AGENT_TOOL_TIMEOUT> environment variable (default 60 seconds).

=head2 dry_run

Boolean. If true, enables dry-run mode where file-modifying tools (Write, Edit,
Bash with write operations) are intercepted and their effects are previewed
without actually executing them. Read-only tools (Read, Glob, Grep) still execute
normally.

    my $options = Claude::Agent::Options->new(
        dry_run => 1,
        on_dry_run => sub {
            my ($tool_name, $tool_input, $preview) = @_;
            print "Would execute $tool_name:\n";
            print "  $preview\n";
        },
    );

=head2 on_dry_run

Coderef callback invoked when a tool is blocked in dry-run mode. Receives:

=over 4

=item * tool_name - Name of the tool that would execute

=item * tool_input - HashRef of input parameters

=item * preview - Human-readable preview of what would happen

=back

=head1 METHODS

=head2 to_hash

    my $hash = $options->to_hash;

Convert options to a hashref for CLI arguments or serialization.
Uses camelCase keys to match the SDK API format.

=cut

sub to_hash {
    my ($self) = @_;

    my %hash;

    $hash{allowedTools} = $self->allowed_tools if $self->has_allowed_tools;
    $hash{disallowedTools} = $self->disallowed_tools if $self->has_disallowed_tools;
    $hash{systemPrompt} = $self->system_prompt if $self->has_system_prompt;
    $hash{permissionMode} = $self->permission_mode if $self->has_permission_mode;
    $hash{model} = $self->model if $self->has_model;
    $hash{maxTurns} = $self->max_turns if $self->has_max_turns;
    $hash{cwd} = $self->cwd if $self->has_cwd;
    $hash{resume} = $self->resume if $self->has_resume;
    $hash{forkSession} = $self->fork_session if $self->has_fork_session;
    $hash{outputFormat} = $self->output_format if $self->has_output_format;
    $hash{settingSources} = $self->setting_sources if $self->has_setting_sources;
    $hash{sandbox} = $self->sandbox if $self->has_sandbox;
    $hash{includePartialMessages} = $self->include_partial_messages if $self->has_include_partial_messages;
    $hash{continueConversation} = $self->continue_conversation if $self->has_continue_conversation;

    # Handle MCP servers
    if ($self->has_mcp_servers) {
        $hash{mcpServers} = {
            map {
                my $server = $self->mcp_servers->{$_};
                $_ => ($server->can('to_hash') ? $server->to_hash : $server)
            } keys %{$self->mcp_servers}
        };
    }

    # Handle agents (subagents)
    if ($self->has_agents) {
        $hash{agents} = {
            map {
                my $agent = $self->agents->{$_};
                $_ => ($agent->can('to_hash') ? $agent->to_hash : $agent)
            } keys %{$self->agents}
        };
    }

    return \%hash;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
