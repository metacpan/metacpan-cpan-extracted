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
constant (pTHX_ const char *name, STRLEN len, NV *nv_return, const char **pv_return) {
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

my $types = {map {($_, 1)} qw(NV PV)};
my @names = (qw(),
            {name=>"AJM_E", type=>"NV"},
            {name=>"AJM_PI", type=>"NV"},
            {name=>"EMBOSS_VERSION", type=>"PV"});

print constant_types(); # macro defs
foreach (C_constant ("Bio::Emboss", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Bio::Emboss", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "AJM_E", 5)) {
#ifdef AJM_E
      *nv_return = AJM_E;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 6:
    if (memEQ(name, "AJM_PI", 6)) {
#ifdef AJM_PI
      *nv_return = AJM_PI;
      return PERL_constant_ISNV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "EMBOSS_VERSION", 14)) {
#ifdef EMBOSS_VERSION
      *pv_return = EMBOSS_VERSION;
      return PERL_constant_ISPV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

