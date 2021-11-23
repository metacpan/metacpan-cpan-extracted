use strict;
use warnings;
use Test::More tests => 5;
use Plack::Test;
use HTTP::Request::Common;
use FindBin;
use lib "$FindBin::Bin/MyApp/lib";

use_ok 'MyApp';

my $test_app = Plack::Test->create(MyApp->to_app);
my $res;

$res = $test_app->request( GET '/' );
is($res->is_success, 1, '/');

$res = $test_app->request( GET '/users' );
is($res->is_success, 1, '/users');

$res = $test_app->request( GET '/users/thoughts' );
is($res->is_success, 1, '/users/thoughts');

$res = $test_app->request( GET '/services' );
is($res->is_success, 1, '/services');
