#ifndef __DATA_CHECKS_H__
#define __DATA_CHECKS_H__

#ifdef HAVE_DATA_CHECKS_IMPL
#  define DECLARE_FUNCTION(name, rettype, args, argnames) \
static rettype S_DataChecks_##name args;
#else
#  define DECLARE_FUNCTION(name, rettype, args, argnames) \
static rettype (*name##_func) args;                       \
static rettype S_DataChecks_##name args                   \
{                                                         \
  if(!name##_func)                                        \
    croak("Must call boot_data_checks() first");          \
  return (*name##_func) argnames;                         \
}
#endif

#define DATACHECKS_ABI_VERSION 0

struct DataChecks_Checker;

#define make_checkdata(checkspec)  S_DataChecks_make_checkdata(aTHX_ checkspec)
DECLARE_FUNCTION(make_checkdata,
    struct DataChecks_Checker *, (pTHX_ SV *checkspec), (aTHX_ checkspec))

#define free_checkdata(checker)  S_DataChecks_free_checkdata(aTHX_ checker)
DECLARE_FUNCTION(free_checkdata,
    void, (pTHX_ struct DataChecks_Checker *checker), (aTHX_ checker))

#define gen_assertmess(checker, name, constraint)  S_DataChecks_gen_assertmess(aTHX_ checker, name, constraint)
DECLARE_FUNCTION(gen_assertmess,
    void, (pTHX_ struct DataChecks_Checker *checker, SV *name, SV *constraint), (aTHX_ checker, name, constraint))

#define make_assertop(checker, argop)  S_DataChecks_make_assertop(aTHX_ checker, argop)
DECLARE_FUNCTION(make_assertop,
    OP *, (pTHX_ struct DataChecks_Checker *checker, OP *argop), (aTHX_ checker, argop))

#define check_value(checker, value)  S_DataChecks_check_value(aTHX_ checker, value)
DECLARE_FUNCTION(check_value,
    bool, (pTHX_ struct DataChecks_Checker *checker, SV *value), (aTHX_ checker, value))

#define assert_value(checker, value)  S_DataChecks_assert_value(aTHX_ checker, value)
DECLARE_FUNCTION(assert_value,
    void, (pTHX_ struct DataChecks_Checker *checker, SV *value), (aTHX_ checker, value))

#ifndef HAVE_DATA_CHECKS_IMPL

#define must_SvUV_from_modglobal(key)  S_must_SvUV_from_modglobal(aTHX_ key)
static UV S_must_SvUV_from_modglobal(pTHX_ const char *key)
{
  SV **svp = hv_fetch(PL_modglobal, key, strlen(key), 0);
  if(!svp)
    croak("Cannot load DataChecks.h: Expected to find %s in PL_modglobal", key);

  return SvUV(*svp);
}

#define boot_data_checks(ver) S_boot_data_checks(aTHX_ ver)
static void S_boot_data_checks(pTHX_ double ver) {
  SV **svp;
  if(ver < 0.02)
    ver = 0.02;
  SV *versv = newSVnv(ver);

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
      must_SvUV_from_modglobal("Data::Checks/make_checkdata()@0"));
  free_checkdata_func = INT2PTR(void (*)(pTHX_ struct DataChecks_Checker *checker),
      must_SvUV_from_modglobal("Data::Checks/free_checkdata()@0"));
  gen_assertmess_func = INT2PTR(void (*)(pTHX_ struct DataChecks_Checker *checker, SV *name, SV *constraint),
      must_SvUV_from_modglobal("Data::Checks/gen_assertmess()@0"));
  make_assertop_func = INT2PTR(OP *(*)(pTHX_ struct DataChecks_Checker *checker, OP *argop),
      must_SvUV_from_modglobal("Data::Checks/make_assertop()@0"));
  check_value_func = INT2PTR(bool (*)(pTHX_ struct DataChecks_Checker *checker, SV *value),
      must_SvUV_from_modglobal("Data::Checks/check_value()@0"));
  assert_value_func = INT2PTR(void (*)(pTHX_ struct DataChecks_Checker *checker, SV *value),
      must_SvUV_from_modglobal("Data::Checks/assert_value()@0"));
}

#endif /* defined HAVE_DATA_CHECKS_IMPL */

#endif
