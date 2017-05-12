#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ofa1/ofa.h>


MODULE = Audio::Ofa          PACKAGE = Audio::Ofa

SV *
ofa_get_version()
PREINIT:
    int major, minor, rev;
CODE:
    ofa_get_version(&major, &minor, &rev);

    RETVAL = newSVpvf("%d.%d.%d", major, minor, rev);
OUTPUT:
    RETVAL

const char *
ofa_create_print(samples, byteOrder, size, sRate, stereo)
    unsigned char *samples;
    int byteOrder;
    long size;
    int sRate;
    int stereo;
PREINIT:
    STRLEN len;
INIT:
    SvPV(ST(0), len);
    if (size * 2 > len) {
        croak("The buffer (%ld bytes) is too small for %ld 16-bit samples",
            len, size);
    }
    if (size < 0) {
        croak("Negative size");
    }
CODE:
    /* warn("Running ofa_create_print 0x%x, %d, %ld, %d, %d", samples, byteOrder, size, sRate, stereo); */
    RETVAL = ofa_create_print(samples, byteOrder, size, sRate, stereo);
    /* warn("RETVAL is %x", RETVAL); */
OUTPUT: RETVAL

int
OFA_LITTLE_ENDIAN()
PROTOTYPE:
CODE:
    RETVAL = OFA_LITTLE_ENDIAN;
OUTPUT: RETVAL

int
OFA_BIG_ENDIAN()
PROTOTYPE:
CODE:
    RETVAL = OFA_BIG_ENDIAN;
OUTPUT: RETVAL
