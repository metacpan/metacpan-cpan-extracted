#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = Algorithm::StringHash::FromCSharp35::XS		PACKAGE = Algorithm::StringHash::FromCSharp35::XS		

unsigned int GetHashCode(const char * str)
CODE:
    unsigned int    num = 0x15051505;
    unsigned int    num2 = num;
    int length=strlen(str);

    int new_length = length + ( 8 - length % 8) + 128;
    char chPtr[new_length];
    memset(chPtr,0,new_length);
    strcpy(chPtr,str);

    unsigned int  * numPtr = (unsigned int *)chPtr;
    int i=0;
    for(i=length;i>0;i-=4)
    {
        num = (((num << 5) + num) + (num >> 0x1b)) ^ numPtr[0];
        if(i<=2) break;
        num2=(((num2 << 5) + num2) + (num2 >> 0x1b)) ^ numPtr[1];
        numPtr+=2;
    }
    unsigned int ret = (num + (num2 * 0x5d588b65));
    RETVAL = ret;
OUTPUT:
    RETVAL
