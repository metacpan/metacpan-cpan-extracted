#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_load_module
#define NEED_vload_module
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <uuid/uuid.h>

#ifdef PERL_DARWIN
#define PID_CHECK pid_check()
#include <stdlib.h>
#else
#define PID_CHECK
#endif


#define UUID_TYPE_TIME 2
#define UUID_TYPE_RANDOM 4

#define UUID_HEX_SIZE sizeof(uuid_t) * 2
#define UUID_STRING_SIZE 36
#define UUID_BASE64_SIZE 24
#define UUID_BASE64_LF_SIZE 25
#define UUID_BASE64_CRLF_SIZE 26


/* these define RETBUF, which is the PV inside RETVAL preallocated to a certain
 * size. Avoids the copying of XSRETURN_PVN and teaches me to write more
 * obfuscated C ;-) */

/* type bufer[size] with SvCUR set to cur */
#define dRETBUF(type, size, cur) \
    type RETBUF; \
    RETVAL = newSV(size); \
    SvPOK_on(RETVAL); \
    SvCUR_set(RETVAL, cur); \
    RETBUF = (type)SvPVX(RETVAL)

/* sizeof(type) buffer with SvCUR set to size */
#define dRETBUFs(type, size) dRETBUF(type, size, size)

/* null terminated buffer with size + 1 bytes and SvCUR set to size */
#define dRETBUFz(size) \
    dRETBUF(char *, size + 1, size); \
    RETBUF[size + 1] = 0

#define dUUIDRETBUF dRETBUFs(unsigned char *, sizeof(uuid_t))
#define dSTRRETBUF  dRETBUFs(char *, UUID_STRING_SIZE)
#define dHEXRETBUF  dRETBUFz(UUID_HEX_SIZE)

/* FIXME uuid_time, uuid_type, uuid_variant are available in libuuid but not in
 * darwin's uuid.h... consider exposing? */

static pid_t last_pid = 0;

inline STATIC void pid_check () {
    if ( getpid() != last_pid ) {
        last_pid = getpid();
        arc4random_stir();
    }
}

/* generates a new UUID of a given version */
STATIC void new_uuid (IV version, uuid_t uuid) {
    PID_CHECK;

    switch (version) {
        case UUID_TYPE_TIME:
            uuid_generate_time(uuid);
            break;
        case UUID_TYPE_RANDOM:
            uuid_generate_random(uuid);
            break;
        ggdefault:
            uuid_generate(uuid);
    }
}

STATIC IV hex_to_uuid (uuid_t uuid, char *pv) {
    int i;

    Zero(uuid, 1, uuid_t);

    /* decode hex */
    for ( i = 0; i < sizeof(uuid_t); i++ ) {
        if ( !isALNUM(*pv) )
            return 0;
    }

    for ( i = 0; i < sizeof(uuid_t); i++ ) {
        /* left nybble */
        if ( isDIGIT(*pv) )
            uuid[i] |= ( *pv++ << 4 ) & 0xf0;
        else
            uuid[i] |= ( (*pv++ + 9) << 4 ) & 0xf0;

        /* right nybble */
        if ( isDIGIT(*pv) )
            uuid[i] |= *pv++ & 0xf;
        else
            uuid[i] |= (*pv++ + 9) & 0xf;

    }

    return 1;
}

/* hex-string, hex, base64 (TODO), or binary sv to uuid_t */
STATIC IV sv_to_uuid (SV *sv, uuid_t uuid) {
    dSP;

    if ( SvPOK(sv) || sv_isobject(sv) ) {
        char *pv;
        STRLEN len;

        if ( SvPOK(sv) ) {
            pv = SvPV_nolen(sv);
            len = SvCUR(sv);
        } else {
            pv = SvPV(sv, len);
        }

        switch ( len ) {
            case UUID_HEX_SIZE:
                return hex_to_uuid(uuid, pv);
            case UUID_BASE64_SIZE:
            case UUID_BASE64_LF_SIZE:
            case UUID_BASE64_CRLF_SIZE:

                load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("MIME::Base64"), NULL);

                PUSHMARK(SP);
                XPUSHs(sv);
                PUTBACK;

                call_pv("MIME::Base64::decode_base64", G_SCALAR);

                SPAGAIN;
                pv = SvPV_nolen(TOPs);

                /* fall through */
            case sizeof(uuid_t):
                uuid_copy(uuid, *(uuid_t *)pv);
                return 1;
            case UUID_STRING_SIZE:
                if ( uuid_parse(pv, uuid) == 0 )
                    return 1;
        }
    }

    return 0;
}


