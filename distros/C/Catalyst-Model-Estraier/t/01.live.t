use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

plan skip_all => 'set ESTRAIER_TEST_LIVE and run http://localhost:1978/node/test, in order to enable this test'
    unless $ENV{ESTRAIER_TEST_LIVE};
plan tests    => 2;

my $res = request('/search?q=foo');
ok $res->is_success;
like $res->content, qr/ok/;
