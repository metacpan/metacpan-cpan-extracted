
=head1 NAME

Array::Tour::RandomWalk - Return coordinates to take a random path.

=head1 SYNOPSIS

      use Array::Tour::RandomWalk qw(:directions);
  
      my $rndwalk = Array::Tour::RandomWalk->new(
          dimensions => [13, 7, 1],
	  start => [0, 0, 0]
	  backtrack => "queue",
	  );

The object is created with the following attributes:

=over 4

=item dimensions

Set the size of the grid:

	my $spath1 = Array::Tour->new(dimensions => [16, 16]);

If the grid is going to be square, a single integer is sufficient:

	my $spath1 = Array::Tour->new(dimensions => 16);

=item start

I<Default value: [0, 0, 0].> Starting point of the random walk.

=item backtrack

I<Default value: 'queue'.> Method of looking up cells to backtrack to. As the
random walk is made, cells where there were more than one direction to go are
stored in a list. When the random walk hits a dead end, it goes back to a cell
in the list. By default, the list is treated as a queue: the first cell on the
list is the first cell used.

If backtrack is set to 'stack', the list is treated as a stack: the last cell on
the list is the first cell used.

The final choice, 'random', will choose a cell at random from the list.

=back

The new() method is defined in the Array::Tour class.  Attributes unique to this
class are dealt with in its own _set() method.

=head1 PREREQUISITES

Perl 5.8 or later. This is the version of perl under which this module
was developed.

=head1 DESCRIPTION

A simple iterator that will return the coordinates of the next cell if
one were to randomly tour a matrix.

=cut
package Array::Tour::RandomWalk;
use 5.008;
use strict;
use warnings;
use integer;
use base q(Array::Tour);
use Array::Tour qw(:directions :status);

our $VERSION = '0.06';

=head3 direction()

Returns the current direction as found in the :directions EXPORT tag.

Overrides Array::Tour's direction() method.

=cut

sub direction()
{
	my $self = shift;
	return ($self->{tourstatus} == STOP)? NoDirection: $self->{direction};
}

=head2 Tour Object Methods

=head3 next()

Returns an array reference to the next coordinates to use.  Returns undef if
the object is finished.

Overrides Array::Tour's next() method.

=cut

sub next
{
	my $self = shift;

	return undef unless ($self->has_next());

	my @dir = $self->_collect_dirs();

#	print "Position => [", join(", ", @{$self->get_position()}), "]\n",
#		"Can go (", join(", ", (map{$self->direction_name($_)} @dir)), ")\n";
	#
	# There is a cell to break into.
	#
	if (@dir > 0)
	{
		my $p = $self->{position};

		#
		# If there were multiple choices, save it
		# for future reference.
		#
		push @{ $self->{plist} }, $p if (@dir > 1);

		#
		# Choose a wall at random and break into the next cell.
		#
		$self->{direction} = $self->{wander}->(\@dir, $p);
		$self->_break_through();
		++$self->{odometer};
	}
	else	# No place to go, back up.
	{
		if (@{ $self->{plist} } == 0)	# No place to back up, quit.
		{
			$self->{tourstatus} = STOP;
			return undef;
		}

		$self->{direction} = SetPosition;
		if ($self->{backtrack} eq 'stack')
		{
			$self->{position} = pop @{ $self->{plist} };
		}
		elsif ($self->{backtrack} eq 'random')
		{
			$self->{position} = splice @{ $self->{plist} }, rand @{ $self->{plist} }, 1;
		}
		else
		{
			$self->{position} = shift @{ $self->{plist} };
		}
	}

#	print "\n********\n", $self->dump_array(), "\n********\n";

	return $self->adjusted_position();
}

=head2 Internal Tour Object Methods

=head3 _set()

  $self->_set(%attributes);
  
Overrides Array::Tour's _set() method.

=cut
sub _set
{
	my $self = shift;
	my(%params) = @_;

	#
	# Parameter checks.
	#
	warn "Unknown paramter $_" foreach (grep{$_ !~ /backtrack|wander|start/} (keys %params));
	$params{start} ||= [0, 0, 0];
	$params{backtrack} ||= "queue";

	#
	# We've got the dimensions, now set up an array.
	#
	$self->_make_array();

	$self->{position} = $self->{start} = $params{start};
	$self->{wander} = $params{wander} || \&_random_dir;
	$self->{backtrack} = $params{backtrack};

	$self->{plist} = ();

	return $self;
}

=head3 _random_dir()

The default function used to perform the random walk.

The function may be overridden if a function is referenced in {wander}.  This
function will take two arguments, a reference the list of possible directions
to move to, and a reference to the position (an array of [column, row, level]).

=cut

sub _random_dir
{
	return ${$_[0]}[int(rand(@{$_[0]}))];
}

=head3 _collect_dirs()

  @directions = $obj->_collect_dirs($c, $r, $l);

Find all of our possible directions to wander through the array.
You are only allowed to go into not-yet-broken cells.  The directions
are deliberately accumulated in a counter-clockwise fashion.

=cut

sub _collect_dirs
{
	my $self = shift;
	my($c, $r, $l) = @{ $self->{position} };
	my $m = $self->get_array();
	my($c_siz, $r_siz, $l_siz) = map {$_ - 1} $self->get_dimensions();
	my @dir;

	#
	# Search for enclosed cells in a partially sorted order,
	# starting from North and going counter-clockwise (Ceiling
	# and Floor will always be pushed last).
	#
	push(@dir, North)    if ($r > 0 and $$m[$l][$r - 1][$c] == 0);
	push(@dir, West)     if ($c > 0 and $$m[$l][$r][$c - 1] == 0);
	push(@dir, South)    if ($r < $r_siz and $$m[$l][$r + 1][$c] == 0);
	push(@dir, East)     if ($c < $c_siz and $$m[$l][$r][$c + 1] == 0);
	push(@dir, Ceiling)  if ($l > 0 and $$m[$l - 1][$r][$c] == 0);
	push(@dir, Floor)    if ($l < $l_siz and $$m[$l + 1][$r][$c] == 0);
	return @dir;
}

=head3 _break_through()

=cut

sub _break_through
{
	my $self = shift;
	my $dir = $self->{direction};
	my($c, $r, $l) = @{$self->{position}};
	my $m = $self->get_array();

	$$m[$l][$r][$c] |= $dir;
	($c, $r, $l) = @{$self->_move_to($dir)};
	$$m[$l][$r][$c] |= $self->opposite_direction($dir);
	$self->{position} = [$c, $r, $l];
}

1;
__END__

=head2 See Also

L<Array::Tour|Array::Tour>
L<Games::Maze|Games::Maze>

=head1 AUTHOR

John M. Gamble may be found at <jgamble@cpan.org>

=cut
