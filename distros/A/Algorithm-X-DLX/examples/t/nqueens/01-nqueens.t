#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../nqueens/" }
use NQueens;
BEGIN { shift @INC }

subtest 'zero' => sub {
  plan tests => 1;
  dies_ok { NQueens->new(0) } 'assertion';
};

subtest 'count solutions' => sub {
  plan tests => 10;
  is(1,   NQueens->new(1)->count_solutions(), '1 queen');
  is(0,   NQueens->new(2)->count_solutions(), '1 queen');
  is(0,   NQueens->new(3)->count_solutions(), '1 queen');
  is(2,   NQueens->new(4)->count_solutions(), '1 queen');
  is(10,  NQueens->new(5)->count_solutions(), '1 queen');
  is(4,   NQueens->new(6)->count_solutions(), '1 queen');
  is(40,  NQueens->new(7)->count_solutions(), '1 queen');
  is(92,  NQueens->new(8)->count_solutions(), '1 queen');
  is(352, NQueens->new(9)->count_solutions(), '1 queen');
  is(724, NQueens->new(10)->count_solutions(), '1 queen');
};

subtest 'find_solutions' => sub {
  plan tests => 3;
  ok(@{NQueens->new(2)->find_solutions()} == 0, 'empty array');
  is_deeply([[0]], NQueens->new(1)->find_solutions(), '1 solution');

  sub sort_AoA_by_content {join(',', @$a) cmp join(',', @$b)}
  my @n4 = sort sort_AoA_by_content @{NQueens->new(4)->find_solutions()};
  is_deeply([[1, 3, 0, 2], [2, 0, 3, 1]], \@n4, '4 queens');
};

done_testing();

