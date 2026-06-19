#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef __bool_true_false_are_defined
#undef bool
#include <stdbool.h>
#endif

#define NEED_mg_findext
#include "ppport.h"

#include <openssl/ssl.h>
#include <openssl/param_build.h>
#include <openssl/kdf.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>
#include <openssl/ts.h>
#include <openssl/opensslv.h>
#if OPENSSL_VERSION_PREREQ(3, 2)
#include <openssl/hpke.h>
#endif

static unsigned char* S_make_buffer(pTHX_ SV** retval, size_t size) {
	*retval = newSVpv("", 0);
	char* ptr = SvGROW(*retval, size);
	return (unsigned char*)ptr;
}
#define make_buffer(svp, size) S_make_buffer(aTHX_ svp, size)

static char* S_grow_buffer(pTHX_ SV* buffer, size_t size) {
	SvUPGRADE(buffer, SVt_PV);
	SV_CHECK_THINKFIRST(buffer);
	return SvGROW(buffer, size);
}
#define grow_buffer(sv, size) S_grow_buffer(aTHX_ sv, size)

static inline void S_set_buffer_length(pTHX_ SV* buffer, ssize_t result) {
	SvCUR_set(buffer, result);
	SvPOK_only(buffer);
}
#define set_buffer_length(buffer, result) S_set_buffer_length(aTHX_ buffer, result)

#define TYPE_TYPE(c_type, xs_type) typedef c_type * Crypt__OpenSSL3__ ## xs_type;
#define MAGIC_TABLE(xs_type, dup, free)\
static const MGVTBL Crypt__OpenSSL3__ ## xs_type ## _magic = {\
	.svt_free = free,\
	.svt_dup = dup,\
};

#define TYPE_COMMON(c_type, xs_type, p_type)\
static inline SV* make_ ## c_type(pTHX_ void* var) {\
	SV* result = newSV(0);\
	const char* classname = "Crypt::OpenSSL3::" #p_type;\
	const MGVTBL* mgvtbl = &Crypt__OpenSSL3__## xs_type ##_magic;\
	MAGIC* magic = sv_magicext(newSVrv(result, classname), NULL, PERL_MAGIC_ext, mgvtbl, (const char*)var, 0);\
	magic->mg_flags |= MGf_DUP;\
	return result;\
}\
static inline c_type* get_ ## c_type (pTHX_ SV* value) {\
	if (!SvROK(value))\
		return NULL;\
	MAGIC* magic = mg_findext(SvRV(value), PERL_MAGIC_ext, &Crypt__OpenSSL3__## xs_type ##_magic);\
	return magic ? (c_type*)magic->mg_ptr : NULL;\
}

#define DUPLICATING_TYPE(c_type, xs_type, p_type)\
TYPE_TYPE(c_type, xs_type)\
static int c_type ## _magic_dup(pTHX_ MAGIC* mg, CLONE_PARAMS* params) {\
	PERL_UNUSED_VAR(params);\
	mg->mg_ptr = (char*)c_type ## _dup((c_type*)mg->mg_ptr);\
	return 0;\
}\
static int c_type ## _magic_free(pTHX_ SV* sv, MAGIC* mg) {\
	PERL_UNUSED_VAR(sv);\
	c_type ## _free((c_type*)mg->mg_ptr);\
	return 0;\
}\
MAGIC_TABLE(xs_type, c_type ## _magic_dup, c_type ## _magic_free)\
TYPE_COMMON(c_type, xs_type, p_type)

#define COUNTING_TYPE(c_type, xs_type, p_type)\
typedef c_type * Crypt__OpenSSL3__ ## xs_type;\
static int c_type ## _magic_dup(pTHX_ MAGIC* mg, CLONE_PARAMS* params) {\
	PERL_UNUSED_VAR(params);\
	c_type ## _up_ref((c_type*)mg->mg_ptr);\
	return 0;\
}\
static int c_type ## _magic_free(pTHX_ SV* sv, MAGIC* mg) {\
	PERL_UNUSED_VAR(sv);\
	c_type ## _free((c_type*)mg->mg_ptr);\
	return 0;\
}\
MAGIC_TABLE(xs_type, c_type ## _magic_dup, c_type ## _magic_free)\
TYPE_COMMON(c_type, xs_type, p_type)

#define SIMPLE_TYPE(c_type, xs_type, p_type, modifier)\
TYPE_TYPE(modifier c_type, xs_type)\
MAGIC_TABLE(xs_type, NULL, NULL)\
TYPE_COMMON(c_type, xs_type, p_type)

#define STACK_TYPE(c_prefix, xs_type)\
typedef STACK_OF(c_prefix) * Crypt__OpenSSL3__ ## xs_type ## __Stack;\
static int c_prefix ## __Stack_magic_dup(pTHX_ MAGIC* mg, CLONE_PARAMS* params) {\
	PERL_UNUSED_VAR(params);\
	mg->mg_ptr = (char*)sk_ ## c_prefix ## _dup((STACK_OF(c_prefix)*)mg->mg_ptr);\
	return 0;\
}\
static int c_prefix ## __Stack_magic_free(pTHX_ SV* sv, MAGIC* mg) {\
	PERL_UNUSED_VAR(sv);\
	sk_ ## c_prefix ## _free((STACK_OF(c_prefix)*)mg->mg_ptr);\
	return 0;\
}\
static const MGVTBL Crypt__OpenSSL3__ ## xs_type ## __Stack_magic = {\
	.svt_dup = c_prefix ## __Stack_magic_dup,\
	.svt_free = c_prefix ## __Stack_magic_free,\
};

#if !OPENSSL_VERSION_PREREQ(3, 2)
static EVP_MD_CTX *EVP_MD_CTX_dup(const EVP_MD_CTX *in) {
	EVP_MD_CTX* result = EVP_MD_CTX_new();
	EVP_MD_CTX_copy(result, in);
	return result;
}

static EVP_CIPHER_CTX *EVP_CIPHER_CTX_dup(const EVP_CIPHER_CTX *in) {
	EVP_CIPHER_CTX* result = EVP_CIPHER_CTX_new();
	EVP_CIPHER_CTX_copy(result, in);
	return result;
}
#define EVP_RAND_CTX_up_ref(ctx) NULL
#endif

typedef unsigned long Crypt__OpenSSL3__Error;
COUNTING_TYPE(EVP_RAND, Random, Random)
COUNTING_TYPE(EVP_RAND_CTX, Random__Context, Random::Context)
COUNTING_TYPE(EVP_CIPHER, Cipher, Cipher)
DUPLICATING_TYPE(EVP_CIPHER_CTX, Cipher__Context, Cipher::Context)
COUNTING_TYPE(EVP_MD, MD, MD)
DUPLICATING_TYPE(EVP_MD_CTX, MD__Context, MD::Context)
COUNTING_TYPE(EVP_MAC, MAC, MAC)
DUPLICATING_TYPE(EVP_MAC_CTX, MAC__Context, MAC::Context)
COUNTING_TYPE(EVP_KDF, KDF, KDF)
DUPLICATING_TYPE(EVP_KDF_CTX, KDF__Context, KDF::Context)
COUNTING_TYPE(EVP_SIGNATURE, Signature, Signature)
DUPLICATING_TYPE(EVP_PKEY, PKey, PKey)
DUPLICATING_TYPE(EVP_PKEY_CTX, PKey__Context, PKey::Context)

typedef BIGNUM BN;
DUPLICATING_TYPE(BN, BigNum, BigNum);
#define BN_CTX_dup(old) BN_CTX_new()
DUPLICATING_TYPE(BN_CTX, BigNum__Context, BigNum::Context)

typedef int Crypt__OpenSSL3__NID;
SIMPLE_TYPE(ASN1_OBJECT, ASN1__Object, ASN1::Object, const)
DUPLICATING_TYPE(ASN1_INTEGER, ASN1__Integer, ASN1::Integer)
#define ASN1_ENUMERATED_dup ASN1_INTEGER_dup
DUPLICATING_TYPE(ASN1_ENUMERATED, ASN1__Enumerated, ASN1::Enumerated)
DUPLICATING_TYPE(ASN1_STRING, ASN1__String, ASN1::String)
DUPLICATING_TYPE(ASN1_TIME, ASN1__Time, ASN1::Time)
DUPLICATING_TYPE(ASN1_GENERALIZEDTIME, ASN1__Time__Generalized, ASN1::Time::Generalized)
DUPLICATING_TYPE(ASN1_UTCTIME, ASN1__Time__UTC, ASN1::Time::UTC)
DUPLICATING_TYPE(X509, X509, X509)
STACK_TYPE(X509, X509)
COUNTING_TYPE(X509_STORE, X509__Store, X509::Store)
DUPLICATING_TYPE(X509_NAME, X509__Name, X509::Name)
DUPLICATING_TYPE(X509_NAME_ENTRY, X509__Name__Entry, X509::Name::Entry)
DUPLICATING_TYPE(X509_REQ, X509__Request, X509::Request)
DUPLICATING_TYPE(X509_ALGOR, X509__Algorithm, X509::Algorithm)
DUPLICATING_TYPE(X509_EXTENSION, X509__Extension, X509::Extension)
DUPLICATING_TYPE(X509_ATTRIBUTE, X509__Attribute, X509::Attribute)
SIMPLE_TYPE(X509_VERIFY_PARAM, X509__VerifyParam, X509::VerifyParam, )
DUPLICATING_TYPE(GENERAL_NAME, X509__GeneralName, X509::GeneralName)
typedef long Crypt__OpenSSL3__X509__VerifyResult;
DUPLICATING_TYPE(PKCS7, PKCS7, PKCS7)

DUPLICATING_TYPE(TS_REQ, Timestamp__Request, Timestamp::Request)
DUPLICATING_TYPE(TS_RESP, Timestamp__Response, Timestamp::Respone)
DUPLICATING_TYPE(TS_MSG_IMPRINT, Timestamp__Imprint, Timestamp::Imprint)
DUPLICATING_TYPE(TS_TST_INFO, Timestamp__TokenInfo, Timestamp::TokenInfo)
DUPLICATING_TYPE(TS_STATUS_INFO, Timestamp__StatusInfo, Timestamp::StatusInfo)
DUPLICATING_TYPE(TS_ACCURACY, Timestamp__Accuracy, Timestamp::Accuracy)
#define TS_VERIFY_CTX_dup(ctx) NULL
DUPLICATING_TYPE(TS_VERIFY_CTX, Timestamp__Verifier, Timestamp::Verifier)

COUNTING_TYPE(BIO, BIO, BIO)
#if OPENSSL_VERSION_PREREQ(3, 2)
DUPLICATING_TYPE(BIO_ADDR, BIO__Address, BIO::Address)
typedef BIO_POLL_DESCRIPTOR* Crypt__OpenSSL3__BIO__PollDescriptor;
#endif

SIMPLE_TYPE(SSL_METHOD, SSL__Method, SSL::Method, const)
COUNTING_TYPE(SSL_CTX, SSL__Context, SSL::Context)
COUNTING_TYPE(SSL, SSL, SSL)
DUPLICATING_TYPE(SSL_SESSION, SSL__Session, SSL::Session)
SIMPLE_TYPE(SSL_CIPHER, SSL__Cipher, SSL::Context, const)

#if OPENSSL_VERSION_PREREQ(3, 2)
typedef struct HPKE {
	OSSL_HPKE_CTX* context;
	OSSL_HPKE_SUITE suite;
} HPKE;

#define HPKE_dup(hpke) NULL

static void HPKE_free(HPKE* hpke) {
	OSSL_HPKE_CTX_free(hpke->context);
	Safefree(hpke);
}

DUPLICATING_TYPE(HPKE, HPKE__Context, HPKE::Context)
typedef OSSL_HPKE_SUITE* Crypt__OpenSSL3__HPKE;
#endif

#define PARAMS(a) OSSL_PARAM*
#define CTX_PARAMS(a) OSSL_PARAM*

#undef OPENSSL_VERSION_TEXT
#define OPENSSL_VERSION_TEXT OPENSSL_VERSION

#define BIO_new_mem() BIO_new(BIO_s_mem())
#define BIO_POLL_DESCRIPTOR_new(class) safecalloc(1, sizeof(BIO_POLL_DESCRIPTOR))
#define BIO_POLL_DESCRIPTOR_type(desc) ((desc)->type)
#define BIO_POLL_DESCRIPTOR_fd(desc) ((desc)->value.fd)

#define BN_generate_prime BN_generate_prime_ex2

#define OBJ_get_data OBJ_get0_data
#define OBJ_from_nid OBJ_nid2obj
#define OBJ_from_text OBJ_txt2obj
#define OBJ_to_nid OBJ_obj2nid
SV* S_OBJ_to_text(pTHX_ const ASN1_OBJECT* object, bool no_name) {
	SV* result = &PL_sv_undef;
	int buf_len = OBJ_obj2txt(NULL, 0, object, no_name);
	if (buf_len > 0) {
		unsigned char* ptr = make_buffer(&result, buf_len);
		if (OBJ_obj2txt((char*)ptr, buf_len, object, no_name) > 0)
			set_buffer_length(result, buf_len);
	}
	return result;
}
#define OBJ_to_text(object, no_name) S_OBJ_to_text(aTHX_ object, no_name)
#define ASN1_INTEGER_get_BN(ai) ASN1_INTEGER_to_BN(ai, NULL)
#define ASN1_INTEGER_set_BN(ai, bn) BN_to_ASN1_INTEGER(bn, ai)
#define ASN1_INTEGER_set_buffer ASN1_STRING_set
#define ASN1_ENUMERATED_set_BN(ai, bn) BN_to_ASN1_ENUMERATED(bn, ai)
#define ASN1_ENUMERATED_get_BN(ai) ASN1_ENUMERATED_to_BN(ai, NULL)
#define ASN1_TIME_cmp_time ASN1_TIME_cmp_time_t

#define GENERAL_NAME_type(gn) (gn->type)

#define X509_read_der d2i_X509_bio
#define X509_write_der i2d_X509_bio
#define X509_read_pem PEM_read_bio_X509
#define X509_write_pem PEM_write_bio_X509
#define X509_get_tbs_sigalg(c) (X509_ALGOR*)X509_get0_tbs_sigalg(c)
#define X509_get_signature X509_get0_signature
#define X509_get_subject_key_id(c) (ASN1_OCTET_STRING*)X509_get0_subject_key_id(c)
#define X509_get_authority_issuer(c) (GENERAL_NAME*)X509_get0_authority_issuer(c)
#define X509_get_authority_key_id(c) (ASN1_OCTET_STRING*)X509_get0_authority_key_id(c)
#define X509_get_authority_serial(c) (ASN1_INTEGER*)X509_get0_authority_serial(c)
#define X509_set_notAfter X509_set1_notAfter
#define X509_set_notBefore X509_set1_notBefore
#define X509_get_distinguishing_id(c) ASN1_OCTET_STRING_dup(X509_get0_distinguishing_id(c))
#define X509_set_distinguishing_id X509_set0_distinguishing_id
#define X509_get_ext(c, loc) X509_EXTENSION_dup(X509_get_ext(c, loc))
#define X509_EXTENSION_get_object(e) X509_EXTENSION_get_object(e)
#define X509_EXTENSION_get_data(e) ASN1_OCTET_STRING_dup(X509_EXTENSION_get_data(e))
#define X509_ATTRIBUTE_get_data X509_ATTRIBUTE_get0_data
#define X509_ATTRIBUTE_set_data X509_ATTRIBUTE_set1_data
#define X509_ATTRIBUTE_get_object X509_ATTRIBUTE_get0_object
#define X509_ATTRIBUTE_set_object X509_ATTRIBUTE_set1_object
#define X509_NAME_get_entry(n, loc) X509_NAME_ENTRY_dup(X509_NAME_get_entry(n, loc))
#undef X509_NAME_hash
#define X509_NAME_hash X509_NAME_hash_ex
#define X509_NAME_print X509_NAME_print_ex
#define GENERAL_NAME_new_from_x509_name GENERAL_NAME_set1_X509_NAME
#define X509_STORE_load_file X509_STORE_load_file_ex
#define X509_STORE_load_store X509_STORE_load_store_ex
#define X509_ALGOR_get X509_ALGOR_get0
#define X509_ALGOR_set X509_ALGOR_set0
#define X509_verify_cert_error_code(value) value
#define X509_verify_cert_ok(value) (value == X509_V_OK)
#define X509_VERIFY_PARAM_add_policy X509_VERIFY_PARAM_add0_policy
#define X509_VERIFY_PARAM_get_host X509_VERIFY_PARAM_get0_host
#define X509_VERIFY_PARAM_set_host X509_VERIFY_PARAM_set1_host
#define X509_VERIFY_PARAM_add_host X509_VERIFY_PARAM_add1_host
#define X509_VERIFY_PARAM_get_peername X509_VERIFY_PARAM_get0_peername
#define X509_VERIFY_PARAM_get_email X509_VERIFY_PARAM_get0_email
#define X509_VERIFY_PARAM_set_email X509_VERIFY_PARAM_set1_email
#define X509_VERIFY_PARAM_get_ip_asc X509_VERIFY_PARAM_get1_ip_asc
#define X509_VERIFY_PARAM_set_ip X509_VERIFY_PARAM_set1_ip
#define X509_VERIFY_PARAM_set_ip_asc X509_VERIFY_PARAM_set1_ip_asc
#define X509_REQ_new X509_REQ_new_ex
#define X509_REQ_read_der d2i_X509_REQ_bio
#define X509_REQ_write_der i2d_X509_REQ_bio
#define X509_REQ_read_pem PEM_read_bio_X509_REQ
#define X509_REQ_write_pem PEM_write_bio_X509_REQ
#define X509_REQ_add_attr X509_REQ_add1_attr
#define X509_REQ_add_attr_by_NID X509_REQ_add1_attr_by_NID
#define X509_REQ_add_attr_by_OBJ X509_REQ_add1_attr_by_OBJ
#define X509_REQ_add_attr_by_txt X509_REQ_add1_attr_by_txt
#define X509_REQ_get_X509_pubkey X509_REQ_get_X509_PUBKEY
#define X509_REQ_get_distinguishing_id(c) ASN1_OCTET_STRING_dup(X509_REQ_get0_distinguishing_id(c))
#define X509_REQ_set_distinguishing_id X509_REQ_set0_distinguishing_id
#define X509_REQ_get_signature X509_REQ_get0_signature
#define X509_REQ_set_signature X509_REQ_set0_signature
#define X509_REQ_set_signature_algo X509_REQ_set1_signature_algo
#define X509_REQ_verify X509_REQ_verify_ex

#define PKCS7_new PKCS7_new_ex
#define PKCS7_read_pem PEM_read_bio_PKCS7
#define PKCS7_write_pem PEM_write_bio_PKCS7
#define PKCS7_read_der d2i_PKCS7_bio
#define PKCS7_write_der i2d_PKCS7_bio
#define PKCS7_sign PKCS7_sign_ex
#define PKCS7_get_signers PKCS7_get0_signers
#define PKCS7_encrypt PKCS7_encrypt_ex

#define TS_REQ_print(t, b) TS_REQ_print_bio(b, t)
#define TS_REQ_read_der d2i_TS_REQ_bio
#define TS_REQ_write_der i2d_TS_REQ_bio
#define TS_REQ_get_nonce(req) ASN1_INTEGER_dup(TS_REQ_get_nonce(req))
#define TS_TST_INFO_print(t, b) TS_TST_INFO_print_bio(b, t)
#define TS_TST_INFO_read_der d2i_TS_TST_INFO_bio
#define TS_TST_INFO_write_der i2d_TS_TST_INFO_bio
#define TS_RESP_print(t, b) TS_RESP_print_bio(b, t)
#define TS_RESP_read_der d2i_TS_RESP_bio
#define TS_RESP_write_der i2d_TS_RESP_bio
#define TS_MSG_IMPRINT_print(t, b) TS_MSG_IMPRINT_print_bio(b, t)
#define TS_MSG_IMPRINT_read_der d2i_TS_MSG_IMPRINT_bio
#define TS_MSG_IMPRINT_write_der i2d_TS_MSG_IMPRINT_bio
#define TS_TST_INFO_get_serial(tst) ASN1_INTEGER_dup(TS_TST_INFO_get_serial(tst))
#define TS_TST_INFO_get_time(tst) ASN1_GENERALIZEDTIME_dup(TS_TST_INFO_get_time(tst))
#define TS_TST_INFO_get_nonce(tst) ASN1_INTEGER_dup(TS_TST_INFO_get_nonce(tst))
#define TS_STATUS_INFO_get_status(status) ASN1_INTEGER_dup(TS_STATUS_INFO_get0_status(status))
#define TS_STATUS_INFO_get_failure_info(status) ASN1_INTEGER_dup(TS_STATUS_INFO_get0_failure_info(status))
#define TS_ACCURACY_get_seconds(status) ASN1_INTEGER_dup(TS_ACCURACY_get_seconds(status))
#define TS_ACCURACY_get_millis(status) ASN1_INTEGER_dup(TS_ACCURACY_get_millis(status))
#define TS_ACCURACY_get_micros(status) ASN1_INTEGER_dup(TS_ACCURACY_get_micros(status))
#define TS_VERIFY_CTX_init_from_request(ctx, req) TS_REQ_to_TS_VERIFY_CTX(req, ctx)
#if OPENSSL_VERSION_PREREQ(3, 4)
#define TS_VERIFY_CTX_set_data TS_VERIFY_CTX_set0_data
#define TS_VERIFY_CTX_set_imprint TS_VERIFY_CTX_set0_imprint
#define TS_VERIFY_CTX_set_store TS_VERIFY_CTX_set0_store
#define TS_VERIFY_CTX_set_certs TS_VERIFY_CTX_set0_certs
#endif
#define TS_VERIFY_CTX_verify_response TS_RESP_verify_response

#define SSL_Method_TLS TLS_method
#define SSL_Method_TLS_server TLS_server_method
#define SSL_Method_TLS_client TLS_client_method

#define SSL_Method_DTLS DTLS_method
#define SSL_Method_DTLS_server DTLS_server_method
#define SSL_Method_DTLS_client DTLS_client_method

#define SSL_Method_QUIC_client OSSL_QUIC_client_method
#define SSL_Method_QUIC_client_thread OSSL_QUIC_client_thread_method
#define SSL_Method_QUIC_server OSSL_QUIC_server_method

#define SSL_CTX_get_param SSL_CTX_get0_param
#define SSL_CTX_set_param SSL_CTX_set1_param

#define SSL_set_host SSL_set1_host
#define SSL_set_dnsname SSL_set1_dnsname
#define SSL_set_ipaddr SSL_set1_ipaddr
#define SSL_set_rbio SSL_set0_rbio
#define SSL_set_wbio SSL_set0_wbio
#define SSL_get_context SSL_get_SSL_CTX
#define SSL_get_alpn_selected SSL_get0_alpn_selected
#define SSL_get_connection SSL_get0_connection
#define SSL_get_listener SSL_get0_listener
#define SSL_get_domain SSL_get0_domain
#define SSL_set_initial_peer_addr SSL_set1_initial_peer_addr
#define SSL_get_param SSL_get0_param
#define SSL_set_param SSL_set1_param
#if !OPENSSL_VERSION_PREREQ(3, 2)
#define SSL_is_tls(s) (!SSL_is_dtls(s))
#define SSL_is_quic(s) FALSE
#endif

#define SSL_SESSION_read_der d2i_SSL_SESSION_bio
#define SSL_SESSION_write_der i2d_SSL_SESSION_bio
#define SSL_SESSION_get_peer SSL_SESSION_get0_peer
#define SSL_SESSION_get_alpn_selected SSL_SESSION_get0_alpn_selected
#define SSL_SESSION_get_cipher SSL_SESSION_get0_cipher
#define SSL_SESSION_get_hostname SSL_SESSION_get0_hostname
#define SSL_SESSION_get_id_context SSL_SESSION_get0_id_context
#define SSL_SESSION_get_ticket SSL_SESSION_get0_ticket
#define SSL_SESSION_set_alpn_selected SSL_SESSION_set1_alpn_selected
#define SSL_SESSION_set_hostname SSL_SESSION_set1_hostname
#define SSL_SESSION_set_id SSL_SESSION_set1_id
#define SSL_SESSION_set_id_context SSL_SESSION_set1_id_context
#if !OPENSSL_VERSION_PREREQ(3,2)
#define SSL_get_event_timeout(s, tv, inf) DTLSv1_get_timeout(s, tv)
#define SSL_handle_events DTLSv1_handle_timeout
#endif
#if OPENSSL_VERSION_PREREQ(3, 3)
#define SSL_SESSION_get_time SSL_SESSION_get_time_ex
#define SSL_SESSION_set_time SSL_SESSION_set_time_ex
#endif

#define NID_create OBJ_create
#define NID_from_long_name OBJ_ln2nid
#define NID_from_short_name OBJ_sn2nid
#define NID_from_text OBJ_txt2nid
#define NID_get_long_name OBJ_nid2ln
#define NID_get_short_name OBJ_nid2sn
#define NID_to_object OBJ_nid2obj
#define NID_eq(left, right) (left == right)
#define NID_raw(nid) nid
#define NID_is_undef(nid) (nid == NID_undef)

#define SSL_CIPHER_get_handshake_digest(c) (EVP_MD*)SSL_CIPHER_get_handshake_digest(c)

