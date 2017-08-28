#!/usr/bin/perl

use strict;
use feature qw( say );
use Data::Dumper;
use IO::Socket::INET;
use lib './lib/';
use Data::Netflow;
my $receive_port = shift // 2055;    # IPFIX port
my $packet;
my %TemplateArrayRefs;
my $sock = IO::Socket::INET->new(
    LocalPort => $receive_port,
    Proto     => 'udp'
);

my $sender;
my $nbr =1;
while ( $sender = $sock->recv( $packet, 0xFFFF ) )
{
    my ( $sender_port, $sender_addr ) = unpack_sockaddr_in( $sender );
    $sender_addr = inet_ntoa( $sender_addr );

    $Data::Dumper::Sortkeys = 1;
    my ($headers , $flows ) = Data::Netflow::decode( $packet ) ;
  #  say Dumper $headers;
    say "*" x 50 . " $nbr ".time;
    say Dumper $flows;
    $nbr++;
}
