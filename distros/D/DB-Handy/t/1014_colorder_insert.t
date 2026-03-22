######################################################################
#
# Tests for two new features in 1.05:
#
#   Feature A: SELECT * and JOIN preserve column declaration order.
#              SELECT * FROM t     -> NAME follows CREATE TABLE order.
#              SELECT * with JOIN  -> NAME follows table appearance
#                                     order, each table in CREATE order.
#
#   Feature B: INSERT INTO table VALUES (...) without a column list
#              is now supported; columns are matched by position in
#              the CREATE TABLE declaration order.
#
# Perl 5.005_03 compatible: no 'our', no say, no //, no given/when,
# no Time::HiRes, no external modules.
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

print "1..76\n";

use File::Path ();
my $BASE = "/tmp/test_colorder_insert_$$";
File::Path::rmtree($BASE) if -d $BASE;

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('t');
$db->use_database('t');

###############################################################################
# Setup: tables with non-alphabetical column order
###############################################################################
$db->execute("CREATE TABLE emp  (id INT, name VARCHAR(40), dept VARCHAR(20), salary INT)");
$db->execute("CREATE TABLE dept (did INT, dname VARCHAR(20), budget INT)");
$db->execute("CREATE TABLE proj (pid INT, pname VARCHAR(40), lead_id INT)");

# Insert via column-list form (proven to work)
$db->execute("INSERT INTO emp  (id,name,dept,salary)   VALUES (1,'Alice','Eng',90000)");
$db->execute("INSERT INTO emp  (id,name,dept,salary)   VALUES (2,'Bob',  'Mkt',60000)");
$db->execute("INSERT INTO emp  (id,name,dept,salary)   VALUES (3,'Carol','Eng',75000)");
$db->execute("INSERT INTO dept (did,dname,budget)      VALUES (1,'Engineering',500000)");
$db->execute("INSERT INTO dept (did,dname,budget)      VALUES (2,'Marketing',  300000)");
$db->execute("INSERT INTO proj (pid,pname,lead_id)     VALUES (1,'Alpha',1)");
$db->execute("INSERT INTO proj (pid,pname,lead_id)     VALUES (2,'Beta', 2)");

my $dbh = DB::Handy->connect($BASE, 't');

###############################################################################
# Feature A -- SELECT * column order (single table)
###############################################################################

# A1: NAME reflects CREATE TABLE declaration order
my $sth = $dbh->prepare("SELECT * FROM emp WHERE id=1");
$sth->execute;
# ok 1
is(join(',', @{$sth->{NAME}}), 'id,name,dept,salary',
    "A: SELECT * NAME follows CREATE order");
# ok 2
is($sth->{NUM_OF_FIELDS}+0, 4, "A: NUM_OF_FIELDS=4");
my $aref = $sth->fetchrow_arrayref;
# ok 3
is($aref->[0]+0, 1,       "A: arrayref[0]=id=1");
# ok 4
is($aref->[1],   'Alice',  "A: arrayref[1]=name=Alice");
# ok 5
is($aref->[2],   'Eng',    "A: arrayref[2]=dept=Eng");
# ok 6
is($aref->[3]+0, 90000,   "A: arrayref[3]=salary=90000");
$sth->finish;

# A2: fetchrow_array also in declaration order
$sth = $dbh->prepare("SELECT * FROM emp WHERE id=2");
$sth->execute;
my @row = $sth->fetchrow_array;
# ok 7
is(scalar @row, 4, "A: fetchrow_array 4 elements");
# ok 8
is($row[0]+0, 2,     "A: fetchrow_array[0]=id=2");
# ok 9
is($row[1],   'Bob', "A: fetchrow_array[1]=name=Bob");
$sth->finish;

# A3: 0-row result still has correct NAME from SQL
$sth = $dbh->prepare("SELECT * FROM emp WHERE id=9999");
$sth->execute;
# ok 10
is(join(',', @{$sth->{NAME}}), 'id,name,dept,salary',
    "A: SELECT * 0-row NAME from schema");
# ok 11
is($sth->{NUM_OF_FIELDS}+0, 4, "A: 0-row NUM_OF_FIELDS=4");
$sth->finish;

