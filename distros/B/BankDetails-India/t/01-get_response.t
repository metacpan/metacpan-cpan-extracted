use strict;
use warnings; 
use Test::More;
use BankDetails::India;

# Test get_response method
subtest "Test get_response method" => sub {
    my $api = BankDetails::India->new;
    # Check if the user agent is online
    if (! $api->user_agent->is_online) {
        plan skip_all => "User agent is not online, skipping the test";
    }

    my ($got, $expect) = ('', undef);
    $got = $api->get_response();
    is_deeply($got, $expect, 'expect no response');
};

done_testing;