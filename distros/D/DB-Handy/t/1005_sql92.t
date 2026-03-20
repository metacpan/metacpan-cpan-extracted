######################################################################
#
# Tests SQL-92 features: GROUP BY, HAVING, DISTINCT, ORDER BY
# (multi-column), UNION, CASE WHEN, COALESCE, NULLIF, CAST,
# scalar functions, arithmetic, string concatenation, IS NULL,
# NOT LIKE, BETWEEN, column aliases, JOIN+GROUP BY, and more.
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
sub is      { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub rows_ok { my($r,$c,$n)=@_; $T++; (ref($r) eq 'ARRAY')&&(@$r==$c) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got=".(ref($r) eq 'ARRAY'?scalar@$r:'undef').", exp=$c)\n") }

print "1..56\n";
use File::Path ();

sub qry {
    my($db,$sql)=@_;
    my $r=$db->execute($sql);
    if($r->{type} eq 'error'){$FAIL++;print "FAIL  SQL: $sql\n      msg: $r->{message}\n";return[]}
    return defined($r->{data}) ? $r->{data} : [];
}

# Fresh DB directory for each run
my $base="/tmp/sql92test_$$";
my $db=DB::Handy->new(base_dir=>$base);
$db->execute("CREATE DATABASE t");
$db->execute("USE t");

###############################################################################
# WHERE: AND/OR/NOT
###############################################################################
{
    qry($db,"CREATE TABLE w (id INT, v INT)");
    qry($db,"INSERT INTO w (id,v) VALUES (1,10)");
    qry($db,"INSERT INTO w (id,v) VALUES (2,20)");
    qry($db,"INSERT INTO w (id,v) VALUES (3,30)");
    qry($db,"INSERT INTO w (id,v) VALUES (4,40)");

    # ok 1
    rows_ok(qry($db,"SELECT id FROM w WHERE v > 15"),              3,"WHERE v > 15");

    # ok 2
    rows_ok(qry($db,"SELECT id FROM w WHERE v >= 20 AND v <= 30"), 2,"WHERE AND");

    # ok 3
    rows_ok(qry($db,"SELECT id FROM w WHERE v < 15 OR v > 35"),    2,"WHERE OR");

    # ok 4
    rows_ok(qry($db,"SELECT id FROM w WHERE NOT v = 10"),          3,"WHERE NOT");}

###############################################################################
# BETWEEN
###############################################################################
{

    # ok 5
    rows_ok(qry($db,"SELECT id FROM w WHERE v BETWEEN 15 AND 35"),     2,"BETWEEN");

    # ok 6
    rows_ok(qry($db,"SELECT id FROM w WHERE v NOT BETWEEN 15 AND 35"), 2,"NOT BETWEEN");}

###############################################################################
# IS NULL / IS NOT NULL
###############################################################################
{
    qry($db,"CREATE TABLE n (id INT, x VARCHAR(10))");
    qry($db,"INSERT INTO n (id,x) VALUES (1,'hello')");
    qry($db,"INSERT INTO n (id)   VALUES (2)");
    qry($db,"INSERT INTO n (id)   VALUES (3)");

    # ok 7
    rows_ok(qry($db,"SELECT id FROM n WHERE x IS NULL"),     2,"IS NULL");

    # ok 8
    rows_ok(qry($db,"SELECT id FROM n WHERE x IS NOT NULL"), 1,"IS NOT NULL");}

###############################################################################
# LIKE / NOT LIKE
###############################################################################
{
    qry($db,"CREATE TABLE l (id INT, name VARCHAR(20))");
    qry($db,"INSERT INTO l (id,name) VALUES (1,'alice')");
    qry($db,"INSERT INTO l (id,name) VALUES (2,'bob')");
    qry($db,"INSERT INTO l (id,name) VALUES (3,'carol')");

    # ok 9
    rows_ok(qry($db,"SELECT id FROM l WHERE name LIKE 'a%'"),   1,"LIKE 'a%'");

    # ok 10
    rows_ok(qry($db,"SELECT id FROM l WHERE name LIKE '%o%'"),  2,"LIKE '%o%'");

    # ok 11
    rows_ok(qry($db,"SELECT id FROM l WHERE name NOT LIKE '%o%'"),1,"NOT LIKE (alice only)");}

###############################################################################
# Column alias + expressions
###############################################################################
{
    my $r=qry($db,"SELECT v * 2 AS dbl FROM w WHERE id = 1");

    # ok 12
    rows_ok($r,1,"expr AS alias: 1 row");

    # ok 13
    is($r->[0]{dbl}, 20, "v*2=20");

    $r=qry($db,"SELECT id, v+100 AS v2, v*3 AS v3 FROM w WHERE id = 2");

    # ok 14
    is($r->[0]{v2}, 120, "v+100=120");

    # ok 15
    is($r->[0]{v3}, 60, "v*3=60");
}

###############################################################################
# String functions
###############################################################################
{
    my $r=qry($db,"SELECT UPPER(name) AS u FROM l WHERE id=1");

    # ok 16
    is($r->[0]{u}, 'ALICE', 'UPPER()');
    $r=qry($db,"SELECT LENGTH(name) AS len FROM l WHERE id=3");

    # ok 17
    is($r->[0]{len}, 5, 'LENGTH(carol)=5');
    $r=qry($db,"SELECT SUBSTR(name,1,3) AS s FROM l WHERE id=2");

    # ok 18
    is($r->[0]{s}, 'bob', 'SUBSTR(bob,1,3)');
}

###############################################################################
# CASE WHEN
###############################################################################
{
    my $r=qry($db,"SELECT id, CASE WHEN v<20 THEN 'low' WHEN v<35 THEN 'mid' ELSE 'high' END AS g FROM w");

    # ok 19
    rows_ok($r,4,"CASE: 4 rows");    my %g=map{$_->{id}=>$_->{g}}@$r;

    # ok 20
    is($g{1}, 'low', "id=1 low");

    # ok 21
    is($g{2}, 'mid', "id=2 mid");

    # ok 22
    is($g{4}, 'high', "id=4 high");
}

###############################################################################
# COALESCE
###############################################################################
{
    my $r=qry($db,"SELECT id, COALESCE(x,'none') AS x2 FROM n");

    # ok 23
    rows_ok($r,3,"COALESCE: 3 rows");    my %h=map{$_->{id}=>$_->{x2}}@$r;

    # ok 24
    is($h{1}, 'hello', "COALESCE keeps value");

    # ok 25
    is($h{2}, 'none', "COALESCE null->none");
}

###############################################################################
# DISTINCT
###############################################################################
{
    qry($db,"CREATE TABLE d (cat VARCHAR(5))");
    qry($db,"INSERT INTO d (cat) VALUES ('A')");
    qry($db,"INSERT INTO d (cat) VALUES ('B')");
    qry($db,"INSERT INTO d (cat) VALUES ('A')");

    # ok 26
    rows_ok(qry($db,"SELECT DISTINCT cat FROM d"),2,"DISTINCT 2 cats");}

###############################################################################
# ORDER BY (multi-col, ASC/DESC)
###############################################################################
{

    my $r=qry($db,"SELECT id FROM w ORDER BY id ASC");

    # ok 27
    is($r->[0]{id}, 1, "ORDER ASC first=1");

    # ok 28
    is($r->[-1]{id}, 4, "ORDER ASC last=4");

    qry($db,"CREATE TABLE ob (g VARCHAR(3), v INT)");
    qry($db,"INSERT INTO ob (g,v) VALUES ('B',2)");
    qry($db,"INSERT INTO ob (g,v) VALUES ('A',3)");
    qry($db,"INSERT INTO ob (g,v) VALUES ('A',1)");
    my $rdesc=qry($db,"SELECT g,v FROM ob ORDER BY v DESC");

    # ok 29
    is($rdesc->[0]{v}, 3, "ob ORDER DESC first v=3");

    # ok 30
    is($rdesc->[-1]{v}, 1, "ob ORDER DESC last v=1");
    $r=qry($db,"SELECT g,v FROM ob ORDER BY g ASC, v DESC");

    # ok 31
    is($r->[0]{g}, 'A', "multi-col: first g=A");

    # ok 32
    is($r->[0]{v}, 3, "multi-col: first v=3");

    # ok 33
    is($r->[1]{v}, 1, "multi-col: second v=1");
}

###############################################################################
# GROUP BY + aggregates
###############################################################################
{
    qry($db,"CREATE TABLE s (dept VARCHAR(5), amt INT)");
    qry($db,"INSERT INTO s (dept,amt) VALUES ('Eng',100)");
    qry($db,"INSERT INTO s (dept,amt) VALUES ('Eng',200)");
    qry($db,"INSERT INTO s (dept,amt) VALUES ('Mkt',150)");
    qry($db,"INSERT INTO s (dept,amt) VALUES ('Mkt',50)");
    qry($db,"INSERT INTO s (dept,amt) VALUES ('Eng',300)");

    my $r=qry($db,"SELECT dept, COUNT(*) AS cnt, SUM(amt) AS total FROM s GROUP BY dept ORDER BY dept");

    # ok 34
    rows_ok($r,2,"GROUP BY 2 depts");    my %g=map{$_->{dept}=>$_}@$r;

    # ok 35
    is($g{Eng}{cnt}, 3, "Eng COUNT=3");

    # ok 36
    is($g{Eng}{total}, 600, "Eng SUM=600");

    # ok 37
    is($g{Mkt}{cnt}, 2, "Mkt COUNT=2");

    # ok 38
    is($g{Mkt}{total}, 200, "Mkt SUM=200");

    $r=qry($db,"SELECT dept, MIN(amt) AS mn, MAX(amt) AS mx FROM s GROUP BY dept ORDER BY dept");
    my %g2=map{$_->{dept}=>$_}@$r;

    # ok 39
    is($g2{Eng}{mn}, 100, "Eng MIN=100");

    # ok 40
    is($g2{Eng}{mx}, 300, "Eng MAX=300");

    $r=qry($db,"SELECT dept, AVG(amt) AS av FROM s GROUP BY dept ORDER BY dept");
    my %g3=map{$_->{dept}=>$_}@$r;

    # ok 41
    is(int($g3{Eng}{av}+0.5), 200, "Eng AVG~200");
}

###############################################################################
# HAVING
###############################################################################
{
    my $r=qry($db,"SELECT dept, SUM(amt) AS total FROM s GROUP BY dept HAVING SUM(amt) > 300");

    # ok 42
    rows_ok($r,1,"HAVING SUM>300: 1 row");

    # ok 43
    is($r->[0]{dept}, 'Eng', "HAVING: Eng");

    $r=qry($db,"SELECT dept, COUNT(*) AS cnt FROM s GROUP BY dept HAVING COUNT(*) >= 2");

    # ok 44
    rows_ok($r,2,"HAVING COUNT>=2: both");}

###############################################################################
# COUNT(DISTINCT)
###############################################################################
{
    my $r=qry($db,"SELECT COUNT(DISTINCT dept) AS ud FROM s");

    # ok 45
    is($r->[0]{ud}, 2, "COUNT(DISTINCT dept)=2");
}

###############################################################################
# UNION / UNION ALL
###############################################################################
{
    qry($db,"CREATE TABLE ua (x INT)");
    qry($db,"CREATE TABLE ub (x INT)");
    qry($db,"INSERT INTO ua (x) VALUES (1)");
    qry($db,"INSERT INTO ua (x) VALUES (2)");
    qry($db,"INSERT INTO ub (x) VALUES (2)");
    qry($db,"INSERT INTO ub (x) VALUES (3)");

    # ok 46
    rows_ok(qry($db,"SELECT x FROM ua UNION ALL SELECT x FROM ub"),4,"UNION ALL: 4");

    # ok 47
    rows_ok(qry($db,"SELECT x FROM ua UNION SELECT x FROM ub"),    3,"UNION dedup: 3");}

###############################################################################
# INSERT INTO ... SELECT
###############################################################################
{
    qry($db,"CREATE TABLE scopy (dept VARCHAR(5), amt INT)");
    qry($db,"INSERT INTO scopy (dept,amt) SELECT dept,amt FROM s WHERE dept = 'Eng'");
    my $r=qry($db,"SELECT COUNT(*) AS n FROM scopy");

    # ok 48
    is($r->[0]{n}, 3, "INSERT-SELECT: 3 Eng rows");
}

###############################################################################
# Column constraints: NOT NULL, DEFAULT
###############################################################################
{
    qry($db,"CREATE TABLE ct (id INT NOT NULL, name VARCHAR(10), status VARCHAR(10) DEFAULT 'active')");
    qry($db,"INSERT INTO ct (id,name) VALUES (1,'Alice')");
    my $r=qry($db,"SELECT status FROM ct WHERE id=1");

    # ok 49
    is($r->[0]{status}, 'active', "DEFAULT applied");

    my $err=$db->execute("INSERT INTO ct (name) VALUES ('Bob')");

    # ok 50
    is($err->{type}, 'error', "NOT NULL violation");
}

###############################################################################
# UPDATE with expressions
###############################################################################
{
    qry($db,"UPDATE w SET v = v * 2 WHERE id = 1");
    my $r=qry($db,"SELECT v FROM w WHERE id=1");

    # ok 51
    is($r->[0]{v}, 20, "UPDATE v=v*2: 10->20");

    qry($db,"UPDATE w SET v = v + 1"); #koko Perl5.5hung, Perl5.42 ok
    $r=qry($db,"SELECT v FROM w WHERE id=2");

    # ok 52
    is($r->[0]{v}, 21, "UPDATE all: 20->21");
}

###############################################################################
# DELETE with complex WHERE
###############################################################################
{
    qry($db,"CREATE TABLE dt (id INT, x INT)");
    qry($db,"INSERT INTO dt (id,x) VALUES (1,10)");
    qry($db,"INSERT INTO dt (id,x) VALUES (2,20)");
    qry($db,"INSERT INTO dt (id,x) VALUES (3,30)");
    qry($db,"INSERT INTO dt (id,x) VALUES (4,40)");
    qry($db,"DELETE FROM dt WHERE x < 15 OR x > 35");
    my $r=qry($db,"SELECT COUNT(*) AS n FROM dt");

    # ok 53
    is($r->[0]{n}, 2, "DELETE OR: 2 remain");
}

###############################################################################
# LIMIT / OFFSET
###############################################################################
{
    my $r=qry($db,"SELECT id FROM w ORDER BY id LIMIT 2");

    # ok 54
    rows_ok($r,2,"LIMIT 2");    $r=qry($db,"SELECT id FROM w ORDER BY id LIMIT 2 OFFSET 1");

    # ok 55
    rows_ok($r,2,"LIMIT 2 OFFSET 1");

    # ok 56
    is($r->[0]{id}, 2, "OFFSET 1: id=2");
}

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($base) if -d $base;

exit($FAIL ? 1 : 0);
