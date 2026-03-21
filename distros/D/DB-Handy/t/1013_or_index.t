######################################################################
#
# Tests for Feature: OR conditions on indexed columns use index lookups.
#
#   WHERE col1 = v1 OR col2 = v2  now uses index lookups for each atom
#   and returns their union, rather than a full table scan.
#
#   Restriction: every atom in the OR chain must have an index on its
#   column.  If any atom has no index the engine falls back to a full
#   table scan (but still returns correct results).
#
# Perl 5.005_03 compatible: no 'our', no say, no //, no given/when,
# no Time::HiRes.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use DB::Handy;

###############################################################################
# Minimal test harness
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

print "1..62\n";

use File::Path ();
my $BASE = "/tmp/test_or_index_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('t');
$db->use_database('t');

###############################################################################
# Setup
###############################################################################
$db->execute("CREATE TABLE emp (id INT, dept VARCHAR(20), salary INT, grade CHAR(2))");
$db->execute("CREATE INDEX idx_id   ON emp (id)");
$db->execute("CREATE INDEX idx_dept ON emp (dept)");
# salary and grade: no index

my @emp = (
    [1, 'Eng', 90000, 'A'],
    [2, 'Mkt', 60000, 'B'],
    [3, 'Eng', 75000, 'A'],
    [4, 'HR',  80000, 'B'],
    [5, 'Eng', 50000, 'C'],
    [6, 'Mkt', 85000, 'A'],
    [7, 'Eng', 95000, 'A'],
    [8, 'HR',  55000, 'C'],
);
for my $r (@emp) {
    $db->execute("INSERT INTO emp (id,dept,salary,grade)"
        . " VALUES ($r->[0],'$r->[1]',$r->[2],'$r->[3]')");
}

###############################################################################
# 1. Same-column OR (equality, indexed)
###############################################################################
my $r = $db->execute("SELECT id FROM emp WHERE dept='Eng' OR dept='HR'");
my @ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 1
is(scalar @ids, 6, "OR same-col: 6 rows (Eng=4 + HR=2)");
# ok 2
is(join(',', @ids), '1,3,4,5,7,8', "OR same-col: correct ids");

###############################################################################
# 2. Different-column OR (both indexed)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=2 OR dept='HR'");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 3
is(scalar @ids, 3, "OR diff-col: 3 rows (id=2 + HR=2, no overlap)");
# ok 4
is(join(',', @ids), '2,4,8', "OR diff-col: correct ids");

###############################################################################
# 3. Three-way OR (all indexed)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=1 OR id=3 OR id=5");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 5
is(scalar @ids, 3, "OR 3-way same-col: 3 rows");
# ok 6
is(join(',', @ids), '1,3,5', "OR 3-way same-col: correct");

###############################################################################
# 4. OR with range atom (col >= val)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id >= 7 OR dept='Mkt'");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 7
is(scalar @ids, 4, "OR range+eq: 4 rows (id>=7: 7,8 + Mkt: 2,6)");
# ok 8
is(join(',', @ids), '2,6,7,8', "OR range+eq: correct ids");

###############################################################################
# 5. OR with BETWEEN atom
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id BETWEEN 1 AND 2 OR dept='HR'");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 9
is(scalar @ids, 4, "OR BETWEEN+eq: 4 rows");
# ok 10
is(join(',', @ids), '1,2,4,8', "OR BETWEEN+eq: correct");

###############################################################################
# 6. OR with IN atom
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,3) OR dept='Mkt'");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 11
is(scalar @ids, 4, "OR IN+eq: 4 rows");
# ok 12
is(join(',', @ids), '1,2,3,6', "OR IN+eq: correct");

###############################################################################
# 7. OR no-match
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=99 OR dept='ZZZ'");
# ok 13
is(scalar @{$r->{data}}, 0, "OR no-match: 0 rows");

###############################################################################
# 8. OR full overlap (same result set)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=1 OR id=1");
# ok 14
is(scalar @{$r->{data}}, 1, "OR overlap: deduplicated to 1 row");
# ok 15
is($r->{data}[0]{id}+0, 1, "OR overlap: id=1");

###############################################################################
# 9. OR with unindexed column (fallback to full scan, correct result)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE salary=90000 OR id=2");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 16
is(scalar @ids, 2, "OR unindexed: full-scan fallback, 2 rows");
# ok 17
is(join(',', @ids), '1,2', "OR unindexed: correct ids");

