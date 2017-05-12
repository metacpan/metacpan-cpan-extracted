# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

use integer

# ----------------------------------------------------------------------

# $i ** $j (mod $n)
sub exp_mod:
    my ($i, $j, $n) = @_
    my $r = 1
    while $j:
        if $j % 2:
            $r = $i*$r % $n
        $j >>= 1
        $i = $i**2 % $n
    return $r

is exp_mod(3, 2, 7), 2
is exp_mod(7, 2, 43), 6
is exp_mod(9, 4, 6561), 0

# ----------------------------------------------------------------------

sub gcd:
    my ($a, $b) = @_
    my $r
    do:
        ($a, $b) = ($b, $a % $b)
    while $b
    return $a

is gcd(12, 1), 1
is gcd(1, 12), 1
is gcd(21, 12), 3
is gcd(49, 91), 7

# ----------------------------------------------------------------------

sub is_prime:
    my $n = shift
    return 1 if $n <= 3
    return 0 unless $n % 2

    my $a = int(rand($n - 3)) + 2
    return 0 if gcd($a, $n) > 1

    # find the greatest odd divisor of $n - 1
    # $n - 1 = 2^$k*$x is an invariant
    my $x = $n - 1 # even
    my $k = 0
    do:
        $x /= 2
        ++$k
    until $x % 2

    my $b = exp_mod($a, $x, $n)
    return 1 if $b == 1

    my $c = $b
    for 1..$k:
        $b = exp_mod($b, 2, $n)
        if $b == 1:
            last
        else:
            $c = $b

    return 0 if $b != 1

    my $d = gcd($c + 1, $n)
    return $d == 1 || $d == $n ? 1 : 0


is is_prime(2), 1
is is_prime(3), 1
is is_prime(16), 0
is is_prime(99), 0
is is_prime(647), 1
is is_prime(4900), 0
is is_prime(7919), 1


sub eratostenes:
    my $num = shift 
    $num or die 'Dona\'m un enter, si us plau'

    # creo les dues llistes per emmagatzemar els
    # primers i els nombres
    my @primers
    my @nombres
    
    # afegeixo a la llista cadascun dels nombres
    for my $i in 2..$num:
	   push(@nombres, $i)
	
    push(@primers, shift(@nombres))

    # mentres el quadrat del nombre més gran
    # dels primers sigui més petit que el nombre
    # més gran de la llista, esborra els múltiples
    # del primer més gran a la llista de nombres
    while @nombres && ($primers[-1] ** 2) <= $nombres[-1]:
        @nombres = grep:
	        $_ % $primers[-1]
	    @nombres
	   push(@primers, shift(@nombres))


    return join(',', @primers, @nombres)
    
is eratostenes(2), "2"
is eratostenes(3), "2,3"
is eratostenes(5), "2,3,5"
is eratostenes(6), eratostenes(5)
is eratostenes(49), "2,3,5,7,11,13,17,19,23,29,31,37,41,43,47" 
is eratostenes(50), eratostenes(49)

# ----------------------------------------------------------------------

sub bubblesort:
    my $array = shift
    for my $i = $#$array; $i; $i--:
        for my $j = 1; $j <= $i; $j++:
            if $array->[$j-1] > $array->[$j]:
                @$array[$j, $j-1] = @$array[$j-1, $j]

my @a = 1..10
bubblesort \@a
is_deeply \@a, [sort { $a <=> $b } @a]

@a = (1,2,3,2,-1)
bubblesort \@a
is_deeply \@a, [sort { $a <=> $b } @a]

@a = reverse 50..100
bubblesort \@a
is_deeply \@a, [sort { $a <=> $b } @a]

# ----------------------------------------------------------------------


# These subroutines are ports to Acme::Pythonic from the ones in
# "Mastering Algorithms with Perl" except the last one, which I fixed
# myself. The one in the book is buggy.

sub basic_tree_find:
    my ($tree_link, $target, $cmp) = @_
    my $node

    while $node = $$tree_link:
        no warnings
        my $relation = defined $cmp ? $cmp->($target, $node->{val}) \
                                    : $target <=> $node->{val}
        return ($tree_link, $node) if $relation == 0
        $tree_link = $relation > 0 ? \$node->{left} : \$node->{right}

    return ($tree_link, undef)

sub basic_tree_add:
    my ($tree_link, $target, $cmp) = @_
    my $found

    ($tree_link, $found) = basic_tree_find($tree_link, $target, $cmp)
    unless $found:
        $found = {left  => undef,
                  right => undef,
                  val   => $target}
        $$tree_link = $found

    return $found

