#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define CHILDREN_PER_NODE 4

typedef struct QuadTreeNode QuadTreeNode;
typedef struct QuadTreeRootNode QuadTreeRootNode;
typedef struct DynArr DynArr;
typedef struct Shape Shape;

typedef enum ShapeType ShapeType;

struct QuadTreeNode {
	QuadTreeNode *children;
	DynArr *values;
	double xmin, ymin, xmax, ymax;
};

struct QuadTreeRootNode {
	QuadTreeNode *node;
	HV *backref;
};

struct DynArr {
	void **ptr;
	unsigned int count;
	unsigned int max_size;
};

enum ShapeType {
	shape_rectangle,
	shape_circle
};

struct Shape {
	ShapeType type;
	double dimensions[4];
};

DynArr* create_array()
{
	DynArr *arr = malloc(sizeof *arr);
	arr->count = 0;
	arr->max_size = 0;

	return arr;
}

void destroy_array(DynArr* arr)
{
	if (arr->max_size > 0) {
		free(arr->ptr);
	}

	free(arr);
}

void destroy_array_SV(DynArr* arr)
{
	int i;
	for (i = 0; i < arr->count; ++i) {
		SvREFCNT_dec((SV*) arr->ptr[i]);
	}

	destroy_array(arr);
}

void push_array(DynArr *arr, void *ptr)
{
	if (arr->max_size == 0) {
		arr->max_size = 2;
		arr->ptr = malloc(arr->max_size * sizeof *arr->ptr);
	}
	else if (arr->count == arr->max_size) {
		arr->max_size *= 2;

		void *enlarged = realloc(arr->ptr, arr->max_size * sizeof *arr->ptr);
		assert(enlarged != NULL);

		arr->ptr = enlarged;
	}

	arr->ptr[arr->count] = ptr;
	arr->count += 1;
}

void push_array_SV(DynArr *arr, SV *ptr)
{
	push_array(arr, ptr);
	SvREFCNT_inc(ptr);
}

QuadTreeNode* create_nodes(int count)
{
	QuadTreeNode *node = malloc(count * sizeof *node);

	int i;
	for (i = 0; i < count; ++i) {
		node[i].values = NULL;
		node[i].children = NULL;
	}

	return node;
}

// NOTE: does not actually free the node, but frees its children nodes
void destroy_node(QuadTreeNode *node)
{
	if (node->values != NULL) {
		destroy_array_SV(node->values);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			destroy_node(&node->children[i]);
		}

		free(node->children);
	}
}

QuadTreeRootNode* create_root()
{
	QuadTreeRootNode *root = malloc(sizeof *root);
	root->node = create_nodes(1);
	root->backref = newHV();

	return root;
}

void store_backref(QuadTreeRootNode *root, QuadTreeNode* node, SV *value)
{
	DynArr *list;
	if (!hv_exists_ent(root->backref, value, 0)) {
		list = create_array();
		hv_store_ent(root->backref, value, newSViv((unsigned long) list), 0);
	}
	else {
		list = (DynArr*) SvIV(HeVAL(hv_fetch_ent(root->backref, value, 0, 0)));
	}

	push_array(list, node);
}

void node_add_level(QuadTreeNode* node, double xmin, double ymin, double xmax, double ymax, int depth)
{
	bool last = --depth == 0;

	node->xmin = xmin;
	node->ymin = ymin;
	node->xmax = xmax;
	node->ymax = ymax;

	if (last) {
		node->values = create_array();
	}
	else {
		node->children = create_nodes(CHILDREN_PER_NODE);
		double xmid = xmin + (xmax - xmin) / 2;
		double ymid = ymin + (ymax - ymin) / 2;

		node_add_level(&node->children[0], xmin, ymin, xmid, ymid, depth);
		node_add_level(&node->children[1], xmin, ymid, xmid, ymax, depth);
		node_add_level(&node->children[2], xmid, ymin, xmax, ymid, depth);
		node_add_level(&node->children[3], xmid, ymid, xmax, ymax, depth);
	}
}

bool is_within_node_rect(QuadTreeNode *node, double xmin, double ymin, double xmax, double ymax)
{
	return (xmin <= node->xmax && xmax >= node->xmin)
		&& (ymin <= node->ymax && ymax >= node->ymin);
}

bool is_within_node_circ(QuadTreeNode *node, double x, double y, double radius)
{
	double check_x = x < node->xmin
		? node->xmin
		: x > node->xmax
			? node->xmax
			: x
	;

	double check_y = y < node->ymin
		? node->ymin
		: y > node->ymax
			? node->ymax
			: y
	;

	check_x -= x;
	check_y -= y;

	return check_x * check_x + check_y * check_y <= radius * radius;
}

bool is_within_node(QuadTreeNode *node, Shape *param)
{
	switch (param->type) {
		case shape_rectangle:
			return is_within_node_rect(node, param->dimensions[0], param->dimensions[1], param->dimensions[2], param->dimensions[3]);
		case shape_circle:
			return is_within_node_circ(node, param->dimensions[0], param->dimensions[1], param->dimensions[2]);
	}
}

