use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Cwd;

# Test get_micr_code_by_ifsc method
subtest "Test get_micr_code_by_ifsc method" => sub {
    my $api = BankDetails::India->new();
    my $cwd = getcwd();
    $api->cache_data(CHI->new(driver => 'File', 
                        namespace => 'bankdetails',
                        root_dir => $cwd . '/t/cache/'));

    my $micr_code = $api->get_micr_code_by_ifsc('UTIB0000037');
    ok(defined $micr_code, "get_micr_code_by_ifsc for 'UTIB0000037' returns defined address");
    like($micr_code, qr/^\d{9}$/, "Returned MICR code has the correct format");
};

done_testing;