package Algorithm::QuadTree::PP;
$Algorithm::QuadTree::PP::VERSION = '0.3';
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(
	_AQT_init
	_AQT_deinit
	_AQT_addObject
	_AQT_findObjects
	_AQT_delete
	_AQT_clear
);

# recursive method which adds levels to the quadtree
sub _addLevel
{
	my ($self, $depth, @coords) = @_;
	my $node = {
		AREA => \@coords,
	};

	if ($depth < $self->{DEPTH}) {
		my ($xmin, $ymin, $xmax, $ymax) = @coords;
		my $xmid = $xmin + ($xmax - $xmin) / 2;
		my $ymid = $ymin + ($ymax - $ymin) / 2;
		$depth += 1;

		# segment in the following order:
		# top left, top right, bottom left, bottom right
		$node->{CHILDREN} = [
			_addLevel($self, $depth, $xmin, $ymid, $xmid, $ymax),
			_addLevel($self, $depth, $xmid, $ymid, $xmax, $ymax),
			_addLevel($self, $depth, $xmin, $ymin, $xmid, $ymid),
			_addLevel($self, $depth, $xmid, $ymin, $xmax, $ymid),
		];
	}
	else {
		# leaves must have empty aref in objects
		$node->{OBJECTS} = [];
	}

	return $node;
}

# this private method executes $code on every leaf node of the tree
# which is within the circular shape
sub _loopOnNodesInCircle
{
	my ($self, @coords) = @_;

	# this is a bounding box of a circle
	# it will help us filter out all the far away shapes
	my @box = (
		$coords[0] - $coords[2],
		$coords[1] - $coords[2],
		$coords[0] + $coords[2],
		$coords[1] + $coords[2],
	);

	# avoid squaring the radius on each iteration
	my $radius_squared = $coords[2] ** 2;

	my @nodes;
	for my $current (@{_loopOnNodesInRectangle($self, @box)}) {
		my ($cxmin, $cymin, $cxmax, $cymax) = @{$current->{AREA}};

		my $cx = $coords[0] < $cxmin
			? $cxmin
			: $coords[0] > $cxmax
				? $cxmax
				: $coords[0]
		;

		my $cy = $coords[1] < $cymin
			? $cymin
			: $coords[1] > $cymax
				? $cymax
				: $coords[1]
		;

		push @nodes, $current
			if ($coords[0] - $cx) ** 2 + ($coords[1] - $cy) ** 2
			<= $radius_squared;
	}

	return \@nodes;
}

# this private method executes $code on every leaf node of the tree
# which is within the rectangular shape
sub _loopOnNodesInRectangle
{
	my ($self, @coords) = @_;

	my @nodes;
	my @loopargs = $self->{ROOT};
	for my $current (@loopargs) {

		# first check if obj overlaps current segment.
		next if
			$coords[0] > $current->{AREA}[2] ||
			$coords[2] < $current->{AREA}[0] ||
			$coords[1] > $current->{AREA}[3] ||
			$coords[3] < $current->{AREA}[1];

		if ($current->{CHILDREN}) {
			push @loopargs, @{$current->{CHILDREN}};
		} else {
			# segment is a leaf and overlaps the obj
			push @nodes, $current;
		}
	}

	return \@nodes;
}

# choose the right function based on argument count
# first argument is always $self, the rest are coords
sub _loopOnNodes
{
	goto \&_loopOnNodesInCircle if @_ == 4;
	goto \&_loopOnNodesInRectangle;
}

sub _AQT_init
{
	my $obj = shift;

	$obj->{BACKREF} = {};
	$obj->{ROOT} = _addLevel(
		$obj,
		1,    #current depth
		$obj->{XMIN},
		$obj->{YMIN},
		$obj->{XMAX},
		$obj->{YMAX},
	);
}

sub _AQT_deinit
{
	# no nothing in PP implementation
}

sub _AQT_addObject
{
	my ($self, $object, @coords) = @_;

	for my $node (@{_loopOnNodes($self, @coords)}) {
		push @{$node->{OBJECTS}}, $object;
		push @{$self->{BACKREF}{$object}}, $node;
	}
}

sub _AQT_findObjects
{
	my ($self, @coords) = @_;

	# map returned nodes to an array containing all of
	# their objects
	return [
		map {
			@{$_->{OBJECTS}}
		} @{_loopOnNodes($self, @coords)}
	];
}

sub _AQT_delete
{
	my ($self, $object) = @_;

	return unless exists $self->{BACKREF}{$object};

	for my $node (@{$self->{BACKREF}{$object}}) {
		$node->{OBJECTS} = [ grep {$_ ne $object} @{$node->{OBJECTS}} ];
	}

	delete $self->{BACKREF}{$object};
}

sub _AQT_clear
{
	my ($self) = @_;

	for my $key (keys %{$self->{BACKREF}}) {
		for my $node (@{$self->{BACKREF}{$key}}) {
			$node->{OBJECTS} = [];
		}
	}
	$self->{BACKREF} = {};
}

1;

