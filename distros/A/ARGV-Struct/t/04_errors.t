#!/usr/bin/env perl

use Test::More;
use Test::Exception;
use ARGV::Struct;

my @tests = (
 { argv => [ qw/{/ ],
   error => 'Unclosed hash',
 },
 { argv => [ qw/{ X=Y Y={/ ],
   error => 'Unclosed hash',
 },
 { argv => [ qw/[/ ],
   error => 'Unclosed list',
 },
 { argv => [ qw/{ X: X X: Y }/ ],
   error => 'Repeated'
 }, 
 { argv => [ qw/[ A B ] Trail/],
   error => 'Trailing'
 }, 
 { argv => [ qw/{ 3 /],
   error => 'Key 3 doesn\'t',
 }, 
 { argv => [ qw/{ X }/],
 },
 { argv => [ qw/{ X: }/ ],
 },
);

foreach $test (@tests) {
  $test->{ error } = '.+' if (not defined $test->{ error });
  throws_ok(
    sub { ARGV::Struct->new(argv => $test->{ argv })->parse },
    qr/$test->{ error }/,
    "Conformance of " . join ' ', @{ $test->{ argv } }
  );
}

done_testing;
