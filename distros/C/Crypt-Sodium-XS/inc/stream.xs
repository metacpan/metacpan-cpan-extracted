=for documentation

stream is provided for completeness, but should not be used without very good
understanding. it is not authenticated. better options are secretbox or box.

salsa208 not implemented (deprecated in libsodium)

libsodium does not provide interface to set internal counter when using stream
function (only for stream_*xor_ic). always starts at 0 and is incremented as
needed internally for output size.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::stream

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::stream", 0);

  PPCODE:
  newCONSTSUB(stash, "stream_KEYBYTES", newSVuv(crypto_stream_KEYBYTES));
  newCONSTSUB(stash, "stream_chacha20_KEYBYTES",
              newSVuv(crypto_stream_chacha20_KEYBYTES));
  newCONSTSUB(stash, "stream_chacha20_ietf_KEYBYTES",
              newSVuv(crypto_stream_chacha20_ietf_KEYBYTES));
  newCONSTSUB(stash, "stream_salsa20_KEYBYTES",
              newSVuv(crypto_stream_salsa20_KEYBYTES));
  newCONSTSUB(stash, "stream_salsa2012_KEYBYTES",
              newSVuv(crypto_stream_salsa2012_KEYBYTES));
  newCONSTSUB(stash, "stream_xchacha20_KEYBYTES",
              newSVuv(crypto_stream_xchacha20_KEYBYTES));
  newCONSTSUB(stash, "stream_xsalsa20_KEYBYTES",
              newSVuv(crypto_stream_xsalsa20_KEYBYTES));
  newCONSTSUB(stash, "stream_NONCEBYTES", newSVuv(crypto_stream_NONCEBYTES));
  newCONSTSUB(stash, "stream_chacha20_NONCEBYTES",
              newSVuv(crypto_stream_chacha20_NONCEBYTES));
  newCONSTSUB(stash, "stream_chacha20_ietf_NONCEBYTES",
              newSVuv(crypto_stream_chacha20_ietf_NONCEBYTES));
  newCONSTSUB(stash, "stream_salsa20_NONCEBYTES",
              newSVuv(crypto_stream_salsa20_NONCEBYTES));
  newCONSTSUB(stash, "stream_salsa2012_NONCEBYTES",
              newSVuv(crypto_stream_salsa2012_NONCEBYTES));
  newCONSTSUB(stash, "stream_xchacha20_NONCEBYTES",
              newSVuv(crypto_stream_xchacha20_NONCEBYTES));
  newCONSTSUB(stash, "stream_xsalsa20_NONCEBYTES",
              newSVuv(crypto_stream_xsalsa20_NONCEBYTES));
  newCONSTSUB(stash, "stream_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_chacha20_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_chacha20_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_chacha20_ietf_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_chacha20_ietf_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_salsa20_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_salsa20_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_salsa2012_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_salsa2012_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_xchacha20_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_xchacha20_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_xsalsa20_MESSAGEBYTES_MAX",
              newSVuv(crypto_stream_xsalsa20_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "stream_PRIMITIVE", newSVpvs(crypto_stream_PRIMITIVE));

SV * stream(STRLEN out_len, SV * nonce, SV * key)

  ALIAS:
  stream_chacha20 = 1
  stream_chacha20_ietf = 2
  stream_salsa20 = 3
  stream_salsa2012 = 4
  stream_xchacha20 = 5
  stream_xsalsa20 = 6

  PREINIT:
  protmem *key_pm = NULL;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *out_buf;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  int (*func)(unsigned char *, unsigned long long,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_stream_chacha20_NONCEBYTES;
      key_req_len = crypto_stream_chacha20_KEYBYTES;
      func = crypto_stream_chacha20;
      break;
    case 2:
      nonce_req_len = crypto_stream_chacha20_ietf_NONCEBYTES;
      key_req_len = crypto_stream_chacha20_ietf_KEYBYTES;
      func = crypto_stream_chacha20_ietf;
      break;
    case 3:
      nonce_req_len = crypto_stream_salsa20_NONCEBYTES;
      key_req_len = crypto_stream_salsa20_KEYBYTES;
      func = crypto_stream_salsa20;
      break;
    case 4:
      nonce_req_len = crypto_stream_salsa2012_NONCEBYTES;
      key_req_len = crypto_stream_salsa2012_KEYBYTES;
      func = crypto_stream_salsa2012;
      break;
    case 5:
      nonce_req_len = crypto_stream_xchacha20_NONCEBYTES;
      key_req_len = crypto_stream_xchacha20_KEYBYTES;
      func = crypto_stream_xchacha20;
      break;
    case 6:
      nonce_req_len = crypto_stream_xsalsa20_NONCEBYTES;
      key_req_len = crypto_stream_xsalsa20_KEYBYTES;
      func = crypto_stream_xsalsa20;
      break;
    default:
      nonce_req_len = crypto_stream_NONCEBYTES;
      key_req_len = crypto_stream_KEYBYTES;
      func = crypto_stream;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("stream: Invalid nonce length %lu", nonce_len);

  if (sv_derived_from(key, MEMVAULT_CLASS)) {
    key_pm = protmem_get(aTHX_ key, MEMVAULT_CLASS);
    key_buf = key_pm->pm_ptr;
    key_len = key_pm->size;
  }
  else
    key_buf = (unsigned char *)SvPVbyte(key, key_len);
  if (key_len != key_req_len)
    croak("stream: Invalid key length %lu", key_len);

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream: Failed to grant key protmem RO");

  Newx(out_buf, out_len + 1, unsigned char);
  if (out_buf == NULL) {
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream: Failed to allocate memory");
  }
  out_buf[out_len] = '\0';

  func(out_buf, out_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream: Failed to release key protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * stream_keygen(SV * flags = &PL_sv_undef)

  ALIAS:
  stream_chacha20_keygen = 1
  stream_chacha20_ietf_keygen = 2
  stream_salsa20_keygen = 3
  stream_salsa2012_keygen = 4
  stream_xchacha20_keygen = 5
  stream_xsalsa20_keygen = 6

  CODE:
  switch(ix) {
    case 1:
      RETVAL = sv_keygen(aTHX_ crypto_stream_chacha20_KEYBYTES, flags);
      break;
    case 2:
      RETVAL = sv_keygen(aTHX_ crypto_stream_chacha20_ietf_KEYBYTES, flags);
      break;
    case 3:
      RETVAL = sv_keygen(aTHX_ crypto_stream_salsa20_KEYBYTES, flags);
      break;
    case 4:
      RETVAL = sv_keygen(aTHX_ crypto_stream_salsa2012_KEYBYTES, flags);
      break;
    case 5:
      RETVAL = sv_keygen(aTHX_ crypto_stream_xchacha20_KEYBYTES, flags);
      break;
    case 6:
      RETVAL = sv_keygen(aTHX_ crypto_stream_xsalsa20_KEYBYTES, flags);
      break;
    default:
      RETVAL = sv_keygen(aTHX_ crypto_stream_KEYBYTES, flags);
  }

  OUTPUT:
  RETVAL

SV * stream_nonce(SV * base = &PL_sv_undef)

  ALIAS:
  stream_chacha20_nonce = 1
  stream_chacha20_ietf_nonce = 2
  stream_salsa20_nonce = 3
  stream_salsa2012_nonce = 4
  stream_xchacha20_nonce = 5
  stream_xsalsa20_nonce = 6

  CODE:
  switch(ix) {
    case 1:
      RETVAL = nonce_generate(aTHX_ crypto_stream_chacha20_NONCEBYTES, base);
      if (!SvOK(base))
        croak("Random nonces are unsafe with this primitive");
      break;
    case 2:
      if (!SvOK(base))
        croak("Random nonces are unsafe with this primitive");
      RETVAL = nonce_generate(aTHX_ crypto_stream_chacha20_ietf_NONCEBYTES, base);
      break;
    case 3:
      if (!SvOK(base))
        croak("Random nonces are unsafe with this primitive");
      RETVAL = nonce_generate(aTHX_ crypto_stream_salsa20_NONCEBYTES, base);
      break;
    case 4:
      if (!SvOK(base))
        croak("Random nonces are unsafe with this primitive");
      RETVAL = nonce_generate(aTHX_ crypto_stream_salsa2012_NONCEBYTES, base);
      break;
    case 5:
      RETVAL = nonce_generate(aTHX_ crypto_stream_xchacha20_NONCEBYTES, base);
      break;
    case 6:
      RETVAL = nonce_generate(aTHX_ crypto_stream_xsalsa20_NONCEBYTES, base);
      break;
    default:
      RETVAL = nonce_generate(aTHX_ crypto_stream_NONCEBYTES, base);
  }
  OUTPUT:
  RETVAL

SV * stream_xor(SV * msg, SV * nonce, SV * key)

  ALIAS:
  stream_chacha20_xor = 1
  stream_chacha20_ietf_xor = 2
  stream_salsa20_xor = 3
  stream_salsa2012_xor = 4
  stream_xchacha20_xor = 5
  stream_xsalsa20_xor = 6

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *ct_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  int (*func)(unsigned char *, const unsigned char *, unsigned long long,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_stream_chacha20_NONCEBYTES;
      key_req_len = crypto_stream_chacha20_KEYBYTES;
      func = crypto_stream_chacha20_xor;
      break;
    case 2:
      nonce_req_len = crypto_stream_chacha20_ietf_NONCEBYTES;
      key_req_len = crypto_stream_chacha20_ietf_KEYBYTES;
      func = crypto_stream_chacha20_ietf_xor;
      break;
    case 3:
      nonce_req_len = crypto_stream_salsa20_NONCEBYTES;
      key_req_len = crypto_stream_salsa20_KEYBYTES;
      func = crypto_stream_salsa20_xor;
      break;
    case 4:
      nonce_req_len = crypto_stream_salsa2012_NONCEBYTES;
      key_req_len = crypto_stream_salsa2012_KEYBYTES;
      func = crypto_stream_salsa2012_xor;
      break;
    case 5:
      nonce_req_len = crypto_stream_xchacha20_NONCEBYTES;
      key_req_len = crypto_stream_xchacha20_KEYBYTES;
      func = crypto_stream_xchacha20_xor;
      break;
    case 6:
      nonce_req_len = crypto_stream_xsalsa20_NONCEBYTES;
      key_req_len = crypto_stream_xsalsa20_KEYBYTES;
      func = crypto_stream_xsalsa20_xor;
      break;
    default:
      nonce_req_len = crypto_stream_NONCEBYTES;
      key_req_len = crypto_stream_KEYBYTES;
      func = crypto_stream_xor;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("stream_xor: Invalid nonce length %lu", nonce_len);

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
    croak("stream_xor: Invalid key length %lu", key_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_xor: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor: Failed to grant key protmem RO");
  }

  Newx(ct_buf, msg_len + 1, unsigned char);
  if (ct_buf == NULL) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor: Failed to allocate memory");
  }
  ct_buf[msg_len] = '\0';

  func(ct_buf, msg_buf, msg_len, nonce_buf, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_xor: Failed to release msg protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

=for documentation

chacha20_ietf xor_ic uses 32-bit counter

there's no xor_ic for salsa2012

providing generic stream_xor_ic though libsodium doesn't

=cut

SV * stream_xor_ic(SV * msg, SV * nonce, UV ic, SV * key)

  ALIAS:
  stream_chacha20_xor_ic = 1
  stream_salsa20_xor_ic = 2
  stream_xchacha20_xor_ic = 3
  stream_xsalsa20_xor_ic = 4

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *ct_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN key_len;
  STRLEN nonce_req_len;
  STRLEN key_req_len;
  int (*func)(unsigned char *, const unsigned char *, unsigned long long,
              const unsigned char *, uint64_t, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_stream_chacha20_NONCEBYTES;
      key_req_len = crypto_stream_chacha20_KEYBYTES;
      func = crypto_stream_chacha20_xor_ic;
      break;
    case 2:
      nonce_req_len = crypto_stream_salsa20_NONCEBYTES;
      key_req_len = crypto_stream_salsa20_KEYBYTES;
      func = crypto_stream_salsa20_xor_ic;
      break;
    case 3:
      nonce_req_len = crypto_stream_xchacha20_NONCEBYTES;
      key_req_len = crypto_stream_xchacha20_KEYBYTES;
      func = crypto_stream_xchacha20_xor_ic;
      break;
    default:
      nonce_req_len = crypto_stream_xsalsa20_NONCEBYTES;
      key_req_len = crypto_stream_xsalsa20_KEYBYTES;
      func = crypto_stream_xsalsa20_xor_ic;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("stream_xor_ic: Invalid nonce length %lu", nonce_len);

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
    croak("stream_xor_ic: Invalid key length %lu", key_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_xor_ic: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor_ic: Failed to grant key protmem RO");
  }

  Newx(ct_buf, msg_len + 1, unsigned char);
  if (ct_buf == NULL) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor_ic: Failed to allocate memory");
  }
  ct_buf[msg_len] = '\0';

  func(ct_buf, msg_buf, msg_len, nonce_buf, ic, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_xor_ic: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_xor_ic: Failed to release msg protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

=for documentation

chacha20_ietf is special snowflake, with 32-bit counter

do not use with a counter that could exceed 2 ** 32 -1.

=cut

SV * stream_chacha20_ietf_xor_ic(SV * msg, SV * nonce, U32 ic, SV * key)

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *key_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *key_buf;
  unsigned char *ct_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN key_len;

  CODE:
  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != crypto_stream_chacha20_ietf_NONCEBYTES)
    croak("stream_chacha20_ietf_xor_ic: Invalid nonce length %lu", nonce_len);

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
  if (key_len != crypto_stream_chacha20_ietf_KEYBYTES)
    croak("stream_chacha20_ietf_xor_ic: Invalid key length %lu", key_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_chacha20_ietf_xor_ic: Failed to grant msg protmem RO");

  if (key_pm && protmem_grant(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_chacha20_ietf_xor_ic: Failed to grant key protmem RO");
  }

  Newx(ct_buf, msg_len + 1, unsigned char);
  if (ct_buf == NULL) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    if (key_pm)
      protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_chacha20_ietf_xor_ic: Failed to allocate memory");
  }
  ct_buf[msg_len] = '\0';

  crypto_stream_chacha20_ietf_xor_ic(ct_buf, msg_buf, msg_len,
                                     nonce_buf, ic, key_buf);

  if (key_pm && protmem_release(aTHX_ key_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("stream_chacha20_ietf_xor_ic: Failed to release key protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("stream_chacha20_ietf_xor_ic: Failed to release msg protmem RO");

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL
