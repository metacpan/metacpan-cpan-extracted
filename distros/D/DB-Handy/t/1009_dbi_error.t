######################################################################
#
# Tests DBI-like error handling:
# RaiseError, PrintError, errstr/err on dbh and sth,
# last_insert_id, INSERT...SELECT, CAST, NULLIF, TRIM,
# string concatenation (||), and SELECT * / DISTINCT via DBI API.
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
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\ (defined $g?$g:'undef')}', exp='$e')\n") }
sub isnt { my($g,$e,$n)=@_; $T++; !defined($g)||("$g" ne "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (both='$g')\n") }

print "1..60\n";
use File::Path ();
my $BASE = "/tmp/test_dbi_error_$$";
File::Path::rmtree($BASE) if -d $BASE;

###############################################################################
# RaiseError
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest', {RaiseError => 1});

    # ok 1
    ok(defined $dbh, "connect with RaiseError=1 ok");

    $dbh->do("CREATE TABLE t1 (id INT, v VARCHAR(20))");
    $dbh->do("INSERT INTO t1 (id,v) VALUES (1,'alpha')");

    # RaiseError: error should die
    my $died = 0;
    eval { $dbh->do("SELECT * FROM no_such_table") };
    $died = 1 if $@;

    # ok 2
    ok($died, "RaiseError: failed do() causes die");
    # ok 3
    ok(length($@) > 0, "RaiseError: \$@ contains error message");

    # RaiseError: prepare+execute
    my $sth;
    eval { $sth = $dbh->prepare("SELECT * FROM no_such_table"); $sth->execute };
    # ok 4
    ok($@, "RaiseError: execute on missing table dies");

    $dbh->disconnect;
}

###############################################################################
# PrintError
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest', {PrintError => 1, RaiseError => 0});

    # ok 5
    ok(defined $dbh, "connect with PrintError=1 ok");

    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $rv = $dbh->do("SELECT * FROM no_such_table");

    # ok 6
    ok(!defined $rv, "PrintError: failed do() returns undef");
    # ok 7
    ok(scalar @warnings > 0, "PrintError: warning was emitted");
    # ok 8
    ok($warnings[0] =~ /DB::Handy/, "PrintError: warning mentions DB::Handy");

    $dbh->disconnect;
}

###############################################################################
# errstr / err: dbh level
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');

    # Successful operation: err should be 0
    $dbh->do("INSERT INTO t1 (id,v) VALUES (2,'beta')");
    # ok 9
    is($dbh->err+0, 0, "dbh->err is 0 after success");

    # Failed operation: err and errstr are set
    my $rv = $dbh->do("SELECT * FROM no_such_table");
    # ok 10
    ok(!defined $rv,          "do() on missing table returns undef");
    # ok 11
    ok($dbh->err,             "dbh->err is set after failure");
    # ok 12
    ok(length($dbh->errstr),  "dbh->errstr is non-empty after failure");

    # Package-level $DB::Handy::errstr mirrors dbh->errstr
    # ok 13
    ok(defined $DB::Handy::errstr && $DB::Handy::errstr ne '',
       "package-level errstr is set");

    $dbh->disconnect;
}

###############################################################################
# errstr / err: sth level
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    my $sth = $dbh->prepare("SELECT * FROM no_such_table");
    my $rv  = $sth->execute;

    # ok 14
    ok(!defined $rv,         "sth execute on missing table returns undef");
    # ok 15
    ok($sth->err,            "sth->err is set");
    # ok 16
    ok(length($sth->errstr), "sth->errstr is non-empty");

    # dbh->err propagated from sth
    # ok 17
    ok($dbh->err,            "dbh->err propagated from sth failure");

    $dbh->disconnect;
}

