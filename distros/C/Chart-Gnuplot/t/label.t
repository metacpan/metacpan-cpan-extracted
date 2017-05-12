#!/usr/bin/perl -w
use strict;
use Test::More (tests => 3);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test default setting of label
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
    );

    $c->label(
        text     => "Test label",
        position => "1, -2",
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "label_1.gp") == 0);
}

# Test formatting label
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
    );

    $c->label(
        text       => "Test label",
        position   => "1, -2",
        offset     => "1.5, 0",
        pointtype  => 5,
        pointsize  => 3,
        pointcolor => 'blue',
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "label_2.gp") == 0);
}

# Test multiple labels
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
    );

    # Label 1
    $c->label(
        text       => "Test label 1",
        position   => "2, -0.3",
        offset     => "1.5, 0",
        pointtype  => 5,
        pointsize  => 3,
        pointcolor => 'blue',
    );

    # Label 2
    $c->label(
        text      => "Test label 2",
        position  => "-2, 0.3",
        pointtype => 'square',
        pointsize => 2,
    );

    $c->_setChart();
    ok(&diff($c->{_script}, "label_3.gp") == 0);
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
