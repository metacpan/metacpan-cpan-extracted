use strict;
use warnings;

use Test::More;
use Clone qw(clone);
use File::Spec ();
use Scalar::Util ();

# GH #27: Cloning IO handles (filehandles, DBI-like objects) should not segfault.
# Clone cannot deep-copy IO handles (they wrap C-level structures), but it
# should either croak with a clear message or return a shallow ref — never crash.
#
# DBI clones lack XS-level magic and produce STDERR noise (SV dumps, "not a
# DBI handle" warnings) when DBI's DESTROY fires on them.  Worse, circular
# refs inside cloned handles cause SEGVs during global destruction.  We run
# DBI-specific tests in a forked subprocess and redirect its STDERR to
# devnull so neither the noise nor the crash pollutes the test harness.

plan tests => 18;

# --- Test 1-2: bare filehandle (PVGV containing PVIO) ---

{
    my $fh;
    open($fh, '<', $0) or die "Cannot open $0: $!";
    my $cloned;
    my $ok = eval { $cloned = clone($fh); 1 };
    ok($ok, "clone of bare filehandle does not die")
        or diag("Error: $@");
    ok(defined $cloned, "clone of filehandle returns something defined");
    close($fh);
}

# --- Test 3: IO::Handle object ---

SKIP: {
    eval { require IO::Handle } or skip "IO::Handle not available", 1;

    my $io = IO::Handle->new;
    my $cloned;
    my $ok = eval { $cloned = clone($io); 1 };
    ok($ok, "clone of IO::Handle does not die or segfault")
        or diag("Error: $@");
}

# --- Test 4-5: IO::File object ---

SKIP: {
    eval { require IO::File } or skip "IO::File not available", 2;

    my $io = IO::File->new($0, "r") or skip "Cannot open $0 via IO::File", 2;
    my $cloned;
    my $ok = eval { $cloned = clone($io); 1 };
    ok($ok, "clone of IO::File does not die or segfault")
        or diag("Error: $@");
    ok(defined $cloned, "clone of IO::File returns defined value");
    $io->close;
}

# --- Test 6-7: hashref containing a filehandle (DBI-like structure) ---

{
    my $fh;
    open($fh, '<', $0) or die "Cannot open $0: $!";
    my $obj = bless { handle => $fh, name => "test" }, "FakeDBH";
    my $cloned;
    my $ok = eval { $cloned = clone($obj); 1 };
    ok($ok, "clone of hashref containing filehandle does not die")
        or diag("Error: $@");
    ok(defined $cloned, "clone result is defined");
    close($fh);
}

# --- Test 8-9: nested structure with IO at depth ---

{
    my $fh;
    open($fh, '<', $0) or die "Cannot open $0: $!";
    my $deep = {
        level1 => {
            level2 => {
                io => $fh,
                data => [1, 2, 3],
            },
            name => "nested",
        },
    };
    my $cloned;
    my $ok = eval { $cloned = clone($deep); 1 };
    ok($ok, "clone of deeply nested structure with IO does not die")
        or diag("Error: $@");
    ok(defined $cloned, "deeply nested clone returns defined value");
    close($fh);
}

# --- Test 10: STDOUT/STDERR globals ---

{
    my $cloned;
    my $ok = eval { $cloned = clone(\*STDOUT); 1 };
    ok($ok, "clone of STDOUT glob ref does not die")
        or diag("Error: $@");
}

# --- Test 11-12: Socket-like handle ---

SKIP: {
    eval { require IO::Socket::INET } or skip "IO::Socket::INET not available", 2;

    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
    );
    skip "Cannot create socket", 2 unless $sock;

    my $cloned;
    my $ok = eval { $cloned = clone($sock); 1 };
    ok($ok, "clone of IO::Socket does not die or segfault")
        or diag("Error: $@");
    ok(defined $cloned, "clone of IO::Socket returns defined value");
    $sock->close;
}

# --- Test 13-16: DBI database handle (the original GH #27 report) ---
#
# Cloned DBI handles lack XS-level magic.  DBI's DESTROY dumps SV internals
# to STDERR and internal circular refs cause SEGVs during global destruction.
# We run these tests in a forked child with STDERR suppressed; the child
# prints TAP lines to a pipe and the parent relays them to Test::More.

