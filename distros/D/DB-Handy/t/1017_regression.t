######################################################################
#
# Regression tests for the defects fixed in 1.09:
#
#   R1  _load_schema() clobbered the caller's $_
#   R2  LIMIT / OFFSET were ignored without WHERE / ORDER BY / GROUP BY
#   R3  CHECK constraint rejected a NULL value (SQL-92: UNKNOWN passes)
#   R4  LIKE did not escape regular-expression metacharacters
#   R5  LIKE did not un-escape a doubled single quote in the pattern
#   R6  COUNT(col) / COUNT(DISTINCT col) counted NULL values
#   R7  three or more unaliased expressions lost the SELECT column order
#   R8  a NULL FLOAT value produced an "isn't numeric" warning
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

my $BASE = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_regr_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $db = DB::Handy->new(base_dir => $BASE);
$db->create_database('regr');
$db->use_database('regr');

# Collect any warning the engine emits, so R8 can assert on it.
my @WARN;
$SIG{__WARN__} = sub { push @WARN, $_[0] };

# Flatten a result row set into a comparable string.
sub rowstr {
    my($r, @cols) = @_;
    return 'ERROR' unless $r && ($r->{type} eq 'rows');
    my @out;
    for my $row (@{$r->{data}}) {
        push @out, join(',', map { defined($row->{$_}) ? $row->{$_} : 'NULL' } @cols);
    }
    return join('|', @out);
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # R1 -- _load_schema() must not touch the caller's $_
    # -------------------------------------------------------------------
    sub {
        $db->execute('CREATE TABLE r1 (id INT)');
        my @ids = (11, 22, 33);
        for (@ids) { $db->execute("INSERT INTO r1 (id) VALUES ($_)") }
        is(join(',', @ids), '11,22,33', 'R1 - caller @_ array survives execute()');
    },
    sub {
        my $alive = 1;
        # A read-only value would die with "Modification of a read-only value".
        eval {
            $db->{_tables} = {};
            for (44) { $db->execute("INSERT INTO r1 (id) VALUES ($_)") }
        };
        $alive = 0 if $@;
        ok($alive, 'R1 - constant list element is not modified');
    },
    sub {
        $db->{_tables} = {};
        my @seen = map { $db->execute('SELECT id FROM r1 WHERE id = 11'); $_ } (1, 2, 3);
        is(join(',', @seen), '1,2,3', 'R1 - $_ intact inside map');
    },

    # -------------------------------------------------------------------
    # R2 -- LIMIT / OFFSET with no WHERE / ORDER BY / GROUP BY
    # -------------------------------------------------------------------
    sub {
        $db->execute('CREATE TABLE r2 (id INT, s VARCHAR(10))');
        $db->execute("INSERT INTO r2 (id,s) VALUES ($_,'v$_')") for 1 .. 5;
        my $r = $db->execute('SELECT id FROM r2 LIMIT 2');
        is(scalar(@{$r->{data}}), 2, 'R2 - bare LIMIT is honoured');
    },
    sub {
        my $r = $db->execute('SELECT id FROM r2 OFFSET 3');
        is(scalar(@{$r->{data}}), 2, 'R2 - bare OFFSET is honoured');
    },
    sub {
        my $r = $db->execute('SELECT * FROM r2 LIMIT 1');
        is(scalar(@{$r->{data}}), 1, 'R2 - SELECT * with bare LIMIT');
    },
    sub {
        my $r = $db->execute('SELECT id FROM r2 ORDER BY id LIMIT 2 OFFSET 1');
        is(rowstr($r, 'id'), '2|3', 'R2 - ORDER BY with LIMIT/OFFSET still works');
    },
    sub {
        my $r = $db->execute('SELECT id FROM r2 WHERE id > 1 LIMIT 2');
        is(scalar(@{$r->{data}}), 2, 'R2 - WHERE with LIMIT still works');
    },

    # -------------------------------------------------------------------
    # R3 -- CHECK constraint versus NULL
    # -------------------------------------------------------------------
    sub {
        $db->execute('CREATE TABLE r3 (id INT, age INT CHECK (age >= 0))');
        my $r = $db->execute('INSERT INTO r3 (id,age) VALUES (1,5)');
        is($r->{type}, 'ok', 'R3 - value satisfying CHECK is accepted');
    },
    sub {
        my $r = $db->execute('INSERT INTO r3 (id) VALUES (2)');
        is($r->{type}, 'ok', 'R3 - omitted checked column is accepted');
    },
    sub {
        my $r = $db->execute('INSERT INTO r3 (id,age) VALUES (3,NULL)');
        is($r->{type}, 'ok', 'R3 - explicit NULL passes CHECK');
    },
    sub {
        my $r = $db->execute('INSERT INTO r3 (id,age) VALUES (4,-1)');
        is($r->{type}, 'error', 'R3 - value violating CHECK is still rejected');
    },
    sub {
        my $r = $db->execute('UPDATE r3 SET age = -9 WHERE id = 1');
        is($r->{type}, 'error', 'R3 - UPDATE violating CHECK is still rejected');
    },
    sub {
        my $r = $db->execute('UPDATE r3 SET age = 7 WHERE id = 1');
        is($r->{type}, 'ok', 'R3 - UPDATE satisfying CHECK is accepted');
    },

    # -------------------------------------------------------------------
    # R4 / R5 -- LIKE pattern handling
    # -------------------------------------------------------------------
    sub {
        $db->execute('CREATE TABLE r4 (id INT, s VARCHAR(20))');
        $db->execute("INSERT INTO r4 (id,s) VALUES (1,'a.c')");
        $db->execute("INSERT INTO r4 (id,s) VALUES (2,'abc')");
        $db->execute("INSERT INTO r4 (id,s) VALUES (3,'C++')");
        $db->execute("INSERT INTO r4 (id,s) VALUES (4,'Cxx')");
        $db->execute("INSERT INTO r4 (id,s) VALUES (5,'50%off')");
        $db->execute("INSERT INTO r4 (id,s) VALUES (6,'O''Brien')");
        my $r = $db->execute("SELECT id FROM r4 WHERE s LIKE 'a.c'");
        is(rowstr($r, 'id'), '1', 'R4 - dot in LIKE pattern is literal');
    },
    sub {
        my $r = $db->execute("SELECT id FROM r4 WHERE s LIKE 'C++'");
        is(rowstr($r, 'id'), '3', 'R4 - plus in LIKE pattern is literal');
    },
    sub {
        my $r = $db->execute("SELECT id FROM r4 WHERE s LIKE '50\%off'");
        is(rowstr($r, 'id'), '5', 'R4 - percent still works as a wildcard');
    },
    sub {
        my $r = $db->execute("SELECT id FROM r4 WHERE s LIKE 'a_c'");
        is(rowstr($r, 'id'), '1|2', 'R4 - underscore still matches any character');
    },
    sub {
        my $r = $db->execute("SELECT id FROM r4 WHERE s NOT LIKE 'a.c'");
        is(rowstr($r, 'id'), '2|3|4|5|6', 'R4 - NOT LIKE escapes metacharacters too');
    },
    sub {
        my $r = $db->execute("SELECT id FROM r4 WHERE s LIKE 'O''B%'");
        is(rowstr($r, 'id'), '6', 'R5 - doubled quote inside a LIKE pattern');
    },

    # -------------------------------------------------------------------
    # R6 -- COUNT must skip NULL
    # -------------------------------------------------------------------
    sub {
        $db->execute('CREATE TABLE r6 (id INT, s VARCHAR(10))');
        $db->execute("INSERT INTO r6 (id,s) VALUES (1,'x')");
        $db->execute("INSERT INTO r6 (id,s) VALUES (2,'x')");
        $db->execute("INSERT INTO r6 (id,s) VALUES (3,'y')");
        $db->execute('INSERT INTO r6 (id,s) VALUES (4,NULL)');
        my $r = $db->execute('SELECT COUNT(*) FROM r6');
        is($r->{data}[0]{'COUNT(*)'}, 4, 'R6 - COUNT(*) counts every row');
    },
    sub {
        my $r = $db->execute('SELECT COUNT(s) FROM r6');
        is($r->{data}[0]{'COUNT(s)'}, 3, 'R6 - COUNT(col) skips NULL');
    },
    sub {
        my $r = $db->execute('SELECT COUNT(DISTINCT s) FROM r6');
        is($r->{data}[0]{'COUNT(DISTINCT s)'}, 2, 'R6 - COUNT(DISTINCT col) skips NULL');
    },

    # -------------------------------------------------------------------
    # R7 -- SELECT column order with three or more unaliased expressions
    # -------------------------------------------------------------------
    sub {
        my $dbh = DB::Handy->connect($BASE, 'regr');
        my $sth = $dbh->prepare('SELECT COUNT(*), SUM(id), MIN(id) FROM r6');
        $sth->execute;
        is(join(',', @{$sth->{NAME}}), 'COUNT(*),SUM(id),MIN(id)',
           'R7 - NAME follows the SELECT list order');
        $dbh->disconnect;
    },
    sub {
        my $dbh = DB::Handy->connect($BASE, 'regr');
        my $row = $dbh->selectall_arrayref('SELECT COUNT(*), SUM(id), MIN(id) FROM r6');
        is(join(',', @{$row->[0]}), '4,10,1',
           'R7 - arrayref values follow the SELECT list order');
        $dbh->disconnect;
    },
    sub {
        my $dbh = DB::Handy->connect($BASE, 'regr');
        my $sth = $dbh->prepare('SELECT id, s FROM r6 WHERE id = 1');
        $sth->execute;
        is(join(',', @{$sth->{NAME}}), 'id,s',
           'R7 - plain column list order is unchanged');
        $dbh->disconnect;
    },

    # -------------------------------------------------------------------
    # R8 -- no numeric warning for a NULL FLOAT
    # -------------------------------------------------------------------
    sub {
        @WARN = ();
        $db->execute('CREATE TABLE r8 (id INT, n FLOAT)');
        $db->execute('INSERT INTO r8 (id,n) VALUES (1,NULL)');
        $db->execute('INSERT INTO r8 (id) VALUES (2)');
        my @numeric = grep { /isn't numeric/ } @WARN;
        ok(!@numeric, "R8 - NULL FLOAT emits no \"isn't numeric\" warning");
    },
    sub {
        @WARN = ();
        $db->execute('CREATE INDEX r8_n ON r8 (n)');
        $db->execute('INSERT INTO r8 (id,n) VALUES (3,NULL)');
        my @numeric = grep { /isn't numeric/ } @WARN;
        ok(!@numeric, 'R8 - indexed NULL FLOAT emits no numeric warning');
    },
    sub {
        my $r = $db->execute('SELECT id FROM r8 WHERE id = 1');
        is(rowstr($r, 'id'), '1', 'R8 - the NULL FLOAT row is still readable');
    },
);

###############################################################################
# Run.  Every closure above emits exactly one assertion, so catching a die
# and reporting one "not ok" for it keeps the count in step with the plan
# even when the engine throws (which is what R1 used to do).
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

delete $SIG{__WARN__};

exit($FAIL ? 1 : 0);
