use Test2::V0 -target => 'DBIx::QuickDB::Driver::MariaDB';
use File::Temp qw/tempdir/;

# Unit tests for the MDEV-38811 broken-version refusal. Uses stub "server"
# binaries that only answer -V, so no real MariaDB is needed for most of this.

# The stubs are #!/bin/sh scripts; without a POSIX shell they never execute, so
# broken_version_check sees no -V output and returns undef for everything. The
# MariaDB driver is unusable on Windows regardless.
skip_all "stub servers require a POSIX shell (#!/bin/sh), unavailable on $^O"
    if $^O eq 'MSWin32';

my $dir = tempdir(CLEANUP => 1);

sub stub_bin {
    my ($name, $version_line) = @_;
    my $path = "$dir/$name";
    open(my $fh, '>', $path) or die "Could not write stub: $!";
    print $fh "#!/bin/sh\necho \"$version_line\"\n";
    close($fh);
    chmod(0755, $path);
    return $path;
}

my $broken122  = stub_bin(broken122  => 'mariadbd  Ver 12.2.2-MariaDB for linux-systemd on x86_64 (MariaDB Server)');
my $broken1011 = stub_bin(broken1011 => 'mariadbd  Ver 10.11.16-MariaDB for Linux on x86_64 (MariaDB Server)');
my $fixed123   = stub_bin(fixed123   => 'mariadbd  Ver 12.3.2-MariaDB for Linux on x86_64 (MariaDB Server)');
my $old1011    = stub_bin(old1011    => 'mariadbd  Ver 10.11.15-MariaDB for Linux on x86_64 (MariaDB Server)');
my $mysql8     = stub_bin(mysql8     => 'mysqld  Ver 8.0.42 for Linux on x86_64 (MySQL Community Server - GPL)');

subtest broken_version_check => sub {
    local %ENV = %ENV;
    delete $ENV{QDB_MARIADB_IGNORE_BROKEN};

    like(
        $CLASS->broken_version_check($broken122),
        qr/MariaDB 12\.2\.2 hangs unkillably.*MDEV-38811/s,
        "12.2.2 is flagged, message names the bug"
    );

    like(
        $CLASS->broken_version_check($broken122),
        qr/skip-grant-tables/,
        "message explains the trigger"
    );

    like(
        $CLASS->broken_version_check($broken122),
        qr/QDB_MARIADB_IGNORE_BROKEN/,
        "message names the override"
    );

    like(
        $CLASS->broken_version_check($broken1011),
        qr/MariaDB 10\.11\.16 .*fixed in 10\.11\.17/s,
        "10.11.16 is flagged and points at the fixed release"
    );

    is($CLASS->broken_version_check($fixed123), undef, "12.3.2 is fine");
    is($CLASS->broken_version_check($old1011),  undef, "10.11.15 (pre-bug) is fine");
    is($CLASS->broken_version_check($mysql8),   undef, "non-MariaDB output is ignored");
    is($CLASS->broken_version_check("$dir/nope"), undef, "missing binary is ignored");
    is($CLASS->broken_version_check(undef),       undef, "undef binary is ignored");

    {
        local $ENV{QDB_MARIADB_IGNORE_BROKEN} = 1;
        is($CLASS->broken_version_check($broken122), undef, "QDB_MARIADB_IGNORE_BROKEN accepts a broken server");
    }
};

subtest viable_integration => sub {
    skip_all "No MariaDB install detected (provider_info empty), cannot exercise viable()"
        unless keys %{$CLASS->provider_info};
    skip_all "Neither DBD::MariaDB nor DBD::mysql installed"
        unless $CLASS->dbd_driver;

    local %ENV = %ENV;
    delete $ENV{QDB_MARIADB_IGNORE_BROKEN};

    my ($ok, $why) = $CLASS->viable({bootstrap => 1, server => $broken122});
    ok(!$ok, "broken server version is not viable");
    like($why, qr/MDEV-38811/, "reason explains the server bug");

    ($ok, $why) = $CLASS->viable({autostart => 1, server => $broken122});
    ok(!$ok, "also refused for autostart without bootstrap");

    ($ok, $why) = $CLASS->viable({server => $broken122});
    ok($ok, "no bootstrap/autostart means the server is never started, version is irrelevant")
        or diag $why;

    ($ok, $why) = $CLASS->viable({bootstrap => 1, server => $fixed123});
    ok($ok, "fixed version is viable") or diag $why;

    {
        local $ENV{QDB_MARIADB_IGNORE_BROKEN} = 1;
        ($ok, $why) = $CLASS->viable({bootstrap => 1, server => $broken122});
        ok($ok, "override makes the broken version viable again") or diag $why;
    }
};

done_testing;
