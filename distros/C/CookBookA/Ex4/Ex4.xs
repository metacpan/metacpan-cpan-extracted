#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* With typemap, maps AvObject to a blessed AV */
typedef AV AvObject; 

MODULE = CookBookA::Ex4		PACKAGE = CookBookA::Ex4

# Fiddling a blessed array.

char *
pop_val(self)
	AvObject *self
    PREINIT:
	SV *sv1 = NULL;
    CODE:
	if( av_len( self ) > -1 )
		sv1 = av_pop( self );
	if( sv1 != NULL ){
		RETVAL = (char *)SvPV( sv1, na );
		printf("# popped '%s'\n", RETVAL );
	}
	else{
		printf("# nothing popped\n" );
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

void
push_val(self,nval)
	AvObject *self
	char *nval
    PREINIT:
	SV *svval;
    PPCODE:
	svval = newSVpv( nval, strlen( nval ) );
	av_push( self, svval );


MODULE = CookBookA::Ex4		PACKAGE = CookBookA::Ex4A

# Creating a blessed array.  An AV is a Perl type, and Perl knows
# how to destroy it, so we won't need a C-based destructor to match
# this constructor.

AvObject *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = newAV();
    OUTPUT:
	RETVAL
    CLEANUP:
	/* Give up our own reference to the AV.  This must be done
	 * because the newAV() above and the newRV() in the typemap
	 * will increment the refcount.  This will compensate for
	 * that double hit to the refcount.
	 */
	SvREFCNT_dec( RETVAL );


MODULE = CookBookA::Ex4		PACKAGE = CookBookA::Ex4B

# Creating and fiddling an unblessed array.  An AV is a Perl type, and Perl
# knows how to destroy it, so we won't need a C-based destructor to match
# this constructor.

AV *
newarray()
    CODE:
	RETVAL = newAV();
    OUTPUT:
	RETVAL
    CLEANUP:
	/* Give up our own reference to the AV.  This must be done
	 * because the newAV() above and the newRV() in the typemap
	 * will increment the refcount.  This will compensate for
	 * that double hit to the refcount.
	 */
	SvREFCNT_dec( RETVAL );

char *
get_val(av)
	AV *av
    PREINIT:
	SV *sv1;
    CODE:
	if( av_len( av ) > -1 )
		sv1 = av_pop( av );
	if( sv1 != NULL ){
		RETVAL = (char *)SvPV( sv1, na );
		printf("# popped '%s'\n", RETVAL );
	}
	else{
		printf("# nothing popped\n" );
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL
