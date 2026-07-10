#include <stdbool.h>
#include <stdint.h>
#if defined(_WIN32)
#define BF_EXPORT __declspec(dllexport)
#else
#define BF_EXPORT
#endif
#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/cmac.h>
#include <openssl/core_names.h>
#include <openssl/crypto.h>
#include <openssl/ec.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/kdf.h>
#include <openssl/objects.h>
#include <openssl/params.h>
#include <openssl/pem.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


BF_EXPORT bool is_empty(unsigned char *s) {
  if (strlen(s) == 0)
    return true;

  return false;
}

BF_EXPORT void hexdump(unsigned char *info, unsigned char *buf, const int num) {
  int i;
  printf("\n%s, %d\n", info, num);

  for (i = 0; i < num; i++) {
    printf("%02x", buf[i]);
  }
  printf("\n");

  for (i = 0; i < num; i++) {
    printf("%02x ", buf[i]);
    if ((i + 1) % 8 == 0)
      printf("\n");
  }
  printf("\n");
  return;
}

BF_EXPORT size_t slurp(unsigned char *fname, unsigned char **buf) {
  /* declare a file pointer */
  FILE *infile;
  size_t buf_len;

  infile = fopen(fname, "r");

  if (infile == NULL)
    return 0;

  fseek(infile, 0L, SEEK_END);
  buf_len = ftell(infile);

  fseek(infile, 0L, SEEK_SET);

  *buf = (unsigned char *)calloc(buf_len, sizeof(unsigned char));

  if (*buf == NULL)
    return 1;

  int ret = fread(*buf, sizeof(unsigned char), buf_len, infile);
  fclose(infile);

  return buf_len;
}

BF_EXPORT BIGNUM *hex2bn(unsigned char *a) {
  BIGNUM *bn_a = BN_new();
  BN_hex2bn(&bn_a, a);
  return bn_a;
}

BF_EXPORT BIGNUM* bn_value_one(void) {
  return BN_dup(BN_value_one());
}

BF_EXPORT int bn_one(BIGNUM *a) {
  return BN_one(a);
}

BF_EXPORT void bn_zero(BIGNUM *a) {
  BN_zero(a);
}

BF_EXPORT int bn2bin(const BIGNUM *a, unsigned char **to) {
  int len = BN_num_bytes(a);
  if (len <= 0) {
    *to = NULL;
    return 0;
  }
  *to = OPENSSL_malloc(len);
  if (*to == NULL) {
    return -1;
  }
  BN_bn2bin(a, *to);
  return len;
}

BF_EXPORT unsigned char *bin2hex(unsigned char *bin, size_t bin_len) {

  unsigned char *out = NULL;
  size_t out_len;
  size_t n = bin_len * 2 + 1;

  out = OPENSSL_malloc(n);
  OPENSSL_buf2hexstr_ex(out, n, &out_len, (const unsigned char *)bin, bin_len,
                        '\0');

  return out;
}

BF_EXPORT BIGNUM *get_pkey_bn_param(EVP_PKEY *pkey, unsigned char *param_name) {
  BIGNUM *x_bn = NULL;

  int ret = EVP_PKEY_get_bn_param(pkey, param_name, &x_bn);

  return x_bn;
}

BF_EXPORT size_t get_pkey_octet_string_param(EVP_PKEY *pkey,
    unsigned char *param_name,
    unsigned char **s) {
  size_t s_len;

  EVP_PKEY_get_octet_string_param(pkey, param_name, NULL, 0, &s_len);
  *s = OPENSSL_malloc(s_len);
  EVP_PKEY_get_octet_string_param(pkey, param_name, *s, s_len, NULL);

  return s_len;
}

BF_EXPORT unsigned char *get_pkey_utf8_string_param(EVP_PKEY *pkey,
    unsigned char *param_name) {
  unsigned char *s = NULL;
  size_t s_len;

  EVP_PKEY_get_utf8_string_param(pkey, param_name, NULL, 0, &s_len);
  s = OPENSSL_malloc(s_len);
  int ret = EVP_PKEY_get_utf8_string_param(pkey, param_name, s, s_len, NULL);

  if (ret) {
    OPENSSL_free(s);
    return NULL;
  }

  return s;
}

BF_EXPORT EVP_PKEY *export_rsa_pubkey(EVP_PKEY *rsa_priv) {

  OSSL_LIB_CTX *libctx = NULL;
  EVP_PKEY_CTX *ctx = NULL;
  EVP_PKEY *rsa_pub = NULL;
  OSSL_PARAM params[3];
  BIGNUM *n = NULL, *e = NULL;
  size_t n_bin_len, e_bin_len;
  unsigned char *n_bin = NULL, *e_bin = NULL;

  EVP_PKEY_get_bn_param(rsa_priv, OSSL_PKEY_PARAM_RSA_N, &n);
  EVP_PKEY_get_bn_param(rsa_priv, OSSL_PKEY_PARAM_RSA_E, &e);

  n_bin_len = BN_num_bytes(n);
  n_bin = OPENSSL_malloc(n_bin_len);
  BN_bn2nativepad(n, n_bin, n_bin_len);

  e_bin_len = BN_num_bytes(e);
  e_bin = OPENSSL_malloc(e_bin_len);
  BN_bn2nativepad(e, e_bin, e_bin_len);

  params[0] = OSSL_PARAM_construct_BN(OSSL_PKEY_PARAM_RSA_N, n_bin, n_bin_len);
  params[1] = OSSL_PARAM_construct_BN(OSSL_PKEY_PARAM_RSA_E, e_bin, e_bin_len);
  params[2] = OSSL_PARAM_construct_end();

  ctx = EVP_PKEY_CTX_new_from_name(libctx, "RSA", NULL);
  EVP_PKEY_CTX_set_params(ctx, params);

  EVP_PKEY_fromdata_init(ctx);
  EVP_PKEY_fromdata(ctx, &rsa_pub, EVP_PKEY_PUBLIC_KEY, params);

  EVP_PKEY_CTX_free(ctx);
  OSSL_LIB_CTX_free(libctx);
  BN_free(n);
  BN_free(e);
  OPENSSL_free(n_bin);
  OPENSSL_free(e_bin);

  return rsa_pub;
}

