#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#include "ppport.h"

#include <openssl/blowfish.h>
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
#include <openssl/evp.h>
#include <openssl/provider.h>
#endif

/*==========================================================*/
/*                                                          */
/* hexdump.xs:                                              */
/* https://gist.github.com/mcnewton/14322391d50240ec9ebf    */
/*                                                          */
/* Matthew Newton @mcnewton                                 */
/* See hexdump.xs for LICENSE information                   */
/*==========================================================*/

#ifdef INCLUDE_HEXDUMP
#include "hexdump.xs"
#endif

/*==================================================*/
/*                                                  */
/* Macro to swap from little endian to big endian   */
/*                                                  */
/*==================================================*/
# undef n2l
# define n2l(c,l)        (l =((unsigned long)(*((c)++)))<<24L, \
                         l|=((unsigned long)(*((c)++)))<<16L, \
                         l|=((unsigned long)(*((c)++)))<< 8L, \
                         l|=((unsigned long)(*((c)++))))

/*==================================================*/
/*                                                  */
/* Macro to swap from big endian to little endian   */
/*                                                  */
/*==================================================*/
# undef l2n
# define l2n(l,c)        (*((c)++)=(unsigned char)(((l)>>24L)&0xff), \
                         *((c)++)=(unsigned char)(((l)>>16L)&0xff), \
                         *((c)++)=(unsigned char)(((l)>> 8L)&0xff), \
                         *((c)++)=(unsigned char)(((l)     )&0xff))

/*============================================*/
/*                                            */
/* ensure_hv(SV *sv, const char *identifier)  */
/*                                            */
/* Helper function Taken from p5-Git-Raw      */
/* to ensure that a value is a hash.  It is   */
/* used to verify that the 'options' passed   */
/* in the constructor is valid                */
/*                                            */
/*============================================*/
STATIC HV *ensure_hv(pTHX_ SV *sv, const char *identifier) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
    croak("Invalid type for '%s', expected a hash", identifier);

    return (HV *) SvRV(sv);
}

/*======================================================================*/
/*                                                                      */
/* big_endian(const unsigned char *in, unsigned char *out)              */
/*                                                                      */
/* Swap the endianness of the block of data 'in'.  This is only         */
/* required for compatability with the original version of              */
/* Crypt::OpenSSL::Blowfish.  Which calls BF_encrypt and BF_decrypt     */
/* without switching to big endian first.  This function is called if   */
/* Crypt::OpenSSL::Blowfish is created without any options (other than  */
/* the key).                                                            */
/*                                                                      */
/*======================================================================*/
void big_endian(const unsigned char *in, unsigned char *out)
{
    BF_LONG l;
    BF_LONG d[2];

    n2l(in, l);
    d[0] = l;
    n2l(in, l);
    d[1] = l;
    Copy(d, out, 2, BF_LONG);
    l = d[0] = d[1] = 0;
}

/*======================================================================*/
/*                                                                      */
/* return_big_endian(const unsigned char *in)                           */
/*                                                                      */
/* Swap the endianness of the block of data 'in'.  This is only         */
/* required for compatability with the original version of              */
/* Crypt::OpenSSL::Blowfish.  Which calls BF_encrypt and BF_decrypt     */
/* without switching to big endian first.  This function is called if   */
/* Crypt::OpenSSL::Blowfish is created without any options (other than  */
/* the key) or if the Modules get_big_endian is called.                 */
/*                                                                      */
/*======================================================================*/
unsigned char * return_big_endian(pTHX_ const unsigned char *in)
{
    unsigned char * out;
    Newx(out, BF_BLOCK, unsigned char); //Bunsigned char, unsigned char);
    big_endian(in, out);
    return out;
}

/*======================================================================*/
/*                                                                      */
/* little_endian(const BF_LONG *d, unsigned char *out)                  */
/*                                                                      */
/* Swap the endianness of the block of data 'in'.  This is only         */
/* required for compatability with the original version of              */
/* Crypt::OpenSSL::Blowfish.  Which calls BF_encrypt and BF_decrypt     */
/* without switching to big endian first.  This function is called if   */
/* Crypt::OpenSSL::Blowfish is created without any options (other than  */
/* the key).                                                            */
/*                                                                      */
/*======================================================================*/
void little_endian(const BF_LONG *in, unsigned char *out)
{
    BF_LONG l;

    l = in[0];
    l2n(l, out);
    l = in[1];
    l2n(l, out);
}

/*======================================================================*/
/*                                                                      */
/* return_little_endian(const unsigned char *in)                        */
/*                                                                      */
/* Swap the endianness of the block of data 'in'.  This is only         */
/* required for compatability with the original version of              */
/* Crypt::OpenSSL::Blowfish.  Which calls BF_encrypt and BF_decrypt     */
/* without switching to big endian first.  This function is called if   */
/* Crypt::OpenSSL::Blowfish is created without any options (other than  */
/* the key) or if the Modules get_big_endian is called.                 */
/*                                                                      */
/*======================================================================*/
unsigned char * return_little_endian(pTHX_ unsigned char *in)
{
    unsigned char *out;
    BF_LONG d[2];

    Newx(out, BF_BLOCK, unsigned char);
    Copy(in, d, BF_BLOCK, unsigned char);

    little_endian(d, out);

    return out;
}

void print_pointers(pTHX_ char * name, void * pointer) {
#ifdef PRINT_POINTERS
    printf("Crypt pointer - %s: %p\n", name, pointer);
    printf("Crypt INT of pointer - %s: %lu\n", name, (unsigned long) PTR2IV(pointer));
#endif
}

static const MGVTBL ks_magic = { NULL, NULL, NULL, NULL, NULL };

MODULE = Crypt::OpenSSL::Blowfish PACKAGE = Crypt::OpenSSL::Blowfish PREFIX = blowfish_
PROTOTYPES: DISABLE

#=============================================
#
# blowfish_new(class, key_sv, ...)
#
# Instantiate the BF_KEY and add it to the
# object
#
#=============================================
SV *
blowfish_new(class, key_sv, ...)
    const char * class
    SV *  key_sv
PREINIT:
        SV *ks = newSV(0);
        IV mod = 1;
        STRLEN keysize;
        unsigned char * key;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_CIPHER_CTX *ctx = NULL;
        OSSL_PROVIDER *legacy;
        OSSL_PROVIDER *deflt;
#else
        BF_KEY *bf_ks;
#endif
        HV * options = NULL;
        HV * attributes;
        SV *modern = newSV(0);
CODE:
    {
        PERL_UNUSED_ARG(options);
        options = newHV();
        if (items > 2)
            options = ensure_hv(aTHX_ ST(2), "options");

        if (!SvPOK (key_sv))
            croak("Key must be a scalar");

        key     = (unsigned char *) SvPVbyte(key_sv, keysize);

        /* FIXME: openssl seems to use 16-byte keys only */
        if (keysize != 8 && keysize !=16 && keysize != 24 && keysize != 32)
            croak ("The key must be 64, 128, 192 or 256 bits long");
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        legacy = OSSL_PROVIDER_load(NULL, "legacy");
        if (legacy == NULL) {
            croak("Failed to load Legacy provider\n");
        }

        deflt = OSSL_PROVIDER_load(NULL, "default");
        if (deflt == NULL) {
            OSSL_PROVIDER_unload(legacy);
            croak("Failed to load Default provider\n");
        }

        /* Create the EVP_CIPHER_CTX object */
        if(!(ctx = EVP_CIPHER_CTX_new()))
            croak ("Failed to create the EVP_CIPHER_CTX object\n");

        if(0 == EVP_CipherInit_ex2(ctx, EVP_bf_ecb(), NULL, NULL, 0, NULL))
            croak ("EVP_CipherInit_ex2 failed\n");

        EVP_CIPHER_CTX_set_key_length(ctx, keysize);
        /*hexdump(stdout, (unsigned char *) ctx, sizeof(ctx), 16, 8); */
        OPENSSL_assert(EVP_CIPHER_CTX_key_length(ctx) == keysize);
        OPENSSL_assert(EVP_CIPHER_CTX_iv_length(ctx) == 0); /*FIXME */

        if (0 == EVP_CipherInit_ex2(ctx, NULL, key, NULL, 0, NULL))
            croak ("EVP_CipherInit_ex2 failed\n");

        /*hexdump(stdout, (unsigned char *) ctx, sizeof(ctx), 16, 8); */
        print_pointers(aTHX_ "ctx", ctx);
#else
        /* Allocate memory to hold the Blowfish BF_KEY object */
        Newx(bf_ks, 1, BF_KEY);

        BF_set_key(bf_ks, keysize, key);

        print_pointers(aTHX_ "bf_ks", bf_ks);
#endif
        attributes = newHV();
        SV *const self = newRV_inc( (SV *)attributes );
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        sv_magicext(ks, NULL, PERL_MAGIC_ext,
            &ks_magic, (const char *) ctx, 0);
#else
        sv_magicext(ks, NULL, PERL_MAGIC_ext,
            &ks_magic, (const char *) bf_ks, 0);
#endif
        if((hv_store(attributes, "ks", 2, ks, 0)) == NULL)
            croak("unable to store the BF_KEY");

        if (items > 2) {
            sv_magicext(modern, NULL, PERL_MAGIC_ext,
                &ks_magic, (const char *) mod, 0);

            if((hv_store(attributes, "modern", 6, modern, 0)) == NULL)
                croak("unable to store the modern");
        }

        print_pointers(aTHX_ "modern", modern);
        RETVAL = sv_bless( self, gv_stashpv( class, 0 ) );
    }
