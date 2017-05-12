use strict;
use Test::More tests => 10;
BEGIN { 
    use_ok('Apache2::FakeRequest');
};
use Apache2::Const qw( OK DECLINED REDIRECT SERVER_ERROR );

#########################

my $hostname = "foobar.com";
my $uri      = "/foobar";
my $params   = { test_param_1 => '1', test_param_2 => '2' };
my $r        = Apache2::FakeRequest->new( hostname => $hostname );
is( $r->hostname, $hostname, 'Hostname set correctly.' );

$r = Apache2::FakeRequest->new(
    hostname => $hostname,
    uri      => $uri,
    param    => $params
);
is( $r->uri, $uri, 'URI set correctly.' );
is( ref $r->param, 'HASH', 'Param method returns hash.' );
is( $r->param('test_param_1'), 1, 'Param(test_param_1) returns correctly.' );
ok( !$r->param('test'), 'Param(test) returns undef correctly.' );

# Test some basic Apache2::Const variables
is( OK, 0, 'Apache2::Const::OK returns 0.' );
is( DECLINED, -1, 'Apache2::Const::DECLINED returns -1.' );
is( REDIRECT, 302, 'Apache2::Const::REDIRECT returns 302.' );
is( SERVER_ERROR, 500, 'Apache2::Const::SERVER_ERROR returns 500.' );
