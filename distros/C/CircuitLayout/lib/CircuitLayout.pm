require 5.006;
our $VERSION = '0.07'; 
## Note: '@ ( # )' used by the what command  E.g. what CircuitLayout.pm
our $revision = '@(#) $RCSfile: CircuitLayout.pm,v $ $Revision: 1.30 $ $Date: 2003-08-01 00:19:14-05 $';
#use Math::Trig;
#use Tk;
use Tk::WorldCanvas;
use strict;

our $G_epsilon = 0.00000001;
my $pp = 4;

# POD documentation is sprinkled throughout the file in an 
# attempt at Literate Programming style (which Perl partly supports ...
# see http://www.literateprogramming.com/ )
# Search for the strings '=head' or run perldoc on this file.

# You can run this file through either pod2man or pod2html to produce 
# documentation in manual or html file format 

=pod
=head1 COPYRIGHT

Author: Ken Schumack (c) 2001-2004. All rights reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License.
 (see http://www.perl.com/pub/a/language/misc/Artistic.html)
I do ask that you please let me know if you find bugs or have
idea for improvements. You can reach me at Schumack@cpan.org
 Have fun, Ken


=head1 NAME 

CircuitLayout - circuit layout module

=head1 DESCRIPTION

This is CircuitLayout, a module for working with circuit layout items 
like boundaries, texts, rectangles, and srefs.

Send feedback/suggestions to Schumack@cpan.org

=cut

package CircuitLayout;
{

=head1 CircuitLayout::pitches

returns string of pitches given a ref to an array of CircuitLayout::Boundary items

=cut

####### CircuitLayout::Text
sub pitches
{
    my(%arg) = @_;
    my $direction = $arg{'-direction'};
    if (! defined $direction)
    {
        print "WARNING: missing -direction arg to pitches, using 'y'\n";
        $direction = 'y';
    }
    $direction = lc $direction;
    my $boundaryRefs = $arg{'-boundaries'};
    if (defined($boundaryRefs))
    {
        my $firstItem = $$boundaryRefs[0];
        if (ref($firstItem) ne 'CircuitLayout::Boundary')
        {
            die "-boundaries expects ref to CircuitLayout::Boundary items array. $!";
        }
    }
    my $giveTransitionPoints = $arg{'-giveTransitionPoints'};
    $giveTransitionPoints = 0 if (! defined $giveTransitionPoints);

    my %locations=();
    foreach my $polygon (@$boundaryRefs)
    {
        my $x = $polygon -> extent -> center -> x;
        my $y = $polygon -> extent -> center -> y;
        if ($direction eq 'x')
        {
            $locations{$y} .= "$x " if ((! defined $locations{$y}) || ($locations{$y} !~ m/\b$x /));
        }
        else
        {
            $locations{$x} .= "$y " if ((! defined $locations{$x}) || ($locations{$x} !~ m/\b$y /));
        }
    }
    my $pitches = '';
    my @transitionPointsArray = ();
    foreach my $location (sort {$a <=> $b} keys %locations)
    {
        my @centers = split(' ',$locations{$location});
        my $lastCenter = '';
        foreach my $center (sort {$a <=> $b} @centers)
        {
            if ($lastCenter ne '')
            {
                my $pitch = sprintf("%0.${pp}f",$center - $lastCenter);
                if ($pitches !~ m/\b$pitch /)
                {
                    $pitches .= "$pitch ";
                    push @transitionPointsArray, $lastCenter;
                }
            }
            $lastCenter = $center;
        }
    }
    $pitches =~ s/ $//;
    if (($pitches =~ m/ /) && $giveTransitionPoints)
    {
        shift @transitionPointsArray; ## 1st one is not wanted
        my $transitionPoints = join(' ;',@transitionPointsArray);
        $pitches .= ";$transitionPoints";
    }
    $pitches =~ s/ $//;
    $pitches;
}
1;
}

package CircuitLayout::Text;
{
# This is the default class for the CircuitLayout::Text object to use when all else fails.
$CircuitLayout::Text::DefaultClass = 'CircuitLayout::Text' unless defined $CircuitLayout::Text::DefaultClass;

=head1 CircuitLayout::Text::new

=head2 Usage:

## Coord object for CircuitLayout::Text origin coordinate...
my $text = new CircuitLayout::Text(-origin=>$coord,
                    -string=>$string);
 -or-

my @point = (0,0);
## anonymous array or array ref
my $edge = new CircuitLayout::Edge(-origin=>\@point,
                    -string=>"VDD");

=cut

#### Method: new CircuitLayout::Text
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::Text::DefaultClass;
    my $origin = $arg{'-origin'};
    if (! defined($origin))
    {
        die "new CircuitLayout::Text expects origin Coord. Missing -origin => Coord $!";
    }
    else
    {
        if (ref($origin) ne 'CircuitLayout::Coord')
        {
            if (ref($origin) eq 'ARRAY') ## anonymous array...
            {
                $origin = new CircuitLayout::Coord(-x=>@$origin[0],-y=>@$origin[1]);
            }
            die "CircuitLayout::Text::new did not receive or could not create a coord. $!" if (ref($origin) ne 'CircuitLayout::Coord');
        }
    }
    my $string = $arg{'-string'};
    if (! defined $string)
    {
        $string = '';
    }

    my $layer = $arg{'-layer'};
    if (! defined $layer)
    {
        $layer = 0;
    }

    $self -> {'PrintPrecision'} = 4; #init
    $self -> {'Origin'}         = $origin;
    $self -> {'Layer'}          = $layer;
    $self -> {'String'}         = $string;
    $self;  
}
################################################################

=head1 CircuitLayout::Text::display

draws on a worldCanvas

=cut

####### CircuitLayout::Text
sub display
{
    my($self,%arg) = @_;
    my $canvas = $arg{'-worldCanvas'};
    if (! defined $canvas)
    {
        print "ERROR: missing -canvas arg to CircuitLayout::Boundary::display\n";
        exit 2;
    }
    
    my $fill = $arg{'-fill'}; ## fill color
    my $fillColor = '';
    if (! defined $fill)
    {
        $fill = undef;
    }
    else
    {
        $fillColor = $fill;
    }

    my $showOrigin = $arg{'-showOrigin'}; ## 
    if (! defined $showOrigin)
    {
        $showOrigin = 0;
    }

    my $layer = $self -> {'Layer'};
    my $name = $arg{'-name'};
    if (! defined $name)
    {
        $name = "layer $layer";
    }

    my $visible = $arg{'-visible'};
    if (! defined $visible)
    {
        $visible = 'true';
    }

    my $type = 'text';
    my $string = $self -> {'String'};

    my @points = ();
    push @points,$self -> origin -> x;
    push @points,$self -> origin -> y;
    $canvas -> createText(
        @points,
        -fill     => $fill,
        -tags     => [
                      "fill=$fillColor",
                      "layer=$layer",
                      'layout=true',
                      "name=$name",
                      'selected=false',
                      "type=$type",
                      "visible=$visible",
                     ],
        -text     => "$string",
    );

    if ($showOrigin)
    {
        my @textOriginPoints = (); ## make a diamond
        my ($x,$y) = @points;
        my $halfSize = 0.01;
        push @textOriginPoints,$x - $halfSize; push @textOriginPoints,$y;
        push @textOriginPoints,$x            ; push @textOriginPoints,$y + $halfSize;
        push @textOriginPoints,$x + $halfSize; push @textOriginPoints,$y;
        push @textOriginPoints,$x            ; push @textOriginPoints,$y - $halfSize;
        push @textOriginPoints,$x - $halfSize; push @textOriginPoints,$y;
        my $fillTagColor = '';
        $fillTagColor = $fill if (defined $fill);
        $canvas -> createLine(
            @textOriginPoints,
            -fill     => $fill,
            -width    => 0,
            -capstyle => 'butt',
            -stipple  => '',
            -tags     => [
                          "fill=$fillTagColor",
                          'layout=false',
                          'type=textorigin',
                          'selected=false',
                          "visible=$visible",
                         ],
        );
    }
}
################################################################

=head1 CircuitLayout::Text::directionExtent

=cut

####### CircuitLayout::Text
sub directionExtent
{
    my ($self,%arg) = @_;
    my $side = $arg{'-direction'};  # 'N' 'S' 'E' or 'W' ...
    $side =~ s|^(.).*|\U$1|;
    my ($x1,$x2,$y1,$y2);
    my $num;

    if (($side eq 'N') || ($side eq 'S'))
    {
        $num = $self -> origin -> y;
    }
    else
    {
        $num = $self -> origin -> x;
    }
}
################################################################

=head1 CircuitLayout::Text::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Text
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################

=head1 CircuitLayout::Text::string

=cut

####### CircuitLayout::Text
sub string
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'String'} = $value;
    }
    $self -> {'String'};
}
################################################################

=head1 CircuitLayout::Text::layer

=cut

####### CircuitLayout::Text
sub layer
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Layer'} = $value;
    }
    $self -> {'Layer'};
}
################################################################

=head1 CircuitLayout::Text::origin

returns origin as Coord object
use -value to change and pass in Coord or x,y array

=cut

####### CircuitLayout::Text
sub origin
{
    my($self,%arg) = @_;
    my $origin = $arg{'-value'};
    if (defined($origin))
    {
        if (ref($origin) ne 'CircuitLayout::Coord')
        {
            if (ref($origin) eq 'ARRAY') ## anonymous array...
            {
                $origin = new CircuitLayout::Coord(-x=>@$origin[0],-y=>@$origin[1]);
            }
            die "CircuitLayout::Text::origin did not receive or could not create a coord. $!" if (ref($origin) ne 'CircuitLayout::Coord');
        }
        $self -> {'Origin'} = $origin;
    }
    $self -> {'Origin'};
}
################################################################

