#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#include <sys/types.h>

typedef unsigned long ulong;
typedef unsigned char uchar;

void __crypt_mysql_hash_password(ulong *result,
  const char *password, size_t password_len)
{
  const char *password_end = password + password_len;
  register ulong nr=1345345333L, add=7, nr2=0x12345671L;
  ulong tmp;
  for (; password != password_end ; password++)
  {
    if (*password == ' ' || *password == '\t')
      continue;			/* skipp space in password */
    tmp= (ulong) (uchar) *password;
    nr^= (((nr & 63)+add)*tmp)+ (nr << 8);
    nr2+=(nr2 << 8) ^ nr;
    add+=tmp;
  }
  result[0]=nr & (((ulong) 1L << 31) -1L); /* Don't use sign bit (str2int) */;
  result[1]=nr2 & (((ulong) 1L << 31) -1L);
  return;
}

void __crypt_mysql_make_scrambled_password(char *to,
  const char *password, size_t password_len)
{
  ulong hash_res[2];
  __crypt_mysql_hash_password(hash_res,password,password_len);
  sprintf(to,"%08lx%08lx",hash_res[0],hash_res[1]);
}

MODULE = Crypt::MySQL		PACKAGE = Crypt::MySQL		

SV *
password(str)
	SV *str;
	CODE:
	{
	char to[17];
	STRLEN size;
	char *src = SvPV(str, size);
	__crypt_mysql_make_scrambled_password(to, src, size);
	RETVAL = newSVpv(to, 0);
	}
	OUTPUT:
	RETVAL


