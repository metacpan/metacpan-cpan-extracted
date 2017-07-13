use Test::More;
use Test::Alien;
use Alien::PCRE2;

alien_ok 'Alien::PCRE2';

xs_ok do { local $/; <DATA> }, with_subtest {

  my $re = Foo::pcre2_compile("pattern");
  ok $re, "returned a non-null pointer";
  note "re = $re";

  Foo::pcre2_code_free($re);

};

done_testing;

__DATA__
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

MODULE = Foo PACKAGE = Foo

void *
pcre2_compile(pattern)
    const char *pattern
  CODE:
    pcre2_code *re;
    int errornumber;
    PCRE2_SIZE erroroffset;
    RETVAL = pcre2_compile((PCRE2_SPTR)pattern, PCRE2_ZERO_TERMINATED, 0, &errornumber, &erroroffset, NULL);
  OUTPUT:
    RETVAL

void
pcre2_code_free(re)
    void *re
  CODE:
    pcre2_code_free((pcre2_code *)re);
