#include <assert.h>
#include <string.h>
#if defined(HAVE_SYS_TIME_H)
#  include <sys/time.h>
#endif
#include <openssl/rand.h>
#include <openssl/crypto.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/x509.h>
#include <openssl/cms.h>
#if defined(HAVE_TIME_H)
#  include <time.h>
#endif
#include <sys/types.h>
#include <sys/stat.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

enum {
    CRYPT_SMIME_FORMAT_ASN1,
    CRYPT_SMIME_FORMAT_PEM,
    CRYPT_SMIME_FORMAT_SMIME
};

struct crypt_smime {
    EVP_PKEY *priv_key;
    X509*     priv_cert;
    bool      priv_key_is_tainted;
    bool      priv_cert_is_tainted;
    const EVP_CIPHER* cipher;

    /* 暗号化, 添付用 */
    STACK_OF(X509)* pubkeys_stack;

    /* 検証用 */
    X509_STORE* pubkeys_store;

    bool pubkeys_are_tainted;
};
typedef struct crypt_smime * Crypt_SMIME;

#define OPENSSL_CROAK(description)                              \
    croak("%s: %s",                                             \
          description,                                          \
          ERR_error_string(ERR_get_error(), NULL))

static inline bool is_string(SV const* sv) {
    /* It's not sufficient to call SvPOK() to see if an SV contains a
     * character string. It returns false for all SV if taint checking
     * is enabled.
     */
    return SvPOK(sv) || SvPOKp(sv);
}

static int B64_write_CMS(BIO *bio, CMS_ContentInfo *p7)
{
        BIO *b64;
        if(!(b64 = BIO_new(BIO_f_base64()))) {
                return 0;
        }
        bio = BIO_push(b64, bio);
        i2d_CMS_bio(bio, p7);
        (void)BIO_flush(bio);
        bio = BIO_pop(bio);
        BIO_free(b64);
        return 1;
}


static EVP_PKEY* load_privkey(Crypt_SMIME this, char* pem, char* password) {
    BIO *buf;
    EVP_PKEY *key;

    buf = BIO_new_mem_buf(pem, -1);
    if (buf == NULL) {
        return NULL;
    }

    key = PEM_read_bio_PrivateKey(
        buf, NULL, (pem_password_cb*)NULL, password);
    BIO_free(buf);

    return key;
}

/* ----------------------------------------------------------------------------
 * X509* x509 = load_cert(crt);
 * extract X509 information from cert data.
 * not from file, from just data.
 * ------------------------------------------------------------------------- */
static X509* load_cert(char* crt) {
    BIO* buf;
    X509 *x;

    buf = BIO_new_mem_buf(crt, -1);
    if (buf == NULL) {
        return NULL;
    }

    x = PEM_read_bio_X509_AUX(buf, NULL, NULL, NULL);
    BIO_free(buf);

    return x;
}

static SV* sign(Crypt_SMIME this, char* plaintext) {
    BIO* inbuf;
    BIO* outbuf;
    CMS_ContentInfo* cms;
    int flags = CMS_DETACHED | CMS_STREAM | CMS_PARTIAL;
    BUF_MEM* bufmem;
    SV* result;
    int err;
    int i;

    inbuf = BIO_new_mem_buf(plaintext, -1);
    if (inbuf == NULL) {
        return NULL;
    }

    /* Generate a detached signature */
    cms = CMS_sign(this->priv_cert, this->priv_key, NULL, inbuf, flags);
    if (cms == NULL) {
        BIO_free(inbuf);
        return NULL;
    }

    outbuf = BIO_new(BIO_s_mem());
    if (outbuf == NULL) {
        CMS_ContentInfo_free(cms);
        BIO_free(inbuf);
        return NULL;
    }

    for (i = 0; i < sk_X509_num(this->pubkeys_stack); i++) {
        X509* x509 = sk_X509_value(this->pubkeys_stack, i);
        assert(x509 != NULL);
        if (CMS_add0_cert(cms, x509) != 1) {
            if (ERR_GET_REASON(ERR_peek_last_error()) != CMS_R_CERTIFICATE_ALREADY_PRESENT) {
                CMS_ContentInfo_free(cms);
                BIO_free(inbuf);
                return NULL;
            }
        }
    }

    err = SMIME_write_CMS(outbuf, cms, inbuf, flags);
    CMS_ContentInfo_free(cms);
    BIO_free(inbuf);
    if (err != 1) {
        return NULL;
    }

    BIO_get_mem_ptr(outbuf, &bufmem);
    result = newSVpv(bufmem->data, bufmem->length);
    BIO_free(outbuf);

    if (this->priv_key_is_tainted || this->priv_cert_is_tainted || this->pubkeys_are_tainted) {
        SvTAINTED_on(result);
    }

    return result;
}

