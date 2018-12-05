#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#include <stdio.h>
#include <string.h>
int   _al_vc[256];
#define MAX_ERROR_LEN 200


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

int check_digit_rff(char *number) {
    static int deltas[]={ 0, 1, 2, 3, 4, -4, -3, -2, -1, 0 };
    int checksum,flip = 0;
    int len=strlen(number)-1;
    int i,j;
    for (i = len; i >=0; --i) {
       j=number[i]-48;
       checksum += j;
       if (flip ^= 1) {
           checksum += deltas[j];
       }
    }
    checksum *=9;
    return checksum % 10;
}

int check_digit_fast(char *input) {
    int i, sum, ch, num, twoup, len;
    len = strlen(input);
    sum = 0;
    twoup = 1;
    for (i = len - 1; i >= 0; --i) {
        num=_al_vc[input[i]];
        if (num == -1)  { 
          /* Don't change the error text, perl tests depend on the exact words */ 
          char err[MAX_ERROR_LEN];
          snprintf(err,MAX_ERROR_LEN,"Invalid character '%c', in check_digit calculation",input[i]);
          SV *error;
          error=get_sv("Algorithm::LUHN_XS::ERROR",GV_ADD);
          sv_setpv(error,err);
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
    return((10-(sum %10)) % 10);
}

SV* check_digit(char *input) {
    int rv=check_digit_fast(input);
    if (rv == -1) {
        return &PL_sv_undef;
    } else {
        return newSViv(rv);
    }
}

SV* is_valid(char *input) {
    char *copy=strndup(input,strlen(input)-1); 
    char cd=input[strlen(input)-1];
    char c=check_digit_fast(copy)+'0';
    if (c == -1) {
        SV* rv=newSVpv(NULL,1);
        return rv;
    } else {
        if (cd == c) {
            return(newSViv(1));
        } else {
            char err[MAX_ERROR_LEN];
            snprintf(err,MAX_ERROR_LEN,
                "Check digit incorrect. Expected %c",c);
            SV *error;
            error=get_sv("Algorithm::LUHN_XS::ERROR",GV_ADD);
            sv_setpv(error,err);
            SV* rv=newSVpv(NULL,1);
            return rv;
        }
    }
}

int is_valid_fast(char *input) {
    char *copy=strndup(input,strlen(input)-1);
    char cd=input[strlen(input)-1];
    char c=check_digit_fast(copy)+'0';
    if (c == -1) {
        return 0;
    } else {
        if (cd == c) {
            return 1;
        } else {
            char err[MAX_ERROR_LEN];
            snprintf(err,MAX_ERROR_LEN,
                "Check digit incorrect. Expected %c",c);
            SV *error;
            error=get_sv("Algorithm::LUHN_XS::ERROR",GV_ADD);
            sv_setpv(error,err);
            SV* rv=newSVpv(NULL,1);
            return 0;
        }
    }
}

int is_valid_rff(char *input) {
    char *copy=strndup(input,strlen(input)-1);
    char cd=input[strlen(input)-1];
    char c=check_digit_rff(copy)+'0';
    if (c == -1) {
        return 0;
    } else {
        if (cd == c) {
            return 1;
        } else {
            return 0;
        }
    }
}

MODULE = Algorithm::LUHN_XS  PACKAGE = Algorithm::LUHN_XS  

PROTOTYPES: DISABLE


int
_al_init_vc (hash_ref)
	SV *	hash_ref

int
check_digit_rff (number)
	char *	number

int
check_digit_fast (number)
	char *	number

SV*
check_digit(number)
	char *	number

SV*
is_valid(input)
	char *	input

int
is_valid_fast(input)
	char *	input

int
is_valid_rff(input)
	char *	input
