######################################################################
#
# Tests for three bug fixes:
#
#   Fix 1: CHECK constraint is now evaluated on UPDATE (not INSERT only)
#   Fix 2: Index used for AND two-sided range and BETWEEN queries
#   Fix 3: fetchrow_arrayref / NAME reflect SELECT column order
#
# All tests use Perl 5.005_03-compatible syntax (no 'our', no say,
# no given/when, no //, no qr with modifiers unavailable in 5.005).
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
sub ok  { my($c,$n)=@_; $T++; $c ? ($PASS++,print "ok $T - $n\n")
                                  : ($FAIL++,print "not ok $T - $n\n") }
sub is  { my($g,$e,$n)=@_; $T++;
          defined($g) && ("$g" eq "$e")
            ? ($PASS++, print "ok $T - $n\n")
            : ($FAIL++, print "not ok $T - $n  (got='${\ (defined $g?$g:'undef')}', exp='$e')\n") }

print "1..60\n";

use File::Path ();
my $BASE = "/tmp/test_fixes_$$";
File::Path::rmtree($BASE) if -d $BASE;

###############################################################################
# Setup
###############################################################################
my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('ftest');
$db->use_database('ftest');

###############################################################################
# Fix 1 -- CHECK constraint enforced on UPDATE
###############################################################################
$db->execute("CREATE TABLE ck (id INT NOT NULL, salary INT CHECK (salary >= 0), score INT CHECK (score <= 100))");
my $r = $db->execute("INSERT INTO ck (id,salary,score) VALUES (1,50000,80)");
# ok 1
ok($r->{type} eq 'ok', "Fix1: INSERT valid row ok");

$r = $db->execute("INSERT INTO ck (id,salary,score) VALUES (2,-1,50)");
# ok 2
ok($r->{type} eq 'error', "Fix1: INSERT negative salary blocked");

# UPDATE violation: salary goes negative
$r = $db->execute("UPDATE ck SET salary=-1 WHERE id=1");
# ok 3
ok($r->{type} eq 'error', "Fix1: UPDATE salary=-1 blocked by CHECK");
# ok 4
ok($r->{message} =~ /CHECK/, "Fix1: UPDATE error mentions CHECK");

# UPDATE violation: score exceeds limit
$r = $db->execute("UPDATE ck SET score=101 WHERE id=1");
# ok 5
ok($r->{type} eq 'error', "Fix1: UPDATE score=101 blocked by CHECK");

# UPDATE to boundary value: allowed
$r = $db->execute("UPDATE ck SET salary=0 WHERE id=1");
# ok 6
ok($r->{type} eq 'ok', "Fix1: UPDATE salary=0 (boundary) ok");
$r = $db->execute("SELECT salary FROM ck WHERE id=1");
# ok 7
is($r->{data}[0]{salary}+0, 0, "Fix1: salary=0 stored correctly");

# UPDATE to boundary score: allowed
$r = $db->execute("UPDATE ck SET score=100 WHERE id=1");
# ok 8
ok($r->{type} eq 'eq' || $r->{type} eq 'ok', "Fix1: UPDATE score=100 (boundary) ok");
$r = $db->execute("UPDATE ck SET score=100 WHERE id=1");
# ok 9
ok($r->{type} eq 'ok', "Fix1: UPDATE score=100 ok");

# UPDATE valid positive salary
$r = $db->execute("UPDATE ck SET salary=99000 WHERE id=1");
# ok 10
ok($r->{type} eq 'ok', "Fix1: UPDATE salary=99000 ok");
$r = $db->execute("SELECT salary FROM ck WHERE id=1");
# ok 11
is($r->{data}[0]{salary}+0, 99000, "Fix1: salary=99000 verified");

# UPDATE only non-CHECK column: not blocked
$db->execute("CREATE TABLE ck2 (id INT NOT NULL, val INT CHECK (val >= 10), note VARCHAR(20))");
$db->execute("INSERT INTO ck2 (id,val,note) VALUES (1,50,'ok')");
$r = $db->execute("UPDATE ck2 SET note='updated' WHERE id=1");
# ok 12
ok($r->{type} eq 'ok', "Fix1: UPDATE non-CHECK column not blocked");
$r = $db->execute("UPDATE ck2 SET val=9 WHERE id=1");
# ok 13
ok($r->{type} eq 'error', "Fix1: UPDATE CHECK column to invalid value blocked");

