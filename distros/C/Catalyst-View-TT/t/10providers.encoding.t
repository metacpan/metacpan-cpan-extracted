use strict;
use warnings;
use Test::More;

eval "use Template::Provider::Encoding";
if ($@) {
    plan skip_all => 'Template::Provider::Encoding';
} else {
    plan tests => 3;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test_includepath?view=Encoding&template=test.tt&additionalpath=test_include_path"))->is_success, 'provider request');
cmp_ok($response->content, 'eq', 'hi', 'provider worked');

