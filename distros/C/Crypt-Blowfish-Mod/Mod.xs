#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "blowfish.h"

MODULE = Crypt::Blowfish::Mod PACKAGE = Crypt::Blowfish::Mod
PROTOTYPES: DISABLE

char *
b_encrypt (key, str, big, b_signed)
    unsigned char *key
    char *str
    short big
    short b_signed

char *
b_decrypt (key, str, big)
    unsigned char *key
    char *str
    short big
