#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SECP256K1_STATIC
#include <secp256k1.h>

#define CURVE_SIZE 32

typedef struct {
	secp256k1_context *ctx;
	secp256k1_pubkey *pubkey;
	secp256k1_pubkey **pubkeys;
	unsigned int pubkeys_count;
	secp256k1_ecdsa_signature *signature;
} secp256k1_perl;

void secp256k1_perl_replace_pubkey(secp256k1_perl *perl_ctx, secp256k1_pubkey *new_pubkey);
void secp256k1_perl_replace_signature(secp256k1_perl *perl_ctx, secp256k1_ecdsa_signature *new_signature);

secp256k1_perl* secp256k1_perl_create()
{
	secp256k1_context *secp_ctx = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
	secp256k1_perl *perl_ctx = malloc(sizeof *perl_ctx);
	perl_ctx->ctx = secp_ctx;
	perl_ctx->pubkey = NULL;
	perl_ctx->signature = NULL;
	perl_ctx->pubkeys = NULL;
	perl_ctx->pubkeys_count = 0;
	return perl_ctx;
}

void secp256k1_perl_clear(secp256k1_perl *perl_ctx)
{
	secp256k1_perl_replace_pubkey(perl_ctx, NULL);
	secp256k1_perl_replace_signature(perl_ctx, NULL);

	if (perl_ctx->pubkeys_count > 0) {
		int i;
		for (i = 0; i < perl_ctx->pubkeys_count; ++i) {
			free(perl_ctx->pubkeys[i]);
		}

		free(perl_ctx->pubkeys);
		perl_ctx->pubkeys_count = 0;
		perl_ctx->pubkeys = NULL;
	}
}

void secp256k1_perl_destroy(secp256k1_perl *perl_ctx)
{
	secp256k1_perl_clear(perl_ctx);
	secp256k1_context_destroy(perl_ctx->ctx);
	free(perl_ctx);
}

void secp256k1_perl_replace_pubkey(secp256k1_perl *perl_ctx, secp256k1_pubkey *new_pubkey)
{
	if (perl_ctx->pubkey != NULL) {
		free(perl_ctx->pubkey);
	}

	perl_ctx->pubkey = new_pubkey;
}

void secp256k1_perl_replace_signature(secp256k1_perl *perl_ctx, secp256k1_ecdsa_signature *new_signature)
{
	if (perl_ctx->signature != NULL) {
		free(perl_ctx->signature);
	}

	perl_ctx->signature = new_signature;
}

/* HELPERS */

secp256k1_perl* ctx_from_sv(SV *self)
{
	if (!(sv_isobject(self) && sv_derived_from(self, "Bitcoin::Secp256k1"))) {
		croak("calling Bitcoin::Secp256k1 methods is only valid in object context");
	}

	return (secp256k1_perl*) SvIV(SvRV(self));
}

unsigned char* bytestr_from_sv(SV *perlval, STRLEN *size)
{
	return (unsigned char*) SvPVbyte(perlval, *size);
}

unsigned char* size_bytestr_from_sv(SV *perlval, size_t wanted_size, char *argname)
{
	STRLEN size;
	unsigned char *bytestr = bytestr_from_sv(perlval, &size);

	if (size != wanted_size) {
		char error_message[100];
		sprintf(error_message, "%s must be a bytestring of length %zu", argname, wanted_size);

		croak(error_message);
	}

	return bytestr;
}

secp256k1_pubkey* pubkey_from_sv(secp256k1_perl *ctx, SV *data)
{
	if (!SvOK(data) || SvROK(data)) {
		croak("public key must be defined and not a reference");
	}

	size_t key_size;
	unsigned char *key = bytestr_from_sv(data, &key_size);

	secp256k1_pubkey *result_pubkey = malloc(sizeof *result_pubkey);
	int result = secp256k1_ec_pubkey_parse(
		ctx->ctx,
		result_pubkey,
		key,
		key_size
	);

	if (!result) {
		free(result_pubkey);
		croak("the input does not appear to be a valid public key");
	}

	return result_pubkey;
}