## end package CircuitLayout::Text
1;
}

package CircuitLayout::Coord;
{
# This is the default class for the CircuitLayout::Coord object to use when all else fails.
$CircuitLayout::Coord::DefaultClass = 'CircuitLayout::Coord' unless defined $CircuitLayout::Coord::DefaultClass;

use overload '=='       => \&equals,
             'bool'     => sub {defined $_[0] ? 1 : 0},
             'fallback' => 1,
             'nomethod' => sub {die "Operator $_[3] makes no sense for CircuitLayout::Coord" };

=head1 CircuitLayout::Coord::new

=cut

#### Method: new CircuitLayout::Coord
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::Coord::DefaultClass;
    my $resolution = $arg{'-resolution'};
    if (! defined $resolution)
    {
        $resolution = 0.001;
    }
    die "new CircuitLayout::Coord expects a positive real resolution. Missing -resolution => #.# $!" if (("$resolution" !~ m|^\d*\.?\d+|)||($resolution<=0));
    my $x = $arg{'-x'};
    my $y = $arg{'-y'};
    if (! ((defined $x)&&(defined $y)))
    {
        die "new CircuitLayout::Coord expects x and y value. Missing -x => #.# and or -y => #.# $!";
    }
    $self -> {'Resolution'}     = $resolution;
    $self -> {'PrintPrecision'} = 4; #init
    my $pp1 = $self -> printPrecision + 1;
    $x = sprintf("%0.${pp1}f",$x);
    $y = sprintf("%0.${pp1}f",$y);
    $self -> {'X'}              = $x;
    $self -> {'Y'}              = $y;
    $self;  
}
################################################################

sub directionExtent
{
    my ($self,%arg) = @_;
    CircuitLayout::Edge::directionExtent($self,%arg);
}

=head1 CircuitLayout::Coord::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Coord
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################

=head1 CircuitLayout::Coord::coordSubtract

=cut

####### CircuitLayout::Coord
sub coordSubtract($$$)
{
    my $self = shift;
    my $coordA = shift;
    my $coordB = shift;
    my $x = $coordA -> x;
    my $y = $coordA -> y;
    $x -= $coordB -> x;
    $y -= $coordB -> y;
    my $result = new CircuitLayout::Coord(-x=>$x,-y=>$y);
    $result;
}
################################################################

=head1 CircuitLayout::Coord::onGrid

=cut

####### CircuitLayout::Coord
sub isOnGrid
{
    my ($self,%arg) = @_;
    my $xOffset = $arg{'-xOffset'};
    my $yOffset = $arg{'-yOffset'};
    my $xGrid = $arg{'-xGrid'};
    my $yGrid = $arg{'-yGrid'};
    if (! ((defined $xOffset) && 
           (defined $yOffset) &&
           (defined $xGrid) &&
           (defined $yGrid)  )
    )
    {
        die "CircuitLayout::Coord isOnGrid expects -xOffset -yOffset -xGrid and -yGrid args $!";
        return 0;
    }
    if ($xGrid == 0.0 || $yGrid == 0.0)
    {
        die "CircuitLayout::Coord isOnGrid was passed in 0.0 for an a or y grid $!";
        return 0;
    }
    my $pp1 = ($self -> printPrecision) + 1;
    my $offsetSelfX = sprintf("%0.${pp1}f",(abs($self -> x) - $xOffset));
    my $offsetSelfY = sprintf("%0.${pp1}f",(abs($self -> y) - $yOffset));
    if (
        (sprintf("%0.${pp1}f",($offsetSelfX / $xGrid)) != int(($offsetSelfX / $xGrid) + $G_epsilon)) ||
        (sprintf("%0.${pp1}f",($offsetSelfY / $yGrid)) != int(($offsetSelfY / $yGrid) + $G_epsilon)) 
    )
    {
        return 0;
    }
    1;
}
################################################################

=head1 CircuitLayout::Coord::resolution

=cut

####### CircuitLayout::Coord
sub resolution
{
    my $self = shift;
    $self -> {'Resolution'};
}
################################################################

=head1 CircuitLayout::Coord::x

=cut

####### CircuitLayout::Coord
sub x
{
    my $self = shift;
    $self -> {'X'};
}
################################################################

=head1 CircuitLayout::Coord::y

=cut

####### CircuitLayout::Coord
sub y
{
    my $self = shift;
    $self -> {'Y'};
}
################################################################

=head1 CircuitLayout::Coord::scale

=cut

####### CircuitLayout::Coord
sub scale
{
    my ($self,%arg) = @_;
    my $factor = $arg{'-factor'};
    if (! defined $factor)
    {
        $factor=1;
    }
    if ($factor <= 0)
    {
        die "CircuitLayout::Coord scale expects a positive factor -factor => #.# $!";
    }
    
    my $snap = $arg{'-snap'};
    if (! defined $snap)
    {
        $snap=0;
    }
    if ($snap < 0)
    {
        die "CircuitLayout::Coord scale expects a positive snap -snap => #.# $!";
    }
    
    my $resolution=$self -> resolution;
    ### written this way to make a separate x/y snap/factor easy to do....later :->
    my $x = $self -> x;
    my $y = $self -> y;
    $x *= $factor;
    $y *= $factor;
    
    if ($snap)
    {
        $x = snapNum($x,$snap,$resolution);
        $y = snapNum($y,$snap,$resolution);
    }
    $self -> {'X'} = $x;
    $self -> {'Y'} = $y;
    $self;
}
################################################################

=head1 CircuitLayout::Coord::snapNum

=cut

####### CircuitLayout::Coord
sub snapNum($$$)
{
    my $num=shift;
    my $snap=shift;
    my $resolution=shift;
    $snap =~ s|0+$||;
    my $snapLength = length("$snap");
    my $lean=1; ##init
    $lean = -1 if($num < 0);
    $num = int(($num*(1/$resolution))+0.5);
    ## snap to grid..   
    my $littlePart=substr($num,-$snapLength,$snapLength);
    if($num<0)
    {
        $littlePart = -$littlePart;
    }
    $littlePart = int(($littlePart/$snap)+(0.5*$lean))*$snap;
    my $bigPart=substr($num,0,-$snapLength);
    if ($bigPart =~ m|^[-]?$|)
    {
        $bigPart=0;
    }
    else
    {
        $bigPart *= 10**$snapLength;
    }
    $num = ($bigPart + $littlePart) * $resolution;
}
################################################################
        
=head1 CircuitLayout::Coord::printableCoords

returns string in "x1,y1"
where x and y print precision is controlled by objects printPrecision

Note: returns just one coordinate but method name
is plural none the less to be consistant with other methods.

=cut

####### Coord
sub printableCoords
{
    my $self = shift;
    my $pp = $self -> printPrecision;
    sprintf("%0.${pp}f",$self -> x).','.sprintf("%0.${pp}f",$self -> y);
}
################################################################

=head1 CircuitLayout::Coord::equals

=cut


####### CircuitLayout::Coord::equals
sub equals
{
    my($self,$ref) = @_;
    my ($x1,$x2,$y1,$y2);
    my $result = 0;
    if (ref $ref eq 'CircuitLayout::Coord')
    {
        $x2 = $ref -> x;
        $y2 = $ref -> y;
    }
    elsif (ref $ref eq 'ARRAY') ## anonymous array...
    {
        $x2 = @$ref[0];
        $y2 = @$ref[1];

    }
    else
    {
        die "Coord::equals did not receive a CircuitLayout::Coord or anonymous/reference array. $!";
    }
    $x1 = $self -> x;
    $y1 = $self -> y;

    ## use sprintf to handle binary representation errors
    my $pp1 = $self -> printPrecision + 1;
    
    my $x1String = sprintf("%0.${pp1}f",$x1);
    my $y1String = sprintf("%0.${pp1}f",$y1);
    my $x2String = sprintf("%0.${pp1}f",$x2);
    my $y2String = sprintf("%0.${pp1}f",$y2);

    $result = 1 if (($x1String eq $x2String) && ($y1String eq $y2String));
    $result;
}
################################################################

## end package CircuitLayout::Coord
1;
}

package CircuitLayout::Edge;
{
# This is the default class for the CircuitLayout::Edge object to use when all else fails.
$CircuitLayout::Edge::DefaultClass = 'CircuitLayout::Edge' unless defined $CircuitLayout::Edge::DefaultClass;

=head1 CircuitLayout::Edge::new

=head2 Usage:

## CircuitLayout::Coord object for Lower Left Coordinate...
my $edge = new CircuitLayout::Edge(-startCoord=>$coord1,
                    -endCoord=>$coord2);
 -or-

my @startPoint = (0,0);
## anonymous array or array ref
my $edge = new CircuitLayout::Edge(-startCoord=>\@startPoint,
                    -endCoord=>[2.3,4.5]);

=cut

#### Method: new CircuitLayout::Edge
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::Edge::DefaultClass;
    my $startCoord = $arg{'-startCoord'};
    my $endCoord   = $arg{'-endCoord'};
    my @coords;
    if (! ((defined $startCoord)&&(defined $endCoord)))
    {
        die "new CircuitLayout::Edge expects start and end Coords. Missing -startCoord => CircuitLayout::Coord and or -endCoord => CircuitLayout::Coord $!";
    }
    if (ref($startCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($startCoord) eq 'ARRAY') ## anonymous array...
        {
            $startCoord = new CircuitLayout::Coord(-x=>@$startCoord[0],-y=>@$startCoord[1]);
        }
        die "CircuitLayout::Edge::new did not receive or could not create a coord. $!" if (ref($startCoord) ne 'CircuitLayout::Coord');
    }
    if (ref($endCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($endCoord) eq 'ARRAY') ## anonymous array...
        {
            $endCoord = new CircuitLayout::Coord(-x=>@$endCoord[0],-y=>@$endCoord[1]);
        }
        die "CircuitLayout::Edge::new did not receive or could not create a coord. $!" if (ref($endCoord) ne 'CircuitLayout::Coord');
    }
    $self -> {'PrintPrecision'} = 4;
    $self -> {'StartCoord'}     = $startCoord;
    $self -> {'EndCoord'}       = $endCoord;
    push @coords,$startCoord;
    push @coords,$endCoord;
    $self -> {'Coords'}         = \@coords;
    $self;  
}
################################################################

