
use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;
use_ok('Catalyst::Test', 'TestApp');

# render TT
{
    ok my $res = request GET '/render_tt';
    is $res->code, 200;
    is $res->content, "helloworld\n";
    is $res->content_type, 'text/html';
}


done_testing;
