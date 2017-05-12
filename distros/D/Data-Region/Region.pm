package Data::Region;
use strict;

our $VERSION = '1.0';
our $REVISION = '$Id: Region.pm,v 1.5 2002/11/09 02:32:19 gdf Exp $ ';


# Reading the perldoc at the end is probably a better place to start
# than reading these inline comments...

our @_Keys = qw( warnings data );

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init(@_);
  return $self;
}

#
# warnings => if true, bounds errors generate gripes
# data => ref to some random data to associate with this region
# x =>
# y => specify top left corner (defaults to 0,0)
#
# coords start from top left, and proceed to lower right
#
sub _init {
  my $self = shift;
  my( $w, $h, $opt ) = @_;

  my $x = (defined($opt->{x}) ? $opt->{x} : 0);
  my $y = (defined($opt->{y}) ? $opt->{y} : 0);

  #w; warn "DIAG Creating $w x $h @ ($x, $y)\n";
  $self->{tl} = [$x,$y];
  $self->{br} = [$x+$w,$y+$h];
  $self->{_kids} = [];
  $self->{_calls} = [];

  foreach my $k (@_Keys) {
    $self->{$k} = $opt->{$k};
  }
}

# Returns a list of sub-areas, tiled vertically into $self,
#  where each successive area has a height given by the list of args.
# A final area will be returned comprising the remaining height of $self,
#  if the arguments do not entirely fill $self.
# eg, if $self->height()==13, then
#   @a = $self->split_vertical( 2, 5, 1 );
#   $a[0]->height() == 2 # y=[0..2]
#   $a[1]->height() == 5 # y=[2..7]
#   $a[2]->height() == 1 # y=[7..8]
#   $a[3]->height() == 5 # y=[8..13], ie all the rest of $self
#
sub split_vertical {
  my $self = shift;
  my( @offs ) = @_;
  my @ret;

  my($x,$w) = ($self->{tl}->[0], ($self->{br}->[0] - $self->{tl}->[0]));
  my $yc = $self->{tl}->[1];
  for( my $i=0; $i<@offs; $i++ ) {
    push( @ret, $self->_spawn($x,$yc, $w, $offs[$i]) );
    $yc += $offs[$i];
  }
  if ( $yc < $self->{br}->[1] ) { # any area of $self left?
    push( @ret, $self->_spawn($x,$yc, $w, ($self->{br}->[1]-$yc)) );
  }
  return @ret;

}


sub split_horizontal {
  my $self = shift;
  my( @offs ) = @_;
  my @ret;

  my($y,$h) = ($self->{tl}->[1], ($self->{br}->[1] - $self->{tl}->[1]));
  my $xc = $self->{tl}->[0];
  for( my $i=0; $i<@offs; $i++) {
    push(@ret, $self->_spawn($xc,$y, $offs[$i],$h) );
    $xc+=$offs[$i];
  }
  if ( $xc < $self->{br}->[0] ) {
    push(@ret, $self->_spawn($xc,$y, ($self->{br}->[0]-$xc),$h) );
  }
  return @ret;
}

# returns list of sub-areas, tiled vertically into $self,
# with successive Y coordinates given by @stops
sub split_vertical_abs {
  my $self = shift;
  my( @stops ) = @_;
  my @ret;

  my($x,$w) = ($self->{tl}->[0], ($self->{br}->[0] - $self->{tl}->[0]));
  for( my $i=0; $i<@stops; $i++ ) {
    my $yc = $stops[$i];
    my $nexty = $stops[$i+1];
    $nexty = $self->{br}->[1] unless defined($nexty);
    my $hc = $nexty-$yc;
    push(@ret, $self->_spawn($x,$yc, $w,$hc));
  }
  return @ret;
}

# returns list of sub-areas, tiled horizontally into $self,
# with successive X coordinates given by @stops
# XXX rename this split_horizontal_abs, and create a non-abs one
sub split_horizontal_abs {
  my $self = shift;
  my( @stops ) = @_;
  my @ret;

  my($y, $h) = ($self->{tl}->[1], ($self->{br}->[1] - $self->{tl}->[1]));
  for( my $i=0; $i<@stops; $i++) {
    my $xc = $stops[$i];
    my $nextx = $stops[$i+1];
    # last area fills to the right
    $nextx = $self->{br}->[0] unless defined($nextx);
    my $wc = ($nextx-$xc);
    push(@ret, $self->_spawn($xc,$y, $wc,$h));
  }
  return @ret;
}


