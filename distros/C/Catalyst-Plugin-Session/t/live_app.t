use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
};

use Test::More;

use lib "t/lib";

use MiniUA;

my $ua1 = MiniUA->new('SessionTestApp');
my $ua2 = MiniUA->new('SessionTestApp');

my $res1 = $ua1->get( 'http://localhost/page');
my $res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'initial get' for $res1, $res2;

like $res1->content, qr/please login/, 'ua1 not logged in';
like $res2->content, qr/please login/, 'ua2 not logged in';

$res1 = $ua1->get( 'http://localhost/login');
ok $res1->is_success, 'log ua1 in';
like $res1->content, qr/logged in/, 'ua1 logged in';

$res1 = $ua1->get( 'http://localhost/page');
$res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'get main page' for $res1, $res2;

like $res1->content, qr/you are logged in/, 'ua1 logged in';
like $res2->content, qr/please login/, 'ua2 not logged in';

$res2 = $ua2->get( 'http://localhost/login');
ok $res2->is_success, 'log ua2 in';
like $res2->content, qr/logged in/, 'ua2 logged in';

$res1 = $ua1->get( 'http://localhost/page');
$res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'get main page' for $res1, $res2;

like $res1->content, qr/you are logged in/, 'ua1 logged in';
like $res2->content, qr/you are logged in/, 'ua2 logged in';

my ( $u1_expires ) = ($res1->content =~ /(\d+)$/);
my ( $u2_expires ) = ($res2->content =~ /(\d+)$/);

sleep 1;

$res1 = $ua1->get( 'http://localhost/page');
$res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'get main page' for $res1, $res2;

like $res1->content, qr/you are logged in/, 'ua1 logged in';
like $res2->content, qr/you are logged in/, 'ua2 logged in';

my ( $u1_expires_updated ) = ($res1->content =~ /(\d+)$/);
my ( $u2_expires_updated ) = ($res2->content =~ /(\d+)$/);

cmp_ok( $u1_expires, "<", $u1_expires_updated, "expiry time updated");
cmp_ok( $u2_expires, "<", $u2_expires_updated, "expiry time updated");

$res2 = $ua2->get( 'http://localhost/logout');
ok $res2->is_success, 'log ua2 out';
like $res2->content, qr/logged out/, 'ua2 logged out';
like $res2->content, qr/after 2 requests/,
    'ua2 made 2 requests for page in the session';

$res1 = $ua1->get( 'http://localhost/page');
$res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'get main page' for $res1, $res2;

like $res1->content, qr/you are logged in/, 'ua1 logged in';
like $res2->content, qr/please login/, 'ua2 not logged in';

$res1 = $ua1->get( 'http://localhost/logout');
ok $res1->is_success, 'log ua1 out';
like $res1->content, qr/logged out/, 'ua1 logged out';
like $res1->content, qr/after 4 requests/,
    'ua1 made 4 requests for page in the session';

$res1 = $ua1->get( 'http://localhost/page');
$res2 = $ua2->get( 'http://localhost/page');
ok $_->is_success, 'get main page' for $res1, $res2;

like $res1->content, qr/please login/, 'ua1 not logged in';
like $res2->content, qr/please login/, 'ua2 not logged in';

my $ua3 = MiniUA->new('SessionTestApp');
my $res3 = $ua3->get( 'http://localhost/login');
ok $res3->is_success, 'log ua3 in';
$res3 = $ua3->get( 'http://localhost/dump_these_loads_session');
ok $res3->is_success;
like $res3->content, qr/NOT/;


my $ua4 = MiniUA->new('SessionTestApp');
my $res4 = $ua4->get( 'http://localhost/page');
ok $res4->is_success, 'initial get';
like $res4->content, qr/please login/, 'ua4 not logged in';
$res4 = $ua4->get( 'http://localhost/login');
ok $res4->is_success, 'log ua4 in';
like $res4->content, qr/logged in/, 'ua4 logged in';

$res4 = $ua4->get( "http://localhost/page");
ok +$res4->is_success, "get page";
my ( $ua4_expires1 ) = ($res4->content =~ /(\d+)$/);
$res4 = $ua4->get( "http://localhost/page");
ok +$res4->is_success, "get page";
my ( $ua4_expires2 ) = ($res4->content =~ /(\d+)$/);
is( $ua4_expires1, $ua4_expires2, 'expires has not changed' );

$res4 = $ua4->get( "http://localhost/change_session_expires");
ok +$res4->is_success, "get page";
$res4 = $ua4->get( "http://localhost/page" );
ok +$res4->is_success, "get page";
my ( $ua4_expires3 ) = ($res4->content =~ /(\d+)$/);
ok( $ua4_expires3 > ( $ua4_expires1 + 30000000), 'expires has been extended' );

done_testing;
