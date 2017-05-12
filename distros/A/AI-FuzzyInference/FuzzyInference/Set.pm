
# A module to implement a fuzzy term set.
# Only triangular term sets are allowed.
#
# Copyright Ala Qumsieh (ala_qumsieh@yahoo.com) 2002.
# This program is distributed under the same terms as Perl itself.

package AI::FuzzyInference::Set;
use strict;

#our $VERSION = 0.02;
use vars qw/$VERSION/;  # a bit more backward compatibility.
$VERSION = 0.04;

1;

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $obj = bless {} => $class;

    $obj->_init;

    return $obj;
}

sub _init {
    my $self = shift;

    $self->{TS}   = {};
    $self->{AREA} = {};
}

sub add {
    my ($self,
	$name,
	$xmin,
	$xmax,
	@coords,
	) = @_;

    # make sure coords span the whole universe.
    if ($coords[0] > $xmin) {
	unshift @coords => ($xmin, $coords[1]);
    }

    if ($coords[-2] < $xmax) {
	push @coords => ($xmax, $coords[-1]);
    }

    $self->{TS}{$name} = \@coords;
}

sub delete {
    my ($self,
	$name,
	) = @_;

    delete $self->{$_}{$name} for qw/TS AREA/;
}

sub membership {
    my ($self,
	$name,
	$val,
	) = @_;

    return undef unless $self->exists($name);

    my $deg = 0;
    my @c   = $self->coords($name);

    my $x1 = shift @c;
    my $y1 = shift @c;

    while (@c) {
	my $x2 = shift @c;
	my $y2 = shift @c;

	next if $x1 == $x2;    # hmm .. why do we have this?

	unless ($x1 <= $val && $val <= $x2) {
	    $x1 = $x2;
	    $y1 = $y2;
	    next;
	}
	$deg = $y2 - ($y2 - $y1) * ($x2 - $val) / ($x2 - $x1);
	last;
    }

    return $deg;
}

sub listAll {
    my $self = shift;

    return keys %{$self->{TS}};
}

sub listMatching {
    my ($self, $rgx) = @_;

    return grep /$rgx/, keys %{$self->{TS}};
}

sub max {    # max of two sets.
    my ($self,
	$set1,
	$set2,
	) = @_;

    my @coords1 = $self->coords($set1);
    my @coords2 = $self->coords($set2);

    my @newCoords;
    my ($x, $y, $other);
    while (@coords1 && @coords2) {
	if ($coords1[0] < $coords2[0]) {
	    $x     = shift @coords1;
	    $y     = shift @coords1;
	    $other = $set2;
	} else {
	    $x     = shift @coords2;
	    $y     = shift @coords2;
	    $other = $set1;
	}
	my $val    = $self->membership($other, $x);
	$val = $y if $y > $val;
	push @newCoords => $x, $val;
    }

    push @newCoords => @coords1 if @coords1;
    push @newCoords => @coords2 if @coords2;

    return @newCoords;
}

sub min {    # min of two sets.
    my ($self,
	$set1,
	$set2,
	) = @_;

    my @coords1 = $self->coords($set1);
    my @coords2 = $self->coords($set2);

    my @newCoords;
    my ($x, $y, $other);
    while (@coords1 && @coords2) {
	if ($coords1[0] < $coords2[0]) {
	    $x     = shift @coords1;
	    $y     = shift @coords1;
	    $other = $set2;
	} else {
	    $x     = shift @coords2;
	    $y     = shift @coords2;
	    $other = $set1;
	}
	my $val    = $self->membership($other, $x);
	$val = $y if $y < $val;
	push @newCoords => $x, $val;
    }

    push @newCoords => @coords1 if @coords1;
    push @newCoords => @coords2 if @coords2;

    return @newCoords;
}

sub complement {
    my ($self, $name) = @_;

    my @coords = $self->coords($name);
    my $i = 0;
    return map {++$i % 2 ? $_ : 1 - $_} @coords;
}

sub coords {
    my ($self,
	$name,
	) = @_;

    return undef unless $self->exists($name);

    return @{$self->{TS}{$name}};
}

sub scale {  # product implication
    my ($self,
	$name,
	$scale,
	) = @_;

    my $i = 0;
    my @c = map { $_ * ++$i % 2 ? 1 : $scale } $self->coords($name);

    return @c;
}

sub clip {   # min implication
    my ($self,
	$name,
	$val,
	) = @_;

    my $i = 0;
    my @c = map {
	++$i % 2 ? $_ : $_ > $val ? $val : $_
	}$self->coords($name);

    return @c;
}

# had to roll my own centroid algorithm.
# not sure why standard algorithms didn't work
# correctly!
sub centroid {   # center of mass.
    my ($self,
	$name,
	) = @_;

    return undef unless $self->exists($name);

    my @coords = $self->coords($name);
    my @ar;

    my $x0 = shift @coords;
    my $y0 = shift @coords;
    my ($x1, $y1);

    while (@coords) {
	$x1 = shift @coords;
	$y1 = shift @coords;

	my $a1 = abs(0.5 * ($x1 - $x0) * ($y1 - $y0));
	my $c1 = (1/3) * ($x0 + $x1 + ($y1 > $y0 ? $x1 : $x0));

	my $a2 = abs(($x1 - $x0) * ($y0 < $y1 ? $y0 : $y1));
	my $c2 = $x0 + 0.5 * ($x1 - $x0);

	my $ta = $a1 + $a2;
	next if $ta == 0;

	my $c  = $c1 * ($a1 / $ta);
	$c    += $c2 * ($a2 / $ta);

	push @ar => [$c, $ta];
    } continue {
	$x0 = $x1;
	$y0 = $y1;
    }

    my $ta = 0;
    $ta += $_->[1] for @ar;

    my $c = 0;
    $c += $_->[0] * ($_->[1] / $ta) for @ar;

    return $c;
}

sub median {
    my ($self,
	$name,
	) = @_;

    my @coords = $self->coords($name);

    # hmmm .. how do I do *this*?
    return 0;
}

sub exists {
    my ($self,
	$name,
	) = @_;

    return exists $self->{TS}{$name};
}

sub uniquify {
    my $self = shift;

    my @new;
    my %seen;

    while (@_) {
	my $x = shift;
	my $y = shift;

	next if $seen{$x};

	push @new => ($x, $y);
	$seen{$x} = 1;
    }

    return @new;
}

sub area {
    my ($self, $name) = @_;

    return $self->{AREA}{$name} if exists $self->{AREA}{$name};

    my @coords = $self->coords($name);

    my $x0   = shift @coords;
    my $y0   = shift @coords;
    my $area = 0;

    while (@coords) {
	my $x1 = shift @coords;
	my $y1 = shift @coords;

	$area += 0.5 * ($x1 - $x0) * ($y1 + $y0);

	$x0 = $x1;
	$y0 = $y1;
    }

    return $self->{AREA}{$name} = $area;
}
