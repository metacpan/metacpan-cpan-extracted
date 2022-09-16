#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if !PERL_VERSION_GE(5,9,3)
# define SVt_LAST (SVt_PVIO+1)
#endif /* <5.9.3 */

#if PERL_VERSION_GE(5,9,4)
# define SVt_PADNAME SVt_PVMG
#else /* <5.9.4 */
# define SVt_PADNAME SVt_PVGV
#endif /* <5.9.4 */

#ifndef sv_setpvs
# define sv_setpvs(SV, STR) sv_setpvn(SV, ""STR"", sizeof(STR)-1)
#endif /* !sv_setpvs */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#ifndef SvPAD_OUR_on
# define SvPAD_OUR_on(SV) (SvFLAGS(SV) |= SVpad_OUR)
#endif /* !SvPAD_OUR_on */

#ifndef SvOURSTASH_set
# ifdef OURSTASH_set
#  define SvOURSTASH_set(SV, STASH) OURSTASH_set(SV, STASH)
# else /* !OURSTASH_set */
#  define SvOURSTASH_set(SV, STASH) (GvSTASH(SV) = STASH)
# endif /* !OURSTASH_set */
#endif /* !SvOURSTASH_set */

#ifndef PadMAX
# define PadlistARRAY(pl) ((PAD**)AvARRAY(pl))
# define PadlistNAMES(pl) (PadlistARRAY(pl)[0])
# define PadMAX(p) AvFILLp(p)
typedef AV PADNAMELIST;
#endif /* !PadMAX */

#if !PERL_VERSION_GE(5,8,1)
typedef AV PADLIST;
typedef AV PAD;
#endif /* <5.8.1 */

#ifndef COP_SEQ_RANGE_LOW
# if PERL_VERSION_GE(5,9,5)
#  define COP_SEQ_RANGE_LOW(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow
#  define COP_SEQ_RANGE_HIGH(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh
# else /* <5.9.5 */
#  define COP_SEQ_RANGE_LOW(sv) ((U32)SvNVX(sv))
#  define COP_SEQ_RANGE_HIGH(sv) ((U32)SvIVX(sv))
# endif /* <5.9.5 */
#endif /* !COP_SEQ_RANGE_LOW */

#ifndef COP_SEQ_RANGE_LOW_set
# ifdef newPADNAMEpvn
#  define COP_SEQ_RANGE_LOW_set(sv,val) \
	do { (sv)->xpadn_low = (val); } while(0)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) \
	do { (sv)->xpadn_high = (val); } while(0)
# elif PERL_VERSION_GE(5,9,5)
#  define COP_SEQ_RANGE_LOW_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = val; } while(0)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = val; } while(0)
# else /* <5.9.5 */
#  define COP_SEQ_RANGE_LOW_set(sv,val) SvNV_set(sv, val)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) SvIV_set(sv, val)
# endif /* <5.9.5 */
#endif /* !COP_SEQ_RANGE_LOW_set */

#ifndef SvRV_set
# define SvRV_set(SV, VAL) (SvRV(SV) = (VAL))
#endif /* !SvRV_set */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

#ifndef SVfARG
# define SVfARG(p) ((void *)p)
#endif /* !SVfARG */

#ifndef GV_NOTQUAL
# define GV_NOTQUAL 0
#endif /* !GV_NOTQUAL */

#ifndef padnamelist_store
 /* Note that the return values are different.  If we ever call it in non-
    void context, we would have to change it to *av_store.  */
# define padnamelist_store av_store
#endif

/*
 * scalar classification
 *
 * Logic borrowed from Params::Classify.
 */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

