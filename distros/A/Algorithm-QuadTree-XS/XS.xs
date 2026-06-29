#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "qtbase.h"

MODULE = Algorithm::QuadTree::XS		PACKAGE = Algorithm::QuadTree::XS

PROTOTYPES: DISABLE

void
_AQT_init(self)
		SV *self
	CODE:
		QuadTreeRootNode *root = create_root();

		HV *params = (HV*) SvRV(self);

		node_add_level(root->node,
			SvNV(get_hash_key(params, "XMIN", 4)),
			SvNV(get_hash_key(params, "YMIN", 4)),
			SvNV(get_hash_key(params, "XMAX", 4)),
			SvNV(get_hash_key(params, "YMAX", 4)),
			SvIV(get_hash_key(params, "DEPTH", 5))
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

		Shape *param = create_shape();
		if (items > 5) {
			prepare_rectangle(param, x, y, x2_or_radius, SvNV(ST(5)));
		}
		else {
			prepare_circle(param, x, y, x2_or_radius);
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

		HV *params = (HV*) SvRV(self);
		SV *geometry_checks = get_hash_key(params, "CHECK", 5);
		HV *ret_hash = newHV();

		Shape param;
		if (items > 4) {
			prepare_rectangle(&param, x, y, x2_or_radius, SvNV(ST(4)));
		}
		else {
			prepare_circle(&param, x, y, x2_or_radius);
		}

		find_nodes(root->node, ret_hash, &param, false);
		if (geometry_checks != NULL && SvIV(geometry_checks) != 0)
			filter_geometry(ret_hash, root->backref, &param);

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
			delete_nodes(root->node, object, s, false);
			destroy_shape(s);
			disown_object(root, object);
		}

void
_AQT_clear(self)
		SV* self
	CODE:
		QuadTreeRootNode *root = get_root_from_perl(self);
		clear_tree(root);

