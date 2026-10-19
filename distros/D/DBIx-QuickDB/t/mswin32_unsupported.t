use Test2::V0;

use DBIx::QuickDB::Watcher;
use DBIx::QuickDB::Driver::PostgreSQL;
use DBIx::QuickDB::Driver::MariaDB;
use DBIx::QuickDB::Driver::MySQLCom;
use DBIx::QuickDB::Driver::Percona;

# Server drivers need the Unix watcher; on MSWin32 they must say so instead of
# crashing in the pseudo-forked watcher.
my @drivers = map { "DBIx::QuickDB::Driver::$_" } qw/PostgreSQL MariaDB MySQLCom Percona/;

for my $class (@drivers) {
    subtest $class => sub {
        {
            local $^O = 'MSWin32';
            my ($ok, $why) = $class->viable({bootstrap => 1, autostart => 1});
            ok(!$ok, 'not viable on MSWin32');
            like($why, qr/not supported on MSWin32/, 'reason names the platform');

            ($ok, $why) = $class->viable({});
            unlike($why // '', qr/not supported on MSWin32/, 'no server needed, no refusal');
        }

        {
            local $^O = 'linux';
            my ($ok, $why) = $class->viable({bootstrap => 1, autostart => 1});
            unlike($why // '', qr/not supported on MSWin32/, 'never refused for it elsewhere');
        }
    };
}

subtest watcher_refuses_before_forking => sub {
    local $^O = 'MSWin32';
    # Owned by no live process, so its DESTROY has nothing to tear down.
    my $watcher = bless({master_pid => 0}, 'DBIx::QuickDB::Watcher');
    like(
        dies { $watcher->start },
        qr/not supported on MSWin32/,
        'start croaks instead of pseudo-forking',
    );
};

done_testing;
