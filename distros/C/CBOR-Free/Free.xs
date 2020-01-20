#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "cbor_free_common.h"

#include "cbor_free_boolean.h"
#include "cbor_free_encode.h"
#include "cbor_free_decode.h"

#define _PACKAGE "CBOR::Free"

#define CANONICAL_OPT "canonical"
#define CANONICAL_OPT_LEN (sizeof(CANONICAL_OPT) - 1)

#define PRESERVE_REFS_OPT "preserve_references"
#define PRESERVE_REFS_OPT_LEN (sizeof(PRESERVE_REFS_OPT) - 1)

#define SCALAR_REFS_OPT "scalar_references"
#define SCALAR_REFS_OPT_LEN (sizeof(SCALAR_REFS_OPT) - 1)

#define TEXT_KEYS_OPT "text_keys"
#define TEXT_KEYS_OPT_LEN (sizeof(TEXT_KEYS_OPT) - 1)

HV *cbf_stash = NULL;

//----------------------------------------------------------------------

MODULE = CBOR::Free           PACKAGE = CBOR::Free

PROTOTYPES: DISABLE

BOOT:
    cbf_stash = gv_stashpv(_PACKAGE, FALSE);
    newCONSTSUB(cbf_stash, "_MAX_RECURSION", newSVuv( MAX_ENCODE_RECURSE ));


SV *
encode( SV * value, ... )
    CODE:
        uint8_t encode_state_flags = 0;

        U8 i;
        for (i=1; i<items; i++) {
            if (!(i % 2)) continue;

            if ((SvCUR(ST(i)) == CANONICAL_OPT_LEN) && memEQ( SvPV_nolen(ST(i)), CANONICAL_OPT, CANONICAL_OPT_LEN)) {
                ++i;
                if (i<items && SvTRUE(ST(i))) {
                    encode_state_flags |= ENCODE_FLAG_CANONICAL;
                }
            }

            else if ((SvCUR(ST(i)) == TEXT_KEYS_OPT_LEN) && memEQ( SvPV_nolen(ST(i)), TEXT_KEYS_OPT, TEXT_KEYS_OPT_LEN)) {
                ++i;
                if (i<items && SvTRUE(ST(i))) {
                    encode_state_flags |= ENCODE_FLAG_TEXT_KEYS;
                }
            }

            else if ((SvCUR(ST(i)) == PRESERVE_REFS_OPT_LEN) && memEQ( SvPV_nolen(ST(i)), PRESERVE_REFS_OPT, PRESERVE_REFS_OPT_LEN)) {
                ++i;
                if (i<items && SvTRUE(ST(i))) {
                    encode_state_flags |= ENCODE_FLAG_PRESERVE_REFS;
                }
            }

            else if ((SvCUR(ST(i)) == SCALAR_REFS_OPT_LEN) && memEQ( SvPV_nolen(ST(i)), SCALAR_REFS_OPT, SCALAR_REFS_OPT_LEN)) {
                ++i;
                if (i<items && SvTRUE(ST(i))) {
                    encode_state_flags |= ENCODE_FLAG_SCALAR_REFS;
                }
            }
        }

        encode_ctx encode_state = cbf_encode_ctx_create(encode_state_flags);

        RETVAL = newSV(0);

        cbf_encode(aTHX_ value, &encode_state, RETVAL);

        cbf_encode_ctx_free_reftracker( &encode_state );

        // Don’t use newSVpvn here because that will copy the string.
        // Instead, create a new SV and manually assign its pieces.
        // This follows the example from ext/POSIX/POSIX.xs:

        SvUPGRADE(RETVAL, SVt_PV);
        SvPV_set(RETVAL, encode_state.buffer);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, encode_state.len - 1);
        SvLEN_set(RETVAL, encode_state.buflen);

    OUTPUT:
        RETVAL


SV *
decode( SV *cbor )
    CODE:
        RETVAL = cbf_decode( aTHX_ cbor, NULL, false );

    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = CBOR::Free     PACKAGE = CBOR::Free::Decoder

PROTOTYPES: DISABLE

BOOT:
    HV *stash = gv_stashpvn("CBOR::Free::Decoder", 19, FALSE);
    newCONSTSUB(stash, "_FLAG_PRESERVE_REFERENCES", newSVuv(CBF_FLAG_PRESERVE_REFERENCES));
    newCONSTSUB(stash, "_FLAG_NAIVE_UTF8", newSVuv(CBF_FLAG_NAIVE_UTF8));

SV *
decode( SV *selfref, SV *cbor )
    CODE:
        HV *self = (HV *)SvRV(selfref);

        HV *tag_handler = NULL;

        UV flags_uv;

        SV **tag_handler_hr = hv_fetchs(self, "_tag_decode_callback", 0);

        if (tag_handler_hr && *tag_handler_hr && SvOK(*tag_handler_hr)) {
            tag_handler = (HV *)SvRV(*tag_handler_hr);
        }

        SV **flags = hv_fetchs(self, "_flags", 0);

        if (flags && *flags) {
            flags_uv = SvUV(*flags);
        }
        else {
            flags_uv = 0;
        }

        RETVAL = cbf_decode( aTHX_
            cbor,
            tag_handler,
            flags_uv
        );

    OUTPUT:
        RETVAL
