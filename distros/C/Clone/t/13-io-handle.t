use strict;
use warnings;

use Test::More;
use Clone qw(clone);

# GH #27: Cloning IO handles (filehandles, DBI-like objects) should not segfault.
# Clone cannot deep-copy IO handles (they wrap C-level structures), but it
# should either croak with a clear message or return a shallow ref — never crash.

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

SKIP: {
    eval { require DBI; require DBD::SQLite }
        or skip "DBI + DBD::SQLite required for DBI tests", 4;

    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", "", "",
        { PrintError => 0, RaiseError => 0 });
    skip "Cannot create DBI handle", 4 unless $dbh;

    $dbh->do("CREATE TABLE test (id INTEGER, name TEXT)");
    $dbh->do("INSERT INTO test VALUES (1, 'foo')");

    # Test 13: clone does not segfault
    my $cloned;
    my $ok = eval { $cloned = clone($dbh); 1 };
    ok($ok, "GH #27: clone of DBI handle does not segfault")
        or diag("Error: $@");

    # Test 14: clone returns a defined value
    ok(defined $cloned, "cloned DBI handle is defined");

    # Test 15: original still works after clone
    my $sth = $dbh->prepare("SELECT name FROM test WHERE id = 1");
    $sth->execute;
    my ($name) = $sth->fetchrow_array;
    is($name, "foo", "original DBI handle still works after clone");

    # Test 16: cloned handle cannot be used (but doesn't segfault)
    eval {
        my $sth2 = $cloned->prepare("SELECT * FROM test");
        $sth2->execute;
    };
    ok($@, "cloned DBI handle raises error on use (not segfault)")
        or diag("Expected an error but got none");

    $dbh->disconnect;
}

# --- Test 17-18: DBI statement handle ---

SKIP: {
    eval { require DBI; require DBD::SQLite }
        or skip "DBI + DBD::SQLite required for sth tests", 2;

    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", "", "",
        { PrintError => 0, RaiseError => 0 });
    skip "Cannot create DBI handle", 2 unless $dbh;

    $dbh->do("CREATE TABLE t2 (x INTEGER)");
    my $sth = $dbh->prepare("SELECT * FROM t2");

    # Test 17: clone of sth does not segfault
    my $cloned;
    my $ok = eval { $cloned = clone($sth); 1 };
    ok($ok, "clone of DBI statement handle does not segfault")
        or diag("Error: $@");

    # Test 18: original dbh still works
    $sth->execute;
    ok(1, "original statement handle still works after clone");

    $dbh->disconnect;
}
