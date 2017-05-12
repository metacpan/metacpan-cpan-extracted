use Test::More tests => 11;
BEGIN { use_ok('Data::COW'); }

my $array = [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ] ];
my $base  = [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ] ];

my $new = make_cow_ref $array;

ok(tied @$new, "tie worked");

is($new->[1][1], 5, "new array reflects old one");
is_deeply($array, $base, "original is untouched");

$new->[0][0] = 2;
is($new->[0][0], 2, "successfully changed");
is_deeply($array, $base, "original is untouched");

$new->[2][1] = 6;
is($new->[2][1], 6, "successfully changed");
is($new->[0][0], 2, "the first one is still changed");

$new->[3] = 10;
is(scalar @$new, 4, "autovivi");
is($new->[3], 10, "we actually put something there");
is_deeply($array, $base, "original is untouched");

# vim: ft=perl :
