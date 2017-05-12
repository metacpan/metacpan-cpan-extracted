#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* With typemap, maps HvObject to a blessed HV */
typedef HV HvObject; 

MODULE = CookBookA::Ex3		PACKAGE = CookBookA::Ex3

# Fiddling a blessed hash.

char *
say_key(self,key)
	HvObject *self
	char *key
    PREINIT:
	SV **ssv;
	char *val;
    CODE:
	ssv = hv_fetch( self, key, strlen(key), 0 );
	if( ssv != NULL ){
		val = SvPV( *ssv, na );
		printf("# key '%s' => '%s'\n", key, val );
	}
	else{
		printf("# key '%s' not found\n", key );
		XSRETURN_UNDEF;
	}
	RETVAL = val;
    OUTPUT:
	RETVAL

char *
put_key(self,key,nval)
	HvObject *self
	char *key
	char *nval
    PREINIT:
	SV **ssv;
	SV *svval;
    CODE:
	svval = newSVpv( nval, strlen( nval ) );
	ssv = hv_store( self, key, strlen(key), svval, 0 );
	if( ssv != NULL ){
		RETVAL = SvPV( *ssv, na );
		printf("# key '%s' => '%s'\n", key, RETVAL );
	}
	else
		croak("Bad: key '%s' not stored", key );
    OUTPUT:
	RETVAL


MODULE = CookBookA::Ex3		PACKAGE = CookBookA::Ex3A

# Creating a blessed hash.  An HV is a Perl type, and Perl knows
# how to destroy it, so we won't need a C-based destructor to match
# this constructor.

HvObject *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = newHV();
    OUTPUT:
	RETVAL
    CLEANUP:
	/* Give up our own reference to the HV.  This must be done
	 * because the newHV() above and the newRV() in the typemap
	 * will increment the refcount.  This will compensate for
	 * that double hit to the refcount.
	 */
	SvREFCNT_dec( RETVAL );

MODULE = CookBookA::Ex3		PACKAGE = CookBookA::Ex3B

# Creating and fiddling an unblessed hash.  An HV is a Perl type, and Perl
# knows how to destroy it, so we won't need a C-based destructor to match
# this constructor.

HV *
newhash()
    CODE:
	RETVAL = newHV();
    OUTPUT:
	RETVAL
    CLEANUP:
	/* Give up our own reference to the HV.  This must be done
	 * because the newHV() above and the newRV() in the typemap
	 * will increment the refcount.  This will compensate for
	 * that double hit to the refcount.
	 */
	SvREFCNT_dec( RETVAL );

char *
getkey(hv,key)
	HV *hv
	char *key
    PREINIT:
	SV **ssv;
    CODE:
	ssv = hv_fetch( hv, key, strlen(key), 0 );
	if( ssv != NULL ){
		RETVAL = SvPV( *ssv, na );
		printf("# key '%s' => '%s'\n", key, RETVAL );
	}
	else{
		printf("# key '%s' not found\n", key );
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL
