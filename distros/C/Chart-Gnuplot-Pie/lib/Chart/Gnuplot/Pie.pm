package Chart::Gnuplot::Pie;
use strict;
use vars qw($VERSION);
use base 'Chart::Gnuplot';
use Carp;
$VERSION = '0.04';


sub new
{
    my ($self, %opt) = @_;
    my $obj = $self->SUPER::new(%opt);
    $obj->set(
        parametric => '',
        xyplane    => 'at 0',
        urange     => '[0:1]',
        vrange     => '[0:1]',
        zrange     => '[-1:1]',
        cbrange    => '[-1:1]',
    );
    $obj->command(join("\n", (
        'unset border',
        'unset tics',
        'unset key',
        'unset colorbox',
    )));
    return($obj);
}


# Plot 2D pie chart
sub plot2d
{
    my ($self, $dataSet) = @_;
    $self->set(
        xrange => '[-1.5:1.5]',
        yrange => '[-1.5:1.5]',
        size   => 'square',
        view   => 'map',
    );
    $self->SUPER::_setChart([$dataSet]);

    open(CHT, ">>$self->{_script}") || confess("Can't write $self->{_script}");
    print CHT "set multiplot\n";
    print CHT $dataSet->_thaw2d($self);
    print CHT "unset multiplot\n";
    close(CHT);

    $self->SUPER::execute();
    return($self);
}


# Plot 3D pie chart
sub plot3d
{
    my ($self, $dataSet) = @_;
    $self->set(
        xrange => '[-1:1]',
        yrange => '[-1:1]',
    );
    $self->SUPER::_setChart([$dataSet]);

    open(CHT, ">>$self->{_script}") || confess("Can't write $self->{_script}");
    print CHT "set multiplot\n";
    print CHT $dataSet->_thaw3d($self);
    print CHT "unset multiplot\n";
    close(CHT);

    $self->SUPER::execute();
    return($self);
}

1;

##############################################################

package Chart::Gnuplot::Pie::DataSet;
use strict;
use base 'Chart::Gnuplot::DataSet';


# Plot 2D pie chart
sub _thaw2d
{
    my ($self, $chart) = @_;
    my $string = '';
    my $rotate = (defined $self->{rotate})? $self->{rotate} : 0;

    my $pt = $self->{data};
    my $sum = 0;
    for (my $i = 0; $i < @$pt; $i++)
    {
        $sum += $$pt[$i][1];
    }

    # Print label
    my $s = my $start = $rotate/360;
    my (@r, @g, @b) = ();
    for (my $i = 0; $i < @$pt; $i++)
    {
        my $e = $$pt[$i][1]/$sum + $s;

        # Print label
        my $pos = "cos(($s+$e)*pi)*1.1, sin(($s+$e)*pi)*1.1";
        $pos .= ", -0.1" if ($s+$e > 1 && $s+$e < 2);
        $pos .= ", 0.2" if ($s+$e < 1 || $s+$e > 2);
        $pos .= " right" if ($s+$e > 0.5 && $s+$e < 1.5);
        $pos .= " front";
        $chart->label(
            text     => $$pt[$i][0],
            position => $pos,
        );
        $string .= "set label${$chart->{_labels}}[-1]\n";
        $s = $e;
    }

    # Draw top surface
    $s = $start;
    for (my $i = 0; $i < @$pt; $i++)
    {
        my $e = $$pt[$i][1]/$sum + $s;

        # Set colors of the slices
        # - Initialize random color if not specified
        my ($r, $g, $b);
        if (!defined $self->{colors} || ${$self->{colors}}[$i] eq '')
        {
            $r = rand();
            $g = rand();
            $b = rand();
        }
        else
        {
            ($r, $g, $b) = &_rgb2real(${$self->{colors}}[$i]);
        }

        # Draw top surface
        $string .= "set palette model RGB functions $r, $g, $b\n";
        $string .= "splot cos(2*pi*(($e-$s)*u+$s))*v, ".
            "sin(2*pi*(($e-$s)*u+$s))*v, 0.1 with pm3d\n";
        $s = $e;
    }

    # Draw border around slice
    if (defined $self->{border} && $self->{border} ne 'off')
    {
        # Set line properties
        my $border = $self->{border};
        my $linecolor = "black";
        my $linewidth = 1;
        if (ref($border) eq 'HASH')
        {
            $linecolor = $$border{color} if (defined $$border{color});
            $linewidth = $$border{width} if (defined $$border{width});
        }

        $s = $start;
        for (my $i = 0; $i < @$pt; $i++)
        {
            my $e = $$pt[$i][1]/$sum + $s;
            $string .= "splot cos(2*pi*(($e-$s)*u+$s)), ".
                "sin(2*pi*(($e-$s)*u+$s)), 0.1 with lines lt 1 ".
                "lw $linewidth lc rgb \"$linecolor\"";
            $string .= ", u*cos(2*pi*$s), u*sin(2*pi*$s), 0.1 ".
                "with lines lt 1 lw $linewidth lc rgb \"$linecolor\"\n";
            $s = $e;
        }
    }

    return($string);
}


# Plot 3D pie chart
sub _thaw3d
{
    my ($self, $chart) = @_;
    my $string = '';
    my $rotate = (defined $self->{rotate})? $self->{rotate} : 0;

    my $pt = $self->{data};
    my $sum = 0;

    for (my $i = 0; $i < @$pt; $i++)
    {
        $sum += $$pt[$i][1];
    }

    # Print label and draw side sureface
    my $s = my $start = $rotate/360;
    my (@r, @g, @b) = ();
    for (my $i = 0; $i < @$pt; $i++)
    {
        my $e = $$pt[$i][1]/$sum + $s;

        # Print label
        my $pos = "cos(($s+$e)*pi)*1.1, sin(($s+$e)*pi)*1.1";
        $pos .= ", -0.1" if ($s+$e > 1 && $s+$e < 2);
        $pos .= ", 0.2" if ($s+$e < 1 || $s+$e > 2);
        $pos .= " right" if ($s+$e > 0.5 && $s+$e < 1.5);
        $pos .= " front";
        $chart->label(
            text     => $$pt[$i][0],
            position => $pos,
        );
        $string .= "set label${$chart->{_labels}}[-1]\n";

        # Set colors of the slices
        # - Initialize random color if not specified
        if (!defined $self->{colors} || ${$self->{colors}}[$i] eq '')
        {
            push(@r, rand());
            push(@g, rand());
            push(@b, rand());
        }
        else
        {
            my ($r, $g, $b) = &_rgb2real(${$self->{colors}}[$i]);
            push(@r, $r);
            push(@g, $g);
            push(@b, $b);
        }
        $string .= "set palette model RGB functions ".
            "$r[$i]*0.8, $g[$i]*0.8, $b[$i]*0.8\n";

        # Draw side surface
        $string .= "splot cos(2*pi*(($e-$s)*u+$s)), ".
            "sin(2*pi*(($e-$s)*u+$s)), v*0.2 with pm3d\n";
        $s = $e;
    }

    # Draw top surface
    $s = $start;
    for (my $i = 0; $i < @$pt; $i++)
    {
        my $e = $$pt[$i][1]/$sum + $s;

        # Draw top surface
        $string .= "set palette model RGB functions ".
            "$r[$i], $g[$i], $b[$i]\n";
        $string .= "splot cos(2*pi*(($e-$s)*u+$s))*v, ".
            "sin(2*pi*(($e-$s)*u+$s))*v, 0.2 with pm3d\n";
        $s = $e;
    }

    return($string);
}


