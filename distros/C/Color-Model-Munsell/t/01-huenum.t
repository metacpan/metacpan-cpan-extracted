#!perl -T
use strict;
use warnings;
#use Data::Dumper;
use Test::More 'no_plan';

BEGIN {
    use_ok( 'Color::Model::Munsell' ) || print "Bail out!";
}

my %_hue_order = (
    R  => 0, YR => 1, Y  => 2, GY => 3, G  => 4,
    BG => 5, B  => 6, PB => 7, P  => 8, RP => 9,
);

foreach my $col ( qw(R YR Y GY G BG B PB P RP ) ){
	for (my $i=0.5; $i<=10.0; $i+=0.5){
		my $m = Color::Model::Munsell->new("$i$col 5/14");
		my $n = ($col eq 'RP' and $i == 10.0)? 0:
			$_hue_order{$m->hueCol}*10 + $m->hueStep;
		ok($m->degree == $n, "checking $m");
	}
}

