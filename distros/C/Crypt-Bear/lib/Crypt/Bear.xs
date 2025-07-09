#include <bearssl.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Generic stuff */

typedef struct {
	const char* key;
	size_t length;
	union value {
		const void* pointer;
		UV integer;
	} value;
} entry;
typedef entry map[];

#define make_map_int_entry(name, result) { STR_WITH_LEN(name), (union value) { .integer = result } }
#define make_map_pointer_entry(name, result) { STR_WITH_LEN(name), (union value) { .pointer = result } }

static const entry* S_map_find(pTHX_ const map table, size_t table_size, const char* name, size_t name_length) {
	size_t i;
	for (i = 0; i < table_size; ++i) {
		if (table[i].length == name_length && strEQ(name, table[i].key))
			return &table[i];
	}
	return NULL;
}
#define map_find(table, table_size, name, name_len) S_map_find(aTHX_ table, table_size, name, name_len)

static union value S_map_get(pTHX_ const map table, size_t table_size, SV* input, const char* type) {
	STRLEN name_length;
	const char* name = SvPVutf8(input, name_length);
	const entry* item = map_find(table, table_size, name, name_length);
	if (item == NULL)
		Perl_croak(aTHX_ "No such %s '%s'", type, name);
	return item->value;
}
#define map_get(table, name, type) S_map_get(aTHX_ table, sizeof table / sizeof *table, name, type)

static const entry* S_map_reverse_find(pTHX_ const map table, size_t table_size, union value value) {
	size_t i;
	for (i = 0; i < table_size; ++i) {
		if (memcmp(&table[i].value, &value, sizeof(union value)) == 0)
			return table + i;
	}
	return NULL;
}
#define map_reverse_find(table, value) S_map_reverse_find(aTHX_ table, sizeof table / sizeof *table, value)

SV* S_make_buffer(pTHX_ size_t size) {
	SV* result = newSVpv("", 0);
	SvGROW(result, size);
	SvCUR_set(result, size);
	return result;
}
#define make_buffer(size) S_make_buffer(aTHX_ size)

SV* S_make_magic(pTHX_ const void* object, const char* classname, const MGVTBL* virtual) {
	SV* result = newSV(0);
	MAGIC* magic = sv_magicext(newSVrv(result, classname), NULL, PERL_MAGIC_ext, virtual, (const char*)object, 0);
	magic->mg_flags |= MGf_COPY|MGf_DUP;
	return result;
}
#define make_magic(object, class, virtual) S_make_magic(aTHX_ object, class, virtual)

#define saveupvn(ptr, len) (unsigned char*)savepvn((const char*)ptr, len)
#define push_isa(child, parent) av_push(get_av(#child "::ISA", GV_ADD), newSVpvs(#parent))

#define br_error_entry(name, key) make_map_int_entry(name, BR_ERR_ ## key)
static const map br_errors = {
	// SSL errors

	br_error_entry("ok", OK),
	br_error_entry("bad param", BAD_PARAM),
	br_error_entry("bad state", BAD_STATE),
	br_error_entry("unsupported version", UNSUPPORTED_VERSION),
	br_error_entry("bad version", BAD_VERSION),
	br_error_entry("bad length", BAD_LENGTH),
	br_error_entry("too large", TOO_LARGE),
	br_error_entry("bad mac", BAD_MAC),
	br_error_entry("no random", NO_RANDOM),
	br_error_entry("unknown type", UNKNOWN_TYPE),
	br_error_entry("unexpected", UNEXPECTED),
	br_error_entry("bad ccs", BAD_CCS),
	br_error_entry("bad alert", BAD_ALERT),
	br_error_entry("bad handshake", BAD_HANDSHAKE),
	br_error_entry("oversized id", OVERSIZED_ID),
	br_error_entry("bad cipher suite", BAD_CIPHER_SUITE),
	br_error_entry("bad compression", BAD_COMPRESSION),
	br_error_entry("bad fraglen", BAD_FRAGLEN),
	br_error_entry("bad secreneg", BAD_SECRENEG),
	br_error_entry("extra extension", EXTRA_EXTENSION),
	br_error_entry("bad sni", BAD_SNI),
	br_error_entry("bad hello done", BAD_HELLO_DONE),
	br_error_entry("limit exceeded", LIMIT_EXCEEDED),
	br_error_entry("bad finished", BAD_FINISHED),
	br_error_entry("resume mismatch", RESUME_MISMATCH),
	br_error_entry("invalid algorithm", INVALID_ALGORITHM),
	br_error_entry("bad signature", BAD_SIGNATURE),
	br_error_entry("wrong key usage", WRONG_KEY_USAGE),
	br_error_entry("no client auth", NO_CLIENT_AUTH),
	br_error_entry("io", IO),
	br_error_entry("recv fatal alert", RECV_FATAL_ALERT),
	br_error_entry("send fatal alert", SEND_FATAL_ALERT),

	// X509 errors
	br_error_entry("ok", X509_OK),
	br_error_entry("invalid value", X509_INVALID_VALUE),
	br_error_entry("truncated", X509_TRUNCATED),
	br_error_entry("empty chain", X509_EMPTY_CHAIN),
	br_error_entry("inner trunc", X509_INNER_TRUNC),
	br_error_entry("bad tag class", X509_BAD_TAG_CLASS),
	br_error_entry("bad tag value", X509_BAD_TAG_VALUE),
	br_error_entry("indefinite length", X509_INDEFINITE_LENGTH),
	br_error_entry("extra element", X509_EXTRA_ELEMENT),
	br_error_entry("unexpected", X509_UNEXPECTED),
	br_error_entry("not constructed", X509_NOT_CONSTRUCTED),
	br_error_entry("not primitive", X509_NOT_PRIMITIVE),
	br_error_entry("partial byte", X509_PARTIAL_BYTE),
	br_error_entry("bad boolean", X509_BAD_BOOLEAN),
	br_error_entry("overflow", X509_OVERFLOW),
	br_error_entry("bad dn", X509_BAD_DN),
	br_error_entry("bad time", X509_BAD_TIME),
	br_error_entry("unsupported", X509_UNSUPPORTED),
	br_error_entry("limit exceeded", X509_LIMIT_EXCEEDED),
	br_error_entry("wrong key type", X509_WRONG_KEY_TYPE),
	br_error_entry("bad signature", X509_BAD_SIGNATURE),
	br_error_entry("time unknown", X509_TIME_UNKNOWN),
	br_error_entry("expired", X509_EXPIRED),
	br_error_entry("dn mismatch", X509_DN_MISMATCH),
	br_error_entry("bad server name", X509_BAD_SERVER_NAME),
	br_error_entry("critical extension", X509_CRITICAL_EXTENSION),
	br_error_entry("not ca", X509_NOT_CA),
	br_error_entry("forbidden key usage", X509_FORBIDDEN_KEY_USAGE),
	br_error_entry("weak public key", X509_WEAK_PUBLIC_KEY),
	br_error_entry("not trusted", X509_NOT_TRUSTED),

};
typedef unsigned br_error_type;

static const char* S_lookup_error(pTHX_ int error) {
	union value value = { .integer = error };
	const entry* entry = map_reverse_find(br_errors, value);
	return entry ? entry->key : NULL;
}
#define lookup_error(error) S_lookup_error(aTHX_ error)


/* Hash stuff */

#define hash_entry_for(name) make_map_pointer_entry(#name, (&br_ ## name ## _vtable))

static const map hashs = {
	hash_entry_for(sha256),
	hash_entry_for(sha512),
	hash_entry_for(sha384),
	hash_entry_for(sha224),
	hash_entry_for(sha1),
	hash_entry_for(md5)
};
typedef const br_hash_class* hash_type;

typedef const struct hash_oid {
	size_t length;
	unsigned char oid[10];
} *hash_oid_type;
static const struct hash_oid sha1_oid   = { 20, { 0x05, 0x2B, 0x0E, 0x03, 0x02, 0x1A } };
static const struct hash_oid sha224_oid = { 28, { 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04 } };
static const struct hash_oid sha256_oid = { 32, { 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01 } };
static const struct hash_oid sha384_oid = { 48, { 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02 } };
static const struct hash_oid sha512_oid = { 64, { 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03 } };

#define hash_oid_entry(name) make_map_pointer_entry(#name, &name ## _oid)
static const map hash_oids = {
	hash_oid_entry(sha1),
	hash_oid_entry(sha224),
	hash_oid_entry(sha256),
	hash_oid_entry(sha384),
	hash_oid_entry(sha512),
};

#define br_hash_update(hasher, data, length) (hasher->vtable->update)(&hasher->vtable, data, length)

#define br_hash_desc(hasher, field) (((hasher)->vtable->desc >> BR_HASHDESC_ ## field ## _OFF) & BR_HASHDESC_ ## field ##_MASK)
#define br_hash_output_size(hasher) br_hash_desc(hasher, OUT)
#define br_hash_state_size(hasher) br_hash_desc(hasher, STATE)
#define br_hash_digest(hasher) ((self)->vtable)
static br_ghash ghash_impl;
#define br_hmac_key_digest br_hmac_key_get_digest
#define br_hmac_digest br_hmac_get_digest

typedef br_hash_compat_context* Crypt__Bear__Hash;
typedef br_hmac_key_context* Crypt__Bear__HMAC__Key;
typedef br_hmac_context* Crypt__Bear__HMAC;


/* KDF stuff */

typedef br_hkdf_context* Crypt__Bear__HKDF;
// typedef br_shake_context* Crypt__Bear__Shake;

/* Block stuff */

static const br_block_cbcenc_class* aes_cbc_enc;
static const br_block_cbcdec_class* aes_cbc_dec;
static const br_block_ctr_class* aes_ctr;
static const br_block_ctrcbc_class* aes_ctrcbc;

#define br_block_cbcenc_block_size(cbcenc) (*cbcenc)->block_size
#define br_block_cbcdec_block_size(cbcdec) (*cbcdec)->block_size
#define br_block_ctr_block_size(ctr) (*ctr)->block_size

typedef const br_block_cbcenc_class** Crypt__Bear__CBC__Enc;
typedef const br_block_cbcdec_class** Crypt__Bear__CBC__Dec;
typedef const br_block_ctr_class** Crypt__Bear__CTR;
typedef const br_block_ctrcbc_class** Crypt__Bear__CTRCBC;

typedef br_aes_gen_cbcenc_keys* Crypt__Bear__AES_CBC__Enc;
typedef br_aes_gen_cbcdec_keys* Crypt__Bear__AES_CBC__Dec;
typedef br_aes_gen_ctr_keys* Crypt__Bear__AES_CTR;
typedef br_aes_gen_ctrcbc_keys* Crypt__Bear__AES_CTRCBC;


/* AEAD stuff */

