#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use Future;
use IO::Async::Loop;

use Claude::Agent::Hook qw(:events);
use Claude::Agent::Hook::Registry;

# constants
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
is($STOP_FAILURE, 'StopFailure', 'exported STOP_FAILURE');
is($POST_COMPACT, 'PostCompact', 'exported POST_COMPACT');
is($PERMISSION_DENIED, 'PermissionDenied', 'exported PERMISSION_DENIED');
is($SETUP, 'Setup', 'exported SETUP');
is(scalar @EVENTS, 26, 'twenty-six events');
is_deeply([grep { $_ eq 'ElicitationResult' } @EVENTS], ['ElicitationResult'], 'EVENTS has ElicitationResult');

# Hook::Result shapes
is_deeply(Claude::Agent::Hook::Result->proceed, {}, 'proceed is an empty hash');
is_deeply(
    Claude::Agent::Hook::Result->allow(updated_input => { modified => 1 }, reason => 'Allowed by policy'),
    { hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow',
        permissionDecisionReason => 'Allowed by policy', updatedInput => { modified => 1 } } },
    'allow shape',
);
is_deeply(
    Claude::Agent::Hook::Result->deny(reason => 'Security policy'),
    { hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny',
        permissionDecisionReason => 'Security policy' } },
    'deny shape',
);
is_deeply(
    Claude::Agent::Hook::Result->ask(reason => 'Check first', event => 'PermissionRequest'),
    { hookSpecificOutput => { hookEventName => 'PermissionRequest', permissionDecision => 'ask',
        permissionDecisionReason => 'Check first' } },
    'ask shape with an event',
);
is(Claude::Agent::Hook::Result->defer->{hookSpecificOutput}{permissionDecision}, 'defer', 'defer shape');
is_deeply(Claude::Agent::Hook::Result->block(reason => 'keep going'), { decision => 'block', reason => 'keep going' }, 'block shape');
my $stop = Claude::Agent::Hook::Result->stop(reason => 'enough');
is($stop->{stopReason}, 'enough', 'stop reason');
ok(ref $stop->{continue} && !${$stop->{continue}}, 'stop continue is JSON false');
is_deeply(
    Claude::Agent::Hook::Result->add_context('note', event => 'UserPromptSubmit'),
    { hookSpecificOutput => { hookEventName => 'UserPromptSubmit', additionalContext => 'note' } },
    'add_context shape',
);
is_deeply(
    Claude::Agent::Hook::Result->update_tool_output('new output'),
    { hookSpecificOutput => { hookEventName => 'PostToolUse', updatedToolOutput => 'new output' } },
    'update_tool_output shape',
);
is_deeply(Claude::Agent::Hook::Result->system_message('hi'), { systemMessage => 'hi' }, 'system_message shape');
ok(${ Claude::Agent::Hook::Result->suppress_output->{suppressOutput} }, 'suppress_output is JSON true');
is(Claude::Agent::Hook::Result->async(timeout => 30)->{asyncTimeout}, 30, 'async timeout');
is_deeply(
    Claude::Agent::Hook::Result->merge(
        Claude::Agent::Hook::Result->add_context('note', event => 'PreToolUse'),
        Claude::Agent::Hook::Result->allow(reason => 'ok'),
        Claude::Agent::Hook::Result->system_message('m'),
    ),
    { systemMessage => 'm', hookSpecificOutput => { hookEventName => 'PreToolUse', additionalContext => 'note',
        permissionDecision => 'allow', permissionDecisionReason => 'ok' } },
    'merge combines hookSpecificOutput',
);

# Hook::Matcher
my $matcher = Claude::Agent::Hook::Matcher->new(
    matcher => 'Bash',
    hooks   => [sub { Claude::Agent::Hook::Result->proceed }],
    timeout => 30,
);
isa_ok($matcher, 'Claude::Agent::Hook::Matcher');
is($matcher->timeout, 30, 'timeout set correctly');
ok($matcher->matches('Bash'), 'matches exact tool name');
ok(!$matcher->matches('Read'), 'does not match different tool');
ok(!$matcher->matches('BashOutput'), 'exact match does not match partial');
ok(!$matcher->matches(undef), 'undef never matches');

my $regex_matcher = Claude::Agent::Hook::Matcher->new(matcher => 'mcp__.*');
ok($regex_matcher->matches('mcp__math__calculate'), 'regex matches mcp tool');
ok(!$regex_matcher->matches('Read'), 'regex does not match non-mcp tool');
ok(!$regex_matcher->has_timeout, 'no timeout by default');
is_deeply($regex_matcher->hooks, [], 'hooks default to an empty list');

my $catch_all = Claude::Agent::Hook::Matcher->new;
ok($catch_all->matches('anything'), 'no matcher matches anything');
ok(!Claude::Agent::Hook::Matcher->new(matcher => '(a+)+$')->matches('aaaa'), 'nested quantifiers are refused');
ok(!Claude::Agent::Hook::Matcher->new(matcher => 'x' x 1001)->matches('x'), 'an over-long pattern is refused');
ok(Claude::Agent::Hook::Matcher->new(matcher => 'Write|Edit')->matches('Edit'), 'alternation works');

# Hook::Context
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
my $bare = Claude::Agent::Hook::Context->new(session_id => undef, cwd => undef);
ok(!$bare->has_session_id, 'undef session_id is absent');

