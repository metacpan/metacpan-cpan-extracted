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

done_testing();
