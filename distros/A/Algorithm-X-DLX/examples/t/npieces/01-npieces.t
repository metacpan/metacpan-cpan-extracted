#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../npieces/" }
use NPieces;
BEGIN { shift @INC }

subtest 'zero pieces' => sub {
  plan tests => 3;
  is(1, NPieces->new()->count_solutions(), '0x0');
  is(1, NPieces->new()->size(1)->count_solutions(), '1x1');
  is(1, NPieces->new()->size(2, 3)->count_solutions(), '2x3');
};

subtest 'knights' => sub {
  plan tests => 32;
  is(1, NPieces->new()->size(1)->knights(0)->count_solutions(), 'no knight on 1x1');
  is(1, NPieces->new()->size(1)->knights(1)->count_solutions(), '1 knight on 1x1');
  is(0, NPieces->new()->size(1)->knights(2)->count_solutions(), '2 knights on 1x1');

  is(1, NPieces->new()->size(2, 1)->knights(0)->count_solutions(), 'no knight on 2x1');
  is(2, NPieces->new()->size(2, 1)->knights(1)->count_solutions(), '1 knight on 2x1');
  is(1, NPieces->new()->size(2, 1)->knights(2)->count_solutions(), '2 knights on 2x1');
  is(0, NPieces->new()->size(2, 1)->knights(3)->count_solutions(), '3 knights on 2x1');

  is(1, NPieces->new()->size(1, 2)->knights(0)->count_solutions(), 'no knight on 1x2');
  is(2, NPieces->new()->size(1, 2)->knights(1)->count_solutions(), '1 knight on 1x2');
  is(1, NPieces->new()->size(1, 2)->knights(2)->count_solutions(), '2 knights on 1x2');
  is(0, NPieces->new()->size(1, 2)->knights(3)->count_solutions(), '3 knights on 1x2');

  is(1, NPieces->new()->size(3, 1)->knights(0)->count_solutions(), 'no knight on 3x1');
  is(3, NPieces->new()->size(3, 1)->knights(1)->count_solutions(), '1 knight on 3x1');
  is(3, NPieces->new()->size(3, 1)->knights(2)->count_solutions(), '2 knights on 3x1');
  is(1, NPieces->new()->size(3, 1)->knights(3)->count_solutions(), '3 knights on 3x1');
  is(0, NPieces->new()->size(3, 1)->knights(4)->count_solutions(), '4 knights on 3x1');

  is(1, NPieces->new()->size(4, 1)->knights(0)->count_solutions(), 'no knight on 4x1');
  is(4, NPieces->new()->size(4, 1)->knights(1)->count_solutions(), '1 knight on 4x1');
  is(6, NPieces->new()->size(4, 1)->knights(2)->count_solutions(), '2 knights on 4x1');
  is(4, NPieces->new()->size(4, 1)->knights(3)->count_solutions(), '3 knights on 4x1');
  is(1, NPieces->new()->size(4, 1)->knights(4)->count_solutions(), '4 knights on 4x1');
  is(0, NPieces->new()->size(4, 1)->knights(5)->count_solutions(), '5 knights on 4x1');

  is(1, NPieces->new()->size(2)->knights(0)->count_solutions(), 'no knight on 2x2');
  is(4, NPieces->new()->size(2)->knights(1)->count_solutions(), '1 knight on 2x2');
  is(6, NPieces->new()->size(2)->knights(2)->count_solutions(), '2 knights on 2x2');
  is(4, NPieces->new()->size(2)->knights(3)->count_solutions(), '3 knights on 2x2');
  is(1, NPieces->new()->size(2)->knights(4)->count_solutions(), '4 knights on 2x2');
  is(0, NPieces->new()->size(2)->knights(5)->count_solutions(), '5 knights on 2x2');

  is(1, NPieces->new()->size(2, 3)->knights(0)->count_solutions(), 'no knight on 2x3');
  is(6, NPieces->new()->size(2, 3)->knights(1)->count_solutions(), '1 knight on 2x3');
  is(13, NPieces->new()->size(2, 3)->knights(2)->count_solutions(), '2 knights on 2x3');

  is(64, NPieces->new()->size(8)->knights(1)->count_solutions(), '1 knight on 8x8');
};

subtest 'queens' => sub {
  plan tests => 14;
  is(1, NPieces->new()->size(1)->queens(0)->count_solutions(), 'no queen on 1x1');
  is(1, NPieces->new()->size(1)->queens(1)->count_solutions(), '1 queen on 1x1');
  is(0, NPieces->new()->size(1)->queens(2)->count_solutions(), '2 queens on 1x1');

  is(1, NPieces->new()->size(2)->queens(0)->count_solutions(), 'no queen on 2x2');
  is(4, NPieces->new()->size(2)->queens(1)->count_solutions(), '1 queen on 2x2');
  is(0, NPieces->new()->size(2)->queens(2)->count_solutions(), '2 queens on 2x2');

  is(1, NPieces->new()->size(3)->queens(0)->count_solutions(), 'no queen on 3x3');
  is(9, NPieces->new()->size(3)->queens(1)->count_solutions(), '1 queen on 3x3');

  is(2, NPieces->new()->size(3, 2)->queens(2)->count_solutions(), '2 queens on 3x2');

  is(8, NPieces->new()->size(3)->queens(2)->count_solutions(), '2 queens on 3x3');
  is(0, NPieces->new()->size(3)->queens(3)->count_solutions(), '3 queens on 3x3');

  is(44, NPieces->new()->size(4)->queens(2)->count_solutions(), '2 queens on 4x4');

  is(2, NPieces->new()->size(4)->queens(4)->count_solutions(), '4 queens on 4x4');
  is(10, NPieces->new()->size(5)->queens(5)->count_solutions(), '5 queens on 5x5');
};

done_testing();

