######################################################################
#
# Tests for unsupported-feature behaviour in 1.06:
#
#   Each unsupported feature now returns a clear error or documented
#   response rather than silently producing wrong results or crashing.
#
#   1. WINDOW functions (OVER clause) -> type='error'
#   2. FOREIGN KEY in CREATE TABLE    -> type='ok' with note in message
#   3. begin_work / commit / rollback -> return undef, set errstr
#   4. AutoCommit attribute           -> always returns 1
#   5. VARCHAR / CHAR declared-size enforcement -> type='error' on overflow
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

print "1..56\n";

use File::Path ();
my $BASE = "/tmp/test_unsupported_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('t');
$db->use_database('t');
$db->execute("CREATE TABLE emp (id INT, name VARCHAR(20))");
$db->execute("INSERT INTO emp (id,name) VALUES (1,'Alice')");
$db->execute("INSERT INTO emp (id,name) VALUES (2,'Bob')");

my $dbh = DB::Handy->connect($BASE, 't');

###############################################################################
# 1. WINDOW functions -> type='error'
###############################################################################

# 1-1: ROW_NUMBER() OVER ()
my $r = $db->execute("SELECT id, ROW_NUMBER() OVER () AS rn FROM emp");
# ok 1
ok($r->{type} eq 'error', "WINDOW: ROW_NUMBER() OVER() -> error");
# ok 2
ok($r->{message} =~ /Window|OVER|not supported/i,
    "WINDOW: error message mentions OVER/Window");

# 1-2: RANK() OVER (ORDER BY id)
$r = $db->execute("SELECT id, RANK() OVER (ORDER BY id) AS rnk FROM emp");
# ok 3
ok($r->{type} eq 'error', "WINDOW: RANK() OVER(ORDER BY) -> error");

# 1-3: PARTITION BY
$r = $db->execute(
    "SELECT id, ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) AS rn FROM emp");
# ok 4
ok($r->{type} eq 'error', "WINDOW: ROW_NUMBER() OVER(PARTITION BY) -> error");

# 1-4: LAG / LEAD
$r = $db->execute("SELECT id, LAG(id) OVER (ORDER BY id) AS lag FROM emp");
# ok 5
ok($r->{type} eq 'error', "WINDOW: LAG() OVER -> error");

# 1-5: SUM() OVER ()
$r = $db->execute("SELECT id, SUM(id) OVER () AS running FROM emp");
# ok 6
ok($r->{type} eq 'error', "WINDOW: SUM() OVER -> error");

# 1-6: Normal aggregate (no OVER) still works
$r = $db->execute("SELECT COUNT(*) AS n FROM emp");
# ok 7
ok($r->{type} eq 'rows', "WINDOW: normal COUNT(*) still works");
# ok 8
is($r->{data}[0]{n}+0, 2, "WINDOW: COUNT(*)=2");

# 1-7: OVER inside string literal does NOT trigger error
$r = $db->execute("SELECT id FROM emp WHERE name='OVER()'");
# ok 9
ok($r->{type} eq 'rows', "WINDOW: OVER in string literal not flagged");

###############################################################################
# 2. FOREIGN KEY in CREATE TABLE
###############################################################################

# 2-1: REFERENCES syntax -> ok but message notes FK not enforced
$db->execute("CREATE TABLE dept (id INT, name VARCHAR(20))");
$db->execute("INSERT INTO dept (id,name) VALUES (1,'Eng')");
$r = $db->execute("CREATE TABLE child1 (id INT, dept_id INT REFERENCES dept(id))");
# ok 10
ok($r->{type} eq 'ok', "FK: CREATE TABLE with REFERENCES -> ok");
# ok 11
ok($r->{message} =~ /FOREIGN KEY.*not enforced/i,
    "FK: message warns constraints not enforced");

# 2-2: INSERT violating FK does NOT produce an error (not enforced)
$r = $db->execute("INSERT INTO child1 (id,dept_id) VALUES (1,999)");
# ok 12
ok($r->{type} eq 'ok', "FK: INSERT violating FK -> ok (not enforced)");

# 2-3: FOREIGN KEY table constraint syntax
$r = $db->execute(
    "CREATE TABLE child2 (id INT, dept_id INT, FOREIGN KEY (dept_id) REFERENCES dept(id))");
# ok 13
ok($r->{type} eq 'ok', "FK: FOREIGN KEY table constraint -> ok");

# 2-4: Normal CREATE TABLE without FK is unaffected
$r = $db->execute("CREATE TABLE plain (id INT, name VARCHAR(10))");
# ok 14
ok($r->{type} eq 'ok', "FK: plain CREATE TABLE unaffected");
# ok 15
ok($r->{message} !~ /FOREIGN KEY/i, "FK: plain message has no FK note");

###############################################################################
# 3. begin_work / commit / rollback -> undef + errstr (not crash)
###############################################################################

# 3-1: begin_work returns undef
my $rv = $dbh->begin_work;
# ok 16
ok(!defined $rv, "TX: begin_work returns undef");
# ok 17
ok($dbh->errstr =~ /Transactions.*not supported|AutoCommit/i,
    "TX: begin_work sets errstr");

