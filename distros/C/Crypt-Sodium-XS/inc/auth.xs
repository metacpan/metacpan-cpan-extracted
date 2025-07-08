MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::auth

void _define_constants()

  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::auth", 0);

  PPCODE:
  newCONSTSUB(stash, "auth_BYTES",
              newSVuv(crypto_auth_BYTES));
  newCONSTSUB(stash, "auth_hmacsha256_BYTES",
              newSVuv(crypto_auth_hmacsha256_BYTES));
  newCONSTSUB(stash, "auth_hmacsha512_BYTES",
              newSVuv(crypto_auth_hmacsha512_BYTES));
  newCONSTSUB(stash, "auth_hmacsha512256_BYTES",
              newSVuv(crypto_auth_hmacsha512256_BYTES));
  newCONSTSUB(stash, "auth_KEYBYTES",
              newSVuv(crypto_auth_KEYBYTES));
  newCONSTSUB(stash, "auth_hmacsha256_KEYBYTES",
              newSVuv(crypto_auth_hmacsha256_KEYBYTES));
  newCONSTSUB(stash, "auth_hmacsha512_KEYBYTES",
              newSVuv(crypto_auth_hmacsha512_KEYBYTES));
  newCONSTSUB(stash, "auth_hmacsha512256_KEYBYTES",
              newSVuv(crypto_auth_hmacsha512256_KEYBYTES));
  newCONSTSUB(stash, "auth_PRIMITIVE", newSVpvs(crypto_auth_PRIMITIVE));

