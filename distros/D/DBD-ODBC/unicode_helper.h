#ifdef WITH_UNICODE

#ifndef unicode_helper_h
#define unicode_helper_h
#include "ConvertUTF.h"

UTF16 * WValloc(char * s);

void WVfree(UTF16 * wp);

void sv_setwvn(pTHX_ SV * sv, UTF16 * wp, STRLEN len);
SV *sv_newwvn(pTHX_ UTF16 * wp, STRLEN len);


char * PVallocW(UTF16 * wp);

void PVfreeW(char * s);

void SV_toWCHAR(pTHX_ SV * sv);
void utf8sv_to_wcharsv(pTHX_ SV *sv);

#endif /* defined unicode_helper_h */
#endif /* WITH_UNICODE */
