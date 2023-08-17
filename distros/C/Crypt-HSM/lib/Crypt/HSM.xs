#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_mg_findext
#include "ppport.h"

#include "cryptoki.h"
#include "refcount.h"

#ifdef WIN32
#define dlopen(file, flags) ((void*)win32_dynaload(file))
#define dlsym(handle, symbol) ((void*)GetProcAddress((HINSTANCE)handle, symbol))
#define dlclose(handle) (FreeLibrary((HMODULE)handle))
#else
#include "dlfcn.h"
#endif

typedef struct { const char* key; size_t length; CK_ULONG value; } entry;
typedef entry map[];

static const entry* S_map_find(pTHX_ const map table, size_t table_size, const char* name, size_t name_length) {
	size_t i;
	for (i = 0; i < table_size; ++i) {
		if (table[i].length == name_length && strEQ(name, table[i].key))
			return &table[i];
	}
	return NULL;
}
#define map_find(table, table_size, name, name_len) S_map_find(aTHX_ table, table_size, name, name_len)

static CK_ULONG S_map_get(pTHX_ const map table, size_t table_size, SV* input, const char* type) {
	STRLEN name_length;
	const char* name = SvPVutf8(input, name_length);
	const entry* item = map_find(table, table_size, name, name_length);
	if (item == NULL)
		Perl_croak(aTHX_ "No such %s '%s'", type, name);
	return item->value;
}
#define map_get(table, name, type) S_map_get(aTHX_ table, sizeof table / sizeof *table, name, type)

static const entry* S_map_reverse_find(pTHX_ const map table, size_t table_size, UV value) {
	size_t i;
	for (i = 0; i < table_size; ++i) {
		if (table[i].value == value)
			return &table[i];
	}
	return NULL;
}
#define map_reverse_find(table, value) S_map_reverse_find(aTHX_ table, sizeof table / sizeof *table, value)

static const map errors = {
	{ STR_WITH_LEN("ok"), CKR_OK },
	{ STR_WITH_LEN("cancel"), CKR_CANCEL },
	{ STR_WITH_LEN("host memory"), CKR_HOST_MEMORY },
	{ STR_WITH_LEN("slot id invalid"), CKR_SLOT_ID_INVALID },
	{ STR_WITH_LEN("general error"), CKR_GENERAL_ERROR },
	{ STR_WITH_LEN("function failed"), CKR_FUNCTION_FAILED },
	{ STR_WITH_LEN("arguments bad"), CKR_ARGUMENTS_BAD },
	{ STR_WITH_LEN("no event"), CKR_NO_EVENT },
	{ STR_WITH_LEN("need to create threads"), CKR_NEED_TO_CREATE_THREADS },
	{ STR_WITH_LEN("cant lock"), CKR_CANT_LOCK },
	{ STR_WITH_LEN("attribute read only"), CKR_ATTRIBUTE_READ_ONLY },
	{ STR_WITH_LEN("attribute sensitive"), CKR_ATTRIBUTE_SENSITIVE },
	{ STR_WITH_LEN("attribute type invalid"), CKR_ATTRIBUTE_TYPE_INVALID },
	{ STR_WITH_LEN("attribute value invalid"), CKR_ATTRIBUTE_VALUE_INVALID },
	{ STR_WITH_LEN("action prohibited"), CKR_ACTION_PROHIBITED },
	{ STR_WITH_LEN("data invalid"), CKR_DATA_INVALID },
	{ STR_WITH_LEN("data len range"), CKR_DATA_LEN_RANGE },
	{ STR_WITH_LEN("device error"), CKR_DEVICE_ERROR },
	{ STR_WITH_LEN("device memory"), CKR_DEVICE_MEMORY },
	{ STR_WITH_LEN("device removed"), CKR_DEVICE_REMOVED },
	{ STR_WITH_LEN("encrypted data invalid"), CKR_ENCRYPTED_DATA_INVALID },
	{ STR_WITH_LEN("encrypted data len range"), CKR_ENCRYPTED_DATA_LEN_RANGE },
	{ STR_WITH_LEN("aead decrypt failed"), CKR_AEAD_DECRYPT_FAILED },
	{ STR_WITH_LEN("function canceled"), CKR_FUNCTION_CANCELED },
	{ STR_WITH_LEN("function not parallel"), CKR_FUNCTION_NOT_PARALLEL },
	{ STR_WITH_LEN("function not supported"), CKR_FUNCTION_NOT_SUPPORTED },
	{ STR_WITH_LEN("key handle invalid"), CKR_KEY_HANDLE_INVALID },
	{ STR_WITH_LEN("key size range"), CKR_KEY_SIZE_RANGE },
	{ STR_WITH_LEN("key type inconsistent"), CKR_KEY_TYPE_INCONSISTENT },
	{ STR_WITH_LEN("key not needed"), CKR_KEY_NOT_NEEDED },
	{ STR_WITH_LEN("key changed"), CKR_KEY_CHANGED },
	{ STR_WITH_LEN("key needed"), CKR_KEY_NEEDED },
	{ STR_WITH_LEN("key indigestible"), CKR_KEY_INDIGESTIBLE },
	{ STR_WITH_LEN("key function not permitted"), CKR_KEY_FUNCTION_NOT_PERMITTED },
	{ STR_WITH_LEN("key not wrappable"), CKR_KEY_NOT_WRAPPABLE },
	{ STR_WITH_LEN("key unextractable"), CKR_KEY_UNEXTRACTABLE },
	{ STR_WITH_LEN("mechanism invalid"), CKR_MECHANISM_INVALID },
	{ STR_WITH_LEN("mechanism param invalid"), CKR_MECHANISM_PARAM_INVALID },
	{ STR_WITH_LEN("object handle invalid"), CKR_OBJECT_HANDLE_INVALID },
	{ STR_WITH_LEN("operation active"), CKR_OPERATION_ACTIVE },
	{ STR_WITH_LEN("operation not initialized"), CKR_OPERATION_NOT_INITIALIZED },
	{ STR_WITH_LEN("pin incorrect"), CKR_PIN_INCORRECT },
	{ STR_WITH_LEN("pin invalid"), CKR_PIN_INVALID },
	{ STR_WITH_LEN("pin len range"), CKR_PIN_LEN_RANGE },
	{ STR_WITH_LEN("pin expired"), CKR_PIN_EXPIRED },
	{ STR_WITH_LEN("pin locked"), CKR_PIN_LOCKED },
	{ STR_WITH_LEN("session closed"), CKR_SESSION_CLOSED },
	{ STR_WITH_LEN("session count"), CKR_SESSION_COUNT },
	{ STR_WITH_LEN("session handle invalid"), CKR_SESSION_HANDLE_INVALID },
	{ STR_WITH_LEN("session parallel not supported"), CKR_SESSION_PARALLEL_NOT_SUPPORTED },
	{ STR_WITH_LEN("session read only"), CKR_SESSION_READ_ONLY },
	{ STR_WITH_LEN("session exists"), CKR_SESSION_EXISTS },
	{ STR_WITH_LEN("session read only exists"), CKR_SESSION_READ_ONLY_EXISTS },
	{ STR_WITH_LEN("session read write so exists"), CKR_SESSION_READ_WRITE_SO_EXISTS },
	{ STR_WITH_LEN("signature invalid"), CKR_SIGNATURE_INVALID },
	{ STR_WITH_LEN("signature len range"), CKR_SIGNATURE_LEN_RANGE },
	{ STR_WITH_LEN("template incomplete"), CKR_TEMPLATE_INCOMPLETE },
	{ STR_WITH_LEN("template inconsistent"), CKR_TEMPLATE_INCONSISTENT },
	{ STR_WITH_LEN("token not present"), CKR_TOKEN_NOT_PRESENT },
	{ STR_WITH_LEN("token not recognized"), CKR_TOKEN_NOT_RECOGNIZED },
	{ STR_WITH_LEN("token write protected"), CKR_TOKEN_WRITE_PROTECTED },
	{ STR_WITH_LEN("unwrapping key handle invalid"), CKR_UNWRAPPING_KEY_HANDLE_INVALID },
	{ STR_WITH_LEN("unwrapping key size range"), CKR_UNWRAPPING_KEY_SIZE_RANGE },
	{ STR_WITH_LEN("unwrapping key type inconsistent"), CKR_UNWRAPPING_KEY_TYPE_INCONSISTENT },
	{ STR_WITH_LEN("user already logged in"), CKR_USER_ALREADY_LOGGED_IN },
	{ STR_WITH_LEN("user not logged in"), CKR_USER_NOT_LOGGED_IN },
	{ STR_WITH_LEN("user pin not initialized"), CKR_USER_PIN_NOT_INITIALIZED },
	{ STR_WITH_LEN("user type invalid"), CKR_USER_TYPE_INVALID },
	{ STR_WITH_LEN("user another already logged in"), CKR_USER_ANOTHER_ALREADY_LOGGED_IN },
	{ STR_WITH_LEN("user too many types"), CKR_USER_TOO_MANY_TYPES },
	{ STR_WITH_LEN("wrapped key invalid"), CKR_WRAPPED_KEY_INVALID },
	{ STR_WITH_LEN("wrapped key len range"), CKR_WRAPPED_KEY_LEN_RANGE },
	{ STR_WITH_LEN("wrapping key handle invalid"), CKR_WRAPPING_KEY_HANDLE_INVALID },
	{ STR_WITH_LEN("wrapping key size range"), CKR_WRAPPING_KEY_SIZE_RANGE },
	{ STR_WITH_LEN("wrapping key type inconsistent"), CKR_WRAPPING_KEY_TYPE_INCONSISTENT },
	{ STR_WITH_LEN("random seed not supported"), CKR_RANDOM_SEED_NOT_SUPPORTED },
	{ STR_WITH_LEN("random no rng"), CKR_RANDOM_NO_RNG },
	{ STR_WITH_LEN("domain params invalid"), CKR_DOMAIN_PARAMS_INVALID },
	{ STR_WITH_LEN("curve not supported"), CKR_CURVE_NOT_SUPPORTED },
	{ STR_WITH_LEN("buffer too small"), CKR_BUFFER_TOO_SMALL },
	{ STR_WITH_LEN("saved state invalid"), CKR_SAVED_STATE_INVALID },
	{ STR_WITH_LEN("information sensitive"), CKR_INFORMATION_SENSITIVE },
	{ STR_WITH_LEN("state unsaveable"), CKR_STATE_UNSAVEABLE },
	{ STR_WITH_LEN("cryptoki not initialized"), CKR_CRYPTOKI_NOT_INITIALIZED },
	{ STR_WITH_LEN("cryptoki already initialized"), CKR_CRYPTOKI_ALREADY_INITIALIZED },
	{ STR_WITH_LEN("mutex bad"), CKR_MUTEX_BAD },
	{ STR_WITH_LEN("mutex not locked"), CKR_MUTEX_NOT_LOCKED },
	{ STR_WITH_LEN("new pin mode"), CKR_NEW_PIN_MODE },
	{ STR_WITH_LEN("next otp"), CKR_NEXT_OTP },
	{ STR_WITH_LEN("exceeded max iterations"), CKR_EXCEEDED_MAX_ITERATIONS },
	{ STR_WITH_LEN("fips self test failed"), CKR_FIPS_SELF_TEST_FAILED },
	{ STR_WITH_LEN("library load failed"), CKR_LIBRARY_LOAD_FAILED },
	{ STR_WITH_LEN("pin too weak"), CKR_PIN_TOO_WEAK },
	{ STR_WITH_LEN("public key invalid"), CKR_PUBLIC_KEY_INVALID },
	{ STR_WITH_LEN("function rejected"), CKR_FUNCTION_REJECTED },
	{ STR_WITH_LEN("token resource exceeded"), CKR_TOKEN_RESOURCE_EXCEEDED },
	{ STR_WITH_LEN("operation cancel failed"), CKR_OPERATION_CANCEL_FAILED },
	{ STR_WITH_LEN("key exhausted"), CKR_KEY_EXHAUSTED },
	{ STR_WITH_LEN("vendor defined"), CKR_VENDOR_DEFINED },
};

static void S_croak_with(pTHX_ const char* message, CK_RV result) {
	const entry* item = map_reverse_find(errors, result);
	const char* reason = item ? item->key : "unknown";
	Perl_croak(aTHX_ "%s: %s", message, reason);
}
#define croak_with(message, result) S_croak_with(aTHX_ message, result)

static const map slot_flags = {
	{ STR_WITH_LEN("token-present"), CKF_TOKEN_PRESENT },
	{ STR_WITH_LEN("removable-device"), CKF_REMOVABLE_DEVICE },
	{ STR_WITH_LEN("hw-slot"), CKF_HW_SLOT },
};

static const map token_flags = {
	{ STR_WITH_LEN("rng"), CKF_RNG },
	{ STR_WITH_LEN("write-protected"), CKF_WRITE_PROTECTED },
	{ STR_WITH_LEN("login-required"), CKF_LOGIN_REQUIRED },
	{ STR_WITH_LEN("user-pin-initialized"), CKF_USER_PIN_INITIALIZED },
	{ STR_WITH_LEN("restore-key-not-needed"), CKF_RESTORE_KEY_NOT_NEEDED },
	{ STR_WITH_LEN("clock-on-token"), CKF_CLOCK_ON_TOKEN },
	{ STR_WITH_LEN("protected-authentication-path"), CKF_PROTECTED_AUTHENTICATION_PATH },
	{ STR_WITH_LEN("dual-crypto-operations"), CKF_DUAL_CRYPTO_OPERATIONS },
	{ STR_WITH_LEN("token-initialized"), CKF_TOKEN_INITIALIZED },
	{ STR_WITH_LEN("secondary-authentication"), CKF_SECONDARY_AUTHENTICATION },
	{ STR_WITH_LEN("user-pin-count-low"), CKF_USER_PIN_COUNT_LOW },
	{ STR_WITH_LEN("user-pin-final-try"), CKF_USER_PIN_FINAL_TRY },
	{ STR_WITH_LEN("user-pin-locked"), CKF_USER_PIN_LOCKED },
	{ STR_WITH_LEN("user-pin-to-be-changed"), CKF_USER_PIN_TO_BE_CHANGED },
	{ STR_WITH_LEN("so-pin-count-low"), CKF_SO_PIN_COUNT_LOW },
	{ STR_WITH_LEN("so-pin-final-try"), CKF_SO_PIN_FINAL_TRY },
	{ STR_WITH_LEN("so-pin-locked"), CKF_SO_PIN_LOCKED },
	{ STR_WITH_LEN("so-pin-to-be-changed"), CKF_SO_PIN_TO_BE_CHANGED },
	{ STR_WITH_LEN("error-state"), CKF_ERROR_STATE },
};

static const map session_flags = {
	{ STR_WITH_LEN("rw-session"), CKF_RW_SESSION },
	{ STR_WITH_LEN("serial-session"), CKF_SERIAL_SESSION },
};
typedef CK_FLAGS Session_flags;

static const map mechanism_flags = {
	{ STR_WITH_LEN("hw"), CKF_HW },
	{ STR_WITH_LEN("message-encrypt"), CKF_MESSAGE_ENCRYPT },
	{ STR_WITH_LEN("message-decrypt"), CKF_MESSAGE_DECRYPT },
	{ STR_WITH_LEN("message-sign"), CKF_MESSAGE_SIGN },
	{ STR_WITH_LEN("message-verify"), CKF_MESSAGE_VERIFY },
	{ STR_WITH_LEN("multi-message"), CKF_MULTI_MESSAGE },
	{ STR_WITH_LEN("multi-messge"), CKF_MULTI_MESSGE },
	{ STR_WITH_LEN("find-objects"), CKF_FIND_OBJECTS },
	{ STR_WITH_LEN("encrypt"), CKF_ENCRYPT },
	{ STR_WITH_LEN("decrypt"), CKF_DECRYPT },
	{ STR_WITH_LEN("digest"), CKF_DIGEST },
	{ STR_WITH_LEN("sign"), CKF_SIGN },
	{ STR_WITH_LEN("sign-recover"), CKF_SIGN_RECOVER },
	{ STR_WITH_LEN("verify"), CKF_VERIFY },
	{ STR_WITH_LEN("verify-recover"), CKF_VERIFY_RECOVER },
	{ STR_WITH_LEN("generate"), CKF_GENERATE },
	{ STR_WITH_LEN("generate-key-pair"), CKF_GENERATE_KEY_PAIR },
	{ STR_WITH_LEN("wrap"), CKF_WRAP },
	{ STR_WITH_LEN("unwrap"), CKF_UNWRAP },
	{ STR_WITH_LEN("derive"), CKF_DERIVE },
	{ STR_WITH_LEN("ec-f-p"), CKF_EC_F_P },
	{ STR_WITH_LEN("ec-f-2m"), CKF_EC_F_2M },
	{ STR_WITH_LEN("ec-ecparameters"), CKF_EC_ECPARAMETERS },
	{ STR_WITH_LEN("ec-oid"), CKF_EC_OID },
	{ STR_WITH_LEN("ec-namedcurve"), CKF_EC_NAMEDCURVE },
	{ STR_WITH_LEN("ec-uncompress"), CKF_EC_UNCOMPRESS },
	{ STR_WITH_LEN("ec-compress"), CKF_EC_COMPRESS },
	{ STR_WITH_LEN("ec-curvename"), CKF_EC_CURVENAME },
	{ STR_WITH_LEN("extension"), CKF_EXTENSION },
};

static const map state_flags = {
	{ STR_WITH_LEN("ro-public-session"), CKS_RO_PUBLIC_SESSION },
	{ STR_WITH_LEN("ro-user-functions"), CKS_RO_USER_FUNCTIONS },
	{ STR_WITH_LEN("rw-public-session"), CKS_RW_PUBLIC_SESSION },
	{ STR_WITH_LEN("rw-user-functions"), CKS_RW_USER_FUNCTIONS },
	{ STR_WITH_LEN("rw-so-functions"), CKS_RW_SO_FUNCTIONS },
};


static UV S_get_flags(pTHX_ const map table, size_t table_size, SV* input) {
	if (SvROK(input) && SvTYPE(SvRV(input)) == SVt_PVAV) {
		UV result = 0, i;
		AV* array = (AV*)SvRV(input);
		for (i = 0; i < av_count(array); ++i) {
			SV** svp = av_fetch(array, i, FALSE);
			result |= S_map_get(aTHX_ table, table_size, *svp, "flag");
		}
		return result;
	}
	else {
		return S_map_get(aTHX_ table, table_size, input, "flag");
	}
}
#define get_flags(table, input) S_get_flags(aTHX_ table, sizeof table / sizeof *table, input)

