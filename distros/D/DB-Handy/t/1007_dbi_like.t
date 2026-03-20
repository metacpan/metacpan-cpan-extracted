######################################################################
#
# Tests DB::Handy::Connection and DB::Handy::Statement:
# connect/disconnect, do, prepare/execute, placeholder substitution,
# bind_param, all fetch methods, quote, table_info/column_info,
# error handling, statement reuse, and aggregate queries.
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
sub isnt    { my($g,$e,$n)=@_; $T++; !defined($g)||("$g" ne "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (both='$g')\n") }

print "1..93\n";
use File::Path ();

###############################################################################
# Setup
###############################################################################
my $BASE = "/tmp/dbd_first_dbi_$$";
File::Path::rmtree($BASE) if -d $BASE;

###############################################################################
# connect / disconnect
###############################################################################
{
    # Basic connection
    my $dbh = DB::Handy->connect($BASE, 'testdb');

    # ok 1
    ok(defined $dbh,           "connect() returns object");

    # ok 2
    ok(ref $dbh eq 'DB::Handy::Connection', "is a Connection object");

    # ok 3
    ok($dbh->ping,             "ping() returns true");

    # disconnect

    # ok 4
    ok($dbh->disconnect,       "disconnect() returns true");

    # ok 5
    ok(!$dbh->ping,            "ping() false after disconnect");

    # DSN string format
    my $dbh2 = DB::Handy->connect("base_dir=$BASE;database=testdb");

    # ok 6
    ok(defined $dbh2,          "connect with DSN string");

    # ok 7
    ok($dbh2->ping,            "ping() on DSN-connected handle");
    $dbh2->disconnect;
}

###############################################################################
# do() / DDL
###############################################################################
my $dbh = DB::Handy->connect($BASE, 'testdb');

# ok 8
ok(defined $dbh, "reconnect for tests");
{
    my $r = $dbh->do("CREATE TABLE emp (id INT, name VARCHAR(40), dept VARCHAR(20), salary INT)");

    # ok 9
    ok(defined $r, "do() CREATE TABLE");

    # Multiple INSERTs
    for my $row (
        [1, 'Alice',   'Eng', 75000],
        [2, 'Bob',     'Mkt', 60000],
        [3, 'Carol',   'Eng', 80000],
        [4, 'Dave',    'Mkt', 55000],
        [5, 'Eve',     'Eng', 90000],
    ) {
        my ($id, $nm, $dp, $sal) = @$row;
        my $n = $dbh->do("INSERT INTO emp (id,name,dept,salary) VALUES ($id,'$nm','$dp',$sal)");

        # ok 10-14
        ok(defined $n, "do() INSERT $nm");
    }
}

###############################################################################
# prepare / execute / fetchrow_hashref
###############################################################################
{
    my $sth = $dbh->prepare("SELECT id, name, salary FROM emp ORDER BY id");

    # ok 15
    ok(defined $sth, "prepare() returns sth");

    # ok 16
    ok(ref $sth eq 'DB::Handy::Statement', "is a Statement object");

    my $rv = $sth->execute;

    # ok 17
    ok(defined $rv,  "execute() returns defined");

    # ok 18
    isnt($rv, '',    "execute() returns non-empty");

    # ok 19
    is($sth->rows,  5, "rows() = 5 after SELECT");

    my $row = $sth->fetchrow_hashref;

    # ok 20
    ok(defined $row, "fetchrow_hashref returns row");

    # ok 21
    is($row->{id},     1,       "first row id=1");

    # ok 22
    is($row->{name},   'Alice', "first row name=Alice");

    # ok 23
    is($row->{salary}, 75000,   "first row salary=75000");

    # Read all remaining rows
    my $count = 1;
    while ($sth->fetchrow_hashref) { $count++ }

    # ok 24
    is($count, 5, "fetched all 5 rows");

    $sth->finish;

    # ok 25
    ok(!defined $sth->fetchrow_hashref, "fetchrow_hashref after finish = undef");
}

