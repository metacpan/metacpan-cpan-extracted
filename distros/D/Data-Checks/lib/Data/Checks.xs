/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_DATA_CHECKS_IMPL
#include "DataChecks.h"

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

struct Constraint;

typedef bool ConstraintFunc(pTHX_ struct Constraint *c, SV *value);

struct Constraint
{
  ConstraintFunc *func;
  int flags; /* avoids needing an entire SV just for a few numeric flag bits */
  size_t n;
  SV *args[0];
};

#define alloc_constraint(svp, constraintp, func, n)  S_alloc_constraint(aTHX_ svp, constraintp, func, n)
static void S_alloc_constraint(pTHX_ SV **svp, struct Constraint **constraintp, ConstraintFunc *func, size_t n)
{
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);

  SV *sv = newSV(sizeof(struct Constraint) + 1*sizeof(SV *));
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

struct DataChecks_Checker
{
  CV *cv;
  struct Constraint *constraint;
  SV *arg0;
  SV *assertmess;
};

#include "perl-backcompat.c.inc"

#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "optree-additions.c.inc"
#include "sv_streq.c.inc"
#include "sv_numcmp.c.inc"

#include "ckcall_constfold.c.inc"

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

static struct DataChecks_Checker *S_DataChecks_make_checkdata(pTHX_ SV *checkspec)
{
  HV *stash = NULL;
  CV *checkcv = NULL;
  struct Constraint *constraint = NULL;

  if(SvROK(checkspec) && SvOBJECT(SvRV(checkspec)))
    stash = SvSTASH(SvRV(checkspec));
  else if(SvPOK(checkspec) && (stash = gv_stashsv(checkspec, GV_NOADD_NOINIT)))
    ; /* checkspec is package name */
  else if(SvROK(checkspec) && !SvOBJECT(SvRV(checkspec)) && SvTYPE(SvRV(checkspec)) == SVt_PVCV) {
    checkcv = (CV *)SvREFCNT_inc(SvRV(checkspec));
    checkspec = NULL;
  }
  else
    croak("Expected the checker expression to yield an object or code reference or package name; got %" SVf " instead",
      SVfARG(checkspec));

  if(stash && sv_isa(checkspec, "Data::Checks::Constraint")) {
    constraint = (struct Constraint *)SvPVX(SvRV(checkspec));
    /* arg0 will store checkspec pointer, thus ensuring this SV is retained */
  }
  else if(!checkcv) {
    GV *methgv;
    if(!(methgv = gv_fetchmeth_pv(stash, "check", -1, 0)))
      croak("Expected that the checker expression can ->check");
    if(!GvCV(methgv))
      croak("Expected that methgv has a GvCV");
    checkcv = (CV *)SvREFCNT_inc(GvCV(methgv));
  }

  struct DataChecks_Checker *checker;
  Newx(checker, 1, struct DataChecks_Checker);

  *checker = (struct DataChecks_Checker){
    .cv         = checkcv,
    .constraint = constraint,
    .arg0       = SvREFCNT_inc(checkspec),
  };

  return checker;
}

static void S_DataChecks_free_checkdata(pTHX_ struct DataChecks_Checker *checker)
{
  if(checker->assertmess)
    SvREFCNT_dec(checker->assertmess);

  SvREFCNT_dec(checker->cv);

  if(checker->arg0)
    SvREFCNT_dec(checker->arg0);

  Safefree(checker);
}

static void S_DataChecks_gen_assertmess(pTHX_ struct DataChecks_Checker *checker, SV *name, SV *constraint)
{
  checker->assertmess = newSVpvf("%" SVf " requires a value satisfying %" SVf,
      SVfARG(name), SVfARG(constraint));
}

static XOP xop_invoke_checkfunc;
static OP *pp_invoke_checkfunc(pTHX)
{
  dSP;
  struct Constraint *constraint = (struct Constraint *)cUNOP_AUX->op_aux;
  SV *value = POPs;

  PUSHs(boolSV((*constraint->func)(aTHX_ constraint, value)));

  RETURN;
}

#define make_checkop(checker, argop)  S_DataChecks_make_checkop(aTHX_ checker, argop)
static OP *S_DataChecks_make_checkop(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  if(checker->constraint) {
    return newUNOP_AUX_CUSTOM(&pp_invoke_checkfunc, OPf_WANT_SCALAR,
      argop,
      (UNOP_AUX_item *)checker->constraint);
  }

  if(checker->cv && checker->arg0)
    /* checkcv($checker, ARGOP) ... */
    return newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->arg0)),
      argop,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->cv)),
      NULL);

  if(checker->cv)
    /* checkcv(ARGOP) ... */
    return newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
      argop,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->cv)),
      NULL);

  croak("ARGH unsure how to make checkop");
}

static OP *S_DataChecks_make_assertop(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  return newLOGOP(OP_OR, 0,
    make_checkop(checker, argop),
    /* ... or die MESSAGE */
    newLISTOPn(OP_DIE, 0,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->assertmess)),
      NULL));
}

static bool S_DataChecks_check_value(pTHX_ struct DataChecks_Checker *checker, SV *value)
{
  if(checker->constraint) {
    return (*checker->constraint->func)(aTHX_ checker->constraint, value);
  }

  dSP;

  ENTER;
  SAVETMPS;

  EXTEND(SP, 2);
  PUSHMARK(SP);
  if(checker->arg0)
    PUSHs(sv_mortalcopy(checker->arg0));
  PUSHs(value); /* Yes we're pushing the SV itself */
  PUTBACK;

  call_sv((SV *)checker->cv, G_SCALAR);

  SPAGAIN;

  bool ok = SvTRUEx(POPs);

  PUTBACK;

  FREETMPS;
  LEAVE;

  return ok;
}

