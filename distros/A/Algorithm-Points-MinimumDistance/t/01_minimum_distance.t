use strict;
use Test::More tests => 19;

use_ok( "Algorithm::Points::MinimumDistance" );

my @points = ( [1, 3], [2, 3], [3, 1], [5, 7] );
my $dists = Algorithm::Points::MinimumDistance->new( points  => \@points,
                                      boxsize => 4 );
isa_ok( $dists, "Algorithm::Points::MinimumDistance" );

# Test that ->box is performing sanely.
my @box = $dists->box( [1, 3] );
is_deeply( \@box, [0, 0], "right box for [1, 3]" );
@box = $dists->box( [2, 3] );
is_deeply( \@box, [0, 0], "...and for [2, 3]" );
@box = $dists->box( [3, 1] );
is_deeply( \@box, [0, 0], "...and for [3, 1]" );
@box = $dists->box( [5, 7] );
is_deeply( \@box, [4, 4], "...and for [5, 7]" );

# Test that things are going in to the right region.
$dists = Algorithm::Points::MinimumDistance->new( points  => \@points,
                                   boxsize => 2 );
my $points = $dists->region( centre => [2, 4] );
my %reghash = map { join(",", @$_) => 1 } @$points;
ok( $reghash{"1,3"}, "[1, 3] is in region centred on box [2, 4]" );
ok( $reghash{"2,3"}, "...as is [2, 3]" );
ok( $reghash{"5,7"}, "...as is [5, 7]" );
ok( !$reghash{"3,1"}, "...but not [3, 1]" );

# Now test actual distance finding.
is( $dists->distance( point => [1, 3] ), 1,
    "->distance returns distance to [2, 3] when called on [1, 3]" );
is( $dists->distance( point => [5, 7] ), 2,
    "->distance returns boxsize when called on [5, 7]" );
is( $dists->min_distance, 1, "->min_distance returns 1" );

# Try it with a huge box size (so distances get worked out for all points).
$dists = Algorithm::Points::MinimumDistance->new( points  => \@points,
                                   boxsize => 10 );
is( $dists->distance( point => [1, 3] ), 1,
    "->distance returns distance to [2, 3] when called on [1, 3]" );
is( $dists->distance( point => [5, 7] ), 5,
    "->distance returns distance to [2, 3] when called on [5, 7]" );
is( $dists->min_distance, 1, "->min_distance returns 1" );

# Try it with a small box size.
$dists = Algorithm::Points::MinimumDistance->new( points  => \@points,
                                   boxsize => 1 );
is( $dists->distance( point => [1, 3] ), 1,
    "->distance returns distance to [2, 3] when called on [1, 3]" );
is( $dists->distance( point => [5, 7] ), 1,
    "->distance returns boxsize when called on [5, 7]" );
is( $dists->min_distance, 1, "->min_distance returns 1" );


__END__

8

7                   x

6

5

4

3   x   x

2

1           x

0   1   2   3   4   5   6   7   8



# 9 + 16 = 25

