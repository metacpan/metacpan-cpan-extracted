#include "qtbase.h"
#include <math.h>

#define CHILDREN_PER_NODE 4

Shape* create_shape()
{
	Shape *s = malloc(sizeof *s);
	return s;
}

void prepare_rectangle(Shape *s, double x, double y, double x2, double y2)
{
	s->type = shape_rectangle;
	s->x = x;
	s->y = y;
	s->x2 = x2;
	s->y2 = y2;
}

void prepare_circle(Shape *s, double x0, double y0, double radius)
{
	s->type = shape_circle;
	s->x0 = x0;
	s->y0 = y0;
	s->radius = radius;
	s->radius_sq = radius * radius;

	double contained_radius = s->radius / sqrt(2);
	s->x = x0 - contained_radius;
	s->x2 = x0 + contained_radius;
	s->y = y0 - contained_radius;
	s->y2 = y0 + contained_radius;
}

void destroy_shape(Shape *s)
{
	free(s);
}

void adopt_object (QuadTreeRootNode *root, SV *value, Shape *s)
{
	hv_store_ent(root->backref, value, newSViv((uintptr_t) s), 0);
}

void disown_object (QuadTreeRootNode *root, SV *value)
{
	/* NOTE: no shape destruction here, since "adopt_object" does not create it */
	hv_delete_ent(root->backref, value, 0, 0);
}

QuadTreeNode* create_nodes(int count)
{
	QuadTreeNode *node = malloc(count * sizeof *node);

	int i;
	for (i = 0; i < count; ++i) {
		node[i].values = NULL;
		node[i].children = NULL;
		node[i].has_objects = false;
	}

	return node;
}

/* NOTE: does not actually free the node, but frees its children nodes */
void destroy_node(QuadTreeNode *node)
{
	SvREFCNT_dec((SV*) node->values);
	destroy_shape(node->dimensions);

	if (node->children != NULL) {
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

void node_add_level(QuadTreeNode* node, double xmin, double ymin, double xmax, double ymax, int depth)
{
	bool last = --depth == 0;

	node->dimensions = create_shape();
	prepare_rectangle(node->dimensions, xmin, ymin, xmax, ymax);
	node->values = newAV();

	if (!last) {
		node->children = create_nodes(CHILDREN_PER_NODE);
		double xmid = xmin + (xmax - xmin) / 2;
		double ymid = ymin + (ymax - ymin) / 2;

		node_add_level(&node->children[0], xmin, ymin, xmid, ymid, depth);
		node_add_level(&node->children[1], xmin, ymid, xmid, ymax, depth);
		node_add_level(&node->children[2], xmid, ymin, xmax, ymid, depth);
		node_add_level(&node->children[3], xmid, ymid, xmax, ymax, depth);
	}
}

bool shape_contained (Shape *inner_s, Shape *s)
{
	return (s->x <= inner_s->x && s->x2 >= inner_s->x2)
		&& (s->y <= inner_s->y && s->y2 >= inner_s->y2);
}

bool shapes_overlap (Shape *s1, Shape *s2)
{
	if (s1->type == s2->type) {
		switch (s1->type) {
			case shape_circle: {
				/* circle vs circle */
				double distance_x = s1->x0 - s2->x0;
				double distance_y = s1->y0 - s2->y0;
				double radius = s1->radius + s2->radius;

				return distance_x * distance_x + distance_y * distance_y
					<= radius * radius;
			}
			case shape_rectangle: {
				/* rectangle vs rectangle */
				if (s1->type == shape_rectangle) {
					return (s1->x <= s2->x2 && s1->x2 >= s2->x)
						&& (s1->y <= s2->y2 && s1->y2 >= s2->y);
				}
			}
		}
	}

	/* circle vs rectangle - circle first */
	/* circles first, if available */
	if (s2->type == shape_circle) {
		Shape *stemp;
		stemp = s1;
		s1 = s2;
		s2 = stemp;
	}

	double check_x = s1->x0 < s2->x
		? s2->x - s1->x0
		: s1->x0 > s2->x2
			? s2->x2 - s1->x0
			: 0
	;

	double check_y = s1->y0 < s2->y
		? s2->y - s1->y0
		: s1->y0 > s2->y2
			? s2->y2 - s1->y0
			: 0
	;

	return check_x * check_x + check_y * check_y <= s1->radius_sq;
}

void find_nodes(QuadTreeNode *node, HV *ret, Shape *param, bool fully_contained)
{
	if (!node->has_objects) return;

	fully_contained = fully_contained || shape_contained(node->dimensions, param);
	if (!(fully_contained || shapes_overlap(param, node->dimensions))) return;

	int i;
	for (i = 0; i < av_count(node->values); ++i) {
		SV **fetched = av_fetch(node->values, i, 0);
		if (fetched != NULL) {
			SvREFCNT_inc(*fetched);
			hv_store_ent(ret, *fetched, *fetched, 0);
		}
	}

	if (node->children != NULL) {
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			find_nodes(&node->children[i], ret, param, fully_contained);
		}
	}
}

bool fill_nodes (QuadTreeNode *node, SV *value, Shape *param)
{
	if (shape_contained(node->dimensions, param)) {
		av_push(node->values, SvREFCNT_inc(value));
	}
	else {
		if (!shapes_overlap(param, node->dimensions)) return false;

		if (node->children == NULL) {
			av_push(node->values, SvREFCNT_inc(value));
		}
		else {
			int i;
			for (i = 0; i < CHILDREN_PER_NODE; ++i) {
				fill_nodes(&node->children[i], value, param);
			}
		}
	}

	/* NOTE: only first level result is important, since if the object fits in
	 * the tree area at all, it must fit into one of the leaves */
	node->has_objects = true;
	return true;
}

void delete_nodes(QuadTreeNode *node, SV *value, Shape *param, bool fully_contained)
{
	if (!node->has_objects) return;

	fully_contained = fully_contained || shape_contained(node->dimensions, param);
	if (!(fully_contained || shapes_overlap(param, node->dimensions))) return;

	int i;


	if (av_count(node->values) > 0) {
		AV* new_list = newAV();

		for (i = 0; i < av_count(node->values); ++i) {
			SV **fetched = av_fetch(node->values, i, 0);
			if (fetched != NULL && !sv_eq(*fetched, value)) {
				av_push(new_list, SvREFCNT_inc(*fetched));
			}
		}

		SvREFCNT_dec((SV*) node->values);
		node->values = new_list;
		node->has_objects = av_count(new_list) > 0;
	}

	if (node->children != NULL) {
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			delete_nodes(&node->children[i], value, param, fully_contained);
			node->has_objects = node->has_objects || node->children[i].has_objects;
		}
	}
}

