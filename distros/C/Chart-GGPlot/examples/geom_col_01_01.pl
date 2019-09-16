#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame;
use PDL::SV ();
use PDL::Core qw(pdl);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $df = Data::Frame->new(
    columns => [
        trt     => PDL::SV->new( [qw(a b c)] ),
        outcome => pdl( [ 2.3, 1.9, 3.2 ] ),
    ]
);

my $p = ggplot(
    data    => $df,
    mapping => aes( x => 'trt', y => 'outcome' )
)->geom_col();

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

