#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "multicall.h"

#ifndef SvUOK
# define SvUOK(sv)           SvIOK_UV(sv)
#endif

#ifndef cxinc
# define cxinc() my_cxinc(aTHX)
static I32
my_cxinc(pTHX)
{
    cxstack_max = cxstack_max * 3 / 2;
    Renew(cxstack, cxstack_max + 1, struct context);
    return cxstack_ix + 1;
}
#endif

/* This was changed by patch 24531 -- one of Nick's optimizations */
#if PERL_VERSION < 10
#  define AvARRAY_set(av, val) ((XPVAV*)  SvANY(av))->xav_array = (char*) val
#else
#  define AvARRAY_set(av, val) av->sv_u.svu_array = (SV**) val
#endif

void
permute_engine(AV* av, SV** array, I32 level, I32 len, SV*** tmparea, OP* multicall_cop)
{
	SV** copy    = tmparea[level];
	int  index   = level;
	bool calling = (index + 1 == len);
	SV*  tmp;
	
	Copy(array, copy, len, SV*);
	
	if (calling)
	    AvARRAY_set(av, copy);

	do {
		if (calling) {
		    MULTICALL;
		}
		else {
		    permute_engine(av, copy, level + 1, len, tmparea, multicall_cop);
		}
		if (index != 0) {
			tmp = copy[index];
			copy[index] = copy[index - 1];
			copy[index - 1] = tmp;
		}
	} while (index-- > 0);
}

struct afp_cache {
    SV***         tmparea;
    AV*           array;
    I32           len;
    SV**          array_array;
    U32           array_flags;
    SSize_t       array_fill;
    SV**          copy;          /* Non-magical SV list for magical array */
};

static
void afp_destructor(void *cache)
{
    struct afp_cache *c = cache;
    I32               x;
    
    /* PerlIO_stdoutf("DESTROY!\n"); */

    for (x = c->len - 1; x >= 0; x--) free(c->tmparea[x]);
    free(c->tmparea);
    if (c->copy) {
        for (x=0; x < c->len; x++) SvREFCNT_dec(c->copy[x]);
        free(c->copy);
    }
    
    AvARRAY_set(c->array, c->array_array);
    SvFLAGS(c->array) = c->array_flags;
    AvFILLp(c->array) = c->array_fill;
    
    free(c);
}


MODULE = Algorithm::FastPermute		PACKAGE = Algorithm::FastPermute		

void
permute(callback_sv, array_sv)
SV* callback_sv;
SV* array_sv;
  PROTOTYPE: &\@
  PREINIT:
    dMULTICALL;
    I32           gimme = G_VOID;  /* We call our callback in VOID context */
    bool          old_catch;
    struct afp_cache *c;
    I32           x;
  PPCODE:
    if (!SvROK(callback_sv) || SvTYPE(SvRV(callback_sv)) != SVt_PVCV)
        Perl_croak(aTHX_ "Callback is not a CODE reference");
    if (!SvROK(array_sv)    || SvTYPE(SvRV(array_sv))    != SVt_PVAV)
        Perl_croak(aTHX_ "Array is not an ARRAY reference");
    
    c = malloc(sizeof(struct afp_cache));
    cv = (CV*)SvRV(callback_sv);
    c->array = (AV*)SvRV(array_sv);
    c->len   = 1 + av_len(c->array);
    
    if (SvREADONLY(c->array))
        Perl_croak(aTHX_ "Can't permute a read-only array");
    
    if (c->len == 0) {
        /* Should we warn here? */
        free(c);
        return;
    }
    
    c->array_array = AvARRAY(c->array);
    c->array_flags = SvFLAGS(c->array);
    c->array_fill  = AvFILLp(c->array);

    /* Magical array. Realise it temporarily. */
    if (SvRMAGICAL(c->array)) {
        c->copy = (SV**) malloc (c->len * sizeof *(c->copy));
        for (x=0; x < c->len; x++) {
            SV **svp = av_fetch(c->array, x, FALSE);
            c->copy[x] = (svp) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
        }
        SvRMAGICAL_off(c->array);
        AvARRAY_set(c->array, c->copy);
        AvFILLp(c->array) = c->len - 1;
    }
    else
        c->copy = 0;
    
    SvREADONLY_on(c->array);  /* Can't change the array during permute */ 
    
    /* Allocate memory for the engine to scribble on */   
    c->tmparea = (SV***) malloc( (c->len+1) * sizeof *(c->tmparea));
    for (x = c->len; x >= 0; x--)
        c->tmparea[x]  = malloc(c->len * sizeof **(c->tmparea));
    
    /* Set up the context for the callback */
    PUSH_MULTICALL(cv);
    save_destructor(afp_destructor, c);
    
    permute_engine(c->array, AvARRAY(c->array), 0, c->len,
    	c->tmparea, multicall_cop);
    
    POP_MULTICALL;
