=for documentation

libsodium secretstream includes only xchacha20poly1305-specific functions.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::secretstream

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::secretstream", 0);

  PPCODE:
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_ABYTES",
              newSVuv(crypto_secretstream_xchacha20poly1305_ABYTES));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_HEADERBYTES",
              newSVuv(crypto_secretstream_xchacha20poly1305_HEADERBYTES));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_KEYBYTES",
              newSVuv(crypto_secretstream_xchacha20poly1305_KEYBYTES));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_MESSAGEBYTES_MAX",
              newSVuv(crypto_secretstream_xchacha20poly1305_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_TAG_MESSAGE",
              newSVuv(crypto_secretstream_xchacha20poly1305_TAG_MESSAGE));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_TAG_PUSH",
              newSVuv(crypto_secretstream_xchacha20poly1305_TAG_PUSH));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_TAG_REKEY",
              newSVuv(crypto_secretstream_xchacha20poly1305_TAG_REKEY));
  newCONSTSUB(stash, "secretstream_xchacha20poly1305_TAG_FINAL",
              newSVuv(crypto_secretstream_xchacha20poly1305_TAG_FINAL));

SV * secretstream_xchacha20poly1305_init_decrypt( \
  SV * header, \
  SV * key, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  secretstream_xchacha20poly1305_init_pull = 1

  PREINIT:
  PERL_UNUSED_VAR(ix);
  protmem *state_pm;
  protmem *key_pm = NULL;
  unsigned char *header_buf;
  unsigned char *key_buf;
  STRLEN header_len;
  STRLEN key_len;
  unsigned int state_flags = g_protmem_flags_key_default;

  CODE:
  if (SvOK(flags))
    state_flags = SvUV(flags);

  header_buf = (unsigned char *)SvPVbyte(header, header_len);
  if (header_len != crypto_secretstream_xchacha20poly1305_HEADERBYTES)
    croak("secretstream_init_decrypt: Invalid header length %lu", header_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_secretstream_xchacha20poly1305_KEYBYTES)
    croak("secretstream_init_decrypt: Invalid key length %lu", key_len);

  state_pm = protmem_init(aTHX_ sizeof(crypto_secretstream_xchacha20poly1305_state), state_flags);
  if (state_pm == NULL)
    croak("secretstream_init_decrypt: Failed to allocate state protmem");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("secretstream_init_decrypt: Failed to grant key protmem RO");
  }

  crypto_secretstream_xchacha20poly1305_init_pull(state_pm->pm_ptr, header_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("secretstream_init_decrypt: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("secretstream_init_decrypt: Failed to release state protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ state_pm,
           "Crypt::Sodium::XS::secretstream::xchacha20poly1305_decrypt");

  OUTPUT:
  RETVAL

void secretstream_xchacha20poly1305_init_encrypt(SV * key, SV * flags = &PL_sv_undef)

  ALIAS:
  secretstream_xchacha20poly1305_init_push = 1

  PREINIT:
  PERL_UNUSED_VAR(ix);
  protmem *state_pm;
  protmem *key_pm = NULL;
  SV * header;
  unsigned char *key_buf;
  unsigned char *header_buf;
  STRLEN key_len;
  unsigned int state_flags = g_protmem_flags_key_default;

  PPCODE:
  if (SvOK(flags))
    state_flags = SvUV(flags);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != crypto_secretstream_xchacha20poly1305_KEYBYTES)
    croak("secretstream_init_encrypt: Invalid key length %lu", key_len);

  state_pm = protmem_init(aTHX_ sizeof(crypto_secretstream_xchacha20poly1305_state), state_flags);
  if (state_pm == NULL)
    croak("secretstream_init_encrypt: Failed to allocate state protmem");

  Newx(header_buf,
       crypto_secretstream_xchacha20poly1305_HEADERBYTES + 1, unsigned char);
  if (header_buf == NULL) {
    protmem_free(aTHX_ state_pm);
    croak("secretstream_init_encrypt: Failed to allocate memory");
  }
  header_buf[crypto_secretstream_xchacha20poly1305_HEADERBYTES] = '\0';

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    Safefree(header_buf);
    croak("secretstream_init_encrypt: Failed to grant key protmem RO");
  }

  crypto_secretstream_xchacha20poly1305_init_push(state_pm->pm_ptr, header_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("secretstream_init_encrypt: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    Safefree(header_buf);
    croak("secretstream_init_encrypt: Failed to release state protmem RW");
  }

  header = newSV(0);
  sv_usepvn_flags(header, (char *)header_buf,
                  crypto_secretstream_xchacha20poly1305_HEADERBYTES,
                  SV_HAS_TRAILING_NUL);
  mXPUSHs(header);
  mXPUSHs(protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_encrypt"));

  XSRETURN(2);

SV * secretstream_xchacha20poly1305_keygen(SV * flags = &PL_sv_undef)

  CODE:
  RETVAL = sv_keygen(aTHX_ crypto_secretstream_xchacha20poly1305_KEYBYTES, flags);

  OUTPUT:
  RETVAL


MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::secretstream::xchacha20poly1305_decrypt

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::secretstream::xchachapoly1305_encrypt = 1

  PREINIT:
  protmem *state_pm;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_encrypt");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_decrypt");
  }
  protmem_free(aTHX_ state_pm);

