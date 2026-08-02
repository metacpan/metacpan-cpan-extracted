use Test2::V0 -target => 'DBIx::QuickDB::Driver::MariaDB';
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

{
    package Local::MariaDB::MatchedInstall;
    use parent -norequire, 'DBIx::QuickDB::Driver::MariaDB';
    sub dbd_driver { 'DBD::Test' }
}

{
    package Local::MariaDB::MismatchedInstall;
    use parent -norequire, 'DBIx::QuickDB::Driver::MariaDB';
    sub dbd_driver { 'DBD::Test' }
}

# Unit tests for the MDEV-38811 broken-version refusal. Uses stub "server"
# binaries that only answer -V, so no real MariaDB is needed for most of this.

# The stubs are #!/bin/sh scripts; without a POSIX shell they never execute, so
# broken_version_check sees no -V output and returns undef for everything. The
# MariaDB driver is unusable on Windows regardless.
skip_all "stub servers require a POSIX shell (#!/bin/sh), unavailable on $^O"
    if $^O eq 'MSWin32';

my $dir = tempdir(CLEANUP => 1);

sub stub_at {
    my ($path, $version_line) = @_;
    open(my $fh, '>', $path) or die "Could not write stub: $!";
    print $fh "#!/bin/sh\necho \"$version_line\"\n";
    close($fh);
    chmod(0755, $path);
    return $path;
}

sub stub_bin {
    my ($name, $version_line) = @_;
    return stub_at("$dir/$name", $version_line);
}

my $broken122  = stub_bin(broken122  => 'mariadbd  Ver 12.2.2-MariaDB for linux-systemd on x86_64 (MariaDB Server)');
my $broken1011 = stub_bin(broken1011 => 'mariadbd  Ver 10.11.16-MariaDB for Linux on x86_64 (MariaDB Server)');
my $fixed123   = stub_bin(fixed123   => 'mariadbd  Ver 12.3.2-MariaDB for Linux on x86_64 (MariaDB Server)');
my $old1011    = stub_bin(old1011    => 'mariadbd  Ver 10.11.15-MariaDB for Linux on x86_64 (MariaDB Server)');
my $mysql8     = stub_bin(mysql8     => 'mysqld  Ver 8.0.42 for Linux on x86_64 (MySQL Community Server - GPL)');

subtest provider_info_is_detached_from_parent_cache => sub {
    my $info   = $CLASS->provider_info;
    my $cached = DBIx::QuickDB::Driver::MySQL::provider_info($CLASS);

    ref_is_not($info, $cached, 'MariaDB provider_info does not expose the parent cache hash');
    is($info->{server_bin}, $cached->{server_bin}, 'detached copy carries the cached server');
    is($info->{client_bin}, $cached->{client_bin}, 'detached copy carries the cached client');

    # install_bin is deliberately not compared: replacing it with a helper
    # from the selected server's installation is what the override is for.
    $info->{install_bin} = 'MUTATED';
    isnt(
        DBIx::QuickDB::Driver::MySQL::provider_info($CLASS)->{install_bin},
        'MUTATED',
        'mutating the returned hash cannot corrupt the parent cache',
    );
};

subtest provider_info_requires_helper_from_selected_installation => sub {
    my $matched_root = "$dir/matched-install";
    make_path("$matched_root/bin", "$matched_root/scripts");

    my $matched_server = stub_at(
        "$matched_root/bin/mariadbd",
        'mariadbd  Ver 12.3.2-MariaDB for Linux on x86_64 (MariaDB Server)',
    );
    stub_at("$matched_root/bin/mariadb", 'mariadb client');
    my $matched_helper = stub_at(
        "$matched_root/scripts/mariadb-install-db",
        'MariaDB install helper',
    );

    {
        local $ENV{PATH} = "$matched_root/bin";
        my $info = Local::MariaDB::MatchedInstall->provider_info;

        is($info->{server_bin}, $matched_server, 'fake installation selects its server');
        is($info->{install_bin}, $matched_helper,
            'helper under the selected installation scripts directory is paired with the server');

        my ($ok, $why) = Local::MariaDB::MatchedInstall->viable({
            bootstrap => 1,
            load_sql  => 1,
        });
        ok($ok, 'bootstrap is viable with an executable helper from the selected installation')
            or diag($why);
    }

    my $selected_root = "$dir/selected-install";
    my $foreign_root  = "$dir/foreign-install";
    make_path("$selected_root/bin", "$foreign_root/bin");

    stub_at(
        "$selected_root/bin/mariadbd",
        'mariadbd  Ver 12.3.2-MariaDB for Linux on x86_64 (MariaDB Server)',
    );
    stub_at("$selected_root/bin/mariadb", 'mariadb client');
    stub_at("$foreign_root/bin/mariadb-install-db", 'foreign MariaDB install helper');

    {
        local $ENV{PATH} = join ':' => "$selected_root/bin", "$foreign_root/bin";
        my $info = Local::MariaDB::MismatchedInstall->provider_info;

        is($info->{install_bin}, undef,
            'helper from an unrelated installation is rejected');

        my ($ok, $why) = Local::MariaDB::MismatchedInstall->viable({
            bootstrap => 1,
            load_sql  => 1,
        });
        ok(!$ok, 'bootstrap is not viable with only a foreign helper');
        like(
            $why,
            qr/selected MariaDB installation \(\Q$selected_root\E\).*needed for bootstrap.*different installations are not used/,
            'reason names the selected installation and explains why the foreign helper is ignored',
        );
    }
};

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

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Driver::MariaDB::install_bin = sub { $fixed123 };

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

subtest bootstrap_requires_install_helper => sub {
    my $root = "$dir/server-only";
    mkdir($root) or die "Could not create server-only test directory: $!";

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Driver::MariaDB::provider_info = sub {
        return {server_bin => $fixed123, client_bin => $fixed123};
    };
    local *DBIx::QuickDB::Driver::MariaDB::install_bin = sub { undef };
    local *DBIx::QuickDB::Driver::MariaDB::dbd_driver = sub { 'DBD::Test' };

    my ($ok, $why) = $CLASS->viable({
        bootstrap => 1,
        load_sql  => 1,
        server    => $fixed123,
        client    => $fixed123,
    });
    ok(!$ok, 'bootstrap is not viable without an install helper');
    like(
        $why,
        qr/'mariadb-install-db'.*'mysql_install_db'.*selected MariaDB installation.*needed for bootstrap.*different installations are not used/,
        'nonviability reason explains the selected-installation bootstrap requirement',
    );

    ($ok, $why) = $CLASS->viable({
        autostart => 1,
        load_sql => 1,
        server   => $fixed123,
        client   => $fixed123,
    });
    ok($ok, 'autostart and load_sql remain viable without an install helper')
        or diag($why);

    my $db = $CLASS->new(
        dir    => $root,
        server => $fixed123,
        client => $fixed123,
    );

    my @commands;
    local *DBIx::QuickDB::Driver::MariaDB::run_command = sub {
        my ($self, $command) = @_;
        push @commands => [@$command];
        return;
    };

    my $warning = '';
    my $error = '';
    {
        local $SIG{__WARN__} = sub { $warning .= join '' => @_ };
        eval { $db->bootstrap; 1 } or $error = $@;
    }

    like(
        $error,
        qr/'mariadb-install-db'.*'mysql_install_db'.*selected MariaDB installation.*needed for bootstrap.*different installations are not used/,
        'a direct bootstrap call fails clearly when viability was bypassed',
    );
    is($warning, '', 'missing helper emits no warning');
    is(\@commands, [], 'missing helper runs no bootstrap command');
    ok(!-e "$root/data", 'missing helper creates no partial data directory');
    ok(!-e "$root/temp", 'missing helper creates no bootstrap temp directory');
    ok(!-e "$root/init.sql", 'missing helper creates no bootstrap SQL file');
    ok(!-e "$root/my.cfg", 'missing helper writes no bootstrap config');
};

subtest helper_bootstrap_avoids_version_specific_option => sub {
    my $root = "$dir/helper-bootstrap";
    mkdir($root) or die "Could not create helper test directory: $!";

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Driver::MariaDB::provider_info = sub {
        return {
            server_bin  => $fixed123,
            client_bin  => $fixed123,
            install_bin => $fixed123,
        };
    };
    local *DBIx::QuickDB::Driver::MariaDB::dbd_driver = sub { 'DBD::Test' };

    my $db = $CLASS->new(
        dir    => $root,
        server => $fixed123,
        client => $fixed123,
    );

    my @commands;
    local *DBIx::QuickDB::Driver::MariaDB::run_command = sub {
        my ($self, $command) = @_;
        push @commands => [@$command];
        return;
    };

    $db->bootstrap;

    is(scalar(@commands), 2, 'complete bootstrap runs the helper and bare server bootstrap');
    is($commands[0]->[0], $fixed123, 'first bootstrap command uses the selected helper');
    unlike(join(' ' => @{$commands[0]}), qr/--skip-test-db/,
        'helper invocation works on MariaDB releases older than 10.1');
    is($commands[1]->[-1], '--bootstrap', 'second command creates the QuickDB database');
};

done_testing;