# returns a list of new regions tiled into this one, with the given size
# may not fill this entire region (only whole regions will be created)
sub subdivide {
  my $self = shift;
  my( $w, $h ) = @_;
  my @ret = ();

  #w; warn "DIAG entering subd\n";

  my($xc,$yc) = @{$self->{tl}};
  while( $yc+$h <= $self->{br}->[1] ) {
    while( $xc+$w <= $self->{br}->[0] ) {
      push(@ret, $self->_spawn($xc,$yc,$w,$h));
      $xc += $w;
    }
    $xc = $self->{tl}->[0];
    $yc += $h;
  }

  return @ret;
}

# returns new region with coords relative to this one
sub area {
  my $self = shift;
  my( $x1,$y1, $x2,$y2 ) = @_;

  #w; warn "DIAG entering area ( $x1,$y1, $x2,$y2 )\n";

  my( $x,$y ) = ( $self->{tl}->[0]+$x1, $self->{tl}->[1]+$y1 );
  #w; warn "DIAG tl corner = ($x,$y)\n";
  # allow second (x,y) to be negative (=back off from br corner)
  my( $brx, $bry );
  if ( $x2<0 ) {
    $brx = $self->{br}->[0] + $x2;
  } else {
    $brx = $self->{tl}->[0] + $x2;
  }
  if ( $y2<0 ) {
    $bry = $self->{br}->[1] + $y2;
  } else {
    $bry = $self->{tl}->[1] + $y2;
  }
  #w; warn "DIAG br corner = ($x2,$y2)\n";
  my( $w,$h ) = ( $brx-$x, $bry-$y );

  # should warn here if warnings on and this w/h > $self->w/h
  #     or if the tlc>brc

  return $self->_spawn($x,$y,$w,$h);
}


# _spawn( $x,$y, $w,$h );
# x, y absolute
sub _spawn {
  my $self = shift;
  my( $x,$y,$w,$h ) = @_;

  my $new = ref($self)->new( $w,$h, {x=>$x, y=>$y} );
  foreach my $k (@_Keys) { # inherit parent's attributes
    $new->{$k} = $self->{$k};
  }
  push(@{$self->{_kids}}, $new);
  return $new;
}


# returns the coords of the top left, bottom right corners of this region
sub coords { 
  my $self = shift;
  return (@{$self->{tl}}, @{$self->{br}});
}

sub width {
  my $self = shift;
  return $self->{br}->[0] - $self->{tl}->[0];
}

sub height {
  my $self = shift;
  return $self->{br}->[1] - $self->{tl}->[1];
}

sub top_left {
  my $self = shift;
  return @{$self->{tl}};
}

sub top_right {
  my $self = shift;
  return ($self->{br}->[0], $self->{tl}->[1]);
}

sub bottom_right {
  my $self = shift;
  return @{$self->{br}};
}

sub bottom_left {
  my $self = shift;
  return ($self->{tl}->[0], $self->{br}->[1]);
}

sub data {
  my $self = shift;
  if (defined(my $arg = shift)) {
    return $self->{data} = $arg;
  } else {
    return $self->{data};
  }
}

sub action {
  my $self = shift;
  my $subref = shift;

  push( @{$self->{_calls}}, $subref );
}

sub render {
  my $self = shift;

  foreach my $s (@{$self->{_calls}}) {
    $s->($self);
  }
  foreach my $child (@{$self->{_kids}}) {
    $child->render();
  }
}


1;
__END__

=pod

=head1 NAME

Data::Region - define hierarchical areas with behaviors

