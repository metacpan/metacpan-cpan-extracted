#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame;
use PDL::Core qw(pdl);
use PDL::Basic qw(sequence);
use PDL::Primitive qw(random);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $n  = 201;
my $x  = ( sequence($n) - $n / 2 )->repeat($n) * 0.1;
my $y  = ( pdl( map { ($_) x $n } ( 0 .. $n - 1 ) ) - $n / 2 ) * 0.1;
my $z  = ( $x**2 + $y**2 )->sqrt->sin;
my $df = Data::Frame->new(
    columns => [
        x => $x,
        y => $y,
        z => $z,
    ]
);

my $p = ggplot(
    data    => $df,
    mapping => aes( x => 'x', y => 'y', fill => 'z' )
)->geom_raster();

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

