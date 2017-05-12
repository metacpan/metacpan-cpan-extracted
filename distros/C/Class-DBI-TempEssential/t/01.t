#! perl -w
use strict;
use Test::More;
$| = 1;

BEGIN {
        eval "use DBD::SQLite";
        plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 9);
}

INIT {
    use lib 't/testlib';
    use TestTable;
}

BEGIN {
    use_ok('Class::DBI::TempEssential');
}

my @orgEssential = TestTable->_essential;
my $row = TestTable->retrieve('id1');
my @allvalues = map { $row->$_ } TestTable->columns;

my @newEssential = qw(id ess1);

my $tmpEss;
ok($tmpEss = new Class::DBI::TempEssential('TestTable', @newEssential),
   "init Essential");

my @tmpEssential = TestTable->_essential;
ok(eq_array(\@newEssential, \@tmpEssential), "temp essential columns");
$row = TestTable->retrieve('id1');
my @tmpAllValues = map {  $row->$_ } TestTable->columns;
ok(eq_array(\@allvalues, \@tmpAllValues), "temp all columns");

my @newEssential2 = qw(id ess2);
my $tmpEss2;
ok($tmpEss2 = new Class::DBI::TempEssential('TestTable', @newEssential2),
   "init Essential 2");
my @tmpEssential2 = TestTable->_essential;
ok(eq_array(\@newEssential2, \@tmpEssential2), "temp essential columns 2");
$row = TestTable->retrieve('id1');
my @tmpAllValues2 = map {  $row->$_ } TestTable->columns;
ok(eq_array(\@allvalues, \@tmpAllValues2), "temp all columns 2");
$tmpEss2 = undef;

$tmpEss = undef;
@tmpEssential = TestTable->_essential;
ok(eq_array(\@orgEssential, \@tmpEssential), "after temp essential columns");
$row = TestTable->retrieve('id1');
@tmpAllValues = map {  $row->$_ } TestTable->columns;
ok(eq_array(\@allvalues, \@tmpAllValues), "after temp all columns");

