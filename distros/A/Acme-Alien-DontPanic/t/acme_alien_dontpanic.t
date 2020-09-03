use Test2::V0 -no_srand => 1;
use Test::Alien 0.05;
use Acme::Alien::DontPanic;
use Data::Dumper qw( Dumper );

alien_ok 'Acme::Alien::DontPanic';

xs_ok do { local $/; <DATA> }, with_subtest {
  my($module) = @_;
  plan 1;
  is $module->answer, 42, 'answer is 42';
};

ffi_ok { symbols => ['answer'] }, with_subtest {
  my($ffi) = @_;
  my $answer = $ffi->function(answer=>[]=>'int')->call;
  plan 1;
  is $answer, 42;
};

run_ok('dontpanic')
  ->success
  ->out_like(qr{the answer to life the universe and everything is 42})
  ->note;

note Dumper(Acme::Alien::DontPanic->Inline("C"));
note Dumper(Acme::Alien::DontPanic->runtime_prop);

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

int answer(class)
    const char *class;
  CODE:
    RETVAL = answer();
  OUTPUT:
    RETVAL