static AV* S_reverse_flags(pTHX_ const map table, size_t table_size, CK_ULONG input) {
	AV* result = newAV();
	CK_ULONG i;
	for (i = 0; i < CHAR_BIT * sizeof(CK_ULONG); ++i) {
		CK_ULONG right = 1ul << i;
		if (input & right) {
			const entry* item = S_map_reverse_find(aTHX_ table, table_size, right);
			if (item)
				av_push(result, newSVpvn(item->key, item->length));
			else
				av_push(result, newSVpvs("unknown"));
		}
	}
	return result;
}
#define reverse_flags(table, input) S_reverse_flags(aTHX_ table, sizeof table / sizeof *table, input)

static const map mechanisms = {
	{ STR_WITH_LEN("rsa-pkcs-key-pair-gen"), CKM_RSA_PKCS_KEY_PAIR_GEN },
	{ STR_WITH_LEN("rsa-pkcs"), CKM_RSA_PKCS },
	{ STR_WITH_LEN("rsa-9796"), CKM_RSA_9796 },
	{ STR_WITH_LEN("rsa-x-509"), CKM_RSA_X_509 },
	{ STR_WITH_LEN("md2-rsa-pkcs"), CKM_MD2_RSA_PKCS },
	{ STR_WITH_LEN("md5-rsa-pkcs"), CKM_MD5_RSA_PKCS },
	{ STR_WITH_LEN("sha1-rsa-pkcs"), CKM_SHA1_RSA_PKCS },
	{ STR_WITH_LEN("ripemd128-rsa-pkcs"), CKM_RIPEMD128_RSA_PKCS },
	{ STR_WITH_LEN("ripemd160-rsa-pkcs"), CKM_RIPEMD160_RSA_PKCS },
	{ STR_WITH_LEN("rsa-pkcs-oaep"), CKM_RSA_PKCS_OAEP },
	{ STR_WITH_LEN("rsa-x9-31-key-pair-gen"), CKM_RSA_X9_31_KEY_PAIR_GEN },
	{ STR_WITH_LEN("rsa-x9-31"), CKM_RSA_X9_31 },
	{ STR_WITH_LEN("sha1-rsa-x9-31"), CKM_SHA1_RSA_X9_31 },
	{ STR_WITH_LEN("rsa-pkcs-pss"), CKM_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha1-rsa-pkcs-pss"), CKM_SHA1_RSA_PKCS_PSS },
	{ STR_WITH_LEN("dsa-key-pair-gen"), CKM_DSA_KEY_PAIR_GEN },
	{ STR_WITH_LEN("dsa"), CKM_DSA },
	{ STR_WITH_LEN("dsa-sha1"), CKM_DSA_SHA1 },
	{ STR_WITH_LEN("dsa-sha224"), CKM_DSA_SHA224 },
	{ STR_WITH_LEN("dsa-sha256"), CKM_DSA_SHA256 },
	{ STR_WITH_LEN("dsa-sha384"), CKM_DSA_SHA384 },
	{ STR_WITH_LEN("dsa-sha512"), CKM_DSA_SHA512 },
	{ STR_WITH_LEN("dsa-sha3-224"), CKM_DSA_SHA3_224 },
	{ STR_WITH_LEN("dsa-sha3-256"), CKM_DSA_SHA3_256 },
	{ STR_WITH_LEN("dsa-sha3-384"), CKM_DSA_SHA3_384 },
	{ STR_WITH_LEN("dsa-sha3-512"), CKM_DSA_SHA3_512 },
	{ STR_WITH_LEN("dh-pkcs-key-pair-gen"), CKM_DH_PKCS_KEY_PAIR_GEN },
	{ STR_WITH_LEN("dh-pkcs-derive"), CKM_DH_PKCS_DERIVE },
	{ STR_WITH_LEN("x9-42-dh-key-pair-gen"), CKM_X9_42_DH_KEY_PAIR_GEN },
	{ STR_WITH_LEN("x9-42-dh-derive"), CKM_X9_42_DH_DERIVE },
	{ STR_WITH_LEN("x9-42-dh-hybrid-derive"), CKM_X9_42_DH_HYBRID_DERIVE },
	{ STR_WITH_LEN("x9-42-mqv-derive"), CKM_X9_42_MQV_DERIVE },
	{ STR_WITH_LEN("sha256-rsa-pkcs"), CKM_SHA256_RSA_PKCS },
	{ STR_WITH_LEN("sha384-rsa-pkcs"), CKM_SHA384_RSA_PKCS },
	{ STR_WITH_LEN("sha512-rsa-pkcs"), CKM_SHA512_RSA_PKCS },
	{ STR_WITH_LEN("sha256-rsa-pkcs-pss"), CKM_SHA256_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha384-rsa-pkcs-pss"), CKM_SHA384_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha512-rsa-pkcs-pss"), CKM_SHA512_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha224-rsa-pkcs"), CKM_SHA224_RSA_PKCS },
	{ STR_WITH_LEN("sha224-rsa-pkcs-pss"), CKM_SHA224_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha512-224"), CKM_SHA512_224 },
	{ STR_WITH_LEN("sha512-224-hmac"), CKM_SHA512_224_HMAC },
	{ STR_WITH_LEN("sha512-224-hmac-general"), CKM_SHA512_224_HMAC_GENERAL },
	{ STR_WITH_LEN("sha512-224-key-derivation"), CKM_SHA512_224_KEY_DERIVATION },
	{ STR_WITH_LEN("sha512-256"), CKM_SHA512_256 },
	{ STR_WITH_LEN("sha512-256-hmac"), CKM_SHA512_256_HMAC },
	{ STR_WITH_LEN("sha512-256-hmac-general"), CKM_SHA512_256_HMAC_GENERAL },
	{ STR_WITH_LEN("sha512-256-key-derivation"), CKM_SHA512_256_KEY_DERIVATION },
	{ STR_WITH_LEN("sha512-t"), CKM_SHA512_T },
	{ STR_WITH_LEN("sha512-t-hmac"), CKM_SHA512_T_HMAC },
	{ STR_WITH_LEN("sha512-t-hmac-general"), CKM_SHA512_T_HMAC_GENERAL },
	{ STR_WITH_LEN("sha512-t-key-derivation"), CKM_SHA512_T_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-256-rsa-pkcs"), CKM_SHA3_256_RSA_PKCS },
	{ STR_WITH_LEN("sha3-384-rsa-pkcs"), CKM_SHA3_384_RSA_PKCS },
	{ STR_WITH_LEN("sha3-512-rsa-pkcs"), CKM_SHA3_512_RSA_PKCS },
	{ STR_WITH_LEN("sha3-256-rsa-pkcs-pss"), CKM_SHA3_256_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha3-384-rsa-pkcs-pss"), CKM_SHA3_384_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha3-512-rsa-pkcs-pss"), CKM_SHA3_512_RSA_PKCS_PSS },
	{ STR_WITH_LEN("sha3-224-rsa-pkcs"), CKM_SHA3_224_RSA_PKCS },
	{ STR_WITH_LEN("sha3-224-rsa-pkcs-pss"), CKM_SHA3_224_RSA_PKCS_PSS },
	{ STR_WITH_LEN("rc2-key-gen"), CKM_RC2_KEY_GEN },
	{ STR_WITH_LEN("rc2-ecb"), CKM_RC2_ECB },
	{ STR_WITH_LEN("rc2-cbc"), CKM_RC2_CBC },
	{ STR_WITH_LEN("rc2-mac"), CKM_RC2_MAC },
	{ STR_WITH_LEN("rc2-mac-general"), CKM_RC2_MAC_GENERAL },
	{ STR_WITH_LEN("rc2-cbc-pad"), CKM_RC2_CBC_PAD },
	{ STR_WITH_LEN("rc4-key-gen"), CKM_RC4_KEY_GEN },
	{ STR_WITH_LEN("rc4"), CKM_RC4 },
	{ STR_WITH_LEN("des-key-gen"), CKM_DES_KEY_GEN },
	{ STR_WITH_LEN("des-ecb"), CKM_DES_ECB },
	{ STR_WITH_LEN("des-cbc"), CKM_DES_CBC },
	{ STR_WITH_LEN("des-mac"), CKM_DES_MAC },
	{ STR_WITH_LEN("des-mac-general"), CKM_DES_MAC_GENERAL },
	{ STR_WITH_LEN("des-cbc-pad"), CKM_DES_CBC_PAD },
	{ STR_WITH_LEN("des2-key-gen"), CKM_DES2_KEY_GEN },
	{ STR_WITH_LEN("des3-key-gen"), CKM_DES3_KEY_GEN },
	{ STR_WITH_LEN("des3-ecb"), CKM_DES3_ECB },
	{ STR_WITH_LEN("des3-cbc"), CKM_DES3_CBC },
	{ STR_WITH_LEN("des3-mac"), CKM_DES3_MAC },
	{ STR_WITH_LEN("des3-mac-general"), CKM_DES3_MAC_GENERAL },
	{ STR_WITH_LEN("des3-cbc-pad"), CKM_DES3_CBC_PAD },
	{ STR_WITH_LEN("des3-cmac-general"), CKM_DES3_CMAC_GENERAL },
	{ STR_WITH_LEN("des3-cmac"), CKM_DES3_CMAC },
	{ STR_WITH_LEN("cdmf-key-gen"), CKM_CDMF_KEY_GEN },
	{ STR_WITH_LEN("cdmf-ecb"), CKM_CDMF_ECB },
	{ STR_WITH_LEN("cdmf-cbc"), CKM_CDMF_CBC },
	{ STR_WITH_LEN("cdmf-mac"), CKM_CDMF_MAC },
	{ STR_WITH_LEN("cdmf-mac-general"), CKM_CDMF_MAC_GENERAL },
	{ STR_WITH_LEN("cdmf-cbc-pad"), CKM_CDMF_CBC_PAD },
	{ STR_WITH_LEN("des-ofb64"), CKM_DES_OFB64 },
	{ STR_WITH_LEN("des-ofb8"), CKM_DES_OFB8 },
	{ STR_WITH_LEN("des-cfb64"), CKM_DES_CFB64 },
	{ STR_WITH_LEN("des-cfb8"), CKM_DES_CFB8 },
	{ STR_WITH_LEN("md2"), CKM_MD2 },
	{ STR_WITH_LEN("md2-hmac"), CKM_MD2_HMAC },
	{ STR_WITH_LEN("md2-hmac-general"), CKM_MD2_HMAC_GENERAL },
	{ STR_WITH_LEN("md5"), CKM_MD5 },
	{ STR_WITH_LEN("md5-hmac"), CKM_MD5_HMAC },
	{ STR_WITH_LEN("md5-hmac-general"), CKM_MD5_HMAC_GENERAL },
	{ STR_WITH_LEN("sha1"), CKM_SHA_1 },
	{ STR_WITH_LEN("sha1-hmac"), CKM_SHA_1_HMAC },
	{ STR_WITH_LEN("sha1-hmac-general"), CKM_SHA_1_HMAC_GENERAL },
	{ STR_WITH_LEN("ripemd128"), CKM_RIPEMD128 },
	{ STR_WITH_LEN("ripemd128-hmac"), CKM_RIPEMD128_HMAC },
	{ STR_WITH_LEN("ripemd128-hmac-general"), CKM_RIPEMD128_HMAC_GENERAL },
	{ STR_WITH_LEN("ripemd160"), CKM_RIPEMD160 },
	{ STR_WITH_LEN("ripemd160-hmac"), CKM_RIPEMD160_HMAC },
	{ STR_WITH_LEN("ripemd160-hmac-general"), CKM_RIPEMD160_HMAC_GENERAL },
	{ STR_WITH_LEN("sha256"), CKM_SHA256 },
	{ STR_WITH_LEN("sha256-hmac"), CKM_SHA256_HMAC },
	{ STR_WITH_LEN("sha256-hmac-general"), CKM_SHA256_HMAC_GENERAL },
	{ STR_WITH_LEN("sha224"), CKM_SHA224 },
	{ STR_WITH_LEN("sha224-hmac"), CKM_SHA224_HMAC },
	{ STR_WITH_LEN("sha224-hmac-general"), CKM_SHA224_HMAC_GENERAL },
	{ STR_WITH_LEN("sha384"), CKM_SHA384 },
	{ STR_WITH_LEN("sha384-hmac"), CKM_SHA384_HMAC },
	{ STR_WITH_LEN("sha384-hmac-general"), CKM_SHA384_HMAC_GENERAL },
	{ STR_WITH_LEN("sha512"), CKM_SHA512 },
	{ STR_WITH_LEN("sha512-hmac"), CKM_SHA512_HMAC },
	{ STR_WITH_LEN("sha512-hmac-general"), CKM_SHA512_HMAC_GENERAL },
	{ STR_WITH_LEN("securid-key-gen"), CKM_SECURID_KEY_GEN },
	{ STR_WITH_LEN("securid"), CKM_SECURID },
	{ STR_WITH_LEN("hotp-key-gen"), CKM_HOTP_KEY_GEN },
	{ STR_WITH_LEN("hotp"), CKM_HOTP },
	{ STR_WITH_LEN("acti"), CKM_ACTI },
	{ STR_WITH_LEN("acti-key-gen"), CKM_ACTI_KEY_GEN },
	{ STR_WITH_LEN("sha3-256"), CKM_SHA3_256 },
	{ STR_WITH_LEN("sha3-256-hmac"), CKM_SHA3_256_HMAC },
	{ STR_WITH_LEN("sha3-256-hmac-general"), CKM_SHA3_256_HMAC_GENERAL },
	{ STR_WITH_LEN("sha3-256-key-gen"), CKM_SHA3_256_KEY_GEN },
	{ STR_WITH_LEN("sha3-224"), CKM_SHA3_224 },
	{ STR_WITH_LEN("sha3-224-hmac"), CKM_SHA3_224_HMAC },
	{ STR_WITH_LEN("sha3-224-hmac-general"), CKM_SHA3_224_HMAC_GENERAL },
	{ STR_WITH_LEN("sha3-224-key-gen"), CKM_SHA3_224_KEY_GEN },
	{ STR_WITH_LEN("sha3-384"), CKM_SHA3_384 },
	{ STR_WITH_LEN("sha3-384-hmac"), CKM_SHA3_384_HMAC },
	{ STR_WITH_LEN("sha3-384-hmac-general"), CKM_SHA3_384_HMAC_GENERAL },
	{ STR_WITH_LEN("sha3-384-key-gen"), CKM_SHA3_384_KEY_GEN },
	{ STR_WITH_LEN("sha3-512"), CKM_SHA3_512 },
	{ STR_WITH_LEN("sha3-512-hmac"), CKM_SHA3_512_HMAC },
	{ STR_WITH_LEN("sha3-512-hmac-general"), CKM_SHA3_512_HMAC_GENERAL },
	{ STR_WITH_LEN("sha3-512-key-gen"), CKM_SHA3_512_KEY_GEN },
	{ STR_WITH_LEN("cast-key-gen"), CKM_CAST_KEY_GEN },
	{ STR_WITH_LEN("cast-ecb"), CKM_CAST_ECB },
	{ STR_WITH_LEN("cast-cbc"), CKM_CAST_CBC },
	{ STR_WITH_LEN("cast-mac"), CKM_CAST_MAC },
	{ STR_WITH_LEN("cast-mac-general"), CKM_CAST_MAC_GENERAL },
	{ STR_WITH_LEN("cast-cbc-pad"), CKM_CAST_CBC_PAD },
	{ STR_WITH_LEN("cast3-key-gen"), CKM_CAST3_KEY_GEN },
	{ STR_WITH_LEN("cast3-ecb"), CKM_CAST3_ECB },
	{ STR_WITH_LEN("cast3-cbc"), CKM_CAST3_CBC },
	{ STR_WITH_LEN("cast3-mac"), CKM_CAST3_MAC },
	{ STR_WITH_LEN("cast3-mac-general"), CKM_CAST3_MAC_GENERAL },
	{ STR_WITH_LEN("cast3-cbc-pad"), CKM_CAST3_CBC_PAD },
	{ STR_WITH_LEN("cast5-key-gen"), CKM_CAST5_KEY_GEN },
	{ STR_WITH_LEN("cast128-key-gen"), CKM_CAST128_KEY_GEN },
	{ STR_WITH_LEN("cast5-ecb"), CKM_CAST5_ECB },
	{ STR_WITH_LEN("cast128-ecb"), CKM_CAST128_ECB },
	{ STR_WITH_LEN("cast5-cbc"), CKM_CAST5_CBC },
	{ STR_WITH_LEN("cast128-cbc"), CKM_CAST128_CBC },
	{ STR_WITH_LEN("cast5-mac"), CKM_CAST5_MAC },
	{ STR_WITH_LEN("cast128-mac"), CKM_CAST128_MAC },
	{ STR_WITH_LEN("cast5-mac-general"), CKM_CAST5_MAC_GENERAL },
	{ STR_WITH_LEN("cast128-mac-general"), CKM_CAST128_MAC_GENERAL },
	{ STR_WITH_LEN("cast5-cbc-pad"), CKM_CAST5_CBC_PAD },
	{ STR_WITH_LEN("cast128-cbc-pad"), CKM_CAST128_CBC_PAD },
	{ STR_WITH_LEN("rc5-key-gen"), CKM_RC5_KEY_GEN },
	{ STR_WITH_LEN("rc5-ecb"), CKM_RC5_ECB },
	{ STR_WITH_LEN("rc5-cbc"), CKM_RC5_CBC },
	{ STR_WITH_LEN("rc5-mac"), CKM_RC5_MAC },
	{ STR_WITH_LEN("rc5-mac-general"), CKM_RC5_MAC_GENERAL },
	{ STR_WITH_LEN("rc5-cbc-pad"), CKM_RC5_CBC_PAD },
	{ STR_WITH_LEN("idea-key-gen"), CKM_IDEA_KEY_GEN },
	{ STR_WITH_LEN("idea-ecb"), CKM_IDEA_ECB },
	{ STR_WITH_LEN("idea-cbc"), CKM_IDEA_CBC },
	{ STR_WITH_LEN("idea-mac"), CKM_IDEA_MAC },
	{ STR_WITH_LEN("idea-mac-general"), CKM_IDEA_MAC_GENERAL },
	{ STR_WITH_LEN("idea-cbc-pad"), CKM_IDEA_CBC_PAD },
	{ STR_WITH_LEN("generic-secret-key-gen"), CKM_GENERIC_SECRET_KEY_GEN },
	{ STR_WITH_LEN("concatenate-base-and-key"), CKM_CONCATENATE_BASE_AND_KEY },
	{ STR_WITH_LEN("concatenate-base-and-data"), CKM_CONCATENATE_BASE_AND_DATA },
	{ STR_WITH_LEN("concatenate-data-and-base"), CKM_CONCATENATE_DATA_AND_BASE },
	{ STR_WITH_LEN("xor-base-and-data"), CKM_XOR_BASE_AND_DATA },
	{ STR_WITH_LEN("extract-key-from-key"), CKM_EXTRACT_KEY_FROM_KEY },
	{ STR_WITH_LEN("ssl3-pre-master-key-gen"), CKM_SSL3_PRE_MASTER_KEY_GEN },
	{ STR_WITH_LEN("ssl3-master-key-derive"), CKM_SSL3_MASTER_KEY_DERIVE },
	{ STR_WITH_LEN("ssl3-key-and-mac-derive"), CKM_SSL3_KEY_AND_MAC_DERIVE },
	{ STR_WITH_LEN("ssl3-master-key-derive-dh"), CKM_SSL3_MASTER_KEY_DERIVE_DH },
	{ STR_WITH_LEN("tls-pre-master-key-gen"), CKM_TLS_PRE_MASTER_KEY_GEN },
	{ STR_WITH_LEN("tls-master-key-derive"), CKM_TLS_MASTER_KEY_DERIVE },
	{ STR_WITH_LEN("tls-key-and-mac-derive"), CKM_TLS_KEY_AND_MAC_DERIVE },
	{ STR_WITH_LEN("tls-master-key-derive-dh"), CKM_TLS_MASTER_KEY_DERIVE_DH },
	{ STR_WITH_LEN("tls-prf"), CKM_TLS_PRF },
	{ STR_WITH_LEN("ssl3-md5-mac"), CKM_SSL3_MD5_MAC },
	{ STR_WITH_LEN("ssl3-sha1-mac"), CKM_SSL3_SHA1_MAC },
	{ STR_WITH_LEN("md5-key-derivation"), CKM_MD5_KEY_DERIVATION },
	{ STR_WITH_LEN("md2-key-derivation"), CKM_MD2_KEY_DERIVATION },
	{ STR_WITH_LEN("sha1-key-derivation"), CKM_SHA1_KEY_DERIVATION },
	{ STR_WITH_LEN("sha256-key-derivation"), CKM_SHA256_KEY_DERIVATION },
	{ STR_WITH_LEN("sha384-key-derivation"), CKM_SHA384_KEY_DERIVATION },
	{ STR_WITH_LEN("sha512-key-derivation"), CKM_SHA512_KEY_DERIVATION },
	{ STR_WITH_LEN("sha224-key-derivation"), CKM_SHA224_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-256-key-derivation"), CKM_SHA3_256_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-224-key-derivation"), CKM_SHA3_224_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-384-key-derivation"), CKM_SHA3_384_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-512-key-derivation"), CKM_SHA3_512_KEY_DERIVATION },
	{ STR_WITH_LEN("shake-128-key-derivation"), CKM_SHAKE_128_KEY_DERIVATION },
	{ STR_WITH_LEN("shake-256-key-derivation"), CKM_SHAKE_256_KEY_DERIVATION },
	{ STR_WITH_LEN("sha3-256-key-derive"), CKM_SHA3_256_KEY_DERIVE },
	{ STR_WITH_LEN("sha3-224-key-derive"), CKM_SHA3_224_KEY_DERIVE },
	{ STR_WITH_LEN("sha3-384-key-derive"), CKM_SHA3_384_KEY_DERIVE },
	{ STR_WITH_LEN("sha3-512-key-derive"), CKM_SHA3_512_KEY_DERIVE },
	{ STR_WITH_LEN("shake-128-key-derive"), CKM_SHAKE_128_KEY_DERIVE },
	{ STR_WITH_LEN("shake-256-key-derive"), CKM_SHAKE_256_KEY_DERIVE },
	{ STR_WITH_LEN("pbe-md2-des-cbc"), CKM_PBE_MD2_DES_CBC },
	{ STR_WITH_LEN("pbe-md5-des-cbc"), CKM_PBE_MD5_DES_CBC },
	{ STR_WITH_LEN("pbe-md5-cast-cbc"), CKM_PBE_MD5_CAST_CBC },
	{ STR_WITH_LEN("pbe-md5-cast3-cbc"), CKM_PBE_MD5_CAST3_CBC },
	{ STR_WITH_LEN("pbe-md5-cast5-cbc"), CKM_PBE_MD5_CAST5_CBC },
	{ STR_WITH_LEN("pbe-md5-cast128-cbc"), CKM_PBE_MD5_CAST128_CBC },
	{ STR_WITH_LEN("pbe-sha1-cast5-cbc"), CKM_PBE_SHA1_CAST5_CBC },
	{ STR_WITH_LEN("pbe-sha1-cast128-cbc"), CKM_PBE_SHA1_CAST128_CBC },
	{ STR_WITH_LEN("pbe-sha1-rc4-128"), CKM_PBE_SHA1_RC4_128 },
	{ STR_WITH_LEN("pbe-sha1-rc4-40"), CKM_PBE_SHA1_RC4_40 },
	{ STR_WITH_LEN("pbe-sha1-des3-ede-cbc"), CKM_PBE_SHA1_DES3_EDE_CBC },
	{ STR_WITH_LEN("pbe-sha1-des2-ede-cbc"), CKM_PBE_SHA1_DES2_EDE_CBC },
	{ STR_WITH_LEN("pbe-sha1-rc2-128-cbc"), CKM_PBE_SHA1_RC2_128_CBC },
	{ STR_WITH_LEN("pbe-sha1-rc2-40-cbc"), CKM_PBE_SHA1_RC2_40_CBC },
	{ STR_WITH_LEN("pkcs5-pbkd2"), CKM_PKCS5_PBKD2 },
	{ STR_WITH_LEN("pba-sha1-with-sha1-hmac"), CKM_PBA_SHA1_WITH_SHA1_HMAC },
	{ STR_WITH_LEN("wtls-pre-master-key-gen"), CKM_WTLS_PRE_MASTER_KEY_GEN },
	{ STR_WITH_LEN("wtls-master-key-derive"), CKM_WTLS_MASTER_KEY_DERIVE },
	{ STR_WITH_LEN("wtls-master-key-derive-dh-ecc"), CKM_WTLS_MASTER_KEY_DERIVE_DH_ECC },
	{ STR_WITH_LEN("wtls-prf"), CKM_WTLS_PRF },
	{ STR_WITH_LEN("wtls-server-key-and-mac-derive"), CKM_WTLS_SERVER_KEY_AND_MAC_DERIVE },
	{ STR_WITH_LEN("wtls-client-key-and-mac-derive"), CKM_WTLS_CLIENT_KEY_AND_MAC_DERIVE },
	{ STR_WITH_LEN("tls10-mac-server"), CKM_TLS10_MAC_SERVER },
	{ STR_WITH_LEN("tls10-mac-client"), CKM_TLS10_MAC_CLIENT },
	{ STR_WITH_LEN("tls12-mac"), CKM_TLS12_MAC },
	{ STR_WITH_LEN("tls12-kdf"), CKM_TLS12_KDF },
	{ STR_WITH_LEN("tls12-master-key-derive"), CKM_TLS12_MASTER_KEY_DERIVE },
	{ STR_WITH_LEN("tls12-key-and-mac-derive"), CKM_TLS12_KEY_AND_MAC_DERIVE },
	{ STR_WITH_LEN("tls12-master-key-derive-dh"), CKM_TLS12_MASTER_KEY_DERIVE_DH },
	{ STR_WITH_LEN("tls12-key-safe-derive"), CKM_TLS12_KEY_SAFE_DERIVE },
	{ STR_WITH_LEN("tls-mac"), CKM_TLS_MAC },
	{ STR_WITH_LEN("tls-kdf"), CKM_TLS_KDF },
	{ STR_WITH_LEN("key-wrap-lynks"), CKM_KEY_WRAP_LYNKS },
	{ STR_WITH_LEN("key-wrap-set-oaep"), CKM_KEY_WRAP_SET_OAEP },
	{ STR_WITH_LEN("cms-sig"), CKM_CMS_SIG },
	{ STR_WITH_LEN("kip-derive"), CKM_KIP_DERIVE },
	{ STR_WITH_LEN("kip-wrap"), CKM_KIP_WRAP },
	{ STR_WITH_LEN("kip-mac"), CKM_KIP_MAC },
	{ STR_WITH_LEN("camellia-key-gen"), CKM_CAMELLIA_KEY_GEN },
	{ STR_WITH_LEN("camellia-ecb"), CKM_CAMELLIA_ECB },
	{ STR_WITH_LEN("camellia-cbc"), CKM_CAMELLIA_CBC },
	{ STR_WITH_LEN("camellia-mac"), CKM_CAMELLIA_MAC },
	{ STR_WITH_LEN("camellia-mac-general"), CKM_CAMELLIA_MAC_GENERAL },
	{ STR_WITH_LEN("camellia-cbc-pad"), CKM_CAMELLIA_CBC_PAD },
	{ STR_WITH_LEN("camellia-ecb-encrypt-data"), CKM_CAMELLIA_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("camellia-cbc-encrypt-data"), CKM_CAMELLIA_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("camellia-ctr"), CKM_CAMELLIA_CTR },
	{ STR_WITH_LEN("aria-key-gen"), CKM_ARIA_KEY_GEN },
	{ STR_WITH_LEN("aria-ecb"), CKM_ARIA_ECB },
	{ STR_WITH_LEN("aria-cbc"), CKM_ARIA_CBC },
	{ STR_WITH_LEN("aria-mac"), CKM_ARIA_MAC },
	{ STR_WITH_LEN("aria-mac-general"), CKM_ARIA_MAC_GENERAL },
	{ STR_WITH_LEN("aria-cbc-pad"), CKM_ARIA_CBC_PAD },
	{ STR_WITH_LEN("aria-ecb-encrypt-data"), CKM_ARIA_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("aria-cbc-encrypt-data"), CKM_ARIA_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("seed-key-gen"), CKM_SEED_KEY_GEN },
	{ STR_WITH_LEN("seed-ecb"), CKM_SEED_ECB },
	{ STR_WITH_LEN("seed-cbc"), CKM_SEED_CBC },
	{ STR_WITH_LEN("seed-mac"), CKM_SEED_MAC },
	{ STR_WITH_LEN("seed-mac-general"), CKM_SEED_MAC_GENERAL },
	{ STR_WITH_LEN("seed-cbc-pad"), CKM_SEED_CBC_PAD },
	{ STR_WITH_LEN("seed-ecb-encrypt-data"), CKM_SEED_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("seed-cbc-encrypt-data"), CKM_SEED_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("skipjack-key-gen"), CKM_SKIPJACK_KEY_GEN },
	{ STR_WITH_LEN("skipjack-ecb64"), CKM_SKIPJACK_ECB64 },
	{ STR_WITH_LEN("skipjack-cbc64"), CKM_SKIPJACK_CBC64 },
	{ STR_WITH_LEN("skipjack-ofb64"), CKM_SKIPJACK_OFB64 },
	{ STR_WITH_LEN("skipjack-cfb64"), CKM_SKIPJACK_CFB64 },
	{ STR_WITH_LEN("skipjack-cfb32"), CKM_SKIPJACK_CFB32 },
	{ STR_WITH_LEN("skipjack-cfb16"), CKM_SKIPJACK_CFB16 },
	{ STR_WITH_LEN("skipjack-cfb8"), CKM_SKIPJACK_CFB8 },
	{ STR_WITH_LEN("skipjack-wrap"), CKM_SKIPJACK_WRAP },
	{ STR_WITH_LEN("skipjack-private-wrap"), CKM_SKIPJACK_PRIVATE_WRAP },
	{ STR_WITH_LEN("skipjack-relayx"), CKM_SKIPJACK_RELAYX },
	{ STR_WITH_LEN("kea-key-pair-gen"), CKM_KEA_KEY_PAIR_GEN },
	{ STR_WITH_LEN("kea-key-derive"), CKM_KEA_KEY_DERIVE },
	{ STR_WITH_LEN("kea-derive"), CKM_KEA_DERIVE },
	{ STR_WITH_LEN("fortezza-timestamp"), CKM_FORTEZZA_TIMESTAMP },
	{ STR_WITH_LEN("baton-key-gen"), CKM_BATON_KEY_GEN },
	{ STR_WITH_LEN("baton-ecb128"), CKM_BATON_ECB128 },
	{ STR_WITH_LEN("baton-ecb96"), CKM_BATON_ECB96 },
	{ STR_WITH_LEN("baton-cbc128"), CKM_BATON_CBC128 },
	{ STR_WITH_LEN("baton-counter"), CKM_BATON_COUNTER },
	{ STR_WITH_LEN("baton-shuffle"), CKM_BATON_SHUFFLE },
	{ STR_WITH_LEN("baton-wrap"), CKM_BATON_WRAP },
	{ STR_WITH_LEN("ecdsa-key-pair-gen"), CKM_ECDSA_KEY_PAIR_GEN },
	{ STR_WITH_LEN("ec-key-pair-gen"), CKM_EC_KEY_PAIR_GEN },
	{ STR_WITH_LEN("ecdsa"), CKM_ECDSA },
	{ STR_WITH_LEN("ecdsa-sha1"), CKM_ECDSA_SHA1 },
	{ STR_WITH_LEN("ecdsa-sha224"), CKM_ECDSA_SHA224 },
	{ STR_WITH_LEN("ecdsa-sha256"), CKM_ECDSA_SHA256 },
	{ STR_WITH_LEN("ecdsa-sha384"), CKM_ECDSA_SHA384 },
	{ STR_WITH_LEN("ecdsa-sha512"), CKM_ECDSA_SHA512 },
	{ STR_WITH_LEN("ec-key-pair-gen-w-extra-bits"), CKM_EC_KEY_PAIR_GEN_W_EXTRA_BITS },
	{ STR_WITH_LEN("ecdh1-derive"), CKM_ECDH1_DERIVE },
	{ STR_WITH_LEN("ecdh1-cofactor-derive"), CKM_ECDH1_COFACTOR_DERIVE },
	{ STR_WITH_LEN("ecmqv-derive"), CKM_ECMQV_DERIVE },
	{ STR_WITH_LEN("ecdh-aes-key-wrap"), CKM_ECDH_AES_KEY_WRAP },
	{ STR_WITH_LEN("rsa-aes-key-wrap"), CKM_RSA_AES_KEY_WRAP },
	{ STR_WITH_LEN("juniper-key-gen"), CKM_JUNIPER_KEY_GEN },
	{ STR_WITH_LEN("juniper-ecb128"), CKM_JUNIPER_ECB128 },
	{ STR_WITH_LEN("juniper-cbc128"), CKM_JUNIPER_CBC128 },
	{ STR_WITH_LEN("juniper-counter"), CKM_JUNIPER_COUNTER },
	{ STR_WITH_LEN("juniper-shuffle"), CKM_JUNIPER_SHUFFLE },
	{ STR_WITH_LEN("juniper-wrap"), CKM_JUNIPER_WRAP },
	{ STR_WITH_LEN("fasthash"), CKM_FASTHASH },
	{ STR_WITH_LEN("aes-xts"), CKM_AES_XTS },
	{ STR_WITH_LEN("aes-xts-key-gen"), CKM_AES_XTS_KEY_GEN },
	{ STR_WITH_LEN("aes-key-gen"), CKM_AES_KEY_GEN },
	{ STR_WITH_LEN("aes-ecb"), CKM_AES_ECB },
	{ STR_WITH_LEN("aes-cbc"), CKM_AES_CBC },
	{ STR_WITH_LEN("aes-mac"), CKM_AES_MAC },
	{ STR_WITH_LEN("aes-mac-general"), CKM_AES_MAC_GENERAL },
	{ STR_WITH_LEN("aes-cbc-pad"), CKM_AES_CBC_PAD },
	{ STR_WITH_LEN("aes-ctr"), CKM_AES_CTR },
	{ STR_WITH_LEN("aes-gcm"), CKM_AES_GCM },
	{ STR_WITH_LEN("aes-ccm"), CKM_AES_CCM },
	{ STR_WITH_LEN("aes-cts"), CKM_AES_CTS },
	{ STR_WITH_LEN("aes-cmac"), CKM_AES_CMAC },
	{ STR_WITH_LEN("aes-cmac-general"), CKM_AES_CMAC_GENERAL },
	{ STR_WITH_LEN("aes-xcbc-mac"), CKM_AES_XCBC_MAC },
	{ STR_WITH_LEN("aes-xcbc-mac-96"), CKM_AES_XCBC_MAC_96 },
	{ STR_WITH_LEN("aes-gmac"), CKM_AES_GMAC },
	{ STR_WITH_LEN("blowfish-key-gen"), CKM_BLOWFISH_KEY_GEN },
	{ STR_WITH_LEN("blowfish-cbc"), CKM_BLOWFISH_CBC },
	{ STR_WITH_LEN("twofish-key-gen"), CKM_TWOFISH_KEY_GEN },
	{ STR_WITH_LEN("twofish-cbc"), CKM_TWOFISH_CBC },
	{ STR_WITH_LEN("blowfish-cbc-pad"), CKM_BLOWFISH_CBC_PAD },
	{ STR_WITH_LEN("twofish-cbc-pad"), CKM_TWOFISH_CBC_PAD },
	{ STR_WITH_LEN("des-ecb-encrypt-data"), CKM_DES_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("des-cbc-encrypt-data"), CKM_DES_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("des3-ecb-encrypt-data"), CKM_DES3_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("des3-cbc-encrypt-data"), CKM_DES3_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("aes-ecb-encrypt-data"), CKM_AES_ECB_ENCRYPT_DATA },
	{ STR_WITH_LEN("aes-cbc-encrypt-data"), CKM_AES_CBC_ENCRYPT_DATA },
	{ STR_WITH_LEN("gostr3410-key-pair-gen"), CKM_GOSTR3410_KEY_PAIR_GEN },
	{ STR_WITH_LEN("gostr3410"), CKM_GOSTR3410 },
	{ STR_WITH_LEN("gostr3410-with-gostr3411"), CKM_GOSTR3410_WITH_GOSTR3411 },
	{ STR_WITH_LEN("gostr3410-key-wrap"), CKM_GOSTR3410_KEY_WRAP },
	{ STR_WITH_LEN("gostr3410-derive"), CKM_GOSTR3410_DERIVE },
	{ STR_WITH_LEN("gostr3411"), CKM_GOSTR3411 },
	{ STR_WITH_LEN("gostr3411-hmac"), CKM_GOSTR3411_HMAC },
	{ STR_WITH_LEN("gost28147-key-gen"), CKM_GOST28147_KEY_GEN },
	{ STR_WITH_LEN("gost28147-ecb"), CKM_GOST28147_ECB },
	{ STR_WITH_LEN("gost28147"), CKM_GOST28147 },
	{ STR_WITH_LEN("gost28147-mac"), CKM_GOST28147_MAC },
	{ STR_WITH_LEN("gost28147-key-wrap"), CKM_GOST28147_KEY_WRAP },
	{ STR_WITH_LEN("chacha20-key-gen"), CKM_CHACHA20_KEY_GEN },
	{ STR_WITH_LEN("chacha20"), CKM_CHACHA20 },
	{ STR_WITH_LEN("poly1305-key-gen"), CKM_POLY1305_KEY_GEN },
	{ STR_WITH_LEN("poly1305"), CKM_POLY1305 },
	{ STR_WITH_LEN("dsa-parameter-gen"), CKM_DSA_PARAMETER_GEN },
	{ STR_WITH_LEN("dh-pkcs-parameter-gen"), CKM_DH_PKCS_PARAMETER_GEN },
	{ STR_WITH_LEN("x9-42-dh-parameter-gen"), CKM_X9_42_DH_PARAMETER_GEN },
	{ STR_WITH_LEN("dsa-probabilistic-parameter-gen"), CKM_DSA_PROBABILISTIC_PARAMETER_GEN },
	{ STR_WITH_LEN("dsa-probablistic-parameter-gen"), CKM_DSA_PROBABLISTIC_PARAMETER_GEN },
	{ STR_WITH_LEN("dsa-shawe-taylor-parameter-gen"), CKM_DSA_SHAWE_TAYLOR_PARAMETER_GEN },
	{ STR_WITH_LEN("dsa-fips-g-gen"), CKM_DSA_FIPS_G_GEN },
	{ STR_WITH_LEN("aes-ofb"), CKM_AES_OFB },
	{ STR_WITH_LEN("aes-cfb64"), CKM_AES_CFB64 },
	{ STR_WITH_LEN("aes-cfb8"), CKM_AES_CFB8 },
	{ STR_WITH_LEN("aes-cfb128"), CKM_AES_CFB128 },
	{ STR_WITH_LEN("aes-cfb1"), CKM_AES_CFB1 },
	{ STR_WITH_LEN("aes-key-wrap"), CKM_AES_KEY_WRAP },
	{ STR_WITH_LEN("aes-key-wrap-pad"), CKM_AES_KEY_WRAP_PAD },
	{ STR_WITH_LEN("aes-key-wrap-kwp"), CKM_AES_KEY_WRAP_KWP },
	{ STR_WITH_LEN("aes-key-wrap-pkcs7"), CKM_AES_KEY_WRAP_PKCS7 },
	{ STR_WITH_LEN("rsa-pkcs-tpm-1-1"), CKM_RSA_PKCS_TPM_1_1 },
	{ STR_WITH_LEN("rsa-pkcs-oaep-tpm-1-1"), CKM_RSA_PKCS_OAEP_TPM_1_1 },
	{ STR_WITH_LEN("sha1-key-gen"), CKM_SHA_1_KEY_GEN },
	{ STR_WITH_LEN("sha224-key-gen"), CKM_SHA224_KEY_GEN },
	{ STR_WITH_LEN("sha256-key-gen"), CKM_SHA256_KEY_GEN },
	{ STR_WITH_LEN("sha384-key-gen"), CKM_SHA384_KEY_GEN },
	{ STR_WITH_LEN("sha512-key-gen"), CKM_SHA512_KEY_GEN },
	{ STR_WITH_LEN("sha512-224-key-gen"), CKM_SHA512_224_KEY_GEN },
	{ STR_WITH_LEN("sha512-256-key-gen"), CKM_SHA512_256_KEY_GEN },
	{ STR_WITH_LEN("sha512-t-key-gen"), CKM_SHA512_T_KEY_GEN },
	{ STR_WITH_LEN("null"), CKM_NULL },
	{ STR_WITH_LEN("blake2b-160"), CKM_BLAKE2B_160 },
	{ STR_WITH_LEN("blake2b-160-hmac"), CKM_BLAKE2B_160_HMAC },
	{ STR_WITH_LEN("blake2b-160-hmac-general"), CKM_BLAKE2B_160_HMAC_GENERAL },
	{ STR_WITH_LEN("blake2b-160-key-derive"), CKM_BLAKE2B_160_KEY_DERIVE },
	{ STR_WITH_LEN("blake2b-160-key-gen"), CKM_BLAKE2B_160_KEY_GEN },
	{ STR_WITH_LEN("blake2b-256"), CKM_BLAKE2B_256 },
	{ STR_WITH_LEN("blake2b-256-hmac"), CKM_BLAKE2B_256_HMAC },
	{ STR_WITH_LEN("blake2b-256-hmac-general"), CKM_BLAKE2B_256_HMAC_GENERAL },
	{ STR_WITH_LEN("blake2b-256-key-derive"), CKM_BLAKE2B_256_KEY_DERIVE },
	{ STR_WITH_LEN("blake2b-256-key-gen"), CKM_BLAKE2B_256_KEY_GEN },
	{ STR_WITH_LEN("blake2b-384"), CKM_BLAKE2B_384 },
	{ STR_WITH_LEN("blake2b-384-hmac"), CKM_BLAKE2B_384_HMAC },
	{ STR_WITH_LEN("blake2b-384-hmac-general"), CKM_BLAKE2B_384_HMAC_GENERAL },
	{ STR_WITH_LEN("blake2b-384-key-derive"), CKM_BLAKE2B_384_KEY_DERIVE },
	{ STR_WITH_LEN("blake2b-384-key-gen"), CKM_BLAKE2B_384_KEY_GEN },
	{ STR_WITH_LEN("blake2b-512"), CKM_BLAKE2B_512 },
	{ STR_WITH_LEN("blake2b-512-hmac"), CKM_BLAKE2B_512_HMAC },
	{ STR_WITH_LEN("blake2b-512-hmac-general"), CKM_BLAKE2B_512_HMAC_GENERAL },
	{ STR_WITH_LEN("blake2b-512-key-derive"), CKM_BLAKE2B_512_KEY_DERIVE },
	{ STR_WITH_LEN("blake2b-512-key-gen"), CKM_BLAKE2B_512_KEY_GEN },
	{ STR_WITH_LEN("salsa20"), CKM_SALSA20 },
	{ STR_WITH_LEN("chacha20-poly1305"), CKM_CHACHA20_POLY1305 },
	{ STR_WITH_LEN("salsa20-poly1305"), CKM_SALSA20_POLY1305 },
	{ STR_WITH_LEN("x3dh-initialize"), CKM_X3DH_INITIALIZE },
	{ STR_WITH_LEN("x3dh-respond"), CKM_X3DH_RESPOND },
	{ STR_WITH_LEN("x2ratchet-initialize"), CKM_X2RATCHET_INITIALIZE },
	{ STR_WITH_LEN("x2ratchet-respond"), CKM_X2RATCHET_RESPOND },
	{ STR_WITH_LEN("x2ratchet-encrypt"), CKM_X2RATCHET_ENCRYPT },
	{ STR_WITH_LEN("x2ratchet-decrypt"), CKM_X2RATCHET_DECRYPT },
	{ STR_WITH_LEN("xeddsa"), CKM_XEDDSA },
	{ STR_WITH_LEN("hkdf-derive"), CKM_HKDF_DERIVE },
	{ STR_WITH_LEN("hkdf-data"), CKM_HKDF_DATA },
	{ STR_WITH_LEN("hkdf-key-gen"), CKM_HKDF_KEY_GEN },
	{ STR_WITH_LEN("salsa20-key-gen"), CKM_SALSA20_KEY_GEN },
	{ STR_WITH_LEN("ecdsa-sha3-224"), CKM_ECDSA_SHA3_224 },
	{ STR_WITH_LEN("ecdsa-sha3-256"), CKM_ECDSA_SHA3_256 },
	{ STR_WITH_LEN("ecdsa-sha3-384"), CKM_ECDSA_SHA3_384 },
	{ STR_WITH_LEN("ecdsa-sha3-512"), CKM_ECDSA_SHA3_512 },
	{ STR_WITH_LEN("ec-edwards-key-pair-gen"), CKM_EC_EDWARDS_KEY_PAIR_GEN },
	{ STR_WITH_LEN("ec-montgomery-key-pair-gen"), CKM_EC_MONTGOMERY_KEY_PAIR_GEN },
	{ STR_WITH_LEN("eddsa"), CKM_EDDSA },
	{ STR_WITH_LEN("sp800-108-counter-kdf"), CKM_SP800_108_COUNTER_KDF },
	{ STR_WITH_LEN("sp800-108-feedback-kdf"), CKM_SP800_108_FEEDBACK_KDF },
	{ STR_WITH_LEN("sp800-108-double-pipeline-kdf"), CKM_SP800_108_DOUBLE_PIPELINE_KDF },
	{ STR_WITH_LEN("ike2-prf-plus-derive"), CKM_IKE2_PRF_PLUS_DERIVE },
	{ STR_WITH_LEN("ike-prf-derive"), CKM_IKE_PRF_DERIVE },
	{ STR_WITH_LEN("ike1-prf-derive"), CKM_IKE1_PRF_DERIVE },
	{ STR_WITH_LEN("ike1-extended-derive"), CKM_IKE1_EXTENDED_DERIVE },
	{ STR_WITH_LEN("hss-key-pair-gen"), CKM_HSS_KEY_PAIR_GEN },
	{ STR_WITH_LEN("hss"), CKM_HSS },
	{ STR_WITH_LEN("vendor-defined"), CKM_VENDOR_DEFINED },
};

