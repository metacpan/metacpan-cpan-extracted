#!perl

# Protocol edge cases: input fragmentation and reassembly, line
# framing, and the validation boundaries of the wire protocol.

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	plan skip_all => 'unix domain sockets and fork required'
		if $^O eq 'MSWin32';
}

use lib 't/lib';
use Time::HiRes     qw(sleep);
use Sukkal_TestUtil qw(spawn_daemon connect_daemon read_line req req_multi stop_daemon);

$SIG{PIPE} = 'IGNORE';
alarm 120;    # watchdog: a hung daemon must fail the test, not the harness

my $d    = spawn_daemon( window => 5, max_key_length => 10 );
my $sock = connect_daemon($d);

#
# a command split across two writes is reassembled from the read buffer
#
print $sock 'MARK fr';
sleep 0.25;    # let the daemon read the fragment on its own
print $sock "ag 3\nCOUNT frag\n";
is( read_line($sock), 'OK 3', 'command fragmented across writes is reassembled' );

#
# one byte per write: reassembly across many reads
#
for my $byte ( split //, "COUNT frag\n" ) {
	print $sock $byte;
	sleep 0.02;
}
is( read_line($sock), 'OK 3', 'command dribbled a byte at a time is reassembled' );

#
# blank and whitespace-only lines are skipped without a reply;
# commands are case-insensitive and tolerate CRLF
#
print $sock "\n   \nping\r\n";
is( read_line($sock),     'OK PONG', 'blank lines skipped; lowercase command with CRLF accepted' );
is( req( $sock, 'PING' ), 'OK PONG', 'connection still in sync afterwards' );

#
# count boundaries: 15 digits is the documented ceiling
#
print $sock "MARK big 100000000000000\n";
is( req( $sock, 'TOTAL big' ), 'OK 100000000000000', '15-digit count accepted' );
like( req( $sock, 'MARK big 1000000000000000' ), qr/^ERR bad count/, '16-digit count rejected' );
like( req( $sock, 'MARK big 0' ),                qr/^ERR bad count/, 'MARK count of 0 rejected' );
like( req( $sock, 'MARKRATE big 0' ),            qr/^ERR bad count/, 'MARKRATE count of 0 rejected' );

#
# key length boundary at max_key_length (10 here)
#
print $sock 'MARK ', 'k' x 10, "\n";
is( req( $sock, 'COUNT ' . 'k' x 10 ), 'OK 1', 'key exactly at max_key_length accepted' );
like( req( $sock, 'MARK ' . 'k' x 11 ),  qr/^ERR bad key/, 'key one over max_key_length rejected' );
like( req( $sock, 'COUNT ' . 'k' x 11 ), qr/^ERR bad key/, 'query with an oversized key rejected' );

#
# keys may hold any high-bit bytes
#
my $key = "caf\xC3\xA9";
print $sock "MARK $key\n";
is( req( $sock, "COUNT $key" ), 'OK 1', 'high-bit bytes are legal in keys' );

#
# a partial line pending at EOF is discarded, never applied
#
{
	my $c = connect_daemon($d);
	print $c 'MARK ghost 5';    # no newline
	close $c;
	sleep 0.25;
	my ( $hdr, @keys ) = req_multi( $sock, 'KEYS' );
	ok( !grep( { $_ eq 'ghost' } @keys ), 'partial line at EOF is discarded, not applied' );
}

#
# commands pipelined after QUIT are not processed
#
{
	my $c = connect_daemon($d);
	print $c "PING\nQUIT\nPING\n";
	is( read_line($c), 'OK PONG', 'reply to the command before a pipelined QUIT' );
	is( read_line($c), 'OK BYE',  'QUIT acknowledged mid-pipeline' );
	is( read_line($c), undef,     'commands pipelined after QUIT are dropped with the connection' );
}

#
# a single line larger than the read buffer ceiling is rejected and
# the connection dropped
#
{
	my $c    = connect_daemon($d);
	my $junk = 'x' x ( 2 * 1024 * 1024 );    # 2 MB, no newline
	my $off  = 0;
	while ( $off < length $junk ) {
		my $n = syswrite $c, $junk, 65536, $off;
		last unless defined $n;              # daemon dropped us mid-write
		$off += $n;
	}
	is( read_line($c), 'ERR line too long', 'oversized line without a newline is rejected' );
	is( read_line($c), undef,               'and the connection is dropped' );
}

# the daemon survived all of the above
is( req( $sock, 'PING' ), 'OK PONG', 'daemon still serving after the abuse' );

is( stop_daemon($d), 0, 'daemon exited cleanly' );

done_testing();
