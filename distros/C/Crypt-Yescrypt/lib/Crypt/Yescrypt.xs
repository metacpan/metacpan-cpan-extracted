#define PERL_NO_GET_CONTEXT

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "yescrypt.h"

static int timing_safe_compare(const unsigned char *str1, const unsigned char *str2, STRLEN length) {
	int ret = 0;
	STRLEN i;

	for (i = 0; i < length; ++i)
		ret |= (str1[i] ^ str2[i]);

	return ret == 0;
}

#define PREFIX_LEN 95
#define HASH_LEN 43

#define MAP_CONSTANT(cons) newCONSTSUB(stash, #cons, newSVuv(cons))

// Unicode stuff. This will force byte semantics on all string
#undef SvPV
#define SvPV(sv, len) SvPVbyte(sv, len)
#undef SvPV_nolen
#define SvPV_nolen(sv) SvPVbyte_nolen(sv)

MODULE = Crypt::Yescrypt	PACKAGE = Crypt::Yescrypt

PROTOTYPES: DISABLE

BOOT:
	HV* stash = get_hv("Crypt::Yescrypt::", FALSE);

	MAP_CONSTANT(YESCRYPT_WORM);
	MAP_CONSTANT(YESCRYPT_RW);
	MAP_CONSTANT(YESCRYPT_ROUNDS_3);
	MAP_CONSTANT(YESCRYPT_ROUNDS_6);
	MAP_CONSTANT(YESCRYPT_GATHER_1);
	MAP_CONSTANT(YESCRYPT_GATHER_2);
	MAP_CONSTANT(YESCRYPT_GATHER_4);
	MAP_CONSTANT(YESCRYPT_GATHER_8);
	MAP_CONSTANT(YESCRYPT_SIMPLE_1);
	MAP_CONSTANT(YESCRYPT_SIMPLE_2);
	MAP_CONSTANT(YESCRYPT_SIMPLE_4);
	MAP_CONSTANT(YESCRYPT_SIMPLE_8);
	MAP_CONSTANT(YESCRYPT_SBOX_6K);
	MAP_CONSTANT(YESCRYPT_SBOX_12K);
	MAP_CONSTANT(YESCRYPT_SBOX_24K);
	MAP_CONSTANT(YESCRYPT_SBOX_48K);
	MAP_CONSTANT(YESCRYPT_SBOX_96K);
	MAP_CONSTANT(YESCRYPT_SBOX_192K);
	MAP_CONSTANT(YESCRYPT_SBOX_384K);
	MAP_CONSTANT(YESCRYPT_SBOX_768K);

	MAP_CONSTANT(YESCRYPT_RW_DEFAULTS);

const char* yescrypt(const unsigned char* password, size_t length(password), const unsigned char* salt, size_t length(salt), UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	CODE:
		yescrypt_local_t local;
		uint8_t settings[PREFIX_LEN + 1];
		uint8_t buf[PREFIX_LEN + 1 + HASH_LEN + 1];
		yescrypt_params_t params = { flavor, (uint64_t)1 << n, r, p, t, g, 0 };
		if (!yescrypt_init_local(&local)) {
			yescrypt_encode_params_r(&params, salt, STRLEN_length_of_salt, settings, sizeof(settings));
			RETVAL = (char*)yescrypt_r(NULL, &local, password, STRLEN_length_of_password, settings, NULL, buf, sizeof(buf));
			yescrypt_free_local(&local);
		}
		else
			RETVAL = NULL;
	OUTPUT:
		RETVAL

int yescrypt_check(const unsigned char* password, size_t length(password), const char* hash, STRLEN length(hash))
	PREINIT:
	STRLEN password_len;
	yescrypt_local_t local;
	uint8_t outhash[PREFIX_LEN + 1 + HASH_LEN + 1];
	CODE:
		RETVAL = 0;
		if (!yescrypt_init_local(&local)) {
			const uint8_t* ret = yescrypt_r(NULL, &local, password, STRLEN_length_of_password, (const uint8_t*)hash, NULL, outhash, sizeof(outhash));
			yescrypt_free_local(&local);

			if (ret && strlen((const char*)outhash) == STRLEN_length_of_hash)
				RETVAL = timing_safe_compare((const unsigned char *)hash, outhash, STRLEN_length_of_hash);
		}
	OUTPUT:
		RETVAL

int yescrypt_needs_rehash(const unsigned char* hash, size_t length(hash), UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	PREINIT:
	uint8_t settings[PREFIX_LEN + 1];
	STRLEN setting_len;
	CODE:
		yescrypt_params_t params = { flavor, (uint64_t)1 << n, r, p, t, g, 0 };
		yescrypt_encode_params_r(&params, (const uint8_t*)"", 0, settings, sizeof(settings));
		setting_len = strlen((const char*)settings);
		RETVAL = STRLEN_length_of_hash < setting_len || !timing_safe_compare(hash, settings, setting_len - 1);
	OUTPUT:
		RETVAL

SV* yescrypt_kdf(const unsigned char* password, size_t length(password), const unsigned char* salt, size_t length(salt), size_t buffer_size, UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	PREINIT:
	int rc;
	yescrypt_local_t local;
	CODE:
		if (!yescrypt_init_local(&local)) {
			yescrypt_params_t params = { flavor, 1ul << n, r, p, t, g, 0 };

			RETVAL = newSV(buffer_size);
			rc = yescrypt_kdf(NULL, &local, password, STRLEN_length_of_password, salt, STRLEN_length_of_salt, &params, (uint8_t*)SvPVX(RETVAL), buffer_size);
			yescrypt_free_local(&local);
			if (rc == 0) {
				SvPOK_only(RETVAL);
				SvCUR(RETVAL) = buffer_size;
			}
		}
		else
			RETVAL = &PL_sv_undef;
	OUTPUT:
		RETVAL
