######################################################################
#
# Tests for the integrity and parser fixes in 1.09:
#
#   K1  PRIMARY KEY is enforced through an auto-created UNIQUE index
#   K2  UNIQUE, as a column modifier and as a table constraint, is
#       enforced through an auto-created UNIQUE index
#   K3  a UNIQUE column still accepts any number of NULLs
#   J1  a JOIN whose tables carry no alias keeps its join type and its
#       ON condition (the alias slot no longer swallows a keyword)
#   B1  execute() rejects a bind list that does not match the number of
#       placeholders
#   E1  err/errstr are cleared when a later statement succeeds
#   O1  ORDER BY <position> sorts by that select-list column, and an
#       out-of-range position is reported instead of ignored
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
use File::Path ();
use File::Spec ();
use DB::Handy;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my($PASS, $FAIL, $T) = (0, 0, 0);
sub ok {
    my($c, $n) = @_;
    $T++;
    $c ? ($PASS++, print "ok $T - $n\n")
       : ($FAIL++, print "not ok $T - $n\n");
}
sub is {
    my($g, $e, $n) = @_;
    my $got = defined($g) ? $g : 'undef';
    $T++;
    ("$got" eq "$e")
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got='$got', exp='$e')\n");
}

my $BASE = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_integrity_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }
File::Path::mkpath($BASE);

my $dbh = DB::Handy->connect($BASE, 'integrity')
    or die "connect failed: $DB::Handy::errstr\n";

###############################################################################
# Fixtures
###############################################################################
$dbh->do('CREATE TABLE pk1 (id INT PRIMARY KEY, name VARCHAR(20))');
$dbh->do('CREATE TABLE uq1 (id INT PRIMARY KEY, code VARCHAR(20) UNIQUE)');
$dbh->do('CREATE TABLE uq2 (id INT, code VARCHAR(20), UNIQUE (code))');
$dbh->do('CREATE TABLE nul (id INT PRIMARY KEY, code VARCHAR(20) UNIQUE)');

$dbh->do('CREATE TABLE emp (id INT PRIMARY KEY, name VARCHAR(10), dept INT, sal INT)');
$dbh->do('CREATE TABLE dpt (did INT PRIMARY KEY, dname VARCHAR(10))');
$dbh->do('INSERT INTO emp (id,name,dept,sal) VALUES (?,?,?,?)', @$_)
    for ([1, 'ann', 1, 300], [2, 'bob', 2, 100], [3, 'cy', 1, 200], [4, 'dee', 9, 50]);
$dbh->do('INSERT INTO dpt (did,dname) VALUES (?,?)', @$_)
    for ([1, 'sales'], [2, 'tech']);

# Flatten a result set into a comparable string.
sub flat {
    my($sql, @bind) = @_;
    my $r = $dbh->selectall_arrayref($sql, {}, @bind);
    return 'ERROR' unless defined $r;
    return join '|', map {
        join ',', map { defined($_) ? $_ : 'NULL' } @$_
    } @$r;
}

# Index names recorded for a table, sorted.
sub idxnames {
    my($tbl) = @_;
    my $ix = $dbh->{_engine}->list_indexes($tbl);
    return '' unless ref($ix) eq 'ARRAY';
    return join ',', sort map { $_->{name} } @$ix;
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
# Each closure emits exactly one assertion.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # K1 -- PRIMARY KEY uniqueness
    # -------------------------------------------------------------------
    sub {
        ok($dbh->do("INSERT INTO pk1 (id,name) VALUES (1,'Alice')"),
           'K1 first row with a fresh PRIMARY KEY is accepted');
    },
    sub {
        my $r = $dbh->do("INSERT INTO pk1 (id,name) VALUES (1,'Dup')");
        ok(!defined($r), 'K1 duplicate PRIMARY KEY is rejected');
    },
    sub {
        ok($dbh->errstr =~ /UNIQUE/, 'K1 rejection names the UNIQUE constraint');
    },
    sub {
        is(idxnames('pk1'), 'id_pk', 'K1 PRIMARY KEY creates the index id_pk');
    },
    sub {
        my $ix = $dbh->{_engine}->list_indexes('pk1');
        ok($ix->[0]{unique} && ($ix->[0]{col} eq 'id'),
           'K1 the auto-created index is UNIQUE and covers the PK column');
    },
    sub {
        ok($dbh->do("INSERT INTO pk1 (id,name) VALUES (2,'Bob')"),
           'K1 a different PRIMARY KEY value is still accepted');
    },
    sub {
        my $r = $dbh->do('UPDATE pk1 SET id = 1 WHERE id = 2');
        ok(!defined($r), 'K1 UPDATE onto an existing PRIMARY KEY is rejected');
    },
    sub {
        is(flat('SELECT id FROM pk1 ORDER BY id'), '1|2',
           'K1 the rejected INSERT and UPDATE left the table unchanged');
    },
    sub {
        my $r = $dbh->do("INSERT INTO pk1 (name) VALUES ('NoKey')");
        ok(!defined($r), 'K1 PRIMARY KEY still implies NOT NULL');
    },

    # -------------------------------------------------------------------
    # K2 -- UNIQUE as column modifier and as table constraint
    # -------------------------------------------------------------------
    sub {
        $dbh->do("INSERT INTO uq1 (id,code) VALUES (1,'AAA')");
        my $r = $dbh->do("INSERT INTO uq1 (id,code) VALUES (2,'AAA')");
        ok(!defined($r), 'K2 column-level UNIQUE rejects a duplicate');
    },
    sub {
        is(idxnames('uq1'), 'code_unique,id_pk',
           'K2 column-level UNIQUE creates the index code_unique');
    },
    sub {
        $dbh->do("INSERT INTO uq2 (id,code) VALUES (1,'BBB')");
        my $r = $dbh->do("INSERT INTO uq2 (id,code) VALUES (2,'BBB')");
        ok(!defined($r), 'K2 table-level UNIQUE (col) rejects a duplicate');
    },
    sub {
        is(idxnames('uq2'), 'code_unique',
           'K2 table-level UNIQUE creates the index code_unique');
    },
    sub {
        $dbh->do('CREATE TABLE both1 (id INT PRIMARY KEY UNIQUE, s VARCHAR(5))');
        is(idxnames('both1'), 'id_pk',
           'K2 PRIMARY KEY plus UNIQUE on one column yields a single index');
    },
    sub {
        ok($dbh->do("INSERT INTO uq1 (id,code) VALUES (3,'CCC')"),
           'K2 a distinct value is still accepted');
    },

    # -------------------------------------------------------------------
    # K3 -- NULL is exempt from UNIQUE, as SQL-92 requires
    # -------------------------------------------------------------------
    sub {
        ok($dbh->do('INSERT INTO nul (id) VALUES (1)'),
           'K3 first row omitting the UNIQUE column is accepted');
    },
    sub {
        ok($dbh->do('INSERT INTO nul (id) VALUES (2)'),
           'K3 a second NULL in a UNIQUE column is also accepted');
    },
    sub {
        is(flat('SELECT id FROM nul ORDER BY id'), '1|2',
           'K3 both NULL rows were stored');
    },

    # -------------------------------------------------------------------
    # J1 -- JOIN without table aliases
    # -------------------------------------------------------------------
    sub {
        is(flat('SELECT emp.name, dpt.dname FROM emp INNER JOIN dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'ann,sales|bob,tech|cy,sales',
           'J1 INNER JOIN on bare table names applies the ON condition');
    },
    sub {
        is(flat('SELECT e.name, d.dname FROM emp e INNER JOIN dpt d'
                . ' ON e.dept = d.did ORDER BY e.name'),
           flat('SELECT emp.name, dpt.dname FROM emp INNER JOIN dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'J1 bare table names and aliases give the same result');
    },
    sub {
        is(flat('SELECT emp.name, dpt.dname FROM emp LEFT JOIN dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'ann,sales|bob,tech|cy,sales|dee,NULL',
           'J1 LEFT JOIN on bare table names stays a LEFT JOIN');
    },
    sub {
        is(flat('SELECT emp.name, dpt.dname FROM emp LEFT OUTER JOIN dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'ann,sales|bob,tech|cy,sales|dee,NULL',
           'J1 LEFT OUTER JOIN on bare table names stays an outer join');
    },
    sub {
        is(flat('SELECT emp.name FROM emp INNER JOIN dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'ann|bob|cy',
           'J1 a bare-name join does not degrade into a cross join');
    },
    sub {
        is(flat('SELECT emp.name, dpt.dname FROM emp AS emp INNER JOIN dpt AS dpt'
                . ' ON emp.dept = dpt.did ORDER BY emp.name'),
           'ann,sales|bob,tech|cy,sales',
           'J1 an explicit AS alias equal to the table name still works');
    },

    # -------------------------------------------------------------------
    # B1 -- placeholder count is checked
    # -------------------------------------------------------------------
    sub {
        my $sth = $dbh->prepare('SELECT name FROM emp WHERE id = ? AND dept = ?');
        my $r   = $sth->execute(1);
        ok(!defined($r), 'B1 too few bind values is an error');
    },
    sub {
        my $sth = $dbh->prepare('SELECT name FROM emp WHERE id = ?');
        $sth->execute(1, 2);
        ok($sth->errstr =~ /bind variable/,
           'B1 the message explains the bind count mismatch');
    },
    sub {
        my $sth = $dbh->prepare('SELECT name FROM emp WHERE id = ?');
        my $r   = $sth->execute(1, 2, 3);
        ok(!defined($r), 'B1 too many bind values is an error');
    },
    sub {
        my $sth = $dbh->prepare('SELECT name FROM emp WHERE id = ?');
        ok($sth->execute(1), 'B1 a matching bind count still executes');
    },
    sub {
        my $sth = $dbh->prepare('SELECT name FROM emp WHERE id = 1');
        ok($sth->execute, 'B1 a statement with no placeholders still executes');
    },
    sub {
        is($dbh->prepare('SELECT name FROM emp WHERE id = ? AND dept = ?')
                ->{NUM_OF_PARAMS},
           2, 'B1 NUM_OF_PARAMS counts the placeholders');
    },

    # -------------------------------------------------------------------
    # E1 -- error state is cleared by a later successful statement
    # -------------------------------------------------------------------
    sub {
        $dbh->do('SELCT nonsense');
        ok($dbh->errstr ne '', 'E1 a failed statement sets errstr');
    },
    sub {
        $dbh->do('SELCT nonsense');
        $dbh->do('SELECT id FROM emp');
        is($dbh->errstr, '', 'E1 a later successful statement clears errstr');
    },
    sub {
        $dbh->do('SELCT nonsense');
        $dbh->do('SELECT id FROM emp');
        is($dbh->err, 0, 'E1 a later successful statement clears err');
    },
    sub {
        $dbh->do('SELCT nonsense');
        my $sth = $dbh->prepare('SELECT id FROM emp');
        $sth->execute;
        is($sth->errstr, '', 'E1 a fresh statement handle starts without an error');
    },

    # -------------------------------------------------------------------
    # O1 -- ORDER BY <position>
    # -------------------------------------------------------------------
    sub {
        is(flat('SELECT name, sal FROM emp ORDER BY 2 DESC'),
           'ann,300|cy,200|bob,100|dee,50',
           'O1 ORDER BY 2 DESC sorts by the second select-list column');
    },
    sub {
        is(flat('SELECT name, sal FROM emp ORDER BY 2'),
           'dee,50|bob,100|cy,200|ann,300',
           'O1 ORDER BY 2 defaults to ascending');
    },
    sub {
        is(flat('SELECT name, sal FROM emp ORDER BY 2 DESC'),
           flat('SELECT name, sal FROM emp ORDER BY sal DESC'),
           'O1 a position and the column name give the same order');
    },
    sub {
        is(flat('SELECT * FROM emp ORDER BY 4 DESC'),
           flat('SELECT * FROM emp ORDER BY sal DESC'),
           'O1 a position resolves against the table order for SELECT *');
    },
    sub {
        is(flat('SELECT dept, SUM(sal) FROM emp GROUP BY dept ORDER BY 1'),
           '1,500|2,100|9,50',
           'O1 a position works with GROUP BY');
    },
    sub {
        is(flat('SELECT e.name, e.sal FROM emp e INNER JOIN dpt d'
                . ' ON e.dept = d.did ORDER BY 2 DESC'),
           'ann,300|cy,200|bob,100',
           'O1 a position works in a JOIN');
    },
    sub {
        is(flat('SELECT x.name, x.sal FROM (SELECT name, sal FROM emp) AS x'
                . ' ORDER BY 2 DESC'),
           'ann,300|cy,200|bob,100|dee,50',
           'O1 a position works on a derived table');
    },
    sub {
        is(flat('SELECT name, dept, sal FROM emp ORDER BY 2, 3 DESC'),
           'ann,1,300|cy,1,200|bob,2,100|dee,9,50',
           'O1 several positions sort in sequence');
    },
    sub {
        is(flat('SELECT name, sal FROM emp ORDER BY 99'), 'ERROR',
           'O1 a position past the select list is an error');
    },
    sub {
        $dbh->selectall_arrayref('SELECT name, sal FROM emp ORDER BY 99');
        ok($dbh->errstr =~ /ORDER BY position/,
           'O1 the message names the offending position');
    },
    sub {
        is(flat('SELECT name, sal FROM emp ORDER BY 0'), 'ERROR',
           'O1 position 0 is an error, positions are 1-based');
    },
    sub {
        is(flat('SELECT name FROM emp ORDER BY 1+1'),
           flat('SELECT name FROM emp'),
           'O1 an arithmetic expression is not treated as a position');
    },
);

###############################################################################
# Run.  A die inside a closure is reported as that closure's one assertion,
# so a single crashing case cannot truncate the report.
###############################################################################
print '1..', scalar(@tests), "\n";
for my $t (@tests) {
    eval { $t->() };
    next unless $@;
    my $e = $@;
    $e =~ s/\s+$//;
    $e =~ s/\n/ /g;
    $T++;
    $FAIL++;
    print "not ok $T - died: $e\n";
}

$dbh->disconnect;

exit($FAIL ? 1 : 0);
