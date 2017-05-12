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
my @names = (qw(ECDSA_F_ECDSA_CHECK ECDSA_F_ECDSA_DATA_NEW_METHOD
	       ECDSA_F_ECDSA_DO_SIGN ECDSA_F_ECDSA_DO_VERIFY
	       ECDSA_F_ECDSA_SIGN_SETUP ECDSA_R_BAD_SIGNATURE
	       ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE ECDSA_R_ERR_EC_LIB
	       ECDSA_R_MISSING_PARAMETERS ECDSA_R_NEED_NEW_SETUP_VALUES
	       ECDSA_R_NON_FIPS_METHOD ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED
	       ECDSA_R_SIGNATURE_MALLOC_FAILED));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Crypt::OpenSSL::ECDSA", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Crypt::OpenSSL::ECDSA", $types);
__END__
   */

  switch (len) {
  case 18:
    if (memEQ(name, "ECDSA_R_ERR_EC_LIB", 18)) {
#ifdef ECDSA_R_ERR_EC_LIB
      *iv_return = ECDSA_R_ERR_EC_LIB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    if (memEQ(name, "ECDSA_F_ECDSA_CHECK", 19)) {
#ifdef ECDSA_F_ECDSA_CHECK
      *iv_return = ECDSA_F_ECDSA_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    /* Names all of length 21.  */
    /* ECDSA_F_ECDSA_DO_SIGN ECDSA_R_BAD_SIGNATURE */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'N':
      if (memEQ(name, "ECDSA_R_BAD_SIGNATURE", 21)) {
      /*                              ^            */
#ifdef ECDSA_R_BAD_SIGNATURE
        *iv_return = ECDSA_R_BAD_SIGNATURE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "ECDSA_F_ECDSA_DO_SIGN", 21)) {
      /*                              ^            */
#ifdef ECDSA_F_ECDSA_DO_SIGN
        *iv_return = ECDSA_F_ECDSA_DO_SIGN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 23:
    /* Names all of length 23.  */
    /* ECDSA_F_ECDSA_DO_VERIFY ECDSA_R_NON_FIPS_METHOD */
    /* Offset 20 gives the best switch position.  */
    switch (name[20]) {
    case 'H':
      if (memEQ(name, "ECDSA_R_NON_FIPS_METHOD", 23)) {
      /*                                   ^         */
#ifdef ECDSA_R_NON_FIPS_METHOD
        *iv_return = ECDSA_R_NON_FIPS_METHOD;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "ECDSA_F_ECDSA_DO_VERIFY", 23)) {
      /*                                   ^         */
#ifdef ECDSA_F_ECDSA_DO_VERIFY
        *iv_return = ECDSA_F_ECDSA_DO_VERIFY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 24:
    if (memEQ(name, "ECDSA_F_ECDSA_SIGN_SETUP", 24)) {
#ifdef ECDSA_F_ECDSA_SIGN_SETUP
      *iv_return = ECDSA_F_ECDSA_SIGN_SETUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    if (memEQ(name, "ECDSA_R_MISSING_PARAMETERS", 26)) {
#ifdef ECDSA_R_MISSING_PARAMETERS
      *iv_return = ECDSA_R_MISSING_PARAMETERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    /* Names all of length 29.  */
    /* ECDSA_F_ECDSA_DATA_NEW_METHOD ECDSA_R_NEED_NEW_SETUP_VALUES */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'D':
      if (memEQ(name, "ECDSA_F_ECDSA_DATA_NEW_METHOD", 29)) {
      /*                         ^                         */
#ifdef ECDSA_F_ECDSA_DATA_NEW_METHOD
        *iv_return = ECDSA_F_ECDSA_DATA_NEW_METHOD;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "ECDSA_R_NEED_NEW_SETUP_VALUES", 29)) {
      /*                         ^                         */
#ifdef ECDSA_R_NEED_NEW_SETUP_VALUES
        *iv_return = ECDSA_R_NEED_NEW_SETUP_VALUES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 31:
    if (memEQ(name, "ECDSA_R_SIGNATURE_MALLOC_FAILED", 31)) {
#ifdef ECDSA_R_SIGNATURE_MALLOC_FAILED
      *iv_return = ECDSA_R_SIGNATURE_MALLOC_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 35:
    if (memEQ(name, "ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE", 35)) {
#ifdef ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE
      *iv_return = ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 39:
    if (memEQ(name, "ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED", 39)) {
#ifdef ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED
      *iv_return = ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