###############################################################################
# Fix 2 -- Index used for AND range and BETWEEN
###############################################################################
$db->execute("CREATE TABLE rng (id INT, v FLOAT)");
$db->execute("CREATE INDEX idx_rng_id ON rng (id)");
$db->execute("CREATE INDEX idx_rng_v  ON rng (v)");
for my $i (1..50) {
    my $v = $i * 0.5;
    $db->execute("INSERT INTO rng (id,v) VALUES ($i,$v)");
}

# AND range: id > 10 AND id < 20  (exclusive: 11..19 = 9 rows)
$r = $db->execute("SELECT id FROM rng WHERE id > 10 AND id < 20");
# ok 14
is(scalar @{$r->{data}}, 9, "Fix2: id > 10 AND id < 20 returns 9 rows");

# AND range: id >= 10 AND id <= 20  (inclusive: 10..20 = 11 rows)
$r = $db->execute("SELECT id FROM rng WHERE id >= 10 AND id <= 20");
# ok 15
is(scalar @{$r->{data}}, 11, "Fix2: id >= 10 AND id <= 20 returns 11 rows");

# AND range reversed: id < 20 AND id > 10
$r = $db->execute("SELECT id FROM rng WHERE id < 20 AND id > 10");
# ok 16
is(scalar @{$r->{data}}, 9, "Fix2: reversed AND (id < 20 AND id > 10) returns 9 rows");

# BETWEEN inclusive: id BETWEEN 10 AND 20  (10..20 = 11 rows)
$r = $db->execute("SELECT id FROM rng WHERE id BETWEEN 10 AND 20");
# ok 17
is(scalar @{$r->{data}}, 11, "Fix2: id BETWEEN 10 AND 20 returns 11 rows");

# BETWEEN single value: id BETWEEN 5 AND 5 (1 row)
$r = $db->execute("SELECT id FROM rng WHERE id BETWEEN 5 AND 5");
# ok 18
is(scalar @{$r->{data}}, 1, "Fix2: id BETWEEN 5 AND 5 returns 1 row");
# ok 19
is($r->{data}[0]{id}+0, 5, "Fix2: BETWEEN 5 AND 5 -> id=5");

# BETWEEN empty range (inverted): id BETWEEN 20 AND 10 (0 rows)
$r = $db->execute("SELECT id FROM rng WHERE id BETWEEN 20 AND 10");
# ok 20
is(scalar @{$r->{data}}, 0, "Fix2: BETWEEN inverted range returns 0 rows");

# Correctness: AND range values match
$r = $db->execute("SELECT id FROM rng WHERE id >= 3 AND id <= 5");
my @ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 21
is(join(',', @ids), '3,4,5', "Fix2: AND range values correct (3,4,5)");

# FLOAT index with AND
$r = $db->execute("SELECT v FROM rng WHERE v >= 2.5 AND v <= 5.0");
my @vs = sort { $a <=> $b } map { $_->{v}+0 } @{$r->{data}};
# ok 22
is(scalar @vs, 6, "Fix2: FLOAT AND range returns 6 rows");
# ok 23
ok($vs[0] > 2.4 && $vs[0] < 2.6, "Fix2: FLOAT AND range lower bound ~2.5");

# Verify index is used correctly: indexed and non-indexed tables return
# identical results for AND range queries (correctness cross-check).
# No external timing module needed -- we validate behaviour, not speed.
$db->execute("CREATE TABLE big (n INT)");
$db->execute("CREATE INDEX idx_big ON big (n)");
for my $i (1..200) { $db->execute("INSERT INTO big (n) VALUES ($i)") }

$db->execute("CREATE TABLE big2 (n INT)");
for my $i (1..200) { $db->execute("INSERT INTO big2 (n) VALUES ($i)") }

my $r_idx  = $db->execute("SELECT n FROM big  WHERE n > 180 AND n <= 200");
my $r_full = $db->execute("SELECT n FROM big2 WHERE n > 180 AND n <= 200");
# ok 24
is(scalar @{$r_idx->{data}}, scalar @{$r_full->{data}},
   "Fix2: indexed AND range returns same count as full-scan");

