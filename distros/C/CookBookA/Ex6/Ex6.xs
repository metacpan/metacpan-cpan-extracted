#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* With typemap, maps AvObject to a blessed AV */
typedef AV AvObject; 

typedef struct {
	AV *obj1;
	AV *obj2;
} container;


MODULE = CookBookA::Ex6		PACKAGE = CookBookA::Ex6

container *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = (container*)safemalloc( sizeof( container ) );
	if( RETVAL == NULL ){
		warn("unable to malloc container");
		XSRETURN_UNDEF;
	}
	/* let the destructor know there's nothing here */
	RETVAL->obj1 = Nullav;
	RETVAL->obj2 = Nullav;
    OUTPUT:
	RETVAL

# Perl doesn't know how to destroy a container because it isn't
# a Perl type (i.e  HV,AV,SV).  So we supply a destructor that knows
# how to destroy a container.

void
DESTROY(self)
	container *self
    CODE:
	printf("# destroying %s\n", SvPV(ST(0),na) );

	/* Before destroying the container, release our references to
	 * the objects in the container.  The objects are AVs, Perl objects,
	 * so Perl will know how to destroy them once we've released
	 * our claim to them.
	 */
	if( self->obj1 != Nullav )
		SvREFCNT_dec( self->obj1 );
	if( self->obj2 != Nullav )
		SvREFCNT_dec( self->obj2 );

	safefree( (char*)self );


# Keep a reference to the object.  Increment its refcount so Perl knows
# we are using the object and doesn't try to destroy it.
void
saveit(self,obj)
	container *self
	AvObject *obj
    PREINIT:
	container *c;
    CODE:
	self->obj1 = obj;
	SvREFCNT_inc( obj );

# Keep a reference to the object.  Increment its refcount so Perl knows
# we are using the object and doesn't try to destroy it.
void
saveit2(self,obj)
	container *self
	AvObject *obj
    PREINIT:
	container *c;
    CODE:
	self->obj2 = obj;
	SvREFCNT_inc( obj );


# Get a reference to the object.  The typemap will increment the refcount
# to show that there is another ref.
# Return AV rather than AvObject, because the object is already blessed
# and we don't have to use an auto-blessing typemap.
AV *
getit(self)
	container *self
    CODE:
	RETVAL = self->obj1;
    OUTPUT:
	RETVAL


# Get a reference to the object, and decrement its refcount to tell
# Perl that the C object is no longer holding a reference to the object.
# The variable which holds the return value is the only reference to
# the object, when it goes out of scope Perl will destroy the object.
# Return AV rather than AvObject, because the object is already blessed
# and we don't have to use an auto-blessing typemap.
AV *
dropit(self)
	container *self
    CODE:
	RETVAL = self->obj1;
    OUTPUT:
	RETVAL
    CLEANUP:
	/* Decrement the refcount last, to avoid accidents. */
	SvREFCNT_dec( RETVAL );
	self->obj1 = Nullav; /* let the destructor know it's gone */