###############################################################################
# Placeholder substitution (?)
###############################################################################
{
    # Integer placeholder
    my $sth = $dbh->prepare("SELECT name, salary FROM emp WHERE id = ?");
    $sth->execute(3);
    my $row = $sth->fetchrow_hashref;

    # ok 26
    is($row->{name},   'Carol', "placeholder int: name=Carol");

    # ok 27
    is($row->{salary}, 80000,   "placeholder int: salary=80000");
    $sth->finish;

    # String placeholder
    $sth = $dbh->prepare("SELECT id FROM emp WHERE dept = ? ORDER BY id");
    $sth->execute('Eng');
    my @ids;
    while (my $r = $sth->fetchrow_hashref) { push @ids, $r->{id} }

    # ok 28
    is(scalar @ids, 3, "string placeholder: 3 Eng rows");

    # ok 29
    is($ids[0], 1, "Eng first id=1");
    $sth->finish;

    # Multiple placeholders
    $sth = $dbh->prepare("SELECT name FROM emp WHERE dept = ? AND salary >= ?");
    $sth->execute('Eng', 80000);
    my @names;
    while (my $r = $sth->fetchrow_hashref) { push @names, $r->{name} }

    # ok 30
    is(scalar @names, 2, "multi-placeholder: Carol + Eve");

    # ok 31
    ok(scalar(grep { $_ eq 'Carol' } @names), "Carol in results");

    # ok 32
    ok(scalar(grep { $_ eq 'Eve'   } @names), "Eve in results");
    $sth->finish;

    # NULL-adjacent placeholder
    $dbh->do("CREATE TABLE nullable2 (id INT, val VARCHAR(20))");
    $dbh->do("INSERT INTO nullable2 (id,val) VALUES (1,'hello')");
    $dbh->do("INSERT INTO nullable2 (id,val) VALUES (2,'')");
    $sth = $dbh->prepare("SELECT id FROM nullable2 WHERE id = ?");
    $sth->execute(1);
    my $r = $sth->fetchrow_hashref;

    # ok 33
    is($r->{id}, 1, "NULL-adjacent placeholder: id=1");
    $sth->finish;
}

###############################################################################
# bind_param()
###############################################################################
{
    my $sth = $dbh->prepare("SELECT name FROM emp WHERE id = ?");
    $sth->bind_param(1, 2);
    $sth->execute;
    my $row = $sth->fetchrow_hashref;

    # ok 34
    is($row->{name}, 'Bob', "bind_param(1,2): name=Bob");
    $sth->finish;

    # Re-bind to a different value
    $sth->bind_param(1, 5);
    $sth->execute;
    $row = $sth->fetchrow_hashref;

    # ok 35
    is($row->{name}, 'Eve', "rebind to 5: name=Eve");
    $sth->finish;
}

###############################################################################
# fetchrow_arrayref / fetchrow_array
###############################################################################
{
    my $sth = $dbh->prepare("SELECT id, name FROM emp WHERE id <= 2 ORDER BY id");
    $sth->execute;

    my $aref = $sth->fetchrow_arrayref;

    # ok 36
    ok(ref $aref eq 'ARRAY', "fetchrow_arrayref returns arrayref");

    # ok 37
    is(scalar @$aref, 2, "2 columns");

    my @row = $sth->fetchrow_array;

    # ok 38
    ok(scalar @row == 2, "fetchrow_array returns list");
    $sth->finish;
}

###############################################################################
# fetchall_arrayref
###############################################################################
{
    # Slice={} -> array of hashrefs
    my $sth = $dbh->prepare("SELECT id, name FROM emp ORDER BY id");
    $sth->execute;
    my $all = $sth->fetchall_arrayref({});

    # ok 39
    ok(ref $all eq 'ARRAY',      "fetchall_arrayref({}) returns arrayref");

    # ok 40
    is(scalar @$all, 5,          "5 rows");

    # ok 41
    ok(ref $all->[0] eq 'HASH',  "elements are hashrefs");

    # ok 42
    is($all->[0]{name}, 'Alice', "first name=Alice");

    # ok 43
    is($all->[4]{name}, 'Eve',   "last name=Eve");

    # Slice=[] -> array of arrayrefs
    $sth->execute;
    my $all2 = $sth->fetchall_arrayref([]);

    # ok 44
    ok(ref $all2->[0] eq 'ARRAY', "fetchall_arrayref([]) elements are arrayrefs");

    # ok 45
    is(scalar @{$all2->[0]}, 2,   "2 columns per row");
}

###############################################################################
# fetchall_hashref
###############################################################################
{
    my $sth = $dbh->prepare("SELECT id, name, salary FROM emp");
    $sth->execute;
    my $h = $sth->fetchall_hashref('id');

    # ok 46
    ok(ref $h eq 'HASH',        "fetchall_hashref returns hashref");

    # ok 47
    is($h->{1}{name},   'Alice', "id=1 name=Alice");

    # ok 48
    is($h->{3}{name},   'Carol', "id=3 name=Carol");

    # ok 49
    is($h->{5}{salary}, 90000,   "id=5 salary=90000");
}

###############################################################################
# selectall_arrayref / selectrow_hashref
###############################################################################
{
    # selectall_arrayref with Slice={}
    my $rows = $dbh->selectall_arrayref(
        "SELECT name FROM emp WHERE dept = ? ORDER BY name",
        {Slice=>{}}, 'Eng'
    );

    # ok 50
    ok(ref $rows eq 'ARRAY', "selectall_arrayref returns arrayref");

    # ok 51
    is(scalar @$rows, 3,     "3 Eng employees");

    # ok 52
    is($rows->[0]{name}, 'Alice', "first Eng=Alice");

    # selectrow_hashref
    my $row = $dbh->selectrow_hashref(
        "SELECT name, salary FROM emp WHERE id = ?", {}, 1
    );

    # ok 53
    is($row->{name},   'Alice', "selectrow_hashref name=Alice");

    # ok 54
    is($row->{salary}, 75000,   "selectrow_hashref salary=75000");

    # selectrow_arrayref
    my $aref = $dbh->selectrow_arrayref(
        "SELECT id FROM emp WHERE name = ?", {}, 'Bob'
    );

    # ok 55
    ok(ref $aref eq 'ARRAY', "selectrow_arrayref returns arrayref");

    # selectall_hashref
    my $href = $dbh->selectall_hashref(
        "SELECT id, name, dept FROM emp", 'id'
    );

    # ok 56
    is($href->{2}{name}, 'Bob',  "selectall_hashref id=2 name=Bob");

    # ok 57
    is($href->{4}{dept}, 'Mkt',  "selectall_hashref id=4 dept=Mkt");
}

###############################################################################
# rows() after UPDATE / DELETE
###############################################################################
{
    my $sth = $dbh->prepare("UPDATE emp SET salary = ? WHERE dept = ?");
    my $rv = $sth->execute(65000, 'Mkt');

    # ok 58
    ok(defined $rv,      "UPDATE execute defined");

    # ok 59
    is($sth->rows, 2,    "UPDATE rows=2 (Bob + Dave)");

    # Verify the update
    my $row = $dbh->selectrow_hashref("SELECT salary FROM emp WHERE id = ?", {}, 2);

    # ok 60
    is($row->{salary}, 65000, "Bob salary updated to 65000");

    $sth = $dbh->prepare("DELETE FROM emp WHERE id = ?");
    $rv = $sth->execute(4);

    # ok 61
    is($sth->rows, 1, "DELETE rows=1");

    my $cnt = $dbh->selectrow_hashref("SELECT COUNT(*) AS n FROM emp");

    # ok 62
    is($cnt->{n}, 4, "4 rows remain after DELETE");
}

###############################################################################
# quote()
###############################################################################
{
    # ok 63
    is($dbh->quote("hello"),      "'hello'",    "quote simple string");

    # ok 64
    is($dbh->quote("it's"),       "'it''s'",    "quote with apostrophe");

    # ok 65
    is($dbh->quote(42),           "'42'",       "quote number (returns string)");

    # ok 66
    is($dbh->quote(undef),        'NULL',       "quote undef = NULL");

    # Use quoted value in an actual query
    my $name = "O'Brien";
    my $q    = $dbh->quote($name);
    $dbh->do("INSERT INTO emp (id,name,dept,salary) VALUES (99,$q,'HR',50000)");
    my $row = $dbh->selectrow_hashref("SELECT name FROM emp WHERE id = ?", {}, 99);

    # ok 67
    is($row->{name}, "O'Brien", "quote round-trip with apostrophe");
    $dbh->do("DELETE FROM emp WHERE id = 99");
}

###############################################################################
# table_info / column_info
###############################################################################
{
    my $tables = $dbh->table_info();

    # ok 68
    ok(ref $tables eq 'ARRAY',    "table_info returns arrayref");

    # ok 69
    ok(scalar @$tables >= 1,      "at least 1 table");

    # ok 70
    { my @tn=map{$_->{TABLE_NAME}}@$tables; ok(scalar(grep{$_ eq 'emp'}@tn),"emp in table_info"); }

    my $cols = $dbh->column_info('emp');

    # ok 71
    ok(ref $cols eq 'ARRAY',      "column_info returns arrayref");
    my %cn = map { $_->{COLUMN_NAME} => $_ } @$cols;

    # ok 72
    ok(exists $cn{id},            "emp has id column");

    # ok 73
    ok(exists $cn{name},          "emp has name column");

    # ok 74
    is($cn{id}{DATA_TYPE},   'INT',     "id DATA_TYPE=INT");

    # ok 75
    is($cn{name}{DATA_TYPE}, 'VARCHAR', "name DATA_TYPE=VARCHAR");
}

###############################################################################
# Error handling
###############################################################################
{
    # SELECT from a non-existent table
    my $sth = $dbh->prepare("SELECT * FROM no_such_table");
    my $rv  = $sth->execute;

    # ok 76
    ok(!defined $rv,           "execute on missing table returns undef");

    # ok 77
    ok($sth->err,              "sth->err is set");

    # ok 78
    ok(length($sth->errstr),   "sth->errstr is non-empty");

    # ok 79
    ok($dbh->err,              "dbh->err is propagated");

    # do() on a non-existent table
    my $r = $dbh->do("INSERT INTO no_such_table (x) VALUES (1)");

    # ok 80
    ok(!defined $r,            "do() on missing table returns undef");
}

###############################################################################
# Statement reuse (multiple execute calls)
###############################################################################
{
    my $sth = $dbh->prepare("SELECT name FROM emp WHERE id = ?");
    my %results;
    for my $id (1..3) {
        $sth->execute($id);
        my $row = $sth->fetchrow_hashref;
        $results{$id} = $row->{name} if $row;
        $sth->finish;
    }

    # ok 81
    is($results{1}, 'Alice', "reuse sth id=1 Alice");

    # ok 82
    is($results{2}, 'Bob',   "reuse sth id=2 Bob");

    # ok 83
    is($results{3}, 'Carol', "reuse sth id=3 Carol");
}

###############################################################################
# Aggregate queries
###############################################################################
{
    my $row = $dbh->selectrow_hashref(
        "SELECT COUNT(*) AS cnt, SUM(salary) AS total, MAX(salary) AS top FROM emp"
    );

    # ok 84
    is($row->{cnt},   4,      "COUNT=4");

    # ok 85
    is($row->{total}, 310000, "SUM salary correct");

    # ok 86
    is($row->{top},   90000,  "MAX salary=90000");

    my $rows = $dbh->selectall_arrayref(
        "SELECT dept, COUNT(*) AS cnt FROM emp GROUP BY dept ORDER BY dept",
        {Slice=>{}}
    );

    # ok 87
    is(scalar @$rows, 2, "2 depts");
    my %d = map { $_->{dept} => $_->{cnt} } @$rows;

    # ok 88
    is($d{Eng}, 3, "Eng cnt=3");

    # ok 89
    is($d{Mkt}, 1, "Mkt cnt=1");
}

###############################################################################
# NAME / NUM_OF_FIELDS attributes
###############################################################################
{
    my $sth = $dbh->prepare("SELECT id, name, salary FROM emp WHERE id = 1");
    $sth->execute;

    # ok 90
    is($sth->{NUM_OF_FIELDS}, 3, "NUM_OF_FIELDS=3");

    # ok 91
    ok(ref $sth->{NAME} eq 'ARRAY', "NAME is arrayref");

    # ok 92
    is(scalar @{$sth->{NAME}}, 3,  "NAME has 3 elements");

    # ok 93
    ok(scalar(grep { $_ eq 'name' } @{$sth->{NAME}}), "'name' in NAME");
    $sth->finish;
}

###############################################################################
# Cleanup
###############################################################################
$dbh->disconnect;
File::Path::rmtree($BASE) if -d $BASE;

exit($FAIL ? 1 : 0);