# A4: All rows in order
$sth = $dbh->prepare("SELECT * FROM emp ORDER BY id");
$sth->execute;
my @all_rows;
while (my $r = $sth->fetchrow_arrayref) { push @all_rows, [ @$r ] }
$sth->finish;
# ok 12
is(scalar @all_rows, 3, "A: 3 rows");
# ok 13
is($all_rows[0][1], 'Alice', "A: row0 name=Alice");
# ok 14
is($all_rows[1][2], 'Mkt',   "A: row1 dept=Mkt");
# ok 15
is($all_rows[2][3]+0, 75000, "A: row2 salary=75000");

# A5: named SELECT list still preserved (regression)
$sth = $dbh->prepare("SELECT salary, name FROM emp WHERE id=1");
$sth->execute;
# ok 16
is(join(',', @{$sth->{NAME}}), 'salary,name',
    "A: named SELECT list still in SELECT order (regression)");
my $h = $sth->fetchrow_hashref;
$sth->finish;

# A6: selectall_arrayref with SELECT * and Slice=>{}
my $all = $dbh->selectall_arrayref("SELECT * FROM emp ORDER BY id", { Slice=>{} });
# ok 17
is(scalar @$all, 3, "A: selectall 3 rows");
# ok 18
is($all->[0]{id}+0,  1,       "A: selectall[0]{id}=1");
# ok 19
is($all->[0]{name},  'Alice', "A: selectall[0]{name}=Alice");

# A7: selectrow_arrayref with SELECT *
my $saref = $dbh->selectrow_arrayref("SELECT * FROM emp WHERE id=3");
# ok 20
is($saref->[0]+0, 3,       "A: selectrow_arrayref[0]=id=3");
# ok 21
is($saref->[1],   'Carol', "A: selectrow_arrayref[1]=name=Carol");
# ok 22
is($saref->[2],   'Eng',   "A: selectrow_arrayref[2]=dept=Eng");
# ok 23
is($saref->[3]+0, 75000,   "A: selectrow_arrayref[3]=salary=75000");

# A8: SELECT * with WHERE on non-key column
$sth = $dbh->prepare("SELECT * FROM emp WHERE dept='Eng' ORDER BY id");
$sth->execute;
# ok 24
is(join(',', @{$sth->{NAME}}), 'id,name,dept,salary',
    "A: SELECT * WHERE non-key: NAME correct");
my @eng;
while (my $r = $sth->fetchrow_arrayref) { push @eng, $r->[1] }
$sth->finish;
# ok 25
is(join(',', @eng), 'Alice,Carol', "A: WHERE dept=Eng: Alice,Carol");

# A9: SELECT DISTINCT * (fallback acceptable -- DISTINCT * is unusual)
my $r = $db->execute("SELECT DISTINCT dept FROM emp");
# ok 26
ok(scalar @{$r->{data}} == 2, "A: DISTINCT dept: 2 unique depts");

###############################################################################
# Feature A -- SELECT * with JOIN (multi-table column order)
###############################################################################

# B1: INNER JOIN SELECT * -- table appearance order
$sth = $dbh->prepare(
    "SELECT * FROM emp AS e INNER JOIN dept AS d ON e.id = d.did WHERE e.id=1");
$sth->execute;
my @join_names = @{$sth->{NAME}};
# ok 27
is($join_names[0], 'e.id',    "B: JOIN NAME[0]=e.id");
# ok 28
is($join_names[1], 'e.name',  "B: JOIN NAME[1]=e.name");
# ok 29
is($join_names[2], 'e.dept',  "B: JOIN NAME[2]=e.dept");
# ok 30
is($join_names[3], 'e.salary',"B: JOIN NAME[3]=e.salary");
# ok 31
is($join_names[4], 'd.did',   "B: JOIN NAME[4]=d.did");
# ok 32
is($join_names[5], 'd.dname', "B: JOIN NAME[5]=d.dname");
# ok 33
is($join_names[6], 'd.budget',"B: JOIN NAME[6]=d.budget");
# ok 34
is(scalar @join_names, 7, "B: JOIN 7 columns total");
my $jr = $sth->fetchrow_arrayref;
# ok 35
is($jr->[0]+0, 1,             "B: JOIN arrayref[0]=e.id=1");
# ok 36
is($jr->[1],   'Alice',       "B: JOIN arrayref[1]=e.name=Alice");
# ok 37
is($jr->[4]+0, 1,             "B: JOIN arrayref[4]=d.did=1");
# ok 38
is($jr->[5],   'Engineering', "B: JOIN arrayref[5]=d.dname=Engineering");
$sth->finish;

