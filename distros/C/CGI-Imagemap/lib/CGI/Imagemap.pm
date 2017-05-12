package CGI::Imagemap;
use strict;
use vars '$VERSION';
$VERSION = 2.0;

sub new { 
  return bless {
		DEFAULT => undef,
		ISMAP   => [],
		MINDIST => -1
	       }, shift;
}

sub addmap {
  my $self = shift;
  if( $_[0] eq '-file' ){
    open(my $map, $_[1]) || die("Unable to open map '$_[1]': $!");
    @_ = grep {! /^\s*(?:#|$)/ } <$map>;
    close($map);
  }
  push @{$self->{ISMAP}}, @_;
}


sub action {
  my($self, $x, $y) = @_;

  $self->{MINDIST} = -1;
  
  die "No map specified" unless defined($self->{ISMAP});

 POINT: foreach ( @{$self->{ISMAP}} ){
    my ($shape, $URI, $points) = split(/\s+/, $_, 3);
    $self->{DEFAULT} ||= $URI                      if $shape =~ /default/i;
    $self->_rect  ($x, $y, $points) && return $URI if $shape =~ /rect/i;
    $self->_poly  ($x, $y, $points) && return $URI if $shape =~ /poly/i;
    $self->_circle($x, $y, $points) && return $URI if $shape =~ /circle/i;
    $self->_oval  ($x, $y, $points) && return $URI if $shape =~ /oval/i;
    $self->_point ($x, $y, $points) &&
      ($self->{DEFAULT} = $URI) if $shape =~ /point/i;
  }
  return $self->{DEFAULT};
}

# set default action if this point is the closest so far
# does not check for validity of parameters
sub _point {
  my($self, $x, $y, $target) = @_;
  my($dist2, $Tx, $Ty) = 0;

  ($Tx, $Ty) = $target =~ m/(\d+),\s*(\d+)/;
  $dist2 = ($x - $Tx)**2 + ($y - $Ty)**2;

  if( $self->{MINDIST} == -1 || $dist2 < $self->{MINDIST} ){
    $self->{MINDIST} = $dist2;
    return 1;
  }
  return 0;
}

# return true if point is in given rectangle
sub _rect {
  my($self, $x, $y, $target) = @_;
  my($ulx,$uly,$llx,$lly) = $target =~ m/(\d+),(\d+)\s+(\d+),(\d+)/;

  return ($x >= $ulx && $y >= $uly && $x <= $llx && $y <= $lly);
}

sub _oval{
  my($self, $x, $y, $target) = @_;
  my($cx, $cy, $major, $minor) = $target =~ m/(\d+),(\d+)\s+(\d+),(\d+)/;

  # Ellipse equation: (x-$cx)^2/major^2 + (y-$cy)^2/minor^2 = 1
  # If the point ($x,$y) plugged into the equation is > 1 =>
  # pt is outside, if <=1, pt. is inside..
  return (($x-$cx)**2/$major**2 + ($y-$cy)**2/$minor**2)<=1;
}

# return true if point is in circle
sub _circle {
  my($self, $x, $y, $target) = @_;
  my($cx,$cy,$ex,$ey) = $target =~ m/(\d+),(\d+)\s+(\d+),(\d+)/;

  my($distanceP,$distanceE);

  # compare squares of distance from center of edgepoint and given point

  $distanceP = ($cx - $x)**2 + ($cy - $y)**2;
  $distanceE = ($cx - $ex)**2 + ($cy - $ey)**2;

  return ($distanceP <= $distanceE);
}

# return true if point is in given polygon
sub _poly {
  my($self, $x, $y, $target) = @_;
  my($pn, @px, @py) = 0;
  my($i,$intersections,$dy,$dx,$b,$m,$x1,$y1,$x2,$y2);

  # We'll treat the test point as the origin, so translate each
  # point in the polygon appropriately
  while($target =~ s/\s*(\d+),(\d+),?//) {
    $px[$pn] = $1 - $x;
    $py[$pn] = $2 - $y;
    $pn++;
  }

  # A polygon with less than 3 points is an error
  return 0 if $pn < 3;

  # Close the polygon
  $px[$pn] = $px[0];
  $py[$pn] = $py[0];

  # Now count the number of line segments in the polygon that intersect
  # the left side of the X axis.  If it's an odd number we are inside the
  # polygon.

  # Assume no intersection
  $intersections=0;

  for($i = 0; $i < $pn; $i++) {
    $x1 = $px[$i  ]; $y1 = $py[$i  ];
    $x2 = $px[$i+1]; $y2 = $py[$i+1];

    # Line is completely to the right of the Y axis
    next if( ($x1>0) && ($x2>0) );

    # Line doesn't intersect the X axis at all
    next if( (($y1<=>0)==($y2<=>0)) && (($y1!=0)&&($y2!=0)) );

    # Special case.. if the Y on the bottom=0, we ignore this intersection
    # (otherwise a line endpoint counts as 2 hits instead of 1)
    if( $y2>$y1 ){
      next if $y2==0;
    }
    elsif( $y1>$y2 ){
      next if $y1==0;
    }
    else {
      # Horizontal span overlaying the X axis.  Consider it an intersection 
      # iff. it extends into the left side of the X axis
      $intersections++ if ( ($x1 < 0) || ($x2 < 0) );
      next;
    }

    # We know line must intersect the X axis, so see where
    $dx = $x2 - $x1;

    # Special case.. if a vertical line, it intersects
    unless ( $dx ) {
      $intersections++;
      next;
    }

    $dy = $y2 - $y1;
    $m = $dy / $dx;
    $b = $y2 - $m * $x2;
    next if ( ( (0 - $b) / $m ) > 0 );

    $intersections++;
  }

  # If there were an odd number of intersections to the left of the origin
  # (the clicked-on point) then it is within the polygon
  return ($intersections % 2);
}

1;

__END__

=pod

=head1 NAME

CGI::Imagemap - interpret NCSA imagemaps for CGI programs

=head1 SYNOPSIS

  use CGI::Imagemap;
 
  $map = new CGI::Imagemap;

  $map->addmap(-file=>"image.map");
  #OR
  $map->addmap(@map);

  eval { $action = $map->action($x,$y) };
  #Check $@ for errors

=head1 DESCRIPTION

CGI::Imagemap allows CGI programmers to emulate the NCSA C<imagemap>
CGI or place TYPE=IMAGE form fields on their forms.

The imagemap file follows that of the NCSA imagemap program.
See L</NOTES> for further details.

=over

=item addmap(-file=>F<image.map>)

This appends the contents of the file to the map object.

  $map->addmap('path/to/file.map');

=item addmap(@map)

This appends @map to the map object.

  $map->addmap('point http://cpan.org 3,9');

=item action(x,y)

This finds the URI defined by the map for the point at x and y.
Returns undef if nothing matches. ie; no point and no default directives

  $action = $map->action($x, $y);

C<action> throws an exception if there is an error.
You should catch this with block eval and check $@

=back

=head1 NOTES

=head2 NCSA Style Image Map Syntax

Blank lines and comments (start with I<#>) are ignored.
Each line in the map consists of a directive such as a shape name followed
by the URI to associate with the shape and the points defining the shape.
A point is an I<x,y> tuple. Supported directives are

=over

=item default URI

The URI for a selection not within any defined shape,
if there are no point directives defined.

=item point   URI point

Point objects do not themselves have to be clicked,
instead if no shape was clicked the point closest to
the clicked location matches.

=item circle  URI centerPoint    edgePoint

A circle with radius extending from centerPoint to edgePoint.

=item oval    URI centerPoint    xAxis,           yAxis

An oval (ellipse) centered at centerPoint with the defined axes.

  oval 50,50 30,30

Is the same as

  circle 50,50 20,50

=item rect    URI upperLeftPoint lowerRightPoint

A rectangle from upperleftPoint to lowerRightPoint. eg;

  rectangle 10,10 30,30

Is a rectangle with corners at 10,10 10,30 30,30 30,10

=item poly    URI point1         point2  .  .  .  pointN

A closed polygon defined by edges connecting points in the order listed. eg;

  poly 10,10 10,30 30,30 30,10

Is the same as the rectangle above.

=back

The input coordinates are matched against the targets in the order which
they were added to the object eg; read from the map file. This is normal
behavior and so if you have overlapping shapes be sure to order them properly.
Additionally, if you have complex non-overlapping shapes their order will
affect the time to match. Place the simplest or most likely to be selected
shapes first in your map file.

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=head1 CREDITS

Based upon CGI::Imagemap 1.00 by Mike Heins <mikeh@cpan.org>.

Who intern gladly reused code from C<imagemap.pl> by V. Khera <khera@kciLink.com>.

Point in polygon detection based on code by Mike Lyons <lyonsm@netbistro.com>.

Point in oval detection based on code by Lynn Bry <lynn@pharmdec.wustl.edu>.

=cut
