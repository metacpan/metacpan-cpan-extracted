package Claude::Agent::Options;

use 5.020;
use strict;
use warnings;

use Carp ();
use Object::Proto ();
use Claude::Agent::Types;

BEGIN {
    Object::Proto::define('Claude::Agent::Options',
        'allowed_tools:StrList:predicate',
        'disallowed_tools:StrList:predicate',
        'tools:predicate',
        'system_prompt:StrOrHashRef:predicate',
        'permission_mode:PermissionMode:predicate',
        'permission_prompt_tool_name:Str:predicate',
        'can_use_tool:CodeRef:predicate',
        'mcp_servers:HashRef:predicate',
        'strict_mcp_config:Bool:predicate',
        'hooks:HashRef:predicate',
        'agents:HashRef:predicate',
        'cwd:Str:predicate',
        'add_dirs:StrList:predicate',
        'env:HashRef:predicate',
        'model:Str:predicate',
        'fallback_model:Str:predicate',
        'effort:Effort:predicate',
        'thinking:HashRef:predicate',
        'max_thinking_tokens:Int:predicate',
        'betas:StrList:predicate',
        'max_turns:Int:predicate',
        'max_budget_usd:Num:predicate',
        'resume:Str:predicate',
        'continue_conversation:Bool:predicate',
        'session_id:Str:predicate',
        'fork_session:Bool:predicate',
        'output_format:predicate',
        'settings:StrOrHashRef:predicate',
        'setting_sources:StrList:predicate',
        'sandbox:HashRef:predicate',
        'plugins:ArrayRef:predicate',
        'include_partial_messages:Bool:predicate',
        'include_hook_events:Bool:predicate',
        'forward_subagent_text:Bool:predicate',
        'enable_file_checkpointing:Bool:predicate',
        'extra_args:HashRef:predicate',
        'stderr:CodeRef:predicate',
        'cli_path:Str:predicate',
        'query_timeout:Int:default(600):predicate',
        'dry_run:Bool:predicate',
        'on_dry_run:CodeRef:predicate',
    );
}

my %CAMEL = (
    allowed_tools               => 'allowedTools',
    disallowed_tools            => 'disallowedTools',
    system_prompt               => 'systemPrompt',
    permission_mode             => 'permissionMode',
    permission_prompt_tool_name => 'permissionPromptToolName',
    strict_mcp_config           => 'strictMcpConfig',
    add_dirs                    => 'addDirs',
    fallback_model              => 'fallbackModel',
    max_thinking_tokens         => 'maxThinkingTokens',
    max_turns                   => 'maxTurns',
    max_budget_usd              => 'maxBudgetUsd',
    continue_conversation       => 'continueConversation',
    session_id                  => 'sessionId',
    fork_session                => 'forkSession',
    output_format               => 'outputFormat',
    setting_sources             => 'settingSources',
    include_partial_messages    => 'includePartialMessages',
    include_hook_events         => 'includeHookEvents',
    forward_subagent_text       => 'forwardSubagentText',
    enable_file_checkpointing   => 'enableFileCheckpointing',
    extra_args                  => 'extraArgs',
    cli_path                    => 'cliPath',
    query_timeout               => 'queryTimeout',
    dry_run                     => 'dryRun',
);

my %SKIP_IN_HASH = map { $_ => 1 } qw(can_use_tool hooks stderr on_dry_run);

