/* -*- mode:C tab-width:4 -*- */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"
#include "XSUB.h"


#ifdef PERL_OBJECT
# undef PL_op_name
# undef PL_opargs
# undef PL_op_desc
# define PL_op_name (get_op_names())
# define PL_opargs (get_opargs())
# define PL_op_desc (get_op_descs())
#endif

/* CPAN #28912: MSWin32 and AIX as only platforms do not export PERL_CORE functions,
   such as Perl_pad_alloc, Perl_cv_clone, fold_constants,
   so disable this feature. cygwin gcc-3 --export-all-symbols was non-strict, gcc-4 is.
   POSIX with export PERL_DL_NONLAZY=1 also fails. This is checked in Makefile.PL
   but cannot be solved for clients adding it.
   TODO: Add the patchlevel here when it is fixed in CORE.
*/
#if !defined (DISABLE_PERL_CORE_EXPORTED) &&					\
  (defined(WIN32) ||											\
   defined(_MSC_VER) || defined(__MINGW32_VERSION) ||			\
   (defined(__CYGWIN__) && (__GNUC__ > 3)) || defined(AIX))
# define DISABLE_PERL_CORE_EXPORTED
#endif

#ifdef DISABLE_PERL_CORE_EXPORTED
# undef HAVE_PAD_ALLOC
# undef HAVE_CV_CLONE
# undef HAVE_FOLD_CONSTANTS
#endif

#ifdef PERL_CUSTOM_OPS
# define CHECK_CUSTOM_OPS \
    if (typenum == OP_CUSTOM) \
        o->op_ppaddr = custom_op_ppaddr(SvPV_nolen(type));
#else
# define CHECK_CUSTOM_OPS
#endif

#ifndef PadARRAY
#undef HAVE_PADNAMELIST
# if PERL_VERSION < 8 || (PERL_VERSION == 8 && !PERL_SUBVERSION)
typedef AV PADLIST;
typedef AV PAD;
# endif
# define PadlistARRAY(pl)	((PAD **)AvARRAY(pl))
# define PadlistNAMES(pl)	(*PadlistARRAY(pl))
# define PadARRAY			AvARRAY
# define PadnamelistMAX		AvFILLp
# define PadnamelistARRAY	AvARRAY
#else
#define HAVE_PADNAMELIST
#endif

#ifndef SvIS_FREED
#  define SvIS_FREED(sv) ((sv)->sv_flags == SVTYPEMASK)
#endif
#ifndef OpSIBLING
# ifdef PERL_OP_PARENT
#  define OpSIBLING(o)		  (0 + (o)->op_moresib ? (o)->op_sibparent : NULL)
#  define OpSIBLING_set(o, v) ((o)->op_moresib ? (o)->op_sibparent = (v) : NULL)
# else
#  define OpSIBLING(o)        (o)->op_sibling
#  define OpSIBLING_set(o, v) (o)->op_sibling = (v)
# endif
#else
#  ifndef OpSIBLING_set
#    define OpSIBLING_set(o, v) OpMORESIB_set((o), (v))
#  endif
#endif

static const char* const svclassnames[] = {
    "B::NULL",
#if PERL_VERSION >= 9 && PERL_VERSION < 19
    "B::BIND",
#endif
    "B::IV",
    "B::NV",
#if PERL_VERSION <= 10
    "B::RV",
#endif
    "B::PV",
#if PERL_VERSION >= 19
    "B::INVLIST",
#endif
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
#if PERL_VERSION <= 8
    "B::BM",
#endif
#if PERL_VERSION >= 11
    "B::REGEXP",
#endif
#if PERL_VERSION >= 9
    "B::GV",
#endif
    "B::PVLV",
    "B::AV",
    "B::HV",
    "B::CV",
#if PERL_VERSION <= 8
    "B::GV",
#endif
    "B::FM",
    "B::IO",
};

typedef enum {
    OPc_NULL,   /* 0 */
    OPc_BASEOP, /* 1 */
    OPc_UNOP,   /* 2 */
    OPc_BINOP,  /* 3 */
    OPc_LOGOP,  /* 4 */
    OPc_LISTOP, /* 5 */
    OPc_PMOP,   /* 6 */
    OPc_SVOP,   /* 7 */
    OPc_PADOP,  /* 8 */
    OPc_PVOP,   /* 9 */
    OPc_CVOP,   /* 10 */
    OPc_LOOP,   /* 11 */
    OPc_COP,     /* 12 */
    OPc_METHOP, /* 13 */
    OPc_UNOP_AUX /* 14 */
} opclass;

static char *opclassnames[] = {
    "B::NULL",
    "B::OP",
    "B::UNOP",
    "B::BINOP",
    "B::LOGOP",
    "B::LISTOP",
    "B::PMOP",
    "B::SVOP",
    "B::PADOP",
    "B::PVOP",
    "B::CVOP",
    "B::LOOP",
    "B::COP",
    "B::METHOP",
    "B::UNOP_AUX"
};

static int walkoptree_debug = 0; /* Flag for walkoptree debug hook */

static SV *specialsv_list[7];    /* 0-6 */

AV * tmp_comppad;
#ifdef HAVE_PADNAMELIST
PADNAMELIST * tmp_comppad_name;
#else
AV * tmp_comppad_name;
#endif
I32 tmp_padix, tmp_reset_pending;
OP * tmp_op;

CV * my_curr_cv = NULL;

SV** my_current_pad;
SV** tmp_pad;

HV* root_cache;

#define GEN_PAD  { set_active_sub(find_cv_by_root((OP*)o));tmp_pad = PL_curpad;PL_curpad = my_current_pad;}
#define GEN_PAD_CV(cv) { set_active_sub(cv);tmp_pad = PL_curpad;PL_curpad = my_current_pad;}
#define OLD_PAD      (PL_curpad = tmp_pad)

#define SAVE_VARS \
{ \
	tmp_comppad       = PL_comppad; \
	tmp_comppad_name  = PL_comppad_name; \
	tmp_padix         = PL_padix; \
	tmp_reset_pending = PL_pad_reset_pending; \
	tmp_pad           = PL_curpad; \
	tmp_op            = PL_op; \
	if ( my_curr_cv) { \
		PL_comppad       = PadlistARRAY(CvPADLIST(my_curr_cv))[1]; \
		PL_comppad_name  = PadlistNAMES(CvPADLIST(my_curr_cv)); \
		PL_padix         = PadnamelistMAX(PL_comppad_name); \
		PL_pad_reset_pending = 0; \
	} \
	PL_curpad = AvARRAY(PL_comppad); \
}

#define RESTORE_VARS \
{ \
	PL_op                = tmp_op; \
	PL_comppad           = tmp_comppad; \
	PL_curpad            = tmp_pad; \
	PL_padix             = tmp_padix; \
	PL_comppad_name      = tmp_comppad_name; \
	PL_pad_reset_pending = tmp_reset_pending; \
}

void
set_active_sub(SV *sv)
{
    dTHX;
    PADLIST* padlist;
    PAD** svp;
    /* sv_dump(SvRV(sv)); */
    padlist = CvPADLIST(SvRV(sv));
    if (!padlist) {
        dTHX;				/* XXX coverage 0 */
        sv_dump(sv);
        sv_dump((SV*)SvRV(sv));
        croak("set_active_sub: !CvPADLIST(SvRV(sv))");
    }
    svp = PadlistARRAY(padlist);
    my_current_pad = PadARRAY(svp[1]); /* => GEN_PAD */
}

