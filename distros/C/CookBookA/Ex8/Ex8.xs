#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Av_CharPtrPtr.h"  /* XS_*_charPtrPtr() */
#ifdef __cplusplus
}
#endif

static void
into( s )
char **s;
{
	char **c;
	for( c = s; *c != NULL; ++c )
		printf("%s\n", *c );
}

typedef char Char;  /* Char is an O_OBJECT */

MODULE = CookBookA::Ex8		PACKAGE = CookBookA::Ex8

Char **
new(CLASS)
	char *CLASS
    PREINIT:
	int x;
    CODE:
	RETVAL = (Char **)safemalloc( sizeof(Char*) * 4 );
	if( RETVAL == NULL ){
		warn("unable to malloc Char**");
		XSRETURN_UNDEF;
	}
	for( x = 1; x < 4; ++x ){
		RETVAL[x-1] = (Char *)safemalloc( sizeof(Char) * 5 );
		if( RETVAL[x-1] == NULL )
			warn("unable to malloc Char*");
		else
			sprintf( RETVAL[x-1], "ok %d", x );
	}
	RETVAL[x-1] = (Char*)NULL;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	Char **self
    PREINIT:
	char **c;
    CODE:
	for( c = self; *c != NULL; ++c )
		safefree( *c );
	safefree( self );


char *
set_elem(self,idx,str)
	Char **self
	int idx
	char *str
    CODE:
	/* Normally some bounds checking would be added: */
	/* 1) idx is within the range of self		 */
	/* 2) str fits in the buffer			 */
	sprintf( self[idx], "%s", str );

void
into(self)
	Char **self


MODULE = CookBookA::Ex8		PACKAGE = CookBookA::Ex8A

# This package handles char** by using the default typemap.  The default
# typemap uses functions XS_pack_charPtrPtr() and XS_unpack_charPtrPtr()
# to translate between the Perl type and the C char**.  The XS_*_charPtrPtr
# in Av_CharPtrPtr.c assume the Perl type is an AV.

void
into10(s)
	char **s
    CODE:
	into( s );
    CLEANUP:
	XS_release_charPtrPtr( s );

char **
outof10()
    PREINIT:
	char *s[4] = { "ok 9", "ok 10", "ok 11", 0 };
    CODE:
	RETVAL = s;
    OUTPUT:
	RETVAL

