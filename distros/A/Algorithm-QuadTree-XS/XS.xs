#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "qtbase.h"

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

		SV *root_sv = newSViv((uintptr_t) root);
		SvREADONLY_on(root_sv);
		hv_stores(params, "ROOT", root_sv);

void
_AQT_deinit(self)
		SV *self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		clear_tree(root);
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

		if (fill_nodes(root, root->node, object, &param)) {
			push_array_SV(root->objects, object);
		}

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
						push_array(new_list, fetched);
					}
				}

				destroy_array(node->values);
				node->values = new_list;
				if (new_list->count == 0) clear_has_objects(node);
			}

			destroy_array(list);
			hv_delete_ent(root->backref, object, 0, 0);

			DynArr* new_list = create_array();
			for(j = 0; j < root->objects->count; ++j) {
				SV *fetched = (SV*) root->objects->ptr[j];
				if (!sv_eq(fetched, object)) {
					push_array(new_list, fetched);
				}
				else {
					SvREFCNT_dec(fetched);
				}
			}

			destroy_array(root->objects);
			root->objects = new_list;
		}

void
_AQT_clear(self)
		SV* self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);
		clear_tree(root);

MODULE = Algorithm::QuadTree::XS		PACKAGE = Algorithm::QuadTree::XS::NoBackRefs		PREFIX = nbr

PROTOTYPES: DISABLE

void
nbr_AQT_init(obj)
		SV *obj
	CODE:
		QuadTreeRootNode *root = create_root_nobackref();

		HV *params = (HV*) SvRV(obj);

		node_add_level(root->node,
			SvNV(get_hash_key(params, "XMIN")),
			SvNV(get_hash_key(params, "YMIN")),
			SvNV(get_hash_key(params, "XMAX")),
			SvNV(get_hash_key(params, "YMAX")),
			SvIV(get_hash_key(params, "DEPTH"))
		);

		SV *root_sv = newSViv((uintptr_t) root);
		SvREADONLY_on(root_sv);
		hv_stores(params, "ROOT", root_sv);

void
nbr_AQT_deinit(self)
		SV *self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		clear_tree(root);
		destroy_node(root->node);
		free(root->node);

		free(root);


void
nbr_AQT_addObject(self, object, x, y, x2_or_radius, ...)
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

		if (fill_nodes_nobackref(root->node, object, &param)) {
			push_array_SV(root->objects, object);
		}

SV*
nbr_AQT_findObjects(self, x, y, x2_or_radius, ...)
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
nbr_AQT_clear(self)
		SV* self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);
		clear_tree(root);