/*
 * gen_const_identity_op()
 *
 * This function generate op that evaluates to a fixed object identity
 * and can also participate in constant folding.
 *
 * Lexical::Var generally needs to make ops that evaluate to fixed
 * identities, that being what a name that it handles represents.
 * Normally it can do this by means of an rv2xv op applied to a const op,
 * where the const op holds an RV that references the object of interest.
 * However, rv2xv can't undergo constant folding.  Where the object is
 * a readonly scalar, we'd like it to take part in constant folding.
 * The obvious way to make it work as a constant for folding is to use a
 * const op that directly holds the object.  However, in a Perl built for
 * ithreads, the value in a const op gets moved into the pad to achieve
 * clonability, and in the process the value may be copied rather than the
 * object merely rereferenced.  Generally, the const op only guarantees
 * to provide a fixed *value*, not a fixed object identity.
 *
 * Where a const op might not preserve object identity, we can achieve
 * preservation by means of a customised variant of the const op.  The op
 * directly holds an RV that references the object of interest, and its
 * variant pp function dereferences it (as rv2sv would).  The pad logic
 * operates on the op structure as normal, and may copy the RV without
 * preserving its identity, which is OK because the RV isn't what we
 * need to preserve.  Being labelled as a const op, it is eligible for
 * constant folding.  When actually executed, it evaluates to the object
 * of interest, providing both fixed value and fixed identity.
 */

#ifdef USE_ITHREADS
# define Q_USE_ITHREADS 1
#else /* !USE_ITHREADS */
# define Q_USE_ITHREADS 0
#endif /* !USE_ITHREADS */

#define Q_CONST_COPIES Q_USE_ITHREADS

#if Q_CONST_COPIES
static OP *pp_const_via_ref(pTHX)
{
	dSP;
	SV *reference_sv = cSVOPx_sv(PL_op);
	SV *referent_sv = SvRV(reference_sv);
	PUSHs(referent_sv);
	RETURN;
}
#endif /* Q_CONST_COPIES */

#define gen_const_identity_op(sv) THX_gen_const_identity_op(aTHX_ sv)
static OP *THX_gen_const_identity_op(pTHX_ SV *sv)
{
#if Q_CONST_COPIES
	OP *op = newSVOP(OP_CONST, 0, newRV_noinc(sv));
	op->op_ppaddr = pp_const_via_ref;
	return op;
#else /* !Q_CONST_COPIES */
	return newSVOP(OP_CONST, 0, sv);
#endif /* !Q_CONST_COPIES */
}

/*
 * %^H key names
 */

#define KEYPREFIX "Lexical::Var/"
#define KEYPREFIXLEN (sizeof(KEYPREFIX)-1)

#define LEXPADPREFIX "Lexical::Var::<LEX>"
#define LEXPADPREFIXLEN (sizeof(LEXPADPREFIX)-1)

#define CHAR_IDSTART 0x01
#define CHAR_IDCONT  0x02
#define CHAR_SIGIL   0x10
#define CHAR_USEPAD  0x20

