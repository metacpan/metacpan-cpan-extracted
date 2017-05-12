#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "config.h"
#include "passwd.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Crypt::Passwd		PACKAGE = Crypt::Passwd		


double
constant(name,arg)
	char *		name
	int		arg

char*
unix_std_crypt(passwd, salt)
	char* passwd
	char* salt
  PROTOTYPE: $$
  CODE:
#ifdef STD_CRYPT
	RETVAL = STD_CRYPT(passwd, salt);
#else /* STD_CRYPT */
	croak("No standard crypt() defined");
	RETVAL = NULL;
#endif /* STD_CRYPT */
  OUTPUT:
	RETVAL

char*
unix_ext_crypt(passwd, salt)
	char* passwd
	char* salt
  PROTOTYPE: $$
  CODE:
#ifdef EXT_CRYPT
	RETVAL = EXT_CRYPT(passwd, salt);
#else /* EXT_CRYPT */
	croak("No extended crypt() or crypt16() defined");
	RETVAL = NULL;
#endif /* EXT_CRYPT */
  OUTPUT:
	RETVAL
