MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::MemVault

SV * new(SV * class, SV * bytes, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *new_pm;
  unsigned char *out_buf;
  STRLEN out_len;
  unsigned int new_flags = g_protmem_default_flags_memvault;

  CODE:
  PERL_UNUSED_VAR(class);

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  out_buf = (unsigned char *)SvPVbyte(bytes, out_len);

  new_pm = protmem_init(aTHX_ out_len, new_flags);
  if (new_pm == NULL)
    croak("new: Failed to allocate protmem");
  memcpy(new_pm->pm_ptr, out_buf, out_len);

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("new: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * new_from_hex(SV * class, SV * hex, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *hex_pm = NULL;
  protmem *new_pm;
  char *hex_buf = NULL;
  STRLEN hex_len;
  unsigned int new_flags = g_protmem_default_flags_memvault;

  CODE:
  PERL_UNUSED_VAR(class);

  if (sv_derived_from(hex, MEMVAULT_CLASS)) {
    hex_pm = protmem_get(aTHX_ hex, MEMVAULT_CLASS);
    hex_buf = hex_pm->pm_ptr;
    hex_len = hex_pm->size;
  }
  else
    hex_buf = SvPVbyte(hex, hex_len);

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  new_pm = protmem_init(aTHX_ hex_len / 2, new_flags);
  if (new_pm == NULL)
    croak("new_from_hex: Failed to allocate protmem");

  if (hex_pm) {
    new_pm->flags = hex_pm->flags;
    if (protmem_grant(aTHX_ hex_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ new_pm);
      croak("new_from_hex: Failed to grant hex protmem RO");
    }
  }

  sodium_hex2bin(new_pm->pm_ptr, new_pm->size, hex_buf, hex_len,
                 NULL, &(new_pm->size), NULL);

  if (hex_pm)
    if (protmem_release(aTHX_ hex_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ new_pm);
      croak("new_from_hex: Failed to release hex protmem RO");
    }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("new_from_hex: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * new_from_base64( \
  SV * class,  \
  SV * b64,  \
  int variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *b64_pm = NULL;
  protmem *new_pm;
  char *b64_buf = NULL;
  STRLEN b64_len;
  STRLEN max_len;
  unsigned int new_flags = g_protmem_default_flags_memvault;

  CODE:
  PERL_UNUSED_VAR(class);

  if (sv_derived_from(b64, MEMVAULT_CLASS)) {
    b64_pm = protmem_get(aTHX_ b64, MEMVAULT_CLASS);
    b64_buf = (char *)b64_pm->pm_ptr;
    b64_len = b64_pm->size;
    new_flags = b64_pm->flags;
  }
  else
    b64_buf = SvPVbyte(b64, b64_len);

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  switch (variant) {
    case 0:
      variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING;
      break;
    case sodium_base64_VARIANT_ORIGINAL: /* fallthrough */
    case sodium_base64_VARIANT_ORIGINAL_NO_PADDING: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE_NO_PADDING:
      break;
    default:
      croak("new_from_base64: Invalid base64 variant");
  }

  /* FIXME: this should check for valid b64 */
  max_len = ((b64_len + 3) & ~3) / 4 * 3;
  new_pm = protmem_init(aTHX_ max_len, new_flags);
  if (new_pm == NULL)
    croak("new_from_base64: Failed to allocate protmem");

  if (b64_pm) {
    if (protmem_grant(aTHX_ b64_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ new_pm);
      croak("new_from_base64: Failed to grant b64 protmem RO");
    }
  }

  sodium_base642bin(new_pm->pm_ptr, new_pm->size, b64_buf, b64_len,
                    NULL, &(new_pm->size), NULL, variant);

  if (b64_pm) {
    if (protmem_release(aTHX_ b64_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      protmem_free(aTHX_ new_pm);
      croak("new_from_base64: Failed to release b64 protmem RO");
    }
  }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("new_from_base64: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

=for notes

this is only intended for reading secrets (keys) or data in limited block
sizes.

=cut

SV * new_from_fd(SV * class, SV * file, STRLEN len = 0, SV * flags = &PL_sv_undef)

  ALIAS:
  new_from_file = 1

  PREINIT:
  protmem *new_pm, *resize_pm;
  char *path_buf = NULL;
  ssize_t r = 0;
  size_t b = 0, bufrem, lenrem = SIZE_MAX;
  STRLEN bufsize = MEMVAULT_READ_BUFSIZE;
  unsigned int new_flags = g_protmem_default_flags_memvault;
  int fd;

  CODE:
  PERL_UNUSED_VAR(class);

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  switch(ix) {
    case 1:
      path_buf = SvPVbyte_nolen(file);
      /* really need to be checking path_buf for nul termination, etc */

      fd = open(path_buf, O_RDONLY|O_CLOEXEC|O_NOCTTY);
      if (fd < 0)
        croak("new_from_fd|file: %s: open failed", path_buf);
      break;
    default:
      fd = SvIV(file);
  }

  if (len && len < bufsize)
    bufsize = len;

  new_pm = protmem_init(aTHX_ bufsize, new_flags);
  if (new_pm == NULL) {
    if (ix == 1)
      close(fd);
    croak("new_from_fd|file: Failed to allocate protmem");
  }

  /* r: iteration read bytes */
  /* b: total buffer read bytes */
  /* sub-optimal for perfomance, but "safer" */
  for (;;) {
    if (b == bufsize) {
      bufsize *= 2;
      resize_pm = protmem_clone(aTHX_ new_pm, bufsize);
      protmem_free(aTHX_ new_pm);
      if (resize_pm == NULL) {
        if (ix == 1)
          close(fd);
        croak("new_from_fd|file: Failed to allocate resize protmem");
      }
      new_pm = resize_pm;
    }
    bufrem = bufsize - r;
    if (len)
      lenrem = len - b;
    r = read(fd, new_pm->pm_ptr + b, lenrem < bufrem ? lenrem : bufrem);
    if (r < 0) {
      if (errno == EINTR)
        continue;
      if (ix == 1)
        close(fd);
      protmem_free(aTHX_ new_pm);
      croak("new_from_fd|file: read error %d", errno);
    }
    b += r;
    new_pm->size = b;
    if (r == 0)
      break;
    if (len && b == len)
      break;
  }

  if (ix == 1)
    if (close(fd) < 0) {
      protmem_free(aTHX_ new_pm);
      croak("new_from_fd|file: %s: close error %d", path_buf, errno);
    }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    if (ix == 1)
      close(fd);
    protmem_free(aTHX_ new_pm);
    croak("new_from_fd|file: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * new_from_ttyno( \
  SV * class, \
  SV * ttyno = &PL_sv_undef, \
  SV * prompt = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *new_pm;
  char *prompt_buf;
  char *vbuf;
  int fd;
  unsigned int new_flags = g_protmem_default_flags_key;
  STRLEN prompt_len;
  struct termios tattr;
  FILE *file;

  CODE:
  PERL_UNUSED_VAR(class);

  SvGETMAGIC(ttyno);
  if (SvOK(ttyno))
    fd = SvIV_nomg(ttyno);
  else
    fd = 0;

  SvGETMAGIC(prompt);
  if (SvOK(prompt))
    /* prompt_len unused */
    prompt_buf = SvPVbyte_nomg(prompt, prompt_len);
  else
    prompt_buf = "Password: ";

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV(flags);

  new_pm = protmem_init(aTHX_ 1024, new_flags);
  if (new_pm == NULL)
    croak("new_from_ttyno: Failed to allocate protmem");

  vbuf = sodium_malloc(1024);
  if (vbuf == NULL)
    croak("new_from_ttyno: Failed to allocate vbuf memory");

  if (fprintf(stderr, "%s", prompt_buf) == EOF) {
    protmem_free(aTHX_ new_pm);
    croak("new_from_ttyno: Failed to prompt");
  }
  if (fflush(stderr) == EOF) {
    fprintf(stderr, "\n");
    croak("new_from_ttyno: Failed fflush (stderr)");
  }

  if (!isatty(fd) || tcgetattr(fd, &tattr) != 0) {
    fprintf(stderr, "\n");
    croak("new_from_ttyno: Failed tcgetattr (not a tty?)");
  }
  tattr.c_lflag &= ~ECHO;
  if (tcsetattr(fd, TCSAFLUSH, &tattr) != 0) {
    fprintf(stderr, "\n");
    croak("new_from_ttyno: Failed tcsetattr");
  }

  if ((file = fdopen(fd, "r")) == NULL) {
    fprintf(stderr, "\n");
    tattr.c_lflag |= ECHO;
    tcsetattr(fd, TCSAFLUSH, &tattr);
    croak("new_from_ttyno: Failed fdopen");
  }

  if (setvbuf(file, vbuf, _IOLBF, 1024) != 0) {
    fprintf(stderr, "\n");
    tattr.c_lflag |= ECHO;
    tcsetattr(fd, TCSAFLUSH, &tattr);
    croak("new_from_ttyno: Failed to setvbuf");
  }

  if (fgets((char *)new_pm->pm_ptr, 1024, file) == NULL)
    RETVAL = &PL_sv_undef;
  else {
    char *input_buf = (char *)new_pm->pm_ptr;
    char *nl_pos;

    if ((nl_pos = strchr(input_buf, '\r')) != NULL)
      *nl_pos = '\0';
    if ((nl_pos = strchr(input_buf, '\n')) != NULL)
      *nl_pos = '\0';
    new_pm->size = strlen(input_buf);


    if (new_pm->size == 0)
      fprintf(stderr, "(WARNING: empty)\n");
    else if (new_pm->size == 1023) {
      /* warns even if input was exactly 1023. meh. */
      fprintf(stderr, "(WARNING: truncated to 1023 characters)\n");
      fflush(file);
    }

    RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);
  }

  setvbuf(file, NULL, _IOLBF, 0);
  sodium_free(vbuf);

  fprintf(stderr, "\n");
  fflush(stderr);
  if (tcgetattr(fd, &tattr) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("new_from_ttyno: tcgetattr failed");
  }
  tattr.c_lflag |= ECHO;
  if (tcsetattr(fd, TCSAFLUSH, &tattr) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("new_from_ttyno: tcsetattr failed (stdin)");
  }

  OUTPUT:
  RETVAL

void DESTROY(SV * self)

  PREINIT:
  protmem *self_pm;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  protmem_free(aTHX_ self_pm);

void _overload_bool(SV * self, ...)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  if (self_pm->size)
    XSRETURN_YES;
  else
    XSRETURN_NO;

SV * _overload_mult(SV * self, SV * other, SV * swapped)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  unsigned int count = 0;
  unsigned int cur = 0;

  CODE:
  PERL_UNUSED_VAR(swapped);

  count = SvUV(other);

  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  new_pm = protmem_init(aTHX_ self_pm->size * count, self_pm->flags);
  if (new_pm == NULL)
    croak("_overload_mult: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("_overload_mult: Failed to grant self protmem RO");

  while(count--)
    memcpy(new_pm->pm_ptr + self_pm->size * cur++, self_pm->pm_ptr, self_pm->size);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("_overload_mult: Failed to release self protmem RO");
  }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("_overload_mult: Failed to release new protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

void _overload_nomethod(SV * self, ...)

  PREINIT:
  char *operator;

  PPCODE:
  PERL_UNUSED_VAR(self);
  operator = SvPVbyte_nolen(ST(3));
  croak("Operation \"%s\" on MemVault is not supported", operator);

void bitwise_and(SV * self, SV * other, ...)

  ALIAS:
  bitwise_or = 1
  bitwise_xor = 2
  bitwise_and_equals = 100
  bitwise_or_equals = 101
  bitwise_xor_equals = 102

  PREINIT:
  protmem *self_pm;
  protmem *other_pm = NULL;
  protmem *new_pm = NULL;
  unsigned char *buf;
  unsigned char *other_buf;
  STRLEN other_len;
  STRLEN i;
  unsigned int new_flags;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  if (sv_derived_from(other, MEMVAULT_CLASS)) {
    other_pm = protmem_get(aTHX_ other, MEMVAULT_CLASS);
    other_buf = other_pm->pm_ptr;
    other_len = other_pm->size;
  }
  else
    other_buf = (unsigned char *)SvPVbyte(other, other_len);
    /* should probably zero afterwards */
  if (other_len != self_pm->size)
    /* lengths MUST be identical below */
    croak("Exclusive-or operands do not have equal length");

  if (ix >= 100) {
    if (other_pm)
      if (protmem_grant(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
        protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("xor: Failed to grant other protmem RO");
      }
    if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("xor: Failed to grant self protmem RW");
    }
    buf = self_pm->pm_ptr;
    /* lengths identical, assured above */
    for (i = 0; i < other_len; i++)
      switch(ix) {
        case 101:
          buf[i] |= other_buf[i];
          break;
        case 102:
          buf[i] ^= other_buf[i];
          break;
        default: /* 100 */
          buf[i] &= other_buf[i];
      }
    if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("xor: Failed to release self protmem RW");
    }
  }
  else {
    new_flags = self_pm->flags;
    if (other_pm)
      new_flags &= other_pm->flags;
    new_pm = protmem_init(aTHX_ self_pm->size, new_flags);
    if (new_pm == NULL)
      croak("xor: Failed to allocate protmem");

    if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
      croak("xor: Failed to grant self protmem RO");

    if (other_pm)
      if (protmem_grant(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
        protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
        croak("xor: Failed to grant other protmem RO");
      }

    buf = memcpy(new_pm->pm_ptr, self_pm->pm_ptr, self_pm->size);
    for (i = 0; i < other_len; i++)
      switch(ix) {
        case 1:
          buf[i] |= other_buf[i];
          break;
        case 2:
          buf[i] ^= other_buf[i];
          break;
        default:
          buf[i] &= other_buf[i];
      }

    if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("xor: Failed to release new protmem RW");
    }
    if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("xor: Failed to release self protmem RW");
    }

    mXPUSHs(protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS));
  }

  if (other_pm)
    if (protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
      croak("xor: Failed to release other protmem RO");

  XSRETURN(1);

SV * clone(SV * self)

  CODE:
  RETVAL = protmem_clone_sv(aTHX_ self, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

void compare(SV * self, SV * other, STRLEN size = 0)

  ALIAS:
  _overload_eq = 1
  _overload_ne = 2
  memcmp = 3

  PREINIT:
  protmem *self_pm = NULL, *other_pm = NULL;
  unsigned char *self_buf, *other_buf;
  STRLEN self_size, other_size;
  int ret = 0;

  PPCODE:
  /* since used for overloads, args could be swapped. could require either self
   * or other to be a memvault */
  if (sv_derived_from(self, MEMVAULT_CLASS)) {
    self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
    if (ix == 0 && !(self_pm->flags & PROTMEM_FLAG_LOCK_UNLOCKED))
      croak("compare: Unlock MemVault object before comparison");
    self_buf = self_pm->pm_ptr;
    self_size = self_pm->size;
  }
  else
    self_buf = (unsigned char *)SvPVbyte(self, self_size);

  if (sv_derived_from(other, MEMVAULT_CLASS)) {
    other_pm = protmem_get(aTHX_ other, MEMVAULT_CLASS);
    if (ix == 0 && !(other_pm->flags & PROTMEM_FLAG_LOCK_UNLOCKED))
      croak("compare: Unlock MemVault object before comparison");
    other_buf = other_pm->pm_ptr;
    other_size = other_pm->size;
  }
  else
    other_buf = (unsigned char *)SvPVbyte(other, other_size);

  if (self_size != other_size) {
    switch(ix) {
      case 1: /* fallthrough */
      case 2:
        croak("compare: %s %s",
              "Variables of unequal size cannot be automatically compared.",
              "Please use memcmp() with the size argument provided.");
        break;
      default:
        if (size == 0) {
          croak("compare: %s %s",
                "Variables of unequal size cannot be automatically compared.",
                "Please provide the size argument.");
        }
        else {
          if (size > self_size)
            croak("compare: The argument (left) is shorter then requested size");
          else if (size > other_size)
            croak("compare: The argument (right) is shorter then requested size");
        }
    }
  }

  if (self_pm)
    if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
      croak("compare: Failed to grant self protmem RO");

  if (other_pm) {
    if (protmem_grant(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      if (self_pm)
        protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("compare: Failed to grant other protmem RO");
    }
  }

  if (ix != 0)
    ret = sodium_memcmp(self_buf, other_buf, self_size);
  else
    ret = sodium_compare(self_buf, other_buf, self_size);

  if (other_pm && protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    if (self_pm)
      protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("compare: Failed to release other protmem RO");
  }
  if (self_pm && protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("compare: Failed to release self protmem RO");

  if (ix == 0) {
    XSRETURN_IV(ret);
  }
  else if (ix == 2) {
    if (ret == 0)
      XSRETURN_NO;
    XSRETURN_YES;
  }
  else {
    if (ret == 0)
      XSRETURN_YES;
    XSRETURN_NO;
  }

=for TODO

consider a flags argument. that cannot co-exist with overloading as it is now.

=cut

void concat(SV * self, SV * other, SV * swapped = &PL_sv_undef)

  ALIAS:
  concat_inplace = 1

  PREINIT:
  protmem *self_pm;
  protmem *other_pm = NULL;
  protmem *new_pm;
  unsigned char *buf;
  MAGIC *mg, *mg_found=NULL;
  STRLEN buf_len;
  unsigned int new_flags;

  PPCODE:
  if (sv_derived_from(other, MEMVAULT_CLASS)) {
    other_pm = protmem_get(aTHX_ other, MEMVAULT_CLASS);
    buf = other_pm->pm_ptr;
    buf_len = other_pm->size;
  }
  else
    buf = (unsigned char *)SvPVbyte(other, buf_len);
    /* should probably zero buf afterwards */

  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  new_flags = self_pm->flags;
  if (other_pm)
    new_flags &= other_pm->flags;
  new_pm = protmem_init(aTHX_ self_pm->size + buf_len, new_flags);
  if (new_pm == NULL)
    croak("concat: Failed to allocate protmem");

  if (other_pm && protmem_grant(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("concat: Failed to grant other protmem RO");
  }

  if (ix == 0) {
    if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to grant self protmem RO");
    }

    if (SvTRUE(swapped))
      memcpy(memcpy(new_pm->pm_ptr, buf, buf_len) + buf_len,
             self_pm->pm_ptr, self_pm->size);
    else
      memcpy(memcpy(new_pm->pm_ptr, self_pm->pm_ptr, self_pm->size)
             + self_pm->size, buf, buf_len);

    if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to release self protmem RO");
    }

    if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to release new protmem RW");
    }

    mXPUSHs(protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS));
  }
  else {
    if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("concat: Failed to grant self protmem RW");
    }

    memcpy((unsigned char *)memcpy(new_pm->pm_ptr, self_pm->pm_ptr, self_pm->size)
           + self_pm->size, buf, buf_len);

    if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW != 0)) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to release self protmem RW");
    }

    if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to release new protmem RW");
    }

    for (mg = SvMAGIC(SvRV(self)); mg; mg = mg->mg_moremagic)
      if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &vtbl_protmem) {
        mg_found = mg;
        break;
      }

    if (mg_found != NULL) {
      protmem_free(aTHX_ (protmem *)mg_found->mg_ptr);
      mg_found->mg_ptr = (char *)new_pm;
      new_pm = NULL;
    }
    else {
      if (other_pm)
        protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO);
      protmem_free(aTHX_ new_pm);
      croak("concat: Failed to find protmem magic");
    }
  }

  if (other_pm && protmem_release(aTHX_ other_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("concat: Failed to release other protmem RO");
  }

  XSRETURN(1);

=for notes

FIXME: if self is longer than LONG_MAX or abs(LONG_MIN) this is broke.

=cut

SV * extract( \
  SV * self, \
  long offset = 0, \
  SV * length = &PL_sv_undef, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  unsigned int new_flags;
  STRLEN self_len;
  long new_len;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  self_len = self_pm->size;

  if (offset && (offset > (long)self_len - 1
                || offset < -(long)self_len))
    croak("extract: Invalid offset %ld", offset);
  if (offset < 0)
    offset = self_len + offset;

  SvGETMAGIC(length);
  if (SvOK(length)) {
    new_len = SvIV_nomg(length);
    if (new_len > (long)(self_len - offset))
      new_len = self_len - offset;
    else if (new_len < -(long)(self_len - offset))
      new_len = 0;
    else if (new_len < 0)
      new_len = self_len - offset + new_len;
  }
  else
    new_len = self_len - offset;

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvIV_nomg(flags);
  else
    new_flags = self_pm->flags;

  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("extract: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("extract: Failed to grant self protmem RO");
  }

  memcpy(new_pm->pm_ptr, (unsigned char *)self_pm->pm_ptr + offset, new_len);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("extract: Failed to release self protmem RO");
  }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("extract: Failed to release new protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

unsigned int flags(SV * self, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *self_pm;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  SvGETMAGIC(flags);
  if (SvOK(flags)) {
    unsigned int new_flags;
    unsigned int old_flags;
    new_flags = SvUV_nomg(flags);
    old_flags = self_pm->flags;
    /* may want to allow changing malloc? likely not useful. */
    if ((old_flags & PROTMEM_FLAG_MALLOC_MASK)
        != (new_flags & PROTMEM_FLAG_MALLOC_MASK))
      croak("flags: cannot change malloc method on an existing MemVault");
    if (self_pm->flags != new_flags) {
      self_pm->flags = new_flags;
      if (protmem_release(aTHX_ self_pm, old_flags) != 0)
        croak("flags: Failed to release self protmem from old flags");;
    }
  }

  RETVAL = self_pm->flags;

  OUTPUT:
  RETVAL

SV * from_base64( \
  SV * self, \
  int variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  char *self_buf = NULL;
  STRLEN self_len;
  STRLEN max_len;
  unsigned int new_flags = g_protmem_default_flags_memvault;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  self_buf = (char *)self_pm->pm_ptr;
  self_len = self_pm->size;
  new_flags = self_pm->flags;

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  switch (variant) {
    case 0:
      variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING;
      break;
    case sodium_base64_VARIANT_ORIGINAL: /* fallthrough */
    case sodium_base64_VARIANT_ORIGINAL_NO_PADDING: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE: /* fallthrough */
    case sodium_base64_VARIANT_URLSAFE_NO_PADDING:
      break;
    default:
      croak("from_base64: Invalid base64 variant");
  }

  /* FIXME: this should check for valid base64 */
  max_len = ((self_len + 3) & ~3) / 4 * 3;
  new_pm = protmem_init(aTHX_ max_len, new_flags);
  if (new_pm == NULL)
    croak("from_base64: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_base64: Failed to grant self protmem RO");
  }

  sodium_base642bin(new_pm->pm_ptr, new_pm->size, self_buf, self_len,
                    NULL, &(new_pm->size), NULL, variant);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_base64: Failed to release self protmem RO");
  }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_base64: Failed to release new protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * from_hex(SV * self, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  char *self_buf = NULL;
  STRLEN self_len;
  unsigned int new_flags = g_protmem_default_flags_memvault;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  self_buf = (char *)self_pm->pm_ptr;
  self_len = self_pm->size;
  new_flags = self_pm->flags;

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);

  new_pm = protmem_init(aTHX_ self_len / 2, new_flags);
  if (new_pm == NULL)
    croak("from_hex: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_hex: Failed to grant self protmem RO");
  }

  sodium_hex2bin(new_pm->pm_ptr, new_pm->size, self_buf, self_len,
                NULL, NULL, NULL);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_hex: Failed to release self protmem RO");
  }

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("from_hex: Failed to release new protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

void increment(SV * self)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("increment: Failed to grant self protmem RW");

  sodium_increment(self_pm->pm_ptr, self_pm->size);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) != 0)
    croak("increment: Failed to release self protmem RW");

  XSRETURN(1);

