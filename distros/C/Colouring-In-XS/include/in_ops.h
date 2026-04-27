/*
 * in_ops.h - Custom ops + peephole optimizer for Colouring::In::XS
 *
 * Replaces entersub calls with lightweight custom ops at compile time.
 * Requires in.h (which pulls in colouring.h) already included.
 */

#ifndef COLOURING_IN_OPS_H
#define COLOURING_IN_OPS_H

/* compat for pre-5.22 perls */
#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)  ((o)->op_sibling != NULL)
#endif
#ifndef OpSIBLING
#  define OpSIBLING(o)      ((o)->op_sibling)
#endif

/* Peek the invocant without disturbing the mark/stack. */
#define COLOURING_PEEK_INVOCANT() \
    ((PL_markstack_ptr > PL_markstack)                                        \
        && ((PL_stack_base + *PL_markstack_ptr + 1) <= PL_stack_sp)           \
        ? *(PL_stack_base + *PL_markstack_ptr + 1)                            \
        : NULL)

/* If the invocant isn't a Colouring::In::XS object (or subclass), fall
 * through to the original OP_ENTERSUB pp so unrelated callers behave. */
#define COLOURING_GUARD_INVOCANT() STMT_START {                                \
    SV * _self = COLOURING_PEEK_INVOCANT();                                    \
    if (!_self || !sv_isobject(_self)                                          \
        || !sv_derived_from(_self, COLOURING_CLASS)) {                         \
        return PL_ppaddr[OP_ENTERSUB](aTHX);                                   \
    }                                                                          \
} STMT_END

/* ── Format ops (self → string) ───────────────────────────────── */

