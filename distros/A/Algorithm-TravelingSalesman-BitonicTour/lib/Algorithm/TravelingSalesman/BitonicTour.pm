package Algorithm::TravelingSalesman::BitonicTour;

use strict;
use warnings FATAL => 'all';
use base 'Class::Accessor::Fast';
use Carp 'croak';
use List::Util 'reduce';
use Params::Validate qw/ validate_pos SCALAR /;
use Regexp::Common;

our $VERSION = '0.05';

__PACKAGE__->mk_accessors(qw/ _points _sorted_points _tour /);

=head1 NAME

Algorithm::TravelingSalesman::BitonicTour - solve the euclidean traveling-salesman problem with bitonic tours

=head1 SYNOPSIS

    use Algorithm::TravelingSalesman::BitonicTour;
    my $bt = Algorithm::TravelingSalesman::BitonicTour->new;
    $bt->add_point($x1,$y1);
    $bt->add_point($x2,$y2);
    $bt->add_point($x3,$y3);
    # ...add other points as needed...

    # get and print the solution
    my ($len, @coords) = $bt->solve;
    print "optimal path length: $len\n";
    print "coordinates of optimal path:\n";
    print "   ($_->[0], $_->[1])\n" for @coords;

=head1 THE PROBLEM

From I<Introduction to Algorithms>, 2nd ed., T. H. Cormen, C. E. Leiserson, R.
Rivest, and C. Stein, MIT Press, 2001, problem 15-1, p. 364:

=over 4

The B<euclidean traveling-salesman problem> is the problem of determining the
shortest closed tour that connects a given set of I<n> points in the plane.
Figure 15.9(a) shows the solution to a 7-point problem.  The general problem is
NP-complete, and its solution is therefore believed to require more than
polynomial time (see Chapter 34).

J. L. Bentley has suggested that we simplify the problem by restricting our
attention to B<bitonic tours>, that is, tours that start at the leftmost point,
go strictly left to right to the rightmost point, and then go strictly right to
left back to the starting point.  Figure 15.9(b) shows the shortest bitonic
tour of the same 7 points.  In this case, a polynomial-time algorithm is
possible.

Describe an I<O>(n^2)-time algorithm for determining an optimal bitonic tour.
You may assume that no two points have the same I<x>-coordinate.  (I<Hint:>
Scan left to right, maintaining optimal possibilities for the two parts of the
tour.)

=back

