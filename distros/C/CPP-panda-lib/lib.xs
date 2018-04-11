extern "C" {
#  include "EXTERN.h"
#  include "perl.h"
#  include "XSUB.h"
#  undef do_open
#  undef do_close
}

// THIS XS IS ONLY NEEDED BECAUSE TESTS FOR STRING, CONTAINERS, ETC ARE WRITTEN IN PERL, SO WE NEED ADAPTERS TO TEST IT
// IT IS ONLY COMPILED WITH TEST_FULL=1, OTHERWISE IT IS EMPTY XS
// THIS FILE AND EVERYTHING IN t/* CAN BE REMOVED WHEN PERL TESTS ARE REPLACED WITH C++ TESTS

#include "t/src/test.h"
   
MODULE = CPP::panda::lib                PACKAGE = CPP::panda::lib
PROTOTYPES: DISABLE

TYPEMAP: << END

uint64_t T_UV
int64_t  T_IV
uint32_t T_UV

testString   T_STRING
pandaString  T_STRING
testString*  T_MYPTROBJ2
testString2* T_MYPTROBJ2
string_view  T_STRING_VIEW

INPUT

T_STRING
  { STRLEN __${var}_len;
    const char* __${var}_buf = SvPV($arg, __${var}_len);
    $var.assign(__${var}_buf, __${var}_len); }
    
T_STRING_VIEW
  { STRLEN __${var}_len;
    const char* __${var}_buf = SvPV($arg, __${var}_len);
    $var = decltype($var)(__${var}_buf, __${var}_len); }

T_MYPTROBJ2
    { if (SvROK($arg)) $var = INT2PTR($type,SvIV((SV*)SvRV($arg))); else croak("WTF"); }
    DESTROY { delete $var; }

OUTPUT

T_STRING
    sv_setpvn((SV*)$arg, $var.data(), $var.length());

T_STRING_VIEW
    sv_setpvn((SV*)$arg, $var.data(), $var.length());

T_MYPTROBJ2
    { sv_setref_pv($arg, CLASS, (void*)$var); }

END

INCLUDE: t/src/test.xsi