# B2: LEFT JOIN SELECT *
$sth = $dbh->prepare(
    "SELECT * FROM emp AS e LEFT JOIN proj AS p ON e.id = p.lead_id ORDER BY e.id");
$sth->execute;
my @lj_names = @{$sth->{NAME}};
# ok 39
is($lj_names[0], 'e.id',    "B: LEFT JOIN NAME[0]=e.id");
# ok 40
is($lj_names[4], 'p.pid',   "B: LEFT JOIN NAME[4]=p.pid");
# ok 41
is($lj_names[5], 'p.pname', "B: LEFT JOIN NAME[5]=p.pname");
$sth->finish;

# B3: Named JOIN SELECT list still works (regression)
$sth = $dbh->prepare(
    "SELECT e.name, d.dname FROM emp AS e INNER JOIN dept AS d ON e.id = d.did WHERE e.id=1");
$sth->execute;
# ok 42
is(join(',', @{$sth->{NAME}}), 'e.name,d.dname',
    "B: named JOIN SELECT list still in SELECT order");
$sth->finish;

###############################################################################
# Feature B -- INSERT without column list
###############################################################################

# C1: Basic INSERT without column list
$r = $db->execute("INSERT INTO emp VALUES (10,'Dave','HR',70000)");
# ok 43
ok($r->{type} eq 'ok', "C: INSERT no-col-list ok");

# C2: Values inserted correctly (fetch by column name)
$r = $db->execute("SELECT id,name,dept,salary FROM emp WHERE id=10");
# ok 44
is(scalar @{$r->{data}}, 1, "C: inserted row found");
# ok 45
is($r->{data}[0]{name},       'Dave', "C: name=Dave");
# ok 46
is($r->{data}[0]{dept},       'HR',   "C: dept=HR");
# ok 47
is($r->{data}[0]{salary}+0,   70000,  "C: salary=70000");

# C3: INSERT with wrong number of values -> error
$r = $db->execute("INSERT INTO emp VALUES (11,'Eve')");
# ok 48
ok($r->{type} eq 'error', "C: too few values -> error");
# ok 49
ok($r->{message} =~ /\d+.*column/i, "C: error message mentions column count");

# C4: INSERT with too many values -> error
$r = $db->execute("INSERT INTO emp VALUES (12,'Frank','Sales',55000,99)");
# ok 50
ok($r->{type} eq 'error', "C: too many values -> error");

# C5: INSERT no-col-list into dept
$r = $db->execute("INSERT INTO dept VALUES (3,'HR',200000)");
# ok 51
ok($r->{type} eq 'ok', "C: INSERT dept no-col-list ok");
$r = $db->execute("SELECT dname,budget FROM dept WHERE did=3");
# ok 52
is($r->{data}[0]{dname},     'HR',    "C: dept dname=HR");
# ok 53
is($r->{data}[0]{budget}+0, 200000,   "C: dept budget=200000");

# C6: INSERT no-col-list respects column order (not alphabetical)
# emp order: id, name, dept, salary
# If values mapped alphabetically they'd go to: dept, id, name, salary
$r = $db->execute("INSERT INTO emp VALUES (20,'Zara','Fin',80000)");
# ok 54
ok($r->{type} eq 'ok', "C: INSERT order check: ok");
$r = $db->execute("SELECT id,name,dept,salary FROM emp WHERE id=20");
# ok 55
is($r->{data}[0]{id}+0,     20,      "C: id=20 correct");
# ok 56
is($r->{data}[0]{name},     'Zara',  "C: name=Zara correct");
# ok 57
is($r->{data}[0]{dept},     'Fin',   "C: dept=Fin (not id 20!)");
# ok 58
is($r->{data}[0]{salary}+0, 80000,   "C: salary=80000 correct");

