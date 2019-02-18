#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* libsodium */
#include "sodium.h"

#ifdef XopENTRY_set
static XOP my_encrypt, my_decrypt;
#endif


/* Code stolen from Sereal: */
/* perl 5.25 op_sibling renaming related compat macros. Should probably
 * live in ppport or so. */

#ifndef OpSIBLING
# define OpSIBLING(op) ((op)->op_sibling)
#endif

#ifndef OpHAS_SIBLING
# define OpHAS_SIBLING(op) ((op)->op_sibling != NULL)
#endif

/* This is completely opting out, sigh */
#ifndef op_parent
# undef OpLASTSIB_set
# undef OpMORESIB_set
# define op_parent(op) NULL
# define OpMORESIB_set(op, sib) ((op)->op_sibling = (sib))
# define OpLASTSIB_set(op, parent) ((op)->op_sibling = NULL)
#endif

#ifdef XopENTRY_set
/* -MO=Concise & friends will show useful info for our custom ops */
# define XopENTRY_multiset(a,b,c) STMT_START {   \
    XopENTRY_set(&(a), xop_name, b);            \
    XopENTRY_set(&(a), xop_desc, b);            \
    XopENTRY_set(&(a), xop_class, OA_UNOP);     \
    Perl_custom_op_register(aTHX_ (c), &(a));   \
} STMT_END
#else
# define XopENTRY_multiset(a,b,c)
#endif

SV*
THX_sodium_encrypt(pTHX_ SV* msg, SV* nonce, SV* key)
#define sodium_encrypt(a,b,c) THX_sodium_encrypt(aTHX_ a,b,c)
{
    SV* encrypted_sv;
    STRLEN msg_len, nonce_len, key_len, enc_len;
    unsigned char *msg_buf, *nonce_buf, *key_buf;
    nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
    if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
        croak("Invalid nonce");
    }

    key_buf = (unsigned char *)SvPV(key, key_len);
    if ( key_len != crypto_secretbox_KEYBYTES ) {
        croak("Invalid key");
    }

    msg_buf = (unsigned char *)SvPV(msg, msg_len);

    enc_len = crypto_secretbox_MACBYTES + msg_len;

    encrypted_sv = newSV(enc_len);
    SvUPGRADE(encrypted_sv, SVt_PV);
    SvPOK_on(encrypted_sv);
    SvCUR_set(encrypted_sv, enc_len);

    crypto_secretbox_easy(
        (unsigned char *)SvPVX(encrypted_sv),
        msg_buf,
        msg_len,
        nonce_buf,
        key_buf
    );

    return encrypted_sv;
}

SV*
THX_sodium_decrypt(pTHX_ SV* ciphertext, SV* nonce, SV* key)
#define sodium_decrypt(a,b,c)   THX_sodium_decrypt(aTHX_ a,b,c)
{
    SV* decrypted_sv;
    STRLEN dec_len, nonce_len, key_len, msg_len;
    int decrypt_result = 0;
    unsigned char *nonce_buf, *key_buf, *msg_buf;

    nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
    if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
        croak("Invalid nonce");
    }

    key_buf = (unsigned char *)SvPV(key, key_len);
    if ( key_len != crypto_secretbox_KEYBYTES ) {
        croak("Invalid key");
    }

    msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);
    if ( msg_len < crypto_secretbox_MACBYTES ) {
        croak("Invalid ciphertext");
    }
    dec_len = msg_len - crypto_secretbox_MACBYTES;

    decrypted_sv = newSV(dec_len);
    SvUPGRADE(decrypted_sv, SVt_PV);
    SvPOK_on(decrypted_sv);

     decrypt_result = crypto_secretbox_open_easy(
        (unsigned char *)SvPVX(decrypted_sv),
        msg_buf,
        msg_len,
        nonce_buf,
        key_buf
    );

    if ( decrypt_result != 0 ) {
        sv_free(decrypted_sv);
        croak("Message forged");
    }

    SvCUR_set(decrypted_sv, dec_len);
    return decrypted_sv;
}

#define ARITY ((SP - PL_stack_base) - TOPMARK)

OP*
S_pp_encrypt(pTHX)
{
    dSP;
    SSize_t arity = ARITY;
    SV *encrypted, *msg, *nonce, *key;

    if ( arity != 3 )
        croak("encrypt() must be passed a message, a nonce, and a key");

    key   = POPs;
    nonce = POPs;
    msg   = POPs;
    POPMARK;

    encrypted = sodium_encrypt(msg, nonce, key);

    mXPUSHs(encrypted);
    PUTBACK;

    return NORMAL;
}

