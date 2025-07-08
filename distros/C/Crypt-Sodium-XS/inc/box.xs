=for documentation

same as with secretbox, box does not have separate functions for
curve25519xsalsa20poly1305 _easy, _detached, _open_easy, _open_detached, nor
the associated afternm functions. it is the default algorithm for them.
aliases are still provided, and just fall through to the defaults.

also of note, no curve25519xsalsa20poly1305 seal interfaces. same deal.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::box

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::box", 0);

  PPCODE:
  newCONSTSUB(stash, "box_BEFORENMBYTES",
              newSVuv(crypto_box_BEFORENMBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_BEFORENMBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_BEFORENMBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_BEFORENMBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_BEFORENMBYTES));
  newCONSTSUB(stash, "box_MACBYTES",
              newSVuv(crypto_box_MACBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_MACBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_MACBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_MACBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_MACBYTES));
  newCONSTSUB(stash, "box_MESSAGEBYTES_MAX",
              newSVuv(crypto_box_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_MESSAGEBYTES_MAX",
              newSVuv(crypto_box_curve25519xchacha20poly1305_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_MESSAGEBYTES_MAX",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "box_NONCEBYTES",
              newSVuv(crypto_box_NONCEBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_NONCEBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_NONCEBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_NONCEBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_NONCEBYTES));
  newCONSTSUB(stash, "box_PUBLICKEYBYTES",
              newSVuv(crypto_box_PUBLICKEYBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_PUBLICKEYBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_PUBLICKEYBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES));
  newCONSTSUB(stash, "box_SEALBYTES",
              newSVuv(crypto_box_SEALBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_SEALBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_SEALBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_SEALBYTES",
              newSVuv(crypto_box_SEALBYTES));
  newCONSTSUB(stash, "box_SECRETKEYBYTES",
              newSVuv(crypto_box_SECRETKEYBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_SECRETKEYBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_SECRETKEYBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES));
  newCONSTSUB(stash, "box_SEEDBYTES",
              newSVuv(crypto_box_SEEDBYTES));
  newCONSTSUB(stash, "box_curve25519xchacha20poly1305_SEEDBYTES",
              newSVuv(crypto_box_curve25519xchacha20poly1305_SEEDBYTES));
  newCONSTSUB(stash, "box_curve25519xsalsa20poly1305_SEEDBYTES",
              newSVuv(crypto_box_curve25519xsalsa20poly1305_SEEDBYTES));
  newCONSTSUB(stash, "box_PRIMITIVE", newSVpvs(crypto_box_PRIMITIVE));

SV * box_beforenm(SV * pk, SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  box_curve25519xchacha20poly1305_beforenm = 1
  box_curve25519xsalsa20poly1305_beforenm = 2

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *precalc_pm;
  unsigned char *pk_buf;
  unsigned char *sk_buf;
  STRLEN pk_len;
  STRLEN sk_len;
  STRLEN precalc_len;
  STRLEN pk_req_len;
  STRLEN sk_req_len;
  unsigned int precalc_flags = g_protmem_flags_key_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      precalc_len = crypto_box_curve25519xchacha20poly1305_BEFORENMBYTES;
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      sk_req_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      func = crypto_box_curve25519xchacha20poly1305_beforenm;
      break;
    case 2:
      precalc_len = crypto_box_curve25519xsalsa20poly1305_BEFORENMBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      func = crypto_box_curve25519xsalsa20poly1305_beforenm;
      break;
    default:
      precalc_len = crypto_box_BEFORENMBYTES;
      pk_req_len = crypto_box_PUBLICKEYBYTES;
      sk_req_len = crypto_box_SECRETKEYBYTES;
      func = crypto_box_beforenm;
  }

  if (SvOK(flags))
    precalc_flags = SvUV(flags);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_before_nm: Invalid public key length %lu", pk_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("box_before_nm: Invalid secret key length %lu", sk_len);

  precalc_pm = protmem_init(aTHX_ precalc_len, precalc_flags);
  if (precalc_pm == NULL)
    croak("box_before_nm: Failed to allocate precalc protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("box_before_nm: Failed to grant sk protmem RO");
  }

  ret = func(precalc_pm->pm_ptr, pk_buf, sk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("box_before_nm: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("box_before_nm: Failed to release precalc protmem RW");
  }

  if (ret != 0) {
    protmem_free(aTHX_ precalc_pm);
    croak("box_before_nm: Failed to create key (invalid public key?)");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ precalc_pm, "Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305");
      break;
    case 2:
      RETVAL = protmem_to_sv(aTHX_ precalc_pm, "Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ precalc_pm, "Crypt::Sodium::XS::box::precalc");
  }

  OUTPUT:
  RETVAL

SV * box_decrypt( \
  SV * ciphertext, \
  SV * nonce, \
  SV * pk, \
  SV * sk, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  box_curve25519xchacha20poly1305_decrypt = 1
  box_curve25519xsalsa20poly1305_decrypt = 2

  PREINIT:
  protmem *msg_pm;
  protmem *sk_pm = NULL;
  unsigned char *ct_buf;
  unsigned char *nonce_buf;
  unsigned char *sk_buf;
  unsigned char *pk_buf;
  STRLEN ct_len;
  STRLEN nonce_len;
  STRLEN sk_len;
  STRLEN pk_len;
  STRLEN nonce_req_len;
  STRLEN sk_req_len;
  STRLEN pk_req_len;
  STRLEN mac_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      mac_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      func = crypto_box_curve25519xchacha20poly1305_open_easy;
      break;
    case 2:
      /* no separate NONCEBYTES MACBYTES or function */
      nonce_req_len = crypto_box_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      mac_len = crypto_box_MACBYTES;
      func = crypto_box_open_easy;
      break;
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      mac_len = crypto_box_MACBYTES;
      func = crypto_box_open_easy;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < mac_len)
    croak("box_decrypt: Invalid ciphertext length (too short)");

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("box_decrypt: Invalid nonce length %lu", nonce_len);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_decrypt: Invalid public key length %lu", pk_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("box_decrypt: Invalid key length %lu", sk_len);

  msg_pm = protmem_init(aTHX_ ct_len - mac_len, msg_flags);
  if (msg_pm == NULL)
    croak("box_decrypt: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt: Failed to grant sk protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, ct_len, nonce_buf, pk_buf, sk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt: Message forged");
  }

  OUTPUT:
  RETVAL

SV * box_decrypt_detached( \
  SV * ciphertext, \
  SV * mac, \
  SV * nonce, \
  SV * pk, \
  SV * sk, \
  SV * flags = &PL_sv_undef \
)

  ALIAS:
  box_curve25519xchacha20poly1305_decrypt_detached = 1
  box_curve25519xsalsa20poly1305_decrypt_detached = 2

  PREINIT:
  protmem *msg_pm;
  protmem *sk_pm = NULL;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  unsigned char *nonce_buf;
  unsigned char *sk_buf;
  unsigned char *pk_buf;
  STRLEN ct_len;
  STRLEN mac_len;
  STRLEN nonce_len;
  STRLEN sk_len;
  STRLEN pk_len;
  STRLEN mac_req_len;
  STRLEN nonce_req_len;
  STRLEN sk_req_len;
  STRLEN pk_req_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              const unsigned char *, unsigned long long,
              const unsigned char *,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      mac_req_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      func = crypto_box_curve25519xchacha20poly1305_open_detached;
      break;
    case 2:
      /* no separate NONCEBYTES MACBYTES or function */
      nonce_req_len = crypto_box_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      mac_req_len = crypto_box_MACBYTES;
      func = crypto_box_open_detached;
      break;
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      mac_req_len = crypto_box_MACBYTES;
      func = crypto_box_open_detached;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != mac_req_len)
    croak("box_decrypt_detached: Invalid mac length: %lu", mac_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("box_decrypt_detached: Invalid nonce");

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_decrypt_detached: Invalid public key length %lu", pk_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("box_decrypt_detached: Invalid secret key length %lu", sk_len);

  msg_pm = protmem_init(aTHX_ ct_len, msg_flags);
  if (msg_pm == NULL)
    croak("box_decrypt_detached: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt_detached: Failed to grant sk protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, mac_buf, ct_len, nonce_buf, pk_buf, sk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt_detached: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt_detached: Failed to release msg protmem RW");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("box_decrypt_detached: Message forged");
  }

  OUTPUT:
  RETVAL

void box_encrypt(SV * msg, SV * nonce, SV * pk, SV * sk)

  ALIAS:
  box_encrypt_detached = 1
  box_curve25519xchacha20poly1305_encrypt = 2
  box_curve25519xchacha20poly1305_encrypt_detached = 3
  box_curve25519xsalsa20poly1305_encrypt = 4
  box_curve25519xsalsa20poly1305_encrypt_detached = 5

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *sk_pm = NULL;
  SV *ct;
  SV *mac = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *pk_buf;
  unsigned char *sk_buf;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN pk_len;
  STRLEN sk_len;
  STRLEN mac_len;
  STRLEN nonce_req_len;
  STRLEN pk_req_len;
  STRLEN sk_req_len;
  int (*detached_func)(unsigned char *, unsigned char *,
                       const unsigned char *, unsigned long long,
                       const unsigned char *, const unsigned char *,
                       const unsigned char *);
  int (*easy_func)(unsigned char *, const unsigned char *,
                   unsigned long long, const unsigned char *,
                   const unsigned char *, const unsigned char *);

  PPCODE:
  switch(ix) {
    case 2: /* fallthrough */
    case 3:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      sk_req_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      mac_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      detached_func = crypto_box_curve25519xchacha20poly1305_detached;
      easy_func = crypto_box_curve25519xchacha20poly1305_easy;
      break;
    case 4: /* fallthrough */
    case 5:
      nonce_req_len = crypto_box_curve25519xsalsa20poly1305_NONCEBYTES;
      pk_req_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      sk_req_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      mac_len = crypto_box_curve25519xsalsa20poly1305_MACBYTES;
      /* no separate functions */
      detached_func = crypto_box_detached;
      easy_func = crypto_box_easy;
      break;
    case 1: /* fallthrough */
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      pk_req_len = crypto_box_PUBLICKEYBYTES;
      sk_req_len = crypto_box_SECRETKEYBYTES;
      mac_len = crypto_box_MACBYTES;
      detached_func = crypto_box_detached;
      easy_func = crypto_box_easy;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("box_encrypt: Invalid nonce length %lu", nonce_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("box_encrypt: Invalid secret key length %lu", sk_len);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_encrypt: Invalid public key length %lu", pk_len);

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("box_encrypt: Failed to grant sk protmem RO");
  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("box_encrypt: Failed to grant msg protmem RO");
  }

  /* NB: odd aliases are _detached, even are combined */
  if (ix & 1) {
    Newx(mac_buf, mac_len + 1, unsigned char);
    if (mac_buf == NULL) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("box_encrypt: Failed to allocate memory");
    }
    mac_buf[mac_len] = '\0';
    Newx(ct_buf, msg_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      Safefree(mac_buf);
      croak("box_encrypt: Failed to allocate memory");
    }
    ct_buf[msg_len] = '\0';

    detached_func(ct_buf, mac_buf, msg_buf, msg_len, nonce_buf, pk_buf, sk_buf);

    mac = newSV(0);
    sv_usepvn_flags(mac, (char *)mac_buf, mac_len, SV_HAS_TRAILING_NUL);
    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);
  }
  else {
    STRLEN ct_len = mac_len + msg_len;

    Newx(ct_buf, ct_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (msg_pm)
        protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("box_encrypt: Failed to allocate memory");
    }
    ct_buf[mac_len + msg_len] = '\0';

    easy_func(ct_buf, msg_buf, msg_len, nonce_buf, pk_buf, sk_buf);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, mac_len + msg_len, SV_HAS_TRAILING_NUL);
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("box_encrypt: Failed to release sk protmem RO");
  }
  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO != 0))
    croak("box_encrypt: Failed to release msg protmem RO");

  mXPUSHs(ct);

  if (ix & 1) {
    mXPUSHs(mac);
    XSRETURN(2);
  }

  XSRETURN(1);

