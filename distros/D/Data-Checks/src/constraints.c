/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024-2025 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"

#include "constraints.h"

#include "perl-backcompat.c.inc"

#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "optree-additions.c.inc"
#include "sv_regexp_match.c.inc"
#include "sv_streq.c.inc"
#include "sv_numcmp.c.inc"

#include "ckcall_constfold.c.inc"

#if HAVE_PERL_VERSION(5, 28, 0)
   /* perl 5.28.0 onward can do gv_fetchmeth superclass lookups without caching
    */
#  define HAVE_FETCHMETH_SUPER_NOCACHE
#endif

#define newSVsv_num(osv)  S_newSVsv_num(aTHX_ osv)
static SV *S_newSVsv_num(pTHX_ SV *osv)
{
  if(SvNOK(osv))
    return newSVnv(SvNV(osv));
  if(SvIOK(osv) && SvIsUV(osv))
    return newSVuv(SvUV(osv));

  return newSViv(SvIV(osv));
}

#define newSVsv_str(osv)  S_newSVsv_str(aTHX_ osv)
static SV *S_newSVsv_str(pTHX_ SV *osv)
{
  SV *nsv = newSV(0);
  sv_copypv(nsv, osv);
  return nsv;
}

#if !HAVE_PERL_VERSION(5, 32, 0)
# define sv_isa_sv(sv, namesv)  S_sv_isa_sv(aTHX_ sv, namesv)
static bool S_sv_isa_sv(pTHX_ SV *sv, SV *namesv)
{
  if(!SvROK(sv) || !SvOBJECT(SvRV(sv)))
    return FALSE;

  /* TODO: ->isa invocation */

  return sv_derived_from_sv(sv, namesv, 0);
}
#endif

#ifndef op_force_list
#  define op_force_list(o)  S_op_force_list(aTHX_ o)
static OP *S_op_force_list(pTHX_ OP *o)
/* Sufficiently good enough for our purposes */
{
  op_null(o);
  return o;
}
#endif

#define alloc_constraint(svp, constraintp, func, n)  S_alloc_constraint(aTHX_ svp, constraintp, func, n)
static void S_alloc_constraint(pTHX_ SV **svp, struct Constraint **constraintp, ConstraintFunc *func, size_t n)
{
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);

  SV *sv = newSV(sizeof(struct Constraint) + n*sizeof(SV *));
  SvPOK_on(sv);
  struct Constraint *constraint = (struct Constraint *)SvPVX(sv);
  *constraint = (struct Constraint){
    .func = func,
    .n    = n,
  };

  for(int i = 0; i < n; i++)
    constraint->args[i] = NULL;

  *svp = sv_bless(newRV_noinc(sv), constraint_stash);
  *constraintp = constraint;
}

SV *DataChecks_extract_constraint(pTHX_ SV *sv)
{
  if(!sv_isa(sv, "Data::Checks::Constraint"))
    croak("Expected a Constraint instance as argument");

  return SvRV(sv);
}

#define sv_has_overload(sv, method)  S_sv_has_overload(aTHX_ sv, method)
static bool S_sv_has_overload(pTHX_ SV *sv, int method)
{
  assert(SvROK(sv));

  HV *stash = SvSTASH(SvRV(sv));
  if(!stash || !Gv_AMG(stash))
    return false;

  MAGIC *mg = mg_find((const SV *)stash, PERL_MAGIC_overload_table);
  if(!mg)
    return false;

  CV **cvp = NULL;
  if(AMT_AMAGIC((AMT *)mg->mg_ptr))
    cvp  = ((AMT *)mg->mg_ptr)->table;
  if(!cvp)
    return false;

  CV *cv = cvp[method];
  if(!cv)
    return false;

  return true;
}

static bool constraint_Defined(pTHX_ struct Constraint *c, SV *value)
{
  return SvOK(value);
}

static bool constraint_Object(pTHX_ struct Constraint *c, SV *value)
{
  return SvROK(value) && SvOBJECT(SvRV(value));
}

