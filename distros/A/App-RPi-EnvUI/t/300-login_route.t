use strict;
use warnings;


BEGIN {
    use lib 't/';
    use TestBase;
    config();
    set_testing();
    db_create();
}

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use HTTP::Request::Common;
use Plack::Test;
use App::RPi::EnvUI;

my $test = Plack::Test->create(App::RPi::EnvUI->to_app);

{
    my $res = $test->request(GET '/');
    ok $res->is_success, 'Successful request';
    like $res->content, qr/Temperature/, 'front page loaded ok';
}

unset_testing();
unconfig();
db_remove();
done_testing();