# Transform #RRGGBB to (0-1, 0-1, 0-1)
# - called by _thaw2d() and _thaw3d()
sub _rgb2real
{
    my ($rgb) = @_;
    my ($r, $g, $b) = ($rgb =~ /^#(.{2})(.{2})(.{2})/);
    return(&_16to1($r)/255, &_16to1($g)/255, &_16to1($b)/255);
}


# Transform 0-H to 0-255
# - called by _rgb2real()
sub _16to1
{
    my ($x) = @_;
    my %tran = (
        0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => 4,
        5 => 5, 6 => 6, 7 => 7, 8 => 8, 9 => 9,
        A => 10, B => 11, C => 12, D => 13, E => 14, F => 15,
        a => 10, b => 11, c => 12, d => 13, e => 14, f => 15,
    );
    my ($a, $b) = ($x =~ /^(.)(.)$/);
    return($tran{$a}*16 + $tran{$b});
}


1;

__END__

=head1 NAME

Chart::Gnuplot::Pie - Plot pie chart using Gnuplot on the fly

=head1 SYNOPSIS

    use Chart::Gnuplot::Pie;

    # Create the pie chart object
    my $chart = Chart::Gnuplot::Pie->new(
        output => "pie.png",
        title  => "Sample Pie",
        ....
    );

    # Data set
    my $dataSet = Chart::Gnuplot::Pie::DataSet->new(
        data => [
            ['Item 1', 7500],
            ['Item 2', 3500],
            ['Item 3', 2000],
            ['Item 4', 4500],
        ],
        ....
    );

    # Plot a 2D pie chart
    $chart->plot2d($dataSet);

    #################################################

    # Plot a 3D pie chart
    $chart->plot3d($dataSet);

=head1 DESCRIPTION

This module provides an interface for plotting pie charts using Gnuplot, which
has not built-in command for pie. This module is an implementation of the idea
of L<The Impossible Gnuplot
Graphs|http://www.phyast.pitt.edu/~zov1/gnuplot/html/pie.html>.
L<Gnuplot|http://www.gnuplot.info> and L<Chart::Gnuplot> are required. 

B<IMPORTANT>: This is a preliminary version. Not many pie charting options are
provided currently. Besides, backward compatibility may not be guaranteed in
the later versions.

=head1 PIE CHART OBJECT

C<Chart::Gnuplot::Pie> is a child class of C<Chart::Gnuplot>. As a result, what
you may do on a C<Chart::Gnuplot> object basically works on a
C<Chart::Gnuplot::Pie> object too, with a few exceptions.

=head2 Pie Chart Options

The following options have no effect since they have not much meaning in pie
chart.

    xlabel, ylabel, zlabel
    x2label, y2label
    xrange, yrange, zrange
    x2range, y2range
    trange, urange, vrange
    xtics, ytics, ztics
    x2tics, y2tics
    timeaxis
    grid

Besides, the following options, though can be meaningful, are not supported yet.

    legend
    size
    bg
    plotbg

Supported options are:

    output
    title
    border
    tmargin, bmargin
    lmargin, rmargin
    orient
    imagesize
    origin
    timestamp
    view (only 3D pie)
    gnuplot
    convert
    terminal

=head1 DATASET OBJECT

C<Chart::Gnuplot::Pie::DataSet> is a child class of C<Chart::Gnuplot::DataSet>.

=head2 Dataset Options

The following options have no effect since they have not much meaning in pie
dataset.

    xdata, ydata, zdata
    points
    func
    title
    style
    width
    linetype
    pointtype
    pointsize
    axes
    smooth

Besides, the following options, though can be meaningful, are not supported yet.

    datafile
    fill
    timefmt

Supported options are:

    data
    rotate
    colors
    border

=head3 data

The data that would be displayed in the pie chart. The data should be organized
in a matrix of the format:

    [
        ['Item 1', value 1],
        ['Item 2', value 2],
        ['Item 3', value 3],
        ['Item 4', value 4],
        .....
    ],

=head3 rotate

The angle (in degree) that the pie would be rotated anti-clockwisely. E.g.

    rotate => -90    # rotate 90 degree clockwisely

=head3 colors

Color of each slice, in format of #RRGGBB. E.g. to set the second slice to
"#99ccff",

    colors => ["", "#99ccff", "", ....]

=head3 border

Border around and inside the pie. Currently, it is supported only for 2D pie.
E.g.

    border => {
        width => 3,
        color => "black",
    }

Supported proerties are:

    width
    color

=head1 EXAMPLES

=over

=item 1. A simple 2D pie chart

    my $c = Chart::Gnuplot::Pie->new(
        output   => "pie2d.png",
        title    => "Simple pie chart",
    );
    
    my $d = Chart::Gnuplot::Pie::DataSet->new(
        data => [
            ['Item 1', 7500],
            ['Item 2', 3500],
            ['Item 3', 2000],
            ['Item 4', 4500],
        ],
    );
    
    $c->plot2d($d);

=for HTML <p><img src="http://sourceforge.net/apps/gallery/chartgnuplotpie/main.php?g2_view=core.DownloadItem&g2_itemId=17&g2_serialNumber=4"/></p>

=item 2. A simple 3D pie chart

    my $c = Chart::Gnuplot::Pie->new(
        output   => "pie3d.png",
        title    => "Simple pie chart",
    );
    
    my $d = Chart::Gnuplot::Pie::DataSet->new(
        data => [
            ['Item 1', 65],
            ['Item 2', 60],
            ['Item 3', 20],
            ['Item 4', 45],
            ['Item 5', 25],
        ],
    );
    
    $c->plot3d($d);

=for HTML <p><img src="http://sourceforge.net/apps/gallery/chartgnuplotpie/main.php?g2_view=core.DownloadItem&g2_itemId=29&g2_serialNumber=4"/></p>

=back

=head1 REQUIREMENT

L<Chart::Gnuplot>

Gnuplot L<http://www.gnuplot.info>

ImageMagick L<http://www.imagemagick.org> (for full feature)

=head1 SEE ALSO

L<Chart::Gnuplot>

Impossible Gnuplot Graphs: L<http://www.phyast.pitt.edu/~zov1/gnuplot/html/pie.html>

=head1 AUTHOR

Ka-Wai Mak <kwmak@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009, 2011, 2013 Ka-Wai Mak. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
