use Test2::V0 -no_srand => 1;
use Test::Alien 0.05;
use Acme::Alien::DontPanic2;

my @libs = Acme::Alien::DontPanic2->dynamic_libs;

skip_all 'test requires dynamic libraries'
  unless @libs;

alien_ok 'Acme::Alien::DontPanic2';

ffi_ok { symbols => ['answer'] }, with_subtest {
  my($ffi) = @_;
  my $answer = $ffi->function(answer=>[]=>'int')->call;
  plan 1;
  is $answer, 42;
};

done_testing;

