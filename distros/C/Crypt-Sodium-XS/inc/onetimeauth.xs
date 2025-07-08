MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::onetimeauth

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::onetimeauth", 0);

  PPCODE:
  newCONSTSUB(stash, "onetimeauth_BYTES", newSVuv(crypto_onetimeauth_BYTES));
  newCONSTSUB(stash, "onetimeauth_poly1305_BYTES",
              newSVuv(crypto_onetimeauth_poly1305_BYTES));
  newCONSTSUB(stash, "onetimeauth_KEYBYTES",
              newSVuv(crypto_onetimeauth_KEYBYTES));
  newCONSTSUB(stash, "onetimeauth_poly1305_KEYBYTES",
              newSVuv(crypto_onetimeauth_poly1305_KEYBYTES));
  newCONSTSUB(stash, "onetimeauth_PRIMITIVE",
              newSVpvs(crypto_onetimeauth_PRIMITIVE));

SV *onetimeauth(SV *msg, SV *key)

  ALIAS:
  onetimeauth_poly1305 = 1

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *key_buf;
  unsigned char *out_buf;
  STRLEN key_len;
  STRLEN msg_len;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      func = crypto_onetimeauth_poly1305;
      break;
    default:
      func = crypto_onetimeauth;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_onetimeauth_KEYBYTES)
    croak("onetimeauth: Invalid key length %lu", key_len);

  Newx(out_buf, crypto_onetimeauth_BYTES + 1, unsigned char);
  if (out_buf == NULL)
    croak("onetimeauth: Failed to allocate memory");
  out_buf[crypto_onetimeauth_BYTES] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("onetimeauth: Failed to grant msg protmem RO");
  }

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(out_buf);
    croak("onetimeauth: Failed to grant key protmem RO");
  }

  func(out_buf, msg_buf, msg_len, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(out_buf);
    croak("onetimeauth: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("onetimeauth: Failed to release msg protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_onetimeauth_BYTES,
                  SV_HAS_TRAILING_NUL);
  OUTPUT:
  RETVAL

SV *onetimeauth_keygen(SV *flags = &PL_sv_undef)

  ALIAS:
  onetimeauth_poly1305_keygen = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_onetimeauth_poly1305_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_onetimeauth_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL

void onetimeauth_verify(SV *mac, SV *msg, SV *key)

  ALIAS:
  onetimeauth_poly1305_verify = 1

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *mac_buf;
  unsigned char *msg_buf;
  unsigned char *key_buf;
  STRLEN mac_len;
  STRLEN msg_len;
  STRLEN key_len;
  int ret;
  int (*func)(const unsigned char *, const unsigned char *,
                unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      func = crypto_onetimeauth_poly1305_verify;
      break;
    default:
      func = crypto_onetimeauth_verify;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_onetimeauth_KEYBYTES)
    croak("onetimeauth_verify: Invalid key length %lu", key_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("onetimeauth_verify: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("onetimeauth_verify: Failed to grant key protmem RO");
  }

  ret = func(mac_buf, msg_buf, msg_len, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("onetimeauth_verify: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("onetimeauth_verify: Failed to release msg protmem RO");

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

SV * onetimeauth_init(SV *key, SV *flags = &PL_sv_undef)

  ALIAS:
  onetimeauth_poly1305_init = 1

  PREINIT:
  protmem *state_pm;
  protmem *key_pm = NULL;
  unsigned char *key_buf;
  STRLEN key_len;
  unsigned int state_flags = g_protmem_flags_key_default;

  CODE:
  if (SvOK(flags))
    state_flags = SvUV(flags);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  switch(ix) {
    case 1:
      if (key_len != crypto_onetimeauth_poly1305_KEYBYTES)
        croak("onetimeauth_init: Invalid key length %lu", key_len);
      break;
    default:
      if (key_len != crypto_onetimeauth_KEYBYTES)
        croak("onetimeauth_init: Invalid key length %lu", key_len);
  }

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("onetimeauth_init: Failed to grant key protmem RO");

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_onetimeauth_poly1305_state), state_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("onetimeauth_init: Failed to allocate state protmem");
      }
      crypto_onetimeauth_poly1305_init(state_pm->pm_ptr, key_buf);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_onetimeauth_state), state_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("onetimeauth_init: Failed to allocate state protmem");
      }
      crypto_onetimeauth_init(state_pm->pm_ptr, key_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("onetimeauth_init: Failed to release state protmem RW");
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("onetimeauth_init: Failed to release key protmem RO");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::onetimeauth::poly1305_multi");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::onetimeauth::multi");
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::onetimeauth::multi

void DESTROY(SV *self)

  ALIAS:
  Crypt::Sodium::XS::onetimeauth::poly1305_multi::DESTROY = 1

  PREINIT:
  protmem *state_pm;

  CODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::poly1305_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::multi");
  }
  protmem_free(aTHX_ state_pm);

SV *clone(SV *self)

  ALIAS:
  Crypt::Sodium::XS::onetimeauth::poly1305_multi::clone = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::poly1305_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::multi");
  }

  OUTPUT:
  RETVAL

SV * final(SV *self)

  ALIAS:
  Crypt::Sodium::XS::onetimeauth::poly1305_multi::final = 1

  PREINIT:
  protmem *state_pm;
  unsigned char *out_buf;

  CODE:
  switch(ix) {
    case 1:
      Newx(out_buf, crypto_onetimeauth_poly1305_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_onetimeauth_poly1305_BYTES] = '\0';

      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::poly1305_multi");
      break;
    default:
      Newx(out_buf, crypto_onetimeauth_BYTES + 1, unsigned char);
      if (out_buf == NULL)
        croak("final: Failed to allocate memory");
      out_buf[crypto_onetimeauth_BYTES] = '\0';

      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to grant state protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_onetimeauth_poly1305_final(state_pm->pm_ptr, out_buf);
      break;
    default:
      crypto_onetimeauth_final(state_pm->pm_ptr, out_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to release state protmem RW");
  }

  RETVAL = newSV(0);
  switch(ix) {
    case 1:
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_onetimeauth_poly1305_BYTES, SV_HAS_TRAILING_NUL);
      break;
    default:
      sv_usepvn_flags(RETVAL, (char *)out_buf, crypto_onetimeauth_BYTES, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

void update(SV *self, ...)

  ALIAS:
  Crypt::Sodium::XS::onetimeauth::poly1305_multi::update = 1

  PREINIT:
  protmem *state_pm;
  protmem *msg_mv = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::poly1305_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::onetimeauth::multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to grant state protmem RW");

  for (i = 1; i < items; i++) {
    if (sv_derived_from(ST(i), MEMVAULT_CLASS)) {
      msg_mv = protmem_get(aTHX_ ST(i), MEMVAULT_CLASS);
      msg_buf = msg_mv->pm_ptr;
      msg_len = msg_mv->size;
    }
    else
      msg_buf = (unsigned char *)SvPVbyte(ST(i), msg_len);

    if (msg_mv && protmem_grant(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to grant msg protmem RO");
    }

    switch(ix) {
      case 1:
        crypto_onetimeauth_poly1305_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_onetimeauth_update(state_pm->pm_ptr, msg_buf, msg_len);
    }

    if (msg_mv && protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to release msg protmem RO");
    }

    msg_mv = NULL;
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to release state protmem RW");

  XSRETURN(1);
