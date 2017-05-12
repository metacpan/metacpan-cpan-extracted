#ifndef PACK_H_INCLUDE_GUARD
#define PACK_H_INCLUDE_GUARD

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
extern "C" {
#endif


	/* Macros used to pack a C struct into Perl Hashes (from HPUX::Pstat) */

	/* pack the integer value in p->name into hash hv
	 * using key "name"
	 */
#define PACK_IV(name) \
    sv = newSViv(p->name);\
    if (hv_store(hv, #name, sizeof(#name)-1, sv, 0) == NULL) {\
    warn("__FILE__:__LINE__ failed to pack '" #name "' elem");\
    }\

	/* pack the unsigned integer value in p->name into hash hv
	 * using key "name"
	 */
#define PACK_UV(name) \
    sv = newSVuv(p->name);\
    if (hv_store(hv, #name, sizeof(#name)-1, sv, 0) == NULL) {\
    warn("__FILE__:__LINE__ failed to pack '" #name "' elem");\
    }\

	/* pack the double value in p->name into hash hv
	 * using key "name"
	 */
#define PACK_NV(name) \
    sv = newSVnv(p->name);\
    if (hv_store(hv, #name, sizeof(#name)-1, sv, 0) == NULL) {\
    warn("__FILE__:__LINE__ failed to pack '" #name "' elem");\
    }\

	/* pack the string starting at p->name into hash hv
	 * using key "name", string length in len (calculated if len == 0)
	 */
#define PACK_PV(name, len) \
    sv = newSVpv(p->name, len);\
    if (hv_store(hv, #name, sizeof(#name)-1, sv, 0) == NULL) {\
    warn("__FILE__:__LINE__ failed to pack '" #name "' elem");\
    }\

	/* pack reference to av into hash hv
	 * using key "name"
	 */
#define PACK_AV(name) \
    sv = newRV_noinc((SV*)av);\
    if (hv_store(hv, #name, sizeof(#name)-1, sv, 0) == NULL) {\
    warn("__FILE__:__LINE__ failed to pack '" #name "' elem");\
    }\

#ifdef __cplusplus
}
#endif

#endif /* undef PACK_H_INCLUDE_GUARD */
