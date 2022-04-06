#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <argon2.h>

static size_t S_parse_size(pTHX_ SV* value, int type) {
	STRLEN len;
	const char* string = SvPVbyte(value, len);
	char* end = NULL;
	int base = strtoul(string, &end, 0);
	if (end == string)
		Perl_croak(aTHX_ "Couldn't compute %s tag: memory cost doesn't contain anything numeric", argon2_type2string(type, 0));
	switch(*end) {
		case '\0':
			if (base > 1024)
				return base / 1024;
			else
				Perl_croak(aTHX_ "Couldn't compute %s tag: Memory size much be at least a kilobyte", argon2_type2string(type, 0));
		case 'k':
			return base;
		case 'M':
			return base * 1024;
		case 'G':
			return base * 1024 * 1024;
		default:
			Perl_croak(aTHX_ "Couldn't compute %s tag: Can't parse '%c' as an order of magnitude", argon2_type2string(type, 0), *end);
	}
}
#define parse_size(value, type) S_parse_size(aTHX_ value, type)

MODULE = Crypt::Argon2	PACKAGE = Crypt::Argon2

SV* argon2d_pass(SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)
	ALIAS:
	argon2d_pass = Argon2_d
	argon2i_pass = Argon2_i
	argon2id_pass = Argon2_id
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, encoded_length, m_cost;
	CODE:
	m_cost = parse_size(m_factor, ix);
	password_raw = SvPVbyte(password, password_len);
	salt_raw = SvPVbyte(salt, salt_len);
	encoded_length = argon2_encodedlen(t_cost, m_cost, parallelism, salt_len, output_length, ix);
	RETVAL = newSV(encoded_length - 1);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		NULL, output_length,
		SvPVX(RETVAL), encoded_length,
		ix, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute %s tag: %s", argon2_type2string(ix, FALSE), argon2_error_message(rc));
	}
	SvCUR(RETVAL) = encoded_length - 1;
	OUTPUT:
	RETVAL

SV* argon2d_raw(SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)
	ALIAS:
	argon2d_raw = Argon2_d
	argon2i_raw = Argon2_i
	argon2id_raw = Argon2_id
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, m_cost;
	CODE:
	m_cost = parse_size(m_factor, ix);
	password_raw = SvPVbyte(password, password_len);
	salt_raw = SvPVbyte(salt, salt_len);
	RETVAL = newSV(output_length);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		SvPVX(RETVAL), output_length,
		NULL, 0,
		ix, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute %s tag: %s", argon2_type2string(ix, FALSE), argon2_error_message(rc));
	}
	SvCUR(RETVAL) = output_length;
	OUTPUT:
	RETVAL

SV* argon2d_verify(SV* encoded, SV* password)
	ALIAS:
	argon2d_verify = Argon2_d
	argon2i_verify = Argon2_i
	argon2id_verify = Argon2_id
	PREINIT:
	char* password_raw;
	STRLEN password_len;
	int status;
	CODE:
	password_raw = SvPVbyte(password, password_len);
	status = argon2_verify(SvPVbyte_nolen(encoded), password_raw, password_len, ix);
	switch(status) {
		case ARGON2_OK:
			RETVAL = &PL_sv_yes;
			break;
		case ARGON2_VERIFY_MISMATCH:
			RETVAL = &PL_sv_no;
			break;
		default:
			Perl_croak(aTHX_ "Could not verify %s tag: %s", argon2_type2string(ix, FALSE), argon2_error_message(status));
	}
	OUTPUT:
	RETVAL