void find_nodes(QuadTreeNode *node, AV *ret, Shape *param)
{
	if (!is_within_node(node, param)) return;

	int i;

	if (node->values != NULL) {
		for (i = 0; i < node->values->count; ++i) {
			SV *fetched = (SV*) node->values->ptr[i];
			SvREFCNT_inc(fetched);
			av_push(ret, fetched);
		}
	}
	else {
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			find_nodes(&node->children[i], ret, param);
		}
	}
}

void fill_nodes(QuadTreeRootNode *root, QuadTreeNode *node, SV *value, Shape *param)
{
	if (!is_within_node(node, param)) return;

	if (node->values != NULL) {
		push_array_SV(node->values, value);
		store_backref(root, node, value);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			fill_nodes(root, &node->children[i], value, param);
		}
	}
}

// XS helpers

SV* get_hash_key (HV* hash, const char* key)
{
	SV **value = hv_fetch(hash, key, strlen(key), 0);

	assert(value != NULL);
	return *value;
}

QuadTreeRootNode* get_root_from_perl(SV *self)
{
	HV *params = (HV*) SvRV(self);

	return (QuadTreeRootNode*) SvIV(get_hash_key(params, "ROOT"));
}

// proper XS Code starts here

MODULE = Algorithm::QuadTree::XS		PACKAGE = Algorithm::QuadTree::XS

PROTOTYPES: DISABLE

void
_AQT_init(obj)
		SV *obj
	CODE:
		QuadTreeRootNode *root = create_root();

		HV *params = (HV*) SvRV(obj);

		node_add_level(root->node,
			SvNV(get_hash_key(params, "XMIN")),
			SvNV(get_hash_key(params, "YMIN")),
			SvNV(get_hash_key(params, "XMAX")),
			SvNV(get_hash_key(params, "YMAX")),
			SvIV(get_hash_key(params, "DEPTH"))
		);

		SV *root_sv = newSViv((unsigned long) root);
		SvREADONLY_on(root_sv);
		hv_stores(params, "ROOT", root_sv);

void
_AQT_deinit(self)
		SV *self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		call_method("_AQT_clear", 0);
		destroy_node(root->node);
		free(root->node);
		SvREFCNT_dec((SV*) root->backref);

		free(root);


void
_AQT_addObject(self, object, x, y, x2_or_radius, ...)
		SV *self
		SV *object
		double x
		double y
		double x2_or_radius
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		Shape param;
		param.type = shape_circle;
		param.dimensions[0] = x;
		param.dimensions[1] = y;
		param.dimensions[2] = x2_or_radius;

		if (items > 5) {
			param.type = shape_rectangle;
			param.dimensions[3] = SvNV(ST(5));
		}

		fill_nodes(root, root->node, object, &param);

SV*
_AQT_findObjects(self, x, y, x2_or_radius, ...)
		SV *self
		double x
		double y
		double x2_or_radius
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		AV *ret = newAV();

		Shape param;
		param.type = shape_circle;
		param.dimensions[0] = x;
		param.dimensions[1] = y;
		param.dimensions[2] = x2_or_radius;

		if (items > 4) {
			param.type = shape_rectangle;
			param.dimensions[3] = SvNV(ST(4));
		}

		find_nodes(root->node, ret, &param);

		RETVAL = newRV_noinc((SV*) ret);
	OUTPUT:
		RETVAL

void
_AQT_delete(self, object)
		SV *self
		SV *object
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		if (hv_exists_ent(root->backref, object, 0)) {
			DynArr* list = (DynArr*) SvIV(HeVAL(hv_fetch_ent(root->backref, object, 0, 0)));

			int i, j;
			for (i = 0; i < list->count; ++i) {
				QuadTreeNode *node = (QuadTreeNode*) list->ptr[i];
				DynArr* new_list = create_array();

				for(j = 0; j < node->values->count; ++j) {
					SV *fetched = (SV*) node->values->ptr[j];
					if (!sv_eq(fetched, object)) {
						push_array_SV(new_list, fetched);
					}
				}

				destroy_array_SV(node->values);
				node->values = new_list;
			}

			destroy_array(list);
			hv_delete_ent(root->backref, object, 0, 0);
		}

void
_AQT_clear(self)
		SV* self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		char *key;
		I32 retlen;
		SV *value;
		int i;

		hv_iterinit(root->backref);
		while ((value = hv_iternextsv(root->backref, &key, &retlen)) != NULL) {
			DynArr *list = (DynArr*) SvIV(value);
			for (i = 0; i < list->count; ++i) {
				QuadTreeNode *node = (QuadTreeNode*) list->ptr[i];
				destroy_array_SV(node->values);
				node->values = create_array();
			}

			destroy_array(list);
		}

		hv_clear(root->backref);

