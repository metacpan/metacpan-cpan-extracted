#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Socket::Protocols
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
use Data::Tools;
use Data::Tools::Socket;
use Data::Tools::Socket::Protocols;

ok( defined $Data::Tools::Socket::Protocols::VERSION, 'Data::Tools::Socket::Protocols loaded' );

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
# protocol types and the modules they need
#   'b' binary        -- no module needed
#   'h' hash2str      -- no module needed
#   'H' hash2str_url  -- no module needed
#   'p' Storable      -- core
#   'j' JSON
#   'e' Sereal        -- optional
#   's' Data::Stacker -- optional
#   'x' XML::Simple   -- optional
##############################################################################

my %NEEDS = (
            'b' => undef,
            'h' => undef,
            'H' => undef,
            'p' => 'Storable',
            'j' => 'JSON',
            'e' => 'Sereal',
            's' => 'Data::Stacker',
            'x' => 'XML::Simple',
            );

##############################################################################
# round trip of a hash through every available protocol
##############################################################################

my $HR = { alpha => 'one', beta => 'two words', gamma => '3' };

for my $ptype ( sort keys %NEEDS )
{
  next if $ptype eq 'b'; # binary carries plain data, tested separately

  SKIP:
  {
    my $need = $NEEDS{ $ptype };
    if( $need )
      {
      eval { my $fn = perl_package_to_file( $need ); require $fn; };
      skip( "$need is not installed, protocol '$ptype' unavailable", 3 ) if $@;
      }

    ok( socket_protocol_write_message( $A, $ptype, $HR, $TIMEOUT ),
        "socket_protocol_write_message() protocol '$ptype'" );

    my ( $got, $got_type, $err ) = socket_protocol_read_message( $B, $TIMEOUT );

    is( $got_type, $ptype, "socket_protocol_read_message() reports protocol '$ptype'" );
    is_deeply( $got, $HR,  "protocol '$ptype' round trip" );
  }
}

##############################################################################
# binary protocol carries plain data, not a hash
##############################################################################

ok( socket_protocol_write_message( $A, 'b', 'plain binary payload', $TIMEOUT ),
    "socket_protocol_write_message() protocol 'b'" );

my ( $bin, $bin_type, $bin_err ) = socket_protocol_read_message( $B, $TIMEOUT );
is( $bin_type, 'b',                      "socket_protocol_read_message() reports protocol 'b'" );
is( $bin, 'plain binary payload',        "protocol 'b' round trip" );
is( $bin_err, undef,                     "protocol 'b' reports no error" );

my $raw = join '', map { chr } 0 .. 255;
socket_protocol_write_message( $A, 'b', $raw, $TIMEOUT );
is( scalar socket_protocol_read_message( $B, $TIMEOUT ), $raw, "protocol 'b' is binary clean" );

socket_protocol_write_message( $A, 'b', 'scalar context', $TIMEOUT );
is( scalar socket_protocol_read_message( $B, $TIMEOUT ), 'scalar context',
    'socket_protocol_read_message() in scalar context returns the payload' );

##############################################################################
# argument checking
##############################################################################

eval { socket_protocol_write_message( $A, 'Z', { a => 1 }, $TIMEOUT ) };
like( $@, qr/unknown or forbidden PROTOCOL_TYPE/, 'socket_protocol_write_message() rejects unknown protocol' );

eval { socket_protocol_write_message( $A, 'h', 'not a hash ref', $TIMEOUT ) };
like( $@, qr/expected HASH reference/, 'socket_protocol_write_message() requires a hash ref for non-binary protocols' );

##############################################################################
# socket_protocols_allow()
##############################################################################

socket_protocols_allow( 'bh' );

ok( socket_protocol_write_message( $A, 'h', $HR, $TIMEOUT ), 'allowed protocol still works' );
is_deeply( scalar socket_protocol_read_message( $B, $TIMEOUT ), $HR, 'allowed protocol round trip' );

eval { socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ) };
like( $@, qr/unknown or forbidden PROTOCOL_TYPE/, 'socket_protocols_allow() forbids the other protocols' );

socket_protocols_allow( 'b', 'h' ); # a list of strings is joined
eval { socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ) };
ok( $@, 'socket_protocols_allow() accepts a list of protocol strings' );

eval { socket_protocols_allow( 'bZ' ) };
like( $@, qr/unknown PROTOCOL_TYPE/, 'socket_protocols_allow() rejects unknown protocol types' );

socket_protocols_allow( '*' );
ok( socket_protocol_write_message( $A, 'p', $HR, $TIMEOUT ), 'socket_protocols_allow( "*" ) re-enables everything' );
is_deeply( scalar socket_protocol_read_message( $B, $TIMEOUT ), $HR, 'protocol works again after "*"' );

##############################################################################
# error reporting on a dead socket
##############################################################################

my ( $C, $D ) = make_pair();
close( $C );
my ( undef, undef, $eof ) = socket_protocol_read_message( $D, $TIMEOUT );
is( $eof, 'E_EOF', 'socket_protocol_read_message() reports E_EOF on a closed socket' );
close( $D );

# a zero length message has no protocol type byte
my ( $E, $F ) = make_pair();
socket_write_message( $E, '', $TIMEOUT );
my ( undef, undef, $empty ) = socket_protocol_read_message( $F, $TIMEOUT );
is( $empty, 'E_EMPTY', 'socket_protocol_read_message() reports E_EMPTY for an empty message' );

# a message with only the protocol type byte has no payload
socket_write_message( $E, 'h', $TIMEOUT );
my ( undef, $only_type, $nopayload ) = socket_protocol_read_message( $F, $TIMEOUT );
is( $only_type, 'h',       'socket_protocol_read_message() still reports the protocol type' );
is( $nopayload, 'E_EMPTY', 'socket_protocol_read_message() reports E_EMPTY for a payload-less message' );
close( $E );
close( $F );

close( $A );
close( $B );

##############################################################################

done_testing();