void box_keypair(SV * seed = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  box_curve25519xchacha20poly1305_keypair = 1
  box_curve25519xsalsa20poly1305_keypair = 2

  PREINIT:
  protmem *sk_pm;
  SV *pk_sv;
  unsigned char *pk_buf;
  STRLEN seed_req_len;
  STRLEN pk_len;
  STRLEN sk_len;
  unsigned int sk_flags = g_protmem_flags_key_default;

  PPCODE:
  if (SvOK(flags))
    sk_flags = SvUV(flags);

  switch(ix) {
    case 1:
      seed_req_len = crypto_box_curve25519xchacha20poly1305_SEEDBYTES;
      pk_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      sk_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      break;
    case 2:
      seed_req_len = crypto_box_curve25519xsalsa20poly1305_SEEDBYTES;
      pk_len = crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES;
      sk_len = crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES;
      break;
    default:
      seed_req_len = crypto_box_SEEDBYTES;
      pk_len = crypto_box_PUBLICKEYBYTES;
      sk_len = crypto_box_SECRETKEYBYTES;
  }

  Newx(pk_buf, pk_len + 1, unsigned char);
  if (pk_buf == NULL)
    croak("box_keypair: Failed to allocate memory");
  pk_buf[pk_len] = '\0';

  if (!SvOK(seed)) {
    sk_pm = protmem_init(aTHX_ sk_len, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("box_keypair: Failed to allocate protmem");
    }
    switch(ix) {
      case 1:
        crypto_box_curve25519xchacha20poly1305_keypair(pk_buf, sk_pm->pm_ptr);
        break;
      case 2:
        crypto_box_curve25519xsalsa20poly1305_keypair(pk_buf, sk_pm->pm_ptr);
        break;
      default:
        crypto_box_keypair(pk_buf, sk_pm->pm_ptr);
    }
  }
  else {
    /* from seed */
    protmem *seed_pm = NULL;
    unsigned char *seed_buf;
    STRLEN seed_len;

    if (sv_derived_from(ST(0), MEMVAULT_CLASS)) {
      seed_pm = protmem_get(aTHX_ ST(0), MEMVAULT_CLASS);
      seed_buf = seed_pm->pm_ptr;
      seed_len = seed_pm->size;
    }
    else
      seed_buf = (unsigned char *)SvPVbyte(ST(0), seed_len);
    if (seed_len != seed_req_len) {
      Safefree(pk_buf);
      croak("box_keypair: Invalid seed length: %lu", seed_len);
    }
    sk_pm = protmem_init(aTHX_ sk_len, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("box_keypair: Failed to allocate protmem");
    }

    if (seed_pm && protmem_grant(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("box_keypair: Failed to grant seed protmem RO");
    }

    switch(ix) {
      case 1:
        crypto_box_curve25519xchacha20poly1305_seed_keypair(
                pk_buf, sk_pm->pm_ptr, seed_buf);
        break;
      case 2:
        crypto_box_curve25519xsalsa20poly1305_seed_keypair(
                pk_buf, sk_pm->pm_ptr, seed_buf);
        break;
      default:
        crypto_box_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
    }

    if (seed_pm && protmem_release(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("box_keypair: Failed to release seed protmem RO");
    }
  }

  if (protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ sk_pm);
    croak("box_keypair: Failed to release sk protmem RW");
  }

  pk_sv = newSV(0);
  sv_usepvn_flags(pk_sv, (char *)pk_buf, pk_len, SV_HAS_TRAILING_NUL);
  mXPUSHs(pk_sv);
  mXPUSHs(protmem_to_sv(aTHX_ sk_pm, MEMVAULT_CLASS));
  XSRETURN(2);

SV * box_nonce(SV * base = &PL_sv_undef)

  ALIAS:
  box_curve25519xchacha20poly1305_nonce = 1
  box_curve25519xsalsa20poly1305_nonce = 2

  CODE:
  switch(ix) {
    case 1:
      RETVAL = nonce_generate(aTHX_ crypto_box_curve25519xchacha20poly1305_NONCEBYTES, base);
      break;
    case 2:
      RETVAL = nonce_generate(aTHX_ crypto_box_curve25519xsalsa20poly1305_NONCEBYTES, base);
      break;
    default:
      RETVAL = nonce_generate(aTHX_ crypto_box_NONCEBYTES, base);
  }

  OUTPUT:
  RETVAL

SV * box_seal_encrypt(SV * msg, SV * pk)

  ALIAS:
  box_curve25519xchacha20poly1305_seal_encrypt = 1
  box_curve25519xsalsa20poly1305_seal_encrypt = 2

  PREINIT:
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *pk_buf;
  unsigned char *ct_buf;
  STRLEN msg_len;
  STRLEN pk_len;
  STRLEN pk_req_len;
  STRLEN seal_len;
  STRLEN ct_len;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      seal_len = crypto_box_curve25519xchacha20poly1305_SEALBYTES;
      func = crypto_box_curve25519xchacha20poly1305_seal;
      break;
    case 2: /* fallthrough */
    default:
      pk_req_len = crypto_box_PUBLICKEYBYTES;
      seal_len = crypto_box_SEALBYTES;
      func = crypto_box_seal;
  }

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_seal_encrypt: Invalid public key length %lu", pk_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);
  ct_len = seal_len + msg_len;

  Newx(ct_buf, ct_len + 1, unsigned char);
  if (ct_buf == NULL)
    croak("box_seal_encrypt: Failed to allocate memory");
  ct_buf[ct_len] = '\0';

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(ct_buf);
    croak("box_seal_encrypt: Failed to grant msg protmem RO");
  }

  func(ct_buf, msg_buf, msg_len, pk_buf);

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(ct_buf);
    croak("box_seal_encrypt: Failed to release msg protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * box_seal_decrypt(SV * ciphertext, SV * pk, SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  box_curve25519xchacha20poly1305_seal_decrypt = 1
  box_curve25519xsalsa20poly1305_seal_decrypt = 2

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *msg_pm;
  unsigned char *ct_buf;
  unsigned char *pk_buf;
  unsigned char *sk_buf;
  STRLEN ct_len;
  STRLEN pk_len;
  STRLEN sk_len;
  STRLEN pk_req_len;
  STRLEN sk_req_len;
  STRLEN seal_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *,
              const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      pk_req_len = crypto_box_curve25519xchacha20poly1305_PUBLICKEYBYTES;
      sk_req_len = crypto_box_curve25519xchacha20poly1305_SECRETKEYBYTES;
      seal_len = crypto_box_curve25519xchacha20poly1305_SEALBYTES;
      func = crypto_box_curve25519xchacha20poly1305_seal_open;
      break;
    case 2: /* fallthrough */
    default:
      pk_req_len = crypto_box_PUBLICKEYBYTES;
      sk_req_len = crypto_box_SECRETKEYBYTES;
      seal_len = crypto_box_SEALBYTES;
      func = crypto_box_seal_open;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < seal_len)
    croak("box_seal_decrypt: Invalid ciphertext length (too short)");

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("box_seal_decrypt: Invalid public key length %lu", pk_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("box_seal_decrypt: Invalid secret key length %lu", sk_len);

  msg_pm = protmem_init(aTHX_ ct_len - seal_len, msg_flags);
  if (msg_pm == NULL)
    croak("box_seal_decrypt: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_seal_decrypt: Failed to grant sk protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, ct_len, pk_buf, sk_buf);

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("box_seal_decrypt: Failed to release sk protmem RO");
  }

  if (ret == 0)
    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  else {
    protmem_free(aTHX_ msg_pm);
    croak("box_seal_decrypt: Message forged");
  }

  OUTPUT:
  RETVAL

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::box::precalc

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305::DESTROY = 1
  Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305::DESTROY = 2

  PREINIT:
  protmem *precalc_pm;

  PPCODE:
  switch(ix) {
    case 1:
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305");
      break;
    case 2:
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305");
      break;
    default:
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc");
  }
  protmem_free(aTHX_ precalc_pm);

SV * decrypt(SV * self, SV * ciphertext, SV * nonce, SV * flags = &PL_sv_undef)

  ALIAS:
  Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305::decrypt = 1
  Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305::decrypt = 2

  PREINIT:
  protmem *msg_pm;
  protmem *precalc_pm;
  unsigned char *ct_buf;
  unsigned char *nonce_buf;
  STRLEN ct_len;
  STRLEN nonce_len;
  STRLEN nonce_req_len;
  STRLEN mac_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *,
              const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      mac_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305");
      func = crypto_box_curve25519xchacha20poly1305_open_easy_afternm;
      break;
    case 2:
      /* no separate NONCEBYTES MACBYTES or function */
      nonce_req_len = crypto_box_NONCEBYTES;
      mac_len = crypto_box_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305");
      func = crypto_box_open_easy_afternm;
      break;
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      mac_len = crypto_box_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc");
      func = crypto_box_open_easy_afternm;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len < mac_len)
    croak("decrypt: Invalid ciphertext length (too short)");

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("decrypt: Invalid nonce length %lu", nonce_len);

  msg_pm = protmem_init(aTHX_ ct_len - mac_len, msg_flags);
  if (msg_pm == NULL)
    croak("decrypt: Failed to allocate protmem");

  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to grant precalc protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, ct_len, nonce_buf, precalc_pm->pm_ptr);

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt: Failed to release precalc protmem RO");
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

SV * decrypt_detached(SV * self, SV * ciphertext, SV * mac, SV * nonce, SV * flags = &PL_sv_undef)

  ALIAS:
  Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305::decrypt_detached = 1
  Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305::decrypt_detached = 2

  PREINIT:
  protmem *msg_pm;
  protmem *precalc_pm;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  unsigned char *nonce_buf;
  STRLEN ct_len;
  STRLEN mac_len;
  STRLEN nonce_len;
  STRLEN mac_req_len;
  STRLEN nonce_req_len;
  unsigned int msg_flags = g_protmem_flags_decrypt_default;
  int ret;
  int (*func)(unsigned char *, const unsigned char *,
              const unsigned char *, unsigned long long,
              const unsigned char *, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      mac_req_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305");
      func = crypto_box_curve25519xchacha20poly1305_open_detached_afternm;
      break;
    case 2:
      /* no separate NONCEBYTES MACBYTES or function */
      nonce_req_len = crypto_box_NONCEBYTES;
      mac_req_len = crypto_box_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305");
      func = crypto_box_open_detached_afternm;
      break;
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      mac_req_len = crypto_box_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc");
      func = crypto_box_open_detached_afternm;
  }

  if (SvOK(flags))
    msg_flags = SvUV(flags);

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);

  mac_buf = (unsigned char *)SvPVbyte(mac, mac_len);
  if (mac_len != mac_req_len)
    croak("decrypt_detached: Invalid mac length: %lu", mac_len);

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("decrypt_detached: Invalid nonce length: %lu", nonce_len);

  msg_pm = protmem_init(aTHX_ ct_len, msg_flags);
  if (msg_pm == NULL)
    croak("decrypt_detached: Failed to allocate protmem");

  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Failed to grant precalc protmem RO");
  }

  ret = func(msg_pm->pm_ptr, ct_buf, mac_buf, ct_len, nonce_buf, precalc_pm->pm_ptr);

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ msg_pm);
    croak("decrypt_detached: Failed to release precalc protmem RO");
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

