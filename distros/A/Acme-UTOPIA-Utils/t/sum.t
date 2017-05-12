use Test::More;
use Test::Number::Delta;

BEGIN {
  use_ok( 'Acme::UTOPIA::Utils' );
  Acme::UTOPIA::Utils->import( qw( sum ) );
}

is( sum( 34, 21, 99 ), 154, 'Small positive numbers sum correctly' );
is( sum( -33, 2, 0, 12, 5 ), -14, 'Small positive and negatives sum correctly' );
is( sum(), 0, 'No args should equal 0' );
is( sum('foo', 9, 'bar', -2), 7,
  'String args should be disregarded' );
delta_ok( sum( 0.74, 0.99, 0.002 ), 1.732,
  'Sum of floats within a reasonable tolerance' );
delta_within( sum( 12 ** 12, 5 ** 25 ), 2.98032139977401381e+17,
  100, 'Huge numbers summed to an accuracy within 100' ); # Good enough for jazz.

&done_testing;
