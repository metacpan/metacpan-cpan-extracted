
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"
#include "ppport.h"

/* libsodium */
#include "sodium.h"

#define DUMP(v) do_sv_dump(0, Perl_debug_log, v, 0, 4, 0, 0);

typedef struct {
    unsigned char * bytes;
    STRLEN length;
    int locked;
} DataBytesLocker;

#if defined(AES256GCM_IS_AVAILABLE)
typedef struct {
    int locked;
    crypto_aead_aes256gcm_state * ctx;
} CryptNaClSodiumAeadAes256gcmState;
#endif

typedef struct {
    crypto_generichash_state * state;
    size_t init_bytes;
} CryptNaClSodiumGenerichashStream;

typedef struct {
    crypto_hash_sha256_state * state;
} CryptNaClSodiumHashSha256Stream;

typedef struct {
    crypto_hash_sha512_state * state;
} CryptNaClSodiumHashSha512Stream;

typedef struct {
    crypto_auth_hmacsha256_state * state;
} CryptNaClSodiumAuthHmacsha256Stream;

typedef struct {
    crypto_auth_hmacsha512_state * state;
} CryptNaClSodiumAuthHmacsha512Stream;

typedef struct {
    crypto_auth_hmacsha512256_state * state;
} CryptNaClSodiumAuthHmacsha512256Stream;

typedef struct {
    crypto_onetimeauth_state * state;
} CryptNaClSodiumOnetimeauthStream;

typedef DataBytesLocker * Data__BytesLocker;
#if defined(AES256GCM_IS_AVAILABLE)
typedef CryptNaClSodiumAeadAes256gcmState * Crypt__NaCl__Sodium__aead__aes256gcmstate;
#endif
typedef CryptNaClSodiumGenerichashStream * Crypt__NaCl__Sodium__generichash__stream;
typedef CryptNaClSodiumHashSha256Stream * Crypt__NaCl__Sodium__hash__sha256stream;
typedef CryptNaClSodiumHashSha512Stream * Crypt__NaCl__Sodium__hash__sha512stream;
typedef CryptNaClSodiumAuthHmacsha256Stream * Crypt__NaCl__Sodium__auth__hmacsha256stream;
typedef CryptNaClSodiumAuthHmacsha512Stream * Crypt__NaCl__Sodium__auth__hmacsha512stream;
typedef CryptNaClSodiumAuthHmacsha512256Stream * Crypt__NaCl__Sodium__auth__hmacsha512256stream;
typedef CryptNaClSodiumOnetimeauthStream * Crypt__NaCl__Sodium__onetimeauth__stream;

