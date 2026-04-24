#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/err.h>
#include <openssl/md5.h>
#include <openssl/objects.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/ripemd.h>
#if OPENSSL_VERSION_NUMBER >= 0x10000000 && OPENSSL_VERSION_NUMBER < 0x30000000
#ifndef LIBRESSL_VERSION_NUMBER
#ifndef OPENSSL_NO_WHIRLPOOL
#include <openssl/whrlpool.h>
#endif
#endif
#endif
#include <openssl/rsa.h>
#include <openssl/sha.h>
#include <openssl/ssl.h>
#include <openssl/evp.h>
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#include <openssl/core_names.h>
#include <openssl/param_build.h>
#include <openssl/encoder.h>
#include <openssl/decoder.h>
#endif

/* Pre-3.x helper for PKCS#8 export: wraps RSA* in a real EVP_PKEY and
   writes PKCS#8 PEM.  Defined BEFORE the EVP_PKEY->RSA compatibility
   macros so that EVP_PKEY, EVP_PKEY_new, EVP_PKEY_free, and
   PEM_write_bio_PrivateKey resolve to their real OpenSSL symbols. */
#if OPENSSL_VERSION_NUMBER < 0x30000000L
static int _write_pkcs8_pem(BIO* bio, RSA* rsa, const EVP_CIPHER* enc,
                            unsigned char* pass, int passlen)
{
    EVP_PKEY* pkey = EVP_PKEY_new();
    int ok;
    if (!pkey) return 0;
    if (!EVP_PKEY_set1_RSA(pkey, rsa)) {
        EVP_PKEY_free(pkey);
        return 0;
    }
    ok = PEM_write_bio_PrivateKey(bio, pkey, enc, pass, passlen, NULL, NULL);
    EVP_PKEY_free(pkey);
    return ok;
}
#endif

/* Pre-3.x helper for loading encrypted PKCS#8 DER private keys.
   Placed BEFORE the EVP_PKEY->RSA compatibility macros so that
   EVP_PKEY, EVP_PKEY_free, and EVP_PKEY_get1_RSA resolve to their
   real OpenSSL symbols. */
#if OPENSSL_VERSION_NUMBER < 0x30000000L
static RSA* _load_pkcs8_der_key(BIO* bio, const char* passphrase)
{
    EVP_PKEY* pkey;
    RSA* rsa;

    pkey = d2i_PKCS8PrivateKey_bio(bio, NULL, NULL, (void*)passphrase);
    if (!pkey)
        return NULL;

    rsa = EVP_PKEY_get1_RSA(pkey);
    EVP_PKEY_free(pkey);
    return rsa;
}
#endif

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#define UNSIGNED_CHAR unsigned char
#define SIZE_T_INT size_t
#define SIZE_T_UNSIGNED_INT size_t
#define EVP_PKEY EVP_PKEY
#define EVP_PKEY_free(p) EVP_PKEY_free(p)
#define EVP_PKEY_get_size(p) EVP_PKEY_get_size(p)
#define PEM_read_bio_PrivateKey PEM_read_bio_PrivateKey
#define PEM_read_bio_RSAPublicKey PEM_read_bio_PUBKEY
#define PEM_read_bio_RSA_PUBKEY PEM_read_bio_PUBKEY
#define PEM_write_bio_PUBKEY(o,p) PEM_write_bio_PUBKEY(o,p)
#define PEM_write_bio_PrivateKey_traditional(m, n, o, p, q, r, s) PEM_write_bio_PrivateKey_traditional(m, n, o, p, q, r, s)
#else
#define UNSIGNED_CHAR char
#define SIZE_T_INT int
#define SIZE_T_UNSIGNED_INT unsigned int
#define EVP_PKEY RSA
#define EVP_PKEY_free(p) RSA_free(p)
#define EVP_PKEY_get_size(p) RSA_size(p)
#define PEM_read_bio_PrivateKey PEM_read_bio_RSAPrivateKey
#define PEM_read_bio_RSAPublicKey PEM_read_bio_RSAPublicKey
#define PEM_read_bio_RSA_PUBKEY PEM_read_bio_RSA_PUBKEY
#define PEM_write_bio_PUBKEY(o,p) PEM_write_bio_RSA_PUBKEY(o,p)
#define PEM_write_bio_PrivateKey_traditional(m, n, o, p, q, r, s) PEM_write_bio_RSAPrivateKey(m, n , o, p, q, r, s)
#endif

typedef struct
{
    EVP_PKEY* rsa;
    int padding;
    int hashMode;
    int is_private_key;  /* cached once at construction; avoids per-call BIGNUM alloc on 3.x */
} rsaData;

/* Key names for the rsa hash structure */

#define KEY_KEY "_Key"
#define PADDING_KEY "_Padding"
#define HASH_KEY "_Hash_Mode"

#define PACKAGE_NAME "Crypt::OpenSSL::RSA"

#ifdef LIBRESSL_VERSION_NUMBER
#define OLD_CRUFTY_SSL_VERSION (OPENSSL_VERSION_NUMBER < 0x10100000L || LIBRESSL_VERSION_NUMBER < 0x03050000fL)
#else
#define OLD_CRUFTY_SSL_VERSION (OPENSSL_VERSION_NUMBER < 0x10100000L)
#endif

void croakSsl(char* p_file, int p_line)
{
    const char* errorReason;
    unsigned long last_err = 0;
    unsigned long err;
    /* Drain the error queue and use the last (most recent) error,
       which is typically the most descriptive.  This also prevents
       stale errors from a previous eval-caught failure from leaking
       into the next croak message. */
    while ((err = ERR_get_error()) != 0) {
        last_err = err;
    }
    errorReason = ERR_reason_error_string(last_err);
    croak("%s:%d: OpenSSL error: %s", p_file, p_line,
          errorReason ? errorReason : "(unknown error)");
}

#define CHECK_OPEN_SSL(p_result) if (!(p_result)) croakSsl(__FILE__, __LINE__);
#define CHECK_OPEN_SSL_BIO(p_result, bio) \
    if (!(p_result)) { BIO_free(bio); croakSsl(__FILE__, __LINE__); }

#define PACKAGE_CROAK(p_message) croak("%s", (p_message))
#define CHECK_NEW(p_var, p_size, p_type) \
  if (New(0, p_var, p_size, p_type) == NULL) \
    { PACKAGE_CROAK("unable to alloc buffer"); }

#define THROW(p_result) if (!(p_result)) { error = 1; goto err; }

char _is_private(rsaData* p_rsa)
{
    return p_rsa->is_private_key;
}

static int _detect_private_key(EVP_PKEY* p_rsa)
{
#if OLD_CRUFTY_SSL_VERSION
    return (p_rsa->d != NULL);
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    BIGNUM* d = NULL;
    EVP_PKEY_get_bn_param(p_rsa, OSSL_PKEY_PARAM_RSA_D, &d);
    if (d) {
        BN_clear_free(d);
        return 1;
    }
    return 0;
#else
    const BIGNUM* d = NULL;
    RSA_get0_key(p_rsa, NULL, NULL, &d);
    return (d != NULL);
#endif
#endif
}

