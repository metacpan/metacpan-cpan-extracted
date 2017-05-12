/* 
   Permute.xs

   Copyright (c) 1999 - 2008  Edwin Pratomo

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,
   with the exception that it cannot be placed on a CD-ROM or similar media
   for commercial distribution without the prior approval of the author.

*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include "coollex.h"
#ifdef __cplusplus
}
#endif

#ifdef TRUE
    #undef TRUE
#endif

#ifdef FALSE
    #undef FALSE
#endif

#define TRUE  1
#define FALSE 0

/* For 5.005 compatibility */
#ifndef aTHX_
#  define aTHX_
#endif
#ifndef aTHX
#  define aTHX
#endif
#ifdef ppaddr
#  define PL_ppaddr ppaddr
#endif

/* (Robin) This hack is stolen from Graham Barr's Scalar-List-Utils package.
   The comment therein runs:

   Some platforms have strict exports. And before 5.7.3 cxinc (or Perl_cxinc)
   was not exported. Therefore platforms like win32, VMS etc have problems
   so we redefine it here -- GMB

   With any luck, it will enable us to build under ActiveState Perl.
*/
#if PERL_VERSION < 7/* Not in 5.6.1. */
#  define SvUOK(sv)           SvIOK_UV(sv)
#  ifdef cxinc
#    undef cxinc
#  endif
#  define cxinc() my_cxinc(aTHX)
static I32
my_cxinc(pTHX)
{
    cxstack_max = cxstack_max * 3 / 2;
    Renew(cxstack, cxstack_max + 1, struct context);      /* XXX should fix CXINC macro */
    return cxstack_ix + 1;
}
#endif

/* (Robin) Assigning to AvARRAY(array) expands to an assignment which has a typecast on the left-hand side.
 * So it was technically illegal, but GCC is decent enough to accept it
 * anyway. Unfortunately other compilers are not usually so forgiving...
 */
#if PERL_VERSION >= 9
#  define AvARRAY_set(av, val) ((av)->sv_u.svu_array) = val
#else
#  define AvARRAY_set(av, val) ((XPVAV*) SvANY(av))->xav_array = (char*) val
#endif

typedef unsigned int  UINT;
typedef unsigned long ULONG;

#ifdef USE_LINKEDLIST
typedef struct record {
   int info;
   struct record *link;
} listrecord;
#endif

typedef struct {
    bool is_done;
    SV **items;
    UV num;
#ifdef USE_LINKEDLIST
    listrecord *ptr_head, **ptr, **pred;
#else
    UINT *loc; /* location of n in p[] */
    UINT *p;
#endif
    COMBINATION *c;
} Permute;

/* private _next */
#ifdef USE_LINKEDLIST
static bool _next(UV n, listrecord *ptr_head, listrecord **ptr, listrecord **pred)
#else
static bool _next(UV n, UINT *p, UINT *loc)
#endif
{
#ifndef USE_LINKEDLIST
    int i;
#endif
    bool is_done = FALSE;

    if (n <= 1) /* termination condition */
        return TRUE;

#ifdef USE_LINKEDLIST
    /* less arithmetic */
    if (ptr[n]->link != NULL) {
        pred[n]->link = ptr[n]->link;
        pred[n] = pred[n]->link;
        ptr[n]->link = pred[n]->link;
        pred[n]->link = ptr[n];
    } else {
        pred[n]->link = NULL;
        is_done = _next(n - 1, ptr_head, ptr, pred);
        ptr[n]->link = ptr_head->link;
        ptr_head->link = ptr[n]; /* change head of list */
        pred[n] = ptr_head;
    }
#else
    if (loc[n] < n) {
        /* swap adjacent */
        p[loc[n]] = p[loc[n] + 1];
        p[++loc[n]] = n;
    } else {
        is_done = _next(n - 1, p, loc);
        /* then shift right */
        for (i = n - 1; i >= 1; i--)
            p[i + 1] = p[i];
        /* adjust both extremes */
        p[1] = n;
        loc[n] = 1;
    }
#endif
    return is_done;
}


/* permute_engine() and afp_destructor() are from Robin Houston
 * <robin@kitsite.com> */
void permute_engine(
AV* av, 
SV** array, 
I32 level, 
I32 len, SV*** tmparea, OP* callback)
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
            PL_op = callback;
            CALLRUNOPS(aTHX);
        }
        else {
            permute_engine(av, copy, level + 1, len, tmparea, callback);
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

    for (x = c->len; x >= 0; x--) free(c->tmparea[x]);
    free(c->tmparea);
    if (c->copy) {
        for (x = 0; x < c->len; x++) SvREFCNT_dec(c->copy[x]);
        free(c->copy);
    }
    
    AvARRAY_set(c->array, c->array_array);
    SvFLAGS(c->array) = c->array_flags;
    AvFILLp(c->array) = c->array_fill;
    free(c);
}

MODULE = Algorithm::Permute     PACKAGE = Algorithm::Permute        
PROTOTYPES: DISABLE

Permute* 
new(CLASS, av, ...)
    char *CLASS
    AV *av
    PREINIT:
    UV i, num;
    COMBINATION *c;
    UV r, n;