SV * index(SV * self, SV * str, STRLEN offset = 0)

  PREINIT:
  protmem *self_pm;
  char *str_buf;
  unsigned char *self_start, *self_p, *self_stop;
  STRLEN str_len;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  if (!(self_pm->flags & PROTMEM_FLAG_LOCK_UNLOCKED))
    croak("index: Unlock MemVault object before using index");

  if (offset > self_pm->size - 1)
    XSRETURN_IV(-1);
  str_buf = SvPVbyte(str, str_len);
  if (str_len < 1)
    XSRETURN_IV(0);
  self_start = (unsigned char *)self_pm->pm_ptr;
  self_p = self_start + offset;
  self_stop = self_start + self_pm->size - str_len; /* + 1 - 1 */
  if (self_p >= self_stop)
    XSRETURN_IV(-1);

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("index: Failed to grant self protmem RO");

  RETVAL = &PL_sv_undef;

  /* naive implementation, good nuff for "unsafe" */
  while (self_p <= self_stop) {
    if (*self_p == str_buf[0]) {
      if (str_len == 1) {
        RETVAL=newSVuv(self_p - self_start);
        break;
      }
      else {
        if (memcmp(self_p, str_buf, str_len) == 0) {
          RETVAL = newSVuv(self_p - self_start);
          break;
        }
      }
    }
    ++self_p;
  }

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("index: Failed to release self protmem RO");

  OUTPUT:
  RETVAL

