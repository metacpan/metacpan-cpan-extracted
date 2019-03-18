#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Chart::GGPlot::Util qw(seq_n);
use Data::Frame;
use PDL::Core qw(pdl);

my $save_as;
GetOptions( 'o=s' => \$save_as );

sub qlogis {
    my ($p) = @_;
    return ( $p / ( 1 - $p ) )->log;
}

my $x  = seq_n( 0.01, 0.99, 100 );
my $df = Data::Frame->new(
    columns => [
        x     => $x->glue( 0, $x ),
        y     => qlogis($x)->glue( 0, qlogis($x) * 2 ),
        group => PDL::SV->new( [('a') x 100, ('b') x 100 ] )
    ]
);

my $p = ggplot(
    data    => $df,
    mapping => aes( x => 'x', y => 'y', group => 'group' )
)->geom_line(linetype => 'dash');

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

