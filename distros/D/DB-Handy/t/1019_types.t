######################################################################
#
# Tests for the type validation added in 1.09:
#
#   T1  INT rejects a numeric value outside -2147483648 .. 2147483647
#       instead of clamping it silently
#   T2  INT keeps its historical behaviour for values that are merely
#       imprecise: a fractional value is truncated, a non-numeric value
#       is stored as 0, and neither is an error
#   T3  DATE rejects anything that is not a well-formed calendar date
#   T4  DATE accepts NULL and the empty string
#   T5  the same checks apply on UPDATE, and a rejected UPDATE leaves
#       the stored value alone
#   T6  a table's .dat file is created in binary mode
#   T7  FLOAT follows the same non-numeric rule as INT and does so
#       without leaking an "isn't numeric" warning out of the module,
#       on the record path and on the index key path alike
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

my $BASE = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_types_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $dbh = DB::Handy->connect($BASE, 'types')
    or die "connect failed: $DB::Handy::errstr\n";

$dbh->do('CREATE TABLE t (id INT, n INT, d DATE, s VARCHAR(20))');

# A second table for the FLOAT tests.  'g' is indexed and 'f' is not, so
# that both the record packer and the index key encoder are exercised.
$dbh->do('CREATE TABLE f (id INT, f FLOAT, g FLOAT, n INT)');
$dbh->do('CREATE INDEX ix_g ON f (g)');

# Single scalar value of column $col in the row where id = $id.
sub val {
    my($col, $id) = @_;
    my $r = $dbh->selectall_arrayref("SELECT $col FROM t WHERE id = $id");
    return 'no-row' unless $r && @$r;
    my $v = $r->[0][0];
    return defined($v) ? $v : 'undef';
}

# Same, for table f.
sub fval {
    my($col, $id) = @_;
    my $r = $dbh->selectall_arrayref("SELECT $col FROM f WHERE id = $id");
    return 'no-row' unless $r && @$r;
    my $v = $r->[0][0];
    return defined($v) ? $v : 'undef';
}

