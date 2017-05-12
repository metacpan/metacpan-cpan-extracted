#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test formatting the border
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        border => {
            linetype => 3,
            width    => 2,
            color    => '#ff00ff',
        },
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "border_1.gp") == 0);
}

# Test formatting the specified borders
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        border => {
            sides    => "left, bottom",
            linetype => 3,
            width    => 2,
            color    => '#ff00ff',
        },
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "border_2.gp") == 0);
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
