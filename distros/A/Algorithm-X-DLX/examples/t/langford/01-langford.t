#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../langford/" }
use Langford;
BEGIN { shift @INC }

use Algorithm::X::DLX;

subtest 'count solutions' => sub {
  plan tests => 1;
  is(0, Algorithm::X::DLX->new(Langford->new(1)->problem())->count_solutions(), 'n = 1');
};

subtest 'find solutions' => sub {
  plan tests => 3;
  ok(@{Algorithm::X::DLX->new(Langford->new(1)->problem())->find_solutions()} == 0, 'empty array');

  my $langford = Langford->new(3);
  my $used_rows = Algorithm::X::DLX->new($langford->problem())->find_solutions();
  is(1, @$used_rows, 'has one solution');
  is_deeply([3, 1, 2, 1, 3, 2], $langford->make_solution($used_rows->[0]), '1st solution');
};

done_testing();

