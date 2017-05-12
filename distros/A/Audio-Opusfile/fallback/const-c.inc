#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     OP_EIMPL OP_EREAD OP_FALSE */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "OP_EREA", 7)) {
    /*                      D     */
#ifdef OP_EREAD
      *iv_return = OP_EREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "OP_FALS", 7)) {
    /*                      E     */
#ifdef OP_FALSE
      *iv_return = OP_FALSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "OP_EIMP", 7)) {
    /*                      L     */
#ifdef OP_EIMPL
      *iv_return = OP_EIMPL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     OP_EBADHEADER OP_EBADPACKET OP_ENOTFORMAT OP_TRACK_GAIN */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'F':
    if (memEQ(name, "OP_ENOTFORMAT", 13)) {
    /*                      ^            */
#ifdef OP_ENOTFORMAT
      *iv_return = OP_ENOTFORMAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "OP_EBADHEADER", 13)) {
    /*                      ^            */
#ifdef OP_EBADHEADER
      *iv_return = OP_EBADHEADER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "OP_TRACK_GAIN", 13)) {
    /*                      ^            */
#ifdef OP_TRACK_GAIN
      *iv_return = OP_TRACK_GAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "OP_EBADPACKET", 13)) {
    /*                      ^            */
#ifdef OP_EBADPACKET
      *iv_return = OP_EBADPACKET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     OP_PIC_FORMAT_GIF OP_PIC_FORMAT_PNG OP_PIC_FORMAT_URL */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'F':
    if (memEQ(name, "OP_PIC_FORMAT_GI", 16)) {
    /*                               F      */
#ifdef OP_PIC_FORMAT_GIF
      *iv_return = OP_PIC_FORMAT_GIF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "OP_PIC_FORMAT_PN", 16)) {
    /*                               G      */
#ifdef OP_PIC_FORMAT_PNG
      *iv_return = OP_PIC_FORMAT_PNG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "OP_PIC_FORMAT_UR", 16)) {
    /*                               L      */
#ifdef OP_PIC_FORMAT_URL
      *iv_return = OP_PIC_FORMAT_URL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     OP_GET_SERVER_INFO_REQUEST OP_HTTP_PROXY_HOST_REQUEST
     OP_HTTP_PROXY_PASS_REQUEST OP_HTTP_PROXY_PORT_REQUEST
     OP_HTTP_PROXY_USER_REQUEST */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'O':
    if (memEQ(name, "OP_GET_SERVER_INFO_REQUEST", 26)) {
    /*                                ^               */
#ifdef OP_GET_SERVER_INFO_REQUEST
      *iv_return = OP_GET_SERVER_INFO_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "OP_HTTP_PROXY_USER_REQUEST", 26)) {
    /*                                ^               */
#ifdef OP_HTTP_PROXY_USER_REQUEST
      *iv_return = OP_HTTP_PROXY_USER_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "OP_HTTP_PROXY_PASS_REQUEST", 26)) {
    /*                                ^               */
#ifdef OP_HTTP_PROXY_PASS_REQUEST
      *iv_return = OP_HTTP_PROXY_PASS_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "OP_HTTP_PROXY_HOST_REQUEST", 26)) {
    /*                                ^               */
#ifdef OP_HTTP_PROXY_HOST_REQUEST
      *iv_return = OP_HTTP_PROXY_HOST_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "OP_HTTP_PROXY_PORT_REQUEST", 26)) {
    /*                                ^               */
#ifdef OP_HTTP_PROXY_PORT_REQUEST
      *iv_return = OP_HTTP_PROXY_PORT_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(OPUS_CHANNEL_COUNT_MAX OP_ABSOLUTE_GAIN OP_DEC_FORMAT_FLOAT
	       OP_DEC_FORMAT_SHORT OP_DEC_USE_DEFAULT OP_EBADHEADER OP_EBADLINK
	       OP_EBADPACKET OP_EBADTIMESTAMP OP_EFAULT OP_EIMPL OP_EINVAL
	       OP_ENOSEEK OP_ENOTAUDIO OP_ENOTFORMAT OP_EOF OP_EREAD
	       OP_EVERSION OP_FALSE OP_GET_SERVER_INFO_REQUEST OP_HEADER_GAIN
	       OP_HOLE OP_HTTP_PROXY_HOST_REQUEST OP_HTTP_PROXY_PASS_REQUEST
	       OP_HTTP_PROXY_PORT_REQUEST OP_HTTP_PROXY_USER_REQUEST
	       OP_PIC_FORMAT_GIF OP_PIC_FORMAT_JPEG OP_PIC_FORMAT_PNG
	       OP_PIC_FORMAT_UNKNOWN OP_PIC_FORMAT_URL
	       OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST OP_TRACK_GAIN));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Audio::Opusfile", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Audio::Opusfile", $types);
