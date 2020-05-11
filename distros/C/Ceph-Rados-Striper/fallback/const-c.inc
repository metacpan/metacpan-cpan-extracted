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
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LIBRADOSSTRIPER_VER_EXTRA LIBRADOSSTRIPER_VER_MAJOR
     LIBRADOSSTRIPER_VER_MINOR */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'J':
    if (memEQ(name, "LIBRADOSSTRIPER_VER_MAJOR", 25)) {
    /*                                     ^         */
#ifdef LIBRADOSSTRIPER_VER_MAJOR
      *iv_return = LIBRADOSSTRIPER_VER_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LIBRADOSSTRIPER_VER_MINOR", 25)) {
    /*                                     ^         */
#ifdef LIBRADOSSTRIPER_VER_MINOR
      *iv_return = LIBRADOSSTRIPER_VER_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LIBRADOSSTRIPER_VER_EXTRA", 25)) {
    /*                                     ^         */
#ifdef LIBRADOSSTRIPER_VER_EXTRA
      *iv_return = LIBRADOSSTRIPER_VER_EXTRA;
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
my @names = (qw(LIBRADOSSTRIPER_VERSION_CODE LIBRADOSSTRIPER_VER_EXTRA
	       LIBRADOSSTRIPER_VER_MAJOR LIBRADOSSTRIPER_VER_MINOR));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Ceph::Rados::Striper", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Ceph::Rados::Striper", $types);
__END__
   */

  switch (len) {
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 28:
    if (memEQ(name, "LIBRADOSSTRIPER_VERSION_CODE", 28)) {
#ifdef LIBRADOSSTRIPER_VERSION_CODE
      *iv_return = LIBRADOSSTRIPER_VERSION_CODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

