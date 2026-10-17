#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Permission;

# Test permission mode constants
is($Claude::Agent::Permission::MODE_DEFAULT, 'default', 'MODE_DEFAULT constant');
is($Claude::Agent::Permission::MODE_ACCEPT_EDIT, 'acceptEdits', 'MODE_ACCEPT_EDIT constant');
is($Claude::Agent::Permission::MODE_BYPASS, 'bypassPermissions', 'MODE_BYPASS constant');
is($Claude::Agent::Permission::MODE_DONT_ASK, 'dontAsk', 'MODE_DONT_ASK constant');

# Test Permission->allow()
my $allow_result = Claude::Agent::Permission->allow(
    updated_input => { file_path => '/tmp/test.txt' },
);

isa_ok($allow_result, 'Claude::Agent::Permission::Result::Allow');
isa_ok($allow_result, 'Claude::Agent::Permission::Result');
is($allow_result->behavior, 'allow', 'allow result behavior');
is_deeply($allow_result->updated_input, { file_path => '/tmp/test.txt' }, 'allow updated_input');

# Test allow with permissions update
$allow_result = Claude::Agent::Permission->allow(
    updated_input       => { data => 'test' },
    updated_permissions => { 'Read:/tmp/*' => 'allow' },
);

is_deeply(
    $allow_result->updated_permissions,
    { 'Read:/tmp/*' => 'allow' },
    'allow updated_permissions'
);

# Test to_hash for allow
my $allow_hash = $allow_result->to_hash;
is($allow_hash->{behavior}, 'allow', 'to_hash behavior');
is_deeply($allow_hash->{updatedInput}, { data => 'test' }, 'to_hash updatedInput');
is_deeply(
    $allow_hash->{updatedPermissions},
    { 'Read:/tmp/*' => 'allow' },
    'to_hash updatedPermissions'
);

# Test Permission->deny()
my $deny_result = Claude::Agent::Permission->deny(
    message => 'Operation not permitted',
);

isa_ok($deny_result, 'Claude::Agent::Permission::Result::Deny');
isa_ok($deny_result, 'Claude::Agent::Permission::Result');
is($deny_result->behavior, 'deny', 'deny result behavior');
is($deny_result->message, 'Operation not permitted', 'deny message');

# Test deny with interrupt
$deny_result = Claude::Agent::Permission->deny(
    message   => 'Dangerous operation blocked',
    interrupt => 1,
);

ok($deny_result->interrupt, 'deny interrupt flag');

# Test deny without interrupt
my $deny_no_interrupt = Claude::Agent::Permission->deny(
    message   => 'Just denied',
    interrupt => 0,
);

ok(!$deny_no_interrupt->interrupt, 'deny without interrupt');

# Test to_hash for deny
my $deny_hash = $deny_result->to_hash;
is($deny_hash->{behavior}, 'deny', 'deny to_hash behavior');
is($deny_hash->{message}, 'Dangerous operation blocked', 'deny to_hash message');
ok(${$deny_hash->{interrupt}}, 'deny to_hash interrupt is JSON true');

$deny_hash = $deny_no_interrupt->to_hash;
ok(!${$deny_hash->{interrupt}}, 'deny to_hash interrupt is JSON false when off');

# Test Permission::Context
my $context = Claude::Agent::Permission::Context->new(
    session_id => 'session-abc',
    cwd        => '/project',
    tool_name  => 'Write',
    tool_input => { file_path => '/tmp/out.txt', content => 'data' },
);

isa_ok($context, 'Claude::Agent::Permission::Context');
is($context->session_id, 'session-abc', 'context session_id');
is($context->cwd, '/project', 'context cwd');
is($context->tool_name, 'Write', 'context tool_name');
is_deeply(
    $context->tool_input,
    { file_path => '/tmp/out.txt', content => 'data' },
    'context tool_input'
);

# Test realistic can_use_tool callback usage
my $can_use_tool = sub {
    my ($tool_name, $input, $ctx) = @_;

    # Block dangerous bash commands
    if ($tool_name eq 'Bash') {
        my $cmd = $input->{command} // '';
        if ($cmd =~ /rm\s+-rf/) {
            return Claude::Agent::Permission->deny(
                message   => 'Recursive delete not allowed',
                interrupt => 0,
            );
        }
    }

    # Allow writes only to /tmp
    if ($tool_name eq 'Write') {
        my $path = $input->{file_path} // '';
        if ($path !~ m{^/tmp/}) {
            return Claude::Agent::Permission->deny(
                message => 'Can only write to /tmp',
            );
        }
    }

    # Allow everything else
    return Claude::Agent::Permission->allow(
        updated_input => $input,
    );
};

