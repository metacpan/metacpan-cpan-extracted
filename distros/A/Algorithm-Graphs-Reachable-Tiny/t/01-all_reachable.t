use strict;
use warnings;

use Algorithm::Graphs::Reachable::Tiny qw(all_reachable);

use Test::More tests => 36;

## use Data::Dumper;

{
  # Empty input
  is_deeply(all_reachable({}, {}), {}, "all_reachable({}, {})");
  is_deeply(all_reachable({}, []), {}, "all_reachable({}, {})");

  is_deeply(all_reachable([], {}), {}, "all_reachable([], {})");
  is_deeply(all_reachable([], []), {}, "all_reachable([], {})");
}

{
  note("Graph as HASH");
  my %g = (
           0 => {1 => undef},
           1 => {2 => undef, 4 => undef},
           2 => {3 => undef},
           4 => {5 => undef},
           6 => {7 => undef},
           7 => {8 => undef},
           8 => {9 => undef},
           9 => {7 => undef, 10 => undef}
          );
  is_deeply(all_reachable(\%g, {}), {}, "nodes = {}");
  is_deeply(all_reachable(\%g, []), {}, "nodes = []");
  is_deeply(all_reachable(\%g, {unknown => undef}), {unknown => undef}, "nodes = {'unknown'}");
  is_deeply(all_reachable(\%g, ['unknown']),        {unknown => undef}, "nodes = ['unknown']");
  {
    my %expected = (
                    4  => undef,
                    5  => undef,
                    7  => undef,
                    8  => undef,
                    9  => undef,
                    10 => undef,
                   );
    is_deeply(all_reachable(\%g, {4 => undef, 7 => undef}), \%expected, "non-trivial 1 hash");
    is_deeply(all_reachable(\%g, [4, 7]),                   \%expected, "non-trivial 1 array");

    is_deeply(all_reachable(\%g, {4 => undef, 9 => undef}), \%expected, "non-trivial 2 hash");
    is_deeply(all_reachable(\%g, [4, 9]),                   \%expected, "non-trivial 2 array");

    my %exp_all = map {$_ => undef} (0 .. 10);
    is_deeply(all_reachable(\%g, {0 => undef, 6 => undef}), \%exp_all, "non-trivial 3 hash");
    is_deeply(all_reachable(\%g, [0, 6]),                   \%exp_all, "non-trivial 3 array");

    $expected{unknown} = undef;
    is_deeply(all_reachable(\%g, {4 => undef, 7 => undef, unknown => undef}),
              \%expected, "with 'unknown' in hash");
    is_deeply(all_reachable(\%g, ['unknown', 4, 7]),
              \%expected, "with 'unknown' in array");
  }
} # 12



{
  note("Graph as ARRAY, with empty hashes");
  my @g = (
           {1 => undef},
           {2 => undef, 4 => undef},
           {3 => undef},
           {},
           {5 => undef},
           {},
           {7 => undef},
           {8 => undef},
           {9 => undef},
           {7 => undef, 10 => undef}
          );
  is_deeply(all_reachable(\@g, {}), {}, "nodes = {}");
  is_deeply(all_reachable(\@g, []), {}, "nodes = []");
  {
    my %expected = (
                    4  => undef,
                    5  => undef,
                    7  => undef,
                    8  => undef,
                    9  => undef,
                    10 => undef,
                   );
    is_deeply(all_reachable(\@g, {4 => undef, 7 => undef}), \%expected, "non-trivial 1 hash");
    is_deeply(all_reachable(\@g, [4, 7]),                   \%expected, "non-trivial 1 array");

    is_deeply(all_reachable(\@g, {4 => undef, 9 => undef}), \%expected, "non-trivial 2 hash");
    is_deeply(all_reachable(\@g, [4, 9]),                   \%expected, "non-trivial 2 array");

    my %exp_all = map {$_ => undef} (0 .. 10);
    is_deeply(all_reachable(\@g, {0 => undef, 6 => undef}), \%exp_all, "non-trivial 3 hash");
    is_deeply(all_reachable(\@g, [0, 6]),                   \%exp_all, "non-trivial 3 array");

    $expected{3} = undef;
    $expected{100} = undef;
    is_deeply(all_reachable(\@g, {4 => undef, 7 => undef, 3 => undef, 100 => undef}),
              \%expected, "with 3 and 100 in hash");
    is_deeply(all_reachable(\@g, [3, 100, 4, 7]),
              \%expected, "with 3 and 100 in array");
  }
} #10



{
  note("Graph as ARRAY, with undef");
  my @g = (
           {1 => undef},
           {2 => undef, 4 => undef},
           {3 => undef},
           undef,
           {5 => undef},
           undef,
           {7 => undef},
           {8 => undef},
           {9 => undef},
           {7 => undef, 10 => undef}
          );
  is_deeply(all_reachable(\@g, {}), {}, "nodes = {}");
  is_deeply(all_reachable(\@g, []), {}, "nodes = []");
  {
    my %expected = (
                    4  => undef,
                    5  => undef,
                    7  => undef,
                    8  => undef,
                    9  => undef,
                    10 => undef,
                   );
    is_deeply(all_reachable(\@g, {4 => undef, 7 => undef}), \%expected, "non-trivial 1 hash");
    is_deeply(all_reachable(\@g, [4, 7]),                   \%expected, "non-trivial 1 array");

    is_deeply(all_reachable(\@g, {4 => undef, 9 => undef}), \%expected, "non-trivial 2 hash");
    is_deeply(all_reachable(\@g, [4, 9]),                   \%expected, "non-trivial 2 array");

    my %exp_all = map {$_ => undef} (0 .. 10);
    is_deeply(all_reachable(\@g, {0 => undef, 6 => undef}), \%exp_all, "non-trivial 3 hash");
    is_deeply(all_reachable(\@g, [0, 6]),                   \%exp_all, "non-trivial 3 array");

    $expected{3} = undef;
    $expected{100} = undef;
    is_deeply(all_reachable(\@g, {4 => undef, 7 => undef, 3 => undef, 100 => undef}),
              \%expected, "with 3 and 100 in hash");
    is_deeply(all_reachable(\@g, [3, 100, 4, 7]),
              \%expected, "with 3 and 100 in array");
  }
} #10