BF_EXPORT size_t rsa_oaep_encrypt(unsigned char *digest_name, EVP_PKEY *pub,
                                  unsigned char *in, size_t in_len,
                                  unsigned char **out) {
  int ret = 0;
  OSSL_LIB_CTX *libctx = NULL;
  EVP_PKEY_CTX *ctx = NULL;
  char *propq = NULL;
  size_t out_len;

  OSSL_PARAM params[3];
  params[0] = OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_PAD_MODE,
              OSSL_PKEY_RSA_PAD_MODE_OAEP, 0);
  params[1] = OSSL_PARAM_construct_utf8_string(
                OSSL_ASYM_CIPHER_PARAM_OAEP_DIGEST, digest_name, 0);
  params[2] = OSSL_PARAM_construct_end();

  ctx = EVP_PKEY_CTX_new_from_pkey(libctx, pub, propq);
  EVP_PKEY_encrypt_init_ex(ctx, params);
  EVP_PKEY_encrypt(ctx, NULL, &out_len, in, in_len);
  *out = OPENSSL_zalloc(out_len);

  if (EVP_PKEY_encrypt(ctx, *out, &out_len, in, in_len) <= 0) {
    OPENSSL_free(*out);
    out_len = -1;
  }

  EVP_PKEY_CTX_free(ctx);

  return out_len;
}

BF_EXPORT size_t rsa_oaep_decrypt(unsigned char *digest_name, EVP_PKEY *priv,
                                  unsigned char *in, size_t in_len,
                                  unsigned char **out) {
  int ret = 0;
  OSSL_LIB_CTX *libctx = NULL;
  EVP_PKEY_CTX *ctx = NULL;
  char *propq = NULL;
  size_t out_len;

  OSSL_PARAM params[3];
  params[0] = OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_PAD_MODE,
              OSSL_PKEY_RSA_PAD_MODE_OAEP, 0);
  params[1] = OSSL_PARAM_construct_utf8_string(
                OSSL_ASYM_CIPHER_PARAM_OAEP_DIGEST, digest_name, 0);
  params[2] = OSSL_PARAM_construct_end();

  ctx = EVP_PKEY_CTX_new_from_pkey(libctx, priv, propq);
  EVP_PKEY_decrypt_init_ex(ctx, params);
  EVP_PKEY_decrypt(ctx, NULL, &out_len, in, in_len);
  *out = OPENSSL_zalloc(out_len);

  if (EVP_PKEY_decrypt(ctx, *out, &out_len, in, in_len) <= 0) {
    OPENSSL_free(*out);
    out_len = -1;
  }

  EVP_PKEY_CTX_free(ctx);

  return out_len;
}

BF_EXPORT unsigned char *read_key(EVP_PKEY *pkey) {
  BIGNUM *priv_bn = NULL;
  char *priv_hex = NULL;
  char *priv = NULL;
  size_t priv_len = 0;

  EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_PRIV_KEY, &priv_bn);

  if (priv_bn == NULL) {

    EVP_PKEY_get_raw_private_key(pkey, NULL, &priv_len);
    priv = OPENSSL_malloc(priv_len);
    EVP_PKEY_get_raw_private_key(pkey, priv, &priv_len);

    priv_bn = BN_bin2bn(priv, priv_len, NULL);
    OPENSSL_free(priv);
  }

  priv_hex = BN_bn2hex(priv_bn);

  BN_free(priv_bn);

  return priv_hex;
}

BF_EXPORT EVP_PKEY *read_key_from_der(unsigned char *keyfile) {

  EVP_PKEY *pkey = NULL;

  /*BIO *inf=NULL;*/
  /*inf = BIO_new_file(keyfile, "r");*/
  /*pkey = d2i_PrivateKey_bio(inf, &pkey);*/
  /*BIO_set_close(inf, BIO_CLOSE);*/

  FILE *inf = NULL;
  inf = fopen(keyfile, "r");
  pkey = d2i_PrivateKey_fp(inf, &pkey);
  fclose(inf);

  return pkey;
}

BF_EXPORT EVP_PKEY *read_pubkey_from_der(unsigned char *keyfile) {

  EVP_PKEY *pkey = NULL;

  unsigned char *buf = NULL;
  size_t buf_len = slurp(keyfile, &buf);

  d2i_PUBKEY(&pkey, (const unsigned char **)&buf, buf_len);

  return pkey;
}

