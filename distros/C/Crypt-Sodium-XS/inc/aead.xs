=for documentation

libsodium aead provides only algorithm-specific functions.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::aead

void
_define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::aead", 0);

  PPCODE:
  newCONSTSUB(stash, "aead_chacha20poly1305_ABYTES",
              newSVuv(crypto_aead_chacha20poly1305_ABYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_ietf_ABYTES",
              newSVuv(crypto_aead_chacha20poly1305_ietf_ABYTES));
  newCONSTSUB(stash, "aead_aes256gcm_ABYTES",
              newSVuv(crypto_aead_aes256gcm_ABYTES));
  newCONSTSUB(stash, "aead_xchacha20poly1305_ietf_ABYTES",
              newSVuv(crypto_aead_xchacha20poly1305_ietf_ABYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_KEYBYTES",
              newSVuv(crypto_aead_chacha20poly1305_KEYBYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_ietf_KEYBYTES",
              newSVuv(crypto_aead_chacha20poly1305_ietf_KEYBYTES));
  newCONSTSUB(stash, "aead_aes256gcm_KEYBYTES",
              newSVuv(crypto_aead_aes256gcm_KEYBYTES));
  newCONSTSUB(stash, "aead_xchacha20poly1305_ietf_KEYBYTES",
              newSVuv(crypto_aead_xchacha20poly1305_ietf_KEYBYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_chacha20poly1305_KEYBYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_ietf_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_chacha20poly1305_ietf_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "aead_aes256gcm_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_aes256gcm_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "aead_xchacha20poly1305_ietf_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_xchacha20poly1305_ietf_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "aead_chacha20poly1305_NPUBBYTES",
              newSVuv(crypto_aead_chacha20poly1305_NPUBBYTES));
  newCONSTSUB(stash, "aead_chacha20poly1305_ietf_NPUBBYTES",
              newSVuv(crypto_aead_chacha20poly1305_ietf_NPUBBYTES));
  newCONSTSUB(stash, "aead_aes256gcm_NPUBBYTES",
              newSVuv(crypto_aead_aes256gcm_NPUBBYTES));
  newCONSTSUB(stash, "aead_xchacha20poly1305_ietf_NPUBBYTES",
              newSVuv(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES));
#ifdef SODIUM_HAS_AEGIS
  newCONSTSUB(stash, "aead_aegis128l_ABYTES",
              newSVuv(crypto_aead_aegis128l_ABYTES));
  newCONSTSUB(stash, "aead_aegis256_ABYTES",
              newSVuv(crypto_aead_aegis256_ABYTES));
  newCONSTSUB(stash, "aead_aegis128l_KEYBYTES",
              newSVuv(crypto_aead_aegis128l_KEYBYTES));
  newCONSTSUB(stash, "aead_aegis256_KEYBYTES",
              newSVuv(crypto_aead_aegis256_KEYBYTES));
  newCONSTSUB(stash, "aead_aegis128l_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_aegis128l_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "aead_aegis256_MESSAGEBYTES_MAX",
              newSVuv(crypto_aead_aegis256_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "aead_aegis128l_NPUBBYTES",
              newSVuv(crypto_aead_aegis128l_NPUBBYTES));
  newCONSTSUB(stash, "aead_aegis256_NPUBBYTES",
              newSVuv(crypto_aead_aegis256_NPUBBYTES));
#endif
=for notes
nsec is not used by libsodium aead algorithms. provided for completeness.
=cut
  newCONSTSUB(stash, "aead_chacha20poly1305_NSECBYTES", newSVuv(0));
  newCONSTSUB(stash, "aead_chacha20poly1305_ietf_NSECBYTES", newSVuv(0));
  newCONSTSUB(stash, "aead_aes256gcm_NSECBYTES", newSVuv(0));
#ifdef SODIUM_HAS_AEGIS
  newCONSTSUB(stash, "aead_aegis128l_NSECBYTES", newSVuv(0));
  newCONSTSUB(stash, "aead_aegis256_NSECBYTES", newSVuv(0));
#endif
  newCONSTSUB(stash, "aead_xchacha20poly1305_NSECBYTES", newSVuv(0));
  newCONSTSUB(stash, "aead_aes256gcm_available",
              has_aes256gcm ? &PL_sv_yes : &PL_sv_no);
#ifdef SODIUM_HAS_AEGIS
  newCONSTSUB(stash, "aead_aegis_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "aead_aegis_available", &PL_sv_no);
#endif

SV * aead_aes256gcm_beforenm(SV * key, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *precalc_pm;
  protmem *key_pm = NULL;
  unsigned char *key_buf;
  STRLEN key_len;
  unsigned int precalc_pm_flags = g_protmem_flags_key_default;

  CODE:
  if (!has_aes256gcm)
    croak("aead_beforenm: AES256GCM is not supported on this cpu");

  if (SvOK(flags))
    precalc_pm_flags = SvUV(flags);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_aead_aes256gcm_KEYBYTES)
    croak("aead_beforenm: Invalid key length %lu", key_len);

  precalc_pm = protmem_init(aTHX_ sizeof(crypto_aead_aes256gcm_state), precalc_pm_flags);
  if (precalc_pm == NULL)
    croak("aead_beforenm: Failed to allocate protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("aead_beforenm: Failed to grant key protmem RO");
  }

  crypto_aead_aes256gcm_beforenm(precalc_pm->pm_ptr, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("aead_beforenm: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("aead_beforenm: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ precalc_pm, "Crypt::Sodium::XS::aead::precalc");

  OUTPUT:
  RETVAL

SV * aead_chacha20poly1305_decrypt( \
  SV * ciphertext, \
  SV * nonce, \
  SV * key, \
  SV * adata = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  aead_chacha20poly1305_ietf_decrypt = 1
  aead_aes256gcm_decrypt = 2
  aead_xchacha20poly1305_ietf_decrypt = 3
  aead_aegis128l_decrypt = 4
  aead_aegis256_decrypt = 5

  PREINIT:
  protmem *key_pm = NULL;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  STRLEN ct_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN adata_req_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, unsigned long long *, unsigned char *,
              const unsigned char *, unsigned long long, const unsigned char *,
              unsigned long long, const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      adata_req_len = crypto_aead_chacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_ietf_KEYBYTES;
      func = crypto_aead_chacha20poly1305_ietf_decrypt;
      break;
    case 2:
      if (!has_aes256gcm)
        croak("aead_decrypt: AES256GCM is not supported by this CPU");
      adata_req_len = crypto_aead_aes256gcm_ABYTES;
      nonce_req_len = crypto_aead_aes256gcm_NPUBBYTES;
      key_req_len = crypto_aead_aes256gcm_KEYBYTES;
      func = crypto_aead_aes256gcm_decrypt;
      break;
    case 3:
      adata_req_len = crypto_aead_xchacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_xchacha20poly1305_ietf_KEYBYTES;
      func = crypto_aead_xchacha20poly1305_ietf_decrypt;
      break;
    case 4:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_decrypt: AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis128l_ABYTES;
      nonce_req_len = crypto_aead_aegis128l_NPUBBYTES;
      key_req_len = crypto_aead_aegis128l_KEYBYTES;
      func = crypto_aead_aegis128l_decrypt;
#endif
      break;
    case 5:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_decrypt: AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis256_ABYTES;
      nonce_req_len = crypto_aead_aegis256_NPUBBYTES;
      key_req_len = crypto_aead_aegis256_KEYBYTES;
      func = crypto_aead_aegis256_decrypt;
#endif
      break;
    default:
      adata_req_len = crypto_aead_chacha20poly1305_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_KEYBYTES;
      func = crypto_aead_chacha20poly1305_decrypt;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < adata_req_len)
    croak("aead_decrypt: Invalid ciphertext length (too short)");

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("aead_decrypt: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("aead_decrypt: Invalid key length %lu:", key_len);

  msg_pm = protmem_init(aTHX_ ct_len - adata_req_len, msg_flags);
  if (msg_pm == NULL)
    croak("aead_decrypt: Failed to allocate protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt: Failed to grant key protmem RO");
  }

  ret = func(msg_pm->pm_ptr, NULL, NULL, ct_buf, ct_len,
             adata_buf, adata_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt: Message forged");
  }

  OUTPUT:
  RETVAL

SV * aead_chacha20poly1305_decrypt_detached( \
  SV * ciphertext, \
  SV * mac, \
  SV * nonce, \
  SV * key, \
  SV * adata = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  aead_chacha20poly1305_ietf_decrypt_detached = 1
  aead_aes256gcm_decrypt_detached = 2
  aead_xchacha20poly1305_ietf_decrypt_detached = 3
  aead_aegis128l_decrypt_detached = 4
  aead_aegis256_decrypt_detached = 5

  PREINIT:
  protmem *key_pm = NULL;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  STRLEN ct_len;
  STRLEN mac_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN adata_req_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      adata_req_len = crypto_aead_chacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_ietf_KEYBYTES;
      func = crypto_aead_chacha20poly1305_ietf_decrypt_detached;
      break;
    case 2:
      adata_req_len = crypto_aead_aes256gcm_ABYTES;
      nonce_req_len = crypto_aead_aes256gcm_NPUBBYTES;
      key_req_len = crypto_aead_aes256gcm_KEYBYTES;
      func = crypto_aead_aes256gcm_decrypt_detached;
      break;
    case 3:
      adata_req_len = crypto_aead_xchacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_xchacha20poly1305_ietf_KEYBYTES;
      func = crypto_aead_xchacha20poly1305_ietf_decrypt_detached;
      break;
    case 4:
#ifndef SODIUM_HAS_AEGIS
      croak("AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis128l_ABYTES;
      nonce_req_len = crypto_aead_aegis128l_NPUBBYTES;
      key_req_len = crypto_aead_aegis128l_KEYBYTES;
      func = crypto_aead_aegis128l_decrypt_detached;
#endif
      break;
    case 5:
#ifndef SODIUM_HAS_AEGIS
      croak("AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis256_ABYTES;
      nonce_req_len = crypto_aead_aegis256_NPUBBYTES;
      key_req_len = crypto_aead_aegis256_KEYBYTES;
      func = crypto_aead_aegis256_decrypt_detached;
#endif
      break;
    default:
      adata_req_len = crypto_aead_chacha20poly1305_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_KEYBYTES;
      func = crypto_aead_chacha20poly1305_decrypt_detached;
  }

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != adata_req_len)
    croak("aead_decrypt_detached: Invalid mac length %lu", mac_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("aead_decrypt_detached: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("aead_decrypt_detached: Invalid key length %lu", key_len);

  msg_pm = protmem_init(aTHX_ ct_len, msg_flags);
  if (msg_pm == NULL)
    croak("aead_decrypt_detached: Failed to allocate protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt_detached: Failed to grant key protmem RO");
  }

  ret = func(msg_pm->pm_ptr, NULL, ct_buf, ct_len, mac_buf,
             adata_buf, adata_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt_detached: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt_detached: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("aead_decrypt_detached: Message forged");
  }

  OUTPUT:
  RETVAL

void aead_chacha20poly1305_encrypt( \
  SV * msg, \
  SV * nonce, \
  SV * key, \
  SV * adata = &PL_sv_undef \
)

  ALIAS:
  aead_chacha20poly1305_encrypt_detached = 1
  aead_chacha20poly1305_ietf_encrypt = 2
  aead_chacha20poly1305_ietf_encrypt_detached = 3
  aead_aes256gcm_encrypt = 4
  aead_aes256gcm_encrypt_detached = 5
  aead_xchacha20poly1305_ietf_encrypt = 6
  aead_xchacha20poly1305_ietf_encrypt_detached = 7
  aead_aegis128l_encrypt = 8
  aead_aegis128l_encrypt_detached = 9
  aead_aegis256_encrypt = 10
  aead_aegis256_encrypt_detached = 11

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  SV * ct;
  SV * adata_out = NULL;
  unsigned char *msg_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *ct_buf;
  unsigned char *adata_out_buf;
  STRLEN msg_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN adata_req_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  int (*comb_func)(unsigned char *, unsigned long long *, const unsigned char *,
                   unsigned long long, const unsigned char *, unsigned long long,
                   const unsigned char *, const unsigned char *, const unsigned char *);
  int (*detached_func)(unsigned char *, unsigned char *, unsigned long long *,
                       const unsigned char *, unsigned long long, const unsigned char *,
                       unsigned long long, const unsigned char *, const unsigned char *,
                       const unsigned char *);

  PPCODE:
  switch(ix) {
    case 2: /* fallthrough */
    case 3:
      adata_req_len = crypto_aead_chacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_ietf_KEYBYTES;
      comb_func = crypto_aead_chacha20poly1305_ietf_encrypt;
      detached_func = crypto_aead_chacha20poly1305_ietf_encrypt_detached;
      break;
    case 4: /* fallthrough */
    case 5:
      if (!has_aes256gcm)
        croak("aead_encrypt: AES256GCM is not supported by this CPU");
      adata_req_len = crypto_aead_aes256gcm_ABYTES;
      nonce_req_len = crypto_aead_aes256gcm_NPUBBYTES;
      key_req_len = crypto_aead_aes256gcm_KEYBYTES;
      comb_func = crypto_aead_aes256gcm_encrypt;
      detached_func = crypto_aead_aes256gcm_encrypt_detached;
      break;
    case 6: /* fallthrough */
    case 7:
      adata_req_len = crypto_aead_xchacha20poly1305_ietf_ABYTES;
      nonce_req_len = crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;
      key_req_len = crypto_aead_xchacha20poly1305_ietf_KEYBYTES;
      comb_func = crypto_aead_xchacha20poly1305_ietf_encrypt;
      detached_func = crypto_aead_xchacha20poly1305_ietf_encrypt_detached;
      break;
    case 8: /* fallthrough */
    case 9:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_encrypt: AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis128l_ABYTES;
      nonce_req_len = crypto_aead_aegis128l_NPUBBYTES;
      key_req_len = crypto_aead_aegis128l_KEYBYTES;
      comb_func = crypto_aead_aegis128l_encrypt;
      detached_func = crypto_aead_aegis128l_encrypt_detached;
#endif
      break;
    case 10: /* fallthrough */
    case 11:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_encrypt: AEGIS not supported by this version of libsodium");
#else
      adata_req_len = crypto_aead_aegis256_ABYTES;
      nonce_req_len = crypto_aead_aegis256_NPUBBYTES;
      key_req_len = crypto_aead_aegis256_KEYBYTES;
      comb_func = crypto_aead_aegis256_encrypt;
      detached_func = crypto_aead_aegis256_encrypt_detached;
#endif
      break;
    case 1: /* fallthrough */
    default:
      adata_req_len = crypto_aead_chacha20poly1305_ABYTES;
      nonce_req_len = crypto_aead_chacha20poly1305_NPUBBYTES;
      key_req_len = crypto_aead_chacha20poly1305_KEYBYTES;
      comb_func = crypto_aead_chacha20poly1305_encrypt;
      detached_func = crypto_aead_chacha20poly1305_encrypt_detached;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("aead_encrypt: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

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
  if (key_len != key_req_len)
    croak("aead_encrypt: Invalid key length %lu", key_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("aead_encrypt: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("aead_encrypt: Failed to grant key protmem RO");
  }

  /* NB: odd aliases are _detached, even ones are combined */
  if (ix & 1) {
    Newx(ct_buf, msg_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("aead_encrypt: Failed to allocate memory");
    }
    ct_buf[msg_len] = '\0';

    Newx(adata_out_buf, adata_req_len + 1, unsigned char);
    if (adata_out_buf == NULL) {
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("aead_encrypt: Failed to allocate memory");
    }
    adata_out_buf[adata_req_len] = '\0';

    detached_func(ct_buf, adata_out_buf, NULL, msg_buf, msg_len,
                  adata_buf, adata_len, NULL, nonce_buf, key_buf);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);
    adata_out = newSV(0);
    sv_usepvn_flags(adata_out, (char *)adata_out_buf, adata_req_len,
                    SV_HAS_TRAILING_NUL);
  }
  else {
    STRLEN ct_len = adata_req_len + msg_len;

    Newx(ct_buf, ct_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (key_pm)
        protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("aead_encrypt: Failed to allocate memory");
    }
    ct_buf[ct_len] = '\0';

    comb_func(ct_buf, NULL, msg_buf, msg_len,
              adata_buf, adata_len, NULL, nonce_buf, key_buf);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);
  }

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("aead_encrypt: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("aead_encrypt: Failed to release msg protmem RO");

  mXPUSHs(ct);

  if (ix & 1) {
    mXPUSHs(adata_out);
    XSRETURN(2);
  }

  XSRETURN(1);

SV * aead_chacha20poly1305_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  aead_chacha20poly1305_ietf_keygen = 1
  aead_aes256gcm_keygen = 2
  aead_xchacha20poly1305_ietf_keygen = 3
  aead_aegis128l_keygen = 4
  aead_aegis256_keygen = 5

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_aead_chacha20poly1305_ietf_KEYBYTES, flags);
      break;
    case 2:
      if (!has_aes256gcm)
        croak("aead_keygen: AES256GCM is not supported by this CPU");
      RETVAL = sv_keygen(aTHX_ crypto_aead_aes256gcm_KEYBYTES, flags);
      break;
    case 3:
      RETVAL = sv_keygen(aTHX_ crypto_aead_xchacha20poly1305_ietf_KEYBYTES, flags);
      break;
    case 4:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_keygen: AEGIS not supported by this version of libsodium");
#else
      RETVAL = sv_keygen(aTHX_ crypto_aead_aegis128l_KEYBYTES, flags);
#endif
      break;
    case 5:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_keygen: AEGIS not supported by this version of libsodium");
#else
      RETVAL = sv_keygen(aTHX_ crypto_aead_aegis256_KEYBYTES, flags);
#endif
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_aead_chacha20poly1305_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL

SV * aead_chacha20poly1305_nonce(SV * base = &PL_sv_undef)

  ALIAS:
  aead_chacha20poly1305_ietf_nonce = 1
  aead_aes256gcm_nonce = 2
  aead_xchacha20poly1305_ietf_nonce = 3
  aead_aegis128l_nonce = 4
  aead_aegis256_nonce = 5

  CODE:
  switch(ix) {
    case 1:
      RETVAL = nonce_generate(aTHX_ crypto_aead_chacha20poly1305_ietf_NPUBBYTES, base);
      break;
    case 2:
      if (!has_aes256gcm)
        croak("aead_nonce: AES256GCM is not supported by this CPU");
      RETVAL = nonce_generate(aTHX_ crypto_aead_aes256gcm_NPUBBYTES, base);
      break;
    case 3:
      RETVAL = nonce_generate(aTHX_ crypto_aead_xchacha20poly1305_ietf_NPUBBYTES, base);
      break;
    case 4:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_nonce: AEGIS not supported by this version of libsodium");
#else
      RETVAL = nonce_generate(aTHX_ crypto_aead_aegis128l_NPUBBYTES, base);
#endif
      break;
    case 5:
#ifndef SODIUM_HAS_AEGIS
      croak("aead_nonce: AEGIS not supported by this version of libsodium");
#else
      RETVAL = nonce_generate(aTHX_ crypto_aead_aegis256_NPUBBYTES, base);
#endif
      break;
    default:
      RETVAL = nonce_generate(aTHX_ crypto_aead_chacha20poly1305_NPUBBYTES, base);
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::aead::precalc

void DESTROY(SV * self)

  PREINIT:
  protmem *precalc_pm;

  PPCODE:
  precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::aead::precalc");
  protmem_free(aTHX_ precalc_pm);

SV * decrypt( \
  SV * self, \
  SV * ciphertext, \
  SV * nonce, \
  SV * adata = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *precalc_pm;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  STRLEN ct_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;

  CODE:
  if (!has_aes256gcm)
    croak("decrypt: AES256GCM is not supported by this CPU");

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < crypto_aead_aes256gcm_ABYTES)
    croak("decrypt: Invalid ciphertext length (too short)");

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_aead_aes256gcm_NPUBBYTES)
    croak("decrypt: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  msg_pm = protmem_init(aTHX_ ct_len - crypto_aead_aes256gcm_ABYTES, msg_flags);
  if (msg_pm == NULL)
    croak("decrypt: Failed to allocate protmem");

  precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::aead::precalc");
  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to grant protmem RO");
  }

  ret = crypto_aead_aes256gcm_decrypt_afternm(msg_pm->pm_ptr, NULL, NULL,
        ct_buf, ct_len, adata_buf, adata_len, nonce_buf,
        (crypto_aead_aes256gcm_state *)precalc_pm->pm_ptr);

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to release procmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Message forged");
  }

  OUTPUT:
  RETVAL

SV * decrypt_detached( \
  SV * self, \
  SV * ciphertext, \
  SV * mac, \
  SV * nonce, \
  SV * adata = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *precalc_pm;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  STRLEN ct_len;
  STRLEN mac_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;

  CODE:
  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != crypto_aead_aes256gcm_ABYTES)
    croak("decrypt_detached: Invalid mac length %lu", mac_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_aead_aes256gcm_NPUBBYTES)
    croak("decrypt_detached: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  msg_pm = protmem_init(aTHX_ ct_len, msg_flags);
  if (msg_pm == NULL)
    croak("decrypt_detached: Failed to allocate protmem");

  precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::aead::precalc");
  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Failed to grant protmem RO");
  }

  ret = crypto_aead_aes256gcm_decrypt_detached_afternm(
    msg_pm->pm_ptr, NULL, ct_buf, ct_len, mac_buf, adata_buf, adata_len,
    nonce_buf, (crypto_aead_aes256gcm_state *)precalc_pm->pm_ptr
  );

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Failed to release protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Message forged");
  }

  OUTPUT:
  RETVAL

void encrypt(SV * self, SV * msg, SV * nonce, SV * adata = &PL_sv_undef)

  ALIAS:
  encrypt_detached = 1

  PREINIT:
  protmem *precalc_pm;
  protmem *msg_pm = NULL;
  SV * ct;
  SV * adata_out = NULL;
  unsigned char *msg_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *nonce_buf;
  unsigned char *ct_buf;
  unsigned char *adata_out_buf;
  STRLEN msg_len;
  STRLEN adata_len = 0;
  STRLEN nonce_len;

  PPCODE:
  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_aead_aes256gcm_NPUBBYTES)
    croak("encrypt: Invalid nonce length %lu", nonce_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("encrypt: Failed to grant msg protmem RO");

  precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::aead::precalc");
  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("encrypt: Failed to grant protmem RW");
  }

  if (ix == 1) {
    Newx(ct_buf, msg_len + 1, unsigned char);
    if (ct_buf == NULL) {
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("encrypt: Failed to allocate memory");
    }
    ct_buf[msg_len] = '\0';

    Newx(adata_out_buf, crypto_aead_aes256gcm_ABYTES + 1, unsigned char);
    if (adata_out_buf == NULL) {
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("encrypt: Failed to allocate memory");
    }
    adata_out_buf[crypto_aead_aes256gcm_ABYTES] = '\0';

    crypto_aead_aes256gcm_encrypt_detached_afternm(
      ct_buf, adata_out_buf, NULL, msg_buf, msg_len, adata_buf, adata_len,
      NULL, nonce_buf, (crypto_aead_aes256gcm_state *)precalc_pm->pm_ptr
    );

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);
    adata_out = newSV(0);
    sv_usepvn_flags(adata_out, (char *)adata_out_buf,
                    crypto_aead_aes256gcm_ABYTES, SV_HAS_TRAILING_NUL);
  }
  else {
    STRLEN ct_len = crypto_aead_aes256gcm_ABYTES + msg_len;

    Newx(ct_buf, ct_len + 1, unsigned char);
    if (ct_buf == NULL) {
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("encrypt: Failed to allocate memory");
    }
    ct_buf[ct_len] = '\0';

    crypto_aead_aes256gcm_encrypt_afternm(
      ct_buf, NULL, msg_buf, msg_len, adata_buf, adata_len,
      NULL, nonce_buf, (crypto_aead_aes256gcm_state *)precalc_pm->pm_ptr);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);
  }

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("encrypt: Failed to release protmem RW");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("encrypt: Failed to release msg protmem RO");

  mXPUSHs(ct);

  if (ix & 1) {
    mXPUSHs(adata_out);
    XSRETURN(2);
  }

  XSRETURN(1);
