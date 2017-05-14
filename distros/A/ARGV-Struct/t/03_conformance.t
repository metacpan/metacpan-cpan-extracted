#!/usr/bin/env perl

use Test::More;
use ARGV::Struct;

my @tests = (
 { argv => [ qw/{ X Y }/ ],
   struct => { X => 'Y' },
 },
 { argv => [ qw/{ X: Y }/ ],
   struct => { X => 'Y' },
 },
 { argv => [ qw/{ X:: Y }/ ],
   struct => { 'X:' => 'Y' },
 },
 { argv => [ qw/{ X Y Y { A X } }/ ],
   struct => { X => 'Y', Y => { A => 'X' } }
 },
 { argv => [ qw/{ X: Y Y: { A: X } }/ ],
   struct => { X => 'Y', Y => { A => 'X' } }
 },
 { argv => [ qw/{ X Y Y [ 1 2 3 ] Z 3 }/ ],
   struct => { X => 'Y', Y => [ 1, 2, 3 ], Z => 3 }
 },
 { argv => [ qw/[ ]/ ],
   struct => [ ],
 },
 { argv => [ qw/[ X=Y ]/ ],
   struct => [ 'X=Y' ],
 }, 
 { argv => [ qw/[ A B ] /],
   struct => [ 'A', 'B' ],
 },
 { argv => [ qw/[ A: B ] /],
   struct => [ 'A:', 'B' ],
 }, 
 { argv => [ qw/[ [ 1 2 3 ] [ 4 5 6 ] [ 7 8 9 ] ]/],
   struct => [ [1,2,3],[4,5,6],[7,8,9]],
 }, 
 { argv => [ qw/[ { Name X } { Name Y } ]/],
   struct => [ { Name => 'X' }, { Name => 'Y' } ],
 }, 
 { argv => [ qw/[ { Name X: } { Name Y: } ]/],
   struct => [ { Name => 'X:' }, { Name => 'Y:' } ],
 }, 
 { argv => [ '{', 'X', ' Y ', '}' ],
   struct => { X => ' Y ' },
 },
 { argv => [ '{', 'X', 'Y=Y', '}' ],
   struct => { X => 'Y=Y' },
 },
);

foreach $test (@tests) {
  eval {
    is_deeply(
      ARGV::Struct->new(argv => $test->{ argv })->parse,
      $test->{ struct },
      "Conformance of " . join ' ', @{ $test->{ argv } }
    );
  };
  if ($@){
    fail((join ' ', @{ $test->{ argv } }) . " DIED $@");
  }
}

done_testing;
