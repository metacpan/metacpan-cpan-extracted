# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02-dbi.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
my $tests;
BEGIN { $tests = 22; plan tests => $tests };

my $dbh;
eval 'use DBI; $dbh = DBI->connect("dbi:DBM:");';
unless($dbh) {
	for(1 .. $tests) {
		skip("Skip DBI, DBD::DBM not available ($@)");
	}
} else {

$dbh->{RaiseError} = 1;
# Set up environment
$dbh->do("DROP TABLE IF EXISTS fruit")
	or die($dbh->errstr());
$dbh->do("CREATE TABLE fruit (dkey INT, dval VARCHAR(10))")
	or die($dbh->errstr());

pass("Database handle created");

#########################

my $a = 1;
my $b = 2;
my $c = 3;
my $d = 'oranges';
my $e = q('";);
my $f = 'to delete';
my $g = 'apples';

{
use DBIx::InterpolationBinding;

# Try an insert
ok($dbh->execute("INSERT INTO fruit VALUES ($a,$d)"), "Insert #1");
ok($dbh->execute("INSERT INTO fruit VALUES ($b,$e)"), "Insert #2");
ok($dbh->execute("INSERT INTO fruit VALUES ($c,$f)"), "Insert #3");

# And an update
$sth = $dbh->execute("UPDATE fruit SET dval=$g WHERE dkey=$b");
ok($sth, "Update query returned a handle");
is($sth->rows, 1, "Update handle has one row");
$sth->finish if $sth;

# And a delete
$sth = $dbh->execute("DELETE FROM fruit WHERE dval=$f");
ok($sth, "Delete query returned a handle");
is($sth->rows, 1, "Delete handle has one row");

# Try a select
my $row;
$sth = $dbh->execute("SELECT * FROM fruit WHERE dval = $g");
ok($sth, "Simple select query returned a handle");
is($sth->rows, 1, "Simple select handle has one row");
ok($row = $sth->fetchrow_hashref, "Simple select row exists");
is($row->{dkey}, $b, "Simple select key is correct");
is($row->{dval}, $g, "Simple select value is correct");
$sth->finish if $sth;

# And a loop
foreach my $type ($d, $g) {
	$sth = $dbh->execute("SELECT * FROM fruit WHERE dval = $type");
	ok($sth, "Loop select ($type) query returned a handle");
	is($sth->rows, 1, "Loop select ($type) handle has one row");
	ok($row = $sth->fetchrow_hashref, "Loop select ($type) row exists");
	is($row->{dval}, $type, "Loop select ($type) value is correct");
}

}

# Can't work outside scope? - the eval should fail as the string isn't
# overloaded.
eval {
	$dbh->{PrintError} = 0;
	my $sth = $dbh->execute("SELECT * FROM fruit WHERE dval = $c");
	$sth->finish;
};
ok($@);

# Cleanup
$dbh->do("DROP TABLE fruit");

}
