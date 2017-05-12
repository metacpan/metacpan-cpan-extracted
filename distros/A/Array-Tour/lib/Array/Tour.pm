=head1 NAME

Array::Tour - Base class for Array Tours.

=head1 SYNOPSIS

  #
  # For a new package.  Add extra methods and internal attributes afterwards.
  #
  package Array::Tour::NewTypeOfTour
  use base qw(Array::Tour);
  
  # (Code goes here).

or

  #
  # Make use of the constants in the package. 
  #
  use Array::Tour qw(:directions);
  use Array::Tour qw(:status);

or

  #
  # Use Array::Tour for its default 'typewriter' tour of the array.
  #
  use Array::Tour;
  
  my $by_row = Array::Tour->new(dimensions => [24, 80, 1]);
  

=head1 PREREQUISITES

Perl 5.8 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

Array::Tour is a base class for iterators that traverse the cells of an
array. This class should provide most of the methods needed for any type
of tour, whether it needs to visit each cell or not, and whether
the tour needs to be a continuous path or not.

The iterator provides coordinates and directions.  It does not define
the array.  This leaves the user of the tour object free to
define the form of the array or the data structure behind it without
restrictions from the tour object.

By itself without any subclassing or options, the Array::Tour class traverses a
simple left-to-right, top-to-bottom typewriter path. There are options to change
the direction or rotation of the path.

=cut

package Array::Tour;
use 5.008;
use strict;
use warnings;
use integer;

use vars qw(@ISA);
require Exporter;

@ISA = qw(Exporter);

use vars qw(%EXPORT_TAGS @EXPORT_OK);
%EXPORT_TAGS = (
	'directions' => [ qw ( NoDirection
		North NorthWest West SouthWest Ceiling
		South SouthEast East NorthEast Floor
		SetPosition
	)],
	'status' => [ qw (START TOURING STOP)]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'directions'} }, @{ $EXPORT_TAGS{'status'} } );

our $VERSION = '0.06';

#
# Directions.
#
# The eight possible directions that one can move from a cell, including
# "null" direction NoDirection, and position change indicator SetPosition.
#
use constant NoDirection => 0x0000;
use constant North       => 0x0001;	# 0;
use constant NorthWest   => 0x0002;	# 1;
use constant West        => 0x0004;	# 2;
use constant SouthWest   => 0x0008;	# 3;
use constant Ceiling     => 0x0010;	# 4;
use constant South       => 0x0020;	# 5;
use constant SouthEast   => 0x0040;	# 6;
use constant East        => 0x0080;	# 7;
use constant NorthEast   => 0x0100;	# 8;
use constant Floor       => 0x0200;	# 9;
use constant SetPosition => 0x8000;	# 15;

#
# {tourstatus} constants.
#
use constant START	=> 0;
use constant TOURING	=> 1;
use constant STOP	=> 2;


=head2 Tour Object Methods

=head3 new([<attribute> => value, ...])

Creates the object with its attributes.

With the exception of C<dimensions> and C<offest>, attributes are set using the
internal method _set(). This means that subclasses should not override new(),
but instead provide their own _set() method to handle their own attributes.

In addition to C<dimensions> and C<offeset>, new() also creates internal
attributes that may be used by subclasses. See the Attributes section for more
details.

=cut

sub new
{
	my $class = shift;
	my $self = {};

	#
	# We are copying from an existing Tour object?
	#
	if (ref $class)
	{
		if ($class->isa("Array::Tour"))
		{
			$class->_copy($self, @_);
			return bless($self, ref $class);
		}

		warn "Attempts to create an Array Touring object from a '",
			ref $class, "' object fail.\n";
		return undef;
	}

	#
	# Starting from scratch.
	#
	bless($self, $class);
	my %attributes = @_;
	$self->_set_dimensions(%attributes);
	$self->_set_offset(%attributes);
	delete @attributes{qw(dimensions offset)};
	$self->{position} = [0, 0, 0];
	$self->{start} = [0, 0, 0];
	$self->{array} = undef;
	$self->{tourlength} = 1;
	map {$self->{tourlength} *= $_} $self->get_dimensions();
	$self->{tourstatus} = START;
	$self->{odometer} = 0;
	$self->_set(%attributes);

	return $self;
}

=head3 reset()

  $tour->reset([<attribute> => value, ...])

Reset the object by returning its internal state to its original form.
Optionally change some of the characteristics using the same parameters
found in the new() method.

=cut

sub reset
{
	my $self = shift;
	my %newargs = @_;

	my %params = $self->describe();
	$params{position} = [0, 0, 0];
	$params{tourlength} = 1;
	$params{tourstatus} = START;
	$params{odometer} = 0;
	$params{array} = undef if ($self->_uses_array());

	#
	# Apply any options passed in.
	#
	map {$params{$_} = $newargs{$_}} keys %newargs;

	return $self->_set(%params);
}

=head3 has_next()

Returns 1 if there is more to the tour, 0 if finished.

=cut

sub has_next
{
	my $self = shift;
	return ($self->{tourstatus} == STOP)? 0: 1;
}

=head3 get_dimensions()

Returns an array of the dimensions.

=cut

sub get_dimensions
{
	my $self = shift;
	return @{$self->{dimensions}};
}

=head3 direction()

Returns the current direction as found in the :directions EXPORT tag.

=cut

sub direction
{
	my $self = shift;
	return (${$self->{position}}[0] == 0)? NoDirection: East;
}

=head3 opposite_direction()

Return the direction opposite from the current direction.

=cut

sub opposite_direction
{
	my $self = shift;
	my $dir = $self->direction();
	return NoDirection if ($dir == NoDirection);
	return ($dir <=  Ceiling )? ($dir << 5): ($dir >> 5);
}

=head3 say_direction()

Return the name in English of the current direction.

=cut

sub say_direction
{
	my $self = shift;
	my $dir = $self->direction();

	return $self->direction_name($dir);
}

=head3 direction_name()

Return the name in English of the direction passed in.

   print $tour->direction_name(NorthWest), " is ", NorthWest, "\n";

=cut

sub direction_name
{
	my $self = shift;
	my($dir) = @_;

	return q(NoDirection) if ($dir == NoDirection);
	return q(North) if ($dir == North);
	return q(NorthWest) if ($dir == NorthWest);
	return q(West) if ($dir == West);
	return q(SouthWest) if ($dir == SouthWest);
	return q(Ceiling) if ($dir == Ceiling);
	return q(South) if ($dir == South);
	return q(SouthEast) if ($dir == SouthEast);
	return q(East) if ($dir == East);
	return q(NorthEast) if ($dir == NorthEast);
	return q(Floor) if ($dir == Floor);
	if ($dir == SetPosition)
	{
		my @p = @{$self->get_position()};
		return q(SetPosition) . "[" . join(", ", @p) . "]";
	}

	return q(unknown direction);
};

=head3 get_position()

Return a reference to an array of coordinates of the current position.

    @absolute_pos = @{$self->get_position()};

=cut

sub get_position
{
	my $self = shift;
	return $self->{position};
}

=head3 get_offset()

Return a reference to an array of offsets to be added to the current position.

    @offset = @{$self->get_offset()};

=cut

sub get_offset
{
	my $self = shift;
	return $self->{offset};
}

=head3 adjusted_position()

Return a reference to an array of coordinates that are created from the position
plus the offset. Used by the next() method.

    @current_pos = @{$self->adjusted_position()};

=cut

