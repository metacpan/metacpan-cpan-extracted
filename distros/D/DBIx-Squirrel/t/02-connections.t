use 5.010_001;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Carp qw/croak/;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

BEGIN {
    use_ok('DBIx::Squirrel')                 || print "Bail out!\n";
    use_ok('T::Squirrel', qw/:var diagdump/) || print "Bail out!\n";
}

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

my $dbh;
my $clone;

$dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
isa_ok($dbh, 'DBIx::Squirrel::db');
$dbh->disconnect();

$dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS);
isa_ok($dbh, 'DBIx::Squirrel::db');
$dbh->disconnect();

$dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
isa_ok($dbh, 'DBIx::Squirrel::db');
$clone = DBIx::Squirrel->connect($dbh);
isa_ok($clone, 'DBIx::Squirrel::db');
$clone->disconnect();
$dbh->disconnect();

$dbh = DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS);
isa_ok($dbh, 'DBIx::Squirrel::db');
$clone = DBIx::Squirrel->connect($dbh);
isa_ok($clone, 'DBIx::Squirrel::db');
$clone->disconnect();
$dbh->disconnect();

$dbh   = DBI->connect(@MOCK_DB_CONNECT_ARGS);
$clone = DBIx::Squirrel->connect($dbh);
isa_ok($clone, 'DBIx::Squirrel::db');
$clone->disconnect();
$dbh->disconnect();

$dbh   = DBI->connect(@TEST_DB_CONNECT_ARGS);
$clone = DBIx::Squirrel->connect($dbh);
isa_ok($clone, 'DBIx::Squirrel::db');
$clone->disconnect();
$dbh->disconnect();

done_testing();
