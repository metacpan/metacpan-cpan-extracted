#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/cmac.h>
#include <openssl/core_names.h>
#include <openssl/params.h>
#include <openssl/crypto.h>
#include <openssl/ec.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/kdf.h>
#include <openssl/objects.h>
#include <openssl/pem.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool is_empty(unsigned char* s){
    if(strlen(s)==0)
        return true;

    return false;
}

unsigned char* point2hex(unsigned char *group_name, EC_POINT *P, int conv_form)
{
	int nid = OBJ_txt2nid(group_name);
	EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);

	BN_CTX *ctx = BN_CTX_new();

	unsigned char* s = EC_POINT_point2hex(group, P, conv_form, ctx);

	EC_GROUP_free(group);
	BN_CTX_free(ctx);

	return s;
}

EC_POINT* hex2point(unsigned char* group_name, unsigned char* point_hex)
  {
    int nid = OBJ_txt2nid(group_name);
    EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);

    BN_CTX *ctx = BN_CTX_new();

    EC_POINT* ec_point = EC_POINT_new(group);
    ec_point = EC_POINT_hex2point(group, point_hex, ec_point, ctx);

    BN_CTX_free(ctx);

    return  ec_point;
  }

void hexdump(unsigned char *info, unsigned char *buf, const int num)
{
    int i;
    printf("\n%s, %d\n", info, num);

    for(i = 0; i < num; i++)
    {
        printf("%02x", buf[i]);
    }
    printf("\n");

    for(i = 0; i < num; i++)
    {
        printf("%02x ", buf[i]);
        if ((i+1)%8 == 0)
            printf("\n");
    }
    printf("\n");
    return;
}


size_t slurp(unsigned char* fname, unsigned char **buf){
    /* declare a file pointer */
    FILE    *infile;
    size_t    buf_len;

    infile = fopen(fname, "r");

    if(infile == NULL)
        return 0;

    fseek(infile, 0L, SEEK_END);
    buf_len = ftell(infile);

    fseek(infile, 0L, SEEK_SET);	

    *buf = (unsigned char*)calloc(buf_len, sizeof(unsigned char));	

    if(*buf == NULL)
        return 1;

    int ret = fread(*buf, sizeof(unsigned char), buf_len, infile);
    fclose(infile);

    return buf_len;
}

BIGNUM* hex2bn(unsigned char* a)
{
    BIGNUM* bn_a = BN_new();
    BN_hex2bn(&bn_a, a); 
    return bn_a;
}

unsigned char * bin2hex(unsigned char * bin, size_t bin_len)
{

    unsigned char   *out = NULL;
    size_t  out_len;
    size_t n = bin_len*2 + 1;

    out = OPENSSL_malloc(n);
    OPENSSL_buf2hexstr_ex(out, n, &out_len, (const unsigned char *) bin, bin_len, '\0');

    return out;
}

BIGNUM* get_pkey_bn_param(EVP_PKEY *pkey, unsigned char *param_name)
{
    BIGNUM *x_bn = NULL;

    int ret = EVP_PKEY_get_bn_param(pkey, param_name, &x_bn);

    return x_bn;
}

size_t get_pkey_octet_string_param_raw(EVP_PKEY *pkey, unsigned char *param_name, unsigned char **s)
{
    size_t s_len;

    EVP_PKEY_get_octet_string_param(pkey, param_name, NULL,  0, &s_len);
    *s = OPENSSL_malloc(s_len);
    EVP_PKEY_get_octet_string_param(pkey, param_name, *s, s_len, NULL);

    return s_len;
}

unsigned char* get_pkey_utf8_string_param(EVP_PKEY *pkey, unsigned char *param_name)
{
    unsigned char *s=NULL;
    size_t s_len;

    EVP_PKEY_get_utf8_string_param(pkey, param_name, NULL,  0, &s_len);
    s = OPENSSL_malloc(s_len);
    int ret = EVP_PKEY_get_utf8_string_param(pkey, param_name, s, s_len, NULL);

    if(ret){
        OPENSSL_free(s);
        return NULL;
    }

    return s;
}

EVP_PKEY *export_rsa_pubkey(EVP_PKEY *rsa_priv)
{

    OSSL_LIB_CTX *libctx = NULL;
    EVP_PKEY_CTX *ctx = NULL;
    EVP_PKEY *rsa_pub = NULL;
    OSSL_PARAM params[3];
    BIGNUM *n = NULL, *e = NULL;
    size_t n_bin_len, e_bin_len;
    unsigned char *n_bin=NULL, *e_bin =NULL;

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

size_t rsa_oaep_encrypt_raw(unsigned char *digest_name, EVP_PKEY *pub, unsigned char* in, size_t in_len, unsigned char ** out)
{
    int ret=0;
    OSSL_LIB_CTX *libctx=NULL;
    EVP_PKEY_CTX *ctx = NULL;
    char *propq = NULL;
    size_t out_len;

    OSSL_PARAM params[3];
    params[0] = OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_PAD_MODE, OSSL_PKEY_RSA_PAD_MODE_OAEP, 0);
    params[1]= OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_OAEP_DIGEST, digest_name, 0);
    params[2] = OSSL_PARAM_construct_end();

    ctx = EVP_PKEY_CTX_new_from_pkey(libctx, pub, propq);
    EVP_PKEY_encrypt_init_ex(ctx, params);
    EVP_PKEY_encrypt(ctx, NULL, &out_len, in, in_len);
    *out = OPENSSL_zalloc(out_len);

    if( EVP_PKEY_encrypt(ctx, *out, &out_len, in, in_len) <=0 ){
        OPENSSL_free(*out);
        out_len = -1;
    }

    EVP_PKEY_CTX_free(ctx);

    return out_len;
}