=head1 CircuitLayout::Edge::coords

=cut

####### CircuitLayout::Edge
sub coords
{
    my $self = shift;
    my $coords=$self -> {'Coords'};
    my @coords=@$coords;
    @coords;
}
################################################################

=head1 CircuitLayout::Edge::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Edge
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################

=head1 CircuitLayout::Edge::isLeft

=head2 Usage:

my $isLeft = $edge -> isLeft(-coord=>$coord);

=head2 Synopsis:

=cut

####### CircuitLayout::Edge
sub isLeft
{
    my ($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    my ($x1,$x2,$y1,$y2,$x3,$y3);
    $x1 = $self -> startCoord -> x;
    $x2 = $self -> endCoord -> x;
    $y1 = $self -> startCoord -> y;
    $y2 = $self -> endCoord -> y;
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
    }
    $x3 = $coordRef -> x;
    $y3 = $coordRef -> y;
    my $result=( ($x2 - $x1) * ($y3 - $y1) - ($x3 - $x1) * ($y2 - $y1) );
    return 1  if ($result > $G_epsilon);
    return -1 if ($result < (0 - $G_epsilon));
    return 0;
}

################################################################


=head1 CircuitLayout::Edge::direction

=head2 Usage:

my $edgeDirection = $edge -> direction;

=head2 Synopsis:

Returns one of 8 compass directions: 'N','NE','E','SE','S','SW','W','NW'

S<my $edge = new CircuitLayout::Edge(-startCoord=E<gt>[0,0],-endCoord=E<gt>[5,5]);>

S<print $edge -E<gt> direction; >## prints 'NE';

=cut

####### CircuitLayout::Edge
sub direction
{
    my $self = shift;
    my ($x1,$x2,$y1,$y2);
    $x1 = $self -> startCoord -> x;
    $x2 = $self -> endCoord -> x;
    $y1 = $self -> startCoord -> y;
    $y2 = $self -> endCoord -> y;
    my $compass='';
    if ($y2 > $y1) #NW N NE
    {
        $compass = 'N'  if ($x2 == $x1);
        $compass = 'NW' if ($x2 < $x1);
        $compass = 'NE' if ($x2 > $x1);
    }
    elsif ($y2 < $y1) # SW S SE
    {
        $compass = 'S'  if ($x2 == $x1);
        $compass = 'SW' if ($x2 < $x1);
        $compass = 'SE' if ($x2 > $x1);
    }
    else # W E
    {
        $compass = 'W' if ($x2 < $x1);
        $compass = 'E' if ($x2 > $x1);
    }
    $compass;
}
################################################################

=head1 CircuitLayout::Edge::is45multiple

=head2 Usage:

my $test = $edge -> is45multiple;

=head2 Synopsis:

Returns true or false ( 1 or 0 ) depending on whether edge is a
45 degree multiple

S<my $edge = new CircuitLayout::Edge(-startCoord=E<gt>[0,0],-endCoord=E<gt>[5,5]);>

S<print $edge -E<gt> is45multiple; >## prints 1;

=cut

####### CircuitLayout::Edge
sub is45multiple
{
    my $self = shift;
    my ($x1,$x2,$y1,$y2);
    $x1 = $self -> startCoord -> x;
    $x2 = $self -> endCoord -> x;
    $y1 = $self -> startCoord -> y;
    $y2 = $self -> endCoord -> y;
    return 1 if ($x1 == $x2);
    return 1 if ($y1 == $y2);
    my $pp1 = $self -> printPrecision + 1;
    my $ax = sprintf("%0.${pp1}f",abs($x1 - $x2));
    my $ay = sprintf("%0.${pp1}f",abs($y1 - $y2));
    return 1 if ($ax == $ay);

    return 0;
}
################################################################

=head1 CircuitLayout::Edge::xIntersection

Returns x value where CircuitLayout::Edge actually crosses x axis
or would cross if it was extended.

=cut

####### CircuitLayout::Edge
sub xIntersection
{
    my $self = shift;
    my $x1 = $self -> startCoord -> x;
    my $x2 = $self -> endCoord -> x;
    my $y1 = $self -> startCoord -> y;
    my $y2 = $self -> endCoord -> y;
    return undef() if ($y2 == $y1);
    (($x1 * $y2) - ($x2 * $y1)) / ($y2 - $y1);
}
################################################################

=head1 CircuitLayout::Edge::straddleTouchXray

Returns 0 or 1 depending on whether CircuitLayout::Edge straddles or touches horizontal X ray.
Default X ray is X axis (y value==0)

$edge -> straddleTouchXray;
 -or-
$edge -> straddleTouchXray(-yValue=>4.3);


=cut

####### CircuitLayout::Edge
sub straddleTouchXray
{
    my ($self,%arg) = @_;
    my $yValue = $arg{'-yValue'};
    if (! defined $yValue)
    {
        $yValue = 0.0;
    }
    my $y1 = $self -> startCoord -> y;
    my $y2 = $self -> endCoord -> y;
    my $result=0;
    $result = 1 if ((($y1 > $yValue) && ($y2 <= $yValue)) ||
                    (($y2 > $yValue) && ($y1 <= $yValue)));
    $result;
}
################################################################

=head1 CircuitLayout::Edge::printableCoords

Returns CircuitLayout::Edge as 'x1,y1;x2,y2' string.

print $edge -> printableCoords;

=cut

####### CircuitLayout::Edge
sub printableCoords
{
    my $self = shift;
    $self -> {'StartCoord'} -> {'X'}.','.$self -> {'StartCoord'} -> {'Y'}.';'.$self -> {'EndCoord'} -> {'X'}.','.$self -> {'EndCoord'} -> {'Y'};
}
################################################################

=head1 CircuitLayout::Edge::startCoord

Returns 1st edge coordinate as a Coord.

=cut

####### CircuitLayout::Edge
sub startCoord
{
    my $self = shift;
    $self -> {'StartCoord'};
}
################################################################

=head1 CircuitLayout::Edge::endCoord

Returns last edge coordinate as a Coord.

=cut

####### CircuitLayout::Edge
sub endCoord
{
    my $self = shift;
    $self -> {'EndCoord'};
}
################################################################

=head1 CircuitLayout::Coord::directionExtent CircuitLayout::Edge::directionExtent CircuitLayout::Boundary::directionExtent

=head2 Usage:

my $edgeExtent = $edge -> directionExtent;

=head2 Synopsis:

Returns position (real number) of edge in one of 4 magor compass directions: 'N','E','S','W'

S<my $edge = new CircuitLayout::Edge(-startCoord=E<gt>[0,0],-endCoord=E<gt>[0,5]);>

S<print $edge -E<gt> directionExtent(-direction=E<gt>'N'); >## prints 5;

=cut

####### CircuitLayout::Edge Coord Boundary
sub directionExtent
{
    my ($self,%arg) = @_;
    my $side = $arg{'-direction'};  # 'N' 'S' 'E' or 'W' ...
    $side =~ s|^(.).*|\U$1|;
    my ($x1,$x2,$y1,$y2);
    my $num;

    if (ref($self) eq 'CircuitLayout::Coord')
    {
        if (($side eq 'N') || ($side eq 'S'))
        {
            $num = $self -> y;
        }
        else
        {
            $num = $self -> x;
        }
    }
    else
    {
        my @edges = ($self); ## default;
        @edges = $self -> edges if ((ref($self) eq 'CircuitLayout::Boundary') || (ref($self) eq 'CircuitLayout::Rectangle'));

        foreach my $edge (@edges)
        {
            my $edgeNum;
            $x1 = $edge -> startCoord -> x;
            $y1 = $edge -> startCoord -> y;
            $x2 = $edge -> endCoord -> x;
            $y2 = $edge -> endCoord -> y;
            if ($side eq 'N')
            {
                $edgeNum = $y1 > $y2 ? $y1 : $y2;
                $num = $edgeNum if (! defined $num);
                $num = $edgeNum if ($edgeNum > $num);
            }
            elsif ($side eq 'S')
            {
                $edgeNum = $y1 < $y2 ? $y1 : $y2;
                $num = $edgeNum if (! defined $num);
                $num = $edgeNum if ($edgeNum < $num);
            }
            elsif ($side eq 'E')
            {
                $edgeNum = $x1 > $x2 ? $x1 : $x2;
                $num = $edgeNum if (! defined $num);
                $num = $edgeNum if ($edgeNum > $num);
            }
            elsif ($side eq 'W')
            {
                $edgeNum = $x1 < $x2 ? $x1 : $x2;
                $num = $edgeNum if (! defined $num);
                $num = $edgeNum if ($edgeNum < $num);
            }
        }
    }
    $num;
}
################################################################

sub triangleArea($$$$$$)
{
    my ($x0,$y0,$x1,$y1,$x2,$y2) = @_;

    ( ($x1 - $x0) * ($y2 - $y0) -
      ($x2 - $x0) * ($y1 - $y0)
    ) / 2.0;
}
################################################################

