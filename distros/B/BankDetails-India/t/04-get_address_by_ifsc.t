use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Cwd;

# Test get_address_by_ifsc method
subtest "Test get_address_by_ifsc method" => sub {
    my $api = BankDetails::India->new();
    my $cwd = getcwd();
    $api->cache_data(CHI->new(driver => 'File', 
                        namespace => 'bankdetails',
                        root_dir => $cwd . '/t/cache/'));

    my $address_01 = $api->get_address_by_ifsc('UTIB0000037');
    ok(defined $address_01, "get_address_by_ifsc for 'UTIB0000037' returns defined address");

    my $address_02 = $api->get_address_by_ifsc('KKBK0005652');
    ok(defined $address_02, "get_address_by_ifsc for 'KKBK0005652' returns defined address");
};

done_testing;