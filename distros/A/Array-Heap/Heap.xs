#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* pre-5.10 compatibility */
#ifndef GV_NOTQUAL
# define GV_NOTQUAL 1
#endif
#ifndef gv_fetchpvs
# define gv_fetchpvs gv_fetchpv
#endif

/* pre-5.8 compatibility */
#ifndef PERL_MAGIC_tied
# define PERL_MAGIC_tied 'P'
#endif

#include "multicall.h"

/* workaround for buggy multicall API */
#ifndef cxinc
# define cxinc() Perl_cxinc (aTHX)
#endif

#define dCMP			\
  dMULTICALL;			\
  void *cmp_data;               \
  I32 gimme = G_SCALAR;

#define CMP_PUSH(sv)		\
  PUSH_MULTICALL (cmp_push_ (sv));\
  cmp_data = multicall_cop;

#define CMP_POP			\
  POP_MULTICALL;

#define dCMP_CALL(data)		\
  OP *multicall_cop = (OP *)data;

static void *
cmp_push_ (SV *sv)
{
  HV *st;
  GV *gvp;
  CV *cv;

  cv = sv_2cv (sv, &st, &gvp, 0);

  if (!cv)
    croak ("%s: callback must be a CODE reference or another callable object", SvPV_nolen (sv));

  SAVESPTR (PL_firstgv ); PL_firstgv  = gv_fetchpv ("a", GV_ADD | GV_NOTQUAL, SVt_PV); SAVESPTR (GvSV (PL_firstgv ));
  SAVESPTR (PL_secondgv); PL_secondgv = gv_fetchpv ("b", GV_ADD | GV_NOTQUAL, SVt_PV); SAVESPTR (GvSV (PL_secondgv));

  return cv;
}

/*****************************************************************************/

static SV *
sv_first (SV *sv)
{
  if (SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV)
    {
      AV *av = (AV *)SvRV (sv);

      sv = AvFILLp (av) < 0 || !AvARRAY (sv)[0]
           ? &PL_sv_undef : AvARRAY (av)[0];
    }

  return sv;
}

static void
set_idx (SV *sv, int idx)
{
  if (!SvROK (sv))
    return;

  sv = SvRV (sv);
  
  if (SvTYPE (sv) != SVt_PVAV)
    return;
  
  if (
     AvFILL ((AV *)sv) < 1
     || AvARRAY ((AV *)sv)[1] == 0
     || AvARRAY ((AV *)sv)[1] == &PL_sv_undef)
    av_store ((AV *)sv, 1, newSViv (idx));
  else
    {
      sv = AvARRAY ((AV *)sv)[1];

      if (SvTYPE (sv) == SVt_IV)
        SvIV_set (sv, idx);
      else
        sv_setiv (sv, idx);
    }
}

#define set_heap(idx,he)		\
  do {					\
    if (flags)				\
      set_idx (he, idx);		\
    heap [idx] = he;			\
  } while (0)

static int
cmp_nv (SV *a, SV *b, void *cmp_data)
{
  a = sv_first (a);
  b = sv_first (b);

  return SvNV (a) > SvNV (b);
}

static int
cmp_sv (SV *a, SV *b, void *cmp_data)
{
  a = sv_first (a);
  b = sv_first (b);

  return sv_cmp (a, b) > 0;
}

static int
cmp_custom (SV *a, SV *b, void *cmp_data)
{
  dCMP_CALL (cmp_data);

  GvSV (PL_firstgv ) = a;
  GvSV (PL_secondgv) = b;

  MULTICALL;

  if (SvTRUE (ERRSV))
    croak (NULL);

  {
    dSP;
    return TOPi > 0;
  }
}

/*****************************************************************************/

typedef int (*f_cmp)(SV *a, SV *b, void *cmp_data);

