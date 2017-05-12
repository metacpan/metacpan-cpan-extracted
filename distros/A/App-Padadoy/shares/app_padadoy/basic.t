use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use_ok('YOUR_MODULE');

my $app = YOUR_MODULE->new;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    ok $res->content, "Non-empty response at '/'"; 
    like $res->code, qr{^[23]..$}, "HTTP status is 2xx or 3xx at '/'";
};

done_testing;
