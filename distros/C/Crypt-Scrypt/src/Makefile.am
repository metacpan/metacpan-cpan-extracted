lib_LTLIBRARIES = libscrypt.la
libscrypt_la_SOURCES = src/lib/util/memlimit.c \
		       src/lib/util/readpass.c \
		       src/lib/util/warn.c \
		       src/lib/scryptenc/scryptenc.c \
		       src/lib/scryptenc/scryptenc_cpuperf.c \
		       src/lib/crypto/crypto_scrypt-ref.c \
		       src/lib/crypto/sha256.c \
		       src/lib/crypto/crypto_aesctr.c
libscrypt_la_CPPFLAGS = -I src/lib/util -I src/lib/scryptenc -I src/lib/crypto \
			-I src -fvisibility=hidden
libscrypt_la_LDFLAGS = -release 1.1.6

# TODO(fes): auto-set sse/nosse/ref
#		       src/lib/crypto/crypto_scrypt-nosse.c
#		       src/lib/crypto/crypto_scrypt-sse.c
