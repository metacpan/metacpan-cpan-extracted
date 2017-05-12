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
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SSL_ALERT_LEVEL_FATAL SSL_FLAGS_CLIENT_AUTH SSL_MAX_PLAINTEXT_LEN */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'P':
    if (memEQ(name, "SSL_MAX_PLAINTEXT_LEN", 21)) {
    /*                       ^                   */
#ifdef SSL_MAX_PLAINTEXT_LEN
      *iv_return = SSL_MAX_PLAINTEXT_LEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SSL_FLAGS_CLIENT_AUTH", 21)) {
    /*                       ^                   */
#ifdef SSL_FLAGS_CLIENT_AUTH
      *iv_return = SSL_FLAGS_CLIENT_AUTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SSL_ALERT_LEVEL_FATAL", 21)) {
    /*                       ^                   */
#ifdef SSL_ALERT_LEVEL_FATAL
      *iv_return = SSL_ALERT_LEVEL_FATAL;
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
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SSL_ALERT_BAD_CERTIFICATE SSL_ALLOW_ANON_CONNECTION
     SSL_OPTION_DELETE_SESSION */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'O':
    if (memEQ(name, "SSL_OPTION_DELETE_SESSION", 25)) {
    /*                       ^                       */
#ifdef SSL_OPTION_DELETE_SESSION
      *iv_return = SSL_OPTION_DELETE_SESSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SSL_ALERT_BAD_CERTIFICATE", 25)) {
    /*                       ^                       */
#ifdef SSL_ALERT_BAD_CERTIFICATE
      *iv_return = SSL_ALERT_BAD_CERTIFICATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "SSL_ALLOW_ANON_CONNECTION", 25)) {
    /*                       ^                       */
#ifdef SSL_ALLOW_ANON_CONNECTION
      *iv_return = SSL_ALLOW_ANON_CONNECTION;
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
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SSL_ALERT_CERTIFICATE_EXPIRED SSL_ALERT_CERTIFICATE_REVOKED
     SSL_ALERT_CERTIFICATE_UNKNOWN */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'I':
    if (memEQ(name, "SSL_ALERT_CERTIFICATE_EXPIRED", 29)) {
    /*                                        ^          */
#ifdef SSL_ALERT_CERTIFICATE_EXPIRED
      *iv_return = SSL_ALERT_CERTIFICATE_EXPIRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SSL_ALERT_CERTIFICATE_UNKNOWN", 29)) {
    /*                                        ^          */
#ifdef SSL_ALERT_CERTIFICATE_UNKNOWN
      *iv_return = SSL_ALERT_CERTIFICATE_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SSL_ALERT_CERTIFICATE_REVOKED", 29)) {
    /*                                        ^          */
#ifdef SSL_ALERT_CERTIFICATE_REVOKED
      *iv_return = SSL_ALERT_CERTIFICATE_REVOKED;
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
my @names = (qw(SSL_ALERT SSL_ALERT_BAD_CERTIFICATE SSL_ALERT_BAD_RECORD_MAC
	       SSL_ALERT_CERTIFICATE_EXPIRED SSL_ALERT_CERTIFICATE_REVOKED
	       SSL_ALERT_CERTIFICATE_UNKNOWN SSL_ALERT_CLOSE_NOTIFY
	       SSL_ALERT_DECOMPRESSION_FAILURE SSL_ALERT_HANDSHAKE_FAILURE
	       SSL_ALERT_ILLEGAL_PARAMETER SSL_ALERT_LEVEL_FATAL
	       SSL_ALERT_LEVEL_WARNING SSL_ALERT_NO_CERTIFICATE
	       SSL_ALERT_UNEXPECTED_MESSAGE SSL_ALERT_UNSUPPORTED_CERTIFICATE
	       SSL_ALLOW_ANON_CONNECTION SSL_ERROR SSL_FILE_NOT_FOUND
	       SSL_FLAGS_CLIENT_AUTH SSL_FLAGS_SERVER SSL_FULL
	       SSL_MAX_PLAINTEXT_LEN SSL_MEM_ERROR SSL_OPTION_DELETE_SESSION
	       SSL_PARTIAL SSL_PROCESS_DATA SSL_SEND_RESPONSE SSL_SUCCESS));

print constant_types(); # macro defs
foreach (C_constant ("Crypt::MatrixSSL", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Crypt::MatrixSSL", $types);
__END__
   */

  switch (len) {
  case 8:
    if (memEQ(name, "SSL_FULL", 8)) {
#ifdef SSL_FULL
      *iv_return = SSL_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    /* Names all of length 9.  */
    /* SSL_ALERT SSL_ERROR */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'R':
      if (memEQ(name, "SSL_ERRO", 8)) {
      /*                       R     */
#ifdef SSL_ERROR
        *iv_return = SSL_ERROR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "SSL_ALER", 8)) {
      /*                       T     */
#ifdef SSL_ALERT
        *iv_return = SSL_ALERT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* SSL_PARTIAL SSL_SUCCESS */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'P':
      if (memEQ(name, "SSL_PARTIAL", 11)) {
      /*                   ^             */
#ifdef SSL_PARTIAL
        *iv_return = SSL_PARTIAL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SSL_SUCCESS", 11)) {
      /*                   ^             */
#ifdef SSL_SUCCESS
        *iv_return = SSL_SUCCESS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 13:
    if (memEQ(name, "SSL_MEM_ERROR", 13)) {
#ifdef SSL_MEM_ERROR
      *iv_return = SSL_MEM_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* SSL_FLAGS_SERVER SSL_PROCESS_DATA */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'C':
      if (memEQ(name, "SSL_PROCESS_DATA", 16)) {
      /*                      ^               */
#ifdef SSL_PROCESS_DATA
        *iv_return = SSL_PROCESS_DATA;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'G':
      if (memEQ(name, "SSL_FLAGS_SERVER", 16)) {
      /*                      ^               */
#ifdef SSL_FLAGS_SERVER
        *iv_return = SSL_FLAGS_SERVER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    if (memEQ(name, "SSL_SEND_RESPONSE", 17)) {
#ifdef SSL_SEND_RESPONSE
      *iv_return = SSL_SEND_RESPONSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "SSL_FILE_NOT_FOUND", 18)) {
#ifdef SSL_FILE_NOT_FOUND
      *iv_return = SSL_FILE_NOT_FOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    if (memEQ(name, "SSL_ALERT_CLOSE_NOTIFY", 22)) {
#ifdef SSL_ALERT_CLOSE_NOTIFY
      *iv_return = SSL_ALERT_CLOSE_NOTIFY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    if (memEQ(name, "SSL_ALERT_LEVEL_WARNING", 23)) {
#ifdef SSL_ALERT_LEVEL_WARNING
      *iv_return = SSL_ALERT_LEVEL_WARNING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    /* Names all of length 24.  */
    /* SSL_ALERT_BAD_RECORD_MAC SSL_ALERT_NO_CERTIFICATE */
    /* Offset 23 gives the best switch position.  */
    switch (name[23]) {
    case 'C':
      if (memEQ(name, "SSL_ALERT_BAD_RECORD_MA", 23)) {
      /*                                      C      */
#ifdef SSL_ALERT_BAD_RECORD_MAC
        *iv_return = SSL_ALERT_BAD_RECORD_MAC;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "SSL_ALERT_NO_CERTIFICAT", 23)) {
      /*                                      E      */
#ifdef SSL_ALERT_NO_CERTIFICATE
        *iv_return = SSL_ALERT_NO_CERTIFICATE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 27:
    /* Names all of length 27.  */
    /* SSL_ALERT_HANDSHAKE_FAILURE SSL_ALERT_ILLEGAL_PARAMETER */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'H':
      if (memEQ(name, "SSL_ALERT_HANDSHAKE_FAILURE", 27)) {
      /*                         ^                       */
#ifdef SSL_ALERT_HANDSHAKE_FAILURE
        *iv_return = SSL_ALERT_HANDSHAKE_FAILURE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "SSL_ALERT_ILLEGAL_PARAMETER", 27)) {
      /*                         ^                       */
#ifdef SSL_ALERT_ILLEGAL_PARAMETER
        *iv_return = SSL_ALERT_ILLEGAL_PARAMETER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 28:
    if (memEQ(name, "SSL_ALERT_UNEXPECTED_MESSAGE", 28)) {
#ifdef SSL_ALERT_UNEXPECTED_MESSAGE
      *iv_return = SSL_ALERT_UNEXPECTED_MESSAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 31:
    if (memEQ(name, "SSL_ALERT_DECOMPRESSION_FAILURE", 31)) {
#ifdef SSL_ALERT_DECOMPRESSION_FAILURE
      *iv_return = SSL_ALERT_DECOMPRESSION_FAILURE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 33:
    if (memEQ(name, "SSL_ALERT_UNSUPPORTED_CERTIFICATE", 33)) {
#ifdef SSL_ALERT_UNSUPPORTED_CERTIFICATE
      *iv_return = SSL_ALERT_UNSUPPORTED_CERTIFICATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

