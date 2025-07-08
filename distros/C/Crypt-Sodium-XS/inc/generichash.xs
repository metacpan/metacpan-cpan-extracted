MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::generichash

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::generichash", 0);

  PPCODE:
  newCONSTSUB(stash, "generichash_BYTES",
              newSVuv(crypto_generichash_BYTES));
  newCONSTSUB(stash, "generichash_blake2b_BYTES",
              newSVuv(crypto_generichash_blake2b_BYTES));
  newCONSTSUB(stash, "generichash_BYTES_MAX",
              newSVuv(crypto_generichash_BYTES_MAX));
  newCONSTSUB(stash, "generichash_blake2b_BYTES_MAX",
              newSVuv(crypto_generichash_blake2b_BYTES_MAX));
  newCONSTSUB(stash, "generichash_BYTES_MIN",
              newSVuv(crypto_generichash_BYTES_MIN));
  newCONSTSUB(stash, "generichash_blake2b_BYTES_MIN",
              newSVuv(crypto_generichash_blake2b_BYTES_MIN));
  newCONSTSUB(stash, "generichash_KEYBYTES",
              newSVuv(crypto_generichash_KEYBYTES));
  newCONSTSUB(stash, "generichash_blake2b_KEYBYTES",
              newSVuv(crypto_generichash_blake2b_KEYBYTES));
  newCONSTSUB(stash, "generichash_KEYBYTES_MAX",
              newSVuv(crypto_generichash_KEYBYTES_MAX));
  newCONSTSUB(stash, "generichash_blake2b_KEYBYTES_MAX",
              newSVuv(crypto_generichash_blake2b_KEYBYTES_MAX));
  newCONSTSUB(stash, "generichash_KEYBYTES_MIN",
              newSVuv(crypto_generichash_KEYBYTES_MIN));
  newCONSTSUB(stash, "generichash_blake2b_KEYBYTES_MIN",
              newSVuv(crypto_generichash_blake2b_KEYBYTES_MIN));
  newCONSTSUB(stash, "generichash_blake2b_PERSONALBYTES",
              newSVuv(crypto_generichash_blake2b_PERSONALBYTES));
  newCONSTSUB(stash, "generichash_blake2b_SALTBYTES",
              newSVuv(crypto_generichash_blake2b_SALTBYTES));
  newCONSTSUB(stash, "generichash_PRIMITIVE",
              newSVpvs(crypto_generichash_PRIMITIVE));

