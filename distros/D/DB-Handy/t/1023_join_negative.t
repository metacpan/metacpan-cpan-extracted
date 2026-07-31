######################################################################
#
# Tests for the JOIN and set-operation corrections made in 1.09:
#
#   J1  ON with the operands the other way round is the same join
#   J2  ON that is not a single two-column equality is an error
#   J3  USING, NATURAL and FULL OUTER JOIN are errors
#   J4  a JOIN with no ON is an error; CROSS JOIN still needs none
#   J5  an ON naming an unknown alias, or an unqualified name, is an error
#   J6  a JOIN WHERE that cannot be executed is an error, not a no-op
#   J7  IS [NOT] NULL and BETWEEN work in a JOIN WHERE
#   J8  SELECT DISTINCT over a JOIN deduplicates
#   J9  a JOIN select item that is not a column is an error
#   J10 a multi-key ORDER BY is honoured, in both branches
#   J11 an aggregate JOIN keeps the select-list column order
#   J12 set-operation branches are matched by position, not by name
#   J13 the errors reach the DBI layer (errstr, err, RaiseError)
#
# Every construct below returned a wrong answer in silence up to 1.08:
# an unreadable ON, USING, NATURAL, FULL OUTER JOIN and a reversed
# operand order all produced a Cartesian product; an unsupported WHERE
# condition was dropped so the rows came back unfiltered; DISTINCT
# produced empty rows; and a multi-key ORDER BY did nothing.  Each test
# therefore pins one of two outcomes -- the right answer, or an error --
# and never "returns something".
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

my $ROOT = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_joinneg_$$");
File::Path::rmtree($ROOT) if -d $ROOT;
END { File::Path::rmtree($ROOT) if defined($ROOT) && -d $ROOT }
File::Path::mkpath($ROOT);

my $dbh = DB::Handy->connect($ROOT, 'jn', { RaiseError => 0, PrintError => 0 })
    or die "connect failed: $DB::Handy::Connection::errstr\n";

$dbh->do("CREATE TABLE a (x INT, y VARCHAR(10))") or die "create a\n";
$dbh->do("CREATE TABLE b (k INT, q VARCHAR(10))") or die "create b\n";

# a has three rows; b matches a.x = 1 twice and a.x = 2 once, so an
# honest inner join is three rows and a Cartesian product is nine.  x = 3
# has no match, which is what the LEFT JOIN tests hang on.
for my $r ([1,'p'], [2,'p'], [3,'z']) {
    $dbh->do("INSERT INTO a (x,y) VALUES (?,?)", $r->[0], $r->[1])
        or die "insert a\n";
}
for my $r ([1,'b1'], [1,'b1b'], [2,'b2']) {
    $dbh->do("INSERT INTO b (k,q) VALUES (?,?)", $r->[0], $r->[1])
        or die "insert b\n";
}

# Flatten a result set to one comparable string, so a test states the
# whole answer -- row count, column count, order and values -- at once.
sub flat {
    my($sql) = @_;
    my $rows = $dbh->selectall_arrayref($sql);
    return undef unless $rows;
    return join('|', map {
        join(',', map { defined($_) ? $_ : 'NULL' } @$_)
    } @$rows);
}