SV* make_rsa_obj(SV* p_proto, EVP_PKEY* p_rsa)
{
    rsaData* rsa;

    CHECK_NEW(rsa, 1, rsaData);
    rsa->rsa = p_rsa;
#ifdef SHA512_DIGEST_LENGTH
    rsa->hashMode = NID_sha256;
#else
    rsa->hashMode = NID_sha1;
#endif
    rsa->padding = RSA_PKCS1_OAEP_PADDING;
    rsa->is_private_key = _detect_private_key(p_rsa);
    return sv_bless(
        newRV_noinc(newSViv((IV) rsa)),
        (SvROK(p_proto) ? SvSTASH(SvRV(p_proto)) : gv_stashsv(p_proto, 1)));
}

int get_digest_length(int hash_method)
{
    switch(hash_method)
    {
        case NID_md5:
            return MD5_DIGEST_LENGTH;
            break;
        case NID_sha1:
            return SHA_DIGEST_LENGTH;
            break;
#ifdef SHA512_DIGEST_LENGTH
        case NID_sha224:
            return SHA224_DIGEST_LENGTH;
            break;
        case NID_sha256:
            return SHA256_DIGEST_LENGTH;
            break;
        case NID_sha384:
            return SHA384_DIGEST_LENGTH;
            break;
        case NID_sha512:
            return SHA512_DIGEST_LENGTH;
            break;
#endif
        case NID_ripemd160:
            return RIPEMD160_DIGEST_LENGTH;
            break;
#ifdef WHIRLPOOL_DIGEST_LENGTH
        case NID_whirlpool:
            return WHIRLPOOL_DIGEST_LENGTH;
            break;
#endif
        default:
            croak("Unknown digest hash mode %u", hash_method);
            break;
    }
}
#if OPENSSL_VERSION_NUMBER >= 0x30000000L

EVP_MD *get_md_bynid(int hash_method)
{
    switch(hash_method)
    {
        case NID_md5:
            return EVP_MD_fetch(NULL, "md5", NULL);
            break;
        case NID_sha1:
            return EVP_MD_fetch(NULL, "sha1", NULL);
            break;
#ifdef SHA512_DIGEST_LENGTH
        case NID_sha224:
            return EVP_MD_fetch(NULL, "sha224", NULL);
            break;
        case NID_sha256:
            return EVP_MD_fetch(NULL, "sha256", NULL);
            break;
        case NID_sha384:
            return EVP_MD_fetch(NULL, "sha384", NULL);
            break;
        case NID_sha512:
            return EVP_MD_fetch(NULL, "sha512", NULL);
            break;
#endif
        case NID_ripemd160:
            return EVP_MD_fetch(NULL, "ripemd160", NULL);
            break;
#ifdef WHIRLPOOL_DIGEST_LENGTH
        case NID_whirlpool:
            return EVP_MD_fetch(NULL, "whirlpool", NULL);
            break;
#endif
        default:
            croak("Unknown digest hash mode %u", hash_method);
            break;
    }
}

/* Configure PSS/PKCS1 padding, signature digest, and MGF1 on an already-initialised
 * EVP_PKEY_CTX.  On success returns 1 and sets *md_out to a freshly-fetched EVP_MD
 * that the caller must free with EVP_MD_free().  Returns 0 on any OpenSSL error. */
static int
setup_pss_sign_ctx(EVP_PKEY_CTX *ctx, int padding, int hash_nid, EVP_MD **md_out)
{
    int effective_pad = padding;
    EVP_MD *md = NULL;

    if (padding != RSA_NO_PADDING && padding != RSA_PKCS1_PADDING)
        effective_pad = RSA_PKCS1_PSS_PADDING;

    if (EVP_PKEY_CTX_set_rsa_padding(ctx, effective_pad) <= 0)
        return 0;

    md = get_md_bynid(hash_nid);
    if (!md)
        return 0;

    if (EVP_PKEY_CTX_set_signature_md(ctx, md) <= 0) {
        EVP_MD_free(md);
        return 0;
    }

    if (effective_pad == RSA_PKCS1_PSS_PADDING) {
        if (EVP_PKEY_CTX_set_rsa_mgf1_md(ctx, md) <= 0 ||
            EVP_PKEY_CTX_set_rsa_pss_saltlen(ctx, RSA_PSS_SALTLEN_DIGEST) <= 0) {
            EVP_MD_free(md);
            return 0;
        }
    }

    *md_out = md;
    return 1;
}
#endif
unsigned char* get_message_digest(SV* text_SV, int hash_method, unsigned char* md)
{
    STRLEN text_length;
    unsigned char* text;
    text = (unsigned char*) SvPV(text_SV, text_length);

#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    /* Delegate NID→name lookup to get_md_bynid() — single source of truth. */
    {
        EVP_MD *md_obj = get_md_bynid(hash_method); /* croak()s on unknown NID */
        unsigned int result_len;
        int ok = EVP_Digest(text, text_length, md, &result_len, md_obj, NULL);
        EVP_MD_free(md_obj);
        return ok ? md : NULL;
    }
#else
    switch(hash_method)
    {
        case NID_md5:
            return MD5(text, text_length, md);
            break;
        case NID_sha1:
            return SHA1(text, text_length, md);
            break;
#ifdef SHA512_DIGEST_LENGTH
        case NID_sha224:
            return SHA224(text, text_length, md);
            break;
        case NID_sha256:
            return SHA256(text, text_length, md);
            break;
        case NID_sha384:
            return SHA384(text, text_length, md);
            break;
        case NID_sha512:
            return SHA512(text, text_length, md);
            break;
#endif
        case NID_ripemd160:
            return RIPEMD160(text, text_length, md);
            break;
#ifdef WHIRLPOOL_DIGEST_LENGTH
        case NID_whirlpool:
            return WHIRLPOOL(text, text_length, md);
            break;
#endif
        default:
            croak("Unknown digest hash mode %u", hash_method);
            break;
    }
#endif
}

SV* cor_bn2sv(const BIGNUM* p_bn)
{
    return p_bn != NULL
        ? sv_2mortal(newSViv((IV) BN_dup(p_bn)))
        : &PL_sv_undef;
}

SV* extractBioString(BIO* p_stringBio)
{
    SV* sv;
    char* datap;
    long datasize;
    int error = 0;

    THROW(BIO_flush(p_stringBio) == 1);

    datasize = BIO_get_mem_data(p_stringBio, &datap);
    THROW(datasize > 0);

    sv = newSVpv(datap, datasize);

    BIO_set_close(p_stringBio, BIO_CLOSE);
    BIO_free(p_stringBio);
    return sv;

    err:
        BIO_free(p_stringBio);
        CHECK_OPEN_SSL(0);
        return NULL; /* unreachable, CHECK_OPEN_SSL croaks */
}

EVP_PKEY*  _load_rsa_key(SV* p_keyStringSv,
                        EVP_PKEY*(*p_loader)(BIO *, EVP_PKEY**, pem_password_cb*, void*),
                   SV* p_passphraseSv)
{
    STRLEN keyStringLength;
    char* keyString;
    UNSIGNED_CHAR *passphrase = NULL;

    EVP_PKEY* rsa;
    BIO* stringBIO;

    keyString = SvPV(p_keyStringSv, keyStringLength);

    if (SvPOK(p_passphraseSv)) {
        passphrase = (UNSIGNED_CHAR *)SvPV_nolen(p_passphraseSv);
    }

    CHECK_OPEN_SSL(stringBIO = BIO_new_mem_buf(keyString, keyStringLength));

    rsa = p_loader(stringBIO, NULL, NULL, passphrase);

    CHECK_OPEN_SSL(BIO_set_close(stringBIO, BIO_CLOSE) == 1);
    BIO_free(stringBIO);

    CHECK_OPEN_SSL(rsa);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    /* On 3.x, PEM_read_bio_PrivateKey/PEM_read_bio_PUBKEY accept any key
       type (EC, DSA, etc.).  Pre-3.x used RSA-specific loaders that would
       reject non-RSA keys at parse time.  Validate here to preserve that
       behavior and give a clear error instead of confusing failures later.
       Also rejects RSA-PSS keys (EVP_PKEY_RSA_PSS) — this module
       only supports traditional RSA (EVP_PKEY_RSA). */
    if (EVP_PKEY_get_base_id(rsa) != EVP_PKEY_RSA) {
        EVP_PKEY_free(rsa);
        croak("The key loaded is not an RSA key");
    }
#endif
    return rsa;
}

static void check_max_message_length(rsaData* p_rsa, STRLEN from_length) {
    int size;
    int max_len = -1;
    const char *pad_name = NULL;

    size = EVP_PKEY_get_size(p_rsa->rsa);

    if (p_rsa->padding == RSA_PKCS1_OAEP_PADDING) {
        max_len = size - 42;  /* 2 * SHA1_DIGEST_LENGTH + 2 */
        pad_name = "OAEP";
    } else if (p_rsa->padding == RSA_PKCS1_PADDING) {
        max_len = size - 11;  /* PKCS#1 v1.5 overhead */
        pad_name = "PKCS#1 v1.5";
    } else if (p_rsa->padding == RSA_NO_PADDING) {
        max_len = size;
        pad_name = "no";
    }
    if (max_len >= 0 && from_length > (STRLEN) max_len) {
        croak("plaintext too long for key size with %s padding"
              " (%d bytes max, got %d)", pad_name, max_len, (int)from_length);
    }
}
#if OPENSSL_VERSION_NUMBER >= 0x30000000L

SV* rsa_crypt(rsaData* p_rsa, SV* p_from,
              int (*p_crypt)(EVP_PKEY_CTX*, unsigned char*, size_t*, const unsigned char*, size_t),
              int (*init_crypt)(EVP_PKEY_CTX*), int is_encrypt)
#else

SV* rsa_crypt(rsaData* p_rsa, SV* p_from,
              int (*p_crypt)(int, const unsigned char*, unsigned char*, RSA*, int), int is_encrypt)
#endif
{
    STRLEN from_length;
    SIZE_T_INT to_length;
    unsigned char* from;
    UNSIGNED_CHAR *to = NULL;
    SV* sv;
#if OPENSSL_VERSION_NUMBER < 0x30000000L
    int size;
#endif

    from = (unsigned char*) SvPV(p_from, from_length);

    if(is_encrypt && p_rsa->padding == RSA_PKCS1_PADDING) {
        croak("PKCS#1 v1.5 padding for encryption is vulnerable to the Marvin attack. "
              "Use use_pkcs1_oaep_padding() for encryption, or use_pkcs1_padding() with sign()/verify().");
    }

    if(is_encrypt && p_rsa->padding == RSA_PKCS1_PSS_PADDING) {
        croak("PKCS#1 v2.1 RSA-PSS cannot be used for encryption operations call \"use_pkcs1_oaep_padding\" instead.");
    }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY_CTX *ctx = NULL;
    int error = 0;

    if (is_encrypt) {
        /* Encryption path: OAEP is the only safe padding for encrypt/decrypt. */
        if (p_rsa->padding != RSA_NO_PADDING && p_rsa->padding != RSA_PKCS1_OAEP_PADDING) {
            croak("Only OAEP padding or no padding is supported for encrypt/decrypt. "
                  "Call \"use_pkcs1_oaep_padding()\" or \"use_no_padding()\" first.");
        }
    } else {
        /* Sign/verify_recover path (private_encrypt / public_decrypt):
           these are low-level RSA operations that respect the user's
           padding choice.  OAEP and PSS are not valid here. */
        if (p_rsa->padding == RSA_PKCS1_OAEP_PADDING) {
            croak("OAEP padding is not supported for private_encrypt/public_decrypt. "
                  "Call use_no_padding() or use_pkcs1_padding() first.");
        }
        if (p_rsa->padding == RSA_PKCS1_PSS_PADDING) {
            croak("PSS padding with private_encrypt/public_decrypt is not supported. "
                  "Use sign()/verify() for PSS signatures.");
        }
    }

    ctx = EVP_PKEY_CTX_new_from_pkey(NULL, (EVP_PKEY* )p_rsa->rsa, NULL);

    THROW(ctx);

    THROW(init_crypt(ctx) == 1);
    THROW(EVP_PKEY_CTX_set_rsa_padding(ctx, p_rsa->padding) > 0);
    THROW(p_crypt(ctx, NULL, &to_length, from, from_length) == 1);
    Newx(to, to_length, UNSIGNED_CHAR);
    THROW(to);
    THROW(p_crypt(ctx, to, &to_length, from, from_length) == 1);

    EVP_PKEY_CTX_free(ctx);

    goto crypt_done;
    err:
        if (ctx) EVP_PKEY_CTX_free(ctx);
        Safefree(to);
        CHECK_OPEN_SSL(0);
    crypt_done:
#else
    size = EVP_PKEY_get_size(p_rsa->rsa);
    CHECK_NEW(to, size, UNSIGNED_CHAR);
    to_length = p_crypt(
       from_length, from, (unsigned char*) to, p_rsa->rsa, p_rsa->padding);
#endif
    if (to_length < 0)
    {
        Safefree(to);
        CHECK_OPEN_SSL(0);
    }
    sv = newSVpv((char* ) to, to_length);
    Safefree(to);
    return sv;
}

MODULE = Crypt::OpenSSL::RSA		PACKAGE = Crypt::OpenSSL::RSA
PROTOTYPES: DISABLE

BOOT:
#if OPENSSL_VERSION_NUMBER < 0x10100000L
    # might introduce memory leak without calling EVP_cleanup() on exit
    # see https://wiki.openssl.org/index.php/Library_Initialization
    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
#else
    # NOOP
#endif

SV*
_new_private_key_pem(proto, key_string_SV, passphrase_SV=&PL_sv_undef)
    SV* proto;
    SV* key_string_SV;
    SV* passphrase_SV;
  CODE:
    RETVAL = make_rsa_obj(
        proto, _load_rsa_key(key_string_SV, PEM_read_bio_PrivateKey, passphrase_SV));
  OUTPUT:
    RETVAL

SV*
_new_public_key_pkcs1(proto, key_string_SV)
    SV* proto;
    SV* key_string_SV;
  CODE:
    RETVAL = make_rsa_obj(
        proto, _load_rsa_key(key_string_SV, PEM_read_bio_RSAPublicKey, &PL_sv_undef));
  OUTPUT:
    RETVAL

SV*
_new_public_key_x509(proto, key_string_SV)
    SV* proto;
    SV* key_string_SV;
  CODE:
    RETVAL = make_rsa_obj(
        proto, _load_rsa_key(key_string_SV, PEM_read_bio_RSA_PUBKEY, &PL_sv_undef));
  OUTPUT:
    RETVAL

SV*
_new_public_key_x509_der(proto, key_string_SV)
    SV* proto;
    SV* key_string_SV;
  PREINIT:
    STRLEN keyStringLength;
    char* keyString;
    EVP_PKEY* pkey;
    BIO* bio;
  CODE:
    keyString = SvPV(key_string_SV, keyStringLength);
    CHECK_OPEN_SSL(bio = BIO_new_mem_buf(keyString, keyStringLength));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    pkey = d2i_PUBKEY_bio(bio, NULL);
#else
    pkey = d2i_RSA_PUBKEY_bio(bio, NULL);
#endif
    BIO_free(bio);
    CHECK_OPEN_SSL(pkey);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    if (EVP_PKEY_get_base_id(pkey) != EVP_PKEY_RSA) {
        EVP_PKEY_free(pkey);
        croak("The key loaded is not an RSA key");
    }
#endif
    RETVAL = make_rsa_obj(proto, pkey);
  OUTPUT:
    RETVAL

SV*
_new_public_key_pkcs1_der(proto, key_string_SV)
    SV* proto;
    SV* key_string_SV;
  PREINIT:
    STRLEN keyStringLength;
    char* keyString;
    EVP_PKEY* pkey;
    BIO* bio;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    OSSL_DECODER_CTX* dctx;
#endif
  CODE:
    keyString = SvPV(key_string_SV, keyStringLength);
    CHECK_OPEN_SSL(bio = BIO_new_mem_buf(keyString, keyStringLength));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    pkey = NULL;
    dctx = OSSL_DECODER_CTX_new_for_pkey(&pkey, "DER", "type-specific",
                                          "RSA", OSSL_KEYMGMT_SELECT_PUBLIC_KEY,
                                          NULL, NULL);
    if (!dctx) {
        BIO_free(bio);
        croakSsl(__FILE__, __LINE__);
    }
    if (!OSSL_DECODER_from_bio(dctx, bio)) {
        OSSL_DECODER_CTX_free(dctx);
        BIO_free(bio);
        croakSsl(__FILE__, __LINE__);
    }
    OSSL_DECODER_CTX_free(dctx);
#else
    pkey = d2i_RSAPublicKey_bio(bio, NULL);
#endif
    BIO_free(bio);
    CHECK_OPEN_SSL(pkey);
    RETVAL = make_rsa_obj(proto, pkey);
  OUTPUT:
    RETVAL

SV*
_new_private_key_der(proto, key_string_SV, passphrase_SV=&PL_sv_undef)
    SV* proto;
    SV* key_string_SV;
    SV* passphrase_SV;
  PREINIT:
    STRLEN keyStringLength;
    char* keyString;
    EVP_PKEY* pkey;
    BIO* bio;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    OSSL_DECODER_CTX* dctx;
#endif
  CODE:
    keyString = SvPV(key_string_SV, keyStringLength);
    CHECK_OPEN_SSL(bio = BIO_new_mem_buf(keyString, keyStringLength));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    pkey = NULL;
    dctx = OSSL_DECODER_CTX_new_for_pkey(&pkey, "DER", NULL,
                                          "RSA", OSSL_KEYMGMT_SELECT_ALL,
                                          NULL, NULL);
    if (!dctx) {
        BIO_free(bio);
        croakSsl(__FILE__, __LINE__);
    }
    if (SvPOK(passphrase_SV)) {
        STRLEN passlen;
        unsigned char* pass = (unsigned char*)SvPV(passphrase_SV, passlen);
        if (!OSSL_DECODER_CTX_set_passphrase(dctx, pass, passlen)) {
            OSSL_DECODER_CTX_free(dctx);
            BIO_free(bio);
            croakSsl(__FILE__, __LINE__);
        }
    }
    if (!OSSL_DECODER_from_bio(dctx, bio)) {
        OSSL_DECODER_CTX_free(dctx);
        BIO_free(bio);
        croakSsl(__FILE__, __LINE__);
    }
    OSSL_DECODER_CTX_free(dctx);
#else
    if (SvPOK(passphrase_SV)) {
        char* passphrase = SvPV_nolen(passphrase_SV);
        pkey = _load_pkcs8_der_key(bio, passphrase);
    } else {
        pkey = d2i_RSAPrivateKey_bio(bio, NULL);
    }
#endif
    BIO_free(bio);
    CHECK_OPEN_SSL(pkey);
    RETVAL = make_rsa_obj(proto, pkey);
  OUTPUT:
    RETVAL

void
DESTROY(p_rsa)
    rsaData* p_rsa;
  CODE:
    EVP_PKEY_free(p_rsa->rsa);
    Safefree(p_rsa);

SV*
get_private_key_string(p_rsa, passphrase_SV=&PL_sv_undef, cipher_name_SV=&PL_sv_undef)
    rsaData* p_rsa;
    SV* passphrase_SV;
    SV* cipher_name_SV;
  PREINIT:
    BIO* stringBIO;
    char* passphrase = NULL;
    STRLEN passphraseLength = 0;
    char* cipher_name;
    const EVP_CIPHER* enc = NULL;
  CODE:
    if (!_is_private(p_rsa))
    {
        croak("Public keys cannot export private key strings");
    }
    if (SvPOK(cipher_name_SV) && !SvPOK(passphrase_SV)) {
        croak("Passphrase is required for cipher");
    }
    if (SvPOK(passphrase_SV)) {
        passphrase = SvPV(passphrase_SV, passphraseLength);
        if (SvPOK(cipher_name_SV)) {
            cipher_name = SvPV_nolen(cipher_name_SV);
        }
        else {
            cipher_name = "des3";
        }
        enc = EVP_get_cipherbyname(cipher_name);
        if (enc == NULL) {
            croak("Unsupported cipher: %s", cipher_name);
        }
    }

    CHECK_OPEN_SSL(stringBIO = BIO_new(BIO_s_mem()));
    CHECK_OPEN_SSL_BIO(PEM_write_bio_PrivateKey_traditional(
        stringBIO, p_rsa->rsa, enc, (unsigned char* ) passphrase, passphraseLength, NULL, NULL), stringBIO);
    RETVAL = extractBioString(stringBIO);

  OUTPUT:
    RETVAL

SV*
get_private_key_pkcs8_string(p_rsa, passphrase_SV=&PL_sv_undef, cipher_name_SV=&PL_sv_undef)
    rsaData* p_rsa;
    SV* passphrase_SV;
    SV* cipher_name_SV;
  PREINIT:
    BIO* stringBIO;
    char* passphrase = NULL;
    STRLEN passphraseLength = 0;
    char* cipher_name;
    const EVP_CIPHER* enc = NULL;
  CODE:
    if (SvPOK(cipher_name_SV) && !SvPOK(passphrase_SV)) {
        croak("Passphrase is required for cipher");
    }
    if (SvPOK(passphrase_SV)) {
        passphrase = SvPV(passphrase_SV, passphraseLength);
        if (SvPOK(cipher_name_SV)) {
            cipher_name = SvPV_nolen(cipher_name_SV);
        }
        else {
            cipher_name = "des3";
        }
        enc = EVP_get_cipherbyname(cipher_name);
        if (enc == NULL) {
            croak("Unsupported cipher: %s", cipher_name);
        }
    }

    CHECK_OPEN_SSL(stringBIO = BIO_new(BIO_s_mem()));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    CHECK_OPEN_SSL_BIO(PEM_write_bio_PrivateKey(
        stringBIO, p_rsa->rsa, enc, (unsigned char*) passphrase, passphraseLength, NULL, NULL), stringBIO);
#else
    CHECK_OPEN_SSL_BIO(_write_pkcs8_pem(
        stringBIO, p_rsa->rsa, enc, (unsigned char*) passphrase, passphraseLength), stringBIO);
#endif
    RETVAL = extractBioString(stringBIO);

  OUTPUT:
    RETVAL

SV*
get_public_key_string(p_rsa)
    rsaData* p_rsa;
  PREINIT:
    BIO* stringBIO;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    OSSL_ENCODER_CTX *ctx = NULL;
    int error = 0;
#endif
  CODE:
    CHECK_OPEN_SSL(stringBIO = BIO_new(BIO_s_mem()));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    ctx = OSSL_ENCODER_CTX_new_for_pkey(p_rsa->rsa, OSSL_KEYMGMT_SELECT_PUBLIC_KEY,
            "PEM", "PKCS1", NULL);
    THROW(ctx != NULL && OSSL_ENCODER_CTX_get_num_encoders(ctx));

    THROW(OSSL_ENCODER_to_bio(ctx, stringBIO) == 1);

    OSSL_ENCODER_CTX_free(ctx);
    ctx = NULL;

    goto pubkey_done;
    err:
        if (ctx) { OSSL_ENCODER_CTX_free(ctx); ctx = NULL; }
        BIO_free(stringBIO);
        CHECK_OPEN_SSL(0);
    pubkey_done:
#else
    CHECK_OPEN_SSL_BIO(PEM_write_bio_RSAPublicKey(stringBIO, p_rsa->rsa), stringBIO);
#endif
    RETVAL = extractBioString(stringBIO);

  OUTPUT:
    RETVAL

SV*
get_public_key_x509_string(p_rsa)
    rsaData* p_rsa;
  PREINIT:
    BIO* stringBIO;
  CODE:
    CHECK_OPEN_SSL(stringBIO = BIO_new(BIO_s_mem()));
    CHECK_OPEN_SSL_BIO(PEM_write_bio_PUBKEY(stringBIO, p_rsa->rsa), stringBIO);
    RETVAL = extractBioString(stringBIO);

  OUTPUT:
    RETVAL

SV*
generate_key(proto, bitsSV, exponent = 65537)
    SV* proto;
    SV* bitsSV;
    unsigned long exponent;
  PREINIT:
    EVP_PKEY* rsa = NULL;
    BIGNUM *e = NULL;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY_CTX *ctx = NULL;
    int error = 0;
#endif
  CODE:
    if (SvIV(bitsSV) < 512)
        croak("RSA key size must be at least 512 bits (got %"IVdf")", SvIV(bitsSV));
    if (exponent < 3 || (exponent % 2) == 0)
        croak("RSA exponent must be odd and >= 3 (got %lu)", exponent);
    e = BN_new();
    BN_set_word(e, exponent);
#if OPENSSL_VERSION_NUMBER < 0x00908000L
    rsa = RSA_generate_key(SvIV(bitsSV), exponent, NULL, NULL);
    BN_free(e);
    CHECK_OPEN_SSL(rsa != NULL);
#endif
#if OPENSSL_VERSION_NUMBER >= 0x00908000L && OPENSSL_VERSION_NUMBER < 0x30000000L
    rsa = RSA_new();
    if (!RSA_generate_key_ex(rsa, SvIV(bitsSV), e, NULL))
    {
        BN_free(e);
        RSA_free(rsa);
        croak("Unable to generate a key");
    }
    BN_free(e);
#endif
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    ctx = EVP_PKEY_CTX_new_from_name(NULL, "RSA", NULL);
    THROW(ctx);
    THROW(EVP_PKEY_keygen_init(ctx) == 1);
    THROW(EVP_PKEY_CTX_set_rsa_keygen_bits(ctx, SvIV(bitsSV)) > 0);
    THROW(EVP_PKEY_CTX_set1_rsa_keygen_pubexp(ctx, e) > 0);
    THROW(EVP_PKEY_generate(ctx, &rsa) == 1);
err:
    BN_free(e);
    e = NULL;
    EVP_PKEY_CTX_free(ctx);
    ctx = NULL;
    if (error)
        croakSsl(__FILE__, __LINE__);
#endif
    CHECK_OPEN_SSL(rsa);
    RETVAL = make_rsa_obj(proto, rsa);
  OUTPUT:
    RETVAL


SV*
_new_key_from_parameters(proto, n, e, d, p, q)
    SV* proto;
    BIGNUM* n;
    BIGNUM* e;
    BIGNUM* d;
    BIGNUM* p;
    BIGNUM* q;
  PREINIT:
    EVP_PKEY* rsa = NULL;
    BN_CTX* ctx = NULL;
    BIGNUM* p_minus_1 = NULL;
    BIGNUM* q_minus_1 = NULL;
    BIGNUM* dmp1 = NULL;
    BIGNUM* dmq1 = NULL;
    BIGNUM* iqmp = NULL;
    int error = 0;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    OSSL_PARAM *params = NULL;
    EVP_PKEY_CTX *pctx = NULL;
    OSSL_PARAM_BLD *params_build = NULL;
#endif
  CODE:
{
    if (!(n && e))
    {
        croak("At least a modulus and public key must be provided");
    }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    pctx = EVP_PKEY_CTX_new_from_name(NULL, "RSA", NULL);
    THROW(pctx != NULL);
    THROW(EVP_PKEY_fromdata_init(pctx) > 0);
    params_build = OSSL_PARAM_BLD_new();
    THROW(params_build);
#else
    CHECK_OPEN_SSL(rsa = RSA_new());
#endif
#if OLD_CRUFTY_SSL_VERSION
    rsa->n = n;
    rsa->e = e;
#endif
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_N, n));
    THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_E, e));
#endif
    if (p || q)
    {
        error = 0;
        THROW(ctx = BN_CTX_new());
        if (!p)
        {
            THROW(p = BN_new());
            THROW(BN_div(p, NULL, n, q, ctx));
        }
        else if (!q)
        {
            THROW(q = BN_new());
            THROW(BN_div(q, NULL, n, p, ctx));
        }
#if OLD_CRUFTY_SSL_VERSION
        rsa->p = p;
        rsa->q = q;
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#else
        THROW(RSA_set0_factors(rsa, p, q));
#endif
#endif
        THROW(p_minus_1 = BN_new());
        THROW(BN_sub(p_minus_1, p, BN_value_one()));
        THROW(q_minus_1 = BN_new());
        THROW(BN_sub(q_minus_1, q, BN_value_one()));
        if (!d)
        {
            THROW(d = BN_new());
            THROW(BN_mul(d, p_minus_1, q_minus_1, ctx));
            THROW(BN_mod_inverse(d, e, d, ctx));
        }
#if OLD_CRUFTY_SSL_VERSION
        rsa->d = d;
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_D, d));
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_FACTOR1, p));
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_FACTOR2, q));
#else
        THROW(RSA_set0_key(rsa, n, e, d));
#endif
#endif
        THROW(dmp1 = BN_new());
        THROW(BN_mod(dmp1, d, p_minus_1, ctx));
        THROW(dmq1 = BN_new());
        THROW(BN_mod(dmq1, d, q_minus_1, ctx));
        THROW(iqmp = BN_new());
        THROW(BN_mod_inverse(iqmp, q, p, ctx));
#if OLD_CRUFTY_SSL_VERSION
        rsa->dmp1 = dmp1;
        rsa->dmq1 = dmq1;
        rsa->iqmp = iqmp;
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_EXPONENT1, dmp1));
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_EXPONENT2, dmq1));
        THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_COEFFICIENT1, iqmp));

        params = OSSL_PARAM_BLD_to_param(params_build);
        THROW(params != NULL);

        int status = EVP_PKEY_fromdata(pctx, &rsa, EVP_PKEY_KEYPAIR, params);
        THROW( status > 0 && rsa != NULL );
        EVP_PKEY_CTX* test_ctx = EVP_PKEY_CTX_new_from_pkey(NULL, rsa, NULL);
        int check_ok = (test_ctx != NULL && EVP_PKEY_check(test_ctx) == 1);
        EVP_PKEY_CTX_free(test_ctx);
        THROW(check_ok);
#else
        THROW(RSA_set0_crt_params(rsa, dmp1, dmq1, iqmp));
#endif
#endif
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        /* OSSL_PARAM_BLD_push_BN() copies the value, so the original
           BIGNUMs (from pointer_copy or BN_new) must be freed here.
           On pre-3.x, RSA_set0_key/RSA_set0_factors took ownership. */
        BN_clear_free(n);
        BN_clear_free(e);
        BN_clear_free(d);
        BN_clear_free(p);
        BN_clear_free(q);
        BN_clear_free(dmp1);
        BN_clear_free(dmq1);
        BN_clear_free(iqmp);
        n = e = d = p = q = NULL;
#endif
        dmp1 = dmq1 = iqmp = NULL;
        BN_CTX_free(ctx);
        ctx = NULL;
        BN_clear_free(p_minus_1);
        p_minus_1 = NULL;
        BN_clear_free(q_minus_1);
        q_minus_1 = NULL;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        OSSL_PARAM_BLD_free(params_build);
        params_build = NULL;
        OSSL_PARAM_free(params);
        params = NULL;
        EVP_PKEY_CTX_free(pctx);
        pctx = NULL;
#else
        THROW(RSA_check_key(rsa) == 1);
#endif
    }
    else
    {
#if OLD_CRUFTY_SSL_VERSION
        rsa->d = d;
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        if(d != NULL)
            THROW(OSSL_PARAM_BLD_push_BN(params_build, OSSL_PKEY_PARAM_RSA_D, d));
        params = OSSL_PARAM_BLD_to_param(params_build);
        THROW(params != NULL);

        int status = EVP_PKEY_fromdata(pctx, &rsa, EVP_PKEY_KEYPAIR, params);
        OSSL_PARAM_BLD_free(params_build);
        OSSL_PARAM_free(params);
        params_build = NULL;
        params = NULL;
        THROW( status > 0 && rsa != NULL );
        EVP_PKEY_CTX_free(pctx);
        pctx = NULL;
        BN_clear_free(n);
        BN_clear_free(e);
        BN_clear_free(d);
        n = e = d = NULL;
#else
        CHECK_OPEN_SSL(RSA_set0_key(rsa, n, e, d));
#endif
#endif
    }

    THROW(RETVAL = make_rsa_obj(proto, rsa));
    goto end;

    err:
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        /* On 3.x, push_BN copies, so originals are always ours to free.
           On pre-3.x, RSA_set0_key/set0_factors may have taken ownership,
           so these are intentionally skipped (risk of double-free). */
        BN_clear_free(n);
        BN_clear_free(e);
        BN_clear_free(d);
        BN_clear_free(p);
        BN_clear_free(q);
#endif
        if (p_minus_1) BN_clear_free(p_minus_1);
        if (q_minus_1) BN_clear_free(q_minus_1);
        if (dmp1) BN_clear_free(dmp1);
        if (dmq1) BN_clear_free(dmq1);
        if (iqmp) BN_clear_free(iqmp);
        if (ctx) BN_CTX_free(ctx);
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        if (pctx) { EVP_PKEY_CTX_free(pctx); pctx = NULL; }
        if (params_build) { OSSL_PARAM_BLD_free(params_build); params_build = NULL; }
        if (params) { OSSL_PARAM_free(params); params = NULL; }
#endif
        if (error)
        {
            EVP_PKEY_free(rsa);
            CHECK_OPEN_SSL(0);
        }
    }
    end:

  OUTPUT:
    RETVAL