sub area
{
    my ($self,%arg) = @_;
    my @coords = $self -> coords;
    my $area = 0;
    my $numCoords = $#coords;
    for (my $i=1; $i<($numCoords - 1); $i++)
    {
        $area += triangleArea($coords[0]->x,    $coords[0]->y,
                              $coords[$i]->x,   $coords[$i]->y,
                              $coords[$i+1]->x, $coords[$i+1]->y);
    }
    abs($area);
}
################################################################

=head1 CircuitLayout::Edge::length CircuitLayout::Boundary::length

=head2 Usage:

my $edgeLength = $edge -> length;

=head2 Synopsis:

Returns length of edge

S<my $edge = new CircuitLayout::Edge(-startCoord=E<gt>[0,1],-endCoord=E<gt>[0,5]);>

S<print $edge -E<gt> length(); >## prints 4;

=cut

####### CircuitLayout::Edge
sub length
{
    my ($self,%arg) = @_;
    
    my @edges = ($self); ## default;
    @edges = $self -> edges if ((ref($self) eq 'CircuitLayout::Boundary') || (ref($self) eq 'CircuitLayout::Rectangle'));

    my $edgeLength = 0.0;
    foreach my $edge (@edges)
    {
        my $x1 = $edge -> startCoord -> x;
        my $y1 = $edge -> startCoord -> y;
        my $x2 = $edge -> endCoord -> x;
        my $y2 = $edge -> endCoord -> y;
        $edgeLength += CircuitLayout::distance($x1, $y1, $x2, $y2);
    }

    $edgeLength;
}
################################################################

=head1 CircuitLayout::Edge::lengthAtExtent CircuitLayout::Boundary::lengthAtExtent

=head2 Usage:

my $edgeExtentLength = $edge -> lengthAtExtent;

=head2 Synopsis:

Returns position (real number) of edge length at maximum point in one of 4 magor compass directions: 'N','E','S','W'

S<my $edge = new CircuitLayout::Edge(-startCoord=E<gt>[0,1],-endCoord=E<gt>[0,5]);>

S<print $edge -E<gt> lengthAtExtent(-direction=E<gt>'N'); >## prints 4;

=cut

####### CircuitLayout::Edge
sub lengthAtExtent
{
    my ($self,%arg) = @_;
    my $side = $arg{'-direction'};  # 'N' 'S' 'E' or 'W' ...
    $side =~ s|^(.).*|\U$1|;
    my ($x1,$x2,$y1,$y2);
    my $num;
    my $position2Find = $self -> directionExtent(-direction=>$side);
    my @edges = ($self); ## default;
    @edges = $self -> edges if ((ref($self) eq 'CircuitLayout::Boundary') || (ref($self) eq 'CircuitLayout::Rectangle'));

    my $length = 0.0;
    my $edgeLength = 0.0;
    foreach my $edge (@edges)
    {
        my $edgeNum;
        $x1 = $edge -> startCoord -> x;
        $y1 = $edge -> startCoord -> y;
        $x2 = $edge -> endCoord -> x;
        $y2 = $edge -> endCoord -> y;
        if ($side eq 'N')
        {
            $edgeNum = $y1 > $y2 ? $y1 : $y2;
            $num = $edgeNum if (! defined $num);
            $num = $edgeNum if ($edgeNum > $num);
            $edgeLength = abs($x1 - $x2) if ($num == $position2Find);
        }
        elsif ($side eq 'S')
        {
            $edgeNum = $y1 < $y2 ? $y1 : $y2;
            $num = $edgeNum if (! defined $num);
            $num = $edgeNum if ($edgeNum < $num);
            $edgeLength = abs($x1 - $x2) if ($num == $position2Find);
        }
        elsif ($side eq 'E')
        {
            $edgeNum = $x1 > $x2 ? $x1 : $x2;
            $num = $edgeNum if (! defined $num);
            $num = $edgeNum if ($edgeNum > $num);
            $edgeLength = abs($y1 - $y2) if ($num == $position2Find);
        }
        elsif ($side eq 'W')
        {
            $edgeNum = $x1 < $x2 ? $x1 : $x2;
            $num = $edgeNum if (! defined $num);
            $num = $edgeNum if ($edgeNum < $num);
            $edgeLength = abs($y1 - $y2) if ($num == $position2Find);
        }

        $length = $edgeLength if ($edgeLength > $length);
    }
    my $pp1 = $self -> printPrecision + 1;
    sprintf("%0.${pp1}f",$length);
}
################################################################

=head1 CircuitLayout::Edge::inside

=head2 Usage:

print 'inside == true' if ($edge -> inside(-coord => $coord);

=head2 Synopsis:

Returns 0 | 1 depending on whether coord is inside of edge

=cut

####### CircuitLayout::Edge
sub inside
{
    my ($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
    }
    my ($cx,$cy,$x1,$x2,$y1,$y2);
    $cx = $coordRef -> x;
    $cy = $coordRef -> y;
    $x1 = $self -> startCoord -> x;
    $x2 = $self -> endCoord   -> x;
    $y1 = $self -> startCoord -> y;
    $y2 = $self -> endCoord   -> y;
    if (
        ($cx < $x1 && $cx < $x2) ||
        ($cx > $x1 && $cx > $x2) ||     
        ($cy < $y1 && $cy < $y2) ||
        ($cy > $y1 && $cy > $y2)
    )
    {
        return 0;
    }
#( abs(atan2($y1,$x1)) != abs(atan2($cy,$cx)) ) 
## TODO handle cx,cy = 0,0 and edge passes through it....
    return 1; ## made it...
}
################################################################

## end package CircuitLayout::Edge
1;
}

