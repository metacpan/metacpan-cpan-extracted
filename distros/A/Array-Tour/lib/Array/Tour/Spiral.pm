package Array::Tour::Spiral;

use 5.008;
use strict;
use warnings;
use integer;
use base q(Array::Tour);
use Array::Tour qw(:directions :status);

our $VERSION = '0.06';

=head1 NAME

Array::Tour::Spiral - Return coordinates to take a spiral path.

=head1 SYNOPSIS

  use Array::Tour::Spiral qw(:directions);

  my $spiral = Array::Tour::Spiral->new(
      dimensions => [5, 5],
      counterclock => $counterclock,
      corner_right => $corner_right,
      corner_bottom => $corner_bottom
      inward => $inward);

Creates the object with its attributes. The attributes are:

=over 4

=item dimensions

Set the size of the grid:

	my $spath1 = Array::Tour::Spiral->new(dimensions => [16, 16]);

If the grid is going to be square, a single integer is sufficient:

	my $spath1 = Array::Tour::Spiral->new(dimensions => 16);

=item counterclock corner_bottom corner_right inward

I<Default values: 0.> All are boolean values that affect the starting
point and the direction of the spiral path. By default, the spiral is
generated outwards from the center, using the upper left corner (if
there is a choice), in a clockwise direction. See the Examples section
to see what effects the different combinations produce.

=back

=head1 PREREQUISITES

Perl 5.8 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

A simple iterator that will return the coordinates of the next cell if
one were to tour a matrice's cells in a spiral path.

=head2 Spiral Object Methods

=head3 direction

$dir = $tour->direction()

Return the direction we just walked.

Overrides Array::Tour's direction() method.

=cut

sub direction()
{
	my $self = shift;
	return ($self->{status} == STOP)? undef: ${$self->{direction}}[0];
}

=head3 next()

Returns an array reference to the next coordinates to use. Returns
undef if there is no next cell to visit.

    my $ctr = 1;
    my $tour = Array::Tour::Spiral->new(dimensions => 64);

    while (my $cref = $tour->next())
    {
        my($x_coord, $y_coord, $z_coord) = @{$cref};
        $grid[$y_coord, $x_coord] = isprime($ctr++);
    }

The above example generates Ulam's Spiral
L<http://en.wikipedia.org/wiki/Ulam_spiral> in the array @grid.

Overrides Array::Tour's next() method.

=cut

sub next()
{
	my $self = shift;

	return undef unless ($self->has_next());

	#
	# Set up the conditions for the pacing.
	# The first pacing value is incremented by one for inward
	# spirals because by the time it is used for the second time
	# it won't be shortened by a perpendicular branch of the walk.
	#
	if ($self->{tourstatus} == START)
	{
		$self->{tourstatus} = TOURING;
		$self->{pacer} = ${$self->{pacing}}[0];
		${$self->{pacing}}[0] += 1 if ($self->{inward});
	}
	else
	{
		#
		# Pace off in the current direction.
		#
		my $direction = ${$self->{direction}}[0];
		${$self->{position}}[(($direction & (North | South)) == 0)? 0: 1] +=
			(($direction & (North | West)) == 0)? 1: -1;

		#
		# Will the next pace be in a different direction?
		#
		if (--$self->{pacer} == 0)
		{
			$self->{pacer} = ${$self->{pacing}}[1];
			${$self->{pacing}}[0] += $self->{pacechange};
	
			#
			# Rotate to the next pacing length and the next direction.
			#
			push @{$self->{pacing}}, shift @{$self->{pacing}};
			push @{$self->{direction}}, shift @{$self->{direction}};
		}

	}

	$self->{tourstatus} = STOP if (++$self->{odometer} == $self->{tourlength});
	return $self->adjusted_position();
}

=head3 anti_spiral()

  $larips = $spiral->anti_spiral();

Return a new object that follows the same path as the original object,
reversing the inward/outward direction.

=cut