static bool constraint_Str(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value))
    return false;

  if(SvROK(value)) {
    SV *rv = SvRV(value);
    if(!SvOBJECT(rv))
      return false;

    if(sv_has_overload(value, string_amg))
      return true;

    return false;
  }
  else {
    return true;
  }
}

static bool constraint_StrEq(pTHX_ struct Constraint *c, SV *value)
{
  if(!constraint_Str(aTHX_ c, value))
    return false;

  SV *strs = c->args[0];
  if(SvTYPE(strs) != SVt_PVAV)
    return sv_streq(value, strs);

  /* TODO: If we were to sort the values initially we could binary-search
   * these much faster
   */
  size_t n = av_count((AV *)strs);
  SV **svp = AvARRAY(strs);
  for(size_t i = 0; i < n; i++)
    if(sv_streq(value, svp[i]))
      return true;

  return false;
}

static SV *mk_constraint_StrEq(pTHX_ size_t nargs, SV **args)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_StrEq, 1);
  sv_2mortal(ret);

  if(!nargs)
    croak("Require at least one string for StrEq()");

  if(nargs == 1)
    /* We can just store a single string directly */
    c->args[0] = newSVsv_str(args[0]);
  else {
    AV *strs = newAV_alloc_x(nargs);
    for(size_t i = 0; i < nargs; i++)
      av_store(strs, i, newSVsv_str(args[i]));

    c->args[0] = (SV *)strs;
  }

  return ret;
}

static bool constraint_StrMatch(pTHX_ struct Constraint *c, SV *value)
{
  if(!constraint_Str(aTHX_ c, value))
    return false;

  return sv_regexp_match(value, (REGEXP *)c->args[0]);
}

static SV *mk_constraint_StrMatch(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_StrMatch, 1);
  sv_2mortal(ret);

  if(!SvROK(arg0) || !SvRXOK(SvRV(arg0)))
    croak("Require a pre-compiled regexp pattern for StrMatch()");

  c->args[0] = SvREFCNT_inc(SvRV(arg0));

  return ret;
}

static bool constraint_Num(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value))
    return false;

  if(SvROK(value)) {
    SV *rv = SvRV(value);
    if(!SvOBJECT(rv))
      return false;

    if(sv_has_overload(value, numer_amg))
      return true;

    return false;
  }
  else if(SvPOK(value)) {
    if(!looks_like_number(value))
      return false;

    // reject NaN
    if(SvPVX(value)[0] == 'N' || SvPVX(value)[0] == 'n')
      return false;

    return true;
  }
  else {
    // reject NaN
    if(SvNOK(value) && Perl_isnan(SvNV(value)))
      return false;

    return true;
  }
}

enum {
  NUMBOUND_LOWER_INCLUSIVE = (1<<0),
  NUMBOUND_UPPER_INCLUSIVE = (1<<1),
};

static bool constraint_NumBound(pTHX_ struct Constraint *c, SV *value)
{
  /* First off it must be a Num */
  if(!constraint_Num(aTHX_ c, value))
    return false;

  if(c->args[0]) {
    int cmp = sv_numcmp(c->args[0], value);
    if(cmp > 0 || (cmp == 0 && !(c->flags & NUMBOUND_LOWER_INCLUSIVE)))
      return false;
  }

  if(c->args[1]) {
    int cmp = sv_numcmp(value, c->args[1]);
    if(cmp > 0 || (cmp == 0 && !(c->flags & NUMBOUND_UPPER_INCLUSIVE)))
      return false;
  }

  return true;
}

static SV *mk_constraint_NumGT(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumBound, 2);
  sv_2mortal(ret);

  c->args[0] = newSVsv_num(arg0);
  c->args[1] = NULL;

  return ret;
}

static SV *mk_constraint_NumGE(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumBound, 2);
  sv_2mortal(ret);

  c->flags   = NUMBOUND_LOWER_INCLUSIVE;
  c->args[0] = newSVsv_num(arg0);
  c->args[1] = NULL;

  return ret;
}