void copy_bytestr(unsigned char *to, unsigned char *from, size_t size)
{
	int i;
	for (i = 0; i < size; ++i) {
		to[i] = from[i];
	}
}

void clean_secret(unsigned char *secret)
{
	int i;
	for (i = 0; i < CURVE_SIZE; ++i) {
		secret[i] = 0;
	}
}

/* XS code below */

MODULE = Bitcoin::Secp256k1				PACKAGE = Bitcoin::Secp256k1

PROTOTYPES: DISABLED

SV*
new(classname)
		SV *classname
	CODE:
		/* Calling Bytes::Random::Secure to randomize context */
		dSP;
		PUSHMARK(SP);

		SV *tmp = newSViv(CURVE_SIZE);

		EXTEND(SP, 1);
		PUSHs(tmp);
		PUTBACK;

		size_t count = call_pv("Bitcoin::Secp256k1::_random_bytes", G_SCALAR);
		SvREFCNT_dec(tmp);

		SPAGAIN;

		if (count != 1) {
			croak("fetching randomness went wrong in Bitcoin::Secp256k1::new");
		}

		tmp = POPs;
		PUTBACK;

		/* Randomness dump */
		/* for (int i = 0; i < len; ++i) { warn("%d: %d", i, randomize[i]); } */

		secp256k1_perl* ctx = secp256k1_perl_create();

		if (SvOK(tmp)) {
			unsigned char *randomize = size_bytestr_from_sv(tmp, CURVE_SIZE, "random data");

			if (!secp256k1_context_randomize(ctx->ctx, randomize)) {
				secp256k1_perl_destroy(ctx);
				croak("Failed to randomize secp256k1 context");
			}
		}

		/* Blessing the object */
		SV *secp_sv = newSViv(0);
		RETVAL = sv_setref_iv(secp_sv, SvPVbyte_nolen(classname), (uintptr_t) ctx);
		SvREADONLY_on(secp_sv);
	OUTPUT:
		RETVAL

# Clears public key and signature from the object
void
_clear(self)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		secp256k1_perl_clear(ctx);


