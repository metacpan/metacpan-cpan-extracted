use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Cwd;

# Test ping_api method
subtest "Test ping_api method" => sub {
    my $api = BankDetails::India->new;
    # Check if the user agent is online
    if (! $api->user_agent->is_online) {
        plan skip_all => "User agent is not online, skipping the test";
    }

    is($api->ping_api, 1, "ping_api returns true for a successful API call");
};

done_testing;