BF_EXPORT EVP_PKEY *read_key_from_pem(unsigned char *keyfile) {

  EVP_PKEY *pkey = NULL;

  BIO *inf = NULL;
  inf = BIO_new_file(keyfile, "r");

  pkey = PEM_read_bio_PrivateKey(inf, NULL, NULL, NULL);
  BIO_free(inf);

  if (pkey == NULL) {
    inf = BIO_new_file(keyfile, "r");
    pkey = PEM_read_bio_PUBKEY(inf, NULL, NULL, NULL);
    BIO_free(inf);
  }

  return pkey;
}

BF_EXPORT EVP_PKEY *read_pubkey_from_pem(unsigned char *keyfile) {
  FILE *inf = fopen(keyfile, "r");

  EVP_PKEY *pkey = NULL;

  pkey = PEM_read_PUBKEY(inf, NULL, NULL, NULL);

  fclose(inf);

  return pkey;
}

BF_EXPORT unsigned char *read_pubkey(EVP_PKEY *pkey) {
  unsigned char *pub = NULL;
  unsigned char *phex = NULL;
  size_t pub_len;
  EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_ENCODED_PUBLIC_KEY,
                                  NULL, 0, &pub_len);
  /*EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_PUB_KEY, NULL,  0,
   * &pub_len);*/
  pub = OPENSSL_malloc(pub_len);
  EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_ENCODED_PUBLIC_KEY, pub,
                                  pub_len, NULL);
  /*EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_PUB_KEY, pub, pub_len,
   * &pub_len);*/

  if (pub) {
    phex = bin2hex(pub, pub_len);
    OPENSSL_free(pub);
  }
  return phex;
}

BF_EXPORT unsigned char *read_ec_pubkey(EVP_PKEY *pkey, int compressed_flag) {
  unsigned char *phex = NULL;
  if (compressed_flag) {
    EVP_PKEY_set_utf8_string_param(
      pkey, OSSL_PKEY_PARAM_EC_POINT_CONVERSION_FORMAT,
      OSSL_PKEY_EC_POINT_CONVERSION_FORMAT_COMPRESSED);
  }

  phex = read_pubkey(pkey);
  return phex;
}

BF_EXPORT BIGNUM *bn_mod_sqrt(BIGNUM *a, BIGNUM *p) {

  BN_CTX *ctx;

  ctx = BN_CTX_new();

  BIGNUM *s = BN_new();
  BN_mod_sqrt(s, a, p, ctx);

  BN_CTX_free(ctx);

  return s;
}

BF_EXPORT unsigned char *aes_cmac(unsigned char *cipher_name,
                                  unsigned char *key, size_t key_len,
                                  unsigned char *msg, size_t msg_len,
                                  size_t *out_len_ptr) {
  // https://github.com/openssl/openssl/blob/master/demos/mac/cmac-aes256.c

  unsigned char *out = NULL;

  OSSL_LIB_CTX *library_context = NULL;
  EVP_MAC *mac = NULL;
  EVP_MAC_CTX *mctx = NULL;
  OSSL_PARAM params[4], *p = params;

  library_context = OSSL_LIB_CTX_new();
  mac = EVP_MAC_fetch(library_context, "CMAC", NULL);
  mctx = EVP_MAC_CTX_new(mac);

  *p++ = OSSL_PARAM_construct_utf8_string(OSSL_MAC_PARAM_CIPHER, cipher_name,
                                          sizeof(cipher_name));
  *p = OSSL_PARAM_construct_end();

  EVP_MAC_init(mctx, key, key_len, params);
  EVP_MAC_update(mctx, msg, msg_len);

  EVP_MAC_final(mctx, NULL, out_len_ptr, 0);
  out = OPENSSL_malloc(*out_len_ptr);
  EVP_MAC_final(mctx, out, out_len_ptr, *out_len_ptr);

  EVP_MAC_CTX_free(mctx);
  EVP_MAC_free(mac);
  OSSL_LIB_CTX_free(library_context);

  return out;
}

BF_EXPORT unsigned char *pkcs12_key_gen(unsigned char *password,
                                        size_t password_len,
                                        unsigned char *salt, size_t salt_len,
                                        unsigned int id, unsigned int iteration,
                                        unsigned char *digest_name,
                                        size_t *out_len_ptr) {
  unsigned char *out = NULL;
  const EVP_MD *digest;

  digest = EVP_get_digestbyname(digest_name);
  *out_len_ptr = EVP_MD_get_size(digest);

  out = OPENSSL_malloc(*out_len_ptr);
  PKCS12_key_gen(password, password_len, salt, salt_len, id, iteration,
                 *out_len_ptr, out, digest);

  return out;
}

BF_EXPORT unsigned char *
pkcs5_pbkdf2_hmac(unsigned char *password, size_t password_len,
                  unsigned char *salt, size_t salt_len, unsigned int iteration,
                  unsigned char *digest_name, size_t *out_len_ptr) {
  unsigned char *out = NULL;
  const EVP_MD *digest;

  digest = EVP_get_digestbyname(digest_name);
  *out_len_ptr = EVP_MD_get_size(digest);

  out = OPENSSL_malloc(*out_len_ptr);
  PKCS5_PBKDF2_HMAC(password, password_len, salt, salt_len, iteration, digest,
                    *out_len_ptr, out);

  return out;
}

