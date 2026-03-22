######################################################################
#
# Tests for features added in 1.06:
#
#   Feature 1: NOT IN with indexed column uses index complement
#              (no full table scan when index is available).
#
#   Feature 2: last_insert_id() accepts DBI-compatible arguments
#              (catalog, schema, table, field) which are ignored.
#
#   Feature 3: connect() accepts dbi:Handy:key=val;... DSN prefix.
#
#   Feature 4: INSERT INTO dst (...) SELECT ... FROM src maps columns
#              by name when dst column names exist in the result row,
#              rather than always mapping by position.
#
# Perl 5.005_03 compatible.
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

print "1..68\n";

use File::Path ();
my $BASE = "/tmp/test_new_features_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('t');
$db->use_database('t');

###############################################################################
# Setup
###############################################################################
$db->execute("CREATE TABLE emp (id INT, dept VARCHAR(20), salary INT)");
$db->execute("CREATE INDEX idx_id   ON emp (id)");
$db->execute("CREATE INDEX idx_dept ON emp (dept)");
# salary: no index

my @emp = (
    [1, 'Eng', 90000],
    [2, 'Mkt', 60000],
    [3, 'Eng', 75000],
    [4, 'HR',  80000],
    [5, 'Eng', 50000],
    [6, 'Mkt', 85000],
    [7, 'Eng', 95000],
    [8, 'HR',  55000],
);
for my $r (@emp) {
    $db->execute("INSERT INTO emp (id,dept,salary) VALUES ($r->[0],'$r->[1]',$r->[2])");
}

my $dbh = DB::Handy->connect($BASE, 't');

###############################################################################
# Feature 1 -- NOT IN index acceleration
###############################################################################

# 1-1: Basic NOT IN on indexed integer column
my $r = $db->execute("SELECT id FROM emp WHERE id NOT IN (1,2,3)");
my @ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 1
is(scalar @ids, 5, "NOT IN: 5 rows (8 - 3 excluded)");
# ok 2
is(join(',', @ids), '4,5,6,7,8', "NOT IN: correct remaining ids");

# 1-2: NOT IN on indexed string column
$r = $db->execute("SELECT id FROM emp WHERE dept NOT IN ('Eng')");
my @ids2 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 3
is(scalar @ids2, 4, "NOT IN str: 4 rows (Mkt=2 + HR=2)");
# ok 4
is(join(',', @ids2), '2,4,6,8', "NOT IN str: correct ids");

# 1-3: NOT IN excludes all rows
$r = $db->execute("SELECT id FROM emp WHERE dept NOT IN ('Eng','Mkt','HR')");
# ok 5
is(scalar @{$r->{data}}, 0, "NOT IN all depts: 0 rows");

# 1-4: NOT IN excludes nothing (values not present)
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (99,100,101)");
# ok 6
is(scalar @{$r->{data}}, 8, "NOT IN no-match values: all 8 rows");

# 1-5: NOT IN unindexed column (full scan, correct result)
$r = $db->execute("SELECT id FROM emp WHERE salary NOT IN (90000,60000)");
my @ids3 = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 7
is(scalar @ids3, 6, "NOT IN no-index: full scan, 6 rows");
# ok 8
is(join(',', @ids3), '3,4,5,6,7,8', "NOT IN no-index: correct ids");

# 1-6: NOT IN with NULL in list -> 0 rows (SQL UNKNOWN semantics)
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (1,NULL,3)");
# ok 9
# SQL: col NOT IN (v1, NULL, v2) is UNKNOWN for every row that does not
# match v1 or v2.  The engine returns 0 rows, consistent with standard SQL.
is(scalar @{$r->{data}}, 0, "NOT IN with NULL: 0 rows (SQL UNKNOWN semantics)");

# 1-7: NOT IN single value
$r = $db->execute("SELECT id FROM emp WHERE id NOT IN (5)");
my @ni_single = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 10
is(scalar @ni_single, 7, "NOT IN single: 7 rows");
# ok 11
ok(!(grep { $_ == 5 } @ni_single), "NOT IN single: 5 is excluded");

