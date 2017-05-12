// (c) 2001 by St. Traby <stefan@hello-penguin.com>
//
// There are two ways that perl can be started instead
// of cache.
// The first way is using "--perl" or "-perl" as first
// commandline argument to cache.
// The other way is having "cperl" at the end of argv[0]

#include <string.h>

extern int mmain(int argc, char **argv, char **envp);
extern int perl_master(int argc, char **argv, char **envp);
extern int perl_slave(int argc, char **argv, char **envp);

static const char *pmaster = "--perl";
static int want_perl = 0;

int main(int argc, char **argv, char **envp)
{
  int i;
  if(argc > 1 && (!strcmp(argv[1], pmaster) || !strcmp(argv[1], &pmaster[1]))) {
    // caller made a good choice, he requested perl by specifying --perl or -perl :)
    argc--;
    for(i = 1; i < argc; i++)
      argv[i] = argv[i+1];
    argv[i] = 0;
    want_perl = 1;
  }

  i = strlen(argv[0]);
  if(i > 4 && !strcmp("cperl", argv[0] + i - 5)) {
       want_perl = 1;  
  }

  if(want_perl) {
     return perl_master(argc, argv, envp);
  } else {
    perl_slave(argc, argv, envp); // notify perl that cache is master
                                  // if perl is master, cache will be initialized on demand
    return mmain(argc, argv, envp);
  }
}