From Wikipedia (L<http://en.wikipedia.org/wiki/bitonic_tour>):

=over 4

In computational geometry, a B<bitonic tour> of a set of point sites in the
Euclidean plane is a closed polygonal chain that has each site as one of its
vertices, such that any vertical line crosses the chain at most twice.

=back

=head1 THE SOLUTION

=head2 Conventions

Points are numbered from left to right, starting with "0", then "1", and so on.
For convenience I call the rightmost point C<R>.

=head2 Key Insights Into the Problem

=over 4

=item 1. Focus on optimal B<open> bitonic tours.

B<Optimal open bitonic tours> have endpoints (i,j) where C<< i < j < R >>, and
they are the building blocks of the optimal closed bitonic tour we're trying to
find.

An open bitonic tour, optimal or not, has these properties:

 * it's bitonic (a vertical line crosses the tour at most twice)
 * it's open (it has endpoints), which we call "i" and "j" (i < j)
 * all points to the left of "j" are visited by the tour
 * points i and j are endpoints (connected to exactly one edge)
 * all other points in the tour are connected to two edges

For a given set of points there may be many open bitonic tours with endpoints
(i,j), but we are only interested in the I<optimal> open tour--the tour with
the shortest length. Let's call this tour B<C<T(i,j)>>.

=item 2. Grok the (slightly) messy recurrence relation.

A concrete example helps clarify this.  Assume we know the optimal tour lengths
for all (i,j) to the right of point C<5>:

    T(0,1)
    T(0,2)  T(1,2)
    T(0,3)  T(1,3)  T(2,3)
    T(0,4)  T(1,4)  T(2,4)  T(3,4)

From this information, we can find C<T(0,5)>, C<T(1,5)>, ... C<T(4,5)>.

=over 4

=item B<Finding C<T(0,5)>>

From our definition, C<T(0,5)> must have endpoints C<0> and C<5>, and must also
include all intermediate points C<1>-C<4>.  This means C<T(0,5)> is composed of
points C<0> through C<5> in order.  This is also the union of C<T(0,4)> and the
line segment C<4>-C<5>.

=item B<Finding C<T(1,5)>>

C<T(1,5)> has endpoints at C<1> and C<5>, and visits all points to the left of
C<5>.  To preserve the bitonicity of C<T(1,5)>, the only possibility for the
tour is the union of C<T(1,4)> and line segment C<4>-C<5>.  I have included a
short proof by contradiction of this in the source code.

=begin comment

Proof by contradiction:

 1. Assume the following:
    * T(1,5) is an optimal open bitonic tour having endpoints 1 and 5.
    * Points 4 and 5 are not adjacent in the tour, i.e. the final segment in
      the tour joins points "P" and 5, where "P" is to the left of point 4.
 2. Since T(1,5) is an optimal open bitonic tour, point 4 is included in the
    middle of the tour, not at an endpoint, and is connected to two edges.
 3. Since 4 is not connected to 5, both its edges connect to points to its
    left.
 4. Combined with the segment from 5 to P, a vertical line immediately to the
    left of point 4 must cross at least three line segments, thus our proposed
    T(1,5) is not bitonic.

Thus points 4 and 5 must be adjacent in tour T(1,5), so the tour must be the
optimal tour from 1 to 4 (more convenently called "T(1,4)"), plus the segment
from 4 to 5.

=end comment

=item B<Finding C<T(2,5)-T(3,5)>>

Our logic for finding C<T(1,5)> applies to these cases as well.

=item B<Finding C<T(4,5)>>

Tour C<T(4,5)> breaks the pattern seen in C<T(0,5)> through C<T(3,5)>, because
the leftmost point (point 4) must be an endpoint in the tour.  Via proof by
contradiction similar to the above, our choices for constructing C<T(4,5)> are:

    T(0,4) + line segment from 0 to 5
    T(1,4) + line segment from 1 to 5
    T(2,4) + line segment from 2 to 5
    T(3,4) + line segment from 3 to 5

All of them meet our bitonicity requirements, so we choose the shortest of
these for C<T(4,5)>.

=back

To summarize the recurrence, and using function C<delta()> to calculate the
distance between points:

=over 5

=item if i < j-1:

C<< T(i,j) = T(i,j-1) + delta(j-1,j) >>

=item if i == j-1:

C<< T(i,j) = min{ T(k,i) + delta(k,j) } >>, for all k < i

=back

=item 3. The base case.

The open tour C<T(0,1)> has to be the line segment from 0 to 1.

=back

=head2 Dynamic Programming

This problem exhibits the classic features suggesting a dynamic programming
solution: I<overlapping subproblems> and I<optimal substructure>.

=head3 Overlapping Subproblems

The construction of tour C<T(i,j)> depends on knowledge of tours to the left of
C<j>:

    to construct:   one must know:
    -------------   --------------
    T(0,5)          T(0,4)
    T(1,5)          T(1,4)
    T(2,5)          T(2,4)
    T(3,5)          T(3,4)
    T(4,5)          T(0,4), T(1,4), T(2,4), T(3,4)

We also see that a given optimal tour is used I<more than once> in constructing
longer tours.  For example, C<T(1,4)> is used in the construction of both
C<T(1,5)> and C<T(4,5)>.

=head3 Optimal Substructure

As shown in the above analysis, constructing a given optimal tour depends on
knowledge of shorter "included" optimal tours; suboptimal tours are irrelevant.

=head1 EXERCISES

These exercises may clarify the above analysis.

=over 4

=item Exercise 1.

Consider the parallelogram ((0,0), (1,1), (2,0), (3,1)).

    a. Draw it on graph paper.
    b. Label points "0" through "3"
    c. Draw t[0,1].  Calculate its length.
    d. Draw t[0,2] and t[1,2].  Calculate their lengths.
    e. Draw t[0,3], t[1,3], and t[2,3].  Calculate their lengths.
    f. What is the optimal bitonic tour?
    g. Draw the suboptimal bitonic tour.
    h. Why does the above algorithm find the optimal tour,
       and not the suboptimal tour?

=item Exercise 2.

Repeat Exercise 1 with pentagon ((0,2), (1,0), (2,3), (3,0), (4,2)).

=back

=head1 METHODS

=head2 $class->new()

Constructs a new solution object.

Example:

    my $ts = Algorithm::TravelingSalesman::BitonicTour->new;

=cut

sub new {
    my $class = shift;
    my $self = bless { _tour => {}, _points => {} }, $class;
    return $self;
}

=head2 $ts->add_point($x,$y)

Adds a point at position (C<$x>, C<$y>) to be included in the solution.  Method
C<add_point()> checks to make sure that no two points have the same
I<x>-coordinate.  This method will C<croak()> with a descriptive error message
if anything goes wrong.

Example:

    # add point at position (x=2, y=3) to the problem
    $ts->add_point(2,3);

=cut

sub add_point {
    my $self = shift;
    my $valid = { type => SCALAR, regexp => $RE{num}{real} };
    my ($x, $y) = validate_pos(@_, ($valid) x 2);
    if (exists $self->_points->{$x}) {
        my $py = $self->_points->{$x};
        croak "FAIL: point ($x,$y) duplicates previous point ($x,$py)";
    }
    else {
        $self->_sorted_points(undef);   # clear any previous cache of sorted points
        $self->_points->{$x} = $y;
        return [$x, $y];
    }
}

=head2 $ts->N()

Returns the number of points that have been added to the object (mnemonic:
B<n>umber).

Example:

    print "I have %d points.\n", $ts->N;

=cut

sub N {
    my $self = shift;
    return scalar keys %{ $self->_points };
}

=head2 $ts->R()

Returns the index of the rightmost point that has been added to the object
(mnemonic: B<r>ightmost).  This is always one less than C<< $ts->N >>.

=cut

sub R {
    my $self = shift;
    die 'Problem has no rightmost point (N < 1)' if $self->N < 1;
    return $self->N - 1;
}


=head2 $ts->sorted_points()

Returns an array of points sorted by increasing I<x>-coordinate.  The first
("zeroI<th>") array element returned is thus the leftmost point in the problem.

Each point is represented as an arrayref containing (x,y) coordinates.  The
sorted array of points is cached, but the cache is cleared by each call to
C<add_point()>.

Example:

    my $ts = Algorithm::TravelingSalesman::BitonicTour->new;
    $ts->add_point(1,1);
    $ts->add_point(0,0);
    $ts->add_point(2,0);
    my @sorted = $ts->sorted_points;
    # @sorted contains ([0,0], [1,1], [2,0])

=cut

sub sorted_points {
    my $self = shift;
    unless ($self->_sorted_points) {
        my @x = sort { $a <=> $b } keys %{ $self->_points };
        my @p = map [ $_, $self->_points->{$_} ], @x;
        $self->_sorted_points(\@p);
    }
    return @{ $self->_sorted_points };
}

=head2 coord($n)

Returns an array containing the coordinates of point C<$n>.

Examples:

    my ($x0, $y0) = $ts->coord(0);   # coords of leftmost point
    my ($x1, $y1) = $ts->coord(1);   # coords of next point
    # ...
    my ($xn, $yn) = $ts->coord(-1);  # coords of rightmost point--CLEVER!

=cut

sub coord {
    my ($self, $n) = @_;
    return @{ ($self->sorted_points)[$n] };
}

=head2 $ts->solve()

Solves the problem as configured.  Returns a list containing the length of the
minimum tour, plus the coordinates of the points in the tour in traversal
order.

Example:

    my ($length, @points) = $ts->solve();
    print "length: $length\n";
    for (@points) {
        my ($x,$y) = @$_;
        print "($x,$y)\n";
    }

=cut

sub solve {
    my $self = shift;
    my ($length, @points);
    if ($self->N < 1) {
        die "ERROR: you need to add some points!";
    }
    elsif ($self->N == 1) {
        ($length, @points) = (0,0);
    }
    else {
        ($length, @points) = $self->optimal_closed_tour;
    }
    my @coords = map { [ $self->coord($_) ] } @points;
    return ($length, @coords);
}

=head2 $ts->optimal_closed_tour

Find the length of the optimal complete (closed) bitonic tour.  This is done by
choosing the shortest tour from the set of all possible complete tours.

A possible closed tour is composed of a partial tour with rightmost point C<R>
as one of its endpoints plus the final return segment from R to the other
endpoint of the tour.

    T(0,R) + delta(0,R)
    T(1,R) + delta(1,R)
    ...
    T(i,R) + delta(i,R)
    ...
    T(R-1,R) + delta(R-1,R)

=cut

sub optimal_closed_tour {
    my $self = shift;
    $self->populate_open_tours;
    my $R = $self->R;
    my @tours = map {
        my $cost = $self->tour_length($_,$self->R) + $self->delta($_,$self->R);
        my @points = ($self->tour_points($_,$R), $_);
        [ $cost, @points ];
    } 0 .. $self->R - 1;
    my $tour = reduce { $a->[0] < $b->[0] ? $a : $b } @tours;
    return @$tour;
}

=head2 $ts->populate_open_tours

Populates internal data structure C<tour($i,$j)> describing all possible
optimal open tour costs and paths for this problem configuration.

=cut

sub populate_open_tours {
    my $self = shift;

    # Base case: tour(0,1) has to be the segment (0,1).  It would be nice if
    # the loop indices handled this case correctly, but they don't.
    $self->tour_length(0, 1, $self->delta(0,1) );
    $self->tour_points(0, 1, 0, 1);

    # find optimal tours for all points to the left of 2, 3, ... up to R
    foreach my $k (2 .. $self->R) {

        # for each point "i" to the left of "k", find (and save) the optimal
        # open bitonic tour from "i" to "k".
        foreach my $i (0 .. $k - 1) {
            my ($len, @points) = $self->optimal_open_tour($i,$k);
            $self->tour_length($i, $k, $len);
            $self->tour_points($i, $k, @points);
        }
    }
}

=head2 $ts->optimal_open_tour($i,$j)

Determines the optimal open tour from point C<$i> to point C<$j>, based on the
values of previously calculated optimal tours to the left of C<$j>.

As discussed above, there are two distinct cases for this calculation: when C<<
$i == $j - 1 >> and when C<< $i < $j - 1 >>.

    # determine the length of and points in the tour
    # starting at point 20 and ending at point 25
    my ($length,@points) = $ts->optimal_open_tour(20,25);

=cut

sub optimal_open_tour {
    my ($self, $i, $j) = @_;
    local $" = q(,);

    # we want $i to be strictly less than $j (we can actually be more lax with
    # the inputs, but this stricture halves our storage needs)
    croak "ERROR: bad call, optimal_open_tour(@_)" unless $i < $j;

    # if $i and $j are adjacent, many valid bitonic tours (i => x => j) are
    # possible; choose the shortest one.
    return $self->optimal_open_tour_adjacent($i, $j) if $i + 1 == $j;

    # if $i and $j are NOT adjacent, then only one bitonic tour (i => j-1 => j)
    # is possible.
    return $self->optimal_open_tour_nonadjacent($i, $j) if $i + 1 < $j;

    croak "ERROR: bad call, optimal_open_tour(@_)";
}

=head2 $obj->optimal_open_tour_adjacent($i,$j)

Uses information about optimal open tours to the left of <$j> to find the
optimal tour with endpoints (C<$i>, C<$j>).

This method handles the case where C<$i> and C<$j> are adjacent, i.e.  C<< $i =
$j - 1 >>.  In this case there are many possible bitonic tours, all going from
C<$i> to "C<$x>" to C<$j>.  All points C<$x> in the range C<(0 .. $i - 1)> are
examined to find the optimal tour.

=cut

sub optimal_open_tour_adjacent {
    my ($self, $i, $j) = @_;
    my @tours = map {
        my $x = $_;
        my $len = $self->tour_length($x,$i) + $self->delta($x,$j);
        my @path = reverse($j, $self->tour_points($x, $i) );
        [ $len, @path ];
    } 0 .. $i - 1;
    my $min_tour = reduce { $a->[0] < $b->[0] ? $a : $b } @tours;
    return @$min_tour;
}

=head2 $obj->optimal_open_tour_nonadjacent($i,$j)

Uses information about optimal open tours to the left of <$j> to find the
optimal tour with endpoints (C<$i>, C<$j>).

This method handles the case where C<$i> and C<$j> are not adjacent, i.e.  C<<
$i < $j - 1 >>.  In this case there is only one bitonic tour possible, going
from C<$i> to C<$j-1> to C<$j>.

=cut

sub optimal_open_tour_nonadjacent {
    my ($self, $i, $j) = @_;
    my $len = $self->tour_length($i, $j - 1) + $self->delta($j - 1,$j);
    my @points = ($self->tour_points($i, $j - 1), $j);
    return($len, @points);
}


=head2 $b->tour($i,$j)

Returns the data structure associated with the optimal open bitonic tour with
endpoints (C<$i>, C<$j>).

=cut

sub tour {
    my ($self, $i, $j) = @_;
    croak "ERROR: tour($i,$j) ($i >= $j)"
        unless $i < $j;
    croak "ERROR: tour($i,$j,...) ($j >= @{[ $self->N ]})"
        unless $j < $self->N;
    $self->_tour->{$i}{$j} = [] unless $self->_tour->{$i}{$j};
    return $self->_tour->{$i}{$j};
}

=head2 $b->tour_length($i, $j, [$len])

Returns the length of the optimal open bitonic tour with endpoints (C<$i>,
C<$j>).  If C<$len> is specified, set the length to C<$len>.

=cut

sub tour_length {
    my $self = shift;
    my $i    = shift;
    my $j    = shift;
    if (@_) {
        croak "ERROR: tour_length($i,$j,$_[0]) has length <= 0 ($_[0])"
            unless $_[0] > 0;
        $self->tour($i,$j)->[0] = $_[0];
    }
    if (exists $self->tour($i,$j)->[0]) {
        return $self->tour($i,$j)->[0];
    }
    else {
        croak "Don't know the length of tour($i,$j)";
    }
}

=head2 $b->tour_points($i, $j, [@points])

Returns an array containing the indices of the points in the optimal open
bitonic tour with endpoints (C<$i>, C<$j>).

If C<@points> is specified, set the endpoints to C<@points>.

=cut

sub tour_points {
    my $self = shift;
    my $i    = shift;
    my $j    = shift;
    if (@_) {
        croak "ERROR: tour_points($i,$j,@_) ($i != first point)"
            unless $i == $_[0];
        croak "ERROR: tour_points($i,$j,@_) ($j != last point)"
            unless $j == $_[-1];
        croak "ERROR: tour_points($i,$j,@_) (wrong number of points in @_)"
            unless scalar(@_) == $j + 1;
        $self->tour($i,$j)->[1] = \@_;
    }
    if (exists $self->tour($i,$j)->[1]) {
        return @{ $self->tour($i,$j)->[1] };
    }
    else {
        croak "Don't know the points for tour($i,$j)";
    }
}

=head2 $b->delta($p1,$p2);

Returns the euclidean distance from point C<$p1> to point C<$p2>.

Examples:

    # print the distance from the leftmost to the next point
    print $b->delta(0,1);
    # print the distance from the leftmost to the rightmost point
    print $b->delta(0,-1);

=cut

sub delta {
    my ($self, $p1, $p2) = @_;
    my ($x1, $y1) = $self->coord($p1);
    my ($x2, $y2) = $self->coord($p2);
    return sqrt((($x1-$x2)*($x1-$x2))+(($y1-$y2)*($y1-$y2)));
}


=head1 RESOURCES

=over 4

=item

Cormen, Thomas H.; Leiserson, Charles E.; Rivest, Ronald L.; Stein, Clifford
(2001). Introduction to Algorithms, second edition, MIT Press and McGraw-Hill.
ISBN 978-0-262-53196-2.

=item

Bentley, Jon L. (1990), "Experiments on traveling salesman heuristics", Proc.
1st ACM-SIAM Symp. Discrete Algorithms (SODA), pp. 91-99,
L<http://portal.acm.org/citation.cfm?id=320186>.

=item

L<http://en.wikipedia.org/wiki/Bitonic_tour>

=item

L<http://en.wikipedia.org/wiki/Traveling_salesman_problem>

=item

L<http://www.tsp.gatech.edu/>

=item

L<http://en.wikipedia.org/wiki/Dynamic_programming>

=back

=head1 AUTHOR

John Trammell, C<< <johntrammell at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cormen-bitonic at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-TravelingSalesman-BitonicTour>.
I will be notified, and then you'll automatically be notified of progress on
your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::TravelingSalesman::BitonicTour

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-TravelingSalesman-BitonicTour>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-TravelingSalesman-BitonicTour>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-TravelingSalesman-BitonicTour>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-TravelingSalesman-BitonicTour>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 John Trammell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

