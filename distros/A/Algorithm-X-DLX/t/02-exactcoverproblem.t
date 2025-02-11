#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use Algorithm::X::ExactCoverProblem;

# Tests

subtest 'constructor' => sub {
  plan tests => 7;
  throws_ok { Algorithm::X::ExactCoverProblem->new(0, [[0]]) }    qr/column out of range/i, 'size mismatch';
  throws_ok { Algorithm::X::ExactCoverProblem->new(1, [[1]]) }    qr/column out of range/i, 'size mismatch';
  throws_ok { Algorithm::X::ExactCoverProblem->new(5, [[5]]) }    qr/column out of range/i, 'size mismatch';
  throws_ok { Algorithm::X::ExactCoverProblem->new(1, [[0, 0]]) } qr/duplicate columns/i, 'duplicate columns';

  lives_ok { Algorithm::X::ExactCoverProblem->new(1, [[0]]) } 'size matches';
  lives_ok { Algorithm::X::ExactCoverProblem->new(2, [[1]]) } 'size matches';
  lives_ok { Algorithm::X::ExactCoverProblem->new(6, [[5]]) } 'size matches';
};

subtest 'dense matrix' => sub {
  plan tests => 9;
  throws_ok { Algorithm::X::ExactCoverProblem->dense([[0], []]) }    qr/rows have different lengths/i, 'row size mismatch';
  throws_ok { Algorithm::X::ExactCoverProblem->dense([[2]]) }    qr/dense matrix must contain only 0s and 1s/i, 'non boolean content';
  throws_ok { Algorithm::X::ExactCoverProblem->dense([[0], 2]) }    qr/Can't use string \("2"\) as an ARRAY ref/i, 'corrupted matrix';

  lives_ok { Algorithm::X::ExactCoverProblem->dense([]) } 'size matches';
  lives_ok { Algorithm::X::ExactCoverProblem->dense([[], []]) } 'size matches';
  lives_ok { Algorithm::X::ExactCoverProblem->dense([[0], [1]]) } 'size matches';
  lives_ok { Algorithm::X::ExactCoverProblem->dense([[0]], 1) } 'size matches';

  is 0, Algorithm::X::ExactCoverProblem->dense([[]])->width(), 'empty matrix width';
  is 2, Algorithm::X::ExactCoverProblem->dense([[0, 0]])->width(), 'column count';
};

done_testing();

