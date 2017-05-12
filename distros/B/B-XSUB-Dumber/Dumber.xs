#include "EXTERN.h"
#include "perl.h"
#include "embed.h"
#include "XSUB.h"

/* a much dumber version of entersub */
OP *pp_simple_xsub(pTHX)
{
	dSP; dPOPss;
	register CV *cv = GvCV(sv);

	PUTBACK;

	(void)(*CvXSUB(cv))(aTHX_ cv);

	return NORMAL;
}

MODULE = B::XSUB::Dumber PACKAGE = B::XSUB::Dumber

I32
simple_xsub_ppaddr()
	CODE:
		RETVAL = (I32)&pp_simple_xsub;
	OUTPUT: RETVAL



