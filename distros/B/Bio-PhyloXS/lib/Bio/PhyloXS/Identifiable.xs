#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/types.h"
# include "src/Identifiable.h"

void initialize_identifiable(Identifiable* self){
	self->id = idpool++;
}

int get_id(Identifiable* self){
	return self->id;
}

int _type(Identifiable* self){
	return self->_type;
}

int _container(Identifiable* self){
	return self->_container;
}

int _index(Identifiable* self) {
	return self->_index;
}

void destroy_identifiable(Identifiable* self) {
	//Safefree(self);
}
MODULE = Bio::PhyloXS::Identifiable  PACKAGE = Bio::PhyloXS::Identifiable  

PROTOTYPES: DISABLE


void
initialize_identifiable (self)
	Identifiable *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_identifiable(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
get_id (self)
	Identifiable *	self

int
_type (self)
	Identifiable *	self

int
_container (self)
	Identifiable *	self

int
_index (self)
	Identifiable *	self

void
destroy_identifiable (self)
	Identifiable *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_identifiable(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

