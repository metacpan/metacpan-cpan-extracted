#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: the control socket of the running daemon.
#
# The socket is where hapctl asks the daemon what it is doing. This
# file proves the boundary around it: it appears after the privilege
# drop, owned by _openhap and mode 0600 in a directory of mode 0700;
# a user who is neither root nor _openhap cannot reach it; a bad
# request is refused and the daemon stays up; and a clean shutdown
# removes it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use Fugu::Control;
use Fugu::Imsg;
use IO::Socket::UNIX;
use JSON::PP ();
use App::OpenHAP::Test::Integration;
use POSIX       ();
use Socket      qw(SOCK_STREAM);
use Time::HiRes qw(sleep);

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

my $socket = $env->get_config_value('control')
    // '/var/run/openhapd/control.sock';
my $dir = $socket =~ s{/[^/]+$}{}r;
my $hapctl = '/usr/local/bin/hapctl';

$env->ensure_daemon_running or die "cannot start openhapd\n";
$env->wait_for_hap_port     or die "daemon not serving\n";

# ------------------------------------------------------------------
# The boundary
# ------------------------------------------------------------------

ok( -S $socket, 'the control socket is there' ) or die "no socket at $socket\n";

my @sock_stat = stat $socket;
my @dir_stat  = stat $dir;

is( $sock_stat[2] & 07777, 0600, 'the socket is mode 0600' );
is( $dir_stat[2] & 07777,  0700, 'its directory is mode 0700' );

my $openhap_uid = getpwnam('_openhap');
ok( defined $openhap_uid, 'the _openhap user exists' );
is( $sock_stat[4], $openhap_uid, 'the socket belongs to _openhap' );
is( $dir_stat[4],  $openhap_uid, 'and so does its directory' );

# The daemon bound the socket after it dropped privileges. A
# root-owned socket would mean the bind happened too early.
isnt( $sock_stat[4], 0, 'the socket is not root-owned' );

# ------------------------------------------------------------------
# What the daemon answers
# ------------------------------------------------------------------

my $client = Fugu::Control::Client->new( path => $socket );

my $status = $client->request('status');
ok( defined $status, 'the daemon answers status' )
    or diag( $client->error // 'no error recorded' );
is( $status->{port},
	$env->get_config_value('hap_port') // 51827,
	'and it names the HAP port it serves' );
ok( defined $status->{config_number}, 'the configuration number is there' );
ok( exists $status->{paired},         'and the pairing state' );

my $devices = $client->request('devices');
is( ref $devices, 'ARRAY', 'the daemon answers devices with a list' );
is( scalar @$devices,
	$status->{devices},
	'and the count matches what status reported' );

# No reply carries a secret. The configuration holds the setup code
# and the broker password, and a control reply must carry neither.
my $json = JSON::PP->new->utf8->canonical;
my $all  = $json->encode( { status => $status, devices => $devices } );
for my $key (qw(hap_pin mqtt_pass)) {
	my $secret = $env->get_config_value($key);
	next unless defined $secret && length $secret;
	ok( index( $all, $secret ) < 0, "the replies carry no $key" );
}

# ------------------------------------------------------------------
# Bad input fails closed
# ------------------------------------------------------------------

is( $client->request('no-such-command'),
	undef, 'an unknown command is refused' );
like( $client->error, qr/unknown command/, 'and the reason says so' );

# A payload that is not JSON, sent by hand
my $raw = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $socket )
    or die "connect: $!";
my $imsg = Fugu::Imsg->new( fh => $raw );
$imsg->send(
	type   => Fugu::Control::TYPE_REQUEST(),
	peerid => 42,
	data   => 'not json at all',
);
my $frame = $imsg->recv( timeout => 5 );
ok( defined $frame, 'the daemon answered a malformed request' );
is( $frame->{type}, Fugu::Control::TYPE_ERROR(),
	'and the answer is an error frame' );
$imsg->close;

# The daemon is still up and still serving HAP
ok( $client->request('status'), 'the daemon survived the bad requests' );
ok( $env->wait_for_hap_port,    'and it still serves HAP' );
$client->disconnect;

# ------------------------------------------------------------------
# hapctl reads the socket, and creates nothing
# ------------------------------------------------------------------

# A directory scan before and after: a read-only command must not
# create a file anywhere it looks
my $db_path = $env->get_config_value('db_path') // '/var/db/openhapd';

# listing($path): the sorted names in a directory, or an empty list
sub listing ($path)
{
	opendir my $dh, $path or return ();
	my @names = sort grep { !/^\.\.?$/ } readdir $dh;
	closedir $dh;
	return @names;
}

my @db_before  = listing($db_path);
my @dir_before = listing($dir);

my $out = `$hapctl status 2>&1`;
like( $out, qr/openhapd is running/, 'hapctl status reads the socket' );
unlike( $out, qr{read from /var/run/openhapd\.pid},
	'and it did not fall back to the PID file' );

my $devices_out = `$hapctl devices 2>&1`;
like( $devices_out, qr/(Loaded devices|No devices loaded)/,
	'hapctl devices reads the socket too' );

is_deeply( [ listing($db_path) ], \@db_before,
	'hapctl created nothing in the state directory' );
is_deeply( [ listing($dir) ], \@dir_before,
	'and nothing beside the control socket' );

# ------------------------------------------------------------------
# An unprivileged user cannot reach it
# ------------------------------------------------------------------

# nobody is neither root nor _openhap, so the directory mode alone
# stops it. The drop happens in a forked child rather than through
# su(1): the shell of nobody is /sbin/nologin, and su would fail for
# that reason instead of the one under test.
sub run_as_nobody (@command)
{
	my ( undef, undef, $uid, $gid ) = getpwnam('nobody')
	    or die "no nobody user\n";

	pipe my $reader, my $writer or die "pipe: $!";

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		close $reader;
		open STDOUT, '>&', $writer or POSIX::_exit(127);
		open STDERR, '>&', \*STDOUT or POSIX::_exit(127);

		# The group goes first. A process that gave up root
		# cannot then change its group.
		$) = "$gid $gid";
		$( = $gid;
		$> = $uid;
		$< = $uid;
		POSIX::_exit(126) if $> == 0 || $< == 0;

		# The or form keeps perl from warning that the line
		# after an exec is unreachable
		exec { $command[0] } @command or POSIX::_exit(127);
	}
	close $writer;

	my $output = do { local $/; <$reader> };
	close $reader;
	waitpid $pid, 0;

	return $output // '';
}

my $as_nobody = run_as_nobody( $hapctl, 'status' );

like( $as_nobody, qr/openhapd is (not )?running/,
	'an unprivileged status still reports something' );
like( $as_nobody, qr{read from /var/run/openhapd\.pid},
	'and it says the answer came from the PID file' );
like( $as_nobody, qr/Permission denied/,
	'the reason is the permission, not an absent daemon' );
unlike( $as_nobody, qr/Configuration num:/,
	'it saw nothing that only the daemon knows' );

# ------------------------------------------------------------------
# A clean shutdown removes it
# ------------------------------------------------------------------

system('rcctl stop openhapd >/dev/null 2>&1');

my $deadline = time + 30;
sleep 0.5 while -e $socket && time < $deadline;
ok( !-e $socket, 'a clean shutdown removes the socket' );
ok( -d $dir,     'the directory stays' );

# The daemon takes the name again at the next start
system('rcctl start openhapd >/dev/null 2>&1');
$env->wait_for_hap_port or die "daemon not serving after restart\n";
ok( -S $socket, 'and the next start binds it again' );

$env->teardown;
done_testing();