static SV* signonly(Crypt_SMIME this, char* plaintext) {
    BIO* inbuf;
    BIO* outbuf;
    CMS_ContentInfo* cms;
    int flags = CMS_DETACHED;
    BUF_MEM* bufmem;
    SV* result;
    int err;
    int i;

    inbuf = BIO_new_mem_buf(plaintext, -1);
    if (inbuf == NULL) {
        return NULL;
    }

    /* Generate a detached signature */
    cms = CMS_sign(this->priv_cert, this->priv_key, NULL, inbuf, flags);
    BIO_free(inbuf);
    if (cms == NULL) {
        return NULL;
    }

    outbuf = BIO_new(BIO_s_mem());
    if (outbuf == NULL) {
        CMS_ContentInfo_free(cms);
        return NULL;
    }

    for (i = 0; i < sk_X509_num(this->pubkeys_stack); i++) {
        X509* x509 = sk_X509_value(this->pubkeys_stack, i);
        assert(x509 != NULL);
        if (CMS_add0_cert(cms, x509) != 1) {
            if (ERR_GET_REASON(ERR_peek_last_error()) != CMS_R_CERTIFICATE_ALREADY_PRESENT) {
                CMS_ContentInfo_free(cms);
                BIO_free(inbuf);
                return NULL;
            }
        }
    }

    err = B64_write_CMS(outbuf, cms);
    CMS_ContentInfo_free(cms);
    if (err != 1) {
        return NULL;
    }

    BIO_get_mem_ptr(outbuf, &bufmem);
    result = newSVpv(bufmem->data, bufmem->length);
    BIO_free(outbuf);

    if (this->priv_key_is_tainted || this->priv_cert_is_tainted || this->pubkeys_are_tainted) {
        SvTAINTED_on(result);
    }

    return result;
}

static SV* check(Crypt_SMIME this, char* signed_mime, int flags) {
    BIO* inbuf;
    BIO* detached = NULL;
    BIO* outbuf;
    CMS_ContentInfo* cms;
    int err;
    BUF_MEM* bufmem;
    SV* result;

    inbuf = BIO_new_mem_buf(signed_mime, -1);
    if (inbuf == NULL) {
        return NULL;
    }

    cms = SMIME_read_CMS(inbuf, &detached);
    BIO_free(inbuf);
    if (cms == NULL) {
        return NULL;
    }

    outbuf = BIO_new(BIO_s_mem());
    if (outbuf == NULL) {
        CMS_ContentInfo_free(cms);
        return NULL;
    }

    err = CMS_verify(cms, this->pubkeys_stack, this->pubkeys_store, detached, outbuf, flags);
    CMS_ContentInfo_free(cms);

    if (detached != NULL) {
        BIO_free(detached);
    }

    if (err != 1) {
        BIO_free(outbuf);
        return NULL;
    }

    BIO_get_mem_ptr(outbuf, &bufmem);
    result = newSVpv(bufmem->data, bufmem->length);
    BIO_free(outbuf);

    if (this->pubkeys_are_tainted) {
        SvTAINTED_on(result);
    }

    return result;
}

/* CMS */
static SV* _encrypt(Crypt_SMIME this, char* plaintext) {
    BIO* inbuf;
    BIO* outbuf;
    CMS_ContentInfo* enc;
    int flags = 0;
    int err;
    BUF_MEM* bufmem;
    SV* result;

    inbuf = BIO_new_mem_buf(plaintext, -1);
    if (inbuf == NULL) {
        return NULL;
    }

    enc = CMS_encrypt(this->pubkeys_stack, inbuf, this->cipher, flags);
    BIO_free(inbuf);

    if (enc == NULL) {
        return NULL;
    }

    outbuf = BIO_new(BIO_s_mem());
    if (outbuf == NULL) {
        CMS_ContentInfo_free(enc);
        return NULL;
    }

    err = SMIME_write_CMS(outbuf, enc, NULL, flags);
    CMS_ContentInfo_free(enc);

    if (err != 1) {
        BIO_free(outbuf);
        return NULL;
    }

    BIO_get_mem_ptr(outbuf, &bufmem);
    result = newSVpv(bufmem->data, bufmem->length);
    BIO_free(outbuf);

    if (this->pubkeys_are_tainted) {
        SvTAINTED_on(result);
    }

    return result;
}

static SV* _decrypt(Crypt_SMIME this, char* encrypted_mime) {
    BIO* inbuf;
    BIO* outbuf;
    CMS_ContentInfo * enc;
    int flags = 0;
    int err;
    BUF_MEM* bufmem;
    SV* result;

    inbuf = BIO_new_mem_buf(encrypted_mime, -1);
    if (inbuf == NULL) {
        return NULL;
    }

    enc = SMIME_read_CMS(inbuf, NULL);
    BIO_free(inbuf);

    if (enc == NULL) {
        return NULL;
    }

    outbuf = BIO_new(BIO_s_mem());
    if (outbuf == NULL) {
        CMS_ContentInfo_free(enc);
        return NULL;
    }

    err = CMS_decrypt(enc, this->priv_key, this->priv_cert, NULL, outbuf, flags);
    CMS_ContentInfo_free(enc);

    if (err != 1) {
        BIO_free(outbuf);
        return NULL;
    }

    BIO_get_mem_ptr(outbuf, &bufmem);
    result = newSVpv(bufmem->data, bufmem->length);
    BIO_free(outbuf);

    if (this->priv_key_is_tainted || this->priv_cert_is_tainted) {
        SvTAINTED_on(result);
    }

    return result;
}

static void seed_rng() {
    /* OpenSSL automatically seeds the random number generator from
     * /dev/urandom (on UNIX) or CryptGenRandom (on Windows). But if
     * we are on an exotic platform, we must somehow seed the RNG.
     */
    RAND_poll();
    while (RAND_status() == 0) {

#if defined(HAVE_GETTIMEOFDAY)
        struct timeval tv;

        gettimeofday(&tv, NULL);
        RAND_seed(&tv, sizeof(struct timeval));

#elif defined(HAVE_TIME)
        time_t t;

        t = time(NULL);
        RAND_seed(&t, sizeof(time_t));

#else
        croak("Crypt::SMIME#import: don't know how to seed the CSPRNG on this platform");
#endif
    }
}

#include "const-c.inc"

MODULE = Crypt::SMIME  PACKAGE = Crypt::SMIME

INCLUDE: const-xs.inc

BOOT:
    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
    seed_rng();

Crypt_SMIME
new(char* /*CLASS*/)
    CODE:
        RETVAL = safemalloc(sizeof(struct crypt_smime));
        if (RETVAL == NULL) {
            croak("Crypt::SMIME#new: unable to allocate Crypt_SMIME");
        }

        memset(RETVAL, '\0', sizeof(struct crypt_smime));

    OUTPUT:
        RETVAL

void
DESTROY(Crypt_SMIME this)
    CODE:
        if (this->priv_cert) {
            X509_free(this->priv_cert);
        }
        if (this->priv_key) {
            EVP_PKEY_free(this->priv_key);
        }
        if (this->pubkeys_stack) {
            /* X.509 certificates are shared between this and
             * pubkeys_store. We only deallocate the stack here.
             */
            sk_X509_free(this->pubkeys_stack);
        }
        if (this->pubkeys_store) {
            X509_STORE_free(this->pubkeys_store);
        }
        safefree(this);

