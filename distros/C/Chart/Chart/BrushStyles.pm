## @file
# Chart::BrushStyles
#
# written and maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::BrushStyles
# Define styles for Points and LinesPoints classes
#
# This class provides functions which define different
# brush styles to extend the previous point as the only design
# for Points.pm or LinesPoints.pm\n\n
# The different brush styles are:\n
# \see OpenCircle\n
# \see FilledCircle\n
# \see Star\n
# \see OpenDiamond\n
# \see FilledDiamond\n
# \see OpenRectangle\n
# \see FilledRectangle\n
package Chart::BrushStyles;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;
use Chart::Constants;

@Chart::BrushStyles::ISA     = qw(Chart::Base);
$Chart::BrushStyles::VERSION = '2.4.10';

## @fn OpenCircle
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the point in pixels
# @param[in] int        $color  Color of the not filled point
#
# @brief Set the gdBrush object to have nice brushed object
# representing a circle of the size \$radius.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->OpenCircle(\\\$rbrush,\$radius, \$newcolor);\n
# to plot the GD::Image representing an open circle as the point
#
sub OpenCircle
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    # draw a filled circle
    if ( $radius < 2 ) { $radius = 2; }

    $$rbrush->arc( $radius, $radius, $radius, $radius, 0, 360, $color );
}

## @fn FilledCircle
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the point in pixels
# @param[in] int        $color  Color of the filled point
# @return nothing
#
# @brief Set the gdBrush object to have nice brushed object
# representing a point of the size \$radius.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->FilledCircle(\\\$rbrush,\$radius, \$color);\n
# to plot the GD::Image representing a filled circle as the point
#
sub FilledCircle
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    # draw a filled circle
    if ( $radius < 2 ) { $radius = 2; }

    $$rbrush->arc( $radius, $radius, $radius, $radius, 0, 360, $color );

    # and fill it
    $$rbrush->fill( $radius, $radius, $color );
}

## @fn Star
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the star in pixels
# @param[in] int        $color  Color of the star
# @return nothing
#
# @brief Set the gdBrush object to have nice brushed object
# representing a star of the size \$radius.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->Star(\\\$rbrush,\$radius, \$color);\n
# to get back an GD::Image representing a star as the point
#
sub Star
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    my $R = $self->maximum( 2, int( $radius + 0.5 ) );
    my $r = $self->maximum( 1, int( $R / 3 + 0.5 ) );
    my $lRadius = $R;
    my $x1      = $lRadius + $R;    # =$R*cos(0) + $R;
    my $y1      = $R;               # =$R*sin(0) + $R
    my ( $x2, $y2 );

    for ( my $iAngleCounter = 1 ; $iAngleCounter < 16 ; $iAngleCounter++ )
    {
        my $phi = $iAngleCounter * Chart::Constants::PI / 8;
        $lRadius = ( ( $iAngleCounter & 1 ) == 0 ) ? $R : $r;
        $x2      = $lRadius * cos($phi);
        $y2      = $lRadius * sin($phi);
        $x2 += $R;
        $y2 += $R;

        #printf("$iAngleCounter: %4f, %4f    %4f,%4f\n", $x1,$y1,$x2,$y2);
        $$rbrush->line( $x1, $y1, $x2, $y2, $color );

        $x1 = $x2;
        $y1 = $y2;
    }

    # draw to the first point
    $x2 = $R + $R;
    $y2 = $R;
    $$rbrush->line( $x1, $y1, $x2, $y2, $color );
}

## @fn FilledDiamond
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the diamond in pixels
# @param[in] int        $color  Color of the filled diamond
# @return nothing
#
# @brief Set the gdBrush object to have nice brushed object
# representing a filled diamond of the size \$radius.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->FilledDiamond(\\\$rbrush,\$radius, \$color);\n
# to get back an GD::Image representing a filled diamond as the point
#
sub FilledDiamond
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    my $R = $self->maximum( 2, int( $radius + 0.5 ) );
    my $R2 = $R * 2;
    $$rbrush->line( $R,  1,       $R2 - 1, $R,      $color );
    $$rbrush->line( $R2, $R,      $R,      $R2 - 1, $color );
    $$rbrush->line( $R,  $R2 - 1, 1,       $R,      $color );
    $$rbrush->line( 1,   $R,      $R,      1,       $color );

    # and fill it
    $$rbrush->fill( $radius - 1, $radius - 1, $color );
}

## @fn OpenDiamond
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the diamond in pixels
# @param[in] int        $color  Color of the diamond
# @return nothing
#
# @brief Set the gdBrush object to have nice brushed object
# representing a diamond of the size \$radius-1.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->OpenDiamond(\\\$rbrush,\$radius, \$color);\n
# to get back an GD::Image representing a diamond as the point
#
sub OpenDiamond
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    my $R = $self->maximum( 2, int( $radius + 0.5 ) );
    my $R2 = $R * 2;
    $$rbrush->line( $R,  1,       $R2 - 1, $R,      $color );
    $$rbrush->line( $R2, $R,      $R,      $R2 - 1, $color );
    $$rbrush->line( $R,  $R2 - 1, 1,       $R,      $color );
    $$rbrush->line( 1,   $R,      $R,      1,       $color );
}

## @fn OpenRectangle
# @param[in] *GD::Image $rbrush Reference to GD::Image
# @param[in] int        $radius Radius of the rectangle in pixels
# @param[in] int        $color  Color of the rectangle
# @return nothing
#
# @brief Set the gdBrush object to have nice brushed object
# representing a rectangle of the height \$radius-1 and width of $radius/2.
#
# @details
# Called by\n
# use Chart::BrushStyles;\n
# \@Chart::Points::ISA     = qw(Chart::BrushStyles);\n
# \$self->OpenDiamond(\\\$rbrush,\$radius, \$color);\n
# to get back an GD::Image representing a rectangle as the point
#
sub OpenRectangle
{
    my $self   = shift;
    my $rbrush = shift;    # reference to GD::Image
    my $radius = shift;
    my $color  = shift;

    # draw a filled circle
    if ( $radius < 2 ) { $radius = 2; }

    my $height = $radius;
    my $width  = $radius / 2;
    if ( $width < 1 ) { $width = 1; }

    $$rbrush->line( -$width, -$height, $width, -$height, $color );

    #$$rbrush->line( $width,    -$height, $width, $height, $color );
    #$$rbrush->line( $width, $height, -$width, $height, $color );
    #$$rbrush->line( -$width,   $height, -$width ,-$height,$color );
}

#################################################################
1;
