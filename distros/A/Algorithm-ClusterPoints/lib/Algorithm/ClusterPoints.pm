package Algorithm::ClusterPoints;

our $VERSION = '0.08';

use strict;
use warnings;

use constant sqr2 => sqrt(2);
use constant isqr2 => 1/sqr2;

use POSIX qw(floor ceil);
use List::Util qw(max min);
use Carp;

use Data::Dumper;

my $packing = ($] >= 5.008 ? 'w*' : 'V*');

sub new {
    @_ & 1 or croak 'Usage: Algorithm::ClusterPoints->new(%options)';
    my ($class, %opts) = @_;

    my $dimension = delete $opts{dimension};
    $dimension = 2 unless defined $dimension;
    $dimension < 1 and croak "positive dimension required";
    my $radius = delete $opts{radius};
    my $minimum_size = delete $opts{minimum_size};
    my $ordered = delete $opts{ordered};
    my $scales = delete $opts{scales};
    my $dimensional_groups = delete $opts{dimensional_groups};

    %opts and croak "unknown constructor option(s) '".join("', '", sort keys %opts)."'";

    my $self = bless { radius => 1.0,
                       minimum_size => 1,
                       ordered => 0,
                       dimension => $dimension,
                       coords => [ map [], 1..$dimension ],
                       scales => [ map 1, 1..$dimension ],
                       dimensional_groups => [[0..$dimension-1]],
                     }, $class;

    $self->radius($radius) if defined $radius;
    $self->minimum_size($minimum_size) if defined $minimum_size;
    $self->ordered($ordered) if defined $ordered;
    if (defined $scales) {
        ref $scales eq 'ARRAY' or croak 'ARRAY reference expected for "scales" option';
        $self->scales(@$scales);
    }
    if (defined $dimensional_groups) {
        ref $dimensional_groups eq 'ARRAY' or croak 'ARRAY reference expected for "dimensional_groups" option';
        $self->dimensional_groups(@$dimensional_groups);
    }
    $self;
}

sub add_point {
    my $self = shift;
    my $dimension = $self->{dimension};
    @_ % $dimension and croak 'coordinates list size is not a multiple of the problem dimension';
    delete $self->{_clusters};
    my $ix = @{$self->{coords}[0]};
    while (@_) {
        push @$_, shift
            for (@{$self->{coords}});
    }
    $ix;
}

*add_points = \&add_point;

sub point_coords {
    @_ == 2 or croak 'Usage: $clp->point_coords($index)';
    my ($self, $ix) = @_;
    my $top = $#{$self->{coords}[0]};
    croak "point index $ix out of range [0, $top]"
        if ($ix > $top or $ix < 0);
    return $self->{coords}[0][$ix]
        if $self->{dimension} == 1;
    wantarray or croak 'method requires list context';
    map $_->[$ix], @{$self->{coords}};
}

sub reset { delete shift->{_clusters} }

sub radius {
    @_ > 2 and croak 'Usage: $clp->radius([$new_radius])';
    my $self = shift;
    if (@_) {
        my $radius = shift;
        $radius > 0.0 or croak 'positive radius required';
        $self->{radius} = $radius;
        delete $self->{_clusters};
    }
    $self->{radius};
}

sub ordered {
    @_ > 2 and croak 'Usage: $clp->ordered([$ordered])';
    my $self = shift;
    if (@_) {
        $self->{ordered} = !!shift;
        delete $self->{_clusters};
    }
    $self->{ordered};
}

sub minimum_size {
    @_ > 2 and croak 'Usage: $clp->minimum_size([$size])';
    my $self = shift;
    if (@_) {
        my $minimum_size = shift;
        $minimum_size > 0 or croak 'positive minimum_size required';
        $self->{minimum_size} = $minimum_size;
        delete $self->{_clusters};
    }
    $self->{minimum_size};
}

sub scales {
    my $self = shift;
    my $dimension = $self->{dimension};
    if (@_) {
        @_ == $dimension or croak 'number of scales does not match problem dimension';
        grep($_ <= 0, @_) and croak 'positive number required';
        @{$self->{scales}} = @_;
        delete $self->{_clusters};
    }
    return @{$self->{scales}};
}

