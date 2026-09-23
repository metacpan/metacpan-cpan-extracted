#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Socket
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Socket;
use IO::Handle;
use Data::Tools::Socket;

ok( defined $Data::Tools::Socket::VERSION, 'Data::Tools::Socket loaded' );

my $TIMEOUT = 10;

sub make_pair
{
  socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or return ();
  $a->autoflush( 1 );
  $b->autoflush( 1 );
  return ( $a, $b );
}

my ( $A, $B ) = make_pair();
plan( skip_all => "socketpair() is not available: $!" ) unless $A;

##############################################################################
# socket_can_read() / socket_can_write()
##############################################################################

ok(   socket_can_write( $A, $TIMEOUT ), 'socket_can_write() on an idle socket' );
ok( ! socket_can_read(  $B, 0 ),        'socket_can_read() is false with no pending data' );

##############################################################################
# socket_write() / socket_read() / socket_print()
##############################################################################

is( socket_print( $A, 'hello', $TIMEOUT ), 5, 'socket_print() returns bytes written' );

ok( socket_can_read( $B, $TIMEOUT ), 'socket_can_read() is true with pending data' );

my $data;
is( socket_read( $B, \$data, 5, $TIMEOUT ), 5, 'socket_read() returns bytes read' );
is( $data, 'hello', 'socket_read() returned the data' );

is( socket_write( $A, 'abcdef', 6, $TIMEOUT ), 6, 'socket_write() returns bytes written' );
socket_read( $B, \$data, 6, $TIMEOUT );
is( $data, 'abcdef', 'socket_write()/socket_read() round trip' );

# partial write: only the given length is sent
socket_write( $A, 'abcdef', 3, $TIMEOUT );
socket_read( $B, \$data, 3, $TIMEOUT );
is( $data, 'abc', 'socket_write() honours the given length' );

# binary data survives untouched
my $bin = join '', map { chr } 0 .. 255;
socket_write( $A, $bin, length( $bin ), $TIMEOUT );
socket_read( $B, \$data, length( $bin ), $TIMEOUT );
is( $data, $bin, 'socket_write()/socket_read() are binary clean' );

##############################################################################
# socket_read() timing out
##############################################################################

is( socket_read( $B, \$data, 1, 1 ), undef, 'socket_read() returns undef on timeout' );

##############################################################################
# socket_write_message() / socket_read_message()
##############################################################################

ok( socket_write_message( $A, 'message here', $TIMEOUT ), 'socket_write_message()' );

my ( $msg, $len, $err ) = socket_read_message( $B, $TIMEOUT );
is( $msg, 'message here', 'socket_read_message() returned the message' );
is( $len, 12,             'socket_read_message() returned the length' );
is( $err, undef,          'socket_read_message() reported no error' );

socket_write_message( $A, 'scalar context', $TIMEOUT );
is( scalar socket_read_message( $B, $TIMEOUT ), 'scalar context',
    'socket_read_message() in scalar context returns the data' );

# empty message
ok( socket_write_message( $A, '', $TIMEOUT ), 'socket_write_message() with empty data' );
my ( $emsg, $elen, $eerr ) = socket_read_message( $B, $TIMEOUT );
is( $emsg, '',    'socket_read_message() returns empty string for empty message' );
is( $elen, 0,     'socket_read_message() returns zero length for empty message' );
is( $eerr, undef, 'socket_read_message() reports no error for empty message' );

# big message, spanning several reads
my $big = 'x' x 100_000; # must stay below the socket buffer size, nobody reads concurrently
ok( socket_write_message( $A, $big, $TIMEOUT ), 'socket_write_message() with a big message' );
is( scalar socket_read_message( $B, $TIMEOUT ), $big, 'socket_read_message() reassembles a big message' );

##############################################################################
# socket_read_message() error reporting
##############################################################################

# maxlen smaller than the incoming message
socket_write_message( $A, 'too long for maxlen', $TIMEOUT );
my ( undef, undef, $mlerr ) = socket_read_message( $B, $TIMEOUT, 4 );
is( $mlerr, 'E_MSGLEN', 'socket_read_message() reports E_MSGLEN when over maxlen' );

# closed socket: end of communication
my ( $C, $D ) = make_pair();
close( $C );
my ( undef, undef, $eoferr ) = socket_read_message( $D, $TIMEOUT );
is( $eoferr, 'E_EOF', 'socket_read_message() reports E_EOF on a closed socket' );
close( $D );

# truncated length header -- socket_read() gives up on the short read, so this
# surfaces as end of communication rather than a bad length
my ( $E, $F ) = make_pair();
socket_print( $E, "\x00\x00", $TIMEOUT );
close( $E );
my ( undef, undef, $lenerr ) = socket_read_message( $F, $TIMEOUT );
is( $lenerr, 'E_EOF', 'socket_read_message() reports E_EOF on a truncated header' );
close( $F );

# announced length larger than what actually arrives
my ( $G, $H ) = make_pair();
socket_print( $G, pack( 'N', 10 ) . 'short', $TIMEOUT );
close( $G );
my ( undef, undef, $shorterr ) = socket_read_message( $H, $TIMEOUT );
is( $shorterr, 'E_SHORTREAD', 'socket_read_message() reports E_SHORTREAD on a truncated body' );
close( $H );

close( $A );
close( $B );

##############################################################################

done_testing();
