use strict;

use Apache::Test qw(:withtestmore);
use Test::More;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 12;

Apache::TestRequest::module('default');

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

my $got=GET_BODY( "/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr!<a href="/-S:\S+/">! ), "/tmp/ -- parent directory w/o session" );
ok( t_cmp( $got, qr!<a href="/-S:\S+/tmp/x\.html">! ), "/tmp/ -- x.html w/o session" );

$got=~m!<a href="(/-S:\S+)/tmp/x\.html">!;
my $session=$1;
t_debug( "using session: $session" );

$got=GET_BODY( "$session/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr!<a href="\Q$session\E/">! ), "/tmp/ -- parent directory w/ session" );
ok( t_cmp( $got, qr!<a href="x\.html">! ), "/tmp/ -- x.html w/ session" );

sleep 6;

$got=GET_BODY( "$session/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr#<a href="(?!\Q$session\E)/-S:\S+/"># ), "/tmp/ -- parent directory w/ expired session" );
ok( t_cmp( $got, qr#<a href="(?!\Q$session\E)/-S:\S+/tmp/x\.html"># ), "/tmp/ -- x.html w/ expired session" );

Apache::TestRequest::module('Secret');

$config   = Apache::Test::config();
$hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

$got=GET_BODY( "/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr!<a href="/-S:\S+/">! ), "/tmp/ -- parent directory w/o session (Secret)" );
ok( t_cmp( $got, qr!<a href="/-S:\S+/tmp/x\.html">! ), "/tmp/ -- x.html w/o session (Secret)" );

$got=~m!<a href="(/-S:\S+)/tmp/x\.html">!;
$session=$1;
t_debug( "using session: $session" );

$got=GET_BODY( "$session/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr!<a href="\Q$session\E/">! ), "/tmp/ -- parent directory w/ session (Secret)" );
ok( t_cmp( $got, qr!<a href="x\.html">! ), "/tmp/ -- x.html w/ session (Secret)" );

sleep 6;

$got=GET_BODY( "$session/tmp/", redirect_ok=>0 );
ok( t_cmp( $got, qr#<a href="(?!\Q$session\E)/-S:\S+/"># ), "/tmp/ -- parent directory w/ expired session (Secret)" );
ok( t_cmp( $got, qr#<a href="(?!\Q$session\E)/-S:\S+/tmp/x\.html"># ), "/tmp/ -- x.html w/ expired session (Secret)" );

# Local Variables: #
# mode: cperl #
# End: #
