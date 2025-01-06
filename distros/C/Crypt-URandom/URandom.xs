#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/types.h>
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETRANDOM
#include <sys/random.h>
#else
#ifdef HAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM
#include <sys/syscall.h>
#else
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETENTROPY
#include <sys/random.h>
#else
#ifdef HAVE_CRYPT_URANDOM_UNISTD_GETENTROPY
#include <unistd.h>
#endif
#endif
#endif
#endif
#ifdef GRND_NONBLOCK
#else
#define GRND_NONBLOCK	0x0001
#endif
#include <errno.h>

MODULE = Crypt::URandom  PACKAGE = Crypt::URandom  PREFIX = crypt_urandom_
PROTOTYPES: ENABLE

SV *
crypt_urandom_getrandom(length)
        ssize_t length
    PREINIT:
        char *data;
        int result;
    CODE:
	Newx(data, length + 1u, char);
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETRANDOM
        result = getrandom(data, length, GRND_NONBLOCK);
#else
#ifdef HAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM
	result = syscall(SYS_getrandom, data, length, GRND_NONBLOCK);
#else
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETENTROPY
        result = getentropy(data, length);
#else
#ifdef HAVE_CRYPT_URANDOM_UNISTD_GETENTROPY
        result = getentropy(data, length);
#else
        croak("Unable to find getrandom or an alternative");
#endif
#endif
#endif
#endif
        if (result != length) {
            croak("Only read %d bytes from getrandom:%s", result, strerror(errno));
        }
        data[result] = '\0';
        RETVAL = newSVpv(data, result);
    OUTPUT:
        RETVAL
