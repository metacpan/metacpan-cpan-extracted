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

/* TODO: migrate this to optree-additions.c.inc */
#define newUNOP_AUX_CUSTOM(func, flags, first, aux)  S_newUNOP_AUX_CUSTOM(aTHX_ func, flags, first, aux)
static OP *S_newUNOP_AUX_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, UNOP_AUX_item *aux)
{
  OP *o = newUNOP_AUX(OP_CUSTOM, flags, first, aux);
  o->op_ppaddr = func;
  return o;
}

struct Constraint;

typedef bool ConstraintFunc(pTHX_ struct Constraint *c, SV *value);

struct Constraint
{
  ConstraintFunc *func;
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

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "make_argcheck_ops.c.inc"
#include "optree-additions.c.inc"

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

#define MAKE_UNIT_CONSTRAINT(name)   S_make_unit_constraint(aTHX_ #name, &constraint_##name)
static void S_make_unit_constraint(pTHX_ const char *name, ConstraintFunc *func)
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

  newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);

  av_push(exportok, newSVpv(name, 0));
}

static OP *pp_make_constraint(pTHX)
{
  dSP;
  SV *(*mk_constraint)(pTHX_ SV *arg0) = (SV * (*)(pTHX_ SV *))cUNOP_AUX->op_aux;

  SV *arg0 = POPs;

  SV *sv = (*mk_constraint)(aTHX_ arg0);

  PUSHs(sv);

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

  OP *body = make_argcheck_ops(1, 0, 0, namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL,
      newUNOP_AUX_CUSTOM(&pp_make_constraint, 0, newSLUGOP(0), (UNOP_AUX_item *)mk_constraint)));


  newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);

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

  MAKE_UNIT_CONSTRAINT(Defined);
  MAKE_UNIT_CONSTRAINT(Object);
  MAKE_UNIT_CONSTRAINT(Str);
  MAKE_UNIT_CONSTRAINT(Num);

  MAKE_1ARG_CONSTRAINT(Isa);
  MAKE_1ARG_CONSTRAINT(Maybe);
