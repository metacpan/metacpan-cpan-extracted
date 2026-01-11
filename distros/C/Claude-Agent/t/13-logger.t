#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Test module loads
use_ok('Claude::Agent::Logger');
use_ok('Log::Any');

# Test get_logger returns a Log::Any proxy
my $log = Claude::Agent::Logger::get_logger();
isa_ok($log, 'Log::Any::Proxy', 'get_logger returns Log::Any::Proxy');

# Test get_logger with category
my $log2 = Claude::Agent::Logger::get_logger('My::Category');
isa_ok($log2, 'Log::Any::Proxy', 'get_logger with category returns Log::Any::Proxy');

# Test that logging methods exist
can_ok($log, qw(trace debug info notice warning error critical alert emergency));

# Test logging doesn't die (even if adapter discards)
eval {
    $log->debug("Test debug message");
    $log->info("Test info message");
    $log->warning("Test warning message");
};
ok(!$@, 'logging methods do not die');

# Test that Claude::Agent::Logger exports $log directly
{
    package TestModule;
    use Claude::Agent::Logger '$log';

    sub do_something {
        $log->debug("Doing something");
        return 1;
    }
}

ok(TestModule::do_something(), 'Claude::Agent::Logger exports $log to modules');

# Test env var level parsing (integration test)
# Note: Full integration tests for env var configuration require isolated
# subprocesses since adapter configuration happens at import time.
# These are tested manually or in a separate integration test suite.

# Test file output adapter setup
SKIP: {
    skip "File adapter test requires Log::Any::Adapter::File", 1
        unless eval { require Log::Any::Adapter::File; 1 };

    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;

    # In a real test, we'd need to set env vars before loading the module
    # This just tests that the adapter can be set
    eval {
        require Log::Any::Adapter;
        Log::Any::Adapter->set('File', $filename, log_level => 'debug');
    };
    ok(!$@, 'File adapter can be configured') or diag($@);
}

done_testing();