SV * generichash(SV * msg, STRLEN out_len = 0, SV * key = &PL_sv_undef)

  ALIAS:
  generichash_blake2b = 1

  PREINIT:
  protmem *key_pm = NULL;
  protmem *msg_pm = NULL;
  unsigned char *key_buf = NULL;
  unsigned char *msg_buf;
  unsigned char *out_buf;
  STRLEN msg_len;
  STRLEN key_len = 0;
  STRLEN key_req_min;
  STRLEN key_req_max;
  int (*func)(unsigned char *, size_t, const unsigned char *,
              unsigned long long, const unsigned char *, size_t);

  CODE:
  switch(ix) {
    case 1:
      if (out_len == 0)
        out_len = crypto_generichash_blake2b_BYTES;
      if (out_len < crypto_generichash_blake2b_BYTES_MIN
          || out_len > crypto_generichash_blake2b_BYTES_MAX)
        croak("generichash: Invalid output length %lu", out_len);
      key_req_min = crypto_generichash_blake2b_KEYBYTES_MIN;
      key_req_max = crypto_generichash_blake2b_KEYBYTES_MAX;
      func = crypto_generichash_blake2b;
      break;
    default:
      if (out_len == 0)
        out_len = crypto_generichash_BYTES;
      if (out_len < crypto_generichash_BYTES_MIN
          || out_len > crypto_generichash_BYTES_MAX)
        croak("generichash: Invalid output length %lu", out_len);
      key_req_min = crypto_generichash_KEYBYTES_MIN;
      key_req_max = crypto_generichash_KEYBYTES_MAX;
      func = crypto_generichash;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (SvOK(key)) {
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else {
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
    }
    if (key_len < key_req_min || key_len > key_req_max)
      croak("generichash: Invalid key length %lu", key_len);
  }

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("generichash: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("generichash: Failed to grant msg protmem RO");
  }

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash: Failed to grant key protmem RO");
  }

  func(out_buf, out_len, msg_buf, msg_len, key_buf, key_len);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("generichash: Failed to release msg protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * generichash_blake2b_init_salt_personal( \
  SV * salt, \
  SV * personal, \
  STRLEN out_len = 0, \
  SV * key = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *state_pm;
  protmem *key_pm = NULL;
  unsigned char *key_buf = NULL;
  unsigned char *salt_buf;
  unsigned char *personal_buf;
  STRLEN salt_len;
  STRLEN personal_len;
  STRLEN key_len = 0;
  HV *obj;
  unsigned int pm_flags = g_protmem_flags_state_default;

  CODE:
  if (out_len == 0)
    out_len = crypto_generichash_blake2b_BYTES;
  if (out_len < crypto_generichash_blake2b_BYTES_MIN
      || out_len > crypto_generichash_blake2b_BYTES_MAX)
    croak("generichash_init_salt_personal: Invalid output length: %lu", out_len);

  salt_buf = (unsigned char *)SvPVbyte(salt, salt_len);
  if (salt_len < crypto_generichash_blake2b_SALTBYTES)
    croak("generichash_init_salt_personal: Invalid salt length (too short) %lu", salt_len);

  personal_buf = (unsigned char *)SvPVbyte(personal, personal_len);
  if (personal_len < crypto_generichash_blake2b_PERSONALBYTES)
    croak("generichash_init_salt_personal: Invalid personalization length (too short) %lu", personal_len);

  if (SvOK(key)) {
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else {
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
    }
    if (key_len <  crypto_generichash_blake2b_KEYBYTES_MIN
        || key_len > crypto_generichash_blake2b_KEYBYTES_MAX)
      croak("generichash_init_salt_personal: Invalid key length %lu", key_len);
  }

  if (SvOK(flags))
    pm_flags = SvUV(flags);

  if (out_len < crypto_generichash_BYTES_MIN
      || out_len > crypto_generichash_BYTES_MAX)
    croak("generichash_init_salt_personal: Invalid output length: %lu", out_len);

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("generichash_init_salt_personal: Failed to grant key protmem RO");

  state_pm = protmem_init(aTHX_ sizeof(crypto_generichash_blake2b_state), pm_flags);
  if (state_pm == NULL) {
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash_init_salt_personal: Failed to allocate protmem");
  }
  crypto_generichash_blake2b_init_salt_personal(state_pm->pm_ptr, key_buf, key_len,
                                                out_len, salt_buf, personal_buf);

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash_init_salt_personal: Failed to release protmem RW");
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("generichash_init_salt_personal: Failed to release key protmem RO");
  }

  obj = newHV();
  hv_stores(obj, "out_len", newSVuv(out_len));
  hv_stores(obj, "state", protmem_to_sv(aTHX_ state_pm,
                          "Crypt::Sodium::XS::generichash::blake2b_multistate"));
  RETVAL = sv_bless(newRV_noinc((SV *)obj),
                    gv_stashpv("Crypt::Sodium::XS::generichash::blake2b_multi", GV_ADD));

  OUTPUT:
  RETVAL

