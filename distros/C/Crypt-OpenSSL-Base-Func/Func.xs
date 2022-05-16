#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <openssl/ssl.h>
#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/cmac.h>
#include <openssl/crypto.h>
#include <openssl/ec.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/objects.h>
#include <openssl/pem.h>
#include <openssl/pkcs12.h>

#include "basefunc.c"

MODULE = Crypt::OpenSSL::Base::Func		PACKAGE = Crypt::OpenSSL::Base::Func		

EC_GROUP *EC_GROUP_new_by_curve_name(int nid)

EC_KEY *EVP_PKEY_get1_EC_KEY(EVP_PKEY *pkey)

EC_POINT* EC_POINT_hex2point(const EC_GROUP *group, const char *hex, EC_POINT *p, BN_CTX *ctx)

EVP_PKEY* EVP_PKEY_new()

char *EC_POINT_point2hex(const EC_GROUP *group, const EC_POINT *p, point_conversion_form_t form, BN_CTX *ctx)

const BIGNUM *EC_GROUP_get0_cofactor(const EC_GROUP *group)

const BIGNUM *EC_KEY_get0_private_key(const EC_KEY *key)

const EVP_MD *EVP_get_digestbyname(const char *name)

int EC_GROUP_get_curve(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx)

int EC_KEY_set_private_key(EC_KEY *key, const BIGNUM *prv)

