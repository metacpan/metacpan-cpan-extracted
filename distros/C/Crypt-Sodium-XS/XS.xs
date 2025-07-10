#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"
#include "ppport.h"

#if defined(__unix__) || (defined(__APPLE__) && defined(__MACH__)) || defined(__HAIKU__)
#include <sys/types.h>
#endif
#include <limits.h>
#include <stdio.h>
#include <string.h>
#if defined(__unix__) || (defined(__APPLE__) && defined(__MACH__)) || defined(__HAIKU__)
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <termios.h>
#include <unistd.h>
#elif defined(_WIN32)
/* windows is completely untested. */
#include <windows.h>
#endif
#ifndef TCSAFLUSH
#define TCSAFLUSH 0
#endif

#include "sodium.h"

/* likely needs backing off and preprocessor around supported features. "for
 * now"... */
#if (SODIUM_LIBRARY_VERSION_MAJOR < 10U)
#error "libsodium library is not compatible (version too old)"
#endif
#if (SODIUM_LIBRARY_VERSION_MAJOR == 10U) && (SODIUM_LIBRARY_VERSION_MINOR < 3U)
#error "libsodium library is not compatible (version too old)"
#endif

#undef SODIUM_HAS_AEGIS
#if (SODIUM_LIBRARY_VERSION_MAJOR > 26U) || \
    ((SODIUM_LIBRARY_VERSION_MAJOR == 26U) && (SODIUM_LIBRARY_VERSION_MINOR >= 1U))
#define SODIUM_HAS_AEGIS 1U
#endif

#undef SODIUM_HAS_HKDF
#if (SODIUM_LIBRARY_VERSION_MAJOR > 26U) || \
    ((SODIUM_LIBRARY_VERSION_MAJOR == 26U) && (SODIUM_LIBRARY_VERSION_MINOR >= 1U))
#define SODIUM_HAS_HKDF 1U
#endif

/* 00000011 */
#define PROTMEM_FLAG_MPROTECT_MASK 0x3U
#define PROTMEM_FLAG_MPROTECT_NOACCESS 0U
#define PROTMEM_FLAG_MPROTECT_RO 0x1U
/* WR unused (no sodium_mprotect_writeonly), just for completeness */
#define PROTMEM_FLAG_MPROTECT_WR 0x2U
#define PROTMEM_FLAG_MPROTECT_RW 0x3U

/* 00000100 reserved */

/* 00011000 */
#define PROTMEM_FLAG_MLOCK_MASK 0x24U
#define PROTMEM_FLAG_MLOCK_STRICT 0U
#define PROTMEM_FLAG_MLOCK_PERMISSIVE 0x8U
#define PROTMEM_FLAG_MLOCK_NONE 0x24U

/* 00100000 */
#define PROTMEM_FLAG_LOCK_MASK 0x20U
#define PROTMEM_FLAG_LOCK_LOCKED 0U
#define PROTMEM_FLAG_LOCK_UNLOCKED 0x20U

/* 01000000 */
#define PROTMEM_FLAG_MEMZERO_MASK 0x40U
#define PROTMEM_FLAG_MEMZERO_ENABLED 0U
#define PROTMEM_FLAG_MEMZERO_DISABLED 0x40U

/* 10000000 */
#define PROTMEM_FLAG_MALLOC_MASK 0x80U
#define PROTMEM_FLAG_MALLOC_SODIUM 0U
#define PROTMEM_FLAG_MALLOC_PLAIN 0x80U

#define PROTMEM_FLAG_ALL_DISABLED 0xffffffffU
#define PROTMEM_FLAG_ALL_ENABLED 0x0U

#define MEMVAULT_READ_BUFSIZE 4096U
#define MEMVAULT_WRITE_BUFSIZE 4096U

#define MEMVAULT_CLASS ("Crypt::Sodium::XS::MemVault")

#define SODIUM_MALLOC(size) (sodium_malloc(((size) + (size_t)63U) & ~(size_t)63U))

static unsigned int
g_protmem_flags_state_default = PROTMEM_FLAG_MPROTECT_NOACCESS
                              | PROTMEM_FLAG_MLOCK_STRICT;