###############################################################################
# 10. OR correctness: result matches equivalent IN query (same-col equality)
###############################################################################
my $r_or = $db->execute("SELECT id FROM emp WHERE dept='Eng' OR dept='Mkt'");
my $r_in = $db->execute("SELECT id FROM emp WHERE dept IN ('Eng','Mkt')");
my @or_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_or->{data}};
my @in_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_in->{data}};
# ok 18
is(join(',', @or_ids), join(',', @in_ids), "OR equiv IN: same result");

###############################################################################
# 11. OR correctness cross-check (indexed vs non-indexed table)
###############################################################################
$db->execute("CREATE TABLE t2  (id INT, dept VARCHAR(20))");
$db->execute("CREATE TABLE t2b (id INT, dept VARCHAR(20))");
$db->execute("CREATE INDEX t2_id   ON t2 (id)");
$db->execute("CREATE INDEX t2_dept ON t2 (dept)");
for my $r (@emp) {
    $db->execute("INSERT INTO t2  (id,dept) VALUES ($r->[0],'$r->[1]')");
    $db->execute("INSERT INTO t2b (id,dept) VALUES ($r->[0],'$r->[1]')");
}
my $r_ix  = $db->execute("SELECT id FROM t2  WHERE id=1 OR dept='Mkt'");
my $r_nix = $db->execute("SELECT id FROM t2b WHERE id=1 OR dept='Mkt'");
my @ix_ids  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_ix->{data}};
my @nix_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_nix->{data}};
# ok 19
is(join(',', @ix_ids), join(',', @nix_ids),
    "OR cross-check: indexed matches full-scan result");
# ok 20
is(scalar @ix_ids, 3, "OR cross-check: count=3 (id=1 + Mkt=2,6)");

###############################################################################
# 12. DBI-like API with OR
###############################################################################
my $dbh = DB::Handy->connect($BASE, 't');

my $sth = $dbh->prepare("SELECT id FROM emp WHERE id=1 OR dept='HR' ORDER BY id");
$sth->execute;
my @dbi_rows;
while (my $row = $sth->fetchrow_hashref) { push @dbi_rows, $row->{id}+0 }
$sth->finish;
# ok 21
is(scalar @dbi_rows, 3, "OR DBI fetch: 3 rows");
# ok 22
is(join(',', @dbi_rows), '1,4,8', "OR DBI fetch: correct order");

###############################################################################
# 13. OR with LIMIT
###############################################################################
$sth = $dbh->prepare("SELECT id FROM emp WHERE id<=3 OR dept='HR' ORDER BY id LIMIT 3");
$sth->execute;
my @lim;
while (my $row = $sth->fetchrow_hashref) { push @lim, $row->{id}+0 }
$sth->finish;
# ok 23
is(scalar @lim, 3, "OR+LIMIT: 3 rows");
# ok 24
is(join(',', @lim), '1,2,3', "OR+LIMIT: correct (first 3 of 1,2,3,4,8)");

###############################################################################
# 14. OR with SELECT column order (NAME follows SELECT list)
###############################################################################
$sth = $dbh->prepare("SELECT salary, id FROM emp WHERE id=1 OR id=2");
$sth->execute;
# ok 25
is(join(',', @{$sth->{NAME}}), 'salary,id', "OR: NAME order follows SELECT list");
$sth->finish;

###############################################################################
# 15. OR with ORDER BY (non-indexed sort column)
###############################################################################
$r = $db->execute("SELECT id, salary FROM emp WHERE id=1 OR id=6 ORDER BY salary");
my @sorted_ids = map { $_->{id}+0 } @{$r->{data}};
# ok 26
is(scalar @sorted_ids, 2, "OR+ORDER BY: 2 rows");
# ok 27
is(join(',', @sorted_ids), '6,1',
    "OR+ORDER BY salary: id=6(85000) before id=1(90000)");

