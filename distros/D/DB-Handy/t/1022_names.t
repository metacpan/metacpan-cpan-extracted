######################################################################
#
# Tests for the identifier validation added in 1.09:
#
#   N1  drop_database() no longer removes a tree outside base_dir
#   N2  create_database() no longer creates a directory outside base_dir
#   N3  use_database() and the engine constructor reject a bad name
#   N4  create_table() / drop_table() reject a name that is not \w+
#   N5  create_index() / drop_index() reject a name that is not \w+
#   N6  every other table-taking method is covered through _load_schema
#   N7  ordinary \w+ names, including digits and underscores, still work
#   N8  the SQL layer is unaffected (it already restricted names to \w+)
#   N9  the Windows device names (con, prn, aux, nul, comN, lptN) are
#       rejected, in any letter case, on every platform
#
# N1 is the reason the check exists: before it, a name coming from
# outside the program could be walked up out of base_dir and handed to
# File::Path::rmtree().
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

# ROOT holds two siblings: BASE is the database area the engine is told
# about, VICTIM is the tree that an unchecked '..' name would reach.
my $ROOT   = File::Spec->catdir(File::Spec->tmpdir, "dbhandy_names_$$");
my $BASE   = File::Spec->catdir($ROOT, 'base');
my $VICTIM = File::Spec->catdir($ROOT, 'victim');
File::Path::rmtree($ROOT) if -d $ROOT;

# Remove the scratch directory however the script leaves: a normal exit,
# a die in mid-file, or an interrupt.  Without this an aborted run left a
# stale tree behind in the system temp directory.
END { File::Path::rmtree($ROOT) if defined($ROOT) && -d $ROOT }
File::Path::mkpath($BASE);
File::Path::mkpath($VICTIM);

# A file inside VICTIM, so an escaped rmtree is detectable and not just a
# missing empty directory.
my $CANARY = File::Spec->catfile($VICTIM, 'keepme.txt');
{
    local *CANARY_FH;
    open(CANARY_FH, "> $CANARY") or die "cannot write canary: $!\n";
    print CANARY_FH "keep\n";
    close CANARY_FH;
}

my $db = DB::Handy->new(base_dir => $BASE)
    or die "new failed: $DB::Handy::errstr\n";
$db->create_database('names') or die "create_database failed\n";
$db->use_database('names')    or die "use_database failed\n";
$db->create_table('t1', [['id', 'INT'], ['name', 'VARCHAR', 20]])
    or die "create_table failed\n";

# Names that must never be turned into a path component.
my @BAD = ('../victim', '..', '.', 'a/b', 'a\\b', 'x:y', '', 'a b', 'a.b');

# Count how many entries base_dir has, so a rejected create is provably a
# no-op rather than something that merely returned false.
sub base_entries {
    local *BDH;
    opendir(BDH, $BASE) or return -1;
    my @e = grep { !/^\.\.?\z/ } readdir(BDH);
    closedir BDH;
    return scalar(@e);
}

