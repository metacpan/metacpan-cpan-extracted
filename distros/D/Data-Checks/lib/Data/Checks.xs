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

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "optree-additions.c.inc"

static struct DataChecks_Checker *S_DataChecks_make_checkdata(pTHX_ SV *checkspec)
{
  HV *stash = NULL;
  CV *checkcv = NULL;

  if(SvROK(checkspec) && SvOBJECT(SvRV(checkspec)))
    stash = SvSTASH(SvRV(checkspec));
  else if(SvPOK(checkspec) && (stash = gv_stashsv(checkspec, GV_NOADD_NOINIT)))
    ; /* checkspec is package name */
  else if(SvROK(checkspec) && !SvOBJECT(SvRV(checkspec)) && SvTYPE(SvRV(checkspec)) == SVt_PVCV) {
    checkcv = (CV *)SvREFCNT_inc(SvRV(checkspec));
    SvREFCNT_dec(checkspec);
    checkspec = NULL;
  }
  else
    croak("Expected the checker expression to yield an object or code reference or package name; got %" SVf " instead",
      SVfARG(checkspec));

  if(!checkcv) {
    GV *methgv;
    if(!(methgv = gv_fetchmeth_pv(stash, "check", -1, 0)))
      croak("Expected that the checker expression can ->check");
    if(!GvCV(methgv))
      croak("Expected that methgv has a GvCV");
    checkcv = (CV *)SvREFCNT_inc(GvCV(methgv));
  }

  struct DataChecks_Checker *checker;
  Newx(checker, 1, struct DataChecks_Checker);

  checker->obj = checkspec;
  checker->cv  = checkcv;

  return checker;
}

static OP *S_DataChecks_make_assertop(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  OP *checkop = checker->obj
    ? /* checkcv($checker, ARGOP) ... */
      newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->obj)),
        argop,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->cv)),
        NULL)
    : /* checkcv(ARGOP) ... */
      newLISTOPn(OP_ENTERSUB, OPf_WANT_SCALAR|OPf_STACKED,
        argop,
        newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->cv)),
        NULL);

  return newLOGOP(OP_OR, 0,
    checkop,
    /* ... or die MESSAGE */
    newLISTOPn(OP_DIE, 0,
      newSVOP(OP_CONST, 0, SvREFCNT_inc(checker->assertmess)),
      NULL));
}

static bool S_DataChecks_check_value(pTHX_ struct DataChecks_Checker *checker, SV *value)
{
  dSP;

  ENTER;
  SAVETMPS;

  EXTEND(SP, 2);
  PUSHMARK(SP);
  if(checker->obj)
    PUSHs(sv_mortalcopy(checker->obj));
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

MODULE = Data::Checks    PACKAGE = Data::Checks

BOOT:
  sv_setiv(*hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MIN", GV_ADD), 0);
  sv_setiv(*hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MAX", GV_ADD), DATACHECKS_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/make_checkdata()@0", GV_ADD),
    PTR2UV(&S_DataChecks_make_checkdata));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/make_assertop()@0", GV_ADD),
    PTR2UV(&S_DataChecks_make_assertop));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/check_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_check_value));
  sv_setuv(*hv_fetchs(PL_modglobal, "Data::Checks/assert_value()@0", GV_ADD),
    PTR2UV(&S_DataChecks_assert_value));
