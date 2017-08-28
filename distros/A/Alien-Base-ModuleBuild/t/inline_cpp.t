use lib 't/lib';
use Test2::Plugin::AlienEnv;
use Test2::Require::Module 'Inline' => '0.56';
use Test2::Require::Module 'Inline::CPP';
use Test2::Require::Module 'Acme::Alien::DontPanic' => '0.010';
use Test2::V0 -no_srand => 1;
use Acme::Alien::DontPanic;
use Inline 0.56 with => 'Acme::Alien::DontPanic';
use Inline CPP => 'DATA', ENABLE => 'AUTOWRAP';

# Honest question: Where does this test really belong?
#  - Alien-Build (which has Alien::Base)
#  - Acme::Alien::DonePanic
#  - Alien-Base-ModuleBuild

skip_all 'test requires that Acme::Alien::DontPanic was build with Alien::Base 0.006'
  unless defined Acme::Alien::DontPanic->Inline("CPP")->{AUTO_INCLUDE};

is Foo->new->string_answer, "the answer to life the universe and everything is 42", 'indirect';
is answer(), 42, "direct";

done_testing;

__DATA__
__CPP__

#include <stdio.h>

class Foo {
public:
  char *string_answer()
  {
    static char buffer[1024];
    sprintf(buffer, "the answer to life the universe and everything is %d", answer());
    return buffer;
  }
};

extern int answer();