sub anti_spiral()
{
	my $self = shift;
	my %anti_self;
	my @dimensions = @{ $self->{dimensions} };

	$anti_self{dimensions} = $self->{dimensions};
	$anti_self{counterclock} = $self->{counterclock} ^ 1;
	$anti_self{inward} = $self->{inward} ^ 1;

	my $width = $dimensions[0];
	my $height = $dimensions[1];

	if ($width == $height)
	{
		my $is_even = $height & 1;
		$anti_self{corner_right} = $is_even ^ $self->{counterclock} ^ $self->{corner_bottom} ^ 1;
		$anti_self{corner_bottom} = $is_even ^ $self->{counterclock} ^ $self->{corner_right};
	}
	elsif ($width > $height)
	{
		my $is_even = $height & 1;
		$anti_self{corner_right} = $is_even ^ $self->{corner_right};
		$anti_self{corner_bottom} = $is_even ^ $self->{counterclock} ^ $self->{corner_bottom};
	}
	else #$width < $height
	{
		my $is_even = $width & 1;
		$anti_self{corner_right} = $is_even ^ $self->{counterclock} ^ $self->{corner_right};
		$anti_self{corner_bottom} = $is_even ^ $self->{corner_bottom};
	}

	return Array::Tour::Spiral->new(%anti_self);
}

=head3 _set()

  $self->_set(%parameters);

  Override Array::Tour's _set() method for one that can handle
  our parameters.
=cut

sub _set()
{
	my $self = shift;
	my(%params) = @_;

	warn "Unknown paramter $_" foreach (grep{$_ !~ /inward|counterclock|corner_right|corner_bottom/} (keys %params));

	#
	# Set counterclock, corner_right, corner_bottom, and inward
	# to 0/1 values.
	#
	$self->{counterclock} = (defined $params{counterclock} and $params{counterclock} != 0)? 1: 0;
	$self->{corner_right} = (defined $params{corner_right} and $params{corner_right} != 0)? 1: 0;
	$self->{corner_bottom} = (defined $params{corner_bottom} and $params{corner_bottom} != 0)? 1: 0;
	$self->{inward} = (defined $params{inward} and $params{inward} != 0)? 1: 0;

	return $self->_set_inward() if ($self->{inward} == 1);
	return $self->_set_outward();
}

=head3 _set_inward()

  $self->_set_inward();

  Set the attributes knowing that the spiral path goes inward.
=cut

sub _set_inward()
{
	my $self = shift;
	my @dimensions = @{ $self->{dimensions} };
	my $width = $dimensions[0];
	my $height = $dimensions[1];
	my $counterclock = $self->{counterclock};
	my $corner_bottom = $self->{corner_bottom};
	my $corner_right = $self->{corner_right};
	my $pace_x = $width - 1;
	my $pace_y = $height - 1;
	my @direction = (East, South, West, North);
	my($start_x, $start_y) = (0, 0);
	my $rotate;

	$self->{pacechange} = -1;
	$start_x = $width - 1 if ($corner_right);
	$start_y = $height - 1 if ($corner_bottom);

	$rotate = ($corner_bottom << 1) | ($corner_bottom ^ $corner_right);
	$rotate ^= 2 if ($counterclock);
	push @direction, splice(@direction, 0, $rotate);
	@direction = reverse @direction if ($counterclock);

	$self->{direction} = \@direction;
	$self->{pacing} = (($direction[0] & (West | East)) == 0)? [$pace_y, $pace_x]: [$pace_x, $pace_y];
	$self->{start} = [$start_x, $start_y];
	$self->{position} = [$start_x, $start_y];
	$self->{rotate} = $rotate;

	return $self;
}

=head3 _set_outward()

  $self->_set_outward();

  Set the attributes knowing that the spiral path goes outward.
=cut