static SV *mk_constraint_NumLE(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumBound, 2);
  sv_2mortal(ret);

  c->flags   = NUMBOUND_UPPER_INCLUSIVE;
  c->args[0] = NULL;
  c->args[1] = newSVsv_num(arg0);

  return ret;
}

static SV *mk_constraint_NumLT(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumBound, 2);
  sv_2mortal(ret);

  c->args[0] = NULL;
  c->args[1] = newSVsv_num(arg0);

  return ret;
}

static SV *mk_constraint_NumRange(pTHX_ SV *arg0, SV *arg1)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumBound, 2);
  sv_2mortal(ret);

  c->flags   = NUMBOUND_LOWER_INCLUSIVE;
  c->args[0] = newSVsv_num(arg0);
  c->args[1] = newSVsv_num(arg1);

  return ret;
}

static bool constraint_NumEq(pTHX_ struct Constraint *c, SV *value)
{
  if(!constraint_Num(aTHX_ c, value))
    return false;

  SV *nums = c->args[0];
  if(SvTYPE(nums) != SVt_PVAV)
    return sv_numcmp(value, nums) == 0;

  /* TODO: If we were to sort the values initially we could binary-search
   * these much faster
   */
  size_t n = av_count((AV *)nums);
  SV **svp = AvARRAY(nums);
  for(size_t i = 0; i < n; i++)
    if(sv_numcmp(value, svp[i]) == 0)
      return true;

  return false;
}

static SV *mk_constraint_NumEq(pTHX_ size_t nargs, SV **args)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumEq, 1);
  sv_2mortal(ret);

  if(!nargs)
    croak("Require at least one number for NumEq()");

  if(nargs == 1)
    /* We can just store a single number directly */
    c->args[0] = newSVsv_num(args[0]);
  else {
    AV *nums = newAV_alloc_x(nargs);
    for(size_t i = 0; i < nargs; i++)
      av_store(nums, i, newSVsv_num(args[i]));

    c->args[0] = (SV *)nums;
  }

  return ret;
}

static bool constraint_Isa(pTHX_ struct Constraint *c, SV *value)
{
  return sv_isa_sv(value, c->args[0]);
}

static SV *mk_constraint_Isa(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_Isa, 1);

  c->args[0] = newSVsv(arg0);

  return sv_2mortal(ret);
}

static bool constraint_Can(pTHX_ struct Constraint *c, SV *value)
{
  HV *stash;
  if(SvROK(value) && SvOBJECT(SvRV(value)))
    stash = SvSTASH(SvRV(value));
  else if(SvOK(value)) {
    stash = gv_stashsv(value, GV_NOADD_NOINIT);
    if(!stash)
      return false;
  }
  else
    return false;

  /* TODO: we could cache which classes do or don't satisfy the constraints
   * and store it somewhere, maybe in an HV in ->args[1] or somesuch */

  SV *methods = c->args[0];
  size_t nmethods = SvTYPE(methods) == SVt_PVAV ? av_count((AV *)methods) : 1;
  for(size_t idx = 0; idx < nmethods; idx++) {
    SV *method = SvTYPE(methods) == SVt_PVAV ? AvARRAY((AV *)methods)[idx] : methods;
    if(!gv_fetchmeth_sv(stash, method,
#ifdef HAVE_FETCHMETH_SUPER_NOCACHE
          -1,
#else
          0,
#endif
          0))
      return false;
  }

  return true;
}

static SV *mk_constraint_Can(pTHX_ size_t nargs, SV **args)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_Can, 1);
  sv_2mortal(ret);

  if(!nargs)
    croak("Require at least one method name for Can()");

  if(nargs == 1)
    /* We can just store a single string directly */
    c->args[0] = newSVsv_str(args[0]);
  else {
    AV *strs = newAV_alloc_x(nargs);
    for(size_t i = 0; i < nargs; i++)
      av_store(strs, i, newSVsv_str(args[i]));

    c->args[0] = (SV *)strs;
  }

  return ret;
}

