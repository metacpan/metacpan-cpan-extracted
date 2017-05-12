#!/usr/bin/perl -w
use strict;
use Test::More (tests => 6);

BEGIN {use Chart::Gnuplot;}


# Test plotting from Perl arrays of x coordinates and y coordinates
{
    my @x = (-10 .. 10);
    my @y = (0 .. 20);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "dataSrc_1.dat") == 0);
}


# Test plotting from Perl array of x-y pairs
{
    my @xy = (
        [1, 2],
        [3, 1],
        [5, 0],
        [6, 1],
        [7, 2],
        [9, 3],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        points => \@xy,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "dataSrc_2.dat") == 0);
}


# Test plotting from data file
{
    my $infile = "dataSrc_3.dat";
    $infile = "t/".$infile if (!-e $infile);

    my $d = Chart::Gnuplot::DataSet->new(
        datafile => $infile,
    );

    my $string = $d->_thaw();
    ok($string eq "'$infile' title \"\"");
}


# Test plotting from mathematical expression
{
    my $d = Chart::Gnuplot::DataSet->new(
        func => "sin(x)",
    );

    my $string = $d->_thaw();
    ok($string eq 'sin(x) title ""');
}


# Test plotting 2D parametric function
{
    my $c = Chart::Gnuplot->new(
        output => "temp.ps",
    );
    my $d = Chart::Gnuplot::DataSet->new(
        func => {
            x => 'sin(t)',
            y => 'cos(t)',
        },
    );

    $c->_setChart([$d]);
    my $s = $d->_thaw();
    ok($s eq 'sin(t),cos(t) title ""' && defined $c->{parametric});
}


# Test plotting 3D parametric function
{
    my $c = Chart::Gnuplot->new(
        output => "temp.ps",
    );

    # A torus
    my $d = Chart::Gnuplot::DataSet->new(
        func => {
            x => 'cos(u)*(4+cos(v))',
            y => 'sin(u)*(4+cos(v))',
            z => 'sin(v)',
        },
    );

    $c->_setChart([$d]);
    my $s = $d->_thaw();
    ok($s eq 'cos(u)*(4+cos(v)),sin(u)*(4+cos(v)),sin(v) title ""' &&
        defined $c->{parametric});
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
