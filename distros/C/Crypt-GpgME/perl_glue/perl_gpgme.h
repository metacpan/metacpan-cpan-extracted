#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <proto.h>

#include "ppport.h"

#include <gpgme.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "perl_gpgme_data.h"


#define PERL_GPGME_CALL_BOOT(name) \
	{ \
		EXTERN_C XS(name); \
		_perl_gpgme_call_xs (aTHX_ name, cv, mark); \
	}

#ifdef PERL_IMPLICIT_CONTEXT

#define dPERL_GPGME_CALLBACK_MARSHAL_SP \
	SV **sp;

#define PERL_GPGME_MARSHAL_INIT(cb) \
	PERL_SET_CONTEXT (cb->priv); \
	SPAGAIN;

#else

#define dPERL_GPGME_CALLBACK_MARSHAL_SP \
	dSP;

#define PERL_GPGME_MARSHAL_INIT(cb) \
	/* nothing to do */

#endif

typedef gpgme_ctx_t perl_gpgme_ctx_or_null_t;

typedef struct perl_gpgme_status_code_map_St {
	gpgme_status_code_t status;
	const char *string;
} perl_gpgme_status_code_map_t;

typedef enum {
	PERL_GPGME_CALLBACK_PARAM_TYPE_STR,
	PERL_GPGME_CALLBACK_PARAM_TYPE_INT,
	PERL_GPGME_CALLBACK_PARAM_TYPE_CHAR,
	PERL_GPGME_CALLBACK_PARAM_TYPE_STATUS
} perl_gpgme_callback_param_type_t;

typedef enum {
	PERL_GPGME_CALLBACK_RETVAL_TYPE_STR
} perl_gpgme_callback_retval_type_t;

typedef void * perl_gpgme_callback_retval_t;

typedef struct perl_gpgme_callback_St {
	SV *func;
	SV *data;
	SV *obj;
	int n_params;
	perl_gpgme_callback_param_type_t *param_types;
	int n_retvals;
	perl_gpgme_callback_retval_type_t *retval_types;
	void *priv;
} perl_gpgme_callback_t;

void _perl_gpgme_call_xs (pTHX_ void (*subaddr) (pTHX_ CV *cv), CV *cv, SV **mark);

SV *perl_gpgme_new_sv_from_ptr (void *ptr, const char *class);

void *perl_gpgme_get_ptr_from_sv (SV *sv, const char *class);

MAGIC *perl_gpgme_get_magic_from_sv (SV *sv, const char *class);

void perl_gpgme_assert_error (gpgme_error_t err);

perl_gpgme_callback_t *perl_gpgme_callback_new (SV *func, SV *data, SV *obj, int n_params, perl_gpgme_callback_param_type_t param_types[], int n_retvals, perl_gpgme_callback_retval_type_t retval_types[]);

void perl_gpgme_callback_destroy (perl_gpgme_callback_t *cb);

void perl_gpgme_callback_invoke (perl_gpgme_callback_t *cb, perl_gpgme_callback_retval_t *retvals, ...);

SV *perl_gpgme_protocol_to_string (gpgme_protocol_t protocol);

void perl_gpgme_hv_store (HV *hv, const char *key, I32 key_len, SV *val);

SV *perl_gpgme_hashref_from_engine_info (gpgme_engine_info_t info);

SV *perl_gpgme_hashref_from_subkey (gpgme_subkey_t subkey);

SV *perl_gpgme_hashref_from_uid (gpgme_user_id_t uid);

SV *perl_gpgme_avref_from_notation_flags (gpgme_sig_notation_flags_t flags);

SV *perl_gpgme_validity_to_string (gpgme_validity_t validity);

SV *perl_gpgme_array_ref_from_signatures (gpgme_key_sig_t sig);

SV *perl_gpgme_hashref_from_signature (gpgme_key_sig_t sig);

SV *perl_gpgme_array_ref_from_notations (gpgme_sig_notation_t notations);

SV *perl_gpgme_hashref_from_notation (gpgme_sig_notation_t notation);

SV *perl_gpgme_hashref_from_verify_result (gpgme_verify_result_t result);

SV *perl_gpgme_array_ref_from_verify_signatures (gpgme_signature_t sigs);

SV *perl_gpgme_hashref_from_verify_signature (gpgme_signature_t sig);

SV *perl_gpgme_sigsum_to_string (gpgme_sigsum_t summary);

SV *perl_gpgme_hash_algo_to_string (gpgme_hash_algo_t algo);

SV *perl_gpgme_hashref_from_trust_item (gpgme_trust_item_t item);

SV *perl_gpgme_sv_from_status_code (gpgme_status_code_t status);

SV *perl_gpgme_genkey_result_to_sv (gpgme_genkey_result_t result);
