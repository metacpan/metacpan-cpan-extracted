#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "salad/rtree.h"
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#define XS_KEY			"_xs"
#define OPTS_KEY		"constructor.ro.opts"

const uint32_t extent_size = 1024 * 8;

struct rtree_w_ecount {
	int count;
	struct rtree tree[1];
};


static void *
extent_alloc(void *ctx)
{
	void *mem = malloc(extent_size);
	if (!mem)
		croak("Can not allocate %d bytes for R extent", extent_size);
	int *p_extent_count = (int *)ctx;
	++*p_extent_count;
	return mem;
}

static void
extent_free(void *ctx, void *page)
{
	int *p_extent_count = (int *)ctx;
	--*p_extent_count;
	free(page);
}


inline static struct rtree_w_ecount *
self_fetch_tree(pTHX_ SV *self)
{
	self = SvRV(self);
	SV **stree = hv_fetchs((HV *)self, XS_KEY, 0);
	if (*stree)
		return (struct rtree_w_ecount *)SvIV(*stree);
	return NULL;
}

inline static void
_fill_rect(pTHX_ struct rtree *t, struct rtree_rect *r, SV * pref)
{
	if (!(SvROK(pref) && SvTYPE(pref) | SVt_PVAV)) {
		croak("$point or $rect must be an ArrayRef[x0[,x1],y0[,y1]...] object");
	}

	AV *p = (AV *)SvRV(pref);

	if (av_len(p) + 1 == t->dimension) { /* point */
		for (unsigned i = 0; i < t->dimension; i++) {
			SV **item = av_fetch(p, i, 0);

			if (!(item && looks_like_number(*item))) {
				croak("'%s' is not a number (check point[%d])",
					 *item,
					 i
				);
			}
			r->coords[i * 2 + 0] = r->coords[i * 2 + 1] = SvNV(*item);
		}

	} else if (av_len(p) + 1 == t->dimension * 2) { /* box */
		unsigned no = 0;

		for (unsigned i = 0; i < t->dimension; i++) {

			SV **item = av_fetch(p, no, 0);


			if (!(item && looks_like_number(*item)))
				croak("'%s' is not a number (check rect[%d])",
					 *item,
					 no
				);
			r->coords[i * 2] = SvNV(*item);
			no++;
		}

		for (unsigned i = 0; i < t->dimension; i++) {

			SV **item = av_fetch(p, no, 0);


			if (!(item && looks_like_number(*item)))
				croak("'%s' is not a number (check rect[%d])",
					 *item,
					 no
				);
			r->coords[i * 2 + 1] = SvNV(*item);
			no++;
		}
		rtree_rect_normalize(r, t->dimension);
	} else {
		croak(
			"I can't understand if the array is point "
			"or rect (asize=%d, must be %d or %d)",
			av_len(p) + 1,
			t->dimension,
			t->dimension * 2
		);
	}

	/*
	printf("[%5.2f %5.2f %5.2f %5.2f] - %d\n",
		r->coords[0],
		r->coords[1],
		r->coords[2],
		r->coords[3],
		av_len(p) + 1);
	*/
}

MODULE = DR::R		PACKAGE = DR::R
PROTOTYPES: DISABLE
SV * new(SV *class, ...)
	CODE:
		HV * opts = (HV *)sv_2mortal((SV *)newHV());
		const char *classname;

		if (sv_isobject(class)) {
			classname = sv_reftype(SvRV(class), 1);
			SV **popts = hv_fetchs((HV *)SvRV(class), OPTS_KEY, 0);
			if (popts) {
				hv_iterinit((HV *)SvRV(*popts));
				for (;;) {
					HE *iter = hv_iternext((HV *)SvRV(*popts));
					if (!iter)
						break;
					SV *k = hv_iterkeysv(iter);
					SV *v = HeVAL(iter);
					hv_store_ent(opts, k, newSVsv(v), 0);
				}
			}
		} else {
			classname = SvPV_nolen(class);
		}

		HV *self = newHV();
		SV *bself = newRV_noinc((SV *)self);
		sv_bless(bself, gv_stashpv(classname, TRUE));
		for (unsigned i = 1; i < items; i += 2) {
			if (i < items - 1) {
				hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
			} else {
				hv_store_ent(opts, ST(i), newSV(0), 0);
			}
		}
		hv_stores(self, OPTS_KEY, newRV((SV *)opts));

		int d = 2;
		SV ** ds = hv_fetchs(opts, "dimension", 0);
		if (ds) {
			d = SvIV(*ds);

			if (d > RTREE_MAX_DIMENSION) {
				croak("Too high dimension value: %d (max %d)",
					d,
					RTREE_MAX_DIMENSION);
			} else if (d < 1) {
				croak("Too low dimension value: %d (min 1)", d);
			}
		}
		hv_stores(opts, "dimension", newSViv(d));

		unsigned dist_type = RTREE_EUCLID;
		SV ** dt = hv_fetchs(opts, "dist_type", 0);
		if (dt) {
			STRLEN len;
			const char *p = SvPV(*dt, len);
			if (strncmp(p, "EUCLID", len) == 0) {
				dist_type = RTREE_EUCLID;
			} else if (strncmp(p, "MANHATTAN", len) == 0) {
				dist_type = RTREE_MANHATTAN;
			} else {
				croak("dist_type can be in ('EUCLID', 'MANHATTAN')");
			}
		} else {
			hv_stores(opts, "dist_type", newSVpvs("EUCLID"));
		}


		struct rtree_w_ecount *t = malloc(sizeof(struct rtree_w_ecount));
		t->count = 0;
		rtree_init(t->tree,
			d,
			extent_size,
			extent_alloc,
			extent_free,
			&t->count,
			dist_type
		);
		hv_stores(self, XS_KEY, newSViv((IV)t));
		RETVAL = bself;
	OUTPUT:
		RETVAL

