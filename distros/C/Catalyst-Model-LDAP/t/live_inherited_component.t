use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestAppInheritedComponent';

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests    => 2;

{
    my $res = request('/search?sn=TEST');
    ok($res->is_success);
    like($res->content, qr/TEST/);
}