static CK_MECHANISM_TYPE S_get_mechanism_type(pTHX_ SV* input);
#define get_mechanism_type(input) S_get_mechanism_type(aTHX_ input)

static const map generators = {
	{ STR_WITH_LEN("sha1"), CKG_MGF1_SHA1 },
	{ STR_WITH_LEN("sha256"), CKG_MGF1_SHA256 },
	{ STR_WITH_LEN("sha384"), CKG_MGF1_SHA384 },
	{ STR_WITH_LEN("sha512"), CKG_MGF1_SHA512 },
	{ STR_WITH_LEN("sha224"), CKG_MGF1_SHA224 },
	{ STR_WITH_LEN("sha3_224"), CKG_MGF1_SHA3_224 },
	{ STR_WITH_LEN("sha3_256"), CKG_MGF1_SHA3_256 },
	{ STR_WITH_LEN("sha3_384"), CKG_MGF1_SHA3_384 },
	{ STR_WITH_LEN("sha3_512"), CKG_MGF1_SHA3_512 },
};

static const map kdfs = {
	{ STR_WITH_LEN("null"), CKD_NULL },
	{ STR_WITH_LEN("sha1"), CKD_SHA1_KDF },
	{ STR_WITH_LEN("sha1-asn1"), CKD_SHA1_KDF_ASN1 },
	{ STR_WITH_LEN("sha1-concatenate"), CKD_SHA1_KDF_CONCATENATE },
	{ STR_WITH_LEN("sha224"), CKD_SHA224_KDF },
	{ STR_WITH_LEN("sha256"), CKD_SHA256_KDF },
	{ STR_WITH_LEN("sha384"), CKD_SHA384_KDF },
	{ STR_WITH_LEN("sha512"), CKD_SHA512_KDF },
	{ STR_WITH_LEN("cpdiversify"), CKD_CPDIVERSIFY_KDF },
	{ STR_WITH_LEN("sha3-224"), CKD_SHA3_224_KDF },
	{ STR_WITH_LEN("sha3-256"), CKD_SHA3_256_KDF },
	{ STR_WITH_LEN("sha3-384"), CKD_SHA3_384_KDF },
	{ STR_WITH_LEN("sha3-512"), CKD_SHA3_512_KDF },
	{ STR_WITH_LEN("sha1-sp800"), CKD_SHA1_KDF_SP800 },
	{ STR_WITH_LEN("sha224-sp800"), CKD_SHA224_KDF_SP800 },
	{ STR_WITH_LEN("sha256-sp800"), CKD_SHA256_KDF_SP800 },
	{ STR_WITH_LEN("sha384-sp800"), CKD_SHA384_KDF_SP800 },
	{ STR_WITH_LEN("sha512-sp800"), CKD_SHA512_KDF_SP800 },
	{ STR_WITH_LEN("sha3-224-sp800"), CKD_SHA3_224_KDF_SP800 },
	{ STR_WITH_LEN("sha3-256-sp800"), CKD_SHA3_256_KDF_SP800 },
	{ STR_WITH_LEN("sha3-384-sp800"), CKD_SHA3_384_KDF_SP800 },
	{ STR_WITH_LEN("sha3-512-sp800"), CKD_SHA3_512_KDF_SP800 },
	{ STR_WITH_LEN("blake2b-160"), CKD_BLAKE2B_160_KDF },
	{ STR_WITH_LEN("blake2b-256"), CKD_BLAKE2B_256_KDF },
	{ STR_WITH_LEN("blake2b-384"), CKD_BLAKE2B_384_KDF },
	{ STR_WITH_LEN("blake2b-512"), CKD_BLAKE2B_512_KDF },
};

