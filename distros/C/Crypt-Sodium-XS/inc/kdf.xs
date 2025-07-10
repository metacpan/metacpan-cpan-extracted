MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::kdf

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::kdf", 0);

  PPCODE:
  newCONSTSUB(stash, "kdf_BYTES_MAX", newSVuv(crypto_kdf_BYTES_MAX));
  newCONSTSUB(stash, "kdf_blake2b_BYTES_MAX",
              newSVuv(crypto_kdf_blake2b_BYTES_MAX));
  newCONSTSUB(stash, "kdf_BYTES_MIN", newSVuv(crypto_kdf_BYTES_MIN));
  newCONSTSUB(stash, "kdf_blake2b_BYTES_MIN",
              newSVuv(crypto_kdf_blake2b_BYTES_MIN));
  newCONSTSUB(stash, "kdf_CONTEXTBYTES", newSVuv(crypto_kdf_CONTEXTBYTES));
  newCONSTSUB(stash, "kdf_blake2b_CONTEXTBYTES",
              newSVuv(crypto_kdf_blake2b_CONTEXTBYTES));
  newCONSTSUB(stash, "kdf_KEYBYTES", newSVuv(crypto_kdf_KEYBYTES));
  newCONSTSUB(stash, "kdf_blake2b_KEYBYTES",
              newSVuv(crypto_kdf_blake2b_KEYBYTES));
  newCONSTSUB(stash, "kdf_PRIMITIVE", newSVpvs(crypto_kdf_PRIMITIVE));

SV * kdf_derive( \
  SV * key, \
  UV id, \
  STRLEN new_key_len, \
  SV * ctx = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  kdf_blake2b_derive = 1

  PREINIT:
  protmem *key_mv = NULL;
  protmem *new_key_mv;
  unsigned char *key_buf;
  char *ctx_buf = NULL;
  STRLEN key_len;
  STRLEN ctx_len;
  STRLEN key_req_len;
  STRLEN ctx_req_len;
  STRLEN new_key_req_min;
  STRLEN new_key_req_max;
  unsigned int new_key_flags;
  int (*func)(unsigned char *, size_t, uint64_t,
              const char *, const unsigned char *);

  CODE:
  if (SvOK(flags))
    new_key_flags = SvUV(flags);

  switch(ix) {
    case 1:
      key_req_len = crypto_kdf_blake2b_KEYBYTES;
      ctx_req_len = crypto_kdf_blake2b_CONTEXTBYTES;
      new_key_req_min = crypto_kdf_blake2b_BYTES_MIN;
      new_key_req_max = crypto_kdf_blake2b_BYTES_MAX;
      func = crypto_kdf_blake2b_derive_from_key;
      break;
    default:
      key_req_len = crypto_kdf_KEYBYTES;
      ctx_req_len = crypto_kdf_CONTEXTBYTES;
      new_key_req_min = crypto_kdf_BYTES_MIN;
      new_key_req_max = crypto_kdf_BYTES_MAX;
      func = crypto_kdf_derive_from_key;
  }

  if (new_key_len < new_key_req_min)
    croak("derive: Invalid derived key length (too short)");
  if (new_key_len > new_key_req_max)
    croak("derive: Invalid derived key length (too long)");

  if (SvOK(ctx)) {
    ctx_buf = SvPVbyte(ctx, ctx_len);
    if (ctx_len < ctx_req_len)
      croak("derive: Invalid context length (too short)");
  }
  else
    /* some default 8 bytes of junk. should really be ensuring this is
     * always CONTEXTBYTES long (in case it ever changes). */
    ctx_buf = "00000000";

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_mv = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_mv->pm_ptr;
    key_len = key_mv->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("derive: Invalid key length");

  if (SvOK(flags))
    new_key_flags = SvUV(flags);
  else if (key_mv)
    new_key_flags = key_mv->flags;
  else
    new_key_flags = g_protmem_flags_key_default;

  new_key_mv = protmem_init(aTHX_ key_req_len, new_key_flags);
  if (new_key_mv == NULL)
    croak("derive: Failed to allocate protmem");

  if (key_mv && protmem_grant(aTHX_ key_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_key_mv);
    croak("derive: Failed to grant key protmem RO");
  }

  func(new_key_mv->pm_ptr, new_key_len, id, ctx_buf, key_buf);

  if (key_mv && protmem_release(aTHX_ key_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_key_mv);
    croak("derive: Failed to release key protmem RO");
  }

  if (protmem_release(aTHX_ new_key_mv, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_key_mv);
    croak("derive: Failed to release protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ new_key_mv, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * kdf_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  kdf_blake2b_keygen = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_kdf_blake2b_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_kdf_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL
