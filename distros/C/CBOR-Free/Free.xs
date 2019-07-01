#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

//#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "cbor_free_common.h"

#include "cbor_free_boolean.h"
#include "cbor_free_encode.h"
#include "cbor_free_decode.h"

#define _PACKAGE "CBOR::Free"

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
        encode_ctx encode_state[1];

        encode_state->buffer = NULL;
        Newx( encode_state->buffer, ENCODE_ALLOC_CHUNK_SIZE, char );

        encode_state->buflen = ENCODE_ALLOC_CHUNK_SIZE;
        encode_state->len = 0;
        encode_state->recurse_count = 0;

        encode_state->is_canonical = false;

        U8 i;
        for (i=1; i<items; i++) {
            if (!(i % 2)) continue;

            if ((SvCUR(ST(i)) == 9) && memEQ( SvPV_nolen(ST(i)), "canonical", 9)) {
                ++i;
                if (i<items) encode_state->is_canonical = SvTRUE(ST(i));
                break;
            }
        }

        RETVAL = newSV(0);

        cbf_encode(aTHX_ value, encode_state, RETVAL);

        // Don’t use newSVpvn here because that will copy the string.
        // Instead, create a new SV and manually assign its pieces.
        // This follows the example from ext/POSIX/POSIX.xs:

        SvUPGRADE(RETVAL, SVt_PV);
        SvPV_set(RETVAL, encode_state->buffer);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, encode_state->len - 1);
        SvLEN_set(RETVAL, encode_state->buflen);

    OUTPUT:
        RETVAL


SV *
decode( SV *cbor )
    CODE:
        RETVAL = cbf_decode( aTHX_ cbor, NULL );

    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = CBOR::Free     PACKAGE = CBOR::Free::Decoder

PROTOTYPES: DISABLE

SV *
decode( SV *selfref, SV *cbor )
    CODE:
        HV *self = (HV *)SvRV(selfref);

        HV *tag_handler = NULL;

        SV **tag_handler_hr = hv_fetchs(self, "_tag_decode_callback", 0);

        if (tag_handler_hr && *tag_handler_hr && SvOK(*tag_handler_hr)) {
            tag_handler = (HV *)SvRV(*tag_handler_hr);
        }

        RETVAL = cbf_decode( aTHX_ cbor, tag_handler );

    OUTPUT:
        RETVAL