#define INIT_PARAMS(TYPE) \
	TYPE* params;\
	Newxz(params, 1, TYPE);\
	SAVEFREEPV(params);\
	result.pParameter = params;\
	result.ulParameterLen = sizeof *params;

#define specialize_pss(result, hash, generator, array, array_length) {\
	INIT_PARAMS(CK_RSA_PKCS_PSS_PARAMS);\
	params->hashAlg = hash;\
	params->mgf = generator;\
	if (array_len >= 1)\
		params->sLen = SvUV((array)[0]);\
}

#ifndef MIN
#	define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

static CK_BYTE* S_get_buffer(pTHX_ SV* buffer, CK_ULONG* length) {
	STRLEN len;
	char* temp = SvPVbyte(buffer, len);
	*length = len;
	return (CK_BYTE*)temp;
}
#define get_buffer(buffer, length) S_get_buffer(aTHX_ buffer, length)

static CK_MECHANISM S_specialize_mechanism(pTHX_ CK_MECHANISM_TYPE type, SV** array, size_t array_len) {
	CK_MECHANISM result = { type, NULL, 0 };

	switch (type) {
		case CKM_DES_ECB:
		case CKM_DES3_ECB:
		case CKM_AES_ECB:
			break;

		case CKM_DES_CBC:
		case CKM_DES_CBC_PAD:
		case CKM_DES3_CBC:
		case CKM_DES3_CBC_PAD:
		case CKM_AES_CBC:
		case CKM_AES_CBC_PAD:
			if (array_len < 1)
				Perl_croak(aTHX_ "No IV given for cipher needing it");
			result.pParameter = get_buffer(array[0], &result.ulParameterLen);
			break;

		case CKM_AES_CTR: {
			if (array_len < 1)
				Perl_croak(aTHX_ "No IV given for AES CTR");

			INIT_PARAMS(CK_AES_CTR_PARAMS);

			STRLEN len;
			const char* cb = SvPVbyte(array[0], len);
			memcpy(params->cb, cb, MIN(len, 16));

			params->ulCounterBits = array_len >= 2 ? SvUV(array[1]) : 128;

			break;
		}

		case CKM_AES_GCM: {
			if (array_len < 1)
				Perl_croak(aTHX_ "No IV given for AES-GCM");

			INIT_PARAMS(CK_GCM_PARAMS);

			params->pIv = get_buffer(array[0], &params->ulIvLen);
			params->ulIvBits = 8 * params->ulIvLen;

			if (array_len >= 2 && SvOK(array[1]))
				params->pAAD = get_buffer(array[1], &params->ulAADLen);

			params->ulTagBits = array_len >= 3 ? SvUV(array[2]) : 128;

			break;
		}

		case CKM_CHACHA20_POLY1305:
		case CKM_SALSA20_POLY1305: {
			if (array_len < 1)
				Perl_croak(aTHX_ "No nonce given for chacha20/salsa20");

			INIT_PARAMS(CK_SALSA20_CHACHA20_POLY1305_PARAMS);

			params->pNonce = get_buffer(array[0], &params->ulNonceLen);

			if (array_len >= 2 && SvOK(array[1]))
				params->pAAD = get_buffer(array[1], &params->ulAADLen);

			break;
		}

		case CKM_RSA_PKCS_PSS: {
			if (array_len < 1)
				Perl_croak(aTHX_ "No hash given for rsa-pkcs-pss");
			CK_MECHANISM_TYPE hash = get_mechanism_type(array[0]);
			CK_RSA_PKCS_MGF_TYPE generator = map_get(generators, array[0], "generator");
			specialize_pss(&result, hash, generator, array + 1, array_len - 1);
			break;
		}
		case CKM_SHA224_RSA_PKCS_PSS:
			specialize_pss(&result, CKM_SHA224, CKG_MGF1_SHA224, array, array_len);
			break;
		case CKM_SHA256_RSA_PKCS_PSS:
			specialize_pss(&result, CKM_SHA256, CKG_MGF1_SHA256, array, array_len);
			break;
		case CKM_SHA384_RSA_PKCS_PSS:
			specialize_pss(&result, CKM_SHA384, CKG_MGF1_SHA384, array, array_len);
			break;
		case CKM_SHA512_RSA_PKCS_PSS:
			specialize_pss(&result, CKM_SHA512, CKG_MGF1_SHA512, array, array_len);
			break;

		case CKM_ECDH1_DERIVE:
		case CKM_ECDH1_COFACTOR_DERIVE: {
			if (array_len < 2)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			INIT_PARAMS(CK_ECDH1_DERIVE_PARAMS);

			params->pPublicData = get_buffer(array[0], &params->ulPublicDataLen);

			params->kdf = array_len > 1 ? map_get(kdfs, array[1], "kdf") : CKD_NULL;

			if (array_len > 2)
				params->pSharedData = get_buffer(array[2], &params->ulSharedDataLen);

			break;
		}

		case CKM_DH_PKCS_DERIVE: {
			if (array_len < 1)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			result.pParameter = get_buffer(array[0], &result.ulParameterLen);

			break;
		}

		case CKM_DES_ECB_ENCRYPT_DATA:
		case CKM_DES3_ECB_ENCRYPT_DATA:
		case CKM_CONCATENATE_DATA_AND_BASE:
		case CKM_CONCATENATE_BASE_AND_DATA:
		case CKM_AES_ECB_ENCRYPT_DATA: {
			if (array_len < 1)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			INIT_PARAMS(CK_KEY_DERIVATION_STRING_DATA);

			params->pData = get_buffer(array[0], &params->ulLen);

			break;
		}

		case CKM_CONCATENATE_BASE_AND_KEY: {
			if (array_len < 1)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			INIT_PARAMS(CK_OBJECT_HANDLE);

			*params = SvUV(array[0]);

			break;
		}

		case CKM_DES_CBC_ENCRYPT_DATA:
		case CKM_DES3_CBC_ENCRYPT_DATA: {
			if (array_len < 2)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			INIT_PARAMS(CK_DES_CBC_ENCRYPT_DATA_PARAMS);

			params->pData = get_buffer(array[0], &params->length);
			STRLEN length;
			const char* iv = SvPVbyte(array[1], length);
			memcpy(params->iv, iv, MIN(sizeof params->iv, length));

			break;
		}

		case CKM_AES_CBC_ENCRYPT_DATA: {
			if (array_len < 2)
				Perl_croak(aTHX_ "Insufficient parameters for derivation");

			INIT_PARAMS(CK_AES_CBC_ENCRYPT_DATA_PARAMS);

			params->pData = get_buffer(array[0], &params->length);
			STRLEN length;
			const char* iv = SvPVbyte(array[1], length);
			memcpy(params->iv, iv, MIN(sizeof params->iv, length));

			break;
		}

		case CKM_RSA_PKCS_OAEP: {
			if (array_len < 2)
				Perl_croak(aTHX_ "Insufficient parameters for rsa-pkcs-oaep");

			INIT_PARAMS(CK_RSA_PKCS_OAEP_PARAMS);

			params->hashAlg = get_mechanism_type(array[0]);
			params->mgf = map_get(generators, array[0], "generator");
			params->source = SvTRUE(array[1]);

			if (array_len > 2)
				params->pSourceData = get_buffer(array[2], &params->ulSourceDataLen);

			break;
		}

		case CKM_EDDSA: {
			if (array_len) {
				INIT_PARAMS(CK_EDDSA_PARAMS);

				params->phFlag = SvTRUE(array[0]);

				if (array_len > 1)
					params->pContextData = get_buffer(array[0], &params->ulContextDataLen);
			}
		}
	}

	return result;
}
#define mechanism_from_args(mechanism, offset) S_specialize_mechanism(aTHX_ mechanism, PL_stack_base + ax + offset, items - offset);