###############################################################################
# last_insert_id
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');

    $dbh->do("CREATE TABLE li (id INT, name VARCHAR(20))");
    $dbh->do("INSERT INTO li (id,name) VALUES (1,'row1')");

    my $n = $dbh->last_insert_id;
    # ok 18
    is($n+0, 1, "last_insert_id returns 1 after single INSERT");

    # Bulk INSERT...SELECT
    $dbh->do("CREATE TABLE li2 (id INT, name VARCHAR(20))");
    $dbh->do("INSERT INTO li2 (id,name) VALUES (10,'A')");
    $dbh->do("INSERT INTO li2 (id,name) VALUES (20,'B')");
    $dbh->do("INSERT INTO li2 (id,name) VALUES (30,'C')");
    $dbh->do("INSERT INTO li (id,name) SELECT id,name FROM li2");

    my $n2 = $dbh->last_insert_id;
    # ok 19
    is($n2+0, 3, "last_insert_id returns 3 after INSERT...SELECT of 3 rows");

    # Verify the rows were actually inserted
    my $rows = $dbh->selectall_arrayref("SELECT COUNT(*) AS n FROM li", {Slice=>{}});
    # ok 20
    is($rows->[0]{n}+0, 4, "INSERT...SELECT: 4 rows total in li");

    $dbh->disconnect;
}

###############################################################################
# INSERT...SELECT: column mapping
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE src (x INT, y VARCHAR(10))");
    $dbh->do("CREATE TABLE dst (a INT, b VARCHAR(10))");
    for my $i (1..5) {
        $dbh->do("INSERT INTO src (x,y) VALUES ($i,'val$i')");
    }

    # INSERT...SELECT maps columns positionally.
    # Use same column names to keep test simple and unambiguous.
    my $rv = $dbh->do("INSERT INTO dst (a,b) SELECT x,y FROM src WHERE x <= 3");
    # ok 21
    ok(defined $rv, "INSERT...SELECT: do() returns defined value");

    my $row = $dbh->selectrow_hashref("SELECT COUNT(*) AS n FROM dst");
    # ok 22
    is($row->{n}+0, 3, "INSERT...SELECT: 3 rows copied");

    # Verify row count is right; value check via same-name table
    $dbh->do("CREATE TABLE dst_same (x INT, y VARCHAR(10))");
    $dbh->do("INSERT INTO dst_same (x,y) SELECT x,y FROM src WHERE x = 2");
    my $row3 = $dbh->selectrow_hashref("SELECT y FROM dst_same WHERE x=2");
    # ok 23
    is($row3->{y}, 'val2', "INSERT...SELECT: correct value via same-name cols");

    $dbh->disconnect;
}

###############################################################################
# CAST
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE cst (id INT, v VARCHAR(20))");
    $dbh->do("INSERT INTO cst (id,v) VALUES (1,'42')");
    $dbh->do("INSERT INTO cst (id,v) VALUES (2,'3.14')");
    $dbh->do("INSERT INTO cst (id,v) VALUES (3,'hello')");

    my $row = $dbh->selectrow_hashref("SELECT CAST(v AS INT) AS iv FROM cst WHERE id=1");
    # ok 24
    is($row->{iv}+0, 42, "CAST(varchar AS INT): 42");

    $row = $dbh->selectrow_hashref("SELECT CAST(id AS VARCHAR) AS sv FROM cst WHERE id=2");
    # ok 25
    ok(defined $row->{sv}, "CAST(INT AS VARCHAR): defined");
    # ok 26
    is($row->{sv}, '2', "CAST(INT AS VARCHAR): '2'");

    $dbh->disconnect;
}

###############################################################################
# NULLIF
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE nif (id INT, v INT)");
    $dbh->do("INSERT INTO nif (id,v) VALUES (1,0)");
    $dbh->do("INSERT INTO nif (id,v) VALUES (2,5)");

    # NULLIF(v, 0) -> NULL when v=0, v otherwise
    my $row = $dbh->selectrow_hashref("SELECT NULLIF(v,0) AS nv FROM nif WHERE id=1");
    # ok 27
    ok(!defined $row->{nv}, "NULLIF(0,0): result is NULL/undef");

    $row = $dbh->selectrow_hashref("SELECT NULLIF(v,0) AS nv FROM nif WHERE id=2");
    # ok 28
    is($row->{nv}+0, 5, "NULLIF(5,0): result is 5");

    $dbh->disconnect;
}

