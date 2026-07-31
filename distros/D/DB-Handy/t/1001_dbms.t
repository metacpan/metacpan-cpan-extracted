######################################################################
#
# Tests CREATE/DROP TABLE, INSERT, SELECT, UPDATE, DELETE, basic WHERE,
# ORDER BY, LIMIT/OFFSET, and vacuum.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
my @OUT;          # buffered ok() lines
my $DONE = 0;     # set once the plan has been emitted
sub ok      { my($c,$n)=@_; $T++; $c ? ($PASS++, push @OUT, "ok $T - $n\n") : ($FAIL++, push @OUT, "not ok $T - $n\n") }
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, push @OUT, "ok $T - $n\n") : ($FAIL++, push @OUT, "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }


###############################################################################
# Clean slate
###############################################################################
use File::Path ();
use File::Spec ();
my $BASE = File::Spec->catdir(File::Spec->tmpdir, "sdbms_dbms_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $db = DB::Handy->new(base_dir => $BASE);

# ok 1
ok(defined $db, "new() returns object");

###############################################################################
# Database operations
###############################################################################

# ok 2
ok($db->create_database('testdb'),      "create_database");

# ok 3
ok(!$db->create_database('testdb'),     "create_database duplicate fails");

# ok 4
ok($db->use_database('testdb'),         "use_database");

# ok 5
ok(!$db->use_database('nosuchdb'),      "use_database missing fails");

my @dbs = $db->list_databases();

# ok 6
ok(scalar(grep { $_ eq 'testdb' } @dbs),"list_databases contains testdb");

###############################################################################
# Table creation
###############################################################################

# ok 7
ok($db->execute("CREATE TABLE emp (id INT, name VARCHAR(64), salary FLOAT, dept CHAR(20), hire DATE)")->{type} eq 'ok',
    "CREATE TABLE via execute");

my @tbls = $db->list_tables();

# ok 8
ok(scalar(grep { $_ eq 'emp' } @tbls),  "list_tables contains emp");

my $cols = $db->describe_table('emp');

# ok 9
ok(ref $cols eq 'ARRAY' && @$cols == 5,  "describe_table returns 5 cols");

# ok 10
is($cols->[0]{name}, 'id',               "first col is id");

# ok 11
is($cols->[0]{type}, 'INT',              "first col type INT");

# ok 12
is($cols->[1]{name}, 'name',             "second col is name");

# ok 13
is($cols->[2]{type}, 'FLOAT',            "third col type FLOAT");

###############################################################################
# INSERT
###############################################################################
for my $row (
    [1, 'Alice',   75000.00, 'Engineering', '2020-01-15'],
    [2, 'Bob',     55000.50, 'Sales',       '2019-06-01'],
    [3, 'Charlie', 90000.00, 'Engineering', '2018-03-20'],
    [4, 'Diana',   62000.75, 'HR',          '2021-09-10'],
    [5, 'Eve',     80000.00, 'Engineering', '2022-11-30'],
) {
    my $res = $db->execute(
        "INSERT INTO emp (id, name, salary, dept, hire) VALUES ($row->[0], '$row->[1]', $row->[2], '$row->[3]', '$row->[4]')");

    # ok 14-18
    ok($res->{type} eq 'ok', "INSERT $row->[1]");
}

###############################################################################
# SELECT all
###############################################################################
my $res = $db->execute("SELECT * FROM emp");

# ok 19
ok($res->{type} eq 'rows',               "SELECT * returns rows");

# ok 20
is(scalar(@{$res->{data}}), 5,           "SELECT * returns 5 rows");

# SELECT with WHERE
$res = $db->execute("SELECT * FROM emp WHERE dept = 'Engineering'");

# ok 21
is(scalar(@{$res->{data}}), 3,           "WHERE dept=Engineering -> 3 rows");

$res = $db->execute("SELECT * FROM emp WHERE salary >= 75000");

# ok 22
is(scalar(@{$res->{data}}), 3,           "WHERE salary>=75000 -> 3 rows");

$res = $db->execute("SELECT * FROM emp WHERE id < 3");

# ok 23
is(scalar(@{$res->{data}}), 2,           "WHERE id<3 -> 2 rows");

# LIKE
$res = $db->execute("SELECT * FROM emp WHERE name LIKE 'A%'");

# ok 24
is(scalar(@{$res->{data}}), 1,           "LIKE 'A%' -> 1 row");

# ok 25
is($res->{data}[0]{name}, 'Alice',       "LIKE result is Alice");

# ORDER BY
$res = $db->execute("SELECT * FROM emp ORDER BY salary DESC");

# ok 26
is($res->{data}[0]{name}, 'Charlie',     "ORDER BY salary DESC -> Charlie first");

# LIMIT / OFFSET
$res = $db->execute("SELECT * FROM emp ORDER BY id LIMIT 2");

# ok 27
is(scalar(@{$res->{data}}), 2,           "LIMIT 2 -> 2 rows");

$res = $db->execute("SELECT * FROM emp ORDER BY id LIMIT 2 OFFSET 2");

# ok 28
is($res->{data}[0]{id}, 3,               "OFFSET 2 -> starts at id=3");

# Column projection
$res = $db->execute("SELECT id, name FROM emp WHERE id = 1");

# ok 29
ok(exists $res->{data}[0]{id},           "projected id exists");

# ok 30
ok(exists $res->{data}[0]{name},         "projected name exists");

# ok 31
ok(!exists $res->{data}[0]{salary},      "projected salary does NOT exist");

###############################################################################
# UPDATE
###############################################################################
my $upd = $db->execute("UPDATE emp SET salary=95000 WHERE id = 3");

# ok 32
is($upd->{message}, "1 row(s) updated",  "UPDATE 1 row");

$res = $db->execute("SELECT * FROM emp WHERE id = 3");

# ok 33
is($res->{data}[0]{salary}+0, 95000,     "UPDATE salary verified");

###############################################################################
# DELETE
###############################################################################
my $del = $db->execute("DELETE FROM emp WHERE id = 5");

# ok 34
is($del->{message}, "1 row(s) deleted",  "DELETE 1 row");

$res = $db->execute("SELECT * FROM emp");

# ok 35
is(scalar(@{$res->{data}}), 4,           "After DELETE -> 4 rows");

###############################################################################
# VACUUM
###############################################################################
my $vac = $db->execute("VACUUM emp");

# ok 36
ok($vac->{type} eq 'ok',                 "VACUUM ok");

$res = $db->execute("SELECT * FROM emp");

# ok 37
is(scalar(@{$res->{data}}), 4,           "After VACUUM still 4 rows");

###############################################################################
# INT boundary: negative numbers
###############################################################################
$db->execute("INSERT INTO emp (id, name, salary, dept, hire) VALUES (-1, 'Neg', -1000, 'Test', '2000-01-01')");
$res = $db->execute("SELECT * FROM emp WHERE id = -1");

# ok 38
is($res->{data}[0]{id}+0, -1,            "Negative INT roundtrip");

# ok 39
is($res->{data}[0]{salary}+0, -1000,     "Negative FLOAT roundtrip");

###############################################################################
# DROP TABLE
###############################################################################

# ok 40
ok($db->execute("DROP TABLE emp")->{type} eq 'ok', "DROP TABLE");
@tbls = $db->list_tables();

# ok 41
ok(!scalar(grep { $_ eq 'emp' } @tbls),  "emp gone after DROP");

###############################################################################
# DROP DATABASE
###############################################################################

# ok 42
ok($db->drop_database('testdb'),         "drop_database");

###############################################################################
# Cleanup
###############################################################################

###############################################################################
# Emit the plan.  The count is taken from the assertions that actually ran,
# so it can never drift out of step with the body the way the former
# hard-coded "1..N" line could.  The ok() lines are buffered in @OUT purely
# so that the plan can still be printed first: a leading plan is what every
# Test::Harness understands, including the one shipped with Perl 5.005_03.
###############################################################################
$DONE = 1;
print "1..$T\n", @OUT;

exit($FAIL ? 1 : 0);

# If the body dies before the plan is emitted, flush whatever did run and
# append one failing assertion, so the harness is handed a complete and
# definitely-failing stream instead of no plan at all.
END {
    unless ($DONE) {
        print '1..' . ($T + 1) . "\n", @OUT;
        print 'not ok ' . ($T + 1) . " - test script aborted before completion\n";
    }
}
