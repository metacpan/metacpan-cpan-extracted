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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GSM_MAGIC GSM_MAJOR GSM_MINOR */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'G':
    if (memEQ(name, "GSM_MAGIC", 9)) {
    /*                     ^        */
#ifdef GSM_MAGIC
      *iv_return = GSM_MAGIC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "GSM_MAJOR", 9)) {
    /*                     ^        */
#ifdef GSM_MAJOR
      *iv_return = GSM_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GSM_MINOR", 9)) {
    /*                     ^        */
#ifdef GSM_MINOR
      *iv_return = GSM_MINOR;
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
my @names = (qw(GSM_MAGIC GSM_MAJOR GSM_MINOR GSM_OPT_FAST GSM_OPT_FRAME_CHAIN
	       GSM_OPT_FRAME_INDEX GSM_OPT_LTP_CUT GSM_OPT_VERBOSE
	       GSM_OPT_WAV49 GSM_PATCHLEVEL NeedFunctionPrototypes));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Audio::GSM", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Audio::GSM", $types);
__END__
   */

  switch (len) {
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "GSM_OPT_FAST", 12)) {
#ifdef GSM_OPT_FAST
      *iv_return = GSM_OPT_FAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "GSM_OPT_WAV49", 13)) {
#ifdef GSM_OPT_WAV49
      *iv_return = GSM_OPT_WAV49;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "GSM_PATCHLEVEL", 14)) {
#ifdef GSM_PATCHLEVEL
      *iv_return = GSM_PATCHLEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* GSM_OPT_LTP_CUT GSM_OPT_VERBOSE */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'P':
      if (memEQ(name, "GSM_OPT_LTP_CUT", 15)) {
      /*                         ^           */
#ifdef GSM_OPT_LTP_CUT
        *iv_return = GSM_OPT_LTP_CUT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "GSM_OPT_VERBOSE", 15)) {
      /*                         ^           */
#ifdef GSM_OPT_VERBOSE
        *iv_return = GSM_OPT_VERBOSE;
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
    /* GSM_OPT_FRAME_CHAIN GSM_OPT_FRAME_INDEX */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'A':
      if (memEQ(name, "GSM_OPT_FRAME_CHAIN", 19)) {
      /*                               ^         */
#ifdef GSM_OPT_FRAME_CHAIN
        *iv_return = GSM_OPT_FRAME_CHAIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'D':
      if (memEQ(name, "GSM_OPT_FRAME_INDEX", 19)) {
      /*                               ^         */
#ifdef GSM_OPT_FRAME_INDEX
        *iv_return = GSM_OPT_FRAME_INDEX;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 22:
    if (memEQ(name, "NeedFunctionPrototypes", 22)) {
#ifdef NeedFunctionPrototypes
      *iv_return = NeedFunctionPrototypes;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

