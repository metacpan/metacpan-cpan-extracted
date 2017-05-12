#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int _unitcheckify(SV* sv);
int _add_cv_to_reqd(CV *cv);

/* work out which function to really call, ifdefs probably sensible here */
#if (PERL_VERSION >= 9 && PERL_SUBVERSION >= 5) \
  || (PERL_VERSION >= 10)
/* We have a UNITCHECK to use, as we're getting called thus:
COMPILATION UNIT:
some code
use Check::UnitCheck sub { ... };
some more code

which is the same as:

COMPILATION UNIT:
some code
BEGIN {require Check::UnitCheck; Check::UnitCheck->import( sub {...})}
some more code

we can be fairly certain that we'll get the correct unitcheckav 
 */
int _add_cv_to_reqd(CV *cv) {
  if (!cv)
    croak("Need a CV");

  CvSPECIAL_on(cv);

  if (!PL_unitcheckav)
    PL_unitcheckav = newAV();
  
  av_unshift(PL_unitcheckav, 1);
  av_store(PL_unitcheckav, 0, (SV*)cv);

  return 0;
}
#else
/* We only have CHECK, but that's easier */
int _add_cv_to_reqd(CV *cv) {
  if (!cv)
    croak("Need a CV");

  if (PL_main_start && ckWARN(WARN_VOID)) {
    warn("Check::UnitCheck - Too late to run CHECK block");
    return 1;
  }

  CvSPECIAL_on(cv);

  if (!PL_checkav)
    PL_checkav = newAV();
  av_unshift(PL_checkav, 1);
  av_store(PL_checkav, 0, (SV*)cv);
  return 0;
}
#endif

int _unitcheckify(SV *sv) {
  CV *cv;
  cv = (CV*)SvRV(sv);
  SvREFCNT_inc((SV*)cv);
  if (_add_cv_to_reqd(cv)) {
    /* didn't work for a recoverable reason */
    SvREFCNT_dec((SV*)cv);
  }
  else {
    return 0;
  }
}

MODULE = Check::UnitCheck		PACKAGE = Check::UnitCheck		


int
unitcheckify(sv)
    INPUT:
	SV *		sv
    CODE:
        if (!sv) /*SVt_PVCV */
	  croak("Need a subref a");
	if (!SvRV(sv))
	  croak("Need a subref b");
	if (! (SvTYPE(SvRV(sv)) == SVt_PVCV))
	  croak("Need a subref c");

	RETVAL = _unitcheckify(sv);
    OUTPUT:
	RETVAL

