#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <no_such_header.h>

int foo(void) {
    return 42;
}


MODULE = CPAN::Test::Dummy::Perl5::Make::CompilationFails  PACKAGE = CPAN::Test::Dummy::Perl5::Make::CompilationFails  

PROTOTYPES: DISABLE


int
foo ()
		

