=for documentation

skipping sign_edwards25519sha512batch as it is not recommended. providing
aliases for sign_ed25519 as with other packages, though it is the default.

=cut

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::sign

void _define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::sign", 0);

  PPCODE:
  newCONSTSUB(stash, "sign_BYTES", newSVuv(crypto_sign_BYTES));
  newCONSTSUB(stash, "sign_ed25519_BYTES", newSVuv(crypto_sign_ed25519_BYTES));
  newCONSTSUB(stash, "sign_MESSAGEBYTES_MAX",
              newSVuv(crypto_sign_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "sign_ed25519_MESSAGEBYTES_MAX",
              newSVuv(crypto_sign_ed25519_MESSAGEBYTES_MAX));
  newCONSTSUB(stash, "sign_PUBLICKEYBYTES",
              newSVuv(crypto_sign_PUBLICKEYBYTES));
  newCONSTSUB(stash, "sign_ed25519_PUBLICKEYBYTES",
              newSVuv(crypto_sign_ed25519_PUBLICKEYBYTES));
  newCONSTSUB(stash, "sign_SECRETKEYBYTES",
              newSVuv(crypto_sign_SECRETKEYBYTES));
  newCONSTSUB(stash, "sign_ed25519_SECRETKEYBYTES",
              newSVuv(crypto_sign_ed25519_SECRETKEYBYTES));
  newCONSTSUB(stash, "sign_SEEDBYTES", newSVuv(crypto_sign_SEEDBYTES));
  newCONSTSUB(stash, "sign_ed25519_SEEDBYTES",
              newSVuv(crypto_sign_ed25519_SEEDBYTES));
  newCONSTSUB(stash, "sign_PRIMITIVE", newSVpvs(crypto_sign_PRIMITIVE));

SV * sign(SV * msg, SV * sk)

  ALIAS:
  sign_ed25519 = 1

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *sk_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *sk_buf;
  unsigned char *smsg_buf;
  STRLEN msg_len;
  STRLEN sk_len;
  STRLEN sk_req_len;
  STRLEN sig_len;
  int (*func)(unsigned char *, unsigned long long *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      sk_req_len = crypto_sign_ed25519_SECRETKEYBYTES;
      sig_len = crypto_sign_ed25519_BYTES;
      func = crypto_sign_ed25519;
      break;
    default:
      sk_req_len = crypto_sign_SECRETKEYBYTES;
      sig_len = crypto_sign_BYTES;
      func = crypto_sign;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("sign: Invalid secret key length %lu", sk_len);

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign: Failed to grant sk protmem RO");

  RETVAL = &PL_sv_undef;

  /* if the msg came from a MemVault, the signed message is MemVault.
   * if not, use a regular SV. */
  if (msg_pm) {
    protmem *smsg_pm;
    int ret;

    smsg_pm = protmem_init(aTHX_ sig_len + msg_len, msg_pm->flags);
    if (smsg_pm == NULL) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("sign: Failed to allocate protmem");
    }

    if (protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ smsg_pm);
      croak("sign: Failed to grant msg protmem RO");
    }

    ret = func(smsg_pm->pm_ptr, NULL, msg_buf, msg_len, sk_buf);

    if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ smsg_pm);
      croak("sign: Failed to release msg protmem RO");
    }

    if (protmem_release(aTHX_ smsg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ smsg_pm);
      croak("sign: Failed to release signed msg protmem RO");
    }

    if (ret == 0)
      RETVAL = protmem_to_sv(aTHX_ smsg_pm, MEMVAULT_CLASS);
  }
  else {
    STRLEN smsg_len = sig_len + msg_len;

    Newx(smsg_buf, smsg_len + 1, unsigned char);
    if (smsg_buf == NULL) {
      if (sk_pm)
        protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("sign: Failed to allocate memory");
    }
    smsg_buf[smsg_len] = '\0';

    if (func(smsg_buf, NULL, msg_buf, msg_len, sk_buf) == 0) {
      RETVAL = newSV(0);
      sv_usepvn_flags(RETVAL, (char *)smsg_buf, smsg_len, SV_HAS_TRAILING_NUL);
    }
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign: Failed to release sk protmem RO");

  OUTPUT:
  RETVAL

SV * sign_detached(SV * msg, SV * sk)

  ALIAS:
  sign_ed25519_detached = 1

  PREINIT:
  protmem *msg_pm = NULL;
  protmem *sk_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *sk_buf;
  unsigned char *sig_buf;
  STRLEN msg_len;
  STRLEN sk_len;
  STRLEN sk_req_len;
  STRLEN sig_len;
  int (*func)(unsigned char *, unsigned long long *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      sk_req_len = crypto_sign_ed25519_SECRETKEYBYTES;
      sig_len = crypto_sign_ed25519_BYTES;
      func = crypto_sign_ed25519_detached;
      break;
    default:
      sk_req_len = crypto_sign_SECRETKEYBYTES;
      sig_len = crypto_sign_BYTES;
      func = crypto_sign_detached;
  }

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != sk_req_len)
    croak("Invalid secret key length %lu", sk_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign_detached: Failed to grant msg protmem RO");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_detached: Failed to grant sk protmem RO");
  }

  Newx(sig_buf, sig_len + 1, unsigned char);
  if (sig_buf == NULL) {
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_detached: Failed to allocate memory");
  }
  sig_buf[sig_len] = '\0';

  RETVAL = &PL_sv_undef;

  if (func(sig_buf, NULL, msg_buf, msg_len, sk_buf) == 0) {
    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, (char *)sig_buf, sig_len, SV_HAS_TRAILING_NUL);
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (msg_pm)
      protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_detached: Failed to release sk protmem RO");
  }

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign_detached: Failed to release msg protmem RO");

  OUTPUT:
  RETVAL

