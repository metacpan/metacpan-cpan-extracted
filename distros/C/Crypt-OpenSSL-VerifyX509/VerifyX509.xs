#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/asn1.h>
#include <openssl/objects.h>
#include <openssl/bio.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

typedef X509_STORE*  Crypt__OpenSSL__VerifyX509;
typedef X509*  Crypt__OpenSSL__X509;

static int verify_cb(int ok, X509_STORE_CTX *ctx) {
  if (!ok)
    switch (ctx->error) {
    case X509_V_ERR_CERT_HAS_EXPIRED:
 /* case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT: */
    case X509_V_ERR_INVALID_CA:
    case X509_V_ERR_PATH_LENGTH_EXCEEDED:
    case X509_V_ERR_INVALID_PURPOSE:
    case X509_V_ERR_CRL_HAS_EXPIRED:
    case X509_V_ERR_CRL_NOT_YET_VALID:
    case X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION:
      ok = 1;
      break;
    }
  return(ok);
}

static const char *ssl_error(void) {
  return ERR_error_string(ERR_get_error(), NULL);
}

static const char *ctx_error(X509_STORE_CTX *ctx) {
  return X509_verify_cert_error_string(ctx->error);
}

MODULE = Crypt::OpenSSL::VerifyX509    PACKAGE = Crypt::OpenSSL::VerifyX509

PROTOTYPES: DISABLE

BOOT:
  ERR_load_crypto_strings();
  ERR_load_ERR_strings();
  OpenSSL_add_all_algorithms();

Crypt::OpenSSL::VerifyX509
new(class, cafile_str)
  SV *class
  SV *cafile_str

  PREINIT:
  
  int i = 1;
  X509_LOOKUP *lookup = NULL;
  STRLEN len;
  char *cafile;

  CODE:

  (void) SvPV_nolen(class);

  RETVAL = X509_STORE_new();
  if (RETVAL == NULL)
    croak("failure to allocate x509 store: %s", ssl_error());

  X509_STORE_set_verify_cb_func(RETVAL,verify_cb);
  
  /* load CA file given */
  lookup = X509_STORE_add_lookup(RETVAL, X509_LOOKUP_file());
  if (lookup == NULL) 
    croak("failure to add file lookup to store: %s", ssl_error());

  cafile = SvPV(cafile_str, len);
  i = X509_LOOKUP_load_file(lookup, cafile, X509_FILETYPE_PEM);

  if (!i)
    croak("load CA cert: %s", ssl_error());
  
  /* default hash_dir lookup */
  lookup = X509_STORE_add_lookup(RETVAL,X509_LOOKUP_hash_dir());
  if (lookup == NULL) 
    croak("failure to add hash_dir lookup to store: %s", ssl_error());
  
  X509_LOOKUP_add_dir(lookup,NULL,X509_FILETYPE_DEFAULT);  

  ERR_clear_error();

  OUTPUT:
  RETVAL

int
verify(store, x509)
  Crypt::OpenSSL::VerifyX509 store;
  Crypt::OpenSSL::X509 x509;

  PREINIT:
  
  X509_STORE_CTX *csc;

  CODE:
  
  if (x509 == NULL)
    croak("no cert to verify");

  csc = X509_STORE_CTX_new();
  if (csc == NULL)
    croak("csc new: %s", ssl_error());
    
  X509_STORE_set_flags(store, 0);

  if (!X509_STORE_CTX_init(csc,store,x509,NULL))
    croak("store ctx init: %s", ssl_error());
    
  RETVAL = X509_verify_cert(csc);
  X509_STORE_CTX_free(csc);

  if (!RETVAL)
    croak("verify: %s", ctx_error(csc));

  OUTPUT:
  RETVAL

void
DESTROY(store)
  Crypt::OpenSSL::VerifyX509 store;

  PPCODE:

  if (store) X509_STORE_free(store); store = 0;

void
__X509_cleanup(void)
  PPCODE:

  CRYPTO_cleanup_all_ex_data();
  ERR_free_strings();
  ERR_remove_state(0);
  EVP_cleanup();
