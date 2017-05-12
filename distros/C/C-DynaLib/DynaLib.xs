#define PERL_POLLUTE

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Support Perls olders than 5.004.  */
#ifndef UV
#  define UV IV
#  ifndef sv_setuv
#    define sv_setuv(sv,uv) sv_setnv(sv,(double)(unsigned long)(uv))
#  endif
#  ifndef U32
#    define U32 I32
#    define U16 I16
#  endif
#  ifndef POPu
#    define POPu POPi
#  endif
#  ifndef UV_MAX
#    define UV_MAX ((UV) -1)
#  endif
#  ifndef IV_MAX
#    define IV_MAX ((IV) ((UV_MAX - 1) / 2))
#  endif
#  ifndef IV_MIN
#    define IV_MIN (-1 - IV_MAX)
#  endif
#endif

/* Why isn't in_eval defined with PERL_POLLUTE? */
#if defined(na) && !defined(in_eval)
#define in_eval PL_in_eval
#endif

/* First i such that ST(i) is a func arg. 
   This is not hardcoded anymore, as it is checked dynamically at testcall.
   => CDECL_STACK_RESERVE
*/
#define DYNALIB_ARGSTART 3

#ifndef DYNALIB_NUM_CALLBACKS
#define DYNALIB_NUM_CALLBACKS 0
#endif

typedef unsigned char uchar;
typedef char *        char_p;
typedef unsigned int  uint;

#ifdef DYNALIB_USE_cdecl6
# define DYNALIB_DECL "cdecl6"
# include "cdecl6.c"
#endif
#ifdef DYNALIB_USE_cdecl3
# define DYNALIB_DECL "cdecl3"
# include "cdecl3.c"
#endif
#ifdef DYNALIB_USE_cdecltr
# define DYNALIB_DECL "cdecltr"
# include "cdecltr.c"
#endif
#ifdef DYNALIB_USE_cdecl
# define DYNALIB_DECL "cdecl"
# include "cdecl.c"
#endif
#ifdef DYNALIB_USE_sparc
# define DYNALIB_DECL "sparc"
# include "sparc.c"
#endif
#ifdef DYNALIB_USE_alpha
# define DYNALIB_DECL "alpha"
# include "alpha.c"
#endif
#ifdef DYNALIB_USE_hack30
# define DYNALIB_DECL "hack30"
# include "hack30.c"
#endif
/* may be used additionally */
#ifdef DYNALIB_USE_stdcall
# ifndef DYNALIB_DECL
#   define DYNALIB_DECL "stdcall"
# endif
# include "stdcall.c"
#endif

typedef long (*cb_callback) _((void * a, ...));
typedef struct {
    SV *coderef;
    char *ret_type;
    char *arg_type;
    cb_callback func;
} cb_entry;

static long cb_call_sub _((int index, void * first, va_list ap));

#include "cbfunc.c"

static AV *cb_av_config;

static SV *
cb_init(arr_ref)
    SV *arr_ref;
{
    SV *elts[DYNALIB_NUM_CALLBACKS];
    int i;
    cb_entry entry;

    entry.coderef = NULL;
    entry.arg_type = "";
    entry.ret_type = "";
    for (i = 0; i < DYNALIB_NUM_CALLBACKS; i++) {
	entry.func = cb_arr[i];
	elts[i] = newSVpv((char *) &entry, sizeof entry);
    }
    cb_av_config = av_make(DYNALIB_NUM_CALLBACKS, elts);
    return (SV *) cb_av_config;
}

#if DYNALIB_NUM_CALLBACKS
/*
 * With apologies to pp.c
 */
