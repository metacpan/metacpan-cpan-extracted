#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => 'unix domain sockets and fork required'
		if $^O eq 'MSWin32';
}

use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Socket      qw(SOCK_STREAM);
use POSIX       ();
use Time::HiRes qw(sleep);
use Algorithm::EventsPerSecond::Sukkal;

my $dir  = tempdir( CLEANUP => 1 );
my $path = "$dir/sukkal.sock";

my $pid = fork;
die "fork failed: $!" unless defined $pid;

if ( $pid == 0 ) {
	# daemon child; _exit so the parent's Test::More END block does
	# not run twice
	my $ok = eval {
		my $d = Algorithm::EventsPerSecond::Sukkal->new(
			socket   => $path,
			window   => 5,
			max_keys => 4,
		);
		$SIG{TERM} = sub { $d->stop };
		$d->run;
		1;
	};
	warn $@ if !$ok;
	POSIX::_exit( $ok ? 0 : 1 );
} ## end if ( $pid == 0 )

my $sock;
for ( 1 .. 100 ) {
	last if $sock = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $path );
	sleep 0.1;
}
if ( !$sock ) {
	kill 'KILL', $pid;
	waitpid $pid, 0;
	BAIL_OUT("daemon did not come up on $path");
}
ok( $sock, 'connected to daemon socket' );

# send a command, read its single-line reply
sub req {
	my ($cmd) = @_;
	print $sock "$cmd\n";
	my $line = <$sock>;
	return undef unless defined $line;
	$line =~ s/\r?\n\z//;
	return $line;
}

# send a command with a multi-line reply; returns (header, lines up to END)
sub req_multi {
	my ($cmd) = @_;
	print $sock "$cmd\n";
	my $hdr = <$sock>;
	$hdr =~ s/\r?\n\z//;
	my @lines;
	while ( my $l = <$sock> ) {
		$l =~ s/\r?\n\z//;
		last if $l eq 'END';
		push @lines, $l;
	}
	return ( $hdr, @lines );
} ## end sub req_multi

is( req('PING'), 'OK PONG', 'PING' );
like( req('STATS'), qr/^OK keys=0 clients=1 /, 'daemon STATS while empty' );

print $sock "MARK foo\nMARK foo 4\n";
is( req('COUNT foo'), 'OK 5', 'pipelined marks coalesced and counted' );
is( req('TOTAL foo'), 'OK 5', 'TOTAL' );

# rate uses elapsed lifetime while younger than the window, so give the
# meter a second of life before expecting a non-zero rate
sleep 1;
my ($rate) = ( req('RATE foo') || '' ) =~ /^OK (\S+)\z/;
ok( defined $rate && $rate > 0, 'RATE is positive' );

is( req('RATE nosuch'),  'OK 0', 'unknown key rate reads as zero' );
is( req('COUNT nosuch'), 'OK 0', 'unknown key count reads as zero' );

like( req('STATS foo'), qr/^OK rate=\S+ count=5 total=5 window=5\z/, 'per-key STATS' );

like( req('MARK foo abc'),        qr/^ERR bad count/,       'bad count rejected' );
like( req( 'MARK ' . 'x' x 300 ), qr/^ERR bad key/,         'oversized key rejected' );
like( req("MARK bad\tkey"),       qr/^ERR /,                'whitespace in key rejected' );
like( req('BOGUS'),               qr/^ERR unknown command/, 'unknown command' );

# max_keys is 4: foo plus these three fills it
print $sock "MARK a\nMARK b\nMARK c\n";
like( req('MARK d'), qr/^ERR key limit/, 'key limit enforced' );

my ( $hdr, @keys ) = req_multi('KEYS');
is( $hdr, 'OK 4', 'KEYS header' );
is_deeply( \@keys, [qw(a b c foo)], 'KEYS lists all keys sorted' );

( $hdr, my @rows ) = req_multi('DUMP');
is( $hdr, 'OK 4', 'DUMP header' );
like( $rows[3], qr/^foo \S+ 5 5\z/, 'DUMP row for foo' );

is( req('RESET foo'), 'OK',   'RESET' );
is( req('TOTAL foo'), 'OK 0', 'total zeroed by RESET' );

is( req('DEL a'), 'OK', 'DEL' );
($hdr) = req_multi('KEYS');
is( $hdr, 'OK 3', 'key gone after DEL' );

# a slot is free again: fresh key with marks and query in one write
print $sock "MARK d 2\nMARK d 3\nCOUNT d\n";
my $reply = <$sock>;
$reply =~ s/\r?\n\z//;
is( $reply, 'OK 5', 'marks flushed before pipelined query on new key' );

# MARKRATE: mark and query in a single round trip. foo's clock was
# restarted by RESET above, so give it a second of life first, as the
# rate reply is count over elapsed while younger than the window
sleep 1;
my ($mrate) = ( req('MARKRATE foo 2') || '' ) =~ /^OK (\S+)\z/;
ok( defined $mrate && $mrate > 0, 'MARKRATE replies a positive rate' );
is( req('COUNT foo'), 'OK 2', 'MARKRATE recorded the marks' );

# pipelined marks must land before the MARKRATE mark-and-read
print $sock "MARK foo 3\nMARKRATE foo\n";
my $mr = <$sock>;
like( $mr, qr/^OK \S+/, 'pipelined MARKRATE replies' );
is( req('COUNT foo'), 'OK 6', 'pipelined marks flushed before MARKRATE' );

like( req('MARKRATE foo abc'), qr/^ERR bad count/, 'MARKRATE bad count rejected' );
like( req('MARKRATE'),         qr/^ERR bad key/,   'MARKRATE missing key rejected' );

# b c d foo fill max_keys, so a new key via MARKRATE is refused
like( req('MARKRATE e'), qr/^ERR key limit/, 'MARKRATE honors key limit' );

print $sock "QUIT\n";
my $bye = <$sock>;
$bye =~ s/\r?\n\z// if defined $bye;
is( $bye,           'OK BYE', 'QUIT acknowledged' );
is( scalar <$sock>, undef,    'connection closed after QUIT' );

$sock = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $path );
ok( $sock, 'reconnected' );
is( req('PING'), 'OK PONG', 'daemon still serving' );

kill 'TERM', $pid;
waitpid $pid, 0;
is( $? >> 8, 0, 'daemon exited cleanly on SIGTERM' );
ok( !-e $path, 'socket unlinked on shutdown' );

done_testing();
