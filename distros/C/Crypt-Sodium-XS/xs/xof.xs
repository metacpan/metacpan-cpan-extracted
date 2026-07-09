MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::xof

void _define_constants()

  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::xof", 0);

  PPCODE:
#ifdef SODIUM_HAS_XOF
  newCONSTSUB(stash, "xof_shake128_BLOCKBYTES",
              newSVuv(crypto_xof_shake128_BLOCKBYTES));
  newCONSTSUB(stash, "xof_shake128_STATEBYTES",
              newSVuv(crypto_xof_shake128_STATEBYTES));
  newCONSTSUB(stash, "xof_shake128_DOMAIN_STANDARD",
              newSVpvf("%c", crypto_xof_shake128_DOMAIN_STANDARD));
  newCONSTSUB(stash, "xof_shake256_BLOCKBYTES",
              newSVuv(crypto_xof_shake256_BLOCKBYTES));
  newCONSTSUB(stash, "xof_shake256_STATEBYTES",
              newSVuv(crypto_xof_shake256_STATEBYTES));
  newCONSTSUB(stash, "xof_shake256_DOMAIN_STANDARD",
              newSVpvf("%c", crypto_xof_shake256_DOMAIN_STANDARD));
  newCONSTSUB(stash, "xof_turboshake128_BLOCKBYTES",
              newSVuv(crypto_xof_turboshake128_BLOCKBYTES));
  newCONSTSUB(stash, "xof_turboshake128_STATEBYTES",
              newSVuv(crypto_xof_turboshake128_STATEBYTES));
  newCONSTSUB(stash, "xof_turboshake128_DOMAIN_STANDARD",
              newSVpvf("%c", crypto_xof_turboshake128_DOMAIN_STANDARD));
  newCONSTSUB(stash, "xof_turboshake256_BLOCKBYTES",
              newSVuv(crypto_xof_turboshake256_BLOCKBYTES));
  newCONSTSUB(stash, "xof_turboshake256_STATEBYTES",
              newSVuv(crypto_xof_turboshake256_STATEBYTES));
  newCONSTSUB(stash, "xof_turboshake256_DOMAIN_STANDARD",
              newSVpvf("%c", crypto_xof_turboshake256_DOMAIN_STANDARD));
  newCONSTSUB(stash, "available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "available", &PL_sv_no);
#endif

SV * xof_shake128(SV * msg, STRLEN out_len, SV * flags = &PL_sv_undef)

  ALIAS:
  xof_shake256 = 1
  xof_turboshake128 = 2
  xof_turboshake256 = 3
  xof_shake128_key = 16
  xof_shake256_key = 17
  xof_turboshake128_key = 18
  xof_turboshake256_key = 19

  PREINIT:
  protmem *msg_pm = NULL, *out_pm = NULL;
  unsigned char *msg_buf, *out_buf;
  STRLEN msg_len;
  unsigned int out_flags = g_protmem_default_flags_key;

  CODE:
#ifdef SODIUM_HAS_XOF
  SvGETMAGIC(flags);
  if (SvOK(flags))
    out_flags = SvUV_nomg(flags);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (ix & 0x10) {
    out_pm = protmem_init(aTHX_ out_len, out_flags);
    if (out_pm == NULL)
      croak("xof: Failed to allocate protmem");
    out_buf = out_pm->pm_ptr;
  }
  else {
    Newx(out_buf, out_len + 1, unsigned char);
    if (out_buf == NULL)
      croak("xof: Failed to allocate memory");
    out_buf[out_len] = '\0';
  }

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (out_pm)
      protmem_free(aTHX_ out_pm);
    else
      Safefree(out_buf);
    croak("xof: Failed to grant msg protmem RO");
  }

  switch(ix & ~0x10) {
    case 1:
      crypto_xof_shake256(out_buf, out_len, msg_buf, msg_len);
      break;
    case 2:
      crypto_xof_turboshake128(out_buf, out_len, msg_buf, msg_len);
      break;
    case 3:
      crypto_xof_turboshake256(out_buf, out_len, msg_buf, msg_len);
      break;
    default:
      crypto_xof_shake128(out_buf, out_len, msg_buf, msg_len);
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (out_pm)
      protmem_free(aTHX_ out_pm);
    else
      Safefree(out_buf);
    croak("xof: Failed to release msg protmem RO");
  }

  if (ix & 0x10) {
    if (protmem_release(aTHX_ out_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ out_pm);
      croak("xof: Failed to release out protmem RW");
    }
    RETVAL = protmem_to_sv(aTHX_ out_pm, MEMVAULT_CLASS);
  }
  else {
    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);
  }
#else
  croak("XOF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

SV * xof_shake128_init(unsigned char domain = 0x1f, SV * flags = &PL_sv_undef)

  ALIAS:
  xof_shake256_init = 1
  xof_turboshake128_init = 2
  xof_turboshake256_init = 3

  PREINIT:
  protmem *state_pm;
  unsigned int state_flags = g_protmem_default_flags_state;

  CODE:
#ifdef SODIUM_HAS_XOF
  if (domain < 1 || domain > 127)
    croak("xof_init: Invalid domain (must be 1-127)");

  SvGETMAGIC(flags);
  if (SvOK(flags))
    state_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_xof_shake256_state), state_flags);
      if (state_pm == NULL)
        croak("xof_init: Failed to allocate protmem");
      crypto_xof_shake256_init_with_domain(state_pm->pm_ptr, domain);
      break;
    case 2:
      state_pm = protmem_init(aTHX_ sizeof(crypto_xof_turboshake128_state), state_flags);
      if (state_pm == NULL)
        croak("xof_init: Failed to allocate protmem");
      crypto_xof_turboshake128_init_with_domain(state_pm->pm_ptr, domain);
      break;
    case 3:
      state_pm = protmem_init(aTHX_ sizeof(crypto_xof_turboshake256_state), state_flags);
      if (state_pm == NULL)
        croak("xof_init: Failed to allocate protmem");
      crypto_xof_turboshake256_init_with_domain(state_pm->pm_ptr, domain);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_xof_shake128_state), state_flags);
      if (state_pm == NULL)
        croak("xof_init: Failed to allocate protmem");
      crypto_xof_shake128_init_with_domain(state_pm->pm_ptr, domain);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("xof_init: Failed to release protmem RW");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::xof::shake256_multi");
      break;
    case 2:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::xof::turboshake128_multi");
      break;
    case 3:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::xof::turboshake256_multi");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::xof::shake128_multi");
  }
#else
  croak("XOF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::xof::shake128_multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::xof::shake256_multi::DESTROY = 1
  Crypt::Sodium::XS::xof::turboshake128_multi::DESTROY = 2
  Crypt::Sodium::XS::xof::turboshake256_multi::DESTROY = 3

  PREINIT:
  protmem *state_pm;

  CODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake256_multi");
      break;
    case 2:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake128_multi");
      break;
    case 3:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake256_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake128_multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::xof::shake256_multi::clone = 1
  Crypt::Sodium::XS::xof::turboshake128_multi::clone = 2
  Crypt::Sodium::XS::xof::turboshake256_multi::clone = 3

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::xof::shake256_multi");
      break;
    case 2:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake128_multi");
      break;
    case 3:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake256_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::xof::shake128_multi");
  }

  OUTPUT:
  RETVAL

SV * squeeze(SV * self, STRLEN out_len, SV * flags = &PL_sv_undef)

  ALIAS:
  Crypt::Sodium::XS::xof::shake256_multi::squeeze = 1
  Crypt::Sodium::XS::xof::turboshake128_multi::squeeze = 2
  Crypt::Sodium::XS::xof::turboshake256_multi::squeeze = 3
  squeeze_key = 16
  Crypt::Sodium::XS::xof::shake256_multi::squeeze_key = 17
  Crypt::Sodium::XS::xof::turboshake128_multi::squeeze_key = 18
  Crypt::Sodium::XS::xof::turboshake256_multi::squeeze_key = 19

  PREINIT:
  protmem *out_pm = NULL, *state_pm;
  unsigned char *out_buf;
  unsigned int out_flags = g_protmem_default_flags_key;

  CODE:
#ifdef SODIUM_HAS_XOF
  SvGETMAGIC(flags);
  if (SvOK(flags))
    out_flags = SvUV_nomg(flags);

  if (ix & 0x10) {
    out_pm = protmem_init(aTHX_ out_len, out_flags);
    if (out_pm == NULL)
      croak("squeeze: Failed to allocate protmem");
    out_buf = out_pm->pm_ptr;
  }
  else {
    Newx(out_buf, out_len + 1, unsigned char);
    if (out_buf == NULL)
      croak("squeeze: Failed to allocate memory");
    out_buf[out_len] = '\0';
  }

  switch(ix & ~0x10) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake256_multi");
      break;
    case 2:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake128_multi");
      break;
    case 3:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake256_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake128_multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (out_pm)
      protmem_free(aTHX_ out_pm);
    else
      Safefree(out_buf);
    croak("squeeze: Failed to grant protmem RW");
  }

  switch(ix & ~0x10) {
    case 1:
      crypto_xof_shake256_squeeze(state_pm->pm_ptr, out_buf, out_len);
      break;
    case 2:
      crypto_xof_turboshake128_squeeze(state_pm->pm_ptr, out_buf, out_len);
      break;
    case 3:
      crypto_xof_turboshake256_squeeze(state_pm->pm_ptr, out_buf, out_len);
      break;
    default:
      crypto_xof_shake128_squeeze(state_pm->pm_ptr, out_buf, out_len);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (out_pm)
      protmem_free(aTHX_ out_pm);
    else
      Safefree(out_buf);
    croak("squeeze: Failed to release state protmem RW");
  }

  if (ix & 0x10) {
    if (protmem_release(aTHX_ out_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ state_pm);
      croak("squeeze: Failed to release out protmem RW");
    }
    RETVAL = protmem_to_sv(aTHX_ out_pm, MEMVAULT_CLASS);
  }
  else {
    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);
  }
#else
  croak("XOF not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::xof::shake256_multi::update = 1
  Crypt::Sodium::XS::xof::turboshake128_multi::update = 2
  Crypt::Sodium::XS::xof::turboshake256_multi::update = 3

  PREINIT:
  protmem *state_pm, *msg_pm = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
#ifdef SODIUM_HAS_XOF
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake256_multi");
      break;
    case 2:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake128_multi");
      break;
    case 3:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::turboshake256_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::xof::shake128_multi");
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
        crypto_xof_shake128_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      case 2:
        crypto_xof_turboshake128_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      case 3:
        crypto_xof_turboshake256_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_xof_shake128_update(state_pm->pm_ptr, msg_buf, msg_len);
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
#else
  croak("XOF not supported by this version of libsodium");
#endif
