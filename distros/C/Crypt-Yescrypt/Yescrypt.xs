#define PERL_NO_GET_CONTEXT

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "yescrypt.h"

static int timing_safe_compare(const unsigned char *str1, const unsigned char *str2, STRLEN length) {
	int ret = 0;
	int i;

	for (i = 0; i < length; ++i)
		ret |= (str1[i] ^ str2[i]);

	return ret == 0;
}

#define PREFIX_LEN 95
#define HASH_LEN 43

#define MAP_CONSTANT(cons) newCONSTSUB(stash, #cons, newSVuv(cons))

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

char* yescrypt(SV* password, SV* salt, UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	PREINIT:
	char *password_raw, *salt_raw, *setting;
	STRLEN password_len, salt_len;
	int rc;
	yescrypt_local_t local;
	uint8_t settings[PREFIX_LEN + 1];
	uint8_t buf[PREFIX_LEN + 1 + HASH_LEN + 1];
	CODE:
		yescrypt_params_t params = { flavor, (uint64_t)1 << n, r, p, t, g, 0 };
		if (!yescrypt_init_local(&local)) {
			password_raw = SvPVbyte(password, password_len);
			salt_raw = SvPVbyte(salt, salt_len);

			setting = yescrypt_encode_params_r(&params, salt_raw, salt_len, settings, sizeof(settings));
			RETVAL = yescrypt_r(NULL, &local, password_raw, password_len, setting, NULL, buf, sizeof(buf));
			yescrypt_free_local(&local);
		}
	OUTPUT:
		RETVAL

int yescrypt_check(SV* password, const char* hash, STRLEN length(hash))
	PREINIT:
	char *password_raw, *setting_raw;
	STRLEN password_len, setting_len;
	int rc;
	yescrypt_local_t local;
	uint8_t outhash[PREFIX_LEN + 1 + HASH_LEN + 1];
	CODE:
		if (!yescrypt_init_local(&local)) {
			password_raw = SvPVbyte(password, password_len);

			const char* ret = yescrypt_r(NULL, &local, password_raw, password_len, hash, NULL, outhash, sizeof(outhash));
			yescrypt_free_local(&local);

			if (!ret || strlen(outhash) != STRLEN_length_of_hash)
				RETVAL = 0;
			else
				RETVAL = timing_safe_compare((const unsigned char *)hash, (const unsigned char *)outhash, STRLEN_length_of_hash);
		}
	OUTPUT:
		RETVAL

int yescrypt_needs_rehash(SV* hash, UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	PREINIT:
	uint8_t settings[PREFIX_LEN + 1];
	char *hash_raw, *setting;
	STRLEN hash_len, setting_len;
	CODE:
		hash_raw = SvPVbyte(hash, hash_len);
		yescrypt_params_t params = { flavor, (uint64_t)1 << n, r, p, t, g, 0 };
		setting = yescrypt_encode_params_r(&params, "", 0, settings, sizeof(settings));
		setting_len = strlen(settings);
		RETVAL = hash_len < setting_len || !timing_safe_compare(hash_raw, setting, setting_len - 1);
	OUTPUT:
		RETVAL

SV* yescrypt_kdf(SV* password, SV* salt, size_t buffer_size, UV flavor, UV n, UV r, UV p = 1, UV t = 0, UV g = 0)
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc;
	yescrypt_local_t local;
	CODE:
		if (!yescrypt_init_local(&local)) {
			yescrypt_params_t params = { flavor, 1ul << n, r, p, t, g, 0 };
			password_raw = SvPVbyte(password, password_len);
			salt_raw = SvPVbyte(salt, salt_len);

			RETVAL = newSV(buffer_size);
			rc = yescrypt_kdf(NULL, &local, password_raw, password_len, salt_raw, salt_len, &params, SvPVX(RETVAL), buffer_size);
			yescrypt_free_local(&local);
			if (rc == 0) {
				SvPOK_only(RETVAL);
				SvCUR(RETVAL) = buffer_size;
			}
		}
	OUTPUT:
		RETVAL