static SV *
find_cv_by_root(OP* o) {
  dTHX;
  OP* root = o;
  SV* key;
  HE* cached;

  if (PL_compcv && SvTYPE(PL_compcv) == SVt_PVCV && !PL_eval_root) {
	/* XXX coverage 0 */
	if (SvROK(PL_compcv)) {
	  sv_dump(SvRV(PL_compcv));
	  croak("find_cv_by_root: SvROK(PL_compcv)");
	}
	return newRV((SV*)PL_compcv);
  }

  if (!root_cache)
    root_cache = newHV();

  while(root->op_next)
    root = root->op_next;

  key = newSViv(PTR2IV(root));

  cached = hv_fetch_ent(root_cache, key, 0, 0);
  if (cached) {
    SvREFCNT_dec(key);
    return HeVAL(cached);
  }

  if (PL_main_root == root) {
    /* Special case, this is the main root */
    cached = hv_store_ent(root_cache, key, newRV((SV*)PL_main_cv), 0);
  } else if (PL_eval_root == root && PL_compcv) {
    SV* tmpcv = (SV*)NEWSV(1104,0);			/* XXX coverage 0 */
    sv_upgrade((SV *)tmpcv, SVt_PVCV);
    CvPADLIST(tmpcv) = CvPADLIST(PL_compcv);
    SvREFCNT_inc(CvPADLIST(tmpcv));
    CvROOT(tmpcv) = root;
    OP_REFCNT_LOCK;
    OpREFCNT_inc(root);
    OP_REFCNT_UNLOCK;
    cached = hv_store_ent(root_cache, key, newRV((SV*)tmpcv), 0);
  } else {
    /* Need to walk the symbol table, yay */
    CV* cv = 0;
    SV* sva;
    SV* sv;
    register SV* svend;

    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
      svend = &sva[SvREFCNT(sva)];
      for (sv = sva + 1; sv < svend; ++sv) {
        if (!SvIS_FREED(sv) && SvREFCNT(sv)) {
          if (SvTYPE(sv) == SVt_PVCV &&
             CvROOT(sv) == root
             ) {
            cv = (CV*) sv;
			goto out;
          } else if ( SvTYPE(sv) == SVt_PVGV &&
#if PERL_VERSION >= 10
                     isGV_with_GP(sv) &&
#endif
                     GvGP(sv) &&
                     GvCV(sv) && !SvVALID(sv) && !CvXSUB(GvCV(sv)) &&
                     CvROOT(GvCV(sv)) == root)
          {
              cv = (CV*) GvCV(sv);			/* XXX coverage 0 */
			  goto out;
          }
        }
      }
    }

    if (!cv) {
        croak("find_cv_by_root: couldn't find the root cv\n");	/* XXX coverage 0 */
    }
  out:
    cached = hv_store_ent(root_cache, key, newRV((SV*)cv), 0);
  }

  SvREFCNT_dec(key);
  return (SV*) HeVAL(cached);
}


static SV *
make_sv_object(pTHX_ SV *arg, SV *sv)
{
    char *type = 0;
    IV iv;

    for (iv = 0; iv < sizeof(specialsv_list)/sizeof(SV*); iv++) {
        if (sv == specialsv_list[iv]) {
            type = "B::SPECIAL";			/* XXX coverage 0 */
            break;
        }
    }
    if (!type) {
        type = (char*)svclassnames[SvTYPE(sv)];
        iv = PTR2IV(sv);
    }
    sv_setiv(newSVrv(arg, type), iv);
    return arg;
}


/*
   #define PERL_CUSTOM_OPS
   now defined by Makefile.PL, if building for 5.8.x
 */
static I32
op_name_to_num(SV * name)
{
    dTHX;
    char const *s;
    char *wanted = SvPV_nolen(name);
    int i =0;
    int topop = OP_max;

#ifdef PERL_CUSTOM_OPS
    topop--;
#endif

    if (SvIOK(name) && SvIV(name) >= 0 && SvIV(name) < topop)
        return SvIV(name);			/* XXX coverage 0 */

    for (s = PL_op_name[i]; s; s = PL_op_name[++i]) {
        if (strEQ(s, wanted))
            return i;
    }
#ifdef PERL_CUSTOM_OPS
    if (PL_custom_op_names) {
        HE* ent;
        SV* value;

        /* This is sort of a hv_exists, backwards - since custom-ops
	   are stored using their pp-addr as key, we must scan the
	   values */
        (void)hv_iterinit(PL_custom_op_names);
        while ((ent = hv_iternext(PL_custom_op_names))) {
            if (strEQ(SvPV_nolen(hv_iterval(PL_custom_op_names,ent)),wanted))
                return OP_CUSTOM;
        }
    }
#endif

    croak("No such op \"%s\"", SvPV_nolen(name));	/* XXX coverage 0 */

    return -1;
}

#ifdef PERL_CUSTOM_OPS
static void*
custom_op_ppaddr(char *name)
{
    dTHX;
    HE *ent;
    SV *value;
    if (!PL_custom_op_names)
        return 0;

    /* This is sort of a hv_fetch, backwards */
    (void)hv_iterinit(PL_custom_op_names);
    while ((ent = hv_iternext(PL_custom_op_names))) {
        if (strEQ(SvPV_nolen(hv_iterval(PL_custom_op_names,ent)),name))
            return INT2PTR(void*,SvIV(hv_iterkeysv(ent)));
    }

    return 0;
}
#endif

static opclass
cc_opclass(pTHX_ const OP *o)
{
    bool custom = 0;

    if (!o)
	return OPc_NULL;

    if (o->op_type == 0)
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    if (o->op_type == OP_SASSIGN)
	return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

    if (o->op_type == OP_AELEMFAST) {
	if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
#ifdef USE_ITHREADS
	    return OPc_PADOP;
#else
	    return OPc_SVOP;
#endif
    }
    
#ifdef USE_ITHREADS
    if (o->op_type == OP_GV || o->op_type == OP_GVSV 
        || o->op_type == OP_RCATLINE)
	return OPc_PADOP;
#endif

#ifdef PERL_CUSTOM_OPS
    if (o->op_type == OP_CUSTOM)
        custom = 1;
#endif

    switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_BASEOP:
	return OPc_BASEOP;

    case OA_UNOP:
	return OPc_UNOP;

    case OA_BINOP:
	return OPc_BINOP;

    case OA_LOGOP:
	return OPc_LOGOP;

    case OA_LISTOP:
	return OPc_LISTOP;

    case OA_PMOP:
	return OPc_PMOP;

    case OA_SVOP:
	return OPc_SVOP;

    case OA_PADOP:
	return OPc_PADOP;

    case OA_PVOP_OR_SVOP:
        /*
         * Character translations (tr///) are usually a PVOP, keeping a 
         * pointer to a table of shorts used to look up translations.
         * Under utf8, however, a simple table isn't practical; instead,
         * the OP is an SVOP (or, under threads, a PADOP),
         * and the SV is a reference to a swash
         * (i.e., an RV pointing to an HV).
         */
	return (!custom &&
		   (o->op_private & (OPpTRANS_TO_UTF|OPpTRANS_FROM_UTF))
	       )
#if  defined(USE_ITHREADS) \
  && (PERL_VERSION > 8 || (PERL_VERSION == 8 && PERL_SUBVERSION >= 9))
		? OPc_PADOP : OPc_PVOP;
#else
		? OPc_SVOP : OPc_PVOP;
#endif

    case OA_LOOP:
	return OPc_LOOP;

    case OA_COP:
	return OPc_COP;

#if PERL_VERSION >= 22
    case OA_METHOP:
	return OPc_METHOP;

    case OA_UNOP_AUX:
	return OPc_UNOP_AUX;
#endif

    case OA_BASEOP_OR_UNOP:
	/*
	 * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on
	 * whether parens were seen. perly.y uses OPf_SPECIAL to
	 * signal whether a BASEOP had empty parens or none.
	 * Some other UNOPs are created later, though, so the best
	 * test is OPf_KIDS, which is set in newUNOP.
	 */
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    case OA_FILESTATOP:
	/*
	 * The file stat OPs are created via UNI(OP_foo) in toke.c but use
	 * the OPf_REF flag to distinguish between OP types instead of the
	 * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
	 * return OPc_UNOP so that walkoptree can find our children. If
	 * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
	 * (no argument to the operator) it's an OP; with OPf_REF set it's
	 * an SVOP (and op_sv is the GV for the filehandle argument).
	 */
	return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
#ifdef USE_ITHREADS
		(o->op_flags & OPf_REF) ? OPc_PADOP : OPc_BASEOP);
