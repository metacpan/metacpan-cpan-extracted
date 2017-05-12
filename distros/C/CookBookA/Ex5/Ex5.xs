#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* With typemap, maps AvObject to a blessed AV */
typedef AV AvObject; 

/* NOTE:  Some would argue that there's nothing simple or easy about
 * doing callbacks from C to Perl.  Consult the perlcall manpage for
 * descriptions of the macros and concepts used here.  These examples
 * cover an end-case which is not covered in the manpage (that the
 * blessed object has already been dereferenced).
 */

MODULE = CookBookA::Ex5		PACKAGE = CookBookA::Ex5

void
ramble(self,val)
	AvObject *self
	SV *val
    PREINIT:
	int ret;
    CODE:
	printf( "# ramble\n" );

	PUSHMARK(sp); /* bracket the method's arguments */

	/* Our object is not an SV* so we have to make an SV* reference
	 * to it.  Note that newRV() will increment the object's
	 * refcount, so we mortalize the reference to allow Perl to
	 * garbage-collect that refcount after we return from our
	 * call to the other method.
	 */
	XPUSHs( sv_2mortal( newRV( (SV*)self ) ) );
	XPUSHs( val );

	PUTBACK; /* end of method's arguments */

	perl_call_method( "dogwood", G_DISCARD );

	/* Read the value returned by dogwood.  Note that the 'SV *'
	 * typemap does not dereference, so we do it here.
	 */
	ret = SvIV( SvRV( val ) );
	printf("# returned from dogwood = %d\n", ret );


int
drift(self)
	AvObject *self
    PREINIT:
	int count;
    CODE:
	printf( "# drift\n" );

	ENTER; /* bracket everything so we can return values */
	SAVETMPS;

	PUSHMARK(sp); /* bracket the method's arguments */

	/* Our object is not an SV* so we have to make an SV* reference
	 * to it.  Note that newRV() will increment the object's
	 * refcount, so we mortalize the reference to allow Perl to
	 * garbage-collect that refcount after we return from our
	 * call to the other method.
	 */
	XPUSHs( sv_2mortal( newRV( (SV*)self ) ) );

	PUTBACK; /* end of method's arguments */

	count = perl_call_method( "birch", G_SCALAR );

	/* We want 1 return value */
	if( count != 1 )
		croak( "Bad: count was %d\n", count );

	SPAGAIN; /* open stack to get the return value */
	RETVAL = POPi;
	printf("# returned from birch = %d\n", RETVAL );

	PUTBACK; /* close it up */

	FREETMPS;
	LEAVE;  /* close the ENTER above */

	/* If the ENTER/SAVETMPS and FREETMPS/LEAVE bracket is omitted
	 * then the array object, self, will be lost.  But RETVAL will
	 * get through either way :)
	 */

    OUTPUT:
	RETVAL