#define CLONESTATE(streamtype, statetype, padding, extra) \
    Newx(new_stream, 1, streamtype);\
    if ( new_stream == NULL ) {\
        croak("Could not allocate enough memory");\
    }\
    new_stream->state = sodium_malloc(sizeof(crypto_ ## statetype ## _state) + padding);\
    if ( new_stream->state == NULL ) {\
        croak("Could not allocate enough memory");\
    }\
    extra;\
    memcpy(new_stream->state,cur_stream->state,sizeof(crypto_ ## statetype ## _state) + padding);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
STATIC int dup_byteslocker(pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
    DataBytesLocker *new_bl;
    DataBytesLocker *cur_bl;
    PERL_UNUSED_VAR(params);
    Newx(new_bl, 1, DataBytesLocker);
    if ( new_bl == NULL ) {
        croak("Could not allocate enough memory");
    }
    cur_bl = (DataBytesLocker *)mg->mg_ptr;
    new_bl->length = cur_bl->length;
    new_bl->locked = cur_bl->locked;
    new_bl->bytes = sodium_malloc(cur_bl->length + 1 );
    if ( new_bl->bytes == NULL ) {
        croak("Could not allocate enough memory");
    }
    memcpy(new_bl->bytes,cur_bl->bytes,cur_bl->length);
    mg->mg_ptr = (char *)new_bl;
    return 0;
}

#define DUPSTREAM(streamtype, statetype, padding, extra) \
STATIC int dup_ ## statetype ## _stream(pTHX_ MAGIC *mg, CLONE_PARAMS *params)\
{\
    streamtype *new_stream;\
    streamtype *cur_stream;\
    PERL_UNUSED_VAR(params);\
    cur_stream = (streamtype *)mg->mg_ptr;\
    CLONESTATE(streamtype, statetype, padding, extra)\
    mg->mg_ptr = (char *)new_stream;\
    return 0;\
}

#if defined(AES256GCM_IS_AVAILABLE)
STATIC int dup_aead_aes256gcmstate(pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
    CryptNaClSodiumAeadAes256gcmState *new_state;
    CryptNaClSodiumAeadAes256gcmState *cur_state;
    size_t sizeof_state = crypto_aead_aes256gcm_statebytes();
    PERL_UNUSED_VAR(params);
    cur_state = (CryptNaClSodiumAeadAes256gcmState *)mg->mg_ptr;

    Newx(new_state, 1, CryptNaClSodiumAeadAes256gcmState);
    if ( new_state == NULL ) {
        croak("Could not allocate enough memory");
    }
    new_state->ctx = sodium_malloc(sizeof_state);
    if ( new_state->ctx == NULL ) {
        croak("Could not allocate enough memory");
    }
    memcpy(new_state->ctx,cur_state->ctx,sizeof_state);

    mg->mg_ptr = (char *)new_state;
    return 0;
}
#endif

DUPSTREAM(CryptNaClSodiumGenerichashStream, generichash, (size_t)63U & ~(size_t) 63U, new_stream->init_bytes=cur_stream->init_bytes)
DUPSTREAM(CryptNaClSodiumHashSha256Stream, hash_sha256, 0, ((void)0))
DUPSTREAM(CryptNaClSodiumHashSha512Stream, hash_sha512, 0, ((void)0))
DUPSTREAM(CryptNaClSodiumAuthHmacsha256Stream, auth_hmacsha256, 0, ((void)0))
DUPSTREAM(CryptNaClSodiumAuthHmacsha512Stream, auth_hmacsha512, 0, ((void)0))
DUPSTREAM(CryptNaClSodiumAuthHmacsha512256Stream, auth_hmacsha512256, 0, ((void)0))
DUPSTREAM(CryptNaClSodiumOnetimeauthStream, onetimeauth, 0, ((void)0))

#endif

STATIC MGVTBL vtbl_byteslocker = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_byteslocker,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
#if defined(AES256GCM_IS_AVAILABLE)
STATIC MGVTBL vtbl_aead_aes256gcmstate = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_aead_aes256gcmstate,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
#endif
STATIC MGVTBL vtbl_generichash = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_generichash_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_hash_sha256 = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_hash_sha256_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_hash_sha512 = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_hash_sha512_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_auth_hmacsha256 = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_auth_hmacsha256_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_auth_hmacsha512 = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_auth_hmacsha512_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_auth_hmacsha512256 = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_auth_hmacsha512256_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};
STATIC MGVTBL vtbl_onetimeauth = {
    NULL, /* get */ NULL, /* set */ NULL, /* len */ NULL, /* clear */ NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
# ifdef USE_ITHREADS
    dup_onetimeauth_stream,
# else
    NULL, /* dup */
# endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};

static DataBytesLocker * InitDataBytesLocker(pTHX_ STRLEN size) {
    DataBytesLocker *bl;
    Newx(bl, 1, DataBytesLocker);

    if ( bl == NULL ) {
        croak("Could not allocate enough memory");
    }

    bl->bytes = sodium_malloc(size + 1 );

    if ( bl->bytes == NULL ) {
        croak("Could not allocate enough memory");
    }

    bl->length = size;
    bl->locked = 0;

    return bl;
}

static SV * DataBytesLocker2SV(pTHX_ DataBytesLocker *bl) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
    SV *default_locked;
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Data::BytesLocker", 0));

    if ( (default_locked = get_sv("Data::BytesLocker::DEFAULT_LOCKED", 0)) ) {
        if ( SvTRUE(default_locked) ) {
            int rc = sodium_mprotect_noaccess((void *)bl->bytes);

            if ( rc != 0 ) {
                croak("Unable to protect BytesLocker object");
            }
            bl->locked = 1;
        }
    } else {
        int rc = sodium_mprotect_readonly((void *)bl->bytes);

        if ( rc != 0 ) {
            croak("Unable to protect BytesLocker object");
        }
    }

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_byteslocker, (const char *)bl, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static DataBytesLocker* GetBytesLocker(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Data::BytesLocker"))
        croak("Not a reference to a Data::BytesLocker object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_byteslocker) {
            return (DataBytesLocker *)mg->mg_ptr;
        }
    }

    croak("Failed to get Data::BytesLocker pointer");
    return (DataBytesLocker*)0; /* some compilers insist on a return value */
}

#if defined(AES256GCM_IS_AVAILABLE)
static CryptNaClSodiumAeadAes256gcmState * InitAeadAes256gcmState(pTHX_ unsigned char * key) {
    CryptNaClSodiumAeadAes256gcmState *pk;
    Newx(pk, 1, CryptNaClSodiumAeadAes256gcmState);

    if ( pk == NULL ) {
        croak("Could not allocate enough memory");
    }

    pk->ctx = sodium_malloc(crypto_aead_aes256gcm_statebytes());

    if ( pk->ctx == NULL ) {
        croak("Could not allocate enough memory");
    }


    crypto_aead_aes256gcm_beforenm(pk->ctx, key);
    pk->locked = 0;

    return pk;
}

static SV * AeadAes256gcmState2SV(pTHX_ CryptNaClSodiumAeadAes256gcmState *state) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
    SV *default_locked;
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::aead::aes256gcmstate", 0));

    if ( (default_locked = get_sv("Data::BytesLocker::DEFAULT_LOCKED", 0)) ) {
        if ( SvTRUE(default_locked) ) {
            int rc = sodium_mprotect_noaccess((void *)state->ctx);

            if ( rc != 0 ) {
                croak("Unable to protect AES256GCM precalculated key object");
            }
            state->locked = 1;
        }
    }

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_aead_aes256gcmstate, (const char *)state, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumAeadAes256gcmState* GetAeadAes256gcmState(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::aead::aes256gcmstate"))
        croak("Not a reference to a Crypt::NaCl::Sodium::aead::aes256gcmstate object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_aead_aes256gcmstate) {
            return (CryptNaClSodiumAeadAes256gcmState *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::aead::aes256gcmstate pointer");
    return (CryptNaClSodiumAeadAes256gcmState*)0; /* some compilers insist on a return value */
}
#endif

static SV * GenerichashStream2SV(pTHX_ CryptNaClSodiumGenerichashStream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::generichash::stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_generichash, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumGenerichashStream* GetGenerichashStream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::generichash::stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::generichash::stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_generichash) {
            return (CryptNaClSodiumGenerichashStream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::generichash::stream pointer");
    return (CryptNaClSodiumGenerichashStream*)0; /* some compilers insist on a return value */
}


static SV * HashSha256Stream2SV(pTHX_ CryptNaClSodiumHashSha256Stream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::hash::sha256stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_hash_sha256, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumHashSha256Stream* GetHashSha256Stream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::hash::sha256stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::hash::sha256stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_hash_sha256) {
            return (CryptNaClSodiumHashSha256Stream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::hash::sha256stream pointer");
    return (CryptNaClSodiumHashSha256Stream*)0; /* some compilers insist on a return value */
}


static SV * HashSha512Stream2SV(pTHX_ CryptNaClSodiumHashSha512Stream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::hash::sha512stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_hash_sha512, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumHashSha512Stream* GetHashSha512Stream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::hash::sha512stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::hash::sha512stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_hash_sha512) {
            return (CryptNaClSodiumHashSha512Stream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::hash::sha512stream pointer");
    return (CryptNaClSodiumHashSha512Stream*)0; /* some compilers insist on a return value */
}


static SV * AuthHmacsha256Stream2SV(pTHX_ CryptNaClSodiumAuthHmacsha256Stream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::auth::hmacsha256stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_auth_hmacsha256, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumAuthHmacsha256Stream* GetAuthHmacsha256Stream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::auth::hmacsha256stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::auth::hmacsha256stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_auth_hmacsha256) {
            return (CryptNaClSodiumAuthHmacsha256Stream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::auth::hmacsha256stream pointer");
    return (CryptNaClSodiumAuthHmacsha256Stream*)0; /* some compilers insist on a return value */
}


static SV * AuthHmacsha512Stream2SV(pTHX_ CryptNaClSodiumAuthHmacsha512Stream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::auth::hmacsha512stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_auth_hmacsha512, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumAuthHmacsha512Stream* GetAuthHmacsha512Stream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::auth::hmacsha512stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::auth::hmacsha512stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_auth_hmacsha512) {
            return (CryptNaClSodiumAuthHmacsha512Stream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::auth::hmacsha512stream pointer");
    return (CryptNaClSodiumAuthHmacsha512Stream*)0; /* some compilers insist on a return value */
}


static SV * AuthHmacsha512256Stream2SV(pTHX_ CryptNaClSodiumAuthHmacsha512256Stream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::auth::hmacsha512256stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_auth_hmacsha512256, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumAuthHmacsha512256Stream* GetAuthHmacsha512256Stream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::auth::hmacsha512256stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::auth::hmacsha512256stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_auth_hmacsha512256) {
            return (CryptNaClSodiumAuthHmacsha512256Stream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::auth::hmacsha512256stream pointer");
    return (CryptNaClSodiumAuthHmacsha512256Stream*)0; /* some compilers insist on a return value */
}


static SV * OnetimeauthStream2SV(pTHX_ CryptNaClSodiumOnetimeauthStream *stream) {
    SV *sv = newSV(0);
    SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
    MAGIC *mg;
#endif

    sv_bless(obj, gv_stashpv("Crypt::NaCl::Sodium::onetimeauth::stream", 0));

#ifdef USE_ITHREADS
    mg =
#endif
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_onetimeauth, (const char *)stream, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
    mg->mg_flags |= MGf_DUP;
#endif

    return obj;
}

static CryptNaClSodiumOnetimeauthStream* GetOnetimeauthStream(pTHX_ SV* sv)
{
    MAGIC *mg;

    if (!sv_derived_from(sv, "Crypt::NaCl::Sodium::onetimeauth::stream"))
        croak("Not a reference to a Crypt::NaCl::Sodium::onetimeauth::stream object");

    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_onetimeauth) {
            return (CryptNaClSodiumOnetimeauthStream *)mg->mg_ptr;
        }
    }

    croak("Failed to get Crypt::NaCl::Sodium::onetimeauth::stream pointer");
    return (CryptNaClSodiumOnetimeauthStream*)0; /* some compilers insist on a return value */
}


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium

BOOT:
{
    /* Initialise library */
    if ( sodium_init() == -1 )
    {
        croak("Failed to initialze library");
    }
}

PROTOTYPES: ENABLE

void
memcmp(left, right, length = 0)
    SV * left
    SV * right
    unsigned long length
    INIT:
        unsigned char * left_buf;
        unsigned char * right_buf;
        STRLEN left_len;
        STRLEN right_len;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        left_buf = (unsigned char *)SvPV(left, left_len);
        right_buf = (unsigned char *)SvPV(right, right_len);
        if ( length == 0 ) {
            if ( left_len != right_len ) {
                croak("Variables of unequal length cannot be automatically compared. Please provide the length argument");
            }
            length = left_len;
        } else {
            if ( length > left_len ) {
                croak("First argument is shorter then requested length");
            }
            else if ( length > right_len ) {
                croak("Second argument is shorter then requested length");
            }
        }

        if ( sodium_memcmp(left_buf, right_buf, length) == 0 ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

void
compare(left, right, length = 0)
    SV * left
    SV * right
    unsigned long length
    INIT:
        unsigned char * left_buf;
        unsigned char * right_buf;
        STRLEN left_len;
        STRLEN right_len;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        left_buf = (unsigned char *)SvPV(left, left_len);
        right_buf = (unsigned char *)SvPV(right, right_len);
        if ( length == 0 ) {
            if ( left_len != right_len ) {
                croak("Variables of unequal length cannot be automatically compared. Please provide the length argument");
            }
            length = left_len;
        } else {
            if ( length > left_len ) {
                croak("First argument is shorter then requested length");
            }
            else if ( length > right_len ) {
                croak("Second argument is shorter then requested length");
            }
        }

        XSRETURN_IV( sodium_compare(left_buf, right_buf, length) );
    }

void
increment(...)
    INIT:
        unsigned char * number_buf;
        STRLEN len;
        unsigned int i;
    PPCODE:
    {
        for ( i = 0; i < items; i++ ) {
            if (sv_derived_from(ST(i), "Data::BytesLocker")) {
                croak("This function does not handle BytesLocker objects");
            }
            number_buf = (unsigned char *)SvPV(ST(i), len);

            sodium_increment(number_buf, len);
        }
        XSRETURN_EMPTY;
    }

void
memzero(...)
    INIT:
        unsigned char * buf;
        STRLEN len;
        unsigned int i;
    PPCODE:
    {
        for ( i = 0; i < items; i++ ) {
            buf = (unsigned char *)SvPV_force(ST(i), len);
            sodium_memzero( buf, len);
        }
        XSRETURN_YES;
    }

SV *
random_number(...)
    INIT:
        unsigned int num;
    CODE:
    {
        if ( items == 1 ) {
            unsigned int upper_bound = (unsigned int)SvUV(ST(0));

            num = randombytes_uniform(upper_bound);
        }
        else {
            num = randombytes_random();
        }

        RETVAL = newSVuv(num);
    }
    OUTPUT:
        RETVAL

SV *
random_bytes(length)
    SV * length
    INIT:
        size_t len;
        DataBytesLocker *bl;
    CODE:
    {
        len = (size_t)SvUV(length);
        if ( len < 1 ) {
            croak("Invalid length");
        };

        bl = InitDataBytesLocker(aTHX_ len);

        randombytes_buf( bl->bytes, len );

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


SV *
bin2hex(bin_sv)
    SV * bin_sv
    PREINIT:
        char * hex;
        unsigned char * bin;
        size_t hex_len;
        STRLEN bin_len;
    CODE:
        bin = (unsigned char *)SvPV(bin_sv, bin_len);

        hex_len = bin_len * 2;
        hex = sodium_malloc(hex_len + 1);
        if ( hex == NULL ) {
            croak("Could not allocate memory");
        }
        sodium_bin2hex(hex, hex_len + 1, bin, bin_len);

        RETVAL = newSVpvn((const char * const)hex, hex_len);
    OUTPUT:
        RETVAL
    CLEANUP:
        sodium_free(hex);


SV *
hex2bin(hex_sv, ...)
    SV * hex_sv
    PREINIT:
        char * hex;
        unsigned char * bin;
        size_t hex_len;
        size_t bin_len;
        size_t bin_max_len = 0;
        char * ignore = NULL;
    CODE:
        hex = SvPV(hex_sv, hex_len);

        if ( items > 1 && (items + 1) % 2 != 0 ) {
            croak("Invalid number of arguments");
        } else if ( items > 1 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 1; i < items; i += 2 ) {
                key = SvPV(ST(i), keylen);
                if ( keylen == 6 && strnEQ(key, "ignore", 6) ) {
                    ignore = SvPV_nolen(ST(i+1));
                } else if ( keylen == 7 && strnEQ(key, "max_len", 7) ) {
                    bin_max_len = SvUV(ST(i+1));
                    if ( bin_max_len <= 0 ) {
                        croak("Invalid value for max_len: %ld", (long)bin_max_len);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }
        if ( bin_max_len == 0 ) {
            if ( ignore == NULL ) {
                bin_max_len = hex_len / 2;
            } else {
                bin_max_len = hex_len;
            }
        }
        bin = sodium_malloc( bin_max_len + 1 );
        if ( bin == NULL ) {
            croak("Could not allocate memory");
        }
        sodium_hex2bin(bin, bin_max_len, hex, hex_len, ignore, &bin_len, NULL);
        RETVAL = newSVpvn((const char * const)bin, bin_len);
    OUTPUT:
        RETVAL
    CLEANUP:
        sodium_free(bin);

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::secretbox

PROTOTYPES: DISABLE

unsigned int
NONCEBYTES(...)
    CODE:
        RETVAL = crypto_secretbox_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_secretbox_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
MACBYTES(...)
    CODE:
        RETVAL = crypto_secretbox_MACBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_secretbox_KEYBYTES);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
nonce(self, ...)
    SV * self
    PROTOTYPE: $;$
    INIT:
        DataBytesLocker *bl;
    CODE:
        PERL_UNUSED_VAR(self);

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }

        if (items == 2 ) {
            if ( SvOK(ST(1)) ) {
                STRLEN prev_nonce_len;
                unsigned char * prev_nonce = (unsigned char *)SvPV(ST(1), prev_nonce_len);

                if ( prev_nonce_len > crypto_secretbox_NONCEBYTES ) {
                    croak("Base nonce too long");
                }

                bl = InitDataBytesLocker(aTHX_ crypto_secretbox_NONCEBYTES);
                memcpy(bl->bytes, prev_nonce, prev_nonce_len);
                sodium_memzero(bl->bytes + prev_nonce_len, bl->length - prev_nonce_len);
            }
            else {
                croak("Base nonce invalid");
            }
        }
        else {
            bl = InitDataBytesLocker(aTHX_ crypto_secretbox_NONCEBYTES);
            randombytes_buf(bl->bytes, bl->length);
        }
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    OUTPUT:
        RETVAL



void
encrypt(self, msg, nonce, key)
    SV * self
    SV * msg
    SV * nonce
    SV * key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_secretbox_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        /* detached mode */
        if ( GIMME_V == G_ARRAY ) {
            DataBytesLocker *bl_mac;

            bl = InitDataBytesLocker(aTHX_ msg_len);
            bl_mac = InitDataBytesLocker(aTHX_ crypto_secretbox_MACBYTES);

            crypto_secretbox_detached( bl->bytes, bl_mac->bytes, (unsigned char *)msg_buf,
                (unsigned long long) msg_len, nonce_buf, key_buf);
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl_mac) );
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(2);
        }
        /* combined mode */
        else {
            enc_len = crypto_secretbox_MACBYTES + msg_len;
            bl = InitDataBytesLocker(aTHX_ enc_len);
            crypto_secretbox_easy( bl->bytes, msg_buf, msg_len, nonce_buf, key_buf);

            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
    }

void
decrypt(self, ciphertext, nonce, key)
    SV * self
    SV * ciphertext
    SV * nonce
    SV * key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

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
        enc_len = msg_len - crypto_secretbox_MACBYTES;

        bl = InitDataBytesLocker(aTHX_ enc_len);
        if ( crypto_secretbox_open_easy( bl->bytes, msg_buf, msg_len, nonce_buf, key_buf) == 0 ) {
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }



void
decrypt_detached(self, mac, ciphertext, nonce, key)
    SV * self
    SV * mac
    SV * ciphertext
    SV * nonce
    SV * key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned char * mac_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_secretbox_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_secretbox_KEYBYTES ) {
            croak("Invalid key");
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != crypto_secretbox_MACBYTES ) {
            croak("Invalid mac");
        }

        msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);
        if ( crypto_secretbox_open_detached( bl->bytes, msg_buf, mac_buf, msg_len, nonce_buf, key_buf) == 0 ) {
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }



MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::auth

PROTOTYPES: DISABLE

unsigned int
KEYBYTES(...)
    ALIAS:
        HMACSHA256_KEYBYTES = 1
        HMACSHA512_KEYBYTES = 2
        HMACSHA512256_KEYBYTES = 3
    CODE:
        switch(ix) {
            case 1:
                RETVAL = crypto_auth_hmacsha256_KEYBYTES;
                break;
            case 2:
                RETVAL = crypto_auth_hmacsha512_KEYBYTES;
                break;
            case 3:
                RETVAL = crypto_auth_hmacsha512256_KEYBYTES;
                break;
            default:
                RETVAL = crypto_auth_KEYBYTES;
        }
    OUTPUT:
        RETVAL

unsigned int
BYTES(...)
    ALIAS:
        HMACSHA256_BYTES = 1
        HMACSHA512_BYTES = 2
        HMACSHA512256_BYTES = 3
    CODE:
        switch(ix) {
            case 1:
                RETVAL = crypto_auth_hmacsha256_BYTES;
                break;
            case 2:
                RETVAL = crypto_auth_hmacsha512_BYTES;
                break;
            case 3:
                RETVAL = crypto_auth_hmacsha512256_BYTES;
                break;
            default:
                RETVAL = crypto_auth_BYTES;
        }
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    ALIAS:
        hmacsha256_keygen = 1
        hmacsha512_keygen = 2
        hmacsha512256_keygen = 3
    INIT:
        DataBytesLocker *bl;
        unsigned int key_size;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        switch(ix) {
            case 1:
                key_size = crypto_auth_hmacsha256_KEYBYTES;
                break;
            case 2:
                key_size = crypto_auth_hmacsha512_KEYBYTES;
                break;
            case 3:
                key_size = crypto_auth_hmacsha512256_KEYBYTES;
                break;
            default:
                key_size = crypto_auth_KEYBYTES;
        }
        bl = InitDataBytesLocker(aTHX_ key_size);
        randombytes_buf(bl->bytes, key_size);
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
mac(self, msg, key)
    SV * self
    SV * msg
    SV * key
    PROTOTYPE: $$$
    ALIAS:
        hmacsha256 = 1
        hmacsha512 = 2
        hmacsha512256 = 3
    INIT:
        STRLEN msg_len;
        STRLEN key_len;
        unsigned char * msg_buf;
        unsigned char * key_buf;
        unsigned int mac_size;
        unsigned int key_size;
        int (*mac_function)(unsigned char *, const unsigned char *, unsigned long long, const unsigned char *);
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                mac_size = crypto_auth_hmacsha256_BYTES;
                key_size = crypto_auth_hmacsha256_KEYBYTES;
                mac_function = &crypto_auth_hmacsha256;
                break;
            case 2:
                mac_size = crypto_auth_hmacsha512_BYTES;
                key_size = crypto_auth_hmacsha512_KEYBYTES;
                mac_function = &crypto_auth_hmacsha512;
                break;
            case 3:
                mac_size = crypto_auth_hmacsha512256_BYTES;
                key_size = crypto_auth_hmacsha512256_KEYBYTES;
                mac_function = &crypto_auth_hmacsha512256;
                break;
            default:
                mac_size = crypto_auth_BYTES;
                key_size = crypto_auth_KEYBYTES;
                mac_function = &crypto_auth;
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ mac_size);
        (*mac_function)( bl->bytes, msg_buf, msg_len, key_buf);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
verify(self, mac, msg, key)
    SV * self
    SV * mac
    SV * msg
    SV * key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN key_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * mac_buf;
        unsigned char * key_buf;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != crypto_auth_BYTES ) {
            croak("Invalid mac");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_auth_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        if ( crypto_auth_verify( mac_buf, msg_buf, msg_len, key_buf) == 0 ) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }


SV *
hmacsha256_verify(self, mac, msg, key)
    SV * self
    SV * mac
    SV * msg
    SV * key
    PROTOTYPE: $$$$
    ALIAS:
        hmacsha512_verify = 2
        hmacsha512256_verify = 3
    INIT:
        STRLEN msg_len;
        STRLEN key_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * mac_buf;
        unsigned char * key_buf;
        unsigned char * expected = NULL;
        unsigned int mac_size;
        unsigned int key_size;
        int free_expected = 0;
        int (*verify_function)(const unsigned char *, const unsigned char *, unsigned long long, const unsigned char *);
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 2:
                mac_size = crypto_auth_hmacsha512_BYTES;
                key_size = crypto_auth_hmacsha512_KEYBYTES;
                verify_function = &crypto_auth_hmacsha512_verify;
                break;
            case 3:
                mac_size = crypto_auth_hmacsha512256_BYTES;
                key_size = crypto_auth_hmacsha512256_KEYBYTES;
                verify_function = &crypto_auth_hmacsha512256_verify;
                break;
            default:
                mac_size = crypto_auth_hmacsha256_BYTES;
                key_size = crypto_auth_hmacsha256_KEYBYTES;
                verify_function = &crypto_auth_hmacsha256_verify;
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != mac_size ) {
            croak("Invalid mac");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        key_buf = (unsigned char *)SvPV(key, key_len);

        if ( key_len != key_size ) {
            expected = sodium_malloc(mac_size+1);
            if ( expected == NULL ) {
                croak("Could not allocate memory");
            }
            free_expected = 1;

            switch(ix) {
                case 2:
                {
                    crypto_auth_hmacsha512_state state_exp;
                    crypto_auth_hmacsha512_init(&state_exp, key_buf, key_len);
                    crypto_auth_hmacsha512_update(&state_exp, msg_buf, msg_len);
                    crypto_auth_hmacsha512_final(&state_exp, expected);
                    break;
                }
                case 3:
                {
                    crypto_auth_hmacsha512256_state state_exp;
                    crypto_auth_hmacsha512256_init(&state_exp, key_buf, key_len);
                    crypto_auth_hmacsha512256_update(&state_exp, msg_buf, msg_len);
                    crypto_auth_hmacsha512256_final(&state_exp, expected);
                    break;
                }
                default:
                {
                    crypto_auth_hmacsha256_state state_exp;
                    crypto_auth_hmacsha256_init(&state_exp, key_buf, key_len);
                    crypto_auth_hmacsha256_update(&state_exp, msg_buf, msg_len);
                    crypto_auth_hmacsha256_final(&state_exp, expected);
                }
            }

            RETVAL = sodium_memcmp( mac_buf, expected, mac_size ) == 0
                ? &PL_sv_yes : &PL_sv_no;
        } else {
            RETVAL = (*verify_function)( mac_buf, msg_buf, msg_len, key_buf ) == 0
                ? &PL_sv_yes : &PL_sv_no;
        }
    }
    OUTPUT:
        RETVAL
    CLEANUP:
        if ( free_expected ) {
            sodium_free(expected);
        }

void
hmacsha256_init(self, key)
    SV * self
    SV * key
    PROTOTYPE: $$
    INIT:
        STRLEN key_len;
        unsigned char * key_buf;
        CryptNaClSodiumAuthHmacsha256Stream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        key_buf = (unsigned char *)SvPV(key, key_len);

        Newx(stream, 1, CryptNaClSodiumAuthHmacsha256Stream);
        stream->state = sodium_malloc(sizeof(crypto_auth_hmacsha256_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_auth_hmacsha256_init(stream->state, key_buf, key_len);

        ST(0) = sv_2mortal(AuthHmacsha256Stream2SV(aTHX_ stream));

        XSRETURN(1);
    }

void
hmacsha512_init(self, key)
    SV * self
    SV * key
    PROTOTYPE: $$
    INIT:
        STRLEN key_len;
        unsigned char * key_buf;
        CryptNaClSodiumAuthHmacsha512Stream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        key_buf = (unsigned char *)SvPV(key, key_len);

        Newx(stream, 1, CryptNaClSodiumAuthHmacsha512Stream);
        stream->state = sodium_malloc(sizeof(crypto_auth_hmacsha512_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_auth_hmacsha512_init(stream->state, key_buf, key_len);

        ST(0) = sv_2mortal(AuthHmacsha512Stream2SV(aTHX_ stream));

        XSRETURN(1);
    }


void
hmacsha512256_init(self, key)
    SV * self
    SV * key
    PROTOTYPE: $$
    INIT:
        STRLEN key_len;
        unsigned char * key_buf;
        CryptNaClSodiumAuthHmacsha512256Stream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        key_buf = (unsigned char *)SvPV(key, key_len);

        Newx(stream, 1, CryptNaClSodiumAuthHmacsha512256Stream);
        stream->state = sodium_malloc(sizeof(crypto_auth_hmacsha512256_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_auth_hmacsha512256_init(stream->state, key_buf, key_len);

        ST(0) = sv_2mortal(AuthHmacsha512256Stream2SV(aTHX_ stream));

        XSRETURN(1);
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::auth::hmacsha256stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha256Stream* cur_stream = GetAuthHmacsha256Stream(aTHX_ self);
    INIT:
        CryptNaClSodiumAuthHmacsha256Stream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumAuthHmacsha256Stream, auth_hmacsha256, 0, ((void)0))
        ST(0) = sv_2mortal(AuthHmacsha256Stream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }


void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha256Stream* stream = GetAuthHmacsha256Stream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_auth_hmacsha256_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }


SV *
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumAuthHmacsha256Stream* stream = GetAuthHmacsha256Stream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_auth_hmacsha256_BYTES);

        crypto_auth_hmacsha256_final(stream->state, bl->bytes);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha256Stream* stream = GetAuthHmacsha256Stream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::auth::hmacsha512stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512Stream* cur_stream = GetAuthHmacsha512Stream(aTHX_ self);
    INIT:
        CryptNaClSodiumAuthHmacsha512Stream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumAuthHmacsha512Stream, auth_hmacsha512, 0, ((void)0))
        ST(0) = sv_2mortal(AuthHmacsha512Stream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }


void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512Stream* stream = GetAuthHmacsha512Stream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_auth_hmacsha512_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

SV *
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumAuthHmacsha512Stream* stream = GetAuthHmacsha512Stream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_auth_hmacsha512_BYTES);

        crypto_auth_hmacsha512_final(stream->state, bl->bytes);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512Stream* stream = GetAuthHmacsha512Stream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::auth::hmacsha512256stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512256Stream* cur_stream = GetAuthHmacsha512256Stream(aTHX_ self);
    INIT:
        CryptNaClSodiumAuthHmacsha512256Stream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumAuthHmacsha512256Stream, auth_hmacsha512256, 0, ((void)0))
        ST(0) = sv_2mortal(AuthHmacsha512256Stream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }


void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512256Stream* stream = GetAuthHmacsha512256Stream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_auth_hmacsha512256_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

SV *
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumAuthHmacsha512256Stream* stream = GetAuthHmacsha512256Stream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_auth_hmacsha512256_BYTES);

        crypto_auth_hmacsha512256_final(stream->state, bl->bytes);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumAuthHmacsha512256Stream* stream = GetAuthHmacsha512256Stream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::aead