sub adjusted_position
{
	my $self = shift;

	my @position = @{ $self->{position} };
	my @offset = @{ $self->{offset} };
	map {$position[$_] += $offset[$_]} (0..$#position);
	return \@position;
}

=head3 next()

Returns an array reference to the next coordinates to use. Returns
undef if the iterator is finished.

    my $ctr = 1;
    my $tour = Array::Tour->new(dimensions => 64);

    while (my $cref = $tour->next())
    {
        my($x_coord, $y_coord, $z_coord) = @{$cref};
        $grid[$y_coord, $x_coord] = isprime($ctr++);
    }

The above example would look like a completed Sieve of Eratothenes in the array
@grid.

=cut

sub next
{
	my $self = shift;

	return undef unless ($self->has_next());

	#
	# Set up the conditions for the pacing.
	#
	if ($self->{tourstatus} == START)
	{
		$self->{tourstatus} = TOURING;
	}
	else
	{
		#
		# Move to the next cell, checking to see if we've
		# reached the end of the row/plane/cube.
		#
		my($dim, $lastdim) = (0, scalar @{$self->{dimensions}});
		while ($dim < $lastdim and ${$self->{position}}[$dim] == ${$self->{dimensions}}[$dim] - 1)
		{
			${$self->{position}}[$dim++] = 0;
		}
		${$self->{position}}[$dim] += 1 unless ($dim == $lastdim);
	}

	$self->{tourstatus} = STOP if (++$self->{odometer} == $self->{tourlength});
	return $self->adjusted_position();
}

=head3 get_array()

Return a reference to the internally generated array.

    $arrayref = $self->get_array()

=cut

sub get_array
{
	my $self = shift;
	$self->_make_array() unless (defined $self->{array});
	return $self->{array};
}

=head3 describe()

Returns as a hash the attributes of the tour object. The hash may be
used to create a new object.

=cut

sub describe
{
	my $self = shift;
	return map {$_, $self->{$_}} grep(/^[a-z]/, keys %{$self});
}

=head2 Internal Tour Object Methods

=head3 _set_dimensions()

    my $tour = Array::Tour->new(dimensions => [12, 16]);

This works identically as

    my $tour = Array::Tour->new(dimensions => [12, 16, 1]);

If the grid is going to be square, a single integer is sufficient:

    my $tour = Array::Tour->new(dimensions => 16);

In both cases, the new() member funcntion calls _set_dimensions() and sets the
C<dimensions> attribute with a reference to a three dimensional array. The third
dimension is set to 1 if no value is given for it.

=cut

sub _set_dimensions
{
	my $self = shift;
	my(%params) = @_;
	my $dim = $params{dimensions} || [1, 1, 1];

	my @dimensions;

	if (ref $dim eq 'ARRAY')
	{
		@dimensions = map {$_ ||= 1} @{$dim};
		push @dimensions, 1 if (@dimensions < 1);
		push @dimensions, $dimensions[0] if (@dimensions < 2);
	}
	else
	{
		#
		# Square grid if only one dimension is defined.
		#
		@dimensions = ($dim) x 2;
	}
	push @dimensions, 1 if (@dimensions < 3);
	$self->{dimensions} = \@dimensions;

	return $self;
}

=head3 _set_offset()

The new() member funcntion calls _set_offset() and sets the C<offset> attribute
with a reference to an array of coordinates. This method matches the size of the
C<offset> array to the size of C<dimensions>, so _set_dimensions() must be called
beforhand.

=cut

sub _set_offset
{
	my $self = shift;
	my(%params) = @_;
	my $offsetref = $params{offset} || [0, 0, 0];

	$self->{offset} = $offsetref;

	my $dims = scalar @{$self->{dimensions}};
	my $offsets = scalar @{$self->{offset}};
	push @{$self->{offset}}, (0) x ($dims - $offsets) if ($dims > $offsets);
	return @{$self->{offset}};
}

=head3 _move_to()

	$position = $self->_move_to($direction);	# [$c, $r, $l]

Return a new position depending upon the direction taken. This does not set a
new position.

=cut

sub _move_to
{
	my $self = shift;
	my($dir) = @_;
	my($c, $r, $l) = @{ $self->{position} };

	--$r if ($dir & (North | NorthWest | NorthEast));
	++$r if ($dir & (South | SouthWest | SouthEast));
	++$c if ($dir & (East  | NorthEast | SouthEast));
	--$c if ($dir & (West  | NorthWest | SouthWest));
	++$l if ($dir & Floor);
	--$l if ($dir & Ceiling);
	return [$c, $r, $l];
}

=head3 _make_array()

	$self->_make_array();
or
	$self->_make_array($value);

Make an internal array for reference purposes. If no value to set the array cels
with is passed in, the array cells are set to zero by default.

=cut

sub _make_array
{
	my $self = shift;
	my $dflt = (scalar @_)? $_[0]: 0;
	my($cols, $rows, $lvls) = map {$_ - 1} @{$self->{dimensions}};

	my $m = $self->{array} = ([]);
	foreach my $l (0..$lvls)
	{
		foreach my $r (0..$rows)
		{
			foreach my $c (0..$cols)
			{
				$$m[$l][$r][$c] = $dflt;
			}
		}
	}
	return $self;
}

=head3 _set()

$self->_set(%attributes);

Take the parameters provided to new() and use them to set the
attributes of the touring object.

=cut

sub _set()
{
	my $self = shift;
	my(%params) = @_;

	warn "Unknown paramter $_" foreach (grep{$_ !~ /reverse/} (keys %params));
	return $self;
}

=head3 _uses_array()

Returns 0 or 1 depending upon whether there's an internal array to return.

=cut

sub _uses_array {my $self = shift; return 0;}

#
# dump_array
#
# @xlvls = $obj->dump_array($spr_fmt);
# $xstr = $obj->dump_array($spr_fmt);
#
# Returns a formatted string of all the cell values.  By default,
# the format string is " %04x", so the default output strings will
# be rows of hexadecimal numbers separated by a space.
#
# If called in a list context, returns a list of strings, each one
# representing a level. If called in a scalar context, returns a single
# string, each level separated by a single newline.
#
sub dump_array
{
	my $self = shift;
	my $format = $_[0] || " %04x";
	my($cols, $rows, $lvls) = map {$_ - 1} @{$self->{dimensions}};
	my $m = $self->{array};
	my @levels;

	foreach my $l (0..$lvls)
	{
		my $vxstr = "";
		foreach my $r (0..$rows)
		{
			foreach my $c (0..$cols)
			{
				$vxstr .= sprintf($format, $$m[$l][$r][$c]);
			}
			$vxstr .= "\n";
		}

		push @levels, $vxstr;
	}

	return wantarray? @levels: join("\n", @levels);
}

#
# $class->_copy($self);
#
# Duplicate the iterator.
#
sub _copy
{
	my($other, $self) = @_;
	foreach my $k (grep($_ !~ /_array/, keys %{$other}))
	{
		$self->{$k} = $other->{$k};
	}
	if ($other->uses_array())
	{
		# copy it.
	}
}

1;
__END__

=head2 Methods expected to be provided by the derived class.

The methods that will have to be written specifically for the individual tour of
the derived classe will will likely be:

=head3 next()

=head3 _set()

=head3 _uses_array()

=head2 Attributes

Array::Tour keeps track of its state through internal attributes that are
sufficient for its purposes. Derived classes may alter these for their own
purposes and will likely need to add attributes of their own.

=over 4

=item dimensions

I<Default value: [1, 1, 1].>  Set in the method new() using the dimensions
key, which in turn sets it through the set_dimensions() method.

  my $spath1 = Array::Tour->new(dimensions => [16, 16, 1]);
or
  my $spath1 = Array::Tour->new(dimensions => [16, 16]);

The dimensions attribute represents a three-dimensional array, defined by rows,
columns, and levels.  If you are interested only in a two-dimensional array,
you don't need to specify the third dimension -- it will be added on for you.

In fact the C<dimensions> attribute is so forgiving that if you are only
interested in a simple square array, this will be sufficient:

  my $spath1 = Array::Tour->new(dimensions => 16);

The attribute will detect the single dimension, duplicate it, and add the
third dimension of 1.  You will have the same dimensions as the previous
examples.

=item offset

I<Default value: [0, 0, 0].> Set in the method new() using the offset
key, which in turn sets it through the _set_offset() method.

Sets the coordinate of the upper left corner of the tour array. Calls to
adjusted_position() (which in turn is called by the next() method) will return
the position adjusted by the value in C<offset>.

=item start

I<Default value: [0, 0, 0].> The starting position of the tour.  Set
automatically in this class.

=item position

The current position of the iterator in the array.

=item odometer

I<Starting value: 0.> The number of cells visited thus far.

=item tourlength

I<Default value: number of cells in the array.> The total number of cells
to visit. This is sometimes used to determine the endpoint of the tour.

=item tourstatus

Initially set to B<START>.  The remaining _tourstatus values (found with
the export tag C<:status>) are B<TOURING> and B<STOP>.

=item array

I<default value: undef.>  A reference to an internal array.  Some sub-classes
need an internal array for bookkeeping purposes.  This is where it will go.
The method _make_array() will create an internal array for a sub-class if it is
needed.

=back

=head2 Current Tours

This, the base class, performs a typewriter left-to-right tour of the array. If
the array has a third dimension, it will go to the next level after completing
the tour of the rows of the current level.

The subclasses that come with this package are:

L<Spiral|Array::Tour::Spiral>

L<Serpentine|Array::Tour::Serpentine>

L<RandomWalk|Array::Tour::RandomWalk>

There may be other tours under development. See the Changes file for more
information.

=head2 EXPORT

The :directions tag will let you use the constants that indicate
direction. They are the directions C<North>, C<NorthEast>, C<East>,
C<SouthEast>, C<South>, C<SouthWest>, C<West>, C<NorthWest>, C<Ceiling>,
C<Floor>, and C<SetPosition>, which indicates a directionless change in
position.

The :status tag has the values for the running state of the iterator.

=head2 See Also

L<Array::Iterator|Array::Iterator>

=head1 AUTHOR

John M. Gamble may be found at <jgamble@cpan.org>

=cut