###############################################################################
# Test bodies.  The plan count is derived from this list, never hard-coded.
###############################################################################
my @tests = (

    # -------------------------------------------------------------------
    # N1 -- the defect this check exists for
    # -------------------------------------------------------------------
    sub {
        my $r = $db->drop_database('../victim');
        ok(!$r, "N1 drop_database('../victim') is refused");
    },
    sub {
        ok(-f $CANARY,
           'N1 the tree outside base_dir is still there afterwards');
    },
    sub {
        like_invalid($DB::Handy::errstr, 'database',
                     'N1 errstr names the offending database');
    },

    # -------------------------------------------------------------------
    # N2 -- create_database
    # -------------------------------------------------------------------
    sub {
        my $before = base_entries();
        my $bad    = 0;
        for my $name (@BAD) {
            $bad++ if $db->create_database($name);
        }
        is($bad, 0, 'N2 create_database refuses every non-identifier name');
    },
    sub {
        is(base_entries(), 1,
           'N2 base_dir still holds only the one real database');
    },
    sub {
        ok(!-d File::Spec->catdir($ROOT, 'victim', 'nested'),
           'N2 nothing was created outside base_dir');
    },

    # -------------------------------------------------------------------
    # N3 -- use_database and the constructor
    # -------------------------------------------------------------------
    sub {
        my $bad = 0;
        for my $name (@BAD) {
            $bad++ if $db->use_database($name);
        }
        is($bad, 0, 'N3 use_database refuses every non-identifier name');
    },
    sub {
        is($db->{db_name}, 'names',
           'N3 a refused use_database leaves the selection alone');
    },
    sub {
        my $e = DB::Handy->new(base_dir => $BASE, db_name => '../victim');
        ok(!defined($e), 'N3 the constructor refuses a bad db_name');
    },
    sub {
        like_invalid($DB::Handy::errstr, 'database',
                     'N3 the constructor reports which kind of name was bad');
    },

    # -------------------------------------------------------------------
    # N4 -- table names
    # -------------------------------------------------------------------
    sub {
        my $bad = 0;
        for my $name (@BAD) {
            $bad++ if $db->create_table($name, [['id', 'INT']]);
        }
        is($bad, 0, 'N4 create_table refuses every non-identifier name');
    },
    sub {
        like_invalid($DB::Handy::errstr, 'table',
                     'N4 errstr says the table name was the problem');
    },
    sub {
        my $bad = 0;
        for my $name (@BAD) {
            $bad++ if $db->drop_table($name);
        }
        is($bad, 0, 'N4 drop_table refuses every non-identifier name');
    },
    sub {
        ok(-f $CANARY, 'N4 no table operation touched the outside tree');
    },

    # -------------------------------------------------------------------
    # N5 -- index names
    # -------------------------------------------------------------------
    sub {
        my $bad = 0;
        for my $name (@BAD) {
            $bad++ if $db->create_index($name, 't1', 'id', 0);
        }
        is($bad, 0, 'N5 create_index refuses every non-identifier name');
    },
    sub {
        like_invalid($DB::Handy::errstr, 'index',
                     'N5 errstr says the index name was the problem');
    },
    sub {
        my $bad = 0;
        for my $name (@BAD) {
            $bad++ if $db->drop_index($name, 't1');
        }
        is($bad, 0, 'N5 drop_index refuses every non-identifier name');
    },

    # -------------------------------------------------------------------
    # N6 -- the rest of the table-taking methods, via _load_schema
    # -------------------------------------------------------------------
    sub {
        ok(!defined($db->describe_table('../victim')),
           'N6 describe_table refuses a bad table name');
    },
    sub {
        ok(!defined($db->list_indexes('../victim')),
           'N6 list_indexes refuses a bad table name');
    },
    sub {
        ok(!defined($db->insert('../victim', {id => 1})),
           'N6 insert refuses a bad table name');
    },
    sub {
        ok(!defined($db->delete_rows('../victim', sub { 1 })),
           'N6 delete_rows refuses a bad table name');
    },
    sub {
        ok(!defined($db->vacuum('../victim')),
           'N6 vacuum refuses a bad table name');
    },

    # -------------------------------------------------------------------
    # N7 -- ordinary names are untouched
    # -------------------------------------------------------------------
    sub {
        ok($db->create_database('db_2'),
           'N7 an underscore-and-digit database name is accepted');
    },
    sub {
        ok($db->use_database('db_2'), 'N7 it can then be selected');
    },
    sub {
        ok($db->create_table('T_9', [['id', 'INT']]),
           'N7 a mixed-case table name with a digit is accepted');
    },
    sub {
        ok($db->create_index('idx_1', 'T_9', 'id', 1),
           'N7 an index name with an underscore and a digit is accepted');
    },
    sub {
        ok($db->drop_index('idx_1', 'T_9'), 'N7 and can be dropped again');
    },
    sub {
        ok($db->drop_table('T_9'), 'N7 the table can be dropped again');
    },
    sub {
        ok($db->drop_database('db_2'),
           'N7 the database can be dropped again');
    },

    # -------------------------------------------------------------------
    # N8 -- the SQL layer, which already applied the same rule
    # -------------------------------------------------------------------
    sub {
        $db->use_database('names');
        my $res = $db->execute('DROP DATABASE ../victim');
        is($res->{type}, 'error', 'N8 SQL DROP DATABASE rejects a bad name');
    },
    sub {
        ok(-f $CANARY, 'N8 the outside tree survived the SQL attempt');
    },
    sub {
        my $res = $db->execute('CREATE TABLE ok_1 (id INT)');
        is($res->{type}, 'ok', 'N8 an ordinary CREATE TABLE still works');
    },
    sub {
        my $res = $db->execute('INSERT INTO ok_1 (id) VALUES (7)');
        is($res->{type}, 'ok', 'N8 and can still be written to');
    },

    # -------------------------------------------------------------------
    # N9 -- Windows device names.  On MSWin32 "nul.sch" is the bit bucket,
    # so a table called nul would appear to be created, swallow every
    # write and read back as empty.  Rejected on every platform, so that a
    # data directory built on one system stays usable on another.
    # -------------------------------------------------------------------
    sub {
        $db->use_database('names');
        $DB::Handy::errstr = '';   # so the next case cannot read a stale message
        ok(!$db->create_table('nul', [['id', 'INT']]),
           'N9 create_table rejects the device name nul');
    },
    sub {
        like_invalid($DB::Handy::errstr, 'table',
                     'N9 the rejection is an Invalid table name');
    },
    sub {
        ok(!-f File::Spec->catfile($BASE, 'names', 'nul.sch'),
           'N9 no schema file was left behind');
    },
    sub {
        ok(!$db->create_table('NUL', [['id', 'INT']]),
           'N9 the check is case-insensitive');
    },
    sub {
        my $bad = 0;
        my $dev;
        for $dev (qw(con prn aux com1 com9 lpt1 lpt9)) {
            $bad++ if $db->create_table($dev, [['id', 'INT']]);
        }
        is($bad, 0, 'N9 con, prn, aux, comN and lptN are rejected too');
    },
    sub {
        ok(!$db->create_database('nul'),
           'N9 create_database rejects a device name as well');
    },
    sub {
        ok(!$db->create_index('nul', 'ok_1', 'id'),
           'N9 create_index rejects a device name as well');
    },
    sub {
        my $res = $db->execute('CREATE TABLE nul (id INT)');
        is($res->{type}, 'error', 'N9 the SQL layer rejects it too');
    },
    sub {
        ok($db->create_table('nul1', [['id', 'INT']]),
           'N9 a name that merely starts with a device name is accepted');
    },
    sub {
        ok($db->drop_table('nul1'), 'N9 and behaves like any other table');
    },
);

# Assert that $errstr is one of the three validation messages and that it
# is about the expected kind of name.
sub like_invalid {
    my($got, $kind, $name) = @_;
    my $str = defined($got) ? $got : 'undef';
    # The match must be forced to scalar context.  ok() takes a list, and a
    # failing list-context match yields the empty list, so ok() would have
    # received the description as its condition and undef as its name --
    # every failure here reported itself as a nameless pass.
    my $hit = ($str =~ /^Invalid \Q$kind\E name '/) ? 1 : 0;
    ok($hit, $name . " (errstr='$str')");
}

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

exit($FAIL ? 1 : 0);