###############################################################################
# 16. OR with FLOAT index
###############################################################################
$db->execute("CREATE TABLE prices (pid INT, price FLOAT)");
$db->execute("CREATE INDEX idx_pid   ON prices (pid)");
$db->execute("CREATE INDEX idx_price ON prices (price)");
for my $i (1..10) {
    $db->execute("INSERT INTO prices (pid,price) VALUES ($i," . ($i * 1.5) . ")");
}
$r = $db->execute("SELECT pid FROM prices WHERE pid=2 OR price=7.5");
my @pids = sort { $a <=> $b } map { $_->{pid}+0 } @{$r->{data}};
# ok 28  (pid=2 -> price=3.0; price=7.5 -> pid=5)
is(scalar @pids, 2, "OR FLOAT index: 2 rows");
# ok 29
is(join(',', @pids), '2,5', "OR FLOAT index: correct (pid=2 and pid=5)");

###############################################################################
# 17. OR with UNIQUE index
###############################################################################
$db->execute("CREATE TABLE uq (id INT, code VARCHAR(10))");
$db->execute("CREATE UNIQUE INDEX uq_id   ON uq (id)");
$db->execute("CREATE UNIQUE INDEX uq_code ON uq (code)");
for my $i (1..5) {
    $db->execute("INSERT INTO uq (id,code) VALUES ($i,'C$i')");
}
$r = $db->execute("SELECT id FROM uq WHERE id=2 OR code='C4'");
my @uq = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 30
is(scalar @uq, 2, "OR UNIQUE index: 2 rows");
# ok 31
is(join(',', @uq), '2,4', "OR UNIQUE index: correct");

###############################################################################
# 18. Regression: Cases 1-4 still work after Case 5 added
###############################################################################
# Case 1: single equality
$r = $db->execute("SELECT id FROM emp WHERE dept='HR'");
# ok 32
is(scalar @{$r->{data}}, 2, "Regression Case1: dept=HR -> 2 rows");

# Case 1: range
$r = $db->execute("SELECT id FROM emp WHERE id > 5");
# ok 33
is(scalar @{$r->{data}}, 3, "Regression Case1 range: id>5 -> 3 rows");

# Case 2: BETWEEN
$r = $db->execute("SELECT id FROM emp WHERE id BETWEEN 2 AND 5");
# ok 34
is(scalar @{$r->{data}}, 4, "Regression Case2 BETWEEN: 4 rows");

# Case 3: multi-col AND
$r = $db->execute("SELECT id FROM emp WHERE dept='Eng' AND id > 5");
my @r3 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 35
is(join(',', @r3), '7', "Regression Case3 AND: Eng+id>5 -> 7");

# Case 4: IN
$r = $db->execute("SELECT id FROM emp WHERE id IN (2,4,6)");
# ok 36
is(scalar @{$r->{data}}, 3, "Regression Case4 IN: 3 rows");

###############################################################################
# 19. OR mixed with AND in WHERE (OR not at top level -- full scan, correct)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE (id=1 OR id=2) AND salary > 70000");
my @mixed = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 37  -- full scan because OR+AND combined
is(scalar @mixed, 1, "OR+AND combined: correct count");
# ok 38
is($mixed[0], 1, "OR+AND combined: id=1 (salary=90000 > 70000)");

###############################################################################
# 20. OR + INTERSECT
###############################################################################
$r = $db->execute(
    "SELECT id FROM emp WHERE dept='Eng' OR dept='Mkt' "
    . "INTERSECT "
    . "SELECT id FROM emp WHERE id <= 3");
my @inter = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 39
is(scalar @inter, 3, "OR+INTERSECT: 3 rows");
# ok 40
is(join(',', @inter), '1,2,3', "OR+INTERSECT: correct (Eng+Mkt intersect id<=3)");

###############################################################################
# 21. OR + EXCEPT
###############################################################################
$r = $db->execute(
    "SELECT id FROM emp WHERE dept='Eng' OR dept='HR' "
    . "EXCEPT "
    . "SELECT id FROM emp WHERE id >= 7");
my @exc = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 41
is(scalar @exc, 4, "OR+EXCEPT: 4 rows (Eng+HR minus id>=7)");
# ok 42
is(join(',', @exc), '1,3,4,5', "OR+EXCEPT: correct");

###############################################################################
# 22. NOT IN still works (no change, full scan)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (1,2,3)");
my @not_in = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 43
is(scalar @not_in, 5, "NOT IN unaffected: 5 rows");
# ok 44
is(join(',', @not_in), '4,5,6,7,8', "NOT IN unaffected: correct");

