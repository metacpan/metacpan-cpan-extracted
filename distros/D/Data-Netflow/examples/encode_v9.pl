#!/usr/bin/perl

use strict;
use feature qw( say );
use Data::Dumper;
use IO::Socket;
use Socket qw( inet_pton );


use lib './lib/';
use Data::Netflow;

my $back = shift // 0;
my $port = shift // 9995;
my $sock_udp = IO::Socket::INET->new(
    Proto    => 'udp',
    PeerPort => $port,
    PeerAddr => '127.0.0.1',
) or die "Could not create UDP socket: $!\n";

my $TemplateV9 = {
    'FlowSetId'      => 0,
    'TemplateId' => 300,
    'Fields'   => [
        { 'Length' => 4, 'Id' => 1 , 'Name' => 'octetDeltaCount' },    # octetDeltaCount
        { 'Length' => 4, 'Id' => 2 , 'Name' => 'packetDeltaCount' },    # packetDeltaCount
        { 'Length' => 1, 'Id' => 4   , 'Name' => 'protocolIdentifier'},    # protocolIdentifier
#        { 'Length' => 1, 'Id' => 5  },    # ipClassOfService
        { 'Length' => 1, 'Id' => 6 , 'Name' => 'tcp flags' },    # tcp flags
        { 'Length' => 2, 'Id' => 7 , 'Name' => 'sourceTransportPort'  },    # sourceTransportPort
        { 'Length' => 4, 'Id' => 8 , 'Name' => 'sourceIPv4Address' },    # sourceIPv4Address
##        { 'Length' => 1, 'Id' => 9  },    # srcMask
#        { 'Length' => 2, 'Id' => 10 },    # INPUT_SNMP
        { 'Length' => 2, 'Id' => 11, 'Name' => 'destinationTransportPort' },    # destinationTransportPort
        { 'Length' => 4, 'Id' => 12 , 'Name' => 'destinationIPv4Address'},    # destinationIPv4Address
##        { 'Length' => 1, 'Id' => 13 },    # dtsMask
#        { 'Length' => 2, 'Id' => 14 },    # OUTPUT_SNMP
##        { 'Length' => 4, 'Id'     => 15 },    # next hop
#        { 'Length' => 2, 'Id' => 16 },    # src_as
#        { 'Length' => 2, 'Id' => 17 },    # dst_as
        { 'Length' => 4, 'Id' => 21 },    # last switched
        { 'Length' => 4, 'Id' => 22 },    # first switched
##        { 'Length' => 4, 'Id' => 34 },    # samplingInterval
##        { 'Length' => 4, 'Id' => 35 },    # samplingAlgorithm
#        { 'Length' => 1, 'Id' => 89 },    # FORWARDING STATUS
    ],
};

my $Header = {
                 Version => 9,
                 #SourceId => 11,
                 #PackageNum => 10,
                 SysUptime => int ( uptime() *1000 ),
             };


my @flow;
my @tmp = qw( 5 8126 17 0 22 10.2.1.1 5365 10.2.1.254  ) ;
my $uptime = int ( (uptime()- $back ) *1000 );
push @tmp  , $uptime + 5;
push @tmp  , $uptime;
push @flow , \@tmp;


my @tmp = qw( 7 1024 6 27 5555 10.2.1.1 53 10.2.1.3 ) ;

$uptime = int ( (uptime()- $back )*1000 );
push @tmp  , $uptime+5000;
push @tmp  , $uptime;
push @flow , \@tmp;


my @tmp = qw( 1 10024 6 27 6666 10.2.1.77 53 10.2.1.88 ) ;

$uptime = int ( (uptime()- $back )*1000 );
push @tmp  , $uptime+6000;
push @tmp  , $uptime;
push @flow , \@tmp;

my @tmp = qw( 1 300 6 27 123 10.2.1.177 53 10.2.1.188 ) ;

$uptime = int ( (uptime()- $back )*1000 );
push @tmp  , $uptime+6000;
push @tmp  , $uptime;
push @flow , \@tmp;


my @tmp = qw( 1 400 6 20 1230 10.2.1.177 53 10.2.1.188 ) ;

$uptime = int ( (uptime()- $back )*1000 );
push @tmp  , $uptime+6000;
push @tmp  , $uptime;
push @flow , \@tmp;

say Dumper(@flow);
my $encoded = Data::Netflow::encodeV9($Header, $TemplateV9 ,\@flow);
$sock_udp->send( $encoded );

 Data::Netflow::decode($encoded );


sub uptime
{
    return (
        split /\s/,
        do {local ( @ARGV, $/ ) = '/proc/uptime'; <>}
    )[0];
}