size_t rsa_oaep_decrypt_raw(unsigned char *digest_name, EVP_PKEY *priv, unsigned char* in, size_t in_len, unsigned char ** out)
{
    int ret=0;
    OSSL_LIB_CTX *libctx=NULL;
    EVP_PKEY_CTX *ctx = NULL;
    char *propq = NULL;
    size_t out_len;

    OSSL_PARAM params[3];
    params[0] = OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_PAD_MODE, OSSL_PKEY_RSA_PAD_MODE_OAEP, 0);
    params[1]= OSSL_PARAM_construct_utf8_string(OSSL_ASYM_CIPHER_PARAM_OAEP_DIGEST, digest_name, 0);
    params[2] = OSSL_PARAM_construct_end();

    ctx = EVP_PKEY_CTX_new_from_pkey(libctx, priv, propq);
    EVP_PKEY_decrypt_init_ex(ctx, params);
    EVP_PKEY_decrypt(ctx, NULL, &out_len, in, in_len);
    *out = OPENSSL_zalloc(out_len);

    if( EVP_PKEY_decrypt(ctx, *out, &out_len, in, in_len) <=0 ){
        OPENSSL_free(*out);
        out_len = -1;
    }

    EVP_PKEY_CTX_free(ctx);

    return out_len;
}

unsigned char* read_key(EVP_PKEY *pkey)
{
  BIGNUM *priv_bn = NULL;
    char* priv_hex = NULL;
    char* priv = NULL;
    size_t priv_len=0;

    EVP_PKEY_get_bn_param(pkey, OSSL_PKEY_PARAM_PRIV_KEY, &priv_bn);

    if(priv_bn==NULL){

        EVP_PKEY_get_raw_private_key(pkey, NULL, &priv_len);
        priv = OPENSSL_malloc(priv_len);
        EVP_PKEY_get_raw_private_key(pkey, priv, &priv_len);

        priv_bn = BN_bin2bn(priv, priv_len, NULL);
        OPENSSL_free(priv);
    }

    priv_hex = BN_bn2hex(priv_bn);

    OPENSSL_free(priv_bn);

    return priv_hex;

}

EVP_PKEY* read_key_from_der(unsigned char* keyfile) 
{

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

EVP_PKEY* read_pubkey_from_der(unsigned char* keyfile) 
{

    EVP_PKEY *pkey = NULL;

    unsigned char *buf = NULL;
    size_t buf_len = slurp(keyfile, &buf);

    d2i_PUBKEY(&pkey, (const unsigned char **) &buf, buf_len);

    return pkey;
}

EVP_PKEY* read_key_from_pem(unsigned char* keyfile) 
{

    EVP_PKEY *pkey = NULL;

    BIO *inf=NULL;
    inf = BIO_new_file(keyfile, "r");

    pkey = PEM_read_bio_PrivateKey(inf, NULL, NULL, NULL);

    BIO_set_close(inf, BIO_CLOSE);

    return pkey;
}

EVP_PKEY* read_pubkey_from_pem(unsigned char *keyfile)
{
    FILE *inf = fopen(keyfile, "r");

    EVP_PKEY *pkey = NULL;

    pkey = PEM_read_PUBKEY(inf, NULL, NULL, NULL);

    fclose(inf);

    return pkey;

}

unsigned char* read_pubkey(EVP_PKEY *pkey)
{
    unsigned char *pub=NULL;
    unsigned char *phex=NULL;
    size_t pub_len;
    EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_ENCODED_PUBLIC_KEY, NULL,  0, &pub_len);
    /*EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_PUB_KEY, NULL,  0, &pub_len);*/
    pub = OPENSSL_malloc(pub_len);
    EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_ENCODED_PUBLIC_KEY, pub, pub_len, NULL);
    /*EVP_PKEY_get_octet_string_param(pkey, OSSL_PKEY_PARAM_PUB_KEY, pub,  pub_len, &pub_len);*/




    if(pub){
        phex = bin2hex(pub, pub_len);    
        OPENSSL_free(pub);
    }
    return phex;
}

unsigned char* read_ec_pubkey(EVP_PKEY *pkey, int compressed_flag)
{
    unsigned char* phex = NULL;
    if(compressed_flag){
        EVP_PKEY_set_utf8_string_param(pkey, OSSL_PKEY_PARAM_EC_POINT_CONVERSION_FORMAT, OSSL_PKEY_EC_POINT_CONVERSION_FORMAT_COMPRESSED);
    }

    phex = read_pubkey(pkey);
    return phex;

    }

BIGNUM* bn_mod_sqrt(BIGNUM *a, BIGNUM *p)
{

    BN_CTX *ctx;

    ctx = BN_CTX_new();

    BIGNUM* s = BN_new();
    BN_mod_sqrt(s, a, p, ctx);

    BN_CTX_free(ctx);

    return s;
}