__END__
   */

  switch (len) {
  case 6:
    if (memEQ(name, "OP_EOF", 6)) {
#ifdef OP_EOF
      *iv_return = OP_EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    if (memEQ(name, "OP_HOLE", 7)) {
#ifdef OP_HOLE
      *iv_return = OP_HOLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    /* Names all of length 9.  */
    /* OP_EFAULT OP_EINVAL */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'U':
      if (memEQ(name, "OP_EFAULT", 9)) {
      /*                     ^        */
#ifdef OP_EFAULT
        *iv_return = OP_EFAULT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'V':
      if (memEQ(name, "OP_EINVAL", 9)) {
      /*                     ^        */
#ifdef OP_EINVAL
        *iv_return = OP_EINVAL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 10:
    if (memEQ(name, "OP_ENOSEEK", 10)) {
#ifdef OP_ENOSEEK
      *iv_return = OP_ENOSEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* OP_EBADLINK OP_EVERSION */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'N':
      if (memEQ(name, "OP_EBADLINK", 11)) {
      /*                        ^        */
#ifdef OP_EBADLINK
        *iv_return = OP_EBADLINK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "OP_EVERSION", 11)) {
      /*                        ^        */
#ifdef OP_EVERSION
        *iv_return = OP_EVERSION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "OP_ENOTAUDIO", 12)) {
#ifdef OP_ENOTAUDIO
      *iv_return = OP_ENOTAUDIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    if (memEQ(name, "OP_HEADER_GAIN", 14)) {
#ifdef OP_HEADER_GAIN
      *iv_return = OP_HEADER_GAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* OP_ABSOLUTE_GAIN OP_EBADTIMESTAMP */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'N':
      if (memEQ(name, "OP_ABSOLUTE_GAI", 15)) {
      /*                              N      */
#ifdef OP_ABSOLUTE_GAIN
        *iv_return = OP_ABSOLUTE_GAIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "OP_EBADTIMESTAM", 15)) {
      /*                              P      */
#ifdef OP_EBADTIMESTAMP
        *iv_return = OP_EBADTIMESTAMP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* OP_DEC_USE_DEFAULT OP_PIC_FORMAT_JPEG */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'A':
      if (memEQ(name, "OP_PIC_FORMAT_JPEG", 18)) {
      /*                          ^             */
#ifdef OP_PIC_FORMAT_JPEG
        *iv_return = OP_PIC_FORMAT_JPEG;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'D':
      if (memEQ(name, "OP_DEC_USE_DEFAULT", 18)) {
      /*                          ^             */
#ifdef OP_DEC_USE_DEFAULT
        *iv_return = OP_DEC_USE_DEFAULT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* OP_DEC_FORMAT_FLOAT OP_DEC_FORMAT_SHORT */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'H':
      if (memEQ(name, "OP_DEC_FORMAT_SHORT", 19)) {
      /*                              ^          */
#ifdef OP_DEC_FORMAT_SHORT
        *iv_return = OP_DEC_FORMAT_SHORT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "OP_DEC_FORMAT_FLOAT", 19)) {
      /*                              ^          */
#ifdef OP_DEC_FORMAT_FLOAT
        *iv_return = OP_DEC_FORMAT_FLOAT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    if (memEQ(name, "OP_PIC_FORMAT_UNKNOWN", 21)) {
#ifdef OP_PIC_FORMAT_UNKNOWN
      *iv_return = OP_PIC_FORMAT_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    if (memEQ(name, "OPUS_CHANNEL_COUNT_MAX", 22)) {
#ifdef OPUS_CHANNEL_COUNT_MAX
      *iv_return = OPUS_CHANNEL_COUNT_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 37:
    if (memEQ(name, "OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST", 37)) {
#ifdef OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST
      *iv_return = OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