package CircuitLayout::Path;
{
use base ('CircuitLayout::Edge'); ## inherit some stuff

# This is the default class for the Path object to use when all else fails.
$CircuitLayout::Path::DefaultClass = 'CircuitLayout::Path' unless defined $CircuitLayout::Path::DefaultClass;

use overload '=='       => \&equals,
             'fallback' => 1,
             'nomethod' => sub {die "Operator $_[3] makes no sense for CircuitLayout::Path" };

=head1 CircuitLayout::Path::new

=head2 Usage:

## CircuitLayout::Coord object for Lower Left Coordinate...
my $path = new CircuitLayout::Path(

=cut

#### Method: new CircuitLayout::Path
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::DefaultClass;
    my $numCoords=0;
    my @coords;
    my @edges;
    my @revXy;
    my $x;
    my $y;
    my $coordA;
    my $coordB;
    my $edge;
    my @xy;
    my $coordRef = $arg{'-coords'};
    if (defined $coordRef)
    {
        foreach my $coord (@$coordRef)
        {
            push @xy,$coord->x;
            push @xy,$coord->y;
        }
    }
    else
    {
        @xy = $arg{'-xy'};
    }
    my $xy = '';
    my $numValues = 0;
    if ((defined $xy[0])&&($xy[0] ne ''))
    {
        $xy = $xy[0];
        $numValues = @$xy;
        if ($numValues) ## passed in anonymous array
        {
            @xy = @$xy; ## deref
        }
        else
        {
            $numValues = @xy;
        }
    }
    else
    {
        die "new expects xy array or CircuitLayout::Coord reference. Missing -xy => \\\@array $!";
    }
    die "new expects an even sized array to -xy => \\\@array $!" if ($numValues % 2);

    my $width = $arg{'-width'};
    if (! defined $width)
    {
        $width = 0;
    }

    my $layer = $arg{'-layer'};
    if (! defined $layer)
    {
        $layer = 0;
    }   

    my $dataType = $arg{'-dataType'};
    if (! defined $dataType)
    {
        $dataType = 0;
    }

    my $pathType = $arg{'-pathType'};
    if (! defined $pathType)
    {
        $pathType = 0; ## 0, 1, 2, 4
    }

    my $group = $arg{'-group'};
    if (! defined $group)
    {
        $group = '';
    }

    my $net = $arg{'-net'};
    if (! defined $net)
    {
        $net = $arg{'-node'}; ## OLD code may use this ## TODO
    }
    if (! defined $net)
    {
        $net = '';
    }

    my $property = $arg{'-property'};
    if (! defined $property)
    {
        $property = '';
    }

    @revXy = reverse @xy;
    $numCoords = ($#revXy + 1)/2;
    my $coordCnt=0;
    my $firstCoord;
    my $lastCoord;
    while ($#revXy>=0)
    {
        $x=pop @revXy;
        $y=pop @revXy;
        if (! ($coordCnt % 2))
        {
            $coordA = new CircuitLayout::Coord(-x=>$x,-y=>$y);
            push @coords,$coordA;
            if (! $coordCnt)
            {
                $firstCoord = $coordA;
            }
            else
            {
                $edge =  new CircuitLayout::Edge(-startCoord=>$coordB,-endCoord=>$coordA);
                push @edges,$edge;
            }
            $lastCoord = $coordA;
        }
        else
        {
            $coordB = new CircuitLayout::Coord(-x=>$x,-y=>$y);
            push @coords,$coordB;
            $edge =  new CircuitLayout::Edge(-startCoord=>$coordA,-endCoord=>$coordB);
            push @edges,$edge;
            $lastCoord = $coordB;
        }
        $coordCnt++;
    }
    $self -> {'PrintPrecision'} = 4;
    $self -> {'cPtr'}           = 0; ## for coords
    $self -> {'ePtr'}           = 0; ## for edges
    $self -> {'NumCoords'}      = $numCoords;
    $self -> {'XYs'}            = \@xy;
    $self -> {'Coords'}         = \@coords;
    $self -> {'Width'}          = $width;
    $self -> {'Edges'}          = \@edges;
    $self -> {'Layer'}          = $layer;
    $self -> {'DataType'}       = $dataType;
    $self -> {'PathType'}       = $pathType;
    $self -> {'Net'}            = $net;
    $self -> {'Group'}          = $group;
    $self -> {'Property'}       = $property;
    $self -> {'bgnExt'}         = 0; ## TODO 
    $self -> {'endExt'}         = 0; ## TODO  GDS2 path type 4
    
    $self -> {'Extent'}         = ''; ## set when needed 

    $self;
}

=head1 CircuitLayout::Path::display

draws on a worldCanvas

=cut

####### CircuitLayout::Path
sub display
{
    my($self,%arg) = @_;
    my $canvas = $arg{'-worldCanvas'};
    if (! defined $canvas)
    {
        print "ERROR: missing -canvas arg to CircuitLayout::Boundary::display\n";
        exit 2;
    }
    
    my $stippleFile = $arg{'-stippleFile'};
    if ((defined $stippleFile) && (-f $stippleFile)) ## xbitmap file
    {
        $stippleFile = "\@$stippleFile";
    }
    else
    {
        $stippleFile = '';
    }

    my $fill = $arg{'-fill'}; ## fill color
    my $fillColor = '';
    if (! defined $fill)
    {
        $fill = undef;
    }
    else
    {
        $fillColor = $fill;
    }

    my $layer = $self -> {'Layer'};

    my $name = $arg{'-name'};
    if (! defined $name)
    {
        $name = "layer $layer";
    }

    my $visible = $arg{'-visible'};
    if (! defined $visible)
    {
        $visible = 'true';
    }

    my $width = $self -> {'Width'};
    my $type = 'path';

    my @points = @{$self -> {'XYs'}};
    
    my $capstyle = 'butt'; ## TODO
    $canvas -> createLine(
        @points,
        -fill     => $fillColor,
        -width    => $width,
        -capstyle => $capstyle,
        -stipple  => "$stippleFile",
        -tags     => [
                      "fill=$fill",
                      "layer=$layer",
                      'layout=true',
                      "name=$name",
                      'selected=false',
                      "stipple=$stippleFile",
                      "type=$type",
                      "visible=$visible",
                     ],
    );
}
################################################################

## end package CircuitLayout::Path
1;
}


package CircuitLayout::Rectangle;
{
use base ('CircuitLayout::Edge'); ## inherit some stuff

# This is the default class for the Rectangle object to use when all else fails.
$CircuitLayout::Rectangle::DefaultClass = 'CircuitLayout::Rectangle' unless defined $CircuitLayout::Rectangle::DefaultClass;

use overload '=='       => \&equals,
             'fallback' => 1,
             'nomethod' => sub {die "Operator $_[3] makes no sense for CircuitLayout::Rectangle" };

=head1 CircuitLayout::Rectangle::new

=head2 Usage:

## CircuitLayout::Coord object for Lower Left Coordinate...
my $rect = new CircuitLayout::Rectangle(-llCoord=>$coord1,
                         -urCoord=>$coord2);
 -or-

my @llPoint = (0,0);
## anonymous array or array ref
my $rect = new CircuitLayout::Rectangle(-llCoord=>\@llPoint,
                         -urCoord=>[2.3,4.5]);

=cut

#### Method: new CircuitLayout::Rectangle
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::Rectangle::DefaultClass;
    my $layer = $arg{'-layer'};
    my $llCoord = $arg{'-llCoord'};
    my $urCoord = $arg{'-urCoord'};
    if (! ((defined $llCoord) && (defined $urCoord)))
    {
        die "new CircuitLayout::Rectangle expects lower left and upper right Coords. Missing -llCoord => Coord and or -urCoord => Coord $!";
    }
    if (! defined $layer) { $layer = 0; };
    if (ref($llCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($llCoord) eq 'ARRAY') ## anonymous array...
        {
            $llCoord = new CircuitLayout::Coord(-x=>@$llCoord[0],-y=>@$llCoord[1]);
        }
        die "Rectangle::new did not receive or could not create a coord. $!" if (ref($llCoord) ne 'CircuitLayout::Coord');
    }
    if (ref($urCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($urCoord) eq 'ARRAY') ## anonymous array...
        {
            $urCoord = new CircuitLayout::Coord(-x=>@$urCoord[0],-y=>@$urCoord[1]);
        }
        die "Rectangle::new did not receive or could not create a coord. $!" if (ref($urCoord) ne 'CircuitLayout::Coord');
    }
    my @edges;
    my $edge;
    $edge =  new CircuitLayout::Edge(-startCoord=>[$llCoord->x,$llCoord->y], -endCoord=>[$llCoord->x,$urCoord->y]);
    push @edges,$edge;
    $edge =  new CircuitLayout::Edge(-startCoord=>[$llCoord->x,$urCoord->y], -endCoord=>[$urCoord->x,$urCoord->y]);
    push @edges,$edge;
    $edge =  new CircuitLayout::Edge(-startCoord=>[$urCoord->x,$urCoord->y], -endCoord=>[$urCoord->x,$llCoord->y]);
    push @edges,$edge;
    $edge =  new CircuitLayout::Edge(-startCoord=>[$urCoord->x,$llCoord->y], -endCoord=>[$llCoord->x,$llCoord->y]);
    push @edges,$edge;
    $self -> {'PrintPrecision'} = 4;
    $self -> {'UR'}             = $urCoord;
    $self -> {'LL'}             = $llCoord;
    $self -> {'Layer'}          = $layer;
    $self -> {'Edges'}          = \@edges;
    $self;  
}
################################################################

=head1 CircuitLayout::Rectangle::center

=cut

####### CircuitLayout::Rectangle
sub center
{
    my $self = shift;
    my $x1 = $self -> ll -> x;
    my $x2 = $self -> ur -> x;
    my $y1 = $self -> ll -> y;
    my $y2 = $self -> ur -> y;
    my $xdiff = ($x2 - $x1)/2;
    my $ydiff = ($y2 - $y1)/2;
    my $x = $x1 + $xdiff;
    my $y = $y1 + $ydiff;
    my $result = new CircuitLayout::Coord(-x=>$x,-y=>$y);
    $result;
}
################################################################

=head1 CircuitLayout::Rectangle::edges

=cut

####### CircuitLayout::Rectangle
sub edges
{
    my $self = shift;
    my $edges=$self -> {'Edges'};
    my @edges=@$edges;
    @edges;
}
################################################################

=head1 CircuitLayout::Rectangle::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Rectangle
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################

=head1 CircuitLayout::Rectangle::printableCoords

returns string in "x1,y1;x2,y2"
where x and y print precision is controlled by objects printPrecision

Note: x1,y1 is lower left

=cut

####### CircuitLayout::Rectangle
sub printableCoords
{
    my $self = shift;
    my $pp = $self -> printPrecision;
    my $string = sprintf("%0.${pp}f",$self -> ll -> x).','.
                 sprintf("%0.${pp}f",$self -> ll -> y).';'.
                 sprintf("%0.${pp}f",$self -> ur -> x).','.
                 sprintf("%0.${pp}f",$self -> ur -> y);
    $string;
}
################################################################

=head1 CircuitLayout::Rectangle::add

=cut

####### CircuitLayout::Rectangle
sub add
{
    my($self,%arg) = @_;
    my $llCoord = $arg{'-llCoord'};
    my $urCoord = $arg{'-urCoord'};
    if (! ((defined $llCoord) && (defined $urCoord)))
    {
        die "CircuitLayout::Rectangle::add expects lower left and upper right Coords. Missing -llCoord => Coord and or -urCoord => Coord $!";
    }
    if (ref($llCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($llCoord) eq 'ARRAY') ## anonymous array...
        {
            $llCoord = new CircuitLayout::Coord(-x=>@$llCoord[0],-y=>@$llCoord[1]);
        }
        die "Rectangle::add did not receive or could not create a coord. $!" if (ref($llCoord) ne 'CircuitLayout::Coord');
    }
    if (ref($urCoord) ne 'CircuitLayout::Coord')
    {
        if (ref($urCoord) eq 'ARRAY') ## anonymous array...
        {
            $urCoord = new CircuitLayout::Coord(-x=>@$urCoord[0],-y=>@$urCoord[1]);
        }
        die "Rectangle::add did not receive or could not create a coord. $!" if (ref($urCoord) ne 'CircuitLayout::Coord');
    }

    my $llX = $self -> ll -> x;
    my $llY = $self -> ll -> y;
    my $urX = $self -> ur -> x;
    my $urY = $self -> ur -> y;
    my $llX2 = $llCoord -> x;
    my $llY2 = $llCoord -> y;
    my $urX2 = $urCoord -> x;
    my $urY2 = $urCoord -> y;

    $llX = $llX2 if ($llX2 < $llX);
    $llY = $llY2 if ($llY2 < $llY);
    $urX = $urX2 if ($urX2 > $urX);
    $urY = $urY2 if ($urY2 > $urY);
    my $rectangle = new CircuitLayout::Rectangle(-llCoord=>[$llX,$llY],-urCoord=>[$urX,$urY],-layer=>$self -> layer);
    $rectangle;
}
################################################################

=head1 CircuitLayout::Rectangle::extent

=cut

####### CircuitLayout::Rectangle
sub extent
{
    my($self,%arg) = @_;
    ### already a rectangle !!! 
    $self;
}
################################################################

=head1 CircuitLayout::Rectangle::inside

usage:
my $rect = new CircuitLayout::Rectangle(...);

print "is (4,6) inside ? ... ",$rect -> inside(-coord=>[4,6]);

=cut

sub inside
{
    my($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    my $numPoints=0;
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
        $numPoints++;
    }
    my ($cx,$cy,$x1,$x2,$y1,$y2);
    $cx = $coordRef -> x;
    $cy = $coordRef -> y;
    $x1 = $self -> ll -> x;
    $x2 = $self -> ur -> x;
    $y1 = $self -> ll -> y;
    $y2 = $self -> ur -> y;
    if (
        ($cx < $x1 && $cx < $x2) ||
        ($cx > $x1 && $cx > $x2) ||     
        ($cy < $y1 && $cy < $y2) ||
        ($cy > $y1 && $cy > $y2)
    )
    {
        return 0;
    }
    return 1; ## made it...
}
################################################################

=head1 CircuitLayout::Rectangle::interiorTo

usage:
my $rect = new CircuitLayout::Rectangle(...);

print "is (4,6) interiorTo ? ... ",$rect -> interiorTo(-coord=>[4,6]);

=cut

sub interiorTo
{
    my($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    my $numPoints=0;
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
        $numPoints++;
    }
    my ($cx,$cy,$x1,$x2,$y1,$y2);
    $cx = $coordRef -> x;
    $cy = $coordRef -> y;
    $x1 = $self -> ll -> x;
    $x2 = $self -> ur -> x;
    $y1 = $self -> ll -> y;
    $y2 = $self -> ur -> y;
    if (
        ($cx <= $x1 && $cx <= $x2) ||
        ($cx >= $x1 && $cx >= $x2) ||       
        ($cy <= $y1 && $cy <= $y2) ||
        ($cy >= $y1 && $cy >= $y2)
    )
    {
        return 0;
    }
    return 1; ## made it...
}
################################################################

## more package CircuitLayout::Rectangle later
1;
}

package CircuitLayout::Boundary;
{
use base ('CircuitLayout::Coord','CircuitLayout::Edge','CircuitLayout::Rectangle','CircuitLayout::Text'); ## inherit some stuff
# This is the default class for the CircuitLayout::Boundary object to use when all else fails.
$CircuitLayout::Boundary::DefaultClass = 'CircuitLayout::Boundary' unless defined $CircuitLayout::Boundary::DefaultClass;
use overload '+'        => \&append,
             '+='       => \&append,
             'fallback' => 1,
             'nomethod' => sub {die "Operator $_[3] makes no sense" };

=head1 CircuitLayout::new - create new CircuitLayout::Boundary

  usage:
  my $boundary  = new CircuitLayout::Boundary(-xy=>\@xyArray)  -or-
  my $boundary  = new CircuitLayout::Boundary(-coords=>\$coords) 

=cut

#### Method: new CircuitLayout::Boundary
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::DefaultClass;
    my $numCoords=0;
    my @coords;
    my @edges;
    my @revXy;
    my $x;
    my $y;
    my $coordA;
    my $coordB;
    my $edge;
    my @xy;
    my $coordRef = $arg{'-coords'};
    if (defined $coordRef)
    {
        foreach my $coord (@$coordRef)
        {
            push @xy,$coord->x;
            push @xy,$coord->y;
        }
    }
    else
    {
        @xy = $arg{'-xy'};
    }
    my $xy = '';
    my $numValues = 0;
    if ((defined $xy[0])&&($xy[0] ne ''))
    {
        $xy = $xy[0];
        $numValues = @$xy;
        if ($numValues) ## passed in anonymous array
        {
            @xy = @$xy; ## deref
        }
        else
        {
            $numValues = @xy;
        }
    }
    else
    {
        die "new expects xy array or CircuitLayout::Coord reference. Missing -xy => \\\@array $!";
    }
    die "new expects an even sized array to -xy => \\\@array $!" if ($numValues % 2);
    my $layer = $arg{'-layer'};
    if (! defined $layer)
    {
        $layer = 0;
    }   

    my $dataType = $arg{'-dataType'};
    if (! defined $dataType)
    {
        $dataType = 0;
    }

    my $group = $arg{'-group'};
    if (! defined $group)
    {
        $group = '';
    }

    my $net = $arg{'-net'};
    if (! defined $net)
    {
        $net = $arg{'-node'}; ## OLD code may use this ## TODO
    }
    if (! defined $net)
    {
        $net = '';
    }

    my $property = $arg{'-property'};
    if (! defined $property)
    {
        $property = '';
    }

    @revXy = reverse @xy;
    $numCoords = ($#revXy + 1)/2;
    my $coordCnt=0;
    my $firstCoord;
    my $lastCoord;
    while ($#revXy>=0)
    {
        $x=pop @revXy;
        $y=pop @revXy;
        if (! ($coordCnt % 2))
        {
            $coordA = new CircuitLayout::Coord(-x=>$x,-y=>$y);
            push @coords,$coordA;
            if (! $coordCnt)
            {
                $firstCoord = $coordA;
            }
            else
            {
                $edge =  new CircuitLayout::Edge(-startCoord=>$coordB,-endCoord=>$coordA);
                push @edges,$edge;
            }
            $lastCoord = $coordA;
        }
        else
        {
            $coordB = new CircuitLayout::Coord(-x=>$x,-y=>$y);
            push @coords,$coordB;
            $edge =  new CircuitLayout::Edge(-startCoord=>$coordA,-endCoord=>$coordB);
            push @edges,$edge;
            $lastCoord = $coordB;
        }
        $coordCnt++;
    }
    $edge =  new CircuitLayout::Edge(-startCoord=>$lastCoord,-endCoord=>$firstCoord);
    push @edges,$edge; ## closure
    $self -> {'PrintPrecision'} = 4;
    $self -> {'cPtr'}           = 0; ## for coords
    $self -> {'ePtr'}           = 0; ## for edges
    $self -> {'NumCoords'}      = $numCoords;
    $self -> {'XYs'}            = \@xy;
    $self -> {'Coords'}         = \@coords;
    $self -> {'Edges'}          = \@edges;
    $self -> {'Layer'}          = $layer;
    $self -> {'DataType'}       = $dataType;
    $self -> {'Net'}            = $net;
    $self -> {'Group'}          = $group;
    $self -> {'Property'}       = $property;
    
    $self -> {'IsRectangle'}    = ''; ## set when needed 
    $self -> {'Extent'}         = ''; ## set when needed 

    $self;
}
################################################################

=head1 CircuitLayout::Boundary::display

draws on a worldCanvas

=cut

####### CircuitLayout::Boundary
sub display
{
    my($self,%arg) = @_;
    my $canvas = $arg{'-worldCanvas'};
    if (! defined $canvas)
    {
        print "ERROR: missing -canvas arg to CircuitLayout::Boundary::display\n";
        exit 2;
    }
    
    my $stippleFile = $arg{'-stippleFile'};

    if ((defined $stippleFile) && (-f $stippleFile)) ## xbitmap file
    {
        $stippleFile = "\@$stippleFile";
    }
    else
    {
        $stippleFile = '';
    }

    my $fill = $arg{'-fill'}; ## fill color
    my $fillColor = '';
    if (! defined $fill)
    {
        $fill = undef;
    }
    else
    {
        $fillColor = $fill;
    }

    my $outline = $arg{'-outline'}; ## outline color
    my $outlineColor = '';
    if (! defined $outline)
    {
        $outline = undef;
    }
    else
    {
        $outlineColor = $outline;
    }

    my $layer = $self -> {'Layer'};
    my $name = $arg{'-name'};
    if (! defined $name)
    {
        $name = "layer $layer";
    }

    my $visible = $arg{'-visible'};
    if (! defined $visible)
    {
        $visible = 'true';
    }

    my $type = 'boundary';
    my @points = @{$self -> {'XYs'}};
    $canvas -> createPolygon(
        @points,
        -fill     => $fill,
        -outline  => $outline,
        -stipple  => "$stippleFile",
        -tags     => [
                      "fill=$fillColor",
                      "layer=$layer",
                      'layout=true',
                      "name=$name",
                      "outline=$outlineColor",
                      'selected=false',
                      "stipple=$stippleFile",
                      "type=$type",
                      "visible=$visible",
                     ],
    );
}
################################################################

=head1 CircuitLayout::Boundary::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Boundary
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################

=head1 CircuitLayout::Boundary::isRectangle

=cut

####### CircuitLayout::Boundary
sub isRectangle
{
    my $self = shift;
    if ($self -> {'IsRectangle'} eq '')
    {
        my $junk = $self -> extent; ## will find Extent and set IsRectangle
    }
    $self -> {'IsRectangle'};
}
################################################################

=head1 CircuitLayout::Boundary::extent

=cut

####### CircuitLayout::Boundary
sub extent
{
    my($self,%arg) = @_;
    if ($self -> {'Extent'} eq '') ## then need to find extent
    {
        my $layer = $self -> layer;
        my @rectangle;
        my $numCoords = $self -> numCoords;
        my @coords = $self -> coords;
        $self -> {'IsRectangle'} = 0; ## init this way for now...
        if ($numCoords == 4)
        {
            my $llCoord = $coords[0];
            my $urCoord = $coords[0];
            my @last3Coords = ($coords[1],$coords[2],$coords[3]);
            foreach my $testCoord (@last3Coords)
            {
                if (($testCoord->x < $llCoord->x) || ($testCoord->y < $llCoord->y) )
                {
                    $llCoord = $testCoord;
                }
                elsif (($testCoord->x > $urCoord->x) || ($testCoord->y > $urCoord->y) )
                {
                    $urCoord = $testCoord;
                }
            }
            my $rectangle = new CircuitLayout::Rectangle(-llCoord=>$llCoord,-urCoord=>$urCoord,-layer=>$layer);
            push @rectangle,$rectangle;
            my $llXcnt=0;
            my $llYcnt=0;
            my $urXcnt=0;
            my $urYcnt=0;
            foreach my $testCoord (@coords)
            {
                $llXcnt++ if ($testCoord->x == $llCoord->x);
                $llYcnt++ if ($testCoord->y == $llCoord->y);
                $urXcnt++ if ($testCoord->x == $urCoord->x);
                $urYcnt++ if ($testCoord->y == $urCoord->y);
            }
            $self -> {'IsRectangle'} = 1 if ($llXcnt==2 && $llYcnt==2 && $urXcnt==2 && $urYcnt==2);
        }
        else ## not a rectangle - just rectangular extent...
        {
            my $llX = $coords[0] -> x;
            my $llY = $coords[0] -> y;
            my $urX = $llX;
            my $urY = $llY;
            foreach my $testCoord (@coords)
            {
                $llX = $testCoord->x if ($testCoord->x < $llX);
                $llY = $testCoord->y if ($testCoord->y < $llY);
                $urX = $testCoord->x if ($testCoord->x > $urX);
                $urY = $testCoord->y if ($testCoord->y > $urY);
            }
            my $rectangle = new CircuitLayout::Rectangle(-llCoord=>[$llX,$llY],-urCoord=>[$urX,$urY],-layer=>$layer);
            push @rectangle,$rectangle;
        }
        $self -> {'Extent'} = \@rectangle;
    }

    $self -> {'Extent'}[0];
}
################################################################

=head1 CircuitLayout::Boundary::layer

=cut

####### CircuitLayout::Boundary
sub layer
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Layer'} = $value;
    }
    $self -> {'Layer'};
}
################################################################


=head1 CircuitLayout::Boundary::dataType

=cut

####### CircuitLayout::Boundary
sub dataType
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'DataType'} = $value;
    }
    $self -> {'DataType'};
}
################################################################