SV*
setPrivateKey(Crypt_SMIME this, char* pem, char* crt, char* password = "")
    PROTOTYPE: $$$;$
    CODE:
        /* Remove old keys if any. */
        if (this->priv_cert) {
            X509_free(this->priv_cert);
            this->priv_cert = NULL;
        }
        if (this->priv_key) {
            EVP_PKEY_free(this->priv_key);
            this->priv_key = NULL;
        }

        this->priv_key = load_privkey(this, pem, password);
        if (this->priv_key == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#setPrivateKey: failed to load the private key");
        }

        this->priv_cert = load_cert(crt);
        if (this->priv_cert == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#setPrivateKey: failed to load the private cert");
        }

        this->priv_key_is_tainted  = SvTAINTED(ST(1));
        this->priv_cert_is_tainted = SvTAINTED(ST(2));

        SvREFCNT_inc(ST(0));
        RETVAL = ST(0);

    OUTPUT:
        RETVAL

SV*
setPrivateKeyPkcs12(Crypt_SMIME this, SV* pkcs12, char* password = "")
    PROTOTYPE: $$$;$
    PREINIT:
        BIO *bio;
        PKCS12 *p12;
        int success = 0;
    CODE:
        if (this->priv_cert) {
            X509_free(this->priv_cert);
            this->priv_cert = NULL;
        }
        if (this->priv_key) {
            EVP_PKEY_free(this->priv_key);
            this->priv_key = NULL;
        }

        if (SvOK(pkcs12)) {
          if ((bio = BIO_new_mem_buf(SvPV_nolen(pkcs12), SvCUR(pkcs12))) != NULL) {
            if ((p12 = d2i_PKCS12_bio(bio, NULL)) != NULL) {
              success = PKCS12_parse(p12, password, &this->priv_key, &this->priv_cert, NULL);
            }
            BIO_free(bio);
          }
        }

        if (!success || this->priv_key == NULL || this->priv_cert == NULL) {
          OPENSSL_CROAK("Crypt::SMIME#setPrivateKeyPkcs12: failed");
        }
        this->priv_key_is_tainted  = SvTAINTED(ST(1));
        this->priv_cert_is_tainted = SvTAINTED(ST(1));

        SvREFCNT_inc(ST(0));
        RETVAL = ST(0);
    OUTPUT:
        RETVAL

SV*
setPublicKey(Crypt_SMIME this, SV* crt)
    CODE:
        /*
            crt: ARRAY Refなら、その各要素が公開鍵
                 SCALARなら、それが公開鍵
        */

        /* 古い鍵があったら消す */
        if (this->pubkeys_stack) {
            sk_X509_free(this->pubkeys_stack);
            this->pubkeys_stack = NULL;
        }
        if (this->pubkeys_store) {
            X509_STORE_free(this->pubkeys_store);
            this->pubkeys_store = NULL;
        }

        this->pubkeys_store = X509_STORE_new();
        if (this->pubkeys_store == NULL) {
            croak("Crypt::SMIME#setPublicKey: failed to allocate X509_STORE");
        }

        /* 何故STACK_OF(X509)とX509_STOREの二つを使う必要があるのか。 */
        this->pubkeys_stack = sk_X509_new_null();
        if (this->pubkeys_stack == NULL) {
            croak("Crypt::SMIME#setPublicKey: failed to allocate STACK_OF(X509)");
        }

        this->pubkeys_are_tainted = FALSE;

        if (SvROK(crt) && SvTYPE(SvRV(crt)) == SVt_PVAV) {
            AV* array = (AV*)SvRV(crt);
            I32 i, len = av_len(array);

            for (i = 0; i <= len; i++) {
                SV** val = av_fetch(array, i, 1);
                if (val == NULL) {
                    continue; /* 多分起こらないが… */
                }

                if (is_string(*val)) {
                    SV* this_sv = ST(0);

                    dSP;
                    ENTER;

                    PUSHMARK(SP);
                    XPUSHs(this_sv);
                    XPUSHs(*val);
                    PUTBACK;

                    call_method("_addPublicKey", G_DISCARD);

                    LEAVE;
                }
                else {
                    croak("Crypt::SMIME#setPublicKey: ARG[1] is an array but it contains some non-string values");
                }
            }
        }
        else if (is_string(crt)) {
            SV* this_sv = ST(0);

            dSP;
            ENTER;

            PUSHMARK(SP);
            XPUSHs(this_sv);
            XPUSHs(crt);
            PUTBACK;

            call_method("_addPublicKey", G_DISCARD);

            LEAVE;
        }
        else {
            croak("Crypt::SMIME#setPublicKey: ARG[1] is not a string nor an ARRAY Ref");
        }

        SvREFCNT_inc(ST(0));
        RETVAL = ST(0);

    OUTPUT:
        RETVAL

void
_addPublicKey(Crypt_SMIME this, char* crt)
    PREINIT:
        BIO* buf;

    CODE:
        /* Be aware; 'crt' may contain two or more certificates.
        */
        buf = BIO_new_mem_buf(crt, -1);
        if (buf == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#setPublicKey: failed to allocate a buffer");
        }

        while (1) {
            X509* pub_cert;

            pub_cert = PEM_read_bio_X509_AUX(buf, NULL, NULL, NULL);
            if (pub_cert == NULL) {
                if (ERR_GET_REASON(ERR_get_error()) == PEM_R_NO_START_LINE) {
                    break;
                }
                else {
                    BIO_free(buf);
                    OPENSSL_CROAK("Crypt::SMIME#setPublicKey: failed to load the public cert");
                }
            }

            /* X509_STORE_add_cert() has an undocumented behavior that
             * increments a refcount in X509 unlike sk_X509_push(). So
             * we must not call X509_dup() here.
             */
            if (X509_STORE_add_cert(this->pubkeys_store, pub_cert) == 0) {
                X509_free(pub_cert);
                BIO_free(buf);
                OPENSSL_CROAK("Crypt::SMIME#setPublicKey: failed to store the public cert");
            }

            if (sk_X509_push(this->pubkeys_stack, pub_cert) == 0) {
                X509_free(pub_cert);
                BIO_free(buf);
                OPENSSL_CROAK("Crypt::SMIME#setPublicKey: failed to push the public cert onto the stack");
            }
        }
        BIO_free(buf);

        if (SvTAINTED(ST(1))) {
            this->pubkeys_are_tainted = TRUE;
        }