# Getter / setter for the public key
SV*
_pubkey(self, ...)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		if (items > 1 && SvOK(ST(1))) {
			SV *pubkey_data = ST(1);
			secp256k1_pubkey *new_pubkey = pubkey_from_sv(ctx, pubkey_data);
			secp256k1_perl_replace_pubkey(ctx, new_pubkey);
		}

		unsigned int compression = SECP256K1_EC_COMPRESSED;

		if (items > 2 && !SvTRUE(ST(2))) {
			compression = SECP256K1_EC_UNCOMPRESSED;
		}

		if (ctx->pubkey != NULL) {
			unsigned char key_output[65];
			size_t key_size = 65;
			secp256k1_ec_pubkey_serialize(
				ctx->ctx,
				key_output,
				&key_size,
				ctx->pubkey,
				compression
			);

			RETVAL = newSVpv((char*) key_output, key_size);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

# Getter / setter for the signature
SV*
_signature(self, ...)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		if (items > 1 && SvOK(ST(1))) {
			SV *new_signature = ST(1);
			if (SvROK(new_signature)) {
				croak("signature must not be a reference");
			}

			size_t signature_size;
			unsigned char *signature = bytestr_from_sv(new_signature, &signature_size);

			secp256k1_ecdsa_signature *result_signature = malloc(sizeof *result_signature);
			int result = secp256k1_ecdsa_signature_parse_der(
				ctx->ctx,
				result_signature,
				signature,
				signature_size
			);

			if (!result) {
				free(result_signature);
				croak("the input does not appear to be a valid signature");
			}

			secp256k1_perl_replace_signature(ctx, result_signature);
		}

		if (ctx->signature != NULL) {
			unsigned char signature_output[72];
			size_t signature_size = 72;
			secp256k1_ecdsa_signature_serialize_der(
				ctx->ctx,
				signature_output,
				&signature_size,
				ctx->signature
			);

			RETVAL = newSVpv((char*) signature_output, signature_size);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

void
_push_pubkey(self)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);

		if (ctx->pubkeys_count > 0) {
			ctx->pubkeys = realloc(ctx->pubkeys, sizeof *ctx->pubkeys * (ctx->pubkeys_count + 1));
		}
		else {
			ctx->pubkeys = malloc(sizeof *ctx->pubkeys);
		}

		ctx->pubkeys[ctx->pubkeys_count++] = ctx->pubkey;
		ctx->pubkey = NULL;

# Creates a public key from a private key
void
_create_pubkey(self, privkey)
		SV *self
		SV *privkey
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *seckey_str = size_bytestr_from_sv(privkey, CURVE_SIZE, "private key");

		secp256k1_pubkey *result_pubkey = malloc(sizeof *result_pubkey);
		int result = secp256k1_ec_pubkey_create(
			ctx->ctx,
			result_pubkey,
			seckey_str
		);

		if (!result) {
			free(result_pubkey);
			croak("creating pubkey failed (invalid private key?)");
		}

		secp256k1_perl_replace_pubkey(ctx, result_pubkey);

# Normalizes a signature. Returns false value if signature was already normalized
SV*
_normalize(self)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		if (ctx->signature == NULL) {
			croak("normalization requires a signature");
		}

		secp256k1_ecdsa_signature *result_signature = malloc(sizeof *result_signature);
		int result = secp256k1_ecdsa_signature_normalize(
			ctx->ctx,
			result_signature,
			ctx->signature
		);

		secp256k1_perl_replace_signature(ctx, result_signature);
		RETVAL = result ? &PL_sv_yes : &PL_sv_no;
	OUTPUT:
		RETVAL

# Verifies a signature
SV*
_verify(self, message)
		SV *self
		SV *message
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		if (ctx->pubkey == NULL || ctx->signature == NULL) {
			croak("verification requires both pubkey and signature");
		}

		unsigned char *message_str = size_bytestr_from_sv(message, CURVE_SIZE, "digest");

		int result = secp256k1_ecdsa_verify(
			ctx->ctx,
			ctx->signature,
			message_str,
			ctx->pubkey
		);

		RETVAL = result ? &PL_sv_yes : &PL_sv_no;
	OUTPUT:
		RETVAL

# Signs a digest
void
_sign(self, privkey, message)
		SV* self
		SV* privkey
		SV* message
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);

		unsigned char *message_str = size_bytestr_from_sv(message, CURVE_SIZE, "digest");
		unsigned char *seckey_str = size_bytestr_from_sv(privkey, CURVE_SIZE, "private key");

		secp256k1_ecdsa_signature *result_signature = malloc(sizeof *result_signature);
		int result = secp256k1_ecdsa_sign(
			ctx->ctx,
			result_signature,
			message_str,
			seckey_str,
			NULL,
			NULL
		);

		if (!result) {
			free(result_signature);
			croak("signing failed (nonce generation problem?)");
		}

		secp256k1_perl_replace_signature(ctx, result_signature);

# Checks whether a private key is valid
SV*
_verify_privkey(self, privkey)
		SV* self
		SV* privkey
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		STRLEN seckey_size;
		unsigned char *seckey_str = bytestr_from_sv(privkey, &seckey_size);

		int result = (
			seckey_size == CURVE_SIZE
			&& secp256k1_ec_seckey_verify(ctx->ctx, seckey_str)
		);

		RETVAL = result ? &PL_sv_yes : &PL_sv_no;
	OUTPUT:
		RETVAL

# Negates a private key
SV*
_privkey_negate(self, privkey)
		SV *self
		SV *privkey
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *seckey_str = size_bytestr_from_sv(privkey, CURVE_SIZE, "private key");

		unsigned char new_seckey[CURVE_SIZE];
		copy_bytestr(new_seckey, seckey_str, CURVE_SIZE);

		int result = secp256k1_ec_seckey_negate(
			ctx->ctx,
			new_seckey
		);

		if (!result) {
			clean_secret(new_seckey);
			croak("resulting negated privkey is not valid");
		}

		RETVAL = newSVpv((char*) new_seckey, CURVE_SIZE);
		clean_secret(new_seckey);
	OUTPUT:
		RETVAL