BF_EXPORT int hmac(char *digest_name, unsigned char *key, size_t key_len,
                   unsigned char *data, size_t data_len, unsigned char **out) {
  char *propq = NULL;
  OSSL_LIB_CTX *library_context = NULL;
  EVP_MAC *mac = NULL;
  EVP_MAC_CTX *mctx = NULL;
  EVP_MD_CTX *digest_context = NULL;
  size_t out_len = 0;
  OSSL_PARAM params[4], *p = params;

  library_context = OSSL_LIB_CTX_new();

  mac = EVP_MAC_fetch(library_context, "HMAC", propq);
  mctx = EVP_MAC_CTX_new(mac);

  *p++ = OSSL_PARAM_construct_utf8_string(OSSL_MAC_PARAM_DIGEST, digest_name,
                                          sizeof(digest_name));
  *p = OSSL_PARAM_construct_end();

  EVP_MAC_init(mctx, key, key_len, params);

  EVP_MAC_update(mctx, data, data_len);

  EVP_MAC_final(mctx, NULL, &out_len, 0);

  *out = OPENSSL_malloc(out_len);

  EVP_MAC_final(mctx, *out, &out_len, out_len);

  EVP_MD_CTX_free(digest_context);
  EVP_MAC_CTX_free(mctx);
  EVP_MAC_free(mac);
  OSSL_LIB_CTX_free(library_context);

  return out_len;
}

BF_EXPORT int hkdf(int mode, unsigned char *digest_name, unsigned char *ikm,
                   size_t ikm_len, unsigned char *salt, size_t salt_len,
                   unsigned char *info, size_t info_len, unsigned char **okm,
                   size_t okm_len) {
  EVP_KDF *kdf = NULL;
  EVP_KDF_CTX *kctx = NULL;
  OSSL_PARAM params[6], *p = params;
  OSSL_LIB_CTX *library_context = NULL;

  /*library_context = OSSL_LIB_CTX_new();*/
  /*kdf = EVP_KDF_fetch(library_context, "HKDF", NULL);*/

  if ((kdf = EVP_KDF_fetch(NULL, "HKDF", NULL)) == NULL) {
    goto err;
  }
  kctx = EVP_KDF_CTX_new(kdf);
  /*EVP_KDF_free(kdf);    */
  if (kctx == NULL) {
    goto err;
  }

  /*kctx = EVP_KDF_CTX_new(kdf);*/
  *p++ = OSSL_PARAM_construct_int(OSSL_KDF_PARAM_MODE, &mode);
  *p++ =
    OSSL_PARAM_construct_utf8_string(OSSL_KDF_PARAM_DIGEST, digest_name, 0);
  *p++ = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_KEY, ikm, ikm_len);
  *p++ = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_INFO, info, info_len);
  *p++ = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_SALT, salt, salt_len);
  *p = OSSL_PARAM_construct_end();

  if (EVP_KDF_CTX_set_params(kctx, params) <= 0) {
    goto err;
  }

  *okm = OPENSSL_malloc(okm_len);

  if (EVP_KDF_derive(kctx, *okm, okm_len, NULL) <= 0) {
    goto err;
  }

  /*if (EVP_KDF_derive(kctx, *okm, okm_len, params) != 1) {*/
  /*OPENSSL_free(*okm);*/
  /*okm_len = -1;*/
  /*}*/

  /*hexdump("okm", *okm, okm_len);*/

err:

  EVP_KDF_CTX_free(kctx);
  EVP_KDF_free(kdf);
  /*OSSL_LIB_CTX_free(library_context);*/

  return okm_len;
}

BF_EXPORT int scrypt(unsigned char *pass, size_t pass_len, unsigned char *salt,
                     size_t salt_len, uint64_t n, uint32_t r, uint32_t p,
                     uint64_t maxmem, unsigned char **okm, size_t okm_len) {
  EVP_KDF *kdf = NULL;
  EVP_KDF_CTX *kctx = NULL;
  OSSL_PARAM params[7], *param_ptr = params;

  if ((kdf = EVP_KDF_fetch(NULL, "SCRYPT", NULL)) == NULL) {
    goto err;
  }
  kctx = EVP_KDF_CTX_new(kdf);
  if (kctx == NULL) {
    goto err;
  }

  *param_ptr++ = OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_PASSWORD,
                 pass, pass_len);
  *param_ptr++ =
    OSSL_PARAM_construct_octet_string(OSSL_KDF_PARAM_SALT, salt, salt_len);
  *param_ptr++ = OSSL_PARAM_construct_uint64(OSSL_KDF_PARAM_SCRYPT_N, &n);
  *param_ptr++ = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_SCRYPT_R, &r);
  *param_ptr++ = OSSL_PARAM_construct_uint32(OSSL_KDF_PARAM_SCRYPT_P, &p);
  if (maxmem > 0) {
    *param_ptr++ =
      OSSL_PARAM_construct_uint64(OSSL_KDF_PARAM_SCRYPT_MAXMEM, &maxmem);
  }
  *param_ptr = OSSL_PARAM_construct_end();

  if (EVP_KDF_CTX_set_params(kctx, params) <= 0) {
    goto err;
  }

  *okm = OPENSSL_malloc(okm_len);
  if (EVP_KDF_derive(kctx, *okm, okm_len, NULL) <= 0) {
    OPENSSL_free(*okm);
    okm_len = -1;
    goto err;
  }

err:
  EVP_KDF_CTX_free(kctx);
  EVP_KDF_free(kdf);

  return okm_len;
}

