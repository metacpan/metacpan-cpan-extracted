use Test2::V0;
use File::Temp qw/tempdir/;
use IO::Socket::UNIX;
use Time::HiRes qw/time/;

use DBIx::QuickDB::Driver::PostgreSQL;
use DBIx::QuickDB::Driver::MySQLCom;

# Server drivers confirm a fresh start with a real connection; these stub the
# server side so no database is needed.
my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

my %waits;
my $mock = mock 'DBIx::QuickDB::Driver' => (
    override => [
        start             => sub { return },
        _wait_for_connect => sub { $waits{ref($_[0])}++; return },
    ],
);

for my $class (qw/DBIx::QuickDB::Driver::PostgreSQL DBIx::QuickDB::Driver::MySQLCom/) {
    subtest $class => sub {
        my $db      = bless {}, $class;
        my $started = 0;
        my $smock   = mock $class => (override => [started => sub { $started }]);

        %waits = ();
        $db->start;
        is($waits{$class}, 1, 'a fresh start waits for a connection');

        $started = 1;
        $db->start;
        is($waits{$class}, 1, 'start on a running server stays a no-op');
    };
}

$mock = undef;

subtest wait_stops_when_the_server_exits => sub {
    skip_all "needs a Unix-domain socket, not available on $^O" if $^O eq 'MSWin32';

    # A live socket keeps the socket check from ending the wait, so only the
    # recorded exit status can end it before QDB_START_TIMEOUT.
    my $socket   = "$dir/sock";
    my $listener = IO::Socket::UNIX->new(Local => $socket, Listen => 1) or die "listen: $!";

    my $db = bless {
        +DBIx::QuickDB::Driver::DIR()           => $dir,
        +DBIx::QuickDB::Driver::MySQL::SOCKET() => $socket,
        },
        'DBIx::QuickDB::Driver::MySQLCom';

    my $exited = 0;
    my $base   = mock 'DBIx::QuickDB::Driver' => (
        override => [
            connect             => sub { $exited = 1; die "Can't connect to local server (61)\n" },
            _server_exit_status => sub { $exited ? 'exit value 1' : undef },
            read_error_log      => sub { '' },
        ],
    );

    local $ENV{QDB_START_TIMEOUT} = 30;
    my $start = time;
    like(
        dies { $db->_wait_for_connect('mysql') },
        qr/\(61\)/,
        'the last connect error is reported',
    );
    ok(time - $start < 5, 'gave up as soon as the server had exited');
};

done_testing;
