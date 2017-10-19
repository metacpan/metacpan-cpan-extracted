#ifndef TAXAMEDIATOR_H
#define TAXAMEDIATOR_H

# include "src/Identifiable.h"

typedef struct {
	Identifiable identifiable;
	HV* object;
	HV* id_by_type;
	HV* one_to_one;
	HV* one_to_many;
} TaxaMediator;

void initialize_taxamediator(TaxaMediator* self);
TaxaMediator* register_object( TaxaMediator* self, Identifiable* object );
TaxaMediator* unregister_object( TaxaMediator* self, Identifiable* object );
TaxaMediator* set_link( TaxaMediator* self, ... );
TaxaMediator* get_link( TaxaMediator* self, ... );
TaxaMediator* remove_link( TaxaMediator* self, ... );

#endif