SV * generichash_blake2b_salt_personal( \
  SV * msg, \
  SV * salt, \
  SV * personal, \
  STRLEN out_len = crypto_generichash_blake2b_BYTES, \
  SV * key = &PL_sv_undef \
)

  PREINIT:
  protmem *key_pm = NULL;
  protmem *msg_pm = NULL;
  unsigned char *key_buf = NULL;
  unsigned char *msg_buf;
  unsigned char *salt_buf;
  unsigned char *personal_buf;
  unsigned char *out_buf;
  STRLEN msg_len;
  STRLEN salt_len;
  STRLEN personal_len;
  STRLEN key_len = 0;

  CODE:
  salt_buf = (unsigned char *)SvPVbyte(salt, salt_len);
  if (salt_len < crypto_generichash_blake2b_SALTBYTES)
    croak("generichash_salt_personal: Invalid salt length (too short) %lu", salt_len);

  personal_buf = (unsigned char *)SvPVbyte(personal, personal_len);
  if (personal_len < crypto_generichash_blake2b_PERSONALBYTES)
    croak("generichash_salt_personal: Invalid personalization length (too short) %lu", personal_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (SvOK(key)) {
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else {
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
    }
    if (key_len < crypto_generichash_blake2b_KEYBYTES_MIN
        || key_len > crypto_generichash_blake2b_KEYBYTES_MAX)
      croak("generichash_salt_personal: Invalid key length %lu", key_len);
  }

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("generichash_salt_personal: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("generichash_salt_personal: Failed to grant msg protmem RO");
  }

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash_salt_personal: Failed to grant key protmem RO");
  }

  crypto_generichash_blake2b_salt_personal(out_buf, out_len, msg_buf, msg_len,
                                           key_buf, key_len, salt_buf, personal_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash_salt_personal: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("generichash_salt_personal: Failed to release msg protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * generichash_init( \
  STRLEN out_len = 0, \
  SV * key = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  generichash_blake2b_init = 1

  PREINIT:
  protmem *state_pm;
  protmem *key_pm = NULL;
  unsigned char *key_buf = NULL;
  STRLEN key_len = 0;
  HV *obj;
  unsigned int pm_flags = g_protmem_flags_state_default;

  CODE:
  switch(ix) {
    case 1:
      if (out_len == 0)
        out_len = crypto_generichash_blake2b_BYTES;
      if (out_len < crypto_generichash_blake2b_BYTES_MIN
          || out_len > crypto_generichash_blake2b_BYTES_MAX)
        croak("generichash_init: Invalid output length: %lu", out_len);
      break;
    default:
      if (out_len == 0)
        out_len = crypto_generichash_BYTES;
      if (out_len < crypto_generichash_BYTES_MIN
          || out_len > crypto_generichash_BYTES_MAX)
        croak("generichash_init: Invalid output length: %lu", out_len);
  }

  if (SvOK(key)) {
    if (sv_derived_from(key, MEMVAULT_CLASS)) {
      key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
      key_buf = key_pm->pm_ptr;
      key_len = key_pm->size;
    }
    else {
      key_buf = (unsigned char *)SvPVbyte(key, key_len);
    }
    if (key_len <  crypto_generichash_KEYBYTES_MIN
        || key_len > crypto_generichash_KEYBYTES_MAX)
      croak("generichash_init: Invalid key length %lu", key_len);
  }

  if (SvOK(flags))
    pm_flags = SvUV(flags);

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("generichash_init: Failed to grant key protmem RO");

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_generichash_blake2b_state), pm_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("generichash_init: Failed to allocate protmem");
      }
      crypto_generichash_blake2b_init(state_pm->pm_ptr, key_buf, key_len, out_len);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_generichash_state), pm_flags);
      if (state_pm == NULL) {
        if (key_pm)
          protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("generichash_init: Failed to allocate protmem");
      }
      crypto_generichash_init(state_pm->pm_ptr, key_buf, key_len, out_len);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("generichash_init: Failed to release protmem RW");
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("generichash_init: Failed to release key protmem RO");
  }

  obj = newHV();
  hv_stores(obj, "out_len", newSVuv(out_len));

  switch(ix) {
    case 1:
      hv_stores(obj, "state", protmem_to_sv(aTHX_ state_pm,
                              "Crypt::Sodium::XS::generichash::blake2b_multistate"));
      RETVAL = sv_bless(newRV_noinc((SV *)obj),
                        gv_stashpv("Crypt::Sodium::XS::generichash::blake2b_multi", GV_ADD));
      break;
    default:
      hv_stores(obj, "state", protmem_to_sv(aTHX_ state_pm,
                              "Crypt::Sodium::XS::generichash::multistate"));
      RETVAL = sv_bless(newRV_noinc((SV *)obj),
                        gv_stashpv("Crypt::Sodium::XS::generichash::multi", GV_ADD));
  }


  OUTPUT:
  RETVAL