static U8 char_attr[256] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* NUL to BEL */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* BS to SI */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* DLE to ETB */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* CAN to US */
	0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x10, 0x00, /* SP to ' */
	0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, /* ( to / */
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, /* 0 to 7 */
	0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 8 to ? */
	0x30, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* @ to G */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* H to O */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* P to W */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x03, /* X to _ */
	0x00, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* ` to g */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* h to o */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* p to w */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, /* x to DEL */
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
};

#define name_key(sigil, name) THX_name_key(aTHX_ sigil, name)
static SV *THX_name_key(pTHX_ char sigil, SV *name)
{
	char const *p, *q, *end;
	STRLEN len;
	SV *key;
	p = SvPV(name, len);
	end = p + len;
	if(sigil == 'N') {
		sigil = *p++;
		if(!(char_attr[(U8)sigil] & CHAR_SIGIL)) return NULL;
	} else if(sigil == 'P') {
		if(strnNE(p, LEXPADPREFIX, LEXPADPREFIXLEN)) return NULL;
		p += LEXPADPREFIXLEN;
		sigil = *p++;
		if(!(char_attr[(U8)sigil] & CHAR_SIGIL)) return NULL;
		if(p[0] != ':' || p[1] != ':') return NULL;
		p += 2;
	}
	if(!(char_attr[(U8)*p] & CHAR_IDSTART)) return NULL;
	for(q = p+1; q != end; q++) {
		if(!(char_attr[(U8)*q] & CHAR_IDCONT)) return NULL;
	}
	key = sv_2mortal(newSV(KEYPREFIXLEN + 1 + (end-p)));
	sv_setpvs(key, KEYPREFIX"?");
	SvPVX(key)[KEYPREFIXLEN] = sigil;
	sv_catpvn(key, p, end-p);
	return key;
}

/*
 * compiling code that uses lexical variables
 */

#define gv_mark_multi(name) THX_gv_mark_multi(aTHX_ name)
static void THX_gv_mark_multi(pTHX_ SV *name)
{
	GV *gv;
#ifdef gv_fetchsv
	gv = gv_fetchsv(name, GV_NOADD_NOINIT|GV_NOEXPAND|GV_NOTQUAL,
			SVt_PVGV);
#else /* !gv_fetchsv */
	gv = gv_fetchpv(SvPVX(name), 0, SVt_PVGV);
#endif /* !gv_fetchsv */
	if(gv && SvTYPE(gv) == SVt_PVGV) GvMULTI_on(gv);
}

static SV *fake_sv, *fake_av, *fake_hv;

#define ck_rv2xv(o, sigil, nxck) THX_ck_rv2xv(aTHX_ o, sigil, nxck)
static OP *THX_ck_rv2xv(pTHX_ OP *o, char sigil, OP *(*nxck)(pTHX_ OP *o))
{
	OP *c;
	SV *ref, *key;
	HE *he;
	if((o->op_flags & OPf_KIDS) && (c = cUNOPx(o)->op_first) &&
			c->op_type == OP_CONST &&
			(c->op_private & (OPpCONST_ENTERED|OPpCONST_BARE)) &&
			(ref = cSVOPx(c)->op_sv) && SvPOK(ref) &&
			(key = name_key(sigil, ref))) {
		if((he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0))) {
			SV *hintref, *referent, *fake_referent, *newref;
			OP *newop;
			U16 type, flags;
#if !PERL_VERSION_GE(5,11,2)
			if(sigil == '&' && (c->op_private & OPpCONST_BARE))
				croak("can't reference lexical subroutine "
					"without & sigil on this perl");
#endif /* <5.11.2 */
			if(sigil != 'P' || !PERL_VERSION_GE(5,8,0)) {
				/*
				 * A bogus symbol lookup has already been
				 * done (by the tokeniser) based on the name
				 * we're using, to support the package-based
				 * interpretation that we're about to
				 * replace.  This can cause bogus "used only
				 * once" warnings.  The best we can do here
				 * is to flag the symbol as multiply-used to
				 * suppress that warning, though this is at
				 * the risk of muffling an accurate warning.
				 */
				gv_mark_multi(ref);
			}
			/*
			 * The base checker for rv2Xv checks that the
			 * item being pointed to by the constant ref is of
			 * an appropriate type.  There are two problems with
			 * this check.  Firstly, it rejects GVs as a scalar
			 * target, whereas they are in fact valid.  (This
			 * is in RT as bug #69456 so may be fixed.)  Second,
			 * and more serious, sometimes a reference is being
			 * constructed through the wrong op type.  An array
			 * indexing expression "$foo[0]" gets constructed as
			 * an rv2sv op, because of the "$" sigil, and then
			 * gets munged later.  We have to detect the real
			 * intended type through the pad entry, which the
			 * tokeniser has worked out in advance, and then
			 * work through the wrong op.  So it's a bit cheeky
			 * for perl to complain about the wrong type here.
			 * We work around it by making the constant ref
			 * initially point to an innocuous item to pass the
			 * type check, then changing it to the real
			 * reference later.
			 */
			hintref = HeVAL(he);
			if(!SvROK(hintref))
				croak("non-reference hint for Lexical::Var");
			referent = SvREFCNT_inc(SvRV(hintref));
			type = o->op_type;
			flags = o->op_flags | (((U16)o->op_private) << 8);
			if(type == OP_RV2SV && sigil == 'P' &&
					SvPVX(ref)[LEXPADPREFIXLEN] == '$' &&
					SvREADONLY(referent)) {
				op_free(o);
				return gen_const_identity_op(referent);
			}
			switch(type) {
				case OP_RV2SV: fake_referent = fake_sv; break;
				case OP_RV2AV: fake_referent = fake_av; break;
				case OP_RV2HV: fake_referent = fake_hv; break;
				default: fake_referent = referent; break;
			}
			newref = newRV_noinc(fake_referent);
			if(referent != fake_referent) {
				SvREFCNT_inc(fake_referent);
				SvREFCNT_inc(newref);
			}
			newop = newUNOP(type, flags,
					newSVOP(OP_CONST, 0, newref));
			if(referent != fake_referent) {
				fake_referent = SvRV(newref);
				SvREADONLY_off(newref);
				SvRV_set(newref, referent);
				SvREADONLY_on(newref);
				SvREFCNT_dec(fake_referent);
				SvREFCNT_dec(newref);
			}
			op_free(o);
			return newop;
		} else if(sigil == 'P') {
			SV *newref;
			U16 type, flags;
			/*
			 * Not a name that we have a defined meaning for,
			 * but it has the form of the "our" hack, implying
			 * that we did put an entry in the pad for it.
			 * Munge this back to what it would have been
			 * without the pad entry.  This should mainly
			 * happen due to explicit unimportation, but it
			 * might also happen if the scoping of the pad and
			 * %^H ever get out of synch.
			 */
			newref = newSVpvn(SvPVX(ref)+LEXPADPREFIXLEN+3,
						SvCUR(ref)-LEXPADPREFIXLEN-3);
			if(SvUTF8(ref)) SvUTF8_on(newref);
			type = o->op_type;
			flags = o->op_flags | (((U16)o->op_private) << 8);
			op_free(o);
			return newUNOP(type, flags,
				newSVOP(OP_CONST, 0, newref));
		}
	}
	return nxck(aTHX_ o);
}

static OP *(*nxck_rv2sv)(pTHX_ OP *o);
static OP *(*nxck_rv2av)(pTHX_ OP *o);
static OP *(*nxck_rv2hv)(pTHX_ OP *o);
static OP *(*nxck_rv2cv)(pTHX_ OP *o);
static OP *(*nxck_rv2gv)(pTHX_ OP *o);

static OP *ck_rv2sv(pTHX_ OP *o) { return ck_rv2xv(o, 'P', nxck_rv2sv); }
static OP *ck_rv2av(pTHX_ OP *o) { return ck_rv2xv(o, 'P', nxck_rv2av); }
static OP *ck_rv2hv(pTHX_ OP *o) { return ck_rv2xv(o, 'P', nxck_rv2hv); }
static OP *ck_rv2cv(pTHX_ OP *o) { return ck_rv2xv(o, '&', nxck_rv2cv); }
static OP *ck_rv2gv(pTHX_ OP *o) { return ck_rv2xv(o, '*', nxck_rv2gv); }

/*
 * setting up lexical names
 */

static HV *stash_lex_sv, *stash_lex_av, *stash_lex_hv;

#define pad_max() THX_pad_max(aTHX)
static U32 THX_pad_max(pTHX)
{
#if PERL_VERSION_GE(5,13,10)
	return U32_MAX;
#elif PERL_VERSION_GE(5,9,5)
	return I32_MAX;
#elif PERL_VERSION_GE(5,9,0)
	return 999999999;
#elif PERL_VERSION_GE(5,8,0)
	static U32 max;
	if(!max) {
		SV *versv = get_sv("]", 0);
		char *verp = SvPV_nolen(versv);
		max = strGE(verp, "5.008009") ? I32_MAX : 999999999;
	}
	return max;
#else /* <5.8.0 */
	return 999999999;
#endif /* <5.8.0 */
}

#define find_compcv(vari_word) THX_find_compcv(aTHX_ vari_word)
static CV *THX_find_compcv(pTHX_ char const *vari_word)
{
	CV *compcv;
#if PERL_VERSION_GE(5,17,5)
	if(!((compcv = PL_compcv) && CvPADLIST(compcv)))
		compcv = NULL;
#else /* <5.17.5 */
	GV *compgv;
	/*
	 * Given that we're being invoked from a BEGIN block,
	 * PL_compcv here doesn't actually point to the sub
	 * being compiled.  Instead it points to the BEGIN block.
	 * The code that we want to affect is the parent of that.
	 * Along the way, better check that we are actually being
	 * invoked that way: PL_compcv may be null, indicating
	 * runtime, or it can be non-null in a couple of
	 * other situations (require, string eval).
	 */
	if(!(PL_compcv && CvSPECIAL(PL_compcv) &&
			(compgv = CvGV(PL_compcv)) &&
			strEQ(GvNAME(compgv), "BEGIN") &&
			(compcv = CvOUTSIDE(PL_compcv)) &&
			CvPADLIST(compcv)))
		compcv = NULL;
#endif /* <5.17.5 */
	if(!compcv)
		croak("can't set up lexical %s outside compilation",
			vari_word);
	return compcv;
}

#define setup_pad(compcv, name) THX_setup_pad(aTHX_ compcv, name)
static void THX_setup_pad(pTHX_ CV *compcv, char const *name)
{
	PADLIST *padlist = CvPADLIST(compcv);
	PADNAMELIST *padname = PadlistNAMES(padlist);
	PAD *padvar = PadlistARRAY(padlist)[1];
	PADOFFSET ouroffset;
	PADNAME *ourname;
	SV *ourvar;
	HV *stash;
	ourvar = *av_fetch(padvar, PadMAX(padvar) + 1, 1);
	SvPADMY_on(ourvar);
	ouroffset = PadMAX(padvar);
#ifdef newPADNAMEpvn
	ourname = newPADNAMEpvn(name, strlen(name));
#else
	ourname = newSV_type(SVt_PADNAME);
	sv_setpv(ourname, name);
#endif
	SvPAD_OUR_on(ourname);
	stash = name[0] == '$' ? stash_lex_sv :
		name[0] == '@' ? stash_lex_av : stash_lex_hv;
	SvOURSTASH_set(ourname, (HV*)SvREFCNT_inc((SV*)stash));
	COP_SEQ_RANGE_LOW_set(ourname, PL_cop_seqmax);
	COP_SEQ_RANGE_HIGH_set(ourname, pad_max());
	PL_cop_seqmax++;
	padnamelist_store(padname, ouroffset, ourname);
#ifdef PadnamelistMAXNAMED
	PadnamelistMAXNAMED(padname) = ouroffset;
#endif /* PadnamelistMAXNAMED */
}

#define lookup_for_compilation(base_sigil, vari_word, name) \
	THX_lookup_for_compilation(aTHX_ base_sigil, vari_word, name)
static SV *THX_lookup_for_compilation(pTHX_ char base_sigil,
	char const *vari_word, SV *name)
{
	SV *key;
	HE *he;
	if(!sv_is_string(name)) croak("%s name is not a string", vari_word);
	key = name_key(base_sigil, name);
	if(!key) croak("malformed %s name", vari_word);
	he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0);
	return he ? SvREFCNT_inc(HeVAL(he)) : &PL_sv_undef;
}

static int svt_scalar(svtype t)
{
        switch(t) {
		case SVt_NULL: case SVt_IV: case SVt_NV:
#if !PERL_VERSION_GE(5,11,0)
		case SVt_RV:
#endif /* <5.11.0 */
		case SVt_PV: case SVt_PVIV: case SVt_PVNV:
		case SVt_PVMG: case SVt_PVLV: case SVt_PVGV:
#if PERL_VERSION_GE(5,11,0)
                case SVt_REGEXP:
#endif /* >=5.11.0 */
			return 1;
		default:
			return 0;
	}
}

#define import(base_sigil, vari_word) THX_import(aTHX_ base_sigil, vari_word)
static void THX_import(pTHX_ char base_sigil, char const *vari_word)
{
	dXSARGS;
	CV *compcv;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for import");
	if(items == 1)
		croak("%"SVf" does no default importation", SVfARG(ST(0)));
	if(!(items & 1))
		croak("import list for %"SVf
			" must alternate name and reference", SVfARG(ST(0)));
	compcv = find_compcv(vari_word);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	for(i = 1; i != items; i += 2) {
		SV *name = ST(i), *ref = ST(i+1), *key, *val;
		svtype rt;
		bool rok;
		char const *vt;
		char sigil;
		HE *he;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		rt = SvROK(ref) ? SvTYPE(SvRV(ref)) : SVt_LAST;
		switch(sigil) {
			case '$': rok = svt_scalar(rt); vt="scalar"; break;
			case '@': rok = rt == SVt_PVAV; vt="array";  break;
			case '%': rok = rt == SVt_PVHV; vt="hash";   break;
			case '&': rok = rt == SVt_PVCV; vt="code";   break;
			case '*': rok = rt == SVt_PVGV; vt="glob";   break;
			default:  rok = 0; vt = "wibble"; break;
		}
		if(!rok) croak("%s is not %s reference", vari_word, vt);
		val = newRV_inc(SvRV(ref));
		he = hv_store_ent(GvHV(PL_hintgv), key, val, 0);
		if(he) {
			val = HeVAL(he);
			SvSETMAGIC(val);
		} else {
			SvREFCNT_dec(val);
		}
		if(char_attr[(U8)sigil] & CHAR_USEPAD)
			setup_pad(compcv, SvPVX(key)+KEYPREFIXLEN);
	}
	PUTBACK;
}

#define unimport(base_sigil, vari_word) \
	THX_unimport(aTHX_ base_sigil, vari_word)
static void THX_unimport(pTHX_ char base_sigil, char const *vari_word)
{
	dXSARGS;
	CV *compcv;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for unimport");
	if(items == 1)
		croak("%"SVf" does no default unimportation", SVfARG(ST(0)));
	compcv = find_compcv(vari_word);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	for(i = 1; i != items; i++) {
		SV *name = ST(i), *ref, *key;
		char sigil;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		if(i != items && (ref = ST(i+1), SvROK(ref))) {
			HE *he;
			SV *cref;
			i++;
			he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0);
			cref = he ? HeVAL(he) : &PL_sv_undef;
			if(SvROK(cref) && SvRV(cref) != SvRV(ref))
				continue;
		}
		(void) hv_delete_ent(GvHV(PL_hintgv), key, G_DISCARD, 0);
		if(char_attr[(U8)sigil] & CHAR_USEPAD)
			setup_pad(compcv, SvPVX(key)+KEYPREFIXLEN);
	}
}

MODULE = Lexical::Var PACKAGE = Lexical::Var

PROTOTYPES: DISABLE

BOOT:
	fake_sv = &PL_sv_undef;
	fake_av = (SV*)newAV();
	fake_hv = (SV*)newHV();
	stash_lex_sv = gv_stashpvs(LEXPADPREFIX"$", 1);
	stash_lex_av = gv_stashpvs(LEXPADPREFIX"@", 1);
	stash_lex_hv = gv_stashpvs(LEXPADPREFIX"%", 1);
	nxck_rv2sv = PL_check[OP_RV2SV]; PL_check[OP_RV2SV] = ck_rv2sv;
	nxck_rv2av = PL_check[OP_RV2AV]; PL_check[OP_RV2AV] = ck_rv2av;
	nxck_rv2hv = PL_check[OP_RV2HV]; PL_check[OP_RV2HV] = ck_rv2hv;
	nxck_rv2cv = PL_check[OP_RV2CV]; PL_check[OP_RV2CV] = ck_rv2cv;
	nxck_rv2gv = PL_check[OP_RV2GV]; PL_check[OP_RV2GV] = ck_rv2gv;

SV *
_variable_for_compilation(SV *classname, SV *name)
CODE:
	PERL_UNUSED_VAR(classname);
	RETVAL = lookup_for_compilation('N', "variable", name);
OUTPUT:
	RETVAL

void
import(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import('N', "variable");
	SPAGAIN;

void
unimport(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport('N', "variable");
	SPAGAIN;

MODULE = Lexical::Var PACKAGE = Lexical::Sub

SV *
_sub_for_compilation(SV *classname, SV *name)
CODE:
	PERL_UNUSED_VAR(classname);
	RETVAL = lookup_for_compilation('&', "subroutine", name);
OUTPUT:
	RETVAL

void
import(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import('&', "subroutine");
	SPAGAIN;

void
unimport(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport('&', "subroutine");
	SPAGAIN;
