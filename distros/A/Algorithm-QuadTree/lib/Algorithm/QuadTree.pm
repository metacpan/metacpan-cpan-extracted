package Algorithm::QuadTree;
$Algorithm::QuadTree::VERSION = '0.3';
use strict;
use warnings;
use Carp;

###############################
#
# Creating a new QuadTree objects automatically
# segments the given area into quadtrees of the
# specified depth.
#
# Arguments are a hash:
#
# -xmin  => minimum x value
# -xmax  => maximum x value
# -ymin  => minimum y value
# -ymax  => maximum y value
# -depth => depth of tree
#
###############################

BEGIN {
	require Algorithm::QuadTree::PP;
	my $backend = 'Algorithm::QuadTree::PP';

	my $check_backend = $ENV{ALGORITHM_QUADTREE_BACKEND} || 'Algorithm::QuadTree::XS';
	if (eval "require $check_backend; 1;") {
		$backend = $check_backend;
	}

	$backend->import;
}

sub new
{
	my $self  = shift;
	my $class = ref($self) || $self;
	my %args = @_;

	my $obj = bless {}, $class;

	for my $arg (qw/xmin ymin xmax ymax depth/) {
		unless (exists $args{"-$arg"}) {
			carp "- must specify $arg";
			return undef;
		}

		$obj->{uc $arg} = $args{"-$arg"};
	}

	$obj->{ORIGIN} = [0, 0];
	$obj->{SCALE} = 1;

	_AQT_init($obj);

	return $obj;
}

sub DESTROY
{
	my ($self) = @_;

	_AQT_deinit($self);
}

# modify coords according to window
sub _adjustCoords
{
	my ($self, @coords) = @_;

	if (@coords == 4) {
		# rectangle

		$_ = $self->{ORIGIN}[0] + $_ / $self->{SCALE}
			for $coords[0], $coords[2];
		$_ = $self->{ORIGIN}[1] + $_ / $self->{SCALE}
			for $coords[1], $coords[3];
	}
	elsif (@coords == 3) {
		# circle

		$coords[0] = $self->{ORIGIN}[0] + $coords[0] / $self->{SCALE};
		$coords[1] = $self->{ORIGIN}[1] + $coords[1] / $self->{SCALE};
		$coords[2] /= $self->{SCALE};
	}

	return @coords;
}

sub add
{
	my ($self, $object, @coords) = @_;

	# assume that $object is unique.
	# assume coords are (xmin, ymix, xmax, ymax) or (centerx, centery, radius)

	@coords = $self->_adjustCoords(@coords)
		unless $self->{SCALE} == 1;

	# if the object is rectangular, make sure the lower coordinate is always
	# the first one
	if (@coords == 4) {
		($coords[0], $coords[2]) = ($coords[2], $coords[0])
			if $coords[2] < $coords[0];

		($coords[1], $coords[3]) = ($coords[3], $coords[1])
			if $coords[3] < $coords[1];
	}

	_AQT_addObject($self, $object, @coords);

	return;
}

sub delete
{
	my ($self, $object) = @_;

	_AQT_delete($self, $object);

	return;
}

sub clear
{
	my $self = shift;

	_AQT_clear($self);

	return;
}

sub getEnclosedObjects
{
	my ($self, @coords) = @_;

	@coords = $self->_adjustCoords(@coords)
		unless $self->{SCALE} == 1;

	my @results = @{_AQT_findObjects($self, @coords)};

	# uniq results
	my %temp = map { $_ => $_ } @results;

	# PS. I don't check explicitly if those objects
	# are enclosed in the given area. They are just
	# part of the segments that are enclosed in the
	# given area. TBD.

	# get values of %temp, since keys are strings
	# even if they were references originally
	return [values %temp];
}

sub setWindow
{
	my ($self, $sx, $sy, $s) = @_;

	$self->{ORIGIN}[0] += $sx / $self->{SCALE};
	$self->{ORIGIN}[1] += $sy / $self->{SCALE};
	$self->{SCALE} *= $s;
}

sub resetWindow
{
	my $self = shift;

	$self->{ORIGIN}[$_] = 0 for 0 .. 1;
	$self->{SCALE} = 1;
}

1;

__END__

=head1 NAME

Algorithm::QuadTree - A QuadTree Algorithm class in pure Perl.

=head1 SYNOPSIS

    use Algorithm::QuadTree;

    # create a quadtree object
    my $qt = Algorithm::QuadTree->new(-xmin  => 0,
                                      -xmax  => 1000,
                                      -ymin  => 0,
                                      -ymax  => 1000,
                                      -depth => 6);

    # add objects randomly
    my $x = my $tag = 1;
    while ($x < 1000) {
      my $y = 1;
      while ($y < 1000) {
        $qt->add($tag++, $x, $y, $x, $y);

        $y += int rand 200;
      }
      $x += int rand 100;
    }

    # find the objects enclosed in a given region
    my $r_list = $qt->getEnclosedObjects(400, 300,
                                         689, 799);

=head1 DESCRIPTION

Algorithm::QuadTree implements a quadtree algorithm (QTA) in pure Perl.
Essentially, a I<QTA> is used to access a particular area of a map very quickly.
This is especially useful in finding objects enclosed in a given region, or
in detecting intersection among objects. In fact, I wrote this module to rapidly
search through objects in a L<Tk::Canvas> widget, but have since used it in other
non-Tk programs successfully. It is a classic memory/speed trade-off.

Lots of information about QTAs can be found on the web. But, very briefly,
a quadtree is a hierarchical data model that recursively decomposes a map into
smaller regions. Each node in the tree has 4 children nodes, each of which
represents one quarter of the area that the parent represents. So, the root
node represents the complete map. This map is then split into 4 equal quarters,
each of which is represented by one child node. Each of these children is now
treated as a parent, and its area is recursively split up into 4 equal areas,
and so on up to a desired depth.