# Hook::Registry
my @log;
my $loop = IO::Async::Loop->new;
my $registry = Claude::Agent::Hook::Registry->new(
    loop  => $loop,
    hooks => {
        PreToolUse => [
            Claude::Agent::Hook::Matcher->new(
                matcher => 'Bash',
                timeout => 5,
                hooks   => [
                    sub { push @log, 'a'; Claude::Agent::Hook::Result->deny(reason => 'no') },
                    sub { push @log, 'b'; undef },
                ],
            ),
            Claude::Agent::Hook::Matcher->new(
                hooks => [sub {
                    my ($input, $tool_use_id, $ctx, $given_loop) = @_;
                    push @log, "c:$input->{tool_name}:$tool_use_id:" . $ctx->hook_event_name . ":" . ($ctx->tool_use_id // '');
                    is($given_loop, $loop, 'the loop is the fourth argument');
                    is($ctx->loop, $loop, 'the loop is on the context');
                    return Future->done(Claude::Agent::Hook::Result->add_context('ctx'));
                }],
            ),
        ],
        Stop => [
            Claude::Agent::Hook::Matcher->new(hooks => [sub { { decision => 'continue' } }]),
        ],
        PostToolUse => [
            Claude::Agent::Hook::Matcher->new(hooks => [
                sub { die "boom\n" },
                sub { Future->fail("later boom") },
                sub { Future->new },
                sub { { decision => 'deny', reason => 'old style' } },
            ]),
        ],
    },
);
is_deeply($registry->callback_ids, [map { "hook_$_" } 0 .. 7], 'ids in registration order');
is_deeply(
    $registry->to_initialize_config,
    {
        PostToolUse => [{ matcher => undef, hookCallbackIds => [qw(hook_0 hook_1 hook_2 hook_3)] }],
        PreToolUse  => [
            { matcher => 'Bash', hookCallbackIds => [qw(hook_4 hook_5)], timeout => 5 },
            { matcher => undef, hookCallbackIds => ['hook_6'] },
        ],
        Stop        => [{ matcher => undef, hookCallbackIds => ['hook_7'] }],
    },
    'initialize config',
) or diag explain $registry->to_initialize_config;

my $input = { hook_event_name => 'PreToolUse', tool_name => 'Bash', tool_input => { command => 'ls' }, session_id => 's1', cwd => '/x' };
my $f = $registry->run('hook_4', $input, 'toolu_1');
isa_ok($f, 'Future');
is_deeply($f->get, Claude::Agent::Hook::Result->deny(reason => 'no'), 'sync result passes through');
is_deeply($registry->run('hook_5', $input, 'toolu_1')->get, {}, 'undef becomes an empty hash');
is_deeply($registry->run('hook_6', $input, 'toolu_2')->get, Claude::Agent::Hook::Result->add_context('ctx'), 'a Future result is awaited');
is_deeply(\@log, ['a', 'b', 'c:Bash:toolu_2:PreToolUse:toolu_2'], 'callbacks ran with their input');

my $died = $registry->run('hook_0', { hook_event_name => 'PostToolUse' }, 't');
ok($died->is_failed, 'a dying callback fails the Future');
like(scalar $died->failure, qr/boom/, 'with its message');
my $failed = $registry->run('hook_1', {}, 't');
ok($failed->is_failed, 'a failed Future fails');
like(scalar $failed->failure, qr/later boom/, 'with its message');
ok($registry->run('hook_99', {}, 't')->is_failed, 'an unknown id fails');
like(scalar $registry->run('hook_99', {}, 't')->failure, qr/No hook callback found for ID: hook_99/, 'unknown id message');

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    is_deeply($registry->run('hook_7', { hook_event_name => 'Stop' }, undef)->get, {}, 'legacy continue becomes empty');
    is_deeply(
        $registry->run('hook_3', { hook_event_name => 'PostToolUse' }, 't')->get,
        { hookSpecificOutput => { hookEventName => 'PostToolUse', permissionDecision => 'deny', permissionDecisionReason => 'old style' } },
        'legacy deny is translated for its event',
    );
    $registry->run('hook_3', {}, 't')->get;
}
is(scalar @warnings, 2, 'the legacy shape warns once per callback');
like($warnings[0], qr/hook_7 returned the 0\.13 \{decision => 'continue'\} shape/, 'the first warning names continue');
like($warnings[1], qr/hook_3 returned the 0\.13 \{decision => 'deny'\} shape/, 'the second names deny');

# timeout through the loop
my $slow = Claude::Agent::Hook::Registry->new(
    loop  => $loop,
    hooks => { PreToolUse => [Claude::Agent::Hook::Matcher->new(timeout => 0.05, hooks => [sub { $loop->new_future }])] },
);
my $timed = $slow->run('hook_0', {}, 't');
$loop->loop_once(0.02) until $timed->is_ready;
ok($timed->is_failed, 'a slow callback fails on the matcher timeout');
like(scalar $timed->failure, qr/hook_0 timed out after 0\.05s/, 'timeout message');

# no loop, no timeout: a ready Future is fine
my $plain = Claude::Agent::Hook::Registry->new(
    hooks => { PreToolUse => [Claude::Agent::Hook::Matcher->new(timeout => 1, hooks => [sub { Future->done({ a => 1 }) }])] },
);
is_deeply($plain->run('hook_0', {}, 't')->get, { a => 1 }, 'a ready Future without a loop');

done_testing();