static unsigned int
g_protmem_flags_memvault_default = PROTMEM_FLAG_MPROTECT_NOACCESS
                              | PROTMEM_FLAG_MLOCK_STRICT
                              | PROTMEM_FLAG_LOCK_LOCKED;
static unsigned int
g_protmem_flags_key_default = PROTMEM_FLAG_MPROTECT_NOACCESS
                                  | PROTMEM_FLAG_MLOCK_STRICT
                                  | PROTMEM_FLAG_LOCK_LOCKED;
static unsigned int
g_protmem_flags_decrypt_default = PROTMEM_FLAG_MPROTECT_NOACCESS
                                      | PROTMEM_FLAG_MLOCK_STRICT
                                      | PROTMEM_FLAG_LOCK_LOCKED;

static int has_aes256gcm;

typedef struct {
  void *pm_ptr;
  size_t size;
  unsigned int flags;
} protmem;

static void protmem_free(pTHX_ protmem *pm) {
  if (pm == NULL)
    return;
  if (pm->flags & PROTMEM_FLAG_MALLOC_PLAIN) {
    if (!(pm->flags & PROTMEM_FLAG_MEMZERO_DISABLED))
      sodium_memzero(pm->pm_ptr, pm->size);
    safefree(pm->pm_ptr);
  }
  else
    sodium_free(pm->pm_ptr);
  safefree(pm);
}

static protmem * protmem_clone(pTHX_ protmem *cur_pm, size_t new_size) {
  protmem *new_pm;

  if (cur_pm == NULL)
    return NULL;
  new_pm = safemalloc(sizeof(protmem));
  if (new_pm == NULL)
    return NULL;
  if (cur_pm->flags & PROTMEM_FLAG_MALLOC_PLAIN)
    new_pm->pm_ptr = safemalloc(new_size);
  else
    new_pm->pm_ptr = SODIUM_MALLOC(new_size);
  if (new_pm->pm_ptr == NULL) {
    safefree(new_pm);
    return NULL;
  }
  new_pm->size = new_size;
  new_pm->flags = cur_pm->flags;
  /* flags is set, but caller must still mpstate_access_release! */
  if (!(new_pm->flags & PROTMEM_FLAG_MLOCK_PERMISSIVE)
      && !(new_pm->flags & PROTMEM_FLAG_MALLOC_PLAIN)) {
    if (sodium_mlock(new_pm->pm_ptr, new_size) != 0) {
      protmem_free(aTHX_ new_pm);
      warn("protmem_clone: mlock failed\n");
      return NULL;
    }
  }
  if (new_pm->flags & PROTMEM_FLAG_MLOCK_NONE
      && !(new_pm->flags & PROTMEM_FLAG_MALLOC_PLAIN))
    sodium_munlock(new_pm->pm_ptr, new_size);
    /* ignoring failure */
  memcpy(new_pm->pm_ptr, cur_pm->pm_ptr,
         new_size > cur_pm->size ? cur_pm->size : new_size);

  return new_pm;
}

static int protmem_grant(pTHX_ protmem *pm, int flags) {
  int pm_flags;
  if (pm == NULL)
    return -1;
  pm_flags = pm->flags;
  if (pm_flags & PROTMEM_FLAG_MALLOC_PLAIN)
    return 0;
  pm_flags &= PROTMEM_FLAG_MPROTECT_MASK;
  flags &= PROTMEM_FLAG_MPROTECT_MASK;
  if (flags <= pm_flags)
    return 0;
  switch(flags) {
    case PROTMEM_FLAG_MPROTECT_RW:
      return sodium_mprotect_readwrite(pm->pm_ptr);
    case PROTMEM_FLAG_MPROTECT_RO:
      return sodium_mprotect_readonly(pm->pm_ptr);
  }
  return -1;
}

static int protmem_release(pTHX_ protmem *pm, int flags) {
  int pm_flags;
  if (pm == NULL)
    return -1;
  pm_flags = pm->flags;
  if (pm_flags & PROTMEM_FLAG_MALLOC_PLAIN)
    return 0;
  pm_flags &= PROTMEM_FLAG_MPROTECT_MASK;
  flags &= PROTMEM_FLAG_MPROTECT_MASK;
  if (flags <= pm_flags)
    return 0;
  switch(pm_flags) {
    case PROTMEM_FLAG_MPROTECT_RO:
      return sodium_mprotect_readonly(pm->pm_ptr);
    case PROTMEM_FLAG_MPROTECT_NOACCESS:
      return sodium_mprotect_noaccess(pm->pm_ptr);
  }
  return -1;
}

