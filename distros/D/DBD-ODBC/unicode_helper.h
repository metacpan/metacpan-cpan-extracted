#ifdef WITH_UNICODE

#ifndef unicode_helper_h
#define unicode_helper_h
#include "ConvertUTF.h"

UTF16 * WValloc(char * s);

void WVfree(UTF16 * wp);

void sv_setwvn(SV * sv, UTF16 * wp, STRLEN len);
SV *sv_newwvn(UTF16 * wp, STRLEN len);


char * PVallocW(UTF16 * wp);

void PVfreeW(char * s);

void SV_toWCHAR(SV * sv);
void utf8sv_to_wcharsv(SV *sv);

#endif /* defined unicode_helper_h */
#endif /* WITH_UNICODE */
