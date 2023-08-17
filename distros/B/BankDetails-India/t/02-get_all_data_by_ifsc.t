use strict;
use warnings;
use BankDetails::India;
use Test::More;
use Cwd;

# Test get_all_data_by_ifsc method
subtest "Test get_all_data_by_ifsc method" => sub {
    my $api = BankDetails::India->new();
    my $cwd = getcwd();
    $api->cache_data(CHI->new(driver => 'File', 
                    namespace => 'bankdetails',
                    root_dir => $cwd . '/t/cache/'));
    my $ifsc_code = 'KKBK0005652';
    my $data = $api->get_all_data_by_ifsc($ifsc_code);

    ok(defined $data, "get_all_data_by_ifsc returns defined data");
    is($data->{IFSC}, $ifsc_code, "Returned data has the correct IFSC code");
};

done_testing;