static bool constraint_ArrayRef(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value) || !SvROK(value))
    return false;

  SV *rv = SvRV(value);

  if(!SvOBJECT(rv))
    /* plain ref */
    return SvTYPE(rv) == SVt_PVAV;
  else
    return sv_has_overload(value, to_av_amg);
}

static bool constraint_HashRef(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value) || !SvROK(value))
    return false;

  SV *rv = SvRV(value);

  if(!SvOBJECT(rv))
    /* plain ref */
    return SvTYPE(rv) == SVt_PVHV;
  else
    return sv_has_overload(value, to_hv_amg);
}

static bool constraint_Callable(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value) || !SvROK(value))
    return false;

  SV *rv = SvRV(value);

  if(!SvOBJECT(rv))
    /* plain ref */
    return SvTYPE(rv) == SVt_PVCV;
  else
    return sv_has_overload(value, to_cv_amg);
}

static bool constraint_Maybe(pTHX_ struct Constraint *c, SV *value)
{
  if(!SvOK(value))
    return true;

  struct Constraint *inner = (struct Constraint *)SvPVX(c->args[0]);
  return (*inner->func)(aTHX_ inner, value);
}

static SV *mk_constraint_Maybe(pTHX_ SV *arg0)
{
  SV *inner = extract_constraint(arg0);

  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_Maybe, 1);
  sv_2mortal(ret);

  c->args[0] = SvREFCNT_inc(inner);

  return ret;
}

static bool constraint_Any(pTHX_ struct Constraint *c, SV *value)
{
  AV *inners = (AV *)c->args[0];
  SV **innersvs = AvARRAY(inners);
  size_t n = av_count(inners);

  for(size_t i = 0; i < n; i++) {
    struct Constraint *inner = (struct Constraint *)SvPVX(innersvs[i]);
    if((*inner->func)(aTHX_ inner, value))
      return true;
  }

  return false;
}

static SV *mk_constraint_Any(pTHX_ size_t nargs, SV **args)
{
  if(!nargs)
    croak("Any() requires at least one inner constraint");
  if(nargs == 1)
    return args[0];

  AV *inners = newAV();
  sv_2mortal((SV *)inners); // in case of croak during construction

  for(size_t i = 0; i < nargs; i++) {
    SV *innersv = extract_constraint(args[i]);
    struct Constraint *inner = (struct Constraint *)SvPVX(innersv);

    if(inner->func == &constraint_Any) {
      AV *kidav = (AV *)inner->args[0];
      size_t nkids = av_count(kidav);
      for(size_t kidi = 0; kidi < nkids; kidi++) {
        av_push(inners, SvREFCNT_inc(AvARRAY(kidav)[kidi]));
      }
    }
    else
      av_push(inners, SvREFCNT_inc(innersv));
  }

  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_Any, 1);
  sv_2mortal(ret);

  c->args[0] = SvREFCNT_inc(inners);

  return ret;
}

static bool constraint_All(pTHX_ struct Constraint *c, SV *value)
{
  AV *inners = (AV *)c->args[0];
  if(!inners)
    return true;

  SV **innersvs = AvARRAY(inners);
  size_t n = av_count(inners);

  for(size_t i = 0; i < n; i++) {
    struct Constraint *inner = (struct Constraint *)SvPVX(innersvs[i]);
    if(!(*inner->func)(aTHX_ inner, value))
      return false;
  }

  return true;
}

