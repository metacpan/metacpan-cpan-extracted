use 5.010_001;
use strict;
use warnings;
use Carp qw/croak/;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
use Test::More::UTF8;

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw/db st/]) || print "Bail out!\n";
    use_ok('T::Squirrel',    qw/:var diagdump/)                || print "Bail out!\n";
}

# Helpers are accessible to the entire module and we will take full
# advantage of that in this test module.

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

my $dbh;
my $sth;

$dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
isa_ok(db($dbh), 'DBIx::Squirrel::db');
is(db, $dbh, 'helper ("db") associated');

$sth = db->prepare('SELECT * FROM artists');
isa_ok(st($sth), 'DBIx::Squirrel::st');
is(st, $sth, 'helper ("st") associated');

done_testing();
