#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define corlate corlate_subs_MP_corlate

MODULE = Astro::Corlate::Wrapper	PACKAGE = Astro::Corlate::Wrapper

int
corlate( str1, str2, str3, str4, str5, str6, str7, str8 )
   char * str1 
   char * str2 
   char * str3 
   char * str4 
   char * str5 
   char * str6 
   char * str7 
   char * str8 
CODE:
   RETVAL = corlate_subs_MP_corlate( 
                str1, str2, str3, str4, str5, str6, str7, str8,
                strlen(str1), strlen(str2), strlen(str3), strlen(str4),
                strlen(str5), strlen(str6), strlen(str7), strlen(str8)    );
OUTPUT:
   RETVAL              
