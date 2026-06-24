package Algorithm::QuadTree::PP;
$Algorithm::QuadTree::PP::VERSION = '1.0';
use strict;
use warnings;
use Exporter qw(import);

use Scalar::Util qw(weaken);

our @EXPORT = qw(
	_AQT_init
	_AQT_deinit
	_AQT_addObject
	_AQT_findObjects
	_AQT_delete
	_AQT_clear
);

use constant UNIQUE_RESULTS => 1;

use constant SHAPE_CIRCLE => 1;
use constant SHAPE_RECTANGLE => 2;

sub _buildShape
{
	my (@coords) = @_;
	pop @coords while @coords > 4;

	my $shape_type = @coords == 3 ? SHAPE_CIRCLE : SHAPE_RECTANGLE;

	# pre-calculate some of the circle characteristics
	if ($shape_type == SHAPE_CIRCLE) {
		my $contained_radius = $coords[2] / sqrt(2);

		# inner box for this circle - fully contained within the circle
		unshift @coords, (
			$coords[0] - $contained_radius,
			$coords[1] - $contained_radius,
			$coords[0] + $contained_radius,
			$coords[1] + $contained_radius,
		);

		# avoid squaring the radius on each iteration
		$coords[7] = $coords[6] ** 2;
	}

	# -1 is always shape type. We use array for speed.
	push @coords, $shape_type;
	return \@coords;
}

sub _shapesOverlap
{
	my ($s1, $s2) = @_;
	my $type = $s1->[-1];

	# same element
	if ($type == $s2->[-1]) {
		if ($type == SHAPE_CIRCLE) {
			my $dist_x = $s1->[4] - $s2->[4];
			my $dist_y = $s1->[5] - $s2->[5];
			my $diagonal = $s1->[6] + $s2->[6];

			return $dist_x ** 2 + $dist_y ** 2
				<= $diagonal ** 2;
		}
		elsif ($type == SHAPE_RECTANGLE) {
			return $s1->[0] <= $s2->[2] &&
				$s1->[2] >= $s2->[0] &&
				$s1->[1] <= $s2->[3] &&
				$s1->[3] >= $s2->[1];
		}
	}

	# different elements - circle first
	($s1, $s2) = ($s2, $s1)
		unless $type == SHAPE_CIRCLE;

	my $cx = $s1->[4] < $s2->[0]
		? $s2->[0] - $s1->[4]
		: $s1->[4] > $s2->[2]
			? $s2->[2] - $s1->[4]
			: 0
	;

	my $cy = $s1->[5] < $s2->[1]
		? $s2->[1] - $s1->[5]
		: $s1->[5] > $s2->[3]
			? $s2->[3] - $s1->[5]
			: 0
	;

	return $cx ** 2 + $cy ** 2
		<= $s1->[7];
}

sub _shapeContained
{
	my ($inner_s, $s) = @_;

	return $s->[0] <= $inner_s->[0] &&
		$s->[2] >= $inner_s->[2] &&
		$s->[1] <= $inner_s->[1] &&
		$s->[3] >= $inner_s->[3];
}

# recursive method which adds levels to the quadtree
sub _addLevel
{
	my ($self, $depth, $parent, @coords) = @_;
	my $node = {
		PARENT => $parent,
		OBJECTS => [],
		HAS_OBJECTS => 0,
		AREA => _buildShape(@coords),
		DEPTH => $depth,
	};

	weaken $node->{PARENT} if $parent;

	if ($depth < $self->{DEPTH}) {
		my ($xmin, $ymin, $xmax, $ymax) = @coords;
		my $xmid = $xmin + ($xmax - $xmin) / 2;
		my $ymid = $ymin + ($ymax - $ymin) / 2;
		$depth += 1;

		# segment in the following order:
		# top left, top right, bottom left, bottom right
		$node->{CHILDREN} = [
			_addLevel($self, $depth, $node, $xmin, $ymid, $xmid, $ymax),
			_addLevel($self, $depth, $node, $xmid, $ymid, $xmax, $ymax),
			_addLevel($self, $depth, $node, $xmin, $ymin, $xmid, $ymid),
			_addLevel($self, $depth, $node, $xmid, $ymin, $xmax, $ymid),
		];
	}

	return $node;
}

