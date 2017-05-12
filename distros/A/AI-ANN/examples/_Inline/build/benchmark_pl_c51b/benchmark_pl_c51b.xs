#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"
#include <math.h>
double afunc[4001];	
double dafunc[4001];
void generate_globals() {
	int i;
	for (i=0;i<=4000;i++) {
		afunc[i]=2 * erf(i/1000.0-2);
		dafunc[i]=4/sqrt(M_PI) * exp(-1 * (i/1000.0-2) ** 2);
	}
}
double afunc_c (float input) {
	return afunc[int((input)*1000)];
}
double dafunc_c (float input) {
	return dafunc[int((input)*1000)];
}

MODULE = benchmark_pl_c51b	PACKAGE = main	

PROTOTYPES: DISABLE


void
generate_globals ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	generate_globals();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

double
afunc_c (input)
	float	input

double
dafunc_c (input)
	float	input