static OP * pp_colouring_toHEX(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * self   = *(mark + 1);
	int force_long = 0;
	colouring_rgba_t c;
	char css[8];

	if (items > 2) {
		SV * fl = *(mark + 2);
		force_long = SvTRUE(fl);
	}

	SP = mark;
	c = xs_extract_rgba(self);
	colouring_fmt_hex(c, css, sizeof(css), force_long);
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toRGB(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	SV * alpha_sv;

	SP = mark;
	c = xs_extract_rgba(self);
	alpha_sv = *hv_fetch((HV*)SvRV(self), "alpha", 5, 0);
	if (numIs(alpha_sv) && SvIV(alpha_sv) != 1) {
		char css[32];
		colouring_fmt_rgba(c, css, sizeof(css));
		PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	} else {
		char css[24];
		colouring_fmt_rgb(c, css, sizeof(css));
		PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	}
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toRGBA(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	char css[32];

	SP = mark;
	c = xs_extract_rgba(self);
	colouring_fmt_rgba(c, css, sizeof(css));
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toHSL(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	colouring_hsl_t hsl;
	char css[30];

	SP = mark;
	c = xs_extract_rgba(self);
	hsl = colouring_rgb2hsl(c.r, c.g, c.b, c.a);
	colouring_fmt_hsl(hsl, css, sizeof(css));
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toHSV(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	colouring_hsv_t hsv;
	char css[30];

	SP = mark;
	c = xs_extract_rgba(self);
	hsv = colouring_rgb2hsv(c.r, c.g, c.b);
	colouring_fmt_hsv(hsv, css, sizeof(css));
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toCSS(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;

	SP = mark;
	c = xs_extract_rgba(self);
	if (c.a == 1.0) {
		char css[8];
		colouring_fmt_hex(c, css, sizeof(css), 0);
		PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	} else {
		char css[32];
		colouring_fmt_rgba(c, css, sizeof(css));
		PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	}
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toTerm(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	char css[16];

	SP = mark;
	c = xs_extract_rgba(self);
	colouring_fmt_term(c, css, sizeof(css));
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_toOnTerm(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	colouring_rgba_t c;
	char css[20];

	SP = mark;
	c = xs_extract_rgba(self);
	colouring_fmt_on_term(c, css, sizeof(css));
	PUSHs(sv_2mortal(newSVpvn(css, strlen(css))));
	PUTBACK;
	return NORMAL;
}

/* ── Manipulation ops (self, amount → new object) ─────────────── */

static OP * pp_colouring_lighten(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_lighten(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_darken(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_darken(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_fade(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	colouring_rgba_t c;

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_fade(c.r, c.g, c.b, c.a, amount);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_fadeout(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_fadeout(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_fadein(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_fadein(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_saturate(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_saturate(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_desaturate(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * amt_sv = *(mark + 2);
	SV * class  = xs_class_sv();
	double amount;
	int relative = 0;
	colouring_rgba_t c;

	if (items > 3) {
		SV * rel = *(mark + 3);
		if (SvOK(rel) && strEQ(SvPV_nolen(rel), "relative")) relative = 1;
	}

	SP = mark;
	amount = colouring_depercent(SvPV_nolen(amt_sv));
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_desaturate(c.r, c.g, c.b, c.a, amount, relative);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_greyscale(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * colour = *(mark + 1);
	SV * class  = xs_class_sv();
	colouring_rgba_t c;

	SP = mark;
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	c = colouring_greyscale(c.r, c.g, c.b, c.a);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, c)));
	PUTBACK;
	return NORMAL;
}

/* ── Mix-family ops (self, colour2[, weight] → new object) ────── */

static OP * pp_colouring_mix(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax       = POPMARK;
	SV **mark    = PL_stack_base + ax;
	I32 items    = (I32)(SP - mark);
	SV * colour1 = *(mark + 1);
	SV * colour2 = *(mark + 2);
	SV * class   = xs_class_sv();
	int weight   = 50;
	colouring_rgba_t c1, c2, out;

	if (items > 3) {
		SV * w = *(mark + 3);
		if (SvOK(w) && SvIV(w) != 0) weight = SvIV(w);
	}

	SP = mark;
	colour1 = xs_ensure_obj(class, colour1);
	colour2 = xs_ensure_obj(class, colour2);
	c1 = xs_extract_rgba(colour1);
	c2 = xs_extract_rgba(colour2);
	out = colouring_mix(c1, c2, weight);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, out)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_tint(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * class  = xs_class_sv();
	int weight  = 50;
	colouring_rgba_t c, out;

	if (items > 2) {
		SV * w = *(mark + 2);
		if (SvOK(w) && SvIV(w) != 0) weight = SvIV(w);
	}

	SP = mark;
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	out = colouring_tint(c, weight);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, out)));
	PUTBACK;
	return NORMAL;
}

static OP * pp_colouring_shade(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	I32 items   = (I32)(SP - mark);
	SV * colour = *(mark + 1);
	SV * class  = xs_class_sv();
	int weight  = 50;
	colouring_rgba_t c, out;

	if (items > 2) {
		SV * w = *(mark + 2);
		if (SvOK(w) && SvIV(w) != 0) weight = SvIV(w);
	}

	SP = mark;
	colour = xs_ensure_obj(class, colour);
	c = xs_extract_rgba(colour);
	out = colouring_shade(c, weight);
	PUSHs(sv_2mortal(xs_rgba_to_obj(class, out)));
	PUTBACK;
	return NORMAL;
}

/* ── Accessor op ──────────────────────────────────────────────── */

static OP * pp_colouring_colour(pTHX) {
	dSP;
	COLOURING_GUARD_INVOCANT();
	I32 ax      = POPMARK;
	SV **mark   = PL_stack_base + ax;
	SV * self   = *(mark + 1);
	AV * colour = (AV*)SvRV(*hv_fetch((HV*)SvRV(self), "colour", 6, 0));
	int len     = av_len(colour);
	int i;

	SP = mark;
	EXTEND(SP, len + 1);
	for (i = 0; i <= len; i++) {
		PUSHs(sv_2mortal(newSVsv(*av_fetch(colour, i, 0))));
	}
	PUTBACK;
	return NORMAL;
}

/* ══════════════════════════════════════════════════════════════════
 *  XOP descriptors (Perl 5.14+)
 * ══════════════════════════════════════════════════════════════════ */

#if PERL_VERSION >= 14

static XOP xop_toHEX;
static XOP xop_toRGB;
static XOP xop_toRGBA;
static XOP xop_toHSL;
static XOP xop_toHSV;
static XOP xop_toCSS;
static XOP xop_toTerm;
static XOP xop_toOnTerm;
static XOP xop_lighten;
static XOP xop_darken;
static XOP xop_fade;
static XOP xop_fadeout;
static XOP xop_fadein;
static XOP xop_saturate;
static XOP xop_desaturate;
static XOP xop_greyscale;
static XOP xop_mix;
static XOP xop_tint;
static XOP xop_shade;
static XOP xop_colour;

#endif /* PERL_VERSION >= 14 */

/* ══════════════════════════════════════════════════════════════════
 *  Op dispatch table — maps method name → pp function
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	const char *name;
	Perl_ppaddr_t pp;
} colouring_op_entry_t;

static colouring_op_entry_t colouring_op_table[] = {
	{ "toHEX",       pp_colouring_toHEX       },
	{ "toRGB",       pp_colouring_toRGB       },
	{ "toRGBA",      pp_colouring_toRGBA      },
	{ "toHSL",       pp_colouring_toHSL       },
	{ "toHSV",       pp_colouring_toHSV       },
	{ "toCSS",       pp_colouring_toCSS       },
	{ "toTerm",      pp_colouring_toTerm      },
	{ "toOnTerm",    pp_colouring_toOnTerm    },
	{ "lighten",     pp_colouring_lighten     },
	{ "darken",      pp_colouring_darken      },
	{ "fade",        pp_colouring_fade        },
	{ "fadeout",     pp_colouring_fadeout      },
	{ "fadein",      pp_colouring_fadein       },
	{ "saturate",    pp_colouring_saturate     },
	{ "desaturate",  pp_colouring_desaturate   },
	{ "greyscale",   pp_colouring_greyscale    },
	{ "mix",         pp_colouring_mix          },
	{ "tint",        pp_colouring_tint         },
	{ "shade",       pp_colouring_shade        },
	{ "colour",      pp_colouring_colour       },
	{ NULL, NULL }
};

#define COLOURING_OP_COUNT 20

/* ══════════════════════════════════════════════════════════════════
 *  Peephole optimizer — replace entersub with custom ops
 * ══════════════════════════════════════════════════════════════════ */

static peep_t colouring_prev_peep = NULL;

/* Walk an optree looking for entersub ops that call our methods,
 * and replace them with the corresponding custom op. */
static void colouring_peep(pTHX_ OP *o) {
	OP *orig = o;

	/* chain to any previous peep first */
	if (colouring_prev_peep)
		colouring_prev_peep(aTHX_ o);

	for (; o; o = o->op_next) {
		OP *cv_op, *method_op, *first;
		const char *methname;
		STRLEN methlen;
		int i;

		if (o->op_type != OP_ENTERSUB)
			continue;
		if (!(o->op_flags & OPf_STACKED))
			continue;

		/* Find the last child of entersub — should be the method op */
		first = cUNOPo->op_first;
		if (!first)
			continue;

		/* Walk to last sibling */
		cv_op = first;
		while (OpHAS_SIBLING(cv_op))
			cv_op = OpSIBLING(cv_op);

		/* We want OP_METHOD_NAMED */
		if (cv_op->op_type != OP_METHOD_NAMED)
			continue;

		/* Get the method name */
#if PERL_VERSION >= 22
		methname = SvPV_const(cMETHOPx_meth(cv_op), methlen);
#else
		methname = SvPV_const(cSVOPx(cv_op)->op_sv, methlen);
#endif

		/* Look up in our dispatch table */
		for (i = 0; i < COLOURING_OP_COUNT; i++) {
			if (strEQ(methname, colouring_op_table[i].name)) {
				/* Replace the entersub with our custom op */
				o->op_ppaddr = colouring_op_table[i].pp;
				break;
			}
		}
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Registration — call from BOOT
 * ══════════════════════════════════════════════════════════════════ */

#define COLOURING_REGISTER_XOP(xop_var, name_str, pp_fn) \
	XopENTRY_set(&xop_var, xop_name, name_str);      \
	XopENTRY_set(&xop_var, xop_desc, "colouring " name_str); \
	XopENTRY_set(&xop_var, xop_class, OA_UNOP);      \
	Perl_custom_op_register(aTHX_ pp_fn, &xop_var)

static void colouring_register_ops(pTHX) {
#if PERL_VERSION >= 14
	COLOURING_REGISTER_XOP(xop_toHEX,      "toHEX",      pp_colouring_toHEX);
	COLOURING_REGISTER_XOP(xop_toRGB,      "toRGB",      pp_colouring_toRGB);
	COLOURING_REGISTER_XOP(xop_toRGBA,     "toRGBA",     pp_colouring_toRGBA);
	COLOURING_REGISTER_XOP(xop_toHSL,      "toHSL",      pp_colouring_toHSL);
	COLOURING_REGISTER_XOP(xop_toHSV,      "toHSV",      pp_colouring_toHSV);
	COLOURING_REGISTER_XOP(xop_toCSS,      "toCSS",      pp_colouring_toCSS);
	COLOURING_REGISTER_XOP(xop_toTerm,     "toTerm",     pp_colouring_toTerm);
	COLOURING_REGISTER_XOP(xop_toOnTerm,   "toOnTerm",   pp_colouring_toOnTerm);
	COLOURING_REGISTER_XOP(xop_lighten,    "lighten",    pp_colouring_lighten);
	COLOURING_REGISTER_XOP(xop_darken,     "darken",     pp_colouring_darken);
	COLOURING_REGISTER_XOP(xop_fade,       "fade",       pp_colouring_fade);
	COLOURING_REGISTER_XOP(xop_fadeout,    "fadeout",    pp_colouring_fadeout);
	COLOURING_REGISTER_XOP(xop_fadein,     "fadein",     pp_colouring_fadein);
	COLOURING_REGISTER_XOP(xop_saturate,   "saturate",   pp_colouring_saturate);
	COLOURING_REGISTER_XOP(xop_desaturate, "desaturate", pp_colouring_desaturate);
	COLOURING_REGISTER_XOP(xop_greyscale,  "greyscale",  pp_colouring_greyscale);
	COLOURING_REGISTER_XOP(xop_mix,        "mix",        pp_colouring_mix);
	COLOURING_REGISTER_XOP(xop_tint,       "tint",       pp_colouring_tint);
	COLOURING_REGISTER_XOP(xop_shade,      "shade",      pp_colouring_shade);
	COLOURING_REGISTER_XOP(xop_colour,     "colour",     pp_colouring_colour);
#endif

	/* Install peephole optimizer */
	colouring_prev_peep = PL_peepp;
	PL_peepp = colouring_peep;
}

#endif /* COLOURING_IN_OPS_H */
