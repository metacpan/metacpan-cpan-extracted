#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void _binding_ok(){
	printf("all is well\n");
}
MODULE = Bio::PhyloXS  PACKAGE = Bio::PhyloXS  

PROTOTYPES: DISABLE


void
_binding_ok ()
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _binding_ok();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

