#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>

#define COMPL(a, b) if((s[i] == a ^ s[len-i-1] == b)) RETVAL = 0;

MODULE = Bio::Tools::DNAGen		PACKAGE = Bio::Tools::DNAGen		

I32
is_selfcplm(s)
 char *s

 PROTOTYPE: $

 INIT:
  I32 i, len = strlen(s);

 CODE:
  RETVAL = 1;

  if(!(len%2)){
     for(i=0; i<len/2; i++)
	 COMPL('a', 't') else COMPL('t', 'a') else COMPL('c', 'g') else COMPL('g', 'c') 
  }
  else
   RETVAL = 0;

 OUTPUT:
	RETVAL


I32
gcratio(s)
 char *s

 PROTOTYPE: $

 INIT:
  I32 i, len=strlen(s), cnt = 0;

 CODE:
  for(i=0; i<len; i++)
     if(s[i] == 'g' || s[i] == 'c') cnt++;

  RETVAL = (I32)100*((double)cnt/(double)len);

 OUTPUT:
  RETVAL



I32
mt(s)
 char *s

 PROTOTYPE: $

 INIT:
  I32 i, len=strlen(s);
  I32 at_cnt=0, gc_cnt=0;

 CODE:
  // Tm = 2(A+T) + 4(G+C).

  for(i=0; i<len; i++){
     if(s[i] == 'g' || s[i] == 'c') gc_cnt++;
     else if(s[i] == 'a' || s[i] == 't') at_cnt++;
  }

  RETVAL = 2*at_cnt + 4*gc_cnt;

 OUTPUT:
  RETVAL