static long
cb_call_sub(index, first, ap)
    int index;
    void * first;
    va_list ap;
{
    dSP;
    I32 nret;
    int i;
    long result;
    STRLEN old_err_len, new_err_len;
    char *arg_type;
    cb_entry *config;
    SV *sv;
#ifdef HAS_QUAD
    Quad_t aquad;
    unsigned Quad_t auquad;
#endif
    static char *first_msg = "Can't use '%c' as first argument type in callback";

    config = (cb_entry *) SvPV(*av_fetch(cb_av_config, index, 0), PL_na);
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    arg_type = config->arg_type;
    if (*arg_type != '\0') {
	switch (*arg_type) {
	case 'i' :
	    XPUSHs(sv_2mortal(newSViv((IV) (int) first)));
	    break;
	case 'l' :
	    XPUSHs(sv_2mortal(newSViv((IV) (I32) first)));
	    break;
	case 's' :
	    /* the cast to (long) is just to avoid compiler warnings */
	    XPUSHs(sv_2mortal(newSViv((IV) (I16) (long) first)));
	    break;
	case 'c' :
	    XPUSHs(sv_2mortal(newSViv((IV) (char) (long) first)));
	    break;
	case 'I' :
	    sv = newSV(0);
	    sv_setuv(sv, PTR2UV(first));
	    XPUSHs(sv_2mortal(sv));
	    break;
	case 'L' :
	    sv = newSV(0);
	    sv_setuv(sv, PTR2UV(first));
	    XPUSHs(sv_2mortal(sv));
	    break;
	case 'S' :
	    XPUSHs(sv_2mortal(newSViv((IV) (U16) (long) first)));
	    break;
	case 'C' :
	    XPUSHs(sv_2mortal(newSViv((IV) (unsigned char) (long) first)));
	    break;
#ifdef HAS_QUAD
	case 'q' :
	    if (sizeof (Quad_t) <= sizeof first)
		XPUSHs(sv_2mortal(newSViv(PTR2IV((Quad_t) first))));
	    else
		croak(first_msg, *arg_type);
	    break;
	case 'Q' :
	    if (sizeof (unsigned Quad_t) <= sizeof first) {
		sv = newSV(0);
		sv_setuv(sv, PTR2UV((Uquad_t) first));
		XPUSHs(sv_2mortal(sv));
	    }
	    else
		croak(first_msg, *arg_type);
	    break;
#endif
	case 'P' :
	    ++ arg_type;
	    XPUSHs(sv_2mortal(newSVpv((char *) first,
				      (int) strtol(arg_type, &arg_type, 10))));
	    -- arg_type;
	    break;
	case 'Z' :
	case 'p' :
	    XPUSHs(sv_2mortal(newSVpv((char *) first, 0)));
	    break;
	default :
	    croak(first_msg, *arg_type);
	}
	++ arg_type;
	while (*arg_type != '\0') {
	    switch (*arg_type) {
	    case 'i' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, int))));
		break;
	    case 'l' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, I32))));
		break;
	    case 's' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, int))));
		break;
	    case 'c' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, int))));
		break;
	    case 'I' :
		sv = newSV(0);
		sv_setuv(sv, va_arg(ap, UV));
		XPUSHs(sv_2mortal(sv));
		break;
	    case 'L' :
		sv = newSV(0);
		sv_setuv(sv, va_arg(ap, U32));
		XPUSHs(sv_2mortal(sv));
		break;
	    case 'S' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, int))));
		break;
	    case 'C' :
		XPUSHs(sv_2mortal(newSViv((IV) va_arg(ap, int))));
		break;
#ifdef HAS_QUAD
	    case 'q' :
		aquad = va_arg(ap, Quad_t);
		sv = newSV(0);
		if (aquad >= IV_MIN && aquad <= IV_MAX)
		    sv_setiv(sv, (IV)aquad);
		else
		    sv_setnv(sv, (double)aquad);
		XPUSHs(sv_2mortal(sv));
		break;
	    case 'Q' :
		auquad = va_arg(ap, Uquad_t);
		sv = newSV(0);
		if (aquad <= UV_MAX)
		    sv_setuv(sv, (UV)auquad);
		else
		    sv_setnv(sv, (double)auquad);
		XPUSHs(sv_2mortal(sv));
		break;
