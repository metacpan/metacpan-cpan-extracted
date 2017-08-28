use 5.006;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Netflow;
use Test::More tests => 20;
my $TemplateV9 = {
    'FlowSetId'  => 0,
    'TemplateId' => 300,
    'Fields'     => [
        { 'Length' => 4, 'Id' => 1  },    # octetDeltaCount        
        { 'Length' => 4, 'Id' => 2  },    # packetDeltaCount        
        { 'Length' => 1, 'Id' => 4  },    # protocolIdentifier        
        { 'Length' => 1, 'Id' => 6  },    # tcp flags        
        { 'Length' => 2, 'Id' => 7  },    # sourceTransportPort        
        { 'Length' => 4, 'Id' => 8  },    # sourceIPv4Address        
        { 'Length' => 2, 'Id' => 11 },    # destinationTransportPort        
        { 'Length' => 4, 'Id' => 12 },    # destinationIPv4Address        
        { 'Length' => 4, 'Id' => 21 },    # last switched        
        { 'Length' => 4, 'Id' => 22 },    # first switched
    ],
};

my $Header = {
    Version   => 9,
    SysUptime => 15000,
};

my @flows;
my @tmp    = qw( 5 8126 17 0 22 10.2.1.1 5365 10.2.1.254  );
my $uptime = int( 15000 * 1000 );
push @tmp,   $uptime + 5;
push @tmp,   $uptime;
push @flows, \@tmp;

my @tmp1 = qw( 7 1024 6 27 5555 10.2.1.1 53 10.2.1.3 );
$uptime = int( 30000 );
push @tmp1,  $uptime + 5000;
push @tmp1,  $uptime;
push @flows, \@tmp1;

my $encoded = Data::Netflow::encodeV9( $Header, $TemplateV9, \@flows );

my ( $headers, $flows_out ) = Data::Netflow::decode( $encoded );

foreach my $idx ( 0 .. $#flows )
{
    my $in = $flows[$idx];
    my $out = $flows_out->[$idx];
    foreach my $id ( 0 .. ( scalar( @$in - 1 ) ) )
    {
        my $field_idx = $TemplateV9->{Fields}[$id]->{Id};
        ok ( $in->[$id] eq $out->{$field_idx} )
    }

}

