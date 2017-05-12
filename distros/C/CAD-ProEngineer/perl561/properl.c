
/* properl.c - Embedded perl interpreter */


#include "EXTERN.h"
#include "perl.h"

#include "ProToolkit.h"
#include "ProMessage.h"

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
static PerlInterpreter *my_perl;


static void
xs_init(pTHX)
{
  char *file = __FILE__;
  dXSUB_SYS;
  {
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
  }
}


int user_initialize(int argc, char **argv) {

    int exitstatus;
    char **argv1, *argv1a[] = { "", "-S", "interp.pl" }; /* Look in PATH */
    char *env1[] = { NULL }, *args[] = { NULL };
    int argc1=3;

#ifdef PERL_GLOBAL_STRUCT
#define PERLVAR(var,type) /**/
#define PERLVARA(var,type) /**/
#define PERLVARI(var,type,init) PL_Vars.var = init;
#define PERLVARIC(var,type,init) PL_Vars.var = init;
#include "perlvars.h"
#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#endif


    printf("Starting perl interpreter ...\n");

    argv1 = argv1a;

    /* PERL_SYS_INIT3(&argc,&argv,&env); */
    PERL_SYS_INIT3(&argc1,&argv1,&env1);

#ifndef WIN32
    if (!PL_do_undump) {
#endif
        my_perl = perl_alloc();
        if (!my_perl)
            exit(1);
        perl_construct(my_perl);
#ifndef WIN32
        PL_perl_destruct_level = 0;
#endif
#ifndef WIN32
    }
#endif


  {
    ProFileName msg_file;
    ProStringToWstring(msg_file, "msg_file.txt");
    ProMessageDisplay(msg_file, "USER %0s", "Perl interpreter started.");
    ProMessageClear();
  }


  /* exitstatus = perl_parse(my_perl, xs_init, argc, argv, (char **)NULL); */
  exitstatus = perl_parse(my_perl, xs_init, argc1, argv1, env1);
  if (!exitstatus) {
    exitstatus = perl_run(my_perl); /* Run the full script */
    /* call_argv("user_initialize", G_DISCARD | G_NOARGS, args); */  /* Execute user_initialize() sub */
  }


  printf("Perl interpreter started\n");
  return(0);
}


void user_terminate() {

  printf("\n");
  printf("Shutting down perl interpreter ...\n");

  perl_destruct(my_perl);
  perl_free(my_perl);
  PERL_SYS_TERM();

  printf("Perl interpreter shut down\n");
  printf("\n");
  /* return(0); Do not return a value */
}