# this private method executes $code on every leaf node of the tree
# which is within the circular shape
sub _loopOnNodes
{
	my ($self, $finding, $shape) = @_;

	my @nodes;
	my @loopargs = $self->{ROOT};
	my @loopargs_contained;
	my $fully_contained;
	my $current;

	while ($current = shift @loopargs) {
		next if $finding && !$current->{HAS_OBJECTS};

		$fully_contained = _shapeContained($current->{AREA}, $shape);
		next if !$fully_contained && !_shapesOverlap($shape, $current->{AREA});

		if ($finding) {
			push @nodes, $current;
			next unless $current->{CHILDREN};

			if ($fully_contained) {
				push @loopargs_contained, @{$current->{CHILDREN}};
			}
			else {
				push @loopargs, @{$current->{CHILDREN}};
			}
		}
		else {
			$current->{HAS_OBJECTS} = 1;
			if ($fully_contained || !$current->{CHILDREN}) {
				push @nodes, $current;
			}
			else {
				push @loopargs, @{$current->{CHILDREN}};
			}
		}
	}

	if ($finding) {
		while (my $current = shift @loopargs_contained) {
			next if !$current->{HAS_OBJECTS};

			push @nodes, $current;
			push @loopargs_contained, @{$current->{CHILDREN}}
				if $current->{CHILDREN};
		}
	}

	return \@nodes;
}

sub _clearHasObjects
{
	my $node = shift;

	if ($node->{CHILDREN}) {
		for my $child (@{$node->{CHILDREN}}) {
			return if $child->{HAS_OBJECTS};
		}
	}

	$node->{HAS_OBJECTS} = 0;
	if ($node->{PARENT}) {
		_clearHasObjects($node->{PARENT});
	}
}

sub _AQT_init
{
	my $obj = shift;

	$obj->{BACKREF} = {};
	$obj->{ROOT} = _addLevel(
		$obj,
		1,     #current depth
		undef, # parent - none
		$obj->{XMIN},
		$obj->{YMIN},
		$obj->{XMAX},
		$obj->{YMAX},
	);
}

sub _AQT_deinit
{
	# do nothing in PP implementation
}

sub _AQT_addObject
{
	my ($self, $object, @coords) = @_;
	my $shape = _buildShape(@coords);

	my $nodes = _loopOnNodes($self, 0, $shape);
	for my $node (@$nodes) {
		push @{$node->{OBJECTS}}, $object;
	}

	$self->{BACKREF}{$object} = $shape
		unless @$nodes == 0;
}

sub _AQT_findObjects
{
	my ($self, @coords) = @_;
	my $shape = _buildShape(@coords);

	# map returned nodes to an array containing all of
	# their objects
	my %hash;
	foreach my $node (@{_loopOnNodes($self, 1, $shape)}) {
		foreach my $object (@{$node->{OBJECTS}}) {
			$hash{$object} = $object;
		}
	}

	if ($self->{CHECK}) {
		my $backref = $self->{BACKREF};
		foreach my $key (keys %hash) {
			delete $hash{$key}
				unless _shapesOverlap($shape, $backref->{$key});
		}
	}

	return [values %hash];
}

sub _AQT_delete
{
	my ($self, $object) = @_;

	return unless exists $self->{BACKREF}{$object};

	for my $node (@{_loopOnNodes($self, 1, $self->{BACKREF}{$object})}) {
		@{$node->{OBJECTS}} = grep {$_ ne $object} @{$node->{OBJECTS}};
		_clearHasObjects($node) if !@{$node->{OBJECTS}};
	}

	delete $self->{BACKREF}{$object};
}

sub _AQT_clear
{
	my ($self) = @_;

	my @loopargs = $self->{ROOT};
	while (my $current = shift @loopargs) {
		next unless $current->{HAS_OBJECTS};

		@{$current->{OBJECTS}} = ();
		$current->{HAS_OBJECTS} = 0;

		if ($current->{CHILDREN}) {
			push @loopargs, @{$current->{CHILDREN}};
		}
	}

	%{$self->{BACKREF}} = ();
}

1;