BF_EXPORT unsigned char *ecdh(EVP_PKEY *priv, EVP_PKEY *peer_pub,
                              size_t *z_len_ptr) {
  unsigned char *z = NULL;
  EVP_PKEY_CTX *ctx;

  ctx = EVP_PKEY_CTX_new(priv, NULL);

  EVP_PKEY_derive_init(ctx);
  EVP_PKEY_derive_set_peer(ctx, peer_pub);

  EVP_PKEY_derive(ctx, NULL, z_len_ptr);
  z = OPENSSL_malloc(*z_len_ptr);
  EVP_PKEY_derive(ctx, z, z_len_ptr);

  EVP_PKEY_CTX_free(ctx);

  return z;
}

size_t calc_ec_pub_from_priv(unsigned char *group_name, BIGNUM *priv_bn,
                             unsigned char **pubkey) {
  size_t pubkey_len;
  int nid = OBJ_txt2nid(group_name);
  EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);

  EC_POINT *ec_pub_point = EC_POINT_new(group);
  EC_POINT_mul(group, ec_pub_point, priv_bn, NULL, NULL, NULL);

  pubkey_len = EC_POINT_point2oct(group, ec_pub_point,
                                  POINT_CONVERSION_COMPRESSED, NULL, 0, NULL);
  *pubkey = OPENSSL_malloc(pubkey_len);
  EC_POINT_point2oct(group, ec_pub_point, POINT_CONVERSION_COMPRESSED, *pubkey,
                     pubkey_len, NULL);

  EC_POINT_free(ec_pub_point);
  EC_GROUP_free(group);
  return pubkey_len;
}

BF_EXPORT EVP_PKEY *gen_ec_key(unsigned char *group_name,
                               unsigned char *priv_hex) {

  int nid;
  EVP_PKEY_CTX *ctx = NULL;
  EVP_PKEY *pkey = NULL;
  OSSL_PARAM params[4];
  OSSL_PARAM *p = params;

  unsigned char *priv = NULL;
  size_t priv_len;
  BIGNUM *priv_bn = NULL;

  nid = OBJ_sn2nid(group_name);

  priv = OPENSSL_hexstr2buf(priv_hex, &priv_len);

  if (priv) {
    pkey = EVP_PKEY_new_raw_private_key(nid, NULL, priv, priv_len);
  } else {
    ctx = EVP_PKEY_CTX_new_id(nid, NULL);
    if (ctx) {
      EVP_PKEY_keygen_init(ctx);
      EVP_PKEY_keygen(ctx, &pkey);
    }
  }

  if (pkey) {
    EVP_PKEY_CTX_free(ctx);
    OPENSSL_free(priv);
    return pkey;
  }

  *p++ = OSSL_PARAM_construct_utf8_string(OSSL_PKEY_PARAM_GROUP_NAME,
                                          group_name, 0);

  if (priv) {
    BN_hex2bn(&priv_bn, priv_hex);
    BN_bn2nativepad(priv_bn, priv, priv_len);
    *p++ = OSSL_PARAM_construct_BN(OSSL_PKEY_PARAM_PRIV_KEY, priv, priv_len);

    size_t pubkey_len;
    unsigned char *pubkey;
    pubkey_len = calc_ec_pub_from_priv(group_name, priv_bn, &pubkey);
    *p++ = OSSL_PARAM_construct_octet_string(OSSL_PKEY_PARAM_PUB_KEY, pubkey,
           pubkey_len);

    BN_free(priv_bn);
  }

  *p = OSSL_PARAM_construct_end();

  ctx = EVP_PKEY_CTX_new_from_name(NULL, "EC", NULL);
  if (priv) {
    EVP_PKEY_fromdata_init(ctx);
    EVP_PKEY_fromdata(ctx, &pkey, EVP_PKEY_KEYPAIR, params);
  } else {
    EVP_PKEY_keygen_init(ctx);
    EVP_PKEY_CTX_set_params(ctx, params);
    EVP_PKEY_keygen(ctx, &pkey);
  }

  EVP_PKEY_CTX_free(ctx);
  OPENSSL_free(priv);

  return pkey;
}

BF_EXPORT EVP_PKEY *gen_ec_pubkey(unsigned char *group_name,
                                  unsigned char *point_hex) {
  unsigned char *point;
  size_t point_len;
  int nid;
  EVP_PKEY *pkey = NULL;
  EVP_PKEY_CTX *pctx = NULL;

  point = OPENSSL_hexstr2buf(point_hex, &point_len);

  nid = OBJ_txt2nid(group_name);

  pctx = EVP_PKEY_CTX_new_id(nid, NULL);
  if (!pctx) {
    pctx = EVP_PKEY_CTX_new_from_name(NULL, "EC", NULL);
  }
  /*pkey = EVP_PKEY_new_raw_public_key(nid, NULL, point, point_len);*/
  /*EVP_PKEY *pkey = EVP_PKEY_new();*/

  EVP_PKEY_fromdata_init(pctx);

  OSSL_PARAM params[3];
  params[0] = OSSL_PARAM_construct_utf8_string(OSSL_PKEY_PARAM_GROUP_NAME,
              (char *)group_name, 0);
  params[1] = OSSL_PARAM_construct_octet_string(OSSL_PKEY_PARAM_PUB_KEY, point,
              point_len);
  params[2] = OSSL_PARAM_construct_end();

  /*EVP_PKEY_CTX_set_params(pctx, params);*/
  EVP_PKEY_fromdata(pctx, &pkey, EVP_PKEY_PUBLIC_KEY, params);

  EVP_PKEY_CTX_free(pctx);
  /*OPENSSL_free(point);*/

  return pkey;
}

