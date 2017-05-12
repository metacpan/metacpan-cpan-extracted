#!usr/bin/perl -w
# $Id: 31_master_key.t 189 2006-12-05 02:41:46Z fil $

use strict;

use Test::More ( tests=>9 );
use Data::Tabular::Dumper;

pass( 'loaded' );

my %params=( CSV=>["t/test-31-test.csv", {eol=>"\n", binary=>1}], 
             XML=>["t/test-31-test.xml", "catalog", "camera" ],
           );

my $allowed=Data::Tabular::Dumper->available();

foreach my $t ( qw( CSV XML Excel ) ) {
    delete $params{$t} unless $allowed->{$t};    
}


my %tests = (
#########################
LoH => {
    data=> [
        {   camera=>"EOS 2000", price=>12000.00 },
        {   camera=>"FinePix 1300", price=>150 },
    ],
    CSV=>[
        qq(camera,price\n),
        qq("EOS 2000",12000\n),
        qq("FinePix 1300",150\n)
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<catalog>\n),
        qq(  <camera>\n),
        qq(    <camera>EOS 2000</camera>\n),
        qq(    <price>12000</price>\n),
        qq(  </camera>\n),
        qq(  <camera>\n),
        qq(    <camera>FinePix 1300</camera>\n),
        qq(    <price>150</price>\n),
        qq(  </camera>\n),
        qq(</catalog>\n),
    ],
},

##########################
HoH => {
    data => {
       EOS2000     => { mfg =>'Canon', price=>12000 },
       FinePix1300 => { mfg =>'Fuji', price=>150 }
    },
    CSV => [
        qq(SKU,mfg,price\n),
        qq(EOS2000,Canon,12000\n),
        qq(FinePix1300,Fuji,150\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<catalog>\n),
        qq(  <camera>\n),
        qq(    <SKU>EOS2000</SKU>\n),
        qq(    <mfg>Canon</mfg>\n),
        qq(    <price>12000</price>\n),
        qq(  </camera>\n),
        qq(  <camera>\n),
        qq(    <SKU>FinePix1300</SKU>\n),
        qq(    <mfg>Fuji</mfg>\n),
        qq(    <price>150</price>\n),
        qq(  </camera>\n),
        qq(</catalog>\n),
    ]
}
);

##################################################################
foreach my $name ( sort keys %tests ) {
    my $test = $tests{$name};

    foreach my $p ( values %params ) {
        next unless ref $p;
        $p->[0] =~ s/31-\w+/31-$name/;
    }

    # diag( $name );
    my $dumper = Data::Tabular::Dumper->open( %params, master_key=>'SKU' );
    $dumper->dump( $test->{data} );
    $dumper->close;

    foreach my $t ( qw( CSV XML ) ) {

        SKIP: {
            skip "$t support not installed", 2
                unless $params{$t};
            ok( (-f $params{$t}[0]), "Created $name ($t)" );

            if( $t eq 'Excel' ) {
                unlink( $params{ $t }[0] );
                skip "Can't verify $t files", 1;
            }

            my @content =  eval {
                local @ARGV = ( $params{$t}[0] );
                <>;
            };
            die $@ if $@;
            is_deeply( \@content, $test->{$t}, "OK" )
                or die "$params{$t}[0]";
            unlink( $params{$t}[0] );
        }
    }
}