#define br_aead_reset(self, iv, ivlen) ((*(self))->reset)(self, iv, ivlen)
#define br_aead_aad_inject(self, ad, adlen) ((*(self))->aad_inject)(self, ad, adlen)
#define br_aead_flip(self) ((*(self))->flip)(self)
#define br_aead_run(self, encrypt, out, outlen) ((*(self))->run)(self, encrypt, out, outlen)
#define br_aead_get_tag(self, buffer) ((*(self))->get_tag)(self, buffer)
#define br_aead_check_tag(self, buffer) ((*(self))->check_tag)(self, buffer)

typedef const br_aead_class** Crypt__Bear__AEAD;
typedef br_gcm_context* Crypt__Bear__GCM;
typedef br_eax_context* Crypt__Bear__EAX;
typedef br_ccm_context* Crypt__Bear__CCM;


/* PRNG stuff */

static br_prng_seeder system_seeder;
static const char* system_seeder_name;
#define br_prng_system_seeder_name(class) system_seeder_name
#define br_prng_update(prng, data, length) ((*prng)->update)(prng, data, length)
#define br_hmac_drbg_digest br_hmac_drbg_get_hash

typedef const br_prng_class** Crypt__Bear__PRNG;
typedef br_hmac_drbg_context* Crypt__Bear__HMAC__DRBG;
typedef br_aesctr_drbg_context* Crypt__Bear__AES_CTR__DRBG;


/* RSA stuff */

static br_rsa_pkcs1_vrfy rsa_pkcs1_verify;
static br_rsa_pkcs1_sign rsa_pkcs1_sign;
static br_rsa_oaep_encrypt rsa_oaep_encrypt;
static br_rsa_oaep_decrypt rsa_oaep_decrypt;
static br_rsa_keygen rsa_keygen;

static void S_rsa_key_copy(pTHX_ br_rsa_public_key* dest, const br_rsa_public_key* source) {
	char* buffer = safemalloc(source->nlen + source->elen);
	dest->n = memcpy(buffer, source->n, source->nlen);
	dest->nlen = source->nlen;
	buffer += source->nlen;
	dest->e = memcpy(buffer, source->e, source->elen);
	dest->elen = source->elen;
}
#define rsa_key_copy(dest, source) S_rsa_key_copy(aTHX_ dest, source)

#define rsa_key_destroy(target) Safefree((target)->n)

static int rsa_key_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	br_rsa_public_key* old = (br_rsa_public_key*)magic->mg_ptr;
	br_rsa_public_key* self = safemalloc(sizeof(br_rsa_public_key));
	rsa_key_copy(self, old);
	magic->mg_ptr = (char*)self;
	return 0;
}

static int rsa_key_free(pTHX_ SV* sv, MAGIC* magic) {
	br_rsa_public_key* self = (br_rsa_public_key*)magic->mg_ptr;
	rsa_key_destroy(self);
	Safefree(self);
	return 0;
}

static const MGVTBL Crypt__Bear__RSA__PublicKey_magic = {
	.svt_dup = rsa_key_dup,
	.svt_free = rsa_key_free,
};

typedef br_rsa_public_key* Crypt__Bear__RSA__PublicKey;

static void S_rsa_private_key_copy(pTHX_ br_rsa_private_key* dest, const br_rsa_private_key* source) {
	char* buffer = safemalloc(source->plen + source->qlen + source->dplen + source->dqlen + source->iqlen);
	dest->n_bitlen = source->n_bitlen;
	dest->p = memcpy(buffer, source->p, source->plen);
	dest->plen = source->plen;
	buffer += source->plen;
	dest->q = memcpy(buffer, source->q, source->qlen);
	dest->qlen = source->qlen;
	buffer += source->qlen;
	dest->dp = memcpy(buffer, source->dp, source->dplen);
	dest->dplen = source->dplen;
	buffer += source->dplen;
	dest->dq = memcpy(buffer, source->dq, source->dqlen);
	dest->dqlen = source->dqlen;
	buffer += source->dqlen;
	dest->iq = memcpy(buffer, source->iq, source->iqlen);
	dest->iqlen = source->iqlen;
	buffer += source->iqlen;
}
#define rsa_private_key_copy(dest, source) S_rsa_private_key_copy(aTHX_ dest, source)
#define rsa_private_key_destroy(target) Safefree((target)->p)

static int rsa_private_key_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	br_rsa_private_key* old = (br_rsa_private_key*)magic->mg_ptr;
	br_rsa_private_key* self = safemalloc(sizeof(br_rsa_private_key));
	rsa_private_key_copy(self, old);
	magic->mg_ptr = (char*)self;
	return 0;
}

static int rsa_private_key_free(pTHX_ SV* sv, MAGIC* magic) {
	br_rsa_private_key* self = (br_rsa_private_key*)magic->mg_ptr;
	rsa_private_key_destroy(self);
	Safefree(self);
	return 0;
}

static const MGVTBL Crypt__Bear__RSA__PrivateKey_magic = {
	.svt_dup = rsa_private_key_dup,
	.svt_free = rsa_private_key_free,
};

typedef br_rsa_private_key* Crypt__Bear__RSA__PrivateKey;


/* EC stuff */

static const size_t ecdsa_max_size = 132;

typedef U32 curve_type;
#define curve_entry_for(name) make_map_int_entry(#name, BR_EC_ ## name)

static const map curves = {
	curve_entry_for(sect163k1),
	curve_entry_for(sect163r1),
	curve_entry_for(sect163r2),
	curve_entry_for(sect193r1),
	curve_entry_for(sect193r2),
	curve_entry_for(sect233k1),
	curve_entry_for(sect233r1),
	curve_entry_for(sect239k1),
	curve_entry_for(sect283k1),
	curve_entry_for(sect283r1),
	curve_entry_for(sect409k1),
	curve_entry_for(sect409r1),
	curve_entry_for(sect571k1),
	curve_entry_for(sect571r1),

	curve_entry_for(secp160k1),
	curve_entry_for(secp160r1),
	curve_entry_for(secp160r2),
	curve_entry_for(secp192k1),
	curve_entry_for(secp192r1),
	curve_entry_for(secp224k1),
	curve_entry_for(secp224r1),
	curve_entry_for(secp256k1),
	curve_entry_for(secp256r1),
	curve_entry_for(secp384r1),
	curve_entry_for(secp521r1),

	curve_entry_for(brainpoolP256r1),
	curve_entry_for(brainpoolP384r1),
	curve_entry_for(brainpoolP512r1),

	curve_entry_for(curve25519),
	curve_entry_for(curve448),
};

static void S_ec_key_copy(pTHX_ br_ec_public_key* dest, const br_ec_public_key* source) {
	dest->curve = source->curve;
	dest->q = saveupvn(source->q, source->qlen);
	dest->qlen = source->qlen;
}
#define ec_key_copy(dest, source) S_ec_key_copy(aTHX_ dest, source)

#define ec_key_destroy(key) Safefree((key)->q)

static int ec_key_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	br_ec_public_key* old = (br_ec_public_key*)magic->mg_ptr;
	br_ec_public_key* self = safemalloc(sizeof(br_ec_public_key));
	ec_key_copy(self, old);
	magic->mg_ptr = (char*)self;
	return 0;
}

static int ec_key_free(pTHX_ SV* sv, MAGIC* magic) {
	br_ec_public_key* self = (br_ec_public_key*)magic->mg_ptr;
	ec_key_destroy(self);
	Safefree(self);
	return 0;
}

static const MGVTBL Crypt__Bear__EC__PublicKey_magic = {
	.svt_dup = ec_key_dup,
	.svt_free = ec_key_free,
};

static void S_ec_private_key_copy(pTHX_ br_ec_private_key* dest, const br_ec_private_key* source) {
	dest->curve = source->curve;
	dest->x = saveupvn(source->x, source->xlen);
	dest->xlen = source->xlen;
}
#define ec_private_key_copy(dest, source) S_ec_private_key_copy(aTHX_ dest, source)
#define ec_private_key_destroy(target) Safefree((target)->x)

static int ec_privatekey_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	br_ec_private_key* old = (br_ec_private_key*)magic->mg_ptr;
	br_ec_private_key* self = safemalloc(sizeof(br_ec_private_key));
	ec_private_key_copy(self, old);
	magic->mg_ptr = (char*)self;
	return 0;
}

static int ec_privatekey_free(pTHX_ SV* sv, MAGIC* magic) {
	br_ec_private_key* self = (br_ec_private_key*)magic->mg_ptr;
	ec_private_key_destroy(self);
	Safefree(self);
	return 0;
}

static const MGVTBL Crypt__Bear__EC__PrivateKey_magic = {
	.svt_dup = ec_privatekey_dup,
	.svt_free = ec_privatekey_free,
};

static const br_ec_impl* ec_default;
static const br_ec_impl* ec_c25519;
static br_ecdsa_sign ec_sign_default;
static br_ecdsa_vrfy ec_verify_default;

typedef br_ec_public_key* Crypt__Bear__EC__PublicKey;
typedef br_ec_private_key* Crypt__Bear__EC__PrivateKey;
typedef const br_ec_impl* Crypt__Bear__EC;


/* PEM stuff */

#define pem_flag_entry_for(name, value) make_map_int_entry(name, BR_PEM_ ## value)
static const map pem_flags = {
	pem_flag_entry_for("line64", LINE64),
	pem_flag_entry_for("crlf", CRLF),
};
#define lookup_pem_flag(name) (map_get(pem_flags, name, "pem flag").integer)

typedef struct {
#ifdef MULTIPLICITY
	tTHX aTHX;
#endif
	br_pem_decoder_context decoder;
	SV* callback;
	SV* name;
	SV* buffer;
} pem_decoder;

static void pem_callback(void* ptr, const void* data, size_t length) {
	pem_decoder* current = ptr;
	dTHXa(current->aTHX);
	sv_catpvn(current->buffer, data, length);
}

static int pem_decoder_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	pem_decoder* decoder = (pem_decoder*)magic->mg_ptr;
	pem_decoder* self = safecalloc(1, sizeof(pem_decoder));

#ifdef MULTIPLICITY
	self->aTHX = aTHX;
	self->callback = sv_dup_inc(decoder->callback, params);
	if (decoder->buffer)
		self->buffer = sv_dup_inc(decoder->buffer, params);
	if (decoder->name)
		self->name = sv_dup_inc(decoder->name, params);
	if (decoder->decoder.dest_ctx)
		self->decoder.dest_ctx = self;
#endif

	return 0;
}

static int pem_decoder_free(pTHX_ SV* sv, MAGIC* magic) {
	pem_decoder* decoder = (pem_decoder*)magic->mg_ptr;

	SvREFCNT_dec(decoder->callback);
	if (decoder->buffer)
		SvREFCNT_dec(decoder->buffer);
	if (decoder->name)
		SvREFCNT_dec(decoder->name);

	Safefree(decoder);

	return 0;
}

static const MGVTBL Crypt__Bear__PEM__Decoder_magic = {
	.svt_dup = pem_decoder_dup,
	.svt_free = pem_decoder_free,
};

typedef pem_decoder* Crypt__Bear__PEM__Decoder;


/* X509 stuff */

