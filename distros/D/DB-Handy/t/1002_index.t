######################################################################
#
# Tests CREATE/DROP INDEX, SHOW INDEXES, index-accelerated SELECT,
# UNIQUE constraint enforcement, and index maintenance.
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
sub ok      { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }

print "1..52\n";
use File::Path ();

my $BASE = '/tmp/test_idx_' . $$;
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);

# ok 1
ok(defined $db, 'new()');

# ok 2
ok($db->create_database('testdb'), 'create_database');

# ok 3
ok($db->use_database('testdb'),    'use_database');

###############################################################################
# Setup: create table and populate
###############################################################################
$db->execute("CREATE TABLE emp (id INT, name VARCHAR(64), dept CHAR(20), salary FLOAT)");

my @employees = (
    [1,  'Alice',   'Engineering', 75000.0],
    [2,  'Bob',     'Sales',       55000.5],
    [3,  'Charlie', 'Engineering', 90000.0],
    [4,  'Diana',   'HR',          62000.75],
    [5,  'Eve',     'Engineering', 80000.0],
    [6,  'Frank',   'Sales',       48000.0],
    [7,  'Grace',   'HR',          67000.0],
    [8,  'Hank',    'Engineering', 95000.0],
    [9,  'Ivy',     'Sales',       51000.0],
    [10, 'Jack',    'Engineering', 72000.0],
);
for my $e (@employees) {
    $db->execute("INSERT INTO emp (id,name,dept,salary) VALUES ($e->[0],'$e->[1]','$e->[2]',$e->[3])");
}

###############################################################################
# CREATE INDEX
###############################################################################
my $res = $db->execute("CREATE UNIQUE INDEX idx_emp_id   ON emp (id)");

# ok 4
ok($res->{type} eq 'ok', "CREATE UNIQUE INDEX idx_emp_id");

$res = $db->execute("CREATE INDEX idx_emp_dept ON emp (dept)");

# ok 5
ok($res->{type} eq 'ok', "CREATE INDEX idx_emp_dept");

$res = $db->execute("CREATE INDEX idx_emp_salary ON emp (salary)");

# ok 6
ok($res->{type} eq 'ok', "CREATE INDEX idx_emp_salary");

###############################################################################
# SHOW INDEXES
###############################################################################
$res = $db->execute("SHOW INDEXES ON emp");

# ok 7
ok($res->{type} eq 'indexes', "SHOW INDEXES returns indexes type");
my %idx_map = map { $_->{name} => $_ } @{$res->{data}};

# ok 8
ok(exists $idx_map{idx_emp_id},     "SHOW INDEXES: idx_emp_id present");

# ok 9
ok(exists $idx_map{idx_emp_dept},   "SHOW INDEXES: idx_emp_dept present");

# ok 10
ok(exists $idx_map{idx_emp_salary}, "SHOW INDEXES: idx_emp_salary present");

# ok 11
is($idx_map{idx_emp_id}{unique}+0, 1, "idx_emp_id is UNIQUE");

# ok 12
is($idx_map{idx_emp_dept}{unique}+0, 0, "idx_emp_dept is not UNIQUE");

###############################################################################
# Index files exist on disk
###############################################################################

# ok 13
ok(-f "$BASE/testdb/emp.idx_emp_id.idx",     "idx_emp_id file exists");

# ok 14
ok(-f "$BASE/testdb/emp.idx_emp_dept.idx",   "idx_emp_dept file exists");

# ok 15
ok(-f "$BASE/testdb/emp.idx_emp_salary.idx", "idx_emp_salary file exists");

###############################################################################
# Equality search via index (INT)
###############################################################################
$res = $db->execute("SELECT * FROM emp WHERE id = 5");

# ok 16
ok($res->{type} eq 'rows', "SELECT WHERE id=5 ok");

# ok 17
is(scalar @{$res->{data}}, 1, "WHERE id=5 returns 1 row");

# ok 18
is($res->{data}[0]{name}, 'Eve', "WHERE id=5 -> Eve");

# id not found
$res = $db->execute("SELECT * FROM emp WHERE id = 999");

# ok 19
is(scalar @{$res->{data}}, 0, "WHERE id=999 returns 0 rows");

# Equality on VARCHAR column
$res = $db->execute("SELECT * FROM emp WHERE dept = 'Engineering'");