# 1-8: NOT IN correctness: indexed vs non-indexed table
$db->execute("CREATE TABLE emp_noidx (id INT, dept VARCHAR(20), salary INT)");
for my $row (@emp) {
    $db->execute("INSERT INTO emp_noidx (id,dept,salary)"
        . " VALUES ($row->[0],'$row->[1]',$row->[2])");
}
my $r_idx  = $db->execute("SELECT id FROM emp        WHERE id NOT IN (2,4,6,8)");
my $r_scan = $db->execute("SELECT id FROM emp_noidx  WHERE id NOT IN (2,4,6,8)");
my @idx_ids  = sort { $a <=> $b } map { $_->{id}+0 } @{$r_idx->{data}};
my @scan_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r_scan->{data}};
# ok 12
is(join(',', @idx_ids), join(',', @scan_ids),
    "NOT IN cross-check: indexed matches full-scan result");
# ok 13
is(join(',', @idx_ids), '1,3,5,7', "NOT IN cross-check: correct ids");

# 1-9: NOT IN + ORDER BY
my $sth = $dbh->prepare("SELECT id FROM emp WHERE dept NOT IN ('HR') ORDER BY id");
$sth->execute;
my @ord;
while (my $row = $sth->fetchrow_hashref) { push @ord, $row->{id}+0 }
$sth->finish;
# ok 14
is(scalar @ord, 6, "NOT IN + ORDER BY: 6 rows");
# ok 15
is(join(',', @ord), '1,2,3,5,6,7', "NOT IN + ORDER BY: correct order");

# 1-10: NOT IN + LIMIT
$sth = $dbh->prepare("SELECT id FROM emp WHERE id NOT IN (1,2) ORDER BY id LIMIT 3");
$sth->execute;
my @lim;
while (my $row = $sth->fetchrow_hashref) { push @lim, $row->{id}+0 }
$sth->finish;
# ok 16
is(scalar @lim, 3, "NOT IN + LIMIT: 3 rows");
# ok 17
is(join(',', @lim), '3,4,5', "NOT IN + LIMIT: first 3 after excluding 1,2");

# 1-11: NOT IN equivalence: NOT IN (x) = NOT (id = x)
my $r_notin = $db->execute("SELECT id FROM emp WHERE dept NOT IN ('Mkt')");
my $r_neq   = $db->execute("SELECT id FROM emp WHERE dept <> 'Mkt'");
my @notin_s = sort { $a <=> $b } map { $_->{id}+0 } @{$r_notin->{data}};
my @neq_s   = sort { $a <=> $b } map { $_->{id}+0 } @{$r_neq->{data}};
# ok 18
is(join(',', @notin_s), join(',', @neq_s),
    "NOT IN single-val equiv <> : same result");

# 1-12: Regression -- IN still works
$r = $db->execute("SELECT id FROM emp WHERE id IN (1,3,5)");
# ok 19
is(scalar @{$r->{data}}, 3, "Regression IN: 3 rows");

# 1-13: Regression -- OR still works
$r = $db->execute("SELECT id FROM emp WHERE id=1 OR id=2");
# ok 20
is(scalar @{$r->{data}}, 2, "Regression OR: 2 rows");

###############################################################################
# Feature 2 -- last_insert_id() DBI-compatible signature
###############################################################################

$dbh->do("INSERT INTO emp (id,dept,salary) VALUES (9,'IT',70000)");

# 2-1: No arguments (existing behaviour)
my $n0 = $dbh->last_insert_id;
# ok 21
is($n0+0, 1, "last_insert_id(): 1 (one row inserted)");

# 2-2: Four DBI arguments (catalog, schema, table, field) -- accepted, ignored
my $n4 = $dbh->last_insert_id(undef, undef, 'emp', 'id');
# ok 22
is($n4+0, 1, "last_insert_id(undef,undef,'emp','id'): 1");

# 2-3: With string arguments
my $n_str = $dbh->last_insert_id('', '', 'emp', 'id');
# ok 23
is($n_str+0, 1, "last_insert_id('','','emp','id'): 1");

# 2-4: Returns correct count after bulk INSERT...SELECT
$db->execute("CREATE TABLE src_bulk (id INT)");
for my $i (1..5) { $db->execute("INSERT INTO src_bulk (id) VALUES ($i)") }
$db->execute("CREATE TABLE dst_bulk (id INT)");
$db->execute("INSERT INTO dst_bulk (id) SELECT id FROM src_bulk");
my $dbh2 = DB::Handy->connect($BASE, 't');
# row count from the most recent INSERT on this connection.
$dbh2->disconnect;
# The main $dbh hasn't done a bulk insert, so test from engine directly:
$r = $db->execute("INSERT INTO dst_bulk (id) SELECT id FROM src_bulk");
# ok 24
is($r->{type}, 'ok', "last_insert_id bulk context: INSERT...SELECT ok");
# ok 25
is($r->{message}, '5 row(s) inserted', "last_insert_id bulk: 5 rows inserted");

