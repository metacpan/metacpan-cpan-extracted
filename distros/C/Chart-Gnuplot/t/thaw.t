#!/usr/bin/perl -w
use strict;
use Test::More (tests => 17);

BEGIN {use Chart::Gnuplot;}


# Test plotting from Perl arrays of y coordinates only
{
    my @y = (6 .. 10);

    my $d = Chart::Gnuplot::DataSet->new(
        ydata => \@y,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_1.dat") == 0);
}


# Test plotting yerrorbars from Perl arrays of y coordinates only
{
    my @y = (5, 4, 3, 2, 1);
    my @err = (0.5, 0.4, 0.1, 0, 0.3);

    my $d = Chart::Gnuplot::DataSet->new(
        ydata => [[@y], [@err]],
        style => 'yerrorbars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_2.dat") == 0);
}


# Test plotting financebars from Perl arrays of y coordinates only
{
    my @open  = (5, 4, 3, 2, 1);
    my @high  = (7, 6, 5, 4, 3);
    my @low   = (4, 3, 2, 1, 0);
    my @close = (6, 5, 4, 3, 2);

    my $d = Chart::Gnuplot::DataSet->new(
        ydata => [\@open, \@high, \@low, \@close],
        style => 'financebars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_3.dat") == 0);
}


# Test plotting xerrorbars from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (5, 4, 3, 2, 1);
    my @err = (0.5, 0.4, 0.1, 0, 0.3);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => [[@x], [@err]],
        ydata => \@y,
        style => 'xerrorbars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_4.dat") == 0);
}


# Test plotting yerrorbars from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (5, 4, 3, 2, 1);
    my @err = (0.5, 0.4, 0.1, 0, 0.3);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => [[@y], [@err]],
        style => 'yerrorbars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_4.dat") == 0);
}


# Test plotting xyerrorbars from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (5, 4, 3, 2, 1);
    my @xerr = (0.5, 0.4, 0.1, 0, 0.3);
    my @yerr = (0.1, 0.2, 0, 0.4, 0.3);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => [[@x], [@xerr]],
        ydata => [[@y], [@yerr]],
        style => 'xyerrorbars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_5.dat") == 0);
}


# Test plotting financebars from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @open  = (5, 4, 3, 2, 1);
    my @high  = (7, 6, 5, 4, 3);
    my @low   = (4, 3, 2, 1, 0);
    my @close = (6, 5, 4, 3, 2);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => [\@open, \@high, \@low, \@close],
        style => 'financebars',
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_6.dat") == 0);
}


# Test plotting hlines from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (2, 4, 3, 5, 7);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        style => 'hlines',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_7.dat") == 0 && $s =~ /with boxxyerrorbars$/);
}


# Test plotting hbars from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (2, 4, 3, 5, 7);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        style => 'hbars',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_8.dat") == 0 && $s =~ /with boxxyerrorbars$/);
}


# Test plotting histogram from Perl arrays of x and y coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (2, 4, 3, 5, 7);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        style => 'histograms',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_9.dat") == 0 &&
        $s =~ /using 2:xticlabels\(1\) title "" with histograms$/);
}


# Test plotting from Perl arrays of x, y and z coordinates
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (2, 4, 3, 5, 7);
    my @z = (-2, -2, 0, 1, -1);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        zdata => \@z,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_10.dat") == 0);
}


# Test plotting 3D surface from Perl arrays of x, y and z coordinates
{
    my @x = (
        [3, 3, 3],
        [4, 4, 4],
        [5, 5, 5],
    );
    my @y = (
        [0, 1, 2],
        [0, 1, 2],
        [0, 1, 2],
    );
    my @z = (
        [-2, 2, 6],
        [-1, 3, 7],
        [ 0, 4, 8],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        ydata => \@y,
        zdata => \@z,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_11.dat") == 0);
}


# Test plotting hlines from Perl array of points
{
    my @p = (
        [6, 2],
        [7, 4],
        [8, 3],
        [9, 5],
        [10, 7],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        points => \@p,
        style  => 'hlines',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_7.dat") == 0 && $s =~ /with boxxyerrorbars$/);
}


# Test plotting hbars from Perl array of points
{
    my @p = (
        [6, 2],
        [7, 4],
        [8, 3],
        [9, 5],
        [10, 7],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        points => \@p,
        style  => 'hbars',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_8.dat") == 0 && $s =~ /with boxxyerrorbars$/);
}


# Test plotting histogram from Perl array of points
{
    my @p = (
        [6, 2],
        [7, 4],
        [8, 3],
        [9, 5],
        [10, 7],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        points => \@p,
        style  => 'histograms',
    );

    my $s = $d->_thaw();
    ok(&diff($d->{_data}, "thaw_9.dat") == 0 &&
        $s =~ /using 2:xticlabels\(1\) title "" with histograms$/);
}


# Test plotting 3D surface from Perl array of points
{
    my @p = (
        [
            [3, 0, -2],
            [3, 1, 2],
            [3, 2, 6],
        ],
        [
            [4, 0, -1],
            [4, 1, 3],
            [4, 2, 7],
        ],
        [
            [5, 0, 0],
            [5, 1, 4],
            [5, 2, 8],
        ],
    );

    my $d = Chart::Gnuplot::DataSet->new(
        points => \@p,
    );

    $d->_thaw();
    ok(&diff($d->{_data}, "thaw_11.dat") == 0);
}


# Test smoothing the data points
{
    my @x = (6, 7, 8, 9, 10);
    my @y = (2, 4, 3, 5, 7);

    my $d = Chart::Gnuplot::DataSet->new(
        xdata  => \@x,
        ydata  => \@y,
        style  => 'lines',
        smooth => 'csplines',
    );

    my $s = $d->_thaw();
    ok($s =~ /smooth csplines/);
}

###################################################################

# Compare two files
# - return 0 if two files are exactly the same
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