#if defined(USE_ITHREADS) && defined(MGf_DUP)
STATIC int dup_protmem(pTHX_ MAGIC *mg, CLONE_PARAMS *params) {
  protmem *new_pm;
  protmem *cur_pm;
  PERL_UNUSED_VAR(params);
  cur_pm = (protmem *)mg->mg_ptr;

  if (protmem_grant(aTHX_ cur_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("Failed to grant protmem RO");

  new_pm = protmem_clone(aTHX_ cur_pm, cur_pm->size);
  if (new_pm == NULL)
    croak("Failed to clone protmem");

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("Failed to release new protmem RW");
  }

  if (protmem_release(aTHX_ cur_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("Failed to release protmem RO");
  }

  mg->mg_ptr = (char *)new_pm;
  return 0;
}
#endif
STATIC MGVTBL vtbl_protmem = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#ifdef MGf_COPY
    NULL, /* copy */
#endif
#ifdef MGf_DUP
#  ifdef USE_ITHREADS
    dup_protmem,
#  else
    NULL, /* dup */
#  endif
#endif
#ifdef MGf_LOCAL
    NULL /* local */
#endif
};

/* returns NULL on failure */
static protmem * protmem_init(pTHX_ STRLEN size, int flags) {
  protmem *pm;

  pm = safemalloc(sizeof(protmem));
  if (pm == NULL)
    return NULL;

  pm->flags = flags;
  if (flags & PROTMEM_FLAG_MALLOC_PLAIN)
    pm->pm_ptr = safemalloc(size);
  else
    pm->pm_ptr = SODIUM_MALLOC(size);
  if (pm->pm_ptr == NULL) {
    safefree(pm);
    return NULL;
  }
  pm->size = size;
  if (!(flags & PROTMEM_FLAG_MLOCK_PERMISSIVE)
      && !(flags & PROTMEM_FLAG_MALLOC_PLAIN)) {
    if (sodium_mlock(pm->pm_ptr, size) != 0) {
      warn("protmem_init: mlock failed.\n");
      protmem_free(aTHX_ pm);
      return NULL;
    }
  }
  if (flags & PROTMEM_FLAG_MLOCK_NONE && !(flags & PROTMEM_FLAG_MALLOC_PLAIN))
    sodium_munlock(pm->pm_ptr, size);
    /* ignoring failure */

  return pm;
}

/* NB: croaks on failure */
static protmem * protmem_get(pTHX_ SV *sv, const char *sv_pkg) {
  MAGIC *mg;

  if (!sv_derived_from(sv, sv_pkg))
    croak("Not a reference to a %s object", sv_pkg);

  for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
    if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_protmem)
      return (protmem *)mg->mg_ptr;

  croak("Failed to get %s pointer", sv_pkg);
  return NULL;
}

static SV * protmem_to_sv(pTHX_ protmem *pm, const char *sv_pkg) {
  SV *sv = newSV(0);
  SV *obj = newRV_noinc(sv);
#ifdef USE_ITHREADS
  MAGIC *mg;
#endif

  sv_bless(obj, gv_stashpv(sv_pkg, GV_ADD));

#ifdef USE_ITHREADS
  mg =
#endif
  sv_magicext(sv, NULL, PERL_MAGIC_ext, &vtbl_protmem, (const char *)pm, 0);

#if defined(USE_ITHREADS) && defined(MGf_DUP)
  mg->mg_flags |= MGf_DUP;
#endif

  return obj;
}