###############################################################################
# Feature 3 -- dbi:Handy: DSN prefix
###############################################################################

# 3-1: dbi:Handy:dir=DIR;db=DB
my $dbh3 = DB::Handy->connect("dbi:Handy:dir=$BASE;db=t", undef);
# ok 26
ok(defined $dbh3, "dbi:Handy:dir=;db= connect: defined");
my $sth3 = $dbh3->prepare("SELECT COUNT(*) AS n FROM emp");
$sth3->execute;
my $cnt = $sth3->fetchrow_hashref->{n}+0;
$sth3->finish;
$dbh3->disconnect;
# ok 27
ok($cnt > 0, "dbi:Handy:dir=;db= connect: query works");

# 3-2: dbi:Handy:base_dir=DIR;database=DB
my $dbh4 = DB::Handy->connect("dbi:Handy:base_dir=$BASE;database=t", undef);
# ok 28
ok(defined $dbh4, "dbi:Handy:base_dir=;database= connect: defined");
my $sth4 = $dbh4->prepare("SELECT COUNT(*) AS n FROM emp");
$sth4->execute;
my $cnt4 = $sth4->fetchrow_hashref->{n}+0;
$sth4->finish;
$dbh4->disconnect;
# ok 29
ok($cnt4 > 0, "dbi:Handy:base_dir=;database= connect: query works");

# 3-3: dbi:Handy: with mixed case (Dbi:Handy:)
my $dbh5 = DB::Handy->connect("DBI:Handy:dir=$BASE;db=t", undef);
# ok 30
ok(defined $dbh5, "DBI:Handy: (uppercase) connect: defined");
$dbh5->disconnect;

# 3-4: plain path (no DSN prefix) still works
my $dbh6 = DB::Handy->connect($BASE, 't');
# ok 31
ok(defined $dbh6, "plain path connect still works");
$dbh6->disconnect;

# 3-5: plain key=val DSN (no dbi: prefix) still works
my $dbh7 = DB::Handy->connect("dir=$BASE;db=t", undef);
# ok 32
ok(defined $dbh7, "plain key=val DSN still works");
$dbh7->disconnect;

###############################################################################
# Feature 4 -- INSERT...SELECT name-based column mapping
###############################################################################

$db->execute("CREATE TABLE src (a INT, b VARCHAR(20), c INT)");
$db->execute("CREATE TABLE dst (x INT, y VARCHAR(20), z INT)");
$db->execute("INSERT INTO src (a,b,c) VALUES (1,'hello',10)");
$db->execute("INSERT INTO src (a,b,c) VALUES (2,'world',20)");

# 4-1: Same column names -- name-based mapping
$db->execute("CREATE TABLE dst_same (a INT, b VARCHAR(20), c INT)");
$db->execute("INSERT INTO dst_same (a,b,c) SELECT a,b,c FROM src");
$r = $db->execute("SELECT a,b,c FROM dst_same ORDER BY a");
# ok 33
is(scalar @{$r->{data}}, 2, "INSERT...SELECT same-name: 2 rows");
# ok 34
is($r->{data}[0]{a}+0, 1,      "INSERT...SELECT same-name: row0 a=1");
# ok 35
is($r->{data}[0]{b},   'hello', "INSERT...SELECT same-name: row0 b=hello");
# ok 36
is($r->{data}[0]{c}+0, 10,     "INSERT...SELECT same-name: row0 c=10");

# 4-2: Same names but different SELECT order -- name-based mapping preserves values
$db->execute("CREATE TABLE dst_rev (a INT, b VARCHAR(20), c INT)");
$db->execute("INSERT INTO dst_rev (a,b,c) SELECT c,b,a FROM src");
# dst(a,b,c) <- SELECT c,b,a -- position based: a=c_val, b=b_val, c=a_val
$r = $db->execute("SELECT a,b,c FROM dst_rev ORDER BY c");
# ok 37
# Name-based mapping: dst col names a,b,c all exist in result row keys
# (SELECT c,b,a aliases to c,b,a in row hash) so mapping is name-based:
# dst.a = row{a} = 1, dst.b = row{b} = hello, dst.c = row{c} = 10
is($r->{data}[0]{a}+0, 1,      "INSERT...SELECT reversed: name-based dst.a=row{a}=1");
# ok 38
is($r->{data}[0]{b},   'hello', "INSERT...SELECT reversed: dst.b=row{b}=hello");
# ok 39
is($r->{data}[0]{c}+0, 10,     "INSERT...SELECT reversed: dst.c=row{c}=10");