PROTOTYPES: DISABLE

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_aead_chacha20poly1305_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
AES256GCM_KEYBYTES(...)
    CODE:
#if defined(AES256GCM_IS_AVAILABLE)
        RETVAL = crypto_aead_aes256gcm_KEYBYTES;
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    OUTPUT:
        RETVAL

unsigned int
AES256GCM_NPUBBYTES(...)
    CODE:
#if defined(AES256GCM_IS_AVAILABLE)
        RETVAL = crypto_aead_aes256gcm_NPUBBYTES;
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    OUTPUT:
        RETVAL

unsigned int
AES256GCM_ABYTES(...)
    CODE:
#if defined(AES256GCM_IS_AVAILABLE)
        RETVAL = crypto_aead_aes256gcm_ABYTES;
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    OUTPUT:
        RETVAL

unsigned int
NPUBBYTES(...)
    CODE:
        RETVAL = crypto_aead_chacha20poly1305_NPUBBYTES;
    OUTPUT:
        RETVAL

unsigned int
IETF_NPUBBYTES(...)
    CODE:
        RETVAL = crypto_aead_chacha20poly1305_IETF_NPUBBYTES;
    OUTPUT:
        RETVAL

unsigned int
ABYTES(...)
    CODE:
        RETVAL = crypto_aead_chacha20poly1305_ABYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

void
aes256gcm_is_available(self)
    SV * self
    PPCODE:
    {
        if ( crypto_aead_aes256gcm_is_available() ) {
            XSRETURN_YES;
        }
        XSRETURN_NO;
    }

SV *
keygen(self)
    SV * self
    ALIAS:
        aes256gcm_keygen = 1
    INIT:
        unsigned int key_size;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        switch(ix) {
            case 1:
#if defined(AES256GCM_IS_AVAILABLE)
                key_size = crypto_aead_aes256gcm_KEYBYTES;
#else
                croak("AES256-GCM is not supported by this CPU");
#endif
                break;
            default:
                key_size = crypto_aead_chacha20poly1305_KEYBYTES;
        }
        bl = InitDataBytesLocker(aTHX_ key_size);
        randombytes_buf(bl->bytes, key_size);
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
nonce(self, ...)
    SV * self
    PROTOTYPE: $;$
    ALIAS:
        ietf_nonce = 1
        aes256gcm_nonce = 2
    INIT:
        unsigned int nonce_size;
        DataBytesLocker *bl;
    CODE:
        PERL_UNUSED_VAR(self);

        switch(ix) {
            case 1:
                nonce_size = crypto_aead_chacha20poly1305_IETF_NPUBBYTES;
                break;
            case 2:
#if defined(AES256GCM_IS_AVAILABLE)
                nonce_size = crypto_aead_aes256gcm_NPUBBYTES;
#else
                croak("AES256-GCM is not supported by this CPU");
#endif
                break;
            default:
                nonce_size = crypto_aead_chacha20poly1305_NPUBBYTES;
        }

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }

        if (items == 2 ) {
            if ( SvOK(ST(1)) ) {
                STRLEN prev_nonce_len;
                unsigned char * prev_nonce = (unsigned char *)SvPV(ST(1), prev_nonce_len);

                if ( prev_nonce_len > nonce_size ) {
                    croak("Base nonce too long");
                }

                bl = InitDataBytesLocker(aTHX_ nonce_size);
                memcpy(bl->bytes, prev_nonce, prev_nonce_len);
                sodium_memzero(bl->bytes + prev_nonce_len, bl->length - prev_nonce_len);
            }
            else {
                croak("Base nonce invalid");
            }
        }
        else {
            bl = InitDataBytesLocker(aTHX_ nonce_size);
            randombytes_buf(bl->bytes, bl->length);
        }
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    OUTPUT:
        RETVAL

void
encrypt(self, msg, adata, nonce, key)
    SV * self
    SV * msg
    SV * adata
    SV * nonce
    SV * key
    PROTOTYPE: $$$$$
    ALIAS:
        ietf_encrypt = 1
        aes256gcm_encrypt = 2
    INIT:
        STRLEN msg_len;
        STRLEN adata_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * adata_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned int nonce_size;
        unsigned int adlen_size;
        unsigned int key_size;
        int (*encrypt_function)(unsigned char *, unsigned long long *, const unsigned char *, unsigned long long, 
            const unsigned char *, unsigned long long, const unsigned char *, const unsigned char *, const unsigned char *);
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                nonce_size = crypto_aead_chacha20poly1305_IETF_NPUBBYTES;
                key_size = crypto_aead_chacha20poly1305_KEYBYTES;
                adlen_size = crypto_aead_chacha20poly1305_ABYTES;
                encrypt_function = &crypto_aead_chacha20poly1305_ietf_encrypt;
                break;
            case 2:
#if defined(AES256GCM_IS_AVAILABLE)
                nonce_size = crypto_aead_aes256gcm_NPUBBYTES;
                key_size = crypto_aead_aes256gcm_KEYBYTES;
                adlen_size = crypto_aead_aes256gcm_ABYTES;
                encrypt_function = &crypto_aead_aes256gcm_encrypt;
#else
                croak("AES256-GCM is not supported by this CPU");
