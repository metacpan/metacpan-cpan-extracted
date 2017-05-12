#!perl -T

use strict;
use warnings;

use lib qw(t/lib inc);
use Test::More;
use FindBin;

BEGIN {
		$ENV{PATH} = '';
    $ENV{TESTAPP_CONFIG_LOCAL_SUFFIX} = 'lighttpd';
};

eval { use Catalyst::View::Reproxy::Test::HTTP::Server; };
plan( skip_all =>
      'HTTP::Server::Simple::CGI, HTTP::Server::Simple::Static required' )
  if ($@);

eval { use Test::WWW::Mechanize::Catalyst 'TestApp'; };
plan $@
  ? ( skip_app => 'Test::WWW:Mechanize::Catalyst required' )
  : ( tests => 8 );

ok(
    my $server = Catalyst::View::Reproxy::Test::HTTP::Server->new(
        { port => 3500, docroot => $FindBin::Bin }
    )
);
ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Create mechanize object' );

my $pid;

if ( $pid = fork ) {
    ok($pid);

    sleep 1;

    $mech->get_ok( 'http://localhost/test/forward/sendfile',
        'request sendfile action' );
    like( $mech->response->header('X-Sendfile'),
        qr/DUMMY/i, 'X-REPROXY-FILE header test' );

    $mech->get_ok( 'http://localhost/test/forward/proxy_file',
        'request reproxy_file action' );
    like( $mech->response->header('X-Sendfile'),
        qr/DUMMY/i, 'X-REPROXY-FILE header test' );

    $mech->get_ok( 'http://localhost/test/forward/proxy_url',
        'request reproxy_url action' );

    kill HUP => $pid;
}
else {
    defined $pid or die;
    $server->run;
}
