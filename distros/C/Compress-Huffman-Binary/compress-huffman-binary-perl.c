/* Perl bits of the module. This is incorporated into "Binary.xs" by
   the compiler, thus it doesn't need to have many header files. */

#include "huffman.h"

// Unused as yet.

typedef struct {

}
compress_huffman_binary_t;

// Unused as yet.

static int
perl_error_handler (const char * file, int line_number, const char * msg, ...)
{
    va_list args;
    va_start (args, msg);
    vcroak (msg, & args);
    va_end (args);
    return 0;
}

static SV *
perl_huffman_encode (SV * in)
{
    unsigned char * cin;
    STRLEN cinlen;
    unsigned char * out;
    unsigned int outlen;
    int rc;
    SV * RETVAL;
    cin = (unsigned char *) SvPV (in, cinlen);
    if (cinlen == 0) {
	warn ("Empty input");
	return & PL_sv_undef;
    }
    rc = huffman_encode_memory (cin, (unsigned int) cinlen, & out, & outlen);
    if (rc != 0) {
	croak ("Error encoding scalar");
	RETVAL = & PL_sv_undef;
    }
    else {
	RETVAL = newSVpv ((char *) out, (STRLEN) outlen);
    }
    if (out) {
	free (out);
    }
    return RETVAL;
}

static SV *
perl_huffman_decode (SV * in)
{
    unsigned char * cin;
    STRLEN cinlen;
    unsigned char * out;
    unsigned int outlen;
    int rc;
    SV * RETVAL;

    cin = (unsigned char *) SvPV (in, cinlen);
    if (cinlen == 0) {
	warn ("Empty input");
	return & PL_sv_undef;
    }
    rc = huffman_decode_memory (cin, (unsigned int) cinlen, & out, & outlen);
    if (rc != 0) {
	croak ("Error decoding scalar");
	RETVAL = & PL_sv_undef;
    }
    else {
	RETVAL = newSVpv ((char *) out, (STRLEN) outlen);
    }
    RETVAL = newSVpv ((char *) out, (STRLEN) outlen);
    if (out) {
	free (out);
    }
    return RETVAL;
}