SV*
setPublicKeyStore(Crypt_SMIME this, ...)
    INIT:
        X509_STORE* store;
        X509* pub_cert;
        X509_LOOKUP *lookup_file, *lookup_path;
        int i, has_file = 0, has_path = 0;
        char* pathname;
        struct stat bufstat;
    CODE:
        /* 古い証明書ストアがあったら消す */
        if (this->pubkeys_store) {
            X509_STORE_free(this->pubkeys_store);
            this->pubkeys_store = NULL;
        }

        store = X509_STORE_new();
        if (store == NULL) {
            croak("Crypt::SMIME#setPublicKeyStore: failed to allocate X509_STORE");
        }

        /* setPublicKey()で設定した証明書があれば追加する */
        for (i = 0; i < sk_X509_num(this->pubkeys_stack); i++) {
            pub_cert = sk_X509_value(this->pubkeys_stack, i);
            if (pub_cert == NULL || X509_STORE_add_cert(store, pub_cert) == 0) {
                X509_STORE_free(store);
                croak("Crypt::SMIME#setPublicKeyStore: failed to store the public cert");
            }
        }
        if (sk_X509_num(this->pubkeys_stack) == 0) {
            this->pubkeys_are_tainted = FALSE;
        }

        /* 引数があれば証明書ストアとして追加する */
        lookup_file = X509_STORE_add_lookup(store, X509_LOOKUP_file());
        if (lookup_file == NULL) {
            X509_STORE_free(store);
            croak("Crypt::SMIME#setPublicKeyStore: failed to allocate X509_LOOKUP");
        }
        lookup_path = X509_STORE_add_lookup(store, X509_LOOKUP_hash_dir());
        if (lookup_path == NULL) {
            X509_STORE_free(store);
            croak("Crypt::SMIME#setPublicKeyStore: failed to allocate X509_LOOKUP");
        }
        for (i = 1; i < items; i++) {
            if (ST(i) == NULL) {
                continue; /* 多分起こらないが… */
            }
            if (!is_string(ST(i))) {
                X509_STORE_free(store);
                croak("Crypt::SMIME#setPublicKeyStore: ARG[%d] is non-string value", i);
            }

            pathname = (char *)SvPV_nolen(ST(i));
            if (stat(pathname, &bufstat) != 0) {
                X509_STORE_free(store);
                croak("Crypt::SMIME#setPublicKeyStore: cannot stat %s",
                    pathname);
            } else if (bufstat.st_mode & S_IFDIR) {
                if (!X509_LOOKUP_add_dir(lookup_path, pathname,
                        X509_FILETYPE_PEM)) {
                    X509_STORE_free(store);
                    croak("Crypt::SMIME#setPublicKeyStore: failed to add ARG[%d] as store", i);
                }
                has_path = 1;
            } else {
                if (!X509_LOOKUP_load_file(lookup_file, pathname,
                        X509_FILETYPE_PEM)) {
                    X509_STORE_free(store);
                    croak("Crypt::SMIME#setPublicKeyStore: failed to add ARG[%d] as store", i);
                }
                has_file = 1;
            }

            if (SvTAINTED(ST(i))) {
                this->pubkeys_are_tainted = TRUE;
            }
        }

        /* 引数がなければ初期値の場所のストアを (存在すれば) 追加する */
        if (!has_file) {
            X509_LOOKUP_load_file(lookup_file, NULL, X509_FILETYPE_DEFAULT);
        }
        if (!has_path) {
            X509_LOOKUP_add_dir(lookup_path, NULL, X509_FILETYPE_DEFAULT);
        }

        ERR_clear_error();
        this->pubkeys_store = store;

        SvREFCNT_inc(ST(0));
        RETVAL = ST(0);

    OUTPUT:
        RETVAL

SV*
_sign(Crypt_SMIME this, char* plaintext)
    CODE:
        /* 秘密鍵がまだセットされていなければエラー */
        if (this->priv_key == NULL) {
            croak("Crypt::SMIME#sign: private key has not yet been set. Set one before signing");
        }
        if (this->priv_cert == NULL) {
            croak("Crypt::SMIME#sign: private cert has not yet been set. Set one before signing");
        }

        RETVAL = sign(this, plaintext);
        if (RETVAL == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#sign: failed to sign the message");
        }

    OUTPUT:
        RETVAL

SV*
_signonly(Crypt_SMIME this, char* plaintext)
    CODE:
        /* 秘密鍵がまだセットされていなければエラー */
        if (this->priv_key == NULL) {
            croak("Crypt::SMIME#signonly: private key has not yet been set. Set one before signing");
        }
        if (this->priv_cert == NULL) {
            croak("Crypt::SMIME#signonly: private cert has not yet been set. Set one before signing");
        }

        RETVAL = signonly(this, plaintext);
        if (RETVAL == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#signonly: failed to sign the message");
        }

    OUTPUT:
        RETVAL

SV*
_encrypt(Crypt_SMIME this, char* plaintext)
    CODE:
        /* 公開鍵がまだセットされていなければエラー */
        if (this->pubkeys_stack == NULL) {
            croak("Crypt::SMIME#encrypt: public cert has not yet been set. Set one before encrypting");
        }

        /* Initialize the cipher suite to use for encryption */
        if (this->cipher == NULL) {
            /* The man page of CMS_encrypt(3) recommends DES-EDE3-CBC
             * i.e. EVP_des_ede3_cbc() for interoperability but it can
             * no longer be considered to be a safe algorithm.  We use
             * AES-128-CBC instead.
             */
            this->cipher = EVP_aes_128_cbc();
        }

        RETVAL = _encrypt(this, plaintext);
        if (RETVAL == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#encrypt: failed to encrypt the message");
        }

    OUTPUT:
        RETVAL

