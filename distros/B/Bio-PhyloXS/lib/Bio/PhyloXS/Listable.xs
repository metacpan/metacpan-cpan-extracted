#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/types.h"
#include "src/Exceptions.h"
#include "src/Identifiable.h"
#include "src/Listable.h"
#include "src/Writable.h"
#include "src/Node.h"

void initialize_listable(Listable* self){
	initialize_writable((Writable*)self);
	self->index = 0;
	self->entities = newAV();
}

int can_contain(Listable* self, Identifiable* element) {
	Identifiable* listid = (Identifiable*)self;
	
	// in most cases, a simple comparison between the _type
	// and _container fields should suffice
	if ( listid->_type == element->_container ) {
		return 1;
	}
	
	// tree nodes can go into trees, but also in other nodes
	// as their children
	else if ( listid->_type == _NODE_ && element->_type == _NODE_ ) {
		return 1;
	}
	
	// XXX once we deal with raw character data going into matrix rows
	// we will need one more possibility here
	else {
		return 0;
	}
}

void insert(Listable* self, Identifiable* element) {
	if ( can_contain(self,element) ) {
		SV* sv = newSV(0);
		int idx = element->_index;
		sv_setref_pv( sv, package[idx], (void*)element );
		SvREFCNT_inc(sv);
		av_push(self->entities, sv);
		
		if ( element->_type == _NODE_ ) {
			((Node*)element)->tree = (Tree*)self;
		}
	}
	else {
		croak("Object mismatch!");		
	}
}

void insert_at_index(Listable* self, Identifiable* element, int index) {		
	if ( can_contain(self,element) ) {	
		SV* sv = newSV(0);	
		int idx = element->_index;		
		sv_setref_pv( sv, package[idx], (void*)element );
		SvREFCNT_inc(sv);
		av_store(self->entities, index, sv);
	}
	else {
		croak("Object mismatch!");
	}
}

void splice_at_index(Listable* self, Identifiable* element, int index) {
	if ( can_contain(self,element) ) {
		
		// move any subsequent elements over
		//int i;
		//for ( i = ( self->used - 1 ); i >= index; i-- ) {
		//	self->entities[i+1] = self->entities[i];
		//}
		//self->entities[index] = element;
		//SvREFCNT_inc(element->ref);
	}
	else {
		croak("Object mismatch!");
	}
}

AV* get_entities(Listable* self) {
	return self->entities;
}

void destroy_listable(Listable* self) {
	destroy_writable((Writable*)self);
	//SvREFCNT_dec( self->entities );
}
MODULE = Bio::PhyloXS::Listable  PACKAGE = Bio::PhyloXS::Listable  

PROTOTYPES: DISABLE


void
initialize_listable (self)
	Listable *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_listable(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
can_contain (self, element)
	Listable *	self
	Identifiable *	element

void
insert (self, element)
	Listable *	self
	Identifiable *	element
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        insert(self, element);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
insert_at_index (self, element, index)
	Listable *	self
	Identifiable *	element
	int	index
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        insert_at_index(self, element, index);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
splice_at_index (self, element, index)
	Listable *	self
	Identifiable *	element
	int	index
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        splice_at_index(self, element, index);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

AV *
get_entities (self)
	Listable *	self

void
destroy_listable (self)
	Listable *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_listable(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