static const map object_classes = {
	{ STR_WITH_LEN("data"), CKO_DATA },
	{ STR_WITH_LEN("certificate"), CKO_CERTIFICATE },
	{ STR_WITH_LEN("public-key"), CKO_PUBLIC_KEY },
	{ STR_WITH_LEN("private-key"), CKO_PRIVATE_KEY },
	{ STR_WITH_LEN("secret-key"), CKO_SECRET_KEY },
	{ STR_WITH_LEN("hw-feature"), CKO_HW_FEATURE },
	{ STR_WITH_LEN("domain-parameters"), CKO_DOMAIN_PARAMETERS },
	{ STR_WITH_LEN("mechanism"), CKO_MECHANISM },
	{ STR_WITH_LEN("otp-key"), CKO_OTP_KEY },
	{ STR_WITH_LEN("profile"), CKO_PROFILE },
	{ STR_WITH_LEN("vendor-defined"), CKO_VENDOR_DEFINED },
};
#define get_object_class(input) map_get(object_classes, input, "object class")

static const map key_types = {
	{ STR_WITH_LEN("rsa"), CKK_RSA },
	{ STR_WITH_LEN("dsa"), CKK_DSA },
	{ STR_WITH_LEN("dh"), CKK_DH },
	{ STR_WITH_LEN("ecdsa"), CKK_ECDSA },
	{ STR_WITH_LEN("ec"), CKK_EC },
	{ STR_WITH_LEN("x9-42-dh"), CKK_X9_42_DH },
	{ STR_WITH_LEN("kea"), CKK_KEA },
	{ STR_WITH_LEN("generic-secret"), CKK_GENERIC_SECRET },
	{ STR_WITH_LEN("rc2"), CKK_RC2 },
	{ STR_WITH_LEN("rc4"), CKK_RC4 },
	{ STR_WITH_LEN("des"), CKK_DES },
	{ STR_WITH_LEN("des2"), CKK_DES2 },
	{ STR_WITH_LEN("des3"), CKK_DES3 },
	{ STR_WITH_LEN("cast"), CKK_CAST },
	{ STR_WITH_LEN("cast3"), CKK_CAST3 },
	{ STR_WITH_LEN("cast5"), CKK_CAST5 },
	{ STR_WITH_LEN("cast128"), CKK_CAST128 },
	{ STR_WITH_LEN("rc5"), CKK_RC5 },
	{ STR_WITH_LEN("idea"), CKK_IDEA },
	{ STR_WITH_LEN("skipjack"), CKK_SKIPJACK },
	{ STR_WITH_LEN("baton"), CKK_BATON },
	{ STR_WITH_LEN("juniper"), CKK_JUNIPER },
	{ STR_WITH_LEN("cdmf"), CKK_CDMF },
	{ STR_WITH_LEN("aes"), CKK_AES },
	{ STR_WITH_LEN("blowfish"), CKK_BLOWFISH },
	{ STR_WITH_LEN("twofish"), CKK_TWOFISH },
	{ STR_WITH_LEN("securid"), CKK_SECURID },
	{ STR_WITH_LEN("hotp"), CKK_HOTP },
	{ STR_WITH_LEN("acti"), CKK_ACTI },
	{ STR_WITH_LEN("camellia"), CKK_CAMELLIA },
	{ STR_WITH_LEN("aria"), CKK_ARIA },
	{ STR_WITH_LEN("md5-hmac"), CKK_MD5_HMAC },
	{ STR_WITH_LEN("sha1-hmac"), CKK_SHA_1_HMAC },
	{ STR_WITH_LEN("ripemd128-hmac"), CKK_RIPEMD128_HMAC },
	{ STR_WITH_LEN("ripemd160-hmac"), CKK_RIPEMD160_HMAC },
	{ STR_WITH_LEN("sha256-hmac"), CKK_SHA256_HMAC },
	{ STR_WITH_LEN("sha384-hmac"), CKK_SHA384_HMAC },
	{ STR_WITH_LEN("sha512-hmac"), CKK_SHA512_HMAC },
	{ STR_WITH_LEN("sha224-hmac"), CKK_SHA224_HMAC },
	{ STR_WITH_LEN("seed"), CKK_SEED },
	{ STR_WITH_LEN("gostr3410"), CKK_GOSTR3410 },
	{ STR_WITH_LEN("gostr3411"), CKK_GOSTR3411 },
	{ STR_WITH_LEN("gost28147"), CKK_GOST28147 },
	{ STR_WITH_LEN("chacha20"), CKK_CHACHA20 },
	{ STR_WITH_LEN("poly1305"), CKK_POLY1305 },
	{ STR_WITH_LEN("aes-xts"), CKK_AES_XTS },
	{ STR_WITH_LEN("sha3-224-hmac"), CKK_SHA3_224_HMAC },
	{ STR_WITH_LEN("sha3-256-hmac"), CKK_SHA3_256_HMAC },
	{ STR_WITH_LEN("sha3-384-hmac"), CKK_SHA3_384_HMAC },
	{ STR_WITH_LEN("sha3-512-hmac"), CKK_SHA3_512_HMAC },
	{ STR_WITH_LEN("blake2b-160-hmac"), CKK_BLAKE2B_160_HMAC },
	{ STR_WITH_LEN("blake2b-256-hmac"), CKK_BLAKE2B_256_HMAC },
	{ STR_WITH_LEN("blake2b-384-hmac"), CKK_BLAKE2B_384_HMAC },
	{ STR_WITH_LEN("blake2b-512-hmac"), CKK_BLAKE2B_512_HMAC },
	{ STR_WITH_LEN("salsa20"), CKK_SALSA20 },
	{ STR_WITH_LEN("x2ratchet"), CKK_X2RATCHET },
	{ STR_WITH_LEN("ec-edwards"), CKK_EC_EDWARDS },
	{ STR_WITH_LEN("ec-montgomery"), CKK_EC_MONTGOMERY },
	{ STR_WITH_LEN("hkdf"), CKK_HKDF },
	{ STR_WITH_LEN("sha512-224-hmac"), CKK_SHA512_224_HMAC },
	{ STR_WITH_LEN("sha512-256-hmac"), CKK_SHA512_256_HMAC },
	{ STR_WITH_LEN("sha512-t-hmac"), CKK_SHA512_T_HMAC },
	{ STR_WITH_LEN("hss"), CKK_HSS },
	{ STR_WITH_LEN("vendor-defined"), CKK_VENDOR_DEFINED },
};
#define get_key_type(input) map_get(key_types, input, "key type")

static const map certificate_types = {
	{ STR_WITH_LEN("x-509"), CKC_X_509 },
	{ STR_WITH_LEN("x-509-attr-cert"), CKC_X_509_ATTR_CERT },
	{ STR_WITH_LEN("wtls"), CKC_WTLS },
	{ STR_WITH_LEN("vendor-defined"), CKC_VENDOR_DEFINED },
};
#define get_cert_type(input) map_get(certificate_types, input, "cert type")

static const map certificate_categories = {
	{ STR_WITH_LEN("certificate-category-unspecified"), CK_CERTIFICATE_CATEGORY_UNSPECIFIED },
	{ STR_WITH_LEN("certificate-category-token-user"), CK_CERTIFICATE_CATEGORY_TOKEN_USER },
	{ STR_WITH_LEN("certificate-category-authority"), CK_CERTIFICATE_CATEGORY_AUTHORITY },
	{ STR_WITH_LEN("certificate-category-other-entity"), CK_CERTIFICATE_CATEGORY_OTHER_ENTITY },
};
#define get_cert_cat(input) map_get(certificate_categories, input, "cert type")

static const map hardware_types = {
	{ STR_WITH_LEN("monotonic-counter"), CKH_MONOTONIC_COUNTER },
	{ STR_WITH_LEN("clock"), CKH_CLOCK },
	{ STR_WITH_LEN("user-interface"), CKH_USER_INTERFACE },
	{ STR_WITH_LEN("vendor-defined"), CKH_VENDOR_DEFINED },
};
#define get_hardware_type(input) map_get(hardware_types, input, "hardware type")

typedef struct Attributes {
	size_t length;
	CK_ATTRIBUTE* member;
} Attributes;

enum Attribute_type { IntAttr, BoolAttr, StrAttr, ByteAttr, ClassAttr, BigintAttr, KeyTypeAttr, CertTypeAttr, CertCatAttr, HardwareTypeAttr, IntArrayAttr, AttrAttr };

typedef struct { const char* key; size_t length; CK_ULONG value; enum Attribute_type type; } attribute_entry;
typedef attribute_entry attribute_map[];

static const attribute_map attributes = {
	{ STR_WITH_LEN("class"), CKA_CLASS, ClassAttr },
	{ STR_WITH_LEN("token"), CKA_TOKEN, BoolAttr },
	{ STR_WITH_LEN("private"), CKA_PRIVATE, BoolAttr },
	{ STR_WITH_LEN("label"), CKA_LABEL, StrAttr },
	{ STR_WITH_LEN("unique-id"), CKA_UNIQUE_ID, StrAttr },
	{ STR_WITH_LEN("application"), CKA_APPLICATION, StrAttr },
	{ STR_WITH_LEN("value"), CKA_VALUE, ByteAttr },
	{ STR_WITH_LEN("object-id"), CKA_OBJECT_ID, ByteAttr },
	{ STR_WITH_LEN("certificate-type"), CKA_CERTIFICATE_TYPE, CertTypeAttr },
	{ STR_WITH_LEN("issuer"), CKA_ISSUER, ByteAttr },
	{ STR_WITH_LEN("serial-number"), CKA_SERIAL_NUMBER, ByteAttr },
	{ STR_WITH_LEN("ac-issuer"), CKA_AC_ISSUER, ByteAttr },
	{ STR_WITH_LEN("owner"), CKA_OWNER, ByteAttr },
	{ STR_WITH_LEN("attr-types"), CKA_ATTR_TYPES, ByteAttr },
	{ STR_WITH_LEN("trusted"), CKA_TRUSTED, BoolAttr },
	{ STR_WITH_LEN("certificate-category"), CKA_CERTIFICATE_CATEGORY, IntAttr },
	{ STR_WITH_LEN("java-midp-security-domain"), CKA_JAVA_MIDP_SECURITY_DOMAIN, IntAttr },
	{ STR_WITH_LEN("url"), CKA_URL, StrAttr },
	{ STR_WITH_LEN("hash-of-subject-public-key"), CKA_HASH_OF_SUBJECT_PUBLIC_KEY, ByteAttr },
	{ STR_WITH_LEN("hash-of-issuer-public-key"), CKA_HASH_OF_ISSUER_PUBLIC_KEY, ByteAttr },
	{ STR_WITH_LEN("name-hash-algorithm"), CKA_NAME_HASH_ALGORITHM, IntAttr },
	{ STR_WITH_LEN("check-value"), CKA_CHECK_VALUE, ByteAttr },
	{ STR_WITH_LEN("key-type"), CKA_KEY_TYPE, KeyTypeAttr },
	{ STR_WITH_LEN("subject"), CKA_SUBJECT, ByteAttr },
	{ STR_WITH_LEN("id"), CKA_ID, BigintAttr },
	{ STR_WITH_LEN("sensitive"), CKA_SENSITIVE, BoolAttr },
	{ STR_WITH_LEN("encrypt"), CKA_ENCRYPT, BoolAttr },
	{ STR_WITH_LEN("decrypt"), CKA_DECRYPT, BoolAttr },
	{ STR_WITH_LEN("wrap"), CKA_WRAP, BoolAttr },
	{ STR_WITH_LEN("unwrap"), CKA_UNWRAP, BoolAttr },
	{ STR_WITH_LEN("sign"), CKA_SIGN, BoolAttr },
	{ STR_WITH_LEN("sign-recover"), CKA_SIGN_RECOVER, BoolAttr },
	{ STR_WITH_LEN("verify"), CKA_VERIFY, BoolAttr },
	{ STR_WITH_LEN("verify-recover"), CKA_VERIFY_RECOVER, BoolAttr },
	{ STR_WITH_LEN("derive"), CKA_DERIVE, BoolAttr },
	{ STR_WITH_LEN("start-date"), CKA_START_DATE, StrAttr },
	{ STR_WITH_LEN("end-date"), CKA_END_DATE, StrAttr },
	{ STR_WITH_LEN("modulus"), CKA_MODULUS, BigintAttr },
	{ STR_WITH_LEN("modulus-bits"), CKA_MODULUS_BITS, IntAttr },
	{ STR_WITH_LEN("public-exponent"), CKA_PUBLIC_EXPONENT, BigintAttr },
	{ STR_WITH_LEN("private-exponent"), CKA_PRIVATE_EXPONENT, BigintAttr },
	{ STR_WITH_LEN("prime-1"), CKA_PRIME_1, BigintAttr },
	{ STR_WITH_LEN("prime-2"), CKA_PRIME_2, BigintAttr },
	{ STR_WITH_LEN("exponent-1"), CKA_EXPONENT_1, BigintAttr },
	{ STR_WITH_LEN("exponent-2"), CKA_EXPONENT_2, BigintAttr },
	{ STR_WITH_LEN("coefficient"), CKA_COEFFICIENT, BigintAttr },
	{ STR_WITH_LEN("public-key-info"), CKA_PUBLIC_KEY_INFO, ByteAttr },
	{ STR_WITH_LEN("prime"), CKA_PRIME, BigintAttr },
	{ STR_WITH_LEN("subprime"), CKA_SUBPRIME, BigintAttr },
	{ STR_WITH_LEN("base"), CKA_BASE, BigintAttr },
	{ STR_WITH_LEN("prime-bits"), CKA_PRIME_BITS, IntAttr },
	{ STR_WITH_LEN("subprime-bits"), CKA_SUBPRIME_BITS, IntAttr },
	{ STR_WITH_LEN("sub-prime-bits"), CKA_SUB_PRIME_BITS, IntAttr },
	{ STR_WITH_LEN("value-bits"), CKA_VALUE_BITS, IntAttr },
	{ STR_WITH_LEN("value-len"), CKA_VALUE_LEN, IntAttr },
	{ STR_WITH_LEN("extractable"), CKA_EXTRACTABLE, BoolAttr },
	{ STR_WITH_LEN("local"), CKA_LOCAL, BoolAttr },
	{ STR_WITH_LEN("never-extractable"), CKA_NEVER_EXTRACTABLE, BoolAttr },
	{ STR_WITH_LEN("always-sensitive"), CKA_ALWAYS_SENSITIVE, BoolAttr },
	{ STR_WITH_LEN("key-gen-mechanism"), CKA_KEY_GEN_MECHANISM, IntAttr },
	{ STR_WITH_LEN("modifiable"), CKA_MODIFIABLE, BoolAttr },
	{ STR_WITH_LEN("copyable"), CKA_COPYABLE, BoolAttr },
	{ STR_WITH_LEN("destroyable"), CKA_DESTROYABLE, BoolAttr },
	{ STR_WITH_LEN("ecdsa-params"), CKA_ECDSA_PARAMS, BigintAttr },
	{ STR_WITH_LEN("ec-params"), CKA_EC_PARAMS, BigintAttr },
	{ STR_WITH_LEN("ec-point"), CKA_EC_POINT, BigintAttr },
	{ STR_WITH_LEN("secondary-auth"), CKA_SECONDARY_AUTH, BoolAttr },
	{ STR_WITH_LEN("auth-pin-flags"), CKA_AUTH_PIN_FLAGS, IntAttr },
	{ STR_WITH_LEN("always-authenticate"), CKA_ALWAYS_AUTHENTICATE, BoolAttr },
	{ STR_WITH_LEN("wrap-with-trusted"), CKA_WRAP_WITH_TRUSTED, BoolAttr },
	{ STR_WITH_LEN("wrap-template"), CKA_WRAP_TEMPLATE, AttrAttr },
	{ STR_WITH_LEN("unwrap-template"), CKA_UNWRAP_TEMPLATE, AttrAttr },
	{ STR_WITH_LEN("derive-template"), CKA_DERIVE_TEMPLATE, AttrAttr },
	{ STR_WITH_LEN("otp-format"), CKA_OTP_FORMAT, IntAttr },
	{ STR_WITH_LEN("otp-length"), CKA_OTP_LENGTH, IntAttr },
	{ STR_WITH_LEN("otp-time-interval"), CKA_OTP_TIME_INTERVAL, IntAttr },
	{ STR_WITH_LEN("otp-user-friendly-mode"), CKA_OTP_USER_FRIENDLY_MODE, BoolAttr },
	{ STR_WITH_LEN("otp-challenge-requirement"), CKA_OTP_CHALLENGE_REQUIREMENT, IntAttr },
	{ STR_WITH_LEN("otp-time-requirement"), CKA_OTP_TIME_REQUIREMENT, IntAttr },
	{ STR_WITH_LEN("otp-counter-requirement"), CKA_OTP_COUNTER_REQUIREMENT, IntAttr },
	{ STR_WITH_LEN("otp-pin-requirement"), CKA_OTP_PIN_REQUIREMENT, IntAttr },
	{ STR_WITH_LEN("otp-counter"), CKA_OTP_COUNTER, ByteAttr },
	{ STR_WITH_LEN("otp-time"), CKA_OTP_TIME, StrAttr },
	{ STR_WITH_LEN("otp-user-identifier"), CKA_OTP_USER_IDENTIFIER, StrAttr },
	{ STR_WITH_LEN("otp-service-identifier"), CKA_OTP_SERVICE_IDENTIFIER, StrAttr },
	{ STR_WITH_LEN("otp-service-logo"), CKA_OTP_SERVICE_LOGO, ByteAttr },
	{ STR_WITH_LEN("otp-service-logo-type"), CKA_OTP_SERVICE_LOGO_TYPE, StrAttr },
	{ STR_WITH_LEN("gostr3410-params"), CKA_GOSTR3410_PARAMS, ByteAttr },
	{ STR_WITH_LEN("gostr3411-params"), CKA_GOSTR3411_PARAMS, ByteAttr },
	{ STR_WITH_LEN("gost28147-params"), CKA_GOST28147_PARAMS, ByteAttr },
	{ STR_WITH_LEN("hw-feature-type"), CKA_HW_FEATURE_TYPE, IntAttr },
	{ STR_WITH_LEN("reset-on-init"), CKA_RESET_ON_INIT, BoolAttr },
	{ STR_WITH_LEN("has-reset"), CKA_HAS_RESET, BoolAttr },
	{ STR_WITH_LEN("pixel-x"), CKA_PIXEL_X, IntAttr },
	{ STR_WITH_LEN("pixel-y"), CKA_PIXEL_Y, IntAttr },
	{ STR_WITH_LEN("resolution"), CKA_RESOLUTION, IntAttr },
	{ STR_WITH_LEN("char-rows"), CKA_CHAR_ROWS, IntAttr },
	{ STR_WITH_LEN("char-columns"), CKA_CHAR_COLUMNS, IntAttr },
	{ STR_WITH_LEN("color"), CKA_COLOR, IntAttr },
	{ STR_WITH_LEN("bits-per-pixel"), CKA_BITS_PER_PIXEL, IntAttr },
	{ STR_WITH_LEN("char-sets"), CKA_CHAR_SETS, StrAttr },
	{ STR_WITH_LEN("encoding-methods"), CKA_ENCODING_METHODS, StrAttr },
	{ STR_WITH_LEN("mime-types"), CKA_MIME_TYPES, StrAttr },
	{ STR_WITH_LEN("mechanism-type"), CKA_MECHANISM_TYPE, IntAttr },
	{ STR_WITH_LEN("required-cms-attributes"), CKA_REQUIRED_CMS_ATTRIBUTES, ByteAttr },
	{ STR_WITH_LEN("default-cms-attributes"), CKA_DEFAULT_CMS_ATTRIBUTES, ByteAttr },
	{ STR_WITH_LEN("supported-cms-attributes"), CKA_SUPPORTED_CMS_ATTRIBUTES, ByteAttr },
	{ STR_WITH_LEN("allowed-mechanisms"), CKA_ALLOWED_MECHANISMS, IntArrayAttr },
	{ STR_WITH_LEN("profile-id"), CKA_PROFILE_ID, IntAttr },
	{ STR_WITH_LEN("x2ratchet-bag"), CKA_X2RATCHET_BAG, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-bagsize"), CKA_X2RATCHET_BAGSIZE, IntAttr },
	{ STR_WITH_LEN("x2ratchet-bobs1stmsg"), CKA_X2RATCHET_BOBS1STMSG, BoolAttr },
	{ STR_WITH_LEN("x2ratchet-ckr"), CKA_X2RATCHET_CKR, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-cks"), CKA_X2RATCHET_CKS, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-dhp"), CKA_X2RATCHET_DHP, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-dhr"), CKA_X2RATCHET_DHR, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-dhs"), CKA_X2RATCHET_DHS, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-hkr"), CKA_X2RATCHET_HKR, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-hks"), CKA_X2RATCHET_HKS, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-isalice"), CKA_X2RATCHET_ISALICE, BoolAttr },
	{ STR_WITH_LEN("x2ratchet-nhkr"), CKA_X2RATCHET_NHKR, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-nhks"), CKA_X2RATCHET_NHKS, ByteAttr },
	{ STR_WITH_LEN("x2ratchet-nr"), CKA_X2RATCHET_NR, IntAttr },
	{ STR_WITH_LEN("x2ratchet-ns"), CKA_X2RATCHET_NS, IntAttr },
	{ STR_WITH_LEN("x2ratchet-pns"), CKA_X2RATCHET_PNS, IntAttr },
	{ STR_WITH_LEN("x2ratchet-rk"), CKA_X2RATCHET_RK, ByteAttr },
	{ STR_WITH_LEN("hss-levels"), CKA_HSS_LEVELS, IntAttr },
	{ STR_WITH_LEN("hss-lms-type"), CKA_HSS_LMS_TYPE, IntAttr },
	{ STR_WITH_LEN("hss-lmots-type"), CKA_HSS_LMOTS_TYPE, IntAttr },
	{ STR_WITH_LEN("hss-lms-types"), CKA_HSS_LMS_TYPES, IntArrayAttr },
	{ STR_WITH_LEN("hss-lmots-types"), CKA_HSS_LMOTS_TYPES, IntArrayAttr },
	{ STR_WITH_LEN("hss-keys-remaining"), CKA_HSS_KEYS_REMAINING, IntAttr },
	{ STR_WITH_LEN("vendor-defined"), CKA_VENDOR_DEFINED, ByteAttr },
};

