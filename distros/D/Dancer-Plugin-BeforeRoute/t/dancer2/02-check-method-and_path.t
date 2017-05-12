use strict;
use warnings;
use lib "t/dancer2/lib";
use HTTP::Request::Common;
use Plack::Test;
use TestApp;
use Test::More;

my $app = Plack::Test->create( TestApp->to_app );
is $app->request( GET '/' )->content,        "homepage";
is $app->request( GET '/foo' )->content,     "foo", "Test string path";
is $app->request( GET "/foo/baz" )->content, "baz", "Test token path";
is $app->request( POST "/bar" )->content,    "bar", "Test regexp";
is $app->request( POST "/baz" )->code,       404, "Not found";

done_testing;
