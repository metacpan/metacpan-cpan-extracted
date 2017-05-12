## @file
# Implementation of Chart::Base
#
# written by
# @author david bonner (dbonner@cs.bu.edu)
#
# maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10

## @mainpage Chart::Base
#
# Basic Class of Chart from which all the other classes are derived.

## @class Chart::Base
# @brief Base class for Chart; all other classes derived from here
#
# Base class from which all other classes are derived.
# This class provides all functions which are common for
# all classes
package Chart::Base;

# Uses
# GD
# Carp
# FileHandle
use GD;
use Carp;
use FileHandle;
use Chart::Constants;
use GD::Image;

$Chart::Base::VERSION = '2.4.10';

use vars qw(%named_colors);
use strict;

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @cmethod object new()
# @return A new object.
#
# @brief
# Standard normal constructor.\n
# Calls
# @see _init
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

    bless $self, $class;
    $self->_init(@_);

    return $self;
}

## @method int set(%opts)
# Set all options
#
# @details
#  main method for customizing the chart, lets users
#  specify values for different parameters\n
#  The options are saved locally to be able to output them
#  via @see getopts()
#
# @param[in] opts Hash of options to the Chart
# @return ok or croak
#
sub set
{
    my $self = shift;
    my %opts = @_;

    # basic error checking on the options, just warn 'em
    unless ( $#_ % 2 )
    {
        carp "Whoops, some option to be set didn't have a value.\n", "You might want to look at that.\n";
    }

    # set the options
    for ( keys %opts )
    {
        $self->{$_} = $opts{$_};
        $self->{saveopts}->{$_} = $opts{$_};

        # if someone wants to change the grid_lines color, we should set all
        # the colors of the grid_lines
        if ( $_ =~ /^colors$/ )
        {
            my %hash = %{ $opts{$_} };
            foreach my $key ( sort keys %hash )
            {
                if ( $key =~ /^grid_lines$/ )
                {

                    # ORIG:
                    #$self->{'colors'}{'y_grid_lines'}    = $hash{'grid_lines'},
                    #  $self->{'colors'}{'x_grid_lines'}  = $hash{'grid_lines'},
                    #  $self->{'colors'}{'y2_grid_lines'} = $hash{'grid_lines'};
                    #
                    # NEW!!!!!!!!!!!!!!!!!!
                    if ( ref( $hash{'grid_lines'} ) eq 'ARRAY' )
                    {
                        my @aLocal = ( $hash{'grid_lines'}[0], $hash{'grid_lines'}[1], $hash{'grid_lines'}[2] );
                        $self->{'colors'}{'y_grid_lines'}  = [@aLocal];
                        $self->{'colors'}{'x_grid_lines'}  = [@aLocal];
                        $self->{'colors'}{'y2_grid_lines'} = [@aLocal];
                    }
                    elsif ( ref( \$hash{'grid_lines'} ) eq 'SCALAR' )
                    {
                        my $sLocal = $hash{'grid_lines'};
                        $self->{'colors'}{'y_grid_lines'}  = $sLocal;
                        $self->{'colors'}{'x_grid_lines'}  = $sLocal;
                        $self->{'colors'}{'y2_grid_lines'} = $sLocal;
                    }
                    else
                    {
                        carp "colors{'grid_lines'} is not SCALAR and not ARRAY\n";
                    }
                }
            }
        }
    }

    # now return
    return 1;
}

## @method hash getopts()
# @return hash of all set options so far
#
# @brief
# get all options
#
# @details
# @return set options as a hash
sub getopts
{
    my $self = shift;
    my %opts = ();

    foreach ( keys %{ $self->{saveopts} } )
    {
        $opts{$_} = $self->{saveopts};
    }
    return %opts;
}

## @method int add_pt(@data)
# Graph API\n
# Add one dataset (as a list) to the dataref
#
# @param data Dataset to add

## @method add_pt(\\\@data)
# Graph API\n
# Add one dataset (as a reference to a list) to the dataref
# via
# <pre>
# for ( 0 .. $#data )
# {
#    push @{ $self->{'dataref'}->[$_] }, $data[$_];
# }
# </pre>
#
# @param data Dataset to add
#
sub add_pt
{
    my $self = shift;
    my @data = ();

    if ( ( ref $_[0] ) =~ /^ARRAY/ )
    {
        my $rdata = shift;
        @data = @$rdata if @$rdata;
    }
    elsif ( ( ref \$_[0] ) =~ /^SCALAR/ )
    {
        if ( defined $_[0] )
        {
            @data = @_;
        }
    }
    else
    {
        croak "Not an array or reference to array";
    }

    # error check the data (carp, don't croak)
    if ( $self->{'dataref'} && ( $#{ $self->{'dataref'} } != $#data ) )
    {
        carp "New point to be added has an incorrect number of data sets";
        return 0;
    }

    # copy it into the dataref
    for ( 0 .. $#data )
    {
        push @{ $self->{'dataref'}->[$_] }, $data[$_];
    }

    # now return
    return 1;
}

## @method int add_dataset(@data)
#  Graph API\n
# Add many datasets (implemented as a list)
# to the dataref,
#
# @param data Dataset (list) to add

## @method int add_dataset(\\\@data)
#  Graph API\n
# Add many datasets (implemented as a references to alist)
# to the dataref,
#
# @param data Dataset (reference to a list) to add
sub add_dataset
{
    my $self = shift;
    my @data = ();

    if ( ( ref $_[0] ) =~ /^ARRAY/ )
    {
        my $rdata = shift;
        @data = @$rdata if @$rdata;
    }
    elsif ( ( ref \$_[0] ) =~ /^SCALAR/ )
    {
        if ( defined $_[0] )
        {
            @data = @_;
        }
    }
    else
    {
        croak "Not an array or reference to array";
        return;
    }

    # error check the data (carp, don't croak)
    if ( $self->{'dataref'} && ( $#{ $self->{'dataref'}->[0] } != $#data ) )
    {
        carp "New data set to be added has an incorrect number of points";
    }

    # copy it into the dataref
    push @{ $self->{'dataref'} }, [@data];

    # now return
    return 1;
}

## @method int add_datafile($filename,$format)
#  Graph API\n
# it's also possible to add a complete datafile\n
# Uses
# @see add_pt
# @see add_dataset
#
# @param[in] filename Name of file which contents is to be added
# @param[in] format 'pt' or 'set' to distiguish between function add_pt() in case of 'pt'
#                 or function add_dataset() in case of 'set'
sub add_datafile
{
    my $self     = shift;
    my $filename = shift;
    my $format   = shift;
    my ( $File, @array );

    # do some ugly checking to see if they gave me
    # a filehandle or a file name
    if ( ( ref \$filename ) eq 'SCALAR' )
    {

        # they gave me a file name
        open( $File, $filename ) or croak "Can't open the datafile: $filename.\n";
    }
    elsif ( ( ref \$filename ) =~ /^(?:REF|GLOB)$/ )
    {

        # either a FileHandle object or a regular file handle
        $File = $filename;
    }
    else
    {
        carp "I'm not sure what kind of datafile you gave me,\n", "but it wasn't a filename or a filehandle.\n";
    }

    #add the data
    while (<$File>)
    {
        @array = split;
        if ( $#array > -1 )
        {
            if ( $format =~ m/^pt$/i )
            {
                $self->add_pt(@array);
            }
            elsif ( $format =~ m/^set$/i )
            {
                $self->add_dataset(@array);
            }
            else
            {
                carp "Tell me what kind of file you gave me: 'pt' or 'set'\n";
            }
        }
    }
    close($File);
}

## @method int clear_data()
# Clear Graph API (by undefining 'dataref'
# @return Status of function
sub clear_data
{
    my $self = shift;

    # undef the internal data reference
    $self->{'dataref'} = undef;

    # now return
    return 1;
}

## @method arrayref get_data()
#  Get array of data of the last graph
# @return Reference to data set of the last graph
sub get_data
{
    my $self = shift;
    my $ref  = [];
    my ( $i, $j );

    # give them a copy, not a reference into the object
    for $i ( 0 .. $#{ $self->{'dataref'} } )
    {
        @{ $ref->[$i] } = @{ $self->{'dataref'}->[$i] }
## speedup, compared to...
          #   for $j (0..$#{$self->{'dataref'}->[$i]}) {
          #     $ref->[$i][$j] = $self->{'dataref'}->[$i][$j];
          #   }
    }

    # return it
    return $ref;
}

## @method int png($file, $dataref)
# Produce the graph of options set in png format.
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and plot the data
# @see _set_colors
# @see _copy_data
# @see _check_data
# @see _draw
# @param[in] file Name of file to write graph to
# @param[in] dataref Reference to external data space
# @return Status of the plot
sub png
{
    my $self    = shift;
    my $file    = shift;
    my $dataref = shift;
    my $fh;

    # do some ugly checking to see if they gave me
    # a filehandle or a file name
    if ( ( ref \$file ) eq 'SCALAR' )
    {

        # they gave me a file name
        # Try to delete an existing file
        if ( -f $file )
        {
            my $number_deleted_files = unlink $file;
            if ( $number_deleted_files != 1 )
            {
                croak "Error: File \"$file\" did already exist, but it failed to delete it";
            }
        }
        $fh = FileHandle->new(">$file");
        if ( !defined $fh )
        {
            croak "Error: File \"$file\" could not be created!\n";
        }
    }
    elsif ( ( ref \$file ) =~ /^(?:REF|GLOB)$/ )
    {

        # either a FileHandle object or a regular file handle
        $fh = $file;
    }
    else
    {
        croak "I'm not sure what you gave me to write this png to,\n", "but it wasn't a filename or a filehandle.\n";
    }

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # now write it to the file handle, and don't forget
    # to be nice to the poor ppl using nt
    binmode $fh;

    print $fh $self->{'gd_obj'}->png();

    # now exit
    return 1;
}

## @method int cgi_png($dataref)
# Produce the graph of options set in png format to be directly
# written for CGI.
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and plot the data
# @param[in] dataref Reference to external data space
# @return Status of the plot
sub cgi_png
{
    my $self    = shift;
    my $dataref = shift;

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # print the header (ripped the crlf octal from the CGI module)
    if ( $self->true( $self->{no_cache} ) )
    {
        print "Content-type: image/png\015\012Pragma: no-cache\015\012\015\012";
    }
    else
    {
        print "Content-type: image/png\015\012\015\012";
    }

    # now print the png, and binmode it first so Windows-XX likes us
    binmode STDOUT;
    print STDOUT $self->{'gd_obj'}->png();

    # now exit
    return 1;
}

## @method int scalar_png($dataref)
# Produce the graph of options set in PNG format to be directly returned
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and return the image to the caller
#
# @param dataref Reference to data
# @return returns the png image as a scalar value, so that
#         the programmer-user can do whatever the heck
#         s/he wants to with it
sub scalar_png
{
    my $self    = shift;
    my $dataref = shift;

    #allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # returns the png image as a scalar value, so that
    # the programmer/user can do whatever the she/he wants to with it
    return $self->{'gd_obj'}->png();
}

## @method int jpeg($file,$dataref)
# Produce the graph of options set in JPG format to be directly plotted.\n
#
# Called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and plot the data.
# The output has the jpeg format in opposite to png format produced by
# @see png
#
# Uses the following private functions:\n
# @see _set_colors
# @see _copy_data
# @see _check_data
# @see _draw
#
# @param[in] file Name of file to write graph to
# @param[in] dataref Reference to external data space
# @return Status of the plot
#
sub jpeg
{
    my $self    = shift;
    my $file    = shift;
    my $dataref = shift;
    my $fh;

    # do some ugly checking to see if they gave me
    # a filehandle or a file name
    if ( ( ref \$file ) eq 'SCALAR' )
    {

        # they gave me a file name
        # Try to delete an existing file
        if ( -f $file )
        {
            my $number_deleted_files = unlink $file;
            if ( $number_deleted_files != 1 )
            {
                croak "Error: File \"$file\" did already exist, but it fails to delete it";
            }
        }
        $fh = FileHandle->new(">$file");
        if ( !defined $fh )
        {
            croak "Error: File \"$file\" could not be created!\n";
        }
    }
    elsif ( ( ref \$file ) =~ /^(?:REF|GLOB)$/ )
    {

        # either a FileHandle object or a regular file handle
        $fh = $file;
    }
    else
    {
        croak "I'm not sure what you gave me to write this jpeg to,\n", "but it wasn't a filename or a filehandle.\n";
    }

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data;

    # pass off the real work to the appropriate subs
    $self->_draw();

    # now write it to the file handle, and don't forget
    # to be nice to the poor ppl using Windows-XX
    binmode $fh;
    print $fh $self->{'gd_obj'}->jpeg( [100] );    # high quality need

    # now exit
    return 1;
}

## @method int cgi_jpeg($dataref)
# Produce the graph of options set in JPG format to be directly
# for CGI.
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and plot the data
# @param[in] dataref Reference to external data space
# @return Status of the plot
sub cgi_jpeg
{
    my $self    = shift;
    my $dataref = shift;

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # print the header (ripped the crlf octal from the CGI module)
    if ( $self->true( $self->{no_cache} ) )
    {
        print "Content-type: image/jpeg\015\012Pragma: no-cache\015\012\015\012";
    }
    else
    {
        print "Content-type: image/jpeg\015\012\015\012";
    }

    # now print the jpeg, and binmode it first so Windows-XX likes us
    binmode STDOUT;
    print STDOUT $self->{'gd_obj'}->jpeg( [100] );

    # now exit
    return 1;
}

## @method int scalar_jpeg($dataref)
# Produce the graph of options set in JPG format to be directly returned
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and return the image to the caller
#
# @param dataref Reference to data area
# @return returns the jpeg image as a scalar value, so that
#         the programmer-user can do whatever the heck
#         s/he wants to with it
sub scalar_jpeg
{
    my $self    = shift;
    my $dataref = shift;

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # returns the jpeg image as a scalar value, so that
    # the programmer-user can do whatever the heck
    # s/he wants to with it
    $self->{'gd_obj'}->jpeg( [100] );
}

## @method int make_gd($dataref)
# Produce the graph of options set in GD format to be directly
#
# called after the options are set, this method
# invokes all my private methods to actually
# draw the chart and plot the data
# @param dataref Reference to data
# @return Status of the plot
sub make_gd
{
    my $self    = shift;
    my $dataref = shift;

    # allocate the background color
    $self->_set_colors();

    # make sure the object has its copy of the data
    $self->_copy_data($dataref);

    # do a sanity check on the data, and collect some basic facts
    # about the data
    $self->_check_data();

    # pass off the real work to the appropriate subs
    $self->_draw();

    # return the GD::Image object that we've drawn into
    return $self->{'gd_obj'};
}

## @method imagemap_dump()
#  get the information to turn the chart into an imagemap
#
# @return Reference to an array of the image
sub imagemap_dump
{
    my $self = shift;
    my $ref  = [];
    my ( $i, $j );

    # croak if they didn't ask me to remember the data, or if they're asking
    # for the data before I generate it
    unless ( ( $self->true( $self->{'imagemap'} ) ) && $self->{'imagemap_data'} )
    {
        croak "You need to set the imagemap option to true, and then call the png method, before you can get the imagemap data";
    }

    # can't just return a ref to my internal structures...
    for $i ( 0 .. $#{ $self->{'imagemap_data'} } )
    {
        for $j ( 0 .. $#{ $self->{'imagemap_data'}->[$i] } )
        {
            $ref->[$i][$j] = [ @{ $self->{'imagemap_data'}->[$i][$j] } ];
        }
    }

    # return their copy
    return $ref;
}

## @method minimum (@array)
# determine minimum of an array of values
# @param array List of numerical values (\@array)
# @return Minimal value of list of values
sub minimum
{
    my $self  = shift;
    my @array = @_;

    return undef if !@array;
    my $min = $array[0];
    for ( my $iIndex = 0 ; $iIndex < scalar @array ; $iIndex++ )
    {
        $min = $array[$iIndex] if ( $min > $array[$iIndex] );
    }
    $min;
}

## @method maximum(@array)
# determine maximum of an array of values
# @param array List of numerical values (@array)
# @return Maximal value of list of values
sub maximum
{
    my $self  = shift;
    my @array = @_;

    return undef if !@array;
    my $max = $array[0];
    for ( my $iIndex = 0 ; $iIndex < scalar @array ; $iIndex++ )
    {
        $max = $array[$iIndex] if ( $max < $array[$iIndex] );
    }
    $max;
}

## @method arccos($a)
# Function arccos(a)
# @param a Value
# @return arccos(a)
sub arccos
{
    my $self = shift;
    my $a    = shift;

    return ( atan2( sqrt( 1 - $a * $a ), $a ) );
}

## @method arcsin($a)
# Function arcsin(a)
# @param  a Value
# @return arcsin(a)
sub arcsin
{
    my $self = shift;
    my $a    = shift;

    return ( atan2( $a, sqrt( 1 - $a * $a ) ) );
}

## @method true($arg)
# determine true value of argument
# @param[in] arg Bool value to check for true
# @return 1 if argument is equal to TRUE, true, 1, t, T, and defined
sub true
{
    my $pkg = shift;
    my $arg = shift;

    if ( !defined($arg) )
    {
        return 0;
    }

    if (   $arg eq 'true'
        || $arg eq 'TRUE'
        || $arg eq 't'
        || $arg eq 'T'
        || $arg eq '1' )
    {
        return 1;
    }

    return 0;
}

## @method false($arg)
# determine false value of argument
# @param[in] arg Bool value to check for true
# @return 1 if argument is equal to false, FALSE, 0, f, F or undefined
sub false
{
    my $pkg = shift;
    my $arg = shift;

    if ( !defined($arg) )
    {
        return 1;
    }

    if (   $arg eq 'false'
        || $arg eq 'FALSE'
        || $arg eq 'f'
        || $arg eq 'F'
        || $arg eq '0'
        || $arg eq 'none' )
    {
        return 1;
    }

    return 0;
}

## @method modulo($a,$b)
# Calculate float($a % $b) as the internal operator '%'
# does only calculate in integers
# @param[in] a a in a%b
# @param[in] b b in a%b
# @return $a % $b in float
sub modulo
{
    my $pkg = shift;
    my $a   = shift;
    my $b   = shift;

    my $erg = 0.0;

    if ( !defined($a) || !defined($b) || $b == 0 )
    {
        die "Modulo needs valid parameters!"

          #return $erg;
    }

    my $div = $a / $b;

    $erg = $a - int($div) * $b;

    return $erg;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private int _init($x,$y)
# Initialize all default options here
# @param[in] x   Width of the final image in pixels (Default: 400)
# @param[in] y   Height of the final image in pixels (Default: 300)
#
sub _init
{
    my $self = shift;
    my $x    = shift || 400;    # give them a 400x300 image
    my $y    = shift || 300;    # unless they say otherwise

    # get the gd object

    # Reference to new GD::Image
    $self->{'gd_obj'} = GD::Image->new( $x, $y );

    # start keeping track of used space
    # actual current y min Value
    $self->{'curr_y_min'} = 0;
    $self->{'curr_y_max'} = $y;    # maximum pixel in y direction (down)
    $self->{'curr_x_min'} = 0;
    $self->{'curr_x_max'} = $x;    # maximum pixel in x direction (right)

    # use a 10 pixel border around the whole png
    $self->{'png_border'} = 10;

    # leave some space around the text fields
    $self->{'text_space'} = 2;

    # and leave some more space around the chart itself
    $self->{'graph_border'} = 10;

    # leave a bit of space inside the legend box
    $self->{'legend_space'} = 4;

    # set some default fonts
    $self->{'title_font'}        = gdLargeFont,
      $self->{'sub_title_font'}  = gdLargeFont,
      $self->{'legend_font'}     = gdSmallFont,
      $self->{'label_font'}      = gdMediumBoldFont,
      $self->{'tick_label_font'} = gdSmallFont;

    # put the legend on the bottom of the chart
    $self->{'legend'} = 'right';

    # default to an empty list of labels
    $self->{'legend_labels'} = [];

    # use 20 pixel length example lines in the legend
    $self->{'legend_example_size'} = 20;

    # Set the maximum & minimum number of ticks to use.
    $self->{'y_ticks'}          = 6,
      $self->{'min_y_ticks'}    = 6,
      $self->{'max_y_ticks'}    = 100,
      $self->{'x_number_ticks'} = 1,
      $self->{'min_x_ticks'}    = 6,
      $self->{'max_x_ticks'}    = 100;

    # make the ticks 4 pixels long
    $self->{'tick_len'} = 4;

    # no custom y tick labels
    $self->{'y_tick_labels'} = undef;

    # no patterns
    $self->{'patterns'} = undef;

    # let the lines in Chart::Lines be 6 pixels wide
    $self->{'brush_size'} = 6;

    # let the points in Chart::Points and Chart::LinesPoints be 18 pixels wide
    $self->{'pt_size'} = 18;

    # use the old non-spaced bars
    $self->{'spaced_bars'} = 'true';

    # use the new grey background for the plots
    $self->{'grey_background'} = 'true';

    # don't default to transparent
    $self->{'transparent'} = 'false';

    # default to "normal" x_tick drawing
    $self->{'x_ticks'} = 'normal';

    # we're not a component until Chart::Composite says we are
    $self->{'component'} = 'false';

    # don't force the y-axes in a Composite chare to be the same
    $self->{'same_y_axes'} = 'false';

    # plot rectangeles in the legend instead of lines in a composite chart
    $self->{'legend_example_height'} = 'false';

    # don't force integer y-ticks
    $self->{'integer_ticks_only'} = 'false';

    # don't forbid a false zero scale.
    $self->{'include_zero'} = 'false';

    # don't waste time/memory by storing imagemap info unless they ask
    $self->{'imagemap'} = 'false';

    # default for grid_lines is off
    $self->{grid_lines}      = 'false',
      $self->{x_grid_lines}  = 'false',
      $self->{y_grid_lines}  = 'false',
      $self->{y2_grid_lines} = 'false';

    # default for no_cache is false.  (it breaks netscape 4.5)
    $self->{no_cache} = 'false';

    # default value for skip_y_ticks for the labels
    $self->{skip_y_ticks} = 1;

    # default value for skip_int_ticks only for integer_ticks_only
    $self->{skip_int_ticks} = 1;

    # default value for precision
    $self->{precision} = 3;

    # default value for legend label values in pie charts
    $self->{legend_label_values} = 'value';

    #  default value for the labels in a pie chart
    $self->{label_values} = 'percent';

    # default position for the y-axes
    $self->{y_axes} = 'left';

    # copies of the current values at the x-ticks function
    $self->{temp_x_min} = 0;
    $self->{temp_x_max} = 0;
    $self->{temp_y_min} = 0;
    $self->{temp_y_max} = 0;

    # Instance for a sum
    $self->{sum} = 0;

    # Don't sort the data unless they ask
    $self->{'sort'} = 'false';

    # The Interval for drawing the x-axes in the split module
    $self->{'interval'} = undef;

    # The start value for the split chart
    $self->{'start'} = undef;

    # How many ticks do i have to draw at the x-axes in one interval of a split-plot?
    $self->{'interval_ticks'} = 6;

    # Draw the Lines in the split-chart normal
    $self->{'scale'} = 1;

    # Make a x-y plot
    $self->{'xy_plot'} = 'false';

    # min and max for xy plot
    $self->{'x_min_val'} = 1;
    $self->{'x_max_val'} = 1;

    # use the same error value in ErrorBars
    $self->{'same_error'} = 'false';

    # Set the minimum and maximum number of circles to draw in a direction chart
    $self->{'min_circles'} = 4, $self->{'max_circles'} = 100;

    # set the style of a direction diagramm
    $self->{'point'} = 'true', $self->{'line'} = 'false', $self->{'arrow'} = 'false';

    # The number of angel axes in a direction Chart
    $self->{'angle_interval'} = 30;

    # dont use different 'x_axes' in a direction Chart
    $self->{'pairs'} = 'false';

    # polarplot for a direction Chart (not yet tested)
    $self->{'polar'} = 'false';

    # guiding lines in a Pie Chart
    $self->{'legend_lines'} = 'false';

    # Ring Chart instead of Pie
    $self->{'ring'} = 1;    # width of ring; i.e. normal pie

    # stepline for Lines, LinesPoints
    $self->{'stepline'}      = 'false';
    $self->{'stepline_mode'} = 'end';     # begin, end

    # used function to transform x- and y-tick labels to strings
    $self->{f_x_tick} = \&_default_f_tick, $self->{f_y_tick} = \&_default_f_tick, $self->{f_z_tick} = \&_default_f_tick;

    # default color specs for various color roles.
    # Subclasses should extend as needed.
    my $d = 0;
    $self->{'colors_default_spec'} = {
        background      => 'white',
        misc            => 'black',
        text            => 'black',
        y_label         => 'black',
        y_label2        => 'black',
        grid_lines      => 'black',
        grey_background => 'grey',
        (
            map { 'dataset' . $d++ => $_ }
              qw (red green blue purple peach orange mauve olive pink light_purple light_blue plum yellow turquoise light_green brown
              HotPink PaleGreen1 DarkBlue BlueViolet orange2 chocolate1 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown
              pink PaleGreen2 MediumPurple PeachPuff1 orange3 chocolate2 olive pink light_purple light_blue plum yellow turquoise light_green brown
              DarkOrange PaleGreen3 SlateBlue BlueViolet PeachPuff2 orange4 chocolate3 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown
              snow1 honeydew3 SkyBlue1 cyan3 DarkOliveGreen1 IndianRed3
              orange1 LightPink3 MediumPurple1 snow3 LavenderBlush1 SkyBlue3
              DarkSlateGray1 DarkOliveGreen3 sienna1 orange3 PaleVioletRed1
              MediumPurple3 seashell1 LavenderBlush3 LightSkyBlue1
              DarkSlateGray3 khaki1 sienna3 DarkOrange1 PaleVioletRed3
              thistle1 seashell3 MistyRose1 LightSkyBlue3 aquamarine1 khaki3
              burlywood1 DarkOrange3 maroon1 thistle3 AntiqueWhite1
              MistyRose3 SlateGray1 aquamarine3 LightGoldenrod1 burlywood3
              coral1 maroon3 AntiqueWhite3 azure1 SlateGray3 DarkSeaGreen1
              LightGoldenrod3 wheat1 coral3 VioletRed1 bisque1 azure3
              LightSteelBlue1 DarkSeaGreen3 LightYellow1 wheat3 tomato1
              VioletRed3 bisque3 SlateBlue1 LightSteelBlue3 SeaGreen1
              LightYellow3 tan1 tomato3 magenta1 PeachPuff1 SlateBlue3
              LightBlue1 SeaGreen3 yellow1 tan3 OrangeRed1 magenta3
              PeachPuff3 RoyalBlue1 LightBlue3 PaleGreen1 yellow3 chocolate1
              OrangeRed3 orchid1 NavajoWhite1 RoyalBlue3 LightCyan1
              PaleGreen3 gold1 chocolate3 red1 orchid3 NavajoWhite3 blue1
              LightCyan3 SpringGreen1 gold3 firebrick1 red3 plum1
              LemonChiffon1 blue3 PaleTurquoise1 SpringGreen3 goldenrod1
              firebrick3 DeepPink1 plum3 LemonChiffon3 DodgerBlue1
              PaleTurquoise3 green1 goldenrod3 brown1 DeepPink3
              MediumOrchid1 cornsilk1 DodgerBlue3 CadetBlue1 green3
              DarkGoldenrod1 brown3 HotPink1 MediumOrchid3 cornsilk3
              SteelBlue1 CadetBlue3 chartreuse1 DarkGoldenrod3 salmon1
              HotPink3 DarkOrchid1 ivory1 SteelBlue3 turquoise1 chartreuse3
              RosyBrown1 salmon3 pink1 DarkOrchid3 ivory3 DeepSkyBlue1
              turquoise3 OliveDrab1 RosyBrown3 LightSalmon1 pink3 purple1
              honeydew1 DeepSkyBlue3 cyan1 OliveDrab3 IndianRed1
              LightSalmon3 LightPink1 purple3 honeydew2 DeepSkyBlue4 cyan2
              OliveDrab4 IndianRed2 LightSalmon4 LightPink2 purple4 snow2
              honeydew4 SkyBlue2 cyan4 DarkOliveGreen2 IndianRed4 orange2
              LightPink4 MediumPurple2 snow4 LavenderBlush2 SkyBlue4
              DarkSlateGray2 DarkOliveGreen4 sienna2 orange4 PaleVioletRed2
              MediumPurple4 seashell2 LavenderBlush4 LightSkyBlue2
              DarkSlateGray4 khaki2 sienna4 DarkOrange2 PaleVioletRed4
              thistle2 seashell4 MistyRose2 LightSkyBlue4 aquamarine2 khaki4
              burlywood2 DarkOrange4 maroon2 thistle4 AntiqueWhite2
              MistyRose4 SlateGray2 aquamarine4 LightGoldenrod2 burlywood4
              coral2 maroon4 AntiqueWhite4 azure2 SlateGray4 DarkSeaGreen2
              LightGoldenrod4 wheat2 coral4 VioletRed2 bisque2 azure4
              LightSteelBlue2 DarkSeaGreen4 LightYellow2 wheat4 tomato2
              VioletRed4 bisque4 SlateBlue2 LightSteelBlue4 SeaGreen2
              LightYellow4 tan2 tomato4 magenta2 PeachPuff2 SlateBlue4
              LightBlue2 SeaGreen4 yellow2 tan4 OrangeRed2 magenta4
              PeachPuff4 RoyalBlue2 LightBlue4 PaleGreen2 yellow4 chocolate2
              OrangeRed4 orchid2 NavajoWhite2 RoyalBlue4 LightCyan2
              PaleGreen4 gold2 chocolate4 red2 orchid4 NavajoWhite4 blue2
              LightCyan4 SpringGreen2 gold4 firebrick2 red4 plum2
              LemonChiffon2 blue4 PaleTurquoise2 SpringGreen4 goldenrod2
              firebrick4 DeepPink2 plum4 LemonChiffon4 DodgerBlue2
              PaleTurquoise4 green2 goldenrod4 brown2 DeepPink4
              MediumOrchid2 cornsilk2 DodgerBlue4 CadetBlue2 green4
              DarkGoldenrod2 brown4 HotPink2 MediumOrchid4 cornsilk4
              SteelBlue2 CadetBlue4 chartreuse2 DarkGoldenrod4 salmon2
              HotPink4 DarkOrchid2 ivory2 SteelBlue4 turquoise2 chartreuse4
              RosyBrown2 salmon4 pink2 DarkOrchid4 ivory4 DeepSkyBlue2
              turquoise4 OliveDrab2 RosyBrown4 LightSalmon2 pink4 purple2)
        ),
    };

    # get default color specs for some color roles from alternate role.
    # Subclasses should extend as needed.
    $self->{'colors_default_role'} = {
        'x_grid_lines'  => 'grid_lines',
        'y_grid_lines'  => 'grid_lines',
        'y2_grid_lines' => 'grid_lines',    # should be added by Chart::Composite...
    };

    # Define style to plot dots in Points and Lines
    $self->{'brushStyle'} = 'FilledCircle';

    # and return
    return 1;
}

## @fn private int _copy_data($extern_ref)
# Copy external data via a reference to internal memory.
#
# Remember the external reference.\n
# Therefore, this function can anly be called once!
# @param extern_ref  Reference to external data space
sub _copy_data
{
    my $self       = shift;
    my $extern_ref = shift;
    my ( $ref, $i );

    # look to see if they used the other api
    if ( $self->{'dataref'} )
    {

        # we've already got a copy, thanks
        return 1;
    }
    else
    {

        # get an array reference
        $ref = [];

        # loop through and copy the external data to internal memory
        for $i ( 0 .. $#{$extern_ref} )
        {
            @{ $ref->[$i] } = @{ $extern_ref->[$i] };
            ## Speedup compared to:
            #  for $j (0..$#{$extern_ref->[$i]}) {
            #       $ref->[$i][$j] = $extern_ref->[$i][$j];
            #     }
        }

        # put it in the object
        $self->{'dataref'} = $ref;
        return 1;
    }
}

## @fn private int _check_data
# Check the internal data to be displayed.
#
# Make sure the data isn't really weird
#  and collect some basic info about it\n
# Not logical data is 'carp'ed.\n
# @return status of check
sub _check_data
{
    my $self   = shift;
    my $length = 0;

    # first make sure there's something there
    unless ( scalar( @{ $self->{'dataref'} } ) >= 2 )
    {
        croak "Call me again when you have some data to chart";
    }

    # make sure we don't end up dividing by zero if they ask for
    # just one y_tick
    if ( $self->{'y_ticks'} <= 1 )
    {
        $self->{'y_ticks'} = 2;
        carp "The number of y_ticks displayed must be at least 2";
    }

    # remember the number of datasets
    $self->{'num_datasets'} = $#{ $self->{'dataref'} };

    # remember the number of points in the largest dataset
    $self->{'num_datapoints'} = 0;
    for ( 0 .. $self->{'num_datasets'} )
    {
        if ( scalar( @{ $self->{'dataref'}[$_] } ) > $self->{'num_datapoints'} )
        {
            $self->{'num_datapoints'} = scalar( @{ $self->{'dataref'}[$_] } );
        }
    }

    # find good min and max y-values for the plot
    $self->_find_y_scale();

    # find the longest x-tick label
    $length = 0;
    for ( @{ $self->{'dataref'}->[0] } )
    {
        next if !defined($_);
        if ( length( $self->{f_x_tick}->($_) ) > $length )
        {
            $length = length( $self->{f_x_tick}->($_) );
        }
    }
    if ( $length <= 0 ) { $length = 1; }    # make sure $length is positive and greater 0

    # now store it in the object
    $self->{'x_tick_label_length'} = $length;

    # find x-scale, if a x-y plot is wanted
    # makes only sense for some charts
    if (
        $self->true( $self->{'xy_plot'} )
        && (   $self->isa('Chart::Lines')
            || $self->isa('Chart::Points')
            || $self->isa('Chart::LinesPoints')
            || $self->isa('Chart::Split')
            || $self->isa('Chart::ErrorBars') )
      )
    {
        $self->_find_x_scale;
    }

    return 1;
}

## @fn private int _draw
# Plot the chart to the gd object\n
# Calls:
# @see _draw_title
# @see _draw_sub_title
# @see _sort_data
# @see _plot
#
# @return status
sub _draw
{
    my $self = shift;

    # leave the appropriate border on the png
    $self->{'curr_x_max'} -= $self->{'png_border'};
    $self->{'curr_x_min'} += $self->{'png_border'};
    $self->{'curr_y_max'} -= $self->{'png_border'};
    $self->{'curr_y_min'} += $self->{'png_border'};

    # draw in the title
    $self->_draw_title() if $self->{'title'};

    # have to leave this here for backwards compatibility
    $self->_draw_sub_title() if $self->{'sub_title'};

    # sort the data if they want to (mainly here to make sure
    # pareto charts get sorted)
    $self->_sort_data() if ( $self->true( $self->{'sort'} ) );

    # start drawing the data (most methods in this will be
    # overridden by the derived classes)
    # include _draw_legend() in this to ensure that the legend
    # will be flush with the chart
    $self->_plot();

    # and return
    return 1;
}

## @var	    Hash named_colors RGB values of named colors
#
# see URL http://en.wikipedia.org/wiki/Web_colors#X11_color_names
our %named_colors = (
    'white'           => [ 255, 255, 255 ],
    'black'           => [ 0,   0,   0 ],
    'red'             => [ 200, 0,   0 ],
    'green'           => [ 0,   175, 0 ],
    'blue'            => [ 0,   0,   200 ],
    'orange'          => [ 250, 125, 0 ],
    'orange2'         => [ 238, 154, 0 ],
    'orange3'         => [ 205, 133, 0 ],
    'orange4'         => [ 139, 90,  0 ],
    'yellow'          => [ 225, 225, 0 ],
    'purple'          => [ 200, 0,   200 ],
    'light_blue'      => [ 0,   125, 250 ],
    'light_green'     => [ 125, 250, 0 ],
    'light_purple'    => [ 145, 0,   250 ],
    'pink'            => [ 250, 0,   125 ],
    'peach'           => [ 250, 125, 125 ],
    'olive'           => [ 125, 125, 0 ],
    'plum'            => [ 125, 0,   125 ],
    'turquoise'       => [ 0,   125, 125 ],
    'mauve'           => [ 200, 125, 125 ],
    'brown'           => [ 160, 80,  0 ],
    'grey'            => [ 225, 225, 225 ],
    'HotPink'         => [ 255, 105, 180 ],
    'PaleGreen1'      => [ 154, 255, 154 ],
    'PaleGreen2'      => [ 144, 238, 144 ],
    'PaleGreen3'      => [ 124, 205, 124 ],
    'PaleGreen4'      => [ 84,  138, 84 ],
    'DarkBlue'        => [ 0,   0,   139 ],
    'BlueViolet'      => [ 138, 43,  226 ],
    'PeachPuff'       => [ 255, 218, 185 ],
    'PeachPuff1'      => [ 255, 218, 185 ],
    'PeachPuff2'      => [ 238, 203, 173 ],
    'PeachPuff3'      => [ 205, 175, 149 ],
    'PeachPuff4'      => [ 139, 119, 101 ],
    'chocolate1'      => [ 255, 127, 36 ],
    'chocolate2'      => [ 238, 118, 33 ],
    'chocolate3'      => [ 205, 102, 29 ],
    'chocolate4'      => [ 139, 69,  19 ],
    'LightGreen'      => [ 144, 238, 144 ],
    'lavender'        => [ 230, 230, 250 ],
    'MediumPurple'    => [ 147, 112, 219 ],
    'DarkOrange'      => [ 255, 127, 0 ],
    'DarkOrange2'     => [ 238, 118, 0 ],
    'DarkOrange3'     => [ 205, 102, 0 ],
    'DarkOrange4'     => [ 139, 69,  0 ],
    'SlateBlue'       => [ 106, 90,  205 ],
    'BlueViolet'      => [ 138, 43,  226 ],
    'RoyalBlue'       => [ 65,  105, 225 ],
    'AntiqueWhite'    => [ 250, 235, 215 ],
    'AntiqueWhite1'   => [ 255, 239, 219 ],
    'AntiqueWhite2'   => [ 238, 223, 204 ],
    'AntiqueWhite3'   => [ 205, 192, 176 ],
    'AntiqueWhite4'   => [ 139, 131, 120 ],
    'CadetBlue'       => [ 95,  158, 160 ],
    'CadetBlue1'      => [ 152, 245, 255 ],
    'CadetBlue2'      => [ 142, 229, 238 ],
    'CadetBlue3'      => [ 122, 197, 205 ],
    'CadetBlue4'      => [ 83,  134, 139 ],
    'DarkGoldenrod'   => [ 184, 134, 11 ],
    'DarkGoldenrod1'  => [ 255, 185, 15 ],
    'DarkGoldenrod2'  => [ 238, 173, 14 ],
    'DarkGoldenrod3'  => [ 205, 149, 12 ],
    'DarkGoldenrod4'  => [ 139, 101, 8 ],
    'DarkOliveGreen'  => [ 85,  107, 47 ],
    'DarkOliveGreen1' => [ 202, 255, 112 ],
    'DarkOliveGreen2' => [ 188, 238, 104 ],
    'DarkOliveGreen3' => [ 162, 205, 90 ],
    'DarkOliveGreen4' => [ 110, 139, 61 ],
    'DarkOrange1'     => [ 255, 127, 0 ],
    'DarkOrchid'      => [ 153, 50,  204 ],
    'DarkOrchid1'     => [ 191, 62,  255 ],
    'DarkOrchid2'     => [ 178, 58,  238 ],
    'DarkOrchid3'     => [ 154, 50,  205 ],
    'DarkOrchid4'     => [ 104, 34,  139 ],
    'DarkSeaGreen'    => [ 143, 188, 143 ],
    'DarkSeaGreen1'   => [ 193, 255, 193 ],
    'DarkSeaGreen2'   => [ 180, 238, 180 ],
    'DarkSeaGreen3'   => [ 155, 205, 155 ],
    'DarkSeaGreen4'   => [ 105, 139, 105 ],
    'DarkSlateGray'   => [ 47,  79,  79 ],
    'DarkSlateGray1'  => [ 151, 255, 255 ],
    'DarkSlateGray2'  => [ 141, 238, 238 ],
    'DarkSlateGray3'  => [ 121, 205, 205 ],
    'DarkSlateGray4'  => [ 82,  139, 139 ],
    'DeepPink'        => [ 255, 20,  147 ],
    'DeepPink1'       => [ 255, 20,  147 ],
    'DeepPink2'       => [ 238, 18,  137 ],
    'DeepPink3'       => [ 205, 16,  118 ],
    'DeepPink4'       => [ 139, 10,  80 ],
    'DeepSkyBlue'     => [ 0,   191, 255 ],
    'DeepSkyBlue1'    => [ 0,   191, 255 ],
    'DeepSkyBlue2'    => [ 0,   178, 238 ],
    'DeepSkyBlue3'    => [ 0,   154, 205 ],
    'DeepSkyBlue4'    => [ 0,   104, 139 ],
    'DodgerBlue'      => [ 30,  144, 255 ],
    'DodgerBlue1'     => [ 30,  144, 255 ],
    'DodgerBlue2'     => [ 28,  134, 238 ],
    'DodgerBlue3'     => [ 24,  116, 205 ],
    'DodgerBlue4'     => [ 16,  78,  139 ],
    'HotPink1'        => [ 255, 110, 180 ],
    'HotPink2'        => [ 238, 106, 167 ],
    'HotPink3'        => [ 205, 96,  144 ],
    'HotPink4'        => [ 139, 58,  98 ],
    'IndianRed'       => [ 205, 92,  92 ],
    'IndianRed1'      => [ 255, 106, 106 ],
    'IndianRed2'      => [ 238, 99,  99 ],
    'IndianRed3'      => [ 205, 85,  85 ],
    'IndianRed4'      => [ 139, 58,  58 ],
    'LavenderBlush'   => [ 255, 240, 245 ],
    'LavenderBlush1'  => [ 255, 240, 245 ],
    'LavenderBlush2'  => [ 238, 224, 229 ],
    'LavenderBlush3'  => [ 205, 193, 197 ],
    'LavenderBlush4'  => [ 139, 131, 134 ],
    'LemonChiffon'    => [ 255, 250, 205 ],
    'LemonChiffon1'   => [ 255, 250, 205 ],
    'LemonChiffon2'   => [ 238, 233, 191 ],
    'LemonChiffon3'   => [ 205, 201, 165 ],
    'LemonChiffon4'   => [ 139, 137, 112 ],
    'LightBlue'       => [ 173, 216, 230 ],
    'LightBlue1'      => [ 191, 239, 255 ],
    'LightBlue2'      => [ 178, 223, 238 ],
    'LightBlue3'      => [ 154, 192, 205 ],
    'LightBlue4'      => [ 104, 131, 139 ],
    'LightCyan'       => [ 224, 255, 255 ],
    'LightCyan1'      => [ 224, 255, 255 ],
    'LightCyan2'      => [ 209, 238, 238 ],
    'LightCyan3'      => [ 180, 205, 205 ],
    'LightCyan4'      => [ 122, 139, 139 ],
    'LightGoldenrod'  => [ 238, 221, 130 ],
    'LightGoldenrod1' => [ 255, 236, 139 ],
    'LightGoldenrod2' => [ 238, 220, 130 ],
    'LightGoldenrod3' => [ 205, 190, 112 ],
    'LightGoldenrod4' => [ 139, 129, 76 ],
    'LightPink'       => [ 255, 182, 193 ],
    'LightPink1'      => [ 255, 174, 185 ],
    'LightPink2'      => [ 238, 162, 173 ],
    'LightPink3'      => [ 205, 140, 149 ],
    'LightPink4'      => [ 139, 95,  101 ],
    'LightSalmon'     => [ 255, 160, 122 ],
    'LightSalmon1'    => [ 255, 160, 122 ],
    'LightSalmon2'    => [ 238, 149, 114 ],
    'LightSalmon3'    => [ 205, 129, 98 ],
    'LightSalmon4'    => [ 139, 87,  66 ],
    'LightSkyBlue'    => [ 135, 206, 250 ],
    'LightSkyBlue1'   => [ 176, 226, 255 ],
    'LightSkyBlue2'   => [ 164, 211, 238 ],
    'LightSkyBlue3'   => [ 141, 182, 205 ],
    'LightSkyBlue4'   => [ 96,  123, 139 ],
    'LightSteelBlue'  => [ 176, 196, 222 ],
    'LightSteelBlue1' => [ 202, 225, 255 ],
    'LightSteelBlue2' => [ 188, 210, 238 ],
    'LightSteelBlue3' => [ 162, 181, 205 ],
    'LightSteelBlue4' => [ 110, 123, 139 ],
    'LightYellow'     => [ 255, 255, 224 ],
    'LightYellow1'    => [ 255, 255, 224 ],
    'LightYellow2'    => [ 238, 238, 209 ],
    'LightYellow3'    => [ 205, 205, 180 ],
    'LightYellow4'    => [ 139, 139, 122 ],
    'MediumOrchid'    => [ 186, 85,  211 ],
    'MediumOrchid1'   => [ 224, 102, 255 ],
    'MediumOrchid2'   => [ 209, 95,  238 ],
    'MediumOrchid3'   => [ 180, 82,  205 ],
    'MediumOrchid4'   => [ 122, 55,  139 ],
    'MediumPurple1'   => [ 171, 130, 255 ],
    'MediumPurple2'   => [ 159, 121, 238 ],
    'MediumPurple3'   => [ 137, 104, 205 ],
    'MediumPurple4'   => [ 93,  71,  139 ],
    'MistyRose'       => [ 255, 228, 225 ],
    'MistyRose1'      => [ 255, 228, 225 ],
    'MistyRose2'      => [ 238, 213, 210 ],
    'MistyRose3'      => [ 205, 183, 181 ],
    'MistyRose4'      => [ 139, 125, 123 ],
    'NavajoWhite'     => [ 255, 222, 173 ],
    'NavajoWhite1'    => [ 255, 222, 173 ],
    'NavajoWhite2'    => [ 238, 207, 161 ],
    'NavajoWhite3'    => [ 205, 179, 139 ],
    'NavajoWhite4'    => [ 139, 121, 94 ],
    'OliveDrab'       => [ 107, 142, 35 ],
    'OliveDrab1'      => [ 192, 255, 62 ],
    'OliveDrab2'      => [ 179, 238, 58 ],
    'OliveDrab3'      => [ 154, 205, 50 ],
    'OliveDrab4'      => [ 105, 139, 34 ],
    'OrangeRed'       => [ 255, 69,  0 ],
    'OrangeRed1'      => [ 255, 69,  0 ],
    'OrangeRed2'      => [ 238, 64,  0 ],
    'OrangeRed3'      => [ 205, 55,  0 ],
    'OrangeRed4'      => [ 139, 37,  0 ],
    'PaleGreen'       => [ 152, 251, 152 ],
    'PaleTurquoise'   => [ 175, 238, 238 ],
    'PaleTurquoise1'  => [ 187, 255, 255 ],
    'PaleTurquoise2'  => [ 174, 238, 238 ],
    'PaleTurquoise3'  => [ 150, 205, 205 ],
    'PaleTurquoise4'  => [ 102, 139, 139 ],
    'PaleVioletRed'   => [ 219, 112, 147 ],
    'PaleVioletRed1'  => [ 255, 130, 171 ],
    'PaleVioletRed2'  => [ 238, 121, 159 ],
    'PaleVioletRed3'  => [ 205, 104, 137 ],
    'PaleVioletRed4'  => [ 139, 71,  93 ],
    'RosyBrown'       => [ 188, 143, 143 ],
    'RosyBrown1'      => [ 255, 193, 193 ],
    'RosyBrown2'      => [ 238, 180, 180 ],
    'RosyBrown3'      => [ 205, 155, 155 ],
    'RosyBrown4'      => [ 139, 105, 105 ],
    'RoyalBlue1'      => [ 72,  118, 255 ],
    'RoyalBlue2'      => [ 67,  110, 238 ],
    'RoyalBlue3'      => [ 58,  95,  205 ],
    'RoyalBlue4'      => [ 39,  64,  139 ],
    'SeaGreen'        => [ 46,  139, 87 ],
    'SeaGreen1'       => [ 84,  255, 159 ],
    'SeaGreen2'       => [ 78,  238, 148 ],
    'SeaGreen3'       => [ 67,  205, 128 ],
    'SeaGreen4'       => [ 46,  139, 87 ],
    'SkyBlue'         => [ 135, 206, 235 ],
    'SkyBlue1'        => [ 135, 206, 255 ],
    'SkyBlue2'        => [ 126, 192, 238 ],
    'SkyBlue3'        => [ 108, 166, 205 ],
    'SkyBlue4'        => [ 74,  112, 139 ],
    'SlateBlue1'      => [ 131, 111, 255 ],
    'SlateBlue2'      => [ 122, 103, 238 ],
    'SlateBlue3'      => [ 105, 89,  205 ],
    'SlateBlue4'      => [ 71,  60,  139 ],
    'SlateGray'       => [ 112, 128, 144 ],
    'SlateGray1'      => [ 198, 226, 255 ],
    'SlateGray2'      => [ 185, 211, 238 ],
    'SlateGray3'      => [ 159, 182, 205 ],
    'SlateGray4'      => [ 108, 123, 139 ],
    'SpringGreen'     => [ 0,   255, 127 ],
    'SpringGreen1'    => [ 0,   255, 127 ],
    'SpringGreen2'    => [ 0,   238, 118 ],
    'SpringGreen3'    => [ 0,   205, 102 ],
    'SpringGreen4'    => [ 0,   139, 69 ],
    'SteelBlue'       => [ 70,  130, 180 ],
    'SteelBlue1'      => [ 99,  184, 255 ],
    'SteelBlue2'      => [ 92,  172, 238 ],
    'SteelBlue3'      => [ 79,  148, 205 ],
    'SteelBlue4'      => [ 54,  100, 139 ],
    'VioletRed'       => [ 208, 32,  144 ],
    'VioletRed1'      => [ 255, 62,  150 ],
    'VioletRed2'      => [ 238, 58,  140 ],
    'VioletRed3'      => [ 205, 50,  120 ],
    'VioletRed4'      => [ 139, 34,  82 ],
    'aquamarine'      => [ 127, 255, 212 ],
    'aquamarine1'     => [ 127, 255, 212 ],
    'aquamarine2'     => [ 118, 238, 198 ],
    'aquamarine3'     => [ 102, 205, 170 ],
    'aquamarine4'     => [ 69,  139, 116 ],
    'azure'           => [ 240, 255, 255 ],
    'azure1'          => [ 240, 255, 255 ],
    'azure2'          => [ 224, 238, 238 ],
    'azure3'          => [ 193, 205, 205 ],
    'azure4'          => [ 131, 139, 139 ],
    'bisque'          => [ 255, 228, 196 ],
    'bisque1'         => [ 255, 228, 196 ],
    'bisque2'         => [ 238, 213, 183 ],
    'bisque3'         => [ 205, 183, 158 ],
    'bisque4'         => [ 139, 125, 107 ],
    'blue1'           => [ 0,   0,   255 ],
    'blue2'           => [ 0,   0,   238 ],
    'blue3'           => [ 0,   0,   205 ],
    'blue4'           => [ 0,   0,   139 ],
    'brown1'          => [ 255, 64,  64 ],
    'brown2'          => [ 238, 59,  59 ],
    'brown3'          => [ 205, 51,  51 ],
    'brown4'          => [ 139, 35,  35 ],
    'burlywood'       => [ 222, 184, 135 ],
    'burlywood1'      => [ 255, 211, 155 ],
    'burlywood2'      => [ 238, 197, 145 ],
    'burlywood3'      => [ 205, 170, 125 ],
    'burlywood4'      => [ 139, 115, 85 ],
    'chartreuse'      => [ 127, 255, 0 ],
    'chartreuse1'     => [ 127, 255, 0 ],
    'chartreuse2'     => [ 118, 238, 0 ],
    'chartreuse3'     => [ 102, 205, 0 ],
    'chartreuse4'     => [ 69,  139, 0 ],
    'chocolate'       => [ 210, 105, 30 ],
    'coral'           => [ 255, 127, 80 ],
    'coral1'          => [ 255, 114, 86 ],
    'coral2'          => [ 238, 106, 80 ],
    'coral3'          => [ 205, 91,  69 ],
    'coral4'          => [ 139, 62,  47 ],
    'cornsilk'        => [ 255, 248, 220 ],
    'cornsilk1'       => [ 255, 248, 220 ],
    'cornsilk2'       => [ 238, 232, 205 ],
    'cornsilk3'       => [ 205, 200, 177 ],
    'cornsilk4'       => [ 139, 136, 120 ],
    'cyan'            => [ 0,   255, 255 ],
    'cyan1'           => [ 0,   255, 255 ],
    'cyan2'           => [ 0,   238, 238 ],
    'cyan3'           => [ 0,   205, 205 ],
    'cyan4'           => [ 0,   139, 139 ],
    'firebrick'       => [ 178, 34,  34 ],
    'firebrick1'      => [ 255, 48,  48 ],
    'firebrick2'      => [ 238, 44,  44 ],
    'firebrick3'      => [ 205, 38,  38 ],
    'firebrick4'      => [ 139, 26,  26 ],
    'gold'            => [ 255, 215, 0 ],
    'gold1'           => [ 255, 215, 0 ],
    'gold2'           => [ 238, 201, 0 ],
    'gold3'           => [ 205, 173, 0 ],
    'gold4'           => [ 139, 117, 0 ],
    'goldenrod'       => [ 218, 165, 32 ],
    'goldenrod1'      => [ 255, 193, 37 ],
    'goldenrod2'      => [ 238, 180, 34 ],
    'goldenrod3'      => [ 205, 155, 29 ],
    'goldenrod4'      => [ 139, 105, 20 ],
    'gray'            => [ 190, 190, 190 ],
    'gray1'           => [ 3,   3,   3 ],
    'gray2'           => [ 5,   5,   5 ],
    'gray3'           => [ 8,   8,   8 ],
    'gray4'           => [ 10,  10,  10 ],
    'green1'          => [ 0,   255, 0 ],
    'green2'          => [ 0,   238, 0 ],
    'green3'          => [ 0,   205, 0 ],
    'green4'          => [ 0,   139, 0 ],
    'grey1'           => [ 3,   3,   3 ],
    'grey2'           => [ 5,   5,   5 ],
    'grey3'           => [ 8,   8,   8 ],
    'grey4'           => [ 10,  10,  10 ],
    'honeydew'        => [ 240, 255, 240 ],
    'honeydew1'       => [ 240, 255, 240 ],
    'honeydew2'       => [ 224, 238, 224 ],
    'honeydew3'       => [ 193, 205, 193 ],
    'honeydew4'       => [ 131, 139, 131 ],
    'ivory'           => [ 255, 255, 240 ],
    'ivory1'          => [ 255, 255, 240 ],
    'ivory2'          => [ 238, 238, 224 ],
    'ivory3'          => [ 205, 205, 193 ],
    'ivory4'          => [ 139, 139, 131 ],
    'khaki'           => [ 240, 230, 140 ],
    'khaki1'          => [ 255, 246, 143 ],
    'khaki2'          => [ 238, 230, 133 ],
    'khaki3'          => [ 205, 198, 115 ],
    'khaki4'          => [ 139, 134, 78 ],
    'magenta'         => [ 255, 0,   255 ],
    'magenta1'        => [ 255, 0,   255 ],
    'magenta2'        => [ 238, 0,   238 ],
    'magenta3'        => [ 205, 0,   205 ],
    'magenta4'        => [ 139, 0,   139 ],
    'maroon'          => [ 176, 48,  96 ],
    'maroon1'         => [ 255, 52,  179 ],
    'maroon2'         => [ 238, 48,  167 ],
    'maroon3'         => [ 205, 41,  144 ],
    'maroon4'         => [ 139, 28,  98 ],
    'orange1'         => [ 255, 165, 0 ],
    'orchid'          => [ 218, 112, 214 ],
    'orchid1'         => [ 255, 131, 250 ],
    'orchid2'         => [ 238, 122, 233 ],
    'orchid3'         => [ 205, 105, 201 ],
    'orchid4'         => [ 139, 71,  137 ],
    'pink1'           => [ 255, 181, 197 ],
    'pink2'           => [ 238, 169, 184 ],
    'pink3'           => [ 205, 145, 158 ],
    'pink4'           => [ 139, 99,  108 ],
    'plum1'           => [ 255, 187, 255 ],
    'plum2'           => [ 238, 174, 238 ],
    'plum3'           => [ 205, 150, 205 ],
    'plum4'           => [ 139, 102, 139 ],
    'purple1'         => [ 155, 48,  255 ],
    'purple2'         => [ 145, 44,  238 ],
    'purple3'         => [ 125, 38,  205 ],
    'purple4'         => [ 85,  26,  139 ],
    'red1'            => [ 255, 0,   0 ],
    'red2'            => [ 238, 0,   0 ],
    'red3'            => [ 205, 0,   0 ],
    'red4'            => [ 139, 0,   0 ],
    'salmon'          => [ 250, 128, 114 ],
    'salmon1'         => [ 255, 140, 105 ],
    'salmon2'         => [ 238, 130, 98 ],
    'salmon3'         => [ 205, 112, 84 ],
    'salmon4'         => [ 139, 76,  57 ],
    'seashell'        => [ 255, 245, 238 ],
    'seashell1'       => [ 255, 245, 238 ],
    'seashell2'       => [ 238, 229, 222 ],
    'seashell3'       => [ 205, 197, 191 ],
    'seashell4'       => [ 139, 134, 130 ],
    'sienna'          => [ 160, 82,  45 ],
    'sienna1'         => [ 255, 130, 71 ],
    'sienna2'         => [ 238, 121, 66 ],
    'sienna3'         => [ 205, 104, 57 ],
    'sienna4'         => [ 139, 71,  38 ],
    'snow'            => [ 255, 250, 250 ],
    'snow1'           => [ 255, 250, 250 ],
    'snow2'           => [ 238, 233, 233 ],
    'snow3'           => [ 205, 201, 201 ],
    'snow4'           => [ 139, 137, 137 ],
    'tan'             => [ 210, 180, 140 ],
    'tan1'            => [ 255, 165, 79 ],
    'tan2'            => [ 238, 154, 73 ],
    'tan3'            => [ 205, 133, 63 ],
    'tan4'            => [ 139, 90,  43 ],
    'thistle'         => [ 216, 191, 216 ],
    'thistle1'        => [ 255, 225, 255 ],
    'thistle2'        => [ 238, 210, 238 ],
    'thistle3'        => [ 205, 181, 205 ],
    'thistle4'        => [ 139, 123, 139 ],
    'tomato'          => [ 255, 99,  71 ],
    'tomato1'         => [ 255, 99,  71 ],
    'tomato2'         => [ 238, 92,  66 ],
    'tomato3'         => [ 205, 79,  57 ],
    'tomato4'         => [ 139, 54,  38 ],
    'turquoise1'      => [ 0,   245, 255 ],
    'turquoise2'      => [ 0,   229, 238 ],
    'turquoise3'      => [ 0,   197, 205 ],
    'turquoise4'      => [ 0,   134, 139 ],
    'wheat'           => [ 245, 222, 179 ],
    'wheat1'          => [ 255, 231, 186 ],
    'wheat2'          => [ 238, 216, 174 ],
    'wheat3'          => [ 205, 186, 150 ],
    'wheat4'          => [ 139, 126, 102 ],
    'yellow1'         => [ 255, 255, 0 ],
    'yellow2'         => [ 238, 238, 0 ],
    'yellow3'         => [ 205, 205, 0 ],
    'yellow4'         => [ 139, 139, 0 ],
);

## @fn private int _set_colors
#  specify my colors
# @return status
sub _set_colors
{
    my $self = shift;

    my $index = $self->_color_role_to_index('background');    # allocate GD color
    if ( $self->true( $self->{'transparent'} ) )
    {
        $self->{'gd_obj'}->transparent($index);
    }

    # all other roles are initialized by calling $self->_color_role_to_index(ROLENAME);

    # and return
    return 1;
}

## @fn private int _color_role_to_index
# return a (list of) color index(es) corresponding to the (list of) role(s)
#
# @details wantarray
# is a special keyword which returns a flag indicating
# which context your subroutine has been called in.
# It will return one of three values.
#
# @li true: If your subroutine has been called in list context
# @li false: If your subroutine has been called in scalar context
# @li undef: If your subroutine has been called in void context
#
# @return a (list of) color index(es) corresponding to the (list of) role(s) in \\\@_.
#
sub _color_role_to_index
{
    my $self = shift;

    # Return a (list of) color index(es) corresponding to the (list of) role(s) in @_.
    my @result = map {
        my $role  = $_;
        my $index = $self->{'color_table'}->{$role};

        #print STDERR "Role = $_\n";

        unless ( defined $index )
        {
            my $spec =
                 $self->{'colors'}->{$role}
              || $self->{'colors_default_spec'}->{$role}
              || $self->{'colors_default_spec'}->{ $self->{'colors_default_role'}->{$role} };

            my @rgb = $self->_color_spec_to_rgb( $role, $spec );

            #print STDERR "spec = $spec\n";

            my $string = sprintf " RGB(%d,%d,%d)", map { $_ + 0 } @rgb;

            $index = $self->{'color_table'}->{$string};
            unless ( defined $index )
            {
                $index = $self->{'gd_obj'}->colorAllocate(@rgb);
                $self->{'color_table'}->{$string} = $index;
            }

            $self->{'color_table'}->{$role} = $index;
        }
        $index;
    } @_;

    #print STDERR "Result= ".$result[0]."\n";
    ( wantarray && @_ > 1 ? @result : $result[0] );
}

## @fn private array _color_spec_to_rgb($role,$spec)
# Return an array (list of) rgb values for spec
# @param[in] role name of a role
# @param[in] spec [r,g,b] or name
# @return array of rgb values as a list (i.e., \\\@rgb)
#
sub _color_spec_to_rgb
{
    my $self = shift;
    my $role = shift;    # for error messages
    my $spec = shift;    # [r,g,b] or name

    my @rgb;             # result
    if ( ref($spec) eq 'ARRAY' )
    {
        @rgb = @{$spec};
        croak "Invalid color RGB array (" . join( ',', @rgb ) . ") for $role\n"

          unless @rgb == 3 && grep( !m/^\d+$/ || $_ > 255, @rgb ) == 0;
    }
    elsif ( !ref($spec) )
    {
        croak "Unknown named color ($spec) for $role\n"
          unless $named_colors{$spec};
        @rgb = @{ $named_colors{$spec} };
    }
    else
    {
        croak "Unrecognized color for $role\n";
    }
    @rgb;
}

## @fn private int _brushStyles_of_roles
# return a (list of) brushStyles corresponding to the (list of) role(s)
#
# @param list_of_roles List of roles (\\\@list_of_roles)
# @return (list of) brushStyle(s) corresponding to the (list of) role(s) in \\\@_.
#
sub _brushStyles_of_roles
{
    my $self  = shift;
    my @roles = @_;

    my @results = ();
    foreach my $role (@roles)
    {
        my $brushStyle = $self->{'brushStyles'}->{$role};

        if ( !defined($brushStyle) )
        {
            $brushStyle = $self->{'brushStyle'};
        }
        push( @results, $brushStyle );
    }
    @results;
}

## @fn private int _draw_title
#  draw the title for the chart
#
# The title was defined by the user in set('title' => ....)\n
# The user may define some title lines by separating them via character '\\n';\n
# The used font is taken from 'title_font';\n
# The used color is calculated by function '_color_role_to_index'
# based on 'title' or 'text'\n
# @see _color_role_to_index
# @return status
sub _draw_title
{
    my $self = shift;
    my $font = $self->{'title_font'};
    my $color;
    my ( $h, $w, @lines, $x, $y );

    #get the right color
    if ( defined $self->{'colors'}{'title'} )
    {
        $color = $self->_color_role_to_index('title');
    }
    else
    {
        $color = $self->_color_role_to_index('text');
    }

    # make sure we're actually using a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The title font you specified isn\'t a GD Font object";
    }

    # get the height and width of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # split the title into lines
    @lines = split( /\\n/, $self->{'title'} );

    # write the first line
    $x = ( $self->{'curr_x_max'} - $self->{'curr_x_min'} ) / 2 + $self->{'curr_x_min'} - ( length( $lines[0] ) * $w ) / 2;
    $y = $self->{'curr_y_min'} + $self->{'text_space'};

    #-----------------------------------------------------------

    # Tests for Version 2.5
    # ttf are found in /var/share/fonts/truetype/freefont/

    # /var/share/fonts/truetype

    # Sketch for further processing
    #    if ( $font ~= /^gd/ && ! -f $font )
    #    {
    #		$self->{'gd_obj'}->string( $font, $x, $y, $lines[0], $color );
    #	}
    #	elsif ( -f $font )
    #	{
    #		my $fontname = '/var/share/fonts/truetype/freefont/FreeSerifBoldItalic.ttf';
    #		$self->{'gd_obj'}->stringFT( $color, $fontname, 8,0, $x, $y, $lines[0] );
    #	}

    #	my $fontname = '/var/share/fonts/truetype/freefont/FreeSerifBoldItalic.ttf';
    #    #                                              size, angle
    #	$self->{'gd_obj'}->stringFT( $color, $fontname, 12,0, $x, $y, $lines[0] );

    #-----------------------------------------------------------------
    $self->{'gd_obj'}->string( $font, $x, $y, $lines[0], $color );

    # now loop through the rest of them
    # (the font is decreased in width and height by 1
    if ( $w > 1 ) { $w--; }
    if ( $h > 1 ) { $h--; }
    for ( 1 .. $#lines )
    {
        $self->{'curr_y_min'} += $self->{'text_space'} + $h;
        $x = ( $self->{'curr_x_max'} - $self->{'curr_x_min'} ) / 2 + $self->{'curr_x_min'} - ( length( $lines[$_] ) * $w ) / 2;
        $y = $self->{'curr_y_min'} + $self->{'text_space'};
        $self->{'gd_obj'}->string( $font, $x, $y, $lines[$_], $color );
    }

    # mark off that last space
    $self->{'curr_y_min'} += 2 * $self->{'text_space'} + $h;

    # and return
    return 1;
}

## @fn private int _draw_sub_title()
#  draw the sub-title for the chart
# @see _draw_title\n
# _draw_sub_title() is more or less obsolete as _draw_title() does the same
# by writing more than one line as the title.
# Both use decreased width and height of the font by one.
# @return status
sub _draw_sub_title
{
    my $self = shift;

    my $font = $self->{'sub_title_font'};
    my $text = $self->{'sub_title'};
    return 1 if length($text) == 0;    # nothing to plot

    #get the right color
    my $color;
    if ( defined $self->{'colors'}{'title'} )
    {
        $color = $self->_color_role_to_index('title');
    }
    else
    {
        $color = $self->_color_role_to_index('text');
    }

    my ( $h, $w, $x, $y );

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );
    if ( $h > 1 && $w > 1 ) { $h--, $w-- }

    # figure out the placement
    $x = ( $self->{'curr_x_max'} - $self->{'curr_x_min'} ) / 2 + $self->{'curr_x_min'} - ( length($text) * $w ) / 2;
    $y = $self->{'curr_y_min'};

    # now draw the subtitle
    $self->{'gd_obj'}->string( $font, $x, $y, $text, $color );

    # Adapt curr_y_min
    $self->{'curr_y_min'} += $self->{'text_space'} + $h;

    # and return
    return 1;
}

## @fn private int _sort_data()
#  sort the data nicely (mostly for the pareto charts and xy-plots)
# @return status
sub _sort_data
{
    my $self     = shift;
    my $data_ref = $self->{'dataref'};
    my @data     = @{ $self->{'dataref'} };
    my @sort_index;

    #sort the data with slices
    @sort_index = sort { $data[0][$a] <=> $data[0][$b] } ( 0 .. scalar( @{ $data[1] } ) - 1 );
    for ( 1 .. $#data )
    {
        @{ $self->{'dataref'}->[$_] } = @{ $self->{'dataref'}->[$_] }[@sort_index];
    }
    @{ $data_ref->[0] } = sort { $a <=> $b } @{ $data_ref->[0] };

    #finally return
    return 1;
}

## @fn private int _find_x_scale()
# For a xy-plot do the same for the x values, as '_find_y_scale' does for the y values!
# @see _find_y_scale
# @return status
sub _find_x_scale
{
    my $self = shift;
    my @data = @{ $self->{'dataref'} };
    my ( $i,     $j );
    my ( $d_min, $d_max );
    my ( $p_min, $p_max, $f_min, $f_max );
    my ( $tickInterval, $tickCount, $skip );
    my @tickLabels;
    my $maxtickLabelLen = 0;

    #look, if we have numbers
    #see also if we only have integers
    for $i ( 0 .. ( $self->{'num_datasets'} ) )
    {
        for $j ( 0 .. ( $self->{'num_datapoints'} - 1 ) )
        {

            # the following regular Expression matches all possible numbers, including scientific numbers
            # iff data is defined
            if ( defined $data[$i][$j] and $data[$i][$j] !~ m/^[\+\-]?((\.\d+)|(\d+\.?\d*))([eE][+-]?\d+)?[fFdD]?$/ )
            {
                croak "<$data[$i][$j]> You should give me numbers for drawing a xy plot!\n";
            }
        }
    }

    #find the dataset min and max
    ( $d_min, $d_max ) = $self->_find_x_range();

    # Force the inclusion of zero if the user has requested it.
    if ( $self->true( $self->{'include_zero'} ) )
    {
        if ( ( $d_min * $d_max ) > 0 )    # If both are non zero and of the same sign.
        {
            if ( $d_min > 0 )             # If the whole scale is positive.
            {
                $d_min = 0;
            }
            else                          # The scale is entirely negative.
            {
                $d_max = 0;
            }
        }
    }

    # Calculate the width of the dataset. (possibly modified by the user)
    my $d_width = $d_max - $d_min;

    # If the width of the range is zero, forcebly widen it
    # (to avoid division by zero errors elsewhere in the code).
    if ( 0 == $d_width )
    {
        $d_min--, $d_max++, $d_width = 2;
    }

    # Descale the range by converting the dataset width into
    # a floating point exponent & mantisa pair.
    my ( $rangeExponent, $rangeMantisa ) = $self->_sepFP($d_width);
    my $rangeMuliplier = 10**$rangeExponent;

    # Find what tick
    # to use & how many ticks to plot,
    # round the plot min & max to suatable round numbers.
    ( $tickInterval, $tickCount, $p_min, $p_max ) = $self->_calcXTickInterval(
        $d_min / $rangeMuliplier,
        $d_max / $rangeMuliplier,
        $f_min, $f_max,
        $self->{'min_x_ticks'},
        $self->{'max_x_ticks'}
    );

    # Restore the tickInterval etc to the correct scale
    $_ *= $rangeMuliplier foreach ( $tickInterval, $p_min, $p_max );

    #get the precision for the labels
    my $precision = $self->{'precision'};

    # Now sort out an array of tick labels.
    for ( my $labelNum = $p_min ; $labelNum < $p_max + $tickInterval / 2 ; $labelNum += $tickInterval )
    {
        my $labelText;

        if ( defined $self->{f_y_tick} )
        {

            # Is _default_f_tick function used?
            if ( $self->{f_y_tick} == \&_default_f_tick )
            {
                $labelText = sprintf( "%." . $precision . "f", $labelNum );
            }
            else
            {
                $labelText = $self->{f_y_tick}->($labelNum);
            }
        }
        else
        {
            $labelText = sprintf( "%." . $precision . "f", $labelNum );
        }

        push @tickLabels, $labelText;
        $maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
    }

    # Store the calculated data.
    $self->{'x_min_val'}             = $p_min,
      $self->{'x_max_val'}           = $p_max,
      $self->{'x_tick_labels'}       = \@tickLabels,
      $self->{'x_tick_label_length'} = $maxtickLabelLen,
      $self->{'x_number_ticks'}      = $tickCount;
    return 1;
}

## @fn private int _find_y_scale()
#  find good values for the minimum and maximum y-value on the chart
# @return status
#
# New version, re-written by David Pottage of Tao Group.\n
# This code is *AS IS* and comes with *NO WARRANTY*\n
#
# This Sub calculates correct values for the following class local variables,
# if they have not been set by the user.
#
# max_val, min_val: 	The maximum and minimum values for the y axis.\n
# y_ticks:		The number of ticks to plot on the y scale, including
#			the end points. e.g. If the scale runs from 0 to 50,
#			with ticks every 10, y_ticks will have the value of 6.\n
# y_tick_labels:	An array of strings, each is a label for the y axis.\n
# y_tick_labels_length:	The length to allow for B tick labels. (How long is
#                       the longest?)
sub _find_y_scale
{
    my $self = shift;

    # Predeclare vars.
    my ( $d_min,        $d_max );              # Dataset min & max.
    my ( $p_min,        $p_max );              # Plot min & max.
    my ( $tickInterval, $tickCount, $skip );
    my @tickLabels;                            # List of labels for each tick.
    my $maxtickLabelLen = 0;                   # The length of the longest tick label.
    my $prec_test       = 0;                   # Boolean which indicate if precision < |rangeExponent|
    my $temp_rangeExponent;

    my $flag_all_integers = 1;                 # assume true

    # Find the dataset minimum and maximum.
    ( $d_min, $d_max, $flag_all_integers ) = $self->_find_y_range();

    # Force the inclusion of zero if the user has requested it.
    if ( $self->true( $self->{'include_zero'} ) )
    {

        #print "include_zero = true\n";
        if ( ( $d_min * $d_max ) > 0 )         # If both are non zero and of the same sign.
        {
            if ( $d_min > 0 )                  # If the whole scale is positive.
            {
                $d_min = 0;
            }
            else                               # The scale is entirely negative.
            {
                $d_max = 0;
            }
        }
    }

    if ( $self->true( $self->{'integer_ticks_only'} ) )
    {

        # Allow the dataset range to be overidden by the user.
        # f_min/f_max are booleans which indicate that the min & max should not be modified.
        my $f_min = 0;
        if ( defined $self->{'min_val'} ) { $f_min = 1; }
        $d_min = $self->{'min_val'} if $f_min;

        my $f_max = 0;
        if ( defined $self->{'max_val'} ) { $f_max = 1; }
        $d_max = $self->{'max_val'} if $f_max;

        # Assert against defined min and max.
        if ( !defined $d_min || !defined $d_max )
        {
            croak "No min_val or max_val is defined";
        }

        # Assert against the min is larger than the max.
        if ( $d_min > $d_max )
        {
            croak "The specified 'min_val' & 'max_val' values are reversed (min > max: $d_min>$d_max)";
        }

        # The user asked for integer ticks, force the limits to integers.
        # & work out the range directly.
        #$p_min = $self->_round2Tick($d_min, 1, -1);
        #$p_max = $self->_round2Tick($d_max, 1, 1);

        $skip = $self->{skip_int_ticks};
        $skip = 1 if $skip < 1;

        $p_min = $self->_round2Tick( $d_min, 1, -1 );
        $p_max = $self->_round2Tick( $d_max, 1, 1 );
        if ( ( $p_max - $p_min ) == 0 )
        {
            $p_max++ if ( $f_max != 1 );                # p_max is not defined by the user
            $p_min-- if ( $f_min != 1 );                # p_min is not defined by the user
            $p_max++ if ( ( $p_max - $p_min ) == 0 );
        }

        $tickInterval = $skip;
        $tickCount    = ( $p_max - $p_min ) / $skip + 1;

        # Now sort out an array of tick labels.

        for ( my $labelNum = $p_min ; $labelNum < $p_max + $tickInterval / 3 ; $labelNum += $tickInterval )
        {
            my $labelText;

            if ( defined $self->{f_y_tick} )
            {

                # Is _default_f_tick function used?
                if ( $self->{f_y_tick} == \&_default_f_tick )
                {
                    $labelText = sprintf( "%d", $labelNum );
                }
                else
                {
                    $labelText = $self->{f_y_tick}->($labelNum);
                }
            }
            else
            {
                $labelText = sprintf( "%d", $labelNum );
            }

            push @tickLabels, $labelText;
            $maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
        }
    }
    else
    {

        # Allow the dataset range to be overidden by the user.
        # f_min/f_max are booleans which indicate that the min & max should not be modified.
        my $f_min = 0;
        if ( defined $self->{'min_val'} ) { $f_min = 1; }
        $d_min = $self->{'min_val'} if $f_min;

        my $f_max = 0;
        if ( defined $self->{'max_val'} ) { $f_max = 1; }
        $d_max = $self->{'max_val'} if $f_max;

        #  print "fmin $f_min fmax $f_max\n";
        #  print "dmin $d_min dmax $d_max\n";

        # Assert against defined min and max.
        if ( !defined $d_min || !defined $d_max )
        {
            croak "No min_val or max_val is defined";
        }

        # Assert against the min is larger than the max.
        if ( $d_min > $d_max )
        {
            croak "The the specified 'min_val' & 'max_val' values are reversed (min > max: $d_min>$d_max)";
        }

        # Calculate the width of the dataset. (possibly modified by the user)
        my $d_width = $d_max - $d_min;

        # If the width of the range is zero, forcibly widen it
        # (to avoid division by zero errors elsewhere in the code).
        if ( $d_width == 0 )
        {
            $d_min--, $d_max++, $d_width = 2;
        }

        # Descale the range by converting the dataset width into
        # a floating point exponent & mantisa pair.
        my ( $rangeExponent, $rangeMantisa ) = $self->_sepFP($d_width);
        my $rangeMuliplier = 10**$rangeExponent;

        # print "fmin $f_min fmax $f_max\n";
        # print "dmin $d_min dmax $d_max\n";

        # Find what tick
        # to use & how many ticks to plot,
        # round the plot min & max to suitable round numbers.
        ( $tickInterval, $tickCount, $p_min, $p_max ) = $self->_calcTickInterval(
            $d_min / $rangeMuliplier,
            $d_max / $rangeMuliplier,
            $f_min, $f_max,
            $self->{'min_y_ticks'},
            $self->{'max_y_ticks'}
        );

        # Restore the tickInterval etc to the correct scale
        $_ *= $rangeMuliplier foreach ( $tickInterval, $p_min, $p_max );

        # Is precision < |rangeExponent|?
        if ( $rangeExponent < 0 )
        {
            $temp_rangeExponent = -$rangeExponent;
        }
        else
        {
            $temp_rangeExponent = $rangeExponent;
        }

        # print "pmin $p_min pmax $p_max\n";
        # print "range exponent $rangeExponent\n";

        #get the precision for the labels
        my $precision = $self->{'precision'};

        if (   $temp_rangeExponent != 0
            && $rangeExponent < 0
            && $temp_rangeExponent > $precision )
        {
            $prec_test = 1;
        }

        # Now sort out an array of tick labels.
        for ( my $labelNum = $p_min ; $labelNum < $p_max + $tickInterval / 2 ; $labelNum += $tickInterval )
        {
            my $labelText;
            if ( defined $self->{f_y_tick} )
            {

                # Is _default_f_tick function used?
                if ( ( $self->{f_y_tick} == \&_default_f_tick ) && ( $prec_test == 0 ) )
                {
                    $labelText = sprintf( "%." . $precision . "f", $labelNum );
                }

                # If precision <|rangeExponent| print the labels whith exponents
                elsif ( ( $self->{f_y_tick} == \&_default_f_tick ) && ( $prec_test == 1 ) )
                {
                    $labelText = $self->{f_y_tick}->($labelNum);

                    #  print "precision $precision\n";
                    #  print "temp range exponent $temp_rangeExponent\n";
                    #  print "range exponent $rangeExponent\n";
                    #  print "labelText $labelText\n";

                }
                else
                {
                    $labelText = $self->{f_y_tick}->($labelNum);
                }
            }
            else
            {
                $labelText = sprintf( "%." . $precision . "f", $labelNum );
            }
            push @tickLabels, $labelText;
            $maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
        }    # end for
    }

    # Store the calculated data.
    #### begin debugging output
    #if ( defined $self->{'y_ticks'} )
    #{
    #    print "_find_y_scale: self->{'y_ticks'}=".$self->{'y_ticks'}."\n";
    #}
    #else
    #{
    #   print "_find_y_scale: self->{'y_ticks'}= NOT DEFINED\n";
    #}
    #if ( defined $self->{'min_val'} )
    #{
    #    print "_find_y_scale: self->{'min_val'}=".$self->{'min_val'}."\n";
    #}
    #else
    #{
    #    print "_find_y_scale: self->{'min_val'}=NOT DEFINED\n";
    #}
    #if ( defined $self->{'max_val'} )
    #{
    #    print "_find_y_scale: self->{'max_val'}=".$self->{'max_val'}."\n";
    #}
    #else
    #{
    #    print "_find_y_scale: self->{'max_val'}= NOT DEFINED\n";
    #}
    #### end debugging output

    $self->{'min_val'}               = $p_min,
      $self->{'max_val'}             = $p_max,
      $self->{'y_ticks'}             = $tickCount,
      $self->{'y_tick_labels'}       = \@tickLabels,
      $self->{'y_tick_label_length'} = $maxtickLabelLen;

    ##################
    #print statement is for debug only
    #print "_find_y_scale: min_val = $p_min, max_val=$p_max\n";
    ##################

    # and return.
    return 1;
}

## @fn private _calcTickInterval($dataset_min, $dataset_max, $flag_fixed_min, $flag_fixed_max, $minTicks, $maxTicks)
# @brief
# Calculate the Interval between ticks in y direction
#
# @details
# Calculate the Interval between ticks in y direction
# and compare the number of ticks to
# the user's given values min_y_ticks, max_y_ticks.
#
# @param[in] dataset_min Minimal value in y direction
# @param[in] dataset_max Maximal value in y direction
# @param[in] flag_fixed_min Indicator whether the dataset_min value is fixed
# @param[in] flag_fixed_max Indicator whether the dataset_max value is fixed
# @param[in] minTicks Minimal number of ticks wanted
# @param[in] maxTicks Maximal number of ticks wanted
# @return Array of ($tickInterval, $tickCount, $pMin, $pMax)
#
sub _calcTickInterval
{
    my $self = shift;

    my (
        $dataset_min,    $dataset_max,       # The dataset min & max.
        $flag_fixed_min, $flag_fixed_max,    # Indicates if those min/max are fixed.
        $minTicks,       $maxTicks,          # The minimum & maximum number of ticks.
    ) = @_;

# print "calcTickInterval dataset_min $dataset_min dataset_max $dataset_max flag_fixed_min $flag_fixed_min flag_mixed_max $flag_fixed_max\n";

    # Verify the supplied 'min_y_ticks' & 'max_y_ticks' are sensible.
    if ( $minTicks < 2 )
    {

        #print STDERR "Chart::Base::_calcTickInterval : Incorrect value for 'min_y_ticks', too small (less than 2).\n";
        $minTicks = 2;
    }

    if ( $maxTicks < 5 * $minTicks )
    {

        #print STDERR "Chart::Base::_calcTickInterval : Incorrect value for 'max_y_ticks', too small (<5*minTicks).\n";
        $maxTicks = 5 * $minTicks;
    }

    my $width = $dataset_max - $dataset_min;
    my @divisorList;

    for ( my $baseMul = 1 ; ; $baseMul *= 10 )
    {
      TRY: foreach my $tryMul ( 1, 2, 5 )
        {

            # Calc a fresh, smaller tick interval.
            my $divisor = $baseMul * $tryMul;

            # Count the number of ticks.
            my ( $tickCount, $pMin, $pMax ) = $self->_countTicks( $dataset_min, $dataset_max, 1 / $divisor );

            # Look a the number of ticks.
            if ( $maxTicks < $tickCount )
            {

                # If it is to high, Backtrack.
                $divisor = pop @divisorList;

                # just for security:
                if ( !defined($divisor) || $divisor == 0 ) { $divisor = 1; }
                ( $tickCount, $pMin, $pMax ) = $self->_countTicks( $dataset_min, $dataset_max, 1 / $divisor );

#print STDERR "\nChart::Base : Caution: Tick limit of $maxTicks exceeded. Backing of to an interval of ".1/$divisor." which plots $tickCount ticks\n";
                return ( 1 / $divisor, $tickCount, $pMin, $pMax );
            }
            elsif ( $minTicks > $tickCount )
            {

                # If it is too low, try again.
                next TRY;
            }
            else
            {

                # Store the divisor for possible later backtracking.
                push @divisorList, $divisor;

                # if the min or max is fixed, check they will fit in the interval.
                next TRY if ( $flag_fixed_min && ( int( $dataset_min * $divisor ) != ( $dataset_min * $divisor ) ) );
                next TRY if ( $flag_fixed_max && ( int( $dataset_max * $divisor ) != ( $dataset_max * $divisor ) ) );

                # If everything passes the tests, return.
                return ( 1 / $divisor, $tickCount, $pMin, $pMax );
            }
        }
    }

    die "can't happen!";
}

## @fn private int _calcXTickInterval($min,$max,$minF,$maxF,$minTicks,$maxTicks)
# @brief
# Calculate the Interval between ticks in x direction
#
# @details
# Calculate the Interval between ticks in x direction
# and compare the number of ticks to
# the user's given values minTicks, maxTicks.
#
# @param[in] min Minimal value of dataset in x direction
# @param[in] max Maximal value of dataset in x direction
# @param[in] minF Inddicator if those min value is fixed
# @param[in] maxF Inddicator if those max value is fixed
# @param[in] minTicks Minimal number of tick in x direction
# @param[in] maxTicks Maximal number of tick in x direction
# @return $tickInterval, $tickCount, $pMin, $pMax
sub _calcXTickInterval
{
    my $self = shift;
    my (
        $min,      $max,         # The dataset min & max.
        $minF,     $maxF,        # Indicates if those min/max are fixed.
        $minTicks, $maxTicks,    # The minimum & maximum number of ticks.
    ) = @_;

    # Verify the supplied 'min_y_ticks' & 'max_y_ticks' are sensible.
    if ( $minTicks < 2 )
    {

        #print STDERR "Chart::Base::_calcXTickInterval : Incorrect value for 'min_y_ticks', too small.\n";
        $minTicks = 2;
    }

    if ( $maxTicks < 5 * $minTicks )
    {

        #print STDERR "Chart::Base::_calcXTickInterval : Incorrect value for 'max_y_ticks', to small.\n";
        $maxTicks = 5 * $minTicks;
    }

    my $width = $max - $min;
    my @divisorList;

    for ( my $baseMul = 1 ; ; $baseMul *= 10 )
    {
      TRY: foreach my $tryMul ( 1, 2, 5 )
        {

            # Calc a fresh, smaller tick interval.
            my $divisor = $baseMul * $tryMul;

            # Count the number of ticks.
            my ( $tickCount, $pMin, $pMax ) = $self->_countTicks( $min, $max, 1 / $divisor );

            #print STDERR "Chart::Base::_calcXTickInterval : tickCount = $tickCount, maxTicks = $maxTicks\n";
            # Look a the number of ticks.
            if ( $maxTicks < $tickCount )
            {

                # If it is to high, Backtrack.
                $divisor = pop @divisorList;

                # just for security:
                if ( !defined($divisor) || $divisor == 0 ) { $divisor = 1; }
                ( $tickCount, $pMin, $pMax ) = $self->_countTicks( $min, $max, 1 / $divisor );

#print STDERR "\nChart::Base : Caution: Tick limit of $maxTicks exceeded. Backing of to an interval of ".1/$divisor." which plots $tickCount ticks\n";
                return ( 1 / $divisor, $tickCount, $pMin, $pMax );
            }
            elsif ( $minTicks > $tickCount )
            {

                # If it is too low, try again.
                next TRY;
            }
            else
            {

                # Store the divisor for possible later backtracking.
                push @divisorList, $divisor;

                # if the min or max is fixed, check they will fit in the interval.
                next TRY if ( $minF && ( int( $min * $divisor ) != ( $min * $divisor ) ) );
                next TRY if ( $maxF && ( int( $max * $divisor ) != ( $max * $divisor ) ) );

                # If everything passes the tests, return.
                return ( 1 / $divisor, $tickCount, $pMin, $pMax );
            }
        }
    }

    croak "can't happen!";
}

## @fn private int _countTicks($min,$max,$interval)
#
# @brief
# Works out how many ticks would be displayed at that interval
#
# @param min Minimal value
# @param max Maximal value
# @param interval value
# @return ($tickCount, $minR, $maxR)
#
# @details
#
# e.g min=2, max=5, interval=1, result is 4 ticks.\n
# written by David Pottage of Tao Group.\n
# $minR = $self->_round2Tick( $min, $interval, -1);\n
# $maxR = $self->_round2Tick( $max, $interval, 1);\n
# $tickCount = ( $maxR/$interval ) - ( $minR/$interval ) +1;
sub _countTicks
{
    my $self = shift;
    my ( $min, $max, $interval ) = @_;

    my $minR = $self->_round2Tick( $min, $interval, -1 );
    my $maxR = $self->_round2Tick( $max, $interval, 1 );

    my $tickCount = ( $maxR / $interval ) - ( $minR / $interval ) + 1;

    return ( $tickCount, $minR, $maxR );
}

## @fn private int _round2Tick($input, $interval, $roundUP)
# Rounds up or down to the next tick of interval size.
#
# $roundUP can be +1 or -1 to indicate if rounding should be up or down.\n
# written by David Pottage of Tao Group.
#
# @param input
# @param interval
# @param roundUP
# @return retN*interval
sub _round2Tick
{
    my $self = shift;
    my ( $input, $interval, $roundUP ) = @_;
    return $input if $interval == 0;
    die unless 1 == $roundUP * $roundUP;

    my $intN  = int( $input / $interval );
    my $fracN = ( $input / $interval ) - $intN;

    my $retN =
      ( ( 0 == $fracN ) || ( ( $roundUP * $fracN ) < 0 ) )
      ? $intN
      : $intN + $roundUP;

    return $retN * $interval;
}

## @fn private array _sepFP($num)
# @brief
# Seperates a number into it's base 10 floating point exponent & mantisa.
# @details
# written by David Pottage of Tao Group.
#
# @param num Floating point number
# @return ( exponent, mantissa)
sub _sepFP
{
    my $self = shift;
    my ($num) = @_;
    return ( 0, 0 ) if $num == 0;

    my $sign = ( $num > 0 ) ? 1 : -1;
    $num *= $sign;

    my $exponent = int( log($num) / log(10) );
    my $mantisa = $sign * ( $num / ( 10**$exponent ) );

    return ( $exponent, $mantisa );
}

## @fn private array _find_y_range()
# Find minimum and maximum value of y data sets.
#
# @return ( min, max, flag_all_integers )
sub _find_y_range
{
    my $self = shift;
    my $data = $self->{'dataref'};

    my $max               = undef;
    my $min               = undef;
    my $flag_all_integers = 1;       # assume true

    for my $dataset ( @$data[ 1 .. $#$data ] )
    {
        for my $datum (@$dataset)
        {
            if ( defined $datum )
            {

                #croak "Missing data (dataset)";
                if ($flag_all_integers)
                {

                    # it's worth looking for integers
                    if ( $datum !~ /^[\-\+]?\d+$/ )
                    {
                        $flag_all_integers = 0;    # No
                    }
                }
                if ( $datum =~ /^[\-\+]?\s*[\d\.eE\-\+]+/ )
                {
                    if ( defined $max && $max =~ /^[\-\+]{0,}\s*[\d\.eE\-\+]+/ )
                    {
                        if    ( $datum > $max ) { $max = $datum; }
                        elsif ( !defined $min ) { $min = $datum; }
                        elsif ( $datum < $min ) { $min = $datum; }
                    }
                    else { $min = $max = $datum }
                }
            }
        }
    }

    # Return:
    ( $min, $max, $flag_all_integers );
}

## @fn private array _find_x_range()
# Find minimum and maximum value of x data sets
# @return ( min, max )
sub _find_x_range
{
    my $self = shift;
    my $data = $self->{'dataref'};

    my $max = undef;
    my $min = undef;

    for my $datum ( @{ $data->[0] } )
    {
        if ( defined $datum && $datum =~ /^[\-\+]{0,1}\s*[\d\.eE\-\+]+/ )
        {
            if ( defined $max && $max =~ /^[\-\+]{0,1}\s*[\d\.eE\-\+]+/ )
            {
                if    ( $datum > $max ) { $max = $datum }
                elsif ( $datum < $min ) { $min = $datum }
            }
            else { $min = $max = $datum }
        }
    }

    return ( $min, $max );
}

## @fn private int _plot()
# main sub that controls all the plotting of the actual chart
# @return status
sub _plot
{
    my $self = shift;

    # draw the legend first
    $self->_draw_legend();

    # mark off the graph_border space
    $self->{'curr_x_min'} += $self->{'graph_border'};
    $self->{'curr_x_max'} -= $self->{'graph_border'};
    $self->{'curr_y_min'} += $self->{'graph_border'};
    $self->{'curr_y_max'} -= $self->{'graph_border'};

    # draw the x- and y-axis labels
    $self->_draw_x_label          if $self->{'x_label'};
    $self->_draw_y_label('left')  if $self->{'y_label'};
    $self->_draw_y_label('right') if $self->{'y_label2'};

    # draw the ticks and tick labels
    $self->_draw_ticks();

    # give the plot a grey background if they want it
    $self->_grey_background if ( $self->true( $self->{'grey_background'} ) );

    #draw the ticks again if grey_background has ruined it in a Direction Chart.
    if ( $self->true( $self->{'grey_background'} ) && $self->isa("Chart::Direction") )
    {
        $self->_draw_ticks;
    }
    $self->_draw_grid_lines    if ( $self->true( $self->{'grid_lines'} ) );
    $self->_draw_x_grid_lines  if ( $self->true( $self->{'x_grid_lines'} ) );
    $self->_draw_y_grid_lines  if ( $self->true( $self->{'y_grid_lines'} ) );
    $self->_draw_y2_grid_lines if ( $self->true( $self->{'y2_grid_lines'} ) );

    # plot the data
    $self->_draw_data();

    # and return
    return 1;
}

## @fn private int _draw_legend()
# let the user know what all the pretty colors mean.\n
# The user define the position of the legend by setting option
# 'legend' to 'top', 'bottom', 'left', 'right' or 'none'.
# The legend is positioned at the defined place, respectively.
# @return status
sub _draw_legend
{
    my $self = shift;
    my $length;

    # check to see if legend type is none..
    if ( $self->{'legend'} =~ /^none$/ || length( $self->{'legend'} ) == 0 )
    {
        return 1;
    }

    # check to see if they have as many labels as datasets,
    # warn them if not
    if (   ( $#{ $self->{'legend_labels'} } >= 0 )
        && ( ( scalar( @{ $self->{'legend_labels'} } ) ) != $self->{'num_datasets'} ) )
    {
        carp "The number of legend labels and datasets doesn\'t match";
    }

    # init a field to store the length of the longest legend label
    unless ( $self->{'max_legend_label'} )
    {
        $self->{'max_legend_label'} = 0;
    }

    # fill in the legend labels, find the longest one
    for ( 1 .. $self->{'num_datasets'} )
    {
        unless ( $self->{'legend_labels'}[ $_ - 1 ] )
        {
            $self->{'legend_labels'}[ $_ - 1 ] = "Dataset $_";
        }
        $length = length( $self->{'legend_labels'}[ $_ - 1 ] );
        if ( $length > $self->{'max_legend_label'} )
        {
            $self->{'max_legend_label'} = $length;
        }
    }

    # different legend types
    if ( $self->{'legend'} eq 'bottom' )
    {
        $self->_draw_bottom_legend;
    }
    elsif ( $self->{'legend'} eq 'right' )
    {
        $self->_draw_right_legend;
    }
    elsif ( $self->{'legend'} eq 'left' )
    {
        $self->_draw_left_legend;
    }
    elsif ( $self->{'legend'} eq 'top' )
    {
        $self->_draw_top_legend;
    }
    elsif ( $self->{'legend'} eq 'none' || length( $self->{'legend'} ) == 0 )
    {
        $self->_draw_none_legend;
    }
    else
    {
        carp "I can't put a legend there (at " . $self->{'legend'} . ")\n";
    }

    # and return
    return 1;
}

## @fn private int _draw_bottom_legend()
# put the legend on the bottom of the chart
# @return status
sub _draw_bottom_legend
{
    my $self = shift;

    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1,          $y1,              $x2,   $x3,   $y2 );
    my ( $empty_width, $max_label_width, $cols, $rows, $color, $brush );
    my ( $col_width,   $row_height,      $r,    $c,    $index, $x, $y, $w, $h, $axes_space );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # find the base x values
    $axes_space =
      ( $self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width ) +
      $self->{'tick_len'} +
      ( 3 * $self->{'text_space'} );
    $x1 = $self->{'curr_x_min'} + $self->{'graph_border'};
    $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};

    if ( $self->{'y_axes'} =~ /^right$/i )
    {
        $x2 -= $axes_space;
    }
    elsif ( $self->{'y_axes'} =~ /^both$/i )
    {
        $x2 -= $axes_space;
        $x1 += $axes_space;
    }

    if ( $self->{'y_label'} )
    {
        $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    if ( $self->{'y_label2'} )
    {
        $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }

    # figure out how wide the columns need to be, and how many we
    # can fit in the space available
    $empty_width = ( $x2 - $x1 ) - ( 2 * $self->{'legend_space'} );
    $max_label_width = $self->{'max_legend_label'} * $w + ( 4 * $self->{'text_space'} ) + $self->{'legend_example_size'};
    $cols = int( $empty_width / $max_label_width );

    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need, remember how tall they are
    $rows = int( $self->{'num_datasets'} / $cols );
    unless ( ( $self->{'num_datasets'} % $cols ) == 0 )
    {
        $rows++;
    }
    unless ($rows)
    {
        $rows = 1;
    }
    $row_height = $h + $self->{'text_space'};

    # box the legend off
    $y1 = $self->{'curr_y_max'} - $self->{'text_space'} - ( $rows * $row_height ) - ( 2 * $self->{'legend_space'} );
    $y2 = $self->{'curr_y_max'};
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $self->_color_role_to_index('misc') );
    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    for $r ( 0 .. $rows - 1 )
    {
        for $c ( 0 .. $cols - 1 )
        {
            $index = ( $r * $cols ) + $c;    # find the index in the label array
            if ( $labels[$index] )
            {

                # get the color
                $color = $self->_color_role_to_index( 'dataset' . $index );

                # get the x-y coordinate for the start of the example line
                $x = $x1 + ( $col_width * $c );
                $y = $y1 + ( $row_height * $r ) + $h / 2;

                # now draw the example line
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );

                # reset the brush for points
                $brush = $self->_prepare_brush( $color, 'point', 'dataset' . $index );
                $self->{'gd_obj'}->setBrush($brush);

                # draw the point
                $x3 = int( $x + $self->{'legend_example_size'} / 2 );
                $self->{'gd_obj'}->line( $x3, $y, $x3, $y, gdBrushed );

                # adjust the x-y coordinates for the start of the label
                $x += $self->{'legend_example_size'} + ( 2 * $self->{'text_space'} );
                $y = $y1 + ( $row_height * $r );

                # now draw the label
                $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );
            }
        }
    }

    # mark off the space used
    $self->{'curr_y_max'} -= $rows * $row_height + 2 * $self->{'text_space'} + 2 * $self->{'legend_space'};

    # now return
    return 1;
}

## @fn private int _draw_right_legend()
# put the legend on the right of the chart
# @return status
sub _draw_right_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    # find out how wide the largest label is
    $width =
      ( 2 * $self->{'text_space'} ) +
      ( $self->{'max_legend_label'} * $w ) +
      $self->{'legend_example_size'} +
      ( 2 * $self->{'legend_space'} );

    # get some starting x-y values
    $x1 = $self->{'curr_x_max'} - $width;
    $x2 = $self->{'curr_x_max'};
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datasets'} * ( $h + $self->{'text_space'} ) ) +
      ( 2 * $self->{'legend_space'} );

    # box the legend off
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $misccolor );

    # leave that nice space inside the legend box
    $x1 += $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};

    # now draw the actual legend
    for ( 0 .. $#labels )
    {

        # get the color
        my $c = $self->{'num_datasets'} - $_ - 1;

        # color of the datasets in the legend
        $color = $self->_color_role_to_index( 'dataset' . $_ );

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # do the line first
        $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );

        # reset the brush for points
        my $offset = 0;
        ( $brush, $offset ) = $self->_prepare_brush( $color, 'point', 'dataset' . $_ );
        $self->{'gd_obj'}->setBrush($brush);

        # draw the point
        $self->{'gd_obj'}->line( int( ( $x3 + $x2 ) / 2 ), $y2, int( ( $x3 + $x2 ) / 2 ), $y2, gdBrushed );

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;

        # order of the datasets in the legend
        $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
    }

    # mark off the used space
    $self->{'curr_x_max'} -= $width;

    # and return
    return 1;
}

## @fn private int _draw_top_legend()
# put the legend on top of the chart
# @return status
sub _draw_top_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $y1, $x2, $x3, $y2, $empty_width, $max_label_width );
    my ( $cols, $rows, $color, $brush );
    my ( $col_width, $row_height, $r, $c, $index, $x, $y, $w, $h, $axes_space );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # find the base x values
    $axes_space =
      ( $self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width ) +
      $self->{'tick_len'} +
      ( 3 * $self->{'text_space'} );
    $x1 = $self->{'curr_x_min'} + $self->{'graph_border'};
    $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};

    if ( $self->{'y_axes'} =~ /^right$/i )
    {
        $x2 -= $axes_space;
    }
    elsif ( $self->{'y_axes'} =~ /^both$/i )
    {
        $x2 -= $axes_space;
        $x1 += $axes_space;
    }

    # figure out how wide the columns can be, and how many will fit
    $empty_width = ( $x2 - $x1 ) - ( 2 * $self->{'legend_space'} );
    $max_label_width = ( 4 * $self->{'text_space'} ) + ( $self->{'max_legend_label'} * $w ) + $self->{'legend_example_size'};
    $cols = int( $empty_width / $max_label_width );
    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need and remember how tall they are
    $rows = int( $self->{'num_datasets'} / $cols );
    unless ( ( $self->{'num_datasets'} % $cols ) == 0 )
    {
        $rows++;
    }
    unless ($rows)
    {
        $rows = 1;
    }
    $row_height = $h + $self->{'text_space'};

    # box the legend off
    $y1 = $self->{'curr_y_min'};
    $y2 = $self->{'curr_y_min'} + $self->{'text_space'} + ( $rows * $row_height ) + ( 2 * $self->{'legend_space'} );
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $self->_color_role_to_index('misc') );

    # leave some space inside the legend
    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    for $r ( 0 .. $rows - 1 )
    {
        for $c ( 0 .. $cols - 1 )
        {
            $index = ( $r * $cols ) + $c;    # find the index in the label array
            if ( $labels[$index] )
            {

                # get the color
                $color = $self->_color_role_to_index( 'dataset' . $index );

                # find the x-y coords
                $x = $x1 + ( $col_width * $c );
                $y = $y1 + ( $row_height * $r ) + $h / 2;

                # draw the line first
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );

                # reset the brush for points
                $brush = $self->_prepare_brush( $color, 'point', 'dataset' . $index );
                $self->{'gd_obj'}->setBrush($brush);

                # draw the point
                $x3 = int( $x + $self->{'legend_example_size'} / 2 );
                $self->{'gd_obj'}->line( $x3, $y, $x3, $y, gdBrushed );

                # now the label
                $x += $self->{'legend_example_size'} + ( 2 * $self->{'text_space'} );
                $y -= $h / 2;
                $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );
            }
        }
    }

    # mark off the space used
    $self->{'curr_y_min'} += ( $rows * $row_height ) + $self->{'text_space'} + 2 * $self->{'legend_space'};

    # now return
    return 1;
}

## @fn private int _draw_left_legend()
# put the legend on the left of the chart
# @return status
sub _draw_left_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    # find out how wide the largest label is
    $width =
      ( 2 * $self->{'text_space'} ) +
      ( $self->{'max_legend_label'} * $w ) +
      $self->{'legend_example_size'} +
      ( 2 * $self->{'legend_space'} );

    # get some base x-y coordinates
    $x1 = $self->{'curr_x_min'};
    $x2 = $self->{'curr_x_min'} + $width;
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datasets'} * ( $h + $self->{'text_space'} ) ) +
      ( 2 * $self->{'legend_space'} );

    # box the legend off
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $misccolor );

    # leave that nice space inside the legend box
    $x1 += $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};

    # now draw the actual legend
    for ( 0 .. $#labels )
    {

        # get the color
        my $c = $self->{'num_datasets'} - $_ - 1;

        # color of the datasets in the legend
        $color = $self->_color_role_to_index( 'dataset' . $_ );

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # do the line first
        $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );

        # reset the brush for points
        $brush = $self->_prepare_brush( $color, 'point', 'dataset' . $_ );
        $self->{'gd_obj'}->setBrush($brush);

        # draw the point
        $self->{'gd_obj'}->line( int( ( $x3 + $x2 ) / 2 ), $y2, int( ( $x3 + $x2 ) / 2 ), $y2, gdBrushed );

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;

        # order of the datasets in the legend
        $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
    }

    # mark off the used space
    $self->{'curr_x_min'} += $width;

    # and return
    return 1;
}

## @fn private int _draw_none_legend()
# no legend to draw..
# Just return in this case. This routine may be overwritten by
# subclasses.
# @return 1
sub _draw_none_legend
{
    my $self   = shift;
    my $status = 1;

    return $status;
}

## @fn private int _draw_x_label()
# draw the label for the x-axis
#
# Get font for labels\n
# Get the color of x_label or text\n
# Get size of font\n
# and write x-Label
#
# @return status
sub _draw_x_label
{
    my $self  = shift;
    my $label = $self->{'x_label'};
    my $font  = $self->{'label_font'};
    my $color;
    my ( $h, $w, $x, $y );

    #get the right color
    if ( defined $self->{'colors'}->{'x_label'} )
    {
        $color = $self->_color_role_to_index('x_label');
    }
    else
    {
        $color = $self->_color_role_to_index('text');
    }

    # make sure it's a real GD Font object
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The x-axis label font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # make sure it goes in the right place
    $x = ( $self->{'curr_x_max'} - $self->{'curr_x_min'} ) / 2 + $self->{'curr_x_min'} - ( length($label) * $w ) / 2;
    $y = $self->{'curr_y_max'} - ( $self->{'text_space'} + $h );

    # now write it
    $self->{'gd_obj'}->string( $font, $x, $y, $label, $color );

    # mark the space written to as used
    $self->{'curr_y_max'} -= $h + 2 * $self->{'text_space'};

    # and return
    return 1;
}

