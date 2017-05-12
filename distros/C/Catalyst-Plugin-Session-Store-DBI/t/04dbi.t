#!perl

use strict;
use warnings;
use DBI;
use File::Path;
use FindBin;
use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie is required for this test";

    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is required for this test";

    eval { require DBD::SQLite }
      or plan skip_all => "DBD::SQLite is required for this test";

    plan tests => 30;
}

# create the database
my $db_file = "$FindBin::Bin/tmp/session.db";
unless ( -e $db_file ) {
    mkdir "$FindBin::Bin/tmp" or die $!;
    my $sql =
      'CREATE TABLE sessions (id TEXT PRIMARY KEY, s_data TEXT, expires INT);';
    my $dbh = DBI->connect("dbi:SQLite:$db_file") or die $DBI::errstr;
    $dbh->do($sql);
    $dbh->disconnect;
}

use lib "$FindBin::Bin/lib";
use Test::WWW::Mechanize::Catalyst "TestApp";

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;

$_->get_ok( "http://localhost/page", "initial get" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

$ua1->get_ok( "http://localhost/login", "log ua1 in" );
$ua1->content_contains( "logged in", "ua1 logged in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua2->get_ok( "http://localhost/login", "get main page" );
$ua2->content_contains( "logged in", "log ua2 in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "you are logged in", "ua2 logged in" );

$ua2->get_ok( "http://localhost/logout", "log ua2 out" );
$ua2->content_like( qr/logged out/, "ua2 logged out" );
$ua2->content_like( qr/after 1 request/,
    "ua2 made 1 request for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua1->get_ok( "http://localhost/logout", "log ua1 out" );
$ua1->content_like( qr/logged out/, "ua1 logged out" );
$ua1->content_like( qr/after 3 requests/,
    "ua1 made 3 request for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

# Clean up
rmtree "$FindBin::Bin/tmp";