sub dimensional_groups {
    my $self = shift;
    my $hcb = $self->{dimensional_groups};
    my $dimension = $self->{dimension};
    if (@_) {
        my @all = eval {
            no warnings;
            sort { $a <=> $b } map @$_, @_;
        };
        croak 'bad dimension groups'
            unless (@all == $dimension and
                    join('|', @all) eq join('|', 0..$dimension-1));
        $self->{dimensional_groups} = [map [@$_], @_];
        delete $self->{_clusters};
    }
    map [@$_], @{$self->{dimensional_groups}};
}

sub clusters {
    my $self = shift;
    my $clusters = $self->{_clusters} ||= $self->_make_clusters_ix;
    my $ax = $self->{x};
    my $ay = $self->{y};
    my $coords = $self->{coords};
    my @out;
    for my $cluster (@$clusters) {
        my @cluster_coords;
        for my $ix (@$cluster) {
            push @cluster_coords, map $_->[$ix], @$coords;
        }
        push @out, \@cluster_coords;
    }
    @out;
}

sub clusters_ix {
    my $self = shift;
    my $clusters = $self->{_clusters} ||= $self->_make_clusters_ix;
    # dup arrays:
    map [@$_], @$clusters;
}

sub _touch_2 {
    my ($c1, $c2, $ax, $ay) = @_;

    my $c1_xmin = min @{$ax}[@$c1];
    my $c2_xmax = max @{$ax}[@$c2];
    return 0 if $c1_xmin - $c2_xmax > 1;

    my $c1_xmax = max @{$ax}[@$c1];
    my $c2_xmin = min @{$ax}[@$c2];
    return 0 if $c2_xmin - $c1_xmax > 1;

    my $c1_ymin = min @{$ay}[@$c1];
    my $c2_ymax = max @{$ay}[@$c2];
    return 0 if $c1_ymin - $c2_ymax > 1;

    my $c1_ymax = max @{$ay}[@$c1];
    my $c2_ymin = min @{$ay}[@$c2];
    return 0 if $c2_ymin - $c1_ymax > 1;

    for my $i (@$c1) {
        for my $j (@$c2) {
            my $dx = $ax->[$i] - $ax->[$j];
            my $dy = $ay->[$i] - $ay->[$j];
            return 1 if ($dx * $dx + $dy * $dy <= 1);
        }
    }
    0;
}

sub _touch {
    my ($c1, $c2, $coords, $groups) = @_;
    # print STDERR "touch($c1->[0], $c2->[0])\n";

    for my $coord (@$coords) {
        my $c1_min = min @{$coord}[@$c1];
        my $c2_max = max @{$coord}[@$c2];
        return 0 if $c1_min - $c2_max > 1;

        my $c1_max = max @{$coord}[@$c1];
        my $c2_min = min @{$coord}[@$c2];
        return 0 if $c2_min - $c1_max > 1;
    }

    for my $i (@$c1) {
    J: for my $j (@$c2) {
            for my $group (@$groups) {
                my $sum = 0;
                for (@{$coords}[@$group]) {
                    my $delta = $_->[$i] - $_->[$j];
                    $sum += $delta * $delta;
                }
                next J if $sum > 1;
            }
            # print STDERR "they touch\n";
            return 1;
        }
    }
    0;
}

sub _scaled_coords {
    my $self = shift;
    my @coords = @{$self->{coords}};
    my $scales = $self->{scales};
    my $ir = 1.0 / $self->{radius};
    for my $dimension (0..$#coords) {
        my $scale = abs($ir * $scales->[$dimension]);
        next if $scale == 1;
        $coords[$dimension] = [ map $scale * $_, @{$coords[$dimension]} ];
    }
    @coords;
}

sub _hypercylinder_id { join '|', map join(',', @$_), @_ }

sub _make_clusters_ix {
    my $self = shift;
    # print STDERR Dumper $self;
    _hypercylinder_id($self->dimensional_groups) eq '0,1'
        ? $self->_make_clusters_ix_2
        : $self->_make_clusters_ix_any;
}