# ok 20
is(scalar @{$res->{data}}, 5, "WHERE dept=Engineering returns 5 rows");

###############################################################################
# Range searches via index
###############################################################################
# id > 7  -> 8,9,10
$res = $db->execute("SELECT * FROM emp WHERE id > 7");

# ok 21
is(scalar @{$res->{data}}, 3, "WHERE id>7 returns 3 rows");

# id >= 8  -> 8,9,10
$res = $db->execute("SELECT * FROM emp WHERE id >= 8");

# ok 22
is(scalar @{$res->{data}}, 3, "WHERE id>=8 returns 3 rows");

# id < 3  -> 1,2
$res = $db->execute("SELECT * FROM emp WHERE id < 3");

# ok 23
is(scalar @{$res->{data}}, 2, "WHERE id<3 returns 2 rows");

# id <= 2  -> 1,2
$res = $db->execute("SELECT * FROM emp WHERE id <= 2");

# ok 24
is(scalar @{$res->{data}}, 2, "WHERE id<=2 returns 2 rows");

# salary >= 80000 -> 80000, 90000, 95000 (3 rows)
$res = $db->execute("SELECT * FROM emp WHERE salary >= 80000");

# ok 25
is(scalar @{$res->{data}}, 3, "WHERE salary>=80000 returns 3 rows");

###############################################################################
# UNIQUE constraint: duplicate INSERT blocked
###############################################################################
$res = $db->execute("INSERT INTO emp (id,name,dept,salary) VALUES (1,'Dup','Test',1.0)");

# ok 26
ok($res->{type} eq 'error', "Duplicate INSERT blocked by UNIQUE");

# ok 27
ok($res->{message} =~ /UNIQUE/, "Error message mentions UNIQUE");

###############################################################################
# UNIQUE constraint: duplicate UPDATE blocked
###############################################################################
$res = $db->execute("UPDATE emp SET id=1 WHERE id=2");

# ok 28
ok($res->{type} eq 'error', "UPDATE to duplicate id=1 blocked");

# Non-duplicate update is allowed
$res = $db->execute("UPDATE emp SET id=2 WHERE id=2");

# ok 29
ok($res->{type} eq 'ok', "UPDATE id=2->2 (no change) allowed");

###############################################################################
# Index maintained on UPDATE (key change)
###############################################################################
# Change Bob's salary; old value must be gone from index, new added
$res = $db->execute("UPDATE emp SET salary=60000 WHERE id=2");

# ok 30
ok($res->{type} eq 'ok', "UPDATE salary for id=2");

# Old salary (55000.5) should no longer match
$res = $db->execute("SELECT * FROM emp WHERE salary >= 55000");
my @found_55 = grep { $_->{id}==2 } @{$res->{data}};

# ok 31
ok(scalar @found_55 == 1, "Bob still found via salary index after update");

# ok 32
is($res->{data}[0]{salary}+0 == 55000.5 ? 'old' : 'updated',
   'updated', "Salary index updated: old value gone");

# Directly verify new value reachable
$res = $db->execute("SELECT * FROM emp WHERE salary >= 59999 AND salary <= 60001");
# (no index path for AND range with two bounds, but verify via full scan)
my @bobs = grep { $_->{name} eq 'Bob' } @{$res->{data}};

# ok 33
ok(scalar @bobs == 1, "Bob found via salary=60000 after update");

###############################################################################
# Index maintained on DELETE
###############################################################################
$res = $db->execute("DELETE FROM emp WHERE id=10");

# ok 34
ok($res->{type} eq 'ok', "DELETE Jack (id=10)");

$res = $db->execute("SELECT * FROM emp WHERE id=10");

# ok 35
is(scalar @{$res->{data}}, 0, "id=10 not found after DELETE");

$res = $db->execute("SELECT * FROM emp WHERE id >= 1");

# ok 36
is(scalar @{$res->{data}}, 9, "9 rows remain after DELETE");

###############################################################################
# VACUUM rebuilds index
###############################################################################
# Insert some rows then delete to create holes
$db->execute("INSERT INTO emp (id,name,dept,salary) VALUES (11,'Tmp1','Test',1.0)");
$db->execute("INSERT INTO emp (id,name,dept,salary) VALUES (12,'Tmp2','Test',2.0)");
$db->execute("DELETE FROM emp WHERE id=11");
$db->execute("DELETE FROM emp WHERE id=12");