sub _set_outward()
{
	my $self = shift;
	my @dimensions = @{ $self->{dimensions} };
	my $width = $dimensions[0];
	my $height = $dimensions[1];
	my $counterclock = $self->{counterclock};
	my $corner_bottom = $self->{corner_bottom};
	my $corner_right = $self->{corner_right};
	my($pace_x, $pace_y) = (1, 1);
	my @direction = (East, South, West, North);
	my($start_x, $start_y, $rotate);

	$self->{pacechange} = 1;

	#
	# Find the starting corner.
	#
	$start_x = ($width-1)/2;
	$start_y = ($height-1)/2;

	if ($width == $height)
	{
		#
		# Adjust the starting corner if it's an even side.
		#
		if (($width & 1) == 0)
		{
			$start_x++ if ($corner_right);
			$start_y++ if ($corner_bottom);
		}

		#
		# Circling clockwise from top left to bottom left the
		# corner flags are [00], [01], [11], [10].  In other
		# words, a two bit Gray code that converts to 0..3,
		# which we'll use to rotate the direction list.
		#
		$rotate = ($corner_bottom << 1) | ($corner_bottom ^ $corner_right);
		$rotate ^= 2 if ($counterclock);
	}
	elsif ($width > $height)	# X-axis is the major axis.
	{
		$pace_x += $width - $height;
		$start_x = $start_y;

		if (($corner_right ^ $corner_bottom) == 1)
		{
			$pace_x--;
			$start_x++ if (($height & 1) == 0);
		}

		$start_x = ($width - 1) - $start_x if ($corner_right);

		$start_y++ if (($height & 1) == 0 and ($corner_right ^ $counterclock) == 1);

		$rotate = $corner_right << 1;
		$rotate ^= 1 if ($counterclock);
	}
	else		# Y-axis is the major axis.
	{
		$pace_y += $height - $width;
		$start_y = $start_x;

		if (($corner_bottom ^ $corner_right) == 1)
		{
			$pace_y--;
			$start_y++ if (($width & 1) == 0);
		}

		$start_y = ($height - 1) - $start_y if ($corner_bottom);

		$start_x++ if (($width & 1) == 0 and ($corner_bottom ^ $counterclock) == 0);

		$rotate = ($corner_bottom << 1) | 1;
		$rotate ^= 3 if ($counterclock);
	}

	push @direction, splice(@direction, 0, $rotate);
	@direction = reverse @direction if ($counterclock);

	$self->{direction} = \@direction;
	$self->{pacing} = (($direction[0] & (West | East)) == 0)? [$pace_y, $pace_x]: [$pace_x, $pace_y];
	$self->{start} = [$start_x, $start_y];
	$self->{position} = [$start_x, $start_y];
	$self->{rotate} = $rotate;

	return $self;
}
1;
__END__

=head2 Example: A Spiral Tour of the Square

The four by four case demonstrates the different possible spiral arrangements.
There are four possible central positions. By default, the spiral will
begin in the top left corner, but the options C<corner_bottom> and
C<corner_right> can force the starting point to a different corner of
the square.

The results below show the results of the four different combinations of
($corner_bottom, $corner_right), traveling clockwise. The characters
S<'a' .. 'p'> were drawn in order to show the path of the spiral:

      (0,0)     (0,1)     (1,1)     (1,0)
      ghij      pefg      mnop      jklm
      fabk      odah      lcde      ibcn
      edcl      ncbi      kbaf      hado
      ponm      mlkj      jihg      gfep

What if the grid is five by five? With both dimensions odd, there is no
left/right or top/bottom corner. There are still four possible paths to
take though, as shown using the characters S<'a' .. 'y'>:

       (0,0)      (0,1)      (1,1)      (1,0)
       uvwxy      qrstu      mnopq      yjklm
       tghij      pefgv      lcder      xibcn
       sfabk      odahw      kbafs      whado
       redcl      ncbix      jihgt      vgfep
       qponm      mlkjy      yxwvu      utsrq

Even though there is only one center square, the spiral path takes the
same starting direction as the spiral on the four by four square does.

=head2 Example: The Spiral Tour of the Rectangle

Some of our assumptions go awry if width does not equal height. If the
shorter of the two dimensions is even, the starting corner does not
always go where one expects. Here are some examples.

=head1 AUTHOR

John M. Gamble may be found at <jgamble@cpan.org>

=cut