###############################################################################
# Fix 3 -- fetchrow_arrayref / NAME reflect SELECT column order
###############################################################################
$db->execute("CREATE TABLE emp (id INT, name VARCHAR(40), salary INT, dept VARCHAR(20))");
$db->execute("INSERT INTO emp (id,name,salary,dept) VALUES (1,'Alice',75000,'Eng')");
$db->execute("INSERT INTO emp (id,name,salary,dept) VALUES (2,'Bob',60000,'Mkt')");
$db->execute("INSERT INTO emp (id,name,salary,dept) VALUES (3,'Carol',80000,'Eng')");

my $dbh = DB::Handy->connect($BASE, 'ftest');

# Basic: SELECT salary, name, id  (non-alphabetical order)
my $sth = $dbh->prepare("SELECT salary, name, id FROM emp WHERE id=1");
$sth->execute;
# ok 25
is(join(',', @{$sth->{NAME}}), 'salary,name,id', "Fix3: NAME reflects SELECT order");
my $aref = $sth->fetchrow_arrayref;
# ok 26
is($aref->[0]+0, 75000, "Fix3: arrayref[0] = salary = 75000");
# ok 27
is($aref->[1],   'Alice', "Fix3: arrayref[1] = name = Alice");
# ok 28
is($aref->[2]+0, 1,     "Fix3: arrayref[2] = id = 1");
$sth->finish;

# 4 columns reordered
$sth = $dbh->prepare("SELECT dept, salary, name, id FROM emp WHERE id=2");
$sth->execute;
# ok 29
is(join(',', @{$sth->{NAME}}), 'dept,salary,name,id', "Fix3: NAME 4-col reorder");
$aref = $sth->fetchrow_arrayref;
# ok 30
is($aref->[0], 'Mkt',  "Fix3: arrayref[0] = dept = Mkt");
# ok 31
is($aref->[1]+0, 60000, "Fix3: arrayref[1] = salary = 60000");
$sth->finish;

# AS alias: column name in NAME should be alias
$sth = $dbh->prepare("SELECT salary AS sal, name AS nm, id AS eid FROM emp WHERE id=1");
$sth->execute;
# ok 32
is(join(',', @{$sth->{NAME}}), 'sal,nm,eid', "Fix3: AS alias reflected in NAME");
$aref = $sth->fetchrow_arrayref;
# ok 33
is($aref->[0]+0, 75000, "Fix3: AS alias arrayref[0] = 75000");
# ok 34
is($aref->[1], 'Alice', "Fix3: AS alias arrayref[1] = Alice");
$sth->finish;

# fetchrow_array returns in SELECT order
$sth = $dbh->prepare("SELECT name, id FROM emp WHERE id=1");
$sth->execute;
my @row = $sth->fetchrow_array;
# ok 35
is($row[0], 'Alice', "Fix3: fetchrow_array[0] = name = Alice");
# ok 36
is($row[1]+0, 1,     "Fix3: fetchrow_array[1] = id = 1");
$sth->finish;

# NUM_OF_FIELDS
$sth = $dbh->prepare("SELECT id, name FROM emp WHERE id=1");
$sth->execute;
# ok 37
is($sth->{NUM_OF_FIELDS}+0, 2, "Fix3: NUM_OF_FIELDS=2");
$sth->finish;

# SELECT * falls back to alphabetical (known behavior)
$sth = $dbh->prepare("SELECT * FROM emp WHERE id=1");
$sth->execute;
my @star_names = @{$sth->{NAME}};
# ok 38
ok(scalar @star_names == 4, "Fix3: SELECT * gives 4 columns");
# ok 39
ok($star_names[0] lt $star_names[1], "Fix3: SELECT * is alphabetical");
$sth->finish;

# 0-row result: NAME still set from SQL
$sth = $dbh->prepare("SELECT salary, name FROM emp WHERE id=9999");
$sth->execute;
# ok 40
is(join(',', @{$sth->{NAME}}), 'salary,name', "Fix3: NAME set from SQL even for 0 rows");
# ok 41
is($sth->{NUM_OF_FIELDS}+0, 2, "Fix3: NUM_OF_FIELDS=2 for 0 rows");
$sth->finish;

# Multiple rows: all rows fetchable in SELECT order
$sth = $dbh->prepare("SELECT salary, name FROM emp ORDER BY id");
$sth->execute;
my @all_rows;
while (my $r2 = $sth->fetchrow_arrayref) {
    push @all_rows, [@$r2];
}
$sth->finish;
# ok 42
is(scalar @all_rows, 3, "Fix3: all 3 rows fetched");
# ok 43
is($all_rows[0][0]+0, 75000, "Fix3: row1[0] = salary = 75000");
# ok 44
is($all_rows[0][1], 'Alice',  "Fix3: row1[1] = name = Alice");
# ok 45
is($all_rows[1][0]+0, 60000, "Fix3: row2[0] = salary = 60000");

# fetchall_arrayref without Slice: respects NAME order
$sth = $dbh->prepare("SELECT salary, name FROM emp ORDER BY id");
$sth->execute;
my $all = $sth->fetchall_arrayref;
# ok 46
is($all->[0][0]+0, 75000, "Fix3: fetchall_arrayref[0][0] = 75000");
# ok 47
is($all->[0][1], 'Alice',  "Fix3: fetchall_arrayref[0][1] = Alice");
$sth->finish;

# selectrow_arrayref
my $saref = $dbh->selectrow_arrayref(
    "SELECT salary, name, id FROM emp WHERE id=3");
# ok 48
is($saref->[0]+0, 80000,  "Fix3: selectrow_arrayref[0] = salary = 80000");
# ok 49
is($saref->[1], 'Carol',  "Fix3: selectrow_arrayref[1] = name = Carol");
# ok 50
is($saref->[2]+0, 3,      "Fix3: selectrow_arrayref[2] = id = 3");

###############################################################################
# Fix 1+3 combined: CHECK on UPDATE + column order
###############################################################################
$db->execute("CREATE TABLE combo (id INT NOT NULL, val INT CHECK (val >= 0), note VARCHAR(20))");
$db->execute("INSERT INTO combo (id,val,note) VALUES (1,10,'start')");

# CHECK blocks bad UPDATE (fix 1)
$r = $db->execute("UPDATE combo SET val=-1 WHERE id=1");
# ok 51
ok($r->{type} eq 'error', "Fix1+3: CHECK still works after column order changes");

# Fetch in SELECT order (fix 3)
$sth = $dbh->prepare("SELECT note, val, id FROM combo WHERE id=1");
$sth->execute;
# ok 52
is(join(',', @{$sth->{NAME}}), 'note,val,id', "Fix1+3: NAME order note,val,id");
$aref = $sth->fetchrow_arrayref;
# ok 53
is($aref->[0], 'start', "Fix1+3: arrayref[0] = note = start");
# ok 54
is($aref->[1]+0, 10,    "Fix1+3: arrayref[1] = val = 10");
$sth->finish;

###############################################################################
# Fix 2+3 combined: index range + column order in results
###############################################################################
$sth = $dbh->prepare("SELECT name, salary FROM emp WHERE salary >= 70000 AND salary <= 85000");
$sth->execute;
# ok 55
is(join(',', @{$sth->{NAME}}), 'name,salary', "Fix2+3: NAME order name,salary");
my @range_rows;
while (my $r2 = $sth->fetchrow_arrayref) { push @range_rows, [@$r2] }
$sth->finish;
# ok 56
is(scalar @range_rows, 2, "Fix2+3: AND range returns Alice(75k) and Carol(80k)");
my @range_names = sort map { $_->[0] } @range_rows;
# ok 57
is(join(',', @range_names), 'Alice,Carol', "Fix2+3: correct employees in range");

###############################################################################
# Regression: existing functionality unbroken
###############################################################################
# Simple SELECT still works
$r = $db->execute("SELECT * FROM emp WHERE id=1");
# ok 58
is($r->{data}[0]{name}, 'Alice', "Regression: SELECT * WHERE id=1");

# Existing UNIQUE constraint still works
$db->execute("CREATE TABLE uq (id INT)");
$db->execute("CREATE UNIQUE INDEX uq_id ON uq (id)");
$db->execute("INSERT INTO uq (id) VALUES (1)");
$r = $db->execute("INSERT INTO uq (id) VALUES (1)");
# ok 59
ok($r->{type} eq 'error', "Regression: UNIQUE constraint still blocks duplicate");

# JOIN still works
$db->execute("CREATE TABLE dept (did INT, dname VARCHAR(20))");
$db->execute("INSERT INTO dept (did,dname) VALUES (1,'Eng')");
$r = $db->execute(
    "SELECT e.name, d.dname FROM emp AS e " .
    "INNER JOIN dept AS d ON e.id = d.did WHERE e.id=1");
# ok 60
is($r->{data}[0]{'e.name'}, 'Alice', "Regression: JOIN still works");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;

exit($FAIL ? 1 : 0);