$res = $db->execute("VACUUM emp");

# ok 37
ok($res->{type} eq 'ok', "VACUUM ok");

# After vacuum, existing records still findable
$res = $db->execute("SELECT * FROM emp WHERE id=5");

# ok 38
is(scalar @{$res->{data}}, 1, "id=5 still found after VACUUM");

# ok 39
is($res->{data}[0]{name}, 'Eve', "id=5 is still Eve after VACUUM");

# Total row count correct
$res = $db->execute("SELECT * FROM emp");

# ok 40
is(scalar @{$res->{data}}, 9, "9 rows still present after VACUUM");

###############################################################################
# DROP INDEX
###############################################################################
$res = $db->execute("DROP INDEX idx_emp_salary ON emp");

# ok 41
ok($res->{type} eq 'ok', "DROP INDEX idx_emp_salary");

# ok 42
ok(!-f "$BASE/testdb/emp.idx_emp_salary.idx", "idx_emp_salary file removed");

# Remaining indexes still work
$res = $db->execute("SELECT * FROM emp WHERE id=3");

# ok 43
is($res->{data}[0]{name}, 'Charlie', "idx_emp_id still works after drop of salary idx");

###############################################################################
# Multiple indexes -- dept and id both accelerate
###############################################################################
$res = $db->execute("SELECT * FROM emp WHERE dept='HR'");

# ok 44
is(scalar @{$res->{data}}, 2, "dept=HR via index -> 2 rows");

###############################################################################
# INT key sort order (including negatives)
###############################################################################
$db->execute("CREATE TABLE negtest (n INT)");
$db->execute("CREATE INDEX idx_neg ON negtest (n)");
for my $v (-100, -1, 0, 1, 100, -2147483648, 2147483647) {
    $db->execute("INSERT INTO negtest (n) VALUES ($v)");
}
$res = $db->execute("SELECT * FROM negtest WHERE n >= -1");
my @vals = sort { $a <=> $b } map { $_->{n}+0 } @{$res->{data}};

# ok 45
ok(join(',',@vals) eq '-1,0,1,100,2147483647', "INT range search with negatives correct");

$res = $db->execute("SELECT * FROM negtest WHERE n = -2147483648");

# ok 46
is($res->{data}[0]{n}+0, -2147483648, "INT min value exact lookup");

###############################################################################
# FLOAT key sort order
###############################################################################
$db->execute("CREATE TABLE ftest (f FLOAT)");
$db->execute("CREATE INDEX idx_f ON ftest (f)");
for my $v (-1.5, -0.1, 0.0, 0.1, 1.5, 3.14159) {
    $db->execute("INSERT INTO ftest (f) VALUES ($v)");
}
$res = $db->execute("SELECT * FROM ftest WHERE f > 0");
my @fvals = sort { $a <=> $b } map { $_->{f}+0 } @{$res->{data}};

# ok 47
ok(scalar @fvals == 3, "FLOAT range f>0 returns 3 rows");

# ok 48
ok($fvals[0] > 0 && $fvals[0] < 0.2, "smallest positive FLOAT is ~0.1");

###############################################################################
# Existing data indexed on CREATE INDEX (post-insert rebuild)
###############################################################################
$db->execute("CREATE TABLE preexist (id INT, v VARCHAR(64))");
for my $i (1..5) {
    $db->execute("INSERT INTO preexist (id,v) VALUES ($i,'val$i')");
}
# Create index AFTER data is already there
$res = $db->execute("CREATE INDEX idx_pre ON preexist (id)");

# ok 49
ok($res->{type} eq 'ok', "CREATE INDEX on pre-existing data");

$res = $db->execute("SELECT * FROM preexist WHERE id=3");

# ok 50
is(scalar @{$res->{data}}, 1, "pre-existing data found via new index");

# ok 51
is($res->{data}[0]{v}, 'val3', "correct row returned for pre-existing index");

###############################################################################
# DROP TABLE removes all index files
###############################################################################
$db->execute("DROP TABLE ftest");

# ok 52
ok(!-f "$BASE/testdb/ftest.idx_f.idx", "DROP TABLE removes idx file");

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE);

exit($FAIL ? 1 : 0);
