use warnings;
use 5.010;
use strict;

use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Bio::Gonzales::Matrix::Util', 'preview' ); }

my @test = (
  [ 'a' .. 'c' ],
  [ 'd' .. 'f' ],
  [ 'g' .. 'i' ],
  [ 'j' .. 'm' ],
  [ 'n' .. 'q' ],
  [ 'r' .. 't' ],
  [ 'u' .. 'w' ],
  [ 'x' .. 'z' ],
);

my @test_res = (
  [ 'a' .. 'c' ],
  [ 'd' .. 'f' ],
  [ 'g' .. 'i' ],
  [ '...', '...', '...' ],
  [ 'r' .. 't' ],
  [ 'u' .. 'w' ],
  [ 'x' .. 'z' ],
);

is_deeply( preview( \@test, { dots => 1} ), \@test_res );

done_testing();