MODULE = Data::UUID::LibUUID            PACKAGE = Data::UUID::LibUUID
PROTOTYPES: ENABLE
BOOT:
    last_pid = getpid();

SV*
uuid_eq(uu1_sv, uu2_sv)
    SV *uu1_sv;
    SV *uu2_sv;
    PROTOTYPE: $$
    PREINIT:
        uuid_t uu1;
        uuid_t uu2;
    PPCODE:
        if ( sv_to_uuid(uu1_sv, uu1) && sv_to_uuid(uu2_sv, uu2) )
            if ( uuid_compare(uu1, uu2) == 0 )
                XSRETURN_YES;
            else
                XSRETURN_NO;
        else
            XSRETURN_UNDEF;

SV*
uuid_compare(uu1_sv, uu2_sv)
    SV *uu1_sv;
    SV *uu2_sv;
    PROTOTYPE: $$
    PREINIT:
        uuid_t uu1;
        uuid_t uu2;
    PPCODE:
        if ( sv_to_uuid(uu1_sv, uu1) && sv_to_uuid(uu2_sv, uu2) )
            XSRETURN_IV(uuid_compare(uu1, uu2));
        else
            XSRETURN_UNDEF;

SV*
new_uuid_binary(...)
    PROTOTYPE: ;$
    PREINIT:
        IV version = UUID_TYPE_TIME;
    CODE:
        dUUIDRETBUF;

        if ( items == 1 ) version = SvIV(ST(0));

        new_uuid(version, RETBUF);
    OUTPUT: RETVAL

SV*
new_uuid_string(...)
    PROTOTYPE: ;$
    PREINIT:
        uuid_t uuid;
        IV version = UUID_TYPE_TIME;
    CODE:
        dSTRRETBUF;

        if ( items == 1 ) version = SvIV(ST(0));

        new_uuid(version, uuid);
        uuid_unparse(uuid, RETBUF);
    OUTPUT: RETVAL

SV*
uuid_to_string(sv)
    SV *sv
    PROTOTYPE: $
    PREINIT:
        uuid_t uuid;
    CODE:
        if ( sv_to_uuid(sv, uuid) ) {
            dSTRRETBUF;
            uuid_unparse(uuid, RETBUF);
        } else
            XSRETURN_UNDEF;
    OUTPUT: RETVAL

SV*
uuid_to_binary(sv)
    SV *sv
    PROTOTYPE: $
    CODE:
        dUUIDRETBUF;
        if ( !sv_to_uuid(sv, RETBUF) )
            XSRETURN_UNDEF;
    OUTPUT: RETVAL

SV*
uuid_to_hex(sv)
    SV *sv
    PROTOTYPE: $
    PREINIT:
        uuid_t uuid;
    CODE:
        if ( sv_to_uuid(sv, uuid) ) {
            int i;
            U8 bits = 0;
            U8 *uuid_ptr = (U8 *)uuid;
            dHEXRETBUF;

            for (i = 0; i < UUID_HEX_SIZE; i++) {
                if (i & 1) bits <<= 4;
                else bits = *uuid_ptr++;
                RETBUF[i] = PL_hexdigit[(bits >> 4) & 15];
            }
        } else XSRETURN_UNDEF;
    OUTPUT: RETVAL

SV*
new_dce_uuid_binary(...)
    CODE:
        dUUIDRETBUF;
        PID_CHECK;
        uuid_generate(RETBUF);
    OUTPUT: RETVAL

SV*
new_dce_uuid_string(...)
    PREINIT:
        uuid_t uuid;
    CODE:
        dSTRRETBUF;
        PID_CHECK;
        uuid_generate(uuid);
        uuid_unparse(uuid, RETBUF);
    OUTPUT: RETVAL


