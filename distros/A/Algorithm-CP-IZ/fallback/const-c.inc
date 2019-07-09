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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CS_ERR_NO_MEMORY IZ_VERSION_MAJOR IZ_VERSION_MINOR IZ_VERSION_PATCH */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'J':
    if (memEQ(name, "IZ_VERSION_MAJOR", 16)) {
    /*                            ^         */
#ifdef IZ_VERSION_MAJOR
      *iv_return = IZ_VERSION_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "IZ_VERSION_MINOR", 16)) {
    /*                            ^         */
#ifdef IZ_VERSION_MINOR
      *iv_return = IZ_VERSION_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CS_ERR_NO_MEMORY", 16)) {
    /*                            ^         */
#ifdef CS_ERR_NO_MEMORY
      *iv_return = CS_ERR_NO_MEMORY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "IZ_VERSION_PATCH", 16)) {
    /*                            ^         */
#ifdef IZ_VERSION_PATCH
      *iv_return = IZ_VERSION_PATCH;
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

#!/usr/bin/env perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CS_ERR_GETVALUE CS_ERR_NONE CS_ERR_NO_MEMORY CS_ERR_OVERFLOW
	       IZ_VERSION_MAJOR IZ_VERSION_MINOR IZ_VERSION_PATCH));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Algorithm::CP::IZ", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Algorithm::CP::IZ", $types);
__END__
   */

  switch (len) {
  case 11:
    if (memEQ(name, "CS_ERR_NONE", 11)) {
#ifdef CS_ERR_NONE
      *iv_return = CS_ERR_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* CS_ERR_GETVALUE CS_ERR_OVERFLOW */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'R':
      if (memEQ(name, "CS_ERR_OVERFLOW", 15)) {
      /*                         ^           */
#ifdef CS_ERR_OVERFLOW
        *iv_return = CS_ERR_OVERFLOW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'V':
      if (memEQ(name, "CS_ERR_GETVALUE", 15)) {
      /*                         ^           */
#ifdef CS_ERR_GETVALUE
        *iv_return = CS_ERR_GETVALUE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