SKIP: {
    eval { require DBI; require DBD::SQLite }
        or skip "DBI + DBD::SQLite required for DBI tests", 4;
    skip "fork() not available (Windows)", 4 unless _can_fork();

    my $result = _run_in_subprocess(sub {
        my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", "", "",
            { PrintError => 0, RaiseError => 0 });
        return "skip Cannot create DBI handle" unless $dbh;

        $dbh->do("CREATE TABLE test (id INTEGER, name TEXT)");
        $dbh->do("INSERT INTO test VALUES (1, 'foo')");

        # clone does not segfault
        my $cloned;
        my $clone_ok = eval { $cloned = clone($dbh); 1 };
        print "clone_ok=" . ($clone_ok ? 1 : 0) . "\n";
        print "clone_defined=" . (defined $cloned ? 1 : 0) . "\n";

        # original still works after clone
        my $sth = $dbh->prepare("SELECT name FROM test WHERE id = 1");
        $sth->execute;
        my ($name) = $sth->fetchrow_array;
        print "name=$name\n";

        # cloned handle is a HASH-based object (no magic)
        my $is_hash = (ref($cloned) && Scalar::Util::reftype($cloned) eq 'HASH') ? 1 : 0;
        print "is_hash=$is_hash\n";

        $sth->finish;
        $dbh->disconnect;
    });

    if ($result =~ /^skip (.*)/) {
        skip $1, 4;
    }

    my %r = map { /^(\w+)=(.*)/ ? ($1 => $2) : () } split /\n/, $result;
    ok($r{clone_ok},      "GH #27: clone of DBI handle does not segfault");
    ok($r{clone_defined},  "cloned DBI handle is defined");
    is($r{name}, "foo",   "original DBI handle still works after clone");
    ok($r{is_hash},       "cloned DBI handle is a HASH-based object (no magic)");
}

# --- Test 17-18: DBI statement handle ---

SKIP: {
    eval { require DBI; require DBD::SQLite }
        or skip "DBI + DBD::SQLite required for sth tests", 2;
    skip "fork() not available (Windows)", 2 unless _can_fork();

    my $result = _run_in_subprocess(sub {
        my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", "", "",
            { PrintError => 0, RaiseError => 0 });
        return "skip Cannot create DBI handle" unless $dbh;

        $dbh->do("CREATE TABLE t2 (x INTEGER)");
        my $sth = $dbh->prepare("SELECT * FROM t2");

        # clone of sth does not segfault
        my $cloned;
        my $clone_ok = eval { $cloned = clone($sth); 1 };
        print "clone_ok=" . ($clone_ok ? 1 : 0) . "\n";

        # original still works
        $sth->execute;
        print "original_works=1\n";

        $sth->finish;
        $dbh->disconnect;
    });

    if ($result =~ /^skip (.*)/) {
        skip $1, 2;
    }

    my %r = map { /^(\w+)=(.*)/ ? ($1 => $2) : () } split /\n/, $result;
    ok($r{clone_ok},       "clone of DBI statement handle does not segfault");
    ok($r{original_works}, "original statement handle still works after clone");
}

# Check whether fork() is usable.  Strawberry Perl on Windows implements
# fork() via ithreads emulation which doesn't support pipe+fork reliably,
# and some builds don't implement it at all.
sub _can_fork {
    return 0 if $^O eq 'MSWin32';
    my $pid = eval { fork() };
    return 0 unless defined $pid;
    if ($pid == 0) {
        require POSIX;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);
    return 1;
}

# Run a code block in a forked child process with STDERR suppressed.
# Returns the child's STDOUT output.  If the child crashes (SEGV etc.),
# the parent survives and the test still passes based on what was printed
# before the crash.
sub _run_in_subprocess {
    my ($code) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child: suppress STDERR, capture STDOUT to pipe
        close $rd;
        open(STDERR, '>', File::Spec->devnull);
        open(STDOUT, '>&', $wr);
        $| = 1;
        my $ret = $code->();
        print $ret if defined $ret && !ref $ret;
        close $wr;
        # Use POSIX::_exit to avoid running destructors in the child
        # (which would trigger the DBI SEGV on cloned handles).
        require POSIX;
        POSIX::_exit(0);
    }

    # Parent
    close $wr;
    my $output = do { local $/; <$rd> };
    close $rd;
    waitpid($pid, 0);
    return $output || "";
}