unsigned char* aes_cmac_raw(unsigned char* cipher_name, unsigned char* key, size_t key_len, unsigned char* msg, size_t msg_len, size_t *out_len_ptr ) 
{
    // https://github.com/openssl/openssl/blob/master/demos/mac/cmac-aes256.c

    unsigned char* out=NULL;

    OSSL_LIB_CTX *library_context = NULL;
    EVP_MAC *mac = NULL;
    EVP_MAC_CTX *mctx = NULL;
    OSSL_PARAM params[4], *p = params;

    library_context = OSSL_LIB_CTX_new();
    mac = EVP_MAC_fetch(library_context, "CMAC", NULL);
    mctx = EVP_MAC_CTX_new(mac);

    *p++ = OSSL_PARAM_construct_utf8_string(OSSL_MAC_PARAM_CIPHER, cipher_name, sizeof(cipher_name));
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

unsigned char* pkcs12_key_gen_raw(unsigned char* password, size_t password_len, unsigned char* salt, size_t salt_len, unsigned int id, unsigned int iteration, unsigned char *digest_name, size_t *out_len_ptr)
{
    unsigned char *out = NULL;
    const EVP_MD *digest;

    digest = EVP_get_digestbyname(digest_name);
    *out_len_ptr = EVP_MD_get_size(digest);

    out = OPENSSL_malloc(*out_len_ptr); 
    PKCS12_key_gen(password, password_len, salt, salt_len, id, iteration, *out_len_ptr, out, digest);

    return out;
}

unsigned char* pkcs5_pbkdf2_hmac_raw(unsigned char* password, size_t password_len, unsigned char *salt, size_t salt_len, unsigned int iteration, unsigned char *digest_name, size_t *out_len_ptr)
{
    unsigned char *out = NULL;
    const EVP_MD *digest;

    digest = EVP_get_digestbyname(digest_name);
    *out_len_ptr = EVP_MD_get_size(digest);


    out = OPENSSL_malloc(*out_len_ptr); 
    PKCS5_PBKDF2_HMAC(password, password_len, salt, salt_len, iteration, digest, *out_len_ptr, out);

    return out;
}

int hmac_raw(char *digest_name, unsigned char* key, size_t key_len, unsigned char *data, size_t data_len, unsigned char **out)
{
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

    *p++ = OSSL_PARAM_construct_utf8_string(OSSL_MAC_PARAM_DIGEST, digest_name, sizeof(digest_name));
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


int hkdf_raw(int mode, unsigned char *digest_name, unsigned char *ikm, size_t ikm_len, unsigned char *salt, size_t salt_len, unsigned char *info, size_t info_len, unsigned char **okm, size_t okm_len )
{
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
    *p++ = OSSL_PARAM_construct_utf8_string(OSSL_KDF_PARAM_DIGEST, digest_name, 0);
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

unsigned char* ecdh_raw(EVP_PKEY *priv, EVP_PKEY *peer_pub, size_t *z_len_ptr)
{
    unsigned char* z=NULL;
    EVP_PKEY_CTX *ctx;

    ctx = EVP_PKEY_CTX_new(priv, NULL);

    EVP_PKEY_derive_init(ctx);
    EVP_PKEY_derive_set_peer(ctx, peer_pub);

    EVP_PKEY_derive(ctx, NULL, z_len_ptr);
    z = OPENSSL_malloc(*z_len_ptr);
    EVP_PKEY_derive(ctx, z, z_len_ptr);

    OPENSSL_free(ctx);

    return z;
}

size_t  calc_ec_pub_from_priv(unsigned char* group_name, BIGNUM* priv_bn, unsigned char** pubkey){
    size_t pubkey_len;
    int nid = OBJ_txt2nid(group_name);
    EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);

    EC_POINT* ec_pub_point = EC_POINT_new(group);
    EC_POINT_mul(group, ec_pub_point, priv_bn, NULL, NULL, NULL);

    pubkey_len =  EC_POINT_point2oct(group, ec_pub_point, POINT_CONVERSION_COMPRESSED, NULL, 0, NULL);
    *pubkey=OPENSSL_malloc(pubkey_len);
    EC_POINT_point2oct(group, ec_pub_point, POINT_CONVERSION_COMPRESSED, *pubkey, pubkey_len, NULL);

    EC_POINT_free(ec_pub_point);
    EC_GROUP_free(group);
    return pubkey_len; 
}

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx){
    const BIGNUM *cofactor = EC_GROUP_get0_cofactor(group);
    // P = 0*Base + cofactor * Q
    EC_POINT_mul(group, P, NULL, Q, cofactor, ctx);
    return 1;
}

EC_POINT * mul_ec_point(unsigned char *group_name, BIGNUM *x, EC_POINT* Q, BIGNUM *y)
{
    int nid = OBJ_txt2nid(group_name);

    EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);
    BN_CTX *ctx = BN_CTX_new();

    EC_POINT *P = EC_POINT_new(group);
    EC_POINT_mul(group, P, x, Q, y, ctx);

err:
    OPENSSL_free(group);
    OPENSSL_free(ctx);

    return P;

}



EC_POINT * gen_ec_point(unsigned char *group_name, 
BIGNUM *x_bn, BIGNUM *y_bn, int clear_cofactor_flag
//unsigned char* x, size_t x_len, unsigned char *y, size_t y_len
)
{

    int nid = OBJ_txt2nid(group_name);

    EC_GROUP *group = EC_GROUP_new_by_curve_name(nid);
    BN_CTX *ctx = BN_CTX_new();

    EC_POINT *Q = EC_POINT_new(group);

    //BIGNUM *x_bn = BN_bin2bn(x, x_len, NULL);
    //BIGNUM *y_bn = BN_bin2bn(y, y_len, NULL);

    EC_POINT_set_affine_coordinates( group, Q, x_bn, y_bn, ctx );

    if(clear_cofactor_flag){
	    EC_POINT *P = EC_POINT_new(group);
	    clear_cofactor(group, P, Q, ctx);
	    OPENSSL_free(Q);
	    Q = P;
    }

    //printf("point2hex::: %s\n", EC_POINT_point2hex(group, Q, 4, ctx)); 

    OPENSSL_free(group);
    OPENSSL_free(ctx);
    //OPENSSL_free(x_bn);
    //OPENSSL_free(y_bn);


    return Q;
  // int EC_POINT_set_affine_coordinates(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx);
}

EVP_PKEY * gen_ec_key(unsigned char *group_name, unsigned char* priv_hex)
{

    int nid;
    EVP_PKEY_CTX *ctx=NULL;
    EVP_PKEY *pkey = NULL;
    OSSL_PARAM params[4];
    OSSL_PARAM *p = params;

    unsigned char* priv=NULL;
    size_t priv_len;
    BIGNUM *priv_bn = NULL;

    nid = OBJ_sn2nid(group_name);

    priv = OPENSSL_hexstr2buf(priv_hex, &priv_len);

    if(priv){
        pkey = EVP_PKEY_new_raw_private_key(nid, NULL, priv, priv_len);
    }else{
        ctx = EVP_PKEY_CTX_new_id(nid, NULL);
        if(ctx){
            EVP_PKEY_keygen_init(ctx);
            EVP_PKEY_keygen(ctx, &pkey);
        }
    }

    if(pkey)
        return pkey;

    *p++ = OSSL_PARAM_construct_utf8_string(OSSL_PKEY_PARAM_GROUP_NAME, group_name, 0);

    if(priv){
        BN_hex2bn(&priv_bn, priv_hex);
        BN_bn2nativepad(priv_bn, priv, priv_len);
        *p++ = OSSL_PARAM_construct_BN(OSSL_PKEY_PARAM_PRIV_KEY, priv, priv_len);

        size_t pubkey_len;
        unsigned char* pubkey;
        pubkey_len = calc_ec_pub_from_priv(group_name, priv_bn, &pubkey);
        *p++ = OSSL_PARAM_construct_octet_string(OSSL_PKEY_PARAM_PUB_KEY, pubkey, pubkey_len);

        BN_free(priv_bn);
    }

    *p = OSSL_PARAM_construct_end();

    ctx = EVP_PKEY_CTX_new_from_name(NULL, "EC",NULL);
    if(priv){
        EVP_PKEY_fromdata_init(ctx);
        EVP_PKEY_fromdata(ctx, &pkey, EVP_PKEY_KEYPAIR, params);
    }else{
        EVP_PKEY_keygen_init(ctx);
        EVP_PKEY_CTX_set_params(ctx, params);
        EVP_PKEY_keygen(ctx, &pkey);
    }

    OPENSSL_free(ctx);
    OPENSSL_free(priv);

    return pkey;

}


