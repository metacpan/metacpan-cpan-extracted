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
		destroy_array(root->objects);
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

		Shape *param = create_shape();
		param->x = x;
		param->y = y;
		if (items > 5) {
			param->type = shape_rectangle;
			param->x2 = x2_or_radius;
			param->y2 = SvNV(ST(5));
		}
		else {
			param->type = shape_circle;
			param->radius_sq = x2_or_radius * x2_or_radius;
		}

		if (fill_nodes(root->node, object, param)) {
			adopt_object(root, object, param);
		}
		else {
			destroy_shape(param);
		}

SV*
_AQT_findObjects(self, x, y, x2_or_radius, ...)
		SV *self
		double x
		double y
		double x2_or_radius
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);

		HV *ret_hash = newHV();

		Shape param;
		param.x = x;
		param.y = y;
		if (items > 4) {
			param.type = shape_rectangle;
			param.x2 = x2_or_radius;
			param.y2 = SvNV(ST(4));
		}
		else {
			param.type = shape_circle;
			param.radius_sq = x2_or_radius * x2_or_radius;
		}

		find_nodes(root->node, ret_hash, &param);
		AV *ret = get_hash_values(ret_hash);

		SvREFCNT_dec((SV*) ret_hash);
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
			Shape* s = (Shape*) SvIV(HeVAL(hv_fetch_ent(root->backref, object, 0, 0)));
			delete_nodes(root->node, object, s);
			destroy_shape(s);
			disown_object(root, object);
		}

void
_AQT_clear(self)
		SV* self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);
		clear_tree(root);