void is_locked(SV * self)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  if (self_pm->flags & PROTMEM_FLAG_LOCK_UNLOCKED)
    XSRETURN_NO;

  XSRETURN_YES;

void is_zero(SV * self)

  PREINIT:
  protmem *self_pm;
  int ret;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("is_zero: Failed to grant self protmem RO");

  ret = sodium_is_zero(self_pm->pm_ptr, self_pm->size);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("is_zero: Failed to release self protmem RO");

  if (ret)
    XSRETURN_YES;

  XSRETURN_NO;

SV * length(SV * self)

  ALIAS:
  size = 1

  PREINIT:
  protmem *self_pm;

  CODE:
  PERL_UNUSED_VAR(ix);
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  RETVAL = newSVuv((UV)self_pm->size);

  OUTPUT:
  RETVAL

void lock(SV * self)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  self_pm->flags &= ~PROTMEM_FLAG_LOCK_UNLOCKED;
  XSRETURN(1);

SV * pad(SV * self, STRLEN blocksize)

  PREINIT:
  protmem *self_pm, *realloc_pm;
  STRLEN buf_len, pad_len, padded_len;

  CODE:
  if (blocksize <= 0)
    croak("pad: Invalid blocksize <= 0");

  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  buf_len = self_pm->size;

  pad_len = blocksize - 1;
  if ((blocksize & (blocksize - 1)) == 0)
    pad_len -= buf_len & (blocksize - 1);
  else
    pad_len -= buf_len % blocksize;
  pad_len += 1; /* for 0x80 */

  if ((STRLEN)SIZE_MAX - buf_len <= pad_len)
    croak("pad: Pad exceeds SIZE_MAX");
  padded_len = buf_len + pad_len;

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("pad: Failed to grant self protmem RO");

  realloc_pm = protmem_clone(aTHX_ self_pm, padded_len);
  if (realloc_pm == NULL) {
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("pad: Failed to allocate protmem");
  }

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ realloc_pm);
    croak("pad: Failed to release self protmem RO");
  }

  if (sodium_pad(&padded_len, realloc_pm->pm_ptr,
                 buf_len, blocksize, padded_len) != 0) {
    /* should be impossible */
    protmem_free(aTHX_ realloc_pm);
    croak("BUG: pad: sodium_pad returned error");
  }

  if (protmem_release(aTHX_ realloc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ realloc_pm);
    croak("pad: Failed to release protmem RW");
  }

  RETVAL = protmem_to_sv(aTHX_ realloc_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * to_base64( \
  SV * self, \
  int variant = sodium_base64_VARIANT_URLSAFE_NO_PADDING, \
  SV * flags = &PL_sv_undef \
)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  STRLEN new_len;
  unsigned int new_flags;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  new_flags = self_pm->flags;

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);
  new_len = sodium_base64_encoded_len(self_pm->size, variant);
  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("to_base64: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("to_base64: Failed to grant self protmem RO");
  }

  sodium_bin2base64((char *)new_pm->pm_ptr, new_pm->size,
                    self_pm->pm_ptr, self_pm->size, variant);
  /* ditch the appended nul */
  new_pm->size = new_len - 1;

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    protmem_free(aTHX_ new_pm);
    croak("to_base64: Failed to release new protmem RW");
  }

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("to_base64: Failed to release self protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * to_bytes(SV * self, ...)

  PREINIT:
  protmem *self_pm;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);

  if (!(self_pm->flags & PROTMEM_FLAG_LOCK_UNLOCKED))
    croak("_overload_str: Unlock MemVault object before stringifying");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("_overload_str: Failed to grant protmem RO");

  RETVAL = newSVpvn((char *)self_pm->pm_ptr, self_pm->size);

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("_overload_str: Failed to release protmem RO");

  OUTPUT:
  RETVAL