sub _make_clusters_ix_2 {
    my $self = shift;

    $self->{dimension} == 2
        or croak 'internal error: _make_clusters_ix_2 called but dimension is not 2';

    my ($ax, $ay) = $self->_scaled_coords;
    @$ax or croak "points have not been added";

    my $xmin = min @$ax;
    my $ymin = min @$ay;
    # my $xmax = max @$ax;
    # my $ymax = max @$ay;

    my $istep = 1.00001*sqr2;
    my @fx = map { floor($istep * ($_ - $xmin)) } @$ax;
    my @fy = map { floor($istep * ($_ - $ymin)) } @$ay;

    my (%ifx, %ify, $c);
    $c = 1; $ifx{$_} ||= $c++ for @fx;
    $c = 1; $ify{$_} ||= $c++ for @fy;
    my %rifx = reverse %ifx;
    my %rify = reverse %ify;

    my %cell;
    # my %cellid;
    my $cellid = 1;
    for my $i (0..$#$ax) {
        my $cell = pack $packing => $ifx{$fx[$i]}, $ify{$fy[$i]};
        push @{$cell{$cell}}, $i;
        # $cellid{$cell} ||= $cellid++;
        # print STDERR "i: $i, x: $ax->[$i], y: $ay->[$i], fx: $fx[$i], fy: $fy[$i], ifx: $ifx{$fx[$i]}, ify: $ify{$fy[$i]}, cellid: $cellid{$cell}\n";
    }

    my %cell2cluster; # n to 1 relation
    my %cluster2cell; # when $cluster2cell{$foo} does not exists

    while(defined (my $cell = each %cell)) {
        my %cluster;
        my ($ifx, $ify) = unpack $packing => $cell;
        my $fx = $rifx{$ifx};
        my $fy = $rify{$ify};
        for my $dx (-2, -1, 0, 1, 2) {
            my $ifx = $ifx{$fx + $dx};
            defined $ifx or next;
            my $filter = 6 - $dx * $dx;
            for my $dy (-2, -1, 0, 1, 2) {
                # next if $dx * $dx + $dy * $dy > 5;
                next if $dy * $dy > $filter;
                my $ify = $ify{$fy + $dy};
                defined $ify or next;
                my $neighbor = pack $packing => $ifx, $ify;
                my $cluster = $cell2cluster{$neighbor};
                if ( defined $cluster and
                     !$cluster{$cluster} and
                     _touch_2($cell{$cell}, $cell{$neighbor}, $ax, $ay) ) {
                    $cluster{$cluster} = 1;
                }
            }
        }
        if (%cluster) {
            my ($to, $to_cells);
            if (keys %cluster > 1) {
                my $max = 0;
                for (keys %cluster) {
                    my $cells = $cluster2cell{$_};
                    my $n = defined($cells) ? @$cells : 1;
                    if ($n > $max) {
                        $max = $n;
                        $to = $_;
                    }
                }
                delete $cluster{$to};
                $to_cells = ($cluster2cell{$to} ||= [$to]);
                for (keys %cluster) {
                    my $neighbors = delete $cluster2cell{$_};
                    if (defined $neighbors) {
                        push @$to_cells, @$neighbors;
                        $cell2cluster{$_} = $to for @$neighbors;
                    }
                    else {
                        push @$to_cells, $_;
                        $cell2cluster{$_} = $to;
                    }
                }
            }
            else {
                $to = each %cluster;
                $to_cells = ($cluster2cell{$to} ||= [$to]);
            }
            push @$to_cells, $cell;
            $cell2cluster{$cell} = $to;
        }
        else {
            $cell2cluster{$cell} = $cell;
        }
    }

    my @clusters;
    while (my ($cluster, $cells) = each %cluster2cell) {
        my @points = map @{delete $cell{$_}}, @$cells;
        if (@points >= $self->{minimum_size}) {
            @points = sort { $a <=> $b } @points if $self->{ordered};
            push @clusters, \@points;
        }
    }
    push @clusters, grep { @$_ >= $self->{minimum_size} } values %cell;

    @clusters = sort { $a->[0] <=> $b->[0] } @clusters if $self->{ordered};

    return \@clusters;
}

my %delta_hypercylinder; # cache

