#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/TaxaMediator.h"
# include "src/types.h"

TaxaMediator* create(const char* classname) {
	static TaxaMediator* singleton = NULL;
	if ( singleton == NULL ) {
		Newx(singleton,1,TaxaMediator);	
		initialize_taxamediator(singleton);	
	}
	return singleton;
}

void initialize_taxamediator(TaxaMediator* self) {
	self->object = newHV();
	self->id_by_type = newHV();
	self->one_to_one = newHV();
	self->one_to_many = newHV();
	((Identifiable*)self)->_type = _NONE_;
	((Identifiable*)self)->_container = _NONE_;
	((Identifiable*)self)->_index = _TAXAMEDIATOR_IDX_;		
}

//TaxaMediator* register_object( TaxaMediator* self, Identifiable* object );
//TaxaMediator* unregister_object( TaxaMediator* self, Identifiable* object );
//TaxaMediator* set_link( TaxaMediator* self, ... );
//TaxaMediator* get_link( TaxaMediator* self, ... );
//TaxaMediator* remove_link( TaxaMediator* self, ... );

MODULE = Bio::PhyloXS::Mediators::TaxaMediator  PACKAGE = Bio::PhyloXS::Mediators::TaxaMediator  

PROTOTYPES: DISABLE


TaxaMediator *
create (classname)
	const char *	classname

void
initialize_taxamediator (self)
	TaxaMediator *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_taxamediator(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

