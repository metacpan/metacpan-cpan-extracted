#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test formatting the axis tics
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        xtics  => {
            labelfmt  => '%.1g',
            font      => 'arial,18',
            fontcolor => 'magenta',
        },
        ytics  => {
            labels => [-0.8, 0.3, 0.6], # specify tic labels
            rotate => '30',
            mirror => 'off',            # no tic on y2 axis
        },
        x2tics => [-8, -6, -2, 2, 5, 9],
        y2tics => {
            length => "4,2",            # tic size
            minor  => 4,                # 2 minor tics between major tics
        },
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "axisTics_1.gp") == 0);
}


# Test manually-specified range of tic
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        xtics  => {
			incr => 10,
        },
        ytics  => {
			start => -100,
			incr  => 5,
			end   => 200,
        },
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "axisTics_2.gp") == 0);
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
