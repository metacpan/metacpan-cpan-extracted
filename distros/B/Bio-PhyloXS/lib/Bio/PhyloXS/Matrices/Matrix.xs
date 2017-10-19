#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/Matrix.h"
# include "src/TypeSafeData.h"
# include "src/Characters.h"
# include "src/types.h"

Matrix* create(const char * classname) {
	Matrix *self;
	Newx(self,1,Matrix);
	initialize_matrix(self);
	return self;
}

void initialize_matrix(Matrix* self){
	initialize_typesafedata((TypeSafeData*)self);
	self->charlabels = newAV();
	self->statelabels = newAV();
	self->gapmode = 1;
	self->matchchar = '.';
	self->polymorphism = 0;
	self->respectcase = 1;
	((Identifiable*)self)->_type = _MATRIX_;
	((Identifiable*)self)->_container = _MATRICES_;	
	((Identifiable*)self)->_index = _MATRIX_IDX_;		
	
	// allocate and initialize Characters* field
	Newx(self->characters,1,Characters);
	initialize_characters(self->characters);
}

void destroy_matrix(Matrix* self) {
	destroy_characters(self->characters);
	destroy_typesafedata((TypeSafeData*)self);
	//Safefree(self);
}
MODULE = Bio::PhyloXS::Matrices::Matrix  PACKAGE = Bio::PhyloXS::Matrices::Matrix  

PROTOTYPES: DISABLE


Matrix *
create (classname)
	const char *	classname

void
initialize_matrix (self)
	Matrix *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_matrix(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
destroy_matrix (self)
	Matrix *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_matrix(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

