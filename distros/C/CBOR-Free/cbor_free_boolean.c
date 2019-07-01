#include "cbor_free_boolean.h"

static HV *boolean_stash = NULL;

HV *cbf_get_boolean_stash() {
    if (!boolean_stash) {
        dTHX;

        boolean_stash = gv_stashpv(BOOLEAN_CLASS, 0);

        if (!boolean_stash) {
            SV *modname = newSVpvs(LOAD_BOOLEAN_CLASS);
            load_module(PERL_LOADMOD_NOIMPORT, modname, NULL);

            boolean_stash = gv_stashpv(BOOLEAN_CLASS, 0);

            if (!boolean_stash) {
                _croak("Loaded Types::Serialiser but didn’t find stash!");
            }
        }
    }

    return boolean_stash;
}

static SV *stored_false = NULL;
static SV *stored_true = NULL;

SV *cbf_get_false() {
    if (!stored_false) {
        dTHX;
        cbf_get_boolean_stash();
        stored_false = get_sv("Types::Serialiser::false", 0);
    }

    return stored_false;
}

SV *cbf_get_true() {
    if (!stored_true) {
        dTHX;
        cbf_get_boolean_stash();
        stored_true = get_sv("Types::Serialiser::true", 0);
    }

    return stored_true;
}
