use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Test::Exception;
use Cwd;

# Test get_city_by_ifsc method
subtest "Test get_city_by_ifsc method" => sub {
    my $cwd = getcwd();
    my $api = BankDetails::India->new(
        'cache_data' => CHI->new(
                            driver => 'File', 
                            namespace => 'bankdetails',
                            root_dir => $cwd . '/t/cache/'
                        )
    );

    is($api->get_city_by_ifsc('HDFC0000163'), "GREATER MUMBAI", 'expected city found by ifsc_code');

    is($api->get_city_by_ifsc('UTIB0000037'), "PUNE", 'expected city found by ifsc_code');
};
done_testing;