#define usage_entry_for(name, value) make_map_int_entry(name, value)
static const map usages = {
	usage_entry_for("key-exchange", BR_KEYTYPE_KEYX),
	usage_entry_for("signing", BR_KEYTYPE_SIGN),
	usage_entry_for("both", BR_KEYTYPE_KEYX | BR_KEYTYPE_SIGN),
};
typedef unsigned usage_type;

static void S_dn_init(pTHX_ br_x500_name* dest, const unsigned char* data, size_t data_len) {
	dest->data = saveupvn(data, data_len);
	dest->len = data_len;
}
#define dn_init(dest, data, data_len) S_dn_init(aTHX_ dest, data, data_len)

static void S_dn_copy(pTHX_ br_x500_name* dest, const br_x500_name* source) {
	dn_init(dest, source->data, source->len);
}
#define dn_copy(dest, source) S_dn_copy(aTHX_ dest, source)

#define dn_to_sv(dn) newSVpvn((const char*)(dn).data, (dn).len)

#define dn_destroy(target) Safefree((target)->data)

typedef struct certificate {
	br_x509_certificate cert;
	br_x509_decoder_context decoder;
	br_x500_name dn;
} *Crypt__Bear__X509__Certificate;

#define key_type_entry(name, value) make_map_int_entry(name, BR_KEYTYPE_ ## value)
static const map key_kinds = {
	key_type_entry("rsa", RSA),
	key_type_entry("ec", EC),
};
typedef unsigned key_kind_type;

struct decoder_helper {
#ifdef MULTIPLICITY
	tTHX aTHX;
#endif
	SV* value;
};

static void dn_decoder(void *ctx, const void *buf, size_t len) {
	struct decoder_helper* current = (struct decoder_helper*) ctx;
	dTHXa(current->aTHX);
	sv_catpvn(current->value, buf, len);
}

static void S_br_x509_certificate_init(pTHX_ br_x509_certificate* dest, const unsigned char* data, size_t data_len) {
	dest->data = saveupvn(data, data_len);
	dest->data_len = data_len;
}
#define br_x509_certificate_init(cert, data, data_len) S_br_x509_certificate_init(aTHX_ cert, data, data_len)

static void S_br_x509_certificate_copy(pTHX_ br_x509_certificate* dest, const br_x509_certificate* source) {
	br_x509_certificate_init(dest, source->data, source->data_len);
}
#define br_x509_certificate_copy(dest, source) S_br_x509_certificate_copy(aTHX_ dest, source)

#define br_x509_certificate_destroy(target) Safefree((target)->data)

#define br_x509_certificate_dn(self) dn_to_sv((self)->dn)
#define br_x509_certificate_is_ca(self) br_x509_decoder_isCA(&(self)->decoder)
#define br_x509_certificate_signer_key_type(self) br_x509_decoder_get_signer_key_type(&(self)->decoder)

static void S_certificate_destroy(pTHX_ struct certificate* cert) {
	dn_destroy(&cert->dn);
	br_x509_certificate_destroy(&cert->cert);
}
#define certificate_destroy(target) S_certificate_destroy(aTHX_ target)

static void S_certificate_copy(pTHX_ struct certificate* dest, const struct certificate* source) {
	br_x509_certificate_copy(&dest->cert, &source->cert);
	memcpy(&dest->decoder, &source->decoder, sizeof(br_x509_decoder_context));
	dn_copy(&dest->dn, &source->dn);
}
#define certificate_copy(dest, source) S_certificate_copy(aTHX_ dest, source)

static int certificate_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct certificate* old = (struct certificate*)magic->mg_ptr;
	struct certificate* self = safemalloc(sizeof(struct certificate));
	certificate_copy(self, old);
	magic->mg_ptr = (char*)self;
	return 0;
}

static int certificate_free(pTHX_ SV* sv, MAGIC* magic) {
	struct certificate* cert = (struct certificate*)magic->mg_ptr;
	certificate_destroy(cert);
	Safefree(cert);
	return 0;
}

static const MGVTBL Crypt__Bear__X509__Certificate_magic = {
	.svt_dup = certificate_dup,
	.svt_free = certificate_free
};

static SV* S_x509_key_unpack(pTHX_ const br_x509_pkey* public_key) {
	if (public_key->key_type == BR_KEYTYPE_RSA) {
		br_rsa_public_key* key = safemalloc(sizeof *key);
		rsa_key_copy(key, &public_key->key.rsa);
		return make_magic(key, "Crypt::Bear::RSA::PublicKey", &Crypt__Bear__RSA__PublicKey_magic);
	} else if (public_key->key_type == BR_KEYTYPE_EC) {
		br_ec_public_key* key = safemalloc(sizeof *key);
		ec_key_copy(key, &public_key->key.ec);
		return make_magic(key, "Crypt::Bear::EC::PublicKey", &Crypt__Bear__EC__PublicKey_magic);
	}
	return &PL_sv_undef;
}
#define x509_key_unpack(key) S_x509_key_unpack(aTHX_ key)


static void S_x509_key_copy(pTHX_ br_x509_pkey* dest, const br_x509_pkey* source) {
	dest->key_type = source->key_type;
	if (source->key_type == BR_KEYTYPE_RSA) {
		rsa_key_copy(&dest->key.rsa, &source->key.rsa);
	} else if (source->key_type == BR_KEYTYPE_EC) {
		ec_key_copy(&dest->key.ec, &source->key.ec);
	}
}
#define x509_key_copy(dest, source) S_x509_key_copy(aTHX_ dest, source)

static void S_x509_key_destroy(pTHX_ br_x509_pkey* target) {
	if (target->key_type == BR_KEYTYPE_RSA) {
		rsa_key_destroy(&target->key.rsa);
	} else if (target->key_type == BR_KEYTYPE_EC) {
		ec_key_destroy(&target->key.ec);
	}
}
#define x509_key_destroy(dest) S_x509_key_destroy(aTHX_ dest)


static void S_trust_anchor_copy(pTHX_ br_x509_trust_anchor* dest, const br_x509_trust_anchor* source) {
	dest->flags = source->flags;
	dn_copy(&dest->dn, &source->dn);
	x509_key_copy(&dest->pkey, &source->pkey);
}
#define trust_anchor_copy(dest, source) S_trust_anchor_copy(aTHX_ dest, source)

static void S_trust_anchor_destroy(pTHX_ br_x509_trust_anchor* target) {
	Safefree(target->dn.data);
	x509_key_destroy(&target->pkey);
}
#define trust_anchor_destroy(target) S_trust_anchor_destroy(aTHX_ target)

typedef struct trust_anchors {
	br_x509_trust_anchor* array;
	size_t allocated;
	size_t used;
} *Crypt__Bear__X509__TrustAnchors;


static void trust_anchors_init(struct trust_anchors* target) {
	target->array = NULL;
	target->allocated = 0;
	target->used = 0;
}

static void S_trust_anchors_destroy(pTHX_ struct trust_anchors* target) {
	for (size_t i = 0; i < target->used; i++) {
		trust_anchor_destroy(target->array + i);
	}
	Safefree(target->array);
}
#define trust_anchors_destroy(target) S_trust_anchors_destroy(aTHX_ target)

static void S_trust_anchors_copy(pTHX_ struct trust_anchors* dest, const struct trust_anchors* source) {
	dest->used = source->used;
	dest->array = safecalloc(source->allocated, sizeof(br_x509_trust_anchor));
	dest->allocated = source->allocated;

	for (size_t i = 0; i < source->used; i++) {
		trust_anchor_copy(dest->array + i, source->array + i);
	}
}
#define trust_anchors_copy(dest, source) S_trust_anchors_copy(aTHX_ dest, source)

static void S_trust_anchors_push(pTHX_ struct trust_anchors* anchors, const br_x509_trust_anchor* anchor) {
	if (anchors->allocated == 0) {
		anchors->array = safemalloc(8 * sizeof(br_x509_trust_anchor));
		anchors->allocated = 8;
	}
	else if (anchors->used == anchors->allocated) {
		anchors->allocated = anchors->allocated ? 2 * anchors->allocated : 4;
		size_t new_size = anchors->allocated * sizeof(br_x509_trust_anchor);
		anchors->array = saferealloc(anchors->array, new_size);
	}
	memcpy(anchors->array + anchors->used, anchor, sizeof *anchor);
	anchors->used++;
}
#define trust_anchors_push(anchors, new_anchor) S_trust_anchors_push(aTHX_ anchors, new_anchor)

static int trust_anchors_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct trust_anchors* old = (struct trust_anchors*)magic->mg_ptr;
	struct trust_anchors* copy = safemalloc(sizeof *copy);
	trust_anchors_copy(copy, old);
	return 0;
}

static int trust_anchors_free(pTHX_ SV* sv, MAGIC* magic) {
	struct trust_anchors* trust = (struct trust_anchors*)magic->mg_ptr;
	trust_anchors_destroy(trust);
	Safefree(trust);
	return 0;
}

static const MGVTBL Crypt__Bear__X509__TrustAnchors_magic = {
	.svt_dup = trust_anchors_dup,
	.svt_free = trust_anchors_free,
};


typedef struct certificate_chain {
	br_x509_certificate* array;
	size_t allocated;
	size_t used;
	unsigned signer_key_type;
} *Crypt__Bear__X509__Certificate__Chain;


static void certificate_chain_init(struct certificate_chain* target) {
	target->array = NULL;
	target->allocated = 0;
	target->used = 0;
}

static void S_certificate_chain_push(pTHX_ struct certificate_chain* certificates, const br_x509_certificate* anchor) {
	if (certificates->used == certificates->allocated) {
		certificates->allocated = certificates->allocated ? 2 * certificates->allocated : 4;
		size_t new_size = certificates->allocated * sizeof(br_x509_certificate);
		certificates->array = saferealloc(certificates->array, new_size);
	}
	memcpy(certificates->array + certificates->used, anchor, sizeof *anchor);
	certificates->used++;
}
#define certificate_chain_push(anchors, new_anchor) S_certificate_chain_push(aTHX_ anchors, new_anchor)

static void S_certificate_chain_copy(pTHX_ struct certificate_chain* dest, const struct certificate_chain* source) {
	dest->used = source->used;
	dest->array = safecalloc(source->allocated, sizeof(br_x509_certificate));
	dest->allocated = source->allocated;

	for (size_t i = 0; i < source->used; i++) {
		br_x509_certificate_copy(dest->array + i, source->array + i);
	}
}
#define certificate_chain_copy(dest, source) S_certificate_chain_copy(aTHX_ dest, source)

static int certificate_chain_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct certificate_chain* old = (struct certificate_chain*)magic->mg_ptr;
	struct certificate_chain* copy = safemalloc(sizeof *copy);
	certificate_chain_copy(copy, old);
	return 0;
}

static void S_certificate_chain_destroy(pTHX_ struct certificate_chain* chain) {
	for (size_t i = 0; i < chain->used; i++) {
		br_x509_certificate_destroy(chain->array + i);
	}
	Safefree(chain->array);
}
#define certificate_chain_destroy(chain) S_certificate_chain_destroy(aTHX_ chain)

