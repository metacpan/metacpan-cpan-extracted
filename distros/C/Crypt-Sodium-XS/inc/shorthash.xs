MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::shorthash

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::shorthash", 0);

  PPCODE:
  newCONSTSUB(stash, "shorthash_BYTES", newSVuv(crypto_shorthash_BYTES));
  newCONSTSUB(stash, "shorthash_siphash24_BYTES",
              newSVuv(crypto_shorthash_siphash24_BYTES));
  newCONSTSUB(stash, "shorthash_siphashx24_BYTES",
              newSVuv(crypto_shorthash_siphashx24_BYTES));
  newCONSTSUB(stash, "shorthash_KEYBYTES", newSVuv(crypto_shorthash_KEYBYTES));
  newCONSTSUB(stash, "shorthash_siphash24_KEYBYTES",
              newSVuv(crypto_shorthash_siphash24_KEYBYTES));
  newCONSTSUB(stash, "shorthash_siphashx24_KEYBYTES",
              newSVuv(crypto_shorthash_siphashx24_KEYBYTES));
  newCONSTSUB(stash, "shorthash_PRIMITIVE",
              newSVpvs(crypto_shorthash_PRIMITIVE));

SV * shorthash(SV * msg, SV * key)

  ALIAS:
  shorthash_siphash24 = 1
  shorthash_siphashx24 = 2

  PREINIT:
  protmem *key_mv = NULL;
  unsigned char *msg_buf;
  unsigned char *key_buf;
  unsigned char *out_buf;
  STRLEN msg_len;
  STRLEN key_len;
  STRLEN key_req_len;
  STRLEN out_len;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      key_req_len = crypto_shorthash_siphash24_KEYBYTES;
      out_len = crypto_shorthash_siphash24_BYTES;
      func = crypto_shorthash_siphash24;
      break;
    case 2:
      key_req_len = crypto_shorthash_siphashx24_KEYBYTES;
      out_len = crypto_shorthash_siphashx24_BYTES;
      func = crypto_shorthash_siphashx24;
      break;
    default:
      key_req_len = crypto_shorthash_KEYBYTES;
      out_len = crypto_shorthash_BYTES;
      func = crypto_shorthash;
  }

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_mv = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_mv->pm_ptr;
    key_len = key_mv->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("shorthash: Invalid key length %lu", key_len);

  msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("shorthash: Failed to allocate memory");
  out_buf[out_len] = '\0';

  if (key_mv && protmem_grant(aTHX_ key_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(out_buf);
    croak("shorthash: Failed to grant key protmem RO");
  }

  func(out_buf, msg_buf, msg_len, key_buf);

  if (key_mv && protmem_release(aTHX_ key_mv, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("shorthash: Failed to release key protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * shorthash_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  shorthash_siphash24_keygen = 1
  shorthash_siphashx24_keygen = 2

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_shorthash_siphash24_KEYBYTES, flags);
      break;
    case 2:
      RETVAL = sv_keygen(aTHX_ crypto_shorthash_siphashx24_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_shorthash_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL
