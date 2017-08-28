use 5.006;
use strict;
use warnings;


use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Netflow;

use Test::More tests => 40;

my $Header = {
    Version => 5,
    SysUptime =>10000,
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

my @flows;
my @tmp = qw( 10.2.1.1 10.2.1.254 0.0.0.0 0 0 5 8126   );
my $uptime = 25000;
push @tmp,  $uptime;
push @tmp,  $uptime + 5;
push @tmp,  qw(22 5365 0 27 6 0 0 0 0 0 0 );
push @flows, \@tmp;


$uptime = 55000;
push @flows, ['10.2.1.33', '10.2.1.17', '0.0.0.0', 0, 0, 5, 8126, $uptime, $uptime + 5, 2222, 6666, 0, 27, 6, 0, 0, 0, 0, 24, 0];

my $encoded = Data::Netflow::encodeV5( $Header, $TemplateV5, \@flows );
my ( $headers, $flows_out ) = Data::Netflow::decode( $encoded );

foreach my $idx ( 0 .. $#flows )
{
    my $in = $flows[$idx];
    my $out = $flows_out->[$idx];
    foreach my $id ( 0 .. ( scalar( @$in - 1 ) ) )
    {
        my $field_idx = $TemplateV5->{Fields}[$id]->{Id};
        ok ( $in->[$id] eq $out->{$field_idx} )
    }

}


