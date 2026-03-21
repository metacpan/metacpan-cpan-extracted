######################################################################
#
# Tests for two new features:
#
#   Feature 1: Multi-column AND queries exploit an available index
#              on one of the columns (partial AND index pushdown).
#
#   Feature 2: INTERSECT, INTERSECT ALL, EXCEPT, EXCEPT ALL set
#              operations are now supported.
#
# Perl 5.005_03 compatible: no 'our', no say, no //, no given/when,
# no qr with unavailable modifiers, no Time::HiRes.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;

###############################################################################
# Minimal test harness -- no Test::More required
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok  { my($c,$n)=@_; $T++;
          $c ? ($PASS++, print "ok $T - $n\n")
             : ($FAIL++, print "not ok $T - $n\n") }
sub is  { my($g,$e,$n)=@_; $T++;
          defined($g) && ("$g" eq "$e")
            ? ($PASS++, print "ok $T - $n\n")
            : ($FAIL++, print "not ok $T - $n"
               ."  (got='${\ (defined $g ? $g : 'undef')}', exp='$e')\n") }

print "1..69\n";

use File::Path ();
my $BASE = "/tmp/test_idx_setop_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('t');
$db->use_database('t');

###############################################################################
# Feature 1 -- Multi-column AND index pushdown
###############################################################################

# Setup: employees with indexes on dept (equality) and salary (range)
$db->execute("CREATE TABLE emp (id INT, dept VARCHAR(20), salary INT, grade CHAR(2))");
$db->execute("CREATE INDEX idx_dept   ON emp (dept)");
$db->execute("CREATE INDEX idx_salary ON emp (salary)");

my @emp_data = (
    [1, 'Eng', 90000, 'A'],
    [2, 'Mkt', 60000, 'B'],
    [3, 'Eng', 75000, 'A'],
    [4, 'HR',  80000, 'B'],
    [5, 'Eng', 50000, 'C'],
    [6, 'Mkt', 85000, 'A'],
    [7, 'Eng', 95000, 'A'],
    [8, 'HR',  55000, 'C'],
);
for my $row (@emp_data) {
    $db->execute("INSERT INTO emp (id,dept,salary,grade)"
        . " VALUES ($row->[0],'$row->[1]',$row->[2],'$row->[3]')");
}

# -- 1.1: equality index col AND range condition --
my $r = $db->execute("SELECT id FROM emp WHERE dept='Eng' AND salary > 70000");
my @ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 1
is(scalar @ids, 3, "AND: dept=Eng AND salary>70000 -> 3 rows");
# ok 2
is(join(',', @ids), '1,3,7', "AND: correct ids (1,3,7)");

# -- 1.2: reversed order (range col first, equality col second) --
$r = $db->execute("SELECT id FROM emp WHERE salary > 70000 AND dept='Eng'");
my @ids2 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 3
is(scalar @ids2, 3, "AND: salary>70000 AND dept=Eng -> 3 rows");
# ok 4
is(join(',', @ids2), '1,3,7', "AND: reversed order, correct ids");

# -- 1.3: equality AND equality (both indexed) --
$r = $db->execute("SELECT id FROM emp WHERE dept='Mkt' AND salary=85000");
# ok 5
is(scalar @{$r->{data}}, 1, "AND: dept=Mkt AND salary=85000 -> 1 row");
# ok 6
is($r->{data}[0]{id}+0, 6, "AND: correct id=6");

# -- 1.4: equality AND <= --
$r = $db->execute("SELECT id FROM emp WHERE dept='Eng' AND salary <= 75000");
my @ids4 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 7
is(scalar @ids4, 2, "AND: dept=Eng AND salary<=75000 -> 2 rows");
# ok 8
is(join(',', @ids4), '3,5', "AND: correct ids (3,5)");

# -- 1.5: equality AND >= --
$r = $db->execute("SELECT id FROM emp WHERE dept='HR' AND salary >= 80000");
# ok 9
is(scalar @{$r->{data}}, 1, "AND: dept=HR AND salary>=80000 -> 1 row");
# ok 10
is($r->{data}[0]{id}+0, 4, "AND: correct id=4");

# -- 1.6: range AND range on different columns --
$r = $db->execute("SELECT id FROM emp WHERE salary >= 75000 AND salary <= 90000");
# ok 11 (this is a same-column AND range, handled by Case 2)
is(scalar @{$r->{data}}, 4, "AND same-col range: 75000<=salary<=90000 -> 4 rows");

# -- 1.7: three-condition AND (two columns have indexes) --
$r = $db->execute("SELECT id FROM emp WHERE dept='Eng' AND salary > 60000 AND salary < 95000");
my @ids7 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 12
is(scalar @ids7, 2, "AND 3-cond: Eng, 60k<sal<95k -> 2 rows");
# ok 13
is(join(',', @ids7), '1,3', "AND 3-cond: correct ids (1,3)");

# -- 1.8: no index on either column -> full scan, still correct --
$db->execute("CREATE TABLE noidx (a INT, b INT)");
for my $i (1..10) { $db->execute("INSERT INTO noidx (a,b) VALUES ($i," . ($i*2) . ")") }
$r = $db->execute("SELECT a FROM noidx WHERE a > 3 AND b < 14");
my @ni = sort { $a <=> $b } map { $_->{a}+0 } @{$r->{data}};
# ok 14
is(scalar @ni, 3, "AND no-index: a>3 AND b<14 -> 3 rows");
# ok 15
is(join(',', @ni), '4,5,6', "AND no-index: correct (4,5,6)");

# -- 1.9: AND result matches full-scan result (correctness cross-check) --
my $r_and  = $db->execute("SELECT id FROM emp WHERE dept='Mkt' AND salary < 80000");
my $r_full = $db->execute("SELECT id FROM emp WHERE dept='Mkt'");
my @mkt_and  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_and->{data}};
my @mkt_full = grep { my $row = $_; (grep { $_->{id}+0 == $row } @{$r_and->{data}}) } @{$r_full->{data}};
# ok 16
is(scalar @mkt_and, 1, "AND cross-check: Mkt AND salary<80000 -> 1 row");
# ok 17
is($mkt_and[0], 2, "AND cross-check: correct id=2");

# -- 1.10: AND with equality on non-indexed column -> full scan, correct --
$r = $db->execute("SELECT id FROM emp WHERE grade='A' AND salary > 80000");
my @ids10 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 18
is(scalar @ids10, 3, "AND non-indexed col: grade=A AND salary>80000 -> 3 rows");
# ok 19
is(join(',', @ids10), '1,6,7', "AND non-indexed col: correct ids");

###############################################################################
# Feature 2 -- INTERSECT, INTERSECT ALL, EXCEPT, EXCEPT ALL
###############################################################################

# Setup: two simple integer sets
$db->execute("CREATE TABLE s1 (x INT)");
$db->execute("CREATE TABLE s2 (x INT)");
for my $v (1,2,3,4,5)   { $db->execute("INSERT INTO s1 (x) VALUES ($v)") }
for my $v (3,4,5,6,7)   { $db->execute("INSERT INTO s2 (x) VALUES ($v)") }

# -- 2.1: INTERSECT (deduplicates, keeps common rows) --
$r = $db->execute("SELECT x FROM s1 INTERSECT SELECT x FROM s2");
my @ix = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 20
is(scalar @ix, 3, "INTERSECT: 3 common values");
# ok 21
is(join(',', @ix), '3,4,5', "INTERSECT: correct values (3,4,5)");

# -- 2.2: EXCEPT (rows in left but not right, deduplicated) --
$r = $db->execute("SELECT x FROM s1 EXCEPT SELECT x FROM s2");
my @ex = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 22
is(scalar @ex, 2, "EXCEPT: 2 values in s1 but not s2");
# ok 23
is(join(',', @ex), '1,2', "EXCEPT: correct values (1,2)");

# -- 2.3: EXCEPT reversed --
$r = $db->execute("SELECT x FROM s2 EXCEPT SELECT x FROM s1");
my @ex2 = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 24
is(scalar @ex2, 2, "EXCEPT reversed: 2 values in s2 but not s1");
# ok 25
is(join(',', @ex2), '6,7', "EXCEPT reversed: correct (6,7)");

# -- 2.4: INTERSECT with no common rows --
$db->execute("CREATE TABLE s3 (x INT)");
$db->execute("CREATE TABLE s4 (x INT)");
for my $v (1,2) { $db->execute("INSERT INTO s3 (x) VALUES ($v)") }
for my $v (8,9) { $db->execute("INSERT INTO s4 (x) VALUES ($v)") }
$r = $db->execute("SELECT x FROM s3 INTERSECT SELECT x FROM s4");
# ok 26
is(scalar @{$r->{data}}, 0, "INTERSECT: no common rows -> 0 rows");

# -- 2.5: EXCEPT with right superset -> 0 rows --
$r = $db->execute("SELECT x FROM s3 EXCEPT SELECT x FROM s1");
# ok 27
is(scalar @{$r->{data}}, 0, "EXCEPT: left is subset of right -> 0 rows");

# -- 2.6: INTERSECT ALL (preserves duplicates from left) --
$db->execute("CREATE TABLE m1 (x INT)");
$db->execute("CREATE TABLE m2 (x INT)");
for my $v (1,2,2,3,3,3) { $db->execute("INSERT INTO m1 (x) VALUES ($v)") }
for my $v (2,3,3,4)     { $db->execute("INSERT INTO m2 (x) VALUES ($v)") }

$r = $db->execute("SELECT x FROM m1 INTERSECT ALL SELECT x FROM m2");
my @ia = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 28
is(scalar @ia, 3, "INTERSECT ALL: 3 rows (min multiplicity)");
# ok 29
is(join(',', @ia), '2,3,3', "INTERSECT ALL: correct (2,3,3)");

# -- 2.7: EXCEPT ALL (removes with multiplicity) --
$r = $db->execute("SELECT x FROM m1 EXCEPT ALL SELECT x FROM m2");
my @ea = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 30
is(scalar @ea, 3, "EXCEPT ALL: 3 rows remain");
# ok 31
is(join(',', @ea), '1,2,3', "EXCEPT ALL: correct (1,2,3)");

# -- 2.8: INTERSECT with WHERE clause on both sides --
$r = $db->execute(
    "SELECT x FROM s1 WHERE x > 2 INTERSECT SELECT x FROM s2 WHERE x < 5");
my @wix = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 32
is(scalar @wix, 2, "INTERSECT+WHERE: 2 rows");
# ok 33
is(join(',', @wix), '3,4', "INTERSECT+WHERE: correct (3,4)");

# -- 2.9: EXCEPT with WHERE --
# s1 WHERE x>=2 = {2,3,4,5}, s2={3,4,5,6,7} => EXCEPT gives {2}
$r = $db->execute(
    "SELECT x FROM s1 WHERE x >= 2 EXCEPT SELECT x FROM s2");
my @wex2 = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 34
is(scalar @wex2, 1, "EXCEPT+WHERE: s1(x>=2) except s2 -> 1 row");
# ok 35
is($wex2[0], 2, "EXCEPT+WHERE: value is 2");

# -- 2.10: INTERSECT is commutative (unordered) --
my $r_ab = $db->execute("SELECT x FROM s1 INTERSECT SELECT x FROM s2");
my $r_ba = $db->execute("SELECT x FROM s2 INTERSECT SELECT x FROM s1");
my @ab = sort { $a <=> $b } map { $_->{x}+0 } @{$r_ab->{data}};
my @ba = sort { $a <=> $b } map { $_->{x}+0 } @{$r_ba->{data}};
# ok 37
is(join(',', @ab), join(',', @ba), "INTERSECT is commutative");

# -- 2.11: three-way INTERSECT chained --
$db->execute("CREATE TABLE t3a (v INT)");
$db->execute("CREATE TABLE t3b (v INT)");
$db->execute("CREATE TABLE t3c (v INT)");
for my $v (1,2,3,4,5) { $db->execute("INSERT INTO t3a (v) VALUES ($v)") }
for my $v (2,3,4,5,6) { $db->execute("INSERT INTO t3b (v) VALUES ($v)") }
for my $v (3,4,5,6,7) { $db->execute("INSERT INTO t3c (v) VALUES ($v)") }
$r = $db->execute(
    "SELECT v FROM t3a INTERSECT SELECT v FROM t3b INTERSECT SELECT v FROM t3c");
