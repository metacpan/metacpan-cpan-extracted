#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"
# include "src/types.h"
# include "src/Identifiable.h"
# include "src/Writable.h"
# include "src/Listable.h"
# include "src/Node.h"

Node *create(const char *classname) {
	Node *self;
	Newx(self,1,Node);
	initialize_node(self);
	return self;
}

void initialize_node(Node* self) {
	initialize_listable((Listable*)self);
	self->parent = NULL;
	self->rank = NULL;
	self->tree = NULL;
	self->branch_length = 0.0;
	((Identifiable*)self)->_type = _NODE_;
	((Identifiable*)self)->_container = _TREE_;
	((Identifiable*)self)->_index = _NODE_IDX_;	
}

double get_branch_length(Node* self) {
	return self->branch_length;
}

Node* set_raw_branch_length(Node* self, ...) {
	Inline_Stack_Vars; // handle variable argument list
	if ( Inline_Stack_Items == 2 && Inline_Stack_Item(1) != NULL ) {
		SV* value = Inline_Stack_Item(1);
		if ( looks_like_number(value) ) {
			self->branch_length = SvNV(value);
		}
	}
	else {	
		self->branch_length = 0.0;
	}
	return self;
}

Node* set_tree(Node* self, Tree* tree) {
	self->tree = tree;
	return self;
}

Tree* get_tree(Node* self) {
	return self->tree;
}

char* get_rank(Node* self) {
	return self->rank;
}

Node* set_rank(Node* self, char * rank) {
	self->rank = savepv(rank);
	return self;
}

Node* set_raw_parent( Node* self, ... ) {
	Inline_Stack_Vars;	// handle variable argument list
	if ( Inline_Stack_Items == 2 && Inline_Stack_Item(1) != NULL ) {
		self->parent = (Node*)SvIV(SvRV(Inline_Stack_Item(1)));
	}
	else {
		self->parent = NULL;
	}
	return self;
}

Node* get_parent(Node* self) {
	return self->parent;
}

Node* set_raw_child( Node* self, Node* child, ... ) {
	Inline_Stack_Vars;	// handle variable argument list
	
	// determine where to place the child, 
	// default -1 means at the end 
	signed int position = -1;
	if ( Inline_Stack_Items > 2 ) {
		position = SvIV(Inline_Stack_Item(2));
	}
	
	if ( position == -1 ) {
		insert((Listable*)self, (Identifiable*)child);
	}
	else {
		insert_at_index((Listable*)self,(Identifiable*)child,position);
	}
	return self;
}

AV* get_children( Node* self ) {
	return ((Listable*)self)->entities;
}

Node* get_first_daughter( Node* self ) {
	AV* list = ((Listable*)self)->entities;
	if ( av_exists(list,0) ) {
		SV* sv = *(av_fetch(list, 0, 0));
		return (Node*)SvIV(SvRV(sv));
	}
	return NULL;
}

int is_child_of( Node* self, Node* parent ) {
	if ( self->parent != NULL ) {
		return ((Identifiable*)self->parent)->id == ((Identifiable*)parent)->id;
	}
	return 0;
}

int is_ancestor_of( Node* self, Node* desc ) {
	Node* p = desc->parent;
	int sid = ((Identifiable*)self)->id;
	while( p != NULL ) {
		if ( ((Identifiable*)p)->id == sid ) {
			return 1;
		}
		p = p->parent;
	}
	return 0;
}

int is_terminal( Node* self ) {
	return ! av_exists(((Listable*)self)->entities, 0);
}

int is_internal( Node* self ) {
	return av_exists(((Listable*)self)->entities, 0);
}

int is_root( Node* self ) {
	return self->parent == NULL;
}

void destroy_node(Node* self) {
	destroy_listable((Listable*)self);
}
MODULE = Bio::PhyloXS::Forest::Node  PACKAGE = Bio::PhyloXS::Forest::Node  

PROTOTYPES: DISABLE


Node *
create (classname)
	const char *	classname

void
initialize_node (self)
	Node *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        initialize_node(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

double
get_branch_length (self)
	Node *	self

Node *
set_raw_branch_length (self, ...)
	Node *	self
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = set_raw_branch_length(self);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

Node *
set_tree (self, tree)
	Node *	self
	Tree *	tree

Tree *
get_tree (self)
	Node *	self

char *
get_rank (self)
	Node *	self

Node *
set_rank (self, rank)
	Node *	self
	char *	rank

Node *
set_raw_parent (self, ...)
	Node *	self
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = set_raw_parent(self);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

Node *
get_parent (self)
	Node *	self

Node *
set_raw_child (self, child, ...)
	Node *	self
	Node *	child
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = set_raw_child(self, child);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

AV *
get_children (self)
	Node *	self

Node *
get_first_daughter (self)
	Node *	self

int
is_child_of (self, parent)
	Node *	self
	Node *	parent

int
is_ancestor_of (self, desc)
	Node *	self
	Node *	desc

int
is_terminal (self)
	Node *	self

int
is_internal (self)
	Node *	self

int
is_root (self)
	Node *	self

void
destroy_node (self)
	Node *	self
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        destroy_node(self);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

