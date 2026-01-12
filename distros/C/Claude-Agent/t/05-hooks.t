#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Hook;

# Test hook constants
is($Claude::Agent::Hook::PRE_TOOL_USE, 'PreToolUse', 'PRE_TOOL_USE constant');
is($Claude::Agent::Hook::POST_TOOL_USE, 'PostToolUse', 'POST_TOOL_USE constant');
is($Claude::Agent::Hook::POST_TOOL_USE_FAIL, 'PostToolUseFailure', 'POST_TOOL_USE_FAIL constant');
is($Claude::Agent::Hook::USER_PROMPT_SUBMIT, 'UserPromptSubmit', 'USER_PROMPT_SUBMIT constant');
is($Claude::Agent::Hook::STOP, 'Stop', 'STOP constant');
is($Claude::Agent::Hook::SUBAGENT_START, 'SubagentStart', 'SUBAGENT_START constant');
is($Claude::Agent::Hook::SUBAGENT_STOP, 'SubagentStop', 'SUBAGENT_STOP constant');
is($Claude::Agent::Hook::PRE_COMPACT, 'PreCompact', 'PRE_COMPACT constant');
is($Claude::Agent::Hook::PERMISSION_REQUEST, 'PermissionRequest', 'PERMISSION_REQUEST constant');
is($Claude::Agent::Hook::SESSION_START, 'SessionStart', 'SESSION_START constant');
is($Claude::Agent::Hook::SESSION_END, 'SessionEnd', 'SESSION_END constant');
is($Claude::Agent::Hook::NOTIFICATION, 'Notification', 'NOTIFICATION constant');

# Test Hook::Matcher
my $matcher = Claude::Agent::Hook::Matcher->new(
    matcher => 'Bash',
    hooks   => [
        sub {
            my ($input, $tool_use_id, $context) = @_;
            return { decision => 'continue' };
        },
    ],
    timeout => 30,
);

isa_ok($matcher, 'Claude::Agent::Hook::Matcher');
is($matcher->timeout, 30, 'timeout set correctly');

# Test matches() - exact match
ok($matcher->matches('Bash'), 'matches exact tool name');
ok(!$matcher->matches('Read'), 'does not match different tool');
ok(!$matcher->matches('BashOutput'), 'exact match does not match partial');

# Test matches() - regex pattern
my $regex_matcher = Claude::Agent::Hook::Matcher->new(
    matcher => 'mcp__.*',
    hooks   => [],
);

ok($regex_matcher->matches('mcp__math__calculate'), 'regex matches mcp tool');
ok($regex_matcher->matches('mcp__server__tool'), 'regex matches another mcp tool');
ok(!$regex_matcher->matches('Read'), 'regex does not match non-mcp tool');

# Test matches() - no matcher (match all)
my $catch_all = Claude::Agent::Hook::Matcher->new(
    hooks => [],
);

ok($catch_all->matches('Bash'), 'no matcher matches Bash');
ok($catch_all->matches('Read'), 'no matcher matches Read');
ok($catch_all->matches('anything'), 'no matcher matches anything');

# Test run_hooks()
my @call_log;
my $logging_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub {
            my ($input, $tool_use_id, $context) = @_;
            push @call_log, { hook => 1, input => $input };
            return { decision => 'continue' };
        },
        sub {
            my ($input, $tool_use_id, $context) = @_;
            push @call_log, { hook => 2, input => $input };
            return { decision => 'continue' };
        },
    ],
);

my $input_data = { tool_name => 'Test', tool_input => { arg => 'value' } };
# run_hooks now returns a Future
my $future = $logging_matcher->run_hooks($input_data, 'tool-id-123', {});
isa_ok($future, 'Future', 'run_hooks returns a Future');
my $results = $future->get;

is(scalar @$results, 2, 'both hooks ran');
is(scalar @call_log, 2, 'both hooks logged');
is($call_log[0]{hook}, 1, 'first hook ran first');
is($call_log[1]{hook}, 2, 'second hook ran second');

# Test early termination on deny
my $deny_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub { return { decision => 'deny', reason => 'Blocked' } },
        sub { return { decision => 'continue' } },  # Should not run
    ],
);

my @deny_log;
$deny_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub {
            push @deny_log, 1;
            return { decision => 'deny', reason => 'Blocked' };
        },
        sub {
            push @deny_log, 2;
            return { decision => 'continue' };
        },
    ],
);

$future = $deny_matcher->run_hooks({}, 'id', {});
$results = $future->get;
is(scalar @deny_log, 1, 'second hook did not run after deny');
is($results->[0]{decision}, 'deny', 'deny result returned');

# Test error handling in hooks
my $error_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub { die "Hook error!" },
    ],
);

$future = $error_matcher->run_hooks({}, 'id', {});
$results = $future->get;
is($results->[0]{decision}, 'error', 'error caught and reported');
is($results->[0]{error}, 'Hook execution failed', 'error message sanitized');

# Test async hooks (returning Future)
use Future;
my $async_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub {
            my ($input, $tool_use_id, $context, $loop) = @_;
            # Return an immediate Future
            return Future->done({ decision => 'allow', reason => 'Async allowed' });
        },
    ],
);

$future = $async_matcher->run_hooks({}, 'id', {});
isa_ok($future, 'Future', 'async hook returns Future');
$results = $future->get;
is($results->[0]{decision}, 'allow', 'async hook decision returned');
is($results->[0]{reason}, 'Async allowed', 'async hook reason returned');

# Test async hook with failure
my $async_fail_matcher = Claude::Agent::Hook::Matcher->new(
    hooks => [
        sub {
            return Future->fail("Async hook failed");
        },
    ],
);

$future = $async_fail_matcher->run_hooks({}, 'id', {});
$results = $future->get;
is($results->[0]{decision}, 'error', 'async failure caught');
is($results->[0]{error}, 'Hook execution failed', 'async error message sanitized');

# Test Hook::Result factory methods
my $continue_result = Claude::Agent::Hook::Result->proceed();
is($continue_result->{decision}, 'continue', 'Result::proceed()');

my $allow_result = Claude::Agent::Hook::Result->allow(
    updated_input => { modified => 1 },
    reason        => 'Allowed by policy',
);
is($allow_result->{decision}, 'allow', 'Result::allow() decision');
is_deeply($allow_result->{updated_input}, { modified => 1 }, 'Result::allow() updated_input');
is($allow_result->{reason}, 'Allowed by policy', 'Result::allow() reason');

my $deny_result = Claude::Agent::Hook::Result->deny(
    reason => 'Security policy',
);
is($deny_result->{decision}, 'deny', 'Result::deny() decision');
is($deny_result->{reason}, 'Security policy', 'Result::deny() reason');

# Test Hook::Context
my $context = Claude::Agent::Hook::Context->new(
    session_id => 'session-123',
    cwd        => '/home/user/project',
    tool_name  => 'Bash',
    tool_input => { command => 'ls' },
);

isa_ok($context, 'Claude::Agent::Hook::Context');
is($context->session_id, 'session-123', 'context session_id');
is($context->cwd, '/home/user/project', 'context cwd');
is($context->tool_name, 'Bash', 'context tool_name');
is_deeply($context->tool_input, { command => 'ls' }, 'context tool_input');

done_testing();
