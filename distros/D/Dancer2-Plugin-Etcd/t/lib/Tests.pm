package Tests;

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Dancer2::Plugin::Etcd;
use HTTP::Request::Common;
use Plack::Test;
use TestApp;
use Data::Dumper;

my ( $app, $jar, $test );

sub run_tests {
    my ( $req, $res, $history );

    my $settings = shift;
    {
        use Dancer2 appname => 'TestApp';
        foreach my $key ( keys %$settings ) {
            set $key => $settings->{$key};
        }
    }

    $app = TestApp->to_app;
    ok ref($app) eq 'CODE', "Got an app";

    $test = Plack::Test->create($app);

    my $uri = "http://localhost";

    $req = GET "$uri/etcd/put", "X-Requested-With" => "XMLHttpRequest";
    $res = $test->request($req);
    ok( $res->is_success, "get /etcd/key/test OK" );

    $req = GET "$uri/etcd/range", "X-Requested-With" => "XMLHttpRequest";
    $res = $test->request($req);
    ok( $res->is_success, "get /etcd/users OK" );
}
1;


