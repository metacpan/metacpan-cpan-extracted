#!/usr/bin/perl

use strict;
use feature qw( say );
use Data::Dumper;
use IO::Socket;
use Socket qw( inet_pton );

use lib './lib/';
use Data::Netflow;

my $back = shift // 0;
my $sock_udp = IO::Socket::INET->new(
    Proto    => 'udp',
    PeerPort => 9995,
    PeerAddr => '127.0.0.1',
) or die "Could not create UDP socket: $!\n";

my $Header = {
    Version => 5,
    #SourceId => 11,
    #PackageNum => 10,
    SysUptime => int( uptime() * 1000 ),
};

#<<<
my $TemplateV5 = {
    'Fields' => [
            { 'Length' => 4, 'Id'     => 1  },    # Source IP address
            { 'Length' => 4, 'Id'     => 2  },    # Destination IP address
            { 'Length' => 4, 'Id'     => 3  },    # IP address of next hop router
            { 'Length' => 2, 'Id'     => 4  },    # SNMP index of input interface
            { 'Length' => 2, 'Id'     => 5  },    # SNMP index of output interface
            { 'Length' => 4, 'Id'     => 6  },    # Packets in the flow
            { 'Length' => 4, 'Id'     => 7  },    # Total number of Layer 3 bytes in the packets of the flow
            { 'Length' => 4, 'Id'     => 8  },    # StartTime
            { 'Length' => 4, 'Id'     => 9  },    # EndTime
            { 'Length' => 2, 'Id'     => 10 },    # SrcPort
            { 'Length' => 2, 'Id'     => 11 },    # DstPort
            { 'Length' => 1, 'Id'     => 12 },    # Padding
            { 'Length' => 1, 'Id'     => 13 },    # TCP Flags
            { 'Length' => 1, 'Id'     => 14 },    # Protocol
            { 'Length' => 1, 'Id'     => 15 },    # IP ToS
            { 'Length' => 2, 'Id'     => 16 },    # SrcAS
            { 'Length' => 2, 'Id'     => 17 },    # DstAS
            { 'Length' => 1, 'Id'     => 18 },    # SrcMask
            { 'Length' => 1, 'Id'     => 19 },    # DstMask
            { 'Length' => 2, 'Id'     => 20 },    # Padding
    ]
};
#>>>

my @flow;
#my @tmp = qw( 5 8126 17 0 22 10.2.1.1 5365 10.2.1.254  ) ;
my @tmp = qw( 10.2.1.1 10.2.1.254 0.0.0.0 0 0 5 8126   );

my $uptime = int( ( uptime() - $back ) );
push @tmp,  $uptime;
push @tmp,  $uptime + 5;
push @tmp,  qw(22 5365 0 27 6 0 0 0 0 0 0 );
push @flow, \@tmp;

#my @tmp = qw( 10.2.1.33 10.2.1.17 0.0.0.0 0 0 5 8126   );

$uptime = int( ( uptime() - $back ) );
#push @tmp,  $uptime;
#push @tmp,  $uptime + 5;
#push @tmp,  qw(2222 6666 0 27 6 0 0 0 0 24 0 );
#push @flow, \@tmp;
push @flow, ['10.2.1.33', '10.2.1.17', '0.0.0.0', 0, 0, 5, 8126, $uptime, $uptime + 5, 2222, 6666, 0, 27, 6, 0, 0, 0, 0, 24, 0];
say Dumper( @flow );
my $encoded = Data::Netflow::encodeV5( $Header, $TemplateV5, \@flow );
$sock_udp->send( $encoded );
$Data::Dumper::Sortkeys = 1;
say Dumper( Data::Netflow::decode( $encoded) );

sub uptime
{
    return (
        split /\s/,
        do {local ( @ARGV, $/ ) = '/proc/uptime'; <>}
    )[0];
}
