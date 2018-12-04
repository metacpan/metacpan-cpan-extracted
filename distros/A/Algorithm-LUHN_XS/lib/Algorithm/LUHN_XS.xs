#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#include <stdio.h>
#include <string.h>
int   _al_vc[256];
#define MAX_ERROR_LEN 1024
char  _al_lasterr[MAX_ERROR_LEN];

char* _al_get_lasterr() {
    return _al_lasterr;
}

int _al_init_vc(SV* hash_ref) {
  HV* hash;
  HE* hash_entry;
  int num_keys, i;
  SV* sv_key;
  SV* sv_val;
  for (i=0;i<256;++i) {
      _al_vc[i]=-1;
  }
  hash = (HV*)SvRV(hash_ref);
  num_keys = hv_iterinit(hash);
  for (i = 0; i < num_keys; i++) {
    hash_entry = hv_iternext(hash);
    sv_key = hv_iterkeysv(hash_entry);
    sv_val = hv_iterval(hash, hash_entry);
    _al_vc[(SvPV(sv_key,PL_na))[0]]=atoi(SvPV(sv_val,PL_na));
  }
  return 1;
}

int _al_check_digit(char *number) {
    int i, sum, ch, num, twoup, len;
    len = strlen(number);
    sum = 0;
    twoup = 1;
    for (i = len - 1; i >= 0; --i) {
        num=_al_vc[number[i]];
        if (num == -1)  { 
          snprintf(_al_lasterr,1024,"Invalid character '%c', in check_digit calculation",number[i]);
          return -1;
        }
        if (!(twoup = !twoup)) {
            num *= 2;
        }
        while (num) {
           sum += num % 10;
           num=num/10;
        }
    }
    return (10-(sum %10)) % 10;
}

MODULE = Algorithm::LUHN_XS  PACKAGE = Algorithm::LUHN_XS  

PROTOTYPES: DISABLE


char *
_al_get_lasterr ()

int
_al_init_vc (hash_ref)
	SV *	hash_ref

int
_al_check_digit (number)
	char *	number