sub _delta_hypercylinder {

    my $dhc = $delta_hypercylinder{_hypercylinder_id @_} ||= do {
        my @subdimension;
        for my $group (@_) {
            $subdimension[$_] = @$group for @$group;
        }
        my @top = map ceil(sqrt($_)), @subdimension;
        # calculate minimum hypercube
        my @delta_hypercylinder = [];
        for my $dimension (0..$#subdimension) {
            my @next;
            for my $dhc (@delta_hypercylinder) {
                my $top = $top[$dimension];
                push @next, map [@$dhc, $_], -$top..$top;
            }
            @delta_hypercylinder = @next;
        }

        # filter out hyperpixels out of the hypercylinder
        for my $group (@_) {
            @delta_hypercylinder = grep {
                my $sum = 0;
                for (@$_[@$group]) {
                    my $min = ($_ ? abs($_) - 1 : 0);
                    $sum += $min * $min;
                }
                $sum < @$group;
            } @delta_hypercylinder;
        }

        # print Data::Dumper->Dump([\@delta_hypercylinder], [qw($hc)]);

        \@delta_hypercylinder
    };
    # print Data::Dumper->Dump([$dhc], [qw($hc)]);
    @$dhc;
}

sub _print_clusters {
    print join(',', @$_), "\n" for sort { $a->[0] <=> $b->[0] } @_;
}

sub _make_clusters_ix_any {
    my $self = shift;

    my $dimension = $self->{dimension};
    my @coords = $self->_scaled_coords;
    my $coords = \@coords;
    my $top = $#{$coords[0]};
    $top >= 0 or croak "points have not been added";
    my $groups = $self->{dimensional_groups};

    my (@fls, @ifls, @rifls);

    for my $group (@$groups) {
        my $istep = 1.000001 * sqrt(@$group);
        for my $dimension (@$group) {
            my $coord = $coords[$dimension];
            my $min = min @$coord;
            my @fl = map floor($istep * ($_ - $min)), @$coord;
            $fls[$dimension] = \@fl;
            my %ifl;
            my $c = 1;
            $ifl{$_} ||= $c++ for @fl;
            $ifls[$dimension] = \%ifl;
            my %rifl = reverse %ifl;
            $rifls[$dimension] = \%rifl;
        }
    }

    my %cell;
    my $dimension_top = $dimension - 1;
    for my $i (0..$top) {
        my $cell = pack $packing => map $ifls[$_]{$fls[$_][$i]}, 0..$dimension_top;
        push @{$cell{$cell}}, $i;
    }
    # print STDERR "\%cell:\n";
    # _print_clusters(values %cell);

    my %cell2cluster; # n to 1 relation
    my %cluster2cell;

    my @delta_hypercylinder = _delta_hypercylinder @$groups;
    # print STDERR "delta_hypercylinder\n", Dumper \@delta_hypercylinder;

    while(defined (my $cell = each %cell)) {
        my %cluster;
        my @ifl = unpack $packing => $cell;
        my @fl = map $rifls[$_]{$ifl[$_]}, 0..$dimension_top;

        for my $delta (@delta_hypercylinder) {
            # print STDERR "\$delta: @$delta\n";
            my @ifl = map { $ifls[$_]{$fl[$_] + $delta->[$_]} || next } 0..$dimension_top;
            # next if grep !defined, @ifl;
            my $neighbor = pack $packing => @ifl;
            my $cluster = $cell2cluster{$neighbor};
            if ( defined $cluster and
                 !$cluster{$cluster} and
                 _touch($cell{$cell}, $cell{$neighbor}, $coords, $groups) ) {
                $cluster{$cluster} = 1;
            }
        }
        if (%cluster) {
            my ($to, $to_cells);
            if (keys %cluster > 1) {
                my $max = 0;
                for (keys %cluster) {
                    my $cells = $cluster2cell{$_};
                    my $n = defined($cells) ? @$cells : 1;
                    if ($n > $max) {
                        $max = $n;
                        $to = $_;
                    }
                }
                delete $cluster{$to};
                $to_cells = ($cluster2cell{$to} ||= [$to]);
                for (keys %cluster) {
                    my $neighbors = delete $cluster2cell{$_};
                    if (defined $neighbors) {
                        push @$to_cells, @$neighbors;
                        $cell2cluster{$_} = $to for @$neighbors;
                    }
                    else {
                        push @$to_cells, $_;
                        $cell2cluster{$_} = $to;
                    }
                }
            }
            else {
                $to = each %cluster;
                $to_cells = ($cluster2cell{$to} ||= [$to]);
            }
            push @$to_cells, $cell;
            $cell2cluster{$cell} = $to;
        }
        else {
            $cell2cluster{$cell} = $cell;
        }
    }

    my @clusters;
    while (my ($cluster, $cells) = each %cluster2cell) {
        my @points = map @{delete $cell{$_}}, @$cells;
        if (@points >= $self->{minimum_size}) {
            @points = sort { $a <=> $b } @points if $self->{ordered};
            push @clusters, \@points;
        }
    }
    push @clusters, grep { @$_ >= $self->{minimum_size} } values %cell;

    @clusters = sort { $a->[0] <=> $b->[0] } @clusters if $self->{ordered};

    return \@clusters;
}