/* NB: croaks on failure */
/* XXX: does this really need to be able to clone into a different package? */
static SV * protmem_clone_sv(pTHX_ SV *pm_sv, const char *sv_pkg) {
  protmem *new_pm;
  protmem *cur_pm = protmem_get(aTHX_ pm_sv, sv_pkg);

  if (protmem_grant(aTHX_ cur_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("Failed to grant protmem RO");

  new_pm = protmem_clone(aTHX_ cur_pm, cur_pm->size);
  if (new_pm == NULL)
    croak("Failed to clone protmem");

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    protmem_release(aTHX_ cur_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("Failed to release new protmem RW");
  }

  if (protmem_release(aTHX_ cur_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("Failed to release protmem RO");
  }

  return protmem_to_sv(aTHX_ new_pm, sv_pkg);
}

static SV * nonce_generate(pTHX_ STRLEN out_len, SV *base) {
  SV *ret;
  unsigned char *nonce_buf;

  Newxz(nonce_buf, out_len + 1, unsigned char);
  if (nonce_buf == NULL)
    croak("Failed to allocate memory");

  if (SvOK(base)) {
    unsigned char *base_buf;
    STRLEN base_len;
    base_buf = (unsigned char *)SvPVbyte(base, base_len);
    if (base_len > out_len) {
      Safefree(nonce_buf);
      croak("Invalid nonce length (too long): %lu", base_len);
    }

    memcpy(nonce_buf, base_buf, base_len);
  }
  else
    randombytes_buf(nonce_buf, out_len);

  ret = newSV(0);
  sv_usepvn_flags(ret, (char *)nonce_buf, out_len, SV_HAS_TRAILING_NUL);

  return ret;
}

/* NB: croaks on failure */
static SV * sv_keygen(pTHX_ STRLEN size, SV * flags) {
  protmem *key_pm;
  unsigned int mv_flags = g_protmem_flags_key_default;

  if (SvOK(flags))
    mv_flags = SvUV(flags);

  key_pm = protmem_init(aTHX_ size, mv_flags);
  if (key_pm == NULL)
    croak("sv_keygen: Failed to allocate protmem");

  randombytes_buf(key_pm->pm_ptr, key_pm->size);

  if (protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ key_pm);
    croak("sv_keygen: Failed to release key protmem RW");
  }

  return protmem_to_sv(aTHX_ key_pm, MEMVAULT_CLASS);
}

=for TODO

add an optional "wipe" argument to encrypt functions. wipe incoming plaintext
when set.

there is a metric boatload (or two) of error handling in this code that needs
cleaning up. the whole thing could do with a re-factor already. very much
duplicated long-form code that could be abstracted (CAREFULLY). might not be
worth the added complexity. this'll be a beast to maintain as-is, though.

also necessary all over the place is handling older versions of libsodium.
there are version definitions usable from pre-processor that should be used to
protect stuff only in the newer versions, and throw otherwise.

also also, should be keeping track of whether the used libsodium is a "minimal"
build. availablility of a number of algorithms and such are dependent on being
a not-minimal build and should be guarded.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS

BOOT:
if (sodium_init() != 0)
  croak("Failed to initialze library");
has_aes256gcm = crypto_aead_aes256gcm_is_available();

PROTOTYPES: ENABLE

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS", 0);

  PPCODE:
  newCONSTSUB(stash, "SODIUM_VERSION_STRING",
              newSVpvs(SODIUM_VERSION_STRING));
  newCONSTSUB(stash, "SODIUM_LIBRARY_VERSION_MAJOR",
              newSVuv(SODIUM_LIBRARY_VERSION_MAJOR));
  newCONSTSUB(stash, "SODIUM_LIBRARY_VERSION_MINOR",
              newSVuv(SODIUM_LIBRARY_VERSION_MINOR));
  XSRETURN_YES;

const char *
sodium_version_string()

=for notes

another parsexs "bug"? includes get weirdly merged together and claimed to be
recursively included by one another if there isn't an extra blank line in
between.

=cut

INCLUDE: inc/base64.xs

INCLUDE: inc/util.xs

INCLUDE: inc/protmem.xs

INCLUDE: inc/memvault.xs

INCLUDE: inc/kx.xs

INCLUDE: inc/kdf.xs

INCLUDE: inc/hkdf.xs

INCLUDE: inc/secretbox.xs

INCLUDE: inc/box.xs

INCLUDE: inc/sign.xs

INCLUDE: inc/secretstream.xs

INCLUDE: inc/aead.xs

INCLUDE: inc/stream.xs

INCLUDE: inc/shorthash.xs

INCLUDE: inc/generichash.xs

INCLUDE: inc/pwhash.xs

INCLUDE: inc/hash.xs

INCLUDE: inc/auth.xs

INCLUDE: inc/onetimeauth.xs

INCLUDE: inc/scalarmult.xs

INCLUDE: inc/finitefield.xs
