package Array::Tour::Serpentine;

use 5.008;
use strict;
use warnings;
use integer;
use base q(Array::Tour);
use Array::Tour qw(:directions :status);

our $VERSION = '0.06';

=head1 NAME

Array::Tour::Serpentine - Return coordinates to take a serpentine path.

=head1 SYNOPSIS

  use Array::Tour::Serpentine qw(:directions);

  my $tour = Array::Tour::Serpentine->new(
      dimensions => [5, 5],
      vertical => $vertical,
      corner_right => $corner_right,
      corner_bottom => $corner_bottom);

Creates the object with its attributes. The attributes B<dimensions>,
B<offset>, B<start>, and B<position> are inherited from L<Array::Tour>.
This package adds more attributes of its own, which are:

=over 4

=item counterclock, corner_bottom, corner_right, vertical

I<Default values: 0.> All are boolean values that affect the starting
point and the direction of the tour. By default, the tour is
generated the upper left corner in a horizontal back-and-forth path.

See the Examples section
to see what effects the different combinations produce.

=back

=head1 PREREQUISITES

Perl 5.8 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

A simple iterator that will return the coordinates of the next cell if
one were to tour an array's cells in a serpentine path.

=head2 Serpentine Object Methods


=head3 direction()

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

Returns a reference to an array of coordinates.  Returns undef
if there is no next cell to visit.

Overrides Array::Tour's next() method.

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
		$self->{pacer} = ${$self->{pacing}}[0];
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

=head3 opposite()

  $ruot = $tour->opposite();

Return a new object that follows the same path as the original object,
reversing the inward/outward direction.


=cut

sub opposite()
{
	my $self = shift;
	my %anti_self;
	my @dimensions = @{ $self->{dimensions} };

	$anti_self{dimensions} = $self->{dimensions};

	$anti_self{corner_right} ^=  1;
	$anti_self{corner_bottom} ^= 1;

	return Array::Tour::Serpentine->new(%anti_self);
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
	my($pace_x, $pace_y) = (1, 1);
	my($start_x, $start_y) = (0, 0);
	my @dirlist = (East, South, West, North);
	my @dimensions = @{$self->{dimensions}};
	my @direction;

	warn "Unknown paramter $_" foreach (grep{$_ !~ /vertical|corner_right|corner_bottom/} (keys %params));

	#
	# Parameter checks.
	#
	# Set corner_right, corner_bottom, and vertical to 0/1 values.
	#
	my $vertical = (defined $params{vertical} and $params{vertical} != 0)? 1: 0;
	my $corner_right = (defined $params{corner_right} and $params{corner_right} != 0)? 1: 0;
	my $corner_bottom = (defined $params{corner_bottom} and $params{corner_bottom} != 0)? 1: 0;

	$pace_x = $dimensions[0] - 1 unless ($vertical);
	$pace_y = $dimensions[1] - 1 if ($vertical);
	$start_x = $dimensions[0] - 1 if ($corner_right);
	$start_y = $dimensions[1] - 1 if ($corner_bottom);

	my $idx0 = ((($corner_bottom & $vertical)|
	            ($corner_right & ($vertical^1))) << 1) | $vertical;
	my $idx1 = ((($corner_bottom & ($vertical^1))|
	            ($corner_right & $vertical)) << 1) | ($vertical ^ 1);
	push @direction, @dirlist[$idx0, $idx1, $idx0 ^ 2, $idx1];

	$self->{corner_right} = $corner_right;
	$self->{corner_bottom} = $corner_bottom;
	$self->{vertical} = $vertical;
	$self->{direction} = \@direction;
	$self->{pacechange} = 0;
	$self->{pacing} = (($direction[0] & (West | East)) == 0)? [$pace_y, $pace_x]: [$pace_x, $pace_y];
	$self->{start} = [$start_x, $start_y];
	$self->{position} = [$start_x, $start_y];

	return $self;
}

1;
__END__


=head2 Example: A Serpentine Tour of the Square

The four by four case demonstrates the different possible arrangements.
There are four possible central positions. By default, the tour will
begin in the top left corner, but the options C<corner_bottom> and
C<corner_right> can force the starting point to a different corner of
the square.


=head2 EXPORT

The :directions and :status EXPORT tags are available, as defined in L<Array::Tour>.

=head2 See Also


=head1 AUTHOR

John M. Gamble may be found at <jgamble@cpan.org>

=cut
