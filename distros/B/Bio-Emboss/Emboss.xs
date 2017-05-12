#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"

#include "bio_emboss_config.h"
#include "const-c.inc"

#include "emboss-boot-c.inc" /* prototypes of other modules */

MODULE = Bio::Emboss		PACKAGE = Bio::Emboss

PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

INCLUDE: emboss-boot-xs.inc

void
embInitPerl(pgm, argv)
	char *    pgm
        SV *      argv
    INIT:
     	I32 argc = 0;
     	int n;
	char ** cargv;

     	if ((!SvROK(argv))
     	    || (SvTYPE(SvRV(argv)) != SVt_PVAV)
     	    )
     	{
     	    XSRETURN_UNDEF;
     	}
      	argc = av_len((AV *)SvRV(argv)) + 1;
   CODE:
        argc++; /* add pgm */
        cargv = malloc(argc * sizeof(char*));
	cargv[0] = pgm;
	for (n=1; n < argc; n++) {
	   STRLEN l;
	   char * ptr = SvPV(*av_fetch((AV *)SvRV(argv), n-1, 0), l);
	   cargv[n] = ptr;
#ifdef DEBUG_EXS
	   printf("carv[%d]: %s\n", n, cargv[n]);
#endif
	}
	embInit(pgm, argc, cargv);
	free(cargv);


void
ajGraphInitPerl(pgm, argv)
	char *    pgm
        SV *      argv
    INIT:
     	I32 argc = 0;
     	int n;
	char ** cargv;

     	if ((!SvROK(argv))
     	    || (SvTYPE(SvRV(argv)) != SVt_PVAV)
     	    )
     	{
     	    XSRETURN_UNDEF;
     	}
      	argc = av_len((AV *)SvRV(argv)) + 1;
   CODE:
        argc++; /* add pgm */
        cargv = malloc(argc * sizeof(char*));
	cargv[0] = pgm;
	for (n=1; n < argc; n++) {
	   STRLEN l;
	   char * ptr = SvPV(*av_fetch((AV *)SvRV(argv), n-1, 0), l);
	   cargv[n] = ptr;
#ifdef DEBUG_EXS
	   printf("carv[%d]: %s\n", n, cargv[n]);
#endif
	}
	ajGraphInit(pgm, argc, cargv);
	free(cargv);



