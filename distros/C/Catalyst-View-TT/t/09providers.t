use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_includepath?view=Providerconfig&template=test.tt"))->is_success, 'provider request');
cmp_ok($response->content, 'eq', 'Faux-tastic!', 'provider worked');


ok(($response = request("/test_includepath?view=Providerconfig&template=testpath.tt&additionalpath=test_include_path"))->is_success, 'provider request');
cmp_ok($response->content, 'eq', 'Faux-tastic!', 'provider worked');