static AV *
array (SV *ref)
{
  if (SvROK (ref)
      && SvTYPE (SvRV (ref)) == SVt_PVAV
      && !SvTIED_mg (SvRV (ref), PERL_MAGIC_tied))
    return (AV *)SvRV (ref);

  croak ("argument 'heap' must be a (non-tied) array");
}

#define gt(a,b) cmp ((a), (b), cmp_data)

/*****************************************************************************/

/* away from the root */
static void
downheap (AV *av, f_cmp cmp, void *cmp_data, int N, int k, int flags)
{
  SV **heap = AvARRAY (av);
  SV *he = heap [k];

  for (;;)
    {
      int c = (k << 1) + 1;

      if (c >= N)
        break;

      c += c + 1 < N && gt (heap [c], heap [c + 1])
           ? 1 : 0;

      if (!(gt (he, heap [c])))
        break;

      set_heap (k, heap [c]);

      k = c;
    }

  set_heap (k, he);
}

/* towards the root */
static void
upheap (AV *av, f_cmp cmp, void *cmp_data, int k, int flags)
{
  SV **heap = AvARRAY (av);
  SV *he = heap [k];

  while (k)
    {
      int p = (k - 1) >> 1;

      if (!(gt (heap [p], he)))
        break;

      set_heap (k, heap [p]);
      k = p;
    }

  set_heap (k, he);
}

/* move an element suitably so it is in a correct place */
static void
adjustheap (AV *av, f_cmp cmp, void *cmp_data, int N, int k, int flags)
{
  SV **heap = AvARRAY (av);

  if (k > 0 && !gt (heap [k], heap [(k - 1) >> 1]))
    upheap (av, cmp, cmp_data, k, flags);
  else
    downheap (av, cmp, cmp_data, N, k, flags);
}

/*****************************************************************************/

static void
make_heap (AV *av, f_cmp cmp, void *cmp_data, int flags)
{
  int i, len = AvFILLp (av);

  /* do not use floyds algorithm, as I expect the simpler and more cache-efficient */
  /* upheap is actually faster */
  for (i = 0; i <= len; ++i)
    upheap (av, cmp, cmp_data, i, flags);
}

static void
push_heap (AV *av, f_cmp cmp, void *cmp_data, SV **elems, int nelems, int flags)
{
  int i;

  av_extend (av, AvFILLp (av) + nelems);

  /* we do it in two steps, as the perl cmp function might copy the stack */
  for (i = 0; i < nelems; ++i)
    AvARRAY (av)[++AvFILLp (av)] = newSVsv (elems [i]);

  for (i = 0; i < nelems; ++i)
    upheap (av, cmp, cmp_data, AvFILLp (av) - i, flags);
}

static SV *
pop_heap (AV *av, f_cmp cmp, void *cmp_data, int flags)
{
  int len = AvFILLp (av);

  if (len < 0)
    return &PL_sv_undef;
  else if (len == 0)
    return av_pop (av);
  else
    {
      SV *top = av_pop (av);
      SV *result = AvARRAY (av)[0];
      AvARRAY (av)[0] = top;
      downheap (av, cmp, cmp_data, len, 0, flags);
      return result;
    }
}

static SV *
splice_heap (AV *av, f_cmp cmp, void *cmp_data, int idx, int flags)
{
  int len = AvFILLp (av);

  if (idx < 0 || idx > len)
    return &PL_sv_undef;
  else if (idx == len)
    return av_pop (av); /* the last element */
  else
    {
      SV *top = av_pop (av);
      SV *result = AvARRAY (av)[idx];
      AvARRAY (av)[idx] = top;
      adjustheap (av, cmp, cmp_data, len, idx, flags);
      return result;
    }
}

static void
adjust_heap (AV *av, f_cmp cmp, void *cmp_data, int idx, int flags)
{
  int len = AvFILLp (av);

  if (idx > len)
    croak ("Array::Heap::adjust_heap: index out of array bounds");

  adjustheap (av, cmp, cmp_data, len + 1, idx, flags);
}