# Run $code with a warning trap installed and return the warnings it
# produced, joined into one string ('' when it produced none).  DB::Handy
# sets $^W itself, so a warning leaking out of the module reaches the
# caller whatever the caller's own warning settings are; these tests
# check that no warning leaks at all.
sub warnings_from {
    my($code) = @_;
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $code->();
    my $s = join ' | ', @w;
    $s =~ s/\s+$//;
    return $s;
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
# Each closure emits exactly one assertion.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # T1 -- INT range
    # -------------------------------------------------------------------
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (1,2147483647)');
        is($rc, 1, 'T1 - the largest INT is accepted');
    },
    sub {
        is(val('n', 1), '2147483647', 'T1 - the largest INT round-trips');
    },
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (2,-2147483648)');
        is($rc, 1, 'T1 - the smallest INT is accepted');
    },
    sub {
        is(val('n', 2), '-2147483648', 'T1 - the smallest INT round-trips');
    },
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (3,2147483648)');
        ok(!defined $rc, 'T1 - one past the top is rejected');
    },
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (3,-2147483649)');
        ok(!defined $rc, 'T1 - one past the bottom is rejected');
    },
    sub {
        $dbh->do('INSERT INTO t (id,n) VALUES (3,3000000000)');
        my $msg = $dbh->errstr;
        ok((defined($msg) && ($msg =~ /out of range/i)),
           'T1 - the error message says the value is out of range');
    },
    sub {
        my $r = $dbh->selectall_arrayref('SELECT id FROM t WHERE id = 3');
        is(scalar(@$r), 0, 'T1 - a rejected INSERT stores nothing');
    },

    # -------------------------------------------------------------------
    # T2 -- values that are imprecise rather than out of range
    # -------------------------------------------------------------------
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (4,1.7)');
        is($rc, 1, 'T2 - a fractional value is not an error');
    },
    sub {
        is(val('n', 4), '1', 'T2 - a fractional value is truncated towards zero');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,n) VALUES (5,'abc')");
        is($rc, 1, 'T2 - a non-numeric value is not an error');
    },
    sub {
        is(val('n', 5), '0', 'T2 - a non-numeric value is stored as 0');
    },
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,n) VALUES (6,NULL)');
        is($rc, 1, 'T2 - NULL is accepted for an INT column');
    },

    # -------------------------------------------------------------------
    # T3 -- DATE validity
    # -------------------------------------------------------------------
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (10,'2020-01-02')");
        is($rc, 1, 'T3 - a plain valid date is accepted');
    },
    sub {
        is(val('d', 10), '2020-01-02', 'T3 - the date round-trips unchanged');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (11,'2020-02-29')");
        is($rc, 1, 'T3 - 29 February in a leap year is accepted');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (12,'2021-02-29')");
        ok(!defined $rc, 'T3 - 29 February in a common year is rejected');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (12,'2000-02-29')");
        is($rc, 1, 'T3 - 2000 is a leap year (divisible by 400)');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'1900-02-29')");
        ok(!defined $rc, 'T3 - 1900 is not a leap year (divisible by 100)');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'2020-13-01')");
        ok(!defined $rc, 'T3 - month 13 is rejected');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'2020-00-10')");
        ok(!defined $rc, 'T3 - month 00 is rejected');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'2020-04-31')");
        ok(!defined $rc, 'T3 - 31 April is rejected');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'2020-1-2')");
        ok(!defined $rc, 'T3 - an unpadded date is rejected');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (13,'not-a-date')");
        ok(!defined $rc, 'T3 - a non-date string is rejected');
    },
    sub {
        $dbh->do("INSERT INTO t (id,d) VALUES (13,'2020-13-99')");
        my $msg = $dbh->errstr;
        ok((defined($msg) && ($msg =~ /DATE/i)),
           'T3 - the error message names the DATE column');
    },

    # -------------------------------------------------------------------
    # T4 -- NULL and the empty string
    # -------------------------------------------------------------------
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,d) VALUES (20,NULL)');
        is($rc, 1, 'T4 - NULL is accepted for a DATE column');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO t (id,d) VALUES (21,'')");
        is($rc, 1, 'T4 - the empty string is accepted for a DATE column');
    },
    sub {
        my $rc = $dbh->do('INSERT INTO t (id,s) VALUES (22,?)', 'plain');
        is($rc, 1, 'T4 - a row that omits the DATE column is accepted');
    },

    # -------------------------------------------------------------------
    # T5 -- UPDATE is checked too, and a rejected UPDATE changes nothing
    # -------------------------------------------------------------------
    sub {
        my $rc = $dbh->do('UPDATE t SET n = 3000000000 WHERE id = 1');
        ok(!defined $rc, 'T5 - UPDATE rejects an out-of-range INT');
    },
    sub {
        is(val('n', 1), '2147483647', 'T5 - the rejected UPDATE left the INT alone');
    },
    sub {
        my $rc = $dbh->do("UPDATE t SET d = '2020-02-30' WHERE id = 10");
        ok(!defined $rc, 'T5 - UPDATE rejects an invalid DATE');
    },
    sub {
        is(val('d', 10), '2020-01-02', 'T5 - the rejected UPDATE left the DATE alone');
    },
    sub {
        my $rc = $dbh->do("UPDATE t SET d = '2024-02-29' WHERE id = 10");
        is($rc, 1, 'T5 - UPDATE accepts a valid DATE');
    },
    sub {
        is(val('d', 10), '2024-02-29', 'T5 - the accepted UPDATE was stored');
    },
    sub {
        # A column left out of the SET list must not be re-validated.
        my $rc = $dbh->do("UPDATE t SET s = 'touched' WHERE id = 10");
        is($rc, 1, 'T5 - updating another column does not re-check the DATE');
    },

    # -------------------------------------------------------------------
    # T6 -- the .dat file is created in binary mode
    # -------------------------------------------------------------------
    sub {
        # Without binmode on the .dat handle, a platform that translates
        # line endings would lengthen a record holding CR or LF and the
        # fixed-length reader would fall out of step.  The low-level API
        # is used because the SQL layer collapses whitespace inside a
        # string literal before the value ever reaches the file.
        my $e = DB::Handy->new(base_dir => $BASE);
        $e->use_database('types');
        $e->execute('CREATE TABLE b (id INT, s VARCHAR(20))');
        my $raw = "a\r\nb\nc\rd";
        $e->insert('b', { id => 1, s => $raw });
        my $res = $e->execute('SELECT s FROM b WHERE id = 1');
        is($res->{data}[0]{s}, $raw, 'T6 - CR/LF bytes survive a round trip');
    },
    sub {
        my $e = DB::Handy->new(base_dir => $BASE);
        $e->use_database('types');
        $e->insert('b', { id => 2, s => "x\x00y" });
        my $res = $e->execute('SELECT s FROM b WHERE id = 2');
        is($res->{data}[0]{s}, "x\x00y", 'T6 - an interior NUL byte survives');
    },

    # -------------------------------------------------------------------
    # T7 -- FLOAT follows the same non-numeric rule as INT, quietly.
    #
    # Up to 1.08 the FLOAT branches of _pack_record and _encode_key handed
    # the raw value to pack(), so any value that was not a number leaked
    # an "isn't numeric" warning out of DB::Handy -- twice per row when
    # the column was indexed.  INT had a numeric test and FLOAT did not,
    # which also made the two types disagree about what '12abc' means.
    # -------------------------------------------------------------------
    sub {
        my $w = warnings_from(sub {
            $dbh->do("INSERT INTO f (id,f,n) VALUES (1,'abc',0)");
        });
        is($w, '', 'T7 - a non-numeric FLOAT insert emits no warning');
    },
    sub {
        is(fval('f', 1), '0', 'T7 - a non-numeric FLOAT value is stored as 0');
    },
    sub {
        my $w = warnings_from(sub {
            $dbh->do("INSERT INTO f (id,g,n) VALUES (2,'abc',0)");
        });
        is($w, '', 'T7 - an indexed non-numeric FLOAT insert emits no warning');
    },
    sub {
        is(fval('g', 2), '0', 'T7 - an indexed non-numeric FLOAT is stored as 0');
    },
    sub {
        my $w = warnings_from(sub {
            $dbh->do("UPDATE f SET f = 'xyz', g = 'xyz' WHERE id = 1");
        });
        is($w, '', 'T7 - a non-numeric FLOAT update emits no warning');
    },
    sub {
        # The value that made INT and FLOAT disagree: INT read it as 0
        # because it failed the numeric test, FLOAT read it as 12 because
        # Perl stops at the first non-digit.  Both are 0 now.
        $dbh->do("INSERT INTO f (id,f,n) VALUES (3,'12abc','12abc')");
        is(fval('f', 3) . '/' . fval('n', 3), '0/0',
           'T7 - INT and FLOAT agree that 12abc is not a number');
    },
    sub {
        my $w = warnings_from(sub {
            $dbh->do("INSERT INTO f (id,f,g,n) VALUES (4,'0x10','Inf',0)");
        });
        is($w, '', 'T7 - 0x10 and Inf emit no warning');
    },
    sub {
        is(fval('f', 4) . '/' . fval('g', 4), '0/0',
           'T7 - 0x10 and Inf are stored as 0');
    },
    sub {
        my $rc = $dbh->do("INSERT INTO f (id,f,n) VALUES (5,'abc',0)");
        is($rc, 1, 'T7 - a non-numeric FLOAT value is not an error');
    },
    sub {
        # Values that really are numbers must still round trip: an
        # over-strict test would be as wrong as no test at all.
        $dbh->do("INSERT INTO f (id,f,g,n) VALUES (6,'1e3',' 42 ',0)");
        is(fval('f', 6) . '/' . fval('g', 6), '1000/42',
           'T7 - exponent and padded forms are still read as numbers');
    },
    sub {
        $dbh->do('INSERT INTO f (id,f,g,n) VALUES (7,-2.5,-2.5,0)');
        is(fval('f', 7), '-2.5', 'T7 - a negative fractional value round trips');
    },
    sub {
        # The index on g must still find the rows it holds; the encoder
        # changed, so this is not covered by the tests above.
        my $r = $dbh->selectall_arrayref('SELECT id FROM f WHERE g = 42');
        is((($r && @$r) ? $r->[0][0] : 'no-row'), '6',
           'T7 - an index lookup on a FLOAT column still works');
    },
    sub {
        my $r = $dbh->selectall_arrayref('SELECT id FROM f WHERE g = -2.5');
        is((($r && @$r) ? $r->[0][0] : 'no-row'), '7',
           'T7 - an index lookup on a negative FLOAT still works');
    },
    sub {
        my $w = warnings_from(sub {
            $dbh->selectall_arrayref("SELECT id FROM f WHERE g = 'abc'");
        });
        is($w, '', 'T7 - comparing a FLOAT column with junk emits no warning');
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
