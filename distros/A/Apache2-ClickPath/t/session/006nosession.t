use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest qw'GET_BODY GET_HEAD';

plan tests => 17;

Apache::TestRequest::user_agent
  (reset => 1, agent=>'Googlebot/2.1 (+http://www.google.com/bot.html)');

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION" ),
	  qr/^SESSION=Google$/m,  ), "SESSION is Google";

ok t_cmp( GET_BODY( "/TestSession__001session_generation?CGI_SESSION" ),
	  qr/^CGI_SESSION=$/m ), "CGI_SESSION is empty";

ok t_cmp( GET_BODY( "/TestSession__001session_generation?SESSION_AGE" ),
	  qr/^SESSION_AGE=0$/m ), "SESSION_AGE=0";

my $got=GET_HEAD( "/TestSession__002output_headers?type=text/plain;rc=302;loc=/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: /index\.html!m ),
    "Location on REDIRECT" );

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;rc=302;loc=../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Location: \.\./index\.html!m ),
    "Location on REDIRECT and relative uri" );

$got=GET_HEAD( "/TestSession__002output_headers?type=text/plain;refresh=10%3B+URL%3D/index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=/index\.html!m ),
    "Refresh" );

$got=GET_HEAD( "/TestSession__002output_headers/bla/blub?type=text/plain;refresh=10%3B+URL%3D../index.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!^#?Refresh: 10; URL=\.\./index\.html!m ),
    "Refresh and relative uri" );

$got=GET_BODY( "/tmp/x.html", redirect_ok=>0 );
ok( t_cmp( $got, qr!<meta http-equiv="refresh" content="10; URL=/index1\.html">! ),
    "meta 1" );
ok( t_cmp( $got, qr!<meta content="10; URL=/index3\.html" http-equiv="refresh">! ),
    "meta 3" );
ok( t_cmp( $got, qr!<meta content="10; URL=http://\Q$hostport\E/index4\.html" http-equiv="refresh">! ),
    "meta 4" );
ok( t_cmp( $got, qr!<meta content="10; URL=\.\./index5\.html" http-equiv="refresh">! ),
    "meta 5" );

ok( t_cmp( $got, qr!<a href="/index1\.html">1</a>! ),
    "a 1" );
ok( t_cmp( $got, qr!<a href="http://\Q$hostport\E/index1\.html">2</a>! ),
    "a 2" );
ok( t_cmp( $got, qr!<a href="\.\./index1\.html">3</a>! ),
    "a 3" );

ok( t_cmp( $got, qr!<form action="/index1\.html">1</form>! ),
    "form 1" );
ok( t_cmp( $got, qr!<form action="http://\Q$hostport\E/index1\.html">2</form>! ),
    "form 2" );
ok( t_cmp( $got, qr!<form action="\.\./index1\.html">3</form>! ),
    "form 3" );

# Local Variables: #
# mode: cperl #
# End: #