=head1 SYNOPSIS

    use Data::Region;
    
    $r = Data::Region->new( 8.5, 11, { data => PageObj->new() } );
    $r->data( PageObj->new() );
    
    foreach my $c ( $r->subdivide(2.5,3) ) {
      $a = $c->area(0.25,0.25, 2.25,2.75);
      $a2 = $c->area(0.25,0.25, -0.25,-0.25); # as offset from lower right
    
      ($t,$m,$b) = $a->split_vertical(2,5,1);     # sequential heights
      ($t,$m,$b) = $a->split_vertical_abs(0,2,7); # absolute offsets
      ($l,$r) = $a->split_horizontal(2); # $l gets width of 2, $r gets the rest
    
      my($x1,$y1,$x2,$y2) = $a->coords();
      my $data = $a->data(); # data inherits from parent, if not set
      $a->action( sub { $data->setfont("Times-Bold", 10);
    			$data->text($x1,$y1, "Some Text");
    			$data->line( $_[0]->coords() ); # the non-closure way
    		      } );
    }
    $r->render(); # heirarchically perform all the actions
    
    # Get some info about a region:
    ($w,$h) = ( $a->width(), $a->height() );
    ($x1,$y1, $x2,$y2) = $a->coords();
    ($x1,$y1) = $a->top_left();
    ($x2,$y1) = $a->top_right();
    ($x1,$y2) = $a->bottom_left();
    ($x2,$y2) = $a->bottom_right();


=head1 DESCRIPTION

Data::Region allows you to easily define a set of nested (2-dimensional)
areas, defined by related coordinates, and to associate actions with
them.  The actions can then be performed hierarchically from any root of
the tree.

Data::Region was written to provide an easy way to do simple page layout,
but has, perhaps, more general uses.


=head1 USAGE

=head2 Creating Data::Regions

The following methods allow you to create Data::Regions, and
Data::Regions within Data::Regions (from whence it's turtles all the
way down).

=over 4

=item  new( $width, $height, [ \%options ] )

Creates a new (root) Data::Region object with the given width and height.
The coordinates of this Data::Region are screen-oriented, so they range from
(0,0) in the top left corner to ($width,$height) in the lower right
corner.

The final argument, if given, is a hashref of options.  Currently the
only supported option is 'data'.

=over 4

=item data

This option takes a reference to a data object.  This Data::Region and all
regions creted under it have access to this reference via the
C<data()> method.  Child Data::Regions created under this one automatically
inherit this reference as their own 'data', but can override it for
themselves if desired.

=back

=item  $r->area( $topleft_x, $topleft_y, $botright_x, $botright_y )

Creates a sub-region of Data::Region C<$r>.  The corner coordinates of this
area are relative to C<$r>'s coordinates, so for example

  $r->area( 1,1, 2,2 );

creates an area whose top left coordinate is offset (1,1) from the top
left coordinate of C<$r>, and whose bottom right coordinate is offset
(2,2), also from C<$r>'s top left corner.  In this case, if the
corners of C<$r> were (5,5)-(10,10), the created area would have
corners (6,6)-(7,7).

If you specify (either or both coordinates of) the bottom right corner
as negative numbers, the area's bottom right corner will be offset
from the parent Data::Region's bottom right corner.  For example

  $r->area( 1,1, -1,-1 );

Given the same parent region as the previous example, this would
create an area with corners (6,6)-(9,9).

C<area()> returns a new Data::Region object.

=item  $r->subdivide( $width, $height )

Tiles the parent Data::Region into areas of the given dimensions.
C<subdivide()> will try to fit as many in as possibly, but will return
only whole areas and so the returned areas might not cover the entire
parent region.  The first area created will be in the top left-most
corner of the parent region, and proceeds in a left-to-right,
top-to-bottom manner while space remains.

For example, if C<$r> has width of 8.5 and height of 11, this

  @a = $r->subdivide( 2.5, 3 );

returns 9 new Data::Regions into C<@a> (int(8.5/2.5)=3, int(11/3)=3, 3*3=9).

C<subdivide()> returns a list of new Data::Region objects.

=item  $r->split_vertical( $height1, $height2, $height3, ... )

Creates a set of child areas tiled vertically into the parent Data::Region.
Each successive area is created with a height corresponding to the
given argument, beginning at the top of the parent region and
proceeding downwards.  If the given heights do not fill the entire
area of the parent region, a final area is returned which covers the
remaining space.  The list of heights may proceed beyond the bottom of
the parent region.

For example, if C<$r> has corners at (5,5)-(10,10), this

  ($a,$b,$c,$d) = $r->split_vertical( 2, 0.5, 1 );