###############################################################################
# TRIM
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE trm (id INT, v VARCHAR(30))");
    $dbh->do("INSERT INTO trm (id,v) VALUES (1,'  hello  ')");
    $dbh->do("INSERT INTO trm (id,v) VALUES (2,'world')");

    my $row = $dbh->selectrow_hashref("SELECT TRIM(v) AS tv FROM trm WHERE id=1");
    # ok 29
    is($row->{tv}, 'hello', "TRIM: leading/trailing spaces removed");

    $row = $dbh->selectrow_hashref("SELECT TRIM(v) AS tv FROM trm WHERE id=2");
    # ok 30
    is($row->{tv}, 'world', "TRIM: no-op on clean string");

    $dbh->disconnect;
}

###############################################################################
# || string concatenation operator
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE cat (id INT, fn VARCHAR(20), ln VARCHAR(20))");
    $dbh->do("INSERT INTO cat (id,fn,ln) VALUES (1,'John','Doe')");
    $dbh->do("INSERT INTO cat (id,fn,ln) VALUES (2,'Jane','Smith')");

    my $row = $dbh->selectrow_hashref(
        "SELECT fn || ' ' || ln AS full_name FROM cat WHERE id=1");
    # ok 31
    is($row->{full_name}, 'John Doe', "|| concat: 'John' || ' ' || 'Doe'");

    my $rows = $dbh->selectall_arrayref(
        "SELECT fn || ln AS no_space FROM cat ORDER BY id", {Slice=>{}});
    # ok 32
    is($rows->[0]{no_space}, 'JohnDoe',  "|| concat no space: JohnDoe");
    # ok 33
    is($rows->[1]{no_space}, 'JaneSmith',"|| concat no space: JaneSmith");

    # Concatenation in WHERE via alias (or direct expression filter)
    $rows = $dbh->selectall_arrayref(
        "SELECT id FROM cat WHERE fn || ln = 'JohnDoe'", {Slice=>{}});
    # ok 34
    is(scalar @$rows, 1, "|| in WHERE: 1 row matched");
    # ok 35
    is($rows->[0]{id}+0, 1, "|| in WHERE: id=1 matched");

    $dbh->disconnect;
}

###############################################################################
# % modulo operator
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE mod (id INT, v INT)");
    for my $i (1..6) { $dbh->do("INSERT INTO mod (id,v) VALUES ($i,$i)") }

    my $rows = $dbh->selectall_arrayref(
        "SELECT id FROM mod WHERE v % 2 = 0 ORDER BY id", {Slice=>{}});
    # ok 36
    is(scalar @$rows, 3, "modulo: 3 even numbers");
    # ok 37
    is($rows->[0]{id}+0, 2, "modulo: first even id=2");

    $dbh->disconnect;
}

###############################################################################
# DBI-like: LOWER() scalar function
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    # LOWER() on a column value (FROM-less SELECT is not supported)
    $dbh->do("CREATE TABLE lcase_lit (id INT, s VARCHAR(30))");
    $dbh->do("INSERT INTO lcase_lit (id,s) VALUES (99,'HELLO WORLD')");
    my $row = $dbh->selectrow_hashref(
        "SELECT LOWER(s) AS lv FROM lcase_lit WHERE id=99");
    # ok 38
    is($row->{lv}, 'hello world', "LOWER(): works on column value");

    $dbh->do("CREATE TABLE lcase (id INT, word VARCHAR(20))");
    $dbh->do("INSERT INTO lcase (id,word) VALUES (1,'ALPHA')");
    $dbh->do("INSERT INTO lcase (id,word) VALUES (2,'Beta')");

    my $rows = $dbh->selectall_arrayref(
        "SELECT LOWER(word) AS lw FROM lcase ORDER BY id", {Slice=>{}});
    # ok 39
    is($rows->[0]{lw}, 'alpha', "LOWER(col): 'ALPHA'->'alpha'");
    # ok 40
    is($rows->[1]{lw}, 'beta',  "LOWER(col): 'Beta'->'beta'");

    $dbh->disconnect;
}

###############################################################################
# DBI-like: SELECT DISTINCT
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE dist (id INT, cat VARCHAR(5))");
    for my $row ([1,'A'],[2,'B'],[3,'A'],[4,'C'],[5,'B'],[6,'A']) {
        $dbh->do("INSERT INTO dist (id,cat) VALUES ($row->[0],'$row->[1]')");
    }

    my $rows = $dbh->selectall_arrayref(
        "SELECT DISTINCT cat FROM dist ORDER BY cat", {Slice=>{}});
    # ok 41
    is(scalar @$rows, 3, "SELECT DISTINCT: 3 unique categories");
    # ok 42
    is($rows->[0]{cat}, 'A', "DISTINCT first: A");
    # ok 43
    is($rows->[2]{cat}, 'C', "DISTINCT last: C");

    $dbh->disconnect;
}

###############################################################################
# AutoUse => 0: do not auto-create/select database
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'newdb', {AutoUse => 0});
    # ok 44
    ok(defined $dbh, "connect AutoUse=0: returns handle");

    # No database selected -> table op fails
    my $rv = $dbh->do("CREATE TABLE t (id INT)");
    # ok 45
    ok(!defined $rv || (ref($rv) eq '' && $rv == 0) || !$rv,
       "AutoUse=0: no DB selected, table op fails or returns false");

    $dbh->disconnect;
}

###############################################################################
# connect: DSN string format variations
###############################################################################
{
    # dir= alias for base_dir=
    my $dbh = DB::Handy->connect("dir=$BASE;db=etest");
    # ok 46
    ok(defined $dbh, "connect: dir=...;db=... DSN alias works");

    my $rows = $dbh->selectall_arrayref("SELECT COUNT(*) AS n FROM t1", {Slice=>{}});
    # ok 47
    ok(defined $rows->[0]{n}, "connect DSN alias: can query existing table");
    $dbh->disconnect;
}

###############################################################################
# fetchall_hashref via sth
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    my $sth = $dbh->prepare("SELECT id, v FROM t1 ORDER BY id");
    $sth->execute;
    my $h = $sth->fetchall_hashref('id');

    # ok 48
    ok(ref $h eq 'HASH',    "sth->fetchall_hashref: returns HASH");
    # ok 49
    ok(exists $h->{1},      "sth->fetchall_hashref: key 1 exists");
    # ok 50
    is($h->{1}{v}, 'alpha', "sth->fetchall_hashref: value for key 1");

    $dbh->disconnect;
}

###############################################################################
# rows() on DML
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    $dbh->do("CREATE TABLE rowtest (id INT, val INT)");
    for my $i (1..5) {
        $dbh->do("INSERT INTO rowtest (id,val) VALUES ($i,$i)");
    }

    my $sth = $dbh->prepare("UPDATE rowtest SET val=0 WHERE id <= 3");
    my $rv = $sth->execute;
    # ok 51
    ok(defined $rv,        "UPDATE execute returns defined");
    # ok 52
    is($sth->rows+0, 3,   "rows() after UPDATE: 3 affected");

    $sth = $dbh->prepare("DELETE FROM rowtest WHERE val=0");
    $sth->execute;
    # ok 53
    is($sth->rows+0, 3,   "rows() after DELETE: 3 affected");

    $dbh->disconnect;
}

###############################################################################
# selectall_hashref via dbh
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');
    my $h = $dbh->selectall_hashref("SELECT id, v FROM t1", 'id');

    # ok 54
    ok(ref $h eq 'HASH',    "dbh->selectall_hashref: returns HASH");
    # ok 55
    ok(exists $h->{1},      "dbh->selectall_hashref: key 1 exists");
    # ok 56
    is($h->{1}{v}, 'alpha', "dbh->selectall_hashref: value correct");

    $dbh->disconnect;
}

###############################################################################
# quote() edge cases
###############################################################################
{
    my $dbh = DB::Handy->connect($BASE, 'etest');

    # undef -> NULL
    is($dbh->quote(undef), 'NULL', "quote(undef) = NULL");
    # ok 57

    # string with single quote
    is($dbh->quote("it's"), "'it''s'", "quote escapes single quote");
    # ok 58

    # empty string
    is($dbh->quote(''), "''", "quote('') = ''");
    # ok 59

    # numeric (passed as string)
    is($dbh->quote(42), "'42'", "quote(42) = \"'42'\"");
    # ok 60

    $dbh->disconnect;
}

###############################################################################
# Cleanup
###############################################################################
File::Path::rmtree($BASE) if -d $BASE;
exit($FAIL ? 1 : 0);
