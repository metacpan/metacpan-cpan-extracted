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

done_testing();