SV * auth_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  auth_hmacsha256_keygen = 1
  auth_hmacsha512_keygen = 2
  auth_hmacsha512256_keygen = 3

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_auth_hmacsha256_KEYBYTES, flags);
      break;
    case 2:
      RETVAL = sv_keygen(aTHX_ crypto_auth_hmacsha512_KEYBYTES, flags);
      break;
    case 3:
      RETVAL = sv_keygen(aTHX_ crypto_auth_hmacsha512256_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_auth_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL

SV * auth(SV * msg, SV * key)

  ALIAS:
  auth_hmacsha256 = 1
  auth_hmacsha512 = 2
  auth_hmacsha512256 = 3

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *key_buf;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN key_len;
  STRLEN key_req_len;
  STRLEN mac_len;
  int (*func)(unsigned char *, const unsigned char *,
                unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      key_req_len = crypto_auth_hmacsha256_KEYBYTES;
      mac_len = crypto_auth_hmacsha256_BYTES;
      func = crypto_auth_hmacsha256;
      break;
    case 2:
      key_req_len = crypto_auth_hmacsha512_KEYBYTES;
      mac_len = crypto_auth_hmacsha512_BYTES;
      func = crypto_auth_hmacsha512;
      break;
    case 3:
      key_req_len = crypto_auth_hmacsha512256_KEYBYTES;
      mac_len = crypto_auth_hmacsha512256_BYTES;
      func = crypto_auth_hmacsha512256;
      break;
    default:
      key_req_len = crypto_auth_KEYBYTES;
      mac_len = crypto_auth_BYTES;
      func = crypto_auth;
  }

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("auth: Invalid key length %lu", key_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  Newx(mac_buf, mac_len + 1, unsigned char);
  if (mac_buf == NULL)
    croak("auth: Failed to allocate memory");
  mac_buf[mac_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(mac_buf);
    croak("auth: Failed to grant msg protmem RO");
  }

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(mac_buf);
    croak("auth: Failed to grant key protmem RO");
  }

  func(mac_buf, msg_buf, msg_len, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(mac_buf);
    croak("auth: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(mac_buf);
    croak("auth: Failed to release msg protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)mac_buf, mac_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void auth_verify(SV * mac, SV * msg, SV * key)

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *key_buf;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN key_len;
  STRLEN mac_len;
  int ret;

  CODE:
  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_auth_KEYBYTES)
    croak("auth_verify: Invalid key length %lu", key_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != crypto_auth_BYTES)
    croak("auth_verify: Invalid mac length %lu", mac_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("auth_verify: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("auth_verify: Failed to grant key protmem RO");
  }

  ret = crypto_auth(mac_buf, msg_buf, msg_len, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("auth_verify: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("auth_verify: Failed to release msg protmem RO");

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

=for documentation

algorithm-specific verify is allowed to use arbitrary-length keys. this is a
holdover from compatibility to Crypt::NaCl::Sodium, which i'm assuming was
there for a good reason. if that is allowed here, it should likely be allowed
in the general auth_verify() function as well. maybe even in the generic auth()
?

it might be better to remove this altogether (from verify and from multi-part).
it seems to be a great footgun. there's less harm to be done leaving it just
for verify.

=cut

void auth_hmacsha256_verify(SV * mac, SV * msg, SV * key = &PL_sv_undef)

  ALIAS:
  auth_hmacsha512_verify = 1
  auth_hmacsha512256_verify = 2

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *key_buf = NULL;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN key_len = 0;
  STRLEN key_req_len;
  STRLEN mac_len;
  STRLEN mac_req_len;
  int ret;
  int (*func)(const unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *);

  PPCODE:
  switch(ix) {
    case 1:
      key_req_len = crypto_auth_hmacsha512_KEYBYTES;
      mac_req_len = crypto_auth_hmacsha512_BYTES;
      func = crypto_auth_hmacsha512_verify;
      break;
    case 2:
      key_req_len = crypto_auth_hmacsha512256_KEYBYTES;
      mac_req_len = crypto_auth_hmacsha512256_BYTES;
      func = crypto_auth_hmacsha512256_verify;
      break;
    default:
      key_req_len = crypto_auth_hmacsha256_KEYBYTES;
      mac_req_len = crypto_auth_hmacsha256_BYTES;
      func = crypto_auth_hmacsha256_verify;
  }

  if (SvOK(key)) {
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != mac_req_len)
    croak("auth_verify: Invalid mac length %lu", mac_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("auth_verify: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("auth_verify: Failed to grant key protmem RO");
  }

  if (key_len != key_req_len) {
    unsigned char *mac_expected;
    Newx(mac_expected, mac_req_len + 1, unsigned char);
    if (mac_expected == NULL) {
      if (msg)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("auth_verify: Failed to allocate memory");
    }

    switch(ix) {
      case 1:
      {
        crypto_auth_hmacsha512_state state;
        crypto_auth_hmacsha512_init(&state, key_buf, key_len);
        crypto_auth_hmacsha512_update(&state, msg_buf, msg_len);
        crypto_auth_hmacsha512_final(&state, mac_expected);
        break;
      }
      case 2:
      {
        crypto_auth_hmacsha512256_state state;
        crypto_auth_hmacsha512256_init(&state, key_buf, key_len);
        crypto_auth_hmacsha512256_update(&state, msg_buf, msg_len);
        crypto_auth_hmacsha512256_final(&state, mac_expected);
        break;
      }
      default:
      {
        crypto_auth_hmacsha256_state state;
        crypto_auth_hmacsha256_init(&state, key_buf, key_len);
        crypto_auth_hmacsha256_update(&state, msg_buf, msg_len);
        crypto_auth_hmacsha256_final(&state, mac_expected);
      }
    }

    ret = sodium_memcmp(mac_buf, mac_expected, mac_req_len);

    Safefree(mac_expected);
  }
  else
    ret = func(mac_buf, msg_buf, msg_len, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("auth_verify: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("auth_verify: Failed to release msg protmem RO");

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

=for documentation

providing a generic auth_init even though upstream doesn't, using its default
algorithm.

=cut

SV * auth_init(SV * key = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  auth_hmacsha256_init = 1
  auth_hmacsha512_init = 2
  auth_hmacsha512256_init = 3

  PREINIT:
  protmem *state_pm;
  protmem *key_pm = NULL;
  unsigned char *key_buf = NULL;
  STRLEN key_len = 0;
  unsigned int state_flags = g_protmem_flags_key_default;

  CODE:
  if (SvOK(key)) {
    state_flags = g_protmem_flags_key_default;
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else {
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
    }
  }

  if (SvOK(flags))
    state_flags = SvUV(flags);

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("auth_init: Failed to grant key protmem RO");

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_auth_hmacsha256_state), state_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("auth_init: Failed to allocate state protmem");
      }
      crypto_auth_hmacsha256_init(state_pm->pm_ptr, key_buf, key_len);
      break;
    case 2:
      state_pm = protmem_init(aTHX_ sizeof(crypto_auth_hmacsha512_state), state_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("auth_init: Failed to allocate state protmem");
      }
      crypto_auth_hmacsha512_init(state_pm->pm_ptr, key_buf, key_len);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_auth_hmacsha512256_state), state_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("auth_init: Failed to allocate state protmem");
      }
      crypto_auth_hmacsha512256_init(state_pm->pm_ptr, key_buf, key_len);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("auth_init: Failed to release state protmem RO");
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("auth_init: Failed to release key protmem RO");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::auth::hmacsha256_multi");
      break;
    case 2:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::auth::hmacsha512_multi");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::auth::hmacsha512256_multi");
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::auth::hmacsha256_multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::auth::hmacsha512_multi::DESTROY = 1
  Crypt::Sodium::XS::auth::hmacsha512256_multi::DESTROY= 2

  PREINIT:
  protmem *state_pm;

  PPCODE:
  switch (ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512_multi");
      break;
    case 2:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512256_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha256_multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::auth::hmacsha512_multi::clone = 1
  Crypt::Sodium::XS::auth::hmacsha512256_multi::clone = 2

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512_multi");
      break;
    case 2:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512256_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha256_multi");
  }

  OUTPUT:
  RETVAL

SV * final(SV * self)

  ALIAS:
  Crypt::Sodium::XS::auth::hmacsha512_multi::final = 1
  Crypt::Sodium::XS::auth::hmacsha512256_multi::final = 2

  PREINIT:
  protmem *state_pm;
  unsigned char *out_buf;
  STRLEN bytes_len;

  CODE:
  switch(ix) {
    case 1:
      bytes_len = crypto_auth_hmacsha512_BYTES;
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512_multi");
      break;
    case 2:
      bytes_len = crypto_auth_hmacsha512256_BYTES;
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512256_multi");
      break;
    default:
      bytes_len = crypto_auth_hmacsha256_BYTES;
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha256_multi");
  }

  Newx(out_buf, bytes_len + 1, unsigned char);
  if (out_buf == NULL) {
    protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
    croak("Failed to allocate memory");
  }
  out_buf[bytes_len] = '\0';

  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to grant state protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_auth_hmacsha512_final(state_pm->pm_ptr, out_buf);
      break;
    case 2:
      crypto_auth_hmacsha512256_final(state_pm->pm_ptr, out_buf);
      break;
    default:
      crypto_auth_hmacsha256_final(state_pm->pm_ptr, out_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to release state protmem RW");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, bytes_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::auth::hmacsha512_multi::update = 1
  Crypt::Sodium::XS::auth::hmacsha512256_multi::update = 2

  PREINIT:
  protmem *state_pm;
  protmem *msg_mv = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512_multi");
      break;
    case 2:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha512256_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::auth::hmacsha256_multi");
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
        crypto_auth_hmacsha512_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      case 2:
        crypto_auth_hmacsha512256_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_auth_hmacsha256_update(state_pm->pm_ptr, msg_buf, msg_len);
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
