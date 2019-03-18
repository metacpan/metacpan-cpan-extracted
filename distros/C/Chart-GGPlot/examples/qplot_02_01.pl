#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use PDL::LiteF;

use Chart::GGPlot qw(:all);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $lx = pdl( [ 10 .. 50 ] ) / 10;
my $e  = exp(1);
my $y  = exp( -0.5 * $lx**2 );
my $yl = 'e^{-frac(1,2) * {log[10](x)}^2}';

my $p = qplot(
    x     => 10**$lx,
    y     => $y,
    log   => 'xy',
    geom  => 'line',
    title => 'Log-Log plot',
    xlab  => 'x',
    ylab  => $yl,
);

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

