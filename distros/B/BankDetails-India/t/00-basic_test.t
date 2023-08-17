use strict;
use warnings;
use Test::More;
use Test::Exception;
use BankDetails::India;
use Cwd;

BEGIN {
    use_ok( 'BankDetails::India' ) || print "Unable to load module!\n";
}
diag( "Testing BankDetails::India $BankDetails::India::VERSION, Perl $], $^X" );

my $api = BankDetails::India->new();
my $cwd = getcwd();

is($api->VERSION,'1.0','Version test');

is($api->api_url, 'https://ifsc.razorpay.com/', 'get expected API URL match');
dies_ok { $api->api_url('https://someotherurl.com/') } "api_url cannot be modified in readonly mode";

is($api->cache_data->root_dir, $cwd . '/cache/' , 'get expected root_dir correctly');

$api->cache_data(CHI->new(driver => 'File', 
                    namespace => 'bankdetails',
                    root_dir => $cwd . '/t/cache/'));

is($api->cache_data->driver_class, 'CHI::Driver::File', 'expected cache driver set correctly');
is($api->cache_data->root_dir, $cwd . '/t/cache/' , 'expected root_dir set correctly');

done_testing();