void decrypt( \
  SV * self, \
  SV * ciphertext, \
  SV * adata = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  pull = 1

  PREINIT:
  PERL_UNUSED_VAR(ix);
  protmem *state_pm;
  protmem *ct_pm = NULL;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *adata_buf = NULL;
  unsigned char tag;
  STRLEN ct_len;
  STRLEN adata_len = 0;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;

  PPCODE:
  if (SvOK(flags))
    msg_flags = SvUV(flags);

  if (sv_derived_from(ciphertext, MEMVAULT_CLASS)) {
    ct_pm = protmem_get(aTHX_ ciphertext, MEMVAULT_CLASS);
    ct_buf = ct_pm->pm_ptr;
    ct_len = ct_pm->size;
  }
  else
    ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < crypto_secretstream_xchacha20poly1305_ABYTES)
    croak("decrypt: Invalid ciphertext (too short): %lu", ct_len);

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  msg_pm = protmem_init(aTHX_
           ct_len - crypto_secretstream_xchacha20poly1305_ABYTES, msg_flags);
  if (msg_pm == NULL)
    croak("decrypt: Failed to allocate protmem");

  if (ct_pm && protmem_grant(aTHX_ ct_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to grant ciphertext protmem RO");
  }

  state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_decrypt");
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (ct_pm)
      protmem_release(aTHX_ ct_pm, PROTMEM_FLAG_MPROTECT_RO);
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to grant state protmem RW");
  }

  ret = crypto_secretstream_xchacha20poly1305_pull(state_pm->pm_ptr,
          msg_pm->pm_ptr, NULL, &tag, ct_buf, ct_len, adata_buf, adata_len);

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (ct_pm)
      protmem_release(aTHX_ ct_pm, PROTMEM_FLAG_MPROTECT_RO);
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to release state protmem RW");
  }

  if (ct_pm && protmem_release(aTHX_ ct_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to release ciphertext protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("Failed to protect memvault");
  }

  if (ret != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Message forged");
  }

  mXPUSHs(protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS));
  if (GIMME_V == G_ARRAY) {
    mXPUSHs(newSViv(tag));
    XSRETURN(2);
  }
  XSRETURN(1);

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::secretstream::xchacha20poly1305_encrypt

SV * encrypt( \
  SV * self, \
  SV * msg, \
  unsigned char tag = crypto_secretstream_xchacha20poly1305_TAG_MESSAGE, \
  SV * adata = &PL_sv_undef \
)

  ALIAS:
  push = 1

  PREINIT:
  PERL_UNUSED_VAR(ix);
  protmem *state_pm;
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *adata_buf = NULL;
  unsigned char *ct_buf;
  STRLEN msg_len;
  STRLEN ct_len;
  STRLEN adata_len = 0;

  CODE:
  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);
  ct_len = msg_len + crypto_secretstream_xchacha20poly1305_ABYTES;

  if (SvOK(adata))
    adata_buf = (unsigned char *)SvPVbyte(adata, adata_len);

  Newx(ct_buf, ct_len + 1, unsigned char);
  if (ct_buf == NULL)
    croak("encrypt: Failed to allocate memory");
  ct_buf[ct_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(ct_buf);
    croak("encrypt: Failed to grant msg protmem RO");
  }

  state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::secretstream::xchacha20poly1305_encrypt");
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(ct_buf);
    croak("encrypt: Failed to grant state protmem RW");
  }

  crypto_secretstream_xchacha20poly1305_push(state_pm->pm_ptr, ct_buf, NULL,
                                             msg_buf, msg_len,
                                             adata_buf, adata_len, tag);

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(ct_buf);
    croak("encrypt: Failed to release state protmem RW");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(ct_buf);
    croak("encrypt: Failed to release msg protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL
