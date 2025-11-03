#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/hexsimd.h"

MODULE = Data::HexConverter    PACKAGE = Data::HexConverter

PROTOTYPES: ENABLE

SV *
hex_to_binary(SV *hex_ref)
PREINIT:
    SV        *hex_sv;
    STRLEN     in_len;
    const char *in;
    SV        *out_sv;
    char      *out_buf;
    ptrdiff_t  written;
CODE:
    /* must be a ref to a scalar */
    if (!SvROK(hex_ref)) {
        croak("hex_to_binary() expects a reference to a scalar");
    }

    hex_sv = SvRV(hex_ref);
    in     = SvOK(hex_sv) ? SvPVbyte(hex_sv, in_len) : "";

    /* empty input -> empty output */
    if (in_len == 0) {
        RETVAL = newSVpvn("", 0);
    } else {
        /* must be even length */
        if ((in_len & 1) != 0) {
            croak("hex_to_binary() input length (%" IVdf ") is not even", (IV)in_len);
        }

        /* allocate N/2 bytes */
        out_sv  = newSV(in_len / 2);
        SvPOK_on(out_sv);
        SvCUR_set(out_sv, in_len / 2);
        out_buf = SvPVX(out_sv);

        written = hex_to_bytes(in,
                               (size_t)in_len,
                               (uint8_t *)out_buf,
                               /* strict */ 1);

        if (written < 0) {
            SvREFCNT_dec(out_sv);
            croak("hex_to_binary() invalid hex input");
        }

        /* in case C returned less */
        SvCUR_set(out_sv, (STRLEN)written);
        out_buf[written] = '\0';

        RETVAL = out_sv;
    }
OUTPUT:
    RETVAL

SV *
binary_to_hex(SV *bin_ref)
PREINIT:
    SV              *bin_sv;
    STRLEN           in_len;
    const unsigned char *in;
    SV              *out_sv;
    char            *out_buf;
    ptrdiff_t        written;
CODE:
    if (!SvROK(bin_ref)) {
        croak("binary_to_hex() expects a reference to a scalar");
    }

    bin_sv = SvRV(bin_ref);
    in     = SvOK(bin_sv) ? (const unsigned char *)SvPVbyte(bin_sv, in_len)
                          : (const unsigned char *)"";

    /* empty input -> empty hex */
    if (in_len == 0) {
        RETVAL = newSVpvn("", 0);
    } else {
        out_sv  = newSV(in_len * 2);
        SvPOK_on(out_sv);
        SvCUR_set(out_sv, in_len * 2);
        out_buf = SvPVX(out_sv);

        written = bytes_to_hex(in, (size_t)in_len, out_buf);
        if (written < 0) {
            SvREFCNT_dec(out_sv);
            croak("binary_to_hex() conversion failed");
        }

        SvCUR_set(out_sv, (STRLEN)written);
        out_buf[written] = '\0';

        RETVAL = out_sv;
    }
OUTPUT:
    RETVAL

const char *
hex_to_binary_impl()
CODE:
    RETVAL = hexsimd_hex2bin_impl_name();
OUTPUT:
    RETVAL

const char *
binary_to_hex_impl()
CODE:
    RETVAL = hexsimd_bin2hex_impl_name();
OUTPUT:
    RETVAL
