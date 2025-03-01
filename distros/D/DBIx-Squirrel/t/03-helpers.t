use 5.010_001;
use strict;
use warnings;
use Carp qw/croak/;
use Test::Warn;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok('DBIx::Squirrel', database_entities => [qw(db st)])
        or print "Bail out!\n";
    use_ok('T::Squirrel', qw(:var diagdump))
        or print "Bail out!\n";
}

# Helpers are accessible to the entire module and we will take full
# advantage of that in this test module.

diag("Testing DBIx::Squirrel $DBIx::Squirrel::VERSION, Perl $], $^X");

my $dbh = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
isa_ok(db($dbh), 'DBIx::Squirrel::db');
is(db, $dbh, 'helper ("db") associated');

my $sth = db->prepare('SELECT * FROM artists');
isa_ok(st($sth), 'DBIx::Squirrel::st');
is(st, $sth, 'helper ("st") associated');

done_testing();