static const attribute_entry* S_get_attribute_entry(pTHX_ const char* name, size_t name_length) {
	size_t i;
	for (i = 0; i < sizeof attributes / sizeof *attributes; ++i) {
		if (attributes[i].length == name_length && strEQ(name, attributes[i].key))
			return &attributes[i];
	}
	return NULL;
}
#define get_attribute_entry(name, name_length) S_get_attribute_entry(aTHX_ name, name_length)

static void S_set_intval(pTHX_ CK_ATTRIBUTE* current, CK_ULONG value) {
	Newxz(current->pValue, 1, CK_ULONG);
	SAVEFREEPV(current->pValue);
	current->ulValueLen = sizeof(CK_ULONG);
	*(CK_ULONG*)current->pValue = value;
}
#define set_intval(current, value) S_set_intval(aTHX_ current, value)

#define get_attributes(attributes) S_get_attributes(aTHX_ attributes)
static struct Attributes S_get_attributes(pTHX_ SV* attributes_sv) {
	struct Attributes result = { 0, NULL };
	if (!SvOK(attributes_sv))
		return result;

	if (!SvROK(attributes_sv) || SvTYPE(SvRV(attributes_sv)) != SVt_PVHV)
		Perl_croak(aTHX_ "Invalid attributes parameter");
	HV* attributes = (HV*) SvRV(attributes_sv);
	Newxz(result.member, HvUSEDKEYS(attributes), CK_ATTRIBUTE);
	SAVEFREEPV(result.member);

	HE* item;
	hv_iterinit(attributes);

	while((item = hv_iternext(attributes))) {
		I32 name_length;
		const char* name = hv_iterkey(item, &name_length);
		const attribute_entry* entry = get_attribute_entry(name, name_length);
		if (entry == NULL)
			Perl_croak(aTHX_ "No such attribute '%s'", name);

		CK_ATTRIBUTE* current = &result.member[result.length];

		current->type = entry->value;
		SV* value = hv_iterval(attributes, item);
		if (SvOK(value)) {
			switch (entry->type) {
				case IntAttr:
					set_intval(current, SvUV(value));
					break;
				case BoolAttr: {
					static const char bools[] = { '\0', '\1' };
					current->pValue = (char*)&bools[!!SvTRUE(value)];
					current->ulValueLen = 1;
					break;
				}
				case StrAttr: {
					STRLEN len;
					current->pValue = (void*)SvPVutf8(value, len);
					current->ulValueLen = len;
					break;
				}
				case BigintAttr:
					if (SvROK(value)) {
						if (SvTYPE(SvRV(value)) != SVt_PVAV)
							Perl_croak(aTHX_ "Invalid Bigint attribute value");
						AV* input = (AV*) SvRV(value);
						char* array;
						Newxz(array, av_len(input) + 1, char);
						SAVEFREEPV(array);
						size_t i;
						for (i = 0; i < av_count(input); ++i)
							array[i] = (char)SvUV(*av_fetch(input, i, FALSE));
						current->pValue = array;
						current->ulValueLen = av_len(input) + 1;
						break;
					}
					// FALLTHROUGH
				case ByteAttr: {
					current->pValue = get_buffer(value, &current->ulValueLen);
					break;
				}
				case ClassAttr: {
					set_intval(current, get_object_class(value));
					break;
				}
				case KeyTypeAttr: {
					set_intval(current, get_key_type(value));
					break;
				}
				case CertTypeAttr: {
					set_intval(current, get_cert_type(value));
					break;
				}
				case CertCatAttr: {
					set_intval(current, get_cert_cat(value));
					break;
				}
				case HardwareTypeAttr: {
					set_intval(current, get_hardware_type(value));
					break;
				}

				case IntArrayAttr: {
					if (!SvROK(value) || SvTYPE(SvRV(value)) != SVt_PVAV)
						Perl_croak(aTHX_ "Invalid IntArray attribute value");
					AV* array = (AV*) SvRV(value);
					CK_ULONG* values, i;
					Newxz(values, av_len(array) + 1, CK_ULONG);
					SAVEFREEPV(values);
					for (i = 0; i < av_count(array); ++i)
						values[i] = SvUV(*av_fetch(array, i, FALSE));
					current->pValue = value;
					current->ulValueLen = av_len(array) + 1;
					break;
				}
				case AttrAttr: {
					struct Attributes child = get_attributes(value);
					current->pValue = child.member;
					current->ulValueLen = child.length * sizeof(CK_ATTRIBUTE);
					break;
				}
				default:
					Perl_croak(aTHX_ "HERE");
			}
		}
		result.length++;
	}

	return result;
}


static const attribute_entry* S_attribute_reverse_find(pTHX_ CK_ULONG value) {
	size_t i;
	for (i = 0; i < sizeof attributes / sizeof *attributes; ++i) {
		if (attributes[i].value == value)
			return &attributes[i];
	}
	return NULL;
}
#define attribute_reverse_find(value) S_attribute_reverse_find(aTHX_ value)

#define get_intval(pointer) (*(const CK_ULONG*)pointer)

static SV* S_entry_to_sv(pTHX_ const entry* item) {
	return item ? newSVpvn(item->key, item->length) : newSVpvs("unknown");
}
#define entry_to_sv(item) S_entry_to_sv(aTHX_ item)

#define reverse_attribute(attr) S_reverse_attribute(aTHX_ attr)
static SV* S_reverse_attribute(pTHX_ CK_ATTRIBUTE* attribute) {
	if (attribute->ulValueLen == 0 || attribute->ulValueLen == CK_UNAVAILABLE_INFORMATION)
		return &PL_sv_undef;

	const attribute_entry* reversed = attribute_reverse_find(attribute->type);
	if (reversed == NULL)
		return &PL_sv_undef;

	void* pointer = attribute->pValue;
	CK_ULONG length = attribute->ulValueLen;

	switch (reversed->type) {
		case IntAttr:
			return newSVuv(get_intval(pointer));
		case BoolAttr:
			return newSVsv(boolSV(*(const char*)pointer));
		case StrAttr: {
			SV* result = newSVpvn_utf8(pointer, length, TRUE);
			sv_utf8_downgrade(result, TRUE);
			return result;
		}
		case BigintAttr:
		case ByteAttr:
			return newSVpvn(pointer, length);
		case ClassAttr: {
			CK_ULONG integer = get_intval(pointer);
			return entry_to_sv(map_reverse_find(object_classes, integer));
		}
		case KeyTypeAttr: {
			CK_ULONG integer = get_intval(pointer);
			return entry_to_sv(map_reverse_find(key_types, integer));
		}
		case CertTypeAttr: {
			CK_ULONG integer = get_intval(pointer);
			return entry_to_sv(map_reverse_find(certificate_types, integer));
		}
		case CertCatAttr: {
			CK_ULONG integer = get_intval(pointer);
			return entry_to_sv(map_reverse_find(certificate_categories, integer));
		}
		case HardwareTypeAttr: {
			CK_ULONG integer = get_intval(pointer);
			return entry_to_sv(map_reverse_find(hardware_types, integer));
		}
		case IntArrayAttr: {
			AV* result = newAV();
			CK_ULONG* values = (CK_ULONG*) pointer;
			size_t elems = length / sizeof(CK_ULONG), i;
			for (i = 0; i < elems; ++i)
				av_push(result, newSVuv(values[i]));
			return newRV_noinc((SV*)result);
		}
		case AttrAttr: {
			HV* result = newHV();
			CK_ATTRIBUTE* values = (CK_ATTRIBUTE*) pointer;
			size_t elems = length / sizeof(CK_ATTRIBUTE), i;
			for (i = 0; i < elems; ++i) {
				const attribute_entry* reversed2 = attribute_reverse_find(attribute->type);
				if (reversed2)
					hv_store(result, reversed2->key, reversed2->length, reverse_attribute(&values[i]), 0);
			}
			return newRV_noinc((SV*)result);
		}
		default:
			Perl_croak(aTHX_ "Unknown type");
	}
}

static const map user_types = {
	{ STR_WITH_LEN("so"), CKU_SO },
	{ STR_WITH_LEN("user"), CKU_USER },
	{ STR_WITH_LEN("context-specific"), CKU_CONTEXT_SPECIFIC },
};
#define get_user_type(input) map_get(user_types, input, "user type")

static SV* S_trimmed_value(pTHX_ const CK_BYTE* ptr, size_t max) {
	ptrdiff_t last = max - 1;
	while (last >= 0 && ptr[last] == ' ')
		last--;
	return newSVpvn((const char*)ptr, last + 1);
}
#define trimmed_value(ptr, max) S_trimmed_value(aTHX_ ptr, max)

static SV* S_version_to_sv(pTHX_ CK_VERSION* version) {
	return newSVpvf("%d.%02d", version->major, version->minor);
}
#define version_to_sv(version) S_version_to_sv(aTHX_ version)

struct Provider {
	Refcount refcount;
	void* handle;
	CK_FUNCTION_LIST* funcs;
};
typedef struct Provider* Crypt__HSM;

static struct Provider* S_provider_refcount_increment(pTHX_ struct Provider* provider) {
	refcount_inc(&provider->refcount);
	return provider;
}
#define provider_refcount_increment(provider) S_provider_refcount_increment(aTHX_ provider)

static void S_provider_refcount_decrement(pTHX_ struct Provider* provider) {
	if (refcount_dec(&provider->refcount) == 1) {
		provider->funcs->C_Finalize(NULL);
		dlclose(provider->handle);
		refcount_destroy(&provider->refcount);
		PerlMemShared_free(provider);
	}
}
#define provider_refcount_decrement(provider) S_provider_refcount_decrement(aTHX_ provider)

static int provider_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
	PERL_UNUSED_VAR(params);
	provider_refcount_increment((struct Provider*)magic->mg_ptr);
	return 0;
}

static int provider_free(pTHX_ SV* sv, MAGIC* magic) {
	PERL_UNUSED_VAR(sv);
	provider_refcount_decrement((struct Provider*)magic->mg_ptr);
	return 0;
}

static const MGVTBL Crypt__HSM_magic = { NULL, NULL, NULL, NULL, provider_free, NULL, provider_dup, NULL };

struct Slot {
	struct Provider* provider;
	CK_SLOT_ID slot;
};
typedef struct Slot* Crypt__HSM__Slot;

static SV* S_new_slot(pTHX_ struct Provider* provider, CK_SLOT_ID slot) {
	struct Slot* entry;
	Newxz(entry, 1, struct Slot);
	entry->slot = slot;
	entry->provider = provider_refcount_increment(provider);
	SV* object = newSV(0);
	sv_setref_pv(object, "Crypt::HSM::Slot", (void*)entry);
	return object;
}
#define new_slot(provider, slot) S_new_slot(aTHX_ provider, slot)

struct Mechanism {
	struct Provider* provider;
	CK_SLOT_ID slot;
	CK_MECHANISM_TYPE mechanism;
	CK_MECHANISM_INFO info;
	bool initialized;
};
typedef struct Mechanism* Crypt__HSM__Mechanism;

static SV* S_new_mechanism(pTHX_ struct Provider* provider, CK_SLOT_ID slot, CK_MECHANISM_TYPE mechanism) {
	struct Mechanism* entry;
	Newxz(entry, 1, struct Mechanism);
	entry->mechanism = mechanism;
	entry->slot = slot;
	entry->provider = provider_refcount_increment(provider);
	SV* object = newSV(0);
	sv_setref_pv(object, "Crypt::HSM::Mechanism", (void*)entry);
	return object;
}
#define new_mechanism(provider, slot, mechanism) S_new_mechanism(aTHX_ provider, slot, mechanism)

static CK_MECHANISM_TYPE S_get_mechanism_type(pTHX_ SV* input) {
	if (SvROK(input) && sv_derived_from(input, "Crypt::HSM::Mechanism")) {
		IV tmp = SvIV(SvRV(input));
		struct Mechanism* mech = INT2PTR(struct Mechanism*, tmp);
		return mech->mechanism;
	} else {
		return map_get(mechanisms, input, "mechanism");
	}
}

static const CK_MECHANISM_INFO* S_get_mechanism_info(pTHX_ struct Mechanism* self) {
	CK_RV result = CKR_OK;
	if (!self->initialized) {
		result = self->provider->funcs->C_GetMechanismInfo(self->slot, self->mechanism, &self->info);
		if (result != CKR_OK)
			croak_with("Couldn't get mechanism info", result);
		self->initialized = 1;
	}
	return &self->info;
}
#define get_mechanism_info(self) S_get_mechanism_info(aTHX_ self)

struct Session {
	Refcount refcount;
	CK_SLOT_ID slot;
	CK_SESSION_HANDLE handle;
	struct Provider* provider;
};
typedef struct Session* Crypt__HSM__Session;

static struct Session* S_session_refcount_increment(pTHX_ struct Session* session) {
	refcount_inc(&session->refcount);
	return session;
}
#define session_refcount_increment(session) S_session_refcount_increment(aTHX_ session)

static void S_session_refcount_decrement(pTHX_ struct Session* session) {
	if (refcount_dec(&session->refcount) == 1) {
		session->provider->funcs->C_CloseSession(session->handle);
		provider_refcount_decrement(session->provider);
		refcount_destroy(&session->refcount);
		Safefree(session);
	}
}
#define session_refcount_decrement(session) S_session_refcount_decrement(aTHX_ session)

struct Stream {
	struct Session* session;
	CK_OBJECT_HANDLE encrypt_key;
	CK_OBJECT_HANDLE sign_key;
};

typedef struct Stream* Crypt__HSM__Stream;
typedef struct Stream* Crypt__HSM__Encrypt;
typedef struct Stream* Crypt__HSM__Decrypt;
typedef struct Stream* Crypt__HSM__Digest;
typedef struct Stream* Crypt__HSM__Sign;
typedef struct Stream* Crypt__HSM__Verify;

#define CLONE_SKIP() 1

MODULE = Crypt::HSM	 PACKAGE = Crypt::HSM		PREFIX = provider_

PROTOTYPES: DISABLED

BOOT:
	SV* stream = newSVpvs("Crypt::HSM::Stream");
	av_push(get_av("Crypt::HSM::Encrypt::ISA", GV_ADD), SvREFCNT_inc(stream));
	av_push(get_av("Crypt::HSM::Decrypt::ISA", GV_ADD), SvREFCNT_inc(stream));
	av_push(get_av("Crypt::HSM::Digest::ISA", GV_ADD), SvREFCNT_inc(stream));
	av_push(get_av("Crypt::HSM::Sign::ISA", GV_ADD), SvREFCNT_inc(stream));
	av_push(get_av("Crypt::HSM::Verify::ISA", GV_ADD), SvREFCNT_inc(stream));
	SvREFCNT_dec(stream);


Crypt::HSM load(SV* class, const char* path)
CODE:
	PERL_UNUSED_VAR(class);
	RETVAL = (struct Provider*) PerlMemShared_calloc(1, sizeof(struct Provider));
	refcount_init(&RETVAL->refcount, 1);

	RETVAL->handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL);
	if (!RETVAL->handle)
		Perl_croak(aTHX_ "Can not open library");

	CK_RV (*C_GetFunctionList)() = (CK_RV (*)())dlsym(RETVAL->handle, "C_GetFunctionList");
	if (C_GetFunctionList == NULL)
		Perl_croak(aTHX_ "Symbol lookup failed");

	CK_RV rc = C_GetFunctionList(&RETVAL->funcs);
	if (rc != CKR_OK)
		croak_with("Call to C_GetFunctionList failed", rc);
#if defined(USE_THREADS) || defined(__linux__)
	CK_C_INITIALIZE_ARGS init_args = { NULL, NULL, NULL, NULL, CKF_OS_LOCKING_OK, NULL };
#else
	CK_C_INITIALIZE_ARGS init_args = { NULL, NULL, NULL, NULL, CKF_LIBRARY_CANT_CREATE_OS_THREADS, NULL };
#endif
	rc = RETVAL->funcs->C_Initialize(&init_args);
	if (rc != CKR_OK)
		croak_with("Call to C_Initialize failed", rc);
OUTPUT:
	RETVAL


HV* info(Crypt::HSM self)
CODE:
	CK_INFO info;
	CK_RV result = self->funcs->C_GetInfo(&info);
	if (result != CKR_OK)
		croak_with("Couldn't get provider info", result);

	RETVAL = newHV();
	hv_stores(RETVAL, "cryptoki-version", version_to_sv(&info.cryptokiVersion));
	hv_stores(RETVAL, "manufacturer-id", trimmed_value(info.manufacturerID, 32));
	hv_stores(RETVAL, "flags", newRV_noinc((SV*)newAV()));
	hv_stores(RETVAL, "library-description", trimmed_value(info.libraryDescription, 32));
	hv_stores(RETVAL, "library-version", version_to_sv(&info.libraryVersion));
OUTPUT:
	RETVAL


void slots(Crypt::HSM self, CK_BBOOL tokenPresent = 1)
PPCODE:
	CK_ULONG count, i;

	CK_RV result = self->funcs->C_GetSlotList(tokenPresent, NULL, &count);
	if ( result != CKR_OK )
		croak_with("Couldn't get slots", result);

	EXTEND(SP, (int)count);

	CK_SLOT_ID_PTR slotList;
	Newxz(slotList, count, CK_SLOT_ID);
	SAVEFREEPV(slotList);

	result = self->funcs->C_GetSlotList(tokenPresent, slotList, &count);
	if (result != CKR_OK)
		croak_with("Couldn't get slots", result);

	for(i = 0; i < count; i++)
		mPUSHs(new_slot(self, slotList[i]));


SV* slot(Crypt::HSM self, CK_SLOT_ID slot)
CODE:
	RETVAL = new_slot(self, slot);
OUTPUT:
	RETVAL

MODULE = Crypt::HSM	 PACKAGE = Crypt::HSM::Slot

void DESTROY(Crypt::HSM::Slot self)
CODE:
	provider_refcount_decrement(self->provider);

CK_SLOT_ID id(Crypt::HSM::Slot self)
CODE:
	RETVAL = self->slot;
OUTPUT:
	RETVAL

HV* info(Crypt::HSM::Slot self)
CODE:
	CK_SLOT_INFO info;
	CK_RV result = self->provider->funcs->C_GetSlotInfo(self->slot, &info);
	if (result != CKR_OK)
		croak_with("Couldn't get slot info", result);

	RETVAL = newHV();
	hv_stores(RETVAL, "slot-description", trimmed_value(info.slotDescription, 64));
	hv_stores(RETVAL, "manufacturer-id", trimmed_value(info.manufacturerID, 32));
	hv_stores(RETVAL, "flags", newRV_noinc((SV*)reverse_flags(slot_flags, info.flags)));
	hv_stores(RETVAL, "hardware-version", version_to_sv(&info.hardwareVersion));
	hv_stores(RETVAL, "firmware-version", version_to_sv(&info.firmwareVersion));
OUTPUT:
	RETVAL

HV* token_info(Crypt::HSM::Slot self)
CODE:
	CK_TOKEN_INFO info;
	CK_RV result = self->provider->funcs->C_GetTokenInfo(self->slot, &info);
	if (result != CKR_OK)
		croak_with("Couldn't get token info", result);

	RETVAL = newHV();
	hv_stores(RETVAL, "label", trimmed_value(info.label, 32));
	hv_stores(RETVAL, "manufacturer-id", trimmed_value(info.manufacturerID, 32));
	hv_stores(RETVAL, "model", trimmed_value(info.model, 16));
	hv_stores(RETVAL, "serial-number", trimmed_value(info.serialNumber, 16));
	hv_stores(RETVAL, "flags", newRV_noinc((SV*)reverse_flags(token_flags, info.flags)));
	hv_stores(RETVAL, "max-session-count", newSVuv(info.ulMaxSessionCount));
	hv_stores(RETVAL, "session-count", newSVuv(info.ulSessionCount));
	hv_stores(RETVAL, "max-rw-session-count", newSVuv(info.ulMaxRwSessionCount));
	hv_stores(RETVAL, "rw-session-count", newSVuv(info.ulRwSessionCount));
	hv_stores(RETVAL, "max-pin-len", newSVuv(info.ulMaxPinLen));
	hv_stores(RETVAL, "min-pin-len", newSVuv(info.ulMinPinLen));
	hv_stores(RETVAL, "total-public-memory", newSVuv(info.ulTotalPublicMemory));
	hv_stores(RETVAL, "free-public-memory", newSVuv(info.ulFreePublicMemory));
	hv_stores(RETVAL, "total-private-memory", newSVuv(info.ulTotalPrivateMemory));
	hv_stores(RETVAL, "free-private-memory", newSVuv(info.ulFreePrivateMemory));
	hv_stores(RETVAL, "hardware-version", version_to_sv(&info.hardwareVersion));
	hv_stores(RETVAL, "firmware-version", version_to_sv(&info.firmwareVersion));
	hv_stores(RETVAL, "utc-time", trimmed_value(info.utcTime, 16));
OUTPUT:
	RETVAL

Crypt::HSM::Session open_session(Crypt::HSM::Slot self, Session_flags flags = 0)
CODE:
	CK_NOTIFY Notify = NULL;
	Newxz(RETVAL, 1, struct Session);
	refcount_init(&RETVAL->refcount, 1);
	RETVAL->slot = self->slot;
	RETVAL->provider = provider_refcount_increment(self->provider);

	CK_RV result = self->provider->funcs->C_OpenSession(self->slot, flags | CKF_SERIAL_SESSION, NULL, Notify, &RETVAL->handle);
	if (result != CKR_OK)
		croak_with("Could not open session", result);
OUTPUT:
	RETVAL

void mechanisms(Crypt::HSM::Slot self)
PPCODE:
	CK_MECHANISM_TYPE* types;
	CK_ULONG length, i;
	CK_RV result = self->provider->funcs->C_GetMechanismList(self->slot, NULL, &length);
	if (result != CKR_OK)
		croak_with("Couldn't get mechanisms length", result);

	Newxz(types, length, CK_MECHANISM_TYPE);
	SAVEFREEPV(types);
	result = self->provider->funcs->C_GetMechanismList(self->slot, types, &length);
	if (result != CKR_OK)
		croak_with("Couldn't get mechanisms", result);

	for (i = 0; i < length; ++i)
		mXPUSHs(new_mechanism(self->provider, self->slot, types[i]));

SV* mechanism(Crypt::HSM::Slot self, CK_MECHANISM_TYPE type)
CODE:
	RETVAL = new_mechanism(self->provider, self->slot, type);
OUTPUT:
	RETVAL

void close_all_sessions(Crypt::HSM::Slot self)
CODE:
	CK_RV result = self->provider->funcs->C_CloseAllSessions(self->slot);
	if (result != CKR_OK)
		croak_with("Could not open session", result);


void init_token(Crypt::HSM::Slot self, SV* pin, SV* label)
CODE:
	CK_BYTE label_buffer[32];
	STRLEN pin_len, label_len;
	char* pinPV = SvPVutf8(pin, pin_len);
	char* labelPV = SvPVutf8(label, label_len);
	memset(label_buffer, ' ', 32);
	memcpy(label_buffer, labelPV, MIN(label_len, 32));

	CK_RV result = self->provider->funcs->C_InitToken(self->slot, (CK_BYTE*)pinPV, pin_len, label_buffer);
	if (result != CKR_OK)
		croak_with("Could not initialize token", result);


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Mechanism


void DESTROY(Crypt::HSM::Mechanism self)
CODE:
	provider_refcount_decrement(self->provider);

const char* name(Crypt::HSM::Mechanism self)
CODE:
	const entry* item = map_reverse_find(mechanisms, self->mechanism);
	RETVAL = item ? item->key : NULL;
OUTPUT:
	RETVAL


HV* info(Crypt::HSM::Mechanism self)
CODE:
	const CK_MECHANISM_INFO* info = get_mechanism_info(self);

	RETVAL = newHV();
	hv_stores(RETVAL, "min-key-size", newSVuv(info->ulMinKeySize));
	hv_stores(RETVAL, "max-key-size", newSVuv(info->ulMaxKeySize));
	hv_stores(RETVAL, "flags", newRV_noinc((SV*)reverse_flags(mechanism_flags, info->flags)));
OUTPUT:
	RETVAL


bool has_flags(Crypt::HSM::Mechanism self, ...)
CODE:
	CK_ULONG flags = 0, i;
	for (i = 1; i < items; ++i)
		flags |= get_flags(mechanism_flags, ST(i));
	const CK_MECHANISM_INFO* info = get_mechanism_info(self);
	RETVAL = (info->flags & flags) == flags;
OUTPUT:
	RETVAL


bool flags(Crypt::HSM::Mechanism self, ..)
PPCODE:
	const CK_MECHANISM_INFO* info = get_mechanism_info(self);
	AV* flags = reverse_flags(mechanism_flags, info->flags);
	int i;
	for (i = 0; i < av_count(flags); ++i)
		mXPUSHs(*av_fetch(flags, i, 0));
	SvREFCNT_dec((SV*)flags);


CK_ULONG min_key_size(Crypt::HSM::Mechanism self)
CODE:
	const CK_MECHANISM_INFO* info = get_mechanism_info(self);
	RETVAL = info->ulMinKeySize;
OUTPUT:
	RETVAL


CK_ULONG max_key_size(Crypt::HSM::Mechanism self)
CODE:
	const CK_MECHANISM_INFO* info = get_mechanism_info(self);
	RETVAL = info->ulMaxKeySize;
OUTPUT:
	RETVAL


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Session PREFIX = session_


void DESTROY(Crypt::HSM::Session self)
CODE:
	session_refcount_decrement(self);

HV* info(Crypt::HSM::Session self)
CODE:
	CK_SESSION_INFO info;
	CK_RV result = self->provider->funcs->C_GetSessionInfo(self->handle, &info);
	if (result != CKR_OK)
		croak_with("Couldn't get session info", result);

	RETVAL = newHV();
	hv_stores(RETVAL, "slot-id", newSVuv(info.slotID));
	hv_stores(RETVAL, "state", newRV_noinc((SV*)reverse_flags(state_flags, info.state)));
	hv_stores(RETVAL, "flags", newRV_noinc((SV*)reverse_flags(session_flags, info.flags)));
	hv_stores(RETVAL, "device-error", newSVuv(info.ulDeviceError));
OUTPUT:
	RETVAL


Crypt::HSM provider(Crypt::HSM::Session self)
CODE:
	RETVAL = provider_refcount_increment(self->provider);
OUTPUT:
	RETVAL


SV* slot(Crypt::HSM::Session self)
CODE:
	RETVAL = new_slot(self->provider, self->slot);
OUTPUT:
	RETVAL


void login(Crypt::HSM::Session self, CK_USER_TYPE type, SV* pin)
CODE:
	STRLEN pin_len;
	char* pinPV = SvPVutf8(pin, pin_len);
	CK_RV result = self->provider->funcs->C_Login(self->handle, type, (CK_BYTE*)pinPV, pin_len);
	if (result != CKR_OK)
		croak_with("Could not log in", result);


void logout(Crypt::HSM::Session self)
CODE:
	CK_RV result = self->provider->funcs->C_Logout(self->handle);
	if (result != CKR_OK)
		croak_with("Could not log out", result);


void init_pin(Crypt::HSM::Session self, SV* pin)
CODE:
	STRLEN pin_len;
	char* pinPV = SvPVutf8(pin, pin_len);

	CK_RV result = self->provider->funcs->C_InitPIN(self->handle, (CK_BYTE*)pinPV, pin_len);
	if (result != CKR_OK)
		croak_with("Could not initialize pin", result);


void set_pin(Crypt::HSM::Session self, SV* old_pin, SV* new_pin)
CODE:
	STRLEN old_pin_len, new_pin_len;
	char* old_pinPV = SvPVutf8(old_pin, old_pin_len);
	char* new_pinPV = SvPVutf8(new_pin, new_pin_len);

	CK_RV result = self->provider->funcs->C_SetPIN(self->handle, (CK_BYTE*)old_pinPV, old_pin_len, (CK_BYTE*)new_pinPV, new_pin_len);
	if (result != CKR_OK)
		croak_with("Could not set pin", result);


CK_OBJECT_HANDLE create_object(Crypt::HSM::Session self, Attributes template)
CODE:
	CK_RV result = self->provider->funcs->C_CreateObject(self->handle, template.member, template.length, &RETVAL);
	if (result != CKR_OK)
		croak_with("Could not create object", result);
OUTPUT:
	RETVAL


CK_OBJECT_HANDLE copy_object(Crypt::HSM::Session self, CK_OBJECT_HANDLE source, Attributes template)
CODE:
	CK_RV result = self->provider->funcs->C_CopyObject(self->handle, source, template.member, template.length, &RETVAL);
	if (result != CKR_OK)
		croak_with("Could not copy object", result);
OUTPUT:
	RETVAL


void destroy_object(Crypt::HSM::Session self, CK_OBJECT_HANDLE source)
CODE:
	CK_RV result = self->provider->funcs->C_DestroyObject(self->handle, source);
	if (result != CKR_OK)
		croak_with("Could not destroy object", result);

CK_ULONG object_size(Crypt::HSM::Session self, CK_OBJECT_HANDLE source)
CODE:
	CK_RV result = self->provider->funcs->C_GetObjectSize(self->handle, source, &RETVAL);
	if (result != CKR_OK)
		croak_with("Could not get object size", result);
OUTPUT:
	RETVAL

SV* get_attribute(Crypt::HSM::Session self, CK_OBJECT_HANDLE source, SV* attribute_name)
CODE:
	CK_ATTRIBUTE attribute;

	STRLEN name_length;
	const char* name = SvPVutf8(attribute_name, name_length);
	const attribute_entry* item = get_attribute_entry(name, name_length);
	if (item == NULL)
		Perl_croak(aTHX_ "No such attribute %s", name);
	attribute.type = item->value;

	CK_RV result = self->provider->funcs->C_GetAttributeValue(self->handle, source, &attribute, 1);
	if (result != CKR_OK && result != CKR_ATTRIBUTE_SENSITIVE && result != CKR_ATTRIBUTE_TYPE_INVALID && result !=CKR_BUFFER_TOO_SMALL)
		croak_with("Could not get attribute", result);

	if (attribute.ulValueLen != CK_UNAVAILABLE_INFORMATION) {
		Newxz(attribute.pValue, attribute.ulValueLen, char);
		SAVEFREEPV(attribute.pValue);
	}

	result = self->provider->funcs->C_GetAttributeValue(self->handle, source, &attribute, 1);
	if (result != CKR_OK && result != CKR_ATTRIBUTE_SENSITIVE && result != CKR_ATTRIBUTE_TYPE_INVALID && result != CKR_BUFFER_TOO_SMALL)
		croak_with("Could not get attributes", result);

	RETVAL = reverse_attribute(&attribute);
