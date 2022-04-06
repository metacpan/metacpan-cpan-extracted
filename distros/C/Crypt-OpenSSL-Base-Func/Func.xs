#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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


MODULE = Crypt::OpenSSL::Base::Func		PACKAGE = Crypt::OpenSSL::Base::Func		


int OBJ_sn2nid (const char *s)

EC_GROUP *EC_GROUP_new_by_curve_name(int nid);

const BIGNUM *EC_GROUP_get0_cofactor(const EC_GROUP *group)

int EC_GROUP_get_curve(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx)

int EC_POINT_set_affine_coordinates(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx)

int EC_POINT_get_affine_coordinates(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

char *EC_POINT_point2hex(const EC_GROUP *group, const EC_POINT *p, point_conversion_form_t form, BN_CTX *ctx)

EC_POINT *EC_POINT_hex2point(const EC_GROUP *group, const char *hex, EC_POINT *p, BN_CTX *ctx)

const BIGNUM *EC_KEY_get0_private_key(const EC_KEY *key);


const EVP_MD *EVP_get_digestbyname(const char *name)

int EVP_MD_size(const EVP_MD *md)

int EVP_MD_block_size(const EVP_MD *md)


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


    EVP_PKEY_CTX *ctx;
    ctx = EVP_PKEY_CTX_new(pkey, NULL);

    EVP_PKEY_derive_init(ctx);

    EVP_PKEY_derive_set_peer(ctx, peer_pubkey);

    EVP_PKEY_derive(ctx, NULL, &zlen);

    z = OPENSSL_malloc(zlen);

    EVP_PKEY_derive(ctx, z, &zlen);

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
