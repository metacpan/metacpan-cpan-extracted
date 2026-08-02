use FindBin qw/$Bin/;
use lib "$Bin/lib";
use QDB::Installs qw/run_per_install/;    # before Test2::V0: it loads Test2::IPC
use Test2::V0;

# The parent process must not load DBIx::QuickDB or its drivers.  Each body
# runs in a child that selects one MariaDB installation via PATH first.  See
# t/lib/QDB/Installs.pm.
run_per_install(MariaDB => sub {
    require Capture::Tiny;
    require DBIx::QuickDB;
    require Test2::Tools::QuickDB;
    require File::Basename;

    Test2::Tools::QuickDB::skipall_unless_can_db(driver => 'MariaDB');
    skip_all 'selected MariaDB installation has no matching install helper for complete system tables'
        unless DBIx::QuickDB::Driver::MariaDB->install_bin;

    my ($db, $dbh, $version, $trigger_count, $touched, $run_error);

    my $stderr = Capture::Tiny::capture_stderr(sub {
        my $ok = eval {
            $db = DBIx::QuickDB->build_db({
                driver       => 'MariaDB',
                fast_destroy => 1,
            });

            $dbh = $db->connect(
                'quickdb',
                RaiseError => 1,
                PrintError => 0,
            );

            ($version) = $dbh->selectrow_array('SELECT VERSION()');
            $dbh->do(q{
                CREATE TABLE trigger_probe (
                    id      INTEGER PRIMARY KEY,
                    touched INTEGER NOT NULL DEFAULT 0
                )
            });
            $dbh->do(q{
                CREATE TRIGGER trigger_probe_bi
                BEFORE INSERT ON trigger_probe
                FOR EACH ROW SET NEW.touched = 1
            });
            $dbh->do('INSERT INTO trigger_probe (id) VALUES (1)');

            ($touched) = $dbh->selectrow_array(
                'SELECT touched FROM trigger_probe WHERE id = 1'
            );
            ($trigger_count) = $dbh->selectrow_array(q{
                SELECT COUNT(*)
                  FROM information_schema.triggers
                 WHERE trigger_schema = DATABASE()
                   AND trigger_name = 'trigger_probe_bi'
            });

            1;
        };
        $run_error = $@ unless $ok;
    });

    # The watcher inherits fd 2. Keep teardown outside the capture so a slow
    # shutdown warning cannot make the bootstrap/trigger assertion flaky.
    eval { $dbh->disconnect } if $dbh;
    if ($db) {
        my $clean = eval { $db->destroy_quietly; 1 };
        $run_error .= $@ unless $clean;
    }

    Test2::Tools::QuickDB::skipall_on_resource_error($run_error)
        if $run_error;

    ok(!$run_error, "MariaDB bootstrap supports triggers ($version)")
        or diag($run_error);

    if (!$run_error) {
        my $server_root = File::Basename::dirname(
            File::Basename::dirname($db->server_bin)
        );
        my $helper_root = File::Basename::dirname(
            File::Basename::dirname($db->install_bin)
        );

        is($helper_root, $server_root,
            'bootstrap helper comes from the selected MariaDB installation');
        is($touched, 1, 'created trigger ran');
        is($trigger_count, 1,
            'information_schema.triggers contains the created trigger');
    }

    is($stderr, '', 'bootstrap, trigger DDL, and introspection emitted no unexpected stderr');
});

done_testing;
