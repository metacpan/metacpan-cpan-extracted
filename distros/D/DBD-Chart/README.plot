NAME
    DBD::Chart::Plot - Graph/chart Plotting engine for DBD::Chart

SYNOPSIS
        use DBD::Chart::Plot; 
    
        my $img = DBD::Chart::Plot->new(); 
        my $anotherImg = DBD::Chart::Plot->new($image_width, $image_height); 
    
        $img->setPoints(\@xdataset, \@ydataset, 'blue line nopoints');
    
        $img->setOptions (
            horizMargin => 75,
            vertMargin => 100,
            title => 'My Graph Title',
            xAxisLabel => 'my X label',
            yAxisLabel => 'my Y label' );
    
        print $img->plot;

DESCRIPTION
    DBD::Chart::Plot creates images of various types of graphs for 2 or 3
    dimensional data. Unlike GD::Graph, the input data sets do not need to
    be uniformly distributed in the domain (X-axis), and may be either
    numeric, temporal, or symbolic.

    DBD::Chart::Plot supports the following:

    - multiple data set plots
    - line graphs, areagraphs, scatter graphs, linegraphs w/ points,
    candlestick graphs, barcharts (2-D, 3-D, and 3-axis), histograms,
    piecharts, box & whisker charts (aka boxcharts), and Gantt charts
    - optional iconic barcharts or datapoints
    - a wide selection of colors, and point shapes
    - optional horizontal and/or vertical gridlines
    - optional legend
    - auto-sizing of axes based in input dataset ranges
    - optional symbolic and temproal (i.e., non-numeric) domain values
    - automatic sorting of numeric and temporal input datasets to assure
    proper order of plotting
    - optional X, Y, and Z axis labels
    - optional X and/or Y logarithmic scaling
    - optional title
    - optional adjustment of horizontal and vertical margins
    - optional HTML or Perl imagemap generation
    - composite images from multiple graphs
    - user programmable colors
PREREQUISITES
    GD.pm module minimum version 1.26 (available on CPAN)
        GD.pm requires additional libraries:

    libgd
    libpng
    zlib
