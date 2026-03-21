######################################################################
#
# Tests for Feature: IN clause index acceleration
#
#   WHERE col IN (v1, v2, ...)  now uses an equality index lookup
#   per value and returns the union, rather than a full table scan.
#
#   NOT IN is not optimised (falls through to a full table scan),
#   but must still produce correct results.
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

print "1..56\n";

use File::Path ();
my $BASE = "/tmp/test_in_index_$$";
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
# salary and grade have no index

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
# 1. Basic IN with integer indexed column
###############################################################################
my $r = $db->execute("SELECT id FROM emp WHERE id IN (1,3,5)");
my @ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 1
is(scalar @ids, 3, "IN int: 3 rows");
# ok 2
is(join(',', @ids), '1,3,5', "IN int: correct ids (1,3,5)");

###############################################################################
# 2. IN with string indexed column
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE dept IN ('Eng','HR')");
my @ids2 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 3
is(scalar @ids2, 6, "IN str: 6 rows (Eng=4, HR=2)");
# ok 4
is(join(',', @ids2), '1,3,4,5,7,8', "IN str: correct ids");

###############################################################################
# 3. IN with a single value
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (4)");
# ok 5
is(scalar @{$r->{data}}, 1, "IN single val: 1 row");
# ok 6
is($r->{data}[0]{id}+0, 4, "IN single val: id=4");

###############################################################################
# 4. IN with no matching values
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (99,100,101)");
# ok 7
is(scalar @{$r->{data}}, 0, "IN no match: 0 rows");

###############################################################################
# 5. IN on unindexed column (full scan, still correct)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE salary IN (60000,85000)");
my @si = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 8
is(scalar @si, 2, "IN no-index col: 2 rows");
# ok 9
is(join(',', @si), '2,6', "IN no-index col: correct ids");

###############################################################################
# 6. NOT IN (no index, full scan, correct result)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (1,2,3)");
my @ni = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 10
is(scalar @ni, 5, "NOT IN: 5 rows");
# ok 11
is(join(',', @ni), '4,5,6,7,8', "NOT IN: correct ids");

###############################################################################
# 7. IN with WHERE clause also has ORDER BY
###############################################################################
my $dbh = DB::Handy->connect($BASE, 't');
my $sth = $dbh->prepare("SELECT id, dept FROM emp WHERE id IN (3,1,5) ORDER BY id");
$sth->execute;
my @ord;
while (my $row = $sth->fetchrow_hashref) { push @ord, $row->{id}+0 }
$sth->finish;
# ok 12
is(scalar @ord, 3, "IN+ORDER BY: 3 rows");
# ok 13
is(join(',', @ord), '1,3,5', "IN+ORDER BY: ascending order");

###############################################################################
# 8. IN with LIMIT
###############################################################################
$sth = $dbh->prepare("SELECT id FROM emp WHERE id IN (1,2,3,4,5) LIMIT 3");
$sth->execute;
my @lim;
while (my $row = $sth->fetchrow_hashref) { push @lim, $row->{id}+0 }
$sth->finish;
# ok 14
is(scalar @lim, 3, "IN+LIMIT: 3 rows");

###############################################################################
# 9. IN with SELECT column order (NAME should follow SELECT list)
###############################################################################
$sth = $dbh->prepare("SELECT salary, id FROM emp WHERE id IN (1,7)");
$sth->execute;
# ok 15
is(join(',', @{$sth->{NAME}}), 'salary,id', "IN: NAME order follows SELECT list");
my $aref = $sth->fetchrow_arrayref;
# ok 16
ok(defined $aref && $aref->[1] =~ /^[17]$/, "IN: fetchrow_arrayref[1] is id");
$sth->finish;

###############################################################################
# 10. IN with duplicates in the list (should deduplicate results)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,1,3,3)");
my @dedup = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 17
is(scalar @dedup, 2, "IN dedup: 2 unique rows despite duplicate values in list");
# ok 18
is(join(',', @dedup), '1,3', "IN dedup: correct ids");

###############################################################################
# 11. IN with all table rows selected
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,2,3,4,5,6,7,8)");
# ok 19
is(scalar @{$r->{data}}, 8, "IN all rows: 8 rows");

###############################################################################
# 12. IN correctness: result matches equivalent OR query
###############################################################################
my $r_in  = $db->execute("SELECT id FROM emp WHERE dept IN ('Eng','Mkt')");
my $r_or  = $db->execute("SELECT id FROM emp WHERE dept='Eng' OR dept='Mkt'");
my @in_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_in->{data}};
my @or_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_or->{data}};
# ok 20
is(join(',', @in_ids), join(',', @or_ids), "IN equiv OR: same results");

###############################################################################
# 13. IN with NULL in list (should fall through to full scan, still correct)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,NULL,3)");
my @nullish = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 21
is(scalar @nullish, 2, "IN with NULL in list: 2 rows (NULL never matches)");
# ok 22
is(join(',', @nullish), '1,3', "IN with NULL: correct ids");

