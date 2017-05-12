use strict;
use warnings;
use Test2::Bundle::More;
use Test::Alien 0.05;
use Acme::Alien::DontPanic;

plan 3;

alien_ok 'Acme::Alien::DontPanic';

ffi_ok { symbols => ['answer'] }, with_subtest {
  my($ffi) = @_;
  my $answer = $ffi->function(answer=>[]=>'int')->call;
  plan 1;
  is $answer, 42;
};