## @fn private int _draw_y_label()
# draw the label for the y-axis
# @return status
sub _draw_y_label
{
    my $self = shift;
    my $side = shift;
    my $font = $self->{'label_font'};
    my ( $label, $h, $w, $x, $y, $color );

    # get the label
    if ( $side eq 'left' )
    {
        $label = $self->{'y_label'};
        $color = $self->_color_role_to_index('y_label');
    }
    elsif ( $side eq 'right' )
    {
        $label = $self->{'y_label2'};
        $color = $self->_color_role_to_index('y_label2');
    }

    # make sure it's a real GD Font object
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The x-axis label font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # make sure it goes in the right place
    if ( $side eq 'left' )
    {
        $x = $self->{'curr_x_min'} + $self->{'text_space'};
    }
    elsif ( $side eq 'right' )
    {
        $x = $self->{'curr_x_max'} - $self->{'text_space'} - $h;
    }
    $y = ( $self->{'curr_y_max'} - $self->{'curr_y_min'} ) / 2 + $self->{'curr_y_min'} + ( length($label) * $w ) / 2;

    # write it
    $self->{'gd_obj'}->stringUp( $font, $x, $y, $label, $color );

    # mark the space written to as used
    if ( $side eq 'left' )
    {
        $self->{'curr_x_min'} += $h + 2 * $self->{'text_space'};
    }
    elsif ( $side eq 'right' )
    {
        $self->{'curr_x_max'} -= $h + 2 * $self->{'text_space'};
    }

    # now return
    return 1;
}