static SV *mk_constraint_All(pTHX_ size_t nargs, SV **args)
{
  /* nargs == 0 is valid */
  if(nargs == 1)
    return args[0];

  AV *inners = NULL;
  if(nargs) {
    inners = newAV();
    sv_2mortal((SV *)inners); // in case of croak during construction

    /* However many NumBound constraints are in 'inners' it's always possible to
     * optimise them down into just one
     */
    struct Constraint *all_nums = NULL;
    SV *all_nums_sv;

    for(size_t i = 0; i < nargs; i++) {
      SV *innersv = extract_constraint(args[i]);
      struct Constraint *inner = (struct Constraint *)SvPVX(innersv);

      if(inner->func == &constraint_All) {
        AV *kidav = (AV *)inner->args[0];
        size_t nkids = av_count(kidav);
        for(size_t kidi = 0; kidi < nkids; kidi++) {
          av_push(inners, SvREFCNT_inc(AvARRAY(kidav)[kidi]));
        }
      }
      else if(inner->func == &constraint_NumBound) {
        if(!all_nums) {
          alloc_constraint(&all_nums_sv, &all_nums, &constraint_NumBound, 2);
          av_push(inners, SvRV(all_nums_sv)); /* no SvREFCNT_inc() */
        }
        SV *innerL = inner->args[0],
           *innerU = inner->args[1];

        int cmp;

        if(innerL) {
          if(!all_nums->args[0] || (cmp = sv_numcmp(all_nums->args[0], innerL)) < 0) {
            SvREFCNT_dec(all_nums->args[0]);
            all_nums->args[0] = newSVsv_num(innerL);
            all_nums->flags = (all_nums->flags & ~NUMBOUND_LOWER_INCLUSIVE)
                              | (inner->flags & NUMBOUND_LOWER_INCLUSIVE);
          }
          else if(cmp == 0 && !(inner->flags & NUMBOUND_LOWER_INCLUSIVE))
            all_nums->flags &= ~NUMBOUND_LOWER_INCLUSIVE;
        }
        if(innerU) {
          if(!all_nums->args[1] || (cmp = sv_numcmp(all_nums->args[1], innerU)) > 0) {
            SvREFCNT_dec(all_nums->args[1]);
            all_nums->args[1] = newSVsv_num(innerU);
            all_nums->flags = (all_nums->flags & ~NUMBOUND_UPPER_INCLUSIVE)
                              | (inner->flags & NUMBOUND_UPPER_INCLUSIVE);
          }
          else if(cmp == 0 && !(inner->flags & NUMBOUND_UPPER_INCLUSIVE))
            all_nums->flags &= ~NUMBOUND_UPPER_INCLUSIVE;
        }
      }
      else
        av_push(inners, SvREFCNT_inc(innersv));
    }

    /* it's possible we've now squashed all the Num* bounds into a single one
     * and nothing else is left */
    if(all_nums_sv && av_count(inners) == 1)
      return all_nums_sv;
  }

  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_All, 1);
  sv_2mortal(ret);

  c->args[0] = SvREFCNT_inc(inners);

  return ret;
}

#define MAKE_0ARG_CONSTRAINT(name)   S_make_0arg_constraint(aTHX_ #name, &constraint_##name)
static void S_make_0arg_constraint(pTHX_ const char *name, ConstraintFunc *func)
{
  HV *stash = gv_stashpvs("Data::Checks", GV_ADD);
  AV *exportok = get_av("Data::Checks::EXPORT_OK", GV_ADD);

  SV *namesv = newSVpvf("Data::Checks::%s", name);

  /* Before perl 5.38, XSUBs cannot be exported lexically. newCONSTSUB() makes
   * XSUBs. We'll have to build our own constant-value sub instead
   */

  I32 floor_ix = start_subparse(FALSE, 0);

  SV *sv;
  struct Constraint *constraint;
  alloc_constraint(&sv, &constraint, func, 0);

  OP *body = make_argcheck_ops(0, 0, 0, namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL,
      newSVOP(OP_CONST, 0, sv)));

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);
  cv_set_call_checker(cv, &ckcall_constfold, &PL_sv_undef);

  av_push(exportok, newSVpv(name, 0));
}

