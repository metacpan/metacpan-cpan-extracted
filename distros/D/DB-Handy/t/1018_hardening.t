######################################################################
#
# Tests for the hardening work in 1.09:
#
#   H1  SQL comments (-- and /* */) are stripped before parsing, and a
#       comment marker inside a string literal is left alone
#   H2  index files stay consistent across write / read / rebuild, and
#       insert() publishes the record and its index entries together
#   H3  DBI statement attributes NAME_lc, NAME_uc, NUM_OF_PARAMS and
#       Statement
#   H4  a ? inside a string literal or a comment is not a placeholder
#   H5  fetchall_arrayref ignores a column-index slice (documented)
#   H6  the write paths report an I/O failure instead of succeeding
#       silently (skipped where the platform lets the test process
#       write to a read-only file, e.g. when running as root)
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
sub skip {
    my($n, $why) = @_;
    $T++;
    $PASS++;
    print "ok $T - $n # SKIP $why\n";
}

my $BASE = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_hard_$$");
File::Path::rmtree($BASE) if -d $BASE;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($BASE) if defined($BASE) && -d $BASE }

my $dbh = DB::Handy->connect($BASE, 'hard')
    or die "connect failed: $DB::Handy::errstr\n";

# Does chmod actually stop this process from writing?  It does not when the
# test runs as root, and it behaves differently across file systems, so H6
# probes first and skips rather than reporting a spurious failure.
my $CHMOD_BITES = 0;
{
    my $probe = File::Spec->catfile($BASE, 'probe.tmp');
    local *PFH;
    if (open(PFH, "> $probe")) {
        print PFH "x";
        close PFH;
        chmod 0444, $probe;
        if (open(PFH, "+< $probe")) { close PFH }
        else                        { $CHMOD_BITES = 1 }
        chmod 0644, $probe;
        unlink $probe;
    }
}

# H6 works on its own table; create it up front so the last H6 assertion
# holds whether or not the chmod-based cases run.
$dbh->do('CREATE TABLE ro (id INT)');
$dbh->do('INSERT INTO ro (id) VALUES (1)');

