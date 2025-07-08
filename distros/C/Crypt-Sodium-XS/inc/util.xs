MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::Util

SV * sodium_add(SV * x, SV * y)

  PREINIT:
  unsigned char *x_buf;
  unsigned char *y_buf;
  unsigned char *longer_buf;
  unsigned char *shorter_buf;
  unsigned char *out_buf;
  STRLEN x_len;
  STRLEN y_len;
  STRLEN longer_len;
  STRLEN shorter_len;

  CODE:
  x_buf = (unsigned char *)SvPVbyte(x, x_len);
  y_buf = (unsigned char *)SvPVbyte(y, y_len);

  if (x_len < y_len) {
    longer_buf = y_buf;
    longer_len = y_len;
    shorter_buf = x_buf;
    shorter_len = x_len;
  }
  else {
    /* these are fine for the case of equal lengths. */
    longer_buf = x_buf;
    longer_len = x_len;
    shorter_buf = y_buf;
    shorter_len = y_len;
  }

  RETVAL = newSV(0);
  Newxz(out_buf, longer_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("Could not allocate memory");
  memcpy(out_buf, shorter_buf, shorter_len);

  sodium_add(out_buf, longer_buf, longer_len);

  sv_usepvn_flags(RETVAL, (char *)out_buf, longer_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sodium_bin2hex(SV * bytes)

  PREINIT:
  char *bytes_buf;
  char *out_buf;
  STRLEN bytes_len;
  STRLEN out_len;

  CODE:
  bytes_buf = SvPVbyte(bytes, bytes_len);
  out_len = bytes_len * 2;
  Newx(out_buf, out_len + 1, char);
  if (out_buf == NULL)
    croak("Failed to allocate memory");
  sodium_bin2hex(out_buf, out_len + 1, (unsigned char *)bytes_buf, bytes_len);
  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sodium_compare(SV * x, SV * y, STRLEN length = 0)

  PREINIT:
  unsigned char *x_buf;
  unsigned char *y_buf;
  STRLEN x_len;
  STRLEN y_len;

  CODE:
  x_buf = (unsigned char *)SvPVbyte(x, x_len);
  y_buf = (unsigned char *)SvPVbyte(y, y_len);

  if (length == 0) {
    if (x_len != y_len)
      croak("Length of operands must be equal without a length argument");
    length = x_len;
  }
  else {
    if (length > x_len)
      croak("The first argument is shorter then requested length");
    else if (length > y_len)
      croak("The second argument is shorter then requested length");
  }

  RETVAL = newSViv(sodium_compare(x_buf, y_buf, length));

  OUTPUT:
  RETVAL

SV * sodium_hex2bin(SV * bytes)

  PREINIT:
  char *bytes_buf;
  char *out_buf;
  STRLEN bytes_len;
  STRLEN out_len;

  CODE:
  bytes_buf = SvPVbyte(bytes, bytes_len);
  /* should check for overflow... */
  out_len = ((bytes_len + 1) & ~1) / 2;
  Newx(out_buf, out_len + 1, char);
  if (out_buf == NULL)
    croak("Failed to allocate memory");
  out_buf[out_len] = '\0';
  sodium_hex2bin((unsigned char *)out_buf, out_len + 1, bytes_buf, bytes_len,
                 NULL, &out_len, NULL);
  RETVAL = newSV(0);
  sv_usepvn_flags(RETVAL, out_buf, out_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sodium_increment(SV * val)

  PREINIT:
  unsigned char *buf;
  unsigned char *out_buf;
  STRLEN buf_len;

  CODE:
  if (SvREADONLY(val))
    croak("Cannot increment a read-only value");
  buf = (unsigned char *)SvPVbyte(val, buf_len);

  if (buf_len < 1)
    croak("Cannot increment a zero-length value");

  Newx(out_buf, buf_len + 1, unsigned char);
  if (out_buf == NULL)
    croak("Failed to allocate memeory");
  out_buf[buf_len] = '\0';

  memcpy(out_buf, buf, buf_len);

  sodium_increment(out_buf, buf_len);

  RETVAL=newSV(0);
  sv_usepvn_flags(RETVAL, (char *)out_buf, buf_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

SV * sodium_is_zero(SV * bytes)

  PREINIT:
  unsigned char *buf;
  STRLEN buf_len;

  CODE:
  buf = (unsigned char *)SvPVbyte(bytes, buf_len);
  if(sodium_is_zero(buf, buf_len))
    RETVAL = &PL_sv_yes;
  else
    RETVAL = &PL_sv_no;

  OUTPUT:
  RETVAL

SV * sodium_memcmp(SV * x, SV * y, STRLEN length = 0)

  PREINIT:
  unsigned char *x_buf;
  unsigned char *y_buf;
  STRLEN x_len;
  STRLEN y_len;

  CODE:
  x_buf = (unsigned char *)SvPVbyte(x, x_len);
  y_buf = (unsigned char *)SvPVbyte(y, y_len);

  if (length == 0) {
    if (x_len != y_len)
      croak("Length of operands must be equal without a length argument");
    length = x_len;
  }
  else {
    if (length > x_len)
      croak("The first argument is shorter then requested length");
    else if (length > y_len)
      croak("The second argument is shorter then requested length");
  }

  if (sodium_memcmp(x_buf, y_buf, length) == 0)
    RETVAL = &PL_sv_yes;
  else
    RETVAL = &PL_sv_no;

  OUTPUT:
  RETVAL

SV * sodium_random_bytes( \
  STRLEN out_len, \
  SV * use_memvault = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  CODE:
  if (out_len < 1)
    croak("Length must be greater than 0");

  if (SvTRUE(use_memvault)) {
    int mv_flags = g_protmem_flags_memvault_default;
    if (SvOK(flags))
      mv_flags = SvUV(flags);
    protmem *new_pm;
    new_pm = protmem_init(aTHX_ out_len, mv_flags);
    if (new_pm == NULL)
      croak("Failed to allocate protmem");
    randombytes_buf(new_pm->pm_ptr, out_len);
    if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      protmem_free(aTHX_ new_pm);
      croak("Failed to release protmem RW");
    }
    RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);
  }
  else {
    unsigned char *out_buf;

    Newx(out_buf, out_len + 1, unsigned char);
    if (out_buf == NULL)
      croak("Failed to allocate memory");
    out_buf[out_len] = '\0';

    randombytes_buf(out_buf, out_len);

    RETVAL = newSV(0);
    sv_usepvn_flags(RETVAL, (char *)out_buf, out_len, SV_HAS_TRAILING_NUL);
  }

  OUTPUT:
  RETVAL

SV * sodium_sub(SV * x, SV * y)

  PREINIT:
  unsigned char *x_buf;
  unsigned char *y_buf;
  unsigned char *out_buf;
  unsigned char *realloc_buf = NULL;
  STRLEN x_len;
  STRLEN y_len;

  CODE:
  x_buf = (unsigned char *)SvPVbyte(x, x_len);
  y_buf = (unsigned char *)SvPVbyte(y, y_len);

  if (x_len < y_len) {
    Newxz(realloc_buf, y_len + 1, unsigned char);
    if (realloc_buf == NULL)
      croak("Failed to allocate memory");
    memcpy(realloc_buf, x_buf, x_len);
    x_buf = realloc_buf;
    x_len = y_len;
  }
  else if (x_len > y_len) {
    Newxz(realloc_buf, x_len + 1, unsigned char);
    if (realloc_buf == NULL)
      croak("Failed to allocate memory");
    memcpy(realloc_buf, y_buf, y_len);
    y_buf = realloc_buf;
    y_len = x_len;
  }

  RETVAL = newSV(0);
  Newxz(out_buf, x_len + 1, unsigned char);
  if (out_buf == NULL) {
    if (realloc_buf)
      Safefree(realloc_buf);
    croak("Could not allocate memory");
  }
  memcpy(out_buf, x_buf, x_len);

  sodium_sub(out_buf, y_buf, x_len);
  if (realloc_buf)
    free(realloc_buf);

  sv_usepvn_flags(RETVAL, (char *)out_buf, x_len, SV_HAS_TRAILING_NUL);

  OUTPUT:
  RETVAL

void sodium_memzero(...)

  PREINIT:
  unsigned char *arg_buf;
  STRLEN arg_len;
  int i;

  PPCODE:
  if (!items)
    croak("Missing arguments");

  for (i = 0; i < items; i++) {
    arg_buf = (unsigned char *)SvPVbyte_force(ST(i), arg_len);
    sodium_memzero(arg_buf, arg_len);
  }

  XSRETURN_EMPTY;