EVP_PKEY * gen_ec_pubkey(unsigned char *group_name, unsigned char* point_hex)
{
    unsigned char *point; 
    size_t point_len;
    int nid;
    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX* pctx = NULL;

    point = OPENSSL_hexstr2buf(point_hex, &point_len);

    nid = OBJ_txt2nid(group_name);

    pctx = EVP_PKEY_CTX_new_id(nid, NULL);
    if(!pctx){
        pctx = EVP_PKEY_CTX_new_from_name(NULL, "EC", NULL);
    }
        /*pkey = EVP_PKEY_new_raw_public_key(nid, NULL, point, point_len);*/
    /*EVP_PKEY *pkey = EVP_PKEY_new();*/

        EVP_PKEY_fromdata_init(pctx);

        OSSL_PARAM params[3];
        params[0] = OSSL_PARAM_construct_utf8_string(OSSL_PKEY_PARAM_GROUP_NAME, (char *) group_name, 0);
        params[1] = OSSL_PARAM_construct_octet_string(OSSL_PKEY_PARAM_PUB_KEY, point, point_len);
        params[2] = OSSL_PARAM_construct_end();

/*EVP_PKEY_CTX_set_params(pctx, params);*/
        EVP_PKEY_fromdata(pctx, &pkey, EVP_PKEY_PUBLIC_KEY, params);

    EVP_PKEY_CTX_free(pctx);
    /*OPENSSL_free(point);*/

    return pkey;
}


EVP_PKEY* export_ec_pubkey(EVP_PKEY *priv_pkey)
{
    size_t pubkey_len = 0;
    unsigned char* pubkey = NULL;
    unsigned char *pub_hex;
    EVP_PKEY *pub_pkey = NULL;
    int nid=0;
    unsigned char group_name[100];
    size_t group_name_len;

    //nid = OBJ_txt2nid(group_name);
    nid = EVP_PKEY_get_base_id(priv_pkey);
    /*group_name=get_pkey_utf8_string_param(priv_pkey, OSSL_PKEY_PARAM_GROUP_NAME);*/
    EVP_PKEY_get_group_name(priv_pkey, group_name, sizeof(group_name), &group_name_len);
    /*group_name = (unsigned char*) OBJ_nid2sn(nid);*/

    /*printf("%d, %s,\n", nid, group_name);*/

    EVP_PKEY_get_octet_string_param(priv_pkey, OSSL_PKEY_PARAM_PUB_KEY, NULL, 0, &pubkey_len);
    pubkey=OPENSSL_malloc(pubkey_len);
    EVP_PKEY_get_octet_string_param(priv_pkey, OSSL_PKEY_PARAM_PUB_KEY, pubkey, pubkey_len, &pubkey_len);

   /*hexdump("pubkey", pubkey, pubkey_len); */

    if(pubkey_len<1){
        BIGNUM* priv_bn= get_pkey_bn_param(priv_pkey, OSSL_PKEY_PARAM_PRIV_KEY);
        pubkey_len = calc_ec_pub_from_priv(group_name, priv_bn, &pubkey);
        BN_free(priv_bn);
    }

    pub_hex = bin2hex(pubkey, pubkey_len);

    /*printf("%s\n", pub_hex);*/

    pub_pkey = gen_ec_pubkey(group_name, pub_hex);

    /*OPENSSL_free(pub_hex);*/

    return pub_pkey;
}

unsigned char* write_key_to_der(unsigned char* dst_fname, EVP_PKEY *pkey)
{
    BIO *out;
    out = BIO_new_file(dst_fname, "w+");

    i2d_PrivateKey_bio(out, pkey);

    BIO_flush(out);

    return dst_fname;
}

unsigned char* write_key_to_pem(unsigned char* dst_fname, EVP_PKEY *pkey)
{
    BIO *out;
    out = BIO_new_file(dst_fname, "w+");

    PEM_write_bio_PrivateKey(out, pkey, NULL, NULL, 0, NULL, NULL);

    BIO_flush(out);

    return dst_fname;
}

unsigned char* write_pubkey_to_der(unsigned char* dst_fname, EVP_PKEY *pkey)
{
    BIO *out;
    out = BIO_new_file(dst_fname, "w+");

    i2d_PUBKEY_bio(out, pkey);

    BIO_flush(out);

    return dst_fname;
}

unsigned char* write_pubkey_to_pem(unsigned char* dst_fname, EVP_PKEY *pkey)
{
    BIO *out;
    out = BIO_new_file(dst_fname, "w+");

    PEM_write_bio_PUBKEY(out, pkey);

    BIO_flush(out);

    return dst_fname;
}

int ecdsa_sign_raw(EVP_PKEY *priv_key, const char *sig_name, char *msg, int msg_len, unsigned char **sig) 
{

    const char *propq = NULL;
    OSSL_LIB_CTX *libctx = NULL;
    size_t sig_len = 0;
    unsigned char *sig_value = NULL;
    EVP_MD_CTX *sign_context = NULL;

    libctx = OSSL_LIB_CTX_new();
    sign_context = EVP_MD_CTX_new();

    EVP_DigestSignInit_ex(sign_context, NULL, sig_name, libctx, NULL, priv_key, NULL); 

    EVP_DigestSignUpdate(sign_context, msg, msg_len); 

    EVP_DigestSignFinal(sign_context, NULL, &sig_len); 

    *sig = OPENSSL_malloc(sig_len);

    if (!EVP_DigestSignFinal(sign_context, *sig, &sig_len)){ 
        OPENSSL_free(*sig);
        sig_len = -1;
    }

    EVP_MD_CTX_free(sign_context);
    OSSL_LIB_CTX_free(libctx);

    return sig_len;
}

int ecdsa_verify_raw(EVP_PKEY *pub_key, const char *sig_name, char *msg, int msg_len, unsigned char *sig, int sig_len) 
{

    const char *propq = NULL;
    OSSL_LIB_CTX *libctx = NULL;
    unsigned char *sig_value = NULL;
    EVP_MD_CTX *verify_context = NULL;

    libctx = OSSL_LIB_CTX_new();
    verify_context = EVP_MD_CTX_new();

    EVP_DigestVerifyInit_ex(verify_context, NULL, sig_name, libctx, NULL, pub_key, NULL); 

    EVP_DigestVerifyUpdate(verify_context, msg, msg_len); 

    int ret=EVP_DigestVerifyFinal(verify_context, sig, sig_len);


    EVP_MD_CTX_free(verify_context);
    OSSL_LIB_CTX_free(libctx);

    return ret;
}

int symmetric_cipher_raw(unsigned char *cipher_name, unsigned char *in, int in_len, unsigned char *key, unsigned char *iv, int iv_len, unsigned char **out, int is_encrypt )
{
    EVP_CIPHER_CTX *ctx;

    int out_len;
    int len;


    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);

    if(!EVP_CipherInit_ex(ctx, cipher, NULL, NULL, NULL, is_encrypt))
        return -1;

    if(!EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, is_encrypt))
        return -1;

    *out = OPENSSL_malloc(in_len);

    if(!EVP_CipherUpdate(ctx, *out, &out_len, in, in_len))
        return -1;

    if(!EVP_CipherFinal_ex(ctx, *out, &len))
        return -1;
    out_len += len;


    EVP_CIPHER_CTX_cleanup(ctx);

    return out_len;
}

int aead_encrypt_raw(unsigned char *cipher_name, unsigned char *plaintext, int plaintext_len, unsigned char *aad, int aad_len, unsigned char *key, unsigned char *iv, int iv_len, unsigned char **ciphertext, unsigned char **tag, int tag_len)
{
    EVP_CIPHER_CTX *ctx;

    int len;
    int ciphertext_len;


    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
    if(1 != EVP_EncryptInit_ex(ctx, cipher, NULL, NULL, NULL))
        return -1;

    if(OPENSSL_strcasecmp(cipher_name, "gcm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
            return -1;
    }else if(OPENSSL_strcasecmp(cipher_name, "ccm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, iv_len, NULL))
            return -1;
    }

    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
        return -1;

    if(1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len))
        return -1;

    *ciphertext = OPENSSL_malloc(plaintext_len);

    if(1 != EVP_EncryptUpdate(ctx, *ciphertext, &len, plaintext, plaintext_len))
        return -1;
    ciphertext_len = len;

    if(1 != EVP_EncryptFinal_ex(ctx, *ciphertext + len, &len))
        return -1;
    ciphertext_len += len;

    *tag = OPENSSL_malloc(tag_len);

    if(OPENSSL_strcasecmp(cipher_name, "gcm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, tag_len, *tag))
            return -1;
    }else if(OPENSSL_strcasecmp(cipher_name, "ccm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_GET_TAG, tag_len, *tag))
            return -1;
    }

    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

int aead_decrypt_raw( unsigned char *cipher_name, unsigned char *ciphertext, int ciphertext_len, unsigned char *aad, int aad_len, unsigned char *tag, int tag_len, unsigned char *key, unsigned char *iv, int iv_len, unsigned char **plaintext)
{
    EVP_CIPHER_CTX *ctx;
    int len;
    int plaintext_len;
    int ret;


    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    const EVP_CIPHER *cipher = EVP_get_cipherbyname(cipher_name);
    if(!EVP_DecryptInit_ex(ctx, cipher, NULL, NULL, NULL))
        return -1;

    if(OPENSSL_strcasecmp(cipher_name, "gcm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL))
            return -1;
    }else if(OPENSSL_strcasecmp(cipher_name, "ccm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, iv_len, NULL))
            return -1;
    }

    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv))
        return -1;

    if(!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len))
        return -1;

    *plaintext = OPENSSL_malloc(ciphertext_len);

    if(!EVP_DecryptUpdate(ctx, *plaintext, &len, ciphertext, ciphertext_len))
        return -1;
    plaintext_len = len;

    if(OPENSSL_strcasecmp(cipher_name, "gcm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, tag_len, tag))
            return -1;
    }else if(OPENSSL_strcasecmp(cipher_name, "ccm")){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_TAG, tag_len, tag))
            return -1;
    }

    ret = EVP_DecryptFinal_ex(ctx, *plaintext + len, &len);

    EVP_CIPHER_CTX_free(ctx);

    if(ret > 0) {
        plaintext_len += len;
        return plaintext_len;
    } else {
        return -1;
    }
}

void print_pkey_gettable_params(EVP_PKEY *pkey)
{
    // https://www.openssl.org/docs/manmaster/man7/EVP_PKEY-EC.html

    const OSSL_PARAM  *params, *p;
    params = EVP_PKEY_gettable_params(pkey);
    for (p = params; p->key != NULL; p++) {
        printf("%s\n", p->key);
    }

    return;
}

// Hash2Curve

int sgn0_m_eq_1 (BIGNUM *x) {
    BN_ULONG r = BN_mod_word(x, 2);
    return (int) r;
}

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c){
    if(c){
        return b;
    }
    return a;
}


int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)
{

    BN_mod_inverse(c1, a, p, ctx);
    BN_mod_mul(c1, c1, b, p, ctx);
    BN_set_negative(c1, 1);

    BN_mod_inverse(c2, z, p, ctx);
    BN_set_negative(c2, 1);

    return 1;
}

int 
map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
{
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
    BN_copy(x, CMOV(x2, x1, e2_ret!=NULL));

    y2 = CMOV(gx2, gx1, e2_ret!=NULL);
    BN_mod_sqrt(y, y2, p, ctx);

    if(sgn0_m_eq_1(u) != sgn0_m_eq_1(y)){
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

int 
map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)
{
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

    if(BN_is_zero(tv1)){
        BN_copy(x, z);
        BN_mod_inverse(x, x, p,ctx);
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
    if(BN_cmp(y2, gx)!=0){
        BN_mod_mul(x, x, tmp1, p, ctx);

        BN_copy(gx, x);
        BN_mod_sqr(gx, gx, p, ctx);
        BN_mod_add(gx, gx, a, p, ctx);
        BN_mod_mul(gx, gx, x, p, ctx);
        BN_mod_add(gx, gx, b, p, ctx);

        BN_mod_sqrt(y, gx, p, ctx);
        BN_mod_sqr(y2, y, p, ctx);
        if( BN_cmp(y2, gx)!=0 ){
            return 0;
        }
    }

    if(sgn0_m_eq_1(u) != sgn0_m_eq_1(y)){
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





MODULE = Crypt::OpenSSL::BaseFunc		PACKAGE = Crypt::OpenSSL::BaseFunc		

const char *OBJ_nid2sn(int n);

EC_POINT * mul_ec_point(unsigned char *group_name, BIGNUM *x, EC_POINT* Q, BIGNUM *y)

EC_POINT* hex2point(unsigned char* group_name, unsigned char* point_hex)

char *BN_bn2hex(const BIGNUM *a);

BIGNUM* hex2bn(unsigned char* a)

EVP_PKEY * gen_ec_key(unsigned char *group_name, unsigned char* priv_hex)

EVP_PKEY * gen_ec_pubkey(unsigned char* group_name, unsigned char* point_hex)

EC_POINT * gen_ec_point(unsigned char *group_name, BIGNUM *x_bn, BIGNUM *y_bn, int clear_cofactor_flag)

char * bin2hex(unsigned char * bin, size_t len)

BIGNUM* bn_mod_sqrt(BIGNUM *a, BIGNUM *p)

unsigned char* read_key(EVP_PKEY *pkey)

unsigned char* read_ec_pubkey(EVP_PKEY *pkey, int compressed_flag)

unsigned char* read_pubkey(EVP_PKEY *pkey)

EVP_PKEY* read_key_from_pem(unsigned char* keyfile) 

EVP_PKEY* read_key_from_der(unsigned char* keyfile) 

EVP_PKEY* read_pubkey_from_der(unsigned char* keyfile) 

EVP_PKEY* read_pubkey_from_pem(unsigned char *keyfile)

unsigned char* write_key_to_pem(unsigned char* dst_fname, EVP_PKEY *pkey)

unsigned char* write_pubkey_to_pem(unsigned char* dst_fname, EVP_PKEY *pkey)

unsigned char* write_key_to_der(unsigned char* dst_fname, EVP_PKEY *pkey)

unsigned char* write_pubkey_to_der(unsigned char* dst_fname, EVP_PKEY *pkey)

EVP_PKEY *export_rsa_pubkey(EVP_PKEY *rsa_priv)

EVP_PKEY* export_ec_pubkey(EVP_PKEY *priv_pkey)

size_t rsa_oaep_encrypt_raw(unsigned char *digest_name, EVP_PKEY *pub, unsigned char* in, size_t in_len, unsigned char ** out)

size_t rsa_oaep_decrypt_raw(unsigned char *digest_name, EVP_PKEY *priv, unsigned char* in, size_t in_len, unsigned char ** out)

BIGNUM* get_pkey_bn_param(EVP_PKEY *pkey, unsigned char *param_name)

size_t get_pkey_octet_string_param_raw(EVP_PKEY *pkey, unsigned char *param_name, unsigned char **s)

unsigned char* get_pkey_utf8_string_param(EVP_PKEY *pkey, unsigned char *param_name)

void print_pkey_gettable_params(EVP_PKEY *pkey)

char *EC_POINT_point2hex(const EC_GROUP *group, const EC_POINT *p, point_conversion_form_t form, BN_CTX *ctx)

unsigned char* point2hex(unsigned char *group_name, EC_POINT *P, int conv_form)

int OBJ_sn2nid (const char *s)

const EVP_MD *EVP_get_digestbyname(const char *name)

int EVP_MD_get_block_size(const EVP_MD *md)

int EVP_MD_get_size(const EVP_MD *md)

int EC_GROUP_get_curve(const EC_GROUP *group, BIGNUM *p, BIGNUM *a, BIGNUM *b, BN_CTX *ctx)

EC_POINT *EC_POINT_new(const EC_GROUP *group)

int EC_POINT_set_affine_coordinates(const EC_GROUP *group, EC_POINT *p, const BIGNUM *x, const BIGNUM *y, BN_CTX *ctx)

int EC_POINT_get_affine_coordinates(const EC_GROUP *group, const EC_POINT *p, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int sgn0_m_eq_1(BIGNUM *x)

int clear_cofactor(EC_GROUP *group, EC_POINT *P, EC_POINT *Q, BN_CTX* ctx)

BIGNUM* CMOV(BIGNUM *a, BIGNUM *b, int c)

int calc_c1_c2_for_sswu(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BN_CTX *ctx)

int map_to_curve_sswu_straight_line(BIGNUM *c1, BIGNUM *c2, BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)

int map_to_curve_sswu_not_straight_line(BIGNUM *p, BIGNUM *a, BIGNUM *b, BIGNUM *z, BIGNUM *u, BIGNUM *x, BIGNUM *y, BN_CTX *ctx)


SV* hkdf_main(int mode, unsigned char* digest_name, SV* ikm_sv, SV* salt_sv, SV* info_sv, size_t okm_len)
    CODE:
    {
    unsigned char *ikm= NULL;
    size_t ikm_len;
    unsigned char *salt= NULL;
    size_t salt_len;
    unsigned char *info= NULL;
    size_t info_len;
    unsigned char* okm = NULL;
    size_t out_len;

    ikm = (unsigned char*) SvPV( ikm_sv, ikm_len );
    salt = (unsigned char*) SvPV( salt_sv, salt_len );
    info = (unsigned char*) SvPV( info_sv, info_len );

    /*hexdump("hkdf main ikm", ikm, ikm_len);*/
    /*hexdump("hkdf main salt", salt, salt_len);*/
    /*hexdump("hkdf main info", info, info_len);*/

    out_len = hkdf_raw(mode, digest_name, ikm, ikm_len, salt, salt_len, info, info_len, &okm, okm_len);

    /*hexdump("hkdf main okm", okm, okm_len);*/

    RETVAL = newSVpv(okm, out_len);

    }
    OUTPUT:
        RETVAL

SV* hmac(unsigned char* digest_name, SV* key_sv, SV* msg_sv)
    CODE:
    {
    unsigned char *key= NULL;
    size_t key_len;
    unsigned char *msg= NULL;
    size_t msg_len;
    unsigned char* out = NULL;
    size_t out_len = 0;

    key = (unsigned char*) SvPV( key_sv, key_len );
    msg = (unsigned char*) SvPV( msg_sv, msg_len );

    out_len = hmac_raw(digest_name, key, key_len, msg, msg_len, &out);

    RETVAL = newSVpv(out, out_len);

    }
    OUTPUT:
        RETVAL


SV* aes_cmac(unsigned char* cipher_name, SV* key_sv, SV* msg_sv)
    CODE:
    {
    unsigned char *key= NULL;
    size_t key_len;
    unsigned char *msg= NULL;
    size_t msg_len;
    unsigned char* out = NULL;
    size_t out_len;

    key = (unsigned char*) SvPV( key_sv, key_len );
    msg = (unsigned char*) SvPV( msg_sv, msg_len );

    out = aes_cmac_raw(cipher_name, key, key_len, msg, msg_len, &out_len);

    RETVAL = newSVpv(out, out_len);

    }
    OUTPUT:
        RETVAL

SV* pkcs12_key_gen(SV* password_sv, SV* salt_sv, unsigned int id, unsigned int iteration, unsigned char* digest_name)
    CODE:
    {
    unsigned char *password= NULL;
    size_t password_len;
    unsigned char *salt= NULL;
    size_t salt_len;
    unsigned char* out = NULL;
    size_t out_len;

    password = (unsigned char*) SvPV( password_sv, password_len );
    salt = (unsigned char*) SvPV( salt_sv, salt_len );

    out = pkcs12_key_gen_raw(password, password_len, salt, salt_len, id, iteration, digest_name, &out_len);

    RETVAL = newSVpv(out, out_len);

    }
    OUTPUT:
        RETVAL

SV* pkcs5_pbkdf2_hmac(SV* password_sv, SV* salt_sv, unsigned int iteration, unsigned char* digest_name)
    CODE:
    {
    unsigned char *password= NULL;
    size_t password_len;
    unsigned char *salt= NULL;
    size_t salt_len;
    unsigned char* out = NULL;
    size_t out_len;

    password = (unsigned char*) SvPV( password_sv, password_len );
    salt = (unsigned char*) SvPV( salt_sv, salt_len );

    out = pkcs5_pbkdf2_hmac_raw(password, password_len, salt, salt_len, iteration, digest_name, &out_len);

    RETVAL = newSVpv(out, out_len);

    }
    OUTPUT:
        RETVAL

SV* digest_array(unsigned char *digest_name, AV* arr)
    CODE:
    {
    const EVP_MD *digest;
    digest = EVP_get_digestbyname(digest_name);

    EVP_MD_CTX *mdctx= EVP_MD_CTX_new();
    EVP_DigestInit_ex2(mdctx, digest, NULL);

    size_t arr_len = av_len(arr);
    for(int i=0;i<=arr_len; i++)
    {
        SV** msg_SV = av_fetch(arr, i, 0);
        size_t msg_len;
        unsigned char* msg = (unsigned char*) SvPV( *msg_SV, msg_len );
        EVP_DigestUpdate(mdctx, msg, msg_len);
    }

    unsigned int out_len = EVP_MD_get_size(digest);
    unsigned char* out = OPENSSL_malloc(out_len); 
    EVP_DigestFinal_ex(mdctx, out, &out_len);

    EVP_MD_CTX_free(mdctx);

    RETVAL = newSVpv(out, out_len);
    }
    OUTPUT:
        RETVAL


SV* ecdh(EVP_PKEY *priv, EVP_PKEY *peer_pub)
    CODE:
    {
    unsigned char* out = NULL;
    size_t out_len;

    out = ecdh_raw(priv, peer_pub, &out_len);

    RETVAL = newSVpv(out, out_len);
    }
    OUTPUT:
        RETVAL

SV* ecdsa_sign(EVP_PKEY *priv_key, const char* sig_name, SV* msg_SV)
    CODE:
    {
    unsigned char *msg;
    size_t msg_len;

    unsigned char *sig;
    size_t sig_len;
    SV* sig_SV ;

    msg = (unsigned char*) SvPV( msg_SV, msg_len );

    sig_len = ecdsa_sign_raw(priv_key, sig_name, msg, msg_len, &sig);

    sig_SV = newSVpv(sig, sig_len);

    RETVAL = sig_SV;

    }
    OUTPUT:
        RETVAL

int ecdsa_verify(EVP_PKEY *pub_key, unsigned char* sig_name, SV* msg_SV, SV* sig_SV)
    CODE:
    {
    unsigned char *msg;
    size_t msg_len;
    unsigned char *sig;
    size_t sig_len;
    int ret = 0;


    msg = (unsigned char*) SvPV( msg_SV, msg_len );
    sig = (unsigned char*) SvPV( sig_SV, sig_len );

    ret = ecdsa_verify_raw(pub_key, sig_name, msg, msg_len, sig, sig_len);

    RETVAL = ret;

    }
    OUTPUT:
        RETVAL

SV* symmetric_encrypt(unsigned char* cipher_name, SV* plaintext_SV, SV* key_SV, SV* iv_SV)
    CODE:
    {
    unsigned char *plaintext;
    size_t plaintext_len;
    unsigned char *key;
    size_t key_len;
    unsigned char *iv;
    size_t iv_len;

    unsigned char *ciphertext;
    size_t ciphertext_len;
    SV* ciphertext_SV ;

    plaintext = (unsigned char*) SvPV( plaintext_SV, plaintext_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    int is_encrypt = 1;
    ciphertext_len = symmetric_cipher_raw(cipher_name, plaintext, plaintext_len, key, iv, iv_len, &ciphertext, is_encrypt);

    ciphertext_SV = newSVpv(ciphertext, ciphertext_len);


    RETVAL = ciphertext_SV;

    }
    OUTPUT:
        RETVAL

SV* symmetric_decrypt(unsigned char* cipher_name, SV* ciphertext_SV, SV* key_SV, SV* iv_SV)
    CODE:
    {
    unsigned char *ciphertext;
    size_t ciphertext_len;
    unsigned char *key;
    size_t key_len;
    unsigned char *iv;
    size_t iv_len;

    unsigned char *plaintext;
    size_t plaintext_len;
    SV* plaintext_SV ;

    ciphertext = (unsigned char*) SvPV( ciphertext_SV, ciphertext_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    int is_encrypt = 0;
    plaintext_len = symmetric_cipher_raw(cipher_name, ciphertext, ciphertext_len, key, iv, iv_len, &plaintext, is_encrypt);

    plaintext_SV = newSVpv(plaintext, plaintext_len);


    RETVAL = plaintext_SV;

    }
    OUTPUT:
        RETVAL

SV* aead_encrypt(unsigned char* cipher_name, SV* plaintext_SV, SV* aad_SV, SV* key_SV, SV* iv_SV, int tag_len)
    CODE:
    {
    unsigned char *plaintext;
    size_t plaintext_len;
    unsigned char *aad;
    size_t aad_len;
    unsigned char *key;
    size_t key_len;
    unsigned char *iv;
    size_t iv_len;

    unsigned char *ciphertext;
    size_t ciphertext_len;
    SV* ciphertext_SV ;
    SV* tag_SV ;
    unsigned char *tag;

    AV* av = newAV();

    plaintext = (unsigned char*) SvPV( plaintext_SV, plaintext_len );
    aad = (unsigned char*) SvPV( aad_SV, aad_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    ciphertext_len = aead_encrypt_raw(cipher_name, plaintext, plaintext_len, aad, aad_len, key, iv, iv_len, &ciphertext, &tag, tag_len);

    ciphertext_SV = newSVpv(ciphertext, ciphertext_len);
    tag_SV = newSVpv(tag, tag_len);

    av_push(av, ciphertext_SV);
    av_push(av, tag_SV);

    RETVAL = newRV_noinc((SV*)av);

    /*int nid = OBJ_sn2nid(group_name);*/
    /*SV* nid_sv = newSViv(nid);*/
    /*SV* group_name_sv = newSVpv(group_name, strlen(group_name));*/

    /*hv = newHV ();*/
    /*hv_store (hv, "nid", strlen ("nid"), nid_sv, 0);*/
    /*hv_store (hv, "group_name", strlen ("group_name"), group_name_sv , 0);*/
    /*RETVAL = newRV_inc ((SV *) hv);*/

    }
    OUTPUT:
        RETVAL

SV* aead_decrypt(unsigned char* cipher_name, SV* ciphertext_SV, SV* aad_SV, SV* tag_SV, SV* key_SV, SV* iv_SV)
    CODE:
    {
    SV *res =NULL;
    unsigned char *plaintext;
    int plaintext_len;
    unsigned char *ciphertext;
    size_t ciphertext_len;
    unsigned char *aad;
    size_t aad_len;
    unsigned char *tag;
    size_t tag_len;
    unsigned char *key;
    size_t key_len;
    unsigned char *iv;
    size_t iv_len;

    ciphertext = (unsigned char*) SvPV( ciphertext_SV, ciphertext_len );
    aad = (unsigned char*) SvPV( aad_SV, aad_len );
    tag = (unsigned char*) SvPV( tag_SV, tag_len );
    key = (unsigned char*) SvPV( key_SV, key_len );
    iv = (unsigned char*) SvPV( iv_SV, iv_len );

    plaintext_len = aead_decrypt_raw(cipher_name, ciphertext, ciphertext_len, aad, aad_len, tag, tag_len, key, iv, iv_len, &plaintext);

    if(plaintext_len>0){
        res = newSVpv(plaintext, plaintext_len);
    }

    RETVAL = res;
    }
    OUTPUT:
        RETVAL


SV* get_pkey_octet_string_param(EVP_PKEY *pkey, unsigned char* param_name)
    CODE:
    {
    unsigned char *s;
    size_t s_len;
    SV* s_SV ;

    s_len = get_pkey_octet_string_param_raw(pkey, param_name, &s);

    s_SV = newSVpv(s, s_len);

    RETVAL = s_SV;

    }
    OUTPUT:
        RETVAL

SV* rsa_oaep_encrypt(unsigned char* digest_name, EVP_PKEY *pub, SV* plaintext_SV)
    CODE:
    {
    unsigned char *plaintext;
    size_t plaintext_len;
    unsigned char *ciphertext;
    size_t ciphertext_len;
    SV* ciphertext_SV ;

    plaintext = (unsigned char*) SvPV( plaintext_SV, plaintext_len );

    ciphertext_len = rsa_oaep_encrypt_raw(digest_name, pub, plaintext, plaintext_len, &ciphertext);

    ciphertext_SV = newSVpv(ciphertext, ciphertext_len);

    RETVAL = ciphertext_SV;

    }
    OUTPUT:
        RETVAL

SV* rsa_oaep_decrypt(unsigned char* digest_name, EVP_PKEY *priv, SV* ciphertext_SV)
    CODE:
    {
    SV *res;
    unsigned char *plaintext;
    size_t plaintext_len;
    unsigned char *ciphertext;
    size_t ciphertext_len;

    ciphertext = (unsigned char*) SvPV( ciphertext_SV, ciphertext_len );

    plaintext_len = rsa_oaep_decrypt_raw(digest_name, priv, ciphertext, ciphertext_len, &plaintext);

    res = newSVpv(plaintext, plaintext_len);

    RETVAL = res;
    }
    OUTPUT:
        RETVAL





