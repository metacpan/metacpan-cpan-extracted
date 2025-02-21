#if __STDC_VERSION__ >= 199901L
#define PERL_WANT_VARARGS
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <errno.h>

#if defined(HAVE_SYS_RANDOM_GETENTROPY)
#include <sys/random.h>

#elif defined(HAVE_UNISTD_GETENTROPY)
#include <unistd.h>

#elif defined(HAVE_SYS_RANDOM_GETRANDOM)
#include <sys/random.h>

#elif defined(HAVE_SYSCALL_GETRANDOM)
#include <sys/syscall.h>
#include <unistd.h>
#define getrandom(data, length, flags) syscall(SYS_getrandom, data, length, flags)

#elif defined(HAVE_BCRYPT_GENRANDOM)
#define WIN32_NO_STATUS
#include <windows.h>
#undef WIN32_NO_STATUS

#include <winternl.h>
#include <ntstatus.h>
#include <bcrypt.h>

#elif defined(HAVE_RDRAND32) || defined(HAVE_RDRAND64)
#include <immintrin.h>

#else
#error "No suitable implementation found"
#endif

static const char error_string[] = "Could not read random bytes";

MODULE = Crypt::SysRandom::XS				PACKAGE = Crypt::SysRandom::XS

PROTOTYPES: DISABLED

SV* random_bytes(size_t wanted)
	CODE:
		RETVAL = newSVpv("", 0);
		SvGROW(RETVAL, wanted + 1);
		SvCUR_set(RETVAL, wanted);
		char* data = SvPVX(RETVAL);
#if defined(HAVE_SYS_RANDOM_GETENTROPY) || defined(HAVE_UNISTD_GETENTROPY)
		int result = getentropy(data, wanted);
		if (result < 0) {
			SvREFCNT_dec(RETVAL);
			croak(error_string);
		}
#elif defined(HAVE_BCRYPT_GENRANDOM)
		NTSTATUS status = BCryptGenRandom(NULL, data, wanted, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
		if (!NT_SUCCESS(status)) {
			SvREFCNT_dec(RETVAL);
			croak(error_string);
		}
#elif defined(HAVE_RDRAND64)
		if (wanted % 8)
			SvGROW(RETVAL, wanted + (8 - (wanted % 8)) + 1);
		int i;
		for (i = 0; i < wanted; i += 8)
			_rdrand64_step((unsigned long long*)(data + i));
		if (wanted % 8)
			data[wanted] = '\0';
#elif defined(HAVE_RDRAND32)
		if (wanted % 4)
			SvGROW(RETVAL, wanted + (4 - (wanted % 4)) + 1);
		int i;
		for (i = 0; i < wanted; i += 4)
			_rdrand32_step((unsigned*)(data + i));
		if (wanted % 4)
			data[wanted] = '\0';
#else
		size_t received = 0;
		while (received < wanted) {
			size_t length = wanted - received;
			int result = getrandom(data, length, 0);
			if (result == -1 && errno == EINTR) {
				PERL_ASYNC_CHECK();
			} else if (result == -1 || result == 0) {
				SvREFCNT_dec(RETVAL);
				croak(error_string);
			} else {
				received += result;
				data += result;
			}
		}
#endif
	OUTPUT:
		RETVAL
