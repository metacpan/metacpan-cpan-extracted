#!/usr/bin/perl -w
use strict;
use Test::More (tests => 3);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test formatting the border
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
		bg     => {
			color   => '#a2a2ff',
			density => 0.3,
		},
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "background_1.gp") == 0);
}


# Test formatting the border
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
		plotbg => {
			color   => '#a2a2ff',
			density => 0.3,
		},
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "background_2.gp") == 0);
}


# Test formatting the border
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
		bg     => {
			color   => '#a2a2ff',
			density => 0.3,
		},
		plotbg => {
			color   => '#FFDDDD',
			density => 0.2,
		},
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "background_3.gp") == 0);
}

###################################################################

# Compare two files
# - return 0 if two files are the same, except the ordering of the lines
# - return 1 otherwise
sub diff
{
    my ($f1, $f2) = @_;
    $f2 = "t/".$f2 if (!-e $f2);

    open(F1, $f1) || return(1);
    open(F2, $f2) || return(1);
    my @c1 = <F1>;
    my @c2 = <F2>;
    close(F1);
    close(F2);
    return(0) if (join("", sort @c1) eq join("", sort @c2));
    return(1);
}