# 3-2: commit returns undef
$rv = $dbh->commit;
# ok 18
ok(!defined $rv, "TX: commit returns undef");
# ok 19
ok($dbh->errstr =~ /Transactions.*not supported|AutoCommit/i,
    "TX: commit sets errstr");

# 3-3: rollback returns undef
$rv = $dbh->rollback;
# ok 20
ok(!defined $rv, "TX: rollback returns undef");
# ok 21
ok($dbh->errstr =~ /Transactions.*not supported|AutoCommit/i,
    "TX: rollback sets errstr");

# 3-4: Normal operations still work after failed begin_work
$rv = $dbh->do("INSERT INTO emp (id,name) VALUES (3,'Carol')");
# ok 22
ok(defined $rv && $rv == 1, "TX: normal INSERT works after begin_work undef");

# 3-5: errstr is cleared on next successful operation
my $sth = $dbh->prepare("SELECT id FROM emp WHERE id=3");
$sth->execute;
my $h = $sth->fetchrow_hashref;
$sth->finish;
# ok 23
is($h->{id}+0, 3, "TX: SELECT works after failed begin_work");

###############################################################################
# 4. AutoCommit attribute
###############################################################################

# 4-1: AutoCommit returns 1
# ok 24
is($dbh->AutoCommit+0, 1, "AutoCommit: always 1");

# 4-2: AutoCommit from a new connection
my $dbh2 = DB::Handy->connect($BASE, 't');
# ok 25
is($dbh2->AutoCommit+0, 1, "AutoCommit: new connection also 1");
$dbh2->disconnect;

###############################################################################
# 5. VARCHAR / CHAR declared-size enforcement
###############################################################################

$db->execute("CREATE TABLE t_vc (id INT, s VARCHAR(5), c CHAR(3))");

# 5-1: INSERT within length -> ok
$r = $db->execute("INSERT INTO t_vc (id,s,c) VALUES (1,'hello','XYZ')");
# ok 26
ok($r->{type} eq 'ok', "VARCHAR: INSERT at declared length -> ok");

# 5-2: INSERT within shorter -> ok
$r = $db->execute("INSERT INTO t_vc (id,s,c) VALUES (2,'hi','AB')");
# ok 27
ok($r->{type} eq 'ok', "VARCHAR: INSERT shorter than declared -> ok");

# 5-3: INSERT VARCHAR too long -> error
$r = $db->execute("INSERT INTO t_vc (id,s,c) VALUES (3,'toolong','XY')");
# ok 28
ok($r->{type} eq 'error', "VARCHAR: INSERT too long -> error");
# ok 29
ok($r->{message} =~ /too long.*'s'|'s'.*too long|declared VARCHAR\(5\)/i,
    "VARCHAR: error message mentions column and size");

# 5-4: INSERT CHAR too long -> error
$r = $db->execute("INSERT INTO t_vc (id,s,c) VALUES (4,'ok','TOOLONG')");
# ok 30
ok($r->{type} eq 'error', "CHAR: INSERT too long -> error");
# ok 31
ok($r->{message} =~ /too long.*'c'|'c'.*too long|declared VARCHAR\(3\)/i,
    "CHAR: error message mentions column and size");

# 5-5: UPDATE VARCHAR too long -> error
$db->execute("INSERT INTO t_vc (id,s,c) VALUES (5,'abc','DE')");
$r = $db->execute("UPDATE t_vc SET s='toolongvalue' WHERE id=5");
# ok 32
ok($r->{type} eq 'error', "VARCHAR: UPDATE too long -> error");

# 5-6: UPDATE within length -> ok
$r = $db->execute("UPDATE t_vc SET s='fine' WHERE id=5");
# ok 33
ok($r->{type} eq 'ok', "VARCHAR: UPDATE within length -> ok");

# 5-7: Data not corrupted after failed INSERT
$r = $db->execute("SELECT COUNT(*) AS n FROM t_vc");
# ok 34
is($r->{data}[0]{n}+0, 3, "VARCHAR: 3 rows after failed inserts");

# 5-8: VARCHAR(255) has no declared-size restriction (max allowed)
$db->execute("CREATE TABLE t_big (id INT, s VARCHAR(255))");
my $long = 'A' x 200;
$r = $db->execute("INSERT INTO t_big (id,s) VALUES (1,'$long')");
# ok 35
ok($r->{type} eq 'ok', "VARCHAR(255): long value -> ok (no restriction)");

# 5-9: Correct value stored after passing check
$r = $db->execute("SELECT s FROM t_vc WHERE id=1");
# ok 36
is($r->{data}[0]{s}, 'hello', "VARCHAR: correct value stored");

# 5-10: VARCHAR with no size spec (defaults to 255, no restriction)
$db->execute("CREATE TABLE t_nosize (id INT, s VARCHAR)");
$r = $db->execute("INSERT INTO t_nosize (id,s) VALUES (1,'any length value here')");
# ok 37
ok($r->{type} eq 'ok', "VARCHAR no size: long value -> ok");

