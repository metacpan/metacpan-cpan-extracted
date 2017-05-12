use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

{
    use Catalyst::Test 'TestAppLocalNonDefault';
    my ($res, $c) = ctx_request('/tester/get_static_uri');
    is($res->content, 'http://localhost/static/foo.png');
}

done_testing;