#endif
                break;
            default:
                nonce_size = crypto_aead_chacha20poly1305_NPUBBYTES;
                key_size = crypto_aead_chacha20poly1305_KEYBYTES;
                adlen_size = crypto_aead_chacha20poly1305_ABYTES;
                encrypt_function = &crypto_aead_chacha20poly1305_encrypt;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != nonce_size ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        adata_buf = (unsigned char *)SvPV(adata, adata_len);

        enc_len = msg_len + adlen_size;
        bl = InitDataBytesLocker(aTHX_ enc_len);

        (*encrypt_function)( bl->bytes, (unsigned long long *)&enc_len, msg_buf, msg_len,
            adata_buf, adata_len, NULL, nonce_buf, key_buf);

        bl->bytes[enc_len] = '\0';
        bl->length = enc_len;

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
decrypt(self, msg, adata, nonce, key)
    SV * self
    SV * msg
    SV * adata
    SV * nonce
    SV * key
    PROTOTYPE: $$$$
    ALIAS:
        ietf_decrypt = 1
        aes256gcm_decrypt = 2
    INIT:
        STRLEN msg_len;
        STRLEN adata_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * adata_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned int nonce_size;
        unsigned int adlen_size;
        unsigned int key_size;
        int (*decrypt_function)(unsigned char *, unsigned long long *, unsigned char *, const unsigned char *, unsigned long long, 
            const unsigned char *, unsigned long long, const unsigned char *, const unsigned char *);
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                nonce_size = crypto_aead_chacha20poly1305_IETF_NPUBBYTES;
                key_size = crypto_aead_chacha20poly1305_KEYBYTES;
                adlen_size = crypto_aead_chacha20poly1305_ABYTES;
                decrypt_function = &crypto_aead_chacha20poly1305_ietf_decrypt;
                break;
            case 2:
#if defined(AES256GCM_IS_AVAILABLE)
                nonce_size = crypto_aead_aes256gcm_NPUBBYTES;
                key_size = crypto_aead_aes256gcm_KEYBYTES;
                adlen_size = crypto_aead_aes256gcm_ABYTES;
                decrypt_function = &crypto_aead_aes256gcm_decrypt;
#else
                croak("AES256-GCM is not supported by this CPU");
#endif
                break;
            default:
                nonce_size = crypto_aead_chacha20poly1305_NPUBBYTES;
                key_size = crypto_aead_chacha20poly1305_KEYBYTES;
                adlen_size = crypto_aead_chacha20poly1305_ABYTES;
                decrypt_function = &crypto_aead_chacha20poly1305_decrypt;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != nonce_size ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        if ( msg_len < adlen_size ) {
            croak("Invalid ciphertext");
        }

        adata_buf = (unsigned char *)SvPV(adata, adata_len);

        enc_len = msg_len;
        bl = InitDataBytesLocker(aTHX_ enc_len);

        if ( (*decrypt_function)( bl->bytes, (unsigned long long *)&enc_len, NULL, msg_buf, msg_len, adata_buf, adata_len, nonce_buf, key_buf) == 0 ) {
            bl->bytes[enc_len] = '\0';
            bl->length = enc_len;
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }

void
aes256gcm_beforenm(self, key)
    SV * self
    SV * key
    PROTOTYPE: $;%
    INIT:
        STRLEN key_len = 0;
        unsigned char * key_buf = NULL;
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState *state;
#endif
    PPCODE:
    {
        PERL_UNUSED_VAR(self);
#if defined(AES256GCM_IS_AVAILABLE)
        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_aead_aes256gcm_KEYBYTES ) {
            croak("Invalid key");
        }

        state = InitAeadAes256gcmState(aTHX_ key_buf);

        ST(0) = sv_2mortal(AeadAes256gcmState2SV(aTHX_ state));

        XSRETURN(1);
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

