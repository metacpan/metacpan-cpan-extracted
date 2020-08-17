use Test2::V0 -no_srand => 1;
use Test::Alien::CPP;
use Test::Alien::Diag;
use Alien::Boost;
 
alien_diag 'Alien::Boost';
 
alien_ok 'Alien::Boost';
 
subtest xs => sub {
 
  my $xs = <<'EOM';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef do_open(a,b,c,d,e,f,g)
#undef do_open(a,b,c,d,e,f,g)
#undef do_open
#undef do_close(a,b)
#undef do_close
#endif
#include <boost/program_options.hpp>
#ifndef do_open
#define do_open                 Perl_do_open
#define do_open(a,b,c,d,e,f,g)  Perl_do_open(aTHX_ a,b,c,d,e,f,g)
#define do_close                Perl_do_close
#define do_close(a,b)           Perl_do_close(aTHX_ a,b)
#endif

 
MODULE = Boost PACKAGE = Boost
 
int 
main()
    INIT:
    CODE:
      boost::program_options::options_description generic("Generic options");
      RETVAL = 1;
    OUTPUT:
      RETVAL
EOM
 
  xs_ok $xs, with_subtest {
    ok(Boost::main());
  };
 
};
 
done_testing;