static int certificate_chain_free(pTHX_ SV* sv, MAGIC* magic) {
	struct certificate_chain* chain = (struct certificate_chain*)magic->mg_ptr;
	certificate_chain_destroy(chain);
	Safefree(chain);
	return 0;
}

static const MGVTBL Crypt__Bear__X509__Certificate__Chain_magic = {
	.svt_dup = certificate_chain_dup,
	.svt_free = certificate_chain_free,
};

typedef struct private_key {
	unsigned key_type;
	union {
		br_rsa_private_key rsa;
		br_ec_private_key ec;
	};
} *Crypt__Bear__X509__PrivateKey;

static void S_private_key_copy(pTHX_ struct private_key* copy, const struct private_key* old) {
	copy->key_type = old->key_type;
	if (old->key_type == BR_KEYTYPE_RSA)
		rsa_private_key_copy(&copy->rsa, &old->rsa);
	else
		ec_private_key_copy(&copy->ec, &old->ec);
}
#define private_key_copy(copy, old) S_private_key_copy(aTHX_ copy, old)

static int private_key_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct private_key* old = (struct private_key*)magic->mg_ptr;
	struct private_key* copy = safemalloc(sizeof *copy);
	private_key_copy(copy, old);
	return 0;
}

static void S_private_key_destroy(pTHX_ struct private_key* self) {
	if (self->key_type == BR_KEYTYPE_RSA)
		rsa_private_key_destroy(&self->rsa);
	else
		ec_private_key_destroy(&self->ec);
}
#define private_key_destroy(self) S_private_key_destroy(aTHX_ self)

static int private_key_free(pTHX_ SV* sv, MAGIC* magic) {
	struct private_key* self = (struct private_key*)magic->mg_ptr;
	private_key_destroy(self);
	return 0;
}

static const MGVTBL Crypt__Bear__X509__PrivateKey_magic = {
	.svt_dup = private_key_dup,
	.svt_free = private_key_free,
};

static unsigned S_private_key_usage(pTHX_ struct private_key* key) {
	if (key->key_type == BR_KEYTYPE_EC) {
		unsigned result = BR_KEYTYPE_KEYX;
		if (key->ec.curve == BR_EC_secp256r1 || key->ec.curve == BR_EC_secp384r1 || BR_EC_secp521r1)
			result |= BR_KEYTYPE_SIGN;
		return result;
	} else {
		return BR_KEYTYPE_SIGN;
	}
}
#define private_key_usage(key) S_private_key_usage(aTHX_ key)

typedef const br_x509_class** Crypt__Bear__X509__Validator;

typedef struct validator_minimal {
	br_x509_minimal_context context;
	struct trust_anchors anchors;
} *Crypt__Bear__X509__Validator__Minimal;

typedef br_x509_knownkey_context* Crypt__Bear__X509__Validator__KnownKey;

/* SSL stuff */

#define ssl_flag_entry(name, key) make_map_int_entry(name, BR_OPT_ ## key)
static const map ssl_flags = {
	ssl_flag_entry("enforce-server-preferences", ENFORCE_SERVER_PREFERENCES),
	ssl_flag_entry("no-renegotiation", NO_RENEGOTIATION),
	ssl_flag_entry("tolerate-no-client-auth", TOLERATE_NO_CLIENT_AUTH),
	ssl_flag_entry("fail-on-alpn-mismatch", FAIL_ON_ALPN_MISMATCH),
};
typedef unsigned ssl_flag_type;

#define ssl_version_entry(name, key) make_map_int_entry(name, BR_ ## key)
static const map ssl_versions = {
	ssl_version_entry("tls-1.0", TLS10),
	ssl_version_entry("tls-1.1", TLS11),
	ssl_version_entry("tls-1.2", TLS12),
};
typedef unsigned ssl_version_type;

typedef br_ssl_session_parameters* Crypt__Bear__SSL__Session;
typedef br_ssl_engine_context* Crypt__Bear__SSL__Engine;

typedef const br_ssl_client_certificate_class** Crypt__Bear__SSL__Client__Certificate;


typedef struct private_certificate {
	struct certificate_chain chain;
	struct private_key key;
	unsigned usage;
} *Crypt__Bear__SSL__PrivateCertificate;

#define private_certificate_init(self) memset(self, '\0', sizeof(struct private_certificate))

static void S_private_certificate_copy(pTHX_ struct private_certificate* dest, const struct private_certificate* source) {
	certificate_chain_copy(&dest->chain, &source->chain);
	private_key_copy(&dest->key, &source->key);
}
#define private_certificate_copy(dest, source) S_private_certificate_copy(aTHX_ dest, source)

static int private_certificate_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct private_certificate* old = (struct private_certificate*)magic->mg_ptr;
	struct private_certificate* copy = safemalloc(sizeof *copy);

	private_certificate_copy(copy, old);
	magic->mg_ptr = (char*)copy;

	return 0;
}

static void S_private_certificate_destroy(pTHX_ struct private_certificate* self) {
	private_key_destroy(&self->key);
	certificate_chain_destroy(&self->chain);
}
#define private_certificate_destroy(self) S_private_certificate_destroy(aTHX_ self)

static int private_certificate_free(pTHX_ SV* sv, MAGIC* magic) {
	struct private_certificate* self = (struct private_certificate*)magic->mg_ptr;
	private_certificate_destroy(self);
	Safefree(self);
	return 0;
}


static const MGVTBL Crypt__Bear__SSL__PrivateCertificate_magic = {
	.svt_dup = private_certificate_dup,
	.svt_free = private_certificate_free,
};


typedef struct ssl_client {
	br_ssl_client_context context;
	struct private_certificate private;
	unsigned char buffer[BR_SSL_BUFSIZE_BIDI];
	br_x509_minimal_context minimal;
	struct trust_anchors trust_anchors;
} *Crypt__Bear__SSL__Client;

static void ssl_engine_buffer_move(br_ssl_engine_context* new, const br_ssl_engine_context* old, unsigned char* buffer) {
	// HIC SUNT DRACONES
	new->ibuf = buffer;
	new->obuf = buffer + old->ibuf_len;
}

static int ssl_client_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct ssl_client* old = (struct ssl_client*)magic->mg_ptr;
	struct ssl_client* copy = safemalloc(sizeof *copy);

	private_certificate_copy(&copy->private, &old->private);
	trust_anchors_copy(&copy->trust_anchors, &old->trust_anchors);
	br_x509_minimal_init_full(&copy->minimal, copy->trust_anchors.array, copy->trust_anchors.used);
	br_ssl_engine_set_x509(&copy->context.eng, &copy->minimal.vtable);
	ssl_engine_buffer_move(&copy->context.eng, &old->context.eng, copy->buffer);

	magic->mg_ptr = (char*)copy;

	return 0;
}

static int ssl_client_free(pTHX_ SV* sv, MAGIC* magic) {
	struct ssl_client* self = (struct ssl_client*)magic->mg_ptr;

	trust_anchors_destroy(&self->trust_anchors);
	private_certificate_destroy(&self->private);

	Safefree(self);

	return 0;
}

static const MGVTBL Crypt__Bear__SSL__Client_magic = {
	.svt_dup = ssl_client_dup,
	.svt_free = ssl_client_free,
};

typedef struct ssl_server {
	br_ssl_server_context context;
	struct private_certificate private;
	unsigned char buffer[BR_SSL_BUFSIZE_BIDI];
} *Crypt__Bear__SSL__Server;


static int ssl_server_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	struct ssl_server* old = (struct ssl_server*)magic->mg_ptr;
	struct ssl_server* copy = safemalloc(sizeof *copy);

	private_certificate_copy(&copy->private, &old->private);
	ssl_engine_buffer_move(&copy->context.eng, &old->context.eng, copy->buffer);

	magic->mg_ptr = (char*)copy;

	return 0;
}

static int ssl_server_free(pTHX_ SV* sv, MAGIC* magic) {
	struct ssl_server* self = (struct ssl_server*)magic->mg_ptr;
	private_certificate_destroy(&self->private);
	Safefree(self);
	return 0;
}

static const MGVTBL Crypt__Bear__SSL__Server_magic = {
	.svt_dup = ssl_server_dup,
	.svt_free = ssl_server_free,
};


/* DIRTY STUFF */

// Make various default values pretty for XS's error messages
#define automatic private_key_usage(key)
#define undef &PL_sv_undef

// Unicode stuff. This will force byte semantics on all string
#undef SvPV
#define SvPV(sv, len) SvPVbyte(sv, len)
#undef SvPV_nolen
#define SvPV_nolen(sv) SvPVbyte_nolen(sv)


MODULE = Crypt::Bear PACKAGE = Crypt::Bear PREFIX = br_

PROTOTYPES: DISABLED

SV* br_get_config(class)
CODE:
	const br_config_option* current = br_get_config();
	HV* hash = newHV();
	while (current->name) {
		SV* val = newSVuv(current->value);
		hv_store(hash, current->name, strlen(current->name), val, 0);
		current++;
	}
	RETVAL = newRV_noinc((SV*)hash);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::Hash PREFIX = br_hash_

Crypt::Bear::Hash br_hash_new(class, hash_type hash)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	(*hash->init)(&RETVAL->vtable);
OUTPUT:
	RETVAL

void br_hash_update(Crypt::Bear::Hash self, const char* data, size_t length(data))

SV* br_hash_out(Crypt::Bear::Hash self)
CODE:
	RETVAL = make_buffer(br_hash_output_size(self));
	(self->vtable->out)(&self->vtable, SvPVX(RETVAL));
OUTPUT:
	RETVAL

SV* br_hash_state(Crypt::Bear::Hash self)
CODE:
	RETVAL = make_buffer(br_hash_state_size(self));
	(self->vtable->state)(&self->vtable, SvPVX(RETVAL));
OUTPUT:
	RETVAL

void br_hash_set_state(Crypt::Bear::Hash self, const char* state, size_t length(state))
CODE:
	size_t output_size = br_hash_state_size(self);
	if (STRLEN_length_of_state != br_hash_state_size(self))
		Perl_croak(aTHX_ "State hash wrong size");
	(self->vtable->set_state)(&self->vtable, state, STRLEN_length_of_state);

hash_type br_hash_digest(Crypt::Bear::Hash self)

UV br_hash_output_size(Crypt::Bear::Hash self)


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::HMAC::Key PREFIX = br_hmac_key_

Crypt::Bear::HMAC::Key br_hmac_key_new(class, hash_type hash, const char* key, size_t length(key))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_hmac_key_init(RETVAL, hash, key, STRLEN_length_of_key);
OUTPUT:
	RETVAL

hash_type br_hmac_key_digest(Crypt::Bear::HMAC::Key self)

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::HMAC PREFIX = br_hmac_

