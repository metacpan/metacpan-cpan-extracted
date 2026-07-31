######################################################################
#
# Tests for the SQL-layer fixes in 1.09:
#
#   L1  whitespace inside a string literal is preserved; a value holding
#       a newline, a tab or a CR survives INSERT, SELECT, WHERE, LIKE,
#       UPDATE and DELETE unchanged
#   L2  statement layout outside a literal is still normalised, so a
#       multi-line query parses exactly as a one-line one does
#   L3  an aggregate over a derived table is evaluated instead of
#       producing one empty row per input row
#   L4  GROUP BY, HAVING, ORDER BY, LIMIT and OFFSET on a derived table
#   L5  $dbh->{AutoCommit} reads as 1
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
        : ($FAIL++, print "not ok $T - $n  (got='" . _hex($got)
                        . "', exp='" . _hex($e) . "')\n");
}
# Render a value so that a whitespace difference is visible in the report.
sub _hex {
    my($v) = @_;
    return $v unless $v =~ /[\r\n\t]/;
    return join('', map { my $c = $_;
                          ($c eq "\n") ? '\\n' :
                          ($c eq "\r") ? '\\r' :
                          ($c eq "\t") ? '\\t' : $c } split //, $v);
}

my $BASE = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_sqltext_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $dbh = DB::Handy->connect($BASE, 'sqltext')
    or die "connect failed: $DB::Handy::errstr\n";

my $NL = "line1\nline2";
my $CR = "a\r\nb";
my $TB = "x\ty";

$dbh->do('CREATE TABLE v (id INT, s VARCHAR(60))');
$dbh->do('INSERT INTO v (id,s) VALUES (?,?)', 1, $NL);
$dbh->do('INSERT INTO v (id,s) VALUES (?,?)', 2, $CR);
$dbh->do('INSERT INTO v (id,s) VALUES (?,?)', 3, $TB);
$dbh->do('INSERT INTO v (id,s) VALUES (?,?)', 4, 'plain');

$dbh->do('CREATE TABLE e (id INT, dept VARCHAR(10), sal INT)');
$dbh->do('INSERT INTO e (id,dept,sal) VALUES (?,?,?)', @$_)
    for ([1, 'Eng', 100], [2, 'Eng', 200], [3, 'Ops', 150], [4, 'Ops', 150]);

# First column of the first row, or undef.
sub one {
    my($sql, @bind) = @_;
    my $r = $dbh->selectall_arrayref($sql, {}, @bind);
    return undef unless $r && @$r;
    return $r->[0][0];
}
sub nrows {
    my($sql, @bind) = @_;
    my $r = $dbh->selectall_arrayref($sql, {}, @bind);
    return defined($r) ? scalar(@$r) : -1;
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
# Each closure emits exactly one assertion.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # L1 -- whitespace inside a literal is data, not layout
    # -------------------------------------------------------------------
    sub {
        is(one('SELECT s FROM v WHERE id = 1'), $NL,
           'L1 - a newline inside a value survives INSERT and SELECT');
    },
    sub {
        is(one('SELECT s FROM v WHERE id = 2'), $CR,
           'L1 - a CR LF pair survives unchanged');
    },
    sub {
        is(one('SELECT s FROM v WHERE id = 3'), $TB,
           'L1 - a tab survives unchanged');
    },
    sub {
        is(one('SELECT id FROM v WHERE s = ?', $NL), 1,
           'L1 - WHERE = matches a value holding a newline');
    },
    sub {
        is(one('SELECT id FROM v WHERE s LIKE ?', "line1\nline%"), 1,
           'L1 - LIKE matches across a newline');
    },
    sub {
        $dbh->do('UPDATE v SET s = ? WHERE id = 4', "up\ndated");
        is(one('SELECT s FROM v WHERE id = 4'), "up\ndated",
           'L1 - UPDATE stores a newline unchanged');
    },
    sub {
        $dbh->do("UPDATE v SET s = 'z' WHERE s = ?", $NL);
        is(one('SELECT s FROM v WHERE id = 1'), 'z',
           'L1 - UPDATE ... WHERE matches a value holding a newline');
    },
    sub {
        $dbh->do('INSERT INTO v (id,s) VALUES (?,?)', 5, $NL);
        $dbh->do('DELETE FROM v WHERE s = ?', $NL);
        is(nrows('SELECT id FROM v WHERE id = 5'), 0,
           'L1 - DELETE matches a value holding a newline');
    },
    sub {
        $dbh->do('INSERT INTO v VALUES (?,?)', 6, "v\nw");
        is(one('SELECT s FROM v WHERE id = 6'), "v\nw",
           'L1 - INSERT without a column list keeps the newline');
    },
    sub {
        $dbh->do('CREATE INDEX v_s ON v (s)');
        is(one('SELECT id FROM v WHERE s = ?', "v\nw"), 6,
           'L1 - an index lookup finds a value holding a newline');
    },
    sub {
        is(nrows('SELECT id FROM v WHERE s = ? -- trailing', "v\nw"), 1,
           'L1 - a comment plus a newline value work together');
    },
    sub {
        is(one("SELECT s FROM v WHERE s LIKE '%\nw'"), "v\nw",
           'L1 - a literal newline written directly in the SQL text');
    },

    # -------------------------------------------------------------------
    # L2 -- layout outside a literal is still normalised
    # -------------------------------------------------------------------
    sub {
        is(nrows("SELECT id\n  FROM e\n  WHERE id = 1"), 1,
           'L2 - a multi-line statement parses');
    },
    sub {
        is(nrows("SELECT   id\t\tFROM\te\tWHERE\tid = 1"), 1,
           'L2 - tabs and runs of spaces between keywords are collapsed');
    },
    sub {
        is(nrows("SELECT id FROM e\nWHERE dept = 'Eng'\nORDER BY id"), 2,
           'L2 - a multi-line statement with WHERE and ORDER BY');
    },

    # -------------------------------------------------------------------
    # L3 -- aggregates over a derived table
    # -------------------------------------------------------------------
    sub {
        is(one('SELECT COUNT(*) FROM (SELECT id FROM e) AS sub'), 4,
           'L3 - COUNT(*) over a derived table');
    },
    sub {
        is(one('SELECT COUNT(*) FROM (SELECT id FROM e WHERE sal > 100) AS sub'), 3,
           'L3 - COUNT(*) over a filtered derived table');
    },
    sub {
        is(one('SELECT SUM(sal) FROM (SELECT sal FROM e) AS sub'), 600,
           'L3 - SUM over a derived table');
    },
    sub {
        is(one('SELECT MIN(sal) FROM (SELECT sal FROM e) AS sub'), 100,
           'L3 - MIN over a derived table');
    },
    sub {
        is(one('SELECT MAX(sal) FROM (SELECT sal FROM e) AS sub'), 200,
           'L3 - MAX over a derived table');
    },
    sub {
        is(nrows('SELECT COUNT(*) FROM (SELECT id FROM e) AS sub'), 1,
           'L3 - an aggregate collapses the derived rows to one');
    },
    sub {
        is(one('SELECT COUNT(*) FROM (SELECT id FROM e WHERE sal > 9999) AS sub'), 0,
           'L3 - COUNT(*) over an empty derived table is 0');
    },
    sub {
        # A plain projection must still behave as it did.
        is(nrows('SELECT id FROM (SELECT id FROM e WHERE sal > 100) AS sub'), 3,
           'L3 - a derived table without an aggregate is unchanged');
    },

    # -------------------------------------------------------------------
    # L4 -- GROUP BY / HAVING / ORDER BY / LIMIT on a derived table
    # -------------------------------------------------------------------
    sub {
        is(nrows('SELECT dept, COUNT(*) FROM (SELECT dept FROM e) AS sub GROUP BY dept'), 2,
           'L4 - GROUP BY on a derived table gives one row per group');
    },
    sub {
        my $r = $dbh->selectall_arrayref(
            'SELECT dept FROM (SELECT dept, sal FROM e) AS sub'
            . ' GROUP BY dept HAVING MAX(sal) > 150 ORDER BY dept');
        is(join(',', map { $_->[0] } @$r), 'Eng',
           'L4 - HAVING filters the derived groups');
    },
    sub {
        my $r = $dbh->selectall_arrayref(
            'SELECT dept, COUNT(*) FROM (SELECT dept FROM e) AS sub'
            . ' GROUP BY dept ORDER BY dept DESC');
        is($r->[0][0], 'Ops', 'L4 - ORDER BY DESC applies to the grouped rows');
    },
    sub {
        is(nrows('SELECT dept, COUNT(*) FROM (SELECT dept FROM e) AS sub'
                 . ' GROUP BY dept ORDER BY dept LIMIT 1'), 1,
           'L4 - LIMIT applies after grouping, not before');
    },
    sub {
        # LIMIT must not truncate the input of an ungrouped aggregate.
        is(one('SELECT COUNT(*) FROM (SELECT id FROM e) AS sub LIMIT 1'), 4,
           'L4 - LIMIT does not shrink the input of an aggregate');
    },
    sub {
        is(nrows('SELECT id FROM (SELECT id FROM e) AS sub LIMIT 2'), 2,
           'L4 - LIMIT still applies to a plain derived projection');
    },

    # -------------------------------------------------------------------
    # L5 -- AutoCommit attribute
    # -------------------------------------------------------------------
    sub {
        is($dbh->{AutoCommit}, 1, 'L5 - $dbh->{AutoCommit} reads as 1');
    },
    sub {
        is($dbh->AutoCommit, 1, 'L5 - the AutoCommit method agrees');
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
