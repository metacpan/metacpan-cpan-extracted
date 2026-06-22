#include "qtbase.h"

#define CHILDREN_PER_NODE 4
#define MAX_SIZE_INITIAL 4
#define MAX_SIZE_GROWTH 2
#define MAX_SIZE_CLEAR 32

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

void clear_array(DynArr *arr)
{
	arr->count = 0;

	if (arr->max_size >= MAX_SIZE_CLEAR) {
		arr->max_size = 0;
		free(arr->ptr);
	}
}

void refresh_object_array (DynArr* arr)
{
	int i;
	for (i = 0; i < arr->count; ++i) {
		SvREFCNT_dec((SV*) arr->ptr[i]);
	}

	clear_array(arr);
}

void push_array(DynArr *arr, void *ptr)
{
	if (arr->count == arr->max_size) {
		if (arr->max_size == 0) {
			arr->max_size = MAX_SIZE_INITIAL;
			arr->ptr = malloc(arr->max_size * sizeof *arr->ptr);
		}
		else {
			arr->max_size *= MAX_SIZE_GROWTH;

			void *enlarged = realloc(arr->ptr, arr->max_size * sizeof *arr->ptr);
			assert(enlarged != NULL);

			arr->ptr = enlarged;
		}
	}

	arr->ptr[arr->count] = ptr;
	arr->count += 1;
}

void push_array_SV(DynArr *arr, SV *ptr)
{
	push_array(arr, ptr);
	SvREFCNT_inc(ptr);
}

QuadTreeNode* create_nodes(int count, QuadTreeNode *parent)
{
	QuadTreeNode *node = malloc(count * sizeof *node);

	int i;
	for (i = 0; i < count; ++i) {
		node[i].values = NULL;
		node[i].children = NULL;
		node[i].parent = parent;
		node[i].has_objects = false;
	}

	return node;
}

/* NOTE: does not actually free the node, but frees its children nodes */
void destroy_node(QuadTreeNode *node)
{
	if (node->values != NULL) {
		destroy_array(node->values);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			destroy_node(&node->children[i]);
		}

		free(node->children);
	}
}

void clear_has_objects (QuadTreeNode *node)
{
	if (node->values == NULL) {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			if (node->children[i].has_objects) return;
		}
	}

	node->has_objects = false;
	if (node->parent != NULL) {
		clear_has_objects(node->parent);
	}
}

QuadTreeRootNode* create_root_nobackref()
{
	QuadTreeRootNode *root = malloc(sizeof *root);
	root->node = create_nodes(1, NULL);
	root->backref = NULL;
	root->objects = create_array();

	return root;
}

QuadTreeRootNode* create_root()
{
	QuadTreeRootNode *root = create_root_nobackref();
	root->backref = newHV();

	return root;
}

void store_backref(QuadTreeRootNode *root, QuadTreeNode* node, SV *value)
{
	DynArr *list;
	if (!hv_exists_ent(root->backref, value, 0)) {
		list = create_array();
		hv_store_ent(root->backref, value, newSViv((uintptr_t) list), 0);
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
		node->children = create_nodes(CHILDREN_PER_NODE, node);
		double xmid = xmin + (xmax - xmin) / 2;
		double ymid = ymin + (ymax - ymin) / 2;

		node_add_level(&node->children[0], xmin, ymin, xmid, ymid, depth);
		node_add_level(&node->children[1], xmin, ymid, xmid, ymax, depth);
		node_add_level(&node->children[2], xmid, ymin, xmax, ymid, depth);
		node_add_level(&node->children[3], xmid, ymid, xmax, ymax, depth);
	}
}

bool is_within_node(QuadTreeNode *node, Shape *s)
{
	switch (s->type) {
		case shape_rectangle: {
			return (s->x <= node->xmax && s->x2 >= node->xmin)
				&& (s->y <= node->ymax && s->y2 >= node->ymin);
		}

		case shape_circle: {
			double check_x = s->x < node->xmin
				? node->xmin - s->x
				: s->x > node->xmax
					? node->xmax - s->x
					: 0
			;

			double check_y = s->y < node->ymin
				? node->ymin - s->y
				: s->y > node->ymax
					? node->ymax - s->y
					: 0
			;

			return check_x * check_x + check_y * check_y <= s->radius_sq;
		}
	}
}

void find_nodes(QuadTreeNode *node, HV *ret, Shape *param)
{
	if (!node->has_objects || !is_within_node(node, param)) return;

	int i;

	if (node->values != NULL) {
		for (i = 0; i < node->values->count; ++i) {
			SV *fetched = (SV*) node->values->ptr[i];
			SvREFCNT_inc(fetched);
			hv_store_ent(ret, fetched, fetched, 0);
		}
	}
	else {
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			find_nodes(&node->children[i], ret, param);
		}
	}
}

bool fill_nodes_nobackref(QuadTreeNode *node, SV *value, Shape *param)
{
	if (!is_within_node(node, param)) return false;

	if (node->values != NULL) {
		push_array(node->values, value);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			fill_nodes_nobackref(&node->children[i], value, param);
		}
	}

	/* NOTE: only first level result is important, since if the object fits in
	 * the tree area at all, it must fit into one of the leaves */
	node->has_objects = true;
	return true;
}

bool fill_nodes(QuadTreeRootNode *root, QuadTreeNode *node, SV *value, Shape *param)
{
	if (!is_within_node(node, param)) return false;

	if (node->values != NULL) {
		push_array(node->values, value);
		if (root->backref != NULL)
			store_backref(root, node, value);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			fill_nodes(root, &node->children[i], value, param);
		}
	}

	/* NOTE: only first level result is important, since if the object fits in
	 * the tree area at all, it must fit into one of the leaves */
	node->has_objects = true;
	return true;
}

void clear_node(QuadTreeNode *node)
{
	if (!node->has_objects) return;
	node->has_objects = false;

	if (node->values != NULL) {
		clear_array(node->values);
	}
	else {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			clear_node(&node->children[i]);
		}
	}
}

void clear_tree(QuadTreeRootNode *root)
{
	clear_node(root->node);

	char *key;
	I32 retlen;
	SV *value;

	if (root->backref != NULL) {
		hv_iterinit(root->backref);
		while ((value = hv_iternextsv(root->backref, &key, &retlen)) != NULL) {
			destroy_array((DynArr*) SvIV(value));
		}

		hv_clear(root->backref);
	}

	refresh_object_array(root->objects);
}

/* XS helpers */

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

AV* get_hash_values (HV* hash)
{
	AV *ret = newAV();
	HE *he;

	hv_iterinit(hash);
	while ((he = hv_iternext(hash)) != NULL) {
		SV *fetched = HeVAL(he);
		SvREFCNT_inc(fetched);
		av_push(ret, fetched);
	}

	return ret;
}

