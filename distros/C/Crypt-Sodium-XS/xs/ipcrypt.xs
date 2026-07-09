MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::ipcrypt

=for doc

# NB: some constants added for consistency which are not provided by libsodium.
# for deterministic and pfx INPUTBYTES and OUTPUTBYTES are defined to be the
# same as BYTES. TWEAKBYTES is also defined as a constant of 0.

=cut

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::ipcrypt", 0);

  PPCODE:
#ifdef SODIUM_HAS_IPCRYPT
  newCONSTSUB(stash, "ipcrypt_BYTES",
              newSVuv(crypto_ipcrypt_BYTES));
  newCONSTSUB(stash, "ipcrypt_INPUTBYTES",
              newSVuv(crypto_ipcrypt_BYTES));
  newCONSTSUB(stash, "ipcrypt_KEYBYTES",
              newSVuv(crypto_ipcrypt_KEYBYTES));
  newCONSTSUB(stash, "ipcrypt_OUTPUTBYTES",
              newSVuv(crypto_ipcrypt_BYTES));
  newCONSTSUB(stash, "ipcrypt_TWEAKBYTES",
              newSVuv(0));
  newCONSTSUB(stash, "ipcrypt_ND_INPUTBYTES",
              newSVuv(crypto_ipcrypt_ND_INPUTBYTES));
  newCONSTSUB(stash, "ipcrypt_ND_KEYBYTES",
              newSVuv(crypto_ipcrypt_ND_KEYBYTES));
  newCONSTSUB(stash, "ipcrypt_ND_OUTPUTBYTES",
              newSVuv(crypto_ipcrypt_ND_OUTPUTBYTES));
  newCONSTSUB(stash, "ipcrypt_ND_TWEAKBYTES",
              newSVuv(crypto_ipcrypt_ND_TWEAKBYTES));
  newCONSTSUB(stash, "ipcrypt_NDX_INPUTBYTES",
              newSVuv(crypto_ipcrypt_NDX_INPUTBYTES));
  newCONSTSUB(stash, "ipcrypt_NDX_KEYBYTES",
              newSVuv(crypto_ipcrypt_NDX_KEYBYTES));
  newCONSTSUB(stash, "ipcrypt_NDX_OUTPUTBYTES",
              newSVuv(crypto_ipcrypt_NDX_OUTPUTBYTES));
  newCONSTSUB(stash, "ipcrypt_NDX_TWEAKBYTES",
              newSVuv(crypto_ipcrypt_NDX_TWEAKBYTES));
  newCONSTSUB(stash, "ipcrypt_PFX_BYTES",
              newSVuv(crypto_ipcrypt_PFX_BYTES));
  newCONSTSUB(stash, "ipcrypt_PFX_INPUTBYTES",
              newSVuv(crypto_ipcrypt_PFX_BYTES));
  newCONSTSUB(stash, "ipcrypt_PFX_KEYBYTES",
              newSVuv(crypto_ipcrypt_PFX_KEYBYTES));
  newCONSTSUB(stash, "ipcrypt_PFX_OUTPUTBYTES",
              newSVuv(crypto_ipcrypt_PFX_BYTES));
  newCONSTSUB(stash, "ipcrypt_PFX_TWEAKBYTES",
              newSVuv(0));
  newCONSTSUB(stash, "ipcrypt_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "ipcrypt_available", &PL_sv_no);
#endif

SV * ipcrypt_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  ipcrypt_nd_keygen = 1
  ipcrypt_ndx_keygen = 2
  ipcrypt_pfx_keygen = 3

  CODE:
#ifdef SODIUM_HAS_IPCRYPT
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_ipcrypt_ND_KEYBYTES, flags);
      break;
    case 2:
      RETVAL = sv_keygen(aTHX_ crypto_ipcrypt_NDX_KEYBYTES, flags);
      break;
    case 3:
      RETVAL = sv_keygen(aTHX_ crypto_ipcrypt_PFX_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_ipcrypt_KEYBYTES, flags);
  }