SV*
check(Crypt_SMIME this, char* signed_mime, int flags = 0)
    PROTOTYPE: $$;$
    CODE:
        if (this->pubkeys_store == NULL) {
            if (!(flags & CMS_NO_SIGNER_CERT_VERIFY)) {
                croak("Crypt::SMIME#check: public cert has not yet been set. Set one before checking");
            }
        }

        RETVAL = check(this, signed_mime, flags);
        if (RETVAL == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#check: failed to check the signature");
        }

    OUTPUT:
        RETVAL

SV*
decrypt(Crypt_SMIME this, char* encrypted_mime)
    CODE:
        /* 秘密鍵がまだセットされていなければエラー */
        if (this->priv_key == NULL) {
            croak("Crypt::SMIME#decrypt: private key has not yet been set. Set one before decrypting");
        }
        if (this->priv_cert == NULL) {
            croak("Crypt::SMIME#decrypt: private cert has not yet been set. Set one before decrypting");
        }

        RETVAL = _decrypt(this, encrypted_mime);
        if (RETVAL == NULL) {
            OPENSSL_CROAK("Crypt::SMIME#decrypt: failed to decrypt the message");
        }

    OUTPUT:
        RETVAL

SV*
x509_subject_hash(char* cert)
  CODE:
    {
      X509* x509 = load_cert(cert);
      if( x509!=NULL )
      {
        RETVAL = newSVuv(X509_subject_name_hash(x509));
        X509_free(x509);
      }else
      {
        RETVAL = &PL_sv_undef;
      }
    }
  OUTPUT:
    RETVAL

SV*
x509_issuer_hash(char* cert)
  CODE:
    {
      X509* x509 = load_cert(cert);
      if( x509!=NULL )
      {
        RETVAL = newSVuv(X509_issuer_name_hash(x509));
        X509_free(x509);
      }else
      {
        RETVAL = &PL_sv_undef;
      }
    }
  OUTPUT:
    RETVAL

SV*
extractCertificates(SV* indata, int informat=CRYPT_SMIME_FORMAT_SMIME)
    PROTOTYPE: $;$
    INIT:
	BIO* bio;
    CMS_ContentInfo* cms = NULL;
	STACK_OF(X509)* certs = NULL;
	STACK_OF(X509_CRL)* crls = NULL;
	int i;
	AV* result;
	BUF_MEM* bufmem;

	if (!SvOK(indata)) {
	    XSRETURN_UNDEF;
	}
	bio = BIO_new_mem_buf(SvPV_nolen(indata), SvCUR(indata));
    if (bio == NULL) {
	    OPENSSL_CROAK(
	        "Crypt::SMIME#extractCertificates: failed to allocate a buffer"
	    );
	}
	switch (informat) {
	case CRYPT_SMIME_FORMAT_SMIME:
        cms = SMIME_read_CMS(bio, NULL);
	    break;
	case CRYPT_SMIME_FORMAT_PEM:
        cms = PEM_read_bio_CMS(bio, NULL, NULL, NULL);
	    break;
	case CRYPT_SMIME_FORMAT_ASN1:
        cms = d2i_CMS_bio(bio, NULL);
	    break;
	default:
	    BIO_free(bio);
	    croak("Crypt::SMIME#extractCertificates: unknown format %d",
	        informat);
	}
	BIO_free(bio);
	if (cms == NULL) {
	    XSRETURN_UNDEF;
	}

    certs = CMS_get1_certs(cms);
    crls  = CMS_get1_crls(cms);

	result = (AV*)sv_2mortal((SV*)newAV());
    CODE:
	if (certs != NULL) {
	    for (i = 0; i < sk_X509_num(certs); i++) {
	        bio = BIO_new(BIO_s_mem());
	        if (bio == NULL) {
                sk_X509_CRL_pop_free(crls, X509_CRL_free);
                sk_X509_pop_free(certs, X509_free);
                CMS_ContentInfo_free(cms);
	            croak("Crypt::SMIME#extractCertificates: failed to allocate a buffer");
	        }
	        PEM_write_bio_X509(bio, sk_X509_value(certs, i));
	        BIO_get_mem_ptr(bio, &bufmem);
	        av_push(result, newSVpv(bufmem->data, bufmem->length));
	        BIO_free(bio);
	    }
	}
	if (crls != NULL) {
	    for (i = 0; i < sk_X509_CRL_num(crls); i++) {
	        bio = BIO_new(BIO_s_mem());
            if (bio == NULL) {
                sk_X509_CRL_pop_free(crls, X509_CRL_free);
                sk_X509_pop_free(certs, X509_free);
                CMS_ContentInfo_free(cms);
	            croak("Crypt::SMIME#extractCertificates: failed to allocate a buffer");
	        }
	        PEM_write_bio_X509_CRL(bio, sk_X509_CRL_value(crls, i));
	        BIO_get_mem_ptr(bio, &bufmem);
	        av_push(result, newSVpv(bufmem->data, bufmem->length));
	        BIO_free(bio);
	    }
	}

    sk_X509_CRL_pop_free(crls, X509_CRL_free);
    sk_X509_pop_free(certs, X509_free);
    CMS_ContentInfo_free(cms);
	RETVAL = newRV((SV*) result);
    OUTPUT:
	RETVAL

