/* All the mmap() stuff is copied from Malcolm Beattie's Mmap.pm */

#ifdef __cplusplus
  extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
  }
#endif

#include <sys/mman.h>

#ifndef MMAP_RETTYPE
#  ifndef _POSIX_C_SOURCE
#    define _POSIX_C_SOURCE 199309
#  endif
#  ifdef _POSIX_VERSION
#    if _POSIX_VERSION >= 199309
#      define MMAP_RETTYPE void *
#    endif
#  endif
#endif

#ifndef MMAP_RETTYPE
#  define MMAP_RETTYPE caddr_t
#endif

#ifndef MAP_FAILED
#  define MAP_FAILED ((caddr_t)-1)
#endif

/* Required stuff for fcntl locking */
#include <fcntl.h>

/* Stay backwards compatible */
#include "ppport.h"

MODULE = Cache::Mmap		PACKAGE = Cache::Mmap

int
mmap(var,len,fh)
	SV *var
	size_t len
	FILE *fh
	int fd = NO_INIT
	MMAP_RETTYPE addr = NO_INIT
    PROTOTYPE: $$$
    CODE:
	/* XXX Use new perlio stuff to get fd */
	fd=fileno(fh);

	addr=mmap(0,len,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
	if(addr==MAP_FAILED){
	  RETVAL=0;
	}else{
	  SvUPGRADE(var,SVt_PV);
	  SvPVX(var)=(char*)addr;
	  SvCUR_set(var,len);
	  SvLEN_set(var,0);
	  SvPOK_only(var);
	  RETVAL=1;
	}
    OUTPUT:
	RETVAL

int
munmap(var)
	SV *var
    PROTOTYPE: $
    CODE:
	if(munmap((MMAP_RETTYPE)SvPVX(var),SvCUR(var))<0){
	  RETVAL=0;
	}else{
	  SvREADONLY_off(var);
	  SvPVX(var)=0;
	  SvCUR_set(var,0);
	  SvLEN_set(var,0);
	  SvOK_off(var);
	  RETVAL=1;
	}
    OUTPUT:
	RETVAL

int
_lock_xs(fh,off,len,mode)
	FILE *fh
	off_t off
	size_t len
	int mode
	int fd = NO_INIT
	struct flock fl = NO_INIT
    PROTOTYPE: $$$$
    CODE:
	/* XXX Use new perlio stuff to get fd */
	fd=fileno(fh);
	fl.l_whence=SEEK_SET;
	fl.l_start=off;
	fl.l_len=len;
	fl.l_type=mode ? F_WRLCK : F_UNLCK;
	RETVAL=fcntl(fd,F_SETLKW,&fl)>=0;


    /* Define our own utf8::decode(), if we're on perl 5.6 */

MODULE = Cache::Mmap		PACKAGE = utf8

#if (PERL_VERSION == 6)

void
decode(SV *str)
    PROTOTYPE: $
    PPCODE:
	SV *sv=ST(0);
	int RETVAL;

	RETVAL=sv_utf8_decode(sv);
	ST(0)=boolSV(RETVAL);
	sv_2mortal(ST(0));
	XSRETURN(1);

#endif

