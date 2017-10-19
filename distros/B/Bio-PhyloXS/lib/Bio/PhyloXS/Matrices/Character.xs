#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/Character.h"
# include "src/TypeSafeData.h"
# include "src/types.h"

Character* create(const char * classname) {
	Character *self;
	Newx(self,1,Character);
	initialize_character(self);
	return self;
}

void initialize_character(Character* self){
	initialize_typesafedata((TypeSafeData*)self);
	((Identifiable*)self)->_type = _CHARACTER_;
	((Identifiable*)self)->_container = _CHARACTERS_;
	((Identifiable*)self)->_index = _CHARACTER_IDX_;	
}

void destroy_character(Character* self){
	destroy_typesafedata((TypeSafeData*)self);
	//Safefree(self);
}
MODULE = Bio::PhyloXS::Matrices::Character  PACKAGE = Bio::PhyloXS::Matrices::Character  

PROTOTYPES: DISABLE


Character *
create (classname)
	const char *	classname

void
initialize_character (self)
	Character *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_character(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
destroy_character (self)
	Character *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_character(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