SV*
getSigners(SV* indata, int informat=CRYPT_SMIME_FORMAT_SMIME)
    PROTOTYPE: $;$
    INIT:
	BIO* bio;
    BIO* detached = NULL;
	CMS_ContentInfo* cms = NULL;
    int flags;
    int err;
	STACK_OF(X509)* signers;
	int i;
	AV* result;
	BUF_MEM* bufmem;

	if (!SvOK(indata)) {
	    XSRETURN_UNDEF;
	}
	bio = BIO_new_mem_buf(SvPV_nolen(indata), SvCUR(indata));
    if (bio == NULL) {
	    OPENSSL_CROAK(
	        "Crypt::SMIME#getSigners: failed to allocate a buffer"
	    );
	}
	switch (informat) {
	case CRYPT_SMIME_FORMAT_SMIME:
        cms = SMIME_read_CMS(bio, &detached);
	    break;
	case CRYPT_SMIME_FORMAT_PEM:
        cms = PEM_read_bio_CMS(bio, NULL, NULL, NULL);
	    break;
	case CRYPT_SMIME_FORMAT_ASN1:
        cms = d2i_CMS_bio(bio, NULL);
	    break;
	default:
	    BIO_free(bio);
	    croak("Crypt::SMIME#getSigners: unknown format %d",
	        informat);
	}
	BIO_free(bio);
	if (cms == NULL) {
	    XSRETURN_UNDEF;
	}

    /* We are only interested in the signers. No verifications need to
     * be done.
     */
    flags = CMS_NO_SIGNER_CERT_VERIFY
          | CMS_NO_ATTR_VERIFY
          | CMS_NO_CONTENT_VERIFY;
    err = CMS_verify(cms, NULL, NULL, detached, NULL, flags);
    if (err != 1) {
        OPENSSL_CROAK("Crypt::SMIME#getSigners: failed to extract signers");
    }

    if (detached != NULL) {
        BIO_free(detached);
    }

    signers = CMS_get0_signers(cms);
	if (signers == NULL) {
        CMS_ContentInfo_free(cms);
	    XSRETURN_UNDEF;
	}

	result = (AV*)sv_2mortal((SV*)newAV());
    CODE:
	if (0 < sk_X509_num(signers)) {
	    for (i = 0; i < sk_X509_num(signers); i++) {
	        bio = BIO_new(BIO_s_mem());
	        if (bio == NULL) {
                sk_X509_free(signers);
                CMS_ContentInfo_free(cms);
	            croak("Crypt::SMIME#getSigners: failed to allocate a buffer");
	        }
	        PEM_write_bio_X509(bio, sk_X509_value(signers, i));
	        BIO_get_mem_ptr(bio, &bufmem);
	        av_push(result, newSVpv(bufmem->data, bufmem->length));
	        BIO_free(bio);
	    }
	}

	sk_X509_free(signers);
    CMS_ContentInfo_free(cms);
	RETVAL = newRV((SV*) result);
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