void clear_node(QuadTreeNode *node)
{
	if (!node->has_objects) return;
	node->has_objects = false;
	av_clear(node->values);

	if (node->children != NULL) {
		int i;
		for (i = 0; i < CHILDREN_PER_NODE; ++i) {
			clear_node(&node->children[i]);
		}
	}
}

void clear_tree(QuadTreeRootNode *root)
{
	clear_node(root->node);

	int i;
	char *key;
	I32 retlen;
	SV *value;

	hv_iterinit(root->backref);
	while ((value = hv_iternextsv(root->backref, &key, &retlen)) != NULL) {
		destroy_shape((Shape*) SvIV(value));
	}

	hv_clear(root->backref);
}

void filter_geometry(HV* results, HV* shapes, Shape *s)
{
	HE *he;

	hv_iterinit(results);
	while ((he = hv_iternext(results)) != NULL) {
		STRLEN len;
		char *key = HePV(he, len);
		SV **fetched = hv_fetch(shapes, key, len, 0);
		Shape* s2 = (Shape*) SvIV(*fetched);

		if (!shapes_overlap(s, s2))
			hv_delete(results, key, len, 0);
	}
}

/* XS helpers */

SV* get_hash_key (HV* hash, const char* key, int len)
{
	SV **value = hv_fetch(hash, key, len, 0);

	if (value == NULL) return NULL;
	return *value;
}

QuadTreeRootNode* get_root_from_perl(SV *self)
{
	SV *value = get_hash_key((HV*) SvRV(self), "ROOT", 4);
	if (value == NULL)
		croak("quad tree root node is undefined");

	return (QuadTreeRootNode*) SvIV(value);
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