SV * generichash_keygen(STRLEN key_len = 0, SV * flags = &PL_sv_undef)

  ALIAS:
  generichash_blake2b_keygen = 1

  CODE:
  switch(ix) {
    case 1:
      if (key_len == 0)
        key_len = crypto_generichash_blake2b_KEYBYTES;
      if (key_len < crypto_generichash_blake2b_KEYBYTES_MIN
          || key_len > crypto_generichash_blake2b_KEYBYTES_MAX)
        croak("generichash_keygen: Invalid key length: %lu", key_len);
      break;
    default:
      if (key_len == 0)
        key_len = crypto_generichash_KEYBYTES;
      if (key_len < crypto_generichash_KEYBYTES_MIN
          || key_len > crypto_generichash_KEYBYTES_MAX)
        croak("generichash_keygen: Invalid key length: %lu", key_len);
  }

  RETVAL = sv_keygen(aTHX_ key_len, flags);

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::generichash::multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::generichash::blake2b_multi::DESTROY = 1

  PREINIT:
  protmem *state_pm;
  SV *obj;
  SV **state;

  PPCODE:
  obj = SvRV(self);
  if (SvTYPE(obj) != SVt_PVHV)
    croak("BUG: DESTROY: not a hash ref");
  state = hv_fetchs((HV *)obj, "state", 0);
  if (state == NULL)
    croak("BUG: DESTROY: missing state");

  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::blake2b_multistate");
      break;
    default:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::multistate");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::generichash::blake2b_multi::clone = 1

  PREINIT:
  HV *newobj;
  SV *obj;
  SV **state;
  SV **newstate;

  CODE:
  obj = SvRV(self);
  if (SvTYPE(obj) != SVt_PVHV)
    croak("BUG: clone: not a hash ref");
  state = hv_fetchs((HV *)obj, "state", 0);
  if (state == NULL)
    croak("BUG: clone: missing state");

  newobj = newHVhv((HV *)obj);

  switch(ix) {
    case 1:
      newstate = hv_fetchs(newobj, "state", 0);
      if (newstate == NULL)
        croak("BUG: clone: missing state");
      /* FIXME: does the existing state sv need ref decrement? it was copied by newHVhv */
      *newstate = protmem_clone_sv(aTHX_ *state, "Crypt::Sodium::XS::generichash::blake2b_multistate");
      RETVAL = sv_bless(newRV_noinc((SV *)newobj),
                        gv_stashpv("Crypt::Sodium::XS::generichash::blake2b_multi", 0));
      break;
    default:
      newstate = hv_fetchs(newobj, "state", 0);
      if (newstate == NULL)
        croak("BUG: clone: missing state");
      /* FIXME: does the existing state sv need ref decrement? it was copied by newHVhv */
      *newstate = protmem_clone_sv(aTHX_ *state, "Crypt::Sodium::XS::generichash::multistate");
      RETVAL = sv_bless(newRV_noinc((SV *)newobj),
                        gv_stashpv("Crypt::Sodium::XS::generichash::multi", 0));
  }

  OUTPUT:
  RETVAL

SV * final(SV * self)

  ALIAS:
  Crypt::Sodium::XS::generichash::blake2b_multi::final = 1

  PREINIT:
  protmem *state_pm;
  unsigned char *out_buf;
  STRLEN out_len;
  SV *obj;
  SV **state;
  SV **fetch;

  CODE:
  obj = SvRV(self);
  if (SvTYPE(obj) != SVt_PVHV)
    croak("BUG: final: not a hash ref");
  state = hv_fetchs((HV *)obj, "state", 0);
  if (state == NULL)
    croak("BUG: final: missing state");
  fetch = hv_fetchs((HV *)obj, "out_len", 0);
  if (fetch == NULL)
    croak("BUG: final: missing out_len");
  out_len = SvUV(*fetch);

  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::blake2b_multistate");
      break;
    default:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::multistate");
  }

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("final: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to grant protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_generichash_blake2b_final(state_pm->pm_ptr, out_buf, out_len);
      break;
    default:
      crypto_generichash_final(state_pm->pm_ptr, out_buf, out_len);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(out_buf);
    croak("final: Failed to release protmem RW");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::generichash::blake2b_multi::update = 1

  PREINIT:
  protmem *state_pm;
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  STRLEN msg_len;
  SV *obj;
  SV **state;
  I32 i;

  PPCODE:
  obj = SvRV(self);
  if (SvTYPE(obj) != SVt_PVHV)
    croak("BUG: final: not a hash ref");
  state = hv_fetchs((HV *)obj, "state", 0);
  if (state == NULL)
    croak("BUG: update: missing state");

  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::blake2b_multistate");
      break;
    default:
      state_pm = protmem_get(aTHX_ *state, "Crypt::Sodium::XS::generichash::multistate");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to grant protmem RW");

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
        crypto_generichash_blake2b_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_generichash_update(state_pm->pm_ptr, msg_buf, msg_len);
    }

    if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to release msg protmem RO");
    }

    msg_pm = NULL;
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to release protmem RW");

  XSRETURN(1);