OUTPUT:
    RETVAL

#=============================================
#
# blowfish_crypt(self, data_sv, encrypt)
#
# Crypt/Decrypt the data depending on the encrypt
#
#=============================================
SV * blowfish_crypt(self, data_sv, encrypt)
    HV * self
    SV * data_sv
    int encrypt
    PREINIT:
        STRLEN data_len;
        unsigned char * in;
        MAGIC* mg;
        SV **svp;
        int *modern = 0;
        unsigned char *out;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        EVP_CIPHER_CTX *ctx;
        int out_len = 0;
        int ciphertext_len = 0;
        int plaintext_len = 0;
#else
        BF_KEY *bf_ks = NULL;
#endif
    CODE:
    {
        if (hv_exists(self, "modern", strlen("modern"))) {
            svp = hv_fetch(self, "modern", strlen("modern"), 0);
            if (!SvMAGICAL(*svp) || (mg = mg_findext(*svp, PERL_MAGIC_ext, &ks_magic)) == NULL)
                croak("Accessing the modern value from magic failed");
            modern = (int *) mg->mg_ptr;
        }

        in = (unsigned char *) SvPVbyte(data_sv, data_len);

        /*hexdump(stdout, data, data_len, 16, 8); */

        Newx(out, BF_BLOCK, unsigned char);
        if (! modern) {
            Copy(in, out, BF_BLOCK, unsigned char);
            in = return_big_endian(aTHX_ out);
        }

        /*hexdump(stdout, data, data_len, 16, 8); */
        if (!hv_exists(self, "ks", strlen("ks")))
            croak("ks not found in self!\n");

        svp = hv_fetch(self, "ks", strlen("ks"), 0);

        if (!SvMAGICAL(*svp) || (mg = mg_findext(*svp, PERL_MAGIC_ext, &ks_magic)) == NULL)
            croak("Accessing the key from magic failed");
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
        ctx = (EVP_CIPHER_CTX *) mg->mg_ptr;
        print_pointers(aTHX_ "ctx", ctx);

        if ( encrypt == 1) {
            EVP_CIPHER_CTX_set_padding(ctx, 0);
            if (0 == EVP_CipherInit_ex2(ctx, NULL, NULL, NULL, encrypt, NULL))
                croak("EVP_CipherInit_ex2 failed");

            if (0 == EVP_CipherUpdate(ctx, out, &out_len, in, data_len))
                croak ("EVP_CipherUpdate failed in Encrypt\n");

            ciphertext_len += out_len;

            if (0 == EVP_CipherFinal_ex(ctx, out + out_len, &out_len))
                croak ("EVP_CipherFinal_ex failed in Encrypt\n");

            ciphertext_len += out_len;

            /*hexdump(stdout, (unsigned char *) out, sizeof(out), 16, 8); */
        } else {
            print_pointers(aTHX_ "ctx", ctx);
            /*hexdump(stdout, (unsigned char *) data, sizeof(data), 16, 8); */
            EVP_CIPHER_CTX_set_padding(ctx, 0);
            if (0 == EVP_CipherInit_ex2(ctx, NULL, NULL, NULL, encrypt, NULL))
                croak(">>>EVP_CipherInit_ex2 failed");

            /*hexdump(stdout, (unsigned char *) ctx, sizeof(ctx), 16, 8); */
            if (0 == EVP_CipherUpdate(ctx, out, &out_len, in, data_len))
                croak ("EVP_CipherUpdate failed in Decrypt\n");

            /*hexdump(stdout, (unsigned char *) ciphertext, sizeof(plaintext), 16, 8); */
            plaintext_len += out_len;

            if (0 == EVP_CipherFinal_ex(ctx, out + out_len, &out_len))
                croak ("EVP_CipherFinal_ex failed in Decrypt\n");

            plaintext_len += out_len;
            /*hexdump(stdout, (unsigned char *) plaintext, sizeof(plaintext), 16, 8); */
        }
#else
        bf_ks = (BF_KEY *) mg->mg_ptr;
        print_pointers(aTHX_ "bf_ks", bf_ks);

        /*hexdump(stdout, bf_ks, sizeof(BF_KEY), 16, 8); */
        if (data_len != BF_BLOCK) {
            croak("data must be 8 bytes long");
        }

        BF_ecb_encrypt(in, out, bf_ks, encrypt);
#endif
        /*hexdump(stdout, out, sizeof(char)*8, 16, 8); */

        if (! modern) {
            Copy(out, in, BF_BLOCK, unsigned char );
            out = return_little_endian(aTHX_ in);
        }

        /*hexdump(stdout, out, sizeof(char)*8, 16, 8); */

        RETVAL = newSV (data_len);
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, data_len);
        sv_setpvn(RETVAL, (char *) out, data_len);

    }
    OUTPUT:
        RETVAL