SV * to_hex(SV * self, SV * flags = &PL_sv_undef)

  PREINIT:
  protmem *self_pm;
  protmem *new_pm;
  STRLEN new_len;
  unsigned int new_flags;

  CODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  new_flags = self_pm->flags;

  SvGETMAGIC(flags);
  if (SvOK(flags))
    new_flags = SvUV_nomg(flags);
  new_len = self_pm->size * 2 + 1;
  new_pm = protmem_init(aTHX_ new_len, new_flags);
  if (new_pm == NULL)
    croak("to_hex: Failed to allocate protmem");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("to_hex: Failed to grant self protmem RO");
  }

  sodium_bin2hex(new_pm->pm_ptr, new_len, self_pm->pm_ptr, self_pm->size);
  /* ditch the appended nul */
  new_pm->size = new_len - 1;

  if (protmem_release(aTHX_ new_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    protmem_free(aTHX_ new_pm);
    croak("to_hex: Failed to release new protmem RW");
  }

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ new_pm);
    croak("to_hex: Failed to release self protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ new_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

SV * to_fd(SV * self, SV * file, int mode = 0600)

  ALIAS:
  to_file = 1

  PREINIT:
  protmem *self_pm;
  struct stat stat_buf;
  char *path_buf = NULL;
  ssize_t w;
  size_t t = 0;
  size_t r = 0;
  int fd;

  CODE:
  switch (ix) {
    case 1:
      path_buf = SvPVbyte_nolen(file);
      /* really need to be checking path_buf for nul termination, etc */

      fd = open(path_buf, O_WRONLY|O_CLOEXEC|O_NOCTTY|O_CREAT|O_TRUNC, mode);
      if (fd < 0)
        croak("to_fd: %s: open failed", path_buf);
      if (fstat(fd, &stat_buf) < 0) {
        close(fd);
        croak("to_fd: %s: fstat failed", path_buf);
      }
      if (((stat_buf.st_mode & ~S_IFMT) | mode) ^ mode) {
        /* only caring if file has extra (most likely less-restrictive) modes.
         * it would be invalid to assume that it's safe to fchmod here, as anything
         * else could already have gotten a handle opened. */
        croak("to_fd: %s: invalid modes on already-existing file", path_buf);
      }
      break;
    default:
      fd = SvIV(file);
  }

  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) < 0) {
    if (ix == 1)
      close(fd);
    croak("to_fd: Failed to grant self protmem RO");
  }

  /* w: current iteration written bytes */
  /* t: total bytes written */
  /* r: remaining bytes to write */
  r = self_pm->size;
  for (;;) {
    w = write(fd, self_pm->pm_ptr + t,
              r > MEMVAULT_WRITE_BUFSIZE ? MEMVAULT_WRITE_BUFSIZE : r);
    if (w < 0) {
      if (errno == EINTR)
        continue;
      if (ix == 1)
        close(fd);
      protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
      if (ix == 1)
        croak("to_fd: %s: write error", path_buf);
      croak("to_fd: (%d): write error", fd);
    }
    t += w;
    r -= w;
    if (r == 0)
      break;
  }

  if (ix == 1)
    if (close(fd) < 0) {
      protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
      croak("to_fd: %s: close error", path_buf);
    }

  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) < 0)
    croak("to_fd: Failed to release self protmem RO");

  RETVAL = newSVuv(t);

  OUTPUT:
  RETVAL