sub basic_tree_del:
    my ($tree_link, $target, $cmp) = @_
    my $found

    ($tree_link, $found) = basic_tree_find($tree_link, $target, $cmp)
    return undef unless $found
    if ! defined $found->{left}:
        $$tree_link = $found->{right}
    elsif ! defined $found->{right}:
        $$tree_link = $found->{left}
    else:
        MERGE_SOMEHOW($tree_link, $found)

    return $found->{val}

sub MERGE_SOMEHOW:
    my ($tree_link, $found) = @_
    my $left_of_right = $found->{right}
    my $next_left

    $left_of_right = $next_left \
        while $next_left = $left_of_right->{left}

    $left_of_right->{left} = $found->{left}

    $$tree_link = $found->{right}


# ----------------------------------------------------------------------
#
# Now I will port the next subroutines meticulously from the listings in
# the book, respecting comments, whitespace, etc. Except in one place.
#
# ----------------------------------------------------------------------

# manhattan_intersection( @lines )
#   Find the intersection of strictly horizontal and vertical lines.
#   Requires basic_tree_add(), basic_tree_del(), and basic_tree_find(),
#   all defined in Chapter 3, Advanced Data Structures
sub manhattan_intersection:
    my @op # The coordinates are transformed here as operations.

    while @_:
        my @line = splice @_, 0, 4

        if $line[1] == $line[3]:        # Horizontal.
            push @op, [ @line, \&range_check_tree ]
        else:
            # Swap if upside down.
            @line = @line[0, 3, 2, 1] if $line[1] > $line[3]

            push @op, [ @line[0, 1, 2, 1], \&basic_tree_add ]
            push @op, [ @line[0, 3, 2, 3], \&basic_tree_del ]

    my $x_tree # The range check tree.
    # The x coordinate comparison routine.
    my $compare_x = sub { $_[0]->[0] <=> $_[1]->[0] }
    my @intersect # The intersections.

    # We don't reproduce the multi-line here because parens are not put correctly.
    foreach my $op in sort { $a->[1] <=> $b->[1] || $a->[4] == \&range_check_tree || $a->[0] <=> $b->[0] } @op:
        if $op->[4] == \&range_check_tree:
            push @intersect, $op->[4]->( \$x_tree, $op, $compare_x )
        else: # Add or delete.
            $op->[4]->( \$x_tree, $op, $compare_x )

    return @intersect


#
# The implementation of range_check_tree() in the book is buggy, I
# submitted the bug to the authors.
#

# range_check_tree( $tree_link, $horizontal, $compare )
#
#    Returns the list of tree nodes that are within the limits
#    $horizontal->[0] and $horizontal->[1]. Depends on the binary
#    trees of Chapter 3, Advanced Data Structures.
sub range_check_tree:
    my ( $tree, $horizontal, $compare ) = @_

    my @range         = ()     # The return value.
    my $node          = $$tree
    my $vertical_x    = $node->{val}
    my $horizontal_lo = [ $horizontal->[ 0 ] ]
    my $horizontal_hi = [ $horizontal->[ 2 ] ]

    return unless defined $$tree

    push @range, range_check_tree( \$node->{left}, $horizontal, $compare ) \
        if defined $node->{left}

    push @range, $vertical_x->[ 0 ], $horizontal->[ 1 ] \
         if $compare->( $horizontal_lo, $vertical_x ) <= 0 && \
            $compare->( $horizontal_hi, $vertical_x ) >= 0

    push @range, range_check_tree( \$node->{right}, $horizontal,
                                   $compare ) \
        if defined $node->{right}

    return @range

my @lines = (0, 0, 0, 1)
is_deeply [manhattan_intersection(@lines)], []

@lines = (0, 0, 1, 0)
is_deeply [manhattan_intersection(@lines)], []

@lines = (0, 0, 1, 0, 0, 1, 1, 1, 0, 2, 1, 2)
is_deeply [manhattan_intersection(@lines)], []

@lines = (0, 0, 0, 1, 1, 0, 1, 1, 2, 0, 2, 1)
is_deeply [manhattan_intersection(@lines)], []

@lines = (0, 1, 2, 1, 1, 0, 1, 2)
is_deeply [manhattan_intersection(@lines)], [1, 1]

# This is the example in the book.
@lines = ( 1, 6,  1, 3,  1, 2,  3, 2,  1, 1,  4, 1,
              2, 4,  7, 4,  3, 0,  3, 6,  4, 3,  4, 7,
              5, 7,  5, 4,  5, 2,  7, 2 )
# And this is the correct answer, check Figure 10-10, which is right.
is_deeply [manhattan_intersection(@lines)], [3, 1, 3, 2, 5, 4, 4, 4, 3, 4]
