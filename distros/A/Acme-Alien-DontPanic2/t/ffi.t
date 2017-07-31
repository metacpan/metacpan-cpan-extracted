use Test2::V0;
use Test::Alien 0.05;
use Acme::Alien::DontPanic2;

skip_all 'FFI not supported (yet)';

plan 3;

alien_ok 'Acme::Alien::DontPanic2';

ffi_ok { symbols => ['answer'] }, with_subtest {
  my($ffi) = @_;
  my $answer = $ffi->function(answer=>[]=>'int')->call;
  plan 1;
  is $answer, 42;
};