Crypt::Bear::HMAC br_hmac_new(class, Crypt::Bear::HMAC::Key key, size_t out_length = 0)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_hmac_init(RETVAL, key, out_length);
OUTPUT:
	RETVAL

IV br_hmac_size(Crypt::Bear::HMAC self)

void br_hmac_update(Crypt::Bear::HMAC self, const char* data, size_t length(data))

SV* br_hmac_out(Crypt::Bear::HMAC self)
CODE:
	RETVAL = make_buffer(br_hmac_size(self));
	br_hmac_out(self, SvPVX(RETVAL));
OUTPUT:
	RETVAL

hash_type br_hmac_digest(Crypt::Bear::HMAC self)


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::HKDF PREFIX = br_hkdf_

Crypt::Bear::HKDF br_hkdf_new(class, hash_type hash, const char* salt, size_t length(salt))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_hkdf_init(RETVAL, hash, salt, STRLEN_length_of_salt);
OUTPUT:
	RETVAL

void br_hkdf_inject(Crypt::Bear::HKDF self, const char* data, size_t length(data))

void br_hkdf_flip(Crypt::Bear::HKDF self)

SV* br_hkdf_produce(Crypt::Bear::HKDF self, size_t output_size, const char* info, size_t length(info))
CODE:
	RETVAL = make_buffer(output_size);
	br_hkdf_produce(self, info, STRLEN_length_of_info, SvPV_nolen(RETVAL), output_size);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::Shake PREFIX = br_shake_

#if 0
Crypt::Bear::Shake br_shake_new(class, hash_type hash, UV security_level)
CODE:
OUTPUT:
	RETVAL

void br_shake_inject(Crypt::Bear::Shake self, const char* data, size_t length(data))

void br_shake_flip(Crypt::Bear::Shake self)

SV* br_shake_produce(Crypt::Bear::Shake self, const char* info, size_t length(info))
CODE:
	RETVAL = make_buffer(output_size);
	br_shake_produce(self, info, STRLEN_length_of_info, SvPV_nolen(RETVAL), output_size);
OUTPUT:
	RETVAL

#endif


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::CBC::Enc PREFIX = br_block_cbcenc_

IV br_block_cbcenc_block_size(Crypt::Bear::CBC::Enc self)

SV* br_block_cbcenc_run(Crypt::Bear::CBC::Enc self, const char* iv, STRLEN length(iv), const char* data, size_t length(data))
CODE:
	if ((STRLEN_length_of_data % br_block_cbcenc_block_size(self)) != 0)
		Perl_croak(aTHX_ "Data size should be a multiple of %u bytes", br_block_cbcenc_block_size(self));
	if (STRLEN_length_of_iv != br_block_cbcenc_block_size(self))
		Perl_croak(aTHX_ "IV should be %u bytes", br_block_cbcenc_block_size(self));

	char iv_copy[STRLEN_length_of_iv];
	memcpy(iv_copy, iv, STRLEN_length_of_iv);
	RETVAL = newSVpvn(data, STRLEN_length_of_data);
	((*self)->run)(self, iv_copy, SvPV_nolen(RETVAL), STRLEN_length_of_data);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::CBC::Dec PREFIX = br_block_cbcdec_

IV br_block_cbcdec_block_size(Crypt::Bear::CBC::Dec self)

SV* br_block_cbcdec_run(Crypt::Bear::CBC::Dec self, const char* iv, STRLEN length(iv), const char* data, size_t length(data))
CODE:
	if ((STRLEN_length_of_data % br_block_cbcdec_block_size(self)) != 0)
		Perl_croak(aTHX_ "data size should be a multiple of %u bytes", br_block_cbcdec_block_size(self));
	if (STRLEN_length_of_iv != br_block_cbcdec_block_size(self))
		Perl_croak(aTHX_ "IV should be %u bytes", br_block_cbcdec_block_size(self));

	char iv_copy[STRLEN_length_of_iv];
	memcpy(iv_copy, iv, STRLEN_length_of_iv);
	RETVAL = newSVpvn(data, STRLEN_length_of_data);
	((*self)->run)(self, iv_copy, SvPV_nolen(RETVAL), STRLEN_length_of_data);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::CTR PREFIX = br_block_ctr_

IV br_block_ctr_block_size(Crypt::Bear::CTR self)

SV* br_block_ctr_run(Crypt::Bear::CTR self, const char* iv, STRLEN length(iv), U32 counter, const char* data, size_t length(data))
CODE:
	if ((STRLEN_length_of_data % br_block_ctr_block_size(self)) != 0)
		Perl_croak(aTHX_ "data size should be a multiple of %u bytes", br_block_ctr_block_size(self));
	if (STRLEN_length_of_iv != br_block_ctr_block_size(self))
		Perl_croak(aTHX_ "IV should be %u bytes", br_block_ctr_block_size(self));

	char iv_copy[STRLEN_length_of_iv];
	memcpy(iv_copy, iv, STRLEN_length_of_iv);
	RETVAL = newSVpvn(data, STRLEN_length_of_data);
	((*self)->run)(self, iv_copy, counter, SvPV_nolen(RETVAL), STRLEN_length_of_data);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AES_CBC::Enc PREFIX = br_block_aes_cbcenc_
BOOT:
	push_isa(Crypt::Bear::AES_CBC::Enc, Crypt::Bear::CBC::Enc);
	aes_cbc_enc = br_aes_x86ni_cbcenc_get_vtable();
	if (!aes_cbc_enc)
		aes_cbc_enc = &br_aes_ct_cbcenc_vtable;

Crypt::Bear::AES_CBC::Enc br_block_aes_cbcenc_new(class, const char* key, size_t length(key))
CODE:
	RETVAL = safemalloc(aes_cbc_enc->context_size);
	(aes_cbc_enc->init)((const br_block_cbcenc_class**)RETVAL, key, STRLEN_length_of_key);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AES_CBC::Dec PREFIX = br_block_aes_cbcdec_
BOOT:
	push_isa(Crypt::Bear::AES_CBC::Dec, Crypt::Bear::CBC::Dec);
	aes_cbc_dec = br_aes_x86ni_cbcdec_get_vtable();
	if (!aes_cbc_dec)
#if IVSIZE == 8
		aes_cbc_dec = &br_aes_ct64_cbcdec_vtable;
#else
		aes_cbc_dec = &br_aes_ct_cbcdec_vtable;
#endif

Crypt::Bear::AES_CBC::Dec br_block_aes_cbcdec_new(class, const char* key, size_t length(key))
CODE:
	RETVAL = safemalloc(aes_cbc_dec->context_size);
	(aes_cbc_dec->init)((const br_block_cbcdec_class**)RETVAL, key, STRLEN_length_of_key);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AES_CTR PREFIX = br_block_aes_ctr_
BOOT:
	push_isa(Crypt::Bear::AES_CTR, Crypt::Bear::CTR);
	aes_ctr = br_aes_x86ni_ctr_get_vtable();
	if (!aes_ctr)
#if IVSIZE == 8
		aes_ctr = &br_aes_ct64_ctr_vtable;
#else
		aes_ctr = &br_aes_ct_ctr_vtable;
#endif

Crypt::Bear::AES_CTR br_block_aes_ctr_new(class, const char* key, size_t length(key))
CODE:
	RETVAL = safemalloc(aes_ctr->context_size);
	(aes_ctr->init)(&RETVAL->vtable, key, STRLEN_length_of_key);
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::CTRCBC PREFIX = br_block_ctrcbc_


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AES_CTRCBC PREFIX = br_block_aes_ctrcbc_
BOOT:
	push_isa(Crypt::Bear::AES_CTRCBC, Crypt::Bear::CTRCBC);
	aes_ctrcbc = br_aes_x86ni_ctrcbc_get_vtable();
	if (!aes_ctrcbc)
		aes_ctrcbc = &br_aes_ct_ctrcbc_vtable;

Crypt::Bear::AES_CTRCBC br_block_aes_ctrcbc_new(class, const char* data, size_t length(data))
CODE:
	RETVAL = safemalloc(aes_ctrcbc->context_size);
	(aes_ctrcbc->init)(&RETVAL->vtable, data, STRLEN_length_of_data);
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::ChaCha20



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AEAD PREFIX = br_aead_

void br_aead_reset(Crypt::Bear::AEAD self, const char* iv, size_t length(iv))

void br_aead_aad_inject(Crypt::Bear::AEAD self, const char* iv, size_t length(iv))

void br_aead_flip(Crypt::Bear::AEAD self)

SV* run(Crypt::Bear::AEAD self, const char* data, size_t length(data), bool encrypt)
CODE:
	RETVAL = newSVpvn(data, STRLEN_length_of_data);
	br_aead_run(self, encrypt, SvPV_nolen(RETVAL), STRLEN_length_of_data);
OUTPUT:
	RETVAL

SV* get_tag(Crypt::Bear::AEAD self)
CODE:
	RETVAL = make_buffer((*self)->tag_size);
	br_aead_get_tag(self, SvPVX(RETVAL));
OUTPUT:
	RETVAL

bool check_tag(Crypt::Bear::AEAD self, const char* tag, size_t length(tag))
CODE:
	if (STRLEN_length_of_tag != (*self)->tag_size)
		Perl_croak(aTHX_ "Incorrect tag size, got %zu expected %zu", STRLEN_length_of_tag, (*self)->tag_size);
	RETVAL = br_aead_check_tag(self, tag);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::GCM PREFIX = br_gcm_
BOOT:
	push_isa(Crypt::Bear::GCM, Crypt::Bear::AEAD);
	ghash_impl = br_ghash_pclmul_get();
	if (!ghash_impl)
#if IVSIZE == 8
		ghash_impl = &br_ghash_ctmul64;
#else
		ghash_impl = &br_ghash_ctmul;
#endif


Crypt::Bear::GCM br_gcm_new(class, Crypt::Bear::CTR ctr)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_gcm_init(RETVAL, ctr, ghash_impl);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::EAX PREFIX = br_eax_
BOOT:
	push_isa(Crypt::Bear::EAX, Crypt::Bear::AEAD);

Crypt::Bear::EAX br_eax_new(class, Crypt::Bear::CTRCBC ctrcbc)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_eax_init(RETVAL, ctrcbc);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::CCM PREFIX = br_ccm_
BOOT:
	push_isa(Crypt::Bear::CCM, Crypt::Bear::AEAD);

Crypt::Bear::CCM br_ccm_new(class, Crypt::Bear::CTRCBC ctrcbc)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_ccm_init(RETVAL, ctrcbc);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::PRNG PREFIX = br_prng_
BOOT:
	system_seeder = br_prng_seeder_system(&system_seeder_name);

const char* br_prng_system_seeder_name(class)

SV* br_prng_generate(Crypt::Bear::PRNG self, size_t length)
CODE:
	RETVAL = make_buffer(length);
	((*self)->generate)(self, SvPVX(RETVAL), length);
OUTPUT:
	RETVAL

void br_prng_update(Crypt::Bear::PRNG self, const char* data, size_t length(data))