MODULE = Array::Heap		PACKAGE = Array::Heap

void
make_heap (SV *heap)
        PROTOTYPE: \@
        ALIAS:
        make_heap_idx = 1
        CODE:
        make_heap (array (heap), cmp_nv, 0, ix);

void
make_heap_lex (SV *heap)
        PROTOTYPE: \@
        CODE:
        make_heap (array (heap), cmp_sv, 0, 0);

void
make_heap_cmp (SV *cmp, SV *heap)
        PROTOTYPE: &\@
        CODE:
{
        dCMP;
        CMP_PUSH (cmp);
        make_heap (array (heap), cmp_custom, cmp_data, 0);
        CMP_POP;
}

void
push_heap (SV *heap, ...)
        PROTOTYPE: \@@
        ALIAS:
        push_heap_idx = 1
        CODE:
        push_heap (array (heap), cmp_nv, 0, &(ST(1)), items - 1, ix);

void
push_heap_lex (SV *heap, ...)
        PROTOTYPE: \@@
        CODE:
        push_heap (array (heap), cmp_sv, 0, &(ST(1)), items - 1, 0);

void
push_heap_cmp (SV *cmp, SV *heap, ...)
        PROTOTYPE: &\@@
        CODE:
{
	SV **st_2 = &(ST(2)); /* multicall.h uses PUSHSTACK */
        dCMP;
        CMP_PUSH (cmp);
        push_heap (array (heap), cmp_custom, cmp_data, st_2, items - 2, 0);
        CMP_POP;
}

SV *
pop_heap (SV *heap)
        PROTOTYPE: \@
        ALIAS:
        pop_heap_idx = 1
        CODE:
        RETVAL = pop_heap (array (heap), cmp_nv, 0, ix);
        OUTPUT:
        RETVAL

SV *
pop_heap_lex (SV *heap)
        PROTOTYPE: \@
        CODE:
        RETVAL = pop_heap (array (heap), cmp_sv, 0, 0);
        OUTPUT:
        RETVAL

SV *
pop_heap_cmp (SV *cmp, SV *heap)
        PROTOTYPE: &\@
        CODE:
{
        dCMP;
        CMP_PUSH (cmp);
        RETVAL = pop_heap (array (heap), cmp_custom, cmp_data, 0);
        CMP_POP;
}
        OUTPUT:
        RETVAL

SV *
splice_heap (SV *heap, int idx)
        PROTOTYPE: \@$
        ALIAS:
        splice_heap_idx = 1
        CODE:
        RETVAL = splice_heap (array (heap), cmp_nv, 0, idx, ix);
        OUTPUT:
        RETVAL

SV *
splice_heap_lex (SV *heap, int idx)
        PROTOTYPE: \@$
        CODE:
        RETVAL = splice_heap (array (heap), cmp_sv, 0, idx, 0);
        OUTPUT:
        RETVAL

SV *
splice_heap_cmp (SV *cmp, SV *heap, int idx)
        PROTOTYPE: &\@$
        CODE:
{
        dCMP;
        CMP_PUSH (cmp);
        RETVAL = splice_heap (array (heap), cmp_custom, cmp_data, idx, 0);
        CMP_POP;
}
        OUTPUT:
        RETVAL

void
adjust_heap (SV *heap, int idx)
        PROTOTYPE: \@$
        ALIAS:
        adjust_heap_idx = 1
        CODE:
        adjust_heap (array (heap), cmp_nv, 0, idx, ix);

void
adjust_heap_lex (SV *heap, int idx)
        PROTOTYPE: \@$
        CODE:
        adjust_heap (array (heap), cmp_sv, 0, idx, 0);

void
adjust_heap_cmp (SV *cmp, SV *heap, int idx)
        PROTOTYPE: &\@$
        CODE:
{
        dCMP;
        CMP_PUSH (cmp);
        adjust_heap (array (heap), cmp_custom, cmp_data, idx, 0);
        CMP_POP;
}