OP*
S_pp_decrypt(pTHX)
{
    dSP;
    SSize_t arity = ARITY;
    SV *decrypted, *cipher, *nonce, *key;

    if ( arity != 3 )
        croak("decrypt() must be passed a message, a nonce, and a key");

    key    = POPs;
    nonce  = POPs;
    cipher = POPs;
    POPMARK; // Remove the mark added earlier

    decrypted = sodium_decrypt(cipher, nonce, key);
    mXPUSHs(decrypted);
    PUTBACK;
    return NORMAL;
}

STATIC OP*
S_ck_remove_entersub_crypt(pTHX_ OP *entersubop, GV *namegv, SV *encrypt_sv)
{
    OP *pushop, *firstargop, *cvop, *lastargop, *argop, *newop;
    bool encrypt = SvTRUE(encrypt_sv);

    ck_entersub_args_proto_or_list(entersubop, namegv, &PL_sv_undef);

    /* Code stolen from Sereal -- deattach the arguments from the entersub */
    pushop = cUNOPx(entersubop)->op_first;
    if ( ! OpHAS_SIBLING(pushop) )
        pushop = cUNOPx(pushop)->op_first;
    firstargop = OpSIBLING(pushop);

    for (cvop = firstargop; OpHAS_SIBLING(cvop); cvop = OpSIBLING(cvop)) ;

    lastargop = pushop;
    for (
        lastargop = pushop, argop = firstargop;
        argop != cvop;
        lastargop = argop, argop = OpSIBLING(argop)
    ) {
    }

    /* After finding the start/end of the arguments, deattach & free */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(lastargop, op_parent(lastargop));
    op_free(entersubop);

    /* the custom OP that will handle the rest */
    pushop = newOP(OP_PUSHMARK, 0);
    OpMORESIB_set(pushop, firstargop);
    newop = newUNOP(OP_NULL, 0, pushop);
    newop->op_type    = OP_CUSTOM;
    newop->op_ppaddr  = encrypt ? S_pp_encrypt : S_pp_decrypt;
    newop->op_private = 0;

    return newop;
}


MODULE = Crypt::Sodium::Nitrate        PACKAGE = Crypt::Sodium::Nitrate

PROTOTYPES: DISABLE

void
encrypt(SV* msg, SV* nonce, SV* key)
INIT:
    SV* encrypted_sv;
PPCODE:
{
    if ( GIMME_V == G_VOID ) {
        XSRETURN_EMPTY;
    }
    encrypted_sv = sodium_encrypt(msg, nonce, key);
    mXPUSHs( encrypted_sv );
    XSRETURN(1);
}

void
decrypt(SV* ciphertext, SV* nonce, SV* key)
INIT:
    SV* decrypted_sv;
PPCODE:
{
    if ( GIMME_V == G_VOID )
        XSRETURN_EMPTY;
    decrypted_sv = sodium_decrypt(ciphertext, nonce, key);
    mXPUSHs( decrypted_sv );
    XSRETURN(1);
}

BOOT:
{
    /* let's create a couple of constants for perl to use */
    HV *stash = gv_stashpvs("Crypt::Sodium::Nitrate", GV_ADD);

    newCONSTSUB(stash, "NONCEBYTES", newSViv(crypto_secretbox_NONCEBYTES));
    newCONSTSUB(stash, "KEYBYTES",   newSViv(crypto_secretbox_KEYBYTES));
    newCONSTSUB(stash, "MACBYTES",   newSViv(crypto_secretbox_MACBYTES));

    /* Set up custom OPs for encrypt & decrypt */
    CV * const encrypt_cv = get_cvn_flags("Crypt::Sodium::Nitrate::encrypt", 31, 1);
    CV * const decrypt_cv = get_cvn_flags("Crypt::Sodium::Nitrate::decrypt", 31, 1);

    cv_set_call_checker(encrypt_cv, S_ck_remove_entersub_crypt, &PL_sv_yes);
    cv_set_call_checker(decrypt_cv, S_ck_remove_entersub_crypt, &PL_sv_no);

    XopENTRY_multiset(my_encrypt, "encrypt", S_pp_encrypt);
    XopENTRY_multiset(my_decrypt, "decrypt", S_pp_decrypt);
}



