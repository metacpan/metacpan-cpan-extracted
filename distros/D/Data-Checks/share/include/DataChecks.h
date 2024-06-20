#ifndef __DATA_CHECKS_H__
#define __DATA_CHECKS_H__

#define DATACHECKS_ABI_VERSION 0

struct DataChecks_Checker {
  SV *obj;
  CV *cv;
  SV *assertmess;
};

#define make_checkdata(checkspec)  S_DataChecks_make_checkdata(aTHX_ checkspec)
#ifdef HAVE_DATA_CHECKS_IMPL
static struct DataChecks_Checker *S_DataChecks_make_checkdata(pTHX_ SV *checkspec);
#else
static struct DataChecks_Checker *(*make_checkdata_func)(pTHX_ SV *checkspec);
static struct DataChecks_Checker *S_DataChecks_make_checkdata(pTHX_ SV *checkspec)
{
  if(!make_checkdata_func)
    croak("Must call boot_data_checks() first");

  return (*make_checkdata_func)(aTHX_ checkspec);
}
#endif

#define make_assertop(checker, argop)  S_DataChecks_make_assertop(aTHX_ checker, argop)
#ifdef HAVE_DATA_CHECKS_IMPL
static OP *S_DataChecks_make_assertop(pTHX_ struct DataChecks_Checker *checker, OP *argop);
#else
static OP *(*make_assertop_func)(pTHX_ struct DataChecks_Checker *checker, OP *argop);
static OP *S_DataChecks_make_assertop(pTHX_ struct DataChecks_Checker *checker, OP *argop)
{
  if(!make_assertop_func)
    croak("Must call boot_data_checks() first");

  return (*make_assertop_func)(aTHX_ checker, argop);
}
#endif

#define check_value(checker, value)  S_DataChecks_check_value(aTHX_ checker, value)
#ifdef HAVE_DATA_CHECKS_IMPL
static bool S_DataChecks_check_value(pTHX_ struct DataChecks_Checker *checker, SV *value);
#else
static bool (*check_value_func)(pTHX_ struct DataChecks_Checker *checker, SV *value);
static bool S_DataChecks_check_value(pTHX_ struct DataChecks_Checker *checker, SV *value)
{
  if(!check_value_func)
    croak("Must call boot_data_checks() first");

  return (*check_value_func)(aTHX_ checker, value);
}
#endif

#define assert_value(checker, value)  S_DataChecks_assert_value(aTHX_ checker, value)
#ifdef HAVE_DATA_CHECKS_IMPL
static void S_DataChecks_assert_value(pTHX_ struct DataChecks_Checker *checker, SV *value);
#else
static void (*assert_value_func)(pTHX_ struct DataChecks_Checker *checker, SV *value);
static void S_DataChecks_assert_value(pTHX_ struct DataChecks_Checker *checker, SV *value)
{
  if(!assert_value_func)
    croak("Must call boot_data_checks() first");

  return (*assert_value_func)(aTHX_ checker, value);
}
#endif

#ifndef HAVE_DATA_CHECKS_IMPL

#define boot_data_checks(ver) S_boot_data_checks(aTHX_ ver)
static void S_boot_data_checks(pTHX_ double ver) {
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Data::Checks"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MIN", 0);
  if(!svp)
    croak("Data::Checks ABI minimum version missing");
  int abi_ver = SvIV(*svp);
  if(abi_ver > DATACHECKS_ABI_VERSION)
    croak("Data::Checks ABI version mismatch - library supports >= %d, compiled for %d",
        abi_ver, DATACHECKS_ABI_VERSION);

  svp = hv_fetchs(PL_modglobal, "Data::Checks/ABIVERSION_MAX", 0);
  abi_ver = SvIV(*svp);
  if(abi_ver < DATACHECKS_ABI_VERSION)
    croak("Data::Checks ABI version mismatch - library supports <= %d, compiled for %d",
        abi_ver, DATACHECKS_ABI_VERSION);

  make_checkdata_func = INT2PTR(struct DataChecks_Checker *(*)(pTHX_ SV *checkspec),
      SvUV(*hv_fetchs(PL_modglobal, "Data::Checks/make_checkdata()@0", 0)));
  make_assertop_func = INT2PTR(OP *(*)(pTHX_ struct DataChecks_Checker *checker, OP *argop),
      SvUV(*hv_fetchs(PL_modglobal, "Data::Checks/make_assertop()@0", 0)));
  check_value_func = INT2PTR(bool (*)(pTHX_ struct DataChecks_Checker *checker, SV *value),
      SvUV(*hv_fetchs(PL_modglobal, "Data::Checks/check_value()@0", 0)));
  assert_value_func = INT2PTR(void (*)(pTHX_ struct DataChecks_Checker *checker, SV *value),
      SvUV(*hv_fetchs(PL_modglobal, "Data::Checks/assert_value()@0", 0)));
}

#endif /* defined HAVE_DATA_CHECKS_IMPL */

#endif