###############################################################################
# 14. IN in a subquery context (should still work as before)
###############################################################################
$db->execute("CREATE TABLE dept_list (dname VARCHAR(20))");
$db->execute("INSERT INTO dept_list (dname) VALUES ('Eng')");
$db->execute("INSERT INTO dept_list (dname) VALUES ('HR')");
$r = $db->execute("SELECT id FROM emp WHERE dept IN (SELECT dname FROM dept_list)");
my @sub_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 23
is(scalar @sub_ids, 6, "IN subquery: 6 rows (Eng+HR)");
# ok 24
is(join(',', @sub_ids), '1,3,4,5,7,8', "IN subquery: correct ids");

###############################################################################
# 15. IN combined with AND (partial-AND index, Case 3)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,3,5,7) AND salary > 70000");
my @comb = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 25  -- id IN(1,3,5,7) -> {1,3,5,7}; salary>70000 -> {1,3,4,6,7}; intersect -> {1,3,7}
is(scalar @comb, 3, "IN+AND: 3 rows");
# ok 26
is(join(',', @comb), '1,3,7', "IN+AND: correct ids (1,3,7)");

###############################################################################
# 16. IN correctness cross-check: indexed vs non-indexed table
###############################################################################
$db->execute("CREATE TABLE t2 (id INT, val VARCHAR(20))");
$db->execute("CREATE INDEX t2_idx ON t2 (id)");
$db->execute("CREATE TABLE t2b (id INT, val VARCHAR(20))");
for my $i (1..30) {
    my $v = "v$i";
    $db->execute("INSERT INTO t2  (id,val) VALUES ($i,'$v')");
    $db->execute("INSERT INTO t2b (id,val) VALUES ($i,'$v')");
}
my $r_ix  = $db->execute("SELECT id FROM t2  WHERE id IN (5,10,15,20,25)");
my $r_nix = $db->execute("SELECT id FROM t2b WHERE id IN (5,10,15,20,25)");
my @ix_ids  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_ix->{data}};
my @nix_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_nix->{data}};
# ok 27
is(join(',', @ix_ids), join(',', @nix_ids),
    "IN cross-check: indexed result matches full-scan result");
# ok 28
is(scalar @ix_ids, 5, "IN cross-check: correct count (5)");

###############################################################################
# 17. Regression: Case 1 (single equality) still works
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id = 4");
# ok 29
is(scalar @{$r->{data}}, 1, "Regression Case1: id=4 -> 1 row");

###############################################################################
# 18. Regression: Case 2 (same-col AND range) still works
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id >= 3 AND id <= 6");
# ok 30
is(scalar @{$r->{data}}, 4, "Regression Case2: id 3..6 -> 4 rows");

###############################################################################
# 19. Regression: Case 2 BETWEEN still works
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id BETWEEN 2 AND 5");
# ok 31
is(scalar @{$r->{data}}, 4, "Regression BETWEEN: id 2..5 -> 4 rows");

###############################################################################
# 20. Regression: Case 3 (multi-col AND) still works
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE dept='Eng' AND salary > 80000");
my @r3 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 32
is(join(',', @r3), '1,7', "Regression Case3: Eng AND salary>80000 -> 1,7");

###############################################################################
# 21. IN with INTERSECT
###############################################################################
$db->execute("CREATE TABLE s1 (x INT)");
$db->execute("CREATE INDEX s1_idx ON s1 (x)");
for my $v (1..10) { $db->execute("INSERT INTO s1 (x) VALUES ($v)") }
$r = $db->execute(
    "SELECT x FROM s1 WHERE x IN (2,4,6,8) "
    . "INTERSECT "
    . "SELECT x FROM s1 WHERE x IN (4,6,9)");
my @inter = sort { $a <=> $b } map { $_->{x}+0 } @{$r->{data}};
# ok 33
is(scalar @inter, 2, "IN+INTERSECT: 2 rows");
# ok 34
is(join(',', @inter), '4,6', "IN+INTERSECT: correct (4,6)");

###############################################################################
# 22. DBI-like API: fetchrow_array with IN
###############################################################################
$sth = $dbh->prepare("SELECT id FROM emp WHERE id IN (2,4,6) ORDER BY id");
$sth->execute;
my @arr_rows;
while (my @row = $sth->fetchrow_array) { push @arr_rows, $row[0]+0 }
$sth->finish;
# ok 35
is(scalar @arr_rows, 3, "DBI fetchrow_array IN: 3 rows");
# ok 36
is(join(',', @arr_rows), '2,4,6', "DBI fetchrow_array IN: correct");

###############################################################################
# 23. selectrow_arrayref with IN
###############################################################################
my $saref = $dbh->selectrow_arrayref("SELECT id FROM emp WHERE id IN (7)");
# ok 37
ok(defined $saref, "selectrow_arrayref IN: defined");
# ok 38
is($saref->[0]+0, 7, "selectrow_arrayref IN: id=7");