# Negates a public key
void
_pubkey_negate(self)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);

		/* NOTE: result is always 1 */
		int result = secp256k1_ec_pubkey_negate(
			ctx->ctx,
			ctx->pubkey
		);

# Adds a tweak to private key
SV*
_privkey_add(self, privkey, tweak)
		SV *self
		SV *privkey
		SV *tweak
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *seckey_str = size_bytestr_from_sv(privkey, CURVE_SIZE, "private key");
		unsigned char *tweak_str = size_bytestr_from_sv(tweak, CURVE_SIZE, "tweak");

		unsigned char new_seckey[CURVE_SIZE];
		copy_bytestr(new_seckey, seckey_str, CURVE_SIZE);

		int result = secp256k1_ec_seckey_tweak_add(
			ctx->ctx,
			new_seckey,
			tweak_str
		);

		if (!result) {
			clean_secret(new_seckey);
			croak("resulting added privkey is not valid");
		}

		RETVAL = newSVpv((char*) new_seckey, CURVE_SIZE);
		clean_secret(new_seckey);
	OUTPUT:
		RETVAL

# Adds a tweak to public key
void
_pubkey_add(self, tweak)
		SV *self
		SV *tweak
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *tweak_str = size_bytestr_from_sv(tweak, CURVE_SIZE, "tweak");

		int result = secp256k1_ec_pubkey_tweak_add(
			ctx->ctx,
			ctx->pubkey,
			tweak_str
		);

		if (!result) {
			croak("resulting added pubkey is not valid");
		}

# Multiplies private key by a tweak
SV*
_privkey_mul(self, privkey, tweak)
		SV *self
		SV *privkey
		SV *tweak
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *seckey_str = size_bytestr_from_sv(privkey, CURVE_SIZE, "private_key");
		unsigned char *tweak_str = size_bytestr_from_sv(tweak, CURVE_SIZE, "tweak");

		unsigned char new_seckey[CURVE_SIZE];
		copy_bytestr(new_seckey, seckey_str, CURVE_SIZE);

		int result = secp256k1_ec_seckey_tweak_mul(
			ctx->ctx,
			new_seckey,
			tweak_str
		);

		if (!result) {
			clean_secret(new_seckey);
			croak("multiplication arguments are not valid");
		}

		RETVAL = newSVpv((char*) new_seckey, CURVE_SIZE);
		clean_secret(new_seckey);
	OUTPUT:
		RETVAL

# Multiplies public key by a tweak
void
_pubkey_mul(self, tweak)
		SV *self
		SV *tweak
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);
		unsigned char *tweak_str = size_bytestr_from_sv(tweak, CURVE_SIZE, "tweak");

		int result = secp256k1_ec_pubkey_tweak_mul(
			ctx->ctx,
			ctx->pubkey,
			tweak_str
		);

		if (!result) {
			croak("multiplication arguments are not valid");
		}

# Combines public keys together
void
_pubkey_combine(self)
		SV *self
	CODE:
		secp256k1_perl *ctx = ctx_from_sv(self);

		secp256k1_pubkey *result_pubkey = malloc(sizeof *result_pubkey);
		int result = secp256k1_ec_pubkey_combine(
			ctx->ctx,
			result_pubkey,
			ctx->pubkeys,
			ctx->pubkeys_count
		);

		if (!result) {
			free(result_pubkey);
			croak("resulting sum of pubkeys is not valid");
		}

		secp256k1_perl_replace_pubkey(ctx, result_pubkey);


# Destructor
void
DESTROY(self)
		SV *self
	CODE:
		secp256k1_perl_destroy(ctx_from_sv(self));

# Do a selftest on module load
BOOT:
	secp256k1_selftest();