static void S_DataChecks_assert_value(pTHX_ struct DataChecks_Checker *checker, SV *value)
{
  if(check_value(checker, value))
    return;

  croak_sv(checker->assertmess);
}

/* Constraints */

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
  else {
    if(!SvPOK(value))
      return true;

    if(looks_like_number(value))
      return true;

    return false;
  }
}

enum {
  NUMRANGE_LOWER_INCLUSIVE = (1<<0),
  NUMRANGE_UPPER_INCLUSIVE = (1<<1),
};

static bool constraint_NumRange(pTHX_ struct Constraint *c, SV *value)
{
  /* First off it must be a Num */
  if(!constraint_Num(aTHX_ c, value))
    return false;

  if(c->args[0]) {
    int cmp = sv_numcmp(c->args[0], value);
    if(cmp > 0 || (cmp == 0 && !(c->flags & NUMRANGE_LOWER_INCLUSIVE)))
      return false;
  }

  if(c->args[1]) {
    int cmp = sv_numcmp(value, c->args[1]);
    if(cmp > 0 || (cmp == 0 && !(c->flags & NUMRANGE_UPPER_INCLUSIVE)))
      return false;
  }

  return true;
}

static SV *mk_constraint_NumGT(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumRange, 2);
  sv_2mortal(ret);

  c->args[0] = newSVsv_num(arg0);
  c->args[1] = NULL;

  return ret;
}

static SV *mk_constraint_NumGE(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumRange, 2);
  sv_2mortal(ret);

  c->flags   = NUMRANGE_LOWER_INCLUSIVE;
  c->args[0] = newSVsv_num(arg0);
  c->args[1] = NULL;

  return ret;
}

static SV *mk_constraint_NumLE(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumRange, 2);
  sv_2mortal(ret);

  c->flags   = NUMRANGE_UPPER_INCLUSIVE;
  c->args[0] = NULL;
  c->args[1] = newSVsv_num(arg0);

  return ret;
}

static SV *mk_constraint_NumLT(pTHX_ SV *arg0)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumRange, 2);
  sv_2mortal(ret);

  c->args[0] = NULL;
  c->args[1] = newSVsv_num(arg0);

  return ret;
}

static SV *mk_constraint_NumRange(pTHX_ SV *arg0, SV *arg1)
{
  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_NumRange, 2);
  sv_2mortal(ret);

  c->flags   = NUMRANGE_LOWER_INCLUSIVE;
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
  if(!sv_isa(arg0, "Data::Checks::Constraint"))
    croak("Expected a Constraint instance as argument to Maybe()");

  SV *ret;
  struct Constraint *c;
  alloc_constraint(&ret, &c, &constraint_Maybe, 1);
  sv_2mortal(ret);

  /* Unwrap the RV */
  c->args[0] = SvREFCNT_inc(SvRV(arg0));

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

MODULE = Data::Checks    PACKAGE = Data::Checks::Constraint

void DESTROY(SV *self)
  CODE:
  {
    struct Constraint *c = (struct Constraint *)SvPVX(SvRV(self));
    for(int i = c->n - 1; i >= 0; i--)
      SvREFCNT_dec(c->args[i]);
  }

MODULE = Data::Checks    PACKAGE = Data::Checks

BOOT:
  sv_setiv(*hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MIN", GV_ADD), 0);
  sv_setiv(*hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MAX", GV_ADD), DATACHECKS_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/make_checkdata()@0", GV_ADD),
    PTR2UV(&S_DataChecks_make_checkdata));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/free_checkdata()@0", GV_ADD),
    PTR2UV(&S_DataChecks_free_checkdata));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/gen_assertmess()@0", GV_ADD),
    PTR2UV(&S_DataChecks_gen_assertmess));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/make_assertop()@0", GV_ADD),
    PTR2UV(&S_DataChecks_make_assertop));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/check_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_check_value));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/assert_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_assert_value));

  MAKE_0ARG_CONSTRAINT(Defined);
  MAKE_0ARG_CONSTRAINT(Object);
  MAKE_0ARG_CONSTRAINT(Str);
  MAKE_0ARG_CONSTRAINT(Num);

  MAKE_nARG_CONSTRAINT(StrEq);

  MAKE_1ARG_CONSTRAINT(NumGT);
  MAKE_1ARG_CONSTRAINT(NumGE);
  MAKE_1ARG_CONSTRAINT(NumLE);
  MAKE_1ARG_CONSTRAINT(NumLT);
  MAKE_2ARG_CONSTRAINT(NumRange);
  MAKE_nARG_CONSTRAINT(NumEq);

  MAKE_1ARG_CONSTRAINT(Isa);
  MAKE_0ARG_CONSTRAINT(Callable);
  MAKE_1ARG_CONSTRAINT(Maybe);

  XopENTRY_set(&xop_invoke_checkfunc, xop_name, "invoke_checkfunc");
  XopENTRY_set(&xop_invoke_checkfunc, xop_desc, "invoke checkfunc");
  XopENTRY_set(&xop_invoke_checkfunc, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_invoke_checkfunc, &xop_invoke_checkfunc);

  XopENTRY_set(&xop_make_constraint, xop_name, "make_constraint");
  XopENTRY_set(&xop_make_constraint, xop_desc, "make constraint");
  XopENTRY_set(&xop_make_constraint, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_make_constraint, &xop_make_constraint);
