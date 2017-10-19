#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

# include "src/types.h"
# include "src/Identifiable.h"
# include "src/Listable.h"
# include "src/Writable.h"
# include "src/Node.h"
# include "src/Tree.h"

Tree* create(const char * classname) {
	Tree *self;
	Newx(self,1,Tree);
	initialize_tree(self);
	return self;
}

void initialize_tree(Tree* self){
	initialize_listable((Listable*)self);
	self->is_unrooted = 0;
	self->is_default = 0;
	((Identifiable*)self)->_type = _TREE_;
	((Identifiable*)self)->_container = _FOREST_;
	((Identifiable*)self)->_index = _TREE_IDX_;	
}

Tree* set_as_unrooted(Tree* self){
	self->is_unrooted = 1;
	return self;
}

Tree* set_as_default(Tree* self) {
	self->is_default = 1;
	return self;
}

Tree* set_not_default(Tree* self) {
	self->is_default = 0;
	return self;
}

int is_default(Tree* self) {
	return self->is_default;
}

Node* get_root(Tree* self) {
	Listable* list = (Listable*)self;
	SSize_t max = av_len(list->entities);
	int i;
	for ( i = 0; i <= max; i++ ) {
		if ( av_exists(list->entities,i) ) {
			SV* sv = *(av_fetch(list->entities, i, 0));
			Node* node = (Node*)SvIV(SvRV(sv));
			if ( node->parent == NULL ) {
				return node;
			}
		}
	}
	return NULL;
}

void destroy_tree(Tree* self) {
	destroy_listable((Listable*)self);
}
MODULE = Bio::PhyloXS::Forest::Tree  PACKAGE = Bio::PhyloXS::Forest::Tree  

PROTOTYPES: DISABLE


Tree *
create (classname)
	const char *	classname

void
initialize_tree (self)
	Tree *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_tree(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

Tree *
set_as_unrooted (self)
	Tree *	self

Tree *
set_as_default (self)
	Tree *	self

Tree *
set_not_default (self)
	Tree *	self

int
is_default (self)
	Tree *	self

Node *
get_root (self)
	Tree *	self

void
destroy_tree (self)
	Tree *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_tree(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