#ifdef USE_LINKEDLIST
    listrecord *q; /* temporary holder */
#endif
    
    CODE:
    RETVAL = (Permute*) safemalloc(sizeof(Permute));
    if (RETVAL == NULL) {
        warn("Unable to create an instance of Algorithm::Permute");
        XSRETURN_UNDEF;
    }

    RETVAL->is_done = FALSE;
    if ((n = av_len(av) + 1) == 0) 
        XSRETURN_UNDEF;

    /* init combination if necessary */
    if (items > 2) {
        r = SvUV(ST(2));
        if (r > n) {
            warn("Number of combination must be less or equal the number of elements");
            XSRETURN_UNDEF;
        }
        if (r < n) {
            c = init_combination(n, r, av);
            /* PerlIO_stdoutf("passed init_combination()\n"); */
            if (c == NULL) {
                warn("Unable to initialize combination");
                XSRETURN_UNDEF;
            }
            RETVAL->c = c;
            num = r;
        } else {
            RETVAL->c = NULL;
            num = n;
        }
    } else {
        RETVAL->c = NULL;
        num = n;
    }

    RETVAL->num = num;

    if ((RETVAL->items = (SV**) safemalloc(sizeof(SV*) * (num + 1))) == NULL)
        XSRETURN_UNDEF;
#ifdef USE_LINKEDLIST
    RETVAL->ptr_head = safemalloc(sizeof(listrecord));
    if (RETVAL->ptr_head == NULL)
        XSRETURN_UNDEF;
    q = RETVAL->ptr_head;
    RETVAL->ptr  = safemalloc(sizeof(listrecord*) * (num + 1));
    if (RETVAL->ptr == NULL)
        XSRETURN_UNDEF;
    RETVAL->pred = safemalloc(sizeof(listrecord*) * (num + 1));
    if (RETVAL->pred == NULL)
        XSRETURN_UNDEF;
#else
    RETVAL->p = (UINT*) safemalloc(sizeof(UINT) * (num + 1));
    if (RETVAL->p == NULL)
        XSRETURN_UNDEF;
    RETVAL->loc = (UINT*) safemalloc(sizeof(UINT) * (num + 1));
    if (RETVAL->loc == NULL)
        XSRETURN_UNDEF;
#endif

    /* initialize items, p, and loc */
    for (i = 1; i <= num; i++) {
        if (RETVAL->c) {
            *(RETVAL->items + i) = &PL_sv_undef;
        } else {
            *(RETVAL->items + i) = av_shift(av);
        }
#ifdef USE_LINKEDLIST
        q->link = safemalloc(sizeof(listrecord));
        if (q->link == NULL)
            XSRETURN_UNDEF;
        q = q->link;

        q->info = num - i + 1;
        RETVAL->ptr[q->info] = q;
        RETVAL->pred[i] = RETVAL->ptr_head; /* all predecessors point to ptr_head */
#else
        *(RETVAL->p + i) = num - i + 1;
        *(RETVAL->loc + i) = 1;
#endif
    }
#ifdef USE_LINKEDLIST
    q->link = NULL; /* the tail of list points to NULL */
#endif

    if (RETVAL->c) {
        coollex(RETVAL->c);
        coollex_visit(RETVAL->c, RETVAL->items + 1); /* base of items is 1 */
    }

    OUTPUT:
    RETVAL

void
next(self)
    Permute *self
    PREINIT:
    int i;
#ifdef USE_LINKEDLIST
    listrecord *q; /* temporary holder */
#endif
    PPCODE:
    if (self->is_done && self->c) { /* permutation done */
        self->is_done = coollex(self->c); /* generate next combination */
#ifdef USE_LINKEDLIST
        q = self->ptr_head;
        for (i = 1; i <= self->num; i++) {
            q = q->link;
            q->info = self->num - i + 1;
            self->pred[i] = self->ptr_head;
        }
        /* q->link = NULL; */ 
        assert(q->link == NULL); /* should point to NULL */
#else
        /* reset self->p and self->loc */
        for (i = 1; i <= self->num; i++) {
            *(self->p + i) = self->num - i + 1;
            *(self->loc + i) = 1;
        }
#endif
        /* and update self->items */
        coollex_visit(self->c, self->items + 1);
    }
    if (self->is_done) { /* done permutation for all combination */
        if (self->c) {
            free_combination(self->c);
            self->c = NULL;
        }
        XSRETURN_EMPTY;
    }
    else {
        EXTEND(sp, self->num);  
#ifdef USE_LINKEDLIST
        q = self->ptr_head->link;
        while (q) {
            PUSHs(sv_2mortal(newSVsv(*(self->items + q->info))));
            /* PerlIO_stdoutf("%d\n", q->info); */
            q = q->link;
        }
        self->is_done = _next(self->num, self->ptr_head, self->ptr, self->pred);
#else
        for (i = 1; i <= self->num; i++) {
            PUSHs(sv_2mortal(newSVsv(*(self->items + *(self->p + i)))));
        }
        self->is_done = _next(self->num, self->p, self->loc);
#endif
    }

