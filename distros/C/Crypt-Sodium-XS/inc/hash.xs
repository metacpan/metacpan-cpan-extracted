MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::hash

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::hash", 0);

  PPCODE:
  newCONSTSUB(stash, "hash_BYTES", newSVuv(crypto_hash_BYTES));
  newCONSTSUB(stash, "hash_sha256_BYTES", newSVuv(crypto_hash_sha256_BYTES));
  newCONSTSUB(stash, "hash_sha512_BYTES", newSVuv(crypto_hash_sha512_BYTES));
  newCONSTSUB(stash, "hash_PRIMITIVE", newSVpvs(crypto_hash_PRIMITIVE));

SV * hash(SV * msg)

  ALIAS:
  hash_sha256 = 1
  hash_sha512 = 2

  PREINIT:
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *out_buf;
  STRLEN msg_len;
  STRLEN out_len;
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

  PREINIT:
  protmem *state_pm;
  unsigned int state_flags = g_protmem_flags_state_default;

  CODE:
  if (SvOK(flags))
    state_flags = SvUV(flags);

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_hash_sha256_state), state_flags);
      if (state_pm == NULL)
        croak("hash_init: Failed to allocate protmem");
      crypto_hash_sha256_init(state_pm->pm_ptr);
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
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::hash::sha512_multi");
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::hash::sha256_multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::DESTROY = 1

  PREINIT:
  protmem *state_pm;

  CODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::clone = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::hash::sha256_multi");
  }

  OUTPUT:
  RETVAL

SV * final(SV * self)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::final = 1

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
    default:
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_hash_sha256_BYTES, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::hash::sha512_multi::update = 1

  PREINIT:
  protmem *state_pm;
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::hash::sha512_multi");
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