# Test callback with allowed Bash command
my $result = $can_use_tool->('Bash', { command => 'ls -la' }, {});
is($result->behavior, 'allow', 'allowed bash command');

# Test callback with blocked Bash command
$result = $can_use_tool->('Bash', { command => 'rm -rf /' }, {});
is($result->behavior, 'deny', 'blocked dangerous bash command');
is($result->message, 'Recursive delete not allowed', 'correct denial message');

# Test callback with allowed Write
$result = $can_use_tool->('Write', { file_path => '/tmp/test.txt', content => 'hi' }, {});
is($result->behavior, 'allow', 'allowed write to /tmp');

# Test callback with blocked Write
$result = $can_use_tool->('Write', { file_path => '/etc/passwd', content => 'x' }, {});
is($result->behavior, 'deny', 'blocked write outside /tmp');

# Test callback with other tool
$result = $can_use_tool->('Read', { file_path => '/any/path' }, {});
is($result->behavior, 'allow', 'allowed other tools');

# 0.14
is($Claude::Agent::Permission::MODE_PLAN, 'plan', 'MODE_PLAN constant');
is($Claude::Agent::Permission::MODE_AUTO, 'auto', 'MODE_AUTO constant');
is($Claude::Agent::Permission::MODE_MANUAL, 'manual', 'MODE_MANUAL constant');
is_deeply(
    [sort @Claude::Agent::Types::PERMISSION_MODES],
    [sort map { no strict "refs"; ${"Claude::Agent::Permission::$_"} } qw(MODE_DEFAULT MODE_ACCEPT_EDIT MODE_BYPASS MODE_DONT_ASK MODE_PLAN MODE_AUTO MODE_MANUAL)],
    'the constants and the PermissionMode type agree'
);

my $bare_deny = Claude::Agent::Permission->deny;
is($bare_deny->behavior, 'deny', 'deny with no arguments');
ok(!$bare_deny->has_message, 'deny with no message has none');
is_deeply($bare_deny->to_hash, { behavior => 'deny', interrupt => \0 }, 'bare deny to_hash');

my $bare_allow = Claude::Agent::Permission->allow;
ok(!$bare_allow->has_updated_input, 'allow with no input has none');
is_deeply($bare_allow->to_hash, { behavior => 'allow' }, 'bare allow to_hash');
$bare_allow = Claude::Agent::Permission->allow(updated_input => undef);
ok(!$bare_allow->has_updated_input, 'an undef updated_input counts as absent');

my $ctx = Claude::Agent::Permission::Context->new(
    tool_name       => 'Bash',
    tool_input      => {},
    tool_use_id     => 'toolu_1',
    agent_id        => 'agent_1',
    suggestions     => [{ type => 'addRules', rules => [{ toolName => 'Bash' }] }],
    blocked_path    => '/etc',
    decision_reason => 'rule',
    title           => 'Run a command',
);
is($ctx->tool_use_id, 'toolu_1', 'context tool_use_id');
is($ctx->agent_id, 'agent_1', 'context agent_id');
is($ctx->suggestions->[0]{type}, 'addRules', 'context suggestions');
is($ctx->blocked_path, '/etc', 'context blocked_path');
is($ctx->decision_reason, 'rule', 'context decision_reason');
is($ctx->title, 'Run a command', 'context title');
ok(!$ctx->has_session_id, 'context without session_id');
eval { Claude::Agent::Permission::Context->new(tool_name => 'X') };
like($@, qr/Required slot 'tool_input'/, 'tool_input is required');

my $c = Claude::Agent::Permission->coerce({ behavior => 'allow', updatedInput => { a => 1 } });
isa_ok($c, 'Claude::Agent::Permission::Result::Allow');
is_deeply($c->updated_input, { a => 1 }, 'coerce reads updatedInput');
$c = Claude::Agent::Permission->coerce({ behavior => 'deny', message => 'no', interrupt => 1 });
isa_ok($c, 'Claude::Agent::Permission::Result::Deny');
ok($c->interrupt, 'coerce reads interrupt');
is(Claude::Agent::Permission->coerce($c), $c, 'coerce passes a result through');
ok(!defined Claude::Agent::Permission->coerce({ behavior => 'maybe' }), 'coerce rejects an unknown behavior');
ok(!defined Claude::Agent::Permission->coerce('allow'), 'coerce rejects a string');

done_testing();
