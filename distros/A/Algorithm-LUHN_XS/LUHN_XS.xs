#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#include <stdio.h>
#include <string.h>
int   _al_vc[256];
#define MAX_ERROR_LEN 200

/* you may be asking...why? */
/* well, windows and older versions of MacOS don't have strndup, so... */
char * _al_substr(const char* src, const int offset, const int len) {
    char * sub = (char*)malloc(len+1);
    memcpy(sub, src + offset, len);
    sub[len] = 0;
    return sub;
}

/* needed for Devel::Cover */
void _al_test_croak() {
    S_croak_memory_wrap();
}

/* not thread safe, don't use this module with perl threads */
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
    _al_vc[(SvPV(sv_key,PL_na))[0]]=atoi(SvPV(sv_val,PL_na)); /* #uncoverable statment */ 
  }
  return 1;
}

int check_digit_rff(char *input) {
    int len=strlen(input)-1;
    if (len < 1) { 
        return -1;
    }
    static int deltas[]={ 0, 1, 2, 3, 4, -4, -3, -2, -1, 0 };
    int checksum=0;
    int flip=0;
    int i,j;
    for (i = len; i >=0; --i) {
       j=input[i]-48;
       /* only handle numeric input */
       if (j > 9 || j < 0) {return -1;} 
       checksum += j;
       if (flip ^= 1) {
           checksum += deltas[j];
       }
    }
    checksum *= 9;
    return(checksum%10);
}

int check_digit_fast(char *input) {
    int i, sum, ch, num, twoup, len;
    len = strlen(input);
    if (len < 1) { 
          char err[MAX_ERROR_LEN];
          snprintf(err,MAX_ERROR_LEN,"check_digit_fast: No input string.");
          SV *error;
          error=get_sv("Algorithm::LUHN_XS::ERROR",GV_ADD);
          sv_setpv(error,err);
          return -1;
    }
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
    int len=strlen(input);
    if (len < 1) {
        return &PL_sv_undef;
    }
    int rv=check_digit_fast(input);
    if (rv == -1) {
        return &PL_sv_undef;
    } else {
        return newSViv(rv);
    }
}

SV* is_valid(char *input) {
    int len=strlen(input);
    if (len < 2) {
        char err[MAX_ERROR_LEN];
        snprintf(err,MAX_ERROR_LEN,
            "is_valid: you must supply input of at least 2 characters");
        SV *error;
        error=get_sv("Algorithm::LUHN_XS::ERROR",GV_ADD);
        sv_setpv(error,err);
        SV* rv=newSVpv(NULL,1);
        return rv;
    }
    char *leftmost=_al_substr(input,0,len-1); 
    char cd=input[len-1];
    char c=check_digit_fast(leftmost)+'0';
    free(leftmost);
    if (c < 48) {
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
    int len=strlen(input);
    if (len < 2) {
        return 0;
    }
    char *leftmost=_al_substr(input,0,len-1); 
    char cd=input[len-1];
    char c=check_digit_fast(leftmost)+'0';
    free(leftmost);

    if (c < 48) {
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
            return 0;
        }
    }
}

int is_valid_rff(char *input) {
    char csum;
    int len=strlen(input);
    if (len < 2) {
        return 0;
    }
    char cd=input[len-1];
    char *leftmost=_al_substr(input,0,len-1); 
    int d=check_digit_rff(leftmost);
    csum=d+'0';
    free(leftmost);
    if (csum < 48) { 
        return 0;
    } else {
        if (cd == csum) {
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
check_digit_rff (input)
	char *	input

int
check_digit_fast (input)
	char *	input

SV*
check_digit(input)
	char *	input

SV*
is_valid(input)
	char *	input

int
is_valid_fast(input)
	char *	input

int
is_valid_rff(input)
	char *	input

void
_al_test_croak()
