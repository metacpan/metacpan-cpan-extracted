use lib qw(./t blib/lib);
use strict;
use DBConnector;
use MakeAndLoad;
use Test::More qw(no_plan);

my $DATABASE = shift;
$DATABASE or $DATABASE = 'ctd_unittest';

my $dbc = new DBConnector();
my $dbh = $dbc->connect();
my $ext = $dbh->selectall_arrayref("SELECT datname FROM pg_database WHERE datname='$DATABASE'");
#$dbh->do("DROP DATABASE $DATABASE") if $ext;

my $mal = new MakeAndLoad;
$mal->create_db(3);

is(1,1,'instantiation test');