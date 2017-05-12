#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/blowfish.h>

MODULE = Crypt::OpenSSL::Blowfish PACKAGE = Crypt::OpenSSL::Blowfish PREFIX = blowfish_
PROTOTYPES: DISABLE

char * blowfish_init(key)
    unsigned char * key = NO_INIT
    STRLEN key_len = NO_INIT
    CODE:
    {
        char ks[8192];
        key = (unsigned char *) SvPV(ST(0), key_len);
        if (key_len < 8 || key_len > 56) {
            croak("Invalid length key");
        }
        
        BF_set_key((BF_KEY *)ks, key_len, key);
        ST(0) = sv_2mortal(newSVpv(ks, sizeof(ks)));
    }

void blowfish_crypt(data, ks, dir)
    char * data = NO_INIT
    STRLEN data_len = NO_INIT
    char * ks
    int dir
    CODE:
    {
        data = (char *) SvPV(ST(0), data_len);
        if (data_len != 8) {
            croak("data must be 8 bytes long");
        }
        
        if (dir) {
            BF_decrypt((BF_LONG *)data, (BF_KEY *)ks);
        } else {
            BF_encrypt((BF_LONG *)data, (BF_KEY *)ks);
        }
    }