USAGE
  Create an image object: new()

            use DBD::Chart::Plot; 

            my $img = DBD::Chart::Plot->new; 
            my $img = DBD::Chart::Plot->new ( $image_width, $image_height ); 
            my $img = DBD::Chart::Plot->new ( $image_width, $image_height, \%colormap ); 
            my $anotherImg = new DBD::Chart::Plot; 

        Creates an empty image. If image size is not specified, the default
        is 400 x 300 pixels.

  Graph-wide options: setOptions()

            $img->setOptions (_title => 'My Graph Title',
                xAxisLabel => 'my X label',
                yAxisLabel => 'my Y label',
                xLog => 0,
                yLog => 0,
                horizMargin => $numHorPixels,
                vertMargin => $numvertPixels,
                horizGrid => 1,
                vertGrid => 1,
                showValues => 1,
                legend => \@plotnames,
                genMap => 'a_valid_HTML_anchor_name',
                mapURL => 'http://some.website.com/cgi-bin/cgi.pl',
                icon => [ 'redstar.png', 'bluestar.png' ]
                symDomain => 0
             );

        As many (or few) of the options may be specified as desired.

    width, height
        The width and height of the image in pixels. Default is 400 and 300,
        respectively.

    genMap, mapType, mapURL, mapScript
        Control generation of imagemaps. When genMap is set to a legal HTML
        anchor name, an image map of the specified type is created for the
        image. The default type is 'HTML' if no mapType is specified. Legal
        types are 'HTML' and 'PERL'.

        If mapType is 'PERL', then Perl script compatible text is generated
        representing an array ref of hashrefs containing the following
        attributes:

        plotnum => the plot number to which this hashref applies (to support
        multi-range graphs), starting at zero.

        x => the domain value for the plot element

        y => the range value for the plot element

        z => the Z axis value for 3-axis bar charts, if any

        shape => the shape of the hotspot area of the plot element, same as
        for HTML: 'RECT', 'CIRCLE', 'POLY'

        coordinates => an arrayref of the (x,y) pixel coordinates of the
        hotspot area to be mapped; for CIRCLE shape, its (x-center,
        y-center, radius), for RECT, its (upper-left corner x, upper-left
        corner y, lower-right corner x, lower-right corner y), and for POLY
        its the set of vertices (x,y)'s.

        If the mapType is 'HTML', then either the mapURL or mapScript (or
        both) can be specified. mapURL specifies a legal URL string, e.g.,
        'http://www.mysite.com/cgi-bin/plotproc.pl?plotnum=:PLOTNUM&X=:X&Y=:
        Y', which will be added to the AREA tags generated for each mapped
        plot element. mapScript specifies any legal HTML scripting tag,
        e.g., 'ONCLICK="alert('Got X=:X, Y=:Y')"' to be added to each
        generated AREA tag.

        For both mapURL and mapScript, special variables :PLOTNUM, :X, :Y,
        :Z can be specified which are replaced by the following values when
        the imagemap is generated.

        Refer to the IMAGEMAP description at
        www.presicient.com/dbdchart#imagemap for details.

    horizMargin, vertMargin
        Sets the number of pixels around the actual plot area.

    xAxisLabel, yAxisLabel, zAxisLabel
        Sets the label strings for each axis.

    xLog, yLog
        When set to a non-zero value, causes the associated axis to be
        rendered in log10 format. Z axis plots are currently only symbolic,
        so no zLog is supported.

    title
        Sets a title string to be rendered at the bottom center of the image
        in bold text.

    signature
        Sets a string to be rendered in tiny font at the lower right corner
        of the image, e.g., 'Copyright(C) 2001, Presicient Corp.'.

    legend
        Set to an array ref of domain names to be displayed in a legend for
        the various plots. The legend is displayed below the chart, left
        justified and placed above the chart title string. The legend for
        each plot is printed in the same color as the plot. If a point shape
        or icon has been specified for a plot, then the point shape is
        printed with the label; otherwise, a small line segment is printed
        with the label. Due to space limitations, the number of datasets
        plotted should be limited to 8 or less.

    showValues
        When set to a non-zero value, causes the data points for each
        plotted element to be displayed next to hte plot point.

    horizGrid, vertGrid
        Causes grid lines to be drawn completely across the plot area.

    xAxisVert
        When set to a non-zero value, causes the X axis tick labels to be
        rendered vertically.

    keepOrigin
        When set to a non-zero value, forces the (0,0) data point into the
        graph. Normally, DBD::Chart::Plot will heuristically clip away from
        the origin is the plot never crosses the origin.

    bgColor
        Sets the background color of the image. Default is white.

    threed
        When set to a non-zero value for barcharts, causes the bars to be
        rendered in a 3-D effect.

    icons
        Set to an arrayref of image filenames. The images will be used to
        plot iconic barcharts or individual plot points, if the 'icon' shape
        is specified in the property string supplied to the setPoints()
        function (defined below). The array must match 1-to-1 with the
        number of plots in the image; icons and predefined point shapes can
        be mixed in the same image by setting the icon arrayref entry to
        undef for plots using predefined shapes in the properties string.

    symDomain
        When set to a non-zero value, causes the domain to be treated as
        discrete symbolic values which are evenly distributed over the
        X-axis. Numeric domains are plotted as scaled values in the image.

    timeDomain
        When set to a valid format string, the domain data points are
        treated as associated temporal values (e.g., date, time, timestamp,
        interval). The values supplied by setPoints will be strings of the
        specified format (e.g., 'YYYY-MM-DD'), but will be converted to
        numeric time values for purposes of plotting, so the domain is
        treated as continuous numeric data, rather than discrete symbolic.
        Note that for barcharts, histograms, candlesticks, or piecharts,
        temporal domains are treated as symbolic for plotting purposes, but
        are sorted as numeric values.

    timeRange
        When set to a valid format string, the range data points are treated
        as associated temporal values (e.g., date, time, timestamp,
        interval). The values supplied by setPoints will be strings of the
        specified format (e.g., 'YYYY-MM-DD'), but will be converted to
        numeric time values for purposes of plotting, so the range is
        treated as continuous numeric data.

    gridColor
        Sets the color of the axis lines and ticks. Default is black.

    textColor
        Sets the color used to render text in the image. Default is black.

    font - NOT YET SUPPORTED
        Sets the font used to render text in the image. Default is default
        GD fonts (gdMedium, gdSmall, etc.).

    logo
        Specifies the name of an image file to be drawn into the background
        of the image. The logo image is centered in the plot image, and will
        be clipped if the logo size exceeds the defined width or height of
        the plot image.

        By default, the graph will be centered within the image, with 50
        pixel margin around the graph border. You can obtain more space for
        titles or labels by increasing the image size or increasing the
        margin values.

  Establish data points: setPoints()

            $img->setPoints(\@xdata, \@ydata);
            $img->setPoints(\@xdata, \@ydata, 'blue line');
            $img->setPoints(\@xdata, \@ymindata, \@ymaxdata, 'blue points');
            $img->setPoints(\@xdata, \@ydata, \@zdata, 'blue bar zaxis');

        Copies the input array values for later plotting. May be called
        repeatedly to establish multiple plots in a single graph. Returns a
        positive integer on success and "undef" on failure. The global graph
        properties should be set (via setOptions()) prior to setting the
        data points. The error() method can be used to retrieve an error
        message. X-axis values may be non-numeric, in which case the set of
        domain values is uniformly distributed along the X-axis. Numeric
        X-axis data will be properly scaled, including logarithmic scaling
        is requested.

        If two sets of range data (ymindata and ymaxdata in the example
        above) are supplied, and the properties string does not specify a
        3-axis barchart, a candlestick graph is rendered, in which case the
        domain data is assumed non-numeric and is uniformly distributed, the
        first range data array is used as the bottom value, and the second
        range data array is used as the top value of each candlestick.
        Pointshapes may be specified, in which case the top and bottom of
        each stick will be capped with the specified pointshape. The range
        and/or domain axis may be logarithmically scaled. If value display
        is requested, the range value of both the top and bottom of each
        stick will be printed above and below the stick, respectively.

        Plot properties: Properties of each dataset plot can be set with an
        optional string as the third argument. Properties are separated by
        spaces. The following properties may be set on a per-plot basis
        (defaults in capitals):

            COLOR     CHARTSTYLE  USE POINTS?   POINTSHAPE 
            -----     ---------  -----------   ----------
                BLACK       LINE        POINTS     FILLCIRCLE
                white      noline      nopoints    opencircle
                lgray       fill                   fillsquare  
                gray        bar                    opensquare
                dgray       pie                    filldiamond
                lblue       box                    opendiamond
                blue       zaxis                   horizcross
                dblue      histo                   diagcross
                gold                               icon
                lyellow 
                yellow
                dyellow
                lgreen
                green
                dgreen
                lred
                red
                dred
                lpurple 
                purple
                dpurple
                lorange
                orange
                pink
                dpink
                marine
                cyan    
                lbrown
                dbrown

        E.g., if you want a red scatter plot (red dots but no lines) with
        filled diamonds, you could specify

            $p->setPoints (\@xdata, \@ydata, 'Points Noline Red filldiamond');
    
        Specifying icon for the pointshape requires setting the icon object
        attribute to a list of compatible image filenames (as an arrayref,
        see below). In that case, the icon images are displayed centered on
        the associated plotpoints. For 2-D barcharts, a stack of the icon is
        used to display the bars, including a proportionally clipped icon
        image to cap the bar if needed.

  Draw the image: plot()

             $img->plot();

        Draws the image and returns it as a string. To save the image to a
        file:

            open (WR,'>plot.png') or die ("Failed to write file: $!");
            binmode WR;            # for DOSish platforms
            print WR $img->plot();
            close WR;

        To return the graph to a browser via HTTP:

            print "Content-type: image/png\n\n";
            print  $img->plot();

        The range of values on each axis is automatically computed to
        optimize the data placement in the largest possible area of the
        image. As a result, the origin (0, 0) axes may be omitted if none of
        the datasets cross them at any point. Instead, the axes will be
        drawn on the left and bottom borders using the value ranges that
        appropriately fit the dataset(s).

  Fetch the imagemap: getMap()

             $img->getMap();

        Returns the imagemap for the chart. If no mapType was set, or if
        mapType was set to HTML. the returned value is a valid
        <MAP...><AREA...></MAP> HTML string. If mapType was set to 'Perl', a
        Perl-compatible arrayref declaration string is returned.

        The resulting imagemap will be applied as follows:

    2 axis 2-D Barcharts and Histograms
        Each bar is mapped individually.

    Piecharts
        Each wedge is mapped. The CGI parameter values are used slightly
        differently than described above:

        X=<wedge-label>&Y=<wedge-value>&Z=<wedge-percent>

    3-D Barcharts (either 2 or 3 axis)
        The top face of each bar is mapped. The Z CGI parameter will be
        empty for 2 axis barcharts.

    3-D Histograms (either 2 or 3 axis)
        The right face of each bar is mapped. The Z CGI parameter will be
        empty for 2 axis barcharts.

    Line, point, area graphs
        A 4 pixel diameter circle around each datapoint is mapped.

    Candlestick graphs
        A 4 pixel diameter circle around both the top and bottom datapoints
        of each stick are mapped.

    Boxcharts
        The area of the box is mapped, and 4-pixel diameter circles are
        mapped at the end of each extreme whisker.

    Gantt Charts
        The area of each bar in the chart is mapped.

TO DO
    programmable fonts
    symbolic ranges for scatter graphs
    surfacemaps
    SVG support
AUTHOR
        Copyright (c) 2001 by Presicient Corporation.
        (darnold@presicient.com)

        You may distribute this module under the terms of the Artistic
        License, as specified in the Perl README file.

SEE ALSO
        GD, DBD::Chart. (All available on CPAN).