Here is a somewhat crude diagram:

                   ------------------------------
                  |AAA|AAB|       |              |
                  |___AA__|  AB   |              |
                  |AAC|AAD|       |              |
                  |___|___A_______|      B       |
                  |       |       |              |
                  |       |       |              |
                  |   AC  |   AD  |              |
                  |       |       |              |
                   -------------ROOT-------------
                  |               |              |
                  |               |              |
                  |               |              |
                  |      C        |      D       |
                  |               |              |
                  |               |              |
                  |               |              |
                   ------------------------------

Which corresponds to the following quadtree:

                        __ROOT_
                       /  / \  \
                      /  /   \  \
                _____A_  B   C   D
               /  / \  \
              /  /   \  \
        _____AA  AB  AC  AD
       /  / \  \
      /  /   \  \
    AAA AAB AAC AAD

In the above diagrams I show only the nodes through the first branch of
each level. The same structure exists under each node. This quadtree has a
depth of 4.

Each object in the map is assigned to the nodes that it intersects. For example,
if we have an object that overlaps regions I<AAA> and I<AAC>, it will be
assigned to the nodes I<ROOT>, I<A>, I<AA>, I<AAA> and I<AAC>. Now, suppose we
want to find all the objects that intersect a given area. Instead of checking all
objects, we check to see which children of the ROOT node intersect the area. For
each of those nodes, we recursively check I<their> children nodes, and so on
until we reach the leaves of the tree. Finally, we find all the objects that are
assigned to those leaf nodes and check them for overlap with the initial area.

=head1 CLASS METHODS

The following methods are public:

=over 4

=item I<Algorithm::QuadTree>-E<gt>B<new>(I<options>)

This is the constructor. It expects the following options (all mandatory) and
returns an Algorithm::QuadTree object:

=over 8

=item -xmin

This is the X-coordinate of the bottom left corner of the area associated with
the quadtree.

=item -ymin

This is the Y-coordinate of the bottom left corner of the area associated with
the quadtree.

=item -xmax

This is the X-coordinate of the top right corner of the area associated with
the quadtree.

=item -ymax

This is the Y-coordinate of the top right corner of the area associated with
the quadtree.

=item -depth

The depth of the quadtree.

=back

=item I<$qt>-E<gt>B<add>(object, x0, y0, x1, y1)

This method is used to add objects in shape of rectangles to the tree. It has
to be called for every object in the map so that it can properly assigned to
the correct tree nodes. The first argument is an object reference or an
I<unique> ID for the object. The remaining 4 arguments define the outline of
the object (edge coordinates: left, bottom, right, top). This method will
traverse the tree and add the object to the nodes that it overlaps with.

NOTE: The method does B<NOT> check if the object references or IDs passed are
unique or not. It is up to you to make sure they are.

=item I<$qt>-E<gt>B<add>(object, x, y, radius)

Same as above, but for circular objects. C<x> and C<y> are coordinates of object's center.

NOTE: this method called with three coordinates treats the object as a circle,
and with four coordinates as a rectangle. You don't have to worry about
potential empty / undef values in your coordinates, as long as the number of
arguments is right. It will never treat C<< ->add('obj', 1, 2, 3, undef) >> as a
call to the circular version, and instead produce warnings about undef being
treated as a number, hinting you about the problem.

=item I<$qt>-E<gt>B<getEnclosedObjects>(x0, y0, x1, y1)

This method returns an B<array reference> of all the objects that are assigned
to the nodes that overlap the given rectangular area. The objects will be
returned in the exact form they were passed to C<< ->add >>.

=item I<$qt>-E<gt>B<getEnclosedObjects>(x, y, radius)

Same as above, but for circular areas. C<x> and C<y> are coordinates of area's center.

NOTE: this method called with three coordinates treats the object as a circle,
and with four coordinates as a rectangle. You don't have to worry about
potential empty / undef values in your coordinates, as long as the number of
arguments is right. It will never treat C<< ->getEnclosedObjects(1, 2, 3, undef) >>
as a call to the circular version, and instead produce warnings about
undef being treated as a number, hinting you about the problem.

=item I<$qt>-E<gt>B<delete>(object)

This method deletes the object from the tree.

=item I<$qt>-E<gt>B<clear>()

This method deletes all the objects from the tree. It allows to reuse the
(expensive to compute) tree structure whenever the tree needs to be repopulated.

=item I<$qt>-E<gt>B<setWindow>(x0, y0, scale)

This method is useful when you zoom your display to a certain segment of
the map. It sets the window to the given region such that any calls to
B<add> or B<getEnclosedObjects> will have its coordinates properly adjusted
before running. The first two coordinates specify the lower left coordinates
of the new window. The third coordinate specifies the new zoom scale.

NOTE: You are free, of course, to make the coordinate transformation yourself.

=item I<$qt>-E<gt>B<resetWindow>()

This method resets the window region to the full map.

=back

=head2 Backends

By default, the module uses L<Algorithm::QuadTree::PP>, which is the pure perl backend.

If you install L<Algorithm::QuadTree::XS>, the module will load and use that
instead. This behavior can be controlled by setting
L<ALGORITHM_QUADTREE_BACKEND> environmental variable to the package name, which
should be used as the backend.

I<Note: the environmental variable must be present before loading Algorithm::QuadTree for the first time>

	# will load pure perl backend regardless of XS availability
	$ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::PP';

	use Algorithm::QuadTree;

=head1 AUTHORS

Ala Qumsieh I<aqumsieh@cpan.org>

Currently maintained by Bartosz Jarzyna I<bbrtj.pro@gmail.com>

=head1 COPYRIGHTS

This module is distributed under the same terms as Perl itself.