static XOP xop_make_constraint;
static OP *pp_make_constraint(pTHX)
{
  dSP;
  int nargs = PL_op->op_private;

  SV *ret;
  switch(nargs) {
    case 1:
    {
      SV *(*mk_constraint)(pTHX_ SV *arg0) =
        (SV * (*)(pTHX_ SV *))cUNOP_AUX->op_aux;

      SV *arg0 = POPs;

      ret = (*mk_constraint)(aTHX_ arg0);
      break;
    }

    case 2:
    {
      SV *(*mk_constraint)(pTHX_ SV *arg0, SV *arg1) =
        (SV * (*)(pTHX_ SV *, SV *))cUNOP_AUX->op_aux;

      SV *arg1 = POPs;
      SV *arg0 = POPs;

      ret = (*mk_constraint)(aTHX_ arg0, arg1);
      break;
    }

    case (U8)-1:
    {
      SV *(*mk_constraint)(pTHX_ size_t nargs, SV **args) =
        (SV * (*)(pTHX_ size_t, SV **))cUNOP_AUX->op_aux;

      SV **svp = PL_stack_base + POPMARK + 1;
      size_t nargs = SP - svp + 1;
      SP -= nargs;

      if(!nargs)
        EXTEND(SP, 1);

      ret = (*mk_constraint)(aTHX_ nargs, svp);
      break;
    }

    default:
      croak("ARGH unreachable nargs=%d", nargs);
  }

  PUSHs(ret);

  RETURN;
}

#define MAKE_1ARG_CONSTRAINT(name)  S_make_1arg_constraint(aTHX_ #name, &mk_constraint_##name)
static void S_make_1arg_constraint(pTHX_ const char *name, SV *(*mk_constraint)(pTHX_ SV *arg0))
{
  HV *stash = gv_stashpvs("Data::Checks", GV_ADD);
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);
  AV *exportok = get_av("Data::Checks::EXPORT_OK", GV_ADD);

  SV *namesv = newSVpvf("Data::Checks::%s", name);

  I32 floor_ix = start_subparse(FALSE, 0);

  OP *mkop = newUNOP_AUX_CUSTOM(&pp_make_constraint, 0,
        newSLUGOP(0),
        (UNOP_AUX_item *)mk_constraint);
  mkop->op_private = 1;

  OP *body = make_argcheck_ops(1, 0, 0, namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL, mkop));

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);
  cv_set_call_checker(cv, &ckcall_constfold, &PL_sv_undef);

  av_push(exportok, newSVpv(name, 0));
}

#define MAKE_2ARG_CONSTRAINT(name)  S_make_2arg_constraint(aTHX_ #name, &mk_constraint_##name)
static void S_make_2arg_constraint(pTHX_ const char *name, SV *(*mk_constraint)(pTHX_ SV *arg0, SV *arg1))
{
  HV *stash = gv_stashpvs("Data::Checks", GV_ADD);
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);
  AV *exportok = get_av("Data::Checks::EXPORT_OK", GV_ADD);

  SV *namesv = newSVpvf("Data::Checks::%s", name);

  I32 floor_ix = start_subparse(FALSE, 0);

  OP *mkop = newUNOP_AUX_CUSTOM(&pp_make_constraint, 0,
        newLISTOPn(OP_LIST, OPf_WANT_LIST, newSLUGOP(0), newSLUGOP(1), NULL),
        (UNOP_AUX_item *)mk_constraint);
  mkop->op_private = 2;

  OP *body = make_argcheck_ops(2, 0, 0, namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL, mkop));

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);
  cv_set_call_checker(cv, &ckcall_constfold, &PL_sv_undef);

  av_push(exportok, newSVpv(name, 0));
}

#define MAKE_nARG_CONSTRAINT(name)  S_make_narg_constraint(aTHX_ #name, &mk_constraint_##name)
static void S_make_narg_constraint(pTHX_ const char *name, SV *(*mk_constraint)(pTHX_ size_t nargs, SV **args))
{
  HV *stash = gv_stashpvs("Data::Checks", GV_ADD);
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);
  AV *exportok = get_av("Data::Checks::EXPORT_OK", GV_ADD);

  SV *namesv = newSVpvf("Data::Checks::%s", name);

  I32 floor_ix = start_subparse(FALSE, 0);

  OP *mkop = newUNOP_AUX_CUSTOM(&pp_make_constraint, 0,
        op_force_list(newLISTOPn(OP_LIST, OPf_WANT_LIST,
          newUNOP(OP_RV2AV, OPf_WANT_LIST, newGVOP(OP_GV, 0, PL_defgv)),
          NULL)),
        (UNOP_AUX_item *)mk_constraint);
  mkop->op_private = -1;

  OP *body = make_argcheck_ops(0, 0, '@', namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL, mkop));

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);
  cv_set_call_checker(cv, &ckcall_constfold, &PL_sv_undef);

  av_push(exportok, newSVpv(name, 0));
}