void
_get_key_parameters(p_rsa)
    rsaData* p_rsa;
PREINIT:
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    BIGNUM* n = NULL;
    BIGNUM* e = NULL;
    BIGNUM* d = NULL;
    BIGNUM* p = NULL;
    BIGNUM* q = NULL;
    BIGNUM* dmp1 = NULL;
    BIGNUM* dmq1 = NULL;
    BIGNUM* iqmp = NULL;
#else
    const BIGNUM* n;
    const BIGNUM* e;
    const BIGNUM* d;
    const BIGNUM* p;
    const BIGNUM* q;
    const BIGNUM* dmp1;
    const BIGNUM* dmq1;
    const BIGNUM* iqmp;
#endif
PPCODE:
{
    EVP_PKEY* rsa;
    rsa = p_rsa->rsa;
#if OLD_CRUFTY_SSL_VERSION
    n = rsa->n;
    e = rsa->e;
    d = rsa->d;
    p = rsa->p;
    q = rsa->q;
    dmp1 = rsa->dmp1;
    dmq1 = rsa->dmq1;
    iqmp = rsa->iqmp;
#else
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    /* n and e are mandatory for every RSA key — croak on failure. */
    if (!EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_N, &n))
        croakSsl(__FILE__, __LINE__);
    if (!EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_E, &e)) {
        BN_free(n);
        croakSsl(__FILE__, __LINE__);
    }
    /* Private components are absent for public keys — EVP_PKEY_get_bn_param()
       returns 0 and may push errors onto the queue, but the pointer stays NULL
       so cor_bn2sv() will return undef.  This matches the pre-3.x behaviour
       where RSA_get0_key/factors/crt_params simply set NULL for missing fields. */
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_D, &d);
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_FACTOR1, &p);
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_FACTOR2, &q);
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_EXPONENT1, &dmp1);
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_EXPONENT2, &dmq1);
    EVP_PKEY_get_bn_param(rsa, OSSL_PKEY_PARAM_RSA_COEFFICIENT1, &iqmp);
    /* Failed calls (e.g. private params on a public key) push errors
       onto the OpenSSL error queue.  Drain them so they don't leak
       into the next croakSsl() call from an unrelated operation. */
    ERR_clear_error();
#else
    RSA_get0_key(rsa, &n, &e, &d);
    RSA_get0_factors(rsa, &p, &q);
    RSA_get0_crt_params(rsa, &dmp1, &dmq1, &iqmp);
#endif
#endif
    XPUSHs(cor_bn2sv(n));
    XPUSHs(cor_bn2sv(e));
    XPUSHs(cor_bn2sv(d));
    XPUSHs(cor_bn2sv(p));
    XPUSHs(cor_bn2sv(q));
    XPUSHs(cor_bn2sv(dmp1));
    XPUSHs(cor_bn2sv(dmq1));
    XPUSHs(cor_bn2sv(iqmp));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    /* EVP_PKEY_get_bn_param() allocates new BIGNUMs (unlike the pre-3.x
       getters which return internal pointers).  cor_bn2sv() duplicates
       them via BN_dup(), so we must free the originals here. */
    BN_free(n);
    BN_free(e);
    BN_clear_free(d);
    BN_clear_free(p);
    BN_clear_free(q);
    BN_clear_free(dmp1);
    BN_clear_free(dmq1);
    BN_clear_free(iqmp);
#endif
}

SV*
encrypt(p_rsa, p_plaintext)
    rsaData* p_rsa;
    SV* p_plaintext;
  CODE:
    check_max_message_length(p_rsa, sv_len(p_plaintext));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    RETVAL = rsa_crypt(p_rsa, p_plaintext, EVP_PKEY_encrypt, EVP_PKEY_encrypt_init, 1 /* is_encrypt */);
#else
    RETVAL = rsa_crypt(p_rsa, p_plaintext, RSA_public_encrypt, 1 /* is_encrypt */);
#endif
  OUTPUT:
    RETVAL

SV*
decrypt(p_rsa, p_ciphertext)
    rsaData* p_rsa;
    SV* p_ciphertext;
  CODE:
    if (!_is_private(p_rsa))
    {
        croak("Public keys cannot decrypt");
    }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    RETVAL = rsa_crypt(p_rsa, p_ciphertext, EVP_PKEY_decrypt, EVP_PKEY_decrypt_init, 1 /* is_encrypt */);
#else
    RETVAL = rsa_crypt(p_rsa, p_ciphertext, RSA_private_decrypt, 1 /* is_encrypt */);
#endif
  OUTPUT:
    RETVAL

SV*
private_encrypt(p_rsa, p_plaintext)
    rsaData* p_rsa;
    SV* p_plaintext;
  CODE:
    if (!_is_private(p_rsa))
    {
        croak("Public keys cannot private_encrypt");
    }
    if (p_rsa->padding == RSA_PKCS1_OAEP_PADDING) {
        croak("OAEP padding is not supported for private_encrypt/public_decrypt. "
              "Call use_no_padding() or use_pkcs1_padding() first.");
    }
    if (p_rsa->padding == RSA_PKCS1_PSS_PADDING) {
        croak("PSS padding with private_encrypt/public_decrypt is not supported. "
              "Use sign()/verify() for PSS signatures.");
    }
    check_max_message_length(p_rsa, sv_len(p_plaintext));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    RETVAL = rsa_crypt(p_rsa, p_plaintext, EVP_PKEY_sign, EVP_PKEY_sign_init, 0 /* is_encrypt */);
#else
    RETVAL = rsa_crypt(p_rsa, p_plaintext, RSA_private_encrypt, 0 /* is_encrypt */);
#endif
  OUTPUT:
    RETVAL

SV*
public_decrypt(p_rsa, p_ciphertext)
    rsaData* p_rsa;
    SV* p_ciphertext;
  CODE:
    if (p_rsa->padding == RSA_PKCS1_OAEP_PADDING) {
        croak("OAEP padding is not supported for private_encrypt/public_decrypt. "
              "Call use_no_padding() or use_pkcs1_padding() first.");
    }
    if (p_rsa->padding == RSA_PKCS1_PSS_PADDING) {
        croak("PSS padding with private_encrypt/public_decrypt is not supported. "
              "Use sign()/verify() for PSS signatures.");
    }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    RETVAL = rsa_crypt(p_rsa, p_ciphertext, EVP_PKEY_verify_recover, EVP_PKEY_verify_recover_init, 0 /* is_encrypt */);
#else
    RETVAL = rsa_crypt(p_rsa, p_ciphertext, RSA_public_decrypt, 0 /* is_encrypt */);
#endif
  OUTPUT:
    RETVAL

int
size(p_rsa)
    rsaData* p_rsa;
  CODE:
    RETVAL = EVP_PKEY_get_size(p_rsa->rsa);
  OUTPUT:
    RETVAL

int
check_key(p_rsa)
    rsaData* p_rsa;
  CODE:
    if (!_is_private(p_rsa))
    {
        croak("Public keys cannot be checked");
    }
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_from_pkey(NULL, p_rsa->rsa, NULL);
    CHECK_OPEN_SSL(pctx);
    RETVAL = (EVP_PKEY_private_check(pctx) == 1);
    EVP_PKEY_CTX_free(pctx);
#else
    RETVAL = (RSA_check_key(p_rsa->rsa) == 1);
#endif
  OUTPUT:
    RETVAL

 # Seed the PRNG with user-provided bytes; returns true if the
 # seeding was sufficient.

int
_random_seed(random_bytes_SV)
    SV* random_bytes_SV;
  PREINIT:
    STRLEN random_bytes_length;
    char* random_bytes;
  CODE:
    random_bytes = SvPV(random_bytes_SV, random_bytes_length);
    RAND_seed(random_bytes, random_bytes_length);
    RETVAL = RAND_status();
  OUTPUT:
    RETVAL

 # Returns true if the PRNG has enough seed data

int
_random_status()
  CODE:
    RETVAL = RAND_status();
  OUTPUT:
    RETVAL

void
use_md5_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode = NID_md5;

void
use_sha1_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_sha1;

#ifdef SHA512_DIGEST_LENGTH

void
use_sha224_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_sha224;

void
use_sha256_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_sha256;

void
use_sha384_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_sha384;

void
use_sha512_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_sha512;

#endif

void
use_ripemd160_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_ripemd160;

#ifdef WHIRLPOOL_DIGEST_LENGTH

void
use_whirlpool_hash(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->hashMode =  NID_whirlpool;

#endif

void
use_no_padding(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->padding = RSA_NO_PADDING;

void
use_pkcs1_padding(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->padding = RSA_PKCS1_PADDING;

void
use_pkcs1_oaep_padding(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->padding = RSA_PKCS1_OAEP_PADDING;

void
use_pkcs1_pss_padding(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->padding = RSA_PKCS1_PSS_PADDING;

#if OPENSSL_VERSION_NUMBER < 0x30000000L

void
use_sslv23_padding(p_rsa)
    rsaData* p_rsa;
  CODE:
    p_rsa->padding = RSA_SSLV23_PADDING;

#endif

# Sign text. Returns the signature.

SV*
sign(p_rsa, text_SV)
    rsaData* p_rsa;
    SV* text_SV;
  PREINIT:
    UNSIGNED_CHAR *signature = NULL;
    unsigned char* digest;
    SIZE_T_UNSIGNED_INT signature_length;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_PKEY_CTX *ctx = NULL;
    EVP_MD *md = NULL;
    int error = 0;
#endif
  CODE:
{
    if (!_is_private(p_rsa))
    {
        croak("Public keys cannot sign messages");
    }

    unsigned char digest_buf[EVP_MAX_MD_SIZE];
    CHECK_OPEN_SSL(digest = get_message_digest(text_SV, p_rsa->hashMode, digest_buf));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    ctx = EVP_PKEY_CTX_new(p_rsa->rsa, NULL /* no engine */);
    THROW(ctx);
    THROW(EVP_PKEY_sign_init(ctx));
    THROW(setup_pss_sign_ctx(ctx, p_rsa->padding, p_rsa->hashMode, &md));
    THROW(EVP_PKEY_sign(ctx, NULL, &signature_length, digest, get_digest_length(p_rsa->hashMode)) == 1);

    Newx(signature, signature_length, UNSIGNED_CHAR);
    THROW(signature);

    THROW(EVP_PKEY_sign(ctx, signature, &signature_length, digest, get_digest_length(p_rsa->hashMode)) == 1);

    EVP_MD_free(md);
    EVP_PKEY_CTX_free(ctx);

    goto sign_done;
    err:
        Safefree(signature);
        if (md) EVP_MD_free(md);
        if (ctx) EVP_PKEY_CTX_free(ctx);
        CHECK_OPEN_SSL(0);
    sign_done:
#else
    CHECK_NEW(signature, EVP_PKEY_get_size(p_rsa->rsa), UNSIGNED_CHAR);
    if (!RSA_sign(p_rsa->hashMode,
                  digest,
                  get_digest_length(p_rsa->hashMode),
                  (unsigned char*) signature,
                  &signature_length,
                  p_rsa->rsa))
    {
        Safefree(signature);
        croakSsl(__FILE__, __LINE__);
    }
#endif
    RETVAL = newSVpvn((const char* )signature, signature_length);
    Safefree(signature);
}
  OUTPUT:
    RETVAL

# Verify signature. Returns true if correct, false otherwise.

void
verify(p_rsa, text_SV, sig_SV)
    rsaData* p_rsa;
    SV* text_SV;
    SV* sig_SV;
PREINIT:
    int verify_result;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    int error = 0;
    EVP_PKEY_CTX *ctx = NULL;
    EVP_MD *md = NULL;
#endif
PPCODE:
{
    unsigned char* sig;
    unsigned char* digest;
    STRLEN sig_length;

    sig = (unsigned char*) SvPV(sig_SV, sig_length);
    if (EVP_PKEY_get_size(p_rsa->rsa) < sig_length)
    {
        croak("Signature longer than key");
    }

    unsigned char digest_buf[EVP_MAX_MD_SIZE];
    CHECK_OPEN_SSL(digest = get_message_digest(text_SV, p_rsa->hashMode, digest_buf));
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    ctx = EVP_PKEY_CTX_new(p_rsa->rsa, NULL /* no engine */);
    THROW(ctx);
    THROW(EVP_PKEY_verify_init(ctx) == 1);
    THROW(setup_pss_sign_ctx(ctx, p_rsa->padding, p_rsa->hashMode, &md));

    verify_result = EVP_PKEY_verify(ctx, sig, sig_length, digest, get_digest_length(p_rsa->hashMode));
    EVP_MD_free(md);
    EVP_PKEY_CTX_free(ctx);

    goto verify_switch;
    err:
        if (md) EVP_MD_free(md);
        if (ctx) EVP_PKEY_CTX_free(ctx);
        CHECK_OPEN_SSL(0);
    verify_switch: ;
#else
    verify_result = RSA_verify(p_rsa->hashMode,
                      digest,
                      get_digest_length(p_rsa->hashMode),
                      sig,
                      sig_length,
                      p_rsa->rsa);
#endif
    switch(verify_result)
    {
        case 0:
            ERR_clear_error();
            XSRETURN_NO;
            break;
        case 1:
            XSRETURN_YES;
            break;
        default:
            CHECK_OPEN_SSL(0);
            break;
    }
}

int
is_private(p_rsa)
    rsaData* p_rsa;
  CODE:
    RETVAL = _is_private(p_rsa);
  OUTPUT:
    RETVAL