#endif
	    case 'f' :
		XPUSHs(sv_2mortal(newSVnv((double) va_arg(ap, double))));
		break;
	    case 'd' :
		XPUSHs(sv_2mortal(newSVnv(va_arg(ap, double))));
		break;
	    case 'P' :
		++ arg_type;
		XPUSHs(sv_2mortal(newSVpv(va_arg(ap, char *),
					  (int) strtol(arg_type, &arg_type, 10))));
		-- arg_type;
		break;
	    case 'Z' :
	    case 'p' :
		XPUSHs(sv_2mortal(newSVpv(va_arg(ap, char *), 0)));
		break;
	    default :
		croak("Can't use '%c' as argument type in callback", *arg_type);
	    }
	    ++ arg_type;
	}
    }
    PUTBACK;

    if (PL_in_eval) {
	/*
	 * XXX The whole issue of G_KEEPERR and `eval's is very confusing
	 * to me. For example, we should be able to tell whether or not we
	 * are in cleanup code that follows a die.  We can't tell just by
	 * looking at $@, since it may be left over from a previous eval.
	 *
	 * If we're not in cleanup, we should clear $@/errgv before we call the
	 * sub.  The way this code works now, any error string left over from a
	 * completed eval is wrongly included in our croak message.
	 *
	 * It can also produce weirdness when used with Carp::confess.
	 */
	SvPV(GvSV(PL_errgv), old_err_len);
	nret = perl_call_sv(config->coderef, G_SCALAR | G_EVAL | G_KEEPERR);
	SPAGAIN;
	SvPV(GvSV(PL_errgv), new_err_len);
	if (new_err_len > old_err_len) {
	    char *msg = SvPV(GvSV(PL_errgv), PL_na);
	    static char prefix[] = "\t(in cleanup) ";  /* from pp_ctl.c */

	    if (old_err_len == 0 && strnEQ(msg, prefix, (sizeof prefix) - 1)) {
		msg += (sizeof prefix) - 1;
		croak("In callback: %s", msg);
	    }
	    else {
		croak("%s", msg);
	    }
	}
    }
    else {
	nret = perl_call_sv(config->coderef, G_SCALAR);
	SPAGAIN;
    }
    if (nret != 1) {
	/* don't know if this can ever happen... */
	croak("Call to callback failed\n");
    }
    switch (*(config->ret_type)) {
    case '\0' :
    case 'i' :
	result = (long) (int) POPi;
	break;
    case 'I' :
	result = (long) (uint) POPu;
	break;
#if defined(HAS_QUAD) && LONGSIZE >= 8
    case 'q' :
	result = (long) (Quad_t) POPi;
	break;
#endif
	/*
	 * Returning a pointer is impossible to do safely, it seems.
	 * We rather want to return a string instead.
	 * case 'p' :
	 *   result = (long) POPp;
	 *   break;
	 */
    default :
	croak("Can't use '%s' as return type in callback", config->ret_type);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}
#endif  /* DYNALIB_NUM_CALLBACKS != 0 */

static char *
constant(name)
    char *name;
{
    errno = 0;
    switch (*name) {
    case 'D' :
	if (strEQ(name, "DYNALIB_DEFAULT_CONV")) {
	    return DYNALIB_DEFAULT_CONV;
	}
	break;
    case 'P' :
	if (strEQ(name, "PTR_TYPE")) {
	    if (sizeof (void *) == sizeof (int))
		/* XXX Are pointers signed? */
		return "i";
#ifdef HAS_QUAD
	    if (sizeof (void *) == sizeof (Quad_t))
		return "q";
#endif
	    if (sizeof (void *) == sizeof (I32))
		return "l";
	    if (sizeof (void *) == sizeof (I16))
		return "s";
	    croak("Can't find an integer type that's the same size as pointers");
	}
	break;
    }
    errno = EINVAL;
    return 0;
}


MODULE = C::DynaLib  PACKAGE = C::DynaLib

char *
constant(name)
	char *		name

INCLUDE: conv.xsi

void
Poke(dest, data)
	# Well, you could do the same thing by loading memcpy().
	void *	dest
	SV *	data
	CODE:
	{
	  STRLEN len;
	  char *source;
	  if (SvPOK(data)) {
	    source = SvPV(data, len);
	    Copy(source, dest, len, char);
	  }
	}

BOOT:
      {
	/* @C::DynaLib::decl */
	AV* av = get_av("C::DynaLib::decl", GV_ADD);
#ifdef DYNALIB_USE_cdecl6
	av_push(av, newSVpv("cdecl6",0));
#endif
#ifdef DYNALIB_USE_cdecl3
	av_push(av, newSVpv("cdecl3",0));
#endif
#ifdef DYNALIB_USE_cdecl
	av_push(av, newSVpv("cdecl ",0));
#endif
#ifdef DYNALIB_USE_sparc
	av_push(av, newSVpv("sparc",0);
#endif
#ifdef DYNALIB_USE_alpha
	av_push(av, newSVpv("alpha",0));
#endif
#ifdef DYNALIB_USE_hack30
	av_push(av, newSVpv("hack30",0));
#endif
#ifdef DYNALIB_USE_stdcall
	av_push(av, newSVpv("stdcall",0));
#endif

	/* $C::DynaLib::decl = cdecl,hack30,... */
	sv_setsv(get_sv("C::DynaLib::decl", GV_ADD), newSVpv(DYNALIB_DEFAULT_CONV, 0));

	/* Setup the callback config array. */
	sv_setsv(SvRV(ST(2)), newRV((SV*) sv_2mortal(cb_init(ST(2)))));
      }
