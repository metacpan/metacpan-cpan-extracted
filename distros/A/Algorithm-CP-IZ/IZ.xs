#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <iz.h>

#include "const-c.inc"

/*
 * Helper functinos for cs_search, cs_searchCriteria, cs_findAll
 */

typedef int array2index(CSint **allVars, int nbVars);

static array2index* currentArray2IndexFunc;
static SV* findFreeVarPerlFunc;

static CSint* findFreeVarWrapper(CSint **allVars, int nbVars)
{
  int idx = currentArray2IndexFunc(allVars, nbVars);
  if (idx < 0)
    return 0;

  return allVars[idx];
}

static int findFreeVarPerlWrapper(CSint **allVars, int nbVars)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  int count = call_sv(findFreeVarPerlFunc, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("findFreeVarPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return ret;
}

static int findFreeVarDefault(CSint **allVars, int nbVars)
{
  int i;

  for (i=0; i<nbVars; i++) {
    if (cs_isFree(allVars[i]))
      return i;
  }

  return -1;
}

static int findFreeVarNbElements(CSint **allVars, int nbVars)
{
  int i;
  int ret = -1;
  int minElem = INT_MAX;

  for (i=0; i<nbVars; i++) {
    int nElem = cs_getNbElements(allVars[i]);
    if (nElem > 1 && nElem < minElem) {
      ret = i;
      minElem = nElem;
    }
  }

  return ret;
}

array2index* findFreeVarTbl[] = {
  findFreeVarDefault,
  findFreeVarNbElements,
};

static SV* criteriaPerlFunc;

static int criteriaPerlWrapper(int index, int val)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(index)));
  XPUSHs(sv_2mortal(newSViv(val)));

  PUTBACK;
  int count = call_sv(criteriaPerlFunc, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("criteriaPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return ret;
}

/*
 * Helper functinos for cs_findAll
 */
static SV* foundPerlFunc;

static void foundPerlWrapper(CSint **allVars, int nbVars)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  call_sv(foundPerlFunc, G_VOID);
  SPAGAIN;

  FREETMPS;
  LEAVE;
}

/*
 * Helper functinos for cs_backtrack
 */

typedef void backtrackCallback(CSint *vint, int index);

static SV* backtrackPerlFunc;

static void backtrackPerlWrapper(CSint *vint, int index)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  /* index is pointing to context in perl code */
  XPUSHs(sv_2mortal(newSViv(index)));

  PUTBACK;
  call_sv(backtrackPerlFunc, G_VOID);
  SPAGAIN;

  FREETMPS;
  LEAVE;
}

/*
 * Helper functinos for demon funcrions
 */

static IZBOOL eventAllKnownPerlWrapper(CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventAllKnownPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

static IZBOOL eventKnownPerlWrapper(int val, int index, CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(val)));
  XPUSHs(sv_2mortal(newSViv(index)));

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventKnownPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

static IZBOOL eventNewMinMaxNeqPerlWrapper(CSint* vint, int index, int oldValue, CSint **tint, int size, void *ext)
{
  dTHX;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);

  XPUSHs(sv_2mortal(newSViv(index)));
  XPUSHs(sv_2mortal(newSViv(oldValue)));

  PUTBACK;
  int count = call_sv((SV*)ext, G_SCALAR);
  SPAGAIN;
  int ret = -1;

  if (count == 0) {
    croak("eventNewMinMaxNeqPerlWrapper: error");
  }
  ret = POPi;

  FREETMPS;
  LEAVE;

  return (IZBOOL)ret;
}

MODULE = Algorithm::CP::IZ		PACKAGE = Algorithm::CP::IZ		

INCLUDE: const-xs.inc

INCLUDE: cs_vadd.inc
INCLUDE: cs_vmul.inc
INCLUDE: cs_reif2.inc

void*
alloc_var_array(av)
    AV *av;
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);
    RETVAL = array;

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }
OUTPUT:
    RETVAL

void*
alloc_int_array(av)
    AV *av;
PREINIT:
    int* array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, int);
    RETVAL = array;

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvIV(*pptr);
    }
OUTPUT:
    RETVAL


void
free_array(ptr)
    void* ptr;
CODE:
    Safefree(ptr);

void
cs_init()
CODE:
    cs_init();

void
cs_end()
CODE:
    cs_end();

int
cs_saveContext()
CODE:
    RETVAL = cs_saveContext();
OUTPUT:
    RETVAL

void
cs_restoreContext()
CODE:
    cs_restoreContext();

void
cs_restoreAll()
CODE:
    cs_restoreAll();

void
cs_acceptContext()
CODE:
    cs_acceptContext();

void
cs_acceptAll()
CODE:
    cs_acceptAll();

int cs_getNbFails()
CODE:
    RETVAL = cs_getNbFails();
