/*
 * Mmap.xs -- Apache::Mmap XSUB 
 *
 * Copyright (c) 1997
 * Mike Fletcher <lemur1@mindspring.com>
 * 08/26/97
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *
 * See the files 'Copying' or 'Artistic' for conditions of use.
 *
 * Portions based on Mmap module's Mmap.xs 
 * which are Copyright (c) 1996 by Malcolm Beattie
 *
 */

/* 
 * $Id: Mmap.xs,v 1.3 1997/09/15 06:20:56 fletch Exp $
 */
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
#include <string.h>

#ifndef MMAP_RETTYPE
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 199309
#endif /* !_POSIX_C_SOURCE */
#ifdef _POSIX_VERSION
#if _POSIX_VERSION >= 199309
#define MMAP_RETTYPE void *
#endif /* _POSIX_VERSION >= 199309 */
#endif /* _POSIX_VERSION */
#endif /* !MMAP_RETTYPE */

#ifndef MMAP_RETTYPE
#define MMAP_RETTYPE caddr_t
#endif /* !MMAP_RETTYPE */

#ifndef MAP_FAILED
#define MAP_FAILED ((caddr_t)-1)
#endif /* !MAP_FAILED */

/* Define struct to represent a mapped region */
struct _Mmap {
  MMAP_RETTYPE addr;		/* Address of memory returned by mmap(2) */
  size_t len;			/* Length of mapped buffer */
  size_t cur;			/* Current length of string in buffer */ 
  off_t off;			/* Offset in file mapped */
  int prot, flags;		/* Protection and flags passed to mmap(2) */
};
typedef struct _Mmap Mmap;

static void
dump_Mmap( m )
Mmap *m;
{
  if( m != NULL ) 
    fprintf( stderr,
      "Apache::Mmap %x:\naddr: %x\tlen: %d\tcur: %d\noff: %d\tprot: %d\tflags: %d\n",
             m, m->addr, m->len, m->cur, m->off, m->prot, m->flags );
}

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'M':
	if (strEQ(name, "MAP_ANON"))
#ifdef MAP_ANON
	    return MAP_ANON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_ANONYMOUS"))
#ifdef MAP_ANONYMOUS
	    return MAP_ANONYMOUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_FILE"))
#ifdef MAP_FILE
	    return MAP_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_PRIVATE"))
#ifdef MAP_PRIVATE
	    return MAP_PRIVATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAP_SHARED"))
#ifdef MAP_SHARED
	    return MAP_SHARED;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "PROT_EXEC"))
#ifdef PROT_EXEC
	    return PROT_EXEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_NONE"))
#ifdef PROT_NONE
	    return PROT_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_READ"))
#ifdef PROT_READ
	    return PROT_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PROT_WRITE"))
#ifdef PROT_WRITE
	    return PROT_WRITE;
#else
	    goto not_there;
#endif
	break;
    default:
	break;	
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Apache::Mmap	PACKAGE = Apache::Mmap


double
constant(name,arg)
	char *		name
	int		arg

Mmap *
TIESCALAR( CLASS, fh, len, prot, flags, off = 0 )
  char *	CLASS
  FILE *	fh
  size_t	len
  int		prot
  int		flags
  off_t		off

 PREINIT:
  int		fd;
  Mmap *        ret;
  SV   *	sv;

 PROTOTYPE: $$$*;$
 CODE:
   fd = fileno( fh );
   if( fd < 0 ) 
     XSRETURN_UNDEF;

   if( !len ) {
     struct stat st;
     if( fstat( fd, &st ) == -1 )
       XSRETURN_UNDEF;
     len = st.st_size;
   }

   Newz( 0, ret, 1, Mmap );

   ret->len = ret->cur = len;
   ret->off = off;
   ret->prot = prot;
   ret->flags = flags;

   ret->addr = mmap(0, len, prot, flags, fd, off);
   if (ret->addr == MAP_FAILED) {
     XSRETURN_UNDEF;
   }

   RETVAL = ret;

 OUTPUT:
 RETVAL

SV *
STORE( self, what ) 
  Mmap *self
  SV *what

  PROTOTYPE: $$

  CODE:
  /* Croak if what isn't available as a string */
  if( !SvPOK( what ) ) {
    croak( "Attepmt to store non-string scalar\n" );
    XSRETURN_UNDEF;
  }

  /* Make sure region was mapped with write privledges */
  if( !( self->prot & PROT_WRITE ) ) {
    croak( "Attempt to store to read only region\n" );
    XSRETURN_UNDEF;
  }

  /* If length of what is less than or equal size of mapped buffer
   * copy it, set self->cur to SvCUR(what), and zero from the end of
   * the string to the end of the buffer.  Otherwise copy only self->len
   * bytes from what.
   */
  if( SvCUR( what ) <= self->len ) {
    memcpy( self->addr, SvPV( what, self->cur ), self->cur );
    memset( self->addr + self->cur, 0, self->len - self->cur );
  } else {
    memcpy( self->addr, SvPV( what, na ), self->len );
    self->cur = self->len;
  }
  
  /* return copy of what we stored */
  RETVAL = newSVpv( self->addr, self->cur );

  OUTPUT:
  RETVAL

SV *
FETCH( self ) 
  Mmap	*self

  PROTOTYPE: $
  CODE:
  /* Make sure region was mapped with read privledges */
  if( !( self->prot & PROT_READ ) ) {
    croak( "Apache::Mmap::FETCH: Attempt to read from write only region" );
    XSRETURN_UNDEF;
  }

  /* Return a PV with the contents of the mapped region */
  RETVAL = newSVpv( self->addr, self->cur );

  OUTPUT:
  RETVAL

void
DESTROY( self )
  Mmap *self

  PROTOTYPE: $
  CODE:
  if( self == NULL || self->addr == NULL ) {
    warn( "Apache::Mmap::DESTROY: Attempt to destroy null ptr or region\n" );
    XSRETURN_UNDEF;
  }

  if( munmap( self->addr, self->len ) == -1 ) {
    XSRETURN_UNDEF;
  } else {
    self->addr = (MMAP_RETTYPE) NULL;
    self->len = self->cur = 0;
    Safefree( self );
    XSRETURN_YES;
  }