# Flatten selectall_arrayref output into a comparable string.
sub flat {
    my($r) = @_;
    return 'undef' unless defined $r;
    return join('|', map { join(',', map { defined($_) ? $_ : 'NULL' } @$_) } @$r);
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
# Each closure emits exactly one assertion.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # H1 -- SQL comments
    # -------------------------------------------------------------------
    sub {
        $dbh->do('CREATE TABLE c (id INT, s VARCHAR(30))');
        $dbh->do('INSERT INTO c (id,s) VALUES (?,?)', 1, 'a--b');
        $dbh->do('INSERT INTO c (id,s) VALUES (?,?)', 2, 'x/*y*/z');
        $dbh->do('INSERT INTO c (id,s) VALUES (?,?)', 3, "it's -- fine");
        is(flat($dbh->selectall_arrayref('SELECT id FROM c WHERE id = 1 -- trailing')),
           '1', 'H1 - trailing -- comment is stripped');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT id FROM c /* mid */ WHERE id = 2')),
           '2', 'H1 - /* */ comment before WHERE is stripped');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT id FROM c WHERE id = 3 /* a */ /* b */')),
           '3', 'H1 - two /* */ comments are stripped');
    },
    sub {
        is(flat($dbh->selectall_arrayref("SELECT id FROM c WHERE s = 'a--b'")),
           '1', 'H1 - -- inside a literal is not a comment');
    },
    sub {
        is(flat($dbh->selectall_arrayref("SELECT id FROM c WHERE s = 'x/*y*/z'")),
           '2', 'H1 - /* */ inside a literal is not a comment');
    },
    sub {
        is(flat($dbh->selectall_arrayref("SELECT id FROM c WHERE s = 'it''s -- fine'")),
           '3', 'H1 - -- after an escaped quote is not a comment');
    },
    sub {
        my $r = $dbh->selectall_arrayref('SELECT id FROM c WHERE id = 1 /* never closed');
        is(flat($r), '1', 'H1 - unterminated /* does not hang or die');
    },
    sub {
        my $n = $dbh->do("UPDATE c SET s = 'ok' WHERE id = 3 -- comment");
        is($n, 1, 'H1 - comments work on a non-SELECT statement too');
    },

    # -------------------------------------------------------------------
    # H2 -- index integrity
    # -------------------------------------------------------------------
    sub {
        $dbh->do('CREATE TABLE ix (id INT, v VARCHAR(10))');
        $dbh->do("INSERT INTO ix (id,v) VALUES ($_,'v$_')") for 1 .. 5;
        $dbh->do('CREATE INDEX ix_id ON ix (id)');
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 3')),
           'v3', 'H2 - index lookup after CREATE INDEX');
    },
    sub {
        # insert() now updates the indexes while still holding the .dat lock
        $dbh->do("INSERT INTO ix (id,v) VALUES (6,'v6')");
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 6')),
           'v6', 'H2 - index entry is present right after INSERT');
    },
    sub {
        $dbh->do('UPDATE ix SET id = 60 WHERE id = 6');
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 60')),
           'v6', 'H2 - index follows an UPDATE');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 6')),
           '', 'H2 - the old index entry is gone after UPDATE');
    },
    sub {
        $dbh->do('DELETE FROM ix WHERE id = 2');
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 2')),
           '', 'H2 - index follows a DELETE');
    },
    sub {
        # vacuum() renumbers records and rebuilds every index
        my $e = DB::Handy->new(base_dir => $BASE);
        $e->use_database('hard');
        my $kept = $e->vacuum('ix');
        is($kept, 5, 'H2 - vacuum keeps the live records');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT v FROM ix WHERE id = 60')),
           'v6', 'H2 - index still resolves after vacuum rebuilt it');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT id FROM ix WHERE id > 2 ORDER BY id')),
           '3|4|5|60', 'H2 - index range scan after vacuum');
    },
    sub {
        # A unique index must still reject a duplicate
        $dbh->do('CREATE TABLE uq (id INT)');
        $dbh->do('CREATE UNIQUE INDEX uq_id ON uq (id)');
        $dbh->do('INSERT INTO uq (id) VALUES (1)');
        my $rc = $dbh->do('INSERT INTO uq (id) VALUES (1)');
        ok(!defined $rc, 'H2 - UNIQUE index still blocks a duplicate');
    },

    # -------------------------------------------------------------------
    # H3 -- DBI statement attributes
    # -------------------------------------------------------------------
    sub {
        $dbh->do('CREATE TABLE At (Id INT, Nm VARCHAR(20))');
        $dbh->do("INSERT INTO At (Id,Nm) VALUES (1,'Alice')");
        my $sth = $dbh->prepare('SELECT Id, Nm FROM At WHERE Id = ?');
        $sth->execute(1);
        is(join(',', @{$sth->{NAME_lc}}), 'id,nm', 'H3 - NAME_lc is lower-cased');
    },
    sub {
        my $sth = $dbh->prepare('SELECT Id, Nm FROM At WHERE Id = ?');
        $sth->execute(1);
        is(join(',', @{$sth->{NAME_uc}}), 'ID,NM', 'H3 - NAME_uc is upper-cased');
    },
    sub {
        my $sth = $dbh->prepare('SELECT Id, Nm FROM At WHERE Id = ?');
        $sth->execute(1);
        is(join(',', @{$sth->{NAME}}), 'Id,Nm', 'H3 - NAME keeps the original case');
    },
    sub {
        my $sth = $dbh->prepare('SELECT Id FROM At WHERE Id = ? AND Nm = ?');
        is($sth->{NUM_OF_PARAMS}, 2, 'H3 - NUM_OF_PARAMS before execute');
    },
    sub {
        my $sql = 'SELECT Id FROM At WHERE Id = 1';
        my $sth = $dbh->prepare($sql);
        is($sth->{Statement}, $sql, 'H3 - Statement is the SQL as prepared');
    },
    sub {
        my $sth = $dbh->prepare('INSERT INTO At (Id,Nm) VALUES (?,?)');
        $sth->execute(2, 'Bob');
        is($sth->{NUM_OF_FIELDS}, 0, 'H3 - NUM_OF_FIELDS is 0 for a non-SELECT');
    },

    # -------------------------------------------------------------------
    # H4 -- placeholders versus literals and comments
    # -------------------------------------------------------------------
    sub {
        my $sth = $dbh->prepare("UPDATE At SET Nm = 'x?y' WHERE Id = ?");
        is($sth->{NUM_OF_PARAMS}, 1, 'H4 - ? inside a literal is not counted');
    },
    sub {
        my $n = $dbh->do("UPDATE At SET Nm = 'x?y' WHERE Id = ?", 2);
        is($n, 1, 'H4 - the bind value goes to the real placeholder');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT Nm FROM At WHERE Id = 2')),
           'x?y', 'H4 - the literal ? survives into the stored value');
    },
    sub {
        my $sth = $dbh->prepare('SELECT Id FROM At WHERE Id = ? -- is ? ok');
        is($sth->{NUM_OF_PARAMS}, 1, 'H4 - ? inside a comment is not counted');
    },
    sub {
        is(flat($dbh->selectall_arrayref('SELECT Id FROM At WHERE Id = ? -- is ? ok', {}, 1)),
           '1', 'H4 - a comment holding a ? still binds correctly');
    },

    # -------------------------------------------------------------------
    # H5 -- fetchall_arrayref column-index slice (documented as ignored)
    # -------------------------------------------------------------------
    sub {
        my $sth = $dbh->prepare('SELECT Id, Nm FROM At WHERE Id = 1');
        $sth->execute;
        my $all = $sth->fetchall_arrayref([0]);
        is(scalar(@{$all->[0]}), 2,
           'H5 - a column-index slice is ignored, every column is returned');
    },
    sub {
        my $sth = $dbh->prepare('SELECT Id, Nm FROM At WHERE Id = 1');
        $sth->execute;
        my $all = $sth->fetchall_arrayref({});
        is(join(',', sort keys %{$all->[0]}), 'Id,Nm',
           'H5 - a hash slice still returns hash-refs');
    },

    # -------------------------------------------------------------------
    # H6 -- write paths report I/O failure
    # -------------------------------------------------------------------
    sub {
        unless ($CHMOD_BITES) {
            skip('H6 - INSERT reports a read-only data file',
                 'chmod does not stop this process from writing');
            return;
        }
        my $dat = File::Spec->catfile($BASE, 'hard', 'ro.dat');
        chmod 0444, $dat;
        my $rc = $dbh->do('INSERT INTO ro (id) VALUES (2)');
        chmod 0644, $dat;
        ok(!defined $rc, 'H6 - INSERT reports a read-only data file');
    },
    sub {
        unless ($CHMOD_BITES) {
            skip('H6 - the error message names the failure',
                 'chmod does not stop this process from writing');
            return;
        }
        my $dat = File::Spec->catfile($BASE, 'hard', 'ro.dat');
        chmod 0444, $dat;
        $dbh->do('INSERT INTO ro (id) VALUES (3)');
        my $msg = $dbh->errstr;
        chmod 0644, $dat;
        ok((defined($msg) && ($msg =~ /dat|record/i)),
           'H6 - the error message names the failure');
    },
    sub {
        # After the file is writable again the table must still work.
        my $rc = $dbh->do('INSERT INTO ro (id) VALUES (4)');
        is($rc, 1, 'H6 - the table is usable once the file is writable again');
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