my @tri = sort { $a <=> $b } map { $_->{v}+0 } @{$r->{data}};
# ok 38
is(scalar @tri, 3, "3-way INTERSECT: 3 values");
# ok 39
is(join(',', @tri), '3,4,5', "3-way INTERSECT: correct (3,4,5)");

# -- 2.12: EXCEPT deduplicates the left side --
$db->execute("CREATE TABLE dup (x INT)");
for my $v (1,1,2,2,3) { $db->execute("INSERT INTO dup (x) VALUES ($v)") }
$r = $db->execute("SELECT x FROM dup EXCEPT SELECT x FROM s4");
my @dedup = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 40
is(scalar @dedup, 3, "EXCEPT: left deduplication -> 3 distinct values");
# ok 41
is(join(',', @dedup), '1,2,3', "EXCEPT: correct distinct values");

# -- 2.13: INTERSECT deduplicates --
$r = $db->execute("SELECT x FROM dup INTERSECT SELECT x FROM m1");
my @idup = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 42
is(scalar @idup, 3, "INTERSECT: deduplicated -> 3 distinct values");
# ok 43
is(join(',', @idup), '1,2,3', "INTERSECT: correct (1,2,3)");

# -- 2.14: EXCEPT ALL multiplicity detail --
# m1={1,2,2,3,3,3}, m2={2,3,3,4}
# EXCEPT ALL removes 1x(2) and 2x(3): leaves {1,2,3}
$r = $db->execute("SELECT x FROM m1 EXCEPT ALL SELECT x FROM m2");
my @eam = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 44
is(scalar @eam, 3, "EXCEPT ALL multiplicity: 3 rows");
# ok 45
is(join(',', @eam), '1,2,3', "EXCEPT ALL multiplicity: correct (1,2,3)");

# -- 2.15: INTERSECT ALL with no overlap -> 0 rows --
$r = $db->execute("SELECT x FROM s3 INTERSECT ALL SELECT x FROM s4");
# ok 46
is(scalar @{$r->{data}}, 0, "INTERSECT ALL no overlap: 0 rows");

# -- 2.16: EXCEPT ALL with right empty -> all left rows remain --
$r = $db->execute("SELECT x FROM s3 EXCEPT ALL SELECT x FROM s4");
my @exall = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 47
is(scalar @exall, 2, "EXCEPT ALL right-empty: all left rows remain");
# ok 48
is(join(',', @exall), '1,2', "EXCEPT ALL right-empty: correct (1,2)");

###############################################################################
# Regression: existing UNION / UNION ALL still works
###############################################################################
$r = $db->execute("SELECT x FROM s1 UNION SELECT x FROM s2");
my @uni = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 49
is(scalar @uni, 7, "UNION: 7 distinct values (1-7)");
# ok 50
is(join(',', @uni), '1,2,3,4,5,6,7', "UNION: correct");

$r = $db->execute("SELECT x FROM s3 UNION ALL SELECT x FROM s3");
# ok 51
is(scalar @{$r->{data}}, 4, "UNION ALL: 4 rows (duplicates kept)");

###############################################################################
# Regression: Case 1/2 index usage still works after Case 3 added
###############################################################################
# Case 1: single equality
$r = $db->execute("SELECT id FROM emp WHERE dept='HR'");
# ok 52
is(scalar @{$r->{data}}, 2, "Regression Case1 eq: dept=HR -> 2 rows");

# Case 1: single range
$r = $db->execute("SELECT id FROM emp WHERE salary > 85000");
# ok 53
is(scalar @{$r->{data}}, 2, "Regression Case1 range: salary>85000 -> 2 rows");

# Case 2: same-column AND range
$r = $db->execute("SELECT id FROM emp WHERE salary >= 75000 AND salary <= 90000");
# ok 54
is(scalar @{$r->{data}}, 4, "Regression Case2 same-col AND: 4 rows");

# Case 2: BETWEEN
$r = $db->execute("SELECT id FROM emp WHERE salary BETWEEN 75000 AND 90000");
# ok 55
is(scalar @{$r->{data}}, 4, "Regression Case2 BETWEEN: 4 rows");