void
aes256gcm_encrypt_afternm(self, msg, adata, nonce, precalculated_key)
    SV * self
    SV * msg
    SV * adata
    SV * nonce
    SV * precalculated_key
    PROTOTYPE: $$$$$
    INIT:
        STRLEN msg_len;
        STRLEN adata_len;
        STRLEN nonce_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * adata_buf;
        unsigned char * nonce_buf;
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState * precal_key;
#endif
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);
#if defined(AES256GCM_IS_AVAILABLE)

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_aead_aes256gcm_NPUBBYTES ) {
            croak("Invalid nonce");
        }

        precal_key = GetAeadAes256gcmState(aTHX_ precalculated_key);

        if ( precal_key->locked ) {
            croak("Unlock AES256GCM precalculated key object before accessing the state");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        adata_buf = (unsigned char *)SvPV(adata, adata_len);

        enc_len = msg_len + crypto_aead_aes256gcm_ABYTES;
        bl = InitDataBytesLocker(aTHX_ enc_len);

        crypto_aead_aes256gcm_encrypt_afternm( bl->bytes, (unsigned long long *)&enc_len, msg_buf, msg_len,
            adata_buf, adata_len, NULL, nonce_buf, (const crypto_aead_aes256gcm_state *)precal_key->ctx);

        bl->bytes[enc_len] = '\0';
        bl->length = enc_len;

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

        XSRETURN(1);
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

void
aes256gcm_decrypt_afternm(self, msg, adata, nonce, precalculated_key)
    SV * self
    SV * msg
    SV * adata
    SV * nonce
    SV * precalculated_key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN adata_len;
        STRLEN nonce_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * adata_buf;
        unsigned char * nonce_buf;
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState * precal_key;
#endif
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);
#if defined(AES256GCM_IS_AVAILABLE)

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_aead_aes256gcm_NPUBBYTES ) {
            croak("Invalid nonce");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        if ( msg_len < crypto_aead_aes256gcm_ABYTES ) {
            croak("Invalid ciphertext");
        }

        precal_key = GetAeadAes256gcmState(aTHX_ precalculated_key);

        if ( precal_key->locked ) {
            croak("Unlock AES256GCM precalculated key object before accessing the state");
        }

        adata_buf = (unsigned char *)SvPV(adata, adata_len);

        enc_len = msg_len;
        bl = InitDataBytesLocker(aTHX_ enc_len);

        if ( crypto_aead_aes256gcm_decrypt_afternm( bl->bytes, (unsigned long long *)&enc_len, NULL, msg_buf, msg_len, adata_buf, adata_len, nonce_buf, (const crypto_aead_aes256gcm_state *) precal_key->ctx) == 0 ) {
            bl->bytes[enc_len] = '\0';
            bl->length = enc_len;
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::aead::aes256gcmstate

void
lock(self)
    SV * self
    PPCODE:
    {
        int rc;
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState* state;

        state = GetAeadAes256gcmState(aTHX_ self);

        rc = sodium_mprotect_noaccess((void *)state->ctx);

        if (rc == 0 ) {
            state->locked = 1;
            XSRETURN_YES;
        }

        croak("Unable to lock memory: %s", Strerror(errno));
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

void
unlock(self)
    SV * self
    PPCODE:
    {
        int rc;
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState* state;

        state = GetAeadAes256gcmState(aTHX_ self);

        rc = sodium_mprotect_readonly((void *)state->ctx);

        if (rc == 0 ) {
            state->locked = 0;
            XSRETURN_YES;
        }
        croak("Unable to unlock memory: %s", Strerror(errno));
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

void
is_locked(self, ...)
    SV * self
    PPCODE:
    {
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState* state;

        state = GetAeadAes256gcmState(aTHX_ self);
        if ( state->locked ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }

void
DESTROY(self)
    SV * self
    PPCODE:
    {
#if defined(AES256GCM_IS_AVAILABLE)
        CryptNaClSodiumAeadAes256gcmState* state;
        state = GetAeadAes256gcmState(aTHX_ self);
        sodium_free( state->ctx );
        Safefree(state);
#else
        croak("AES256-GCM is not supported by this CPU");
#endif
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::box

PROTOTYPES: DISABLE

unsigned int
PUBLICKEYBYTES(...)
    CODE:
        RETVAL = crypto_box_PUBLICKEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
SECRETKEYBYTES(...)
    CODE:
        RETVAL = crypto_box_SECRETKEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
NONCEBYTES(...)
    CODE:
        RETVAL = crypto_box_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
MACBYTES(...)
    CODE:
        RETVAL = crypto_box_MACBYTES;
    OUTPUT:
        RETVAL

unsigned int
SEEDBYTES(...)
    CODE:
        RETVAL = crypto_box_SEEDBYTES;
    OUTPUT:
        RETVAL

unsigned int
BEFORENMBYTES(...)
    CODE:
        RETVAL = crypto_box_BEFORENMBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

void
keypair(self, ...)
    SV * self
    PROTOTYPE: $;$
    INIT:
        DataBytesLocker *blp;
        DataBytesLocker *bls;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }
        /* from seed */
        else if ( items == 2 ) {
            if ( SvPOK(ST(1)) || (SvROK(ST(1)) && sv_derived_from(ST(1), "Data::BytesLocker"))) {
                STRLEN seed_len;
                unsigned char * seed_buf = (unsigned char *)SvPV(ST(1), seed_len);

                if ( seed_len != crypto_box_SEEDBYTES ) {
                    croak("Invalid seed length: %u", seed_len);
                }

                blp = InitDataBytesLocker(aTHX_ crypto_box_PUBLICKEYBYTES);
                bls = InitDataBytesLocker(aTHX_ crypto_box_SECRETKEYBYTES);

                crypto_box_seed_keypair(blp->bytes, bls->bytes, seed_buf);
            } else {
                croak("Invalid seed");
            }
        }
        /* regular */
        else {
            blp = InitDataBytesLocker(aTHX_ crypto_box_PUBLICKEYBYTES);
            bls = InitDataBytesLocker(aTHX_ crypto_box_SECRETKEYBYTES);
            crypto_box_keypair(blp->bytes, bls->bytes);
        }
        mXPUSHs( DataBytesLocker2SV(aTHX_ blp) );
        mXPUSHs( DataBytesLocker2SV(aTHX_ bls) );
        XSRETURN(2);
    }

SV *
public_key(self, seckey)
    SV * self
    SV * seckey
    INIT:
        DataBytesLocker *bl;
        STRLEN skey_len;
        unsigned char * skey_buf;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_box_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }
        bl = InitDataBytesLocker(aTHX_ crypto_box_PUBLICKEYBYTES);

        crypto_scalarmult_base(bl->bytes, skey_buf);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL



SV *
seed(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_box_SEEDBYTES);
        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


SV *
beforenm(self, pubkey, seckey)
    SV * self
    SV * pubkey
    SV * seckey
    INIT:
        STRLEN pkey_len;
        STRLEN skey_len;
        unsigned char * pkey_buf;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        pkey_buf = (unsigned char *)SvPV(pubkey, pkey_len);
        if ( pkey_len != crypto_box_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_box_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        bl = InitDataBytesLocker(aTHX_ crypto_box_BEFORENMBYTES);

        if ( crypto_box_beforenm(bl->bytes, pkey_buf, skey_buf) != 0 ) {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Failed to pre-calculate key");
        }

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
nonce(self, ...)
    SV * self
    PROTOTYPE: $;$
    INIT:
        DataBytesLocker *bl;
    CODE:
        PERL_UNUSED_VAR(self);

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }

        if (items == 2 ) {
            if ( SvOK(ST(1)) ) {
                STRLEN prev_nonce_len;
                unsigned char * prev_nonce = (unsigned char *)SvPV(ST(1), prev_nonce_len);

                if ( prev_nonce_len > crypto_box_NONCEBYTES ) {
                    croak("Base nonce too long");
                }

                bl = InitDataBytesLocker(aTHX_ crypto_box_NONCEBYTES);
                memcpy(bl->bytes, prev_nonce, prev_nonce_len);
                sodium_memzero(bl->bytes + prev_nonce_len, bl->length - prev_nonce_len);
            }
            else {
                croak("Base nonce invalid");
            }
        }
        else {
            bl = InitDataBytesLocker(aTHX_ crypto_box_NONCEBYTES);
            randombytes_buf(bl->bytes, bl->length);
        }
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    OUTPUT:
        RETVAL


void
encrypt(self, msg, nonce, recipient_pubkey, sender_seckey)
    SV * self
    SV * msg
    SV * nonce
    SV * recipient_pubkey
    SV * sender_seckey
    PROTOTYPE: $$$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN pkey_len;
        STRLEN skey_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * pkey_buf;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
        DataBytesLocker *blm;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        pkey_buf = (unsigned char *)SvPV(recipient_pubkey, pkey_len);
        if ( pkey_len != crypto_box_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        skey_buf = (unsigned char *)SvPV(sender_seckey, skey_len);
        if ( skey_len != crypto_box_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        /* detached mode */
        if ( GIMME_V == G_ARRAY ) {
            unsigned char *mac;

            bl = InitDataBytesLocker(aTHX_ msg_len);
            blm = InitDataBytesLocker(aTHX_ crypto_box_MACBYTES);

            if ( crypto_box_detached( bl->bytes, blm->bytes, (unsigned char *)msg_buf,
                (unsigned long long) msg_len, nonce_buf, pkey_buf, skey_buf) != 0 ) {

                sodium_free(bl->bytes);
                Safefree(bl);
                sodium_free(blm->bytes);
                Safefree(blm);

                croak("Failed to encrypt data");
            }
            mXPUSHs( DataBytesLocker2SV(aTHX_ blm) );
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(2);
        }
        /* combined mode */
        else {
            enc_len = crypto_box_MACBYTES + msg_len;
            bl = InitDataBytesLocker(aTHX_ enc_len);

            if ( crypto_box_easy( bl->bytes, msg_buf, msg_len, nonce_buf, pkey_buf, skey_buf) != 0 ) {
                sodium_free(bl->bytes);
                Safefree(bl);
                croak("Failed to encrypt data");
            }

            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
    }

void
encrypt_afternm(self, msg, nonce, precalculated_key)
    SV * self
    SV * msg
    SV * nonce
    SV * precalculated_key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
        DataBytesLocker *blm;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(precalculated_key, key_len);
        if ( key_len != crypto_box_BEFORENMBYTES ) {
            croak("Invalid precalculated key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        /* detached mode */
        if ( GIMME_V == G_ARRAY ) {

            bl = InitDataBytesLocker(aTHX_ msg_len);
            blm = InitDataBytesLocker(aTHX_ crypto_box_MACBYTES);

            crypto_box_detached_afternm( bl->bytes, blm->bytes, (unsigned char *)msg_buf,
                (unsigned long long) msg_len, nonce_buf, key_buf);

            mXPUSHs( DataBytesLocker2SV(aTHX_ blm) );
            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(2);
        }
        /* combined mode */
        else {
            enc_len = crypto_box_MACBYTES + msg_len;
            bl = InitDataBytesLocker(aTHX_ enc_len);

            crypto_box_easy_afternm( bl->bytes, msg_buf, msg_len,
                 nonce_buf, key_buf);

            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
            XSRETURN(1);
        }
    }


SV *
decrypt(self, ciphertext, nonce, sender_pubkey, recipient_seckey)
    SV * self
    SV * ciphertext
    SV * nonce
    SV * sender_pubkey
    SV * recipient_seckey
    PROTOTYPE: $$$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN pkey_len;
        STRLEN skey_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * pkey_buf;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        pkey_buf = (unsigned char *)SvPV(sender_pubkey, pkey_len);
        if ( pkey_len != crypto_box_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        skey_buf = (unsigned char *)SvPV(recipient_seckey, skey_len);
        if ( skey_len != crypto_box_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);

        if ( msg_len < crypto_box_MACBYTES ) {
            croak("Invalid ciphertext");
        }

        enc_len = msg_len - crypto_box_MACBYTES;

        bl = InitDataBytesLocker(aTHX_ enc_len);
        if ( crypto_box_open_easy( bl->bytes, msg_buf, msg_len, nonce_buf, pkey_buf, skey_buf) == 0 ) {
            RETVAL = DataBytesLocker2SV(aTHX_ bl);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }
    OUTPUT:
        RETVAL


SV *
decrypt_detached(self, mac, ciphertext, nonce, sender_pubkey, recipient_seckey)
    SV * self
    SV * mac
    SV * ciphertext
    SV * nonce
    SV * sender_pubkey
    SV * recipient_seckey
    PROTOTYPE: $$$$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN pkey_len;
        STRLEN skey_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * pkey_buf;
        unsigned char * skey_buf;
        unsigned char * mac_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        pkey_buf = (unsigned char *)SvPV(sender_pubkey, pkey_len);
        if ( pkey_len != crypto_box_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        skey_buf = (unsigned char *)SvPV(recipient_seckey, skey_len);
        if ( skey_len != crypto_box_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != crypto_box_MACBYTES ) {
            croak("Invalid mac");
        }

        msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);
        if ( crypto_box_open_detached( bl->bytes, msg_buf, mac_buf, msg_len, nonce_buf, pkey_buf, skey_buf) == 0 ) {
            RETVAL = DataBytesLocker2SV(aTHX_ bl);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }
    OUTPUT:
        RETVAL


SV *
decrypt_afternm(self, ciphertext, nonce, precalculated_key)
    SV * self
    SV * ciphertext
    SV * nonce
    SV * precalculated_key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(precalculated_key, key_len);
        if ( key_len != crypto_box_BEFORENMBYTES ) {
            croak("Invalid precalculated key");
        }

        msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);

        if ( msg_len < crypto_box_MACBYTES ) {
            croak("Invalid ciphertext");
        }

        enc_len = msg_len - crypto_box_MACBYTES;

        bl = InitDataBytesLocker(aTHX_ enc_len);
        if ( crypto_box_open_easy_afternm( bl->bytes, msg_buf, msg_len, nonce_buf, key_buf) == 0 ) {
            RETVAL = DataBytesLocker2SV(aTHX_ bl);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }
    OUTPUT:
        RETVAL


SV *
decrypt_detached_afternm(self, mac, ciphertext, nonce, precalculated_key)
    SV * self
    SV * mac
    SV * ciphertext
    SV * nonce
    SV * precalculated_key
    PROTOTYPE: $$$$$
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned char * mac_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_box_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(precalculated_key, key_len);
        if ( key_len != crypto_box_BEFORENMBYTES ) {
            croak("Invalid precalculated key");
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != crypto_box_MACBYTES ) {
            croak("Invalid mac");
        }

        msg_buf = (unsigned char *)SvPV(ciphertext, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);
        if ( crypto_box_open_detached_afternm( bl->bytes, msg_buf, mac_buf, msg_len, nonce_buf, key_buf) == 0 ) {
            RETVAL = DataBytesLocker2SV(aTHX_ bl);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }
    OUTPUT:
        RETVAL


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::sign

PROTOTYPES: DISABLE

unsigned int
PUBLICKEYBYTES(...)
    CODE:
        RETVAL = crypto_sign_PUBLICKEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
SECRETKEYBYTES(...)
    CODE:
        RETVAL = crypto_sign_SECRETKEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
BYTES(...)
    CODE:
        RETVAL = crypto_sign_BYTES;
    OUTPUT:
        RETVAL

unsigned int
SEEDBYTES(...)
    CODE:
        RETVAL = crypto_sign_SEEDBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

void
keypair(self, ...)
    SV * self
    PROTOTYPE: $;$
    INIT:
        DataBytesLocker *blp;
        DataBytesLocker *bls;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }
        /* from seed */
        else if ( items == 2 ) {
            if ( SvPOK(ST(1)) || (SvROK(ST(1)) && sv_derived_from(ST(1), "Data::BytesLocker"))) {
                STRLEN seed_len;
                unsigned char * seed_buf = (unsigned char *)SvPV(ST(1), seed_len);

                if ( seed_len != crypto_sign_SEEDBYTES ) {
                    croak("Invalid seed length: %u", seed_len);
                }

                blp = InitDataBytesLocker(aTHX_ crypto_sign_PUBLICKEYBYTES);
                bls = InitDataBytesLocker(aTHX_ crypto_sign_SECRETKEYBYTES);

                crypto_sign_seed_keypair(blp->bytes, bls->bytes, seed_buf);
            } else {
                croak("Invalid seed");
            }
        }
        /* regular */
        else {
            blp = InitDataBytesLocker(aTHX_ crypto_sign_PUBLICKEYBYTES);
            bls = InitDataBytesLocker(aTHX_ crypto_sign_SECRETKEYBYTES);
            crypto_sign_keypair(blp->bytes, bls->bytes);
        }
        mXPUSHs( DataBytesLocker2SV(aTHX_ blp) );
        mXPUSHs( DataBytesLocker2SV(aTHX_ bls) );
        XSRETURN(2);
    }


void
to_curve25519_keypair(self, pubkey, seckey)
    SV * self
    SV * pubkey
    SV * seckey
    PROTOTYPE: $$$
    INIT:
        STRLEN pkey_len;
        STRLEN skey_len;
        unsigned char * pkey_buf;
        unsigned char * skey_buf;
        DataBytesLocker *blp;
        DataBytesLocker *bls;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        pkey_buf = (unsigned char *)SvPV(pubkey, pkey_len);
        if ( pkey_len != crypto_sign_ed25519_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_sign_ed25519_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        blp = InitDataBytesLocker(aTHX_ crypto_scalarmult_curve25519_BYTES);

        if ( crypto_sign_ed25519_pk_to_curve25519( blp->bytes, pkey_buf) != 0 ) {
            sodium_free(blp->bytes);
            Safefree(blp);
            croak("Conversion of public key failed");
        }

        bls = InitDataBytesLocker(aTHX_ crypto_scalarmult_curve25519_BYTES);
        if ( crypto_sign_ed25519_sk_to_curve25519( bls->bytes, skey_buf) != 0 ) {
            sodium_free(bls->bytes);
            Safefree(bls);
            croak("Conversion of secret key failed");
        }

        mXPUSHs( DataBytesLocker2SV(aTHX_ blp) );
        mXPUSHs( DataBytesLocker2SV(aTHX_ bls) );
        XSRETURN(2);
    }


void
public_key(self, seckey)
    SV * self
    SV * seckey
    INIT:
        STRLEN skey_len;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_sign_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }
        bl = InitDataBytesLocker(aTHX_ crypto_sign_PUBLICKEYBYTES);
        crypto_sign_ed25519_sk_to_pk(bl->bytes, skey_buf);
        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
extract_seed(self, seckey)
    SV * self
    SV * seckey
    INIT:
        STRLEN skey_len;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_sign_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }
        bl = InitDataBytesLocker(aTHX_ crypto_sign_SEEDBYTES);
        crypto_sign_ed25519_sk_to_seed(bl->bytes, skey_buf);
        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
seed(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_sign_SEEDBYTES);
        randombytes_buf(bl->bytes, bl->length);
        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
seal(self, msg, seckey)
    SV * self
    SV * msg
    SV * seckey
    PROTOTYPE: $$$
    INIT:
        STRLEN msg_len;
        STRLEN skey_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_sign_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        enc_len = crypto_sign_BYTES + msg_len;
        bl = InitDataBytesLocker(aTHX_ enc_len);
        crypto_sign( bl->bytes, (unsigned long long *)&enc_len, msg_buf, msg_len, skey_buf);
        /* set actual length */
        bl->bytes[enc_len] = '\0';
        bl->length = enc_len;

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


void
mac(self, msg, seckey)
    SV * self
    SV * msg
    SV * seckey
    PROTOTYPE: $$$
    INIT:
        STRLEN msg_len;
        STRLEN skey_len;
        unsigned char * msg_buf;
        unsigned char * skey_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        skey_buf = (unsigned char *)SvPV(seckey, skey_len);
        if ( skey_len != crypto_sign_SECRETKEYBYTES ) {
            croak("Invalid secret key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ crypto_sign_BYTES);

        crypto_sign_detached( bl->bytes, NULL, (unsigned char *)msg_buf,
            (unsigned long long) msg_len, skey_buf);
        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
verify(self, sig, msg, pubkey)
    SV * self
    SV * sig
    SV * msg
    SV * pubkey
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN sig_len;
        STRLEN pkey_len;
        unsigned char * msg_buf;
        unsigned char * sig_buf;
        unsigned char * pkey_buf;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        sig_buf = (unsigned char *)SvPV(sig, sig_len);
        if ( sig_len != crypto_sign_BYTES ) {
            croak("Invalid signature");
        }

        pkey_buf = (unsigned char *)SvPV(pubkey, pkey_len);
        if ( pkey_len != crypto_sign_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        if ( crypto_sign_verify_detached( sig_buf, msg_buf, msg_len, pkey_buf) == 0 ) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }


void
open(self, smsg, pubkey)
    SV * self
    SV * smsg
    SV * pubkey
    PROTOTYPE: $$$
    INIT:
        STRLEN msg_len;
        STRLEN pkey_len;
        STRLEN enc_len;
        unsigned char * msg_buf;
        unsigned char * pkey_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        pkey_buf = (unsigned char *)SvPV(pubkey, pkey_len);
        if ( pkey_len != crypto_sign_PUBLICKEYBYTES ) {
            croak("Invalid public key");
        }

        msg_buf = (unsigned char *)SvPV(smsg, msg_len);

        if ( msg_len < crypto_sign_BYTES ) {
            croak("Invalid input data");
        }

        enc_len = msg_len - crypto_sign_BYTES;

        bl = InitDataBytesLocker(aTHX_ enc_len);
        if ( crypto_sign_open( bl->bytes, (unsigned long long *)&enc_len, msg_buf, msg_len, pkey_buf) == 0 ) {
            /* update actual length */
            bl->bytes[enc_len] = '\0';
            bl->length = enc_len;

            mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

            XSRETURN(1);
        }
        else {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Message forged");
        }
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::generichash

PROTOTYPES: DISABLE

unsigned int
BYTES(...)
    CODE:
        RETVAL = crypto_generichash_BYTES;
    OUTPUT:
        RETVAL

unsigned int
BYTES_MIN(...)
    CODE:
        RETVAL = crypto_generichash_BYTES_MIN;
    OUTPUT:
        RETVAL

unsigned int
BYTES_MAX(...)
    CODE:
        RETVAL = crypto_generichash_BYTES_MAX;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_generichash_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES_MIN(...)
    CODE:
        RETVAL = crypto_generichash_KEYBYTES_MIN;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES_MAX(...)
    CODE:
        RETVAL = crypto_generichash_KEYBYTES_MAX;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self, keybytes = crypto_generichash_KEYBYTES)
    SV * self
    size_t keybytes
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        if ( keybytes < crypto_generichash_KEYBYTES_MIN || keybytes > crypto_generichash_KEYBYTES_MAX ) {
            croak("Invalid keybytes value: %u", keybytes);
        }

        bl = InitDataBytesLocker(aTHX_ keybytes);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
mac(self, msg, ...)
    SV * self
    SV * msg
    PROTOTYPE: $$;%
    INIT:
        unsigned char * msg_buf;
        DataBytesLocker *bl;
        unsigned char * key_buf = NULL;
        STRLEN msg_len = 0;
        STRLEN key_len = 0;
        size_t bytes = crypto_generichash_BYTES;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 2 && ( items > 6 || items % 2 != 0 ) ) {
            croak("Invalid number of arguments");
        } else if ( items > 2 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 2; i < items; i += 2 ) {
                key = SvPV(ST(i), keylen);
                if ( keylen == 3 && strnEQ(key, "key", 3) ) {
                    key_buf = (unsigned char *)SvPV(ST(i+1), key_len);
                    if ( key_len < crypto_generichash_KEYBYTES_MIN || key_len > crypto_generichash_KEYBYTES_MAX ) {
                        croak("Invalid key length: %u", key_len);
                    }
                }
                else if ( keylen == 5 && strnEQ(key, "bytes", 5) ) {
                    bytes = (size_t)SvUV(ST(i+1));
                    if ( bytes < crypto_generichash_BYTES_MIN || bytes > crypto_generichash_BYTES_MAX ) {
                        croak("Invalid bytes value: %u", bytes);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ bytes);
        crypto_generichash(bl->bytes, bytes, msg_buf, msg_len, key_buf, key_len);

        ST(0) = sv_2mortal(DataBytesLocker2SV(aTHX_ bl));
        XSRETURN(1);
    }


void
init(self, ...)
    SV * self
    PROTOTYPE: $;%
    INIT:
        STRLEN key_len = 0;
        unsigned char * key_buf = NULL;
        CryptNaClSodiumGenerichashStream *stream;

        size_t bytes = crypto_generichash_BYTES;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 1 && ( items > 5 || (items + 1) % 2 != 0 ) ) {
            croak("Invalid number of arguments");
        } else if ( items > 1 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 1; i < items; i += 2 ) {
                key = (char *)SvPV(ST(i), keylen);
                if ( keylen == 3 && strnEQ(key, "key", 3) ) {
                    key_buf = (unsigned char *)SvPV(ST(i+1), key_len);
                    if ( key_len < crypto_generichash_KEYBYTES_MIN || key_len > crypto_generichash_KEYBYTES_MAX ) {
                        croak("Invalid key length: %u", key_len);
                    }
                }
                else if ( keylen == 5 && strnEQ(key, "bytes", 5) ) {
                    bytes =  SvUV(ST(i+1));
                    if ( bytes < crypto_generichash_BYTES_MIN || bytes > crypto_generichash_BYTES_MAX ) {
                        croak("Invalid bytes value: %u", bytes);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }

        Newx(stream, 1, CryptNaClSodiumGenerichashStream);
        stream->state = sodium_malloc(sizeof(crypto_generichash_state) + (size_t)63U & ~(size_t) 63U);
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }
        stream->init_bytes = bytes;

        crypto_generichash_init(stream->state, key_buf, key_len, bytes);

        ST(0) = sv_2mortal(GenerichashStream2SV(aTHX_ stream));

        XSRETURN(1);
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::generichash::stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumGenerichashStream* cur_stream = GetGenerichashStream(aTHX_ self);
    INIT:
        CryptNaClSodiumGenerichashStream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumGenerichashStream, generichash, (size_t)63U & ~(size_t) 63U, new_stream->init_bytes=cur_stream->init_bytes)
        ST(0) = sv_2mortal(GenerichashStream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }


void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumGenerichashStream* stream = GetGenerichashStream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_generichash_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

void
final(self, ...)
    SV * self
    PROTOTYPE: $%
    PREINIT:
        CryptNaClSodiumGenerichashStream* stream = GetGenerichashStream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
        size_t bytes;
    PPCODE:
    {
        bytes = stream->init_bytes;

        if ( items > 1 && items != 3 ) {
            croak("Invalid number of arguments");
        } else if ( items > 1 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 1; i < items; i += 2 ) {
                key = (char *)SvPV(ST(i), keylen);
                if ( keylen == 5 && strnEQ(key, "bytes", 5) ) {
                    bytes =  SvUV(ST(i+1));
                    if ( bytes < crypto_generichash_BYTES_MIN || bytes > crypto_generichash_BYTES_MAX ) {
                        croak("Invalid bytes value: %u", bytes);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }
        bl = InitDataBytesLocker(aTHX_ bytes);

        crypto_generichash_final(stream->state, bl->bytes, bytes);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

        XSRETURN(1);
    }

void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumGenerichashStream* stream = GetGenerichashStream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::shorthash

PROTOTYPES: DISABLE

unsigned int
BYTES(...)
    CODE:
        RETVAL = crypto_shorthash_BYTES;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_shorthash_KEYBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_shorthash_KEYBYTES);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


SV *
mac(self, msg, key)
    SV * self
    SV * msg
    SV * key
    PROTOTYPE: $$$
    INIT:
        STRLEN msg_len = 0;
        STRLEN key_len = 0;
        unsigned char * msg_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);


        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_shorthash_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ crypto_shorthash_BYTES);
        crypto_shorthash(bl->bytes, msg_buf, msg_len, key_buf);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::pwhash

PROTOTYPES: DISABLE

unsigned int
SALTBYTES(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_SALTBYTES;
    OUTPUT:
        RETVAL

unsigned int
STRBYTES(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_STRBYTES;
    OUTPUT:
        RETVAL

unsigned long
OPSLIMIT_INTERACTIVE(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
    OUTPUT:
        RETVAL

unsigned long
MEMLIMIT_INTERACTIVE(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
    OUTPUT:
        RETVAL

unsigned long
OPSLIMIT_SENSITIVE(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE;
    OUTPUT:
        RETVAL

unsigned long
MEMLIMIT_SENSITIVE(...)
    CODE:
        RETVAL = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
salt(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_pwhash_scryptsalsa208sha256_SALTBYTES);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


void
key(self, passphrase, salt, ... )
    SV * self
    SV * salt
    SV * passphrase
    PROTOTYPE: $$$$;%
    INIT:
        DataBytesLocker *bl;
        STRLEN pwd_len = 0;
        STRLEN salt_len = 0;
        char * pwd_buf;
        unsigned char * salt_buf;
        unsigned long long outlen = crypto_pwhash_scryptsalsa208sha256_STRBYTES;
        unsigned long long opslimit = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
        size_t memlimit = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 3 && ( ( items + 1 ) % 2 != 0  || items > 9 ) ) {
            croak("Invalid number of arguments");
        } else if ( items > 4 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 3; i < items; i += 2 ) {
                key = (char *)SvPV(ST(i), keylen);
                if ( keylen == 8 && strnEQ(key, "opslimit", 8) ) {
                    opslimit = (unsigned long long)SvUV(ST(i+1));
                    if ( opslimit < 1 ) {
                        croak("Invalid opslimit: %lld", opslimit);
                    }
                } else if ( keylen == 8 && strnEQ(key, "memlimit", 8) ) {
                    memlimit = (unsigned long long)SvUV(ST(i+1));
                    if ( memlimit < 1 ) {
                        croak("Invalid memlimit: %lld", memlimit);
                    }
                } else if ( keylen == 5 && strnEQ(key, "bytes", 5) ) {
                    outlen = (unsigned long long)SvUV(ST(i+1));
                    if ( outlen < 1 ) {
                        croak("Invalid bytes: %lld", outlen);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }

        salt_buf = (unsigned char *)SvPV(salt, salt_len);
        if ( salt_len != crypto_pwhash_scryptsalsa208sha256_SALTBYTES ) {
            croak("Invalid salt");
        }

        pwd_buf = (char *)SvPV(passphrase, pwd_len);

        bl = InitDataBytesLocker(aTHX_ outlen);
        if ( crypto_pwhash_scryptsalsa208sha256(bl->bytes, outlen, pwd_buf, pwd_len, salt_buf, opslimit, memlimit) != 0 ) {
            sodium_free( bl->bytes );
            Safefree(bl);
            croak("Out of memory");
        }

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

        XSRETURN(1);
    }


void
str(self, passphrase, ... )
    SV * self
    SV * passphrase
    PROTOTYPE: $$;%
    INIT:
        DataBytesLocker *bl;
        STRLEN pwd_len = 0;
        char * pwd_buf;
        unsigned long long opslimit = crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE;
        size_t memlimit = crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( items > 2 && ( items % 2 != 0  || items > 6 ) ) {
            croak("Invalid number of arguments");
        } else if ( items > 2 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 2; i < items; i += 2 ) {
                key = (char *)SvPV(ST(i), keylen);
                if ( keylen == 8 && strnEQ(key, "opslimit", 8) ) {
                    opslimit =  SvUV(ST(i+1));
                    if ( opslimit < 1 ) {
                        croak("Invalid opslimit: %lld", opslimit);
                    }
                } else if ( keylen == 8 && strnEQ(key, "memlimit", 8) ) {
                    memlimit =  SvUV(ST(i+1));
                    if ( memlimit < 1 ) {
                        croak("Invalid memlimit: %lld", memlimit);
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }

        pwd_buf = (char *)SvPV(passphrase, pwd_len);

        bl = InitDataBytesLocker(aTHX_ crypto_pwhash_scryptsalsa208sha256_STRBYTES);
        if ( crypto_pwhash_scryptsalsa208sha256_str((char *)bl->bytes, pwd_buf, pwd_len, opslimit, memlimit) != 0 ) {
            sodium_free( bl->bytes );
            Safefree(bl);
            croak("Out of memory");
        }
        bl->bytes[crypto_pwhash_scryptsalsa208sha256_STRBYTES] = 0;

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


SV *
verify(self, str, passphrase )
    SV * self
    SV * str
    SV * passphrase
    PROTOTYPE: $$$
    INIT:
        STRLEN str_len;
        STRLEN pwd_len;
        char * str_buf;
        char * pwd_buf;
        int res = 0;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        str_buf = (char *)SvPV(str, str_len);

        /* -1 - need to expand by single null char */
        if ( str_len == crypto_pwhash_scryptsalsa208sha256_STRBYTES - 1 ) {
            char * str102 = NULL; /* stores the terminating null byte */

            pwd_buf = (char *)SvPV(passphrase, pwd_len);

            str102 = (char *) sodium_malloc(crypto_pwhash_scryptsalsa208sha256_STRBYTES);
            if ( str102 == NULL ) {
                croak("Could not allocate memory");
            }

            memcpy(str102, str_buf, str_len);
            str102[crypto_pwhash_scryptsalsa208sha256_STRBYTES-1] = 0;

            res = crypto_pwhash_scryptsalsa208sha256_str_verify( str102, pwd_buf, pwd_len) == 0;

            sodium_free(str102);
        }
        /* already includes null byte */
        else  if ( str_len == crypto_pwhash_scryptsalsa208sha256_STRBYTES
                &&
                str_buf[crypto_pwhash_scryptsalsa208sha256_STRBYTES - 1] == 0
        ) {
            pwd_buf = (char *)SvPV(passphrase, pwd_len);

            res = crypto_pwhash_scryptsalsa208sha256_str_verify( str_buf, pwd_buf, pwd_len) == 0;
        }
        else {
            croak("Invalid string");
        }

        RETVAL = res ? &PL_sv_yes : &PL_sv_no;
    }
    OUTPUT:
        RETVAL


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::hash

PROTOTYPES: DISABLE

unsigned int
SHA256_BYTES(...)
    CODE:
        RETVAL = crypto_hash_sha256_BYTES;
    OUTPUT:
        RETVAL

unsigned int
SHA512_BYTES(...)
    CODE:
        RETVAL = crypto_hash_sha512_BYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

void
sha256(self, msg)
    SV * self
    SV * msg
    PROTOTYPE: $$
    ALIAS:
        sha512 = 1
    INIT:
        STRLEN msg_len = 0;
        unsigned char * msg_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        switch(ix) {
            case 1:
                bl = InitDataBytesLocker(aTHX_ crypto_hash_sha512_BYTES);
                crypto_hash_sha512(bl->bytes, msg_buf, msg_len);
                break;
            default:
                bl = InitDataBytesLocker(aTHX_ crypto_hash_sha256_BYTES);
                crypto_hash_sha256(bl->bytes, msg_buf, msg_len);
        }

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
sha256_init(self)
    SV * self
    PROTOTYPE: $
    INIT:
        CryptNaClSodiumHashSha256Stream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        Newx(stream, 1, CryptNaClSodiumHashSha256Stream);
        stream->state = sodium_malloc(sizeof(crypto_hash_sha256_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_hash_sha256_init(stream->state);

        ST(0) = sv_2mortal(HashSha256Stream2SV(aTHX_ stream));

        XSRETURN(1);
    }

void
sha512_init(self)
    SV * self
    PROTOTYPE: $
    INIT:
        CryptNaClSodiumHashSha512Stream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        Newx(stream, 1, CryptNaClSodiumHashSha512Stream);
        stream->state = sodium_malloc(sizeof(crypto_hash_sha512_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_hash_sha512_init(stream->state);

        ST(0) = sv_2mortal(HashSha512Stream2SV(aTHX_ stream));

        XSRETURN(1);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::hash::sha256stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha256Stream* cur_stream = GetHashSha256Stream(aTHX_ self);
    INIT:
        CryptNaClSodiumHashSha256Stream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumHashSha256Stream, hash_sha256, 0, ((void)0))
        ST(0) = sv_2mortal(HashSha256Stream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }

void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha256Stream* stream = GetHashSha256Stream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_hash_sha256_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

void
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumHashSha256Stream* stream = GetHashSha256Stream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    PPCODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_hash_sha256_BYTES);

        crypto_hash_sha256_final(stream->state, bl->bytes);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha256Stream* stream = GetHashSha256Stream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::hash::sha512stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha512Stream* cur_stream = GetHashSha512Stream(aTHX_ self);
    INIT:
        CryptNaClSodiumHashSha512Stream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumHashSha512Stream, hash_sha512, 0, ((void)0))
        ST(0) = sv_2mortal(HashSha512Stream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }

void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha512Stream* stream = GetHashSha512Stream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_hash_sha512_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

void
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumHashSha512Stream* stream = GetHashSha512Stream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    PPCODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_hash_sha512_BYTES);

        crypto_hash_sha512_final(stream->state, bl->bytes);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumHashSha512Stream* stream = GetHashSha512Stream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::onetimeauth

PROTOTYPES: DISABLE

unsigned int
BYTES(...)
    CODE:
        RETVAL = crypto_onetimeauth_BYTES;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_onetimeauth_KEYBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_onetimeauth_KEYBYTES);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


void
mac(self, msg, key)
    SV * self
    SV * msg
    SV * key
    PROTOTYPE: $$$
    INIT:
        STRLEN msg_len;
        STRLEN key_len;
        unsigned char * msg_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_onetimeauth_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ crypto_onetimeauth_BYTES);
        crypto_onetimeauth(bl->bytes, msg_buf, msg_len, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
verify(self, mac, msg, key)
    SV * self
    SV * mac
    SV * msg
    SV * key
    PROTOTYPE: $$$$
    INIT:
        STRLEN msg_len;
        STRLEN key_len;
        STRLEN mac_len;
        unsigned char * msg_buf;
        unsigned char * mac_buf;
        unsigned char * key_buf;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        mac_buf = (unsigned char *)SvPV(mac, mac_len);
        if ( mac_len != crypto_onetimeauth_BYTES ) {
            croak("Invalid mac");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_onetimeauth_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        if ( crypto_onetimeauth_verify( mac_buf, msg_buf, msg_len, key_buf) == 0 ) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }


void
init(self, key)
    SV * self
    SV * key
    PROTOTYPE: $;%
    INIT:
        STRLEN key_len;
        unsigned char * key_buf;
        CryptNaClSodiumOnetimeauthStream *stream;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_onetimeauth_KEYBYTES ) {
            croak("Invalid key");
        }

        Newx(stream, 1, CryptNaClSodiumOnetimeauthStream);
        stream->state = sodium_malloc(sizeof(crypto_onetimeauth_state));
        if ( stream->state == NULL ) {
            croak("Could not allocate memory");
        }

        crypto_onetimeauth_init(stream->state, key_buf);

        ST(0) = sv_2mortal(OnetimeauthStream2SV(aTHX_ stream));

        XSRETURN(1);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::onetimeauth::stream

void
clone(self)
    SV * self
    PREINIT:
        CryptNaClSodiumOnetimeauthStream* cur_stream = GetOnetimeauthStream(aTHX_ self);
    INIT:
        CryptNaClSodiumOnetimeauthStream* new_stream;
    PPCODE:
    {
        CLONESTATE(CryptNaClSodiumOnetimeauthStream, onetimeauth, 0, ((void)0))
        ST(0) = sv_2mortal(OnetimeauthStream2SV(aTHX_ new_stream));
        XSRETURN(1);
    }


void
update(self, ...)
    SV * self
    PREINIT:
        CryptNaClSodiumOnetimeauthStream* stream = GetOnetimeauthStream(aTHX_ self);
    INIT:
        STRLEN msg_len;
        unsigned char * msg_buf;
        int i;
    PPCODE:
    {
        for ( i = 1; i < items ; i++ ) {
            msg_buf = (unsigned char *)SvPV(ST(i), msg_len);

            crypto_onetimeauth_update(stream->state, msg_buf, msg_len);
        }

        XSRETURN(1);
    }

void
final(self)
    SV * self
    PROTOTYPE: $
    PREINIT:
        CryptNaClSodiumOnetimeauthStream* stream = GetOnetimeauthStream(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    PPCODE:
    {
        bl = InitDataBytesLocker(aTHX_ crypto_onetimeauth_BYTES);

        crypto_onetimeauth_final(stream->state, bl->bytes);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
DESTROY(self)
    SV * self
    PREINIT:
        CryptNaClSodiumOnetimeauthStream* stream = GetOnetimeauthStream(aTHX_ self);
    PPCODE:
    {
        sodium_free( stream->state );
        Safefree(stream);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::scalarmult

PROTOTYPES: DISABLE

unsigned int
BYTES(...)
    CODE:
        RETVAL = crypto_scalarmult_BYTES;
    OUTPUT:
        RETVAL


unsigned int
SCALARBYTES(...)
    CODE:
        RETVAL = crypto_scalarmult_SCALARBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        bl = InitDataBytesLocker(aTHX_ crypto_scalarmult_SCALARBYTES);

        randombytes_buf(bl->bytes, bl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
base(self, secret_key)
    SV * self
    SV * secret_key
    PROTOTYPE: $$
    INIT:
        STRLEN key_len;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        key_buf = (unsigned char *)SvPV(secret_key, key_len);
        if ( key_len != crypto_scalarmult_SCALARBYTES ) {
            croak("Invalid key");
        }

        bl = InitDataBytesLocker(aTHX_ crypto_scalarmult_BYTES);
        crypto_scalarmult_base( bl->bytes, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


void
shared_secret(self, secret_key, public_key)
    SV * self
    SV * secret_key
    SV * public_key
    PROTOTYPE: $$$$
    INIT:
        STRLEN skey_len;
        STRLEN pkey_len;
        unsigned char * skey_buf;
        unsigned char * pkey_buf;

        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        skey_buf = (unsigned char *)SvPV(secret_key, skey_len);
        if ( skey_len != crypto_scalarmult_SCALARBYTES ) {
            croak("Invalid secret key");
        }

        pkey_buf = (unsigned char *)SvPV(public_key, pkey_len);
        if ( pkey_len != crypto_scalarmult_SCALARBYTES ) {
            croak("Invalid public key");
        }

        bl = InitDataBytesLocker(aTHX_ crypto_scalarmult_BYTES);

        if ( crypto_scalarmult( bl->bytes, skey_buf, pkey_buf) != 0 ) {
            sodium_free(bl->bytes);
            Safefree(bl);
            croak("Failed to calculate shared secret");
        }

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


MODULE = Crypt::NaCl::Sodium        PACKAGE = Crypt::NaCl::Sodium::stream

PROTOTYPES: DISABLE

unsigned int
NONCEBYTES(...)
    CODE:
        RETVAL = crypto_stream_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
KEYBYTES(...)
    CODE:
        RETVAL = crypto_stream_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
CHACHA20_NONCEBYTES(...)
    CODE:
        RETVAL = crypto_stream_chacha20_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
CHACHA20_IETF_NONCEBYTES(...)
    CODE:
        RETVAL = crypto_stream_chacha20_IETF_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
CHACHA20_KEYBYTES(...)
    CODE:
        RETVAL = crypto_stream_chacha20_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
SALSA20_NONCEBYTES(...)
    CODE:
        RETVAL = crypto_stream_salsa20_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
SALSA20_KEYBYTES(...)
    CODE:
        RETVAL = crypto_stream_salsa20_KEYBYTES;
    OUTPUT:
        RETVAL

unsigned int
AES128CTR_NONCEBYTES(...)
    CODE:
        RETVAL = crypto_stream_aes128ctr_NONCEBYTES;
    OUTPUT:
        RETVAL

unsigned int
AES128CTR_KEYBYTES(...)
    CODE:
        RETVAL = crypto_stream_aes128ctr_KEYBYTES;
    OUTPUT:
        RETVAL

PROTOTYPES: ENABLE

SV *
keygen(self)
    SV * self
    ALIAS:
        chacha20_keygen = 1
        salsa20_keygen = 2
        aes128ctr_keygen = 3
    INIT:
        unsigned int key_size;
        DataBytesLocker *bl;
    CODE:
    {
        PERL_UNUSED_VAR(self);

        switch(ix) {
            case 1:
                key_size = crypto_stream_chacha20_KEYBYTES;
                break;
            case 2:
                key_size = crypto_stream_salsa20_KEYBYTES;
                break;
            case 3:
                key_size = crypto_stream_aes128ctr_KEYBYTES;
                break;
            default:
                key_size = crypto_stream_KEYBYTES;
        }
        bl = InitDataBytesLocker(aTHX_ key_size);
        randombytes_buf(bl->bytes, key_size);
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
nonce(self, ...)
    SV * self
    PROTOTYPE: $;$
    ALIAS:
        chacha20_nonce = 1
        salsa20_nonce = 2
        aes128ctr_nonce = 3
        chacha20_ietf_nonce = 4
    INIT:
        unsigned int nonce_size;
        DataBytesLocker *bl;
    CODE:
        PERL_UNUSED_VAR(self);

        switch(ix) {
            case 1:
                nonce_size = crypto_stream_chacha20_NONCEBYTES;
                break;
            case 2:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                break;
            case 3:
                nonce_size = crypto_stream_aes128ctr_NONCEBYTES;
                break;
            case 4:
                nonce_size = crypto_stream_chacha20_IETF_NONCEBYTES;
                break;
            default:
                nonce_size = crypto_stream_NONCEBYTES;
        }

        if ( items > 2 ) {
            croak("Invalid number of arguments");
        }

        if (items == 2 ) {
            if ( SvOK(ST(1)) ) {
                STRLEN prev_nonce_len;
                unsigned char * prev_nonce = (unsigned char *)SvPV(ST(1), prev_nonce_len);

                if ( prev_nonce_len > nonce_size ) {
                    croak("Base nonce too long");
                }

                bl = InitDataBytesLocker(aTHX_ nonce_size);
                memcpy(bl->bytes, prev_nonce, prev_nonce_len);
                sodium_memzero(bl->bytes + prev_nonce_len, bl->length - prev_nonce_len);
            }
            else {
                croak("Base nonce invalid");
            }
        }
        else {
            bl = InitDataBytesLocker(aTHX_ nonce_size);
            randombytes_buf(bl->bytes, bl->length);
        }
        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    OUTPUT:
        RETVAL


void
bytes(self, length, nonce, key)
    SV * self
    SV * length
    SV * nonce
    SV * key
    ALIAS:
        chacha20_bytes = 1
        salsa20_bytes = 2
        aes128ctr_bytes = 3
        salsa2012_bytes = 4
        salsa208_bytes = 5
        chacha20_ietf_bytes = 6
    INIT:
        STRLEN nonce_len;
        STRLEN key_len;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned int nonce_size;
        unsigned int key_size;
        unsigned int bytes_len;
        int (*bytes_function)(unsigned char *, unsigned long long, const unsigned char *, const unsigned char *);
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                nonce_size = crypto_stream_chacha20_NONCEBYTES;
                key_size = crypto_stream_chacha20_KEYBYTES;
                bytes_function = &crypto_stream_chacha20;
                break;
            case 2:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                bytes_function = &crypto_stream_salsa20;
                break;
            case 3:
                nonce_size = crypto_stream_aes128ctr_NONCEBYTES;
                key_size = crypto_stream_aes128ctr_KEYBYTES;
                bytes_function = &crypto_stream_aes128ctr;
                break;
            case 4:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                bytes_function = &crypto_stream_salsa2012;
                break;
            case 5:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                bytes_function = &crypto_stream_salsa208;
                break;
            case 6:
                nonce_size = crypto_stream_chacha20_IETF_NONCEBYTES;
                key_size = crypto_stream_chacha20_KEYBYTES;
                bytes_function = &crypto_stream_chacha20_ietf;
                break;
            default:
                nonce_size = crypto_stream_NONCEBYTES;
                key_size = crypto_stream_KEYBYTES;
                bytes_function = &crypto_stream;
        }

        bytes_len = SvUV(length);

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != nonce_size ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        bl = InitDataBytesLocker(aTHX_ bytes_len);

        (*bytes_function)( bl->bytes, bytes_len, nonce_buf, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


void
xor(self, msg, nonce, key)
    SV * self
    SV * msg
    SV * nonce
    SV * key
    ALIAS:
        chacha20_xor = 1
        salsa20_xor = 2
        aes128ctr_xor = 3
        salsa2012_xor = 4
        salsa208_xor = 5
        chacha20_ietf_xor = 6
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        STRLEN key_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned int nonce_size;
        unsigned int key_size;
        int (*xor_function)(unsigned char *, const unsigned char *, unsigned long long, const unsigned char *, const unsigned char *);
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                nonce_size = crypto_stream_chacha20_NONCEBYTES;
                key_size = crypto_stream_chacha20_KEYBYTES;
                xor_function = &crypto_stream_chacha20_xor;
                break;
            case 2:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                xor_function = &crypto_stream_salsa20_xor;
                break;
            case 3:
                nonce_size = crypto_stream_aes128ctr_NONCEBYTES;
                key_size = crypto_stream_aes128ctr_KEYBYTES;
                xor_function = &crypto_stream_aes128ctr_xor;
                break;
            case 4:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                xor_function = &crypto_stream_salsa2012_xor;
                break;
            case 5:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                xor_function = &crypto_stream_salsa208_xor;
                break;
            case 6:
                nonce_size = crypto_stream_chacha20_IETF_NONCEBYTES;
                key_size = crypto_stream_chacha20_KEYBYTES;
                xor_function = &crypto_stream_chacha20_ietf_xor;
                break;
            default:
                nonce_size = crypto_stream_NONCEBYTES;
                key_size = crypto_stream_KEYBYTES;
                xor_function = &crypto_stream_xor;
        }

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != nonce_size ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);

        (*xor_function)( bl->bytes, msg_buf, msg_len, nonce_buf, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }


void
xor_ic(self, msg, nonce, ic, key)
    SV * self
    SV * msg
    SV * nonce
    SV * ic
    SV * key
    ALIAS:
        chacha20_xor_ic = 1
        salsa20_xor_ic = 2
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        unsigned int bc;
        STRLEN key_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        unsigned int nonce_size;
        unsigned int key_size;
        int (*xor_ic_function)(unsigned char *, const unsigned char *, unsigned long long, const unsigned char *, uint64_t, const unsigned char *);
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        switch(ix) {
            case 1:
                nonce_size = crypto_stream_chacha20_NONCEBYTES;
                key_size = crypto_stream_chacha20_KEYBYTES;
                xor_ic_function = &crypto_stream_chacha20_xor_ic;
                break;
            case 2:
                nonce_size = crypto_stream_salsa20_NONCEBYTES;
                key_size = crypto_stream_salsa20_KEYBYTES;
                xor_ic_function = &crypto_stream_salsa20_xor_ic;
                break;
            default:
                nonce_size = crypto_stream_NONCEBYTES;
                key_size = crypto_stream_KEYBYTES;
                xor_ic_function = &crypto_stream_xsalsa20_xor_ic;
        }

        bc = SvUV(ic);

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != nonce_size ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != key_size ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);

        (*xor_ic_function)( bl->bytes, msg_buf, msg_len, nonce_buf, bc, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

void
chacha20_ietf_xor_ic(self, msg, nonce, ic, key)
    SV * self
    SV * msg
    SV * nonce
    SV * ic
    SV * key
    INIT:
        STRLEN msg_len;
        STRLEN nonce_len;
        unsigned int bc;
        STRLEN key_len;
        unsigned char * msg_buf;
        unsigned char * nonce_buf;
        unsigned char * key_buf;
        DataBytesLocker *bl;
    PPCODE:
    {
        PERL_UNUSED_VAR(self);

        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        bc = SvUV(ic);

        nonce_buf = (unsigned char *)SvPV(nonce, nonce_len);
        if ( nonce_len != crypto_stream_chacha20_IETF_NONCEBYTES ) {
            croak("Invalid nonce");
        }

        key_buf = (unsigned char *)SvPV(key, key_len);
        if ( key_len != crypto_stream_chacha20_KEYBYTES ) {
            croak("Invalid key");
        }

        msg_buf = (unsigned char *)SvPV(msg, msg_len);

        bl = InitDataBytesLocker(aTHX_ msg_len);

        crypto_stream_chacha20_ietf_xor_ic( bl->bytes, msg_buf, msg_len, nonce_buf, bc, key_buf);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );
        XSRETURN(1);
    }

MODULE = Crypt::NaCl::Sodium        PACKAGE = Data::BytesLocker

FALLBACK: FALSE

SV *
new(class, bytes, ...)
    SV * class
    SV * bytes
    PROTOTYPE: $$;%
    INIT:
        DataBytesLocker *bl;
        unsigned char *buf;
        STRLEN buf_len;
        int wipe = 0;
        int readonly = 0;
    CODE:
    {
        if ( SvREADONLY(bytes) ) {
            buf = (unsigned char *)SvPV(bytes, buf_len);
            readonly = 1;
        } else {
            buf = (unsigned char *)SvPV_force(bytes, buf_len);
        }

        if ( items > 2 && items != 4 ) {
            croak("Invalid number of arguments");
        } else if ( items > 2 ) {
            int i = 0;
            STRLEN keylen = 0;
            char * key;

            for ( i = 2; i < items; i += 2 ) {
                key = SvPV(ST(i), keylen);
                if ( keylen == 4 && strnEQ(key, "wipe", 4) ) {
                    wipe = SvTRUE(ST(i+1));
                    if ( wipe && readonly ) {
                        croak("Modification of a read-only value attempted");
                    }
                } else {
                    croak("Invalid argument: %s", key);
                }
            }
        }

        bl = InitDataBytesLocker(aTHX_ buf_len);
        memcpy(bl->bytes, buf, buf_len);

        if ( wipe ) {
            sodium_memzero( buf, buf_len);
        }

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

SV *
_overload_mult(self, other, swapped)
    SV * self
    SV * other
    SV * swapped
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
        unsigned int count = 0;
        unsigned int cur = 0;
    OVERLOAD: x
    CODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        count = SvUV(other);

        bl = InitDataBytesLocker(aTHX_ sbl->length * count);

        while(count--) {
            memcpy(bl->bytes + sbl->length * cur++, sbl->bytes, sbl->length);
        }

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL


SV *
_overload_concat(self, other, swapped)
    SV * self
    SV * other
    SV * swapped
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char *buf;
        STRLEN buf_len;
        DataBytesLocker *bl;
    OVERLOAD: .
    CODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        buf = (unsigned char *)SvPV(other, buf_len);

        bl = InitDataBytesLocker(aTHX_ sbl->length + buf_len);

        if ( SvTRUE(swapped) ) {
            memcpy(memcpy(bl->bytes, buf, buf_len) + buf_len, sbl->bytes, sbl->length);
        }
        else {
            memcpy(memcpy(bl->bytes, sbl->bytes, sbl->length) + sbl->length, buf, buf_len);
        }

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
_overload_bool(self, ...)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        int res;
    OVERLOAD: bool
    PPCODE:
    {

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if ( sbl->length ) {
            res = 1;
        } else {
            res = 0;
        }

        if ( res ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

void
_overload_not(self, ...)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        int res;
    OVERLOAD: !
    PPCODE:
    {

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if ( sbl->length ) {
            res = 0;
        } else {
            res = 1;
        }

        if ( res ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

void
_overload_eq(self, other, swapped)
    SV * self
    SV * other
    SV * swapped
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char *buf;
        STRLEN buf_len;
        int res;
    OVERLOAD: eq
    PPCODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        buf = (unsigned char *)SvPV(other, buf_len);

        if ( sbl->length != buf_len ) {
            croak("Variables of unequal length cannot be automatically compared. Please use memcmp() with the length argument provided");
        }

        if ( sodium_memcmp(sbl->bytes, buf, sbl->length) == 0 ) {
            res = 1;
        } else {
            res = 0;
        }

        if ( res ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


void
_overload_ne(self, other, swapped)
    SV * self
    SV * other
    SV * swapped
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char *buf;
        STRLEN buf_len;
        int res;
    OVERLOAD: ne
    PPCODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        buf = (unsigned char *)SvPV(other, buf_len);

        if ( sbl->length != buf_len ) {
            croak("Variables of unequal length cannot be automatically compared. Please use memcmp() with the length argument provided");
        }

        if ( sodium_memcmp(sbl->bytes, buf, sbl->length) == 0 ) {
            res = 0;
        } else {
            res = 1;
        }

        if ( res ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

void
_overload_str(self, ...)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        SV * pv;
    OVERLOAD: \"\"
    PPCODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        pv = newSVpvn((unsigned char *)sbl->bytes, sbl->length);
        SvREADONLY_on(pv);

        mXPUSHs(pv);
    }

void
_overload_nomethod(self, ...)
    SV * self
    OVERLOAD: nomethod
    INIT:
        char * operator;
    PPCODE:
    {
        operator = SvPV_nolen(ST(3));
        croak("Operation \"%s\" is not supported", operator);
    }

SV *
clone(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        DataBytesLocker *bl;
    CODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        bl = InitDataBytesLocker(aTHX_ sbl->length);

        memcpy(bl->bytes, sbl->bytes, sbl->length);

        RETVAL = DataBytesLocker2SV(aTHX_ bl);
    }
    OUTPUT:
        RETVAL

void
lock(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        int rc;
    PPCODE:
    {
        rc = sodium_mprotect_noaccess((void *)sbl->bytes);

        if (rc == 0 ) {
            sbl->locked = 1;
            XSRETURN_YES;
        }

        croak("Unable to lock memory: %s", Strerror(errno));
    }

void
unlock(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        int rc;
    PPCODE:
    {
        rc = sodium_mprotect_readonly((void *)sbl->bytes);

        if (rc == 0 ) {
            sbl->locked = 0;
            XSRETURN_YES;
        }

        croak("Unable to unlock memory: %s", Strerror(errno));
    }

SV *
length(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    CODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        RETVAL = newSVuv((UV)sbl->length);
    }
    OUTPUT:
        RETVAL

void
is_locked(self, ...)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    PPCODE:
    {
        if ( sbl->locked ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

SV *
to_hex(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        char * hex;
        size_t hex_len;
    CODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        hex_len = sbl->length * 2;
        hex = sodium_malloc(hex_len + 1);
        if ( hex == NULL ) {
            croak("Could not allocate memory");
        }
        sodium_bin2hex(hex, hex_len + 1, sbl->bytes, sbl->length);

        RETVAL = newSVpvn((const char * const)hex, hex_len);
    }
    OUTPUT:
        RETVAL
    CLEANUP:
        sodium_free(hex);

void
bytes(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        SV * pv;
    PPCODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        pv = newSVpvn((unsigned char *)sbl->bytes, sbl->length);

        mXPUSHs(pv);
    }

void
memcmp(self, bytes, length = 0)
    SV * self
    SV * bytes
    unsigned long length
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char * bytes_buf;
        STRLEN bytes_len;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if (sv_derived_from(bytes, "Data::BytesLocker")) {
            DataBytesLocker* rbl = GetBytesLocker(aTHX_ bytes);
            if ( rbl->locked ) {
                croak("Unlock BytesLocker object before accessing the data");
            }
            bytes_buf = rbl->bytes;
            bytes_len = rbl->length;
        }
        else {
            bytes_buf = (unsigned char *)SvPV(bytes, bytes_len);
        }

        if ( length == 0 ) {
            if ( sbl->length != bytes_len ) {
                croak("Variables of unequal length cannot be automatically compared. Please provide the length argument");
            }
            length = bytes_len;
        } else {
            if ( length > sbl->length ) {
                croak("The data is shorter then requested length");
            }
            else if ( length > bytes_len ) {
                croak("The argument is shorter then requested length");
            }
        }

        if ( sodium_memcmp(sbl->bytes, bytes_buf, length) == 0 ) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


void
compare(self, num, length = 0)
    SV * self
    SV * num
    unsigned long length
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char * num_buf;
        STRLEN num_len;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if (sv_derived_from(num, "Data::BytesLocker")) {
            DataBytesLocker* rbl = GetBytesLocker(aTHX_ num);
            if ( rbl->locked ) {
                croak("Unlock BytesLocker object before accessing the data");
            }
            num_buf = rbl->bytes;
            num_len = rbl->length;
        }
        else {
            num_buf = (unsigned char *)SvPV(num, num_len);
        }

        if ( length == 0 ) {
            if ( sbl->length != num_len ) {
                croak("Variables of unequal length cannot be automatically compared. Please provide the length argument");
            }
            length = num_len;
        } else {
            if ( length > sbl->length ) {
                croak("The data is shorter then requested length");
            }
            else if ( length > num_len ) {
                croak("The argument is shorter then requested length");
            }
        }

        XSRETURN_IV( sodium_compare(sbl->bytes, num_buf, length) );
    }

void
increment(self)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        SV * pv;
        DataBytesLocker *bl;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        bl = InitDataBytesLocker(aTHX_ sbl->length);

        memcpy(bl->bytes, sbl->bytes, sbl->length);

        sodium_increment(bl->bytes, sbl->length);

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

        XSRETURN(1);
    }

void
add(self, num, ...)
    SV * self
    SV * num
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        unsigned char * num_buf;
        STRLEN num_len;
        STRLEN inc_len;
        DataBytesLocker *bl;
    PPCODE:
    {
        if ( GIMME_V == G_VOID ) {
            XSRETURN_EMPTY;
        }

        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if (sv_derived_from(num, "Data::BytesLocker")) {
            DataBytesLocker* rbl = GetBytesLocker(aTHX_ num);
            if ( rbl->locked ) {
                croak("Unlock BytesLocker object before accessing the data");
            }
            num_buf = rbl->bytes;
            num_len = rbl->length;
        }
        else {
            num_buf = (unsigned char *)SvPV(num, num_len);
        }

        if ( items == 3 ) {
            inc_len = (STRLEN)SvUV(ST(2));
            if ( inc_len > sbl->length ) {
                croak("The data is shorter then requested length");
            }
            else if ( inc_len > num_len ) {
                croak("The argument is shorter then requested length");
            }
        } else {
            if ( sbl->length != num_len ) {
                croak("Length of argument has to be equal to the length of data. Please provide the length argument");
            }
            inc_len = num_len;
        }

        bl = InitDataBytesLocker(aTHX_ sbl->length);

        memcpy(bl->bytes, sbl->bytes, sbl->length);

        sodium_add( bl->bytes, num_buf, inc_len );

        mXPUSHs( DataBytesLocker2SV(aTHX_ bl) );

        XSRETURN(1);
    }

void
is_zero(self, ...)
    SV * self
    PREINIT:
        DataBytesLocker* sbl = GetBytesLocker(aTHX_ self);
    INIT:
        SV * pv;
    PPCODE:
    {
        if ( sbl->locked ) {
            croak("Unlock BytesLocker object before accessing the data");
        }

        if ( sodium_is_zero(sbl->bytes, sbl->length) == 1 ) {
            XSRETURN_YES;
        }
        XSRETURN_NO;
    }


void
DESTROY(self)
    SV * self
    PREINIT:
        DataBytesLocker* bl = GetBytesLocker(aTHX_ self);
    PPCODE:
    {
        sodium_free( bl->bytes );
        Safefree(bl);
    }

