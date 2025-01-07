#!perl
use strict;
use warnings;

use Test::More;
use Test::Differences;

BEGIN { use_ok('Data::Difference', 'data_diff'); }

my @tests = (
  {a => undef, b => undef, out => []},
  {a => 1,     b => 2,     out => [{path => [], a => 1, b => 2}]},
  {a => [1, 2, 3], b => [1, 2], out => [{path => [2], a => 3}]},
  {a => [1, 2], b => [1, 2, 3], out => [{path => [2], b => 3}]},
  { a   => { k => undef },
    b   => { k => 1 },
    out => [
      { path => ['k'], a => undef, b => 1 }
    ]
  },
  { a   => { k => 1 },
    b   => { k => undef },
    out => [
      { path => ['k'], a => 1, b => undef }
    ]
  },
  { a   => [ undef ],
    b   => [ 1 ],
    out => [
      { path => ['0'], a => undef, b => 1 }
    ]
  },
  { a   => [ 1 ],
    b   => [ undef ],
    out => [
      { path => ['0'], a => 1, b => undef }
    ]
  },
  { a   => {Q => 1, W => 2, E => 3},
    b   => {W => 4, E => 3, R => 5},
    out => [  ##
      {path => ['Q'], a => 1},
      {path => ['R'], b => 5},
      {path => ['W'], a => 2, b => 4},
    ]
  },
);

for my $i (0 .. $#tests) {
  my $t = $tests[$i];
  eq_or_diff(
    [data_diff($t->{a}, $t->{b})],
    $t->{out},
    "\$tests[$i]"
  );
}

done_testing();
