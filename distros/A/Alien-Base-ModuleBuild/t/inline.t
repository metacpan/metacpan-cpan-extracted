use Test2::Require::Module 'Inline' => '0.56';
use Test2::Require::Module 'Inline::C';
use Test2::Require::Module 'Acme::Alien::DontPanic' => '0.010';
use Test2::V0 -no_srand => 1;
use Acme::Alien::DontPanic;
use Inline 0.56 with => 'Acme::Alien::DontPanic';
use Inline C => 'DATA', ENABLE => 'AUTOWRAP';

skip_all 'test requires that Acme::Alien::DontPanic was build with Alien::Base 0.006'
  unless defined Acme::Alien::DontPanic->Inline("C")->{AUTO_INCLUDE};

is string_answer(), "the answer to life the universe and everything is 42", "indirect call";
is answer(), 42, "direct call";

done_testing;

__DATA__
__C__

#include <stdio.h>

char *string_answer()
{
  static char buffer[1024];
  sprintf(buffer, "the answer to life the universe and everything is %d", answer());
  return buffer;
}

extern int answer();
