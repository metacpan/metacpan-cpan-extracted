#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "passwdqc.h"

SV *
password_generate(const char *packed_params)
{
    const char *pass;
    const passwdqc_params_qc_t *params = (passwdqc_params_qc_t *)packed_params;

    pass = passwdqc_random(params);

    if (!pass)
        return &PL_sv_undef;
     return newSVpvn(pass, strlen(pass));
}

SV *
password_check(const char *packed_params, const char *new_pass, const char *old_pass, const char *pw_name, const char *pw_gecos)
{
    const char *reason;
    const passwdqc_params_qc_t *params = (passwdqc_params_qc_t *)packed_params;

    /* this is inspired by what passwdqc does on non-unix platforms */
    struct passwd fake_pw, *pw;
    memset(&fake_pw, 0, sizeof(fake_pw));
    fake_pw.pw_name  = pw_name ? (char *)pw_name : "";
    fake_pw.pw_gecos = pw_gecos ? (char *)pw_gecos : "";
    fake_pw.pw_dir   = "";
    if (pw_name != NULL || pw_gecos != NULL) {
        pw = &fake_pw;
    }
    else {
        pw = NULL;
    }

    reason = passwdqc_check(params, new_pass, old_pass, pw);

    if (!reason)
        return &PL_sv_undef;
    return newSVpvn(reason, strlen(reason));
}


MODULE = Data::Password::passwdqc		PACKAGE = Data::Password::passwdqc		

PROTOTYPES: DISABLE


SV *
password_generate (packed_params)
        const char * packed_params

SV *
password_check (packed_params, new_pass, ...)
        const char * packed_params
        const char * new_pass
    CODE:
        switch (items) {
            case 5:
                RETVAL = password_check(packed_params, new_pass,
                            SvOK(ST(2)) ? (char *)SvPV_nolen(ST(2)) : NULL,
                            SvOK(ST(3)) ? (char *)SvPV_nolen(ST(3)) : NULL,
                            SvOK(ST(4)) ? (char *)SvPV_nolen(ST(4)) : NULL);
                break;
            case 4:
                RETVAL = password_check(packed_params, new_pass,
                            SvOK(ST(2)) ? (char *)SvPV_nolen(ST(2)) : NULL,
                            SvOK(ST(3)) ? (char *)SvPV_nolen(ST(3)) : NULL,
                            NULL);
                break;
            case 3:
                RETVAL = password_check(packed_params, new_pass,
                            SvOK(ST(2)) ? (char *)SvPV_nolen(ST(2)) : NULL,
                            NULL,
                            NULL);
                break;
            case 2:
                RETVAL = password_check(packed_params, new_pass, NULL, NULL, NULL);
                break;
            default:
                croak("password_check() called with too few arguments!");
                break;
        }
    OUTPUT:
        RETVAL

void
_test_params (packed_params)
        const char * packed_params
    PREINIT:
        const passwdqc_params_qc_t * params;
    PPCODE:
        params = (passwdqc_params_qc_t *)packed_params;
        EXTEND(SP, 10);
        PUSHs(sv_2mortal(newSViv(params->min[0])));
        PUSHs(sv_2mortal(newSViv(params->min[1])));
        PUSHs(sv_2mortal(newSViv(params->min[2])));
        PUSHs(sv_2mortal(newSViv(params->min[3])));
        PUSHs(sv_2mortal(newSViv(params->min[4])));
        PUSHs(sv_2mortal(newSViv(params->max)));
        PUSHs(sv_2mortal(newSViv(params->passphrase_words)));
        PUSHs(sv_2mortal(newSViv(params->match_length)));
        PUSHs(sv_2mortal(newSViv(params->similar_deny)));
        PUSHs(sv_2mortal(newSViv(params->random_bits)));

SV *
_test_int_max ()
    CODE:
        RETVAL = newSViv(INT_MAX);
    OUTPUT:
        RETVAL

