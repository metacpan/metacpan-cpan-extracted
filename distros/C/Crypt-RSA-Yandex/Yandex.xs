#include "CP_RSA.h"

#ifdef __cplusplus 
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus 
}
#endif

MODULE = Crypt::RSA::Yandex		PACKAGE = Crypt::RSA::Yandex		
PROTOTYPES: DISABLE

CCryptoProviderRSA *
CCryptoProviderRSA::new()

void
CCryptoProviderRSA::DESTROY()

void
CCryptoProviderRSA::import_public_key(key)
    char *key;
CODE:
    try {
        THIS->ImportPublicKey(key);
    }
    catch (char * e) {
        croak("Exception while CCryptoProviderRSA::ImportPublicKey: %s", e);
    }
    catch (...) {
        croak("Exception while CCryptoProviderRSA::ImportPublicKey");
    }

SV *
CCryptoProviderRSA::encrypt(text)
    SV *text;
PREINIT:
    char crypted_text[MAX_CRYPT_BITS / sizeof(char)] = "\0";
    size_t crypted_len = 0;
    STRLEN text_len;
    char*  text_ptr;
CODE:
    text_ptr = SvPV( text, text_len );
    try {
        THIS->Encrypt( text_ptr, text_len, crypted_text, crypted_len );
    }
    catch (char * e) {
        croak("Exception while CCryptoProviderRSA::ImportPublicKey: %s", e);
    }
    catch (...) {
        croak("Exception while CCryptoProviderRSA::ImportPublicKey");
    }
    RETVAL = newSVpvn( crypted_text, crypted_len );
OUTPUT:
    RETVAL