void DESTROY(SV *self)
	CODE:
		/* warn("DESTRUCTOR"); */
		struct rtree_w_ecount *t = self_fetch_tree(aTHX_ self);
		if (t) {

			struct rtree_rect rect;
			struct rtree_iterator iterator;

			rtree_iterator_init(&iterator);
			memset(&rect, 0, sizeof(rect));

			if (rtree_search(t->tree, &rect, SOP_ALL, &iterator)) {
				for (SV *item = rtree_iterator_next(&iterator);
					item;
					item = rtree_iterator_next(&iterator)) {

					SvREFCNT_dec(item);
				}
			}

			rtree_iterator_destroy(&iterator);
			rtree_destroy(t->tree);
			free(t);

			self = SvRV(self);
			hv_delete((HV *)self, XS_KEY, sizeof(XS_KEY), 0);
		}

SV * insert(SV *self, SV *point, SV *object)
	CODE:
		if (!SvOK(object))
			croak("inserted object must be defined");

		struct rtree_w_ecount *t = self_fetch_tree(aTHX_ self);
		if (!t)
			croak("Object has already been destroyed");

		struct rtree_rect rect;
		_fill_rect(aTHX_ t->tree, &rect, point);


		SV *item = newSVsv(object);
		rtree_insert(t->tree, &rect, item);

		RETVAL = newSViv((IV)item);
	OUTPUT:
		RETVAL



SV * dimension(SV *self)
	CODE:
		struct rtree_w_ecount *tree = self_fetch_tree(aTHX_ self);
		if (tree)
			RETVAL = newSViv(tree->tree->dimension);
		else
			RETVAL = newSV(0);
	OUTPUT:
		RETVAL

SV * remove(SV *self, SV *point, SV *id)
	CODE:
		struct rtree_w_ecount *t = self_fetch_tree(aTHX_ self);
		if (!t)
			croak("Object has already been destroyed");

		struct rtree_rect rect;
		_fill_rect(aTHX_ t->tree, &rect, point);

		if (!SvOK(id))
			croak("Usage: $r->remove($point, $id)");

		IV oid = SvIV(id);

		if (rtree_remove(t->tree, &rect, (void *)oid)) {
			SV *item = (SV *)oid;
			RETVAL = item;
		} else {
			RETVAL = newSV(0);
		}
	OUTPUT:
		RETVAL

SV * foreach(SV *self, SV *type, SV *point, SV *cb)
	CODE:
		struct rtree_w_ecount *t = self_fetch_tree(aTHX_ self);
		if (!t)
			croak("Object has already been destroyed");
		int op = SOP_ALL;
		STRLEN tlen;
		const char *stype;

		struct rtree_iterator iterator;
		rtree_iterator_init(&iterator);

		struct rtree_rect rect;
		_fill_rect(aTHX_ t->tree, &rect, point);

		if (SvOK(type)) {
			stype = SvPV(type, tlen);
			if (strncmp(stype, "EQ", tlen) == 0) {
				op = SOP_EQUALS;
			} else if (strncmp(stype, "NEIGHBOR", tlen) == 0) {
				op = SOP_NEIGHBOR;
			} else if (strncmp(stype, "CONTAINS", tlen) == 0) {
				op = SOP_CONTAINS;
			} else if (strncmp(stype, "CONTAINS!", tlen) == 0) {
				op = SOP_STRICT_CONTAINS;
			} else if (strncmp(stype, "OVERLAPS", tlen) == 0) {
				op = SOP_OVERLAPS;
			} else if (strncmp(stype, "BELONGS", tlen) == 0) {
				op = SOP_BELONGS;
			} else if (strncmp(stype, "BELONGS!", tlen) == 0) {
				op = SOP_STRICT_BELONGS;
			} else if (strncmp(stype, "ALL", tlen) == 0) {
				op = SOP_ALL;
			} else {
				croak("Unknown iterator type: '%.*s'",
					tlen, stype);
			}
		}

		if (!(SvROK(cb) && SvTYPE(cb) | SVt_PVCV)) {
			croak("Usage: $t->foreach($type, $rect, sub { ... })");
		}

		int no = 0;
		if (rtree_search(t->tree, &rect, op, &iterator)) {
			SV *item;
			int count;
			int cont = 1;
			while(cont) {
				item = rtree_iterator_next(&iterator);
				if (!item)
					break;

				dSP;
				ENTER;
				SAVETMPS;

				PUSHMARK(SP);
				EXTEND(SP, 3);
				PUSHs(item);
				PUSHs(sv_2mortal(newSViv((IV)item)));
				PUSHs(sv_2mortal(newSViv(no)));
				no++;
				PUTBACK;

				count = call_sv(cb, G_ARRAY);
				SPAGAIN;

				switch(count) {
					case 0:
						cont = 1;
						break;
					case 1:
						cont = sv_2bool(POPs);
						break;
					default:
						cont = 1;
						break;
				}



				PUTBACK;
				FREETMPS;
				LEAVE;
			}
		}
		rtree_iterator_destroy(&iterator);
		RETVAL = newSVsv(self);
	OUTPUT:
		RETVAL


SV * _ping()
	CODE:
		SV *rv = newSVpvs("pong");
		RETVAL = rv;
	OUTPUT:
		RETVAL

