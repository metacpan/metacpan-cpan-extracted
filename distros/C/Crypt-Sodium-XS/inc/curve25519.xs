MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::curve25519

void
_define_constants()
  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::curve25519", 0);

  PPCODE:
  newCONSTSUB(stash, "core_ed25519_BYTES",
              newSVuv(crypto_core_ed25519_BYTES));
  newCONSTSUB(stash, "core_ed25519_HASHBYTES",
              newSVuv(crypto_core_ed25519_HASHBYTES));
  newCONSTSUB(stash, "core_ed25519_NONREDUCEDSCALARBYTES",
              newSVuv(crypto_core_ed25519_NONREDUCEDSCALARBYTES));
  newCONSTSUB(stash, "core_ed25519_SCALARBYTES",
              newSVuv(crypto_core_ed25519_SCALARBYTES));
  newCONSTSUB(stash, "core_ed25519_UNIFORMBYTES",
              newSVuv(crypto_core_ed25519_UNIFORMBYTES));
#ifdef SODIUM_HAS_RISTRETTO255
  newCONSTSUB(stash, "core_ristretto255_BYTES",
              newSVuv(crypto_core_ristretto255_BYTES));
  newCONSTSUB(stash, "core_ristretto255_HASHBYTES",
              newSVuv(crypto_core_ristretto255_HASHBYTES));
  newCONSTSUB(stash, "core_ristretto255_NONREDUCEDSCALARBYTES",
              newSVuv(crypto_core_ristretto255_NONREDUCEDSCALARBYTES));
  newCONSTSUB(stash, "core_ristretto255_SCALARBYTES",
              newSVuv(crypto_core_ristretto255_SCALARBYTES));
  newCONSTSUB(stash, "core_ristretto255_available", &PL_sv_yes);
#else
  newCONSTSUB(stash, "core_ristretto255_available", &PL_sv_no);
#endif

SV * core_ed25519_add(SV * p, SV * q)

  ALIAS:
  core_ed25519_sub = 1
  core_ristretto255_add = 2
  core_ristretto255_sub = 3

  PREINIT:
  protmem *p_pm = NULL, *q_pm = NULL;
  int ret;
  unsigned char *a_buf, *p_buf, *q_buf;
  STRLEN a_len, p_len, p_req_len, q_len, q_req_len;

  CODE:
  switch(ix) {
    /* case 1 is same as default */
    case 2:
      /* fallthrough */
    case 3:
      a_len = crypto_core_ristretto255_BYTES;
      p_req_len = crypto_core_ristretto255_BYTES;
      q_req_len = crypto_core_ristretto255_BYTES;
      break;
    default:
      a_len = crypto_core_ed25519_BYTES;
      p_req_len = crypto_core_ed25519_BYTES;
      q_req_len = crypto_core_ed25519_BYTES;
  }
  if (sv_derived_from(p, MEMVAULT_CLASS)) {
    p_pm = protmem_get(aTHX_ p, MEMVAULT_CLASS);
    p_buf = p_pm->pm_ptr;
    p_len = p_pm->size;
  }
  else
    p_buf = (unsigned char *)SvPVbyte(p, p_len);
  if (p_len != p_req_len)
    croak("ed25519|ristretto255_add|sub: Invalid p length");

  if (sv_derived_from(q, MEMVAULT_CLASS)) {
    q_pm = protmem_get(aTHX_ q, MEMVAULT_CLASS);
    q_buf = q_pm->pm_ptr;
    q_len = q_pm->size;
  }
  else
    q_buf = (unsigned char *)SvPVbyte(q, q_len);
  if (q_len != q_req_len)
    croak("ed25519|ristretto255_add|sub: Invalid q length");

  /* ok to not use a memvault for output? */
  Newx(a_buf, a_len + 1, unsigned char);
  if (a_buf == NULL)
    croak("ed25519|ristretto255_add|sub: Failed to allocate memory");
  a_buf[a_len] = '\0';

  if (p_pm && protmem_grant(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(a_buf);
    croak("ed25519|ristretto255_add|sub: Failed to grant p protmem RO");
  }
  if (q_pm && protmem_grant(aTHX_ q_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_release(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(a_buf);
    croak("ed25519|ristretto255_add|sub: Failed to grant q protmem RO");
  }

  switch(ix) {
    case 1:
      ret = crypto_core_ed25519_sub(a_buf, p_buf, q_buf);
      break;
    case 2:
      ret = crypto_core_ristretto255_add(a_buf, p_buf, q_buf);
      break;
    case 3:
      ret = crypto_core_ristretto255_sub(a_buf, p_buf, q_buf);
      break;
    default:
      ret = crypto_core_ed25519_add(a_buf, p_buf, q_buf);
  }
  
  if (q_pm && protmem_release(aTHX_ q_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_release(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO);
    Safefree(a_buf);
    croak("ed25519|ristretto255_add|sub: Failed to release q protmem RO");
  }
  if (p_pm && protmem_release(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    Safefree(a_buf);
    croak("ed25519|ristretto255_add|sub: Failed to release p protmem RO");
  }
  if (ret != 0) {
    Safefree(a_buf);
    croak("ed25519|ristretto255_add|sub: Failed to add or sub: p or q were not valid points");
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)a_buf, a_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * core_ed25519_from_uniform(SV * r)

  ALIAS:
  core_ristretto255_from_hash = 1

  PREINIT:
  STRLEN p_len, r_len, r_req_len;
  unsigned char *p_buf, *r_buf;

  CODE:
  switch(ix) {
    case 1:
      p_len = crypto_core_ristretto255_BYTES;
      r_req_len = crypto_core_ristretto255_BYTES;
      break;
    default:
      p_len = crypto_core_ed25519_BYTES;
      r_req_len = crypto_core_ed25519_BYTES;
  }
  r_buf = (unsigned char *)SvPVbyte(r, r_len);
  if (r_len != r_req_len)
    croak("ed25519_from_uniform: invalid vector length");

  Newx(p_buf, p_len + 1, unsigned char);
  if (p_buf == NULL)
    croak("ed25519_from_uniform: Failed to allocate memory");
  p_buf[p_len] = '\0';

  switch(ix) {
    case 1:
      crypto_core_ristretto255_from_hash(p_buf, r_buf);
      break;
    default:
      crypto_core_ed25519_from_uniform(p_buf, r_buf);
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)p_buf, p_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * core_ed25519_is_valid_point(SV * p)

  ALIAS:
  core_ristretto255_is_valid_point = 1

  PREINIT:
  protmem *p_pm = NULL;
  int ret;
  unsigned char *p_buf;
  STRLEN p_len, p_req_len;

  PPCODE:
  PERL_UNUSED_VAR(RETVAL);
  switch(ix) {
    case 1:
      p_req_len = crypto_core_ristretto255_BYTES;
      break;
    default:
      p_req_len = crypto_core_ed25519_BYTES;
  }
  if (sv_derived_from(p, MEMVAULT_CLASS)) {
    p_pm = protmem_get(aTHX_ p, MEMVAULT_CLASS);
    p_buf = p_pm->pm_ptr;
    p_len = p_pm->size;
  }
  else
    p_buf = (unsigned char *)SvPVbyte(p, p_len);
  if (p_len != p_req_len)
    croak("ed25519_is_valid_point: Invalid point length");

  if (p_pm && protmem_grant(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("ed25519_is_valid_point: Failed to grant protmem RO");

  switch(ix) {
    case 1:
      ret = crypto_core_ristretto255_is_valid_point(p_buf);
      break;
    default:
      ret = crypto_core_ed25519_is_valid_point(p_buf);
  }

  if (p_pm && protmem_release(aTHX_ p_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("ed25519_is_valid_point: Failed to release protmem RO");

  if (ret == 1)
    XSRETURN_YES;
  XSRETURN_NO;

SV * core_ed25519_random()

  ALIAS:
  core_ristretto255_random = 1

  PREINIT:
  unsigned char *p_buf;
  STRLEN p_len;

  CODE:
  switch(ix) {
    case 1:
      p_len = crypto_core_ristretto255_BYTES;
      break;
    default:
      p_len = crypto_core_ed25519_BYTES;
  }
  Newx(p_buf, p_len + 1, unsigned char);
  if (p_buf == NULL)
    croak("ed25519_scalar_random: Failed to allocate memory");
  p_buf[p_len] = '\0';

  switch(ix) {
    case 1:
      crypto_core_ristretto255_random(p_buf);
      break;
    default:
      crypto_core_ed25519_random(p_buf);
  }

  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, (char *)p_buf, p_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * core_ed25519_scalar_add(SV * x, SV * y, SV * flags = &PL_sv_undef)

  ALIAS:
  core_ed25519_scalar_sub = 1
  core_ed25519_scalar_mul = 2
  core_ristretto255_scalar_add = 3
  core_ristretto255_scalar_sub = 4
  core_ristretto255_scalar_mul = 5

  PREINIT:
  protmem *new_pm, *x_pm = NULL, *y_pm = NULL;
  unsigned int new_flags = g_protmem_flags_key_default;
  STRLEN new_len, x_len, x_req_len, y_len, y_req_len;
  unsigned char *x_buf, *y_buf;

  CODE:
  switch(ix) {
    /* case 1 and 2 are same as default */
    case 3:
      /* fallthrough */
    case 4:
      /* fallthrough */
    case 5:
      new_len = crypto_core_ristretto255_SCALARBYTES;
      x_req_len = crypto_core_ristretto255_SCALARBYTES;
      y_req_len = crypto_core_ristretto255_SCALARBYTES;
      break;
    default:
      new_len = crypto_core_ed25519_SCALARBYTES;
      x_req_len = crypto_core_ed25519_SCALARBYTES;
      y_req_len = crypto_core_ed25519_SCALARBYTES;
  }
  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  if (sv_derived_from(x, MEMVAULT_CLASS)) {
    x_pm = protmem_get(aTHX_ x, MEMVAULT_CLASS);
    x_buf = x_pm->pm_ptr;
    x_len = x_pm->size;
  }
  else
    x_buf = (unsigned char *)SvPVbyte(x, x_len);
  if (x_len != x_req_len)
    croak("ed25519_scalar_add|sub|mul: Invalid x length");

  if (sv_derived_from(y, MEMVAULT_CLASS)) {
    y_pm = protmem_get(aTHX_ y, MEMVAULT_CLASS);
    y_buf = y_pm->pm_ptr;
    y_len = y_pm->size;
  }
  else
    y_buf = (unsigned char *)SvPVbyte(y, y_len);
  if (y_len != y_req_len)
    croak("ed25519_scalar_add|sub|mul: Invalid y length");

  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("ed25519_scalar_add|sub|mul: Failed to allocate protmem");

  if (x_pm && protmem_grant(aTHX_ x_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_add|sub|mul: Failed to grant x protmem RO");
  }
  if (y_pm && protmem_grant(aTHX_ y_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    protmem_release(aTHX_ x_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("ed25519_scalar_add|sub|mul: Failed to grant y protmem RO");
  }

  switch(ix) {
    case 1:
      crypto_core_ed25519_scalar_sub(new_pm->pm_ptr, x_buf, y_buf);
      break;
    case 2:
      crypto_core_ed25519_scalar_mul(new_pm->pm_ptr, x_buf, y_buf);
      break;
    case 3:
      crypto_core_ristretto255_scalar_add(new_pm->pm_ptr, x_buf, y_buf);
      break;
    case 4:
      crypto_core_ristretto255_scalar_sub(new_pm->pm_ptr, x_buf, y_buf);
      break;
    case 5:
      crypto_core_ristretto255_scalar_mul(new_pm->pm_ptr, x_buf, y_buf);
      break;
    default:
      crypto_core_ed25519_scalar_add(new_pm->pm_ptr, x_buf, y_buf);
  }

  if (y_pm && protmem_release(aTHX_ y_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    protmem_release(aTHX_ x_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("ed25519_scalar_add|sub: Failed to release y protmem RO");
  }
  if (x_pm && protmem_release(aTHX_ x_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_add|sub: Failed to release x protmem RO");
  }
  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_add|sub: Failed to release protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * core_ed25519_scalar_complement(SV * s, SV * flags = &PL_sv_undef)

  ALIAS:
  core_ed25519_scalar_invert = 1
  core_ed25519_scalar_negate = 2
  core_ed25519_scalar_reduce = 3
  core_ristretto255_scalar_complement = 4
  core_ristretto255_scalar_invert = 5
  core_ristretto255_scalar_negate = 6
  core_ristretto255_scalar_reduce = 7

  PREINIT:
  protmem *new_pm, *s_pm = NULL;
  unsigned int new_flags = g_protmem_flags_key_default;
  STRLEN new_len, s_len, s_req_len;
  unsigned char *s_buf;

  CODE:
  switch(ix) {
    case 4:
      /* fallthrough */
    case 5:
      /* fallthrough */
    case 6:
      new_len = crypto_core_ristretto255_SCALARBYTES;
      s_req_len = crypto_core_ristretto255_SCALARBYTES;
      break;
    default:
      new_len = crypto_core_ed25519_SCALARBYTES;
      s_req_len = crypto_core_ed25519_SCALARBYTES;
  }
  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV(flags);

  if (sv_derived_from(s, MEMVAULT_CLASS)) {
    s_pm = protmem_get(aTHX_ s, MEMVAULT_CLASS);
    s_buf = s_pm->pm_ptr;
    s_len = s_pm->size;
  }
  else
    s_buf = (unsigned char *)SvPVbyte(s, s_len);
  if (s_len != s_req_len)
    croak("ed25519_scalar_complement|invert|negate|reduce: Invalid x length");

  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("ed25519_scalar_add|sub|mul: Failed to allocate protmem");

  if (s_pm && protmem_grant(aTHX_ s_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_complement|invert|negate|reduce: Failed to grant s protmem RO");
  }

  switch(ix) {
    case 1:
      crypto_core_ed25519_scalar_invert(new_pm->pm_ptr, s_buf);
      break;
    case 2:
      crypto_core_ed25519_scalar_negate(new_pm->pm_ptr, s_buf);
      break;
    case 3:
      crypto_core_ed25519_scalar_reduce(new_pm->pm_ptr, s_buf);
      break;
    case 4:
      crypto_core_ristretto255_scalar_complement(new_pm->pm_ptr, s_buf);
      break;
    case 5:
      crypto_core_ristretto255_scalar_invert(new_pm->pm_ptr, s_buf);
      break;
    case 6:
      crypto_core_ristretto255_scalar_negate(new_pm->pm_ptr, s_buf);
      break;
    case 7:
      crypto_core_ristretto255_scalar_reduce(new_pm->pm_ptr, s_buf);
      break;
    default:
      crypto_core_ed25519_scalar_complement(new_pm->pm_ptr, s_buf);
  }

  if (s_pm && protmem_release(aTHX_ s_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_complement|invert|negate|reduce: Failed to release s protmem RO");
  }
  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("ed25519_scalar_complement|invert|negate|reduce: Failed to release protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * core_ed25519_scalar_random(SV * flags = &PL_sv_undef)

  ALIAS:
  core_ristretto255_scalar_random = 1

  PREINIT:
  protmem *new_pm;
  unsigned int new_flags = g_protmem_flags_key_default;
  STRLEN new_len;

  CODE:
  switch(ix) {
    case 1:
      new_len = crypto_core_ristretto255_SCALARBYTES;
      break;
    default:
      new_len = crypto_core_ed25519_SCALARBYTES;
  }
  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV(flags);
  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("ed25519_scalar_random: Failed to allocate protmem");
  switch(ix) {
    case 1:
      crypto_core_ristretto255_scalar_random(new_pm->pm_ptr);
      break;
    default:
      crypto_core_ed25519_scalar_random(new_pm->pm_ptr);
  }
  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    croak("ed25519_scalar_random: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL
