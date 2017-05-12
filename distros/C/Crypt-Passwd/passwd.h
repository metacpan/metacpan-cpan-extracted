/*
  
  unix_std_crypt()	- Native UNIX crypt() function
  unix_ext_crypt()	- Ultrix/D-Unix enhanced crypt() function

  This module requires the ufc-crypt library written by Michael Glad
  and is subject to the same licensing and distribution schemes.

  */

#ifdef STD_CRYPT
/* This is the traditional UNIX crypt() function */
char*
STD_CRYPT(char* password, char* salt);
#endif

#ifdef EXT_CRYPT
/* This is the enhanced crypt() present on Ultrix and Digital Unix */
char*
EXT_CRYPT(char* password, char* salt);
#endif