# True when the statement failed and said why.
sub errs {
    my($sql) = @_;
    my $rows = $dbh->selectall_arrayref($sql);
    return 0 if $rows;
    my $e = $dbh->errstr;
    return (defined($e) && ($e =~ /\S/)) ? 1 : 0;
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # J1 -- an equality is symmetric; both spellings are one join
    # -------------------------------------------------------------------
    sub {
        is(flat("SELECT a.y,b.q FROM a JOIN b ON a.x = b.k"),
           'p,b1|p,b1b|p,b2',
           'J1 ON left.col = right.col joins on the condition');
    },
    sub {
        is(flat("SELECT a.y,b.q FROM a JOIN b ON b.k = a.x"),
           'p,b1|p,b1b|p,b2',
           'J1 ON right.col = left.col gives the same three rows');
    },
    sub {
        is(flat("SELECT a.x FROM a LEFT JOIN b ON b.k = a.x ORDER BY a.x"),
           '1|1|2|3',
           'J1 reversed operands work for a LEFT JOIN too');
    },

    # -------------------------------------------------------------------
    # J2 -- an ON the engine cannot execute
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = b.k AND a.x > 1"),
           'J2 a second ON condition is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x < b.k"),
           'J2 a non-equality ON is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = 1"),
           'J2 an ON comparing a column with a literal is an error');
    },
    sub {
        my $e = '';
        $dbh->selectall_arrayref("SELECT a.y FROM a JOIN b ON a.x < b.k");
        $e = $dbh->errstr;
        ok((defined($e) && ($e =~ /\QON a.x < b.k\E/)),
           'J2 the message quotes the offending ON text');
    },

    # -------------------------------------------------------------------
    # J3 -- join syntax that is not implemented at all
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT * FROM a JOIN b USING (x)"),
           'J3 JOIN ... USING is an error');
    },
    sub {
        ok(errs("SELECT * FROM a NATURAL JOIN b"),
           'J3 NATURAL JOIN is an error');
    },
    sub {
        ok(errs("SELECT a.y,b.q FROM a FULL OUTER JOIN b ON a.x = b.k"),
           'J3 FULL OUTER JOIN is an error');
    },
    sub {
        ok(errs("SELECT a.y,b.q FROM a FULL JOIN b ON a.x = b.k"),
           'J3 FULL JOIN without OUTER is an error too');
    },

    # -------------------------------------------------------------------
    # J4 -- a missing ON
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT a.y,b.q FROM a JOIN b"),
           'J4 an INNER JOIN with no ON is an error');
    },
    sub {
        ok(errs("SELECT a.y,b.q FROM a LEFT JOIN b"),
           'J4 a LEFT JOIN with no ON is an error');
    },
    sub {
        my $got = flat("SELECT a.x,b.k FROM a CROSS JOIN b ORDER BY a.x, b.k");
        is($got,
           '1,1|1,1|1,2|2,1|2,1|2,2|3,1|3,1|3,2',
           'J4 CROSS JOIN still needs no ON and gives 3 x 3 rows');
    },

    # -------------------------------------------------------------------
    # J5 -- an ON that does not name the tables being joined
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = zz.k"),
           'J5 an unknown alias in ON is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON x = k"),
           'J5 an unqualified column in ON is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = a.x"),
           'J5 an ON that never mentions the joined table is an error');
    },

    # -------------------------------------------------------------------
    # J6 -- a WHERE the JOIN path cannot execute.  Each of these used to
    #       be dropped, which returned the unfiltered join.
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = b.k WHERE a.x=1 OR a.x=2"),
           'J6 OR in a JOIN WHERE is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = b.k WHERE NOT a.x = 1"),
           'J6 NOT in a JOIN WHERE is an error');
    },
    sub {
        ok(errs("SELECT a.y FROM a JOIN b ON a.x = b.k WHERE (a.x = 1)"),
           'J6 parentheses in a JOIN WHERE are an error');
    },
    sub {
        is(flat("SELECT a.y,b.q FROM a JOIN b ON a.x = b.k WHERE a.x = 2"),
           'p,b2',
           'J6 a supported JOIN WHERE still filters');
    },
    sub {
        is(flat("SELECT a.x FROM a JOIN b ON a.x = b.k"
                . " WHERE a.x > 0 AND b.q LIKE 'b1%' ORDER BY a.x"),
           '1|1',
           'J6 AND-separated conditions are all applied');
    },

    # -------------------------------------------------------------------
    # J7 -- IS [NOT] NULL and BETWEEN, new in 1.09
    # -------------------------------------------------------------------
    sub {
        is(flat("SELECT a.x FROM a LEFT JOIN b ON a.x = b.k"
                . " WHERE b.q IS NULL"),
           '3',
           'J7 IS NULL after a LEFT JOIN finds the unmatched row only');
    },
    sub {
        is(flat("SELECT a.x FROM a LEFT JOIN b ON a.x = b.k"
                . " WHERE b.q IS NOT NULL ORDER BY a.x"),
           '1|1|2',
           'J7 IS NOT NULL after a LEFT JOIN excludes it');
    },
    sub {
        is(flat("SELECT a.x FROM a JOIN b ON a.x = b.k"
                . " WHERE a.x BETWEEN 2 AND 3"),
           '2',
           'J7 BETWEEN is applied, and its AND is not read as a conjunction');
    },
    sub {
        is(flat("SELECT a.x FROM a JOIN b ON a.x = b.k"
                . " WHERE a.x BETWEEN 1 AND 2 AND b.q = 'b2'"),
           '2',
           'J7 BETWEEN combines with a further AND condition');
    },

    # -------------------------------------------------------------------
    # J8 -- DISTINCT
    # -------------------------------------------------------------------
    sub {
        is(flat("SELECT DISTINCT a.x FROM a JOIN b ON a.x = b.k"
                . " ORDER BY a.x"),
           '1|2',
           'J8 SELECT DISTINCT over a JOIN deduplicates');
    },
    sub {
        is(flat("SELECT DISTINCT a.y FROM a JOIN b ON a.x = b.k"),
           'p',
           'J8 DISTINCT collapses three rows to one distinct value');
    },
    sub {
        is(flat("SELECT DISTINCT a.x,a.y FROM a JOIN b ON a.x = b.k"
                . " ORDER BY a.x"),
           '1,p|2,p',
           'J8 DISTINCT over two columns keeps both, deduplicated');
    },
    sub {
        # DISTINCT has to run before LIMIT, or the limit counts duplicates.
        is(flat("SELECT DISTINCT a.x FROM a JOIN b ON a.x = b.k"
                . " ORDER BY a.x LIMIT 2"),
           '1|2',
           'J8 LIMIT applies after DISTINCT, not before');
    },

    # -------------------------------------------------------------------
    # J9 -- select items a JOIN cannot project
    # -------------------------------------------------------------------
    sub {
        ok(errs("SELECT a.y AS nm FROM a JOIN b ON a.x = b.k"),
           'J9 an AS alias in a non-aggregate JOIN is an error');
    },
    sub {
        ok(errs("SELECT a.x+1 FROM a JOIN b ON a.x = b.k"),
           'J9 an expression in a non-aggregate JOIN is an error');
    },
    sub {
        ok(errs("SELECT a.nosuch FROM a JOIN b ON a.x = b.k"),
           'J9 an unknown column in a JOIN is an error');
    },
    sub {
        is(flat("SELECT a.* FROM a JOIN b ON a.x = b.k ORDER BY a.x"),
           '1,p|1,p|2,p',
           'J9 table.* is still accepted');
    },
    sub {
        is(flat("SELECT * FROM a JOIN b ON a.x = b.k ORDER BY b.q"),
           '1,p,1,b1|1,p,1,b1b|2,p,2,b2',
           'J9 SELECT * is still accepted, in declaration order');
    },

    # -------------------------------------------------------------------
    # J10 -- multi-key ORDER BY
    # -------------------------------------------------------------------
    sub {
        # Ties on a.y are broken by a.x descending, so a dropped second
        # key shows up as 1 before 2.
        is(flat("SELECT a.y,a.x FROM a JOIN b ON a.x = b.k"
                . " ORDER BY a.y ASC, a.x DESC"),
           'p,2|p,1|p,1',
           'J10 the second ORDER BY key breaks the tie');
    },
    sub {
        is(flat("SELECT a.y,a.x FROM a JOIN b ON a.x = b.k"
                . " ORDER BY a.y ASC, a.x ASC"),
           'p,1|p,1|p,2',
           'J10 reversing the second key reverses the tie-break');
    },
    sub {
        is(flat("SELECT a.x FROM a JOIN b ON a.x = b.k ORDER BY a.x DESC"),
           '2|1|1',
           'J10 a single ORDER BY key still works');
    },
    sub {
        is(flat("SELECT a.y,a.x FROM a JOIN b ON a.x = b.k ORDER BY 2 DESC"),
           'p,2|p,1|p,1',
           'J10 ORDER BY by position still works');
    },
    sub {
        ok(errs("SELECT a.x FROM a JOIN b ON a.x = b.k ORDER BY nosuch"),
           'J10 an unknown ORDER BY column is an error');
    },

    # -------------------------------------------------------------------
    # J11 -- aggregate over a JOIN
    # -------------------------------------------------------------------
    sub {
        # The select list is (a.y, COUNT(*)); an alphabetical fallback
        # would put COUNT(*) first and give '3,p'.
        is(flat("SELECT a.y,COUNT(*) FROM a JOIN b ON a.x = b.k"
                . " GROUP BY a.y"),
           'p,3',
           'J11 an aggregate JOIN keeps the select-list column order');
    },
    sub {
        my $sth = $dbh->prepare("SELECT a.y,COUNT(*) FROM a JOIN b"
                                . " ON a.x = b.k GROUP BY a.y");
        $sth->execute;
        is(join(',', @{$sth->{NAME}}), 'y,COUNT(*)',
           'J11 sth NAME follows the select list, not the alphabet');
    },
    sub {
        is(flat("SELECT a.y AS nm,COUNT(*) AS n FROM a JOIN b"
                . " ON a.x = b.k GROUP BY a.y"),
           'p,3',
           'J11 AS aliases are accepted in an aggregate JOIN');
    },
    sub {
        is(flat("SELECT a.x,COUNT(*) FROM a JOIN b ON a.x = b.k"
                . " GROUP BY a.x ORDER BY a.x DESC"),
           '2,1|1,2',
           'J11 ORDER BY a qualified column sorts an aggregate JOIN');
    },
    sub {
        ok(errs("SELECT a.x,COUNT(*) FROM a JOIN b ON a.x = b.k"
                . " GROUP BY a.x ORDER BY b.q"),
           'J11 ORDER BY outside the aggregate select list is an error');
    },

    # -------------------------------------------------------------------
    # J12 -- set operations line up by position
    # -------------------------------------------------------------------
    sub {
        # a.x is (1,2,3) and b.k is (1,1,2).  Matching by name would find
        # no 'x' key in the second branch and yield NULL rows.
        is(flat("SELECT x FROM a UNION ALL SELECT k FROM b"),
           '1|2|3|1|1|2',
           'J12 UNION ALL keeps the second branch values');
    },
    sub {
        is(flat("SELECT y FROM a UNION SELECT q FROM b"),
           'p|z|b1|b1b|b2',
           'J12 UNION deduplicates across differently named columns');
    },
    sub {
        is(flat("SELECT x,y FROM a UNION ALL SELECT k,q FROM b"),
           '1,p|2,p|3,z|1,b1|1,b1b|2,b2',
           'J12 a two-column set operation maps both columns by position');
    },
    sub {
        is(flat("SELECT x FROM a INTERSECT SELECT k FROM b"),
           '1|2',
           'J12 INTERSECT compares by position');
    },
    sub {
        is(flat("SELECT x FROM a EXCEPT SELECT k FROM b"),
           '3',
           'J12 EXCEPT compares by position');
    },
    sub {
        ok(errs("SELECT x,y FROM a UNION SELECT k FROM b"),
           'J12 a differing number of columns is an error');
    },

    # -------------------------------------------------------------------
    # J13 -- the errors are visible through the DBI-style interface
    # -------------------------------------------------------------------
    sub {
        my $r = $dbh->selectall_arrayref("SELECT * FROM a NATURAL JOIN b");
        ok(!defined($r), 'J13 a rejected JOIN returns undef, not rows');
    },
    sub {
        $dbh->selectall_arrayref("SELECT * FROM a NATURAL JOIN b");
        is($dbh->err, 1, 'J13 err is set after a rejected JOIN');
    },
    sub {
        $dbh->selectall_arrayref("SELECT * FROM a NATURAL JOIN b");
        my $e = $dbh->errstr;
        ok((defined($e) && ($e =~ /NATURAL JOIN/)),
           'J13 errstr explains which construct was rejected');
    },
    sub {
        my $ok = $dbh->do("SELECT a.y FROM a JOIN b ON a.x = b.k");
        $dbh->selectall_arrayref("SELECT a.x FROM a JOIN b ON a.x = b.k");
        is($dbh->err, 0, 'J13 err is cleared again by a successful statement');
    },
    sub {
        my $strict = DB::Handy->connect($ROOT, 'jn',
                                        { RaiseError => 1, PrintError => 0 });
        my $lived = eval {
            $strict->selectall_arrayref("SELECT * FROM a NATURAL JOIN b");
            1;
        };
        ok(!$lived, 'J13 RaiseError turns a rejected JOIN into a die');
    },

    # -------------------------------------------------------------------
    # J13 -- AutoCommit => 0 is refused rather than quietly ignored
    # -------------------------------------------------------------------
    sub {
        my $d = DB::Handy->connect($ROOT, 'jn',
                                   { AutoCommit => 0, RaiseError => 0,
                                     PrintError => 0 });
        ok(!defined($d), 'J13 connect with AutoCommit => 0 is refused');
    },
    sub {
        DB::Handy->connect($ROOT, 'jn',
                           { AutoCommit => 0, RaiseError => 0,
                             PrintError => 0 });
        ok(($DB::Handy::Connection::errstr =~ /AutoCommit cannot be turned off/),
           'J13 the refusal says why');
    },
    sub {
        my $d = DB::Handy->connect($ROOT, 'jn',
                                   { AutoCommit => 1, RaiseError => 0,
                                     PrintError => 0 });
        ok(defined($d), 'J13 connect with AutoCommit => 1 is accepted');
    },
);

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

exit($FAIL ? 1 : 0);