#define RAND_get_primary RAND_get0_primary
#define RAND_get_public RAND_get0_public
#define RAND_get_private RAND_get0_private
#define RAND_set_public RAND_set0_public
#define RAND_set_private RAND_set0_private
#define EVP_RAND_get_name EVP_RAND_get0_name
#define EVP_RAND_get_description EVP_RAND_get0_description
#define EVP_RAND_CTX_get_rand EVP_RAND_CTX_get0_rand
#define EVP_CIPHER_get_name EVP_CIPHER_get0_name
#define EVP_CIPHER_get_description EVP_CIPHER_get0_description
#undef EVP_CIPHER_CTX_init
#define EVP_CIPHER_CTX_init EVP_CipherInit_ex2
#define EVP_CIPHER_CTX_update EVP_CipherUpdate
#define EVP_CIPHER_CTX_final EVP_CipherFinal_ex
#define EVP_CIPHER_CTX_set_aead_ivlen(ctx, length) EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_IVLEN, length, NULL)
#define EVP_CIPHER_CTX_get_aead_tag(ctx, ptr, length) EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_GET_TAG, length, ptr)
#define EVP_CIPHER_CTX_set_aead_tag(ctx, ptr, length) EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_TAG, length, ptr)
#define EVP_CIPHER_CTX_get_name EVP_CIPHER_CTX_get0_name
#define EVP_CIPHER_CTX_get_cipher EVP_CIPHER_CTX_get1_cipher

#define EVP_MD_digest EVP_Digest
#define EVP_MD_get_name EVP_MD_get0_name
#define EVP_MD_get_description EVP_MD_get0_description
#undef EVP_MD_CTX_init
#define EVP_MD_CTX_get_md EVP_MD_CTX_get1_md
#define EVP_MD_CTX_get_name EVP_MD_CTX_get0_name
#define EVP_MD_CTX_init EVP_DigestInit_ex2
#define EVP_MD_CTX_update EVP_DigestUpdate
#define EVP_MD_CTX_final EVP_DigestFinal_ex
#define EVP_MD_CTX_final_xof EVP_DigestFinalXOF
#define EVP_MD_CTX_squeeze EVP_DigestSqueeze
#define EVP_MD_CTX_sign_init EVP_DigestSignInit
#define EVP_MD_CTX_sign_init_ex EVP_DigestSignInit_ex
#define EVP_MD_CTX_sign_update EVP_DigestSignUpdate
#define EVP_MD_CTX_sign_final EVP_DigestSignFinal
#define EVP_MD_CTX_sign EVP_DigestSign
#define EVP_MD_CTX_verify_init EVP_DigestVerifyInit
#define EVP_MD_CTX_verify_update EVP_DigestVerifyUpdate
#define EVP_MD_CTX_verify_final EVP_DigestVerifyFinal
#define EVP_MD_CTX_verify EVP_DigestVerify

#define EVP_MAC_get_name EVP_MAC_get0_name
#define EVP_MAC_get_description EVP_MAC_get0_description
#define EVP_MAC_CTX_get_mac EVP_MAC_CTX_get0_mac
#define EVP_MAC_CTX_get_name EVP_MAC_CTX_get0_name

#define EVP_KDF_get_name EVP_KDF_get0_name
#define EVP_KDF_get_description EVP_KDF_get0_description
#define EVP_KDF_CTX_get_name EVP_KDF_CTX_get0_name
#define EVP_KDF_CTX_kdf(ctx) (EVP_KDF*)EVP_KDF_CTX_kdf(ctx)

#define EVP_SIGNATURE_get_name EVP_SIGNATURE_get0_name
#define EVP_SIGNATURE_get_description EVP_SIGNATURE_get0_description

#define EVP_PKEY_read_pem_private_key PEM_read_bio_PrivateKey_ex
#define EVP_PKEY_write_pem_private_key PEM_write_bio_PrivateKey_ex
#define EVP_PKEY_read_pem_public_key PEM_read_bio_PUBKEY_ex
#define EVP_PKEY_write_pem_public_key PEM_write_bio_PUBKEY_ex
#define EVP_PKEY_read_der_private_key d2i_PrivateKey_ex_bio
#define EVP_PKEY_write_der_private_key i2d_PrivateKey_bio
#if !OPENSSL_VERSION_PREREQ(3, 2)
#define d2i_PUBKEY_ex_bio(bio, ptr, lib, propq) d2i_PUBKEY_bio(bio, ptr)
#endif
#define EVP_PKEY_read_der_public_key d2i_PUBKEY_ex_bio
#define EVP_PKEY_write_der_public_key i2d_PUBKEY_bio
#define EVP_PKEY_new_raw_private_key EVP_PKEY_new_raw_private_key_ex
#define EVP_PKEY_new_raw_public_key EVP_PKEY_new_raw_public_key_ex
#define EVP_PKEY_get_description EVP_PKEY_get0_description
#define EVP_PKEY_get_type_name EVP_PKEY_get0_type_name
#define EVP_PKEY_get_encoded_public_key EVP_PKEY_get1_encoded_public_key
#define EVP_PKEY_set_encoded_public_key EVP_PKEY_set1_encoded_public_key
#define EVP_PKEY_encrypt_init EVP_PKEY_encrypt_init_ex
#define EVP_PKEY_decrypt_init EVP_PKEY_decrypt_init_ex
#define EVP_PKEY_derive_init EVP_PKEY_derive_init_ex
#define EVP_PKEY_derive_set_peer EVP_PKEY_derive_set_peer_ex

#if !OPENSSL_VERSION_PREREQ(3, 4)
static int EVP_PKEY_sign_init_ex2(EVP_PKEY_CTX *ctx, EVP_SIGNATURE *algo, const OSSL_PARAM params[]) {
	if (algo)
		return FALSE;
	return EVP_PKEY_sign_init_ex(ctx, params);
}

static int EVP_PKEY_verify_init_ex2(EVP_PKEY_CTX *ctx, EVP_SIGNATURE *algo, const OSSL_PARAM params[]) {
	if (algo)
		return FALSE;
	return EVP_PKEY_verify_init_ex(ctx, params);
}
#endif
#define EVP_PKEY_sign_init EVP_PKEY_sign_init_ex2
#define EVP_PKEY_verify_init EVP_PKEY_verify_init_ex2


#if OPENSSL_VERSION_PREREQ(3, 2)
#define OSSL_HPKE_CTX_set_authpriv OSSL_HPKE_CTX_set1_authpriv
#define OSSL_HPKE_CTX_set_authpub OSSL_HPKE_CTX_set1_authpub
#define OSSL_HPKE_CTX_set_psk OSSL_HPKE_CTX_set1_psk
#define OSSL_HPKE_CTX_set_ikme OSSL_HPKE_CTX_set1_ikme
#define OSSL_HPKE_decapsulate OSSL_HPKE_decap
#define OSSL_HPKE_check OSSL_HPKE_suite_check
#define OSSL_HPKE_kem_id(suite) (suite)->kem_id
#define OSSL_HPKE_kdf_id(suite) (suite)->kdf_id
#define OSSL_HPKE_aead_id(suite) (suite)->aead_id
#endif

#define CONSTANT2(PREFIX, VALUE) newCONSTSUB(stash, #VALUE, newSVuv(PREFIX##VALUE))

static OSSL_PARAM* S_params_for(pTHX_ const OSSL_PARAM* settable, SV* input) {
	if (!SvROK(input) || SvTYPE(SvRV(input)) != SVt_PVHV)
		return NULL;

	OSSL_PARAM_BLD* builder = OSSL_PARAM_BLD_new();
	HV* hash = (HV*)SvRV(input);

	hv_iterinit(hash);
	char* name;
	I32 name_len;
	SV* sv;

	while (sv = hv_iternextsv(hash, &name, &name_len)) {
		const OSSL_PARAM* found = OSSL_PARAM_locate_const(settable, name);

		if (found) {
			const BIGNUM* big;
			if (found->data_type == OSSL_PARAM_INTEGER) {
				if (big = get_BN(aTHX_ sv))
					OSSL_PARAM_BLD_push_BN(builder, found->key, big);
				else
					OSSL_PARAM_BLD_push_int64(builder, found->key, SvIV(sv));
			} else if (found->data_type == OSSL_PARAM_UNSIGNED_INTEGER) {
				if (big = get_BN(aTHX_ sv))
					OSSL_PARAM_BLD_push_BN(builder, found->key, big);
				else
					OSSL_PARAM_BLD_push_uint64(builder, found->key, SvUV(sv));
			} else if (found->data_type == OSSL_PARAM_REAL) {
				OSSL_PARAM_BLD_push_double(builder, found->key, SvNV(sv));
			} else if (found->data_type == OSSL_PARAM_UTF8_STRING) {
				STRLEN length;
				const char* ptr = SvPVutf8(sv, length);
				OSSL_PARAM_BLD_push_utf8_string(builder, found->key, ptr, length);
			} else if (found->data_type == OSSL_PARAM_OCTET_STRING) {
				STRLEN length;
				const char* ptr = SvPVbyte(sv, length);
				OSSL_PARAM_BLD_push_octet_string(builder, found->key, ptr, length);
			}
		}
	}

	OSSL_PARAM* result = OSSL_PARAM_BLD_to_param(builder);
	OSSL_PARAM_BLD_free(builder);
	SAVEDESTRUCTOR(OSSL_PARAM_free, result);
	return result;
}
#define params_for(settable, sv) S_params_for(aTHX_ settable, sv)

static SV* S_make_param_scalar(pTHX_ OSSL_PARAM* iter) {
	if (iter->data_type == OSSL_PARAM_INTEGER) {
		if (iter->data_size == 0)
			return newSViv(0);
		else if (iter->data_size <= IVSIZE) {
			int64_t value;
			OSSL_PARAM_get_int64(iter, &value);
			return newSViv(value);
		} else {
			BIGNUM* value = NULL;
			OSSL_PARAM_get_BN(iter, &value);
			return make_BN(aTHX_ value);
		}
	}
	else if (iter->data_type == OSSL_PARAM_UNSIGNED_INTEGER) {
		if (iter->data_size == 0)
			return newSVuv(0);
		else if (iter->data_size <= UVSIZE) {
			uint64_t value = 0;
			OSSL_PARAM_get_uint64(iter, &value);
			return newSVuv(value);
		} else {
			BIGNUM* value = NULL;
			OSSL_PARAM_get_BN(iter, &value);
			return make_BN(aTHX_ value);
		}
	}
	else if (iter->data_type == OSSL_PARAM_REAL) {
		double value;
		OSSL_PARAM_get_double(iter, &value);
		return newSVnv(value);
	}
	else if (iter->data_type == OSSL_PARAM_UTF8_STRING) {
		return newSVpvn_utf8((const char*)iter->data, iter->data_size, 1);
	}
	else if (iter->data_type == OSSL_PARAM_OCTET_STRING) {
		return newSVpvn((const char*)iter->data, iter->data_size);
	}

	return NULL;
}
#define make_param_scalar(params) S_make_param_scalar(aTHX_ params)

#define GENERATE_GET_PARAM(prefix, arg, name)\
	RETVAL = &PL_sv_undef;\
	const OSSL_PARAM* description = OSSL_PARAM_locate_const(prefix ## _gettable_params(arg), name);\
	if (description) {\
		OSSL_PARAM params[] = {\
			OSSL_PARAM_DEFN(description->key, description->data_type, NULL, SIZE_MAX),\
			OSSL_PARAM_END,\
		};\
		if (prefix ## _get_params(arg, params)) {\
			if (OSSL_PARAM_modified(params)) {\
				params->data = OPENSSL_zalloc(params->return_size);\
				params->data_size = params->return_size;\
			}\
			if (prefix ## _get_params(arg, params))\
				RETVAL = make_param_scalar(params);\
		}\
	}

#ifdef MULTIPLICITY
#define iTHX aTHX
#else
#define iTHX NULL
#endif

static void EVP_name_callback(const char* name, void* vdata) {
	dTHXa((PerlInterpreter*)vdata);
	dSP;
	mXPUSHp(name, strlen(name));
	PUTBACK;
}

#define DEFINE_PROVIDED_CALLBACK(c_type)\
static inline void c_type ## _provided_callback(c_type* provided, void* vdata) {\
	dTHXa((PerlInterpreter*)vdata);\
	c_type ## _up_ref(provided);\
	SV* object = make_ ## c_type(aTHX_ provided);\
	dSP;\
	mXPUSHs(object);\
	PUTBACK;\
}
DEFINE_PROVIDED_CALLBACK(EVP_RAND)
DEFINE_PROVIDED_CALLBACK(EVP_CIPHER)
DEFINE_PROVIDED_CALLBACK(EVP_MD)
DEFINE_PROVIDED_CALLBACK(EVP_MAC)
DEFINE_PROVIDED_CALLBACK(EVP_KDF)
DEFINE_PROVIDED_CALLBACK(EVP_SIGNATURE)

typedef int Bool;
typedef int Success;
typedef int PrintRet;
#define undef &PL_sv_undef

#define CLONE_SKIP(...) 1

// This will force byte semantics on all strings
// This should come as the last thing in the C section of this file
#undef SvPV
#define SvPV(sv, len) SvPVbyte(sv, len)
#undef SvPV_nolen
#define SvPV_nolen(sv) SvPVbyte_nolen(sv)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3	PREFIX = OpenSSL_

REQUIRE: 3.60

PROTOTYPES: DISABLE

TYPEMAP: <<END
const unsigned char*	T_PV
Bool	T_BOOL
struct timeval	T_TIMEVAL
int64_t T_IV
uint32_t	T_UV
uint64_t	T_UV
Success T_SUCCESS
PrintRet T_PRINT

Crypt::OpenSSL3::Random T_MAGICEXT
Crypt::OpenSSL3::Random::Context T_MAGICEXT
Crypt::OpenSSL3::Cipher T_MAGICEXT
Crypt::OpenSSL3::Cipher::Context T_MAGICEXT
Crypt::OpenSSL3::MD T_MAGICEXT
Crypt::OpenSSL3::MD::Context T_MAGICEXT
Crypt::OpenSSL3::MAC T_MAGICEXT
Crypt::OpenSSL3::MAC::Context T_MAGICEXT
Crypt::OpenSSL3::KDF T_MAGICEXT
Crypt::OpenSSL3::KDF::Context T_MAGICEXT
Crypt::OpenSSL3::Signature T_MAGICEXT
Crypt::OpenSSL3::PKey T_MAGICEXT
Crypt::OpenSSL3::PKey::Context T_MAGICEXT

Crypt::OpenSSL3::BIO T_MAGICEXT
Crypt::OpenSSL3::BIO::Address T_MAGICEXT
Crypt::OpenSSL3::BIO::PollDescriptor T_MAGICBUF
Crypt::OpenSSL3::Error T_INTOBJ

Crypt::OpenSSL3::BigNum T_MAGICEXT
Crypt::OpenSSL3::BigNum::Context T_MAGICEXT

Crypt::OpenSSL3::ASN1::Object	T_MAGICEXT
Crypt::OpenSSL3::ASN1::Integer	T_MAGICEXT
Crypt::OpenSSL3::ASN1::Enumerated	T_MAGICEXT
Crypt::OpenSSL3::ASN1::String	T_MAGICEXT
Crypt::OpenSSL3::ASN1::String::UTF8	T_MAGICEXT
Crypt::OpenSSL3::ASN1::Time	T_MAGICEXT
Crypt::OpenSSL3::ASN1::Time::Generalized	T_MAGICEXT
Crypt::OpenSSL3::ASN1::Time::UTC	T_MAGICEXT

Crypt::OpenSSL3::X509	T_MAGICEXT
Crypt::OpenSSL3::X509::Stack	T_MAGICEXT
Crypt::OpenSSL3::X509::Store	T_MAGICEXT
Crypt::OpenSSL3::X509::Name	T_MAGICEXT
Crypt::OpenSSL3::X509::Name::Entry	T_MAGICEXT
Crypt::OpenSSL3::X509::Algorithm	T_MAGICEXT
Crypt::OpenSSL3::X509::VerifyResult T_INTOBJ
Crypt::OpenSSL3::X509::GeneralName	T_MAGICEXT
Crypt::OpenSSL3::X509::Extension	T_MAGICEXT
Crypt::OpenSSL3::X509::Attribute	T_MAGICEXT
Crypt::OpenSSL3::X509::VerifyParam	T_MAGICEXT
Crypt::OpenSSL3::X509::Request	T_MAGICEXT

Crypt::OpenSSL3::PKCS7	T_MAGICEXT

Crypt::OpenSSL3::Timestamp::Request	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::Response	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::Imprint	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::TokenInfo	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::StatusInfo	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::Accuracy	T_MAGICEXT
Crypt::OpenSSL3::Timestamp::Verifier	T_MAGICEXT

Crypt::OpenSSL3::SSL::Method T_MAGICEXT
Crypt::OpenSSL3::SSL::Context T_MAGICEXT
Crypt::OpenSSL3::SSL T_MAGICEXT
Crypt::OpenSSL3::SSL::Session T_MAGICEXT
Crypt::OpenSSL3::SSL::Cipher T_MAGICEXT
Crypt::OpenSSL3::NID T_INTOBJ

Crypt::OpenSSL3::HPKE T_MAGICBUF
Crypt::OpenSSL3::HPKE::Context T_MAGICEXT

PARAMS(EVP_RAND_CTX) T_PARAMS
PARAMS(EVP_CIPHER_CTX) T_PARAMS
CTX_PARAMS(EVP_CIPHER) T_CTX_PARAMS
PARAMS(EVP_MD_CTX) T_PARAMS
CTX_PARAMS(EVP_MD) T_CTX_PARAMS
PARAMS(EVP_MAC_CTX) T_PARAMS
PARAMS(EVP_KDF_CTX) T_PARAMS
PARAMS(EVP_PKEY) T_PARAMS
PARAMS(EVP_PKEY_CTX) T_PARAMS
CTX_PARAMS(EVP_SIGNATURE) T_CTX_PARAMS

INPUT
T_PARAMS
	const OSSL_PARAM* settable = ${ (my $settable = $type) =~ s/ PARAMS \( (\w+) \) /$1_settable_params(ctx)/x; \$settable };
	$var = params_for(settable, $arg);

T_CTX_PARAMS
	const OSSL_PARAM* settable = ${ (my $settable = $type) =~ s/ CTX_PARAMS \( (\w+) \) /$1_settable_ctx_params(type)/x; \$settable };
	$var = params_for(settable, $arg);

OUTPUT
T_TIMEVAL
	sv_setnv($arg, $var.tv_sec + $var.tv_usec / 1000000.0);
T_SUCCESS
	${"$var" eq "RETVAL" ? \"$arg = $var < 0 ? &PL_sv_undef : boolSV($var);" : \"sv_setsv($arg, $var < 0 ? &PL_sv_undef : boolSV($var));"}
T_PRINT
	${"$var" eq "RETVAL" ? \"$arg = $var < 0 ? &PL_sv_undef : newSViv($var);" : \"if ($var < 0) sv_setsv($arg, &PL_sv_undef); else sv_setiv($arg, $var);"}
T_PV
	sv_setpv((SV*)$arg, (const char*)$var);
END

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::", GV_ADD | GV_ADDMULTI);
	CONSTANT2(OPENSSL_, VERSION_STRING);
	CONSTANT2(OPENSSL_, VERSION_TEXT);
	CONSTANT2(OPENSSL_, FULL_VERSION_STRING);
	CONSTANT2(OPENSSL_, CFLAGS);
	CONSTANT2(OPENSSL_, BUILT_ON);
	CONSTANT2(OPENSSL_, PLATFORM);
	CONSTANT2(OPENSSL_, DIR);
	CONSTANT2(OPENSSL_, ENGINES_DIR);
	CONSTANT2(OPENSSL_, MODULES_DIR);
	CONSTANT2(OPENSSL_, CPU_INFO);
	CONSTANT2(OPENSSL_, INFO_CONFIG_DIR);
	CONSTANT2(OPENSSL_, INFO_ENGINES_DIR);
	CONSTANT2(OPENSSL_, INFO_MODULES_DIR);
	CONSTANT2(OPENSSL_, INFO_DSO_EXTENSION);
	CONSTANT2(OPENSSL_, INFO_DIR_FILENAME_SEPARATOR);
	CONSTANT2(OPENSSL_, INFO_LIST_SEPARATOR);
	CONSTANT2(OPENSSL_, INFO_CPU_SETTINGS);
#if OPENSSL_VERSION_PREREQ(3, 4)
	CONSTANT2(OPENSSL_, WINCTX);
	CONSTANT2(OPENSSL_, INFO_WINDOWS_CONTEXT);
#endif
}

const char *OpenSSL_version(int t = OPENSSL_VERSION_STRING)

unsigned long OpenSSL_version_num()

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3	PREFIX = OPENSSL_

unsigned int OPENSSL_version_major()

unsigned int OPENSSL_version_minor()

unsigned int OPENSSL_version_patch()

const char *OPENSSL_version_pre_release()

const char *OPENSSL_version_build_metadata()

const char *OPENSSL_info(int t)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3	PREFIX = ERR_

Crypt::OpenSSL3::Error ERR_get_error()

Crypt::OpenSSL3::Error ERR_peek_error()

void ERR_clear_error()

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Error	PREFIX = ERR_

SV* ERR_error_string(unsigned long e, size_t length = 64)
CODE:
	char* ptr = (char*)make_buffer(&RETVAL, length);
	ERR_error_string_n(e, ptr, length);
	set_buffer_length(RETVAL, strlen(ptr));
OUTPUT: RETVAL

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::BIO	PREFIX = BIO_

Crypt::OpenSSL3::BIO BIO_new_file(classname, const char *filename, const char *mode)
C_ARGS: filename, mode

Crypt::OpenSSL3::BIO BIO_new_fd(class, int fd, bool close_flag = FALSE)
INTERFACE: BIO_new_fd  BIO_new_socket  BIO_new_dgram
C_ARGS: fd, close_flag

NO_OUTPUT int BIO_new_bio_pair(classname, OUTLIST Crypt::OpenSSL3::BIO bio1, size_t writebuf1, OUTLIST Crypt::OpenSSL3::BIO bio2, size_t writebuf2);
C_ARGS: &bio1, writebuf1, &bio2, writebuf2
POSTCALL:
	if (!RETVAL)
		XSRETURN_EMPTY;

Crypt::OpenSSL3::BIO BIO_new_mem(class)
C_ARGS:

bool BIO_reset(Crypt::OpenSSL3::BIO b)

int BIO_seek(Crypt::OpenSSL3::BIO b, int ofs)

int BIO_tell(Crypt::OpenSSL3::BIO b)

bool BIO_flush(Crypt::OpenSSL3::BIO b)

bool BIO_eof(Crypt::OpenSSL3::BIO b)

bool BIO_set_close(Crypt::OpenSSL3::BIO b, bool flag)

bool BIO_get_close(Crypt::OpenSSL3::BIO b)

int BIO_pending(Crypt::OpenSSL3::BIO b)

int BIO_wpending(Crypt::OpenSSL3::BIO b)

size_t BIO_ctrl_pending(Crypt::OpenSSL3::BIO b)

size_t BIO_ctrl_wpending(Crypt::OpenSSL3::BIO b)

NO_OUTPUT int BIO_read(Crypt::OpenSSL3::BIO b, OUTLIST SV* out, int size)
INTERFACE: BIO_read  BIO_gets  BIO_get_line
INIT:
	unsigned char* ptr = make_buffer(&out, size);
C_ARGS: b, ptr, size
POSTCALL:
	if (RETVAL >= 0)
		set_buffer_length(out, RETVAL);

int BIO_write(Crypt::OpenSSL3::BIO b, const char *data, int length(data))

bool BIO_get_ktls_send(Crypt::OpenSSL3::BIO b)

bool BIO_get_ktls_recv(Crypt::OpenSSL3::BIO b)

#if OPENSSL_VERSION_PREREQ(3, 2)
bool BIO_get_rpoll_descriptor(Crypt::OpenSSL3::BIO b, Crypt::OpenSSL3::BIO::PollDescriptor desc)

bool BIO_get_wpoll_descriptor(Crypt::OpenSSL3::BIO b, Crypt::OpenSSL3::BIO::PollDescriptor desc)
#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::BIO::Address	PREFIX = BIO_ADDR_

#if OPENSSL_VERSION_PREREQ(3, 2)

Crypt::OpenSSL3::BIO::Address BIO_ADDR_new()

bool BIO_ADDR_copy(Crypt::OpenSSL3::BIO::Address dst, Crypt::OpenSSL3::BIO::Address src)

Crypt::OpenSSL3::BIO::Address BIO_ADDR_dup(Crypt::OpenSSL3::BIO::Address ap)

void BIO_ADDR_clear(Crypt::OpenSSL3::BIO::Address ap)

bool BIO_ADDR_rawmake(Crypt::OpenSSL3::BIO::Address ap, int family, const char *where, size_t length(where), unsigned short port)

int BIO_ADDR_family(Crypt::OpenSSL3::BIO::Address ap)

