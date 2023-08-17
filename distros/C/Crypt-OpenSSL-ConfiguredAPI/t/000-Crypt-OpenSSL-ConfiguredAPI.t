use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Crypt::OpenSSL::ConfiguredAPI') };

my $api = Crypt::OpenSSL::ConfiguredAPI::get_configured_api();
if($api) {
    ok($api, "API Version was configured as $api");
} else {
    ok(!$api, "No API Version was configured");
}
print $api;
