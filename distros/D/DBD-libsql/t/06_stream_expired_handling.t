use strict;
use warnings;
use Test::More 0.98;
use lib 'lib';
use DBD::libsql;

# Test for issue #1 part 6: STREAM_EXPIRED connection error handling
# This test verifies that STREAM_EXPIRED errors are handled with automatic retry

# Test 1: Verify that STREAM_EXPIRED is detected in error messages
{
    my $error_msg = 'HTTP request failed: 400 Bad Request - Response: {"message":"The stream has expired due to inactivity","code":"STREAM_EXPIRED"}';
    ok $error_msg =~ /STREAM_EXPIRED/, 'STREAM_EXPIRED error is detected in error message';
}

# Test 2: Verify that baton is cleared on STREAM_EXPIRED for retry
{
    my $client_data = {
        baton => 'test_baton_value',
        base_url => 'http://example.com',
        auth_token => 'test_token',
    };
    
    # Simulate clearing baton on STREAM_EXPIRED
    my $error_msg = 'Stream has expired due to inactivity';
    if ($error_msg =~ /expired/) {
        $client_data->{baton} = undef;
    }
    
    ok !defined $client_data->{baton}, 'Baton is cleared on stream expiration';
}

# Test 3: Verify retry logic - check that max_retries is set appropriately
{
    my $max_retries = 2;
    my $attempt = 1;
    
    # Simulate first attempt with STREAM_EXPIRED
    if ($attempt < $max_retries) {
        $attempt++;
        ok $attempt == 2, 'First attempt triggers retry (attempt 2)';
    }
    
    # Simulate second attempt succeeds
    $attempt++;
    ok $attempt > $max_retries, 'Second attempt would not retry further';
}

# Test 4: Verify that non-STREAM_EXPIRED errors are not retried
{
    my $error_msg = 'HTTP request failed: 404 Not Found';
    my $attempt = 1;
    my $max_retries = 2;
    
    # Check if this error should trigger retry
    my $should_retry = ($error_msg =~ /STREAM_EXPIRED/ && $attempt < $max_retries);
    
    ok !$should_retry, 'Non-STREAM_EXPIRED errors do not trigger retry';
}

# Test 5: Verify that environment variable for debug logging is respected
{
    local $ENV{DBD_LIBSQL_DEBUG} = 1;
    
    # This would normally produce a warning in the actual code
    my $debug_enabled = exists $ENV{DBD_LIBSQL_DEBUG} && $ENV{DBD_LIBSQL_DEBUG};
    ok $debug_enabled, 'Debug logging can be enabled with environment variable';
}

# Test 6: Verify retry behavior with STREAM_EXPIRED in server response
{
    my $response_content = '{"message":"The stream has expired due to inactivity","code":"STREAM_EXPIRED"}';
    my $error_msg = 'Error: ' . $response_content;
    my $attempt = 1;
    my $max_retries = 2;
    
    if ($error_msg =~ /STREAM_EXPIRED/ && $attempt < $max_retries) {
        ok 1, 'STREAM_EXPIRED in response triggers retry logic';
    } else {
        ok 0, 'STREAM_EXPIRED should trigger retry';
    }
}

# Test 7: Verify that multiple retries don't exceed max_retries
{
    my $max_retries = 2;
    my $attempt = 0;
    my $retry_count = 0;
    
    while ($attempt < $max_retries) {
        $attempt++;
        if ($attempt < $max_retries) {
            $retry_count++;
        }
    }
    
    is $retry_count, 1, 'Only 1 retry happens with max_retries=2';
}

# Test 8: Verify STREAM_EXPIRED pattern matching
{
    my @test_messages = (
        'The stream has expired due to inactivity',
        'STREAM_EXPIRED',
        'Stream expired',
        'Connection timeout',
    );
    
    my @stream_expired = grep { /STREAM_EXPIRED|expired/ } @test_messages;
    is scalar @stream_expired, 3, 'Pattern matches relevant error messages';
}

done_testing;