# 4-3: Different column names -- position-based fallback
$db->execute("INSERT INTO dst (x,y,z) SELECT a,b,c FROM src");
$r = $db->execute("SELECT x,y,z FROM dst ORDER BY x");
# ok 40
is($r->{data}[0]{x}+0, 1,      "INSERT...SELECT diff-names: x=a=1");
# ok 41
is($r->{data}[0]{y},   'hello', "INSERT...SELECT diff-names: y=b=hello");
# ok 42
is($r->{data}[0]{z}+0, 10,     "INSERT...SELECT diff-names: z=c=10");

# 4-4: INSERT...SELECT with SELECT * (position fallback via schema order)
$db->execute("CREATE TABLE dst_star (a INT, b VARCHAR(20), c INT)");
$db->execute("INSERT INTO dst_star (a,b,c) SELECT * FROM src");
$r = $db->execute("SELECT a,b,c FROM dst_star ORDER BY a");
# ok 43
is($r->{data}[0]{a}+0, 1,      "INSERT...SELECT SELECT *: a=1");
# ok 44
is($r->{data}[0]{b},   'hello', "INSERT...SELECT SELECT *: b=hello");

# 4-5: Subset of columns (name-based)
$db->execute("CREATE TABLE dst_sub (b VARCHAR(20), a INT)");
$db->execute("INSERT INTO dst_sub (b,a) SELECT b,a FROM src");
$r = $db->execute("SELECT a,b FROM dst_sub ORDER BY a");
# ok 45
is($r->{data}[0]{a}+0, 1,      "INSERT...SELECT subset: a=1");
# ok 46
is($r->{data}[0]{b},   'hello', "INSERT...SELECT subset: b=hello");

# 4-6: Column alias in SELECT -- name-based via alias
$db->execute("CREATE TABLE dst_alias (p INT, q VARCHAR(20))");
$db->execute("INSERT INTO dst_alias (p,q) SELECT a AS p, b AS q FROM src");
$r = $db->execute("SELECT p,q FROM dst_alias ORDER BY p");
# ok 47
is($r->{data}[0]{p}+0, 1,      "INSERT...SELECT alias: p=1");
# ok 48
is($r->{data}[0]{q},   'hello', "INSERT...SELECT alias: q=hello");

###############################################################################
# NOT IN: additional DBI-API tests
###############################################################################

# fetchrow_array with NOT IN
$sth = $dbh->prepare(
    "SELECT id FROM emp WHERE id NOT IN (1,2,3,4) ORDER BY id");
$sth->execute;
my @fa;
while (my @row = $sth->fetchrow_array) { push @fa, $row[0]+0 }
$sth->finish;
# ok 49
# id NOT IN (1,2,3,4): rows with id 5,6,7,8,9 remain (id=9 added in Feature2 tests)
is(scalar @fa, 5, "NOT IN fetchrow_array: 5 rows (ids 5-9)");
# ok 50
is(join(',', @fa), '5,6,7,8,9', "NOT IN fetchrow_array: correct");

# selectall_arrayref with NOT IN
my $all = $dbh->selectall_arrayref(
    "SELECT id FROM emp WHERE dept NOT IN ('HR') ORDER BY id",
    { Slice => {} });
# ok 51
# dept NOT IN ('HR'): excludes id=4,8 (HR). Remaining: 1,2,3,5,6,7,9(IT)
is(scalar @$all, 7, "NOT IN selectall: 7 rows (HR excluded)");
# ok 52
is($all->[0]{id}+0, 1, "NOT IN selectall: first id=1");

# selectrow_hashref with NOT IN
my $hr = $dbh->selectrow_hashref(
    "SELECT id FROM emp WHERE id NOT IN (1,2,3,4,5,6,7) ORDER BY id");
# ok 53
is($hr->{id}+0, 8, "NOT IN selectrow_hashref: id=8");