/* This does NOT use SVf_quoted as that is intended for C's quoting
 * rules; we want qq()-style perlish ones. This means that $ and @ need to be
 * escaped as well.
 */
#define sv_catsv_quoted(buf, sv, quote)  S_sv_catsv_quoted(aTHX_ buf, sv, quote)
static void S_sv_catsv_quoted(pTHX_ SV *buf, SV *sv, char quote)
{
  STRLEN len;
  const char *s = SvPV_const(sv, len);
  sv_catpvn(buf, &quote, 1);
  for(STRLEN i = 0; i < len; i++) {
    if(len == 256) {
      sv_catpvs(buf, "...");
      break;
    }
    char c = s[i];
    if(c == '\\' || c == quote || (quote != '\'' && (c == '$' || c == '@')))
      sv_catpvs(buf, "\\");
    /* TODO: UTF-8 */
    sv_catpvn(buf, &c, 1);
  }
  sv_catpvn(buf, &quote, 1);
}

#define sv_catsv_quoted_list(buf, av, quote, sep)  S_sv_catsv_quoted_list(aTHX_ buf, av, quote, sep)
static void S_sv_catsv_quoted_list(pTHX_ SV *buf, AV *av, char quote, char sep)
{
  U32 n = av_count(av);
  SV **vals = AvARRAY(av);
  for(U32 i = 0; i < n; i++) {
    if(i > 0)
      sv_catpvn(buf, &sep, 1), sv_catpvs(buf, " ");
    sv_catsv_quoted(buf, vals[i], quote);
  }
}