BF_EXPORT EVP_PKEY *export_ec_pubkey(EVP_PKEY *priv_pkey) {
  size_t pubkey_len = 0;
  unsigned char *pubkey = NULL;
  unsigned char *pub_hex;
  EVP_PKEY *pub_pkey = NULL;
  int nid = 0;
  unsigned char group_name[100];
  size_t group_name_len;

  // nid = OBJ_txt2nid(group_name);
  nid = EVP_PKEY_get_base_id(priv_pkey);
  /*group_name=get_pkey_utf8_string_param(priv_pkey,
   * OSSL_PKEY_PARAM_GROUP_NAME);*/
  EVP_PKEY_get_group_name(priv_pkey, group_name, sizeof(group_name),
                          &group_name_len);
  /*group_name = (unsigned char*) OBJ_nid2sn(nid);*/

  /*printf("%d, %s,\n", nid, group_name);*/

  EVP_PKEY_get_octet_string_param(priv_pkey, OSSL_PKEY_PARAM_PUB_KEY, NULL, 0,
                                  &pubkey_len);
  pubkey = OPENSSL_malloc(pubkey_len);
  EVP_PKEY_get_octet_string_param(priv_pkey, OSSL_PKEY_PARAM_PUB_KEY, pubkey,
                                  pubkey_len, &pubkey_len);

  /*hexdump("pubkey", pubkey, pubkey_len); */

  if (pubkey_len < 1) {
    BIGNUM *priv_bn = get_pkey_bn_param(priv_pkey, OSSL_PKEY_PARAM_PRIV_KEY);
    pubkey_len = calc_ec_pub_from_priv(group_name, priv_bn, &pubkey);
    BN_free(priv_bn);
  }

  pub_hex = bin2hex(pubkey, pubkey_len);

  /*printf("%s\n", pub_hex);*/

  pub_pkey = gen_ec_pubkey(group_name, pub_hex);

  /*OPENSSL_free(pub_hex);*/

  return pub_pkey;
}

BF_EXPORT unsigned char *write_key_to_der(unsigned char *dst_fname,
    EVP_PKEY *pkey) {
  BIO *out;
  out = BIO_new_file(dst_fname, "w+");

  i2d_PrivateKey_bio(out, pkey);

  BIO_flush(out);

  return dst_fname;
}

BF_EXPORT unsigned char *write_key_to_pem(unsigned char *dst_fname,
    EVP_PKEY *pkey) {
  BIO *out;
  out = BIO_new_file(dst_fname, "w+");

  PEM_write_bio_PrivateKey(out, pkey, NULL, NULL, 0, NULL, NULL);

  BIO_flush(out);

  return dst_fname;
}

BF_EXPORT unsigned char *write_pubkey_to_der(unsigned char *dst_fname,
    EVP_PKEY *pkey) {
  BIO *out;
  out = BIO_new_file(dst_fname, "w+");

  i2d_PUBKEY_bio(out, pkey);

  BIO_flush(out);

  return dst_fname;
}

BF_EXPORT unsigned char *write_pubkey_to_pem(unsigned char *dst_fname,
    EVP_PKEY *pkey) {
  BIO *out;
  out = BIO_new_file(dst_fname, "w+");

  PEM_write_bio_PUBKEY(out, pkey);

  BIO_flush(out);

  return dst_fname;
}

BF_EXPORT int ecdsa_sign(EVP_PKEY *priv_key, const char *digest_name, char *msg,
                         int msg_len, unsigned char **sig) {
  size_t sig_len = 0;
  EVP_MD_CTX *sign_context = NULL;
  const EVP_MD *md = EVP_get_digestbyname(digest_name);

  sign_context = EVP_MD_CTX_new();
  if (!sign_context) return -1;

  if (EVP_DigestSignInit(sign_context, NULL, md, NULL, priv_key) <= 0) {
    EVP_MD_CTX_free(sign_context);
    return -1;
  }

  if (EVP_DigestSignUpdate(sign_context, msg, msg_len) <= 0) {
    EVP_MD_CTX_free(sign_context);
    return -1;
  }

  if (EVP_DigestSignFinal(sign_context, NULL, &sig_len) <= 0) {
    EVP_MD_CTX_free(sign_context);
    return -1;
  }

  *sig = OPENSSL_malloc(sig_len);
  if (!*sig) {
    EVP_MD_CTX_free(sign_context);
    return -1;
  }

  if (EVP_DigestSignFinal(sign_context, *sig, &sig_len) <= 0) {
    OPENSSL_free(*sig);
    sig_len = -1;
  }

  EVP_MD_CTX_free(sign_context);

  return sig_len;
}

BF_EXPORT int ecdsa_verify(EVP_PKEY *pub_key, const char *digest_name,
                           char *msg, int msg_len, unsigned char *sig,
                           int sig_len) {
  EVP_MD_CTX *verify_context = NULL;
  const EVP_MD *md = EVP_get_digestbyname(digest_name);

  verify_context = EVP_MD_CTX_new();
  if (!verify_context) return -1;

  if (EVP_DigestVerifyInit(verify_context, NULL, md, NULL, pub_key) <= 0) {
    EVP_MD_CTX_free(verify_context);
    return -1;
  }

  EVP_DigestVerifyUpdate(verify_context, msg, msg_len);

  int ret = EVP_DigestVerifyFinal(verify_context, sig, sig_len);

  EVP_MD_CTX_free(verify_context);

  return ret;
}

BF_EXPORT int symmetric_cipher(unsigned char *cipher_name, unsigned char *in,
                               int in_len, unsigned char *key,
                               unsigned char *iv, int iv_len,
                               unsigned char **out, int is_encrypt) {
  EVP_CIPHER_CTX *ctx;

  int out_len;
  int len;

  if (!(ctx = EVP_CIPHER_CTX_new()))
    return -1;

  const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);

  if (!EVP_CipherInit_ex(ctx, cipher, NULL, NULL, NULL, is_encrypt))
    return -1;

  if (!EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, is_encrypt))
    return -1;

  *out = OPENSSL_malloc(in_len);

  if (!EVP_CipherUpdate(ctx, *out, &out_len, in, in_len))
    return -1;

  if (!EVP_CipherFinal_ex(ctx, *out, &len))
    return -1;
  out_len += len;

  EVP_CIPHER_CTX_cleanup(ctx);

  return out_len;
}