## @fn private int _draw_ticks()
# draw the ticks and tick labels
# @return status
sub _draw_ticks
{
    my $self = shift;

    #if the user wants an xy_plot, calculate the x-ticks too
    if (
        $self->true( $self->{'xy_plot'} )
        && (   $self->isa('Chart::Lines')
            || $self->isa('Chart::Points')
            || $self->isa('Chart::LinesPoints')
            || $self->isa('Chart::Split')
            || $self->isa('Chart::ErrorBars') )
      )
    {
        $self->_draw_x_number_ticks;
    }
    else
    {    # draw the x ticks with strings
        $self->_draw_x_ticks;
    }

    # now the y ticks
    $self->_draw_y_ticks( $self->{'y_axes'} );

    # then return
    return 1;
}

## @fn private int _draw_x_number_ticks()
# draw the ticks and tick labels
# @return status
sub _draw_x_number_ticks
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $h, $w, $x1, $y1, $y2, $x2, $delta, $width, $label );
    my @labels = @{ $self->{'x_tick_labels'} };

    $self->{'grid_data'}->{'x'} = [];

    #make sure we have a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn't a GD font object";
    }

    #get height and width of the font
    ( $h, $w ) = ( $font->height, $font->width );

    #store actual borders, for a possible later repair
    $self->{'temp_x_min'} = $self->{'curr_x_min'};
    $self->{'temp_x_max'} = $self->{'curr_x_max'};
    $self->{'temp_y_max'} = $self->{'curr_y_max'};
    $self->{'temp_y_min'} = $self->{'curr_y_min'};

    #get the right x-value and width
    #The one and only way to get the RIGHT x value and the width
    if ( $self->{'y_axes'} =~ /^right$/i )
    {
        $x1 = $self->{'curr_x_min'};
        $width =
          $self->{'curr_x_max'} -
          $x1 -
          ( $w * $self->{'y_tick_label_length'} ) -
          3 * $self->{'text_space'} -
          $self->{'tick_len'};
    }
    elsif ( $self->{'y_axes'} =~ /^both$/i )
    {
        $x1 = $self->{'curr_x_min'} + ( $w * $self->{'y_tick_label_length'} ) + 3 * $self->{'text_space'} + $self->{'tick_len'};
        $width =
          $self->{'curr_x_max'} -
          $x1 -
          ( $w * $self->{'y_tick_label_length'} ) -
          ( 3 * $self->{'text_space'} ) -
          $self->{'tick_len'};
    }
    else
    {
        $x1 = $self->{'curr_x_min'} + ( $w * $self->{'y_tick_label_length'} ) + 3 * $self->{'text_space'} + $self->{'tick_len'};
        $width = $self->{'curr_x_max'} - $x1;
    }

    #get the delta value
    $delta = $width / ( $self->{'x_number_ticks'} - 1 );

    #draw the labels
    $y2 = $y1;

    if ( $self->{'x_ticks'} =~ /^normal/i )
    {    #just normal ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 2 * $self->{'text_space'} - $h - $self->{'tick_len'};

        #get the start point
        $y2 = $y1 + $self->{'tick_len'} + $self->{'text_space'};

        if ( $self->{'xlabels'} )
        {
            unless ( $self->{'xrange'} )
            {
                croak "Base.pm: xrange must be specified with xlabels!\n";
            }
            my $xmin   = $self->{'xrange'}[0];
            my $xmax   = $self->{'xrange'}[1];
            my @labels = @{ $self->{'xlabels'}[0] };
            my @vals   = @{ $self->{'xlabels'}[1] };
            my $delta  = $width / ( $xmax - $xmin );

            for ( 0 .. $#labels )
            {
                my $label = $labels[$_];
                my $val   = $vals[$_];
                $x2 = $x1 + ( $delta * ( $val - $xmin ) ) - ( 0.5 * $w * length($label) );
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );

                #print "write x-label '".$label."' at ($x2,$y2)\n";
            }
        }
        else
        {
            my $last_x = 'undefined';
            for ( 0 .. $#labels )
            {
                $label = $self->{f_x_tick}->( $self->{'x_tick_labels'}[$_] );
                $x2 = $x1 + ( $delta * $_ ) - ( 0.5 * $w * length($label) );
                if (   $last_x eq 'undefined'
                    or $last_x < $x2 )
                {
                    $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
                    $last_x = $x2 + ( $w * length($label) );
                }

                #print "last_x = $last_x, write string '".$label."' at ($x2,$y2) to '$_'\n";
            }
        }
    }

    elsif ( $self->{'x_ticks'} =~ /^staggered/i )
    {    #staggered ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 3 * $self->{'text_space'} - 2 * $h - $self->{'tick_len'};

        if ( $self->{'xlabels'} )
        {
            unless ( $self->{'xrange'} )
            {
                croak "Base.pm: xrange must be specified with xlabels!\n";
            }
            my $xmin   = $self->{'xrange'}[0];
            my $xmax   = $self->{'xrange'}[1];
            my @labels = @{ $self->{'xlabels'}[0] };
            my @vals   = @{ $self->{'xlabels'}[1] };
            my $delta  = $width / ( $xmax - $xmin );

            for ( 0 .. $#labels )
            {
                my $label = $labels[$_];
                my $val   = $vals[$_];
                $x2 = $x1 + ( $delta * ( $val - $xmin ) ) - ( 0.5 * $w * length($label) );
                unless ( $_ % 2 )
                {
                    $y2 = $y1 + $self->{'text_space'} + $self->{'tick_len'};
                }
                else
                {
                    $y2 = $y1 + $h + 2 * $self->{'text_space'} + $self->{'tick_len'};
                }
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );

                #print "write x-label '".$label."' at ($x2,$y2)\n";
            }
        }
        else
        {
            for ( 0 .. $#labels )
            {
                $label = $self->{f_x_tick}->( $self->{'x_tick_labels'}[$_] );
                $x2 = $x1 + ( $delta * $_ ) - ( 0.5 * $w * length($label) );
                unless ( $_ % 2 )
                {
                    $y2 = $y1 + $self->{'text_space'} + $self->{'tick_len'};
                }
                else
                {
                    $y2 = $y1 + $h + 2 * $self->{'text_space'} + $self->{'tick_len'};
                }
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
            }
        }
    }

    elsif ( $self->{'x_ticks'} =~ /^vertical/i )
    {    #vertical ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 2 * $self->{'text_space'} - $w * $self->{'x_tick_label_length'} - $self->{'tick_len'};

        if ( $self->{'xlabels'} )
        {
            unless ( $self->{'xrange'} )
            {
                croak "Base.pm: xrange must be specified with xlabels!\n";
            }
            my $xmin   = $self->{'xrange'}[0];
            my $xmax   = $self->{'xrange'}[1];
            my @labels = @{ $self->{'xlabels'}[0] };
            my @vals   = @{ $self->{'xlabels'}[1] };
            my $delta  = $width / ( $xmax - $xmin );

            for ( 0 .. $#labels )
            {
                my $label = $labels[$_];
                my $val   = $vals[$_];
                $y2 = $y1 + $self->{'tick_len'} + $w * length($label) + $self->{'text_space'};
                $x2 = $x1 + ( $delta * ( $val - $xmin ) ) - ( $h / 2 );
                $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $label, $textcolor );

                #print "write x-label '".$label."' at ($x2,$y2)\n";
            }
        }
        else
        {

            for ( 0 .. $#labels )
            {
                $label = $self->{f_x_tick}->( $self->{'x_tick_labels'}[$_] );

                #get the start point
                $y2 = $y1 + $self->{'tick_len'} + $w * length($label) + $self->{'text_space'};
                $x2 = $x1 + ( $delta * $_ ) - ( $h / 2 );
                $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $label, $textcolor );
            }
        }
    }

    else
    {
        croak "I don't understand the type of x-ticks you specified\n"
          . "x-ticks must be one of 'normal', 'staggered' or 'vertical' but not of '"
          . $self->{'x_ticks'} . "'.";
    }

    #update the curr y max value
    $self->{'curr_y_max'} = $y1;

    #draw the ticks
    $y1 = $self->{'curr_y_max'};
    $y2 = $self->{'curr_y_max'} + $self->{'tick_len'};

    #draw grid lines
    if ( $self->{'xlabels'} )
    {
        unless ( $self->{'xrange'} )
        {
            croak "Base.pm: xrange must be specified with xlabels!\n";
        }
        my $xmin  = $self->{'xrange'}[0];
        my $xmax  = $self->{'xrange'}[1];
        my @vals  = @{ $self->{'xlabels'}[1] };
        my $delta = $width / ( $xmax - $xmin );

        for ( 0 .. $#vals )
        {
            my $val = $vals[$_];
            $x2 = ($x1) + ( $delta * ( $val - $xmin ) );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    else
    {
        for ( 0 .. $#labels )
        {
            $x2 = $x1 + ( $delta * $_ );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   ( $self->true( $self->{'grid_lines'} ) )
                or ( $self->true( $self->{'x_grid_lines'} ) ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    return 1;
}

## @fn private int _draw_x_ticks()
# draw the x-ticks and their labels
# @return status
sub _draw_x_ticks
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my $label;
    my ( $h,     $w );
    my ( $x1,    $x2, $y1, $y2 );
    my ( $width, $delta );
    my ($stag);

    $self->{'grid_data'}->{'x'} = [];

    # make sure we got a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn\'t a GD Font object";
    }

    # get the height and width of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # maybe, we need the actual x and y values later for drawing the x-ticks again
    # in the draw function in the lines modul. So copy them.
    $self->{'temp_x_min'} = $self->{'curr_x_min'};
    $self->{'temp_x_max'} = $self->{'curr_x_max'};
    $self->{'temp_y_min'} = $self->{'curr_y_min'};
    $self->{'temp_y_max'} = $self->{'curr_y_max'};

    # allow for the amount of space the y-ticks will push the
    # axes over to the right
    ## _draw_y_ticks allows 3 * text_space, not 1 * ;  this caused mismatch between
    ## the ticks (and grid lines) and the data.
    #   $x1 = $self->{'curr_x_min'} + ($w * $self->{'y_tick_label_length'})
    #          + $self->{'text_space'} + $self->{'tick_len'};
    ## And, what about the right-tick space??  Only affects Composite, I guess....

    #The one and only way to get the RIGHT x value and the width
    if ( $self->{'y_axes'} =~ /^right$/i )
    {
        $x1 = $self->{'curr_x_min'};
        $width =
          $self->{'curr_x_max'} -
          $x1 -
          ( $w * $self->{'y_tick_label_length'} ) -
          3 * $self->{'text_space'} -
          $self->{'tick_len'};
    }
    elsif ( $self->{'y_axes'} =~ /^both$/i )
    {
        $x1 = $self->{'curr_x_min'} + ( $w * $self->{'y_tick_label_length'} ) + 3 * $self->{'text_space'} + $self->{'tick_len'};
        $width =
          $self->{'curr_x_max'} -
          $x1 -
          ( $w * $self->{'y_tick_label_length'} ) -
          3 * $self->{'text_space'} -
          $self->{'tick_len'};
    }
    else
    {
        $x1 = $self->{'curr_x_min'} + ( $w * $self->{'y_tick_label_length'} ) + 3 * $self->{'text_space'} + $self->{'tick_len'};
        $width = $self->{'curr_x_max'} - $x1;
    }

    #the same for the y value, but not so tricky
    $y1 = $self->{'curr_y_max'} - $h - $self->{'text_space'};

    # get the delta value, figure out how to draw the labels
    $delta = $width / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    if ( !defined( $self->{'skip_x_ticks'} ) )
    {
        $self->{'skip_x_ticks'} = 1;
    }
    elsif ( $self->{'skip_x_ticks'} == 0 )
    {
        $self->{'skip_x_ticks'} = 1;
    }
    if ( $delta <= ( $self->{'x_tick_label_length'} * $w ) / $self->{'skip_x_ticks'} )
    {
        if ( $self->{'x_ticks'} =~ /^normal$/i )
        {
            $self->{'x_ticks'} = 'staggered';
        }
    }

    # now draw the labels
    if ( $self->{'x_ticks'} =~ /^normal$/i )
    {    # normal ticks
        if ( $self->{'skip_x_ticks'} > 1 )
        {    # draw only every nth tick and label
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                if ( defined( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) )
                {
                    $label = $self->{f_x_tick}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] );
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) - ( $w * length($label) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x2, $y1, $label, $textcolor );
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {    # draw only the ticks they wanted
            for ( @{ $self->{'custom_x_ticks'} } )
            {
                if ( defined($_) )
                {
                    $label = $self->{f_x_tick}->( $data->[0][$_] );
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length($label) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x2, $y1, $label, $textcolor );
                }
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                if ( defined($_) )
                {
                    $label = $self->{f_x_tick}->( $data->[0][$_] );
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length($label) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x2, $y1, $label, $textcolor );
                }
            }
        }
    }

    elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
    {    # staggered ticks
        if ( $self->{'skip_x_ticks'} > 1 )
        {
            $stag = 0;
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                if ( defined( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) )
                {
                    $x2 =
                      $x1 +
                      ( $delta / 2 ) +
                      ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) -
                      ( $w * length( $self->{f_x_tick}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) ) ) / 2;
                    if ( ( $stag % 2 ) == 1 )
                    {
                        $y1 -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}
                      ->string( $font, $x2, $y1, $self->{f_x_tick}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ),
                        $textcolor );
                    if ( ( $stag % 2 ) == 1 )
                    {
                        $y1 += $self->{'text_space'} + $h;
                    }
                    $stag++;
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            $stag = 0;
            for ( sort ( @{ $self->{'custom_x_ticks'} } ) )
            {    # sort to make it look good
                if ( defined($_) )
                {
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{f_x_tick}->( $data->[0][$_] ) ) ) / 2;
                    if ( ( $stag % 2 ) == 1 )
                    {
                        $y1 -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{f_x_tick}->( $data->[0][$_] ), $textcolor );
                    if ( ( $stag % 2 ) == 1 )
                    {
                        $y1 += $self->{'text_space'} + $h;
                    }
                    $stag++;
                }
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                if ( defined( $self->{f_x_tick}->( $data->[0][$_] ) ) )
                {
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{f_x_tick}->( $data->[0][$_] ) ) ) / 2;
                    if ( ( $_ % 2 ) == 1 )
                    {
                        $y1 -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{f_x_tick}->( $data->[0][$_] ), $textcolor );
                    if ( ( $_ % 2 ) == 1 )
                    {
                        $y1 += $self->{'text_space'} + $h;
                    }
                }
            }
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
    {    # vertical ticks
        $y1 = $self->{'curr_y_max'} - $self->{'text_space'};
        if ( $self->{'skip_x_ticks'} > 1 )
        {
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                if ( defined($_) )
                {
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) - $h / 2;
                    $y2 = $y1 - (
                        (
                            $self->{'x_tick_label_length'} -
                              length( $self->{f_x_tick}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) )
                        ) * $w
                    );
                    $self->{'gd_obj'}
                      ->stringUp( $font, $x2, $y2, $self->{f_x_tick}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ),
                        $textcolor );
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            for ( @{ $self->{'custom_x_ticks'} } )
            {
                if ( defined($_) )
                {
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - $h / 2;
                    $y2 = $y1 - ( ( $self->{'x_tick_label_length'} - length( $self->{f_x_tick}->( $data->[0][$_] ) ) ) * $w );
                    $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $self->{f_x_tick}->( $data->[0][$_] ), $textcolor );
                }
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                if ( defined($_) )
                {
                    $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - $h / 2;
                    $y2 = $y1 - ( ( $self->{'x_tick_label_length'} - length( $self->{f_x_tick}->( $data->[0][$_] ) ) ) * $w );
                    $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $self->{f_x_tick}->( $data->[0][$_] ), $textcolor );
                }
            }
        }
    }
    else
    {    # error time
        carp "I don't understand the type of x-ticks you specified";
    }

    # update the current y-max value
    if ( $self->{'x_ticks'} =~ /^normal$/i )
    {
        $self->{'curr_y_max'} -= $h + ( 2 * $self->{'text_space'} );
    }
    elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
    {
        $self->{'curr_y_max'} -= ( 2 * $h ) + ( 3 * $self->{'text_space'} );
    }
    elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
    {
        $self->{'curr_y_max'} -= ( $w * $self->{'x_tick_label_length'} ) + ( 2 * $self->{'text_space'} );
    }

    # now plot the ticks
    $y1 = $self->{'curr_y_max'};
    $y2 = $self->{'curr_y_max'} - $self->{'tick_len'};
    if ( $self->{'skip_x_ticks'} > 1 )
    {
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * ( $_ * $self->{'skip_x_ticks'} ) );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    elsif ( $self->{'custom_x_ticks'} )
    {
        for ( @{ $self->{'custom_x_ticks'} } )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    else
    {
        for ( 0 .. $self->{'num_datapoints'} - 1 )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }

    # update the current y-max value
    $self->{'curr_y_max'} -= $self->{'tick_len'};
}