SV *DataChecks_stringify_constraint(pTHX_ struct Constraint *c)
{
  const char *name = NULL;
  SV *args = sv_2mortal(newSVpvn("", 0));

  /* such a shame C doesn't let us use function addresses as case labels */

  // 0arg
  if     (c->func == &constraint_Defined)
    name = "Defined";
  else if(c->func == &constraint_Object)
    name = "Object";
  else if(c->func == &constraint_ArrayRef)
    name = "ArrayRef";
  else if(c->func == &constraint_HashRef)
    name = "HashRef";
  else if(c->func == &constraint_Callable)
    name = "Callable";
  else if(c->func == &constraint_Num)
    name = "Num";
  else if(c->func == &constraint_Str)
    name = "Str";
  // 1arg
  else if(c->func == &constraint_Isa) {
    name = "Isa";
    sv_catsv_quoted(args, c->args[0], '"');
  }
  else if(c->func == &constraint_StrMatch) {
    name = "StrMatch";
    sv_catpvs(args, "qr");
    sv_catsv_quoted(args, c->args[0], '/');
  }
  else if(c->func == &constraint_Maybe) {
    name = "Maybe";
    args = stringify_constraint_sv(c->args[0]);
  }
  // 2arg
  else if(c->func == &constraint_NumBound) {
    if(!c->args[0])
      name = (c->flags & NUMBOUND_UPPER_INCLUSIVE ) ? "NumLE" : "NumLT";
    else if(!c->args[1])
      name = (c->flags & NUMBOUND_LOWER_INCLUSIVE ) ? "NumGE" : "NumGT";
    else if(c->flags == NUMBOUND_LOWER_INCLUSIVE)
      name = "NumRange";
    else {
      /* This was optimised from an All() call on at least two different ones;
       * we'll have to just stringify it as best we can
       */
      name = "All";
      sv_catpvf(args, "NumG%c(%" SVf "), NumL%c(%" SVf ")",
          (c->flags & NUMBOUND_LOWER_INCLUSIVE) ? 'E' : 'T', SVfARG(c->args[0]),
          (c->flags & NUMBOUND_UPPER_INCLUSIVE) ? 'E' : 'T', SVfARG(c->args[1]));
    }

    if(!SvCUR(args)) {
      if(c->args[0])
        sv_catsv(args, c->args[0]);
      if(c->args[0] && c->args[1])
        sv_catpvs(args, ", ");
      if(c->args[1])
        sv_catsv(args, c->args[1]);
    }
  }
  // narg
  else if(c->func == &constraint_NumEq) {
    name = "NumEq";
    if(SvTYPE(c->args[0]) != SVt_PVAV)
      sv_catsv(args, c->args[0]);
    else {
      U32 n = av_count((AV *)c->args[0]);
      SV **vals = AvARRAY(c->args[0]);
      for(U32 i = 0; i < n; i++) {
        if(i > 0)
          sv_catpvs(args, ", ");
        sv_catsv(args, vals[i]);
      }
    }
  }
  else if(c->func == &constraint_StrEq) {
    name = "StrEq";
    if(SvTYPE(c->args[0]) == SVt_PVAV)
      sv_catsv_quoted_list(args, (AV *)c->args[0], '"', ',');
    else
      sv_catsv_quoted(args, c->args[0], '"');
  }
  else if(c->func == &constraint_Can) {
    name = "Can";
    if(SvTYPE(c->args[0]) == SVt_PVAV)
      sv_catsv_quoted_list(args, (AV *)c->args[0], '"', ',');
    else
      sv_catsv_quoted(args, c->args[0], '"');
  }
  else if(c->func == &constraint_Any || c->func == &constraint_All) {
    name = (c->func == &constraint_Any) ? "Any" : "All";
    if(c->args[0]) {
      U32 n = av_count((AV *)c->args[0]);
      SV **inners = AvARRAY(c->args[0]);
      for(U32 i = 0; i < n; i++) {
        if(i > 0)
          sv_catpvs(args, ", ");
        sv_catsv(args, stringify_constraint_sv(inners[i]));
      }
    }
  }

  else
    return newSVpvs_flags("TODO: debug inspect constraint", SVs_TEMP);

  SV *ret = newSVpvf("%s", name);
  if(SvCUR(args))
    sv_catpvf(ret, "(%" SVf ")", SVfARG(args));

  return sv_2mortal(ret);
}

void boot_Data_Checks__constraints(pTHX)
{
  MAKE_0ARG_CONSTRAINT(Defined);
  MAKE_0ARG_CONSTRAINT(Object);
  MAKE_0ARG_CONSTRAINT(Str);
  MAKE_0ARG_CONSTRAINT(Num);

  MAKE_nARG_CONSTRAINT(StrEq);
  MAKE_1ARG_CONSTRAINT(StrMatch);

  MAKE_1ARG_CONSTRAINT(NumGT);
  MAKE_1ARG_CONSTRAINT(NumGE);
  MAKE_1ARG_CONSTRAINT(NumLE);
  MAKE_1ARG_CONSTRAINT(NumLT);
  MAKE_2ARG_CONSTRAINT(NumRange);
  MAKE_nARG_CONSTRAINT(NumEq);

  MAKE_1ARG_CONSTRAINT(Isa);
  MAKE_nARG_CONSTRAINT(Can);
  MAKE_0ARG_CONSTRAINT(ArrayRef);
  MAKE_0ARG_CONSTRAINT(HashRef);
  MAKE_0ARG_CONSTRAINT(Callable);
  MAKE_1ARG_CONSTRAINT(Maybe);
  MAKE_nARG_CONSTRAINT(Any);
  MAKE_nARG_CONSTRAINT(All);

  XopENTRY_set(&xop_make_constraint, xop_name, "make_constraint");
  XopENTRY_set(&xop_make_constraint, xop_desc, "make constraint");
  XopENTRY_set(&xop_make_constraint, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_make_constraint, &xop_make_constraint);
}