sub brute_force_clusters_ix {
    my $self = shift;
    _hypercylinder_id($self->dimensional_groups) eq '0,1'
        ? $self->brute_force_clusters_ix_2
        : $self->brute_force_clusters_ix_any
}

sub brute_force_clusters_ix_2 {
    @_ == 1 or croak 'Usage: $clp->brute_force_clusters_ix_2';
    my $self = shift;

    $self->{dimension} == 2
        or croak "brute_force_clusters_ix_2 called but dimension is not equal to 2";

    my ($ax, $ay) = $self->_scaled_coords;
    @$ax or croak "points have not been added";

    my @ix = 0..$#$ax;
    my @clusters;
    while (@ix) {
        # print STDERR "\@ix 1: ".join("-", @ix).".\n";
        my @current = shift @ix;
        my @done;
        while (@ix) {
            # print STDERR "\@ix 2: ".join("-", @ix).".\n";
            my $ix = shift @ix;
            my @queue;
            for my $current (@current) {
                # print STDERR "ix: $ix, current: $current\n";
                my $dx = $ax->[$ix] - $ax->[$current];
                my $dy = $ay->[$ix] - $ay->[$current];
                if ($dx * $dx + $dy * $dy <= 1) {
                    # print STDERR "they are together\n";
                    push @queue, $ix;
                    last;
                }
            }
            if (@queue) {
                while (defined($ix = shift @queue)) {
                    for my $done (@done) {
                        next unless defined $done;
                        # print STDERR "ix: $ix, done: $done\n";
                        my $dx = $ax->[$ix] - $ax->[$done];
                        my $dy = $ay->[$ix] - $ay->[$done];
                        if ($dx * $dx + $dy * $dy <= 1) {
                            # print STDERR "they are together\n";
                            push @queue, $done;
                            undef $done;
                        }
                    }
                    push @current, $ix;
                }
            }
            else {
                push @done, $ix;
            }
        }
        if (@current >= $self->{minimum_size}) {
            @current = sort { $a <=> $b } @current if $self->{ordered};
            push @clusters, \@current;
        }
        @ix = grep defined($_), @done;
    }
    @clusters = sort { $a->[0] <=> $b->[0] } @clusters if $self->{ordered};
    return @clusters;
}

sub _points_touch {
    my ($ix0, $ix1, $coords, $groups) = @_;
    for my $group (@$groups) {
        my $sum = 0;
        for (@{$coords}[@$group]) {
            my $delta = $_->[$ix0] - $_->[$ix1];
            $sum += $delta * $delta;
        }
        # print "sum: $sum\n";
        return 0 if $sum > 1;
    }
    # printf STDERR "points %d and %d touch\n", $ix0, $ix1;
    return 1;
}

sub brute_force_clusters_ix_any {
    @_ == 1 or croak 'Usage: $clp->brute_force_clusters_ix_any';
    my $self = shift;

    my $dimension = $self->{dimension};
    my $coords = [ $self->_scaled_coords ];
    my @ix = 0..$#{$coords->[0]};
    @ix or croak "points have not been added";

    my $groups = $self->{dimensional_groups};

    my @clusters;
    while (@ix) {
        # print STDERR "\@ix 1: ".join("-", @ix).".\n";
        my @current = shift @ix;
        my @done;
        while (@ix) {
            # print STDERR "\@ix 2: ".join("-", @ix).".\n";
            my $ix = shift @ix;
            my @queue;
            for my $current (@current) {
                if (_points_touch($ix, $current, $coords, $groups)) {
                    push @queue, $ix;
                    last;
                }
            }
            if (@queue) {
                while (defined($ix = shift @queue)) {
                    for my $done (@done) {
                        next unless defined $done;
                        # print STDERR "ix: $ix, done: $done\n";
                        if (_points_touch($ix, $done, $coords, $groups)) {
                            push @queue, $done;
                            undef $done;
                        }
                    }
                    push @current, $ix;
                }
            }
            else {
                push @done, $ix;
            }
        }
        if (@current >= $self->{minimum_size}) {
            @current = sort { $a <=> $b } @current if $self->{ordered};
            push @clusters, \@current;
        }
        @ix = grep defined($_), @done;
    }
    @clusters = sort { $a->[0] <=> $b->[0] } @clusters if $self->{ordered};
    return @clusters;
}