sub BUILD {
    my ($self) = @_;
    if ($self->has_session_id) {
        my $id = $self->session_id;
        Carp::croak("session_id must be a UUID, not '$id'")
            unless $id =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    }
    if ($self->has_can_use_tool && $self->has_permission_prompt_tool_name) {
        Carp::croak("can_use_tool and permission_prompt_tool_name cannot both be set");
    }
    if ($self->has_thinking) {
        my $type = $self->thinking->{type} // '';
        Carp::croak("thinking->{type} must be adaptive, enabled or disabled, not '$type'")
            unless $type =~ /^(?:adaptive|enabled|disabled)$/;
    }
    if ($self->has_plugins) {
        for my $plugin (@{$self->plugins}) {
            Carp::croak("plugins entries are hashrefs with type => 'local' and a path")
                unless ref $plugin eq 'HASH'
                    && ($plugin->{type} // 'local') eq 'local'
                    && defined $plugin->{path};
        }
    }
    return;
}

sub create {
    my ($class, %args) = @_;
    return $class->new(Claude::Agent::Types::check_args($class, %args));
}

sub with {
    my ($self, %overrides) = @_;
    my %args;
    for my $name (Object::Proto::properties(ref $self)) {
        my $has = "has_$name";
        $args{$name} = $self->$name if $self->$has;
    }
    for my $name (keys %overrides) {
        if (defined $overrides{$name}) {
            $args{$name} = $overrides{$name};
        }
        else {
            delete $args{$name};
        }
    }
    return (ref $self)->create(%args);
}

sub to_hash {
    my ($self) = @_;

    my %hash;
    for my $name (Object::Proto::properties(ref $self)) {
        next if $SKIP_IN_HASH{$name};
        my $has = "has_$name";
        next unless $self->$has;
        $hash{ $CAMEL{$name} // $name } = $self->$name;
    }

    if ($self->has_mcp_servers) {
        $hash{mcpServers} = {
            map {
                my $server = $self->mcp_servers->{$_};
                $_ => ($server->can('to_hash') ? $server->to_hash : $server)
            } keys %{$self->mcp_servers}
        };
    }

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

1;

__END__

=head1 NAME

Claude::Agent::Options - Configuration options for Claude Agent queries

=head1 SYNOPSIS

    use Claude::Agent::Options;

    my $options = Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep'],
        permission_mode => 'acceptEdits',
        model           => 'sonnet',
        effort          => 'high',
        max_turns       => 10,
    );

=head1 DESCRIPTION

This module defines every option that C<query()>, C<session()> and
L<Claude::Agent::Query> accept. Each option maps to a flag of the C<claude>
CLI, an entry of the SDK C<initialize> request, or a behaviour of the Perl
side; the mapping is given with each attribute.

=head1 CONSTRUCTORS

=head2 new

    my $options = Claude::Agent::Options->new(%options);

Takes a flat list of name/value pairs. An option this class does not know
is ignored, so prefer C<create> when the names come from configuration.
Passing a hashref is not supported.

=head2 create

    my $options = Claude::Agent::Options->create(%options);

As C<new>, but croaks naming every unknown option. C<Claude::Agent::query>
and C<session> build their options this way when given a hashref.

=head1 ATTRIBUTES

Every attribute is optional and has a C<has_*> predicate that reports
whether it was given.

=head2 allowed_tools

ArrayRef of tool names Claude may use without asking. C<--allowedTools>.

=head2 disallowed_tools

ArrayRef of tool names Claude may not use. C<--disallowedTools>.

=head2 tools

Which built-in tools exist at all: an ArrayRef of names, C<[]> for none, or
C<{ type =E<gt> 'preset' }> for the default set. C<--tools>.

=head2 system_prompt

A string replaces the system prompt (C<--system-prompt>). A hashref is one
of C<{ type =E<gt> 'preset', preset =E<gt> 'claude_code', append =E<gt> $text }>
(keep the CLI's prompt and append; C<--append-system-prompt>),
C<{ type =E<gt> 'custom', prompt =E<gt> $text }> (C<--system-prompt>) or
C<{ type =E<gt> 'file', path =E<gt> $file }> (C<--system-prompt-file>). A hashref
with only C<preset> is read as the preset form. When unset the CLI's own
prompt is used.

=head2 permission_mode

One of C<default>, C<acceptEdits>, C<bypassPermissions>, C<dontAsk>,
C<plan>, C<auto> or C<manual>. C<--permission-mode>.

=head2 permission_prompt_tool_name

The MCP tool that answers permission prompts (C<--permission-prompt-tool>).
Cannot be combined with C<can_use_tool>, which sets it to C<stdio>.

=head2 can_use_tool

    can_use_tool => sub {
        my ($tool_name, $input, $context) = @_;
        return Claude::Agent::Permission->allow;
    }

Callback asked whenever the CLI would prompt for permission. It receives
the tool name, its input and a L<Claude::Agent::Permission::Context>, and
returns a L<Claude::Agent::Permission::Result>, a hashref with a C<behavior>
key, or a L<Future> of either.

=head2 mcp_servers

HashRef of MCP server configurations keyed by name: L<Claude::Agent::MCP::Server>
objects run in this process, L<Claude::Agent::MCP::StdioServer>,
L<Claude::Agent::MCP::SSEServer> and L<Claude::Agent::MCP::HTTPServer>
objects (or plain hashrefs) are passed to the CLI. C<--mcp-config>.

=head2 strict_mcp_config

Use only the servers in C<mcp_servers>. C<--strict-mcp-config>.

=head2 hooks

HashRef of event name to ArrayRef of L<Claude::Agent::Hook::Matcher>
objects, registered with the CLI in the C<initialize> request.

=head2 agents

HashRef of subagent name to L<Claude::Agent::Subagent>, sent in the
C<initialize> request.

=head2 cwd

Working directory for the CLI process.

=head2 add_dirs

ArrayRef of extra directories the tools may touch. One C<--add-dir> each.

=head2 env

HashRef of environment variables set for the CLI process, over the
inherited environment.

=head2 model

Model name or alias. C<--model>.

=head2 fallback_model

Model to use when the first is overloaded. C<--fallback-model>.

=head2 effort

One of C<low>, C<medium>, C<high>, C<xhigh>, C<max>. C<--effort>.

=head2 thinking

C<{ type =E<gt> 'adaptive' }>, C<{ type =E<gt> 'enabled', budget_tokens =E<gt> $n }>
or C<{ type =E<gt> 'disabled' }>. C<--thinking> or C<--max-thinking-tokens>.

=head2 max_thinking_tokens

Thinking budget. C<--max-thinking-tokens>. Ignored when C<thinking> is set.

=head2 betas

ArrayRef of beta header names. C<--betas>.

=head2 max_turns

Maximum number of agentic turns. C<--max-turns>.

=head2 max_budget_usd

Spending cap for the query. C<--max-budget-usd>.

=head2 resume

Session ID to resume. C<--resume>.

=head2 continue_conversation

Continue the most recent conversation in the working directory.
C<--continue>.

=head2 session_id

UUID to use for the new session. C<--session-id>. Validated at
construction.

=head2 fork_session

When resuming, start a new session ID. C<--fork-session>.

=head2 output_format

    output_format => {
        type   => 'json_schema',
        schema => { ... JSON Schema ... },
    }

Structured output. The schema goes to C<--json-schema> and the parsed
result arrives in the result message's C<structured_output>.

=head2 settings

Path to a settings file, a JSON string, or a hashref. C<--settings>.

=head2 setting_sources

ArrayRef of C<user>, C<project>, C<local>. C<--setting-sources>.

=head2 sandbox

Sandbox settings hashref, merged into C<settings> as its C<sandbox> key.

=head2 plugins

ArrayRef of C<{ type =E<gt> 'local', path =E<gt> $dir }>. One C<--plugin-dir>
each.

=head2 include_partial_messages

Deliver L<Claude::Agent::Message::StreamEvent> messages as the model
streams. C<--include-partial-messages>.

=head2 include_hook_events

Deliver L<Claude::Agent::Message::HookEvent> messages for every hook.
C<--include-hook-events>.

=head2 forward_subagent_text

Deliver subagent assistant and user messages, with C<parent_tool_use_id>
set. Sent in the C<initialize> request.

=head2 enable_file_checkpointing

Let the CLI checkpoint file changes so C<rewind_files> can undo them.

=head2 extra_args

HashRef of extra CLI flags without the leading dashes. A value of undef
passes the bare flag.

=head2 stderr

Callback given each line of the CLI's standard error. By default they are
logged at debug level.

=head2 cli_path

Path to the C<claude> executable, instead of searching for it.

=head2 query_timeout

Seconds the blocking C<next()> waits for a message. Default 600, maximum
3600. Always set, so C<has_query_timeout> is always true.

=head2 dry_run

Preview file-modifying tools instead of running them. See
L<Claude::Agent::DryRun>.

=head2 on_dry_run

    on_dry_run => sub {
        my ($tool_name, $tool_input, $preview) = @_;
        ...
    }

Callback for each tool blocked in dry-run mode.

=head1 METHODS

=head2 with

    my $resumed = $options->with(resume => $session_id);

A copy with the given options changed. A value of undef removes the
option from the copy.

=head2 to_hash

    my $hash = $options->to_hash;

The options that were given, as a hashref with camelCase keys. Callbacks
and hooks are left out; MCP servers and agents are expanded with their
own C<to_hash>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