OUTPUT:
    RETVAL

int cs_getNbChoicePoints()
CODE:
    RETVAL = cs_getNbChoicePoints();
OUTPUT:
    RETVAL

void*
cs_createCSint(min, max)
    int min
    int max
CODE:
    RETVAL = cs_createCSint(min, max);
OUTPUT:
    RETVAL

void*
cs_createCSintFromDomain(parray, size)
    void* parray
    int size
CODE:
    RETVAL = cs_createCSintFromDomain(parray, size);
OUTPUT:
    RETVAL

int
cs_search(av, func_id, func_ref, fail_max)
    AV *av
    int func_id
    SV* func_ref
    int fail_max
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    if (func_id < 0) {
      findFreeVarPerlFunc = SvRV(func_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (func_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[func_id];
    }

    if (fail_max < 0)
      fail_max = INT_MAX;

    RETVAL = cs_searchFail((CSint**)array,
			   (int)alen, findFreeVarWrapper, fail_max);
    Safefree(array);
OUTPUT:
    RETVAL

int
cs_searchCriteria(av, findvar_id, findvar_ref, criteria_ref, fail_max)
    AV *av
    int findvar_id
    SV* findvar_ref
    SV* criteria_ref
    int fail_max
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;
    criteriaPerlFunc = SvRV(criteria_ref);

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("search: Bad FindFreeVar value");
      }
      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    if (fail_max < 0)
        fail_max = INT_MAX;

    RETVAL = cs_searchCriteriaFail((CSint**)array,
				   (int)alen,
				   currentArray2IndexFunc,
				   criteriaPerlWrapper,
				   fail_max);
    Safefree(array);
OUTPUT:
    RETVAL

int
cs_findAll(av, findvar_id, findvar_ref, found_ref)
    AV *av
    int findvar_id
    SV* findvar_ref
    SV* found_ref
PREINIT:
    void** array;
    SSize_t alen;
    SSize_t i;
CODE:
    alen = av_len(av) + 1;
    Newx(array, alen, void*);

    for (i = 0; i<alen; i++) {
      SV** pptr = av_fetch(av, i, 0);
      array[i] = SvRV(*pptr);
    }

    currentArray2IndexFunc = 0;
    findFreeVarPerlFunc = 0;

    foundPerlFunc = SvRV(found_ref);

    if (findvar_id < 0) {
      findFreeVarPerlFunc = SvRV(findvar_ref);
      currentArray2IndexFunc = findFreeVarPerlWrapper;
    }
    else {
      if (findvar_id >= sizeof(findFreeVarTbl)/sizeof(findFreeVarTbl[0])) {
	Safefree(array);
	croak("findAll: Bad FindFreeVar value");
      }

      currentArray2IndexFunc = findFreeVarTbl[findvar_id];
    }

    RETVAL = cs_findAll((CSint**)array, (int)alen,
			findFreeVarWrapper, foundPerlWrapper);
    Safefree(array);
OUTPUT:
    RETVAL

void
cs_backtrack(vint, index, handler)
  void* vint
  int index
  SV* handler
CODE:
  backtrackPerlFunc = SvRV(handler);
  cs_backtrack(vint, index, backtrackPerlWrapper);

int
cs_eventAllKnown(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    RETVAL = cs_eventAllKnown(tint, size,
			      eventAllKnownPerlWrapper, SvRV(handler));
OUTPUT:
    RETVAL

int
cs_eventKnown(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    RETVAL = cs_eventKnown(tint, size,
			   eventKnownPerlWrapper, SvRV(handler));
OUTPUT:
    RETVAL

void
cs_eventNewMin(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNewMin(tint, size,
		   eventNewMinMaxNeqPerlWrapper, SvRV(handler));

void
cs_eventNewMax(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNewMax(tint, size,
		   eventNewMinMaxNeqPerlWrapper, SvRV(handler));

void
cs_eventNeq(tint, size, handler)
    void* tint
    int size
    SV* handler
CODE:
    cs_eventNeq(tint, size,
		eventNewMinMaxNeqPerlWrapper, SvRV(handler));

int
cs_getNbElements(vint)
    void* vint
CODE:
    RETVAL = cs_getNbElements(vint);
OUTPUT:
    RETVAL

int
cs_getMin(vint)
    void* vint
CODE:
    RETVAL = cs_getMin(vint);
OUTPUT:
    RETVAL

int
cs_getMax(vint)
    void* vint
CODE:
    RETVAL = cs_getMax(vint);
OUTPUT:
    RETVAL

int
cs_getValue(vint)
    void* vint
CODE:
    if (cs_isFree(vint))
      croak("variable is not unstantiated.");

    RETVAL = cs_getValue(vint);
OUTPUT:
    RETVAL

int
cs_isIn(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_isIn(vint, val);
OUTPUT:
    RETVAL

int
cs_isFree(vint)
    void* vint
CODE:
    RETVAL = cs_isFree(vint);
OUTPUT:
    RETVAL

int
cs_isInstantiated(vint)
    void* vint
CODE:
    RETVAL = cs_isInstantiated(vint);
OUTPUT:
    RETVAL

void
cs_domain(vint, av)
    void* vint
    AV *av
PREINIT:
    int i;
    int* dom = cs_getDomain(vint);
    int n = cs_getNbElements(vint);
CODE:
    for (i = 0; i < n; i++) {
      av_store(av, i, newSViv(dom[i]));
    }
    free(dom);    

int
cs_getNextValue(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_getNextValue(vint, val);
OUTPUT:
    RETVAL

int
cs_getPreviousValue(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_getPreviousValue(vint, val);
OUTPUT:
    RETVAL

int
cs_is_in(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_isIn(vint, val);
OUTPUT:
    RETVAL

int
cs_AllNeq(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_AllNeq(tint, size);
OUTPUT:
    RETVAL

int
cs_EQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_EQ(vint, val);
OUTPUT:
    RETVAL

int
cs_Eq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Eq(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_NEQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_NEQ(vint, val);
OUTPUT:
    RETVAL

int
cs_Neq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Neq(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_LE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_LE(vint, val);
OUTPUT:
    RETVAL

int
cs_Le(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Le(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_LT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_LT(vint, val);
OUTPUT:
    RETVAL

int
cs_Lt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Lt(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_GE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_GE(vint, val);
OUTPUT:
    RETVAL

int
cs_Ge(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Ge(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_GT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_GT(vint, val);
OUTPUT:
    RETVAL

int
cs_Gt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Gt(vint1, vint2);
OUTPUT:
    RETVAL

int
cs_InArray(vint, array, size)
    void* vint
    void* array
    int size
CODE:
    RETVAL = cs_InArray(vint, array, size);
OUTPUT:
    RETVAL

int
cs_NotInArray(vint, array, size)
    void* vint
    void* array
    int size
CODE:
    RETVAL = cs_NotInArray(vint, array, size);
OUTPUT:
    RETVAL

int
cs_InInterval(vint, minVal, maxVal)
    void* vint
    int minVal
    int maxVal
CODE:
    RETVAL = cs_InInterval(vint, minVal, maxVal);
OUTPUT:
    RETVAL

int
cs_NotInInterval(vint, minVal, maxVal)
    void* vint
    int minVal
    int maxVal
CODE:
    RETVAL = cs_NotInInterval(vint, minVal, maxVal);
OUTPUT:
    RETVAL

void*
cs_Add(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Add(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Mul(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Mul(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Sub(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Sub(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Div(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_Div(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_Sigma(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Sigma(tint, size);
OUTPUT:
    RETVAL

void*
cs_ScalProd(vars, coeffs, n)
    void* vars
    void* coeffs
    int n
CODE:
    RETVAL = cs_ScalProd(vars, coeffs, n);
OUTPUT:
    RETVAL

void*
cs_Abs(vint)
    void* vint
CODE:
    RETVAL = cs_Abs(vint);
OUTPUT:
    RETVAL

void*
cs_Min(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Min(tint, size);
OUTPUT:
    RETVAL

void*
cs_Max(tint, size)
    void* tint
    int size
CODE:
    RETVAL = cs_Max(tint, size);
OUTPUT:
    RETVAL

int
cs_IfEq(vint1, vint2, val1, val2)
    void* vint1
    void* vint2
    int val1
    int val2
CODE:
    RETVAL = cs_IfEq(vint1, vint2, val1, val2);
OUTPUT:
    RETVAL

int
cs_IfNeq(vint1, vint2, val1, val2)
    void* vint1
    void* vint2
    int val1
    int val2
CODE:
    RETVAL = cs_IfNeq(vint1, vint2, val1, val2);
OUTPUT:
    RETVAL

void*
cs_OccurDomain(val, array, size)
    int val
    void* array
    int size
CODE:
    RETVAL = cs_OccurDomain(val, array, size);
OUTPUT:
    RETVAL

int
cs_OccurConstraints(vint, val, array, size)
    void* vint
    int val
    void* array
    int size
CODE:
    RETVAL = cs_OccurConstraints(vint, val, array, size);
OUTPUT:
    RETVAL

void*
cs_Index(array, size, val)
    void* array
    int size
    int val
CODE:
    RETVAL = cs_Index(array, size, val);
OUTPUT:
    RETVAL

void*
cs_Element(index, values, size)
    void* index
    void* values
    int size
CODE:
    RETVAL = cs_Element(index, values, size);
OUTPUT:
    RETVAL
