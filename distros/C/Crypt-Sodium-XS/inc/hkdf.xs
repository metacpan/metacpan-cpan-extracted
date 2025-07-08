MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::hkdf

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::hkdf", 0);

  PPCODE:
#ifdef SODIUM_HAS_HKDF
  newCONSTSUB(stash, "hkdf_sha256_BYTES_MAX",
              newSVuv(crypto_kdf_hkdf_sha256_BYTES_MAX));
  newCONSTSUB(stash, "hkdf_sha512_BYTES_MAX",
              newSVuv(crypto_kdf_hkdf_sha512_BYTES_MAX));
  newCONSTSUB(stash, "hkdf_sha256_BYTES_MIN",
              newSVuv(crypto_kdf_hkdf_sha256_BYTES_MIN));
  newCONSTSUB(stash, "hkdf_sha512_BYTES_MIN",
              newSVuv(crypto_kdf_hkdf_sha512_BYTES_MIN));
  newCONSTSUB(stash, "hkdf_sha256_KEYBYTES",
              newSVuv(crypto_kdf_hkdf_sha256_KEYBYTES));
  newCONSTSUB(stash, "hkdf_sha512_KEYBYTES",
              newSVuv(crypto_kdf_hkdf_sha512_KEYBYTES));
  newCONSTSUB(stash, "hkdf_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "hkdf_available", &PL_sv_no);
#endif

SV * hkdf_sha256_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  hkdf_sha256_keygen = 1
  hkdf_sha512_keygen = 2

  CODE:
  switch(ix) {
    case 1:
#ifdef SODIUM_HAS_HKDF
      RETVAL = sv_keygen(aTHX_ crypto_kdf_hkdf_sha256_KEYBYTES, flags);
#else
      croak("HKDF not supported by this version of libsodium");
#endif
      break;
    default:
#ifdef SODIUM_HAS_HKDF
      RETVAL = sv_keygen(aTHX_ crypto_kdf_hkdf_sha512_KEYBYTES, flags);
#else
      croak("HKDF not supported by this version of libsodium");
#endif
  }

  OUTPUT:
  RETVAL

SV * hkdf_sha256_extract( \
  SV * ikm, \
  SV * salt = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  hkdf_sha512_extract = 1

  PREINIT:
  protmem *ikm_pm = NULL;
  protmem *prk_pm;
  unsigned char *salt_buf = NULL;
  unsigned char *ikm_buf;
  STRLEN prk_len;
  STRLEN salt_len = 0;
  STRLEN ikm_len;
  unsigned int prk_flags = g_protmem_flags_key_default;
  int (*func)(unsigned char *,
              const unsigned char *, size_t, const unsigned char *, size_t);

  CODE:
#if defined(SODIUM_HAS_HKDF)
  if (SvOK(flags))
    prk_flags = SvUV(flags);

  switch(ix) {
    case 1:
      prk_len = crypto_kdf_hkdf_sha512_KEYBYTES;
      func = crypto_kdf_hkdf_sha512_extract;
      break;
    default:
      prk_len = crypto_kdf_hkdf_sha256_KEYBYTES;
      func = crypto_kdf_hkdf_sha256_extract;
  }

  if (SvOK(salt))
    salt_buf = (unsigned char *)SvPVbyte(salt, salt_len);

  if (sv_derived_from(ikm, MEMVAULT_CLASS)) {
    ikm_pm = protmem_get(aTHX_ ikm, MEMVAULT_CLASS);
    ikm_buf = ikm_pm->pm_ptr;
    ikm_len = ikm_pm->size;
  }
  else
    ikm_buf = (unsigned char *)SvPVbyte(ikm, ikm_len);

  prk_pm = protmem_init(aTHX_ prk_len, prk_flags);
  if (prk_pm == NULL)
    croak("hkdf_extract: Failed to allocate protmem");

  if (ikm_pm && protmem_grant(aTHX_ ikm_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("hkdf_extract: Failed to grant ikm protmem RO");
  }

  func(prk_pm->pm_ptr, salt_buf, salt_len, ikm_buf, ikm_len);

  if (ikm_pm && protmem_release(aTHX_ ikm_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("hkdf_extract: Failed to release ikm protmem RO");
  }

  if (protmem_release(aTHX_ prk_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("hkdf_extract: Failed to release prk protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ prk_pm, MEMVAULT_CLASS);
#else
  croak("hkdf_extract: HKDF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

SV * hkdf_sha256_expand( \
  SV * prk, \
  STRLEN out_len, \
  SV * ctx = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  hkdf_sha512_expand = 1

  PREINIT:
  protmem *out_pm;
  protmem *prk_pm = NULL;
  unsigned char *ctx_buf = NULL;
  unsigned char *prk_buf;
  STRLEN out_max_len;
  STRLEN ctx_len = 0;
  STRLEN prk_len;
  STRLEN prk_req_len;
  unsigned int out_flags;
  int (*func)(unsigned char *, size_t, const char *, size_t, const unsigned char *);

  CODE:
#if defined(SODIUM_HAS_HKDF)
  switch(ix) {
    case 1:
      out_max_len = crypto_kdf_hkdf_sha512_BYTES_MAX;
      prk_req_len = crypto_kdf_hkdf_sha512_KEYBYTES;
      func = crypto_kdf_hkdf_sha512_expand;
      break;
    default:
      out_max_len = crypto_kdf_hkdf_sha256_BYTES_MAX;
      prk_req_len = crypto_kdf_hkdf_sha256_KEYBYTES;
      func = crypto_kdf_hkdf_sha256_expand;
  }

  if (out_len > out_max_len)
    croak("hkdf_expand: Invalid expand output length (too large)");

  if (SvOK(ctx))
    ctx_buf = (unsigned char *)SvPVbyte(ctx, ctx_len);

  if (sv_derived_from(prk, MEMVAULT_CLASS)) {
    prk_pm = protmem_get(aTHX_ prk, MEMVAULT_CLASS);
    prk_buf = prk_pm->pm_ptr;
    prk_len = prk_pm->size;
  }
  else
    prk_buf = (unsigned char *)SvPVbyte(prk, prk_len);

  if (prk_len != prk_req_len)
    croak("hkdf_expand: Invalid key length");

  if (SvOK(flags))
    out_flags = SvUV(flags);
  else if (prk_pm)
    out_flags = prk_pm->flags;
  else
    out_flags = g_protmem_flags_key_default;

  out_pm = protmem_init(aTHX_ out_len, out_flags);
  if (out_pm == NULL)
    croak("hkdf_expand: Failed to allocate protmem");

  if (prk_pm && protmem_grant(aTHX_ prk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ out_pm);
    croak("hkdf_expand: Failed to grant prk protmem RO");
  }

  func(out_pm->pm_ptr, out_len, (char *)ctx_buf, ctx_len, prk_buf);

  if (prk_pm && protmem_release(aTHX_ prk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ out_pm);
    croak("hkdf_expand: Failed to release prk protmem RO");
  }

  if (protmem_release(aTHX_ out_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ out_pm);
    croak("hkdf_expand: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ out_pm, MEMVAULT_CLASS);
#else
  croak("hkdf_expand: HKDF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

SV * hkdf_sha256_extract_init(SV * salt = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  hkdf_sha512_extract_init = 1

  PREINIT:
  protmem *state_pm;
  unsigned char *salt_buf = NULL;
  STRLEN salt_len = 0;
  unsigned int state_flags = g_protmem_flags_state_default;

  CODE:
#if defined(SODIUM_HAS_HKDF)
  if (SvOK(salt))
    salt_buf = (unsigned char *)SvPVbyte(salt, salt_len);

  if (SvOK(flags))
    state_flags = SvUV(flags);

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_kdf_hkdf_sha512_state), state_flags);
      if (state_pm == NULL)
        croak("hkdf_extract_init: Failed to allocate state protmem");
      crypto_kdf_hkdf_sha512_extract_init(state_pm->pm_ptr, salt_buf, salt_len);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_kdf_hkdf_sha256_state), state_flags);
      if (state_pm == NULL)
        croak("hkdf_extract_init: Failed to allocate state protmem");
      crypto_kdf_hkdf_sha256_extract_init(state_pm->pm_ptr, salt_buf, salt_len);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("hkdf_extract_init: Failed to release state protmem RW");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hkdf::sha512_multi");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hkdf::sha256_multi");
  }
#else
  croak("HKDF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS::hkdf PACKAGE = Crypt::Sodium::XS::hkdf::sha256_multi

#ifdef SODIUM_HAS_HKDF

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hkdf::sha512_multi::DESTROY = 1

  PREINIT:
  protmem *state_pm;

  CODE:
  switch (ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha512_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha256_multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS: Crypt::Sodium::XS::hkdf::sha512_multi::clone = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha512_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha256_multi");
  }

  OUTPUT:
  RETVAL

SV * final(SV * self, SV * flags = &PL_sv_undef)

  ALIAS:
  Crypt::Sodium::XS::hkdf::sha512_multi::final = 1

  PREINIT:
  protmem *state_pm;
  protmem *prk_pm;
  unsigned int prk_flags = g_protmem_flags_key_default;

  CODE:

  if (SvOK(flags))
    prk_flags = SvUV(flags);

  switch(ix) {
    case 1:
      prk_pm = protmem_init(aTHX_ crypto_kdf_hkdf_sha512_KEYBYTES, prk_flags);
      if (prk_pm == NULL)
        croak("final: Failed to allocate protmem");

      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha512_multi");
      break;
    default:
      prk_pm = protmem_init(aTHX_ crypto_kdf_hkdf_sha256_KEYBYTES, prk_flags);
      if (prk_pm == NULL)
        croak("final: Failed to allocate protmem");

      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha256_multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("final: Failed to grant state protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_kdf_hkdf_sha512_extract_final(state_pm->pm_ptr, prk_pm->pm_ptr);
      break;
    default:
      crypto_kdf_hkdf_sha256_extract_final(state_pm->pm_ptr, prk_pm->pm_ptr);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("final: Failed to release state protmem RW");
  }

  if (protmem_release(aTHX_ prk_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ prk_pm);
    croak("final: Failed to release prk protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ prk_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::hkdf::sha512_multi::update = 1

  PREINIT:
  protmem *state_pm;
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  PERL_UNUSED_VAR(RETVAL);
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha512_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hkdf::sha256_multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to grant state protmem RW");

  for (i = 1; i < items; i++) {
    if (sv_derived_from(ST(i), MEMVAULT_CLASS)) {
      msg_pm = protmem_get(aTHX_ ST(i), MEMVAULT_CLASS);
      msg_buf = msg_pm->pm_ptr;
      msg_len = msg_pm->size;
    }
    else
      msg_buf = (unsigned char *)SvPVbyte(ST(i), msg_len);

    if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to grant msg protmem RO");
    }

    switch(ix) {
      case 1:
        crypto_kdf_hkdf_sha512_extract_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_kdf_hkdf_sha256_extract_update(state_pm->pm_ptr, msg_buf, msg_len);
    }

    if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to release msg protmem RO");
    }

    msg_pm = NULL;
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to release state protmem RW");

  XSRETURN(1);

#endif
