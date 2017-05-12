use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_HEAD GET_BODY);

plan tests => 14;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $got=GET_HEAD( "/TestSession__002output_headers?type=text/plain;rc=302;loc=/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: /-S:[^/]+/index\.html!m ),
    "Location on REDIRECT" );

$got=~m!^#?Location: /-S:([^/]+)/index\.html$!m;
my $session=$1;

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=http://$hostport/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: http://\Q$hostport\E/-S:[^/]+/index\.html!m ),
    "Location on REDIRECT and full uri" );

$got=GET_HEAD( "/-S:$session/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=http://$hostport/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: http://\Q$hostport\E/-S:\Q$session\E/index\.html!m ),
    "Location on REDIRECT and full uri with session" );

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=http://$hostport/-S:$session/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: http://\Q$hostport\E/-S:[^/]+/index\.html!m ),
    "Location on REDIRECT and full uri without session but session in redirect" );

$got=GET_HEAD( "/-S:$session/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=http://$hostport/-S:$session/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: http://\Q$hostport\E/-S:\Q$session\E/index\.html!m ),
    "Location on REDIRECT and full uri with session and session in redirect" );

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: /-S:[^/]+/TestSession__002output_headers/bla/\.\./index\.html!m ),
    "Location on REDIRECT and relative uri" );

sleep 2;
$got=GET_HEAD( "///-S:$session/TestSession__002output_headers?type=text/plain;rc=302;loc=/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: /-S:\Q$session\E/index\.html!m ),
    "Location on REDIRECT with existing session" );

$got=GET_HEAD( "///-S:$session/TestSession__002output_headers?type=text/plain;rc=302;loc=../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: \.\./index\.html!m ),
    "Location on REDIRECT with existing session and relative uri" );

$got=GET_HEAD( "/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/-S:[^/]+/index\.html!m ),
    "Refresh" );

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;refresh=10%3B+URL%3D../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/-S:[^/]+/TestSession__002output_headers/bla/\.\./index\.html!m ),
    "Refresh and relative uri" );

$got=GET_HEAD( "///-S:$session/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/-S:\Q$session\E/index\.html!m ),
    "Refresh with existing session" );

$got=GET_HEAD( "///-S:$session/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D/-S:$session/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/-S:\Q$session\E/index\.html!m ),
    "Refresh with existing session and session in Refresh header" );

$got=GET_HEAD( "/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D/-S:$session/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/-S:[^/]+/index\.html!m ),
    "Refresh without session but session in Refresh header" );

$got=GET_HEAD( "///-S:$session/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=\.\./index\.html!m ),
    "Refresh with existing session and relative uri" );

# Local Variables: #
# mode: cperl #
# End: #