void unlock(SV * self)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  self_pm->flags |= PROTMEM_FLAG_LOCK_UNLOCKED;
  XSRETURN(1);

SV * unpad(SV * self, STRLEN blocksize)

  PREINIT:
  protmem *self_pm, *realloc_pm;
  STRLEN buf_len, unpadded_len;

  CODE:
  if (blocksize <= 0)
    croak("unpad: Invalid blocksize <= 0");

  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  buf_len = self_pm->size;
  if (buf_len < blocksize)
    croak("unpad: Buffer is shorter than blocksize");

  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0)
    croak("unpad: Failed to grant self protmem RO");

  if (sodium_unpad(&unpadded_len, self_pm->pm_ptr, self_pm->size, blocksize) != 0) {
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("unpad: Invalid padded buffer");
  }

  realloc_pm = protmem_clone(aTHX_ self_pm, unpadded_len);
  if (realloc_pm == NULL) {
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sodium_pad: Failed to allocate protmem");
  }

  if (protmem_release(aTHX_ realloc_pm, PROTMEM_FLAG_MPROTECT_RW) != 0) {
    protmem_free(aTHX_ realloc_pm);
    protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO);
    croak("sodium_pad: Failed to release protmem RW");
  }
  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RO) != 0) {
    protmem_free(aTHX_ realloc_pm);
    croak("sodium_pad: Failed to release self protmem RO");
  }

  RETVAL = protmem_to_sv(aTHX_ realloc_pm, MEMVAULT_CLASS);

  OUTPUT:
  RETVAL

void memzero(SV * self)

  PREINIT:
  protmem *self_pm;

  PPCODE:
  self_pm = protmem_get(aTHX_ self, MEMVAULT_CLASS);
  if (protmem_grant(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) < 0)
    croak("memzero: Failed to grant self protmem RW");
  sodium_memzero(self_pm->pm_ptr, self_pm->size);
  if (protmem_release(aTHX_ self_pm, PROTMEM_FLAG_MPROTECT_RW) < 0)
    croak("memzero: Failed to release self protmem RW");

=for FIXME

  separate methods for xor (modify in place) from the overload (new
  memvault). currently no explicit method for returning new memvault, only the
  overload.

=cut