=head1 CircuitLayout::Boundary::property

=cut

####### CircuitLayout::Boundary
sub property
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Property'} = $value;
    }
    $self -> {'Property'};
}
################################################################

=head1 CircuitLayout::Boundary::node

=cut

####### CircuitLayout::Boundary
sub node
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Net'} = $value;
    }
    $self -> {'Net'};
}
################################################################

=head1 CircuitLayout::Boundary::net

=cut

####### CircuitLayout::Boundary
sub net
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Net'} = $value;
    }
    $self -> {'Net'};
}
################################################################

=head1 CircuitLayout::Boundary::group

=cut

####### CircuitLayout::Boundary
sub group
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'Group'} = $value;
    }
    $self -> {'Group'};
}
################################################################

=head1 CircuitLayout::Boundary::nextCoord

=cut

####### CircuitLayout::Boundary
sub nextCoord
{
    my $self = shift;
    my $ptr = $self -> {'cPtr'}++;
    if ($ptr < $self -> numCoords)
    {
        $self -> {'cPtr'} = $ptr + 1; ## Coord "pointer"
        return $self -> {'Coords'}[$ptr];
    }
    else
    {
        $self -> {'cPtr'} = 0;
        return undef();
    }
}
################################################################

=head1 CircuitLayout::Boundary::printableCoords

returns string in "x1,y1;x2,y2;x...."
where x and y print precision is controlled by objects printPrecision

=cut

####### CircuitLayout::Boundary
sub printableCoords
{
    my $self = shift;
    my $string='';
    my $pp = $self -> printPrecision;
    my $savePtr = $self -> {'cPtr'};
    $self -> {'cPtr'} = 0;
    while (my $c = $self -> nextCoord)
    {
        $string .= sprintf("%0.${pp}f",$c -> x).','.sprintf("%0.${pp}f",$c -> y).';';
    }
    $self -> {'cPtr'} = $savePtr;
    $string =~ s|;$||;
    $string;
}
################################################################

=head1 CircuitLayout::Boundary::nextEdge

=cut

####### CircuitLayout::Boundary
sub nextEdge
{
    my $self = shift;
    my $ptr = $self -> {'ePtr'}++;
    if ($ptr < $self -> numCoords)
    {
        $self -> {'ePtr'} = $ptr + 1; ## edge "pointer"
        return $self -> {'Edges'}[$ptr];
    }
    else
    {
        $self -> {'ePtr'} = 0;
        return undef();
    }
}
################################################################

=head1 CircuitLayout::Boundary::append

=cut

####### CircuitLayout::Boundary
sub append
{
    my($self,$ref) = @_;
    if (ref $ref ne 'CircuitLayout::Coord')
    {
        if (ref $ref eq 'ARRAY') ## anonymous array...
        {
            $ref = new CircuitLayout::Coord(-x=>@$ref[0],-y=>@$ref[1]);
        }
        die "append did not receive or could not create a coord. $!" if (ref $ref ne 'CircuitLayout::Coord');
    }
    my @coords = $self -> coords;
    push @coords,$ref;
    $self -> {'NumCoords'}++;
    $self -> {'Coords'} = \@coords;
    bless $self,'CircuitLayout::Boundary';
    $self;
}
################################################################

=head1 CircuitLayout::Boundary::numCoords

=cut

####### CircuitLayout::Boundary
sub numCoords
{
    my $self = shift;
    $self -> {'NumCoords'};
}
################################################################

=head1 CircuitLayout::Boundary::xys

=cut

####### CircuitLayout::Boundary
sub xys
{
    my $self = shift;
    my $xys=$self -> {'XYs'};
    my @xys=@$xys;
    @xys;
}
################################################################

=head1 CircuitLayout::Boundary::coords

=cut

####### CircuitLayout::Boundary
sub coords
{
    my $self = shift;
    my $coords=$self -> {'Coords'};
    my @coords=@$coords;
    @coords;
}
################################################################

=head1 CircuitLayout::Boundary::edges

=cut

####### CircuitLayout::Boundary
sub edges
{
    my $self = shift;
    my $edges=$self -> {'Edges'};
    my @edges=@$edges;
    @edges;
}
################################################################

=head1 CircuitLayout::Boundary::boundaryOutline

returns self (already a Boundary)

=cut

####### CircuitLayout::Boundary
sub boundaryOutline
{
    my $self = shift;
    ## already a Boundary
    $self;
}
################################################################

=head1 CircuitLayout::Boundary::inside

usage:
my @xys=(0,0, 10,0, 10,10, 0,10);

my $boundary = new CircuitLayout::Boundary(-xy=>\@xys);

print "is (4,6) inside ? ... ",$boundary -> inside(-coord=>[4,6]);

=cut

sub inside_old
{
    my($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    my $numPoints=0;
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
        $numPoints++;
    }
    ## copy CircuitLayout::Boundary coords and shift so that coord to test is at the origin.
    my $crossings=0;
    my $savePtr = $self -> {'ePtr'};
    $self -> {'ePtr'} = 0;
    my $e;
    ## For each edge=(i-1,i), see if it crosses x ray.
    while ($e = $self -> nextEdge)
    {
        if (
            (defined ($e -> xIntersection)) &&
            ($e->straddleTouchXray(-yValue => $coordRef->y))
        )
        {
            $crossings++ if ($e->xIntersection > $coordRef->x);
        }
        if ($e -> inside(-coord => $coordRef) ) ## then on edge 
        {
            $self -> {'ePtr'} = $savePtr;
            return 1;
        }
    }
    $self -> {'ePtr'} = $savePtr;
    # inside if (an odd number of crossings.)
    $crossings % 2;
}
################################################################

=head1 CircuitLayout::Boundary::inside

usage:
my @xys=(0,0, 10,0, 10,10, 0,10);

my $boundary = new CircuitLayout::Boundary(-xy=>\@xys);

print "is (4,6) inside ? ... ",$boundary -> inside(-coord=>[4,6]);

=cut

sub inside
{
    my($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
    }
    #### 1st check if coord in extent rectangle.. if not return 0
    my $extent = $self -> extent;
    return 0  if (! $extent -> inside(-coord => $coordRef)); ## not even in extent

    my $savePtr = $self -> {'ePtr'}; ## save state
    $self -> {'ePtr'} = 0;
    my $e;

    ## winding number code modified from source posted on http://geometryalgorithms.com 
    ##// Copyright 2000, softSurfer (www.softsurfer.com)
    ##// This code may be freely used and modified for any purpose
    ##// providing that this copyright notice is included with it.
    my $wn = 0; ## the winding number counter
    my $isLeft;
    while ($e = $self -> nextEdge)
    {
        $isLeft = $e -> isLeft(-coord => $coordRef);
        return 1 if (($isLeft == 0) && ($e -> inside(-coord=>$coordRef))); ## on an edge

        if (($e -> startCoord -> y) <= ($coordRef -> y))
        {
            ++$wn if (($isLeft == 1) && ($e -> endCoord -> y) > ($coordRef -> y));
        }
        else
        {
            --$wn if (($isLeft == -1) && ($e -> endCoord -> y) <= ($coordRef -> y));
        }
    }

    $self -> {'ePtr'} = $savePtr;
    return 1 if ($wn);
    $wn;
}
################################################################

=head1 CircuitLayout::Boundary::interiorTo

usage:
my @xys=(0,0, 10,0, 10,10, 0,10);

my $boundary = new CircuitLayout::Boundary(-xy=>\@xys);

print "is (4,6) interiorTo ? ... ",$boundary -> interiorTo(-coord=>[4,6]);

=cut