sub distance {
    @_ == 3 or croak 'Usage: $clp->distance($ix0, $ix1)';
    my ($self, $ix0, $ix1) = @_;
    my $coords = $self->{coords};
    my $scales = $self->{scales};
    my $sum = 0;
    for my $dimension (0..$#{$coords}) {
        my $delta = $scales->[$dimension] * ($coords->[$dimension][$ix0] - $coords->[$dimension][$ix1]);
        $sum += $delta * $delta;
    }
    sqrt($sum);
}

1;
__END__

=head1 NAME

Algorithm::ClusterPoints - find clusters inside a set of points

=head1 SYNOPSIS

  use Algorithm::ClusterPoints;
  my $clp = Algorithm::ClusterPoints->new( dimension => 3,
                                           radius => 1.0,
                                           minimum_size => 2,
                                           ordered => 1 );
  for my $p (@points) {
      $clp->add_point($p->{x}, $p->{y}, $p->{z});
  }
  my @clusters = $clp->clusters_ix;
  for my $i (0..$#clusters) {
      print( join( ' ',
                   "cluster $i:",
                   map {
                       my ($x, $y, $z) = $clp->point_coords($_);
                       "($_: $x, $y, $z)"
                   } @{$clusters[$i]}
                 ), "\n"
           );
  }

=head1 DESCRIPTION

This module implements an algorithm to find clusters of points inside
a set.

Clusters are defined as sets of points where it is possible to
stablish a way between any pair of points moving from point to point
inside the cluster in steps smaller than a given radius.

Points can have any dimension from one to infinitum, though the
algorithm performance degrades quickly as the dimension increases (it
has O((2*D)^D) complexity).

The algorithm input parameters are:

=over 4

=item $dimension

Dimension of the problem space. For instance, for finding clusters on a
geometric plane, dimension will be 2.

=item $radius

A point is part of a cluster when there is at least another point from
the cluster that is at a distance smaller than $radius from it.

=item $minimum_size

Minimum_number of points required to form a cluster, the default is
one.

=item @points

The coordinates of the points

=item $ordered

Order the points inside the clusters by their indexes and also order
the clusters by the index of the contained points.

Ordering the output data is optional because it can be an
computational expensive operation.

=back

=head2 API

This module has an object oriented interface with the following
methods:

=over 4

=item Algorithm::ClusterPoints->new(%args)

returns a new object.

The accepted arguments are:

=over 4

=item dimension => $dimension

number of dimensions of the points (defaul is 2).

=item radius => $radius

maximum aceptable distance between two points to form a cluster
(default is 1.0).

=item minimum_size => $minimum_size

minimun cluster size (default is 1).

=item ordered => $ordered

sort the returned data structures (default is false).

=item scales => [$x_scale, $y_scale, ...]

point coordinates are scaled by the coefficients given.

=item dimensional_groups => \@dimension_groups

See the "Using hypercylindrical distances" chapter below.


=back

=item $clp->add_point($x, $y, $z, ...)

=item $clp->add_points($x0, $y0, $z0..., $x1, $y1, $z1..., ...);

These methods register points into the algorithm.

They return the index of the (first) point added.

=item $clp->radius

=item $clp->radius($radius)

=item $clp->minimum_size

=item $clp->minimum_size($minimum_size)

=item $clp->ordered

=item $clp->ordered($ordered)

These methods get or set the algorithm parameters.

=item @scales = $clp->scales;

=item @scales = $clp->scales($xs, $ys, $zs, ...);

gets/sets the scales for all the dimensions.

=item @coords = $clp->point_coords($index)

returns the coordinates of the point at index C<$index>.

=item @clusters_ix = $clp->clusters_ix

returns a list of clusters defined by the indexes of the points inside