SV * sign_pk_to_curve25519(SV * pk)

  ALIAS:
  sign_ed25519_pk_to_curve25519 = 1

  PREINIT:
  unsigned char *pk_buf;
  unsigned char *ed_buf;
  STRLEN pk_len;

  CODE:
  PERL_UNUSED_VAR(ix);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != crypto_sign_ed25519_PUBLICKEYBYTES)
    croak("Invalid public key length %lu", pk_len);

  Newx(ed_buf, crypto_scalarmult_curve25519_BYTES + 1, unsigned char);
  if (ed_buf == NULL)
    croak("Failed to allocate memory");
  ed_buf[crypto_scalarmult_curve25519_BYTES] = '\0';

  if (crypto_sign_ed25519_pk_to_curve25519(ed_buf, pk_buf) != 0) {
    Safefree(ed_buf);
    croak("Convert public key to curve25519 failed");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)ed_buf, crypto_scalarmult_curve25519_BYTES,
                  SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sign_sk_to_curve25519(SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  sign_ed25519_sk_to_curve25519 = 1

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *ed_pm;
  unsigned char *sk_buf;
  STRLEN sk_len;
  unsigned int ed_flags = g_protmem_flags_key_default;

  CODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    ed_flags = SvUV(flags);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_sign_ed25519_SECRETKEYBYTES)
    croak("sign_sk_to_curve25519: Invalid secret key length %lu", sk_len);

  ed_pm = protmem_init(aTHX_ crypto_scalarmult_curve25519_BYTES, ed_flags);
  if (ed_pm == NULL)
    croak("sign_sk_to_curve25519: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ed_pm);
    croak("sign_sk_to_curve25519: Failed to grant sk protmem RO");
  }

  if (crypto_sign_ed25519_sk_to_curve25519(ed_pm->pm_ptr, sk_buf) != 0) {
    protmem_free(aTHX_ ed_pm);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_sk_to_curve25519: Convert secret key to curve25519 failed");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ ed_pm);
    croak("sign_sk_to_curve25519: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ ed_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ ed_pm);
    croak("sign_sk_to_curve25519: Failed to release ed protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ ed_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * sign_sk_to_pk(SV * sk)

  ALIAS:
  sign_ed25519_sk_to_pk = 1

  PREINIT:
  protmem *sk_pm = NULL;
  unsigned char *sk_buf;
  unsigned char *pk_buf;
  STRLEN sk_len;

  CODE:
  PERL_UNUSED_VAR(ix);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_sign_ed25519_SECRETKEYBYTES)
    croak("sign_sk_to_pk: Invalid secret key length %lu", sk_len);

  Newx(pk_buf, crypto_sign_ed25519_PUBLICKEYBYTES + 1, unsigned char);
  if (pk_buf == NULL)
    croak("sign_sk_to_pk: Failed to allocate memory");
  pk_buf[crypto_sign_ed25519_PUBLICKEYBYTES] = '\0';

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(pk_buf);
    croak("sign_sk_to_pk: Failed to grant sk protmem RO");
  }

  if (crypto_sign_ed25519_sk_to_pk(pk_buf, sk_buf) != 0) {
    Safefree(pk_buf);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_sk_to_pk: Extract public key from secret key failed");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(pk_buf);
    croak("sign_sk_to_pk: Failed to release sk protmem RO");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)pk_buf, crypto_sign_ed25519_PUBLICKEYBYTES,
                  SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sign_sk_to_seed(SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  sign_ed25519_sk_to_seed = 1

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *seed_pm;
  unsigned char *sk_buf;
  STRLEN sk_len;
  unsigned int seed_flags = g_protmem_flags_key_default;

  CODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    seed_flags = SvUV(flags);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_sign_ed25519_SECRETKEYBYTES)
    croak("sign_sk_to_seed: Invalid secret key length %lu", sk_len);

  seed_pm = protmem_init(aTHX_ crypto_scalarmult_curve25519_BYTES, seed_flags);
  if (seed_pm == NULL)
    croak("sign_sk_to_seed: Failed to allocate protmem");

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ seed_pm);
    croak("sign_sk_to_seed: Failed to grant sk protmem RO");
  }

  if (crypto_sign_ed25519_sk_to_seed(seed_pm->pm_ptr, sk_buf) != 0) {
    protmem_free(aTHX_ seed_pm);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_sk_to_seed: Extract seed from secret key failed");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ seed_pm);
    croak("sign_sk_to_seed: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ seed_pm);
    croak("sign_sk_to_seed: Failed to release seed protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ seed_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * sign_init(SV * flags = &PL_sv_undef)

  ALIAS:
  sign_ed25519_init = 1

  PREINIT:
  protmem *state_pm;
  unsigned int state_flags = g_protmem_flags_state_default;

  CODE:
  if (SvOK(flags))
    state_flags = SvUV(flags);

  switch(ix) {
    case 1:
      state_pm = protmem_init(aTHX_ sizeof(crypto_sign_ed25519ph_state), state_flags);
      if (state_pm == NULL)
        croak("sign_init: Failed to allocate state protmem");
      crypto_sign_ed25519ph_init(state_pm->pm_ptr);
      break;
    default:
      state_pm = protmem_init(aTHX_ sizeof(crypto_sign_state), state_flags);
      if (state_pm == NULL)
        croak("sign_init: Failed to allocate state protmem");
      crypto_sign_init(state_pm->pm_ptr);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ state_pm);
    croak("sign_init: Failed to release state protmem RW");
  }

  switch(ix) {
    case 1:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      RETVAL = protmem_to_sv(aTHX_ state_pm, "Crypt::Sodium::XS::sign::multi"); }

  OUTPUT:
  RETVAL

void sign_keypair(SV * seed = &PL_sv_undef, SV * flags = &PL_sv_undef)

  ALIAS:
  sign_ed25519_keypair = 1

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
      seed_req_len = crypto_sign_ed25519_SEEDBYTES;
      pk_len = crypto_sign_ed25519_PUBLICKEYBYTES;
      sk_len = crypto_sign_ed25519_SECRETKEYBYTES;
      break;
    default:
      seed_req_len = crypto_sign_SEEDBYTES;
      pk_len = crypto_sign_PUBLICKEYBYTES;
      sk_len = crypto_sign_SECRETKEYBYTES;
  }

  Newx(pk_buf, pk_len + 1, unsigned char);
  if (pk_buf == NULL)
    croak("sign_keypair: Failed to allocate memory");
  pk_buf[pk_len] = '\0';

  if (!SvOK(seed)) {
    sk_pm = protmem_init(aTHX_ sk_len, sk_flags);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("sign_keypair: Failed to allocate protmem");
    }
    switch(ix) {
      case 1:
        crypto_sign_ed25519_keypair(pk_buf, sk_pm->pm_ptr);
        break;
      default:
        crypto_sign_keypair(pk_buf, sk_pm->pm_ptr);
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
      croak("sign_keypair: Invalid seed length: %lu", seed_len);
    }

    sk_pm = protmem_init(aTHX_ sk_len, g_protmem_flags_key_default);
    if (sk_pm == NULL) {
      Safefree(pk_buf);
      croak("sign_keypair: Failed to allocate protmem");
    }

    if (seed_pm && protmem_grant(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("sign_keypair: Failed to grant seed protmem RO");
    }

    switch(ix) {
      case 1:
        crypto_sign_ed25519_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
        break;
      default:
        crypto_sign_seed_keypair(pk_buf, sk_pm->pm_ptr, seed_buf);
    }

    if (seed_pm && protmem_release(aTHX_ seed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("sign_keypair: Failed to release seed protmem RO");
    }

    if (protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ sk_pm);
      Safefree(pk_buf);
      croak("sign_keypair: Failed to release sk protmem RO");
    }

  }

  pk_sv = newSV(0);
  sv_usepvn_flags(pk_sv, (char *)pk_buf, pk_len, SV_HAS_TRAILING_NUL);
  mXPUSHs(pk_sv);
  mXPUSHs(protmem_to_sv(aTHX_ sk_pm, MEMVAULT_CLASS));
  XSRETURN(2);

SV * sign_open(SV * smsg, SV * pk)

  ALIAS:
  sign_ed25519_open = 1

  PREINIT:
  protmem *smsg_pm = NULL;
  unsigned char *smsg_buf;
  unsigned char *pk_buf;
  unsigned char *msg_buf;
  STRLEN smsg_len;
  STRLEN pk_len;
  STRLEN pk_req_len;
  STRLEN sig_len;
  int (*func)(unsigned char *, unsigned long long *, const unsigned char *,
              unsigned long long, const unsigned char *);

  CODE:
  switch(ix) {
    case 1:
      pk_req_len = crypto_sign_ed25519_PUBLICKEYBYTES;
      sig_len = crypto_sign_ed25519_BYTES;
      func = crypto_sign_ed25519_open;
      break;
    default:
      pk_req_len = crypto_sign_PUBLICKEYBYTES;
      sig_len = crypto_sign_BYTES;
      func = crypto_sign_open;
  }

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("sign_open: Invalid public key length %lu", pk_len);

  if (sv_derived_from(smsg, MEMVAULT_CLASS)) {
    smsg_pm = protmem_get(aTHX_ smsg, MEMVAULT_CLASS);
    smsg_buf = smsg_pm->pm_ptr;
    smsg_len = smsg_pm->size;
  }
  else
    smsg_buf = (unsigned char *)SvPVbyte(smsg, smsg_len);

  /* if the signed msg came from a MemVault, the returned message is
   * MemVault (with same locking). if not, use a regular SV. */
  if (smsg_pm) {
    protmem *msg_pm;

    msg_pm = protmem_init(aTHX_ smsg_len - sig_len, smsg_pm->flags);
    if (msg_pm == NULL)
      croak("sign_open: Failed to allocate protmem");

    if (protmem_grant(aTHX_ smsg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ msg_pm);
      croak("sign_open: Failed to grant signed message protmem RO");
    }

    if (func(msg_pm->pm_ptr, NULL, smsg_buf, smsg_len, pk_buf) != 0) {
      protmem_release(aTHX_ smsg_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ msg_pm);
      croak("sign_open: Signature forged");
    }

    if (protmem_release(aTHX_ smsg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ msg_pm);
      croak("sign_open: Failed to release signed message protmem RO");
    }

    if (protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ msg_pm);
      croak("sign_open: Failed to release msg protmem RO");
    }

    RETVAL = protmem_to_sv(aTHX_ msg_pm, MEMVAULT_CLASS);
  }
  else {
    STRLEN msg_len = smsg_len - sig_len;

    Newx(msg_buf, msg_len + 1, unsigned char);
    if (msg_buf == NULL)
      croak("sign_open: Failed to allocate memory");
    msg_buf[msg_len] = '\0';

    if (func(msg_buf, NULL, smsg_buf, smsg_len, pk_buf) != 0) {
      Safefree(msg_buf);
      croak("sign_open: Signature forged");
    }

    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, (char *)msg_buf, msg_len, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

void sign_to_curve25519(SV * pk, SV * sk, SV * flags = &PL_sv_undef)

  ALIAS:
  sign_ed25519_to_curve25519 = 1

  PREINIT:
  protmem *sk_pm = NULL;
  protmem *sk_ed_pm;
  SV *pk_ed_sv;
  unsigned char *pk_buf;
  unsigned char *sk_buf;
  unsigned char *pk_ed_buf;
  STRLEN pk_len;
  STRLEN sk_len;
  unsigned int sk_flags = g_protmem_flags_key_default;

  PPCODE:
  PERL_UNUSED_VAR(ix);

  if (SvOK(flags))
    sk_flags = SvUV(flags);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != crypto_sign_ed25519_PUBLICKEYBYTES)
    croak("sign_to_curve25519: Invalid public key length %lu", pk_len);

  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  if (sk_len != crypto_sign_ed25519_SECRETKEYBYTES)
    croak("sign_to_curve25519: Invalid secret key length %lu", sk_len);

  Newx(pk_ed_buf, crypto_scalarmult_curve25519_BYTES + 1, unsigned char);
  if (pk_ed_buf == NULL)
    croak("sign_to_curve25519: Failed to allocate memory");
  pk_ed_buf[crypto_scalarmult_curve25519_BYTES] = '\0';

  if (crypto_sign_ed25519_pk_to_curve25519(pk_ed_buf, pk_buf) != 0) {
    Safefree(pk_ed_buf);
    croak("sign_to_curve25519: Failed to convert public key to curve25519");
  }

  sk_ed_pm = protmem_init(aTHX_ crypto_scalarmult_curve25519_BYTES, sk_flags);
  if (sk_ed_pm == NULL) {
    Safefree(pk_ed_buf);
    croak("sign_to_curve25519: Failed to allocate protmem");
  }

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(pk_ed_buf);
    protmem_free(aTHX_ sk_ed_pm);
    croak("sign_to_curve25519: Failed to grant sk protmem RO");
  }

  if (crypto_sign_ed25519_sk_to_curve25519(sk_ed_pm->pm_ptr, sk_buf) != 0) {
    Safefree(pk_ed_buf);
    protmem_free(aTHX_ sk_ed_pm);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sign_to_curve25519: Failed to convert secret key to curve25519");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(pk_ed_buf);
    protmem_free(aTHX_ sk_ed_pm);
    croak("sign_to_curve25519: Failed to release sk protmem RO");
  }

  if (protmem_release(aTHX_ sk_ed_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(pk_ed_buf);
    protmem_free(aTHX_ sk_ed_pm);
    croak("sign_to_curve25519: Failed to release ed protmem RO");
  }

  pk_ed_sv = newSV(0);
  sv_usepvn_flags(pk_ed_sv, (char *)pk_ed_buf, crypto_scalarmult_curve25519_BYTES,
                  SV_HAS_TRAILING_NUL);
  mXPUSHs(pk_ed_sv);
  mXPUSHs(protmem_to_sv(aTHX_ sk_ed_pm, MEMVAULT_CLASS));
  XSRETURN(2);

void sign_verify(SV * msg, SV * sig, SV * pk)

  ALIAS:
  sign_ed25519_verify = 1

  PREINIT:
  protmem *msg_pm = NULL;
  unsigned char *msg_buf;
  unsigned char *sig_buf;
  unsigned char *pk_buf;
  STRLEN msg_len;
  STRLEN sig_len;
  STRLEN pk_len;
  STRLEN sig_req_len;
  STRLEN pk_req_len;
  int ret;
  int (*func)(const unsigned char *, const unsigned char *,
              unsigned long long, const unsigned char *);

  PPCODE:
  switch(ix) {
    case 1:
      sig_req_len = crypto_sign_ed25519_BYTES;
      pk_req_len = crypto_sign_ed25519_PUBLICKEYBYTES;
      func = crypto_sign_ed25519_verify_detached;
      break;
    default:
      sig_req_len = crypto_sign_BYTES;
      pk_req_len = crypto_sign_PUBLICKEYBYTES;
      func = crypto_sign_verify_detached;
  }

  sig_buf = (unsigned char *)SvPVbyte(sig, sig_len);
  if (sig_len != sig_req_len)
    croak("sign_verify: Invalid signature length %lu", sig_len);

  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);
  if (pk_len != pk_req_len)
    croak("sign_verify: Invalid public key length %lu", pk_len);

  if (sv_derived_from(msg, MEMVAULT_CLASS)) {
    msg_pm = protmem_get(aTHX_ msg, MEMVAULT_CLASS);
    msg_buf = msg_pm->pm_ptr;
    msg_len = msg_pm->size;
  }
  else
    msg_buf = (unsigned char *)SvPVbyte(msg, msg_len);

  if (msg_pm && protmem_grant(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign_verify: Failed to grant msg protmem RO");

  ret = func(sig_buf, msg_buf, msg_len, pk_buf);

  if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("sign_verify: Failed to release msg protmem RO");

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::sign::multi

void DESTROY(SV * self)

  ALIAS:
  Crypt::Sodium::XS::sign::ed25519ph_multi::DESTROY = 1

  PREINIT:
  protmem *state_pm;

  CODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::multi");
  }
  protmem_free(aTHX_ state_pm);

SV * clone(SV * self)

  ALIAS:
  Crypt::Sodium::XS::sign::ed25519ph_multi::clone = 1

  CODE:
  switch(ix) {
    case 1:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      RETVAL = protmem_clone_sv(aTHX_ self, "Crypt::Sodium::XS::sign::multi");
  }

  OUTPUT:
  RETVAL

SV * final_sign(SV * self, SV * sk)

  ALIAS:
  Crypt::Sodium::XS::sign::ed25519ph_multi::final_sign = 1

  PREINIT:
  protmem *state_pm;
  protmem *sk_pm = NULL;
  unsigned char *sk_buf;
  unsigned char *sig_buf;
  STRLEN sk_len;

  CODE:
  if (sv_derived_from(sk, MEMVAULT_CLASS)) {
    sk_pm = protmem_get(aTHX_ sk, MEMVAULT_CLASS);
    sk_buf = sk_pm->pm_ptr;
    sk_len = sk_pm->size;
  }
  else
    sk_buf = (unsigned char *)SvPVbyte(sk, sk_len);
  switch(ix) {
    case 1:
      if (sk_len != crypto_sign_SECRETKEYBYTES)
        croak("final_sign: Invalid secret key length %lu", sk_len);

      Newx(sig_buf, crypto_sign_BYTES + 1, unsigned char);
      if (sig_buf == NULL)
        croak("final_sign: Failed to allocate memory");
      sig_buf[crypto_sign_BYTES] = '\0';
      break;
    default:
      if (sk_len != crypto_sign_ed25519_SECRETKEYBYTES)
        croak("final_sign: Invalid secret key length %lu", sk_len);

      Newx(sig_buf, crypto_sign_ed25519_BYTES + 1, unsigned char);
      if (sig_buf == NULL)
        croak("final_sign: Failed to allocate memory");
      sig_buf[crypto_sign_ed25519_BYTES] = '\0';
  }

  if (sk_pm && protmem_grant(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(sig_buf);
    croak("final_sign: Failed to grant sk protmem RO");
  }

  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(sig_buf);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("final_sign: Failed to grant state protmem RW");
  }

  switch(ix) {
    case 1:
      crypto_sign_ed25519ph_final_create(state_pm->pm_ptr, sig_buf, NULL, sk_buf);
      break;
    default:
      crypto_sign_final_create(state_pm->pm_ptr, sig_buf, NULL, sk_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    Safefree(sig_buf);
    if (sk_pm)
      protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("final_sign: Failed to release state protmem RW");
  }

  if (sk_pm && protmem_release(aTHX_ sk_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(sig_buf);
    croak("final_sign: Failed to release sk protmem RO");
  }

  RETVAL = newSV(0);
  switch(ix) {
    case 1:
      sv_usepvn_flags(RETVAL, (char *)sig_buf, crypto_sign_ed25519_BYTES, SV_HAS_TRAILING_NUL);
      break;
    default:
      sv_usepvn_flags(RETVAL, (char *)sig_buf, crypto_sign_BYTES, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

void final_verify(SV * self, SV * sig, SV * pk)

  ALIAS:
  Crypt::Sodium::XS::sign::ed25519ph_multi::final_verify = 1

  PREINIT:
  protmem *state_pm;
  unsigned char *sig_buf;
  unsigned char *pk_buf;
  STRLEN sig_len;
  STRLEN pk_len;
  int ret;

  PPCODE:
  sig_buf = (unsigned char *)SvPVbyte(sig, sig_len);
  pk_buf = (unsigned char *)SvPVbyte(pk, pk_len);

  switch(ix) {
    case 1:
      if (sig_len != crypto_sign_ed25519_BYTES)
        croak("final_verify: Invalid signature length %lu", sig_len);
      if (pk_len != crypto_sign_ed25519_PUBLICKEYBYTES)
        croak("final_verify: Invalid public key length %lu", pk_len);
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      if (sig_len != crypto_sign_BYTES)
        croak("final_verify: Invalid signature length %lu", sig_len);
      if (pk_len != crypto_sign_PUBLICKEYBYTES)
        croak("final_verify: Invalid public key length %lu", pk_len);
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::multi");
  }

  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("final_verify: Failed to grant state protmem RW");

  switch(ix) {
    case 1:
      ret = crypto_sign_ed25519ph_final_verify(state_pm->pm_ptr, sig_buf, pk_buf);
      break;
    default:
      ret = crypto_sign_final_verify(state_pm->pm_ptr, sig_buf, pk_buf);
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("final_verify: Failed to release state protmem RW");

  if (ret == 0)
    XSRETURN_YES;

  XSRETURN_NO;

void update(SV * self, ...)

  ALIAS:
  Crypt::Sodium::XS::sign::ed25519ph_multi::update = 1

  PREINIT:
  protmem *state_pm;
  protmem *msg_pm;
  unsigned char *msg_buf;
  STRLEN msg_len;
  I32 i;

  PPCODE:
  switch(ix) {
    case 1:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::ed25519ph_multi");
      break;
    default:
      state_pm = protmem_get(aTHX_ self, "Crypt::Sodium::XS::sign::multi");
  }
  if (protmem_grant(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to grant state protmem RW");

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
        crypto_sign_ed25519ph_update(state_pm->pm_ptr, msg_buf, msg_len);
        break;
      default:
        crypto_sign_update(state_pm->pm_ptr, msg_buf, msg_len);
    }

    if (msg_pm && protmem_release(aTHX_ msg_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW);
      croak("update: Failed to release msg protmem RO");
    }

    msg_pm = NULL;
  }

  if (protmem_release(aTHX_ state_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("update: Failed to release state protmem RW");

  XSRETURN(1);
