#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Options;

# Test default construction
my $opts = Claude::Agent::Options->new();
isa_ok($opts, 'Claude::Agent::Options');

# Test default values
ok(!$opts->has_allowed_tools, 'no allowed_tools by default');
ok(!$opts->has_disallowed_tools, 'no disallowed_tools by default');
ok(!$opts->has_permission_mode, 'no permission_mode by default');
ok(!$opts->has_system_prompt, 'no system_prompt by default');
ok(!$opts->has_model, 'no model by default');

# Test with allowed_tools
$opts = Claude::Agent::Options->new(
    allowed_tools => ['Read', 'Glob', 'Grep'],
);
ok($opts->has_allowed_tools, 'has allowed_tools');
is_deeply($opts->allowed_tools, ['Read', 'Glob', 'Grep'], 'allowed_tools correct');

# Test with disallowed_tools
$opts = Claude::Agent::Options->new(
    disallowed_tools => ['Bash', 'Write'],
);
ok($opts->has_disallowed_tools, 'has disallowed_tools');
is_deeply($opts->disallowed_tools, ['Bash', 'Write'], 'disallowed_tools correct');

# Test permission modes
for my $mode (qw(default acceptEdits bypassPermissions plan)) {
    $opts = Claude::Agent::Options->new(permission_mode => $mode);
    is($opts->permission_mode, $mode, "permission_mode '$mode' works");
}

# Test with system prompt string
$opts = Claude::Agent::Options->new(
    system_prompt => 'You are a helpful assistant.',
);
is($opts->system_prompt, 'You are a helpful assistant.', 'system_prompt string works');

# Test with system prompt hashref
$opts = Claude::Agent::Options->new(
    system_prompt => { preset => 'coder' },
);
is_deeply($opts->system_prompt, { preset => 'coder' }, 'system_prompt hashref works');

# Test with model
$opts = Claude::Agent::Options->new(model => 'claude-sonnet-4-20250514');
is($opts->model, 'claude-sonnet-4-20250514', 'model option works');

# Test with max_turns
$opts = Claude::Agent::Options->new(max_turns => 10);
is($opts->max_turns, 10, 'max_turns option works');

# Test with cwd
$opts = Claude::Agent::Options->new(cwd => '/tmp');
is($opts->cwd, '/tmp', 'cwd option works');

# Test with resume
$opts = Claude::Agent::Options->new(resume => 'session-123');
is($opts->resume, 'session-123', 'resume option works');

# Test with fork_session
$opts = Claude::Agent::Options->new(fork_session => 1);
ok($opts->fork_session, 'fork_session option works');

# Test with can_use_tool callback
my $callback_called = 0;
$opts = Claude::Agent::Options->new(
    can_use_tool => sub {
        $callback_called = 1;
        return { behavior => 'allow' };
    },
);
ok($opts->has_can_use_tool, 'has can_use_tool callback');
$opts->can_use_tool->('Test', {});
ok($callback_called, 'can_use_tool callback is callable');

# Test with output_format
$opts = Claude::Agent::Options->new(
    output_format => {
        type   => 'json_schema',
        schema => { type => 'object' },
    },
);
is_deeply(
    $opts->output_format,
    { type => 'json_schema', schema => { type => 'object' } },
    'output_format works'
);

# Test with sandbox
$opts = Claude::Agent::Options->new(
    sandbox => {
        allow_network => 0,
    },
);
is_deeply($opts->sandbox, { allow_network => 0 }, 'sandbox option works');

# Test to_hash method
$opts = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob'],
    permission_mode => 'bypassPermissions',
    model           => 'claude-sonnet-4-20250514',
    max_turns       => 5,
);

my $hash = $opts->to_hash;
is_deeply($hash->{allowedTools}, ['Read', 'Glob'], 'to_hash allowedTools');
is($hash->{permissionMode}, 'bypassPermissions', 'to_hash permissionMode');
is($hash->{model}, 'claude-sonnet-4-20250514', 'to_hash model');
is($hash->{maxTurns}, 5, 'to_hash maxTurns');

# 0.14 options
for my $mode (qw(dontAsk auto manual)) {
    $opts = Claude::Agent::Options->new(permission_mode => $mode);
    is($opts->permission_mode, $mode, "permission_mode '$mode' works");
}
eval { Claude::Agent::Options->new(permission_mode => 'delegate') };
like($@, qr/Type constraint failed for 'permission_mode'/, 'an unknown permission_mode dies');

$opts = Claude::Agent::Options->new(
    tools                     => ['Bash', 'Read'],
    effort                    => 'xhigh',
    betas                     => ['context-1m-2025-08-07'],
    max_budget_usd            => 2.5,
    add_dirs                  => ['/tmp/a', '/tmp/b'],
    settings                  => { permissions => { allow => ['Read'] } },
    session_id                => '123e4567-e89b-12d3-a456-426614174000',
    fallback_model            => 'sonnet',
    thinking                  => { type => 'enabled', budget_tokens => 2048 },
    include_hook_events       => 1,
    forward_subagent_text     => 1,
    strict_mcp_config         => 1,
    plugins                   => [{ type => 'local', path => '/tmp/plugin' }],
    extra_args                => { bare => undef, 'debug-file' => '/tmp/x.log' },
    env                       => { FOO => 'bar' },
    stderr                    => sub { },
    cli_path                  => '/opt/claude',
    enable_file_checkpointing => 1,
    continue_conversation     => 1,
);
is_deeply($opts->tools, ['Bash', 'Read'], 'tools');
is($opts->effort, 'xhigh', 'effort');
is_deeply($opts->betas, ['context-1m-2025-08-07'], 'betas');
is($opts->max_budget_usd, 2.5, 'max_budget_usd');
is_deeply($opts->add_dirs, ['/tmp/a', '/tmp/b'], 'add_dirs');
is($opts->settings->{permissions}{allow}[0], 'Read', 'settings hashref');
is($opts->session_id, '123e4567-e89b-12d3-a456-426614174000', 'session_id');
is($opts->fallback_model, 'sonnet', 'fallback_model');
is($opts->thinking->{budget_tokens}, 2048, 'thinking');
ok($opts->include_hook_events, 'include_hook_events');
ok($opts->forward_subagent_text, 'forward_subagent_text');
ok($opts->strict_mcp_config, 'strict_mcp_config');
is($opts->plugins->[0]{path}, '/tmp/plugin', 'plugins');
ok(exists $opts->extra_args->{bare}, 'extra_args bare flag');
is($opts->env->{FOO}, 'bar', 'env');
ok($opts->has_stderr, 'stderr callback');
is($opts->cli_path, '/opt/claude', 'cli_path');
ok($opts->enable_file_checkpointing, 'enable_file_checkpointing');
ok($opts->continue_conversation, 'continue_conversation');

$hash = $opts->to_hash;
is($hash->{maxBudgetUsd}, 2.5, 'to_hash maxBudgetUsd');
is_deeply($hash->{addDirs}, ['/tmp/a', '/tmp/b'], 'to_hash addDirs');
is($hash->{sessionId}, '123e4567-e89b-12d3-a456-426614174000', 'to_hash sessionId');
is($hash->{effort}, 'xhigh', 'to_hash effort');
ok(!exists $hash->{stderr}, 'to_hash leaves callbacks out');
ok(!exists $hash->{canUseTool}, 'to_hash leaves can_use_tool out');

eval { Claude::Agent::Options->new(effort => 'extreme') };
like($@, qr/Type constraint failed for 'effort'/, 'an unknown effort dies');
eval { Claude::Agent::Options->new(session_id => 'not-a-uuid') };
like($@, qr/session_id must be a UUID/, 'a non-UUID session_id dies');
eval { Claude::Agent::Options->new(thinking => { type => 'lots' }) };
like($@, qr/thinking->\{type\}/, 'a bad thinking type dies');
eval { Claude::Agent::Options->new(plugins => [{ type => 'remote', url => 'x' }]) };
like($@, qr/plugins entries/, 'a non-local plugin dies');
eval { Claude::Agent::Options->new(can_use_tool => sub { }, permission_prompt_tool_name => 'mcp__x__y') };
like($@, qr/cannot both be set/, 'can_use_tool with permission_prompt_tool_name dies');
eval { Claude::Agent::Options->new(allowed_tools => ['Read', []]) };
like($@, qr/Type constraint failed for 'allowed_tools'/, 'a non-string tool name dies');

# system_prompt forms
for my $form (
    { type => 'preset', preset => 'claude_code', append => 'Be brief.' },
    { type => 'custom', prompt => 'You are terse.' },
    { type => 'file', path => '/tmp/prompt.txt' },
) {
    $opts = Claude::Agent::Options->new(system_prompt => $form);
    is_deeply($opts->system_prompt, $form, "system_prompt $form->{type} form");
}

# create and with
$opts = Claude::Agent::Options->new(modle => 'typo', max_turns => 3);
ok(!$opts->has_model, 'new ignores an unknown option');
is($opts->max_turns, 3, 'new keeps the known options beside it');
eval { Claude::Agent::Options->create(modle => 'typo', max_turns => 3) };
like($@, qr/Unknown option\(s\) for Claude::Agent::Options: modle/, 'create dies on an unknown option');
$opts = Claude::Agent::Options->create(model => 'opus', max_turns => 3);
is($opts->model, 'opus', 'create builds the object');

my $with = $opts->with(resume => 'sess-1', max_turns => undef, cwd => '/tmp');
isa_ok($with, 'Claude::Agent::Options');
is($with->model, 'opus', 'with keeps unchanged options');
is($with->resume, 'sess-1', 'with adds an option');
ok(!$with->has_max_turns, 'with undef removes an option');
is($with->cwd, '/tmp', 'with sets another option');
is($opts->max_turns, 3, 'with leaves the original alone');
ok(!$opts->has_resume, 'the original has no resume');

done_testing();