sub interiorTo
{
    my($self,%arg) = @_;
    my $coordRef = $arg{'-coord'};
    my $numPoints=0;
    if (defined $coordRef)
    {
        if (ref $coordRef ne 'CircuitLayout::Coord') ## anonymous array...
        {
            $coordRef = new CircuitLayout::Coord(-x=>@$coordRef[0],-y=>@$coordRef[1]);
        }
        $numPoints++;
    }
    ## copy CircuitLayout::Boundary coords and shift so that coord to test is at the origin.
    my $crossings=0;
    my $savePtr = $self -> {'ePtr'};
    $self -> {'ePtr'} = 0;
    my $e;
    ## For each edge=(i-1,i), see if it crosses x ray.
    while ($e = $self -> nextEdge)
    {
        if (
            (defined ($e -> xIntersection)) &&
            ($e->straddleTouchXray(-yValue => $coordRef->y))
        )
        {
            $crossings++ if ($e->xIntersection > $coordRef->x);
        }
        if ($e -> inside(-coord => $coordRef) ) ## then not strictly interior
        {
            $self -> {'ePtr'} = $savePtr;
            return 0;
        }
    }
    $self -> {'ePtr'} = $savePtr;
    # interiorTo if (an odd number of crossings.)
    $crossings % 2;
}
################################################################

1;
## end package CircuitLayout::Boundary
}

package CircuitLayout::Rectangle;
{
=head1 CircuitLayout::Rectangle::ll

=cut

####### CircuitLayout::Rectangle
sub ll
{
    my $self = shift;
    $self -> {'LL'};
}
################################################################

=head1 CircuitLayout::Rectangle::ur

=cut

####### CircuitLayout::Rectangle
sub ur
{
    my $self = shift;
    $self -> {'UR'};
}
################################################################

=head1 CircuitLayout::Rectangle::layer

=cut

####### CircuitLayout::Rectangle
sub layer 
{
    my $self = shift;
    $self -> {'Layer'};
}
################################################################

=head1 CircuitLayout::Rectangle::boundaryOutline

returns Boundary representation of 2 point rectangle

=cut

####### CircuitLayout::Rectangle
sub boundaryOutline
{
    my $self = shift;
    my @pointArray = ($self -> ll -> x, $self -> ll -> y,
                      $self -> ll -> x, $self -> ur -> y,
                      $self -> ur -> x, $self -> ur -> y,
                      $self -> ur -> x, $self -> ll -> y,
                      );
    my $rectBoundary = new CircuitLayout::Boundary(-xy => \@pointArray);
    $rectBoundary;
}
################################################################

=head1 CircuitLayout::Rectangle::equals

=cut

####### CircuitLayout::Rectangle::equals
sub equals
{
    my($self,$ref) = @_;
    my ($ll1,$ll2,$ur1,$ur2);
    my $result = 0;
    if (ref $ref eq 'CircuitLayout::Rectangle')
    {
        $ll2 = $ref -> ll;
        $ur2 = $ref -> ur;
    }
    else
    {
        die "Rectangle::equals did not receive a CircuitLayout::Rectangle. $!";
    }
    $ll1 = $self -> ll;
    $ur1 = $self -> ur;
    $result = 1 if (($ll1==$ll2) && ($ur1==$ur2));
    $result;
}
################################################################
###########################################################
## end package CircuitLayout::Rectangle
1;
}

package CircuitLayout::Sref;
{
use base ('CircuitLayout::Coord','CircuitLayout::Edge','CircuitLayout::Boundary','CircuitLayout::Rectangle','CircuitLayout::Text'); ## inherit some stuff
# This is the default class for the CircuitLayout::Sref object to use when all else fails.
$CircuitLayout::Sref::DefaultClass = 'CircuitLayout::Sref' unless defined $CircuitLayout::Sref::DefaultClass;

=head1 CircuitLayout::new - create new CircuitLayout::Sref

  usage:
  my $sref  = new CircuitLayout::Sref(-xy=>\@xyArray)  -or-
  my $sref  = new CircuitLayout::Sref(-coords=>\$coords) 

=cut

#### Method: new CircuitLayout::Sref
sub new
{
    my($class,%arg) = @_;
    my $self = {};
    bless $self,$class || ref $class || $CircuitLayout::Sref::DefaultClass;
    my $origin = $arg{'-origin'};
    if (! defined($origin))
    {
        die "new CircuitLayout::Sref expects origin Coord. Missing -origin => Coord $!";
    }
    else
    {
        if (ref($origin) ne 'CircuitLayout::Coord')
        {
            if (ref($origin) eq 'ARRAY') ## anonymous array...
            {
                $origin = new CircuitLayout::Coord(-x=>@$origin[0],-y=>@$origin[1]);
            }
            die "CircuitLayout::Sref::new did not receive or could not create a coord. $!" if (ref($origin) ne 'CircuitLayout::Coord');
        }
    }
    my $name = $arg{'-name'};
    if (! defined $name)
    {
        $name = '';
    }

    my $reflection = $arg{'-reflection'};
    if (! defined $reflection)
    {
        $reflection = 0; ## false
    }

    my $angle = $arg{'-angle'};
    if (! defined $angle)
    {
        $angle = 0.0;
    }

    $self -> {'PrintPrecision'} = 4;
    $self -> {'Origin'}         = $origin;
    $self -> {'Name'}           = $name;
    $self -> {'Reflection'}     = $reflection;
    $self -> {'Angle'}          = $angle;
    $self;
}
################################################################

=head1 CircuitLayout::Sref::name

returns name as "string"
use -value to change and pass in string

=cut

####### CircuitLayout::Sref
sub name
{
    my($self,%arg) = @_;
    my $name = $arg{'-value'};
    if (defined($name))
    {
        $self -> {'Name'} = $name;
    }
    $self -> {'Name'};
}
################################################################

=head1 CircuitLayout::Sref::origin

returns origin as Coord object
use -value to change and pass in Coord or x,y array

=cut

####### CircuitLayout::Sref
sub origin
{
    my($self,%arg) = @_;
    my $origin = $arg{'-value'};
    if (defined($origin))
    {
        if (ref($origin) ne 'CircuitLayout::Coord')
        {
            if (ref($origin) eq 'ARRAY') ## anonymous array...
            {
                $origin = new CircuitLayout::Coord(-x=>@$origin[0],-y=>@$origin[1]);
            }
            die "CircuitLayout::Sref::origin did not receive or could not create a coord. $!" if (ref($origin) ne 'CircuitLayout::Coord');
        }
        $self -> {'Origin'} = $origin;
    }
    $self -> {'Origin'};
}
################################################################

=head1 CircuitLayout::printPrecision

returns precision (integer)

=cut

####### CircuitLayout::Sref
sub printPrecision
{
    my($self,%arg) = @_;
    my $value = $arg{'-value'};
    if (defined $value)
    {
        $self -> {'PrintPrecision'} = $value if ($value =~ m/^\d+$/);
    }
    $self -> {'PrintPrecision'};
}
################################################################


=head1 CircuitLayout::Sref::printableCoords

returns string in "x1,y1"
where x and y print precision is controlled by objects printPrecision

Note: returns origin (which is just one coordinate) but method name
is plural none the less to be consistant with other methods.

=cut

####### CircuitLayout::Sref
sub printableCoords
{
    my $self = shift;
    $self -> origin -> printableCoords;
}
################################################################

1;
## end package CircuitLayout::Sref
}

package CircuitLayout;
{
use base ('CircuitLayout::Coord','CircuitLayout::Edge','CircuitLayout::Rectangle','CircuitLayout::Text'); ## inherit some stuff
# This is the default class for the CircuitLayout object to use when all else fails.
$CircuitLayout::DefaultClass = 'CircuitLayout' unless defined $CircuitLayout::DefaultClass;

=head1 CircuitLayout::version

=cut

sub version()
{
    return $VERSION;
}
################################################################################

=head1 CircuitLayout::revision

=cut

sub revision()
{
    return $revision;
}
################################################################################

sub distance
{
    my ($x1,$y1,$x2,$y2) = @_;
    sqrt( (($x2 - $x1)**2) + (($y2 - $y1)**2) );
}
################################################################################

1;
## end package CircuitLayout
}

__END__

=head1 Examples

=head2 example using GDS2 to read in binary GDS2 stream file.

  #!/usr/local/bin/perl -w
  use strict;
  $|++;
  use lib '.';
  use CircuitLayout;
  use GDS2;
  $\="\n";
  
  my $streamFileName = $ARGV[0];
  my $gds2File = new GDS2(-fileName => $streamFileName);
  my $inBoundary=0;
  my $layerNum;
  my @layerIndexCnt;
  my %boundaries;
  while (my $record = $gds2File -> readGds2Record)
  {
    $inBoundary=1 if($gds2File -> isBoundary);
    $inBoundary=0 if($gds2File -> isEndel);
    if ($inBoundary)
    {
      $layerNum = $gds2File -> returnLayer if($gds2File -> isLayer);
      if($gds2File -> isXy)
      {
        if (! defined $layerIndexCnt[$layerNum]) { $layerIndexCnt[$layerNum] = 0; }
        my $layerIndex = $layerIndexCnt[$layerNum];
        ## Use "my @xys" here to get unique memory location
        my @xys = $gds2File ->  returnXyAsArray(-withClosure=>0,-asInteger=>0);
        my $boundary = new CircuitLayout::Boundary(-xy=>\@xys,-layer=>$layerNum);
        $boundaries{$layerNum}{$layerIndex} = \$boundary;
        $layerIndexCnt[$layerNum]++;
      }
    }
  }
  my $boundary;
  foreach my $layer (sort {$a <=> $b} keys %boundaries)
  {
    foreach my $x (keys %{$boundaries{$layer}})
    {
      $boundary = ${$boundaries{$layer}{$x}};
      print $boundary -> layer,':',$boundary -> printableCoords;
    }
  }
  ################################################################################

=cut