void encrypt(SV * self, SV * msg, SV * nonce)

  ALIAS:
  Crypt::Sodium::XS::box::precalc::encrypt_detached = 1
  Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305::encrypt = 2
  Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305::encrypt_detached = 3
  Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305::encrypt = 4
  Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305::encrypt_detached = 5

  PREINIT:
  protmem *msg_mv = NULL;
  protmem *precalc_pm;
  SV *ct;
  SV *mac = NULL;
  unsigned char *msg_buf;
  unsigned char *nonce_buf;
  unsigned char *ct_buf;
  unsigned char *mac_buf;
  STRLEN msg_len;
  STRLEN nonce_len;
  STRLEN nonce_req_len;
  STRLEN mac_len;
  int (*detached_func)(unsigned char *, unsigned char *,
                       const unsigned char *, unsigned long long,
                       const unsigned char *, const unsigned char *);
  int (*easy_func)(unsigned char *, const unsigned char *,
                   unsigned long long, const unsigned char *,
                   const unsigned char *);

  PPCODE:
  switch(ix) {
    case 2: /* fallthrough */
    case 3:
      nonce_req_len = crypto_box_curve25519xchacha20poly1305_NONCEBYTES;
      mac_len = crypto_box_curve25519xchacha20poly1305_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xchacha20poly1305");
      detached_func = crypto_box_curve25519xchacha20poly1305_detached_afternm;
      easy_func = crypto_box_curve25519xchacha20poly1305_easy_afternm;
      break;
    case 4: /* fallthrough */
    case 5:
      nonce_req_len = crypto_box_curve25519xsalsa20poly1305_NONCEBYTES;
      mac_len = crypto_box_curve25519xsalsa20poly1305_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc::curve25519xsalsa20poly1305");
      /* no separate functions */
      detached_func = crypto_box_detached_afternm;
      easy_func = crypto_box_easy_afternm;
      break;
    case 1: /* fallthrough */
    default:
      nonce_req_len = crypto_box_NONCEBYTES;
      mac_len = crypto_box_MACBYTES;
      precalc_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::box::precalc");
      detached_func = crypto_box_detached_afternm;
      easy_func = crypto_box_easy_afternm;
  }

  nonce_buf = (unsigned char *)SvPVbyte(nonce, nonce_len);
  if (nonce_len != nonce_req_len)
    croak("encrypt: Invalid nonce length %lu", nonce_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_mv = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_mv->pm_ptr;
    msg_len = msg_mv->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (protmem_grant(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("encrypt: Failed to grant precalc protmem RO");
  if (msg_mv && protmem_grant(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("encrypt: Failed to grant msg protmem RO");
  }

  /* NB: odd aliases are _detached, even are combined */
  if (ix & 1) {
    Newx(mac_buf, mac_len + 1, unsigned char);
    if (mac_buf == NULL) {
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("encrypt: Failed to allocate memory");
    }
    mac_buf[mac_len] = '\0';
    Newx(ct_buf, msg_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO);
      Safefree(mac_buf);
      croak("encrypt: Failed to allocate memory");
    }
    ct_buf[msg_len] = '\0';

    detached_func(ct_buf, mac_buf, msg_buf, msg_len, nonce_buf, precalc_pm->pm_ptr);

    mac = newSV(0);
    sv_usepvn_flags(mac, (char *)mac_buf, mac_len, SV_HAS_TRAILING_NUL);
    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, msg_len, SV_HAS_TRAILING_NUL);
  }
  else {
    STRLEN ct_len = mac_len + msg_len;

    Newx(ct_buf, ct_len + 1, unsigned char);
    if (ct_buf == NULL) {
      if (msg_mv)
        protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
      protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("encrypt: Failed to allocate memory");
    }
    ct_buf[ct_len] = '\0';

    easy_func(ct_buf, msg_buf, msg_len, nonce_buf, precalc_pm->pm_ptr);

    ct = newSV(0);
    sv_usepvn_flags(ct, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);
  }

  if (protmem_release(aTHX_ precalc_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_mv)
      protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO);
    croak("encrypt: Failed to release precalc protmem RO");
  }
  if (msg_mv && protmem_release(aTHX_ msg_mv, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("encrypt: Failed to release msg protmem RO");

  mXPUSHs(ct);

  if (ix & 1) {
    mXPUSHs(mac);
    XSRETURN(2);
  }

  XSRETURN(1);
