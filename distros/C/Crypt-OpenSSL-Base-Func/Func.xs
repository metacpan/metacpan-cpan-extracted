#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/cmac.h>
#include <openssl/crypto.h>

#define PACKAGE_NAME "Crypt::OpenSSL::Base::Func"


MODULE = Crypt::OpenSSL::Base::Func		PACKAGE = Crypt::OpenSSL::Base::Func
PROTOTYPES: DISABLE

unsigned char*
aes_cmac(key_hexstr, msg_hexstr, cipher_name)
    unsigned char *key_hexstr;
    unsigned char *msg_hexstr;
    unsigned char *cipher_name;
  PREINIT:
    unsigned char *mac_hexstr;
  CODE:
{
  long key_len;
  unsigned char *key = OPENSSL_hexstr2buf(key_hexstr, &key_len);
  
  long msg_len;
  unsigned char *msg = OPENSSL_hexstr2buf(msg_hexstr, &msg_len);

 const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
 
 size_t block_size = EVP_CIPHER_block_size(cipher);

 unsigned char *mact = OPENSSL_malloc(block_size); 

  CMAC_CTX *ctx = CMAC_CTX_new();
  CMAC_Init(ctx, key, block_size, cipher, NULL);
 
  CMAC_Update(ctx, msg, msg_len);
  CMAC_Final(ctx, mact, &block_size);

  CMAC_CTX_free(ctx);

  unsigned char* mac_hexstr = OPENSSL_buf2hexstr(mact, block_size);

    OPENSSL_free(key);
    OPENSSL_free(msg);
    OPENSSL_free(mact);

    RETVAL = mac_hexstr;
}
  OUTPUT:
    RETVAL 

