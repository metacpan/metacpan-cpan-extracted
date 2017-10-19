#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/TypeSafeData.h"
# include "src/Listable.h"
# include "src/Datatype.h"
# include "src/types.h"

TypeSafeData* create(const char * classname) {
	TypeSafeData *self;
	Newx(self,1,TypeSafeData);
	initialize_typesafedata(self);
	return self;
}

void initialize_typesafedata(TypeSafeData* self){
	initialize_listable((Listable*)self);

	// create datatype object
	Newx(self->datatype,1,Datatype);
	initialize_writable((Writable*)self->datatype);
	self->datatype->missing = '?';
	self->datatype->gap = '-';
	self->datatype->datatype = 0;
	((Identifiable*)self->datatype)->_type = _DATATYPE_;
	((Identifiable*)self->datatype)->_container = _NONE_;
	((Identifiable*)self->datatype)->_index = _DATATYPE_IDX_;		
}

TypeSafeData* set_type(TypeSafeData* self, char* type) {
	if ( tolower(type[0]) == 'd' ) {
		self->datatype->datatype = _DNA_;
	}
	else if ( tolower(type[0]) == 'r' ) {
		self->datatype->datatype = _RNA_;
	}
	else if ( tolower(type[0]) == 'p' ) {
		self->datatype->datatype = _PROTEIN_;
	}
	else if ( tolower(type[0]) == 's' ) {
		self->datatype->datatype = _STANDARD_;
	}
	else if ( tolower(type[0]) == 'c' ) {
		self->datatype->datatype = _CONTINUOUS_;
	}
	else {
		warn("Unsupported data type");
	}
	return self;
}

char get_missing(TypeSafeData* self) {
	return self->datatype->missing;
}

TypeSafeData* set_missing(TypeSafeData* self, char missing) {
	self->datatype->missing = missing;
	return self;
}

char get_gap(TypeSafeData* self) {
	return self->datatype->gap;
}

TypeSafeData* set_gap(TypeSafeData* self, char gap) {
	self->datatype->gap = gap;
	return self;
}

char* get_type(TypeSafeData* self) {
	char* retval;
	switch(self->datatype->datatype) {
		case _DNA_:
			retval = "dna";
			break;
		case _RNA_:
			retval = "rna";
			break;
		case _PROTEIN_:
			retval = "protein";
			break;
		case _STANDARD_:
			retval = "protein";
			break;
		case _CONTINUOUS_:
			retval = "continuous";
			break;
		default:
			warn("Datatype undefined");
			break;
	}
	return retval;
}

Datatype* get_type_object(TypeSafeData* self) {
	return self->datatype;
}

TypeSafeData* set_type_object(TypeSafeData* self, Datatype* type) {
	self->datatype = type;
	return self;
}

void destroy_typesafedata(TypeSafeData* self) {
	destroy_listable((Listable*)self);	
	Safefree(self->datatype);
}
MODULE = Bio::PhyloXS::Matrices::TypeSafeData  PACKAGE = Bio::PhyloXS::Matrices::TypeSafeData  

PROTOTYPES: DISABLE


TypeSafeData *
create (classname)
	const char *	classname

void
initialize_typesafedata (self)
	TypeSafeData *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_typesafedata(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

TypeSafeData *
set_type (self, type)
	TypeSafeData *	self
	char *	type

char
get_missing (self)
	TypeSafeData *	self

TypeSafeData *
set_missing (self, missing)
	TypeSafeData *	self
	char	missing

char
get_gap (self)
	TypeSafeData *	self

TypeSafeData *
set_gap (self, gap)
	TypeSafeData *	self
	char	gap

char *
get_type (self)
	TypeSafeData *	self

Datatype *
get_type_object (self)
	TypeSafeData *	self

TypeSafeData *
set_type_object (self, type)
	TypeSafeData *	self
	Datatype *	type

void
destroy_typesafedata (self)
	TypeSafeData *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_typesafedata(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

