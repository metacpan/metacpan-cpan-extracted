MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::hash

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::hash", 0);

  PPCODE:
  newCONSTSUB(stash, "hash_BYTES", newSVuv(crypto_hash_BYTES));
  newCONSTSUB(stash, "hash_sha256_BYTES", newSVuv(crypto_hash_sha256_BYTES));
  newCONSTSUB(stash, "hash_sha512_BYTES", newSVuv(crypto_hash_sha512_BYTES));
  newCONSTSUB(stash, "hash_PRIMITIVE", newSVpvs(crypto_hash_PRIMITIVE));
#ifdef SODIUM_HAS_SHA3
  newCONSTSUB(stash, "hash_sha3256_BYTES", newSVuv(crypto_hash_sha3256_BYTES));
  newCONSTSUB(stash, "hash_sha3512_BYTES", newSVuv(crypto_hash_sha3512_BYTES));
  newCONSTSUB(stash, "hash_sha3_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "hash_sha3_available", &PL_sv_no);
#endif

SV * hash(SV * msg)

  ALIAS:
  hash_sha256 = 1
  hash_sha512 = 2
  hash_sha3256 = 3
  hash_sha3512 = 4

  PREINIT:
  protmem *msg_pm = NULL;
  unsigned char *msg_buf, *out_buf;
  STRLEN msg_len, out_len;
  int (*func)(unsigned char *, const unsigned char *, unsigned long long);

  CODE:
  switch(ix) {
    case 1:
      out_len = crypto_hash_sha256_BYTES;
      func = crypto_hash_sha256;
      break;
    case 2:
      out_len = crypto_hash_sha512_BYTES;
      func = crypto_hash_sha512;
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      out_len = crypto_hash_sha3256_BYTES;
      func = crypto_hash_sha3256;
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    case 4:
#ifdef SODIUM_HAS_SHA3
      out_len = crypto_hash_sha3512_BYTES;
      func = crypto_hash_sha3512;
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    default:
      out_len = crypto_hash_BYTES;
      func = crypto_hash;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("hash: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("hash: Failed to grant msg protmem RO");
  }

  func(out_buf, msg_buf, msg_len);

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("hash: Failed to release msg protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

=for documentation

providing a generic hash_init even though upstream doesn't, using its default
algorithm.

=cut

SV * hash_init(SV * flags = &PL_sv_undef)

  ALIAS:
  hash_sha256_init = 1
  hash_sha512_init = 2
  hash_sha3256_init = 3
  hash_sha3512_init = 4

  PREINIT:
  protmem *state_pm;
  unsigned int state_flags = g_protmem_default_flags_state;

  CODE:
  SvGETMAGIC(flags);
  if (SvOK(flags))
    state_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_hash_sha256_state), state_flags);
      if (state_pm == NULL)
        croak("hash_init: Failed to allocate protmem");
      crypto_hash_sha256_init(state_pm->pm_ptr);
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      state_pm = protmem_init(aTHX_ sizeof(crypto_hash_sha3256_state), state_flags);
      if (state_pm == NULL)
        croak("hash_init: Failed to allocate protmem");
      crypto_hash_sha3256_init(state_pm->pm_ptr);
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    case 4:
#ifdef SODIUM_HAS_SHA3
      state_pm = protmem_init(aTHX_ sizeof(crypto_hash_sha3512_state), state_flags);
      if (state_pm == NULL)
        croak("hash_init: Failed to allocate protmem");
      crypto_hash_sha3512_init(state_pm->pm_ptr);
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_hash_sha512_state), state_flags);
      if (state_pm == NULL)
        croak("hash_init: Failed to allocate protmem");
      crypto_hash_sha512_init(state_pm->pm_ptr);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("hash_init: Failed to release protmem RW");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hash::sha256_multi");
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hash::sha3256_multi");
#endif
      break;
    case 4:
#ifdef SODIUM_HAS_SHA3
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hash::sha3512_multi");
#endif
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hash::sha512_multi");
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::hash::sha256_multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::DESTROY = 1
  Crypt::Sodium::XS::hash::sha3256_multi::DESTROY = 2
  Crypt::Sodium::XS::hash::sha3512_multi::DESTROY = 3

  PREINIT:
  protmem *state_pm;

  CODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    case 2:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3256_multi");
      break;
    case 3:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3512_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::clone = 1
  Crypt::Sodium::XS::hash::sha3256_multi::clone = 2
  Crypt::Sodium::XS::hash::sha3512_multi::clone = 3

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    case 2:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha3256_multi");
      break;
    case 3:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha3512_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
  }

  OUTPUT:
  RETVAL

SV * final(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::final = 1
  Crypt::Sodium::XS::hash::sha3256_multi::final = 2
  Crypt::Sodium::XS::hash::sha3512_multi::final = 3

  PREINIT:
  protmem *state_pm;
  unsigned char *out_buf;

  CODE:
  switch(ix) {
    case 1:
      Newx(out_buf, crypto_hash_sha512_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_hash_sha512_BYTES] = '\0';
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    case 2:
#ifdef SODIUM_HAS_SHA3
      Newx(out_buf, crypto_hash_sha3256_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_hash_sha3256_BYTES] = '\0';
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3256_multi");
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      Newx(out_buf, crypto_hash_sha3512_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_hash_sha3512_BYTES] = '\0';
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3512_multi");
#else
      croak("SHA3 not supported by this version of libsodium");
#endif
      break;
    default:
      Newx(out_buf, crypto_hash_sha256_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_hash_sha256_BYTES] = '\0';
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to grant protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_hash_sha512_final(state_pm->pm_ptr, out_buf);
      break;
    case 2:
#ifdef SODIUM_HAS_SHA3
      crypto_hash_sha3256_final(state_pm->pm_ptr, out_buf);
#endif
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      crypto_hash_sha3512_final(state_pm->pm_ptr, out_buf);
#endif
      break;
    default:
      crypto_hash_sha256_final(state_pm->pm_ptr, out_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to release protmem RW");
  }

  RETVAL = newSV(0);
  switch(ix) {
    case 1:
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hash_sha512_BYTES, SV_HAS_TRAILING_NUL);
      break;
    case 2:
#ifdef SODIUM_HAS_SHA3
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hash_sha3256_BYTES, SV_HAS_TRAILING_NUL);
#endif
      break;
    case 3:
#ifdef SODIUM_HAS_SHA3
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hash_sha3512_BYTES, SV_HAS_TRAILING_NUL);
#endif
      break;
    default:
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hash_sha256_BYTES, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::update = 1
  Crypt::Sodium::XS::hash::sha3256_multi::update = 2
  Crypt::Sodium::XS::hash::sha3512_multi::update = 3

  PREINIT:
  protmem *state_pm, *msg_pm = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    case 2:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3256_multi");
      break;
    case 3:
#ifndef SODIUM_HAS_SHA3
      croak("SHA3 not supported by this version of libsodium");
#endif
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha3512_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
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
        crypto_hash_sha512_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      case 2:
#ifdef SODIUM_HAS_SHA3
        crypto_hash_sha3256_update(state_pm->pm_ptr, msg_buf, msg_len);
#endif
        break;
      case 3:
#ifdef SODIUM_HAS_SHA3
        crypto_hash_sha3512_update(state_pm->pm_ptr, msg_buf, msg_len);
#endif
        break;
      default:
        crypto_hash_sha256_update(state_pm->pm_ptr, msg_buf, msg_len);
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
