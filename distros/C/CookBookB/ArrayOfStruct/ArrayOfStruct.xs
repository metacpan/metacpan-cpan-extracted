#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


typedef struct {
	double time;
	double rate;
} PAIR;

int foo( PAIR curve[] ){
	PAIR *c;
	int x = 0;

	for( c = curve + x; c->time > -0.1; c = curve + x ){
		printf("idx = %d\n", x );
		printf("  time = %f\n", c->time );
		printf("  rate = %f\n", c->rate );
		++x;
	}
	c = curve + x;
	printf("idx = %d\n", x );
	printf("  time = %f\n", c->time );
	printf("  rate = %f\n", c->rate );
}


MODULE = CookBookB::ArrayOfStruct		PACKAGE = CookBookB::ArrayOfStruct

PAIR *
new(CLASS,cnt)
	char *CLASS
	int cnt
    PREINIT:
	int x = 0;
	PAIR *c;
    CODE:
	RETVAL = (PAIR *)safemalloc(sizeof(PAIR) * cnt);
	if( RETVAL == NULL ){
		warn("unable to malloc PAIR");
		XSRETURN_UNDEF;
	}
	for( c = RETVAL; x < (cnt - 1); c = RETVAL + x ){
		c->time = 0.1 + (double)x;
		c->rate = 0.1 + (double)x;
		++x;
	}
	c = RETVAL + x;
	c->time = -0.1;
	c->rate = -0.1;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	PAIR *self
    CODE:
	safefree((char*)self);

int
foo(self)
	PAIR *self

void
fill(self,index,newtime,newrate)
	PAIR *self
	int index
	double newtime
	double newrate
    PREINIT:
	PAIR *c;
    CODE:
	c = self + index;
	c->time = newtime;
	c->rate = newrate;
