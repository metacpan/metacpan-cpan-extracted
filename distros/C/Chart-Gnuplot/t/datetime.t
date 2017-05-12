#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test input date in time format
{
    my $c = Chart::Gnuplot->new(
        output   => $temp,
        timeaxis => 'x',
    );

    my $d = Chart::Gnuplot::DataSet->new(
        xdata   => ['2012-02-26'],
        ydata   => [1],
        timefmt => '%Y-%m-%d',
    );

    $c->_setChart([$d]);
    ok(&diff($c->{_script}, "datetime_1.gp") == 0);
}

# Test changing date-time format
{
    my $c = Chart::Gnuplot->new(
        output   => $temp,
        timeaxis => 'x',
		xtics    => {labelfmt => '%b %y'},
    );

    my $d = Chart::Gnuplot::DataSet->new(
        xdata   => ['2012-02-26'],
        ydata   => [1],
        timefmt => '%Y-%m-%d',
    );

    $c->_setChart([$d]);
    ok(&diff($c->{_script}, "datetime_2.gp") == 0);
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
