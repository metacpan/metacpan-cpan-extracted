#define PERL_NO_GET_CONTEXT

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

static enum Argon2_type S_find_argon2_type(pTHX_ const char* name, size_t name_len) {
	if (name_len == 8 && strnEQ(name, "argon2id", 8))
		return Argon2_id;
	else if (name_len == 7 && strnEQ(name, "argon2i", 7))
		return Argon2_i;
	else if (name_len == 7 && strnEQ(name, "argon2d", 7))
		return Argon2_d;
	Perl_croak(aTHX_ "No such argon2 type %s", name);
}
#define find_argon2_type(name, len) S_find_argon2_type(aTHX_ name, len)

static enum Argon2_type S_get_argon2_type(pTHX_ SV* name_sv) {
	STRLEN name_len;
	const char* name = SvPV(name_sv, name_len);
	return find_argon2_type(name, name_len);
}
#define get_argon2_type(name) S_get_argon2_type(aTHX_ name)

static SV* S_argon2_pass(pTHX_ enum Argon2_type type, SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length) {
	int m_cost = parse_size(m_factor, type);
	STRLEN password_len, salt_len;
	const char* password_raw = SvPVbyte(password, password_len);
	const char* salt_raw = SvPVbyte(salt, salt_len);
	size_t encoded_length = argon2_encodedlen(t_cost, m_cost, parallelism, salt_len, output_length, type);
	SV* result = newSV(encoded_length - 1);
	SvPOK_only(result);
	int rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		NULL, output_length,
		SvPVX(result), encoded_length,
		type, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(result);
		Perl_croak(aTHX_ "Couldn't compute %s tag: %s", argon2_type2string(type, FALSE), argon2_error_message(rc));
	}
	SvCUR(result) = encoded_length - 1;
	return result;
}
#define argon2_pass(type, password, salt, t_cost, m_factor, parallelism, output_length) S_argon2_pass(aTHX_ type, password, salt, t_cost, m_factor, parallelism, output_length)

static SV* S_argon2_raw(pTHX_ enum Argon2_type type, SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length) {
	int m_cost = parse_size(m_factor, type);
	STRLEN password_len, salt_len;
	const char* password_raw = SvPVbyte(password, password_len);
	const char* salt_raw = SvPVbyte(salt, salt_len);
	SV* result = newSV(output_length);
	SvPOK_only(result);
	int rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		SvPVX(result), output_length,
		NULL, 0,
		type, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(result);
		Perl_croak(aTHX_ "Couldn't compute %s tag: %s", argon2_type2string(type, FALSE), argon2_error_message(rc));
	}
	SvCUR(result) = output_length;
	return result;
}
#define argon2_raw(type, password, salt, t_cost, m_factor, parallelism, output_length) S_argon2_raw(aTHX_ type, password, salt, t_cost, m_factor, parallelism, output_length)

MODULE = Crypt::Argon2	PACKAGE = Crypt::Argon2

SV* argon2_pass(enum Argon2_type type, SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)

SV* argon2id_pass(SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)
ALIAS:
	argon2d_pass = Argon2_d
	argon2i_pass = Argon2_i
	argon2id_pass = Argon2_id
CODE:
	RETVAL = argon2_pass(ix, password, salt, t_cost, m_factor, parallelism, output_length);
OUTPUT:
	RETVAL


SV* argon2_raw(enum Argon2_type type, SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)

SV* argon2id_raw(SV* password, SV* salt, int t_cost, SV* m_factor, int parallelism, size_t output_length)
ALIAS:
	argon2d_raw = Argon2_d
	argon2i_raw = Argon2_i
	argon2id_raw = Argon2_id
CODE:
	RETVAL = argon2_raw(ix, password, salt, t_cost, m_factor, parallelism, output_length);
OUTPUT:
	RETVAL

bool argon2d_verify(SV* encoded, SV* password)
	ALIAS:
	argon2d_verify = Argon2_d
	argon2i_verify = Argon2_i
	argon2id_verify = Argon2_id
	argon2_verify = 4
	PREINIT:
	const char* password_raw, *encoded_raw;
	STRLEN password_len, encoded_len;
	int status;
	CODE:
	encoded_raw = SvPVbyte(encoded, encoded_len);
	if (ix == 4) {
		const char* second_dollar = memchr(encoded_raw + 1, '$', encoded_len - 1);
		ix = find_argon2_type(encoded_raw + 1, second_dollar - encoded_raw - 1);
	}
	password_raw = SvPVbyte(password, password_len);
	status = argon2_verify(SvPVbyte_nolen(encoded), password_raw, password_len, ix);
	switch(status) {
		case ARGON2_OK:
			RETVAL = TRUE;
			break;
		case ARGON2_VERIFY_MISMATCH:
			RETVAL = FALSE;
			break;
		default:
			Perl_croak(aTHX_ "Could not verify %s tag: %s", argon2_type2string(ix, FALSE), argon2_error_message(status));
	}
	OUTPUT:
	RETVAL
