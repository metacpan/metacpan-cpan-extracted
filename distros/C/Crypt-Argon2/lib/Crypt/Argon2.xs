#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <argon2.h>

static size_t S_parse_size(pTHX_ SV* value) {
	STRLEN len;
	const char* string = SvPV(value, len);
	char* end = NULL;
	int base = strtoul(string, &end, 0);
	if (end == string)
		Perl_croak(aTHX_ "Couldn't compute argon2i tag: memory cost doesn't contain anything numeric");
	switch(*end) {
		case '\0':
			if (base > 1024)
				return base / 1024;
			else
				Perl_croak(aTHX_ "Couldn't compute argon2i tag: Memory size much be at least a kilobyte");
		case 'k':
			return base;
		case 'M':
			return base * 1024;
		case 'G':
			return base * 1024 * 1024;
		default:
			Perl_croak(aTHX_ "Couldn't compute argon2i tag: Can't parse '%c' as an order of magnitude", *end);
	}
}
#define parse_size(value) S_parse_size(aTHX_ value)

MODULE = Crypt::Argon2	PACKAGE = Crypt::Argon2

SV*
argon2i_pass(password, salt, t_cost, m_factor, parallelism, output_length)
	int t_cost
	SV* m_factor
	int parallelism
	SV* password
	SV* salt
	size_t output_length;
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, encoded_length, m_cost;
	CODE:
	m_cost = parse_size(m_factor);
	password_raw = SvPV(password, password_len);
	salt_raw = SvPV(salt, salt_len);
	encoded_length = argon2_encodedlen(t_cost, m_cost, parallelism, salt_len, output_length, Argon2_i);
	RETVAL = newSV(encoded_length - 1);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		NULL, output_length,
		SvPVX(RETVAL), encoded_length,
		Argon2_i, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute argon2i tag: %s", argon2_error_message(rc));
	}
	SvCUR(RETVAL) = encoded_length - 1;
	OUTPUT:
	RETVAL

SV*
argon2i_raw(password, salt, t_cost, m_factor, parallelism, output_length)
	int t_cost
	SV* m_factor
	int parallelism
	SV* password
	SV* salt
	size_t output_length;
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, m_cost;
	CODE:
	m_cost = parse_size(m_factor);
	password_raw = SvPV(password, password_len);
	salt_raw = SvPV(salt, salt_len);
	RETVAL = newSV(output_length);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		SvPV_nolen(RETVAL), output_length,
		NULL, 0,
		Argon2_i, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute argon2i tag: %s", argon2_error_message(rc));
	}
	SvCUR(RETVAL) = output_length;
	OUTPUT:
	RETVAL

SV*
argon2i_verify(encoded, password)
	SV* encoded;
	SV* password;
	PREINIT:
	char* password_raw;
	STRLEN password_len;
	int status;
	CODE:
	password_raw = SvPV(password, password_len);
	status = argon2i_verify(SvPV_nolen(encoded), password_raw, password_len);
	switch(status) {
		case ARGON2_OK:
			RETVAL = &PL_sv_yes;
			break;
		case ARGON2_VERIFY_MISMATCH:
			RETVAL = &PL_sv_no;
			break;
		default:
			Perl_croak(aTHX_ "Could not verify argon2i tag: %s", argon2_error_message(status));
	}
	OUTPUT:
	RETVAL

SV*
argon2id_pass(password, salt, t_cost, m_factor, parallelism, output_length)
	int t_cost
	SV* m_factor
	int parallelism
	SV* password
	SV* salt
	size_t output_length;
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, encoded_length, m_cost;
	CODE:
	m_cost = parse_size(m_factor);
	password_raw = SvPV(password, password_len);
	salt_raw = SvPV(salt, salt_len);
	encoded_length = argon2_encodedlen(t_cost, m_cost, parallelism, salt_len, output_length, Argon2_id);
	RETVAL = newSV(encoded_length - 1);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		NULL, output_length,
		SvPVX(RETVAL), encoded_length,
		Argon2_id, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute argon2id tag: %s", argon2_error_message(rc));
	}
	SvCUR(RETVAL) = encoded_length - 1;
	OUTPUT:
	RETVAL

SV*
argon2id_raw(password, salt, t_cost, m_factor, parallelism, output_length)
	int t_cost
	SV* m_factor
	int parallelism
	SV* password
	SV* salt
	size_t output_length;
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, m_cost;
	CODE:
	m_cost = parse_size(m_factor);
	password_raw = SvPV(password, password_len);
	salt_raw = SvPV(salt, salt_len);
	RETVAL = newSV(output_length);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		SvPV_nolen(RETVAL), output_length,
		NULL, 0,
		Argon2_id, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute argon2id tag: %s", argon2_error_message(rc));
	}
	SvCUR(RETVAL) = output_length;
	OUTPUT:
	RETVAL

SV*
argon2id_verify(encoded, password)
	SV* encoded;
	SV* password;
	PREINIT:
	char* password_raw;
	STRLEN password_len;
	int status;
	CODE:
	password_raw = SvPV(password, password_len);
	status = argon2id_verify(SvPV_nolen(encoded), password_raw, password_len);
	switch(status) {
		case ARGON2_OK:
			RETVAL = &PL_sv_yes;
			break;
		case ARGON2_VERIFY_MISMATCH:
			RETVAL = &PL_sv_no;
			break;
		default:
			Perl_croak(aTHX_ "Could not verify argon2id tag: %s", argon2_error_message(status));
	}
	OUTPUT:
	RETVAL


SV*
argon2d_raw(password, salt, t_cost, m_factor, parallelism, output_length)
	int t_cost
	SV* m_factor
	int parallelism
	SV* password
	SV* salt
	size_t output_length;
	PREINIT:
	char *password_raw, *salt_raw;
	STRLEN password_len, salt_len;
	int rc, m_cost;
	CODE:
	m_cost = parse_size(m_factor);
	password_raw = SvPV(password, password_len);
	salt_raw = SvPV(salt, salt_len);
	RETVAL = newSV(output_length);
	SvPOK_only(RETVAL);
	rc = argon2_hash(t_cost, m_cost, parallelism,
		password_raw, password_len,
		salt_raw, salt_len,
		SvPV_nolen(RETVAL), output_length,
		NULL, 0,
		Argon2_d, ARGON2_VERSION_NUMBER
	);
	if (rc != ARGON2_OK) {
		SvREFCNT_dec(RETVAL);
		Perl_croak(aTHX_ "Couldn't compute argon2d tag: %s", argon2_error_message(rc));
	}
	SvCUR(RETVAL) = output_length;
	OUTPUT:
	RETVAL

