#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


struct PAIR {
	double time;
	double rate;
	SV *sv_next;
};
typedef struct PAIR PAIR;

int foo( PAIR *curve ){
	PAIR *c;
	int x = 0;

	c = curve;
	while( c != NULL ){
		printf("idx = %d\n", x );
		printf("  time = %f\n", c->time );
		printf("  rate = %f\n", c->rate );
		++x;
		if( c->sv_next != NULL ){
			c = (PAIR*)SvIV( c->sv_next );
		}
		else{
			c = NULL;
		}
	}
}



MODULE = CookBookB::ListOfStruct		PACKAGE = CookBookB::ListOfStruct

PAIR *
new(CLASS)
	char *CLASS
    CODE:
	RETVAL = (PAIR *)safemalloc(sizeof(PAIR));
	if( RETVAL == NULL ){
		warn("unable to malloc PAIR");
		XSRETURN_UNDEF;
	}
	RETVAL->time = 0.0;
	RETVAL->rate = 0.0;
	RETVAL->sv_next = NULL;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	PAIR *self
    CODE:
	printf("freeing PAIR(%g,%g)\n", self->time, self->rate );
	if( self->sv_next != NULL ){
		/* release our reference to the object in self->sv_next */
		SvREFCNT_dec( self->sv_next );
	}
	safefree((char*)self);

int
foo(self)
	PAIR *self

void
push(self,sv_pair)
	PAIR *self
	SV *sv_pair
    CODE:
	self->sv_next = SvRV( sv_pair );
	/* tell 'self->sv_next' that we have a reference to it */
	SvREFCNT_inc( self->sv_next );

void
fill(self,t,r)
	PAIR *self
	double t;
	double r;
    CODE:
	self->time = t;
	self->rate = r;
