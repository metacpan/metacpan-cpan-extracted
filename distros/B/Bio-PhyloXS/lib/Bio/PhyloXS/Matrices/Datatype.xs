#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/Datatype.h"
# include "src/Writable.h"
# include "src/types.h"

Datatype* create(const char * classname) {
	Datatype *self;
	Newx(self,1,Datatype);	
	initialize_datatype(self);
	return self;
}

void initialize_datatype(Datatype* self){
	initialize_writable((Writable*)self);
	self->missing = '?';
	self->gap = '-';
	self->datatype = 0;
	((Identifiable*)self)->_type = _DATATYPE_;
	((Identifiable*)self)->_container = _NONE_;
	((Identifiable*)self)->_index = _DATATYPE_IDX_;	
}

Datatype* set_type(Datatype* self, char* type) {
	if ( tolower(type[0]) == 'd' ) {
		self->datatype = _DNA_;
	}
	else if ( tolower(type[0]) == 'r' ) {
		self->datatype = _RNA_;
	}
	else if ( tolower(type[0]) == 'p' ) {
		self->datatype = _PROTEIN_;
	}
	else if ( tolower(type[0]) == 's' ) {
		self->datatype = _STANDARD_;
	}
	else if ( tolower(type[0]) == 'c' ) {
		self->datatype = _CONTINUOUS_;
	}
	else {
		warn("Unsupported data type");
	}
	return self;
}

void _to_set_type(Datatype* self, char* type) {
	set_type(self,type);
}

char* get_type(Datatype* self) {
	char* retval;
	switch(self->datatype) {
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

char* _to_get_type(Datatype* self) {
	return get_type(self);
}

char get_missing(Datatype* self) {
	return self->missing;
}

Datatype* set_missing(Datatype* self, char missing) {
	self->missing = missing;
	return self;
}

char get_gap(Datatype* self) {
	return self->gap;
}

Datatype* set_gap(Datatype* self, char gap) {
	self->gap = gap;
	return self;
}

void destroy_datatype(Datatype* self) {
	destroy_writable((Writable*)self);
	//Safefree(self);
}
MODULE = Bio::PhyloXS::Matrices::Datatype  PACKAGE = Bio::PhyloXS::Matrices::Datatype  

PROTOTYPES: DISABLE


Datatype *
create (classname)
	const char *	classname

void
initialize_datatype (self)
	Datatype *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_datatype(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

Datatype *
set_type (self, type)
	Datatype *	self
	char *	type

void
_to_set_type (self, type)
	Datatype *	self
	char *	type
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _to_set_type(self, type);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

char *
get_type (self)
	Datatype *	self

char *
_to_get_type (self)
	Datatype *	self

char
get_missing (self)
	Datatype *	self

Datatype *
set_missing (self, missing)
	Datatype *	self
	char	missing

char
get_gap (self)
	Datatype *	self

Datatype *
set_gap (self, gap)
	Datatype *	self
	char	gap

void
destroy_datatype (self)
	Datatype *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_datatype(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