BF_EXPORT int aead_encrypt(unsigned char *cipher_name, unsigned char *plaintext,
                           int plaintext_len, unsigned char *aad, int aad_len,
                           unsigned char *key, unsigned char *iv, int iv_len,
                           unsigned char **ciphertext, unsigned char **tag,
                           int tag_len) {
  EVP_CIPHER_CTX *ctx;

  int len;
  int ciphertext_len;

  if (!(ctx = EVP_CIPHER_CTX_new()))
    return -1;

  const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
  if (1 != EVP_EncryptInit_ex(ctx, cipher, NULL, NULL, NULL))
    return -1;

  if (OPENSSL_strcasecmp(cipher_name, "gcm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
      return -1;
  } else if (OPENSSL_strcasecmp(cipher_name, "ccm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, iv_len, NULL))
      return -1;
  }

  if (1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
    return -1;

  if (1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len))
    return -1;

  *ciphertext = OPENSSL_malloc(plaintext_len);

  if (1 != EVP_EncryptUpdate(ctx, *ciphertext, &len, plaintext, plaintext_len))
    return -1;
  ciphertext_len = len;

  if (1 != EVP_EncryptFinal_ex(ctx, *ciphertext + len, &len))
    return -1;
  ciphertext_len += len;

  *tag = OPENSSL_malloc(tag_len);

  if (OPENSSL_strcasecmp(cipher_name, "gcm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, tag_len, *tag))
      return -1;
  } else if (OPENSSL_strcasecmp(cipher_name, "ccm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_GET_TAG, tag_len, *tag))
      return -1;
  }

  EVP_CIPHER_CTX_free(ctx);

  return ciphertext_len;
}

BF_EXPORT int aead_decrypt(unsigned char *cipher_name,
                           unsigned char *ciphertext, int ciphertext_len,
                           unsigned char *aad, int aad_len, unsigned char *tag,
                           int tag_len, unsigned char *key, unsigned char *iv,
                           int iv_len, unsigned char **plaintext) {
  EVP_CIPHER_CTX *ctx;
  int len;
  int plaintext_len;
  int ret;

  if (!(ctx = EVP_CIPHER_CTX_new()))
    return -1;

  const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
  if (!EVP_DecryptInit_ex(ctx, cipher, NULL, NULL, NULL))
    return -1;

  if (OPENSSL_strcasecmp(cipher_name, "gcm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
      return -1;
  } else if (OPENSSL_strcasecmp(cipher_name, "ccm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, iv_len, NULL))
      return -1;
  }

  if (!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv))
    return -1;

  if (!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len))
    return -1;

  *plaintext = OPENSSL_malloc(ciphertext_len);

  if (!EVP_DecryptUpdate(ctx, *plaintext, &len, ciphertext, ciphertext_len))
    return -1;
  plaintext_len = len;

  if (OPENSSL_strcasecmp(cipher_name, "gcm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, tag_len, tag))
      return -1;
  } else if (OPENSSL_strcasecmp(cipher_name, "ccm")) {
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_TAG, tag_len, tag))
      return -1;
  }

  ret = EVP_DecryptFinal_ex(ctx, *plaintext + len, &len);

  EVP_CIPHER_CTX_free(ctx);

  if (ret > 0) {
    plaintext_len += len;
    return plaintext_len;
  } else {
    return -1;
  }
}

BF_EXPORT void print_pkey_gettable_params(EVP_PKEY *pkey) {
  // https://www.openssl.org/docs/manmaster/man7/EVP_PKEY-EC.html

  const OSSL_PARAM *params, *p;
  params = EVP_PKEY_gettable_params(pkey);
  for (p = params; p->key != NULL; p++) {
    printf("%s\n", p->key);
  }

  return;
}

// Hash2Curve

int sgn0_m_eq_1(BIGNUM *x) {
  BN_ULONG r = BN_mod_word(x, 2);
  return (int)r;
}

BF_EXPORT BIGNUM *CMOV(BIGNUM *a, BIGNUM *b, int c) {
  if (c) {
    return b;
  }
  return a;
}

BF_EXPORT int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a,
                                  BIGNUM *b, BIGNUM *z, BN_CTX *ctx) {

  BN_mod_inverse(c1, a, p, ctx);
  BN_mod_mul(c1, c1, b, p, ctx);
  BN_set_negative(c1, 1);

  BN_mod_inverse(c2, z, p, ctx);
  BN_set_negative(c2, 1);

  return 1;
}

int map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p,
                                    BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u,
                                    BIGNUM *x, BIGNUM *y, BN_CTX *ctx) {
  BIGNUM *tv1, *tv2, *x1, *gx1, *gx2, *x2, *y2;

  tv1 = BN_new();
  BN_mod_sqr(tv1, u, p, ctx);
  BN_mod_mul(tv1, tv1, z, p, ctx);

  tv2 = BN_new();
  BN_mod_sqr(tv2, tv1, p, ctx);

  x1 = BN_new();
  BN_mod_add(x1, tv1, tv2, p, ctx);
  BN_mod_inverse(x1, x1, p, ctx);

  int e1 = BN_is_zero(x1);
  BN_add_word(x1, 1);
  x1 = CMOV(x1, c2, e1);
  BN_mod_mul(x1, x1, c1, p, ctx);

  gx1 = BN_new();
  BN_mod_sqr(gx1, x1, p, ctx);
  BN_mod_add(gx1, gx1, a, p, ctx);
  BN_mod_mul(gx1, gx1, x1, p, ctx);
  BN_mod_add(gx1, gx1, b, p, ctx);

  x2 = BN_new();
  BN_mod_mul(x2, tv1, x1, p, ctx);
  BN_mod_mul(tv2, tv1, tv2, p, ctx);

  gx2 = BN_new();
  BN_mod_mul(gx2, gx1, tv2, p, ctx);

  BIGNUM *e2_bn = BN_new();
  BIGNUM *e2_ret = BN_mod_sqrt(e2_bn, gx1, p, ctx);
  BN_copy(x, CMOV(x2, x1, e2_ret != NULL));

  y2 = CMOV(gx2, gx1, e2_ret != NULL);
  BN_mod_sqrt(y, y2, p, ctx);

  if (sgn0_m_eq_1(u) != sgn0_m_eq_1(y)) {
    BN_set_negative(y, 1);
    BN_mod_add(y, y, p, p, ctx);
  }

  BN_free(tv1);
  BN_free(tv2);
  BN_free(x1);
  BN_free(gx1);
  BN_free(x2);
  BN_free(gx2);
  BN_free(e2_bn);

  return 1;
}

int map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b,
                                        BIGNUM *z, BIGNUM *u, BIGNUM *x,
                                        BIGNUM *y, BN_CTX *ctx) {
  BIGNUM *tmp1 = BN_new();
  BN_mod(tmp1, u, p, ctx);
  BN_mod_sqr(tmp1, tmp1, p, ctx);
  BN_mod_mul(tmp1, tmp1, z, p, ctx);

  BIGNUM *tv1 = BN_new();
  BN_copy(tv1, tmp1);
  BN_mod_sqr(tv1, tv1, p, ctx);
  BN_mod_add(tv1, tv1, tmp1, p, ctx);
  BN_mod_inverse(tv1, tv1, p, ctx);

  BN_copy(x, tv1);
  BN_add_word(x, 1);
  BN_mod_mul(x, x, b, p, ctx);
  BN_set_negative(x, 1);

  BIGNUM *a_inv = BN_new();
  BN_mod_inverse(a_inv, a, p, ctx);
  BN_mod_mul(x, x, a_inv, p, ctx);

  if (BN_is_zero(tv1)) {
    BN_copy(x, z);
    BN_mod_inverse(x, x, p, ctx);
    BN_mod_mul(x, x, b, p, ctx);
    BN_mod_mul(x, x, a_inv, p, ctx);
  }

  BIGNUM *gx = BN_new();
  BN_copy(gx, x);
  BN_mod_sqr(gx, gx, p, ctx);
  BN_mod_add(gx, gx, a, p, ctx);
  BN_mod_mul(gx, gx, x, p, ctx);
  BN_mod_add(gx, gx, b, p, ctx);

  BN_mod_sqrt(y, gx, p, ctx);

  BIGNUM *y2 = BN_new();
  BN_mod_sqr(y2, y, p, ctx);
  if (BN_cmp(y2, gx) != 0) {
    BN_mod_mul(x, x, tmp1, p, ctx);

    BN_copy(gx, x);
    BN_mod_sqr(gx, gx, p, ctx);
    BN_mod_add(gx, gx, a, p, ctx);
    BN_mod_mul(gx, gx, x, p, ctx);
    BN_mod_add(gx, gx, b, p, ctx);

    BN_mod_sqrt(y, gx, p, ctx);
    BN_mod_sqr(y2, y, p, ctx);
    if (BN_cmp(y2, gx) != 0) {
      return 0;
    }
  }

  if (sgn0_m_eq_1(u) != sgn0_m_eq_1(y)) {
    BN_set_negative(y, 1);
    BN_mod_add(y, y, p, p, ctx);
  }

  BN_free(tmp1);
  BN_free(tv1);
  BN_free(a_inv);
  BN_free(gx);
  BN_free(y2);
  return 1;
}