#else
		(o->op_flags & OPf_REF) ? OPc_SVOP : OPc_BASEOP);
#endif
    case OA_LOOPEXOP:
	/*
	 * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
	 * label was omitted (in which case it's a BASEOP) or else a term was
	 * seen. In this last case, all except goto are definitely PVOP but
	 * goto is either a PVOP (with an ordinary constant label), an UNOP
	 * with OPf_STACKED (with a non-constant non-sub) or an UNOP for
	 * OP_REFGEN (with goto &sub) in which case OPf_STACKED also seems to
	 * get set.
	 */
	if (o->op_flags & OPf_STACKED)
	    return OPc_UNOP;
	else if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
	    return OPc_PVOP;
    }
    warn("can't determine class of operator %s, assuming BASEOP\n",
         OP_NAME(o));
    return OPc_BASEOP;
}

static char *
cc_opclassname(pTHX_ OP *o)
{
    return opclassnames[cc_opclass(aTHX_ o)];
}

static OP *
SVtoO(SV* sv)
{
    dTHX;
    if (SvROK(sv)) {
        IV tmp = SvIV((SV*)SvRV(sv));
        return INT2PTR(OP*,tmp);
    }
    else {
        return 0;
    }
    croak("Argument is not a reference");
    return 0; /* Not reached */
}

/* svop_new */

SV *__svop_new(pTHX_ SV *class, SV *type, I32 flags, SV *sv)
{
    OP *o;
    SV *result;
    SV **sparepad;
    OP *saveop;
    I32 typenum;

    SAVE_VARS;
    sparepad = PL_curpad;
    PL_curpad = AvARRAY(PL_comppad);
    saveop = PL_op;
    typenum = op_name_to_num(type); /* XXX More classes here! */
    if (typenum == OP_GVSV) {
        if (*(SvPV_nolen(sv)) == '$')
            sv = (SV*)gv_fetchpv(SvPVX(sv)+1, TRUE, SVt_PV);
        else
            croak("First character to GVSV was not dollar");
    } else {
        if (SvTYPE(sv) != SVt_PVCV) {
            sv = newSVsv(sv); /* copy it unless it's cv */
        }
    }
    o = newSVOP(typenum, flags, SvREFCNT_inc(sv));
    CHECK_CUSTOM_OPS
    RESTORE_VARS;
    result = sv_newmortal();
    sv_setiv(newSVrv(result, "B::SVOP"), PTR2IV(o));
    return result;
}

/* Pre-5.7 compatibility */
#ifndef op_clear
void op_clear(OP* o) {
    /* Fake it, I'm bored */
    croak("This operation requires a newer version of Perl");
}
#endif
#ifndef op_null
# define op_null    croak("This operation requires a newer version of Perl");
#endif

#ifndef PM_GETRE
# define PM_GETRE(o)     ((o)->op_pmregexp)
#endif

typedef OP      *B__OP;
typedef UNOP    *B__UNOP;
typedef BINOP   *B__BINOP;
typedef LOGOP   *B__LOGOP;
typedef LISTOP  *B__LISTOP;
typedef PMOP    *B__PMOP;
typedef SVOP    *B__SVOP;
typedef PADOP   *B__PADOP;
typedef PVOP    *B__PVOP;
typedef LOOP    *B__LOOP;
typedef COP     *B__COP;
#if PERL_VERSION >= 22
typedef METHOP   *B__METHOP;
typedef UNOP_AUX *B__UNOP_AUX;
typedef UNOP_AUX_item *B__UNOP_AUX_item;
#endif

typedef SV      *B__SV;
typedef SV      *B__IV;
typedef SV      *B__PV;
typedef SV      *B__NV;
typedef SV      *B__PVMG;
typedef SV      *B__PVLV;
typedef SV      *B__BM;
typedef SV      *B__RV;
typedef AV      *B__AV;
typedef HV      *B__HV;
typedef CV      *B__CV;
typedef GV      *B__GV;
typedef IO      *B__IO;

typedef MAGIC   *B__MAGIC;

MODULE = B::Generate    PACKAGE = B     PREFIX = B_

# XXX coverage 0
void
B_fudge()
    CODE:
        SSCHECK(2);
        SSPUSHPTR((SV*)PL_comppad);
        SSPUSHINT(SAVEt_COMPPAD);

# coverage ok
B::OP
B_main_root(...)
    PROTOTYPE: ;$
    CODE:
        if (items > 0)
            PL_main_root = SVtoO(ST(0));
        RETVAL = PL_main_root;
    OUTPUT:
        RETVAL

# coverage ok
B::OP
B_main_start(...)
    PROTOTYPE: ;$
    CODE:
        if (items > 0)
            PL_main_start = SVtoO(ST(0));
        RETVAL = PL_main_start;
    OUTPUT:
        RETVAL

# XXX coverage 0
SV *
B_cv_pad(...)
    CV * old_cv = NO_INIT
  PROTOTYPE: ;$
  CODE:
	old_cv = my_curr_cv;
    if (items > 0) {
        if (SvROK(ST(0))) {
            IV tmp;
            if (!sv_derived_from(ST(0), "B::CV"))
                croak("Reference is not a B::CV object");
        	tmp = SvIV((SV*)SvRV(ST(0)));
            my_curr_cv = INT2PTR(CV*,tmp);
        } else {
            my_curr_cv = NULL;
        }
    }

    if ( old_cv ) {
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::CV"), PTR2IV(old_cv));
	} else {
        ST(0) = &PL_sv_undef;
	}

#define OP_desc(o)      (char* const)PL_op_desc[o->op_type]

MODULE = B::Generate    PACKAGE = B::OP         PREFIX = OP_

# coverage: basic.t
B::CV
OP_find_cv(o)
        B::OP   o
    CODE:
        RETVAL = (CV*)SvRV(find_cv_by_root((OP*)o));
    OUTPUT:
        RETVAL

