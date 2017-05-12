#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test setting range in x, y, x2, y2 axes
{
    my $c = Chart::Gnuplot->new(
        output  => $temp,
        xrange  => [-5, 5],
        yrange  => ["-pi", "*"],
        x2range => ["*", 10],
        y2range => "[-2, 2]",
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "range_1.gp") == 0);
}

# Test setting trange
{
    my $c = Chart::Gnuplot->new(
        output  => $temp,
		trange => [0, 40],
		urange => [-10, 20],
		vrange => [0, "*"],
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "range_2.gp") == 0);
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