# C7: INSERT no-col-list with NULL
$db->execute("CREATE TABLE nullable (id INT, val INT, note VARCHAR(20))");
$r = $db->execute("INSERT INTO nullable VALUES (1,NULL,'test')");
# ok 59
ok($r->{type} eq 'ok', "C: INSERT with NULL ok");
$r = $db->execute("SELECT * FROM nullable WHERE id=1");
# ok 60
is($r->{data}[0]{id}+0, 1,      "C: nullable id=1");
# ok 61
is($r->{data}[0]{note},  'test', "C: nullable note=test");

# C8: INSERT no-col-list into non-existent table -> error
$r = $db->execute("INSERT INTO no_such_table VALUES (1,2,3)");
# ok 62
ok($r->{type} eq 'error', "C: INSERT no-exist table -> error");

# C9: INSERT no-col-list with string values
$db->execute("CREATE TABLE tags (code CHAR(5), label VARCHAR(30), rank INT)");
$r = $db->execute("INSERT INTO tags VALUES ('X001','Alpha Test',1)");
# ok 63
ok($r->{type} eq 'ok', "C: INSERT string values ok");
$r = $db->execute("SELECT * FROM tags WHERE code='X001'");
# ok 64
is($r->{data}[0]{code},    'X001',       "C: code=X001");
# ok 65
is($r->{data}[0]{label},   'Alpha Test', "C: label=Alpha Test");
# ok 66
is($r->{data}[0]{rank}+0,  1,            "C: rank=1");

###############################################################################
# Combined: INSERT no-col-list then SELECT * in order
###############################################################################
$db->execute("CREATE TABLE product (sku INT, name VARCHAR(30), price FLOAT, stock INT)");
$r = $db->execute("INSERT INTO product VALUES (100,'Widget',9.99,50)");
# ok 67
ok($r->{type} eq 'ok', "Combined: INSERT ok");
$sth = $dbh->prepare("SELECT * FROM product WHERE sku=100");
$sth->execute;
# ok 68
is(join(',', @{$sth->{NAME}}), 'sku,name,price,stock',
    "Combined: SELECT * NAME in CREATE order");
my $pr = $sth->fetchrow_arrayref;
# ok 69
is($pr->[0]+0, 100,      "Combined: arrayref[0]=sku=100");
# ok 70
is($pr->[1],   'Widget', "Combined: arrayref[1]=name=Widget");
$sth->finish;

###############################################################################
# SELECT * with LIMIT and OFFSET
###############################################################################
$sth = $dbh->prepare("SELECT * FROM emp ORDER BY id LIMIT 2");
$sth->execute;
# ok 71
is(join(',', @{$sth->{NAME}}), 'id,name,dept,salary',
    "A: SELECT * LIMIT: NAME in CREATE order");
my $lr = $sth->fetchrow_arrayref;
# ok 72
is($lr->[0]+0, 1, "A: SELECT * LIMIT: first row id=1");
$sth->finish;

###############################################################################
# INSERT no-col-list with placeholders
###############################################################################
my $ins_sth = $dbh->prepare("INSERT INTO emp VALUES (?,?,?,?)");
my $ins_rv = $ins_sth->execute(50, 'Yuki', 'Ops', 72000);
# ok 73
ok(defined $ins_rv && $ins_rv == 1, "C: INSERT no-col-list placeholder: rv=1");
$ins_sth->finish;
my $pr2 = $dbh->selectrow_hashref(
    "SELECT id,name,dept,salary FROM emp WHERE id=50");
# ok 74
is($pr2->{name}, 'Yuki', "C: INSERT no-col-list placeholder: name=Yuki");

###############################################################################
# Regression: existing INSERT with column list still works
###############################################################################
$r = $db->execute("INSERT INTO emp (id,name,dept,salary) VALUES (30,'Hana','Ops',65000)");
# ok 75
ok($r->{type} eq 'ok', "Regression: INSERT with col list still works");
$r = $db->execute("SELECT name FROM emp WHERE id=30");
# ok 76
is($r->{data}[0]{name}, 'Hana', "Regression: INSERT col list: name=Hana");

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