bool br_prng_system_seed(Crypt::Bear::PRNG self)
CODE:
	RETVAL = system_seeder ? system_seeder(self) : FALSE;
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::HMAC::DRBG PREFIX = br_hmac_drbg_
BOOT:
	push_isa(Crypt::Bear::HMAC::DRBG, Crypt::Bear::PRNG);

Crypt::Bear::HMAC::DRBG br_hmac_drbg_new(class, hash_type hash, const char* seed, size_t length(seed))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_hmac_drbg_init(RETVAL, hash, seed, STRLEN_length_of_seed);
OUTPUT:
	RETVAL

hash_type br_hmac_drbg_digest(Crypt::Bear::HMAC::DRBG self)


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::AES_CTR::DRBG PREFIX = br_aesctr_drbg_
BOOT:
	push_isa(Crypt::Bear::AES_CTR::DRBG, Crypt::Bear::PRNG);


Crypt::Bear::AES_CTR::DRBG br_aesctr_drbg_new(class, const char* seed, size_t length(seed))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_aesctr_drbg_init(RETVAL, aes_ctr, seed, STRLEN_length_of_seed);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::RSA PREFIX = br_rsa_
BOOT:
	rsa_keygen = br_rsa_keygen_get_default();

void br_rsa_generate_keypair(Crypt::Bear::PRNG prng, size_t size, UV exponent = 0)
PPCODE:
	br_rsa_public_key* key = safemalloc(sizeof(br_rsa_public_key));
	char* public_buffer = safemalloc(BR_RSA_KBUF_PUB_SIZE(size));
	br_rsa_private_key* private_key = safemalloc(sizeof(br_rsa_private_key));
	char* private_buffer = safemalloc(BR_RSA_KBUF_PRIV_SIZE(size));
	bool success = rsa_keygen(prng, private_key, private_buffer, key, public_buffer, size, exponent);

	if (success) {
		SV* public = make_magic(key, "Crypt::Bear::RSA::PublicKey", &Crypt__Bear__RSA__PublicKey_magic);
		mXPUSHs(public);

		SV* private = make_magic(private_key, "Crypt::Bear::RSA::PrivateKey", &Crypt__Bear__RSA__PrivateKey_magic);
		mXPUSHs(private);
	}


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::RSA::PublicKey PREFIX = br_rsa_public_key_
BOOT:
	rsa_pkcs1_verify = br_rsa_pkcs1_vrfy_get_default();
	rsa_oaep_encrypt = br_rsa_oaep_encrypt_get_default();

SV* br_rsa_public_key_pkcs1_verify(Crypt::Bear::RSA::PublicKey self, hash_oid_type hash, const unsigned char* signature, size_t length(signature))
CODE:
	RETVAL = make_buffer(hash->length);
	bool success = rsa_pkcs1_verify(signature, STRLEN_length_of_signature, hash->oid, hash->length, self, (unsigned char*)SvPV_nolen(RETVAL));
	if (!success)
		sv_setsv(RETVAL, &PL_sv_undef);
OUTPUT:
	RETVAL

SV* br_rsa_public_key_oaep_encrypt(Crypt::Bear::RSA::PublicKey self, hash_type hash, const char* plain, size_t length(plain), Crypt::Bear::PRNG prng, const char* label, size_t length(label))
CODE:
	RETVAL = make_buffer(self->nlen);
	size_t length = rsa_oaep_encrypt(prng, hash, label, STRLEN_length_of_label, self, SvPV_nolen(RETVAL), self->nlen, plain, STRLEN_length_of_plain);
	if (length)
		SvCUR_set(RETVAL, length);
	else
		Perl_croak(aTHX_ "Could not encrypt");
OUTPUT:
	RETVAL



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::RSA::PrivateKey PREFIX = br_rsa_private_key_
BOOT:
	rsa_pkcs1_sign = br_rsa_pkcs1_sign_get_default();
	rsa_oaep_decrypt = br_rsa_oaep_decrypt_get_default();

SV* br_rsa_private_key_pkcs1_sign(Crypt::Bear::RSA::PrivateKey self, hash_oid_type hash_oid, const unsigned char* hash, size_t length(hash))
CODE:
	if (STRLEN_length_of_hash != hash_oid->length)
		Perl_croak(aTHX_ "Hash has incorrect length");
	RETVAL = make_buffer((self->n_bitlen+7)/8);
	bool success = rsa_pkcs1_sign(hash_oid->oid, hash, STRLEN_length_of_hash, self, (unsigned char*)SvPV_nolen(RETVAL));
	if (!success)
		Perl_croak(aTHX_ "Could not sign");
OUTPUT:
	RETVAL

SV* br_rsa_private_key_oaep_decrypt(Crypt::Bear::RSA::PrivateKey self, hash_type hash, const char* ciphertext, size_t length(ciphertext), const char* label, size_t length(label))
CODE:
	RETVAL = newSVpvn(ciphertext, STRLEN_length_of_ciphertext);
	size_t len = STRLEN_length_of_ciphertext;
	bool succes = rsa_oaep_decrypt(hash, label, STRLEN_length_of_label, self, SvPV_nolen(RETVAL), &len);
	if (succes)
		SvCUR_set(RETVAL, len);
	else
		sv_setsv(RETVAL, &PL_sv_undef);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::EC PREFIX = br_ec_
BOOT:
	ec_default = br_ec_get_default();
	ec_sign_default = br_ecdsa_sign_asn1_get_default();
	ec_verify_default = br_ecdsa_vrfy_asn1_get_default();

void br_ec_supported_curves(class)
PPCODE:
	for (UV i = 0; i < 31; i++) {
		if (ec_default->supported_curves & (1 << i)) {
			union value value = { .integer = i };
			const entry* entry = map_reverse_find(curves, value);
			mXPUSHp(entry->key, entry->length);
		}
	}


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::EC::PublicKey PREFIX = br_ec_public_key_

Crypt::Bear::EC::PublicKey br_ec_public_key_new(curve_type curve, const char* data, size_t length(data))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	RETVAL->curve = curve;
	RETVAL->q = saveupvn(data, STRLEN_length_of_data);
	RETVAL->qlen = STRLEN_length_of_data;
OUTPUT:
	RETVAL

curve_type br_ec_public_key_curve(Crypt::Bear::EC::PublicKey self)
CODE:
	RETVAL = self->curve;
OUTPUT:
	RETVAL

bool br_ec_public_key_ecdsa_verify(Crypt::Bear::EC::PublicKey self, hash_type hash_name, unsigned char* hash_value, size_t length(hash_value), unsigned char* signature, size_t length(signature))
CODE:
	size_t hash_size = ((hash_name->desc >> BR_HASHDESC_OUT_OFF) & BR_HASHDESC_OUT_MASK);
	if (STRLEN_length_of_hash_value != hash_size)
		Perl_croak(aTHX_ "Hash is inappropriately sized");
	RETVAL = ec_verify_default(ec_default, hash_value, hash_size, self, signature, STRLEN_length_of_signature);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::EC::PrivateKey PREFIX = br_ec_private_key_

Crypt::Bear::EC::PrivateKey br_ec_private_key_new(curve_type curve, const char* data, size_t length(data))
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	RETVAL->curve = curve;
	RETVAL->x = saveupvn(data, STRLEN_length_of_data);
	RETVAL->xlen = STRLEN_length_of_data;
OUTPUT:
	RETVAL

curve_type br_ec_private_key_curve(Crypt::Bear::EC::PrivateKey self)
CODE:
	RETVAL = self->curve;
OUTPUT:
	RETVAL

Crypt::Bear::EC::PrivateKey br_ec_private_key_generate(class, curve_type curve, Crypt::Bear::PRNG prng)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	size_t length = br_ec_keygen(prng, ec_default, RETVAL, NULL, curve);
	char* buffer = safemalloc(length);
	br_ec_keygen(prng, ec_default, RETVAL, buffer, curve);
OUTPUT:
	RETVAL

Crypt::Bear::EC::PublicKey br_ec_private_key_public_key(Crypt::Bear::EC::PrivateKey self)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	size_t length = br_ec_compute_pub(ec_default, RETVAL, NULL, self);
	char* buffer = safemalloc(length);
	br_ec_compute_pub(ec_default, RETVAL, buffer, self);
OUTPUT:
	RETVAL

SV* br_ec_private_key_ecdsa_sign(Crypt::Bear::EC::PrivateKey self, hash_type hash_name, unsigned char* hash_value, size_t length(hash_value))
CODE:
	size_t hash_size = ((hash_name->desc >> BR_HASHDESC_OUT_OFF) & BR_HASHDESC_OUT_MASK);
	if (STRLEN_length_of_hash_value != hash_size)
		Perl_croak(aTHX_ "Hash is inappropriately sized");
	RETVAL = make_buffer(ecdsa_max_size);
	size_t length = ec_sign_default(ec_default, hash_name, hash_value, self, SvPV_nolen(RETVAL));
	if (!length)
		Perl_croak(aTHX_ "Could not sign");
	SvCUR_set(RETVAL, length);
OUTPUT:
	RETVAL

SV* br_ec_private_key_ecdh_key_exchange(Crypt::Bear::EC::PrivateKey self, Crypt::Bear::EC::PublicKey other)
CODE:
	if (self->curve != other->curve)
		Perl_croak(aTHX_ "Keys must be on same curve for EC key exchange");

	size_t out_length = 0;
	(ec_default->generator)(self->curve, &out_length);
	RETVAL = make_buffer(out_length);
	memcpy(SvPV_nolen(RETVAL), other->q, other->qlen);

	(ec_default->mul)(SvPV_nolen(RETVAL), other->qlen, self->x, self->xlen, self->curve);
	size_t xoff, xlen;
	xoff = ec_default->xoff(self->curve, &xlen);
	if (xoff)
		sv_chop(RETVAL, SvPV_nolen(RETVAL) + xoff);
	SvCUR_set(RETVAL, xlen);
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::PEM PREFIX = br_pem_

SV* br_pem_pem_encode(const char* banner, const char* data, size_t length(data), ...)
CODE:
	unsigned flags = 0;
	for (int i = 3; i < items; i++) {
		flags |= lookup_pem_flag(ST(i));
	}
	size_t length = br_pem_encode(NULL, data, STRLEN_length_of_data, banner, flags);
	RETVAL = make_buffer(length);
	br_pem_encode(SvPV_nolen(RETVAL), data, STRLEN_length_of_data, banner, flags);
OUTPUT:
	RETVAL


SV* br_pem_pem_decode(const char* data, size_t length(data))
PPCODE:
	pem_decoder decoder;
	br_pem_decoder_init(&decoder.decoder);
#ifdef MULTIPLICITY
	decoder.aTHX = aTHX;