SV* BIO_ADDR_rawaddress(Crypt::OpenSSL3::BIO::Address ap)
CODE:
	size_t length = 0;
	if (BIO_ADDR_rawaddress(ap, NULL, &length)) {
		unsigned char* ptr = make_buffer(&RETVAL, length);
		if (BIO_ADDR_rawaddress(ap, ptr, &length))
			set_buffer_length(RETVAL, length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

unsigned short BIO_ADDR_rawport(Crypt::OpenSSL3::BIO::Address ap)

char *BIO_ADDR_hostname_string(Crypt::OpenSSL3::BIO::Address ap, int numeric)
INTERFACE:
	BIO_ADDR_hostname_string  BIO_ADDR_service_string  BIO_ADDR_path_string
CLEANUP:
	OPENSSL_free(RETVAL);

#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::BIO::PollDescriptor	PREFIX = BIO_POLL_DESCRIPTOR_
BOOT:
{
#if OPENSSL_VERSION_PREREQ(3, 2)
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::BIO::PollDescriptor", GV_ADD | GV_ADDMULTI);
	CONSTANT2(BIO_POLL_DESCRIPTOR_, TYPE_NONE);
	CONSTANT2(BIO_POLL_DESCRIPTOR_, TYPE_SOCK_FD);
	CONSTANT2(BIO_POLL_DESCRIPTOR_, CUSTOM_START);
#endif
}

#if OPENSSL_VERSION_PREREQ(3, 2)
Crypt::OpenSSL3::BIO::PollDescriptor BIO_POLL_DESCRIPTOR_new(class)

int BIO_POLL_DESCRIPTOR_type(Crypt::OpenSSL3::BIO::PollDescriptor desc)

int BIO_POLL_DESCRIPTOR_fd(Crypt::OpenSSL3::BIO::PollDescriptor desc)
#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::BigNum	PREFIX = BN_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::BigNum", GV_ADD | GV_ADDMULTI);
	CONSTANT2(BN_, RAND_TOP_ANY);
	CONSTANT2(BN_, RAND_TOP_ONE);
	CONSTANT2(BN_, RAND_TOP_TWO);

	CONSTANT2(BN_, RAND_BOTTOM_ANY);
	CONSTANT2(BN_, RAND_BOTTOM_ODD);
}


Crypt::OpenSSL3::BigNum BN_new(classname)
INTERFACE: BN_new  BN_secure_new
C_ARGS:

Crypt::OpenSSL3::BigNum BN_dup(Crypt::OpenSSL3::BigNum self)

bool BN_copy(Crypt::OpenSSL3::BigNum self, Crypt::OpenSSL3::BigNum other)

void BN_clear(Crypt::OpenSSL3::BigNum a)

bool BN_add(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b)

bool BN_sub(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b)

bool BN_mul(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_sqr(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_div(Crypt::OpenSSL3::BigNum dv, Crypt::OpenSSL3::BigNum rem, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum d, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod(Crypt::OpenSSL3::BigNum rem, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_nnmod(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_add(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_sub(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_mul(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_sqr(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_sqrt(Crypt::OpenSSL3::BigNum in, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum p, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_exp(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum p, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_mod_exp(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum p, Crypt::OpenSSL3::BigNum m, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_gcd(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum::Context ctx)

int BN_num_bytes(Crypt::OpenSSL3::BigNum a)

int BN_num_bits(Crypt::OpenSSL3::BigNum a)

NO_OUTPUT int BN_bn2bin(Crypt::OpenSSL3::BigNum a, OUTLIST SV* out)
INIT:
	unsigned char* ptr = make_buffer(&out, BN_num_bytes(a));
C_ARGS: a, ptr
POSTCALL:
	set_buffer_length(out, RETVAL);

NO_OUTPUT int BN_bn2binpad(Crypt::OpenSSL3::BigNum a, OUTLIST SV* out, int tolen = BN_num_bytes(a))
INTERFACE: BN_bn2binpad  BN_bn2lebinpad  BN_bn2nativepad
INIT:
	unsigned char* ptr = make_buffer(&out, tolen);
C_ARGS: a, ptr, tolen
POSTCALL:
	if (RETVAL >= 0)
		set_buffer_length(out, RETVAL);

Crypt::OpenSSL3::BigNum BN_bin2bn(const unsigned char *s, int length(s))
INTERFACE: BN_bin2bn BN_lebin2bn BN_native2bn
C_ARGS: s, XSauto_length_of_s, NULL

NO_OUTPUT int BN_bn2lebinpad(Crypt::OpenSSL3::BigNum a, OUTLIST SV* out, int tolen)
INTERFACE: BN_bn2lebinpad BN_bn2nativepad
INIT:
	unsigned char* ptr = make_buffer(&out, tolen);
C_ARGS: a, ptr, tolen
POSTCALL:
	if (RETVAL >= 0)
		set_buffer_length(out, RETVAL);

#if OPENSSL_VERSION_PREREQ(3, 2)
NO_OUTPUT int BN_signed_bn2lebin(Crypt::OpenSSL3::BigNum a, OUTLIST SV* out, int tolen = BN_num_bytes(a))
INTERFACE: BN_signed_bn2bin  BN_signed_bn2lebin  BN_signed_bn2native
INIT:
	unsigned char* ptr = make_buffer(&out, tolen);
C_ARGS: a, ptr, tolen
POSTCALL:
	if (RETVAL >= 0)
		set_buffer_length(out, RETVAL);

Crypt::OpenSSL3::BigNum BN_signed_bin2bn(const unsigned char *s, int length(s))
INTERFACE: BN_signed_bin2bn BN_signed_lebin2bn BN_signed_native2bn
C_ARGS: s, XSauto_length_of_s, NULL

#endif

char *BN_bn2hex(Crypt::OpenSSL3::BigNum a)
INTERFACE: BN_bn2hex  BN_bn2dec
CLEANUP:
	OPENSSL_free(RETVAL);

NO_OUTPUT int BN_hex2bn(OUTLIST Crypt::OpenSSL3::BigNum a, const char *str)
INIT:
	a = NULL;
INTERFACE: BN_hex2bn BN_dec2bn
C_ARGS: &a, str
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool BN_print(Crypt::OpenSSL3::BIO fp, Crypt::OpenSSL3::BigNum a)


NO_OUTPUT int BN_bn2mpi(Crypt::OpenSSL3::BigNum a, OUTLIST SV* out)
INIT:
	unsigned char* ptr = make_buffer(&out, BN_bn2mpi(a, NULL));
C_ARGS: a, ptr
POSTCALL:
	set_buffer_length(out, RETVAL);

Crypt::OpenSSL3::BigNum BN_mpi2bn(unsigned char *s, int len)
C_ARGS: s, len, NULL

bool BN_check_prime(Crypt::OpenSSL3::BigNum p, Crypt::OpenSSL3::BigNum::Context ctx)
C_ARGS: p, ctx, NULL

bool BN_generate_prime(Crypt::OpenSSL3::BigNum ret, int bits, int safe, Crypt::OpenSSL3::BigNum add, Crypt::OpenSSL3::BigNum rem, Crypt::OpenSSL3::BigNum::Context ctx)
C_ARGS: ret, bits, safe, add, rem, NULL, ctx

bool BN_set_word(Crypt::OpenSSL3::BigNum a, UV w)

UV BN_get_word(Crypt::OpenSSL3::BigNum a)

bool BN_add_word(Crypt::OpenSSL3::BigNum a, UV w)

bool BN_sub_word(Crypt::OpenSSL3::BigNum a, UV w)

bool BN_mul_word(Crypt::OpenSSL3::BigNum a, UV w)

UV BN_div_word(Crypt::OpenSSL3::BigNum a, UV w)

UV BN_mod_word(Crypt::OpenSSL3::BigNum a, UV w)

int BN_cmp(Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b)

int BN_ucmp(Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b)

bool BN_is_zero(Crypt::OpenSSL3::BigNum a)

bool BN_is_one(Crypt::OpenSSL3::BigNum a)

bool BN_is_word(Crypt::OpenSSL3::BigNum a, UV w)

bool BN_abs_is_word(Crypt::OpenSSL3::BigNum a, UV w)

bool BN_is_odd(Crypt::OpenSSL3::BigNum a)

#if OPENSSL_VERSION_PREREQ(3, 2)
bool BN_are_coprime(Crypt::OpenSSL3::BigNum a, Crypt::OpenSSL3::BigNum b, Crypt::OpenSSL3::BigNum::Context ctx);
#endif

bool BN_clear_bit(Crypt::OpenSSL3::BigNum a, int n)

bool BN_is_bit_set(Crypt::OpenSSL3::BigNum a, int n)

bool BN_mask_bits(Crypt::OpenSSL3::BigNum a, int n)

bool BN_lshift(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, int n)

bool BN_lshift1(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a)

bool BN_rshift(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a, int n)

bool BN_rshift1(Crypt::OpenSSL3::BigNum r, Crypt::OpenSSL3::BigNum a)

bool BN_rand_ex(Crypt::OpenSSL3::BigNum rnd, int bits, int top, int bottom, unsigned int strength, Crypt::OpenSSL3::BigNum::Context ctx)

bool BN_rand(Crypt::OpenSSL3::BigNum rnd, int bits, int top, int bottom)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::BigNum::Context	PREFIX = BN_CTX_

Crypt::OpenSSL3::BigNum::Context BN_CTX_new(classname)
INTERFACE: BN_CTX_new  BN_CTX_secure_new
C_ARGS:


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::ASN1", GV_ADD | GV_ADDMULTI);
	CONSTANT2(V_ASN1_, EOC);
	CONSTANT2(V_ASN1_, BOOLEAN);
	CONSTANT2(V_ASN1_, INTEGER);
	CONSTANT2(V_ASN1_, BIT_STRING);
	CONSTANT2(V_ASN1_, OCTET_STRING);
	CONSTANT2(V_ASN1_, NULL);
	CONSTANT2(V_ASN1_, OBJECT);
	CONSTANT2(V_ASN1_, OBJECT_DESCRIPTOR);
	CONSTANT2(V_ASN1_, EXTERNAL);
	CONSTANT2(V_ASN1_, REAL);
	CONSTANT2(V_ASN1_, ENUMERATED);
	CONSTANT2(V_ASN1_, UTF8STRING);
	CONSTANT2(V_ASN1_, SEQUENCE);
	CONSTANT2(V_ASN1_, SET);
	CONSTANT2(V_ASN1_, NUMERICSTRING);
	CONSTANT2(V_ASN1_, PRINTABLESTRING);
	CONSTANT2(V_ASN1_, T61STRING);
	CONSTANT2(V_ASN1_, TELETEXSTRING);
	CONSTANT2(V_ASN1_, VIDEOTEXSTRING);
	CONSTANT2(V_ASN1_, IA5STRING);
	CONSTANT2(V_ASN1_, UTCTIME);
	CONSTANT2(V_ASN1_, GENERALIZEDTIME);
	CONSTANT2(V_ASN1_, GRAPHICSTRING);
	CONSTANT2(V_ASN1_, ISO64STRING);
	CONSTANT2(V_ASN1_, VISIBLESTRING);
	CONSTANT2(V_ASN1_, GENERALSTRING);
	CONSTANT2(V_ASN1_, UNIVERSALSTRING);
	CONSTANT2(V_ASN1_, BMPSTRING);
}


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Object	PREFIX = OBJ_

Crypt::OpenSSL3::ASN1::Object OBJ_from_text(const char *s, bool no_name = FALSE)

Crypt::OpenSSL3::ASN1::Object OBJ_from_nid(Crypt::OpenSSL3::NID n)

int OBJ_cmp(Crypt::OpenSSL3::ASN1::Object a, Crypt::OpenSSL3::ASN1::Object b)

Crypt::OpenSSL3::NID OBJ_to_nid(Crypt::OpenSSL3::ASN1::Object o)

size_t OBJ_length(Crypt::OpenSSL3::ASN1::Object obj)

const unsigned char *OBJ_get_data(Crypt::OpenSSL3::ASN1::Object obj)

SV* OBJ_to_text(Crypt::OpenSSL3::ASN1::Object a, bool no_name = FALSE)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Integer	PREFIX = ASN1_INTEGER_

Crypt::OpenSSL3::ASN1::Integer ASN1_INTEGER_new()
C_ARGS:

NO_OUTPUT int ASN1_INTEGER_get_int64(Crypt::OpenSSL3::ASN1::Integer a, OUTLIST int64_t pr)
C_ARGS: &pr, a
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool ASN1_INTEGER_set_int64(Crypt::OpenSSL3::ASN1::Integer a, int64_t r)

NO_OUTPUT int ASN1_INTEGER_get_uint64(Crypt::OpenSSL3::ASN1::Integer a, OUTLIST uint64_t pr)
C_ARGS: &pr, a
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool ASN1_INTEGER_set_uint64(Crypt::OpenSSL3::ASN1::Integer a, uint64_t r)

Crypt::OpenSSL3::BigNum ASN1_INTEGER_get_BN(Crypt::OpenSSL3::ASN1::Integer ai)

bool ASN1_INTEGER_set_BN(Crypt::OpenSSL3::ASN1::Integer ai, Crypt::OpenSSL3::BigNum bn)

bool ASN1_INTEGER_set_buffer(Crypt::OpenSSL3::ASN1::String str, const char *data, int length(data))

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Enumerated	PREFIX = ASN1_ENUMERATED_

Crypt::OpenSSL3::ASN1::Enumerated ASN1_ENUMERATED_new()
C_ARGS:

NO_OUTPUT int ASN1_ENUMERATED_get_int64(Crypt::OpenSSL3::ASN1::Enumerated a, OUTLIST int64_t pr)
C_ARGS: &pr, a
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool ASN1_ENUMERATED_set_int64(Crypt::OpenSSL3::ASN1::Enumerated a, int64_t r)

bool ASN1_ENUMERATED_set_BN(Crypt::OpenSSL3::ASN1::Integer ai, Crypt::OpenSSL3::BigNum bn)

Crypt::OpenSSL3::BigNum ASN1_ENUMERATED_get_BN(Crypt::OpenSSL3::ASN1::Enumerated ai)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::String	PREFIX = ASN1_STRING_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::ASN1::String", GV_ADD | GV_ADDMULTI);
	CONSTANT2(ASN1_STR, FLGS_ESC_2253);
	CONSTANT2(ASN1_STR, FLGS_ESC_CTRL);
	CONSTANT2(ASN1_STR, FLGS_ESC_MSB);
	CONSTANT2(ASN1_STR, FLGS_UTF8_CONVERT);
	CONSTANT2(ASN1_STR, FLGS_IGNORE_TYPE);
	CONSTANT2(ASN1_STR, FLGS_SHOW_TYPE);
	CONSTANT2(ASN1_STR, FLGS_DUMP_ALL);
	CONSTANT2(ASN1_STR, FLGS_DUMP_UNKNOWN);
	CONSTANT2(ASN1_STR, FLGS_DUMP_DER);
	CONSTANT2(ASN1_STR, FLGS_ESC_2254);
	CONSTANT2(ASN1_STR, FLGS_RFC2253);
}

Crypt::OpenSSL3::ASN1::String ASN1_STRING_new()
C_ARGS:

int ASN1_STRING_length(Crypt::OpenSSL3::ASN1::String x)

SV* ASN1_STRING_get_data(Crypt::OpenSSL3::ASN1::String x)
CODE:
	const unsigned char* data = ASN1_STRING_get0_data(x);
	int length = ASN1_STRING_length(x);
	RETVAL = newSVpvn((const char*)data, length);
OUTPUT: RETVAL

Crypt::OpenSSL3::ASN1::String ASN1_STRING_dup(Crypt::OpenSSL3::ASN1::String a)

int ASN1_STRING_cmp(Crypt::OpenSSL3::ASN1::String a, Crypt::OpenSSL3::ASN1::String b)

bool ASN1_STRING_set(Crypt::OpenSSL3::ASN1::String str, const char *data, int length(data))

int ASN1_STRING_type(Crypt::OpenSSL3::ASN1::String x)

SV* ASN1_STRING_to_UTF8(Crypt::OpenSSL3::ASN1::String in)
CODE:
	unsigned char* out = NULL;
	int result = ASN1_STRING_to_UTF8(&out, in);
	if (result > 0) {
		RETVAL = newSVpvn_utf8((char*)out, result, 1);
		OPENSSL_free(out);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

bool ASN1_STRING_print(Crypt::OpenSSL3::BIO out, Crypt::OpenSSL3::ASN1::String str)

PrintRet ASN1_STRING_print_ex(Crypt::OpenSSL3::BIO out, Crypt::OpenSSL3::ASN1::String str, unsigned long flags)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Time	PREFIX = ASN1_TIME_

Crypt::OpenSSL3::ASN1::Time ASN1_TIME_new(class)
C_ARGS:

Crypt::OpenSSL3::ASN1::Time ASN1_TIME_dup(Crypt::OpenSSL3::ASN1::Time t);

bool ASN1_TIME_set(Crypt::OpenSSL3::ASN1::Time s, time_t t)

bool ASN1_TIME_adj(Crypt::OpenSSL3::ASN1::Time s, time_t t, int offset_day, long offset_sec)

bool ASN1_TIME_set_string(Crypt::OpenSSL3::ASN1::Time s, const char *str)

bool ASN1_TIME_set_string_X509(Crypt::OpenSSL3::ASN1::Time s, const char *str)

bool ASN1_TIME_normalize(Crypt::OpenSSL3::ASN1::Time s)

bool ASN1_TIME_check(Crypt::OpenSSL3::ASN1::Time t)

bool ASN1_TIME_print(Crypt::OpenSSL3::BIO b, Crypt::OpenSSL3::ASN1::Time s)

PrintRet ASN1_TIME_print_ex(Crypt::OpenSSL3::BIO bp, Crypt::OpenSSL3::ASN1::Time tm, unsigned long flags)

NO_OUTPUT bool ASN1_TIME_diff(Crypt::OpenSSL3::ASN1::Time from, Crypt::OpenSSL3::ASN1::Time to, OUTLIST int pday, OUTLIST int psec)
C_ARGS: &pday, &psec, from, to
POSTCALL:
	if (!RETVAL)
		XSRETURN_EMPTY;

int ASN1_TIME_cmp_time(Crypt::OpenSSL3::ASN1::Time s, time_t t)

int ASN1_TIME_compare(Crypt::OpenSSL3::ASN1::Time a, Crypt::OpenSSL3::ASN1::Time b)
POSTCALL:
	if (RETVAL == -2)
		XSRETURN_UNDEF;

void ASN1_TIME_to_tm(Crypt::OpenSSL3::ASN1::Time s)
PPCODE:
	struct tm tm;
	if (ASN1_TIME_to_tm(s, &tm)) {
		EXTEND(SP, 9);
		mPUSHi(tm.tm_sec);
		mPUSHi(tm.tm_min);
		mPUSHi(tm.tm_hour);
		mPUSHi(tm.tm_mday);
		mPUSHi(tm.tm_mon);
		mPUSHi(tm.tm_year);
		mPUSHi(tm.tm_wday);
		mPUSHi(tm.tm_yday);
		mPUSHi(tm.tm_isdst);
	}

Crypt::OpenSSL3::ASN1::Time::Generalized ASN1_TIME_to_generalizedtime(Crypt::OpenSSL3::ASN1::Time t)
C_ARGS: t, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Time::Generalized	PREFIX = ASN1_GENERALIZEDTIME_

Crypt::OpenSSL3::ASN1::Time::Generalized ASN1_GENERALIZEDTIME_new(class)
C_ARGS:

Crypt::OpenSSL3::ASN1::Time::Generalized ASN1_GENERALIZEDTIME_dup(Crypt::OpenSSL3::ASN1::Time::Generalized t);

bool ASN1_GENERALIZEDTIME_set(Crypt::OpenSSL3::ASN1::Time::Generalized s, time_t t)

bool ASN1_GENERALIZEDTIME_adj(Crypt::OpenSSL3::ASN1::Time::Generalized s, time_t t, int offset_day, long offset_sec)

bool ASN1_GENERALIZEDTIME_set_string(Crypt::OpenSSL3::ASN1::Time::Generalized s, const char *str)

bool ASN1_GENERALIZEDTIME_check(Crypt::OpenSSL3::ASN1::Time::Generalized t)

bool ASN1_GENERALIZEDTIME_print(Crypt::OpenSSL3::BIO b, Crypt::OpenSSL3::ASN1::Time::Generalized s)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::ASN1::Time::UTC	PREFIX = ASN1_UTCTIME_

Crypt::OpenSSL3::ASN1::Time::UTC ASN1_UTCTIME_new(class)
C_ARGS:

Crypt::OpenSSL3::ASN1::Time::UTC ASN1_UTCTIME_dup(Crypt::OpenSSL3::ASN1::Time::UTC t);

bool ASN1_UTCTIME_set(Crypt::OpenSSL3::ASN1::Time::UTC s, time_t t)

bool ASN1_UTCTIME_adj(Crypt::OpenSSL3::ASN1::Time::UTC s, time_t t, int offset_day, long offset_sec)

bool ASN1_UTCTIME_set_string(Crypt::OpenSSL3::ASN1::Time::UTC s, const char *str)

int ASN1_UTCTIME_cmp_time_t(Crypt::OpenSSL3::ASN1::Time::UTC s, time_t t)

bool ASN1_UTCTIME_check(Crypt::OpenSSL3::ASN1::Time::UTC t)

bool ASN1_UTCTIME_print(Crypt::OpenSSL3::BIO b, Crypt::OpenSSL3::ASN1::Time::UTC s)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509	PREFIX = X509_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::X509", GV_ADD | GV_ADDMULTI);
	CONSTANT2(X509_, CHECK_FLAG_ALWAYS_CHECK_SUBJECT);
	CONSTANT2(X509_, CHECK_FLAG_NEVER_CHECK_SUBJECT);
	CONSTANT2(X509_, CHECK_FLAG_NO_WILDCARDS);
	CONSTANT2(X509_, CHECK_FLAG_NO_PARTIAL_WILDCARDS);
	CONSTANT2(X509_, CHECK_FLAG_MULTI_LABEL_WILDCARDS);
	CONSTANT2(X509_, CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS);
}

Crypt::OpenSSL3::X509 X509_new(class)
C_ARGS:

Crypt::OpenSSL3::X509 X509_dup(Crypt::OpenSSL3::X509 self)

Crypt::OpenSSL3::X509 X509_read_pem(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL, NULL, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool X509_write_pem(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

Crypt::OpenSSL3::X509 X509_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool X509_write_der(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

const char *X509_get_default_cert_file(class)
C_ARGS:

const char *X509_get_default_cert_dir(class)
C_ARGS:

const char *X509_get_default_cert_file_env(class)
C_ARGS:

const char *X509_get_default_cert_dir_env(class)
C_ARGS:

bool X509_sign(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::MD md)

bool X509_sign_ctx(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::MD::Context ctx)

bool X509_verify(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::PKey pkey)

bool X509_self_signed(Crypt::OpenSSL3::X509 cert, bool verify_signature)

Crypt::OpenSSL3::PKey X509_get_pubkey(Crypt::OpenSSL3::X509 x)

bool X509_set_pubkey(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::PKey pkey);

long X509_get_version(Crypt::OpenSSL3::X509 x)

bool X509_set_version(Crypt::OpenSSL3::X509 x, long version)

void X509_get_signature(Crypt::OpenSSL3::X509 x, OUTLIST Crypt::OpenSSL3::ASN1::String psig, OUTLIST Crypt::OpenSSL3::X509::Algorithm palg)
C_ARGS: (const ASN1_BIT_STRING**)&psig, (const X509_ALGOR**)&palg, x
POSTCALL:
	psig = ASN1_STRING_dup(psig);
	palg = X509_ALGOR_dup(palg);

Crypt::OpenSSL3::NID X509_get_signature_nid(Crypt::OpenSSL3::X509 x)

Crypt::OpenSSL3::X509::Algorithm X509_get_tbs_sigalg(Crypt::OpenSSL3::X509 x)
POSTCALL:
	RETVAL = X509_ALGOR_dup(RETVAL);

Crypt::OpenSSL3::ASN1::Time X509_get_notBefore(Crypt::OpenSSL3::X509 x)
INTERFACE: X509_get_notBefore X509_get_notAfter
POSTCALL:
	RETVAL = ASN1_TIME_dup(RETVAL);

bool X509_set_notBefore(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::ASN1::Time tm)

bool X509_set_notAfter(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::ASN1::Time tm)

Crypt::OpenSSL3::X509::Name X509_get_subject_name(Crypt::OpenSSL3::X509 x)
INTERFACE:
	X509_get_subject_name  X509_get_issuer_name
POSTCALL:
	RETVAL = X509_NAME_dup(RETVAL);

bool X509_set_subject_name(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::X509::Name name)

bool X509_set_issuer_name(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::X509::Name name)

unsigned long X509_subject_name_hash(Crypt::OpenSSL3::X509 x)

unsigned long X509_issuer_name_hash(Crypt::OpenSSL3::X509 x)

NO_OUTPUT Bool X509_digest(Crypt::OpenSSL3::X509 data, Crypt::OpenSSL3::MD type, OUTLIST SV* digest)
INTERFACE: X509_digest  X509_pubkey_digest
INIT:
	unsigned int output_length = EVP_MD_size(type);
	unsigned char* ptr = make_buffer(&digest, output_length);
C_ARGS: data, type, ptr, &output_length
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, output_length);

Crypt::OpenSSL3::ASN1::String X509_digest_sig(Crypt::OpenSSL3::X509 cert)
C_ARGS: cert, NULL, NULL

Crypt::OpenSSL3::ASN1::String X509_get_distinguishing_id(Crypt::OpenSSL3::X509 x)

void X509_set_distinguishing_id(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::ASN1::String distid)
INIT:
	distid = ASN1_OCTET_STRING_dup(distid);

bool X509_check_ca(Crypt::OpenSSL3::X509 cert)

bool X509_check_host(Crypt::OpenSSL3::X509 cert, const char *name, size_t length(name), unsigned int flags, OUTLIST char *peername)

bool X509_check_email(Crypt::OpenSSL3::X509 cert, const char *address, size_t length(address), unsigned int flags)

bool X509_check_ip(Crypt::OpenSSL3::X509 cert, const unsigned char *address, size_t length(address), unsigned int flags)

bool X509_check_ip_asc(Crypt::OpenSSL3::X509 cert, const char *address, unsigned int flags)

bool X509_check_issued(Crypt::OpenSSL3::X509 issuer, Crypt::OpenSSL3::X509 subject)

bool X509_check_private_key(Crypt::OpenSSL3::X509 cert, Crypt::OpenSSL3::PKey pkey)

int X509_cmp(Crypt::OpenSSL3::X509 a, Crypt::OpenSSL3::X509 b)

int X509_issuer_and_serial_cmp(Crypt::OpenSSL3::X509 a, Crypt::OpenSSL3::X509 b)

int X509_issuer_name_cmp(Crypt::OpenSSL3::X509 a, Crypt::OpenSSL3::X509 b)

int X509_subject_name_cmp(Crypt::OpenSSL3::X509 a, Crypt::OpenSSL3::X509 b)

long X509_get_pathlen(Crypt::OpenSSL3::X509 x)

uint32_t X509_get_extension_flags(Crypt::OpenSSL3::X509 x)

uint32_t X509_get_key_usage(Crypt::OpenSSL3::X509 x)

uint32_t X509_get_extended_key_usage(Crypt::OpenSSL3::X509 x)

Crypt::OpenSSL3::ASN1::String X509_get_subject_key_id(Crypt::OpenSSL3::X509 x)
POSTCALL:
	if (RETVAL)
		RETVAL = ASN1_OCTET_STRING_dup(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::ASN1::String X509_get_authority_key_id(Crypt::OpenSSL3::X509 x)
POSTCALL:
	if (RETVAL)
		RETVAL = ASN1_OCTET_STRING_dup(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::X509::GeneralName X509_get_authority_issuer(Crypt::OpenSSL3::X509 x)
POSTCALL:
	if (RETVAL)
		RETVAL = GENERAL_NAME_dup(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::ASN1::Integer X509_get_authority_serial(Crypt::OpenSSL3::X509 x)
POSTCALL:
	if (RETVAL)
		RETVAL = ASN1_INTEGER_dup(RETVAL);
	else
		XSRETURN_UNDEF;

void X509_set_proxy_flag(Crypt::OpenSSL3::X509 x)

void X509_set_proxy_pathlen(Crypt::OpenSSL3::X509 x, int l)

long X509_get_proxy_pathlen(Crypt::OpenSSL3::X509 x)

int X509_get_ext_count(Crypt::OpenSSL3::X509 x)

Crypt::OpenSSL3::X509::Extension X509_get_ext(Crypt::OpenSSL3::X509 x, int loc)

int X509_get_ext_by_NID(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::NID nid, int lastpos = -1)

int X509_get_ext_by_OBJ(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::ASN1::Object obj, int lastpos = -1)

int X509_get_ext_by_critical(Crypt::OpenSSL3::X509 x, int crit, int lastpos = -1)

Crypt::OpenSSL3::X509::Extension X509_delete_ext(Crypt::OpenSSL3::X509 x, int loc)

int X509_add_ext(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::X509::Extension ex, int loc = -1)

Crypt::OpenSSL3::ASN1::Integer X509_get_serialNumber(Crypt::OpenSSL3::X509 x)

bool X509_set_serialNumber(Crypt::OpenSSL3::X509 x, Crypt::OpenSSL3::ASN1::Integer serial)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::VerifyParam	PREFIX = X509_VERIFY_PARAM_

Crypt::OpenSSL3::X509::VerifyParam X509_VERIFY_PARAM_new(class)
C_ARGS:

bool X509_VERIFY_PARAM_set_flags(Crypt::OpenSSL3::X509::VerifyParam param, unsigned long flags)

bool X509_VERIFY_PARAM_clear_flags(Crypt::OpenSSL3::X509::VerifyParam param, unsigned long flags)

unsigned long X509_VERIFY_PARAM_get_flags(Crypt::OpenSSL3::X509::VerifyParam param)

bool X509_VERIFY_PARAM_set_inh_flags(Crypt::OpenSSL3::X509::VerifyParam param, uint32_t flags)

uint32_t X509_VERIFY_PARAM_get_inh_flags(Crypt::OpenSSL3::X509::VerifyParam param)

bool X509_VERIFY_PARAM_set_purpose(Crypt::OpenSSL3::X509::VerifyParam param, int purpose)

#if OPENSSL_VERSION_PREREQ(3, 5)
int X509_VERIFY_PARAM_get_purpose(Crypt::OpenSSL3::X509::VerifyParam param)
#endif

bool X509_VERIFY_PARAM_set_trust(Crypt::OpenSSL3::X509::VerifyParam param, int trust)

void X509_VERIFY_PARAM_set_time(Crypt::OpenSSL3::X509::VerifyParam param, time_t t)

time_t X509_VERIFY_PARAM_get_time(Crypt::OpenSSL3::X509::VerifyParam param)

bool X509_VERIFY_PARAM_add_policy(Crypt::OpenSSL3::X509::VerifyParam param, Crypt::OpenSSL3::ASN1::Object policy)
C_ARGS: param, (ASN1_OBJECT*)policy

#if 0
bool X509_VERIFY_PARAM_set1_policies(Crypt::OpenSSL3::X509::VerifyParam param, Crypt::OpenSSL3::ASN1::Object policies)
#endif

void X509_VERIFY_PARAM_set_depth(Crypt::OpenSSL3::X509::VerifyParam param, int depth)

int X509_VERIFY_PARAM_get_depth(Crypt::OpenSSL3::X509::VerifyParam param)

void X509_VERIFY_PARAM_set_auth_level(Crypt::OpenSSL3::X509::VerifyParam param, int auth_level)

int X509_VERIFY_PARAM_get_auth_level(Crypt::OpenSSL3::X509::VerifyParam param)

char *X509_VERIFY_PARAM_get_host(Crypt::OpenSSL3::X509::VerifyParam param, int n)

bool X509_VERIFY_PARAM_set_host(Crypt::OpenSSL3::X509::VerifyParam param, const char *name, size_t length(name))

bool X509_VERIFY_PARAM_add_host(Crypt::OpenSSL3::X509::VerifyParam param, const char *name, size_t length(name))

void X509_VERIFY_PARAM_set_hostflags(Crypt::OpenSSL3::X509::VerifyParam param, unsigned int flags)

unsigned int X509_VERIFY_PARAM_get_hostflags(Crypt::OpenSSL3::X509::VerifyParam param)

char *X509_VERIFY_PARAM_get_peername(Crypt::OpenSSL3::X509::VerifyParam param)

char *X509_VERIFY_PARAM_get_email(Crypt::OpenSSL3::X509::VerifyParam param)

bool X509_VERIFY_PARAM_set_email(Crypt::OpenSSL3::X509::VerifyParam param, const char *email, size_t length(email))

char *X509_VERIFY_PARAM_get_ip_asc(Crypt::OpenSSL3::X509::VerifyParam param)
CLEANUP:
	OPENSSL_free(RETVAL);

bool X509_VERIFY_PARAM_set_ip(Crypt::OpenSSL3::X509::VerifyParam param, const unsigned char *ip, size_t length(ip))

bool X509_VERIFY_PARAM_set_ip_asc(Crypt::OpenSSL3::X509::VerifyParam param, const char *ipasc)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::GeneralName	PREFIX = GENERAL_NAME_

Crypt::OpenSSL3::X509::GeneralName GENERAL_NAME_new(class)
C_ARGS:

#if OPENSSL_VERSION_PREREQ(3, 4)
NO_OUTPUT int GENERAL_NAME_new_from_x509_name(OUTLIST Crypt::OpenSSL3::X509::GeneralName name, Crypt::OpenSSL3::X509::Name src)
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;
#endif

Crypt::OpenSSL3::X509::GeneralName GENERAL_NAME_dup(Crypt::OpenSSL3::X509::GeneralName gn)

int GENERAL_NAME_type(Crypt::OpenSSL3::X509::GeneralName gn)

SV* GENERAL_NAME_to_string(Crypt::OpenSSL3::X509::GeneralName gn)
CODE:
	switch (gn->type) {
		case GEN_OTHERNAME: {
			ASN1_UTF8STRING* str = gn->d.otherName->value->value.utf8string;
			RETVAL = newSVpvn((const char*)ASN1_STRING_get0_data(str), ASN1_STRING_length(str));
			break;
		}
		case GEN_EMAIL:
		case GEN_DNS:
		case GEN_X400:
		case GEN_URI:
		case GEN_IPADD: {
			ASN1_STRING* str = gn->d.rfc822Name;
			const unsigned char* data = ASN1_STRING_get0_data(str);
			int length = ASN1_STRING_length(str);
			RETVAL = newSVpvn((const char*)data, length);
			break;
		}
		case GEN_DIRNAME: {
			char* str = X509_NAME_oneline(gn->d.directoryName, NULL, 0);
			RETVAL = newSVpv(str, 0);
			OPENSSL_free(str);
			break;
		}
		case GEN_RID: {
			RETVAL = OBJ_to_text(gn->d.registeredID, 1);
			break;
		}
		default:
			RETVAL = &PL_sv_undef;
	}
OUTPUT: RETVAL

SV* GENERAL_NAME_to_value(Crypt::OpenSSL3::X509::GeneralName gn)
CODE:
	switch (gn->type) {
		case GEN_OTHERNAME: {
			ASN1_UTF8STRING* str = gn->d.otherName->value->value.utf8string;
			RETVAL = make_ASN1_STRING(aTHX_ ASN1_STRING_dup(str));
			break;
		}
		case GEN_EMAIL:
		case GEN_DNS:
		case GEN_X400:
		case GEN_URI:
		case GEN_IPADD:
			RETVAL = make_ASN1_STRING(aTHX_ ASN1_STRING_dup(gn->d.rfc822Name));
			break;
		case GEN_RID:
			RETVAL = make_ASN1_OBJECT(aTHX_ gn->d.registeredID);
			break;
		case GEN_DIRNAME:
			RETVAL = make_X509_NAME(aTHX_ X509_NAME_dup(gn->d.directoryName));
			break;
		default:
			RETVAL = &PL_sv_undef;
	}
OUTPUT: RETVAL


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Algorithm	PREFIX = X509_ALGOR_

Crypt::OpenSSL3::X509::Algorithm X509_ALGOR_new(class)
C_ARGS:

Crypt::OpenSSL3::X509::Algorithm X509_ALGOR_dup(Crypt::OpenSSL3::X509::Algorithm alg)

bool X509_ALGOR_set(Crypt::OpenSSL3::X509::Algorithm alg, Crypt::OpenSSL3::ASN1::Object aobj)
C_ARGS: alg, (ASN1_OBJECT*)aobj, V_ASN1_UNDEF, NULL

void X509_ALGOR_get(Crypt::OpenSSL3::X509::Algorithm alg, OUTLIST Crypt::OpenSSL3::ASN1::Object paobj)
C_ARGS: (const ASN1_OBJECT**)&paobj, NULL, NULL, alg

void X509_ALGOR_set_md(Crypt::OpenSSL3::X509::Algorithm alg, Crypt::OpenSSL3::MD md)

int X509_ALGOR_cmp(Crypt::OpenSSL3::X509::Algorithm a, Crypt::OpenSSL3::X509::Algorithm b)

bool X509_ALGOR_copy(Crypt::OpenSSL3::X509::Algorithm dest, Crypt::OpenSSL3::X509::Algorithm src)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Attribute	PREFIX = X509_ATTRIBUTE_


Crypt::OpenSSL3::X509::Attribute X509_ATTRIBUTE_create(class, Crypt::OpenSSL3::NID nid, int atrtype, char *value)
C_ARGS: nid, atrtype, value

Crypt::OpenSSL3::X509::Attribute X509_ATTRIBUTE_create_by_NID(class, Crypt::OpenSSL3::NID nid, int atrtype, const char *data, int length(data))
C_ARGS: NULL, nid, atrtype, data, XSauto_length_of_data

Crypt::OpenSSL3::X509::Attribute X509_ATTRIBUTE_create_by_OBJ(class, Crypt::OpenSSL3::ASN1::Object obj, int atrtype, const char *data, int length(data))
C_ARGS: NULL, obj, atrtype, data, XSauto_length_of_data

Crypt::OpenSSL3::X509::Attribute X509_ATTRIBUTE_create_by_txt(class, const char *atrname, int type, const unsigned char *bytes, int length(bytes))
C_ARGS: NULL, atrname, type, bytes, XSauto_length_of_bytes

bool X509_ATTRIBUTE_set_object(Crypt::OpenSSL3::X509::Attribute attr, Crypt::OpenSSL3::ASN1::Object obj)

bool X509_ATTRIBUTE_set_data(Crypt::OpenSSL3::X509::Attribute attr, int attrtype, const char *data, int length(data))

const char *X509_ATTRIBUTE_get_data(Crypt::OpenSSL3::X509::Attribute attr, int idx, int atrtype)
C_ARGS: attr, idx, atrtype, NULL

PrintRet X509_ATTRIBUTE_count(Crypt::OpenSSL3::X509::Attribute attr)

Crypt::OpenSSL3::ASN1::Object X509_ATTRIBUTE_get_object(Crypt::OpenSSL3::X509::Attribute attr)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Extension	PREFIX = X509_EXTENSION_

Crypt::OpenSSL3::X509::Extension X509_EXTENSION_new(class)
C_ARGS:

Crypt::OpenSSL3::X509::Extension X509_EXTENSION_dup(Crypt::OpenSSL3::X509::Extension ex)

bool X509_EXTENSION_set_object(Crypt::OpenSSL3::X509::Extension ex, Crypt::OpenSSL3::ASN1::Object obj)

bool X509_EXTENSION_set_critical(Crypt::OpenSSL3::X509::Extension ex, bool crit)

bool X509_EXTENSION_set_data(Crypt::OpenSSL3::X509::Extension ex, Crypt::OpenSSL3::ASN1::String data)

Crypt::OpenSSL3::X509::Extension X509_EXTENSION_create_by_NID(Crypt::OpenSSL3::NID nid, bool crit, Crypt::OpenSSL3::ASN1::String data)
C_ARGS: NULL, nid, crit, data

Crypt::OpenSSL3::X509::Extension X509_EXTENSION_create_by_OBJ(Crypt::OpenSSL3::ASN1::Object obj, bool crit, Crypt::OpenSSL3::ASN1::String data)
C_ARGS: NULL, obj, crit, data

Crypt::OpenSSL3::ASN1::Object X509_EXTENSION_get_object(Crypt::OpenSSL3::X509::Extension ex)

bool X509_EXTENSION_get_critical(Crypt::OpenSSL3::X509::Extension ex)

Crypt::OpenSSL3::ASN1::String X509_EXTENSION_get_data(Crypt::OpenSSL3::X509::Extension ne)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Stack	PREFIX = sk_X509_

int sk_X509_num(Crypt::OpenSSL3::X509::Stack sk)

Crypt::OpenSSL3::X509 sk_X509_value(Crypt::OpenSSL3::X509::Stack sk, int idx)

Crypt::OpenSSL3::X509::Stack sk_X509_new(class)
C_ARGS: NULL

int sk_X509_reserve(Crypt::OpenSSL3::X509::Stack sk, int n)

void sk_X509_free(Crypt::OpenSSL3::X509::Stack sk)

void sk_X509_zero(Crypt::OpenSSL3::X509::Stack sk)

Crypt::OpenSSL3::X509 sk_X509_delete(Crypt::OpenSSL3::X509::Stack sk, int i)

Crypt::OpenSSL3::X509 sk_X509_delete_ptr(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr)

int sk_X509_push(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr)

int sk_X509_unshift(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr)

Crypt::OpenSSL3::X509 sk_X509_pop(Crypt::OpenSSL3::X509::Stack sk)

Crypt::OpenSSL3::X509 sk_X509_shift(Crypt::OpenSSL3::X509::Stack sk)

void sk_X509_pop_free(Crypt::OpenSSL3::X509::Stack sk)
C_ARGS: sk, X509_free

int sk_X509_insert(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr, int idx)

Crypt::OpenSSL3::X509 sk_X509_set(Crypt::OpenSSL3::X509::Stack sk, int idx, Crypt::OpenSSL3::X509 ptr)

int sk_X509_find(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr)

int sk_X509_find_ex(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr)

int sk_X509_find_all(Crypt::OpenSSL3::X509::Stack sk, Crypt::OpenSSL3::X509 ptr, OUT int pnum)

void sk_X509_sort(Crypt::OpenSSL3::X509::Stack sk)

int sk_X509_is_sorted(Crypt::OpenSSL3::X509::Stack sk)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::VerifyResult	PREFIX = X509_verify_cert_

IV X509_verify_cert_error_code(Crypt::OpenSSL3::X509::VerifyResult result)

bool X509_verify_cert_ok(Crypt::OpenSSL3::X509::VerifyResult result)

const char* X509_verify_cert_error_string(Crypt::OpenSSL3::X509::VerifyResult result)

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Name	PREFIX = X509_NAME_

Crypt::OpenSSL3::X509::Name X509_NAME_new(class)
C_ARGS:

Crypt::OpenSSL3::X509::Name X509_NAME_dup(Crypt::OpenSSL3::X509::Name self)

int X509_NAME_cmp(Crypt::OpenSSL3::X509::Name a, Crypt::OpenSSL3::X509::Name b)

int X509_NAME_get_index_by_NID(Crypt::OpenSSL3::X509::Name name, Crypt::OpenSSL3::NID nid, int lastpos)

int X509_NAME_get_index_by_OBJ(Crypt::OpenSSL3::X509::Name name, Crypt::OpenSSL3::ASN1::Object obj, int lastpos)

int X509_NAME_entry_count(Crypt::OpenSSL3::X509::Name name)

Crypt::OpenSSL3::X509::Name::Entry X509_NAME_get_entry(Crypt::OpenSSL3::X509::Name name, int loc)
POSTCALL:
	RETVAL = X509_NAME_ENTRY_dup(RETVAL);

char* X509_NAME_oneline(Crypt::OpenSSL3::X509::Name a)
	C_ARGS: a, NULL, 0
	CLEANUP:
		if (RETVAL)
			OPENSSL_free(RETVAL);

NO_OUTPUT int X509_NAME_digest(Crypt::OpenSSL3::X509::Name data, Crypt::OpenSSL3::MD type, OUTLIST SV* hash)
INIT:
	unsigned len = EVP_MD_size(type);
	unsigned char* ptr = make_buffer(&hash, len);
C_ARGS: data, type, ptr, &len
POSTCALL:
	if (RETVAL)
		set_buffer_length(hash, len);

bool X509_NAME_add_entry_by_txt(Crypt::OpenSSL3::X509::Name name, const char *field, int type, const unsigned char *bytes, int len, int loc, int set)

bool X509_NAME_add_entry_by_OBJ(Crypt::OpenSSL3::X509::Name name, Crypt::OpenSSL3::ASN1::Object obj, int type, const unsigned char *bytes, int length(bytes), int loc, int set)

bool X509_NAME_add_entry_by_NID(Crypt::OpenSSL3::X509::Name name, Crypt::OpenSSL3::NID nid, int type, const unsigned char *bytes, int len, int loc, int set)

bool X509_NAME_add_entry(Crypt::OpenSSL3::X509::Name name, Crypt::OpenSSL3::X509::Name::Entry ne, int loc, int set)

Crypt::OpenSSL3::X509::Name::Entry X509_NAME_delete_entry(Crypt::OpenSSL3::X509::Name name, int loc)

int X509_NAME_print(Crypt::OpenSSL3::X509::Name nm, Crypt::OpenSSL3::BIO out, int indent, unsigned long flags)
C_ARGS: out, nm, indent, flags

unsigned long X509_NAME_hash(Crypt::OpenSSL3::X509::Name x, const char *propq = NULL)
C_ARGS: x, NULL, propq, NULL

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Name::Entry	PREFIX = X509_NAME_ENTRY

Crypt::OpenSSL3::X509::Name::Entry X509_NAME_ENTRY_new(class)
C_ARGS:

Crypt::OpenSSL3::ASN1::Object X509_NAME_ENTRY_get_object(Crypt::OpenSSL3::X509::Name::Entry ne)

Crypt::OpenSSL3::ASN1::String X509_NAME_ENTRY_get_data(Crypt::OpenSSL3::X509::Name::Entry ne)

bool X509_NAME_ENTRY_set_object(Crypt::OpenSSL3::X509::Name::Entry ne, Crypt::OpenSSL3::ASN1::Object obj)

bool X509_NAME_ENTRY_set_data(Crypt::OpenSSL3::X509::Name::Entry ne, int type, const unsigned char *bytes, int length(bytes))

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Store	PREFIX = X509_STORE_

Crypt::OpenSSL3::X509::Store X509_STORE_new(class)
C_ARGS:

bool X509_STORE_lock(Crypt::OpenSSL3::X509::Store store)

bool X509_STORE_unlock(Crypt::OpenSSL3::X509::Store store)

bool X509_STORE_add_cert(Crypt::OpenSSL3::X509::Store store, Crypt::OpenSSL3::X509 x)

bool X509_STORE_set_depth(Crypt::OpenSSL3::X509::Store store, int depth)

bool X509_STORE_set_flags(Crypt::OpenSSL3::X509::Store store, unsigned long flags)

bool X509_STORE_set_purpose(Crypt::OpenSSL3::X509::Store store, int purpose)

bool X509_STORE_set_trust(Crypt::OpenSSL3::X509::Store store, int trust)

bool X509_STORE_load_locations(Crypt::OpenSSL3::X509::Store store, const char *file, const char *dir)

bool X509_STORE_set_default_paths(Crypt::OpenSSL3::X509::Store store)

bool X509_STORE_load_file(Crypt::OpenSSL3::X509::Store xs, const char *file, const char *propq = NULL)
C_ARGS: xs, file, NULL, propq

bool X509_STORE_load_path(Crypt::OpenSSL3::X509::Store xs, const char *dir)

bool X509_STORE_load_store(Crypt::OpenSSL3::X509::Store xs, const char *uri, const char *propq = NULL)
C_ARGS: xs, uri, NULL, propq


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::X509::Request	PREFIX = X509_REQ_

Crypt::OpenSSL3::X509::Request X509_REQ_new(class, const char *propq = NULL)
C_ARGS: NULL, propq

Crypt::OpenSSL3::X509::Request X509_REQ_dup(Crypt::OpenSSL3::X509::Request req)

Crypt::OpenSSL3::X509::Request X509_REQ_read_pem(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL, NULL, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool X509_REQ_write_pem(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

Crypt::OpenSSL3::X509::Request X509_REQ_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool X509_REQ_write_der(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

int X509_REQ_get_attr_count(Crypt::OpenSSL3::X509::Request req)

int X509_REQ_get_attr_by_NID(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::NID nid, int lastpos)

int X509_REQ_get_attr_by_OBJ(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::ASN1::Object obj, int lastpos)

Crypt::OpenSSL3::X509::Attribute X509_REQ_get_attr(Crypt::OpenSSL3::X509::Request req, int loc)

Crypt::OpenSSL3::X509::Attribute X509_REQ_delete_attr(Crypt::OpenSSL3::X509::Request req, int loc)

int X509_REQ_add_attr(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::X509::Attribute attr)

int X509_REQ_add_attr_by_OBJ(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::ASN1::Object obj, int type, const unsigned char *bytes, int length(bytes))

int X509_REQ_add_attr_by_NID(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::NID nid, int type, const unsigned char *bytes, int len)

int X509_REQ_add_attr_by_txt(Crypt::OpenSSL3::X509::Request req, const char *attrname, int type, const unsigned char *bytes, int len)

bool X509_REQ_check_private_key(Crypt::OpenSSL3::X509::Request cert, Crypt::OpenSSL3::PKey pkey)

NO_OUTPUT Bool X509_REQ_digest(Crypt::OpenSSL3::X509::Request data, Crypt::OpenSSL3::MD type, OUTLIST SV* digest)
INIT:
	unsigned int output_length = EVP_MD_size(type);
	unsigned char* ptr = make_buffer(&digest, output_length);
C_ARGS: data, type, ptr, &output_length
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, output_length);

Crypt::OpenSSL3::ASN1::String X509_REQ_get_distinguishing_id(Crypt::OpenSSL3::X509::Request x)

void X509_REQ_set_distinguishing_id(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::ASN1::String distid)
INIT:
	distid = ASN1_OCTET_STRING_dup(distid);

Crypt::OpenSSL3::PKey X509_REQ_get_pubkey(Crypt::OpenSSL3::X509::Request x)

bool X509_REQ_set_pubkey(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::PKey pkey)


Crypt::OpenSSL3::X509::Name X509_REQ_get_subject_name(Crypt::OpenSSL3::X509::Request x)
POSTCALL:
	RETVAL = X509_NAME_dup(RETVAL);

bool X509_REQ_set_subject_name(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::X509::Name name)

void X509_REQ_set_signature(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::ASN1::String psig)

void X509_REQ_get_signature(Crypt::OpenSSL3::X509::Request req, OUTLIST Crypt::OpenSSL3::ASN1::String psig, OUTLIST Crypt::OpenSSL3::X509::Algorithm palg)
C_ARGS: req, (const ASN1_BIT_STRING**)&psig, (const X509_ALGOR**)&palg
POSTCALL:
	psig = ASN1_OCTET_STRING_dup(psig);
	palg = X509_ALGOR_dup(palg);
	
int X509_REQ_set_signature_algo(Crypt::OpenSSL3::X509::Request req, Crypt::OpenSSL3::X509::Algorithm palg)

Crypt::OpenSSL3::NID X509_REQ_get_signature_nid(Crypt::OpenSSL3::X509::Request req)

long X509_REQ_get_version(Crypt::OpenSSL3::X509::Request req)

int X509_REQ_set_version(Crypt::OpenSSL3::X509::Request x, long version)

int X509_REQ_verify(Crypt::OpenSSL3::X509::Request a, Crypt::OpenSSL3::PKey r, const char *propq = NULL)
C_ARGS: a, r, NULL, propq

int X509_REQ_sign(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::MD md)

int X509_REQ_sign_ctx(Crypt::OpenSSL3::X509::Request x, Crypt::OpenSSL3::MD::Context ctx)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::PKCS7	PREFIX = PKCS7_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::PKCS7", GV_ADD | GV_ADDMULTI);
	CONSTANT2(PKCS7_, TEXT);
	CONSTANT2(PKCS7_, BINARY);
	CONSTANT2(PKCS7_, NOCERTS);
	CONSTANT2(PKCS7_, DETACHED);
	CONSTANT2(PKCS7_, NOATTR);
	CONSTANT2(PKCS7_, NOSMIMECAP);
	CONSTANT2(PKCS7_, STREAM);
}

Crypt::OpenSSL3::PKCS7 PKCS7_new(class, const char* propq = NULL)
C_ARGS: NULL, propq

Crypt::OpenSSL3::PKCS7 PKCS7_read_pem(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL, NULL, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool PKCS7_write_pem(Crypt::OpenSSL3::PKCS7 x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

Crypt::OpenSSL3::PKCS7 PKCS7_read_der(class, Crypt::OpenSSL3::BIO bp)
C_ARGS: bp, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

int PKCS7_write_der(Crypt::OpenSSL3::PKCS7 p7, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, p7

bool PKCS7_add_certificate(Crypt::OpenSSL3::PKCS7 p7, Crypt::OpenSSL3::X509 cert)

Crypt::OpenSSL3::PKCS7 PKCS7_sign(class, Crypt::OpenSSL3::X509 signcert, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::X509::Stack certs, Crypt::OpenSSL3::BIO data, int flags, const char *propq = NULL)
C_ARGS: signcert, pkey, certs, data, flags, NULL, propq

bool PKCS7_verify(Crypt::OpenSSL3::PKCS7 p7, Crypt::OpenSSL3::X509::Stack certs, Crypt::OpenSSL3::X509::Store store, Crypt::OpenSSL3::BIO indata, Crypt::OpenSSL3::BIO out, int flags)

Crypt::OpenSSL3::X509::Stack PKCS7_get_signers(Crypt::OpenSSL3::PKCS7 p7, Crypt::OpenSSL3::X509::Stack certs, int flags)
POSTCALL:
	if (RETVAL)
		sk_X509_dup(RETVAL);

Crypt::OpenSSL3::PKCS7 PKCS7_encrypt(class, Crypt::OpenSSL3::X509::Stack certs, Crypt::OpenSSL3::BIO in, Crypt::OpenSSL3::Cipher cipher, int flags, const char* propq = NULL)
C_ARGS: certs, in, cipher, flags, NULL, propq

bool PKCS7_decrypt(Crypt::OpenSSL3::PKCS7 p7, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::X509 cert, Crypt::OpenSSL3::BIO data, int flags)

Crypt::OpenSSL3::ASN1::String PKCS7_get_octet_string(Crypt::OpenSSL3::PKCS7 p7);

bool PKCS7_type_is_signed(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_encrypted(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_enveloped(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_signedAndEnveloped(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_data(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_digest(Crypt::OpenSSL3::PKCS7 a)

bool PKCS7_type_is_other(Crypt::OpenSSL3::PKCS7 p7)



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::SSL::Method	PREFIX = SSL_Method_

Crypt::OpenSSL3::SSL::Method SSL_Method_TLS()

Crypt::OpenSSL3::SSL::Method SSL_Method_TLS_server()

Crypt::OpenSSL3::SSL::Method SSL_Method_TLS_client()

Crypt::OpenSSL3::SSL::Method SSL_Method_DTLS()

Crypt::OpenSSL3::SSL::Method SSL_Method_DTLS_server()

Crypt::OpenSSL3::SSL::Method SSL_Method_DTLS_client()

#if OPENSSL_VERSION_PREREQ(3, 2)
Crypt::OpenSSL3::SSL::Method SSL_Method_QUIC_client()

Crypt::OpenSSL3::SSL::Method SSL_Method_QUIC_client_thread()
#endif

#if OPENSSL_VERSION_PREREQ(3, 5)
Crypt::OpenSSL3::SSL::Method SSL_Method_QUIC_server()
#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::SSL::Context	PREFIX = SSL_CTX_

Crypt::OpenSSL3::SSL::Context SSL_CTX_new(classname, Crypt::OpenSSL3::SSL::Method method = TLS_method())
C_ARGS: method

long SSL_CTX_set_options(Crypt::OpenSSL3::SSL::Context ctx, long options)

long SSL_CTX_clear_options(Crypt::OpenSSL3::SSL::Context ctx, long options)

long SSL_CTX_get_options(Crypt::OpenSSL3::SSL::Context ctx)

void SSL_CTX_set_read_ahead(Crypt::OpenSSL3::SSL::Context ctx, bool yes)

bool SSL_CTX_get_read_ahead(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_session_id_context(Crypt::OpenSSL3::SSL::Context ctx, const unsigned char *sid_ctx, unsigned int length(sid_ctx))

long SSL_CTX_set_mode(Crypt::OpenSSL3::SSL::Context ctx, long mode)

long SSL_CTX_clear_mode(Crypt::OpenSSL3::SSL::Context ctx, long mode)

long SSL_CTX_get_mode(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_min_proto_version(Crypt::OpenSSL3::SSL::Context ctx, int version)

bool SSL_CTX_set_max_proto_version(Crypt::OpenSSL3::SSL::Context ctx, int version)

int SSL_CTX_get_min_proto_version(Crypt::OpenSSL3::SSL::Context ctx)

int SSL_CTX_get_max_proto_version(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_alpn_protos(Crypt::OpenSSL3::SSL::Context ctx, const unsigned char *protos, unsigned int length(protos))

Crypt::OpenSSL3::X509::Store SSL_CTX_get_cert_store(Crypt::OpenSSL3::SSL::Context ctx)
POSTCALL:
	X509_STORE_up_ref(RETVAL);

void SSL_CTX_set_cert_store(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::X509::Store store)
POSTCALL:
	X509_STORE_up_ref(store);

bool SSL_CTX_load_verify_locations(Crypt::OpenSSL3::SSL::Context ctx, const char *CAfile, const char *CApath)

bool SSL_CTX_load_verify_file(Crypt::OpenSSL3::SSL::Context ctx, const char *CAfile)

bool SSL_CTX_load_verify_dir(Crypt::OpenSSL3::SSL::Context ctx, const char *CApath)

bool SSL_CTX_load_verify_store(Crypt::OpenSSL3::SSL::Context ctx, const char *CAstore)

bool SSL_CTX_set_default_verify_paths(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_default_verify_dir(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_default_verify_file(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_use_certificate(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::X509 x)

bool SSL_CTX_use_certificate_ASN1(Crypt::OpenSSL3::SSL::Context ctx, int length(d), const unsigned char *d)

bool SSL_CTX_use_certificate_file(Crypt::OpenSSL3::SSL::Context ctx, const char *file, int type)

bool SSL_CTX_use_certificate_chain_file(Crypt::OpenSSL3::SSL::Context ctx, const char *file)

long SSL_CTX_add_extra_chain_cert(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::X509 x509)

long SSL_CTX_clear_extra_chain_certs(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_use_PrivateKey(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::PKey pkey)

bool SSL_CTX_use_PrivateKey_ASN1(Crypt::OpenSSL3::SSL::Context ctx, int pk, const unsigned char *d, long length(d))
C_ARGS: pk, ctx, d, XSauto_length_of_d

bool SSL_CTX_use_PrivateKey_file(Crypt::OpenSSL3::SSL::Context ctx, const char *file, int type)

bool SSL_CTX_check_private_key(Crypt::OpenSSL3::SSL::Context ctx)

void SSL_CTX_set_verify(Crypt::OpenSSL3::SSL::Context ctx, int mode)
C_ARGS: ctx, mode, NULL

void SSL_CTX_set_verify_depth(Crypt::OpenSSL3::SSL::Context ctx, int depth)

void SSL_CTX_set_post_handshake_auth(Crypt::OpenSSL3::SSL::Context ctx, int val)

bool SSL_CTX_set_cipher_list(Crypt::OpenSSL3::SSL::Context ctx, const char *str)

bool SSL_CTX_set_ciphersuites(Crypt::OpenSSL3::SSL::Context ctx, const char *str)

Crypt::OpenSSL3::X509::VerifyParam SSL_CTX_get_param(Crypt::OpenSSL3::SSL::Context ctx)

bool SSL_CTX_set_param(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::X509::VerifyParam vpm);

int SSL_CTX_add_client_CA(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::X509 cacert)
POSTCALL:
	X509_up_ref(cacert);

bool SSL_CTX_add_session(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::SSL::Session c);

bool SSL_CTX_remove_session(Crypt::OpenSSL3::SSL::Context ctx, Crypt::OpenSSL3::SSL::Session c);

long SSL_CTX_sess_number(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_connect(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_connect_good(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_connect_renegotiate(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_accept(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_accept_good(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_accept_renegotiate(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_hits(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_cb_hits(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_misses(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_timeouts(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_cache_full(Crypt::OpenSSL3::SSL::Context ctx)

long SSL_CTX_sess_set_cache_size(Crypt::OpenSSL3::SSL::Context ctx, long t)

long SSL_CTX_sess_get_cache_size(Crypt::OpenSSL3::SSL::Context ctx)

int SSL_CTX_set_num_tickets(Crypt::OpenSSL3::SSL::Context ctx, size_t num_tickets)

size_t SSL_CTX_get_num_tickets(Crypt::OpenSSL3::SSL::Context ctx)

#if OPENSSL_VERSION_PREREQ(3, 5)

bool SSL_CTX_set_domain_flags(Crypt::OpenSSL3::SSL::Context ctx, uint64_t flags)

NO_OUTPUT bool SSL_CTX_get_domain_flags(Crypt::OpenSSL3::SSL::Context ctx, OUTLIST uint64_t flags)
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;
#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::SSL	PREFIX = SSL_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::SSL", GV_ADD | GV_ADDMULTI);
	CONSTANT2(SSL_, ERROR_NONE);
	CONSTANT2(SSL_, ERROR_ZERO_RETURN);
	CONSTANT2(SSL_, ERROR_WANT_READ);
	CONSTANT2(SSL_, ERROR_WANT_WRITE);
	CONSTANT2(SSL_, ERROR_WANT_CONNECT);
	CONSTANT2(SSL_, ERROR_WANT_ACCEPT);
	CONSTANT2(SSL_, ERROR_WANT_X509_LOOKUP);
	CONSTANT2(SSL_, ERROR_WANT_ASYNC);
	CONSTANT2(SSL_, ERROR_WANT_ASYNC_JOB);
	CONSTANT2(SSL_, ERROR_SYSCALL);
	CONSTANT2(SSL_, ERROR_SSL);

	CONSTANT2(SSL_, VERIFY_NONE);
	CONSTANT2(SSL_, VERIFY_PEER);
	CONSTANT2(SSL_, VERIFY_FAIL_IF_NO_PEER_CERT);
	CONSTANT2(SSL_, VERIFY_CLIENT_ONCE);
	CONSTANT2(SSL_, VERIFY_POST_HANDSHAKE);

	CONSTANT2(SSL_, MODE_ENABLE_PARTIAL_WRITE);
	CONSTANT2(SSL_, MODE_ACCEPT_MOVING_WRITE_BUFFER);
	CONSTANT2(SSL_, MODE_AUTO_RETRY);
	CONSTANT2(SSL_, MODE_RELEASE_BUFFERS);
	CONSTANT2(SSL_, MODE_SEND_FALLBACK_SCSV);
	CONSTANT2(SSL_, MODE_ASYNC);

	CONSTANT2(SSL_, FILETYPE_PEM);
	CONSTANT2(SSL_, FILETYPE_ASN1);

	CONSTANT2(, TLS1_VERSION);
	CONSTANT2(, TLS1_1_VERSION);
	CONSTANT2(, TLS1_2_VERSION);
	CONSTANT2(, TLS1_3_VERSION);
	CONSTANT2(, DTLS1_VERSION);
	CONSTANT2(, DTLS1_2_VERSION);
#if OPENSSL_VERSION_PREREQ(3, 2)
	CONSTANT2(OSSL_, QUIC1_VERSION);
	CONSTANT2(SSL_, ACCEPT_STREAM_NO_BLOCK);
	CONSTANT2(SSL_, INCOMING_STREAM_POLICY_AUTO);
	CONSTANT2(SSL_, INCOMING_STREAM_POLICY_ACCEPT);
	CONSTANT2(SSL_, INCOMING_STREAM_POLICY_REJECT);
	CONSTANT2(SSL_, STREAM_FLAG_UNI);
	CONSTANT2(SSL_, STREAM_FLAG_NO_BLOCK);
	CONSTANT2(SSL_, STREAM_FLAG_ADVANCE);
	CONSTANT2(SSL_, STREAM_TYPE_NONE);
	CONSTANT2(SSL_, STREAM_TYPE_BIDI);
	CONSTANT2(SSL_, STREAM_TYPE_READ);
	CONSTANT2(SSL_, STREAM_TYPE_WRITE);
#endif
#if OPENSSL_VERSION_PREREQ(3, 5)
	CONSTANT2(SSL_, ACCEPT_CONNECTION_NO_BLOCK);
	CONSTANT2(SSL_, DOMAIN_FLAG_SINGLE_THREAD);
	CONSTANT2(SSL_, DOMAIN_FLAG_MULTI_THREAD);
	CONSTANT2(SSL_, DOMAIN_FLAG_THREAD_ASSISTED);
	CONSTANT2(SSL_, DOMAIN_FLAG_BLOCKING);
	CONSTANT2(SSL_, DOMAIN_FLAG_LEGACY_BLOCKING);
#endif
}

Crypt::OpenSSL3::SSL SSL_new(classname, Crypt::OpenSSL3::SSL::Context context)
C_ARGS: context

Crypt::OpenSSL3::SSL::Method SSL_get_ssl_method(Crypt::OpenSSL3::SSL ssl)

Crypt::OpenSSL3::SSL::Context SSL_get_context(Crypt::OpenSSL3::SSL ssl)
POSTCALL:
	SSL_CTX_up_ref(RETVAL);

NO_OUTPUT int SSL_get_event_timeout(Crypt::OpenSSL3::SSL s, OUTLIST struct timeval tv, OUTLIST Bool is_infinite)
INIT:
	is_infinite = 0;
POSTCALL:
	if (!RETVAL)
		XSRETURN_EMPTY;

bool SSL_handle_events(Crypt::OpenSSL3::SSL ssl)

long SSL_set_options(Crypt::OpenSSL3::SSL ssl, long options)

long SSL_clear_options(Crypt::OpenSSL3::SSL ssl, long options)

long SSL_get_options(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_session_id_context(Crypt::OpenSSL3::SSL ssl, const unsigned char *sid_ctx, unsigned int length(sid_ctx))

long SSL_set_mode(Crypt::OpenSSL3::SSL ssl, long mode)

long SSL_clear_mode(Crypt::OpenSSL3::SSL ssl, long mode)

long SSL_get_mode(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_min_proto_version(Crypt::OpenSSL3::SSL ssl, int version)

bool SSL_set_max_proto_version(Crypt::OpenSSL3::SSL ssl, int version)

int SSL_get_min_proto_version(Crypt::OpenSSL3::SSL ssl)

int SSL_get_max_proto_version(Crypt::OpenSSL3::SSL ssl)

void SSL_set_security_level(Crypt::OpenSSL3::SSL s, int level)

int SSL_get_security_level(Crypt::OpenSSL3::SSL s)

bool SSL_set_alpn_protos(Crypt::OpenSSL3::SSL ssl, ...)
CODE:
	SV* buffer = sv_2mortal(newSVpvs(""));
	static const char pattern[] = "(C/a)*";
	packlist(buffer, pattern, pattern + sizeof pattern - 1, &ST(1), &ST(items));
	STRLEN raw_len;
	const char* raw = SvPVbyte(buffer, raw_len);
	RETVAL = SSL_set_alpn_protos(ssl, (unsigned char*)raw, raw_len);
OUTPUT: RETVAL

bool SSL_use_certificate(Crypt::OpenSSL3::SSL ssl, Crypt::OpenSSL3::X509 x)

bool SSL_use_certificate_ASN1(Crypt::OpenSSL3::SSL ssl, const unsigned char *d, int length(d))

bool SSL_use_certificate_file(Crypt::OpenSSL3::SSL ssl, const char *file, int type)

bool SSL_use_certificate_chain_file(Crypt::OpenSSL3::SSL ssl, const char *file)

bool SSL_use_PrivateKey(Crypt::OpenSSL3::SSL ssl, Crypt::OpenSSL3::PKey pkey)

bool SSL_use_PrivateKey_ASN1(Crypt::OpenSSL3::SSL ssl, int pk, const unsigned char *d, long length(d))
C_ARGS: pk, ssl, d, XSauto_length_of_d

bool SSL_use_PrivateKey_file(Crypt::OpenSSL3::SSL ssl, const char *file, int type)

bool SSL_check_private_key(Crypt::OpenSSL3::SSL ssl)

void SSL_set_verify(Crypt::OpenSSL3::SSL ssl, int mode)
C_ARGS: ssl, mode, NULL

void SSL_set_verify_depth(Crypt::OpenSSL3::SSL ssl, int depth)

Crypt::OpenSSL3::X509::VerifyResult SSL_get_verify_result(Crypt::OpenSSL3::SSL ssl);

void SSL_set_post_handshake_auth(Crypt::OpenSSL3::SSL ssl, int val)

bool SSL_set_cipher_list(Crypt::OpenSSL3::SSL ssl, const char *str)

bool SSL_set_ciphersuites(Crypt::OpenSSL3::SSL ssl, const char *str)

const char *SSL_get_cipher_list(Crypt::OpenSSL3::SSL ssl, int priority)
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::X509::VerifyParam SSL_get_param(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_param(Crypt::OpenSSL3::SSL ssl, Crypt::OpenSSL3::X509::VerifyParam vpm);

int SSL_add_client_CA(Crypt::OpenSSL3::SSL ssl, Crypt::OpenSSL3::X509 cacert)
POSTCALL:
	X509_up_ref(cacert);

bool SSL_verify_client_post_handshake(Crypt::OpenSSL3::SSL ssl)

int SSL_get_error(Crypt::OpenSSL3::SSL ssl, int ret)

bool SSL_set_tlsext_host_name(Crypt::OpenSSL3::SSL s, const char *name)

const char* SSL_get_servername(Crypt::OpenSSL3::SSL s, int type)

int SSL_get_servername_type(Crypt::OpenSSL3::SSL s)

bool SSL_set_host(Crypt::OpenSSL3::SSL s, const char *hostname)

#if OPENSSL_VERSION_PREREQ(4, 0)
bool SSL_set_dnsname(Crypt::OpenSSL3::SSL s, const char *hostname)

bool SSL_set_ipaddr(Crypt::OpenSSL3::SSL s, const char *hostname)
#endif

int SSL_connect(Crypt::OpenSSL3::SSL ssl)

int SSL_accept(Crypt::OpenSSL3::SSL ssl)

int SSL_clear(Crypt::OpenSSL3::SSL ssl)

int SSL_do_handshake(Crypt::OpenSSL3::SSL ssl)

void SSL_set_connect_state(Crypt::OpenSSL3::SSL ssl)

void SSL_set_accept_state(Crypt::OpenSSL3::SSL ssl)

bool SSL_is_server(Crypt::OpenSSL3::SSL ssl)

int SSL_read(Crypt::OpenSSL3::SSL ssl, SV* buffer, size_t size)
INTERFACE: SSL_read SSL_peek
INIT:
	char* ptr = grow_buffer(buffer, size);
C_ARGS: ssl, ptr, size
POSTCALL:
	if (RETVAL > 0)
		set_buffer_length(buffer, RETVAL);

int SSL_write(Crypt::OpenSSL3::SSL ssl, const char* buf, int length(buf))

ssize_t SSL_sendfile(Crypt::OpenSSL3::SSL s, int fd, uint64_t offset, size_t size, int flags)

int SSL_shutdown(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_fd(Crypt::OpenSSL3::SSL ssl, int fd)

bool SSL_set_rfd(Crypt::OpenSSL3::SSL ssl, int fd)

bool SSL_set_wfd(Crypt::OpenSSL3::SSL ssl, int fd)

int SSL_get_fd(Crypt::OpenSSL3::SSL ssl)

int SSL_get_rfd(Crypt::OpenSSL3::SSL ssl)

int SSL_get_wfd(Crypt::OpenSSL3::SSL ssl)

void SSL_set_rbio(Crypt::OpenSSL3::SSL s, Crypt::OpenSSL3::BIO bio)
INTERFACE: SSL_set_rbio  SSL_set_wbio
INIT:
	BIO_up_ref(bio);

Crypt::OpenSSL3::BIO SSL_get_rbio(Crypt::OpenSSL3::SSL ssl)
INTERFACE: SSL_get_rbio  SSL_get_wbio
POSTCALL:
	if (RETVAL)
		BIO_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

void SSL_set_read_ahead(Crypt::OpenSSL3::SSL s, bool yes)

bool SSL_get_read_ahead(Crypt::OpenSSL3::SSL s)

Crypt::OpenSSL3::SSL::Session SSL_get_session(Crypt::OpenSSL3::SSL ssl)
POSTCALL:
	if (RETVAL)
		SSL_SESSION_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

bool SSL_set_session(Crypt::OpenSSL3::SSL ssl, Crypt::OpenSSL3::SSL::Session session)

bool SSL_session_reused(Crypt::OpenSSL3::SSL ssl)

Crypt::OpenSSL3::X509 SSL_get_certificate(Crypt::OpenSSL3::SSL ssl)
INTERFACE: SSL_get_certificate  SSL_get_peer_certificate
POSTCALL:
	if (RETVAL)
		X509_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::PKey SSL_get_privatekey(Crypt::OpenSSL3::SSL ssl)
POSTCALL:
	if (RETVAL)
		EVP_PKEY_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::SSL::Cipher SSL_get_current_cipher(Crypt::OpenSSL3::SSL ssl)
INTERFACE: SSL_get_current_cipher  SSL_get_pending_cipher
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

int SSL_client_version(Crypt::OpenSSL3::SSL s)

const char *SSL_get_version(Crypt::OpenSSL3::SSL ssl)

bool SSL_is_dtls(Crypt::OpenSSL3::SSL ssl)

bool SSL_is_tls(Crypt::OpenSSL3::SSL ssl)

bool SSL_is_quic(Crypt::OpenSSL3::SSL ssl)

bool SSL_in_init(Crypt::OpenSSL3::SSL s)

bool SSL_in_before(Crypt::OpenSSL3::SSL s)

bool SSL_is_init_finished(Crypt::OpenSSL3::SSL s)

bool SSL_in_connect_init(Crypt::OpenSSL3::SSL s)

bool SSL_in_accept_init(Crypt::OpenSSL3::SSL s)

int SSL_pending(Crypt::OpenSSL3::SSL ssl)

bool SSL_has_pending(Crypt::OpenSSL3::SSL s)

int SSL_version(Crypt::OpenSSL3::SSL s)

const char *SSL_state_string(Crypt::OpenSSL3::SSL ssl)

const char *SSL_state_string_long(Crypt::OpenSSL3::SSL ssl)

const char *SSL_rstate_string(Crypt::OpenSSL3::SSL ssl)

const char *SSL_rstate_string_long(Crypt::OpenSSL3::SSL ssl)

int SSL_set_num_tickets(Crypt::OpenSSL3::SSL s, size_t num_tickets)

size_t SSL_get_num_tickets(Crypt::OpenSSL3::SSL s)

bool SSL_new_session_ticket(Crypt::OpenSSL3::SSL s)

NO_OUTPUT size_t SSL_get_finished(Crypt::OpenSSL3::SSL ssl, OUTLIST SV* result)
	size_t max_size = EVP_MAX_MD_SIZE;
INTERFACE: SSL_get_finished SSL_get_peer_finished
INIT:
	unsigned char* ptr = make_buffer(&result, max_size);
C_ARGS: ssl, ptr, max_size
POSTCALL:
	if (RETVAL)
		set_buffer_length(result, RETVAL);

void SSL_get_alpn_selected(Crypt::OpenSSL3::SSL s, OUTLIST SV* result)
	const unsigned char* ptr = NULL;
	unsigned int len = 0;
C_ARGS: s, &ptr, &len
POSTCALL:
	result = newSVpvn((char*)ptr, len);

#if OPENSSL_VERSION_PREREQ(3, 2)

bool SSL_set_blocking_mode(Crypt::OpenSSL3::SSL s, int blocking)

Success SSL_get_blocking_mode(Crypt::OpenSSL3::SSL s)

Crypt::OpenSSL3::SSL SSL_new_stream(Crypt::OpenSSL3::SSL ssl, uint64_t flags)

bool SSL_set_incoming_stream_policy(Crypt::OpenSSL3::SSL conn, int policy, uint64_t app_error_code = 0)

Crypt::OpenSSL3::SSL SSL_accept_stream(Crypt::OpenSSL3::SSL ssl, uint64_t flags)

size_t SSL_get_accept_stream_queue_len(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_default_stream_mode(Crypt::OpenSSL3::SSL conn, unsigned mode)

bool SSL_stream_conclude(Crypt::OpenSSL3::SSL s, uint64_t flags)

bool SSL_stream_reset(Crypt::OpenSSL3::SSL ssl)
C_ARGS: ssl, NULL, 0

int SSL_get_rpoll_descriptor(Crypt::OpenSSL3::SSL s, Crypt::OpenSSL3::BIO::PollDescriptor desc)

int SSL_get_wpoll_descriptor(Crypt::OpenSSL3::SSL s, Crypt::OpenSSL3::BIO::PollDescriptor desc)

bool SSL_net_read_desired(Crypt::OpenSSL3::SSL s)

bool SSL_net_write_desired(Crypt::OpenSSL3::SSL s)

Crypt::OpenSSL3::SSL SSL_get_connection(Crypt::OpenSSL3::SSL ssl)
POSTCALL:
	SSL_up_ref(RETVAL);

bool SSL_is_connection(Crypt::OpenSSL3::SSL ssl)

uint64_t SSL_get_stream_id(Crypt::OpenSSL3::SSL ssl)
POSTCALL:
	if (RETVAL == UINT64_MAX)
		XSRETURN_UNDEF;

int SSL_get_stream_type(Crypt::OpenSSL3::SSL ssl)

Success SSL_is_stream_local(Crypt::OpenSSL3::SSL ssl)

bool SSL_set_initial_peer_addr(Crypt::OpenSSL3::SSL s, Crypt::OpenSSL3::BIO::Address addr)

#endif


#if OPENSSL_VERSION_PREREQ(3, 5)

Crypt::OpenSSL3::SSL SSL_new_listener(classname, Crypt::OpenSSL3::SSL::Context ctx, uint64_t flags)
C_ARGS: ctx, flags

Crypt::OpenSSL3::SSL SSL_new_listener_from(Crypt::OpenSSL3::SSL ssl, uint64_t flags)

bool SSL_is_listener(Crypt::OpenSSL3::SSL ssl)

Crypt::OpenSSL3::SSL SSL_get_listener(Crypt::OpenSSL3::SSL ssl)
INTERFACE: SSL_get_listener SSL_get_domain
POSTCALL:
	if (RETVAL)
		SSL_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

bool SSL_listen(Crypt::OpenSSL3::SSL ssl)

Crypt::OpenSSL3::SSL SSL_accept_connection(Crypt::OpenSSL3::SSL ssl, uint64_t flags)

size_t SSL_get_accept_connection_queue_len(Crypt::OpenSSL3::SSL ssl)

Crypt::OpenSSL3::SSL SSL_new_from_listener(Crypt::OpenSSL3::SSL ssl, uint64_t flags)

Crypt::OpenSSL3::SSL SSL_new_domain(Crypt::OpenSSL3::SSL::Context ctx, uint64_t flags)

bool SSL_is_domain(Crypt::OpenSSL3::SSL ssl)

NO_OUTPUT int SSL_get_domain_flags(Crypt::OpenSSL3::SSL ssl, OUTLIST uint64_t flags)
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::SSL::Cipher	PREFIX = SSL_CIPHER_

const char *SSL_CIPHER_get_name(Crypt::OpenSSL3::SSL::Cipher cipher)

const char *SSL_CIPHER_standard_name(Crypt::OpenSSL3::SSL::Cipher cipher)

NO_OUTPUT int SSL_CIPHER_get_bits(Crypt::OpenSSL3::SSL::Cipher cipher, OUTLIST int alg_bits)
POSTCALL:
	if (!RETVAL)
		alg_bits = 0;

const char *SSL_CIPHER_get_version(Crypt::OpenSSL3::SSL::Cipher cipher)

NO_OUTPUT char *SSL_CIPHER_description(Crypt::OpenSSL3::SSL::Cipher cipher, OUTLIST SV* description, int length = 128)
INIT:
	char* ptr = (char*)make_buffer(&description, length);
C_ARGS: cipher, ptr, length
POSTCALL:
	if (RETVAL)
		set_buffer_length(description, strlen(ptr));

Crypt::OpenSSL3::NID SSL_CIPHER_get_cipher_nid(Crypt::OpenSSL3::SSL::Cipher c)

Crypt::OpenSSL3::NID SSL_CIPHER_get_digest_nid(Crypt::OpenSSL3::SSL::Cipher c)

Crypt::OpenSSL3::MD SSL_CIPHER_get_handshake_digest(Crypt::OpenSSL3::SSL::Cipher c)
POSTCALL:
	if (RETVAL)
		EVP_MD_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

Crypt::OpenSSL3::NID SSL_CIPHER_get_kx_nid(Crypt::OpenSSL3::SSL::Cipher c)

Crypt::OpenSSL3::NID SSL_CIPHER_get_auth_nid(Crypt::OpenSSL3::SSL::Cipher c)

bool SSL_CIPHER_is_aead(Crypt::OpenSSL3::SSL::Cipher c)

unsigned SSL_CIPHER_get_id(Crypt::OpenSSL3::SSL::Cipher c)

unsigned SSL_CIPHER_get_protocol_id(Crypt::OpenSSL3::SSL::Cipher c)



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::SSL::Session	PREFIX = SSL_SESSION_

Crypt::OpenSSL3::SSL::Session SSL_SESSION_new(class)
C_ARGS:

Crypt::OpenSSL3::SSL::Session SSL_SESSION_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool SSL_SESSION_write_der(Crypt::OpenSSL3::SSL::Session x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

Crypt::OpenSSL3::SSL::Session SSL_SESSION_dup(Crypt::OpenSSL3::SSL::Session s)

long SSL_SESSION_get_timeout(Crypt::OpenSSL3::SSL::Session s)

long SSL_SESSION_set_timeout(Crypt::OpenSSL3::SSL::Session s, long t)

int SSL_SESSION_get_protocol_version(Crypt::OpenSSL3::SSL::Session s)

int SSL_SESSION_set_protocol_version(Crypt::OpenSSL3::SSL::Session s, int version)

time_t SSL_SESSION_get_time(Crypt::OpenSSL3::SSL::Session s)

time_t SSL_SESSION_set_time(Crypt::OpenSSL3::SSL::Session s, time_t t)

const char *SSL_SESSION_get_hostname(Crypt::OpenSSL3::SSL::Session s)

bool SSL_SESSION_set_hostname(Crypt::OpenSSL3::SSL::Session s, const char *hostname)

void SSL_SESSION_get_alpn_selected(Crypt::OpenSSL3::SSL::Session s, OUTLIST SV* result)
	const unsigned char* ptr = NULL;
	size_t len = 0;
C_ARGS: s, &ptr, &len
POSTCALL:
	result = newSVpvn((char*)ptr, len);

bool SSL_SESSION_set_alpn_selected(Crypt::OpenSSL3::SSL::Session s, const unsigned char *alpn, size_t length(alpn))

Crypt::OpenSSL3::SSL::Cipher SSL_SESSION_get_cipher(Crypt::OpenSSL3::SSL::Session s)

bool SSL_SESSION_set_cipher(Crypt::OpenSSL3::SSL::Session s, Crypt::OpenSSL3::SSL::Cipher cipher)

bool SSL_SESSION_has_ticket(Crypt::OpenSSL3::SSL::Session s)

unsigned long SSL_SESSION_get_ticket_lifetime_hint(Crypt::OpenSSL3::SSL::Session s)

void SSL_SESSION_get_ticket(Crypt::OpenSSL3::SSL::Session s, OUTLIST SV* result)
	const unsigned char* ptr = NULL;
	size_t len = 0;
C_ARGS: s, &ptr, &len
POSTCALL:
	result = newSVpvn((char*)ptr, len);

unsigned SSL_SESSION_get_max_early_data(Crypt::OpenSSL3::SSL::Session s)

bool SSL_SESSION_set_max_early_data(Crypt::OpenSSL3::SSL::Session s, unsigned max_early_data)

Crypt::OpenSSL3::X509 SSL_SESSION_get_peer(Crypt::OpenSSL3::SSL::Session session)
POSTCALL:
	if (RETVAL)
		X509_up_ref(RETVAL);
	else
		XSRETURN_UNDEF;

bool SSL_SESSION_set_id_context(Crypt::OpenSSL3::SSL::Session s, const unsigned char *sid_ctx, unsigned int length(sid_ctx))

bool SSL_SESSION_set_id(Crypt::OpenSSL3::SSL::Session s, const unsigned char *sid, unsigned int length(sid))

bool SSL_SESSION_is_resumable(Crypt::OpenSSL3::SSL::Session s)

NO_OUTPUT const unsigned char *SSL_SESSION_get_id(Crypt::OpenSSL3::SSL::Session s, OUTLIST SV* result)
INTERFACE: SSL_SESSION_get_id  SSL_SESSION_get_id_context
INIT:
	unsigned int len = 0;
C_ARGS: s, &len
POSTCALL:
	result = newSVpvn((char*)RETVAL, len);

unsigned int SSL_SESSION_get_compress_id(Crypt::OpenSSL3::SSL::Session s)

bool SSL_SESSION_print(Crypt::OpenSSL3::BIO fp, Crypt::OpenSSL3::SSL::Session ses)

bool SSL_SESSION_print_keylog(Crypt::OpenSSL3::BIO bp, Crypt::OpenSSL3::SSL::Session x)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::Request	PREFIX = TS_REQ_

Crypt::OpenSSL3::Timestamp::Request TS_REQ_new(class)
C_ARGS:

bool TS_REQ_set_version(Crypt::OpenSSL3::Timestamp::Request a, long version)

long TS_REQ_get_version(Crypt::OpenSSL3::Timestamp::Request a)

bool TS_REQ_set_msg_imprint(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::Timestamp::Imprint msg_imprint)

Crypt::OpenSSL3::Timestamp::Imprint TS_REQ_get_msg_imprint(Crypt::OpenSSL3::Timestamp::Request a)

bool TS_REQ_set_policy_id(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::ASN1::Object policy)

Crypt::OpenSSL3::ASN1::Object TS_REQ_get_policy_id(Crypt::OpenSSL3::Timestamp::Request a)

bool TS_REQ_set_nonce(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::ASN1::Integer nonce)

Crypt::OpenSSL3::ASN1::Integer TS_REQ_get_nonce(Crypt::OpenSSL3::Timestamp::Request a)

bool TS_REQ_set_cert_req(Crypt::OpenSSL3::Timestamp::Request a, int cert_req)

int TS_REQ_get_cert_req(Crypt::OpenSSL3::Timestamp::Request a)

# STACK_OF(X509_EXTENSION) *TS_REQ_get_exts(Crypt::OpenSSL3::Timestamp::Request a)

int TS_REQ_get_ext_count(Crypt::OpenSSL3::Timestamp::Request a)

int TS_REQ_get_ext_by_NID(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::NID nid, int lastpos)

int TS_REQ_get_ext_by_OBJ(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::ASN1::Object obj, int lastpos)

int TS_REQ_get_ext_by_critical(Crypt::OpenSSL3::Timestamp::Request a, int crit, int lastpos)

Crypt::OpenSSL3::X509::Extension TS_REQ_get_ext(Crypt::OpenSSL3::Timestamp::Request a, int loc)

Crypt::OpenSSL3::X509::Extension TS_REQ_delete_ext(Crypt::OpenSSL3::Timestamp::Request a, int loc)

bool TS_REQ_add_ext(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::X509::Extension ex, int loc)

PrintRet TS_REQ_print(Crypt::OpenSSL3::Timestamp::Request a, Crypt::OpenSSL3::BIO bio)

Crypt::OpenSSL3::Timestamp::Request TS_REQ_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool TS_REQ_write_der(Crypt::OpenSSL3::Timestamp::Request x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::Imprint	PREFIX = TS_MSG_IMPRINT_

Crypt::OpenSSL3::Timestamp::Imprint TS_MSG_IMPRINT_new(class)
C_ARGS:

bool TS_MSG_IMPRINT_set_algo(Crypt::OpenSSL3::Timestamp::Imprint a, Crypt::OpenSSL3::X509::Algorithm alg)

Crypt::OpenSSL3::X509::Algorithm TS_MSG_IMPRINT_get_algo(Crypt::OpenSSL3::Timestamp::Imprint a)

bool TS_MSG_IMPRINT_set_msg(Crypt::OpenSSL3::Timestamp::Imprint a, unsigned char *d, int length(d))

Crypt::OpenSSL3::ASN1::String TS_MSG_IMPRINT_get_msg(Crypt::OpenSSL3::Timestamp::Imprint a)

PrintRet TS_MSG_IMPRINT_print(Crypt::OpenSSL3::Timestamp::Imprint a, Crypt::OpenSSL3::BIO bio)

Crypt::OpenSSL3::Timestamp::Imprint TS_MSG_IMPRINT_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool TS_MSG_IMPRINT_write_der(Crypt::OpenSSL3::Timestamp::Imprint x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::TokenInfo	PREFIX = TS_TST_INFO_

Crypt::OpenSSL3::Timestamp::TokenInfo TS_TST_INFO_new(class)
C_ARGS:

bool TS_TST_INFO_set_version(Crypt::OpenSSL3::Timestamp::TokenInfo a, long version)

long TS_TST_INFO_get_version(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_policy_id(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::ASN1::Object policy_id)
C_ARGS: a, (ASN1_OBJECT*)policy_id

Crypt::OpenSSL3::ASN1::Object TS_TST_INFO_get_policy_id(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_msg_imprint(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::Timestamp::Imprint msg_imprint)

Crypt::OpenSSL3::Timestamp::Imprint TS_TST_INFO_get_msg_imprint(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_serial(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::ASN1::Integer serial)

Crypt::OpenSSL3::ASN1::Integer TS_TST_INFO_get_serial(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_time(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::ASN1::Time::Generalized gtime)

Crypt::OpenSSL3::ASN1::Time::Generalized TS_TST_INFO_get_time(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_accuracy(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::Timestamp::Accuracy accuracy)

Crypt::OpenSSL3::Timestamp::Accuracy TS_TST_INFO_get_accuracy(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_ordering(Crypt::OpenSSL3::Timestamp::TokenInfo a, int ordering)

int TS_TST_INFO_get_ordering(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_nonce(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::ASN1::Integer nonce)

Crypt::OpenSSL3::ASN1::Integer TS_TST_INFO_get_nonce(Crypt::OpenSSL3::Timestamp::TokenInfo a)

bool TS_TST_INFO_set_tsa(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::X509::GeneralName tsa)

Crypt::OpenSSL3::X509::GeneralName TS_TST_INFO_get_tsa(Crypt::OpenSSL3::Timestamp::TokenInfo a)

int TS_TST_INFO_get_ext_count(Crypt::OpenSSL3::Timestamp::TokenInfo a)

int TS_TST_INFO_get_ext_by_NID(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::NID nid, int lastpos)

int TS_TST_INFO_get_ext_by_OBJ(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::ASN1::Object obj, int lastpos)

int TS_TST_INFO_get_ext_by_critical(Crypt::OpenSSL3::Timestamp::TokenInfo a, int crit, int lastpos)

Crypt::OpenSSL3::X509::Extension TS_TST_INFO_get_ext(Crypt::OpenSSL3::Timestamp::TokenInfo a, int loc)

Crypt::OpenSSL3::X509::Extension TS_TST_INFO_delete_ext(Crypt::OpenSSL3::Timestamp::TokenInfo a, int loc)

bool TS_TST_INFO_add_ext(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::X509::Extension ex, int loc)

PrintRet TS_TST_INFO_print(Crypt::OpenSSL3::Timestamp::TokenInfo a, Crypt::OpenSSL3::BIO bio)

Crypt::OpenSSL3::Timestamp::TokenInfo TS_TST_INFO_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool TS_TST_INFO_write_der(Crypt::OpenSSL3::Timestamp::TokenInfo x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::Response	PREFIX = TS_RESP_

Crypt::OpenSSL3::Timestamp::Response TS_RESP_new(class)
C_ARGS:

bool TS_RESP_set_status_info(Crypt::OpenSSL3::Timestamp::Response a, Crypt::OpenSSL3::Timestamp::StatusInfo info)

Crypt::OpenSSL3::Timestamp::StatusInfo TS_RESP_get_status_info(Crypt::OpenSSL3::Timestamp::Response a)

Crypt::OpenSSL3::Timestamp::TokenInfo TS_RESP_get_tst_info(Crypt::OpenSSL3::Timestamp::Response a)

PrintRet TS_RESP_print(Crypt::OpenSSL3::Timestamp::Response a, Crypt::OpenSSL3::BIO bio)

Crypt::OpenSSL3::Timestamp::Response TS_RESP_read_der(class, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, NULL
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool TS_RESP_write_der(Crypt::OpenSSL3::Timestamp::Response x, Crypt::OpenSSL3::BIO bio)
C_ARGS: bio, x

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::StatusInfo	PREFIX = TS_STATUS_INFO_

Crypt::OpenSSL3::Timestamp::StatusInfo TS_STATUS_INFO_new(class)
C_ARGS:

bool TS_STATUS_INFO_set_status(Crypt::OpenSSL3::Timestamp::StatusInfo a, int i)

Crypt::OpenSSL3::ASN1::Integer TS_STATUS_INFO_get_status(Crypt::OpenSSL3::Timestamp::StatusInfo a)

Crypt::OpenSSL3::ASN1::String TS_STATUS_INFO_get_failure_info(Crypt::OpenSSL3::Timestamp::StatusInfo a)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::Accuracy	PREFIX = TS_ACCURACY_

Crypt::OpenSSL3::Timestamp::Accuracy TS_ACCURACY_new(class)
C_ARGS:

bool TS_ACCURACY_set_seconds(Crypt::OpenSSL3::Timestamp::Accuracy a, Crypt::OpenSSL3::ASN1::Integer seconds)

Crypt::OpenSSL3::ASN1::Integer TS_ACCURACY_get_seconds(Crypt::OpenSSL3::Timestamp::Accuracy a)

bool TS_ACCURACY_set_millis(Crypt::OpenSSL3::Timestamp::Accuracy a, Crypt::OpenSSL3::ASN1::Integer millis)

Crypt::OpenSSL3::ASN1::Integer TS_ACCURACY_get_millis(Crypt::OpenSSL3::Timestamp::Accuracy a)

bool TS_ACCURACY_set_micros(Crypt::OpenSSL3::Timestamp::Accuracy a, Crypt::OpenSSL3::ASN1::Integer micros)

Crypt::OpenSSL3::ASN1::Integer TS_ACCURACY_get_micros(Crypt::OpenSSL3::Timestamp::Accuracy a)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Timestamp::Verifier	PREFIX = TS_VERIFY_CTX_

BOOT:
{
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::Timestamp::Verifier", GV_ADD | GV_ADDMULTI);
	CONSTANT2(TS_, VFY_SIGNATURE);
	CONSTANT2(TS_, VFY_VERSION);
	CONSTANT2(TS_, VFY_POLICY);
	CONSTANT2(TS_, VFY_IMPRINT);
	CONSTANT2(TS_, VFY_DATA);
	CONSTANT2(TS_, VFY_NONCE);
	CONSTANT2(TS_, VFY_SIGNER);
	CONSTANT2(TS_, VFY_TSA_NAME);
	CONSTANT2(TS_, VFY_ALL_IMPRINT);
	CONSTANT2(TS_, VFY_ALL_DATA);
}

Crypt::OpenSSL3::Timestamp::Verifier TS_VERIFY_CTX_new()
POSTCALL:
	TS_VERIFY_CTX_init(RETVAL);

bool TS_VERIFY_CTX_init_from_request(Crypt::OpenSSL3::Timestamp::Verifier ctx, Crypt::OpenSSL3::Timestamp::Request req)

int TS_VERIFY_CTX_set_flags(Crypt::OpenSSL3::Timestamp::Verifier ctx, int f)

int TS_VERIFY_CTX_add_flags(Crypt::OpenSSL3::Timestamp::Verifier ctx, int f)

bool TS_VERIFY_CTX_set_data(Crypt::OpenSSL3::Timestamp::Verifier ctx, Crypt::OpenSSL3::BIO b)
POSTCALL:
	if (RETVAL)
		BIO_up_ref(b);

bool TS_VERIFY_CTX_set_imprint(Crypt::OpenSSL3::Timestamp::Verifier ctx, unsigned char *hexstr, long length(hexstr))
INIT:
	hexstr = OPENSSL_strndup(hexstr, XSauto_length_of_hexstr);

bool TS_VERIFY_CTX_set_store(Crypt::OpenSSL3::Timestamp::Verifier ctx, Crypt::OpenSSL3::X509::Store s)
POSTCALL:
	if (RETVAL)
		X509_STORE_up_ref(s);

bool TS_VERIFY_CTX_set_certs(Crypt::OpenSSL3::Timestamp::Verifier ctx, Crypt::OpenSSL3::X509::Stack certs)
INIT:
	certs = sk_X509_dup(certs);

bool TS_VERIFY_CTX_verify_response(Crypt::OpenSSL3::Timestamp::Verifier ctx, Crypt::OpenSSL3::Timestamp::Response response)

Bool CLONE_SKIP(...)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::NID PREFIX = NID_

Crypt::OpenSSL3::NID NID_create(class, const char *oid, const char *sn, const char *ln)
C_ARGS: oid, sn, ln
POSTCALL:
	if (RETVAL == NID_undef)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::NID NID_from_long_name(class, const char* name)
C_ARGS: name

Crypt::OpenSSL3::NID NID_from_short_name(class, const char* name)
C_ARGS: name

Crypt::OpenSSL3::NID NID_from_text(class, const char* name)
C_ARGS: name

const char *NID_get_long_name(Crypt::OpenSSL3::NID n)

const char *NID_get_short_name(Crypt::OpenSSL3::NID n)

Crypt::OpenSSL3::ASN1::Object NID_to_object(Crypt::OpenSSL3::NID n)

bool NID_eq(Crypt::OpenSSL3::NID left, Crypt::OpenSSL3::NID right)

int NID_raw(Crypt::OpenSSL3::NID n)

bool NID_is_undef(Crypt::OpenSSL3::NID n)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Random	PREFIX = EVP_RAND_

Crypt::OpenSSL3::Random EVP_RAND_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

bool EVP_RAND_is_a(Crypt::OpenSSL3::Random rand, const char *name)

const char *EVP_RAND_get_name(Crypt::OpenSSL3::Random rand)

const char *EVP_RAND_get_description(Crypt::OpenSSL3::Random rand)

void EVP_RAND_names_list_all(Crypt::OpenSSL3::Random rand)
PPCODE:
	PUTBACK;
	EVP_RAND_names_do_all(rand, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_RAND_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_RAND_do_all_provided(NULL, EVP_RAND_provided_callback, iTHX);
	SPAGAIN;

SV* EVP_RAND_get_param(Crypt::OpenSSL3::Random rand, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_RAND, rand, name)
OUTPUT: RETVAL

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Random	PREFIX = RAND_

NO_OUTPUT int RAND_bytes(classname, OUTLIST SV* buffer, int num)
INTERFACE: RAND_bytes  RAND_priv_bytes
INIT:
	unsigned char* ptr = make_buffer(&buffer, num);
C_ARGS: ptr, num
POSTCALL:
	if (RETVAL > 0)
		set_buffer_length(buffer, num);

Crypt::OpenSSL3::Random::Context RAND_get_primary(classname)
INTERFACE: RAND_get_primary  RAND_get_public  RAND_get_private
C_ARGS: NULL
POSTCALL:
	EVP_RAND_CTX_up_ref(RETVAL);

#if OPENSSL_VERSION_PREREQ(3, 2)
Bool RAND_set_public(classname, Crypt::OpenSSL3::Random::Context rand)
INTERFACE: RAND_set_public  RAND_set_private
C_ARGS: NULL, rand
POSTCALL:
	if (RETVAL)
		EVP_RAND_CTX_up_ref(rand);
#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Random::Context	PREFIX = EVP_RAND_CTX_

Crypt::OpenSSL3::Random::Context EVP_RAND_CTX_new(classname, Crypt::OpenSSL3::Random type, Crypt::OpenSSL3::Random::Context parent = NULL)
C_ARGS: type, parent

Crypt::OpenSSL3::Random EVP_RAND_CTX_get_rand(Crypt::OpenSSL3::Random::Context ctx)
POSTCALL:
	EVP_RAND_up_ref(RETVAL);

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Random::Context	PREFIX = EVP_RAND_

bool EVP_RAND_instantiate(Crypt::OpenSSL3::Random::Context ctx, unsigned int strength, int prediction_resistance, const unsigned char *pstr, size_t length(pstr), PARAMS(EVP_RAND_CTX) params = NULL)

bool EVP_RAND_uninstantiate(Crypt::OpenSSL3::Random::Context ctx)

NO_OUTPUT int EVP_RAND_generate(Crypt::OpenSSL3::Random::Context ctx, OUTLIST SV* buffer, size_t outlen, unsigned int strength, int prediction_resistance, const unsigned char *addin, size_t length(addin))
INIT:
	unsigned char* ptr = make_buffer(&buffer, outlen);
C_ARGS: ctx, ptr, outlen, strength, prediction_resistance, addin, XSauto_length_of_addin
POSTCALL:
	if (RETVAL)
		set_buffer_length(buffer, outlen);

int EVP_RAND_reseed(Crypt::OpenSSL3::Random::Context ctx, int prediction_resistance, const unsigned char *ent, size_t length(ent), const unsigned char *addin, size_t addin_len)

NO_OUTPUT int EVP_RAND_nonce(Crypt::OpenSSL3::Random::Context ctx, OUTLIST SV* buffer, size_t outlen)
INIT:
	unsigned char* ptr = make_buffer(&buffer, outlen);
C_ARGS: ctx, ptr, outlen
POSTCALL:
	set_buffer_length(buffer, RETVAL);

bool EVP_RAND_enable_locking(Crypt::OpenSSL3::Random::Context ctx)

bool EVP_RAND_verify_zeroization(Crypt::OpenSSL3::Random::Context ctx)

unsigned int EVP_RAND_get_strength(Crypt::OpenSSL3::Random::Context ctx)

int EVP_RAND_get_state(Crypt::OpenSSL3::Random::Context ctx)


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Cipher	PREFIX = EVP_CIPHER_

Crypt::OpenSSL3::Cipher EVP_CIPHER_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::NID EVP_CIPHER_get_nid(Crypt::OpenSSL3::Cipher e)

int EVP_CIPHER_get_block_size(Crypt::OpenSSL3::Cipher e)

int EVP_CIPHER_get_key_length(Crypt::OpenSSL3::Cipher e)

int EVP_CIPHER_get_iv_length(Crypt::OpenSSL3::Cipher e)

unsigned long EVP_CIPHER_get_mode(Crypt::OpenSSL3::Cipher e)

int EVP_CIPHER_get_type(Crypt::OpenSSL3::Cipher cipher)

bool EVP_CIPHER_is_a(Crypt::OpenSSL3::Cipher cipher, const char *name)

const char *EVP_CIPHER_get_name(Crypt::OpenSSL3::Cipher cipher)

const char *EVP_CIPHER_get_description(Crypt::OpenSSL3::Cipher cipher)

void EVP_CIPHER_names_list_all(Crypt::OpenSSL3::Cipher cipher)
PPCODE:
	PUTBACK;
	EVP_CIPHER_names_do_all(cipher, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_CIPHER_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_CIPHER_do_all_provided(NULL, EVP_CIPHER_provided_callback, iTHX);
	SPAGAIN;

SV* EVP_CIPHER_get_param(Crypt::OpenSSL3::Cipher cipher, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_CIPHER, cipher, name)
OUTPUT: RETVAL


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Cipher::Context	PREFIX = EVP_CIPHER_CTX_

Crypt::OpenSSL3::Cipher::Context EVP_CIPHER_CTX_new(classname)
C_ARGS:

Crypt::OpenSSL3::Cipher::Context EVP_CIPHER_CTX_dup(Crypt::OpenSSL3::Cipher::Context ctx)

bool EVP_CIPHER_CTX_copy(Crypt::OpenSSL3::Cipher::Context self, Crypt::OpenSSL3::Cipher::Context other)

bool EVP_CIPHER_CTX_reset(Crypt::OpenSSL3::Cipher::Context ctx)

bool EVP_CIPHER_CTX_init(Crypt::OpenSSL3::Cipher::Context ctx, Crypt::OpenSSL3::Cipher type, const unsigned char* key, int length(key), const unsigned char* iv, int length(iv), bool enc, CTX_PARAMS(EVP_CIPHER) params = NULL)
INIT:
	if (XSauto_length_of_key != EVP_CIPHER_get_key_length(type) || XSauto_length_of_iv != EVP_CIPHER_get_iv_length(type))
		XSRETURN_NO;
C_ARGS: ctx, type, key, iv, enc, params

NO_OUTPUT int EVP_CIPHER_CTX_update(Crypt::OpenSSL3::Cipher::Context ctx, const unsigned char* input, size_t length(input), OUTLIST SV* output)
INIT:
	int outl = XSauto_length_of_input + EVP_CIPHER_CTX_get_block_size(ctx);
	unsigned char* ptr = make_buffer(&output, outl);
C_ARGS: ctx, ptr, &outl, input, XSauto_length_of_input
POSTCALL:
	if (RETVAL)
		set_buffer_length(output, outl);

NO_OUTPUT int EVP_CIPHER_CTX_final(Crypt::OpenSSL3::Cipher::Context ctx, OUTLIST SV* output)
INIT:
	int size = EVP_CIPHER_CTX_get_block_size(ctx);
	unsigned char* ptr = make_buffer(&output, size);
C_ARGS: ctx, ptr, &size
POSTCALL:
	if (RETVAL)
		set_buffer_length(output, size);

bool EVP_CIPHER_CTX_set_params(Crypt::OpenSSL3::Cipher::Context ctx, PARAMS(EVP_CIPHER_CTX) params = NULL)

SV* EVP_CIPHER_CTX_get_param(Crypt::OpenSSL3::Cipher::Context ctx, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_CIPHER_CTX, ctx, name)
OUTPUT: RETVAL


Crypt::OpenSSL3::NID EVP_CIPHER_CTX_get_nid(Crypt::OpenSSL3::Cipher::Context e)

int EVP_CIPHER_CTX_get_block_size(Crypt::OpenSSL3::Cipher::Context e)

int EVP_CIPHER_CTX_get_key_length(Crypt::OpenSSL3::Cipher::Context e)

int EVP_CIPHER_CTX_get_iv_length(Crypt::OpenSSL3::Cipher::Context e)

unsigned long EVP_CIPHER_CTX_get_mode(Crypt::OpenSSL3::Cipher::Context e)

int EVP_CIPHER_CTX_type(Crypt::OpenSSL3::Cipher::Context ctx)

bool EVP_CIPHER_CTX_set_padding(Crypt::OpenSSL3::Cipher::Context ctx, int padding)

bool EVP_CIPHER_CTX_set_key_length(Crypt::OpenSSL3::Cipher::Context ctx, int keylen)

int EVP_CIPHER_CTX_ctrl(Crypt::OpenSSL3::Cipher::Context ctx, int cmd, int p1, char *p2)

NO_OUTPUT int EVP_CIPHER_CTX_rand_key(Crypt::OpenSSL3::Cipher::Context ctx, OUTLIST SV* key)
INIT:
	size_t size = EVP_CIPHER_CTX_key_length(ctx);
	unsigned char* ptr = make_buffer(&key, size);
C_ARGS: ctx, ptr
POSTCALL:
	if (RETVAL > 0)
		set_buffer_length(key, size);

Crypt::OpenSSL3::Cipher EVP_CIPHER_CTX_get_cipher(Crypt::OpenSSL3::Cipher::Context ctx)

const char *EVP_CIPHER_CTX_get_name(Crypt::OpenSSL3::Cipher::Context ctx)

bool EVP_CIPHER_CTX_is_encrypting(Crypt::OpenSSL3::Cipher::Context ctx)

bool EVP_CIPHER_CTX_set_aead_ivlen(Crypt::OpenSSL3::Cipher::Context ctx, int length)

NO_OUTPUT bool EVP_CIPHER_CTX_get_aead_tag(Crypt::OpenSSL3::Cipher::Context ctx, OUTLIST SV* tag)
INIT:
	int length = EVP_CIPHER_CTX_get_tag_length(ctx);
	unsigned char* ptr = make_buffer(&tag, length);
C_ARGS: ctx, ptr, length
POSTCALL:
	if (RETVAL)
		set_buffer_length(tag, length);

bool EVP_CIPHER_CTX_set_aead_tag(Crypt::OpenSSL3::Cipher::Context ctx, char* ptr, int length(ptr))

#if OPENSSL_VERSION_PREREQ(3, 4)
NO_OUTPUT int EVP_CIPHER_CTX_get_algor(Crypt::OpenSSL3::Cipher::Context ctx, OUTLIST Crypt::OpenSSL3::X509::Algorithm alg)
INIT:
	alg = NULL;
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;
#endif

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::MD	PREFIX = EVP_MD_

Crypt::OpenSSL3::MD EVP_MD_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

const char *EVP_MD_get_name(Crypt::OpenSSL3::MD md)

const char *EVP_MD_get_description(Crypt::OpenSSL3::MD md)

bool EVP_MD_is_a(Crypt::OpenSSL3::MD md, const char *name)

void EVP_MD_names_list_all(Crypt::OpenSSL3::MD md)
PPCODE:
	PUTBACK;
	EVP_MD_names_do_all(md, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_MD_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_MD_do_all_provided(NULL, EVP_MD_provided_callback, iTHX);
	SPAGAIN;

int EVP_MD_get_type(Crypt::OpenSSL3::MD md)

int EVP_MD_get_pkey_type(Crypt::OpenSSL3::MD md)

int EVP_MD_get_size(Crypt::OpenSSL3::MD md)

int EVP_MD_get_block_size(Crypt::OpenSSL3::MD md)

unsigned long EVP_MD_get_flags(Crypt::OpenSSL3::MD md)

#if OPENSSL_VERSION_PREREQ(3, 4)
bool EVP_MD_xof(Crypt::OpenSSL3::MD md)
#endif

SV* EVP_MD_get_param(Crypt::OpenSSL3::MD md, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_MD, md, name)
OUTPUT: RETVAL

NO_OUTPUT bool EVP_MD_digest(Crypt::OpenSSL3::MD md, const char* input, size_t length(input), OUTLIST SV* digest)
INIT:
	unsigned int size = EVP_MD_get_size(md);
	unsigned char* ptr = make_buffer(&digest, size);
C_ARGS: input, XSauto_length_of_input, ptr, &size, md, NULL
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, size);


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::MD::Context	PREFIX = EVP_MD_CTX_

Crypt::OpenSSL3::MD::Context EVP_MD_CTX_new(classname)
C_ARGS:

Crypt::OpenSSL3::MD::Context EVP_MD_CTX_dup(Crypt::OpenSSL3::MD::Context ctx)

bool EVP_MD_CTX_copy(Crypt::OpenSSL3::MD::Context self, Crypt::OpenSSL3::MD::Context other)

bool EVP_MD_CTX_reset(Crypt::OpenSSL3::MD::Context ctx)

bool EVP_MD_CTX_init(Crypt::OpenSSL3::MD::Context ctx, Crypt::OpenSSL3::MD type, CTX_PARAMS(EVP_MD) params = NULL)

bool EVP_MD_CTX_update(Crypt::OpenSSL3::MD::Context ctx, const char *d, size_t length(d))

NO_OUTPUT bool EVP_MD_CTX_final(Crypt::OpenSSL3::MD::Context ctx, OUTLIST SV* digest)
INIT:
	unsigned int size = EVP_MD_CTX_size(ctx);
	unsigned char* ptr = make_buffer(&digest , size);
C_ARGS: ctx, ptr, &size
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, size);

NO_OUTPUT bool EVP_MD_CTX_final_xof(Crypt::OpenSSL3::MD::Context ctx, OUTLIST SV* digest, size_t outlen)
INIT:
	unsigned char* ptr = make_buffer(&digest, outlen);
C_ARGS: ctx, ptr, outlen
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, outlen);

#if OPENSSL_VERSION_PREREQ(3, 3)
NO_OUTPUT bool EVP_MD_CTX_squeeze(Crypt::OpenSSL3::MD::Context ctx, OUTLIST SV* digest, size_t outlen)
INIT:
	unsigned char* ptr = make_buffer(&digest, outlen);
C_ARGS: ctx, ptr, outlen
POSTCALL:
	if (RETVAL)
		set_buffer_length(digest, outlen);
#endif

bool EVP_MD_CTX_sign_init(Crypt::OpenSSL3::MD::Context ctx, Crypt::OpenSSL3::MD type, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::PKey::Context pctx = NULL)
C_ARGS: ctx, pctx ? &pctx : NULL, type, NULL, pkey

bool EVP_MD_CTX_sign_init_ex(Crypt::OpenSSL3::MD::Context ctx, const char* mdname, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::PKey::Context pctx = NULL, const char* props = NULL)
C_ARGS: ctx, pctx ? &pctx : NULL, mdname, NULL, props, pkey, NULL

bool EVP_MD_CTX_sign_update(Crypt::OpenSSL3::MD::Context ctx, const char *d, size_t length(d))

SV* EVP_MD_CTX_sign_final(Crypt::OpenSSL3::MD::Context ctx)
CODE:
	size_t size = 0;
	if (EVP_DigestSignFinal(ctx, NULL, &size) == 1) {
		unsigned char* ptr = make_buffer(&RETVAL, size);
		if (EVP_DigestSignFinal(ctx, ptr, &size) == 1)
			set_buffer_length(RETVAL, size);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

SV* EVP_MD_CTX_sign(Crypt::OpenSSL3::MD::Context ctx, const unsigned char *tbs, size_t length(tbs))
CODE:
	size_t size = 0;
	if (EVP_DigestSign(ctx, NULL, &size, tbs, XSauto_length_of_tbs) == 1) {
		unsigned char* ptr = make_buffer(&RETVAL, size);
		if (EVP_DigestSign(ctx, ptr, &size, tbs, XSauto_length_of_tbs) == 1)
			set_buffer_length(RETVAL, size);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

bool EVP_MD_CTX_verify_init(Crypt::OpenSSL3::MD::Context ctx, Crypt::OpenSSL3::MD type, Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::PKey::Context pctx = NULL)
C_ARGS: ctx, pctx ? &pctx : NULL, type, NULL, pkey
	
bool EVP_MD_CTX_verify_update(Crypt::OpenSSL3::MD::Context ctx, const char *d, size_t length(d))

Success EVP_MD_CTX_verify_final(Crypt::OpenSSL3::MD::Context ctx, const unsigned char *sig, size_t length(sig))

Success EVP_MD_CTX_verify(Crypt::OpenSSL3::MD::Context ctx, const unsigned char *sig, size_t length(sig), const unsigned char *tbs, size_t length(tbs))

bool EVP_MD_CTX_set_params(Crypt::OpenSSL3::MD::Context ctx, PARAMS(EVP_MD_CTX) params = NULL)

SV* EVP_MD_CTX_get_param(Crypt::OpenSSL3::MD::Context ctx, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_MD_CTX, ctx, name)
OUTPUT: RETVAL


void EVP_MD_CTX_ctrl(Crypt::OpenSSL3::MD::Context ctx, int cmd, int p1, char* p2);

void EVP_MD_CTX_set_flags(Crypt::OpenSSL3::MD::Context ctx, int flags)

void EVP_MD_CTX_clear_flags(Crypt::OpenSSL3::MD::Context ctx, int flags)

int EVP_MD_CTX_test_flags(Crypt::OpenSSL3::MD::Context ctx, int flags)

Crypt::OpenSSL3::MD EVP_MD_CTX_get_md(Crypt::OpenSSL3::MD::Context ctx)

const char *EVP_MD_CTX_get_name(Crypt::OpenSSL3::MD::Context ctx)

int EVP_MD_CTX_get_size(Crypt::OpenSSL3::MD::Context ctx)

int EVP_MD_CTX_get_block_size(Crypt::OpenSSL3::MD::Context ctx)

int EVP_MD_CTX_get_type(Crypt::OpenSSL3::MD::Context ctx)



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::MAC	PREFIX = EVP_MAC_

Crypt::OpenSSL3::MAC EVP_MAC_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

const char *EVP_MAC_get_name(Crypt::OpenSSL3::MAC mac)

const char *EVP_MAC_get_description(Crypt::OpenSSL3::MAC mac)

bool EVP_MAC_is_a(Crypt::OpenSSL3::MAC mac, const char *name)

void EVP_MAC_names_list_all(Crypt::OpenSSL3::MAC mac)
PPCODE:
	PUTBACK;
	EVP_MAC_names_do_all(mac, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_MAC_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_MAC_do_all_provided(NULL, EVP_MAC_provided_callback, iTHX);
	SPAGAIN;

SV* EVP_MAC_get_param(Crypt::OpenSSL3::MAC mac, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_MAC, mac, name)
OUTPUT: RETVAL



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::MAC::Context	PREFIX = EVP_MAC_CTX_

Crypt::OpenSSL3::MAC::Context EVP_MAC_CTX_new(classname, Crypt::OpenSSL3::MAC ctx)
C_ARGS: ctx

Crypt::OpenSSL3::MAC::Context EVP_MAC_CTX_dup(Crypt::OpenSSL3::MAC::Context ctx)

Crypt::OpenSSL3::MAC EVP_MAC_CTX_get_mac(Crypt::OpenSSL3::MAC::Context ctx);
POSTCALL:
	EVP_MAC_up_ref(RETVAL);

size_t EVP_MAC_CTX_get_mac_size(Crypt::OpenSSL3::MAC::Context ctx)

size_t EVP_MAC_CTX_get_block_size(Crypt::OpenSSL3::MAC::Context ctx)

bool EVP_MAC_CTX_set_params(Crypt::OpenSSL3::MAC::Context ctx, PARAMS(EVP_MAC_CTX) params = NULL)

SV* EVP_MAC_CTX_get_param(Crypt::OpenSSL3::MAC::Context ctx, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_MAC_CTX, ctx, name)
OUTPUT: RETVAL



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::MAC::Context	PREFIX = EVP_MAC_

bool EVP_MAC_init(Crypt::OpenSSL3::MAC::Context ctx, const unsigned char *key, size_t length(key), PARAMS(EVP_MAC_CTX) params = NULL)

bool EVP_MAC_update(Crypt::OpenSSL3::MAC::Context ctx, const unsigned char *data, size_t length(data))

SV* EVP_MAC_final(Crypt::OpenSSL3::MAC::Context ctx)
CODE:
	size_t outsize;
	EVP_MAC_final(ctx, NULL, &outsize, 0);
	unsigned char* ptr = make_buffer(&RETVAL, outsize);
	int result = EVP_MAC_final(ctx, ptr, &outsize, outsize);
	if (result)
		set_buffer_length(RETVAL, outsize);
OUTPUT: RETVAL

NO_OUTPUT int EVP_MAC_finalXOF(Crypt::OpenSSL3::MAC::Context ctx, OUTLIST SV* code, size_t outsize)
INIT:
	unsigned char* ptr = make_buffer(&code, outsize);
C_ARGS: ctx, ptr, outsize
POSTCALL:
	if (RETVAL)
		set_buffer_length(code, outsize);



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::KDF	PREFIX = EVP_KDF_

Crypt::OpenSSL3::KDF EVP_KDF_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

const char *EVP_KDF_get_name(Crypt::OpenSSL3::KDF kdf)

const char *EVP_KDF_get_description(Crypt::OpenSSL3::KDF kdf)

bool EVP_KDF_is_a(Crypt::OpenSSL3::KDF kdf, const char *name)

void EVP_KDF_names_list_all(Crypt::OpenSSL3::KDF kdf)
PPCODE:
	PUTBACK;
	EVP_KDF_names_do_all(kdf, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_KDF_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_KDF_do_all_provided(NULL, EVP_KDF_provided_callback, iTHX);
	SPAGAIN;

SV* EVP_KDF_get_param(Crypt::OpenSSL3::KDF kdf, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_KDF, kdf, name)
OUTPUT: RETVAL


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::KDF::Context	PREFIX = EVP_KDF_CTX_

Crypt::OpenSSL3::KDF::Context EVP_KDF_CTX_new(classname, Crypt::OpenSSL3::KDF ctx)
C_ARGS: ctx

Crypt::OpenSSL3::KDF::Context EVP_KDF_CTX_dup(Crypt::OpenSSL3::KDF::Context ctx)

void EVP_KDF_CTX_reset(Crypt::OpenSSL3::KDF::Context ctx)

size_t EVP_KDF_CTX_get_kdf_size(Crypt::OpenSSL3::KDF::Context ctx)

bool EVP_KDF_CTX_set_params(Crypt::OpenSSL3::KDF::Context ctx, PARAMS(EVP_KDF_CTX) params = NULL)

SV* EVP_KDF_CTX_get_param(Crypt::OpenSSL3::KDF::Context ctx, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_KDF_CTX, ctx, name)
OUTPUT: RETVAL

Crypt::OpenSSL3::KDF EVP_KDF_CTX_kdf(Crypt::OpenSSL3::KDF::Context ctx)
POSTCALL:
	EVP_KDF_up_ref(RETVAL);


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::KDF::Context	PREFIX = EVP_KDF_

NO_OUTPUT bool EVP_KDF_derive(Crypt::OpenSSL3::KDF::Context ctx, OUTLIST SV* derived, size_t keylen, PARAMS(EVP_KDF_CTX) params)
INIT:
	unsigned char* ptr = make_buffer(&derived, keylen);
C_ARGS: ctx, ptr, keylen, params
POSTCALL:
	if (RETVAL)
		set_buffer_length(derived, keylen);



MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::Signature	PREFIX = EVP_SIGNATURE_

Crypt::OpenSSL3::Signature EVP_SIGNATURE_fetch(classname, const char* algorithm, const char* properties = "")
C_ARGS: NULL, algorithm, properties
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

const char *EVP_SIGNATURE_get_name(Crypt::OpenSSL3::Signature signature)

const char *EVP_SIGNATURE_get_description(Crypt::OpenSSL3::Signature signature)

bool EVP_SIGNATURE_is_a(Crypt::OpenSSL3::Signature signature, const char *name)

void EVP_SIGNATURE_names_list_all(Crypt::OpenSSL3::Signature signature)
PPCODE:
	PUTBACK;
	EVP_SIGNATURE_names_do_all(signature, EVP_name_callback, iTHX);
	SPAGAIN;

void EVP_SIGNATURE_list_all_provided(classname)
PPCODE:
	PUTBACK;
	EVP_SIGNATURE_do_all_provided(NULL, EVP_SIGNATURE_provided_callback, iTHX);
	SPAGAIN;


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::PKey	PREFIX = EVP_PKEY_

Crypt::OpenSSL3::PKey EVP_PKEY_new(classname)
C_ARGS:

Crypt::OpenSSL3::PKey EVP_PKEY_new_raw_private_key(classname, const char *keytype, const unsigned char *key, size_t length(key), const char *propq = "")
C_ARGS: NULL, keytype, propq, key, XSauto_length_of_key
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::PKey EVP_PKEY_new_raw_public_key(classname, const char *keytype, const unsigned char *key, size_t length(key), const char *propq = "")
C_ARGS: NULL, keytype, propq, key, XSauto_length_of_key
POSTCALL:
	if (RETVAL == NULL)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::PKey EVP_PKEY_dup(Crypt::OpenSSL3::PKey ctx)

bool EVP_PKEY_eq(Crypt::OpenSSL3::PKey a, Crypt::OpenSSL3::PKey b)

bool EVP_PKEY_parameters_eq(Crypt::OpenSSL3::PKey a, Crypt::OpenSSL3::PKey b)

NO_OUTPUT void EVP_PKEY_get_raw_private_key(Crypt::OpenSSL3::PKey pkey, OUTLIST SV* key)
CODE:
	size_t length;
	int result = EVP_PKEY_get_raw_private_key(pkey, NULL, &length);
	if (!result)
		XSRETURN_UNDEF;
	unsigned char* ptr = make_buffer(&key, length);
	result = EVP_PKEY_get_raw_private_key(pkey, ptr, &length);
	if (result)
		set_buffer_length(key, length);


NO_OUTPUT void EVP_PKEY_get_raw_public_key(Crypt::OpenSSL3::PKey pkey, OUTLIST SV* key)
CODE:
	size_t length;
	int result = EVP_PKEY_get_raw_public_key(pkey, NULL, &length);
	if (!result)
		XSRETURN_UNDEF;
	unsigned char* ptr = make_buffer(&key, length);
	result = EVP_PKEY_get_raw_public_key(pkey, ptr, &length);
	if (result)
		set_buffer_length(key, length);

Crypt::OpenSSL3::PKey EVP_PKEY_read_pem_private_key(Crypt::OpenSSL3::BIO bio, SV* password_cb = undef, const char* propq = "")
C_ARGS: bio, NULL, NULL, NULL, NULL, propq
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool EVP_PKEY_write_pem_private_key(Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::BIO bio, SV* cipher_sv = undef, SV* key = undef, const char* propq = "")
INIT:
	const EVP_CIPHER* cipher = SvOK(cipher_sv) ? get_EVP_CIPHER(aTHX_ cipher_sv) : NULL;
	STRLEN klen = 0;
	const unsigned char* kstr = NULL;
	if (SvOK(key))
		kstr = (unsigned char*)SvPV(key, klen);
C_ARGS: bio, pkey, cipher, kstr, klen, NULL, NULL, NULL, propq

Crypt::OpenSSL3::PKey EVP_PKEY_read_pem_public_key(Crypt::OpenSSL3::BIO bio, const char* propq = "")
C_ARGS: bio, NULL, NULL, NULL, NULL, propq
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool EVP_PKEY_write_pem_public_key(Crypt::OpenSSL3::PKey pkey, Crypt::OpenSSL3::BIO bio, const char* propq = "")
C_ARGS: bio, pkey, NULL, propq

Crypt::OpenSSL3::PKey EVP_PKEY_read_der_public_key(Crypt::OpenSSL3::BIO bio, const char* propq = NULL)
C_ARGS: bio, NULL, NULL, propq
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::PKey EVP_PKEY_read_der_private_key(Crypt::OpenSSL3::BIO bio, const char* propq = NULL)
C_ARGS: bio, NULL, NULL, propq
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool EVP_PKEY_write_der_public_key(Crypt::OpenSSL3::PKey a, Crypt::OpenSSL3::BIO bio)
INTERFACE: EVP_PKEY_write_der_public_key EVP_PKEY_write_der_private_key
C_ARGS: bio, a

Crypt::OpenSSL3::NID EVP_PKEY_get_id(Crypt::OpenSSL3::PKey pkey)
POSTCALL:
	if (RETVAL == -1)
		XSRETURN_UNDEF;

Crypt::OpenSSL3::NID EVP_PKEY_get_base_id(Crypt::OpenSSL3::PKey pkey)

int EVP_PKEY_type(int type)

bool EVP_PKEY_set_type(Crypt::OpenSSL3::PKey pkey, int type)

bool EVP_PKEY_set_type_str(Crypt::OpenSSL3::PKey pkey, const char *str, int length(str))

int EVP_PKEY_get_size(Crypt::OpenSSL3::PKey pkey)

int EVP_PKEY_get_bits(Crypt::OpenSSL3::PKey pkey)

int EVP_PKEY_get_security_bits(Crypt::OpenSSL3::PKey pkey)

bool EVP_PKEY_is_a(Crypt::OpenSSL3::PKey pkey, const char *name)

bool EVP_PKEY_can_sign(Crypt::OpenSSL3::PKey pkey)

void EVP_PKEY_type_names_list_all(Crypt::OpenSSL3::PKey pkey)
PPCODE:
	PUTBACK;
	EVP_PKEY_type_names_do_all(pkey, EVP_name_callback, iTHX);
	SPAGAIN;

const char *EVP_PKEY_get_type_name(Crypt::OpenSSL3::PKey key)

const char *EVP_PKEY_get_description(Crypt::OpenSSL3::PKey key)

Success EVP_PKEY_digestsign_supports_digest(Crypt::OpenSSL3::PKey pkey, const char *name, const char *propq)
C_ARGS: pkey, NULL, name, propq

NO_OUTPUT int EVP_PKEY_get_default_digest_name(Crypt::OpenSSL3::PKey pkey, OUTLIST SV* mdname)
INIT:
	char* ptr = (char*)make_buffer(&mdname, 32);
C_ARGS: pkey, ptr, 32
POSTCALL:
	if (RETVAL > 0)
		set_buffer_length(mdname, strlen(SvPV_nolen(mdname)));

NO_OUTPUT int EVP_PKEY_get_default_digest_nid(Crypt::OpenSSL3::PKey pkey, OUTLIST Crypt::OpenSSL3::NID pnid)
POSTCALL:
	if (RETVAL <= 0)
		XSRETURN_UNDEF;

int EVP_PKEY_get_field_type(Crypt::OpenSSL3::PKey pkey)

int EVP_PKEY_get_ec_point_conv_form(Crypt::OpenSSL3::PKey pkey)

NO_OUTPUT int EVP_PKEY_get_group_name(Crypt::OpenSSL3::PKey pkey, OUTLIST SV* name, size_t size = 32)
INIT:
	char* ptr = (char*)make_buffer(&name, size);
C_ARGS: pkey, ptr, size + 1, &size
POSTCALL:
	if (RETVAL)
		set_buffer_length(name, size);

bool EVP_PKEY_set_encoded_public_key(Crypt::OpenSSL3::PKey pkey, const unsigned char *pub, size_t length(pub))

NO_OUTPUT size_t EVP_PKEY_get_encoded_public_key(Crypt::OpenSSL3::PKey pkey, OUTLIST SV* result)
INIT:
	unsigned char* ptr = NULL;
C_ARGS: pkey, &ptr
POSTCALL:
	result = RETVAL > 0 ? newSVpvn((char*)ptr, RETVAL) : &PL_sv_undef;
	OPENSSL_free(ptr);

SV* EVP_PKEY_get_param(Crypt::OpenSSL3::PKey pkey, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_PKEY, pkey, name)
OUTPUT: RETVAL

bool EVP_PKEY_get_int_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, OUT int out)

bool EVP_PKEY_get_size_t_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, OUT size_t out)

bool EVP_PKEY_get_bn_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, OUT Crypt::OpenSSL3::BigNum bn)

bool EVP_PKEY_get_utf8_string_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, char *str, size_t length(str), OUT size_t out_len)

bool EVP_PKEY_get_octet_string_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, unsigned char *buf, size_t length(buf), OUT size_t out_len)

bool EVP_PKEY_set_params(Crypt::OpenSSL3::PKey ctx, PARAMS(EVP_PKEY) params = NULL)

bool EVP_PKEY_set_int_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, int in)

bool EVP_PKEY_set_size_t_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, size_t in)

bool EVP_PKEY_set_bn_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, Crypt::OpenSSL3::BigNum bn)

bool EVP_PKEY_set_utf8_string_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, const char *str)

bool EVP_PKEY_set_octet_string_param(Crypt::OpenSSL3::PKey pkey, const char *key_name, const unsigned char *buf, size_t length(buf))

Success EVP_PKEY_print_public(Crypt::OpenSSL3::BIO out, Crypt::OpenSSL3::PKey pkey, int indent)
C_ARGS: out, pkey, indent, NULL

Success EVP_PKEY_print_private(Crypt::OpenSSL3::BIO out, Crypt::OpenSSL3::PKey pkey, int indent)
C_ARGS: out, pkey, indent, NULL

Success EVP_PKEY_print_params(Crypt::OpenSSL3::BIO out, Crypt::OpenSSL3::PKey pkey, int indent)
C_ARGS: out, pkey, indent, NULL

MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::PKey::Context	PREFIX = EVP_PKEY_CTX_


Crypt::OpenSSL3::PKey::Context EVP_PKEY_CTX_new(classname, Crypt::OpenSSL3::PKey pkey)
C_ARGS: pkey, NULL

Crypt::OpenSSL3::PKey::Context EVP_PKEY_CTX_new_id(classname, Crypt::OpenSSL3::NID id)
C_ARGS: id, NULL

Crypt::OpenSSL3::PKey::Context EVP_PKEY_CTX_new_from_name(classname, const char *name, const char *propquery = "")
C_ARGS: NULL, name, propquery

Crypt::OpenSSL3::PKey::Context EVP_PKEY_CTX_new_from_pkey(classname, Crypt::OpenSSL3::PKey pkey, const char *propquery = "")
C_ARGS: NULL, pkey, propquery

Crypt::OpenSSL3::PKey::Context EVP_PKEY_CTX_dup(Crypt::OpenSSL3::PKey::Context ctx)

bool EVP_PKEY_CTX_set_params(Crypt::OpenSSL3::PKey::Context ctx, PARAMS(EVP_PKEY_CTX) params = NULL)

SV* EVP_PKEY_CTX_get_param(Crypt::OpenSSL3::PKey::Context ctx, const char* name)
CODE:
	GENERATE_GET_PARAM(EVP_PKEY_CTX, ctx, name)
OUTPUT: RETVAL

bool EVP_PKEY_CTX_is_a(Crypt::OpenSSL3::PKey::Context ctx, const char *keytype)

#if OPENSSL_VERSION_PREREQ(3, 4)
NO_OUTPUT int EVP_PKEY_CTX_get_algor(Crypt::OpenSSL3::PKey::Context ctx, OUTLIST Crypt::OpenSSL3::X509::Algorithm alg)
INIT:
	alg = NULL;
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;
#endif

#if OPENSSL_VERSION_PREREQ(3, 4)
bool EVP_PKEY_CTX_set_signature(Crypt::OpenSSL3::PKey::Context pctx, const unsigned char *sig, size_t length(sig))
#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::PKey::Context	PREFIX = EVP_PKEY_

Success EVP_PKEY_keygen_init(Crypt::OpenSSL3::PKey::Context ctx)

Success EVP_PKEY_paramgen_init(Crypt::OpenSSL3::PKey::Context ctx)

NO_OUTPUT int EVP_PKEY_generate(Crypt::OpenSSL3::PKey::Context ctx, OUTLIST Crypt::OpenSSL3::PKey ppkey)
INIT:
	ppkey = NULL;
POSTCALL:
	if (RETVAL <= 0)
		XSRETURN_UNDEF;

Success EVP_PKEY_encapsulate_init(Crypt::OpenSSL3::PKey::Context ctx)
C_ARGS: ctx, NULL

void EVP_PKEY_encapsulate(Crypt::OpenSSL3::PKey::Context ctx, OUTLIST SV* wrapped_key, OUTLIST SV* gen_key)
CODE:
	size_t wrapped_length, gen_length;
	if (EVP_PKEY_encapsulate(ctx, NULL, &wrapped_length, NULL, &gen_length) != 1)
		XSRETURN_EMPTY;

	unsigned char* wrapped_ptr = make_buffer(&wrapped_key, wrapped_length);
	unsigned char* gen_ptr = make_buffer(&gen_key, gen_length);

	if (EVP_PKEY_encapsulate(ctx, wrapped_ptr, &wrapped_length, gen_ptr, &gen_length)) {
		set_buffer_length(wrapped_key, wrapped_length);
		set_buffer_length(gen_key, gen_length);
	} else
		XSRETURN_EMPTY;

Success EVP_PKEY_decapsulate_init(Crypt::OpenSSL3::PKey::Context ctx)
C_ARGS: ctx, NULL

SV* EVP_PKEY_decapsulate(Crypt::OpenSSL3::PKey::Context ctx, const unsigned char *wrapped, size_t length(wrapped))
CODE:
	size_t unwrapped_length;
	int result = EVP_PKEY_decapsulate(ctx, NULL, &unwrapped_length, wrapped, XSauto_length_of_wrapped);
	if (result == 1) {
		unsigned char* unwrapped_ptr = make_buffer(&RETVAL, unwrapped_length);

		if (EVP_PKEY_decapsulate(ctx, unwrapped_ptr, &unwrapped_length, wrapped, XSauto_length_of_wrapped) == 1)
			set_buffer_length(RETVAL, unwrapped_length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

#if OPENSSL_VERSION_PREREQ(3, 2)
Success EVP_PKEY_auth_encapsulate_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::PKey authpriv)
C_ARGS: ctx, authpriv, NULL

Success EVP_PKEY_auth_decapsulate_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::PKey authpub)
C_ARGS: ctx, authpub, NULL
#endif

Success EVP_PKEY_encrypt_init(Crypt::OpenSSL3::PKey::Context ctx)
C_ARGS: ctx, NULL

SV* EVP_PKEY_encrypt(Crypt::OpenSSL3::PKey::Context ctx, const unsigned char *in, size_t length(in))
CODE:
	size_t out_length;
	bool result = EVP_PKEY_encrypt(ctx, NULL, &out_length, in, XSauto_length_of_in);
	if (result == 1) {
		unsigned char* out_ptr = make_buffer(&RETVAL, out_length);

		result = EVP_PKEY_encrypt(ctx, out_ptr, &out_length, in, XSauto_length_of_in);
		if (result == 1)
			set_buffer_length(RETVAL, out_length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

bool EVP_PKEY_decrypt_init(Crypt::OpenSSL3::PKey::Context ctx)
C_ARGS: ctx, NULL

SV* EVP_PKEY_decrypt(Crypt::OpenSSL3::PKey::Context ctx, const unsigned char *in, size_t length(in))
CODE:
	size_t out_length;
	if (EVP_PKEY_decrypt(ctx, NULL, &out_length, in, XSauto_length_of_in) == 1) {
		unsigned char* out_ptr = make_buffer(&RETVAL, out_length);

		if (EVP_PKEY_decrypt(ctx, out_ptr, &out_length, in, XSauto_length_of_in) == 1)
			set_buffer_length(RETVAL, out_length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

bool EVP_PKEY_derive_init(Crypt::OpenSSL3::PKey::Context ctx)
C_ARGS: ctx, NULL

bool EVP_PKEY_derive_set_peer(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::PKey peer, bool validate_peer = false)

SV* EVP_PKEY_derive(Crypt::OpenSSL3::PKey::Context ctx)
CODE:
	size_t key_length;
	if (EVP_PKEY_derive(ctx, NULL, &key_length) == 1) {
		unsigned char* key_ptr = make_buffer(&RETVAL, key_length);

		if (EVP_PKEY_derive(ctx, key_ptr, &key_length) == 1)
			set_buffer_length(RETVAL, key_length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

Success EVP_PKEY_sign_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::Signature type = NULL, CTX_PARAMS(EVP_SIGNATURE) params = NULL)

SV* EVP_PKEY_sign(Crypt::OpenSSL3::PKey::Context ctx, const unsigned char *tbs, size_t length(tbs))
CODE:
	size_t sig_length;
	if (EVP_PKEY_sign(ctx, NULL, &sig_length, tbs, XSauto_length_of_tbs) == 1) {
		unsigned char* sig_ptr = make_buffer(&RETVAL, sig_length);

		if (EVP_PKEY_sign(ctx, sig_ptr, &sig_length, tbs, XSauto_length_of_tbs) == 1)
			set_buffer_length(RETVAL, sig_length);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

Success EVP_PKEY_verify_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::Signature type = NULL, CTX_PARAMS(EVP_SIGNATURE) params = NULL)

Success EVP_PKEY_verify(Crypt::OpenSSL3::PKey::Context ctx, const unsigned char *sig, size_t length(sig), const unsigned char *tbs, size_t length(tbs))

#if OPENSSL_VERSION_PREREQ(3, 4)
Success EVP_PKEY_sign_message_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::Signature type = NULL, CTX_PARAMS(EVP_SIGNATURE) params = NULL)

Success EVP_PKEY_sign_message_update(Crypt::OpenSSL3::PKey::Context ctx, unsigned char *in, size_t length(in))

SV* EVP_PKEY_sign_message_final(Crypt::OpenSSL3::PKey::Context ctx)
CODE:
	size_t sigsize;
	if (EVP_PKEY_sign_message_final(ctx, NULL, &sigsize) == 1) {
		unsigned char* ptr = make_buffer(&RETVAL, sigsize);
		if (EVP_PKEY_sign_message_final(ctx, ptr, &sigsize) == 1)
			set_buffer_length(RETVAL, sigsize);
	} else
		RETVAL = &PL_sv_undef;
OUTPUT: RETVAL

Success EVP_PKEY_verify_message_init(Crypt::OpenSSL3::PKey::Context ctx, Crypt::OpenSSL3::Signature type = NULL, CTX_PARAMS(EVP_SIGNATURE) params = NULL)

Success EVP_PKEY_verify_message_update(Crypt::OpenSSL3::PKey::Context ctx, unsigned char *in, size_t length(in))

Success EVP_PKEY_verify_message_final(Crypt::OpenSSL3::PKey::Context ctx)

#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::HPKE	PREFIX = OSSL_HPKE_


BOOT:
{
#if OPENSSL_VERSION_PREREQ(3, 2)
	HV* stash = gv_stashpvs("Crypt::OpenSSL3::HPKE", GV_ADD | GV_ADDMULTI);
	CONSTANT2(OSSL_HPKE_, KEM_ID_P256);
	CONSTANT2(OSSL_HPKE_, KEM_ID_P384);
	CONSTANT2(OSSL_HPKE_, KEM_ID_P521);
	CONSTANT2(OSSL_HPKE_, KEM_ID_X25519);
	CONSTANT2(OSSL_HPKE_, KEM_ID_X448);

	CONSTANT2(OSSL_HPKE_, KDF_ID_HKDF_SHA256);
	CONSTANT2(OSSL_HPKE_, KDF_ID_HKDF_SHA384);
	CONSTANT2(OSSL_HPKE_, KDF_ID_HKDF_SHA512);

	CONSTANT2(OSSL_HPKE_, AEAD_ID_AES_GCM_128);
	CONSTANT2(OSSL_HPKE_, AEAD_ID_AES_GCM_256);
	CONSTANT2(OSSL_HPKE_, AEAD_ID_CHACHA_POLY1305);
	CONSTANT2(OSSL_HPKE_, AEAD_ID_EXPORTONLY);

	CONSTANT2(OSSL_HPKE_, ROLE_SENDER);
	CONSTANT2(OSSL_HPKE_, ROLE_RECEIVER);

	CONSTANT2(OSSL_HPKE_, MODE_BASE);
	CONSTANT2(OSSL_HPKE_, MODE_PSK);
	CONSTANT2(OSSL_HPKE_, MODE_AUTH);
	CONSTANT2(OSSL_HPKE_, MODE_PSKAUTH);

	CONSTANT2(OSSL_HPKE_, MAX_PARMLEN);
	CONSTANT2(OSSL_HPKE_, MIN_PSKLEN);
	CONSTANT2(OSSL_HPKE_, MAX_INFOLEN);
#endif
}

#if OPENSSL_VERSION_PREREQ(3, 2)

Crypt::OpenSSL3::HPKE OSSL_HPKE_new(class, unsigned short kem, unsigned short kdf, unsigned short aead)
CODE:
	RETVAL = safemalloc(sizeof(OSSL_HPKE_SUITE));
	RETVAL->kem_id = kem;
	RETVAL->kdf_id = kdf;
	RETVAL->aead_id = aead;
OUTPUT: RETVAL

Crypt::OpenSSL3::HPKE OSSL_HPKE_from_string(class, const char *str)
CODE:
	RETVAL = safemalloc(sizeof(OSSL_HPKE_SUITE));
	if (!OSSL_HPKE_str2suite(str, RETVAL)) {
		Safefree(RETVAL);
		XSRETURN_UNDEF;
	}
OUTPUT: RETVAL

Crypt::OpenSSL3::HPKE OSSL_HPKE_default(class)
CODE:
	RETVAL = safemalloc(sizeof(OSSL_HPKE_SUITE));
	*RETVAL = (OSSL_HPKE_SUITE)OSSL_HPKE_SUITE_DEFAULT;
OUTPUT: RETVAL

Bool OSSL_HPKE_check(Crypt::OpenSSL3::HPKE suite)
C_ARGS: *suite

size_t OSSL_HPKE_get_ciphertext_size(Crypt::OpenSSL3::HPKE suite, size_t clearlen)
C_ARGS: *suite, clearlen

size_t OSSL_HPKE_get_public_encap_size(Crypt::OpenSSL3::HPKE suite)
C_ARGS: *suite

size_t OSSL_HPKE_get_recommended_ikmelen(Crypt::OpenSSL3::HPKE suite);
C_ARGS: *suite

SV* OSSL_HPKE_keygen(Crypt::OpenSSL3::HPKE suite, OUTLIST Crypt::OpenSSL3::PKey priv, const char *propq = NULL)
CODE:
	size_t pub_len = OSSL_HPKE_get_public_encap_size(*suite);
	unsigned char* pub = make_buffer(&RETVAL, pub_len);
	if (OSSL_HPKE_keygen(*suite, pub, &pub_len, &priv, NULL, 0, NULL, propq))
		set_buffer_length(RETVAL, pub_len);
	else
		XSRETURN_EMPTY;
OUTPUT: RETVAL

SV* OSSL_HPKE_suite(Crypt::OpenSSL3::HPKE suite)
CODE:
	RETVAL = newSVpvn((const char*)suite, sizeof *suite);
OUTPUT: RETVAL

unsigned short OSSL_HPKE_kem_id(Crypt::OpenSSL3::HPKE suite)

unsigned short OSSL_HPKE_kdf_id(Crypt::OpenSSL3::HPKE suite)

unsigned short OSSL_HPKE_aead_id(Crypt::OpenSSL3::HPKE suite)

void OSSL_HPKE_get_grease_value(Crypt::OpenSSL3::HPKE suite, OUTLIST SV* enc, OUTLIST SV* ct, size_t pt_length, const char *propq = NULL)
CODE:
	size_t enc_length = OSSL_HPKE_get_public_encap_size(*suite);
	unsigned char* enc_ptr = make_buffer(&enc, enc_length);
	size_t ct_length = OSSL_HPKE_get_ciphertext_size(*suite, pt_length);
	unsigned char* ct_ptr = make_buffer(&ct, ct_length);
	int retval = OSSL_HPKE_get_grease_value(suite, suite, enc_ptr, &enc_length, ct_ptr, ct_length, NULL, propq);
	if (retval) {
		set_buffer_length(enc, enc_length);
		set_buffer_length(ct, ct_length);
	}
	else
		XSRETURN_EMPTY;

#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::HPKE::Context	PREFIX = OSSL_HPKE_

#if OPENSSL_VERSION_PREREQ(3, 2)

SV* OSSL_HPKE_encapsulate(Crypt::OpenSSL3::HPKE::Context hpke, const unsigned char *pub, size_t length(pub), const unsigned char *info, size_t length(info))
CODE:
	size_t enc_length = OSSL_HPKE_get_public_encap_size(hpke->suite);
	unsigned char* enc_ptr = make_buffer(&RETVAL, enc_length);
	if (OSSL_HPKE_encap(hpke->context, enc_ptr, &enc_length, pub, XSauto_length_of_pub, info, XSauto_length_of_info))
		set_buffer_length(RETVAL, enc_length);
OUTPUT: RETVAL

SV* OSSL_HPKE_seal(Crypt::OpenSSL3::HPKE::Context hpke, const unsigned char *pt, size_t length(pt), const unsigned char *aad, size_t length(aad))
CODE:
	size_t enc_length = OSSL_HPKE_get_ciphertext_size(hpke->suite, XSauto_length_of_pt);
	unsigned char* enc_ptr = make_buffer(&RETVAL, enc_length);
	if (OSSL_HPKE_seal(hpke->context, enc_ptr, &enc_length, aad, XSauto_length_of_aad, pt, XSauto_length_of_pt))
		set_buffer_length(RETVAL, enc_length);
OUTPUT: RETVAL

Bool OSSL_HPKE_decapsulate(Crypt::OpenSSL3::HPKE::Context hpke, const unsigned char *enc, size_t length(enc), Crypt::OpenSSL3::PKey recippriv, const unsigned char *info, size_t length(info))
C_ARGS: hpke->context, enc, XSauto_length_of_enc, recippriv, info, XSauto_length_of_info

SV* OSSL_HPKE_open(Crypt::OpenSSL3::HPKE::Context hpke, const unsigned char *ct, size_t length(ct), const unsigned char *aad, size_t length(aad))
CODE:
	size_t pt_length = XSauto_length_of_ct;
	unsigned char* pt_ptr = make_buffer(&RETVAL, pt_length);
	if (OSSL_HPKE_open(hpke->context, pt_ptr, &pt_length, aad, XSauto_length_of_aad, ct, XSauto_length_of_ct))
		set_buffer_length(RETVAL, pt_length);
OUTPUT: RETVAL

SV* OSSL_HPKE_export(Crypt::OpenSSL3::HPKE::Context hpke, size_t secret_length, const unsigned char *label, size_t length(label))
CODE:
	unsigned char* secret = make_buffer(&RETVAL, secret_length);
	if (OSSL_HPKE_export(hpke->context, secret, secret_length, label, XSauto_length_of_label))
		set_buffer_length(RETVAL, secret_length);
OUTPUT: RETVAL

#endif


MODULE = Crypt::OpenSSL3	PACKAGE = Crypt::OpenSSL3::HPKE::Context	PREFIX = OSSL_HPKE_CTX_

#if OPENSSL_VERSION_PREREQ(3, 2)

Crypt::OpenSSL3::HPKE::Context OSSL_HPKE_CTX_new(class, Crypt::OpenSSL3::HPKE suite, int role, int mode = OSSL_HPKE_MODE_BASE, const char *propq = NULL)
CODE:
	OSSL_HPKE_CTX* ctx = OSSL_HPKE_CTX_new(mode, *suite, role, NULL, propq);
	if (!ctx)
		XSRETURN_UNDEF;
	RETVAL = safemalloc(sizeof(HPKE));
	RETVAL->suite = *suite;
	RETVAL->context = ctx;
OUTPUT: RETVAL

bool OSSL_HPKE_CTX_set_authpriv(Crypt::OpenSSL3::HPKE::Context hpke, Crypt::OpenSSL3::PKey priv)
C_ARGS: hpke->context, priv

bool OSSL_HPKE_CTX_set_authpub(Crypt::OpenSSL3::HPKE::Context hpke, unsigned char *input, size_t length(input))
INTERFACE: OSSL_HPKE_CTX_set_authpub OSSL_HPKE_CTX_set_ikme
C_ARGS: hpke->context, input, XSauto_length_of_input

bool OSSL_HPKE_CTX_set_psk(Crypt::OpenSSL3::HPKE::Context hpke, const char *pskid, const unsigned char *psk, size_t length(psk))
C_ARGS: hpke->context, pskid, psk, XSauto_length_of_psk

NO_OUTPUT int OSSL_HPKE_CTX_get_seq(Crypt::OpenSSL3::HPKE::Context hpke, OUTLIST uint64_t seq)
C_ARGS: hpke->context, &seq
POSTCALL:
	if (!RETVAL)
		XSRETURN_UNDEF;

bool OSSL_HPKE_CTX_set_seq(Crypt::OpenSSL3::HPKE::Context hpke, uint64_t seq)
C_ARGS: hpke->context, seq

Bool CLONE_SKIP(...)

#endif
