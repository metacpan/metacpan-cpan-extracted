#!perl

# Daemon lifecycle: constructor validation, socket path handling,
# socket permissions, the client cap, concurrent multiplexing of
# multiple clients, and idle-key eviction.

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => 'unix domain sockets and fork required'
		if $^O eq 'MSWin32';
}

use lib 't/lib';
use File::Temp  qw(tempdir);
use Time::HiRes qw(sleep);
use Algorithm::EventsPerSecond::Sukkal;
use Sukkal_TestUtil qw(spawn_daemon connect_daemon read_line req req_multi stop_daemon);

alarm 120;    # watchdog: a hung daemon must fail the test, not the harness

sub new_dies {
	my ( $desc, $err_re, %args ) = @_;
	ok( !eval { Algorithm::EventsPerSecond::Sukkal->new(%args); 1 }, $desc );
	like( $@, $err_re, "...$desc message" );
	return;
}

#
# constructor validation; new() never touches the filesystem, so a
# placeholder path is fine
#
my $ph = '/nonexistent/placeholder.sock';

new_dies( 'missing socket dies', qr/socket path required/ );
new_dies( 'empty socket dies', qr/socket path required/, socket => '' );

new_dies( 'window of 0 dies',        qr/window must be a positive integer/, socket => $ph, window => 0 );
new_dies( 'non-numeric window dies', qr/window must be a positive integer/, socket => $ph, window => 'abc' );
new_dies(
	'sweep_interval of 0 dies', qr/sweep_interval must be a positive integer/,
	socket         => $ph,
	sweep_interval => 0
);
new_dies(
	'listen_backlog of 0 dies', qr/listen_backlog must be a positive integer/,
	socket         => $ph,
	listen_backlog => 0
);
new_dies( 'negative max_keys dies', qr/max_keys must be a non-negative integer/, socket => $ph, max_keys => -1 );
new_dies(
	'negative max_clients dies',
	qr/max_clients must be a non-negative integer/,
	socket      => $ph,
	max_clients => -1
);
new_dies(
	'idle_timeout below the window dies',
	qr/idle_timeout must be an integer >= window/,
	socket       => $ph,
	window       => 10,
	idle_timeout => 9
);
new_dies( 'bad socket_mode dies', qr/socket_mode must be an octal string/, socket => $ph, socket_mode => 'rwx' );
new_dies(
	'socket_mode with digits over 7 dies',
	qr/socket_mode must be an octal string/,
	socket      => $ph,
	socket_mode => '0980'
);

ok( eval { Algorithm::EventsPerSecond::Sukkal->new( socket => $ph, window => 10, idle_timeout => 10 ); 1 },
	'idle_timeout equal to the window is accepted' );
ok( eval { Algorithm::EventsPerSecond::Sukkal->new( socket => $ph, socket_mode => '770' ); 1 },
	'socket_mode without a leading zero is accepted' );
ok( eval { Algorithm::EventsPerSecond::Sukkal->new( socket => $ph, max_keys => 0, max_clients => 0 ); 1 },
	'0 accepted as unlimited for max_keys and max_clients' );

#
# a regular file at the socket path is refused
#
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $file = "$dir/notasock";
	open my $fh, '>', $file or die "cannot create $file: $!";
	close $fh;

	my $d = Algorithm::EventsPerSecond::Sukkal->new( socket => $file );
	ok( !eval { $d->run; 1 }, 'run dies when the path is a regular file' );
	like( $@, qr/exists and is not a socket/, '...run regular-file message' );
	ok( -f $file, 'the file is left untouched' );
}

#
# a live listener on the path is refused; a stale socket left by a
# dead daemon is reclaimed
#
{
	my $live = spawn_daemon();

	my $d2 = Algorithm::EventsPerSecond::Sukkal->new( socket => $live->{path} );
	ok( !eval { $d2->run; 1 }, 'run dies when something is already listening' );
	like( $@, qr/already listening/, '...run live-listener message' );

	kill 'KILL', $live->{pid};    # die without cleanup
	waitpid $live->{pid}, 0;
	ok( -S $live->{path}, 'socket file left behind by the killed daemon' );

	my $d3 = spawn_daemon( socket => $live->{path} );
	my $s3 = connect_daemon($d3);
	is( req( $s3, 'PING' ), 'OK PONG', 'new daemon reclaimed the stale socket' );
	is( stop_daemon($d3),   0,         'reclaiming daemon exits cleanly' );
	ok( !-e $live->{path}, 'socket unlinked on shutdown' );
}

