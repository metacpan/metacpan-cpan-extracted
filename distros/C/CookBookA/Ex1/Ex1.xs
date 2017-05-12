#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
	int blue;
	char red[10];
} ex1_struct, ex1b_struct;


MODULE = CookBookA::Ex1		PACKAGE = CookBookA::Ex1

# Make sure that we have at least xsubpp version 1.922.
REQUIRE: 1.922

ex1_struct *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = (ex1_struct*)safemalloc( sizeof( ex1_struct ) );
	if( RETVAL == NULL ){
		warn("unable to malloc ex1_struct");
		XSRETURN_UNDEF;
	}
	RETVAL->blue = 42;
	strcpy( RETVAL->red, "gurgle" );
    OUTPUT:
	RETVAL

# Perl doesn't know how to destroy an ex1_struct because it isn't
# a Perl type (i.e  HV,AV,SV).  So we supply a destructor that knows
# how to destroy an ex1_struct.

void
DESTROY(self)
	ex1_struct *self
    CODE:
	printf("# destroying %s\n", SvPV(ST(0),na) );
	safefree( (char*)self );

int
blue( self )
	ex1_struct *self
    CODE:
	RETVAL = self->blue;
    OUTPUT:
	RETVAL

void
set_blue( self , val )
	ex1_struct *self
	int val
    PPCODE:
	self->blue = val;

char *
red(self)
	ex1_struct *self
    CODE:
	RETVAL = self->red;
    OUTPUT:
	RETVAL

void
set_red(self,val)
	ex1_struct *self
	char *val
    PPCODE:
	strcpy( self->red, val );


MODULE = CookBookA::Ex1		PACKAGE = CookBookA::Ex1B

ex1b_struct *
newEx1B()
    CODE:
	RETVAL = (ex1b_struct*)safemalloc( sizeof( ex1b_struct ) );
	if( RETVAL == NULL ){
		warn("unable to malloc ex1b_struct");
		XSRETURN_UNDEF;
	}
	RETVAL->blue = 142;
	strcpy( RETVAL->red, "piper" );
    OUTPUT:
	RETVAL

# Perl doesn't know how to destroy an ex1b_struct because it isn't
# a Perl type (i.e  HV,AV,SV).  So we supply a destructor that knows
# how to destroy an ex1b_struct.

void
freeEx1B(self)
	ex1b_struct *self
    CODE:
	printf("# freeing %s\n", SvPV(ST(0),na) );
	safefree( (char*)self );

int
get_blue(sv)
	ex1b_struct *sv
    CODE:
	RETVAL = sv->blue;
    OUTPUT:
	RETVAL
