#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/Datum.h"
# include "src/TypeSafeData.h"
# include "src/types.h"

Datum* create(const char * classname) {
	Datum *self;
	Newx(self,1,Datum);
	initialize_datum(self);
	return self;
}

void initialize_datum(Datum* self){
	initialize_typesafedata((TypeSafeData*)self);
	self->position = 0;
	self->weight = 1.0;
	self->annotations = newAV();
	((Identifiable*)self)->_type = _DATUM_;
	((Identifiable*)self)->_container = _MATRIX_;
	((Identifiable*)self)->_index = _DATUM_IDX_;	
}

void destroy_datum(Datum* self) {
	destroy_typesafedata((TypeSafeData*)self);
	SvREFCNT_dec( self->annotations );
}
MODULE = Bio::PhyloXS::Matrices::Datum  PACKAGE = Bio::PhyloXS::Matrices::Datum  

PROTOTYPES: DISABLE


Datum *
create (classname)
	const char *	classname

void
initialize_datum (self)
	Datum *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_datum(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
destroy_datum (self)
	Datum *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_datum(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