###############################################################################
# Feature 1+2 combined: INTERSECT/EXCEPT with AND-filtered operands
###############################################################################
$r = $db->execute(
    "SELECT id FROM emp WHERE dept='Eng' AND salary > 70000 "
    . "INTERSECT "
    . "SELECT id FROM emp WHERE salary < 95000");
my @comb = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 56
is(scalar @comb, 2, "Combined: AND-index+INTERSECT -> 2 rows");
# ok 57
is(join(',', @comb), '1,3', "Combined: correct ids (1,3)");

$r = $db->execute(
    "SELECT id FROM emp WHERE dept='Eng' "
    . "EXCEPT "
    . "SELECT id FROM emp WHERE salary <= 75000");
my @comb2 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 58
is(scalar @comb2, 2, "Combined: AND-index+EXCEPT -> 2 rows");
# ok 59
is(join(',', @comb2), '1,7', "Combined: correct ids (1,7)");

###############################################################################
# Edge: INTERSECT/EXCEPT with ORDER BY on outer query is not required
# (set operations return unordered results; ORDER BY can be applied outside)
###############################################################################
$r = $db->execute(
    "SELECT x FROM s1 INTERSECT SELECT x FROM s2");
# ok 60
ok(ref $r->{data} eq 'ARRAY' && scalar @{$r->{data}} == 3,
   "INTERSECT result is an arrayref of 3 rows");

###############################################################################
# Edge: INTERSECT/EXCEPT with empty result on left
###############################################################################
$r = $db->execute(
    "SELECT x FROM s1 WHERE x > 100 INTERSECT SELECT x FROM s2");
# ok 61
is(scalar @{$r->{data}}, 0, "INTERSECT left-empty: 0 rows");

$r = $db->execute(
    "SELECT x FROM s1 WHERE x > 100 EXCEPT SELECT x FROM s2");
# ok 62
is(scalar @{$r->{data}}, 0, "EXCEPT left-empty: 0 rows");

###############################################################################
# Feature 1: AND with only one indexed column, other is unindexed
###############################################################################
# grade has no index; salary has index
$r = $db->execute("SELECT id FROM emp WHERE salary > 80000 AND grade='A'");
my @gi = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 63
is(scalar @gi, 3, "AND: indexed+unindexed col -> 3 rows");
# ok 64
is(join(',', @gi), '1,6,7', "AND: correct ids (1,6,7)");

###############################################################################
# Feature 1: AND with no usable index falls through to full scan correctly
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE grade='B' AND id > 3");
my @fi = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 65
is(scalar @fi, 1, "AND full-scan fallback: grade=B AND id>3 -> 1 row");
# ok 66
is($fi[0], 4, "AND full-scan fallback: correct id=4");

###############################################################################
# Feature 2: INTERSECT/EXCEPT with multi-column tables
###############################################################################
$db->execute("CREATE TABLE p1 (name VARCHAR(20), score INT)");
$db->execute("CREATE TABLE p2 (name VARCHAR(20), score INT)");
$db->execute("INSERT INTO p1 (name,score) VALUES ('Alice',90)");
$db->execute("INSERT INTO p1 (name,score) VALUES ('Bob',  80)");
$db->execute("INSERT INTO p1 (name,score) VALUES ('Carol',70)");
$db->execute("INSERT INTO p2 (name,score) VALUES ('Bob',  80)");
$db->execute("INSERT INTO p2 (name,score) VALUES ('Carol',70)");
$db->execute("INSERT INTO p2 (name,score) VALUES ('Dave', 60)");

$r = $db->execute("SELECT name, score FROM p1 INTERSECT SELECT name, score FROM p2");
my @names = sort map { $_->{name} } @{$r->{data}};
# ok 67
is(scalar @names, 2, "INTERSECT multi-col: 2 common rows");
# ok 68
is(join(',', @names), 'Bob,Carol', "INTERSECT multi-col: Bob and Carol");

$r = $db->execute("SELECT name FROM p1 EXCEPT SELECT name FROM p2");
# ok 69
is(scalar @{$r->{data}}, 1, "EXCEPT multi-col (name only): 1 row");
# ok 70
is($r->{data}[0]{name}, 'Alice', "EXCEPT multi-col: Alice");

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