#
# socket_mode is applied to the socket file
#
{
	my $d = spawn_daemon( socket_mode => '0700' );
	is( ( stat $d->{path} )[2] & oct('07777'), oct('0700'), 'socket_mode applied to the socket file' );
	stop_daemon($d);
}

#
# max_clients: connections over the cap are closed immediately, and a
# freed slot becomes usable again
#
{
	my $d = spawn_daemon( max_clients => 2 );

	my $a = connect_daemon($d);
	is( req( $a, 'PING' ), 'OK PONG', 'first client served' );
	my $b = connect_daemon($d);
	is( req( $b, 'PING' ), 'OK PONG', 'second client served' );

	like( req( $a, 'STATS' ), qr/\bclients=2\b/, 'STATS counts both clients' );

	my $over = connect_daemon($d);
	is( read_line($over), undef, 'client over max_clients is closed immediately' );

	is( req( $a, 'PING' ), 'OK PONG', 'existing clients unaffected by the rejected one' );

	close $b;
	my $served;
	for ( 1 .. 100 ) {    # the daemon frees the slot when it notices the EOF
		my $again = connect_daemon($d);
		my $reply = req( $again, 'PING' );
		close $again;
		if ( defined $reply && $reply eq 'OK PONG' ) { $served = 1; last }
		sleep 0.1;
	}
	ok( $served, 'slot freed after a client disconnects' );

	stop_daemon($d);
}

#
# two connections driven with interleaved, pipelined traffic: each
# gets its own replies, in the order it asked, on its own socket --
# no cross-talk between the multiplexed clients
#
{
	my $d = spawn_daemon;

	my $a = connect_daemon($d);
	my $b = connect_daemon($d);

	# intermix the writes on the wire: A marks alpha, B marks beta,
	# back and forth. MARK is fire-and-forget, so nothing to read yet.
	for ( 1 .. 20 ) {
		print $a "MARK alpha\n";
		print $b "MARK beta 2\n";
	}

	# each connection pipelines a query then a PING; replies must come
	# back on the asking socket, in the order that connection asked. A
	# connection's own marks always precede its own query (same buffer,
	# processed in order), so each sees its full count. Cross-connection
	# ordering within a select pass is deliberately not relied on.
	print $a "COUNT alpha\n";
	print $a "PING\n";
	print $b "COUNT beta\n";
	print $b "PING\n";

	is( read_line($a), 'OK 20',   'A: COUNT reflects its own 20 alpha marks' );
	is( read_line($a), 'OK PONG', 'A: PING answered next, in order, on A' );
	is( read_line($b), 'OK 40',   'B: COUNT reflects its own 40 beta marks' );
	is( read_line($b), 'OK PONG', 'B: PING answered next, in order, on B' );

	# a tighter interleave: if replies were misrouted, A's PONG could
	# surface on B. Confirm each PING is answered on its own socket.
	print $a "PING\n";
	print $b "PING\n";
	print $b "PING\n";
	print $a "PING\n";

	is( read_line($a), 'OK PONG', 'A: PING answered on A' );
	is( read_line($a), 'OK PONG', 'A: second PING answered on A' );
	is( read_line($b), 'OK PONG', 'B: PING answered on B' );
	is( read_line($b), 'OK PONG', 'B: second PING answered on B' );

	like( req( $a, 'STATS' ), qr/\bclients=2\b/, 'both connections live at once' );

	close $a;
	close $b;
	stop_daemon($d);
}

#
# idle keys are evicted by the sweep, and eviction forgets the
# lifetime total, as documented
#
{
	my $d = spawn_daemon( window => 1, idle_timeout => 1, sweep_interval => 1 );
	my $s = connect_daemon($d);

	print $s "MARK doomed 7\n";
	my ($hdr) = req_multi( $s, 'KEYS' );
	is( $hdr, 'OK 1', 'key tracked after mark' );

	my $gone;
	for ( 1 .. 100 ) {    # eviction is due ~2s after the mark
		($hdr) = req_multi( $s, 'KEYS' );
		if ( $hdr eq 'OK 0' ) { $gone = 1; last }
		sleep 0.1;
	}
	ok( $gone, 'idle key evicted by the sweep' );
	is( req( $s, 'TOTAL doomed' ), 'OK 0', 'lifetime total is forgotten with the eviction' );

	is( stop_daemon($d), 0, 'sweep daemon exits cleanly' );
}

done_testing();