void
DESTROY(self)
    Permute *self
    PREINIT:
    int i;
#ifdef USE_LINKEDLIST
    listrecord *q;
#endif
    CODE:
#ifdef USE_LINKEDLIST
    q = self->ptr_head;
    for (i = 1; i <= self->num; i++) {
        safefree(self->ptr[i]);
        /* No need to deallocate this, in fact, it would be disaster */
        /* safefree(self->pred[i]); */
        SvREFCNT_dec(*(self->items + i));
    }
    safefree(self->ptr);
    safefree(self->pred);
    safefree(self->ptr_head);
#else
    safefree(self->p); /* must free elements first? */
    safefree(self->loc); 
    for (i = 1; i <= self->num; i++) { /* leakproof! */
        SvREFCNT_dec(*(self->items + i));
    }
#endif
    safefree(self->items);
    safefree(self);

void 
peek(self)
    Permute *self
    PREINIT:
#ifdef USE_LINKEDLIST
    listrecord *q;
#else
    int i;
#endif
    PPCODE: 
    if (self->is_done) 
        XSRETURN_EMPTY;
    EXTEND(sp, self->num);
#ifdef USE_LINKEDLIST
    q = self->ptr_head->link;
    while (q) {
        PUSHs(sv_2mortal(newSVsv(*(self->items + q->info))));
        q = q->link;
    }
#else
    for (i = 1; i <= self->num; i++)
        PUSHs(sv_2mortal(newSVsv(*(self->items + *(self->p + i)))));
#endif

void
reset(self)
    Permute *self
    PREINIT:
    int i;
#ifdef USE_LINKEDLIST
    listrecord *q;
#endif
    CODE:
    self->is_done = FALSE;
#ifdef USE_LINKEDLIST
    q = self->ptr_head;
    for (i = 1; i <= self->num; i++) {
        q = q->link;
        q->info = self->num - i + 1;
        self->pred[i] = self->ptr_head;
    }
    assert(q->link == NULL);
#else
    for (i = 1; i <= self->num; i++) {
        *(self->p + i) = self->num - i + 1;
        *(self->loc + i) = 1;     
    }
#endif

void
permute(callback_sv, array_sv)
SV* callback_sv;
SV* array_sv;
  PROTOTYPE: &\@
  PREINIT:
    CV*           callback;
    GV*           agv;
    I32           x;
    PERL_CONTEXT* cx;
    I32           gimme = G_VOID;  /* We call our callback in VOID context */

    bool          old_catch;
    struct afp_cache *c;
    I32 hasargs = 0;
    SV** newsp;
  PPCODE:
{
    if (!SvROK(callback_sv) || SvTYPE(SvRV(callback_sv)) != SVt_PVCV)
        Perl_croak(aTHX_ "Callback is not a CODE reference");
    if (!SvROK(array_sv)    || SvTYPE(SvRV(array_sv))    != SVt_PVAV)
        Perl_croak(aTHX_ "Array is not an ARRAY reference");
    
    c = malloc(sizeof(struct afp_cache));
    callback = (CV*)SvRV(callback_sv);
    c->array    = (AV*)SvRV(array_sv);
    c->len      = 1 + av_len(c->array);
    
    agv = gv_fetchpv("A", TRUE, SVt_PVAV);
    SAVESPTR(GvSV(agv));

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
        for (x = 0; x < c->len; x++) {
            SV **svp = av_fetch(c->array, x, FALSE);
            c->copy[x] = (svp) ? SvREFCNT_inc(*svp) : &PL_sv_undef;
        }
        SvRMAGICAL_off(c->array);
        AvARRAY_set(c->array, c->copy);
        AvFILLp(c->array) = c->len - 1;
    } else {
        c->copy = 0;
    }
    
    SvREADONLY_on(c->array); /* Can't change the array during permute */ 
    
    /* Allocate memory for the engine to scribble on */   
    c->tmparea = (SV***) malloc((c->len + 1) * sizeof *(c->tmparea));
    for (x = c->len; x >= 0; x--)
        c->tmparea[x]  = malloc(c->len * sizeof **(c->tmparea));
    
    /* Set up the context for the callback */
    SAVESPTR(CvROOT(callback)->op_ppaddr);
    CvROOT(callback)->op_ppaddr = PL_ppaddr[OP_NULL];  /* Zap the OP_LEAVESUB */
#ifdef PAD_SET_CUR
    PAD_SET_CUR(CvPADLIST(callback),1);
#else
    SAVESPTR(PL_curpad);
    PL_curpad = AvARRAY((AV*)AvARRAY(CvPADLIST(callback))[1]);
#endif
    SAVETMPS;
    SAVESPTR(PL_op);

    PUSHBLOCK(cx, CXt_NULL, SP);  /* make a pseudo block */
    PUSHSUB(cx);

    old_catch = CATCH_GET;
    CATCH_SET(TRUE);
    save_destructor(afp_destructor, c);
    
    permute_engine(c->array, AvARRAY(c->array), 0, c->len, 
        c->tmparea, CvSTART(callback));
    
    POPBLOCK(cx,PL_curpm);
    CATCH_SET(old_catch);
}