###############################################################################
# 23. OR on non-indexed table (full scan both atoms, correct)
###############################################################################
$db->execute("CREATE TABLE plain (a INT, b INT)");
for my $i (1..10) {
    $db->execute("INSERT INTO plain (a,b) VALUES ($i," . ($i*2) . ")");
}
$r = $db->execute("SELECT a FROM plain WHERE a=3 OR b=10");
my @plain = sort { $a <=> $b } map { $_->{a}+0 } @{$r->{data}};
# ok 45  (a=3 and b=10->a=5)
is(scalar @plain, 2, "OR no-index: full-scan, 2 rows");
# ok 46
is(join(',', @plain), '3,5', "OR no-index: correct (a=3 and a=5)");

###############################################################################
# 24. selectall_arrayref with OR
###############################################################################
my $all = $dbh->selectall_arrayref(
    "SELECT id FROM emp WHERE id=1 OR id=7 ORDER BY id",
    { Slice => {} });
# ok 47
is(scalar @$all, 2, "OR selectall: 2 rows");
# ok 48
is($all->[0]{id}+0, 1, "OR selectall: row0 id=1");
# ok 49
is($all->[1]{id}+0, 7, "OR selectall: row1 id=7");

###############################################################################
# 25. selectrow_hashref with OR
###############################################################################
my $h = $dbh->selectrow_hashref("SELECT id, dept FROM emp WHERE id=99 OR dept='HR' LIMIT 1");
# ok 50
ok(defined $h, "OR selectrow: defined");
# ok 51
is($h->{dept}, 'HR', "OR selectrow: dept=HR");

###############################################################################
# 26. OR with range on different columns
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id >= 7 OR id <= 2");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 52
is(scalar @ids, 4, "OR two ranges same col: 4 rows (id<=2: 1,2 + id>=7: 7,8)");
# ok 53
is(join(',', @ids), '1,2,7,8', "OR two ranges same col: correct");

###############################################################################
# 27. OR correctness: 4-way OR
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=1 OR id=3 OR id=5 OR id=7");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 54
is(scalar @ids, 4, "OR 4-way: 4 rows");
# ok 55
is(join(',', @ids), '1,3,5,7', "OR 4-way: correct");

###############################################################################
# 28. OR with duplicate records (same id in multiple atoms -- deduplication)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id=4 OR dept='HR'");
@ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 56  (id=4 is HR, so would appear in both atoms without dedup)
is(scalar @ids, 2, "OR dedup: id=4 (HR) appears only once");
# ok 57
is(join(',', @ids), '4,8', "OR dedup: correct (4,8)");

###############################################################################
# 29. fetchrow_arrayref column order with OR
###############################################################################
$sth = $dbh->prepare("SELECT salary, id FROM emp WHERE id=1 OR id=2 ORDER BY id");
$sth->execute;
my $aref = $sth->fetchrow_arrayref;
# ok 58
ok(defined $aref, "OR fetchrow_arrayref: defined");
# ok 59
is($aref->[0]+0, 90000, "OR fetchrow_arrayref: [0]=salary(id=1)=90000");
# ok 60
is($aref->[1]+0, 1,     "OR fetchrow_arrayref: [1]=id=1");
$sth->finish;

###############################################################################
# 30. Large table OR performance (correctness only -- no timing)
###############################################################################
$db->execute("CREATE TABLE big (n INT, cat VARCHAR(5))");
$db->execute("CREATE INDEX idx_n   ON big (n)");
$db->execute("CREATE INDEX idx_cat ON big (cat)");
for my $i (1..500) {
    my $c = ($i % 3 == 0) ? 'A' : ($i % 3 == 1) ? 'B' : 'C';
    $db->execute("INSERT INTO big (n,cat) VALUES ($i,'$c')");
}
my $r_or2  = $db->execute("SELECT n FROM big WHERE n IN (100,200,300) OR cat='A'");
my $r_scan = $db->execute("SELECT n FROM big WHERE n IN (100,200,300) OR cat='A'");
# ok 61
is(scalar @{$r_or2->{data}},
   scalar @{$r_scan->{data}},
   "OR large: indexed and scan agree on count");
# ok 62
ok(scalar @{$r_or2->{data}} > 0, "OR large: non-empty result");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