# coverage ok
B::OP
OP_next(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_next = SVtoO(ST(1));
        RETVAL = o->op_next;
    OUTPUT:
        RETVAL

# coverage ok
B::OP
OP_sibling(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
          OpSIBLING_set(o, SVtoO(ST(1)));
        RETVAL = OpSIBLING(o);
    OUTPUT:
        RETVAL

#ifdef PERL_OP_PARENT

# XXX coverage 0
B::OP
OP_sibparent(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            OpLASTSIB_set(o, SVtoO(ST(1)));
        RETVAL = o->op_sibparent;
    OUTPUT:
        RETVAL

#endif

# XXX coverage 0
IV
OP_ppaddr(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_ppaddr = INT2PTR(void*,SvIV(ST(1)));
        RETVAL = PTR2IV((void*)(o->op_ppaddr));
    OUTPUT:
    RETVAL

# XXX coverage 0
char *
OP_desc(o)
        B::OP           o

# XXX coverage 50%
PADOFFSET
OP_targ(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_targ = (PADOFFSET)SvIV(ST(1));

        /* begin highly experimental */	/* XXX coverage 0 */
        if (items > 1 && (SvIV(ST(1)) > 1000 || SvIV(ST(1)) & 0x80000000)) {
            PADLIST *padlist = INT2PTR(PADLIST*,SvIV(ST(1)));

            I32 old_padix             = PL_padix;
            I32 old_comppad_name_fill = PL_comppad_name_fill;
            I32 old_min_intro_pending = PL_min_intro_pending;
            I32 old_max_intro_pending = PL_max_intro_pending;
            /* int old_cv_has_eval       = PL_cv_has_eval; */
            I32 old_pad_reset_pending = PL_pad_reset_pending;
            SV **old_curpad            = PL_curpad;
            AV *old_comppad           = PL_comppad;
#ifdef HAVE_PADNAMELIST
            PADNAMELIST *old_comppad_name = PL_comppad_name;
#else
            AV *old_comppad_name      = PL_comppad_name;
#endif
            /* PTR2UV */

            PL_comppad_name      = PadlistNAMES(padlist);
            PL_comppad           = PadlistARRAY(padlist)[1];
            PL_curpad            = AvARRAY(PL_comppad);

            PL_padix             = PadnamelistMAX(PL_comppad_name);
            PL_pad_reset_pending = 0;
            /* <medwards> PL_comppad_name_fill appears irrelevant as long as you
	       stick to pad_alloc, pad_swipe, pad_free.
	     * PL_comppad_name_fill = 0;
	     * PL_min_intro_pending = 0;
	     * PL_cv_has_eval       = 0;
	     */
#ifdef HAVE_PAD_ALLOC
            o->op_targ = Perl_pad_alloc(aTHX_ 0, SVs_PADTMP);
#else
            /* CPAN #28912: MSWin32 does not export Perl_pad_alloc.
               Rewrite from Perl_pad_alloc for PADTMP:
               Scan the pad from PL_padix upwards for a slot which
               has no name and no active value. */
            {
                SV *sv;
#  if PERL_VERSION > 18
                PADNAME * const * const names = PadnamelistARRAY(PL_comppad_name);
                const SSize_t      names_fill = PadnamelistMAX(PL_comppad_name);
                for (;;) {
                    PADNAME *pn;
                    if (++PL_padix <= names_fill &&
                        (pn = names[PL_padix]) && PadnamePV(pn))
                        continue;
                    sv = *av_fetch(PL_comppad, PL_padix, TRUE);
                    if (!(SvFLAGS(sv) & SVs_PADTMP))
                        break;
                }
#  else
                SV * const * const names = PadnamelistARRAY(PL_comppad_name);
                const SSize_t names_fill = PadnamelistMAX(PL_comppad_name);
                for (;;) {
                    if (++PL_padix <= names_fill &&
                        (sv = names[PL_padix]) && sv != &PL_sv_undef)
                        continue;
                    sv = *av_fetch(PL_comppad, PL_padix, TRUE);
                    if (!(SvFLAGS(sv) & (SVs_PADTMP | SVs_PADMY)) &&
                        !IS_PADGV(sv) && !IS_PADCONST(sv))
                        break;
                }
#  endif
                o->op_targ = PL_padix;
                SvFLAGS(sv) |= SVs_PADTMP;
            }
#endif
            PL_padix             = old_padix;
            PL_comppad_name_fill = old_comppad_name_fill;
            PL_min_intro_pending = old_min_intro_pending;
            PL_max_intro_pending = old_max_intro_pending;
            /* PL_cv_has_eval       = old_cv_has_eval; */
            PL_pad_reset_pending = old_pad_reset_pending;
            PL_curpad            = old_curpad;
            PL_comppad           = old_comppad;
            PL_comppad_name      = old_comppad_name;
        }
        /* end highly experimental */

        RETVAL = o->op_targ;
    OUTPUT:
        RETVAL

# coverage 50%
U16
OP_type(o, ...)
        B::OP           o
    CODE:
        if (items > 1) {
            o->op_type = (U16)SvIV(ST(1));		/* XXX coverage 0 */
            o->op_ppaddr = PL_ppaddr[o->op_type];
        }
        RETVAL = o->op_type;
    OUTPUT:
        RETVAL

#if PERL_VERSION < 10

U16
OP_seq(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_seq = (U16)SvIV(ST(1));
        RETVAL = o->op_seq;
    OUTPUT:
        RETVAL

#endif

# coverage ok
U8
OP_flags(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_flags = (U8)SvIV(ST(1));
        RETVAL = o->op_flags;
    OUTPUT:
        RETVAL

# coverage ok
U8
OP_private(o, ...)
        B::OP           o
    CODE:
        if (items > 1)
            o->op_private = (U8)SvIV(ST(1));
        RETVAL = o->op_private;
    OUTPUT:
        RETVAL

# XXX coverage 0
void
OP_dump(o)
    B::OP o
    CODE:
        op_dump(o);

# XXX coverage 0
void
OP_clean(o)
    B::OP o
    CODE:
        if (o == PL_main_root)
            o->op_next = Nullop;

# XXX coverage 0
void
OP_new(class, type, flags)
    SV * class
    SV * type
    I32 flags
    OP *o = NO_INIT
    I32 typenum = NO_INIT
CODE:
	SAVE_VARS;
	typenum = op_name_to_num(type);
	o = newOP(typenum, flags);
	CHECK_CUSTOM_OPS
	RESTORE_VARS;
	ST(0) = sv_newmortal();
	sv_setiv(newSVrv(ST(0), "B::OP"), PTR2IV(o));

# XXX coverage 0
void
OP_newstate(class, flags, label, oldo)
    SV * class
    I32 flags
    char * label
    B::OP oldo
    OP *o = NO_INIT
CODE:
	SAVE_VARS;
	o = newSTATEOP(flags, label, oldo);
	RESTORE_VARS;
	ST(0) = sv_newmortal();
	sv_setiv(newSVrv(ST(0), "B::LISTOP"), PTR2IV(o));

# XXX coverage 0
B::OP
OP_mutate(o, type)
    B::OP o
    SV* type
    I32 rtype = NO_INIT
  CODE:
    rtype = op_name_to_num(type);
	o->op_ppaddr = PL_ppaddr[rtype];
	o->op_type = rtype;
  OUTPUT:
	o

# Introduced with change 34924, git change b7783a124ff
# This works now only on non-MSWin32/AIX platforms and without PERL_DL_NONLAZY=1,
# checked by DISABLE_PERL_CORE_EXPORTED
# If you use such a platform, you have to fold the constants by yourself.

#if defined(HAVE_FOLD_CONSTANTS) && (PERL_VERSION >= 11)
#  define Perl_fold_constants S_fold_constants
#endif

# XXX coverage 0, added with 0.07
B::OP
OP_convert(o, type, flags)
    B::OP o
    I32 flags
    I32 type
  CODE:
	if (!o || o->op_type != OP_LIST)
	  o = newLISTOP(OP_LIST, 0, o, Nullop);
	else
	  o->op_flags &= ~OPf_WANT;

	if (!(PL_opargs[type] & OA_MARK) && o->op_type != OP_NULL) {
	  op_clear(o);
	  o->op_targ = o->op_type;
	}

    o->op_type = type;
    o->op_ppaddr = PL_ppaddr[type];
    o->op_flags |= flags;

    o = PL_check[type](aTHX_ (OP*)o);
#ifdef HAVE_FOLD_CONSTANTS
    if (o->op_type == type) {
	  COP *cop = PL_curcop;
	  PL_curcop = &PL_compiling;
	  o = Perl_fold_constants(aTHX_ o);
	  PL_curcop = cop;
	}
#endif

  OUTPUT:
    o

MODULE = B::Generate    PACKAGE = B::UNOP               PREFIX = UNOP_

# coverage 50%
B::OP
UNOP_first(o, ...)
    B::UNOP o
  CODE:
	if (items > 1)
	  o->op_first = SVtoO(ST(1));		/* XXX coverage 0 */
    RETVAL = o->op_first;
  OUTPUT:
    RETVAL

# XXX coverage 0
void
UNOP_new(class, type, flags, sv_first)
    SV * class
    SV * type
    I32 flags
    SV * sv_first
    OP *first = NO_INIT
    OP *o = NO_INIT
    I32 typenum = NO_INIT
  CODE:
	I32 padflag = 0;
	if (SvROK(sv_first)) {
	  if (!sv_derived_from(sv_first, "B::OP"))
		croak("Reference 'first' was not a B::OP object");
	  else {
		IV tmp = SvIV((SV*)SvRV(sv_first));
		first = INT2PTR(OP*, tmp);
	  }
	} else if (SvTRUE(sv_first))
	  croak("'first' argument to B::UNOP->new should be a B::OP object or a false value");
	else
	  first = Nullop;
	{

	  SAVE_VARS;
	  typenum = op_name_to_num(type);
	  {
		COP *cop = PL_curcop;
		PL_curcop = &PL_compiling;
		o = newUNOP(typenum, flags, first);
		PL_curcop = cop;
	  }
	  CHECK_CUSTOM_OPS
	  RESTORE_VARS;
	}
    ST(0) = sv_newmortal();
    sv_setiv(newSVrv(ST(0), "B::UNOP"), PTR2IV(o));

MODULE = B::Generate    PACKAGE = B::BINOP              PREFIX = BINOP_

# XXX coverage 0
void
BINOP_null(o)
    B::BINOP        o
  CODE:
    op_null((OP*)o);

# coverage 50%
B::OP
BINOP_last(o,...)
	B::BINOP        o
  CODE:
	if (items > 1)
	  o->op_last = SVtoO(ST(1));	/* XXX coverage 0 */
	RETVAL = o->op_last;
  OUTPUT:
	RETVAL

# coverage 50%
void
BINOP_new(class, type, flags, sv_first, sv_last)
    SV * class
    SV * type
    I32 flags
    SV * sv_first
    SV * sv_last
    OP *first = NO_INIT
    OP *last = NO_INIT
    OP *o = NO_INIT
    CODE:
        if (SvROK(sv_first)) {
            if (!sv_derived_from(sv_first, "B::OP"))
                croak("Reference 'first' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_first));
                first = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_first))
            croak("'first' argument to B::UNOP->new should be a B::OP object or a false value");
        else
            first = Nullop;

        if (SvROK(sv_last)) {
            if (!sv_derived_from(sv_last, "B::OP"))
                croak("Reference 'last' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_last));
                last = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_last))
            croak("'last' argument to B::BINOP->new should be a B::OP object or a false value");
        else
            last = Nullop;

        {
        I32 typenum = op_name_to_num(type);

        SAVE_VARS;

        if (typenum == OP_SASSIGN || typenum == OP_AASSIGN)
            o = newASSIGNOP(flags, first, 0, last);
        else {
		    COP *cop = PL_curcop;
		    PL_curcop = &PL_compiling;
            o = newBINOP(typenum, flags, first, last);
		    PL_curcop = cop;
            CHECK_CUSTOM_OPS
        }

        RESTORE_VARS;
        }
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::BINOP"), PTR2IV(o));

MODULE = B::Generate    PACKAGE = B::LISTOP             PREFIX = LISTOP_

# coverage scope.t
void
LISTOP_new(class, type, flags, sv_first, sv_last)
    SV * class
    SV * type
    I32 flags
    SV * sv_first
    SV * sv_last
    OP *first = NO_INIT
    OP *last = NO_INIT
    OP *o = NO_INIT
    CODE:
        if (SvROK(sv_first)) {
            if (!sv_derived_from(sv_first, "B::OP"))
                croak("Reference 'first' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_first));
                first = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_first))
            croak("'first' argument to B::UNOP->new should be a B::OP object or a false value");
        else
            first = Nullop;

        if (SvROK(sv_last)) {
            if (!sv_derived_from(sv_last, "B::OP"))
                croak("Reference 'last' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_last));
                last = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_last))
            croak("'last' argument to B::BINOP->new should be a B::OP object or a false value");
        else
            last = Nullop;

        {
        I32 typenum = op_name_to_num(type);

	SAVE_VARS;
        o = newLISTOP(typenum, flags, first, last);
        CHECK_CUSTOM_OPS
	RESTORE_VARS;
        }
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::LISTOP"), PTR2IV(o));

MODULE = B::Generate    PACKAGE = B::LOGOP              PREFIX = LOGOP_

# XXX coverage 0
void
LOGOP_new(class, type, flags, sv_first, sv_last)
    SV * class
    SV * type
    I32 flags
    SV * sv_first
    SV * sv_last
    OP *first = NO_INIT
    OP *last = NO_INIT
    OP *o = NO_INIT
    CODE:
        if (SvROK(sv_first)) {
            if (!sv_derived_from(sv_first, "B::OP"))
                croak("Reference 'first' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_first));
                first = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_first))
            croak("'first' argument to B::UNOP->new should be a B::OP object or a false value");
        else
            first = Nullop;

        if (SvROK(sv_last)) {
            if (!sv_derived_from(sv_last, "B::OP"))
                croak("Reference 'last' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_last));
                last = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_last))
            croak("'last' argument to B::BINOP->new should be a B::OP object or a false value");
        else
            last = Nullop;

        {
        I32 typenum  = op_name_to_num(type);
	SAVE_VARS;
        o = newLOGOP(typenum, flags, first, last);
        CHECK_CUSTOM_OPS
        RESTORE_VARS;
        }
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::LOGOP"), PTR2IV(o));

# XXX coverage 0
void
LOGOP_newcond(class, flags, sv_first, sv_last, sv_else)
    SV * class
    I32 flags
    SV * sv_first
    SV * sv_last
    SV * sv_else
    OP *first = NO_INIT
    OP *last = NO_INIT
    OP *elseo = NO_INIT
    OP *o = NO_INIT
    CODE:
        if (SvROK(sv_first)) {
            if (!sv_derived_from(sv_first, "B::OP"))
                croak("Reference 'first' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_first));
                first = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_first))
            croak("'first' argument to B::UNOP->new should be a B::OP object or a false value");
        else
            first = Nullop;

        if (SvROK(sv_last)) {
            if (!sv_derived_from(sv_last, "B::OP"))
                croak("Reference 'last' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_last));
                last = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_last))
            croak("'last' argument to B::BINOP->new should be a B::OP object or a false value");
        else
            last = Nullop;

        if (SvROK(sv_else)) {
            if (!sv_derived_from(sv_else, "B::OP"))
                croak("Reference 'else' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_else));
                elseo = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_else))
            croak("'last' argument to B::BINOP->new should be a B::OP object or a false value");
        else
            elseo = Nullop;

        {
        SAVE_VARS;
        o = newCONDOP(flags, first, last, elseo);
        RESTORE_VARS;
        }
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::LOGOP"), PTR2IV(o));

# coverage 50%
B::OP
LOGOP_other(o,...)
        B::LOGOP        o
    CODE:
        if (items > 1)
            o->op_other = SVtoO(ST(1));
        RETVAL = o->op_other;
    OUTPUT:
        RETVAL

#if PERL_VERSION < 10

#define PMOP_pmreplroot(o)      o->op_pmreplroot
#define PMOP_pmnext(o)          o->op_pmnext
#define PMOP_pmpermflags(o)     o->op_pmpermflags

#endif

#define PMOP_pmregexp(o)        o->op_pmregexp
#define PMOP_pmflags(o)         o->op_pmflags

MODULE = B::Generate    PACKAGE = B::PMOP               PREFIX = PMOP_

#if PERL_VERSION < 10

void
PMOP_pmreplroot(o)
        B::PMOP         o
        OP *            root = NO_INIT
    CODE:
        ST(0) = sv_newmortal();
        root = o->op_pmreplroot;
        /* OP_PUSHRE stores an SV* instead of an OP* in op_pmreplroot */
        if (o->op_type == OP_PUSHRE) {
            sv_setiv(newSVrv(ST(0), root ?
                             svclassnames[SvTYPE((SV*)root)] : "B::SV"),
                     PTR2IV(root));
        }
        else {
            sv_setiv(newSVrv(ST(0), cc_opclassname(aTHX_ root)), PTR2IV(root));
        }

B::OP
PMOP_pmreplstart(o, ...)
        B::PMOP         o
    CODE:
        if (items > 1)
            o->op_pmreplstart = SVtoO(ST(1));
        RETVAL = o->op_pmreplstart;
    OUTPUT:
        RETVAL

B::PMOP
PMOP_pmnext(o, ...)
        B::PMOP         o
    CODE:
        if (items > 1)
            o->op_pmnext = (PMOP*)SVtoO(ST(1));
        RETVAL = o->op_pmnext;
    OUTPUT:
        RETVAL

U16
PMOP_pmpermflags(o)
        B::PMOP         o

#endif

U16
PMOP_pmflags(o)
        B::PMOP         o

#if PERL_VERSION < 11

void
PMOP_precomp(o)
        B::PMOP         o
        REGEXP *        rx = NO_INIT
    CODE:
        ST(0) = sv_newmortal();
        rx = PM_GETRE(o);
        if (rx)
            sv_setpvn(ST(0), rx->precomp, rx->prelen);

#endif

#define SVOP_sv(o)     (cSVOPo_sv)
#define SVOP_gv(o)     ((GV*)cSVOPo_sv)

MODULE = B::Generate    PACKAGE = B::SVOP               PREFIX = SVOP_

# coverage 50%
# SVOP::sv(o, sv, cvref)
# not-threaded ignore optional 2nd cvref arg.
# threaded only allow my variables, not TMP nor OUR.
# XXX [CPAN #70398] B::SVOP->sv broken by B::Generate.
# bad sideeffect polluting Concise.
B::SV
SVOP_sv(o, ...)
        B::SVOP o
    PREINIT:
        SV *sv;
    CODE:
        if (items > 1) {
#ifdef USE_ITHREADS
		    if (items > 2) {
                if (!(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVCV))
                    croak("2nd arg is not a cvref");
			    GEN_PAD_CV(ST(2));
		    } else {
                GEN_PAD;
		    }
#endif
            sv = newSVsv(ST(1));
#ifdef USE_ITHREADS
            if ( cSVOPx(o)->op_sv ) {
                cSVOPx(o)->op_sv = sv;		/* XXX coverage 0 */
            }
            else {
			    /* assert(SvTYPE(sv) & SVs_PADMY); */
                PAD_SVl(o->op_targ) = sv;
            }
#else
            cSVOPx(o)->op_sv = sv;
#endif
#ifdef USE_ITHREADS
            OLD_PAD;
#endif
        }
        /* [CPAN #70398] cSVOPo_sv => cSVOPx(o)->op_sv */
        RETVAL = cSVOPx(o)->op_sv;
    OUTPUT:
        RETVAL

# XXX coverage 0
B::GV
SVOP_gv(o)
        B::SVOP o

# coverage 50% const.t
# uses the additional args type, flags, sv from the embedding function
#define NEW_SVOP(_newOPgen, B_class)                                         \
{                                                                           \
    OP *o;                                                                  \
    SV* param;                                                              \
    I32 typenum;                                                            \
    SAVE_VARS;                                                              \
    typenum = op_name_to_num(type); /* XXX More classes here! */            \
    if (typenum == OP_GVSV) {                                               \
        if (*(SvPV_nolen(sv)) == '$')                                       \
            param = (SV*)gv_fetchpv(SvPVX(sv)+1, TRUE, SVt_PV);             \
        else                                                                \
            croak("First character to GVSV was not dollar");                \
    } else                                                                  \
        param = newSVsv(sv);                                                \
    o = _newOPgen(typenum, flags, param);                                   \
    CHECK_CUSTOM_OPS                                                           \
    RESTORE_VARS;                                                           \
    ST(0) = sv_newmortal();                                                 \
    sv_setiv(newSVrv(ST(0), B_class), PTR2IV(o));                           \
}


# XXX coverage 0
SV*
SVOP_new_svrv(class, type, flags, sv)
    SV * class
    SV * type
    I32 flags
    SV * sv
    CODE:
        ST(0) = __svop_new(aTHX_ class, type, flags, SvRV(sv));


# coverage 100% const.t
# class: ignored. B::SVOP forced
# Note: This is the NEW_SVOP macro expanded for debugging
OP*
SVOP_new(class, type, flags, sv)
    SV * class
    SV * type
    I32 flags
    SV * sv
  CODE:
    OP *o;
    SV* param;
    I32 typenum;
    SAVE_VARS;
    typenum = op_name_to_num(type); /* XXX More classes here! */
    if (typenum == OP_GVSV) {
        if (*(SvPV_nolen(sv)) == '$')
            param = (SV*)gv_fetchpv(SvPVX(sv)+1, TRUE, SVt_PV);
        else
            croak("First character to GVSV was not dollar");
    } else
        param = newSVsv(sv);
    o = newSVOP(typenum, flags, param);
    CHECK_CUSTOM_OPS
    RESTORE_VARS;
    ST(0) = sv_newmortal();
    sv_setiv(newSVrv(ST(0), "B::SVOP"), PTR2IV(o));


#define PADOP_padix(o)  o->op_padix
#define PADOP_sv(o)     (o->op_padix ? PL_curpad[o->op_padix] : Nullsv)
#define PADOP_gv(o)     ((o->op_padix \
                          && SvTYPE(PL_curpad[o->op_padix]) == SVt_PVGV) \
                         ? (GV*)PL_curpad[o->op_padix] : Nullgv)

MODULE = B::Generate    PACKAGE = B::GVOP              PREFIX = GVOP_

# XXX coverage 0
SV *
GVOP_new(class, type, flags, sv)
    SV * class
    SV * type
    I32 flags
    SV * sv
    CODE:
#ifdef USE_ITHREADS
         NEW_SVOP(newPADOP, "B::PADOP");
#else
         NEW_SVOP(newSVOP, "B::SVOP");
#endif

MODULE = B::Generate    PACKAGE = B::PADOP              PREFIX = PADOP_

PADOFFSET
PADOP_padix(o, ...)
        B::PADOP o
    CODE:
        if (items > 1)
            o->op_padix = (PADOFFSET)SvIV(ST(1));
        RETVAL = o->op_padix;
    OUTPUT:
        RETVAL

B::SV
PADOP_sv(o, ...)
        B::PADOP o

B::GV
PADOP_gv(o)
        B::PADOP o

MODULE = B::Generate    PACKAGE = B::PVOP               PREFIX = PVOP_

void
PVOP_pv(o)
        B::PVOP o
    CODE:
        /*
         * OP_TRANS uses op_pv to point to a table of 256 shorts
         * whereas other PVOPs point to a null terminated string.
         */
        ST(0) = sv_2mortal(newSVpv(o->op_pv, (o->op_type == OP_TRANS) ?
                                   256 * sizeof(short) : 0));

MODULE = B::Generate    PACKAGE = B::LOOP               PREFIX = LOOP_

B::OP
LOOP_redoop(o, ...)
        B::LOOP o
    CODE:
        if (items > 1)
            o->op_redoop = SVtoO(ST(1));
        RETVAL = o->op_redoop;
    OUTPUT:
        RETVAL

B::OP
LOOP_nextop(o, ...)
        B::LOOP o
    CODE:
        if (items > 1)
            o->op_nextop = SVtoO(ST(1));
        RETVAL = o->op_nextop;
    OUTPUT:
        RETVAL

B::OP
LOOP_lastop(o, ...)
        B::LOOP o
    CODE:
        if (items > 1)
            o->op_lastop = SVtoO(ST(1));
        RETVAL = o->op_lastop;
    OUTPUT:
        RETVAL

#if PERL_VERSION < 11
#define COP_label(o)    o->cop_label
#endif
#define COP_stashpv(o)  CopSTASHPV(o)
#define COP_stash(o)    CopSTASH(o)
#define COP_file(o)     CopFILE(o)
#define COP_cop_seq(o)  o->cop_seq
#if PERL_VERSION < 10
#define COP_arybase(o)  o->cop_arybase
#endif
#define COP_line(o)     CopLINE(o)
#define COP_warnings(o) (SV*)o->cop_warnings

MODULE = B::Generate    PACKAGE = B::COP                PREFIX = COP_


#if PERL_VERSION < 11

char *
COP_label(o)
        B::COP  o

#endif

char *
COP_stashpv(o)
        B::COP  o

B::HV
COP_stash(o)
        B::COP  o

char *
COP_file(o)
        B::COP  o

U32
COP_cop_seq(o)
        B::COP  o

#if PERL_VERSION < 10

I32
COP_arybase(o)
        B::COP  o

#endif

U16
COP_line(o)
        B::COP  o

=pod

/*
   Disable this wrong B::COP->warnings [CPAN #70396]
   Use the orginal B version instead.

   TODO: This throws a warning that cop_warnings is (STRLEN*)
   while I am casting to (SV*). The typedef converts special
   values of (STRLEN*) into SV objects. Hope the initial pointer
   casting isn't a problem.

   New code for 5.11 is loosely based upon patch 27786 changes to
   B.xs, but avoids calling the static function added there.
   XXX: maybe de-static that function
 */

#if PERL_VERSION < 11

B::SV
COP_warnings(o)
        B::COP  o

#else

void
COP_warnings(o)
        B::COP  o

#endif

=cut

=pod

/*

   another go: with blead@33056, get another arg2 mismatch to newSVpv
   in this code.  Turns out that COP_warnings(o) returns void now.
   So I hope to comment out this XS, and get B's version instead.

B::SV
COP_warnings(o)
        B::COP  o
    CODE:
	RETVAL = newSVpv(o->cop_warnings, 0);

#endif

*/

=cut

#ifndef CopLABEL_alloc
#define CopLABEL_alloc(str) ((str)?savepv(str):NULL)
#endif

# XXX coverage 70%
B::COP
COP_new(class, flags, name, sv_first)
    SV * class
    char * name
    I32 flags
    SV * sv_first
    OP *first = NO_INIT
    OP *o = NO_INIT
    CODE:

        if (SvROK(sv_first)) {	/* # XXX coverage o */
            if (!sv_derived_from(sv_first, "B::OP"))
                croak("Reference 'first' was not a B::OP object");
            else {
                IV tmp = SvIV((SV*)SvRV(sv_first));
                first = INT2PTR(OP*, tmp);
            }
        } else if (SvTRUE(sv_first))
            croak("'first' argument to B::COP->new should be a B::OP object or a false value");
        else
            first = Nullop;

        {
#if PERL_VERSION >= 10
        yy_parser* saveparser = PL_parser, dummyparser;
        if ( PL_parser == NULL) {
            PL_parser = &dummyparser;
            PL_parser-> copline = NOLINE;
        }
#endif
        SAVE_VARS;
        o = newSTATEOP(flags, CopLABEL_alloc(name), first);
        RESTORE_VARS;
#if PERL_VERSION >= 10
        PL_parser = saveparser;
#endif
        }
        ST(0) = sv_newmortal();
        sv_setiv(newSVrv(ST(0), "B::COP"), PTR2IV(o));

#if PERL_VERSION >= 22

MODULE = B::Generate    PACKAGE = B::UNOP_AUX               PREFIX = UNOP_AUX_

# TODO: support list of [type, value] pairs
# coverage
B::UNOP_AUX_item
UNOP_AUX_aux(o, ...)
    B::UNOP_AUX o
  CODE:
	if (items > 1)
	  o->op_aux = (UNOP_AUX_item*)SVtoO(ST(1));
    RETVAL = o->op_aux;
  OUTPUT:
    RETVAL

# XXX coverage 0
void
UNOP_AUX_new(class, type, flags, sv_first, sv_aux)
    SV * class
    SV * type
    I32 flags
    SV * sv_first
    SV * sv_aux
    OP *first = NO_INIT
    UNOP_AUX_item *aux = NO_INIT
    OP *o = NO_INIT
    I32 typenum = NO_INIT
  CODE:
	I32 padflag = 0;
	if (SvROK(sv_first)) {
	  if (!sv_derived_from(sv_first, "B::OP"))
		croak("Reference 'first' was not a B::OP object");
	  else {
		IV tmp = SvIV((SV*)SvRV(sv_first));
		first = INT2PTR(OP*, tmp);
	  }
	} else if (SvTRUE(sv_first))
	  croak("'first' argument to B::UNOP_AUX->new should be a B::OP object or a false value");
	else
	  first = Nullop;

	if (SvROK(sv_aux)) {
	  if (!sv_derived_from(sv_first, "B::PV"))
		croak("Reference 'first' was not a B::PV object");
	  else {
		IV tmp = SvIV((SV*)SvRV(sv_aux));
		aux = INT2PTR(UNOP_AUX_item*, tmp);
	  }
	} else if (SvTRUE(sv_aux))
	  croak("'aux' argument to B::UNOP_AUX->new should be a B::PV object or a false value");
	else
	  aux = NULL;
	{

	  SAVE_VARS;
	  typenum = op_name_to_num(type);
	  {
		COP *cop = PL_curcop;
		PL_curcop = &PL_compiling;
		o = newUNOP_AUX(typenum, flags, first, aux);
		PL_curcop = cop;
	  }
	  CHECK_CUSTOM_OPS
	  RESTORE_VARS;
	}
    ST(0) = sv_newmortal();
    sv_setiv(newSVrv(ST(0), "B::UNOP_AUX"), PTR2IV(o));

MODULE = B::Generate    PACKAGE = B::METHOP               PREFIX = METHOP_

# coverage
B::HV
METHOP_rclass(o, ...)
    B::METHOP o
    SV *sv = NO_INIT
  CODE:
    if (items > 1) {
#ifdef USE_ITHREADS
      int i;
#endif
	  sv = (SV*)SVtoO(ST(1));
      if (sv &&
          (SvTYPE(sv) != SVt_PVHV
           || !HvNAME(sv)))
        croak("rclass argument is not a stash");
#ifdef USE_ITHREADS
      for (i=0;i<PL_generation;i++) {
        if (PL_curpad[i] == sv) {
          o->op_rclass_targ = i;
          break;
        }
      }
#else
      o->op_rclass_sv = sv;
#endif
    }
#ifdef USE_ITHREADS
    RETVAL = (HV*)PL_curpad[o->op_rclass_targ];
#else
    RETVAL = (HV*)o->op_rclass_sv;
#endif
  OUTPUT:
    RETVAL

B::SV
METHOP_meth_sv(o, ...)
    B::METHOP o
  CODE:
	if (items > 1)
	  o->op_u.op_meth_sv = (SV*)SVtoO(ST(1));
    RETVAL = o->op_u.op_meth_sv;
  OUTPUT:
    RETVAL

# XXX coverage 0
void
METHOP_new(class, type, flags, op_first)
    SV * class
    SV * type
    I32 flags
    SV * op_first
    OP *first = NO_INIT
    OP *o = NO_INIT
    I32 typenum = NO_INIT
  CODE:
	I32 padflag = 0;
	if (SvROK(op_first)) {
	  if (!sv_derived_from(op_first, "B::OP")) {
        if (sv_derived_from(op_first, "B::PV")) {
          IV tmp = SvIV(SvRV(op_first));
          first = INT2PTR(OP*, tmp);
        }
        else croak("Reference 'first' was not a B::OP or B::PV object");
      }
	  else {
		IV tmp = SvIV(SvRV(op_first));
		first = INT2PTR(OP*, tmp);
	  }
	} else if (SvTRUE(op_first))
	  croak("'first' argument to B::METHOP->new should be a B::OP or B::PV object or a false value");
	else
	  first = Nullop;
	{

	  SAVE_VARS;
	  typenum = op_name_to_num(type);
	  {
		COP *cop = PL_curcop;
		PL_curcop = &PL_compiling;
		o = newMETHOP(typenum, flags, first);
		PL_curcop = cop;
	  }
	  CHECK_CUSTOM_OPS
	  RESTORE_VARS;
	}
    ST(0) = sv_newmortal();
    sv_setiv(newSVrv(ST(0), "B::METHOP"), PTR2IV(o));

#endif

MODULE = B::Generate  PACKAGE = B::SV  PREFIX = Sv

# coverage ok
SV*
Svsv(sv)
    B::SV   sv
    CODE:
        RETVAL = newSVsv(sv);
    OUTPUT:
        RETVAL

# XXX coverage 0
void*
Svdump(sv)
    B::SV   sv
    CODE:
        sv_dump(sv);

# XXX coverage 0
U32
SvFLAGS(sv, ...)
    B::SV   sv
    CODE:
        if (items > 1)
            sv->sv_flags = SvIV(ST(1));
        RETVAL = SvFLAGS(sv);
    OUTPUT:
        RETVAL

MODULE = B::Generate    PACKAGE = B::CV         PREFIX = CV_

# XXX coverage 0
B::OP
CV_ROOT(cv)
        B::CV   cv
  CODE:
        if (cv == PL_main_cv) {
            RETVAL = PL_main_root;
        } else {
            RETVAL = CvISXSUB(cv) ? NULL : CvROOT(cv);
        }
  OUTPUT:
        RETVAL

# XXX coverage 0
B::CV
CV_newsub_simple(class, name, block)
    SV* class
    SV* name
    B::OP block
    CV* mycv  = NO_INIT
    OP* o = NO_INIT

    CODE:
        o = newSVOP(OP_CONST, 0, SvREFCNT_inc(name));
        mycv = newSUB(start_subparse(FALSE, 0), o, Nullop, block);
        /*op_free(o); */
        RETVAL = mycv;
    OUTPUT:
        RETVAL

#ifdef HAVE_CV_CLONE
# define PERL_CORE
# include "embed.h"

# XXX coverage t/new_cv.t
B::CV
CV_NEW_with_start(cv, root, start)
       B::CV   cv
       B::OP   root
       B::OP   start
    PREINIT:
       CV *new;
    CODE:
       new = Perl_cv_clone(aTHX_ cv);
       CvROOT(new) = root;
       CvSTART(new) = start;
       CvDEPTH(new) = 0;
#if PERL_VERSION > 9
       CvPADLIST(new) = CvPADLIST(cv);
#endif
       SvREFCNT_inc(new);
       RETVAL = new;
    OUTPUT:
       RETVAL

#undef PERL_CORE
#endif

MODULE = B::Generate    PACKAGE = B::PV         PREFIX = Sv

# XXX coverage 0
void
SvPV(sv,...)
    B::PV   sv
  CODE:
  {
	if (items > 1) {
	  sv_setpv(sv, SvPV_nolen(ST(1)));
	}
	ST(0) = sv_newmortal();
	if ( SvPOK(sv) ) {
	  sv_setpvn(ST(0), SvPVX(sv), SvCUR(sv));
	  SvFLAGS(ST(0)) |= SvUTF8(sv);
	}
	else {
	  /* XXX for backward compatibility, but should fail */
	  /* croak( "argument is not SvPOK" ); */
	  sv_setpvn(ST(0), NULL, 0);
	}
  }

BOOT:
    specialsv_list[0] = Nullsv;
    specialsv_list[1] = &PL_sv_undef;
    specialsv_list[2] = &PL_sv_yes;
    specialsv_list[3] = &PL_sv_no;
    /* These are supposed to be (STRLEN*) so I cheat. */
    specialsv_list[4] = (SV*)pWARN_ALL;
    specialsv_list[5] = (SV*)pWARN_NONE;
    specialsv_list[6] = (SV*)pWARN_STD;
