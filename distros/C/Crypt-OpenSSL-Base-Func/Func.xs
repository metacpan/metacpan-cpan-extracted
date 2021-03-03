#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/bio.h>
#include <openssl/cmac.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/pkcs12.h>

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


unsigned char*
ecdh(local_priv_pem, peer_pub_pem)
    unsigned char *local_priv_pem;
    unsigned char *peer_pub_pem;
  PREINIT:
    unsigned char *z_hexstr;
  CODE:
{

    FILE *keyfile = fopen(local_priv_pem, "r");
    EVP_PKEY *pkey = NULL;
    pkey = PEM_read_PrivateKey(keyfile, NULL, NULL, NULL);
    //printf("\nRead Local Private Key:\n");
    //PEM_write_PrivateKey(stdout, pkey, NULL, NULL, 0, NULL, NULL);

    FILE *peer_pubkeyfile = fopen(peer_pub_pem, "r");
    EVP_PKEY *peer_pubkey = NULL;
    peer_pubkey = PEM_read_PUBKEY(peer_pubkeyfile, NULL, NULL, NULL);
    //printf("\nRead Peer PUBKEY Key:\n");
    //PEM_write_PUBKEY(stdout, peer_pubkey);


    EVP_PKEY_CTX *ctx;
    unsigned char *z;
    size_t zlen;
    ctx = EVP_PKEY_CTX_new(pkey, NULL);

    EVP_PKEY_derive_init(ctx);

    EVP_PKEY_derive_set_peer(ctx, peer_pubkey);

    EVP_PKEY_derive(ctx, NULL, &zlen);

    z = OPENSSL_malloc(zlen);

    EVP_PKEY_derive(ctx, z, &zlen);

    unsigned char* z_hexstr = OPENSSL_buf2hexstr(z, zlen);

    OPENSSL_free(z);

    RETVAL = z_hexstr;
}
  OUTPUT:
    RETVAL 

unsigned char*
PKCS12_key_gen(password, salt_hexstr, id, iteration, outlen, digest_name)
    unsigned char *password;
    unsigned char *salt_hexstr;
    unsigned int id;
    unsigned int iteration;
    unsigned int outlen;
    unsigned char *digest_name;
  PREINIT:
    unsigned char *out_hexstr;
  CODE:
{
    int passlen = strlen(password);

    long salt_hexstr_len = strlen(salt_hexstr);
    unsigned char *salt = OPENSSL_hexstr2buf(salt_hexstr, &salt_hexstr_len);
    int saltlen = strlen(salt);

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    unsigned char *out = OPENSSL_malloc(EVP_MAX_MD_SIZE); 
    PKCS12_key_gen(password, passlen, salt, saltlen, id, iteration, outlen, out, digest);
    out_hexstr = OPENSSL_buf2hexstr(out, outlen);

    OPENSSL_free(salt);
    OPENSSL_free(out);

    RETVAL = out_hexstr;
}
  OUTPUT:
    RETVAL 



unsigned char*
PKCS5_PBKDF2_HMAC(password, salt_hexstr, iteration, digest_name, outlen)
    unsigned char *password;
    unsigned char *salt_hexstr;
    unsigned int iteration;
    unsigned char *digest_name;
    unsigned int outlen;
  PREINIT:
    unsigned char *out_hexstr;
  CODE:
{
    int passlen = strlen(password);

    long salt_hexstr_len = strlen(salt_hexstr);
    unsigned char *salt = OPENSSL_hexstr2buf(salt_hexstr, &salt_hexstr_len);
    int saltlen = strlen(salt);

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    unsigned char *out = OPENSSL_malloc(outlen); 
    PKCS5_PBKDF2_HMAC(password, passlen, salt, saltlen, iteration, digest, outlen, out);
    out_hexstr = OPENSSL_buf2hexstr(out, outlen);

    OPENSSL_free(salt);
    OPENSSL_free(out);

    RETVAL = out_hexstr;
}
  OUTPUT:
    RETVAL 
