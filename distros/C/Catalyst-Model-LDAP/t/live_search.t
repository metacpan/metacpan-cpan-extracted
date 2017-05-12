use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests    => 6;

{
    my $res = request('/search?sn=TEST');
    ok($res->is_success);
    like($res->content, qr/TEST/);
}

{
    my $res = request('/blarg?sn=TEST');
    ok($res->is_success);
    like($res->content, qr/TEST/);
}

{
    my $res = request('/is_cool?uid=attest1');
    ok($res->is_success);
    like($res->content, qr/attest1 is cool!/);
}