creates the following: C<$a> is (5,5)-(10,7), C<$b> is (5,7)-(10,7.5),
C<$c> is (5,7.5)-(10,8.5), and C<$d> gets all the rest
(5,8.5)-(10,10).

C<split_vertical()> returns a list of new Data::Region objects.

=item  $r->split_vertical_abs( @offsets )

Similar to C<split_vertical()>, but the arguments specify
Y-coordinates of successive top-left corners, instead of heights
(relative to the parent Data::Region).  The first argument does not need to
be 0.

C<split_vertical_abs()> returns a list of new Data::Region objects.

=item  $r->split_horizontal( $width1, $width2, $width3, ... )

Similar to C<split_vertical()>, except tiled child areas are created
left-to-right, instead of top-to-bottom.

C<split_horizontal()> returns a list of new Data::Region objects.

=item  $r->split_horizontal_abs( @offsets )

To C<split_horizontal()> as C<split_vertical_abs()> is to
C<split_vertical()>. 

C<split_horizontal_abs()> returns a list of new Data::Region objects.

=back


=head2 Finding out about Data::Regions

The following methods allow you to query Data::Region objects for data about
the areas they represent.

=over 4

=item  $r->coords()

Returns the coordinates of the corners of this Data::Region.  The list
returned is (top-left-X, top-left-Y, bottom-right-X, bottom-right-Y).

=item  $r->width()

Returns the width of this Data::Region (the difference between the Y
coordinates of the top-left and bottom-right corners).

=item  $r->height()

Returns the height of this Data::Region (the difference between the X
coordinates of the top-left and bottom-right corners).

=item  $r->top_left()

Returns a list of the X and Y coordinates for the top left corner of
this Data::Region.

=item  $r->top_right

Returns a list of the X and Y coordinates for the top right corner of
this Data::Region.

=item  $r->bottom_right

Returns a list of the X and Y coordinates for the bottom right corner of
this Data::Region.

=item  $r->bottom_left

Returns a list of the X and Y coordinates for the bottom left corner of
this Data::Region.

=back


=head2 Associating behavior with Data::Regions

The following methods allow you to associate data and callbacks to a
tree of Data::Regions, and to request a Data::Region to perform its tree of
callbacks. 

=over 4

=item  $r->data( [$reference] )

Returns, and optionally sets, the C<data> reference associated with
this Data::Region.  Any child regions created under this Data::Region inherit the
reference of their parent (at the time they are created).

C<data()> returns the a reference for the current 'data' field.

=item  $r->action( $coderef )

Associates an action with this Data::Region, to be performed when this
Data::Region's, or an ancestor Data::Region of this Data::Region's, C<render()> method
is called.

The argument is a code reference, which will be called with the Data::Region
object as its parameter.  So for example, you may do

  $r->action( sub {
                my $self = shift;
                # ...$self is the same obj as $r when this is run
              } );

A Data::Region may have any number of actions.  Actions will be executed in
the order that they were assocaited with C<action()>.

=item  $r->render()

Performs the actions associated with this Data::Region, and all of its
child Data::Regions.

Actions are performed for this region first, then for all of its
children recursively.  For each Data::Region, actions are performed in the
order that they were added to that Data::Region.  The order in which child
Data::Regions are recursed into is undefined, but is probably the same as
the order they were created in (eg, that's the way it currently works,
but is subject to change).

=back


=head1 INTERNAL METHODS

The following should be used only within the module itself.

=over 4

=item  $r->_init( @args )

Performs object initialization.  Called by C<new()>, the purpose of
this method is to separate initialization logic from object-creation
gruntwork.  If you subclass this module, it should be sufficient to
override C<_init()> rather than C<new()>.

The list of arguments passed to C<new()> are provided.

C<_init()> returns nothing.

=item  $r->_spawn( $x,$y, $width, $height )

Creates a child Data::Region inside C<$r>, using the given absolute
coordinates and dimensions.  This method handles maintenence of the
parent's list of children, and the new children's attribute
inheritance from the parent.  C<_spawn()> is used by all the Data::Region
creation methods (except C<new()>).

C<_spawn()> returns a new Data::Region object.

=back


=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