int EC_POINT_get_affine_coordinates(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int EC_POINT_set_affine_coordinates(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx)

int EVP_MD_block_size(const EVP_MD *md)

int EVP_MD_size(const EVP_MD *md)

int EVP_PKEY_assign_EC_KEY(EVP_PKEY *pkey, EC_KEY *key)

int OBJ_sn2nid (const char *s)



EVP_PKEY* evp_pkey_from_point_hex(EC_GROUP* group, char* point_hex, BN_CTX* ctx)

EVP_PKEY* evp_pkey_from_priv_hex(EC_GROUP* group, char* priv_hex)

EVP_PKEY* pem_read_pkey(char* keyfile, int is_priv)

int ecdh_pkey_raw(EVP_PKEY *pkey_priv, EVP_PKEY *pkey_peer_pub, unsigned char **z)

int pem_write_evp_pkey(char* dst_fname, EVP_PKEY* pkey, int is_priv)

char* pem_read_priv_hex(char* keyfile) 

char* pem_read_pub_hex(char* keyfile, int point_compress_t)

int aead_encrypt_raw(unsigned char *cipher_name, unsigned char *plaintext, int plaintext_len, unsigned char *aad, int aad_len, unsigned char *key, unsigned char *iv, int iv_len, unsigned char **ciphertext, unsigned char *tag, int tag_len)

int aead_decrypt_raw( unsigned char *cipher_name, unsigned char *ciphertext, int ciphertext_len, unsigned char *aad, int aad_len, unsigned char *tag, int tag_len, unsigned char *key, unsigned char *iv, int iv_len, unsigned char **plaintext)

SV* aead_decrypt(cipher_name, ciphertext_SV, aad_SV, tag_SV, key_SV, iv_SV)
    unsigned char *cipher_name;
    SV* ciphertext_SV;
    SV* aad_SV;
    SV* tag_SV;
    SV* key_SV; 
    SV* iv_SV;
  PREINIT:
    SV *res;
    unsigned char *plaintext;
    int plaintext_len;
    unsigned char *ciphertext;
    STRLEN ciphertext_len;
    unsigned char *aad;
    STRLEN aad_len;
    unsigned char *tag;
    STRLEN tag_len;
    unsigned char *key;
    STRLEN key_len;
    unsigned char *iv;
    STRLEN iv_len;
  CODE:
{
    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);

    ciphertext = (unsigned char*) SvPV( ciphertext_SV, ciphertext_len );
    aad = (unsigned char*) SvPV( aad_SV, aad_len );
    tag = (unsigned char*) SvPV( tag_SV, tag_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    plaintext = malloc(ciphertext_len);
    plaintext_len = aead_decrypt_raw(cipher_name, ciphertext, (int) ciphertext_len, aad, (int) aad_len, tag, (int) tag_len, key, iv, (int) iv_len, &plaintext);

    res = newSVpv(plaintext, plaintext_len);

    RETVAL = res;
}
  OUTPUT:
    RETVAL

SV* aead_encrypt(cipher_name, plaintext_SV, aad_SV, key_SV, iv_SV, tag_len)
    unsigned char *cipher_name;
    SV* plaintext_SV;
    SV* aad_SV;
    SV* key_SV; 
    SV* iv_SV;
    int tag_len;
  PREINIT:
    SV* ciphertext_SV ;
    SV* tag_SV ;
    unsigned char *plaintext;
    STRLEN plaintext_len;
    unsigned char *aad;
    STRLEN aad_len;
    unsigned char *key;
    STRLEN key_len;
    unsigned char *iv;
    STRLEN iv_len;
    unsigned char *ciphertext;
    int ciphertext_len;
    unsigned char *tag;
  CODE:
{
    AV* av = newAV();
    RETVAL = newRV_noinc((SV*)av);

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);

    plaintext = (unsigned char*) SvPV( plaintext_SV, plaintext_len );
    aad = (unsigned char*) SvPV( aad_SV, aad_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    tag = malloc(tag_len);
    ciphertext = malloc(plaintext_len);
    ciphertext_len = aead_encrypt_raw(cipher_name, plaintext, plaintext_len, aad, aad_len, key, iv, iv_len, &ciphertext, tag, tag_len);

    ciphertext_SV = newSVpv(ciphertext, ciphertext_len);
    tag_SV = newSVpv(tag, tag_len);

    av_push(av, ciphertext_SV);
    av_push(av, tag_SV);

    /*SV* res = newSVsv(ciphertext_SV);*/
    /*sv_catsv(res, tag_SV);*/
    /*RETVAL = res;*/
}
  OUTPUT:
    RETVAL


EC_POINT*
hex2point(group, point_hex)
    EC_GROUP *group;
    const char *point_hex;
  CODE:
  {
    BN_CTX *ctx = BN_CTX_new();

    EC_POINT* ec_point = EC_POINT_new(group);
    ec_point = EC_POINT_hex2point(group, point_hex, ec_point, ctx); 

    BN_CTX_free(ctx);

    RETVAL = ec_point;
  }
  OUTPUT:
    RETVAL


SV*
digest(self, bin_SV)
    EVP_MD *self;
    SV* bin_SV;
  PREINIT:
    SV* res;
    unsigned char* dgst;
    unsigned int dgst_length;
    unsigned char* bin;
    STRLEN bin_length;
  CODE:
  {
    bin = (unsigned char*) SvPV( bin_SV, bin_length );
    dgst = malloc(EVP_MD_size(self));
    EVP_Digest(bin, bin_length, dgst, &dgst_length, self, NULL);
    res = newSVpv(dgst, dgst_length);
    RETVAL = res;
  }
  OUTPUT:
    RETVAL

SV*
ecdh_pkey(pkey, peer_pubkey)
    EVP_PKEY* pkey;
    EVP_PKEY* peer_pubkey;
  PREINIT:
    unsigned char *z;
    STRLEN zlen;
    SV* res;
  CODE:
{

    zlen = ecdh_pkey_raw(pkey, peer_pubkey, &z);
    res = newSVpv(z, zlen);
    RETVAL = res;
}
  OUTPUT:
    RETVAL


SV*
ecdh(local_priv_pem, peer_pub_pem)
    unsigned char *local_priv_pem;
    unsigned char *peer_pub_pem;
  PREINIT:
    unsigned char *z;
    STRLEN zlen;
    SV* res;
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

    zlen = ecdh_pkey_raw(pkey, peer_pubkey, &z);

    res = newSVpv(z, zlen);

    RETVAL = res;
}
  OUTPUT:
    RETVAL

SV*
aes_cmac(key_SV, msg_SV, cipher_name)
    SV *key_SV;
    SV *msg_SV;
    unsigned char *cipher_name;
  PREINIT:
    unsigned char *key;
    STRLEN keylen;
    unsigned char *msg;
    STRLEN msglen;
    unsigned char *mac;
    SV* res;
  CODE:
{
    key = (unsigned char*) SvPV( key_SV, keylen );
    msg = (unsigned char*) SvPV( msg_SV, msglen );

     const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
     size_t block_size = EVP_CIPHER_block_size(cipher);

     mac = OPENSSL_malloc(block_size); 
      CMAC_CTX *ctx = CMAC_CTX_new();
      CMAC_Init(ctx, key, block_size, cipher, NULL);
     
      CMAC_Update(ctx, msg, msglen);
      CMAC_Final(ctx, mac, &block_size);

      CMAC_CTX_free(ctx);

      res = newSVpv(mac, block_size);

      RETVAL = res;
}
  OUTPUT:
      RETVAL


SV*
PKCS12_key_gen(password_SV, salt_SV, id, iteration, outlen, digest_name)
    SV *password_SV;
    SV *salt_SV;
    unsigned int id;
    unsigned int iteration;
    unsigned int outlen;
    unsigned char *digest_name;
  PREINIT:
    unsigned char *password;
    STRLEN passlen;
    unsigned char *salt;
    STRLEN saltlen;
    unsigned char *out;
    SV* res;
  CODE:
{
    password = (unsigned char*) SvPV( password_SV, passlen );
    salt = (unsigned char*) SvPV( salt_SV, saltlen );

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    unsigned char *out = OPENSSL_malloc(EVP_MAX_MD_SIZE); 
    PKCS12_key_gen(password, passlen, salt, saltlen, id, iteration, outlen, out, digest);
    res = newSVpv(out, outlen);

    RETVAL = res;
}
  OUTPUT:
    RETVAL


SV*
PKCS5_PBKDF2_HMAC(password_SV, salt_SV, iteration, digest_name, outlen)
    SV *password_SV;
    SV *salt_SV;
    unsigned int iteration;
    unsigned char *digest_name;
    unsigned int outlen;
  PREINIT:
    unsigned char *password;
    STRLEN passlen;
    unsigned char *salt;
    STRLEN saltlen;
    unsigned char *out;
    SV* res;
  CODE:
  {
    password = (unsigned char*) SvPV( password_SV, passlen );
    salt = (unsigned char*) SvPV( salt_SV, saltlen );

    const EVP_MD *digest = EVP_get_digestbyname(digest_name);

    out = OPENSSL_malloc(outlen); 
    PKCS5_PBKDF2_HMAC(password, passlen, salt, saltlen, iteration, digest, outlen, out);
    res = newSVpv(out, outlen);

    RETVAL = res;
  }
  OUTPUT:
    RETVAL


unsigned char*
bn_mod_sqrt(a, p)
    unsigned char *a;
    unsigned char *p;
  PREINIT:
    unsigned char *s;
  CODE:
{

    BN_CTX *ctx;
    BIGNUM *bn_a, *bn_p, *bn_s, *ret;

    ctx = BN_CTX_new();

    bn_a = BN_new();
    BN_hex2bn(&bn_a, a); 

    bn_p = BN_new();
    BN_hex2bn(&bn_p, p);

    bn_s = BN_new();
    ret = BN_mod_sqrt(bn_s, bn_a, bn_p, ctx);

    if(ret != NULL){
        s = BN_bn2hex(bn_s);
    }else{
        s = "";
    }

    BN_free(bn_a);
    BN_free(bn_p);
    BN_free(bn_s);
    BN_CTX_free(ctx);

    RETVAL = s;
}
  OUTPUT:
    RETVAL
