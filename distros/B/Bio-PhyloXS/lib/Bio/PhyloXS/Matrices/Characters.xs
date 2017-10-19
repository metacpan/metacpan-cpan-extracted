#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/Characters.h"
# include "src/TypeSafeData.h"
# include "src/types.h"

Characters* create(const char * classname) {
	Characters *self;
	Newx(self,1,Characters);		
	initialize_characters(self);
	return self;
}

void initialize_characters(Characters* self){
	initialize_typesafedata((TypeSafeData*)self);
	((Identifiable*)self)->_type = _CHARACTERS_;	
	((Identifiable*)self)->_container = _NONE_;	
	((Identifiable*)self)->_index = _CHARACTERS_IDX_;			
}

void destroy_characters(Characters* self) {
	destroy_typesafedata((TypeSafeData*)self);
	//Safefree(self);
}
MODULE = Bio::PhyloXS::Matrices::Characters  PACKAGE = Bio::PhyloXS::Matrices::Characters  

PROTOTYPES: DISABLE


Characters *
create (classname)
	const char *	classname

void
initialize_characters (self)
	Characters *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_characters(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
destroy_characters (self)
	Characters *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_characters(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

