// Compile with: cc -I.. -o leak leak.c `perl -MExtUtils::Embed -e ccopts -e ldopts`
// Run with    : valgrind --leak-check=full ./leak

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tagutils-common.h"
#include "tagutils-flac.c"

static PerlInterpreter *my_perl;

int main(int argc, char** argv) {
  int i = 0;
  char* file = argv[1];

  my_perl = perl_alloc();
  perl_construct(my_perl);

  for (i = 0; i < 5000; i++) {
    HV* info = newHV();
    HV* tags = newHV();

    get_flac_metadata(file, info, tags);
  }

  perl_destruct(my_perl);
  perl_free(my_perl);

  return 0;
}
