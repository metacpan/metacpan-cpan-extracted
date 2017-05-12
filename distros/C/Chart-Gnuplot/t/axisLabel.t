#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test default setting of axis labels
{
    my $c = Chart::Gnuplot->new(
        output  => $temp,
        xlabel  => 'x-label',
        ylabel  => 'y-label',
        x2label => 'x2-label',
        y2label => 'y2-label',
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "axisLabel_1.gp") == 0);
}


# Test formatting the axis labels
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        xlabel => {
            text     => "My axis label in {/Symbol-Oblique greek}",
            font     => "Courier, 30",
            color    => "pink",
            offset   => "3,2",
            enhanced => "on",
        },
        ylabel => {
            text   => "Rotated 80 deg",
            rotate => 80,
        },
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "axisLabel_2.gp") == 0);
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
