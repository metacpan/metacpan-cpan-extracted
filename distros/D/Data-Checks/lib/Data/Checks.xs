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

struct DataChecks_Checker
{
  CV *cv;
  struct Constraint *constraint;
  SV *arg0;
  SV *assertmess;
};

#include "perl-backcompat.c.inc"

#include "newOP_CUSTOM.c.inc"
#include "optree-additions.c.inc"

#include "constraints.h"

#define warn_deprecated(...)  Perl_ck_warner(aTHX_ packWARN(WARN_DEPRECATED), __VA_ARGS__)

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
    /* checkspec is a code reference */
    warn_deprecated("Using a CODE reference as a constraint checker is deprecated");
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
  if(!constraint || !SvOK(constraint)) {
    if(checker->constraint)
      constraint = stringify_constraint(checker->constraint);
    else if(checker->arg0) {
      constraint = sv_newmortal();
      sv_copypv(constraint, checker->arg0);
    }
    else
      croak("gen_assertmess requires a constraint name if the constraint is a CODE reference");
  }
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

static OP *S_DataChecks_make_assertop(pTHX_ struct DataChecks_Checker *checker, U32 flags, OP *argop)
{
  U32 want = flags & OPf_WANT; flags &= ~OPf_WANT;
  bool want_void = (want == OPf_WANT_VOID);

  if(flags)
    croak("TODO: make_assertop with flags 0x%x", flags);

  OP *o = newLOGOP(OP_OR, 0,
    make_checkop(checker, argop),
    /* ... or die MESSAGE */
    newLISTOPn(OP_DIE, 0,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->assertmess)),
      NULL));

  if(want_void) {
    /* Wrap it in a full enter/leave pair so it unstacks correctly */
    o->op_flags |= OPf_PARENS;
    o = op_contextualize(op_scope(o), OPf_WANT_VOID);
  }

  return o;
}

static OP *S_DataChecks_make_assertop_v0(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  return S_DataChecks_make_assertop(aTHX_ checker, 0, argop);
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

MODULE = Data::Checks    PACKAGE = Data::Checks::Debug

void stringify_constraint(SV *sv)
  PPCODE:
    /* Prevent XSUB from double-mortalising it */
    PUSHs(stringify_constraint_sv(extract_constraint(sv)));
    XSRETURN(1);

MODULE = Data::Checks    PACKAGE = Data::Checks::Constraint

void DESTROY(SV *self)
  CODE:
  {
    struct Constraint *c = (struct Constraint *)SvPVX(SvRV(self));
    for(int i = c->n - 1; i >= 0; i--)
      SvREFCNT_dec(c->args[i]);
  }

bool check(SV *self, SV *value)
  CODE:
    struct Constraint *c = (struct Constraint *)SvPVX(SvRV(self));
    RETVAL = (c->func)(aTHX_ c, value);
  OUTPUT:
    RETVAL

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
    PTR2UV(&S_DataChecks_make_assertop_v0));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/make_assertop()@1", GV_ADD),
    PTR2UV(&S_DataChecks_make_assertop));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/check_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_check_value));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/assert_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_assert_value));

  boot_Data_Checks__constraints(aTHX);

  XopENTRY_set(&xop_invoke_checkfunc, xop_name, "invoke_checkfunc");
  XopENTRY_set(&xop_invoke_checkfunc, xop_desc, "invoke checkfunc");
  XopENTRY_set(&xop_invoke_checkfunc, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_invoke_checkfunc, &xop_invoke_checkfunc);
