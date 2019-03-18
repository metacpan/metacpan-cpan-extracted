#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use PDL::Primitive qw(grandom random);

use Chart::GGPlot qw(:all);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $p = qplot(
    x     => [ 0 .. 9 ],
    y     => grandom(10), 
    color => random(10),
    title => 'random numbers',
);

if (defined $save_as) {
    $p->save($save_as);
} else {
    $p->show();
}