#=============================================
#
# blowfish_get_big_endian(self, data_sv)
#
# Convert the data_sv to big-endian
#
#=============================================
SV *
blowfish_get_big_endian(self, data_sv)
    HV * self
    SV * data_sv
    PREINIT:
        unsigned char * in;
        unsigned char * out;
        STRLEN data_len;
    CODE:
        PERL_UNUSED_ARG(self);
        in = (unsigned char *) SvPVbyte(data_sv, data_len);
        out = return_big_endian(aTHX_ in);

        RETVAL = newSV (data_len);
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, data_len);
        sv_setpvn(RETVAL, (char *) out, data_len);
    OUTPUT:
        RETVAL

#=============================================
#
# blowfish_get_little_endian(self, data_sv)
#
# Convert the data_sv to little-endian
#
#=============================================
SV *
blowfish_get_little_endian(self, data_sv)
    HV * self
    SV * data_sv
    PREINIT:
        unsigned char *in;
        unsigned char *out;
        STRLEN data_len;
    CODE:
        PERL_UNUSED_ARG(self);
        in = (unsigned char *) SvPVbyte(data_sv, data_len);
        out = return_little_endian(aTHX_ in);

        RETVAL = newSV (data_len);
        SvPOK_only (RETVAL);
        SvCUR_set (RETVAL, data_len);
        sv_setpvn(RETVAL, (char *) out, data_len);
    OUTPUT:
        RETVAL

#===========================================
#
# blowfish_DESTROY(self)
#
# Free the BF_KEY as the module is unloaded
#
#===========================================
void
blowfish_DESTROY(self)
    HV *self
PREINIT:
    SV **svp;
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    EVP_CIPHER_CTX *ctx = NULL;
#else
    BF_KEY *bf_ks = NULL;
#endif
    MAGIC* mg;
    MAGIC* mg_mod;
    int * modern = NULL;
CODE:
    if (!hv_exists(self, "ks", strlen("ks")))
        croak("ks not found in self!\n");

    svp = hv_fetch(self, "ks", strlen("ks"), 0);

    if (!SvMAGICAL(*svp) || (mg = mg_findext(*svp, PERL_MAGIC_ext, &ks_magic)) == NULL)
        croak("STORE is invalid");
#if OPENSSL_VERSION_NUMBER >= 0x30000000L
    ctx = (EVP_CIPHER_CTX *) mg->mg_ptr;
    print_pointers(aTHX_ "ctx", ctx);

    if (!hv_exists(self, "modern", strlen("modern")))
        croak("modern not found in self!\n");

    svp = hv_fetch(self, "modern", strlen("modern"), 0);

    if (!SvMAGICAL(*svp) || (mg_mod = mg_findext(*svp, PERL_MAGIC_ext, &ks_magic)) == NULL)
    modern = (int *) mg_mod->mg_ptr;
    print_pointers(aTHX_ "modern", modern);
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    Safefree(modern);
#else
    bf_ks = (BF_KEY *) mg->mg_ptr;
    print_pointers(aTHX_ "bf_ks", bf_ks);
    Safefree(bf_ks);
#endif
