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

struct DataChecks_Checker {
  CV *cv;
  bool (*func)(pTHX_ SV *value);
  SV *arg0;
  SV *assertmess;
};

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "make_argcheck_ops.c.inc"
#include "optree-additions.c.inc"

static struct DataChecks_Checker *S_DataChecks_make_checkdata(pTHX_ SV *checkspec)
{
  HV *stash = NULL;
  CV *checkcv = NULL;
  bool (*checkfunc)(pTHX_ SV *value) = NULL;

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
    checkfunc = (bool (*)(pTHX_ SV *))SvUV(SvRV(checkspec));
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
    .cv   = checkcv,
    .func = checkfunc,
    .arg0 = SvREFCNT_inc(checkspec),
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
  bool (*func)(pTHX_ SV *value) = (bool (*)(pTHX_ SV *value))cUNOP_AUX->op_aux;
  SV *value = POPs;

  PUSHs(boolSV((*func)(aTHX_ value)));

  RETURN;
}

#define make_checkop(checker, argop)  S_DataChecks_make_checkop(aTHX_ checker, argop)
static OP *S_DataChecks_make_checkop(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  if(checker->func) {
    OP *o = newUNOP_AUX(OP_CUSTOM, OPf_WANT_SCALAR, argop, (UNOP_AUX_item *)checker->func);
    o->op_ppaddr = &pp_invoke_checkfunc;
    return o;
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
  if(checker->func) {
    return (*checker->func)(aTHX_ value);
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

static bool constraint_Defined(pTHX_ SV *value)
{
  return SvOK(value);
}

static bool constraint_Object(pTHX_ SV *value)
{
  return SvROK(value) && SvOBJECT(SvRV(value));
}

static bool constraint_Str(pTHX_ SV *value)
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

static bool constraint_Num(pTHX_ SV *value)
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

static void S_make_constraint(pTHX_ const char *name, bool (*func)(pTHX_ SV *value))
{
  HV *stash = gv_stashpvs("Data::Checks", GV_ADD);
  HV *constraint_stash = gv_stashpvs("Data::Checks::Constraint", GV_ADD);
  AV *exportok = get_av("Data::Checks::EXPORT_OK", GV_ADD);

  SV *namesv = newSVpvf("Data::Checks::%s", name);

  /* Before perl 5.38, XSUBs cannot be exported lexically. newCONSTSUB() makes
   * XSUBs. We'll have to build our own constant-value sub instead
   */

  I32 floor_ix = start_subparse(FALSE, 0);

  SV *constval =
    sv_bless(newRV_noinc(newSVuv(PTR2UV(func))), constraint_stash);

  OP *body = make_argcheck_ops(0, 0, 0, namesv);
  body = op_append_elem(OP_LINESEQ,
    body,
    newSTATEOP(0, NULL,
      newSVOP(OP_CONST, 0, constval)));

  newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, namesv), NULL, NULL, body);

  av_push(exportok, newSVpv(name, 0));
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
#define MAKE_CONSTRAINT(name)   S_make_constraint(aTHX_ #name, &constraint_##name)

  MAKE_CONSTRAINT(Defined);
  MAKE_CONSTRAINT(Object);
  MAKE_CONSTRAINT(Str);
  MAKE_CONSTRAINT(Num);
