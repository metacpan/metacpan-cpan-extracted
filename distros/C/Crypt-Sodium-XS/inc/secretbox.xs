=for documentation

similar to the situation with kx, libsodium does not have separate secretbox
functions for xsalsa20poly1305 _easy, _detached, _open_easy, or _open_detached.
it is the default algorithm for them. aliases are still provided, and just fall
through to the defaults.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::secretbox

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::secretbox", 0);

  PPCODE:
  newCONSTSUB(stash, "secretbox_KEYBYTES", newSVuv(crypto_secretbox_KEYBYTES));
  newCONSTSUB(stash, "secretbox_xchacha20poly1305_KEYBYTES",
              newSVuv(crypto_secretbox_xchacha20poly1305_KEYBYTES));
  newCONSTSUB(stash, "secretbox_xsalsa20poly1305_KEYBYTES",
              newSVuv(crypto_secretbox_xsalsa20poly1305_KEYBYTES));
  newCONSTSUB(stash, "secretbox_MACBYTES", newSVuv(crypto_secretbox_MACBYTES));
  newCONSTSUB(stash, "secretbox_xchacha20poly1305_MACBYTES",
              newSVuv(crypto_secretbox_xchacha20poly1305_MACBYTES));
  newCONSTSUB(stash, "secretbox_xsalsa20poly1305_MACBYTES",
              newSVuv(crypto_secretbox_xsalsa20poly1305_MACBYTES));
  newCONSTSUB(stash, "secretbox_NONCEBYTES",
              newSVuv(crypto_secretbox_NONCEBYTES));
  newCONSTSUB(stash, "secretbox_xchacha20poly1305_NONCEBYTES",
              newSVuv(crypto_secretbox_xchacha20poly1305_NONCEBYTES));
  newCONSTSUB(stash, "secretbox_xsalsa20poly1305_NONCEBYTES",
              newSVuv(crypto_secretbox_xsalsa20poly1305_NONCEBYTES));
  newCONSTSUB(stash, "secretbox_PRIMITIVE", newSVpvs(crypto_secretbox_PRIMITIVE));

SV * secretbox_decrypt( \
  SV * ciphertext, \
  SV * nonce, \
  SV * key, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  secretbox_xchacha20poly1305_decrypt = 1
  secretbox_xsalsa20poly1305_decrypt = 2

  PREINIT:
  protmem *msg_pm;
  protmem *key_pm = NULL;
  unsigned char *ct_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  STRLEN ct_len;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  STRLEN mac_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *,
              const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_secretbox_xchacha20poly1305_NONCEBYTES;
      key_req_len = crypto_secretbox_xchacha20poly1305_KEYBYTES;
      mac_len = crypto_secretbox_xchacha20poly1305_MACBYTES;
      func = crypto_secretbox_xchacha20poly1305_open_easy;
      break;
    case 2: /* fallthrough */
    default:
      nonce_req_len = crypto_secretbox_NONCEBYTES;
      key_req_len = crypto_secretbox_KEYBYTES;
      mac_len = crypto_secretbox_MACBYTES;
      func = crypto_secretbox_open_easy;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < mac_len)
    croak("secretbox_decrypt: Invalid ciphertext length (too short)");

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("secretbox_decrypt: Invalid nonce length %lu", nonce_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("secretbox_decrypt: Invalid key length %lu", key_len);

  msg_pm = protmem_init(aTHX_ ct_len - mac_len, msg_flags);
  if (msg_pm == NULL)
    croak("secretbox_decrypt: Failed to allocate protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt: Failed to grant key protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, ct_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt: Message forged");
  }

  OUTPUT:
  RETVAL