## @fn private int _draw_y_ticks()
#  draw the y-ticks and their labels
# @return status
sub _draw_y_ticks
{
    my $self      = shift;
    my $side      = shift || 'left';
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my @labels    = @{ $self->{'y_tick_labels'} };
    my ( $w, $h );
    my ( $x1, $x2, $y1, $y2 );
    my ( $height, $delta, $label );
    my ( $s, $f );

    $self->{grid_data}->{'y'}  = [];
    $self->{grid_data}->{'y2'} = [];

    # make sure we got a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn\'t a GD Font object";
    }

    # find out how big the font is
    ( $w, $h ) = ( $font->width, $font->height );

    # figure out which ticks not to draw
    if ( $self->{'min_val'} >= 0 )
    {
        $s = 1;
        $f = $#labels;
    }
    elsif ( $self->{'max_val'} <= 0 )
    {
        $s = 0;
        $f = $#labels;    # -1 entfernt
    }
    else
    {
        $s = 0;
        $f = $#labels;
    }

    # now draw them
    if ( $side eq 'right' )
    {                     # put 'em on the right side of the chart
                          # get the base x-y values, and the delta value
        $x1 =
          $self->{'curr_x_max'} - $self->{'tick_len'} - ( 3 * $self->{'text_space'} ) - ( $w * $self->{'y_tick_label_length'} );
        $y1     = $self->{'curr_y_max'};
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $self->{'y_ticks'} = 2 if $self->{'y_ticks'} < 2;
        $delta = $height / ( $self->{'y_ticks'} - 1 );

        # update the curr_x_max value
        $self->{'curr_x_max'} = $x1;

        # now draw the ticks
        $x2 = $x1 + $self->{'tick_len'};
        for ( $s .. $f )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'y2_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y2'}->[$_] = $y2;
            }
        }

        # update the current x-min value
        $x1 += $self->{'tick_len'} + ( 2 * $self->{'text_space'} );
        $y1 -= $h / 2;

        # now draw the labels
        for ( 0 .. $#labels )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->string( $font, $x1, $y2, $self->{'y_tick_labels'}[$_], $textcolor );
        }
    }
    elsif ( $side eq 'both' )
    {    # put the ticks on the both sides
        ## left side first

        # get the base x-y values
        $x1 = $self->{'curr_x_min'} + $self->{'text_space'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        # now draw the labels
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta = $height / ( $self->{'y_ticks'} - 1 );
        for ( 0 .. $#labels )
        {
            $label = $self->{'y_tick_labels'}[$_];
            $y2    = $y1 - ( $delta * $_ );
            $x2    = $x1 + ( $w * $self->{'y_tick_label_length'} ) - ( $w * length($label) );
            $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
        }

        # and update the current x-min value
        $self->{'curr_x_min'} += ( 3 * $self->{'text_space'} ) + ( $w * $self->{'y_tick_label_length'} );

        # now draw the ticks (skipping the one at zero);
        $x1 = $self->{'curr_x_min'};
        $x2 = $self->{'curr_x_min'} + $self->{'tick_len'};
        $y1 += $h / 2;
        for ( $s .. $f )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{grid_lines} )
                or $self->true( $self->{'y_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }

        # update the current x-min value
        $self->{'curr_x_min'} += $self->{'tick_len'};

        ## now the right side
        # get the base x-y values, and the delta value
        $x1 =
          $self->{'curr_x_max'} - $self->{'tick_len'} - ( 3 * $self->{'text_space'} ) - ( $w * $self->{'y_tick_label_length'} );
        $y1     = $self->{'curr_y_max'};
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta  = $height / ( $self->{'y_ticks'} - 1 );

        # update the curr_x_max value
        $self->{'curr_x_max'} = $x1;

        # now draw the ticks (skipping the one at zero);
        $x2 = $x1 + $self->{'tick_len'};

        for ( $s .. $f )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );    # draw tick_line
            if (   $self->true( $self->{grid_lines} )
                or $self->true( $self->{'y2_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y2'}->[$_] = $y2;
            }
        }

        # update the current x-min value
        $x1 += $self->{'tick_len'} + ( 2 * $self->{'text_space'} );
        $y1 -= $h / 2;

        # now draw the labels
        for ( 0 .. $#labels )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->string( $font, $x1, $y2, $self->{'y_tick_labels'}[$_], $textcolor );
        }
    }
    else
    {    # just the left side
            # get the base x-y values
        $x1 = $self->{'curr_x_min'} + $self->{'text_space'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        # now draw the labels
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $self->{'y_ticks'} = 2 if $self->{'y_ticks'} < 2;
        $delta = $height / ( $self->{'y_ticks'} - 1 );
        for ( 0 .. $#labels )
        {
            $label = $self->{'y_tick_labels'}[$_];
            $y2    = $y1 - ( $delta * $_ );
            $x2    = $x1 + ( $w * $self->{'y_tick_label_length'} ) - ( $w * length($label) );
            $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
        }

        # and update the current x-min value
        $self->{'curr_x_min'} += ( 3 * $self->{'text_space'} ) + ( $w * $self->{'y_tick_label_length'} );

        # now draw the ticks
        $x1 = $self->{'curr_x_min'};
        $x2 = $self->{'curr_x_min'} + $self->{'tick_len'};
        $y1 += $h / 2;
        for ( $s .. $f )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'y_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }

        # update the current x-min value
        $self->{'curr_x_min'} += $self->{'tick_len'};
    }

    # and return
    return 1;
}

## @fn private int _grey_background()
#  put a grey background on the plot of the data itself
# @return status
sub _grey_background
{
    my $self = shift;

    # draw it
    $self->{'gd_obj'}
      ->filledRectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'},
        $self->_color_role_to_index('grey_background') );

    # now return
    return 1;
}

## @fn private int _draw_grid_lines()
# draw grid_lines
# @return status
sub _draw_grid_lines
{
    my $self = shift;
    $self->_draw_x_grid_lines();
    $self->_draw_y_grid_lines();
    $self->_draw_y2_grid_lines();
    return 1;
}

## @fn private int _draw_x_grid_lines()
# draw grid_lines for x
# @return status
sub _draw_x_grid_lines
{
    my $self      = shift;
    my $grid_role = shift || 'x_grid_lines';
    my $gridcolor = $self->_color_role_to_index($grid_role);
    my ( $x, $y, $i );

    foreach $x ( @{ $self->{grid_data}->{'x'} } )
    {
        if ( defined $x )
        {
            $self->{gd_obj}->line( ( $x, $self->{'curr_y_min'} + 1 ), $x, ( $self->{'curr_y_max'} - 1 ), $gridcolor );
        }
    }
    return 1;
}

## @fn private int _draw_y_grid_lines()
# draw grid_lines for y
# @return status
sub _draw_y_grid_lines
{
    my $self      = shift;
    my $grid_role = shift || 'y_grid_lines';
    my $gridcolor = $self->_color_role_to_index($grid_role);
    my ( $x, $y, $i );

    #Look if I'm an HorizontalBars object
    if ( $self->isa('Chart::HorizontalBars') )
    {
        for ( $i = 0 ; $i < ( $#{ $self->{grid_data}->{'y'} } ) + 1 ; $i++ )
        {
            $y = $self->{grid_data}->{'y'}->[$i];
            $self->{gd_obj}->line( ( $self->{'curr_x_min'} + 1 ), $y, ( $self->{'curr_x_max'} - 1 ), $y, $gridcolor );
        }
    }
    else
    {

        # loop for y values is a little different. This is to discard the first
        # and last values we were given - the top/bottom of the chart area.
        for ( $i = 1 ; $i < ( $#{ $self->{grid_data}->{'y'} } ) + 1 ; $i++ )
        {    ###
            $y = $self->{grid_data}->{'y'}->[$i];
            $self->{gd_obj}->line( ( $self->{'curr_x_min'} + 1 ), $y, ( $self->{'curr_x_max'} - 1 ), $y, $gridcolor );
        }
    }
    return 1;
}

## @fn private int _draw_y2_grid_lines()
# draw grid_lines for y
# @return status
sub _draw_y2_grid_lines
{
    my $self      = shift;
    my $grid_role = shift || 'y2_grid_lines';
    my $gridcolor = $self->_color_role_to_index($grid_role);
    my ( $x, $y, $i );

    #Look if I'm an HorizontalBars object
    if ( $self->isa('Chart::HorizontalBars') )
    {
        for ( $i = 0 ; $i < ( $#{ $self->{grid_data}->{'y'} } ) + 1 ; $i++ )
        {
            $y = $self->{grid_data}->{'y'}->[$i];
            $self->{gd_obj}->line( ( $self->{'curr_x_min'} + 1 ), $y, ( $self->{'curr_x_max'} - 1 ), $y, $gridcolor );
        }
    }
    else
    {

        # loop for y2 values is a little different. This is to discard the first
        # and last values we were given - the top/bottom of the chart area.
        for ( $i = 1 ; $i < $#{ $self->{grid_data}->{'y2'} } ; $i++ )
        {
            $y = $self->{grid_data}->{'y2'}->[$i];
            $self->{gd_obj}->line( ( $self->{'curr_x_min'} + 1 ), $y, ( $self->{'curr_x_max'} - 1 ), $y, $gridcolor );
        }
    }
    return 1;
}

## @fn private int _prepare_brush($color,$type,$role)
# prepare brush
#
# @details
#  set the gdBrush object to tick GD into drawing fat lines & points
#  of interesting shapes
#  Needed by "Lines", "Points" and "LinesPoints"
#  All hacked up by Richard Dice <rdice@pobox.com> Sunday 16 May 1999
#
# @param color
# @param type    'line','point'
# @param role
#
# @return status
sub _prepare_brush
{
    my $self  = shift;
    my $color = shift;
    my $type  = shift;
    my $role  = shift || 'default';

    my $brushStyle = $self->{'brushStyle'};
    if ( defined $role )
    {
        my (@brushStyles) = $self->_brushStyles_of_roles($role);
        $brushStyle = $brushStyles[0];
    }

    #print STDERR "role=$role\n";

    # decide what $type should be in the event that a param isn't
    # passed -- this is necessary to preserve backward compatibility
    # with apps that use this module prior to putting _prepare_brush
    # in with Base.pm
    if ( !defined($type) ) { $type = 'point'; }

    if (   ( !length($type) )
        || ( !grep { $type eq $_ } ( 'line', 'point' ) ) )
    {
        $brushStyle = $self->{'brushStyle'};
        $type       = 'line' if ref $self eq 'Chart::Lines';
        $type       = 'point' if ref $self eq 'Chart::Points';
    }

    my ( $radius, @rgb, $brush, $white, $newcolor );

    # get the rgb values for the desired color
    @rgb = $self->{'gd_obj'}->rgb($color);

    # get the appropriate brush size
    if ( $type eq 'line' )
    {
        $radius = $self->{'brush_size'} / 2;
    }
    elsif ( $type eq 'point' )
    {
        $radius = $self->{'pt_size'} / 2;
    }

    # create the new image
    $brush = GD::Image->new( $radius * 2, $radius * 2 );

    # get the colors, make the background transparent
    $white = $brush->colorAllocate( 255, 255, 255 );
    $newcolor = $brush->colorAllocate(@rgb);
    $brush->transparent($white);

    # draw the circle
    if ( $type eq 'line' )
    {
        $brush->arc( $radius - 1, $radius - 1, $radius, $radius, 0, 360, $newcolor );
        $brush->fill( $radius - 1, $radius - 1, $newcolor );

        # RLD
        #
        # Does $brush->fill really have to be here?  Dunno... this
        # seems to be a relic from earlier code
        #
        # Note that 'line's don't benefit from a $brushStyle... yet.
        # It shouldn't be too tough to hack this in by taking advantage
        # of GD's gdStyled facility

    }

    if ( $type eq 'point' )
    {
        $brushStyle = $self->{'brushStyle'}
          unless grep { $brushStyle eq $_ } (
            'FilledCircle',  'circle',             'donut',  'OpenCircle',
            'triangle',      'upsidedownTriangle', 'square', 'hollowSquare',
            'OpenRectangle', 'fatPlus',            'Star',   'OpenStar',
            'FilledDiamond', 'OpenDiamond'
          );

        my ( $xc, $yc ) = ( $radius, $radius );

        if ( grep { $brushStyle eq $_ } ( 'default', 'circle', 'donut', 'OpenCircle', 'FilledCircle' ) )
        {
            $brush->arc( $xc, $yc, $radius, $radius, 0, 360, $newcolor );
            $brush->fill( $xc, $yc, $newcolor );

            # draw a white (and therefore transparent) circle in the middle
            # of the existing circle to make the "donut", if appropriate

            if ( $brushStyle eq 'donut' || $brushStyle eq 'OpenCircle' )
            {
                $brush->arc( $xc, $yc, int( $radius / 2 ), int( $radius / 2 ), 0, 360, $white );
                $brush->fill( $xc, $yc, $white );
            }
        }

        if ( grep { $brushStyle eq $_ } ( 'triangle', 'upsidedownTriangle' ) )
        {
            my $poly = new GD::Polygon;
            my $sign = ( $brushStyle eq 'triangle' ) ? 1 : (-1);
            my $z    = int( 0.8 * $radius );                       # scaling factor

            # co-ords are chosen to make an equilateral triangle

            $poly->addPt( $xc, $yc - ( $z * $sign ) );
            $poly->addPt( $xc + int( ( sqrt(3) * $z ) / 2 ), $yc + ( int( $z / 2 ) * $sign ) );
            $poly->addPt( $xc - int( ( sqrt(3) * $z ) / 2 ), $yc + ( int( $z / 2 ) * $sign ) );

            $brush->filledPolygon( $poly, $newcolor );
        }

        if ( $brushStyle eq 'fatPlus' )
        {
            my $poly = new GD::Polygon;

            my $z = int( 0.3 * $radius );

            $poly->addPt( $xc + $z,     $yc + $z );
            $poly->addPt( $xc + 2 * $z, $yc + $z );
            $poly->addPt( $xc + 2 * $z, $yc - $z );

            $poly->addPt( $xc + $z, $yc - $z );
            $poly->addPt( $xc + $z, $yc - 2 * $z );
            $poly->addPt( $xc - $z, $yc - 2 * $z );

            $poly->addPt( $xc - $z,     $yc - $z );
            $poly->addPt( $xc - 2 * $z, $yc - $z );
            $poly->addPt( $xc - 2 * $z, $yc + $z );

            $poly->addPt( $xc - $z, $yc + $z );
            $poly->addPt( $xc - $z, $yc + 2 * $z );
            $poly->addPt( $xc + $z, $yc + 2 * $z );
            $brush->filledPolygon( $poly, $newcolor );
        }

        if ( $brushStyle eq 'Star' || $brushStyle eq 'OpenStar' )
        {
            my $poly = new GD::Polygon;

            my $z  = int($radius);
            my $sz = int( $z / 3 * 1.75 );    # small z

            my $x1 = int( $xc + $z );
            my $y1 = int($yc);
            my ( $x2, $y2 );

            my $xyRatio = $self->_xyRatio();

            $poly->addPt( $x1, $y1 );

            $x2 = $xc + int( $sz * 0.5 );
            $y2 = $yc - int( $sz * 0.5 );
            $poly->addPt( $x2, $y2 );

            $x2 = $xc;
            $y2 = $yc - $z;
            $poly->addPt( $x2, $y2 );

            $x2 = $xc - int( $sz * 0.5 );
            $y2 = $yc - int( $sz * 0.5 );
            $poly->addPt( $x2, $y2 );

            $x2 = $xc - $z;
            $y2 = $yc;
            $poly->addPt( $x2, $y2 );

            $x2 = $xc - int( $sz * 0.5 );
            $y2 = $yc + int( $sz * 0.5 );
            $poly->addPt( $x2, $y2 );

            $x2 = $xc;
            $y2 = $yc + $z;
            $poly->addPt( $x2, $y2 );

            $x2 = $xc + int( $sz * 0.5 );
            $y2 = $yc + int( $sz * 0.5 );
            $poly->addPt( $x2, $y2 );
            if ( $brushStyle eq 'OpenStar' )
            {
                $brush->polygon( $poly, $newcolor );
            }
            else
            {
                $brush->filledPolygon( $poly, $newcolor );
            }
        }

        if ( grep { $brushStyle eq $_ } ( 'square', 'hollowSquare', 'OpenRectangle' ) )
        {
            my $z = int( 0.5 * $radius );

            $brush->filledRectangle( $xc - $z, $yc - $z, $xc + $z, $yc + $z, $newcolor );

            if ( $brushStyle eq 'hollowSquare' || $brushStyle eq 'OpenRectangle' )
            {
                $z = int( $z / 2 );

                $brush->filledRectangle( $xc - $z, $yc - $z, $xc + $z, $yc + $z, $white );
            }
        }

        if ( grep { $brushStyle eq $_ } ( 'FilledDiamond', 'OpenDiamond' ) )
        {
            my $z = int( 0.75 * $radius );

            $brush->line( $xc + $z, $yc,      $xc,      $yc + $z, $newcolor );
            $brush->line( $xc,      $yc + $z, $xc - $z, $yc,      $newcolor );
            $brush->line( $xc - $z, $yc,      $xc,      $yc - $z, $newcolor );
            $brush->line( $xc,      $yc - $z, $xc + $z, $yc,      $newcolor );

            if ( $brushStyle eq 'FilledDiamond' )
            {

                # and fill it
                $brush->fill( $radius - 1, $radius - 1, $newcolor );
            }
        }

    }

    # set the new image as the main object's brush
    return $brush;
}

## @fn private int _default_f_tick
# default tick conversion function
# This function is pointed to be $self->{f_x_tick} resp. $self->{f_y_tick}
# if the user does not provide another function
#
# @return status
sub _default_f_tick
{
    my $label = shift;

    return $label;
}

## @fn private float _xyRatio
# Get ratio width_x/width_y
#
# @return ratio width_x and width_y
sub _xyRatio
{
    my $self = shift;

    my $width_x = $self->{'curr_x_max'} - $self->{'curr_x_min'} + 1;
    my $width_y = $self->{'curr_y_max'} - $self->{'curr_y_min'} + 1;

    my $ratio = $width_x / $width_y;

    return $ratio;
}

## @fn private float _xPixelInReal
# Get width of one Pixel in real coordinates in x-direction
#
# @return width(interval) of reality in x direction
#
sub _xPixelInReal
{
    my $self = shift;

    my $width_x = $self->{'curr_x_max'} - $self->{'curr_x_min'} + 1;
    my ( $min, $max ) = $self->_find_x_range();
    my $xRealWidth = $max - $min;
    my $ratio      = $xRealWidth / $width_x;

    return $ratio;
}

## @fn private float _yPixelInReal
# Get width of one Pixel in real coordinates in y-direction
#
# @return width(interval) of reality in y direction
#
sub _yPixelInReal
{
    my $self = shift;

    my $width_y = $self->{'curr_y_max'} - $self->{'curr_y_min'} + 1;
    my ( $min, $max, $flag_all_integers ) = $self->_find_y_range();
    my $yRealWidth = $max - $min;
    my $ratio      = $yRealWidth / $width_y;

    return $ratio;
}

## be a good module and return positive
1;