#endif

	size_t left = STRLEN_length_of_data;
	while (left) {
		size_t pushed = br_pem_decoder_push(&decoder.decoder, data, left);
		data += pushed;
		left -= pushed;

		switch (br_pem_decoder_event(&decoder.decoder)) {
			case BR_PEM_BEGIN_OBJ: {
				decoder.name = newSVpv(br_pem_decoder_name(&decoder.decoder), 0);
				decoder.buffer = newSVpvn("", 0);
				br_pem_decoder_setdest(&decoder.decoder, pem_callback, &decoder);
				break;
			}
			case BR_PEM_END_OBJ: {
				if (decoder.buffer) {
					mXPUSHs(decoder.name);
					mXPUSHs(decoder.buffer);
					decoder.name = NULL;
					decoder.buffer = NULL;
				}
				break;
			}
			case BR_PEM_ERROR: {
				if (decoder.name)
					SvREFCNT_dec(decoder.name);
				if (decoder.buffer)
					SvREFCNT_dec(decoder.buffer);
				Perl_croak(aTHX_ "Could not parse PEM");
				break;
			}
		}
	}

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::PEM::Decoder PREFIX = br_pem_decoder_

Crypt::Bear::PEM::Decoder br_pem_decoder_new(class, SV* callback)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_pem_decoder_init(&RETVAL->decoder);
	RETVAL->callback = SvREFCNT_inc(callback);
	RETVAL->name = NULL;
	RETVAL->buffer = NULL;
#ifdef MULTIPLICITY
	RETVAL->aTHX = aTHX;
#endif
OUTPUT:
	RETVAL

void br_pem_decoder_push(Crypt::Bear::PEM::Decoder self, const char* data, size_t length(data))
CODE:
	size_t left = STRLEN_length_of_data;
	while (left) {
		size_t pushed = br_pem_decoder_push(&self->decoder, data, left);
		data += pushed;
		left -= pushed;

		switch (br_pem_decoder_event(&self->decoder)) {
			case BR_PEM_BEGIN_OBJ: {
				self->name = newSVpv(br_pem_decoder_name(&self->decoder), 0);
				self->buffer = newSVpvn("", 0);
				br_pem_decoder_setdest(&self->decoder, pem_callback, self);
				break;
			}
			case BR_PEM_END_OBJ: {
				if (self->buffer) {
					ENTER;
					SAVETMPS;
					PUSHMARK(SP);
					mXPUSHs(self->name);
					mXPUSHs(self->buffer);
					PUTBACK;
					call_sv(self->callback, G_VOID | G_DISCARD);
					SPAGAIN;
					FREETMPS;
					LEAVE;
					self->name = NULL;
					self->buffer = NULL;
				}
				break;
			}
			case BR_PEM_ERROR: {
				if (self->buffer) {
					SvREFCNT_dec(self->buffer);
					self->buffer = NULL;
				}
				Perl_croak(aTHX_ "Could not parse PEM");
				break;
			}
		}
	}

bool br_pem_decoder_entry_in_progress(Crypt::Bear::PEM::Decoder self)
CODE:
	RETVAL = self->buffer != NULL;
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::Certificate PREFIX = br_x509_certificate_

Crypt::Bear::X509::Certificate br_x509_certificate_new(class, const unsigned char* data, size_t length(data))
CODE:
	RETVAL = safemalloc(sizeof(struct certificate));

	SV* dn = sv_2mortal(newSVpvn("", 0));
	struct decoder_helper helper = {
#ifdef MULTIPLICITY
		.aTHX = aTHX,
#endif
		.value = dn,
	};
	br_x509_decoder_init(&RETVAL->decoder, dn_decoder, &helper);
	br_x509_decoder_push(&RETVAL->decoder, data, STRLEN_length_of_data);

	br_error_type error = br_x509_decoder_last_error(&RETVAL->decoder);
	if (error != 0) {
		Safefree(RETVAL);
		Perl_croak(aTHX_ "Could not decode certificate: %s", lookup_error(error));
	}

	RETVAL->dn.data = (unsigned char*)savesvpv(dn);
	RETVAL->dn.len = SvCUR(dn);

	br_x509_certificate_init(&RETVAL->cert, data, STRLEN_length_of_data);
OUTPUT:
	RETVAL

SV* br_x509_certificate_dn(Crypt::Bear::X509::Certificate self)

SV* br_x509_certificate_public_key(Crypt::Bear::X509::Certificate self)
CODE:
	br_x509_pkey* result = br_x509_decoder_get_pkey(&self->decoder);
	RETVAL = x509_key_unpack(result);
OUTPUT:
	RETVAL

bool br_x509_certificate_is_ca(Crypt::Bear::X509::Certificate self)

key_kind_type br_x509_certificate_signer_key_type(Crypt::Bear::X509::Certificate self)



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::PrivateKey PREFIX = br_x509_private_key_

Crypt::Bear::X509::PrivateKey br_x509_private_key_new(class, const char* data, size_t length(data))
CODE:
	br_skey_decoder_context context;
	br_skey_decoder_init(&context);
	br_skey_decoder_push(&context, data, STRLEN_length_of_data);

	br_error_type error = br_skey_decoder_last_error(&context);
	if (error != 0)
		Perl_croak(aTHX_ "Could not decode private key: %s", lookup_error(error));

	RETVAL = safemalloc(sizeof *RETVAL);

	RETVAL->key_type = br_skey_decoder_key_type(&context);
	if (RETVAL->key_type == BR_KEYTYPE_RSA) {
		rsa_private_key_copy(&RETVAL->rsa, br_skey_decoder_get_rsa(&context));
	} else if (RETVAL->key_type == BR_KEYTYPE_EC) {
		ec_private_key_copy(&RETVAL->ec, br_skey_decoder_get_ec(&context));
	}
OUTPUT:
	RETVAL


SV* br_x509_private_key_unpack(Crypt::Bear::X509::PrivateKey self)
CODE:
	RETVAL = &PL_sv_undef;
	if (self->key_type == BR_KEYTYPE_RSA) {
		br_rsa_private_key* key = safemalloc(sizeof *key);
		rsa_private_key_copy(key, &self->rsa);
		RETVAL = make_magic(key, "Crypt::Bear::RSA::PrivateKey", &Crypt__Bear__RSA__PrivateKey_magic);
	} else if (self->key_type == BR_KEYTYPE_EC) {
		br_ec_private_key* key = safemalloc(sizeof *key);
		ec_private_key_copy(key, &self->ec);
		RETVAL = make_magic(key, "Crypt::Bear::EC::PrivateKey", &Crypt__Bear__EC__PrivateKey_magic);
	}
OUTPUT:
	RETVAL


key_kind_type br_x509_private_key_type(Crypt::Bear::X509::PrivateKey self)
CODE:
	RETVAL = self->key_type;
OUTPUT:
	RETVAL



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::TrustAnchors PREFIX = br_x509_trust_anchors_

Crypt::Bear::X509::TrustAnchors br_x509_trust_anchors_new(class)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	trust_anchors_init(RETVAL);
OUTPUT:
	RETVAL

void br_x509_trust_anchors_add(Crypt::Bear::X509::TrustAnchors self, Crypt::Bear::X509::Certificate certificate, bool is_ca = br_x509_decoder_isCA(&certificate->decoder))
CODE:
	br_x509_trust_anchor anchor = { .flags = is_ca ? BR_X509_TA_CA : 0};
	dn_copy(&anchor.dn, &certificate->dn);
	x509_key_copy(&anchor.pkey, br_x509_decoder_get_pkey(&certificate->decoder));
	trust_anchors_push(self, &anchor);

void br_x509_trust_anchors_merge(Crypt::Bear::X509::TrustAnchors self, Crypt::Bear::X509::TrustAnchors other)
CODE:
	for (size_t i = 0; i < other->used; i++) {
		const br_x509_trust_anchor* old = other->array + i;
		br_x509_trust_anchor anchor = { .flags = old->flags };
		dn_copy(&anchor.dn, &old->dn);
		x509_key_copy(&anchor.pkey, &old->pkey);
		trust_anchors_push(self, &anchor);
	}

void br_x509_trust_anchors_names(Crypt::Bear::X509::TrustAnchors self)
PPCODE:
	for (size_t i = 0; i < self->used; i++) {
		const br_x509_trust_anchor* anchor = self->array + i;
		mXPUSHp((const char*)anchor->dn.data, anchor->dn.len);
	}

UV br_x509_trust_anchors_count(Crypt::Bear::X509::TrustAnchors self)
CODE:
	RETVAL = self->used;
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::Validator PREFIX = br_x509_validator_

void start_chain(Crypt::Bear::X509::Validator self, const char* server_name)
CODE:
	((*self)->start_chain)(self, server_name);

void start_certificate(Crypt::Bear::X509::Validator self, size_t length)
CODE:
	((*self)->start_cert)(self, length);

void append(Crypt::Bear::X509::Validator self, const unsigned char* data, size_t length(data))
CODE:
	((*self)->append)(self, data, STRLEN_length_of_data);

void end_certificate(Crypt::Bear::X509::Validator self)
CODE:
	((*self)->end_cert)(self);

void end_chain(Crypt::Bear::X509::Validator self)
CODE:
	((*self)->end_chain)(self);

SV* get_pkey(Crypt::Bear::X509::Validator self, unsigned wanted_usage)
CODE:
	unsigned usage;
	const br_x509_pkey* public_key = ((*self)->get_pkey)(self, &usage);

	if (wanted_usage && (usage & wanted_usage) != wanted_usage)
		RETVAL = &PL_sv_undef;
	else if (public_key)
		RETVAL = x509_key_unpack(public_key);
	else
		RETVAL = &PL_sv_undef;
OUTPUT:
	RETVAL

MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::Validator::Minimal PREFIX = br_x509_minimal_
BOOT:
	push_isa(Crypt::Bear::X509::Validator::Minimal, Crypt::Bear::X509::Validator);

Crypt::Bear::X509::Validator::Minimal br_x509_minimal_new(SV* class, Crypt::Bear::X509::TrustAnchors anchors)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	trust_anchors_copy(&RETVAL->anchors, anchors);
	br_x509_minimal_init_full(&RETVAL->context, RETVAL->anchors.array, RETVAL->anchors.used);
OUTPUT:
	RETVAL

#if 0
void br_x509_minimal_set_time(Crypt::Bear::X509::Validator::Minimal self, UV days, UV seconds)

void br_x509_minimal_set_minrsa(Crypt::Bear::X509::Validator::Minimal self, UV size)
#endif


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::Validator::KnownKey PREFIX = br_x509_knownkey_
BOOT:
	push_isa(Crypt::Bear::X509::Validator::KnownKey, Crypt::Bear::X509::Validator);
 


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::SSL



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::SSL::Session PREFIX = br_ssl_session_



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::X509::Certificate::Chain PREFIX = br_x509_certificate_chain_

Crypt::Bear::X509::Certificate::Chain br_x509_certificate_chain_new(class)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	certificate_chain_init(RETVAL);
OUTPUT:
	RETVAL

void br_x509_certificate_chain_add(Crypt::Bear::X509::Certificate::Chain self, Crypt::Bear::X509::Certificate certificate)
CODE:
	br_x509_certificate entry;
	br_x509_certificate_copy(&entry, &certificate->cert);
	certificate_chain_push(self, &entry);
	if (self->used == 1)
		self->signer_key_type = br_x509_decoder_get_signer_key_type(&certificate->decoder);