#else
  croak("ipcrypt_decrypt: ipcrypt not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

SV * ipcrypt_decrypt(SV * in, SV * key)

  ALIAS:
  ipcrypt_nd_decrypt = 1
  ipcrypt_ndx_decrypt = 2
  ipcrypt_pfx_decrypt = 3

  PREINIT:
  protmem *key_pm = NULL;
  unsigned char *in_buf, *key_buf, *out_buf;
  STRLEN in_len, in_req_len, key_len, key_req_len, out_len;
  void (*func)(unsigned char *, const unsigned char *, const unsigned char *);

  CODE:
#ifdef SODIUM_HAS_IPCRYPT
  switch (ix) {
    case 1:
      in_req_len = crypto_ipcrypt_ND_OUTPUTBYTES;
      key_req_len = crypto_ipcrypt_ND_KEYBYTES;
      out_len = crypto_ipcrypt_ND_INPUTBYTES;
      func = crypto_ipcrypt_nd_decrypt;
      break;
    case 2:
      in_req_len = crypto_ipcrypt_NDX_OUTPUTBYTES;
      key_req_len = crypto_ipcrypt_NDX_KEYBYTES;
      out_len = crypto_ipcrypt_NDX_INPUTBYTES;
      func = crypto_ipcrypt_ndx_decrypt;
      break;
    case 3:
      in_req_len = crypto_ipcrypt_PFX_BYTES;
      key_req_len = crypto_ipcrypt_PFX_KEYBYTES;
      out_len = crypto_ipcrypt_PFX_BYTES;
      func = crypto_ipcrypt_pfx_decrypt;
      break;
    default:
      in_req_len = crypto_ipcrypt_BYTES;
      key_req_len = crypto_ipcrypt_KEYBYTES;
      out_len = crypto_ipcrypt_BYTES;
      func = crypto_ipcrypt_decrypt;
  }

  in_buf = (unsigned char *)SvPVbyte(in, in_len);
  if (in_len != in_req_len)
    croak("ipcrypt_decrypt: Invalid encrypted IP length");

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("ipcrypt_decrypt: Invalid key length");

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("ipcrypt_decrypt: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("ipcrypt_decrypt: Failed to grant key protmem RO");

  func(out_buf, in_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("ipcrypt_decrypt: Failed to release key protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);
#else
  croak("ipcrypt_decrypt: ipcrypt not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

SV * ipcrypt_encrypt(SV * in, SV * key, SV * tweak = &PL_sv_undef)

  ALIAS:
  ipcrypt_pfx_encrypt = 1
  ipcrypt_nd_encrypt = 2
  ipcrypt_ndx_encrypt = 3

  PREINIT:
  protmem *key_pm = NULL;
  unsigned char *in_buf, *key_buf, *out_buf, *tweak_buf = NULL;
  STRLEN in_len, key_len, key_req_len, out_len, tweak_len = 0, tweak_req_len = 0;

  CODE:
#ifdef SODIUM_HAS_IPCRYPT
  switch(ix) {
    case 1:
      key_req_len = crypto_ipcrypt_PFX_KEYBYTES;
      out_len = crypto_ipcrypt_PFX_BYTES;
      break;
    case 2:
      key_req_len = crypto_ipcrypt_ND_KEYBYTES;
      out_len = crypto_ipcrypt_ND_OUTPUTBYTES;
      tweak_req_len = crypto_ipcrypt_ND_TWEAKBYTES;
      break;
    case 3:
      key_req_len = crypto_ipcrypt_NDX_KEYBYTES;
      out_len = crypto_ipcrypt_NDX_OUTPUTBYTES;
      tweak_req_len = crypto_ipcrypt_NDX_TWEAKBYTES;
      break;
    default:
      key_req_len = crypto_ipcrypt_KEYBYTES;
      out_len = crypto_ipcrypt_BYTES;
  }

  in_buf = (unsigned char *)SvPVbyte(in, in_len);
  if (in_len != 16)
    croak("ipcrypt_encrypt: Invalid IP length (forgot to use sodium_ip2bin?)");

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("ipcrypt_encrypt: Invalid key length");

  if (ix > 1) {
    SvGETMAGIC(tweak);
    if (SvOK(tweak)) {
      tweak_buf = (unsigned char *)SvPVbyte(tweak, tweak_len);
      if (tweak_len != tweak_req_len)
        croak("ipcrypt_encrypt: Invalid tweak length");
    }
    else {
      tweak_len = tweak_req_len;
      Newx(tweak_buf, tweak_len + 1, unsigned char);
      if (tweak_buf == NULL)
        croak("ipcrypt_encrypt: Failed to allocate memory");
      randombytes_buf(tweak_buf, tweak_len);
      tweak_buf[tweak_len] = '\0';
    }
  }

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("ipcrypt_encrypt: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("ipcrypt_encrypt: Failed to grant key protmem RO");

  switch(ix) {
    case 1:
      crypto_ipcrypt_pfx_encrypt(out_buf, in_buf, key_buf);
      break;
    case 2:
      crypto_ipcrypt_nd_encrypt(out_buf, in_buf, tweak_buf, key_buf);
      break;
    case 3:
      crypto_ipcrypt_ndx_encrypt(out_buf, in_buf, tweak_buf, key_buf);
      break;
    default:
      crypto_ipcrypt_encrypt(out_buf, in_buf, key_buf);
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);
#else
  croak("ipcrypt_encrypt: ipcrypt not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL
