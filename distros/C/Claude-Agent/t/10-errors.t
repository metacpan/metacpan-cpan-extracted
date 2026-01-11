#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Error;

# Test CLINotFoundError
my $cli_error = Claude::Agent::Error::CLINotFound->new(
    message => 'Claude CLI not found in PATH',
);

isa_ok($cli_error, 'Claude::Agent::Error::CLINotFound');
isa_ok($cli_error, 'Claude::Agent::Error');
is($cli_error->message, 'Claude CLI not found in PATH', 'CLINotFound message');

# Test to_string
like($cli_error->to_string, qr/Claude CLI not found/, 'CLINotFound to_string');

# Test stringification overload
like("$cli_error", qr/CLINotFound.*Claude CLI not found/, 'stringification works');

# Test ProcessError
my $process_error = Claude::Agent::Error::ProcessError->new(
    message   => 'Process exited unexpectedly',
    exit_code => 1,
    stderr    => 'Error: something went wrong',
);

isa_ok($process_error, 'Claude::Agent::Error::ProcessError');
is($process_error->message, 'Process exited unexpectedly', 'ProcessError message');
is($process_error->exit_code, 1, 'ProcessError exit_code');
is($process_error->stderr, 'Error: something went wrong', 'ProcessError stderr');

# Test ProcessError without optional fields
$process_error = Claude::Agent::Error::ProcessError->new(
    message => 'Process failed',
);
ok(!$process_error->has_exit_code, 'ProcessError exit_code optional');
ok(!$process_error->has_stderr, 'ProcessError stderr optional');

# Test JSONDecodeError
my $json_error = Claude::Agent::Error::JSONDecodeError->new(
    message => 'Invalid JSON',
    line    => '{"broken: json',
);

isa_ok($json_error, 'Claude::Agent::Error::JSONDecodeError');
is($json_error->message, 'Invalid JSON', 'JSONDecodeError message');
is($json_error->line, '{"broken: json', 'JSONDecodeError line');

# Test TimeoutError
my $timeout_error = Claude::Agent::Error::TimeoutError->new(
    message    => 'Operation timed out',
    timeout_ms => 30000,
);

isa_ok($timeout_error, 'Claude::Agent::Error::TimeoutError');
is($timeout_error->message, 'Operation timed out', 'TimeoutError message');
is($timeout_error->timeout_ms, 30000, 'TimeoutError timeout_ms');

# Test PermissionDeniedError
my $perm_error = Claude::Agent::Error::PermissionDenied->new(
    message   => 'Permission denied',
    tool_name => 'Bash',
);

isa_ok($perm_error, 'Claude::Agent::Error::PermissionDenied');
is($perm_error->message, 'Permission denied', 'PermissionDenied message');
is($perm_error->tool_name, 'Bash', 'PermissionDenied tool_name');

# Test HookError
my $hook_error = Claude::Agent::Error::HookError->new(
    message    => 'Hook execution failed',
    hook_event => 'PreToolUse',
);

isa_ok($hook_error, 'Claude::Agent::Error::HookError');
is($hook_error->message, 'Hook execution failed', 'HookError message');
is($hook_error->hook_event, 'PreToolUse', 'HookError hook_event');

# Test error inheritance for exception handling
eval { die $cli_error };
isa_ok($@, 'Claude::Agent::Error', 'CLINotFound can be caught as Error');

eval { die $process_error };
isa_ok($@, 'Claude::Agent::Error', 'ProcessError can be caught as Error');

eval { die $json_error };
isa_ok($@, 'Claude::Agent::Error', 'JSONDecodeError can be caught as Error');

eval { die $timeout_error };
isa_ok($@, 'Claude::Agent::Error', 'TimeoutError can be caught as Error');

eval { die $perm_error };
isa_ok($@, 'Claude::Agent::Error', 'PermissionDenied can be caught as Error');

eval { die $hook_error };
isa_ok($@, 'Claude::Agent::Error', 'HookError can be caught as Error');

# Test throw() class method
eval { Claude::Agent::Error::CLINotFound->throw(message => 'not found') };
isa_ok($@, 'Claude::Agent::Error::CLINotFound', 'throw() creates and dies with error');

# Test using errors in try/catch pattern
use Try::Tiny;

my $caught_type;
try {
    die Claude::Agent::Error::CLINotFound->new(message => 'not found');
}
catch {
    if ($_->isa('Claude::Agent::Error::CLINotFound')) {
        $caught_type = 'cli_not_found';
    }
    elsif ($_->isa('Claude::Agent::Error')) {
        $caught_type = 'generic_error';
    }
};

is($caught_type, 'cli_not_found', 'can catch specific error types');

done_testing();
