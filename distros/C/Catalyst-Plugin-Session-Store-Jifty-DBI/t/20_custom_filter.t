use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
  my @requirements = qw(
    Catalyst::Plugin::Session::State::Cookie
    Test::WWW::Mechanize::Catalyst
    DBD::SQLite
  );

  foreach my $module ( @requirements ) {
    eval "require $module;"
      or plan skip_all => "$module is required for this test";
  }

  $ENV{TESTAPP_SESSION_STORE_JDBI_MONIKER}       = 'DB::Filtered';
  $ENV{TESTAPP_SESSION_STORE_JDBI_SERIALIZATION} = 1;
}

plan 'no_plan';

use Test::WWW::Mechanize::Catalyst 'TestApp';

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;
my @all = ($ua1, $ua2);

$ua1->get('http://localhost/db/setup');  # setup database

$_->get_ok('http://localhost/page', 'initial get') for @all;

$ua1->content_contains('please login', 'ua1 not logged in');
$ua2->content_contains('please login', 'ua2 not logged in');

$ua1->get_ok('http://localhost/login', 'log ua1 in');
$ua1->content_contains('logged in', 'ua1 logged in');

$_->get_ok('http://localhost/page', 'get main page') for @all;

$ua1->content_contains('you are logged in', 'ua1 logged in');
$ua2->content_contains('please login', 'ua2 not logged in');

$ua2->get_ok('http://localhost/login', 'log ua2 in');
$ua2->content_contains('logged in', 'ua2 logged in');

$_->get_ok('http://localhost/page', 'get main page') for @all;

$ua1->content_contains('you are logged in', 'ua1 logged in');
$ua2->content_contains('you are logged in', 'ua2 logged in');

$ua2->get_ok('http://localhost/logout', 'log ua2 out');
$ua2->content_like(qr/logged out/, 'ua2 logged out');
$ua2->content_like(qr/after 1 request/, 'ua2 made 1 request for page in the session');

$_->get_ok('http://localhost/page', 'get main page') for @all;

$ua1->content_contains('you are logged in', 'ua1 logged in');
$ua2->content_contains('please login', 'ua2 not logged in');

$ua1->get_ok('http://localhost/logout', 'log ua1 out');
$ua1->content_like(qr/logged out/, 'ua1 logged out');
$ua1->content_like(qr/after 3 request/, 'ua1 made 3 request for page in the session');

$_->get_ok('http://localhost/page', 'get main page') for @all;

$ua1->content_contains('please login', 'ua1 not logged in');
$ua2->content_contains('please login', 'ua2 not logged in');

END { $ua1 && $ua1->get('http://localhost/db/teardown'); }