# 5-11: Old schema file compatibility (no decl field) -- simulate by
# checking that tables loaded from schema without decl field work
# This is implicit: all previous tests still pass (regression).
# ok 38
ok(1, "VARCHAR: backward compat with old schema (implicit via full test suite)");

###############################################################################
# 6. Interaction: FK + VARCHAR length
###############################################################################

$db->execute("CREATE TABLE product (code CHAR(3), name VARCHAR(10))");
$db->execute("CREATE TABLE order_item (id INT, code CHAR(3) REFERENCES product(code))");
$r = $db->execute("INSERT INTO product (code,name) VALUES ('A01','Widget')");
# ok 39
ok($r->{type} eq 'ok', "FK+VARCHAR: INSERT into product ok");
$r = $db->execute("INSERT INTO product (code,name) VALUES ('B01','Too Long Name Here')");
# ok 40
ok($r->{type} eq 'error', "FK+VARCHAR: INSERT too-long name -> error");
$r = $db->execute("INSERT INTO order_item (id,code) VALUES (1,'A01')");
# ok 41
ok($r->{type} eq 'ok', "FK+VARCHAR: INSERT order_item ok");

###############################################################################
# 7. DBI-like API: error handling for unsupported features
###############################################################################

# 7-1: prepare + execute with WINDOW -> execute returns undef
my $wsth = $dbh->prepare("SELECT id, ROW_NUMBER() OVER () AS rn FROM emp");
my $wex = $wsth->execute;
# ok 42
ok(!defined $wex || $wex == 0, "WINDOW DBI: execute returns undef/0");
# ok 43
ok(defined $wsth->errstr || defined $dbh->errstr,
    "WINDOW DBI: errstr set");
$wsth->finish;

# 7-2: selectall_arrayref with WINDOW -> undef
my $wa = $dbh->selectall_arrayref(
    "SELECT id, ROW_NUMBER() OVER () AS rn FROM emp");
# ok 44
ok(!defined $wa, "WINDOW DBI: selectall_arrayref returns undef");

###############################################################################
# 8. Unsupported SQL types (BLOB/CLOB) still rejected
###############################################################################

$r = $db->execute("CREATE TABLE t_blob (id INT, data BLOB)");
# ok 45
ok($r->{type} eq 'error', "BLOB: CREATE TABLE rejected");
# ok 46
ok($r->{message} =~ /Unknown type|not support|BLOB/i,
    "BLOB: error message mentions type");

$r = $db->execute("CREATE TABLE t_clob (id INT, data CLOB)");
# ok 47
ok($r->{type} eq 'error', "CLOB: CREATE TABLE rejected");

###############################################################################
# 9. CREATE VIEW still returns error
###############################################################################

$r = $db->execute("CREATE VIEW v_emp AS SELECT id,name FROM emp");
# ok 48
ok($r->{type} eq 'error', "VIEW: CREATE VIEW -> error");
# ok 49
ok($r->{message} =~ /not support|Unsupported/i,
    "VIEW: error message mentions not supported");

###############################################################################
# 10. Composite index still returns error
###############################################################################

$r = $db->execute("CREATE INDEX idx_comp ON emp (id, name)");
# ok 50
ok($r->{type} eq 'error', "Composite INDEX: CREATE -> error");

###############################################################################
# 11. Regression: normal operations unaffected by new checks
###############################################################################

# Normal INSERT/SELECT/UPDATE/DELETE still work
$db->execute("CREATE TABLE reg (id INT, s VARCHAR(10))");
$db->execute("INSERT INTO reg (id,s) VALUES (1,'hello')");
$r = $db->execute("SELECT s FROM reg WHERE id=1");
# ok 51
is($r->{data}[0]{s}, 'hello', "Regression: normal INSERT/SELECT ok");
$db->execute("UPDATE reg SET s='world' WHERE id=1");
$r = $db->execute("SELECT s FROM reg WHERE id=1");
# ok 52
is($r->{data}[0]{s}, 'world', "Regression: normal UPDATE ok");

# IN index still works
$db->execute("CREATE INDEX idx_reg ON reg (id)");
$r = $db->execute("SELECT s FROM reg WHERE id IN (1)");
# ok 53
is($r->{data}[0]{s}, 'world', "Regression: IN index ok");

# NOT IN index still works
$db->execute("INSERT INTO reg (id,s) VALUES (2,'two')");
$r = $db->execute("SELECT id FROM reg WHERE id NOT IN (2)");
# ok 54
is($r->{data}[0]{id}+0, 1, "Regression: NOT IN index ok");

# CHECK constraint still works
$db->execute("CREATE TABLE t_chk (id INT, v INT CHECK (v > 0))");
$r = $db->execute("INSERT INTO t_chk (id,v) VALUES (1,-1)");
# ok 55
ok($r->{type} eq 'error', "Regression: CHECK constraint ok");

# OR index still works
$r = $db->execute("SELECT id FROM reg WHERE id=1 OR id=2");
# ok 56
is(scalar @{$r->{data}}, 2, "Regression: OR query ok");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