UV br_x509_certificate_chain_count(Crypt::Bear::X509::Certificate::Chain self)
CODE:
	RETVAL = self->used;
OUTPUT:
	RETVAL



MODULE = Crypt::Bear PACKAGE = Crypt::Bear::SSL::PrivateCertificate PREFIX = br_ssl_private_certificate_

Crypt::Bear::SSL::PrivateCertificate br_ssl_private_certificate_new(class, Crypt::Bear::X509::Certificate::Chain certs, Crypt::Bear::X509::PrivateKey key, usage_type usage = automatic)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	certificate_chain_copy(&RETVAL->chain, certs);
	private_key_copy(&RETVAL->key, key);
	RETVAL->usage = usage;
OUTPUT:
	RETVAL

Crypt::Bear::X509::Certificate::Chain br_ssl_private_certificate_chain(Crypt::Bear::SSL::PrivateCertificate self)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	certificate_chain_copy(RETVAL, &self->chain);
OUTPUT:
	RETVAL

Crypt::Bear::X509::PrivateKey br_ssl_private_certificate_key(Crypt::Bear::SSL::PrivateCertificate self)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	private_key_copy(RETVAL, &self->key);
OUTPUT:
	RETVAL


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::SSL::Engine PREFIX = br_ssl_engine_

const char* br_ssl_engine_get_server_name(Crypt::Bear::SSL::Engine self)

ssl_version_type br_ssl_engine_get_version(Crypt::Bear::SSL::Engine self)

void br_ssl_engine_set_versions(Crypt::Bear::SSL::Engine self, ssl_version_type min, ssl_version_type max)

curve_type br_ssl_engine_get_ecdhe_curve(Crypt::Bear::SSL::Engine self)

br_error_type br_ssl_engine_last_error(Crypt::Bear::SSL::Engine self)

void br_ssl_engine_inject_entropy(Crypt::Bear::SSL::Engine self, const char* data, size_t length(data))

Crypt::Bear::SSL::Session br_ssl_engine_get_session_parameters(Crypt::Bear::SSL::Engine self)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	br_ssl_engine_get_session_parameters(self, RETVAL);
OUTPUT:
	RETVAL

void br_ssl_engine_set_session_parameters(Crypt::Bear::SSL::Engine self, Crypt::Bear::SSL::Session pp)

bool br_ssl_engine_is_closed(Crypt::Bear::SSL::Engine self)
CODE:
	RETVAL = br_ssl_engine_current_state(self) == BR_SSL_CLOSED;
OUTPUT:
	RETVAL

bool br_ssl_engine_send_ready(Crypt::Bear::SSL::Engine self)
CODE:
	RETVAL = cBOOL(br_ssl_engine_current_state(self) & BR_SSL_SENDAPP);
OUTPUT:
	RETVAL

SV* br_ssl_engine_push_received(Crypt::Bear::SSL::Engine self, unsigned char* data, size_t length(data))
CODE:
	RETVAL = newSVpvn("", 0);
	size_t offset = 0;

	while (br_ssl_engine_current_state(self) & BR_SSL_RECVAPP) {
		size_t len = 0;
		unsigned char* buffer = br_ssl_engine_recvapp_buf(self, &len);

		sv_catpvn(RETVAL, (const char*)buffer, len);
		br_ssl_engine_recvapp_ack(self, len);
	}

	do {
		if (br_ssl_engine_current_state(self) == BR_SSL_CLOSED)
			Perl_croak(aTHX_ "Connection is closed");

		size_t len = 0;
		unsigned char* buffer = br_ssl_engine_recvrec_buf(self, &len);

		if (len) {
			size_t available = STRLEN_length_of_data - offset;

			if (len > available)
				len = available;

			memcpy(buffer, data + offset, len);
			offset += len;
			br_ssl_engine_recvrec_ack(self, len);
		}

		while (br_ssl_engine_current_state(self) & BR_SSL_RECVAPP) {
			size_t len = 0;
			unsigned char* buffer = br_ssl_engine_recvapp_buf(self, &len);

			sv_catpvn(RETVAL, (const char*)buffer, len);
			br_ssl_engine_recvapp_ack(self, len);
		}
	} while (offset < STRLEN_length_of_data);
OUTPUT:
	RETVAL

SV* br_ssl_engine_push_send(Crypt::Bear::SSL::Engine self, unsigned char* data, size_t length(data), bool flush = FALSE)
CODE:
	RETVAL = newSVpvn("", 0);
	size_t offset = 0;

	do {
		while (br_ssl_engine_current_state(self) & BR_SSL_SENDREC) {
			size_t len = 0;
			unsigned char* buffer = br_ssl_engine_sendrec_buf(self, &len);

			sv_catpvn(RETVAL, (const char*)buffer, len);
			br_ssl_engine_sendrec_ack(self, len);
		}

		if (br_ssl_engine_current_state(self) == BR_SSL_CLOSED)
			Perl_croak(aTHX_ "Connection is closed");

		size_t len = 0;
		unsigned char* buffer = br_ssl_engine_sendapp_buf(self, &len);

		if (len && STRLEN_length_of_data) {
			size_t available = STRLEN_length_of_data - offset;

			if (len > available)
				len = available;

			memcpy(buffer, data + offset, len);
			offset += len;
			br_ssl_engine_sendapp_ack(self, len);
		}
	} while (offset < STRLEN_length_of_data);

	if (flush)
		br_ssl_engine_flush(self, FALSE);

	while (br_ssl_engine_current_state(self) & BR_SSL_SENDREC) {
		size_t len = 0;
		unsigned char* buffer = br_ssl_engine_sendrec_buf(self, &len);

		sv_catpvn(RETVAL, (const char*)buffer, len);
		br_ssl_engine_sendrec_ack(self, len);
	}
OUTPUT:
	RETVAL

SV* br_ssl_engine_pull_send(Crypt::Bear::SSL::Engine self, bool force = FALSE)
CODE:
	RETVAL = newSVpvn("", 0);

	br_ssl_engine_flush(self, force);

	while (br_ssl_engine_current_state(self) & BR_SSL_SENDREC) {
		size_t len = 0;
		unsigned char* buffer = br_ssl_engine_sendrec_buf(self, &len);

		sv_catpvn(RETVAL, (const char*)buffer, len);
		br_ssl_engine_sendrec_ack(self, len);
	}
OUTPUT:
	RETVAL


void br_ssl_engine_close(Crypt::Bear::SSL::Engine self)


MODULE = Crypt::Bear	PACKAGE = Crypt::Bear::SSL::Client PREFIX = br_ssl_client_
BOOT:
	push_isa(Crypt::Bear::SSL::Client, Crypt::Bear::SSL::Engine);

Crypt::Bear::SSL::Client br_ssl_client_new(class, Crypt::Bear::X509::TrustAnchors anchors)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	trust_anchors_copy(&RETVAL->trust_anchors, anchors);
	br_ssl_client_init_full(&RETVAL->context, &RETVAL->minimal, RETVAL->trust_anchors.array, RETVAL->trust_anchors.used);
	br_ssl_engine_set_buffer(&RETVAL->context.eng, RETVAL->buffer, sizeof RETVAL->buffer, true);
	private_certificate_init(&RETVAL->private);
OUTPUT:
	RETVAL

bool br_ssl_client_reset(Crypt::Bear::SSL::Client self, SV* server_name, bool resume_session = FALSE);
CODE:
	if (SvOK(server_name))
		RETVAL = br_ssl_client_reset(&self->context, SvPV_nolen(server_name), resume_session);
	else
		RETVAL = br_ssl_client_reset(&self->context, NULL, resume_session);
OUTPUT:
	RETVAL


void br_ssl_client_set_client_certificate(Crypt::Bear::SSL::Client self, Crypt::Bear::SSL::PrivateCertificate priv_cert)
CODE:
	private_certificate_copy(&self->private, priv_cert);

	if (priv_cert->key.key_type == BR_KEYTYPE_RSA) {
		br_ssl_client_set_single_rsa(&self->context, self->private.chain.array, self->private.chain.used, &self->private.key.rsa, rsa_pkcs1_sign);
	} else if (priv_cert->key.key_type == BR_KEYTYPE_EC) {
		br_ssl_client_set_single_ec(&self->context, self->private.chain.array, self->private.chain.used, &self->private.key.ec, self->private.usage, priv_cert->chain.signer_key_type, ec_default, ec_sign_default);
	} else {
		Perl_croak(aTHX_ "Invalid private key");
	}

void br_ssl_client_forget_session(Crypt::Bear::SSL::Client self)
CODE:
	br_ssl_client_forget_session(&self->context);


MODULE = Crypt::Bear PACKAGE = Crypt::Bear::SSL::Server PREFIX = br_ssl_server_
BOOT:
	push_isa(Crypt::Bear::SSL::Server, Crypt::Bear::SSL::Engine);

Crypt::Bear::SSL::Server br_ssl_server_new(class, Crypt::Bear::SSL::PrivateCertificate priv_cert)
CODE:
	RETVAL = safemalloc(sizeof *RETVAL);
	private_certificate_copy(&RETVAL->private, priv_cert);

	if (priv_cert->key.key_type == BR_KEYTYPE_RSA) {
		br_ssl_server_init_full_rsa(&RETVAL->context, RETVAL->private.chain.array, RETVAL->private.chain.used, &RETVAL->private.key.rsa);
	} else if (priv_cert->key.key_type == BR_KEYTYPE_EC) {
		br_ssl_server_init_full_ec(&RETVAL->context, RETVAL->private.chain.array, RETVAL->private.chain.used, priv_cert->chain.signer_key_type, &RETVAL->private.key.ec);
	} else {
		Safefree(RETVAL);
		Perl_croak(aTHX_ "Invalid private key");
	}
	br_ssl_engine_set_buffer(&RETVAL->context.eng, RETVAL->buffer, BR_SSL_BUFSIZE_BIDI, true);

	unsigned error = br_ssl_engine_last_error(&RETVAL->context.eng);
	if (error) {
		Safefree(RETVAL);
		Perl_croak(aTHX_ "Could not instantiate server: %s", lookup_error(error));
	}
OUTPUT:
	RETVAL

void br_ssl_server_get_client_suites(Crypt::Bear::SSL::Server self)
PPCODE:
	size_t len;	
	const br_suite_translated* suites = br_ssl_server_get_client_suites(&self->context, &len);
	for (size_t i = 0; i < len; i++) {
		AV* pair = newAV();
		av_push(pair, newSVuv(suites[i][0]));
		av_push(pair, newSVuv(suites[i][1]));
		mXPUSHs(newRV_noinc((SV*)pair));
	}


bool br_ssl_server_reset(Crypt::Bear::SSL::Server self);
CODE:
	RETVAL = br_ssl_server_reset(&self->context);
OUTPUT:
	RETVAL