OUTPUT:
	RETVAL

HV* get_attributes(Crypt::HSM::Session self, CK_OBJECT_HANDLE source, AV* attributes_av)
CODE:
	Attributes attributes;
	attributes.length = av_len(attributes_av) + 1;
	Newxz(attributes.member, attributes.length, CK_ATTRIBUTE);
	SAVEFREEPV(attributes.member);

	size_t i;
	for (i = 0; i < attributes.length; ++i) {
		STRLEN name_length;
		const char* name = SvPVutf8(*av_fetch(attributes_av, i, FALSE), name_length);
		const attribute_entry* item = get_attribute_entry(name, name_length);
		if (item == NULL)
			Perl_croak(aTHX_ "No such attribute %s", name);
		attributes.member[i].type = item->value;
	}

	CK_RV result = self->provider->funcs->C_GetAttributeValue(self->handle, source, attributes.member, attributes.length);
	if (result != CKR_OK && result != CKR_ATTRIBUTE_SENSITIVE && result != CKR_ATTRIBUTE_TYPE_INVALID && result !=CKR_BUFFER_TOO_SMALL)
		croak_with("Could not get attributes", result);

	for (i = 0; i < attributes.length; ++i) {
		if (attributes.member[i].ulValueLen != CK_UNAVAILABLE_INFORMATION) {
			Newxz(attributes.member[i].pValue, attributes.member[i].ulValueLen, char);
			SAVEFREEPV(attributes.member[i].pValue);
		}
	}

	result = self->provider->funcs->C_GetAttributeValue(self->handle, source, attributes.member, attributes.length);
	if (result != CKR_OK && result != CKR_ATTRIBUTE_SENSITIVE && result != CKR_ATTRIBUTE_TYPE_INVALID && result != CKR_BUFFER_TOO_SMALL)
		croak_with("Could not get attributes", result);

	RETVAL = newHV();
	for (i = 0; i < attributes.length; ++i) {
		SV* key = *av_fetch(attributes_av, i, FALSE);
		SV* value = reverse_attribute(&attributes.member[i]);
		hv_store_ent(RETVAL, key, value, 0);
	}
OUTPUT:
	RETVAL

void set_attributes(Crypt::HSM::Session self, CK_OBJECT_HANDLE source, Attributes attributes)
CODE:
	CK_RV result = self->provider->funcs->C_SetAttributeValue(self->handle, source, attributes.member, attributes.length);
	if (result != CKR_OK)
		croak_with("Could not set attributes", result);


void find_objects(Crypt::HSM::Session self, Attributes attributes)
PPCODE:
	CK_RV result = self->provider->funcs->C_FindObjectsInit(self->handle, attributes.member, attributes.length);
	if (result != CKR_OK)
		croak_with("Could not find objects", result);

	while (1) {
		CK_OBJECT_HANDLE current;
		CK_ULONG actual;
		CK_RV result = self->provider->funcs->C_FindObjects(self->handle, &current, 1, &actual);
		if (result != CKR_OK) {
			self->provider->funcs->C_FindObjectsFinal(self->handle);
			croak_with("Could not find objects", result);
		}
		if (actual == 0)
			break;
		mXPUSHu(current);
	}
	self->provider->funcs->C_FindObjectsFinal(self->handle);


void generate_keypair(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, Attributes publicKeyTemplate, Attributes privateKeyTemplate)
PPCODE:
	CK_OBJECT_HANDLE publicKey;
	CK_OBJECT_HANDLE privateKey;

	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_RV result = self->provider->funcs->C_GenerateKeyPair(self->handle, &mechanism, publicKeyTemplate.member, publicKeyTemplate.length, privateKeyTemplate.member, privateKeyTemplate.length, &publicKey, &privateKey);
	if (result != CKR_OK)
		croak_with("Could not create keypair", result);

	mXPUSHi(publicKey);
	mXPUSHi(privateKey);


CK_OBJECT_HANDLE generate_key(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, Attributes keyTemplate)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_GenerateKey(self->handle, &mechanism, keyTemplate.member, keyTemplate.length, &RETVAL);
	if (result != CKR_OK)
		croak_with("Could not create key", result);
OUTPUT:
	RETVAL


SV* encrypt(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, SV* data, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_RV result = self->provider->funcs->C_EncryptInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize encryption", result);

	CK_ULONG dataLen, encryptedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	result = self->provider->funcs->C_Encrypt(self->handle, dataPV, dataLen, NULL, &encryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute encrypted length", result);

	RETVAL = newSV(encryptedDataLen);
	SvPOK_only(RETVAL);
	result = self->provider->funcs->C_Encrypt(self->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &encryptedDataLen);
	SvCUR(RETVAL) = encryptedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't encrypt", result);
OUTPUT:
	RETVAL


Crypt::HSM::Encrypt open_encrypt(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_EncryptInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize encryption", result);

	Newxz(RETVAL, 1, struct Stream);
	RETVAL->session = session_refcount_increment(self);
	RETVAL->encrypt_key = key;
OUTPUT:
	RETVAL


SV* decrypt(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, SV* data, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_RV result = self->provider->funcs->C_DecryptInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize decryption", result);

	CK_ULONG dataLen, decryptedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	result = self->provider->funcs->C_Decrypt(self->handle, dataPV, dataLen, NULL, &decryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute decrypted length", result);

	RETVAL = newSV(decryptedDataLen);
	SvPOK_only(RETVAL);
	result = self->provider->funcs->C_Decrypt(self->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &decryptedDataLen);
	SvCUR(RETVAL) = decryptedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't decrypt", result);
OUTPUT:
	RETVAL


Crypt::HSM::Encrypt open_decrypt(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_DecryptInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize decryption", result);

	Newxz(RETVAL, 1, struct Stream);
	RETVAL->session = session_refcount_increment(self);
	RETVAL->encrypt_key = key;
OUTPUT:
	RETVAL


SV* sign(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, SV* data, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_RV result = self->provider->funcs->C_SignInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize signing", result);

	CK_ULONG dataLen, signedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	result = self->provider->funcs->C_Sign(self->handle, dataPV, dataLen, NULL, &signedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute signed length", result);

	RETVAL = newSV(signedDataLen);
	SvPOK_only(RETVAL);
	result = self->provider->funcs->C_Sign(self->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &signedDataLen);
	SvCUR(RETVAL) = signedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't sign", result);
OUTPUT:
	RETVAL


Crypt::HSM::Encrypt open_sign(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_SignInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize signing", result);

	Newxz(RETVAL, 1, struct Stream);
	RETVAL->session = session_refcount_increment(self);
	RETVAL->sign_key = key;
OUTPUT:
	RETVAL


bool verify(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, SV* data, SV* signature, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 5);
	CK_RV result = self->provider->funcs->C_VerifyInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize verifying", result);

	CK_ULONG dataLen, signatureLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_BYTE* signaturePV = get_buffer(signature, &signatureLen);

	result = self->provider->funcs->C_Verify(self->handle, dataPV, dataLen, signaturePV, signatureLen);

	if (result == CKR_OK)
		RETVAL = TRUE;
	else if (result == CKR_SIGNATURE_INVALID)
		RETVAL = FALSE;
	else
		croak_with("Couldn't verify", result);
OUTPUT:
	RETVAL


Crypt::HSM::Encrypt open_verify(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_VerifyInit(self->handle, &mechanism, key);
	if (result != CKR_OK)
		croak_with("Couldn't initialize verifying", result);

	Newxz(RETVAL, 1, struct Stream);
	RETVAL->session = session_refcount_increment(self);
	RETVAL->sign_key = key;
OUTPUT:
	RETVAL


SV* digest(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, SV* data, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_DigestInit(self->handle, &mechanism);
	if (result != CKR_OK)
		croak_with("Couldn't initialize digestion", result);

	CK_ULONG dataLen, digestedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	result = self->provider->funcs->C_Digest(self->handle, dataPV, dataLen, NULL, &digestedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute digested length", result);

	RETVAL = newSV(digestedDataLen);
	SvPOK_only(RETVAL);
	result = self->provider->funcs->C_Digest(self->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &digestedDataLen);
	SvCUR(RETVAL) = digestedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't digest", result);
OUTPUT:
	RETVAL


Crypt::HSM::Encrypt open_digest(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 3);
	CK_RV result = self->provider->funcs->C_DigestInit(self->handle, &mechanism);
	if (result != CKR_OK)
		croak_with("Couldn't initialize digesting", result);

	Newxz(RETVAL, 1, struct Stream);
	RETVAL->session = session_refcount_increment(self);
OUTPUT:
	RETVAL


SV* wrap_key(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE wrappingKey, CK_OBJECT_HANDLE key, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_ULONG length;
	CK_RV result = self->provider->funcs->C_WrapKey(self->handle, &mechanism, wrappingKey, key, NULL, &length);
	if (result != CKR_OK)
		croak_with("Couldn't compute wraped length", result);

	RETVAL = newSV(length);
	SvPOK_only(RETVAL);
	result = self->provider->funcs->C_WrapKey(self->handle, &mechanism, wrappingKey, key, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &length);
	SvCUR(RETVAL) = length;
	if (result != CKR_OK)
		croak_with("Couldn't wrap", result);
OUTPUT:
	RETVAL

CK_OBJECT_HANDLE unwrap_key(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE unwrappingKey, SV* wrapped, Attributes attributes, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 5);
	CK_ULONG wrappedLen;
	CK_BYTE* wrappedPV = get_buffer(wrapped, &wrappedLen);
	CK_RV result = self->provider->funcs->C_UnwrapKey(self->handle, &mechanism, unwrappingKey, wrappedPV, wrappedLen, attributes.member, attributes.length, &RETVAL);
	if (result != CKR_OK)
		croak_with("Couldn't unwrap", result);
OUTPUT:
	RETVAL

CK_OBJECT_HANDLE derive_key(Crypt::HSM::Session self, CK_MECHANISM_TYPE mechanism_type, CK_OBJECT_HANDLE baseKey, Attributes attributes, ...)
CODE:
	CK_MECHANISM mechanism = mechanism_from_args(mechanism_type, 4);
	CK_RV result = self->provider->funcs->C_DeriveKey(self->handle, &mechanism, baseKey, attributes.member, attributes.length, &RETVAL);
	if (result != CKR_OK)
		croak_with("Couldn't derive key", result);
OUTPUT:
	RETVAL


void seed_random(Crypt::HSM::Session self, SV* seed)
CODE:
	CK_ULONG seedLen;
	CK_BYTE* seedPV = get_buffer(seed, &seedLen);
	CK_RV result = self->provider->funcs->C_SeedRandom(self->handle, seedPV, seedLen);
	if (result != CKR_OK)
		croak_with("Couldn't seed entropy pool", result);


SV* generate_random(Crypt::HSM::Session self, CK_ULONG length)
CODE:
	RETVAL = newSV(length);
	SvPOK_only(RETVAL);
	SvCUR(RETVAL) = length;
	CK_RV result = self->provider->funcs->C_GenerateRandom(self->handle, (CK_BYTE*)SvPVbyte_nolen(RETVAL), length);
	if (result != CKR_OK)
		croak_with("Couldn't generate randomness", result);
OUTPUT:
	RETVAL


int CLONE_SKIP();


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Stream


SV* get_state(Crypt::HSM::Stream self)
CODE:
	CK_ULONG length;
	CK_RV result = self->session->provider->funcs->C_GetOperationState(self->session->handle, NULL, &length);
	if (result != CKR_OK)
		croak_with("Couldn't get operation state", result);
	RETVAL = newSV(length);
	SvPOK_only(RETVAL);
	if (length) {
		result = self->session->provider->funcs->C_GetOperationState(self->session->handle, SvPVbyte_nolen(RETVAL), &length);
		SvCUR(RETVAL) = length;
		if (result != CKR_OK)
			croak_with("Couldn't get operation state", result);
	}
OUTPUT:
	RETVAL

void set_state(Crypt::HSM::Stream self, SV* state)
CODE:
	STRLEN stateLen;
	char* statePV = SvPVbyte(state, stateLen);
	CK_RV result = self->session->provider->funcs->C_SetOperationState(self->session->handle, statePV, stateLen, self->encrypt_key, self->sign_key);
	if (result != CKR_OK)
		croak_with("Couldn't set operation state", result);


void DESTROY(Crypt::HSM::Stream self)
CODE:
	session_refcount_decrement(self->session);
	Safefree(self);


int CLONE_SKIP()


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Encrypt


SV* add_data(Crypt::HSM::Encrypt self, SV* data)
CODE:
	CK_ULONG dataLen, encryptedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_RV result = self->session->provider->funcs->C_EncryptUpdate(self->session->handle, dataPV, dataLen, NULL, &encryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute encrypted length", result);

	RETVAL = newSV(encryptedDataLen);
	SvPOK_only(RETVAL);
	if (encryptedDataLen) {
		result = self->session->provider->funcs->C_EncryptUpdate(self->session->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &encryptedDataLen);
		SvCUR(RETVAL) = encryptedDataLen;
		if (result != CKR_OK)
			croak_with("Couldn't encrypt", result);
	}
OUTPUT:
	RETVAL


SV* finalize(Crypt::HSM::Encrypt self)
CODE:
	CK_ULONG encryptedDataLen;
	CK_RV result = self->session->provider->funcs->C_EncryptFinal(self->session->handle, NULL, &encryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute encrypted length", result);

	RETVAL = newSV(encryptedDataLen + 1);
	SvPOK_only(RETVAL);
	result = self->session->provider->funcs->C_EncryptFinal(self->session->handle, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &encryptedDataLen);
	SvCUR(RETVAL) = encryptedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't encrypt", result);
OUTPUT:
	RETVAL


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Decrypt


SV* add_data(Crypt::HSM::Decrypt self, SV* data)
CODE:
	CK_ULONG dataLen, decryptedDataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_RV result = self->session->provider->funcs->C_DecryptUpdate(self->session->handle, dataPV, dataLen, NULL, &decryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute decrypted length", result);

	RETVAL = newSV(decryptedDataLen);
	SvPOK_only(RETVAL);
	if (decryptedDataLen) {
		result = self->session->provider->funcs->C_DecryptUpdate(self->session->handle, dataPV, dataLen, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &decryptedDataLen);
		SvCUR(RETVAL) = decryptedDataLen;
		if (result != CKR_OK)
			croak_with("Couldn't decrypt", result);
	}
OUTPUT:
	RETVAL


SV* finalize(Crypt::HSM::Decrypt self)
CODE:
	CK_ULONG decryptedDataLen;
	CK_RV result = self->session->provider->funcs->C_DecryptFinal(self->session->handle, NULL, &decryptedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute decrypted length", result);

	RETVAL = newSV(decryptedDataLen + 1);
	SvPOK_only(RETVAL);
	result = self->session->provider->funcs->C_DecryptFinal(self->session->handle, SvPVbyte_nolen(RETVAL), &decryptedDataLen);
	SvCUR(RETVAL) = decryptedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't decrypt", result);
OUTPUT:
	RETVAL


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Digest



void add_data(Crypt::HSM::Digest self, SV* data)
CODE:
	CK_ULONG dataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_RV result = self->session->provider->funcs->C_DigestUpdate(self->session->handle, dataPV, dataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute digested length", result);


SV* add_key(Crypt::HSM::Digest self, CK_OBJECT_HANDLE key)
CODE:
	CK_RV result = self->session->provider->funcs->C_DigestKey(self->session->handle, key);
	if (result != CKR_OK)
		croak_with("Couldn't compute digested length", result);
OUTPUT:
	RETVAL


SV* finalize(Crypt::HSM::Digest self)
CODE:
	CK_ULONG digestedDataLen;
	CK_RV result = self->session->provider->funcs->C_DigestFinal(self->session->handle, NULL, &digestedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute digested length", result);

	RETVAL = newSV(digestedDataLen + 1);
	SvPOK_only(RETVAL);
	result = self->session->provider->funcs->C_DigestFinal(self->session->handle, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &digestedDataLen);
	SvCUR(RETVAL) = digestedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't digest", result);
OUTPUT:
	RETVAL


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Sign


void add_data(Crypt::HSM::Sign self, SV* data)
CODE:
	CK_ULONG dataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_RV result = self->session->provider->funcs->C_SignUpdate(self->session->handle, dataPV, dataLen);
	if (result != CKR_OK)
		croak_with("Couldn't add date to sign", result);


SV* finalize(Crypt::HSM::Sign self)
CODE:
	CK_ULONG signedDataLen;
	CK_RV result = self->session->provider->funcs->C_SignFinal(self->session->handle, NULL, &signedDataLen);
	if (result != CKR_OK)
		croak_with("Couldn't compute signed length", result);

	RETVAL = newSV(signedDataLen + 1);
	SvPOK_only(RETVAL);
	result = self->session->provider->funcs->C_SignFinal(self->session->handle, (CK_BYTE*)SvPVbyte_nolen(RETVAL), &signedDataLen);
	SvCUR(RETVAL) = signedDataLen;
	if (result != CKR_OK)
		croak_with("Couldn't sign", result);
OUTPUT:
	RETVAL


MODULE = Crypt::HSM  PACKAGE = Crypt::HSM::Verify


void add_data(Crypt::HSM::Verify self, SV* data)
CODE:
	CK_ULONG dataLen;
	CK_BYTE* dataPV = get_buffer(data, &dataLen);
	CK_RV result = self->session->provider->funcs->C_VerifyUpdate(self->session->handle, dataPV, dataLen);
	if (result != CKR_OK)
		croak_with("Couldn't add data to verify", result);


bool finalize(Crypt::HSM::Verify self, SV* signature)
CODE:
	CK_ULONG signatureLen;
	CK_BYTE* signaturePV = get_buffer(signature, &signatureLen);

	CK_RV result = self->session->provider->funcs->C_VerifyFinal(self->session->handle, signaturePV, signatureLen);

	if (result == CKR_OK)
		RETVAL = TRUE;
	else if (result == CKR_SIGNATURE_INVALID)
		RETVAL = FALSE;
	else
		croak_with("Couldn't verify", result);
OUTPUT:
	RETVAL
