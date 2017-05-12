use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

{
    my $resp = request(GET '/');
    is($resp->content, 0, 'regular request');
}

{
    my $resp = request(GET('/', 'X-Requested-With' => 'foo'));
    is($resp->content, 0, 'request with unknown X-Requested-With');
}

{
    my $resp = request(GET('/', 'X-Requested-With' => 'XMLHttpRequest'));
    is($resp->content, 1, 'XMLHttpRequest');
}

done_testing;