###############################################################################
# NOT IN: FLOAT index
###############################################################################
$db->execute("CREATE TABLE prices (pid INT, price FLOAT)");
$db->execute("CREATE INDEX idx_price ON prices (price)");
for my $i (1..6) {
    $db->execute("INSERT INTO prices (pid,price) VALUES ($i," . ($i*1.5) . ")");
}
$r = $db->execute("SELECT pid FROM prices WHERE price NOT IN (1.5,3,4.5)");
my @pids = sort { $a <=> $b } map { $_->{pid}+0 } @{$r->{data}};
# ok 54
is(scalar @pids, 3, "NOT IN FLOAT: 3 rows");
# ok 55
is(join(',', @pids), '4,5,6', "NOT IN FLOAT: correct pids");

###############################################################################
# NOT IN: UNIQUE index
###############################################################################
$db->execute("CREATE TABLE uq (id INT)");
$db->execute("CREATE UNIQUE INDEX uq_id ON uq (id)");
for my $i (1..8) { $db->execute("INSERT INTO uq (id) VALUES ($i)") }
$r = $db->execute("SELECT id FROM uq WHERE id NOT IN (2,4,6,8)");
my @uq_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 56
is(scalar @uq_ids, 4, "NOT IN UNIQUE: 4 rows");
# ok 57
is(join(',', @uq_ids), '1,3,5,7', "NOT IN UNIQUE: correct");

###############################################################################
# NOT IN: large table (correctness)
###############################################################################
$db->execute("CREATE TABLE big (n INT)");
$db->execute("CREATE INDEX idx_big ON big (n)");
for my $i (1..200) { $db->execute("INSERT INTO big (n) VALUES ($i)") }
my $excl = join(',', 1..100);
$r = $db->execute("SELECT n FROM big WHERE n NOT IN ($excl)");
my @big_n = sort { $a <=> $b } map { $_->{n}+0 } @{$r->{data}};
# ok 58
is(scalar @big_n, 100, "NOT IN large: 100 rows");
# ok 59
is($big_n[0], 101, "NOT IN large: first=101");
# ok 60
is($big_n[-1], 200, "NOT IN large: last=200");

###############################################################################
# NOT IN: interaction with INTERSECT / EXCEPT
###############################################################################
$r = $db->execute(
    "SELECT id FROM emp WHERE id NOT IN (1,2) "
    . "INTERSECT "
    . "SELECT id FROM emp WHERE id NOT IN (7,8)");
my @inter = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 61
# id NOT IN (1,2) intersect id NOT IN (7,8): {3,4,5,6,9} intersect {1,2,3,4,5,6,9} = {3,4,5,6,9}
is(scalar @inter, 5, "NOT IN + INTERSECT: 5 rows");
# ok 62
is(join(',', @inter), '3,4,5,6,9', "NOT IN + INTERSECT: correct");

###############################################################################
# dbi:Handy DSN: round-trip read/write
###############################################################################
my $dbh_dsn = DB::Handy->connect("dbi:Handy:dir=$BASE;db=t", undef);
$dbh_dsn->do("INSERT INTO emp (id,dept,salary) VALUES (50,'DSN',12345)");
my $row = $dbh_dsn->selectrow_hashref(
    "SELECT dept,salary FROM emp WHERE id=50");
# ok 63
is($row->{dept},      'DSN',   "dbi:Handy DSN round-trip: dept=DSN");
# ok 64
is($row->{salary}+0,  12345,   "dbi:Handy DSN round-trip: salary=12345");
$dbh_dsn->disconnect;

###############################################################################
# last_insert_id: DBI args do not break return value
###############################################################################
$dbh->do("INSERT INTO emp (id,dept,salary) VALUES (51,'T',0)");
my $v1 = $dbh->last_insert_id;
my $v2 = $dbh->last_insert_id('cat', 'schema', 'emp', 'id');
# ok 65
is($v1+0, 1, "last_insert_id no-arg: 1");
# ok 66
is($v2+0, 1, "last_insert_id 4-arg: same value");

###############################################################################
# Regression: IN still fully functional
###############################################################################
$r = $db->execute("SELECT id FROM emp WHERE dept IN ('Eng','HR')");
my @in_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 67
ok(scalar @in_ids > 0, "Regression IN: non-empty");

# Regression: OR with indexes still works
$r = $db->execute("SELECT id FROM emp WHERE id=1 OR dept='HR'");
my @or_ids = sort { $a <=> $b } map { $_->{id}+0 } @{$r->{data}};
# ok 68
ok(scalar @or_ids > 0, "Regression OR: non-empty");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