SV * secretbox_decrypt_detached( \
  SV * ciphertext, \
  SV * mac, \
  SV * nonce, \
  SV * key, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  secretbox_xchacha20poly1305_decrypt_detached = 1
  secretbox_xsalsa20poly1305_decrypt_detached = 2

  PREINIT:
  protmem *msg_pm;
  protmem *key_pm = NULL;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  STRLEN ct_len;
  STRLEN mac_len;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN mac_req_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              const unsigned char *, unsigned long long,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_secretbox_xchacha20poly1305_NONCEBYTES;
      key_req_len = crypto_secretbox_xchacha20poly1305_KEYBYTES;
      mac_req_len = crypto_secretbox_xchacha20poly1305_MACBYTES;
      func = crypto_secretbox_xchacha20poly1305_open_detached;
      break;
    case 2: /* fallthrough */
    default:
      nonce_req_len = crypto_secretbox_NONCEBYTES;
      key_req_len = crypto_secretbox_KEYBYTES;
      mac_req_len = crypto_secretbox_MACBYTES;
      func = crypto_secretbox_open_detached;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != mac_req_len)
    croak("secretbox_decrypt_detached: Invalid mac length: %lu", mac_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("secretbox_decrypt_detached: Invalid nonce length: %lu", nonce_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("secretbox_decrypt_detached: Invalid key length: %lu", key_len);

  msg_pm = protmem_init(aTHX_ ct_len, msg_flags);
  if (msg_pm == NULL)
    croak("secretbox_decrypt_detached: Failed to allocate protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt_detached: Failed to grant key protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, mac_buf, ct_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt_detached: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt_detached: Failed to release msg protmem RO");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("secretbox_decrypt_detached: Message forged");
  }

  OUTPUT:
  RETVAL

void secretbox_encrypt(SV * msg, SV * nonce, SV * key)

  ALIAS:
  secretbox_encrypt_detached = 1
  secretbox_xchacha20poly1305_encrypt = 2
  secretbox_xchacha20poly1305_encrypt_detached = 3
  secretbox_xsalsa20poly1305_encrypt = 4
  secretbox_xsalsa20poly1305_encrypt_detached = 5

  PREINIT:
  protmem *key_pm = NULL;
  protmem *msg_mv = NULL;
  SV *ct;
  SV *mac = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  STRLEN mac_len;
  int (*detached_func)(unsigned char *, unsigned char *,
                       const unsigned char *, unsigned long long,
                       const unsigned char *, const unsigned char *);
  int (*easy_func)(unsigned char *, const unsigned char *,
                   unsigned long long, const unsigned char *,
                   const unsigned char *);

  PPCODE:
  switch(ix) {
    case 2:
    case 3: /* fallthrough */
      nonce_req_len = crypto_secretbox_xchacha20poly1305_NONCEBYTES;
      key_req_len = crypto_secretbox_xchacha20poly1305_KEYBYTES;
      mac_len = crypto_secretbox_xchacha20poly1305_MACBYTES;
      detached_func = crypto_secretbox_xchacha20poly1305_detached;
      easy_func = crypto_secretbox_xchacha20poly1305_easy;
      break;
    case 4: /* fallthrough */
    case 5: /* fallthrough */
    case 1: /* fallthrough */
    default:
      nonce_req_len = crypto_secretbox_NONCEBYTES;
      key_req_len = crypto_secretbox_KEYBYTES;
      mac_len = crypto_secretbox_MACBYTES;
      detached_func = crypto_secretbox_detached;
      easy_func = crypto_secretbox_easy;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("secretbox_encrypt: Invalid nonce length %lu", nonce_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("secretbox_encrypt: Invalid key length %lu", key_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_mv = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_mv->pm_ptr;
    msg_len = msg_mv->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("secretbox_encrypt: Failed to grant key protmem RO");

  if (msg_mv && protmem_grant(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("secretbox_encrypt: Failed to grant msg protmem RO");
  }

  /* NB: odd aliases are _detached, even are combined */
  if (ix & 1) {
    /* detached mode */
    Newx(mac_buf, mac_len + 1, unsigned char);
    if (mac_buf == NULL) {
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      croak("secretbox_encrypt: Failed to allocate memory");
    }
    mac_buf[mac_len] = '\0';
    Newx(ct_buf, msg_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      Safefree(mac_buf);
      croak("secretbox_encrypt: Failed to allocate memory");
    }
    ct_buf[msg_len] = '\0';

    detached_func(ct_buf, mac_buf, msg_buf, msg_len, nonce_buf, key_buf);

    mac = newSV(0);
    sv_usepvn_flags(mac, (char *)mac_buf, mac_len, SV_HAS_TRAILING_NUL);
    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);
  }
  else {
    /* combined mode */
    STRLEN ct_len = mac_len + msg_len;

    Newx(ct_buf, ct_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      croak("secretbox_encrypt: Failed to allocate memory");
    }
    ct_buf[ct_len] = '\0';

    easy_func(ct_buf, msg_buf, msg_len, nonce_buf, key_buf);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_mv)
      protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
    croak("secretbox_encrypt: Failed to release key protmem RO");
  }
  if (msg_mv && protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("secretbox_encrypt: Failed to release msg protmem RO");

  mXPUSHs(ct);

  if (ix & 1) {
    mXPUSHs(mac);
    XSRETURN(2);
  }

  XSRETURN(1);

SV * secretbox_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  secretbox_xchacha20poly1305_keygen = 1
  secretbox_xsalsa20poly1305_keygen = 2

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_secretbox_xchacha20poly1305_KEYBYTES, flags);
      break;
    case 2:
      RETVAL = sv_keygen(aTHX_ crypto_secretbox_xsalsa20poly1305_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_secretbox_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL

SV * secretbox_nonce(SV * base = &PL_sv_undef)

  ALIAS:
  secretbox_xchacha20poly1305_nonce = 1
  secretbox_xsalsa20poly1305_nonce = 2

  CODE:
  switch(ix) {
    case 1:
      RETVAL = nonce_generate(aTHX_ crypto_secretbox_xchacha20poly1305_NONCEBYTES, base);
      break;
    case 2:
      RETVAL = nonce_generate(aTHX_ crypto_secretbox_xsalsa20poly1305_NONCEBYTES, base);
      break;
    default:
      RETVAL = nonce_generate(aTHX_ crypto_secretbox_NONCEBYTES, base);
  }

  OUTPUT:
  RETVAL
