use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Test::Exception;
use Cwd;

# Test get_bank_name_by_ifsc method
subtest "Test get_bank_name_by_ifsc method" => sub {
    my $api = BankDetails::India->new();
    my $cwd = getcwd();
    $api->cache_data(CHI->new(driver => 'File', 
                        namespace => 'bankdetails',
                        root_dir => $cwd . '/t/cache/'));

    is($api->get_bank_name_by_ifsc('KKBK0005652'), "Kotak Mahindra Bank", 'expected bank name found by ifsc_code');

    is($api->get_bank_name_by_ifsc('UTIB0001564'), "Axis Bank", 'expected bank name found by ifsc_code');

    dies_ok { $api->get_bank_name_by_ifsc('MANB0004567') } 'Failed to fetch data: 404 Not Found';
};

done_testing;