###############################################################################
# 24. selectall_arrayref with IN
###############################################################################
my $all = $dbh->selectall_arrayref(
    "SELECT id FROM emp WHERE id IN (1,5) ORDER BY id",
    { Slice => {} });
# ok 39
is(scalar @$all, 2, "selectall_arrayref IN: 2 rows");
# ok 40
is($all->[0]{id}+0, 1, "selectall_arrayref IN: first id=1");
# ok 41
is($all->[1]{id}+0, 5, "selectall_arrayref IN: second id=5");

###############################################################################
# 25. IN with FLOAT index
###############################################################################
$db->execute("CREATE TABLE prices (pid INT, price FLOAT)");
$db->execute("CREATE INDEX idx_price ON prices (price)");
for my $i (1..10) {
    my $p = $i * 1.5;
    $db->execute("INSERT INTO prices (pid,price) VALUES ($i,$p)");
}
$r = $db->execute("SELECT pid FROM prices WHERE price IN (3,6,9)");
my @pids = sort { $a <=> $b } map { $_->{pid}+0 } @{$r->{data}};
# ok 42
is(scalar @pids, 3, "IN FLOAT index: 3 rows");
# ok 43
is(join(',', @pids), '2,4,6', "IN FLOAT index: correct pids (price 3=pid2, 6=pid4, 9=pid6)");

###############################################################################
# 26. IN with UNIQUE index
###############################################################################
$db->execute("CREATE TABLE uq (id INT)");
$db->execute("CREATE UNIQUE INDEX uq_id ON uq (id)");
for my $v (1..10) { $db->execute("INSERT INTO uq (id) VALUES ($v)") }
$r = $db->execute("SELECT id FROM uq WHERE id IN (3,7,9)");
my @uq = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 44
is(scalar @uq, 3, "IN UNIQUE index: 3 rows");
# ok 45
is(join(',', @uq), '3,7,9', "IN UNIQUE index: correct");

###############################################################################
# 27. IN empty list (edge case: no values -- full scan, 0 results)
###############################################################################
# Note: WHERE col IN () is syntactically invalid in standard SQL, so we
# test a list that produces no records, not an empty list literal.
$r = $db->execute("SELECT id FROM emp WHERE id IN (999)");
# ok 46
is(scalar @{$r->{data}}, 0, "IN single-no-match: 0 rows");

###############################################################################
# 28. IN with 1-element list that matches multiple rows (string index, non-unique)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE dept IN ('Eng')");
my @eng = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 47
is(scalar @eng, 4, "IN single-str: 4 Eng employees");
# ok 48
is(join(',', @eng), '1,3,5,7', "IN single-str: correct ids");

###############################################################################
# 29. NOT IN correctness with indexed column (full-scan path)
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (1,3,5,7)");
my @not_in = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 49
is(scalar @not_in, 4, "NOT IN: 4 rows");
# ok 50
is(join(',', @not_in), '2,4,6,8', "NOT IN: correct ids");

###############################################################################
# 30. IN result with fetchall_arrayref Slice=>{}
###############################################################################
my $fa = $dbh->fetchall_arrayref_from_sql_or_use_selectall(
    "SELECT id, dept FROM emp WHERE id IN (2,4)", undef
) if 0;   # not a real method -- use selectall_arrayref
$all = $dbh->selectall_arrayref(
    "SELECT id, dept FROM emp WHERE id IN (2,4) ORDER BY id",
    { Slice => {} });
# ok 51
is(scalar @$all, 2, "IN selectall hashref: 2 rows");
# ok 52
is($all->[0]{dept}, 'Mkt', "IN selectall hashref: row0 dept=Mkt");
# ok 53
is($all->[1]{dept}, 'HR',  "IN selectall hashref: row1 dept=HR");

###############################################################################
# 31. IN with very large list (correctness, not performance)
###############################################################################
$db->execute("CREATE TABLE big (n INT)");
$db->execute("CREATE INDEX idx_big ON big (n)");
for my $i (1..200) { $db->execute("INSERT INTO big (n) VALUES ($i)") }
my $in_list = join(',', 1, 50, 100, 150, 200);
$r = $db->execute("SELECT n FROM big WHERE n IN ($in_list)");
my @big_n = sort { $a <=> $b } map { $_->{n}+0 } @{$r->{data}};
# ok 54
is(scalar @big_n, 5, "IN large table: 5 rows");
# ok 55
is(join(',', @big_n), '1,50,100,150,200', "IN large table: correct values");

###############################################################################
# 32. IN vs OR equivalence (indexed column)
###############################################################################
my $r_in2 = $db->execute("SELECT id FROM emp WHERE id IN (2,4,6,8)");
my $r_or2  = $db->execute("SELECT id FROM emp WHERE id=2 OR id=4 OR id=6 OR id=8");
my @in2  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_in2->{data}};
my @or2  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_or2->{data}};
# ok 56
is(join(',', @in2), join(',', @or2), "IN equiv OR (indexed): same result");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
