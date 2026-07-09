MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::kem

void _define_constants()

  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::kem", 0);

  PPCODE:
#ifdef SODIUM_HAS_KEM
  newCONSTSUB(stash, "kem_CIPHERTEXTBYTES", newSVuv(crypto_kem_CIPHERTEXTBYTES));
  newCONSTSUB(stash, "kem_mlkem768_CIPHERTEXTBYTES",
              newSVuv(crypto_kem_mlkem768_CIPHERTEXTBYTES));
  newCONSTSUB(stash, "kem_xwing_CIPHERTEXTBYTES",
              newSVuv(crypto_kem_xwing_CIPHERTEXTBYTES));
  newCONSTSUB(stash, "kem_PUBLICKEYBYTES", newSVuv(crypto_kem_PUBLICKEYBYTES));
  newCONSTSUB(stash, "kem_mlkem768_PUBLICKEYBYTES",
              newSVuv(crypto_kem_mlkem768_PUBLICKEYBYTES));
  newCONSTSUB(stash, "kem_xwing_PUBLICKEYBYTES",
              newSVuv(crypto_kem_xwing_PUBLICKEYBYTES));
  newCONSTSUB(stash, "kem_SECRETKEYBYTES", newSVuv(crypto_kem_SECRETKEYBYTES));
  newCONSTSUB(stash, "kem_mlkem768_SECRETKEYBYTES",
              newSVuv(crypto_kem_mlkem768_SECRETKEYBYTES));
  newCONSTSUB(stash, "kem_xwing_SECRETKEYBYTES",
              newSVuv(crypto_kem_xwing_SECRETKEYBYTES));
  newCONSTSUB(stash, "kem_SHAREDSECRETBYTES",
              newSVuv(crypto_kem_SHAREDSECRETBYTES));
  newCONSTSUB(stash, "kem_mlkem768_SHAREDSECRETBYTES",
              newSVuv(crypto_kem_mlkem768_SHAREDSECRETBYTES));
  newCONSTSUB(stash, "kem_xwing_SHAREDSECRETBYTES",
              newSVuv(crypto_kem_xwing_SHAREDSECRETBYTES));
  newCONSTSUB(stash, "kem_SEEDBYTES", newSVuv(crypto_kem_SEEDBYTES));
  newCONSTSUB(stash, "kem_mlkem768_SEEDBYTES",
              newSVuv(crypto_kem_mlkem768_SEEDBYTES));
  newCONSTSUB(stash, "kem_xwing_SEEDBYTES",
              newSVuv(crypto_kem_xwing_SEEDBYTES));
  newCONSTSUB(stash, "kem_PRIMITIVE", newSVpvs(crypto_kem_PRIMITIVE));
  newCONSTSUB(stash, "available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "available", &PL_sv_no);
#endif

SV * kem_dec(SV * ciphertext, SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  kem_mlkem768_dec = 1
  kem_xwing_dec = 2

  PREINIT:
  protmem *sk_pm = NULL, *ss_pm;
  unsigned char *ct_buf, *sk_buf;
  STRLEN ct_len, ct_req_len, sk_len, sk_req_len, ss_len;
  unsigned int ss_flags = g_protmem_default_flags_key;
  int (*dec_func)(unsigned char *, const unsigned char *, const unsigned char *);

  CODE:
#ifdef SODIUM_HAS_KEM
  SvGETMAGIC(flags);
  if (SvOK(flags))
    ss_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      ct_req_len = crypto_kem_mlkem768_CIPHERTEXTBYTES;
      sk_req_len = crypto_kem_mlkem768_SECRETKEYBYTES;
      ss_len = crypto_kem_mlkem768_SHAREDSECRETBYTES;
      dec_func = crypto_kem_mlkem768_dec;
      break;
    case 2:
      ct_req_len = crypto_kem_xwing_CIPHERTEXTBYTES;
      sk_req_len = crypto_kem_xwing_SECRETKEYBYTES;
      ss_len = crypto_kem_xwing_SHAREDSECRETBYTES;
      dec_func = crypto_kem_xwing_dec;
      break;
    default:
      ct_req_len = crypto_kem_CIPHERTEXTBYTES;
      sk_req_len = crypto_kem_SECRETKEYBYTES;
      ss_len = crypto_kem_SHAREDSECRETBYTES;
      dec_func = crypto_kem_dec;
  }

  ct_buf = (unsigned char *)SvPVbyte(ciphertext, ct_len);
  if (ct_len != ct_req_len)
    croak("kem_dec: Invalid ciphertext length");

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("kem_dec: Invalid secret key length");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("kem_dec: Failed to grant sk protmem RO");

  ss_pm = protmem_init(aTHX_ ss_len, ss_flags);
  if (ss_pm == NULL) {
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("kem_dec: Failed to allocate protmem");
  }

  if (dec_func(ss_pm->pm_ptr, ct_buf, sk_buf) != 0) {
    protmem_free(aTHX_ ss_pm);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("kem_dec: decryption failed");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("kem_dec: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ ss_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ ss_pm);
    croak("kem_dec: failed to release protmem");
  }

  RETVAL = protmem_to_sv(aTHX_ ss_pm, MEMVAULT_CLASS);
#else
  croak("kem_enc: KEM not supported by this version of libsodium");
#endif

  OUTPUT:
  RETVAL

void kem_enc(SV * pk, SV * flags = &PL_sv_undef)

  ALIAS:
  kem_mlkem768_enc = 1
  kem_xwing_enc = 2

  PREINIT:
  protmem *ss_pm;
  SV *ct_sv;
  unsigned char *ct_buf, *pk_buf;
  STRLEN ct_len, pk_len, pk_req_len, ss_len;
  unsigned int ss_flags = g_protmem_default_flags_key;
  int (*enc_func)(unsigned char *, unsigned char *, const unsigned char *);

  PPCODE:
#ifdef SODIUM_HAS_KEM
  SvGETMAGIC(flags);
  if (SvOK(flags))
    ss_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      ct_len = crypto_kem_mlkem768_CIPHERTEXTBYTES;
      pk_req_len = crypto_kem_mlkem768_PUBLICKEYBYTES;
      ss_len = crypto_kem_mlkem768_SHAREDSECRETBYTES;
      enc_func = crypto_kem_mlkem768_enc;
      break;
    case 2:
      ct_len = crypto_kem_xwing_CIPHERTEXTBYTES;
      pk_req_len = crypto_kem_xwing_PUBLICKEYBYTES;
      ss_len = crypto_kem_xwing_SHAREDSECRETBYTES;
      enc_func = crypto_kem_xwing_enc;
      break;
    default:
      ct_len = crypto_kem_CIPHERTEXTBYTES;
      pk_req_len = crypto_kem_PUBLICKEYBYTES;
      ss_len = crypto_kem_SHAREDSECRETBYTES;
      enc_func = crypto_kem_enc;
  }

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("kem_enc: Invalid public key length");

  Newx(ct_buf, ct_len + 1, unsigned char);
  if (ct_buf == NULL)
    croak("kem_enc: Failed to allocate memory");
  ct_buf[ct_len] = '\0';

  ss_pm = protmem_init(aTHX_ ss_len, ss_flags);
  if (ss_pm == NULL) {
    Safefree(ct_buf);
    croak("kem_enc: Failed to allocate protmem");
  }

  if (enc_func(ct_buf, ss_pm->pm_ptr, pk_buf) != 0) {
    protmem_free(aTHX_ ss_pm);
    Safefree(ct_buf);
    croak("kem_enc: encryption failed");
  }

  if (protmem_release(aTHX_ ss_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ ss_pm);
    Safefree(ct_buf);
    croak("kem_enc: Failed to release protmem");
  }

  ct_sv = newSV(0);
  sv_usepvn_flags(ct_sv, (char *)ct_buf, ct_len, SV_HAS_TRAILING_NUL);
  mXPUSHs(ct_sv);
  mXPUSHs(protmem_to_sv(aTHX_ ss_pm, MEMVAULT_CLASS));
  XSRETURN(2);
#else
  croak("kem_enc: KEM not supported by this version of libsodium");
#endif

void kem_keypair(SV * seed = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  kem_mlkem768_keypair = 1
  kem_xwing_keypair = 2

  PREINIT:
  protmem *seed_pm = NULL, *sk_pm;
  SV *pk_sv;
  unsigned char *pk_buf, *seed_buf;
  STRLEN seed_len, seed_req_len, pk_len, sk_len;
  unsigned int sk_flags = g_protmem_default_flags_key;

  PPCODE:
#ifdef SODIUM_HAS_KEM
  SvGETMAGIC(flags);
  if (SvOK(flags))
    sk_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      seed_req_len = crypto_kem_mlkem768_SEEDBYTES;
      pk_len = crypto_kem_mlkem768_PUBLICKEYBYTES;
      sk_len = crypto_kem_mlkem768_SECRETKEYBYTES;
      break;
    case 2:
      seed_req_len = crypto_kem_xwing_SEEDBYTES;
      pk_len = crypto_kem_xwing_PUBLICKEYBYTES;
      sk_len = crypto_kem_xwing_SECRETKEYBYTES;
      break;
    default:
      seed_req_len = crypto_kem_SEEDBYTES;
      pk_len = crypto_kem_PUBLICKEYBYTES;
      sk_len = crypto_kem_SECRETKEYBYTES;
  }

  Newx(pk_buf, pk_len + 1, unsigned char);
  if (pk_buf == NULL)
    croak("kem_seed_keypair: Failed to allocate memory");
  pk_buf[pk_len] = '\0';

  SvGETMAGIC(seed);
  if (!SvOK(seed)) {
    sk_pm = protmem_init(aTHX_ sk_len, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("kem_keypair: Failed to allocate protmem");
    }
    switch(ix) {
      case 1:
        crypto_kem_mlkem768_keypair(pk_buf, sk_pm->pm_ptr);
        break;
      case 2:
        crypto_kem_xwing_keypair(pk_buf, sk_pm->pm_ptr);
        break;
      default:
        crypto_kem_keypair(pk_buf, sk_pm->pm_ptr);
    }
  }
  else {
    if (sv_derived_from(seed, MEMVAULT_CLASS)) {
      seed_pm = protmem_get(aTHX_ seed, MEMVAULT_CLASS);
      seed_buf = seed_pm->pm_ptr;
      seed_len = seed_pm->size;
    }
    else
      seed_buf = (unsigned char *)SvPVbyte_nomg(seed, seed_len);
    if (seed_len != seed_req_len) {
      Safefree(pk_buf);
      croak("kem_keypair: Invalid seed length: %lu", seed_len);
    }
    sk_pm = protmem_init(aTHX_ sk_len, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("kem_keypair: Failed to allocate protmem");
    }

    if (seed_pm && protmem_grant(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kem_keypair: Failed to grant seed protmem RO");
    }

    switch(ix) {
      case 1:
        crypto_kem_mlkem768_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
        break;
      case 2:
        crypto_kem_xwing_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
        break;
      default:
        crypto_kem_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
    }

    if (seed_pm && protmem_release(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("kem_keypair: Failed to release seed protmem RO");
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
#else
  croak("kem_enc: KEM not supported by this version of libsodium");
#endif

