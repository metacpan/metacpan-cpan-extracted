#!/usr/bin/perl -w
use strict;
use Test::More (tests => 2);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test the command method
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
    );

    # A Gnuplot command
    $c->command("set size squre 0.5");

    ok(&diff($c->{_script}, "command_1.gp") == 0);
}


# Test the command method
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
    );

    # Array of Gnuplot commands
    $c->command([
        "set size squre 0.5",
        "set parametric",
    ]);

    ok(&diff($c->{_script}, "command_2.gp") == 0);
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
    return(0) if (join("", @c1) eq join("", @c2));
    return(1);
}