The data estructure returned is a list of arrays. Every array
represents a cluster and contains the indexes of the points inside.

For instance:

  @clusters_ix = ( [ 0, 1, 5, 10, 13, 15, 17, 31, 32, 38 ],
                   [ 2, 12, 20, 26, 27, 29, 33 ],
                   [ 3, 22, 39 ],
                   [ 4, 11, 16, 30, 36 ],
                   [ 6, 14 ],
                   [ 7, 23, 24 ],
                   [ 18, 25 ],
                   [ 21, 40 ] );

You can get back the coordinates of the points using the method
C<point_coords>, as for instance:

   for my $c (@clusters_ix) {
     for my $index (@$c) {
       my ($x, $y, $z) = $clp->point_coords($index);
       ...

Or you can use the method C<clusters> described below that already
returns point coordinates.

=item @clusters = $clp->clusters

returns a list of clusters defined by the coordinates of the points
inside.

This method is similar to C<clusters_ix> but instead of the point
indexes, it includes the point coordinates inside the cluster arrays.

This is a sample of the returned structure:

  @clusters = ( [ 0.49, 0.32, 0.55, 0.32, 0.66, 0.33 ],
                [ 0.95, 0.20, 0.83, 0.27, 0.90, 0.20 ],
                [ 0.09, 0.09, 0.01, 0.08, 0.12, 0.15 ],
                [ 0.72, 0.42, 0.67, 0.47 ],
                [ 0.83, 0.11, 0.77, 0.13, 0.73, 0.07 ],
                [ 0.37, 0.38, 0.36, 0.44 ],
                [ 0.16, 0.79, 0.14, 0.74 ] );

Note that the coordinate values for all the dimensions are interleaved
inside the arrays.

=back

=head2 Using hypercylindrical distances

By default distances between points are meassured as euclidean
distances. That means that two points A and B form a cluster when B is
inside the hypersphere of radius $radius and center A. We will call
this hypersphere the clustering limit surface for point A.

Sometimes, specially when the dimensions represent unrelated entities,
it is desirable to use hypercylinders as the clustering limit surfaces.

For instance, suppose we have a set of three dimensional points ($x,
$y, $t) where the first two dimensions represent coordinates over a
geometrical plane and the third coordinate represents time.

It doesn't make sense to mix space and time to calculate a unique
distance, and so to have a spherical clustering limit surface. What we
need is to set independent limits for geometrical and temporal
dimensions, for instance C<$geo_distance < $geo_radius> and
C<$temp_distance < $temp_radius> and these pair of constraints define
a cylinder on our three-dimensional problem space.

In the general multidimensional case, instead of cylinders, we talk
about hypercylinders but the logic behind is the same, dimensions are
divided in several groups (d-groups) following some problem defined
relation and two points form a cluster when all the subdistances are
smaller than the radius (where subdistance is the euclidean distance
considering only the dimensions in a d-group). Note that every d-group
defines a hypercylinder base.

The method that allows to define the hypercylindrical shape is as
follows:

=over 4

=item $clp->dimensional_groups(\@group0, \@group1, ...)

where @group0, @group1, ... are lists of dimension indexes.

For instance, for a three dimensional problem with dimensions X, Y and
T (in that order), to form a group with the dimensions X and Y and
another with the dimension T, the following call has to be used:

  $clp->dimensional_groups([0, 1], [2]);

=back

The dimensional groups can also be set when the constructor is called:

  my $clp = Algoritm::ClusterPoints->new(
                       dimensional_groups => [[0, 1], [2]],
                       ...);

Usually, when using dimensional groups, you would also want to use the
C<scales> method to set different scales for every dimension group.

Following with the previous example, supposing X and Y are given in
meters and T in seconds, to find the clusters with radius between
points of 1Km and 2 days, the following scales should be used:

  my $spc_scl = 1/1000;
  my $tmp_scl = 1/(2 * 24 * 60 * 60);

  $clp = Algorithm::ClusterPoints->new(
                     dimensional_groups => [[0, 1], [2]],
                     scales => [$spc_scl, $spc_scl, $tmp_scl],
                     ...);

=head1 SEE ALSO

All began on this PerlMonks discussion:
L<http://perlmonks.org/?node_id=694892>.

L<Algorithm::Cluster> is a Perl wrapper for the C Clustering Library.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
