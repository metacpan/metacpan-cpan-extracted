#include "perl_gpgme.h"

static const perl_gpgme_status_code_map_t perl_gpgme_status_code_map[] = {
	{ GPGME_STATUS_EOF, "eof" },

	{ GPGME_STATUS_ENTER, "enter" },
	{ GPGME_STATUS_LEAVE, "leave" },
	{ GPGME_STATUS_ABORT, "abort" },

	{ GPGME_STATUS_GOODSIG, "goodsig" },
	{ GPGME_STATUS_BADSIG, "badsig" },
	{ GPGME_STATUS_ERRSIG, "errsig" },

	{ GPGME_STATUS_BADARMOR, "badarmor" },

	{ GPGME_STATUS_RSA_OR_IDEA, "rsa-or-idea" },
	{ GPGME_STATUS_KEYEXPIRED, "keyexpired" },
	{ GPGME_STATUS_KEYREVOKED, "keyrevoked" },

	{ GPGME_STATUS_TRUST_UNDEFINED, "trust-undefined" },
	{ GPGME_STATUS_TRUST_NEVER, "trust-never" },
	{ GPGME_STATUS_TRUST_MARGINAL, "trust-marginal" },
	{ GPGME_STATUS_TRUST_FULLY, "trust-fully" },
	{ GPGME_STATUS_TRUST_ULTIMATE, "trust-ultimate" },

	{ GPGME_STATUS_SHM_INFO, "shm-info" },
	{ GPGME_STATUS_SHM_GET, "shm-get" },
	{ GPGME_STATUS_SHM_GET_BOOL, "shm-get-bool" },
	{ GPGME_STATUS_SHM_GET_HIDDEN, "shm-get-hidden" },

	{ GPGME_STATUS_NEED_PASSPHRASE, "need-passphrase" },
	{ GPGME_STATUS_VALIDSIG, "validsig" },
	{ GPGME_STATUS_SIG_ID, "sig-id" },
	{ GPGME_STATUS_ENC_TO, "enc-to" },
	{ GPGME_STATUS_NODATA, "nodata" },
	{ GPGME_STATUS_BAD_PASSPHRASE, "bad-passphrase" },
	{ GPGME_STATUS_NO_PUBKEY, "no-pubkey" },
	{ GPGME_STATUS_NO_SECKEY, "no-seckey" },
	{ GPGME_STATUS_NEED_PASSPHRASE_SYM, "need-passphrase-sym" },
	{ GPGME_STATUS_DECRYPTION_FAILED, "decryption-failed" },
	{ GPGME_STATUS_DECRYPTION_OKAY, "decryption-okay" },
	{ GPGME_STATUS_MISSING_PASSPHRASE, "missing-passphrase" },
	{ GPGME_STATUS_GOOD_PASSPHRASE, "good-passphrase" },
	{ GPGME_STATUS_GOODMDC, "goodmdc" },
	{ GPGME_STATUS_BADMDC, "badmdc" },
	{ GPGME_STATUS_ERRMDC, "errmdc" },
	{ GPGME_STATUS_IMPORTED, "imported" },
	{ GPGME_STATUS_IMPORT_OK, "import-ok" },
	{ GPGME_STATUS_IMPORT_PROBLEM, "status-import-problem" },
	{ GPGME_STATUS_IMPORT_RES, "import-res" },
	{ GPGME_STATUS_FILE_START, "file-start" },
	{ GPGME_STATUS_FILE_DONE, "file-done" },
	{ GPGME_STATUS_FILE_ERROR, "file-error" },

	{ GPGME_STATUS_BEGIN_DECRYPTION, "begin-decryption" },
	{ GPGME_STATUS_END_DECRYPTION, "end-decryption" },
	{ GPGME_STATUS_BEGIN_ENCRYPTION, "begin-encryption" },
	{ GPGME_STATUS_END_ENCRYPTION, "end-encryption" },

	{ GPGME_STATUS_DELETE_PROBLEM, "delete-problem" },
	{ GPGME_STATUS_GET_BOOL, "get-bool" },
	{ GPGME_STATUS_GET_LINE, "get-line" },
	{ GPGME_STATUS_GET_HIDDEN, "get-hidden" },
	{ GPGME_STATUS_GOT_IT, "got-it" },
	{ GPGME_STATUS_PROGRESS, "progress" },
	{ GPGME_STATUS_SIG_CREATED, "sig-created" },
	{ GPGME_STATUS_SESSION_KEY, "session-key" },
	{ GPGME_STATUS_NOTATION_NAME, "notation-name" },
	{ GPGME_STATUS_NOTATION_DATA, "notation-data" },
	{ GPGME_STATUS_POLICY_URL, "policy-url" },
	{ GPGME_STATUS_BEGIN_STREAM, "begin-stream" },
	{ GPGME_STATUS_END_STREAM, "end-stream" },
	{ GPGME_STATUS_KEY_CREATED, "key-created" },
	{ GPGME_STATUS_USERID_HINT, "userid-hint" },
	{ GPGME_STATUS_UNEXPECTED, "unexpected" },
	{ GPGME_STATUS_INV_RECP, "inv-recp" },
	{ GPGME_STATUS_NO_RECP, "no-recp" },
	{ GPGME_STATUS_ALREADY_SIGNED, "already-signed" },
	{ GPGME_STATUS_SIGEXPIRED, "sigexpired" },
	{ GPGME_STATUS_EXPSIG, "expsig" },
	{ GPGME_STATUS_EXPKEYSIG, "expkeysig" },
	{ GPGME_STATUS_TRUNCATED, "truncated" },
	{ GPGME_STATUS_ERROR, "error" },
	{ GPGME_STATUS_NEWSIG, "newsig" },
	{ GPGME_STATUS_REVKEYSIG, "revkeysig" },
	{ GPGME_STATUS_SIG_SUBPACKET, "sig-subpacket" },
	{ GPGME_STATUS_NEED_PASSPHRASE_PIN, "need-passphrase-pin" },
	{ GPGME_STATUS_SC_OP_FAILURE, "sc-op-failure" },
	{ GPGME_STATUS_SC_OP_SUCCESS, "sc-op-success" },
	{ GPGME_STATUS_CARDCTRL, "cardctrl" },
	{ GPGME_STATUS_BACKUP_KEY_CREATED, "backup-key-created" },
	{ GPGME_STATUS_PKA_TRUST_BAD, "pka-trust-bad" },
	{ GPGME_STATUS_PKA_TRUST_GOOD, "pka-trust-good" },

	{ GPGME_STATUS_PLAINTEXT, "plaintext" }
};

void
_perl_gpgme_call_xs (pTHX_ void (*subaddr) (pTHX_ CV *), CV *cv, SV **mark) {
	dSP;
	PUSHMARK (mark);
	(*subaddr) (aTHX_ cv);
	PUTBACK;
}

SV *
perl_gpgme_new_sv_from_ptr (void *ptr, const char *class) {
	SV *obj, *sv;
	HV *stash;

	obj = (SV *)newHV ();
	sv_magic (obj, 0, PERL_MAGIC_ext, (const char *)ptr, 0);
	sv = newRV_noinc (obj);
	stash = gv_stashpv (class, 0);
	sv_bless (sv, stash);

	return sv;
}

void *
perl_gpgme_get_ptr_from_sv (SV *sv, const char *class) {
	MAGIC *mg;

	mg = perl_gpgme_get_magic_from_sv (sv, class);

	return (void *)mg->mg_ptr;
}

MAGIC *
perl_gpgme_get_magic_from_sv (SV *sv, const char *class) {
	MAGIC *mg;

	if (!sv || !SvOK (sv) || !SvROK (sv)
	 || (class && !sv_derived_from (sv, class))
	 || !(mg = mg_find (SvRV (sv), PERL_MAGIC_ext))) {
		croak ("invalid object");
	}

	return mg;
}

void
perl_gpgme_assert_error (gpgme_error_t err) {
	if (err == GPG_ERR_NO_ERROR) {
		return;
	}

	croak ("%s: %s", gpgme_strsource (err), gpgme_strerror (err));
}

perl_gpgme_callback_t *
perl_gpgme_callback_new (SV *func, SV *data, SV *obj, int n_params, perl_gpgme_callback_param_type_t param_types[], int n_retvals, perl_gpgme_callback_retval_type_t retval_types[]) {
	perl_gpgme_callback_t *cb;

	Newxz (cb, 1, perl_gpgme_callback_t);

	cb->func = newSVsv (func);

	if (data) {
		cb->data = newSVsv (data);
	}

	if (obj) {
		SvREFCNT_inc (obj);
		cb->obj = obj;
	}

	cb->n_params = n_params;

	if (cb->n_params) {
		if (!param_types) {
			croak ("n_params is %d, but param_types is NULL", n_params);
		}

		Newx (cb->param_types, n_params, perl_gpgme_callback_param_type_t);
		Copy (param_types, cb->param_types, n_params, perl_gpgme_callback_param_type_t);
	}

	cb->n_retvals = n_retvals;

	if (cb->n_retvals) {
		if (!retval_types) {
			croak ("n_retvals is %d, but retval_types is NULL", n_retvals);
		}

		Newx (cb->retval_types, n_retvals, perl_gpgme_callback_retval_type_t);
		Copy (retval_types, cb->retval_types, n_retvals, perl_gpgme_callback_retval_type_t);
	}

#ifdef PERL_IMPLICIT_CONTEXT
	cb->priv = aTHX;
#endif

	return cb;
}

void
perl_gpgme_callback_destroy (perl_gpgme_callback_t *cb) {
	if (cb) {
		if (cb->func) {
			SvREFCNT_dec (cb->func);
			cb->func = NULL;
		}

		if (cb->data) {
			SvREFCNT_dec (cb->func);
			cb->func = NULL;
		}

		if (cb->obj) {
			SvREFCNT_dec (cb->obj);
			cb->obj = NULL;
		}

		if (cb->param_types) {
			Safefree (cb->param_types);
			cb->n_params = 0;
			cb->param_types = NULL;
		}

		if (cb->retval_types) {
			Safefree (cb->retval_types);
			cb->n_retvals = 0;
			cb->retval_types = NULL;
		}

		Safefree (cb);
	}
}

void
perl_gpgme_callback_invoke (perl_gpgme_callback_t *cb, perl_gpgme_callback_retval_t *retvals, ...) {
	va_list va_args;
	int ret, i;
	I32 call_flags;

	dPERL_GPGME_CALLBACK_MARSHAL_SP;

	if (!cb) {
		croak ("NULL cb in callback_invoke");
	}

	PERL_GPGME_MARSHAL_INIT (cb);

	ENTER;
	SAVETMPS;

	PUSHMARK (sp);

	EXTEND (sp, cb->n_params + 1);

	if (cb->obj) {
		PUSHs (cb->obj);
	}

	va_start (va_args, retvals);

	for (i = 0; i < cb->n_params; i++) {
		SV *sv;

		switch (cb->param_types[i]) {
			case PERL_GPGME_CALLBACK_PARAM_TYPE_STR:
				sv = newSVpv (va_arg (va_args, char *), 0);
				break;
			case PERL_GPGME_CALLBACK_PARAM_TYPE_INT:
				sv = newSViv (va_arg (va_args, int));
				break;
			case PERL_GPGME_CALLBACK_PARAM_TYPE_CHAR: {
				char tmp[0];
				tmp[0] = va_arg (va_args, int);

				sv = newSVpv (tmp, 1);
				break;
			}
			case PERL_GPGME_CALLBACK_PARAM_TYPE_STATUS:
				sv = perl_gpgme_sv_from_status_code (va_arg (va_args, gpgme_status_code_t));
				break;
			default:
				PUTBACK;
				croak ("unknown perl_gpgme_callback_param_type_t");
		}

		if (!sv) {
			PUTBACK;
			croak ("failed to convert value to sv");
		}

		PUSHs (sv);
	}

	va_end (va_args);

	if (cb->data) {
		XPUSHs (cb->data);
	}

	PUTBACK;

	if (cb->n_retvals == 0) {
		call_flags = G_VOID|G_DISCARD;
	}
	else if (cb->n_retvals == 1) {
		call_flags = G_SCALAR;
	}
	else {
		call_flags = G_ARRAY;
	}

	ret = call_sv (cb->func, call_flags);

	SPAGAIN;

	if (ret != cb->n_retvals) {
		PUTBACK;
		croak ("callback didn't return as much values as expected (got: %d, expected: %d)", ret, cb->n_retvals);
	}

	for (i = 0; i < ret; i++) {
		switch (cb->retval_types[i]) {
			case PERL_GPGME_CALLBACK_RETVAL_TYPE_STR:
				retvals[i] = (perl_gpgme_callback_retval_t)savepv (POPp);
				break;
			default:
				PUTBACK;
				croak ("unknown perl_gpgme_callback_retval_type_t");
		}
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
}

SV *
perl_gpgme_protocol_to_string (gpgme_protocol_t protocol) {
	const char *name = gpgme_get_protocol_name (protocol);

	if (!name) {
		return &PL_sv_undef;
	}

	return newSVpv (name, 0);
}

void
perl_gpgme_hv_store (HV *hv, const char *key, I32 key_len, SV *val) {
	SV **ret;

	if (key_len == 0) {
		key_len = strlen (key);
	}

	ret = hv_store (hv, key, key_len, val, 0);

	if (!ret) {
		croak ("failed to store value inside hash");
	}
}

SV *
perl_gpgme_hashref_from_engine_info (gpgme_engine_info_t info) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	if (info->file_name) {
		perl_gpgme_hv_store (hv, "file_name", 9, newSVpv (info->file_name, 0));
	}

	if (info->home_dir) {
		perl_gpgme_hv_store (hv, "home_dir", 8, newSVpv (info->home_dir, 0));
	}

	if (info->version) {
		perl_gpgme_hv_store (hv, "version", 7, newSVpv (info->version, 0));
	}

	if (info->req_version) {
		perl_gpgme_hv_store (hv, "req_version", 11, newSVpv (info->req_version, 0));
	}

	perl_gpgme_hv_store (hv, "protocol", 8, perl_gpgme_protocol_to_string (info->protocol));

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_pubkey_algo_to_string (gpgme_pubkey_algo_t algo) {
	const char *name = gpgme_pubkey_algo_name (algo);

	if (!name) {
		return &PL_sv_undef;
	}

	return newSVpv (name, 0);
}

SV *
perl_gpgme_hashref_from_subkey (gpgme_subkey_t subkey) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	perl_gpgme_hv_store (hv, "revoked", 7, newSVuv (subkey->revoked));
	perl_gpgme_hv_store (hv, "expired", 7, newSVuv (subkey->expired));
	perl_gpgme_hv_store (hv, "disabled", 8, newSVuv (subkey->disabled));
	perl_gpgme_hv_store (hv, "invalid", 7, newSVuv (subkey->invalid));
	perl_gpgme_hv_store (hv, "can_encrypt", 11, newSVuv (subkey->can_encrypt));
	perl_gpgme_hv_store (hv, "can_sign", 8, newSVuv (subkey->can_sign));
	perl_gpgme_hv_store (hv, "can_certify", 11, newSVuv (subkey->can_certify));
	perl_gpgme_hv_store (hv, "secret", 6, newSVuv (subkey->secret));
	perl_gpgme_hv_store (hv, "can_authenticate", 16, newSVuv (subkey->can_authenticate));
	perl_gpgme_hv_store (hv, "is_qualified", 12, newSVuv (subkey->is_qualified));
	perl_gpgme_hv_store (hv, "pubkey_algo", 11, perl_gpgme_pubkey_algo_to_string (subkey->pubkey_algo));
	perl_gpgme_hv_store (hv, "length", 6, newSVuv (subkey->length));

	if (subkey->keyid) {
		perl_gpgme_hv_store (hv, "keyid", 5, newSVpv (subkey->keyid, 0));
	}

	if (subkey->fpr) {
		perl_gpgme_hv_store (hv, "fpr", 3, newSVpv (subkey->fpr, 0));
	}

	perl_gpgme_hv_store (hv, "timestamp", 9, newSViv (subkey->timestamp)); /* FIXME: long int vs. int? */
	perl_gpgme_hv_store (hv, "expires", 7, newSViv (subkey->expires)); /* ditto */

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_hashref_from_uid (gpgme_user_id_t uid) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	perl_gpgme_hv_store (hv, "revoked", 7, newSVuv (uid->revoked));
	perl_gpgme_hv_store (hv, "invalid", 7, newSVuv (uid->invalid));
	perl_gpgme_hv_store (hv, "validity", 8, perl_gpgme_validity_to_string (uid->validity));

	if (uid->uid) {
		perl_gpgme_hv_store (hv, "uid", 3, newSVpv (uid->uid, 0));
	}

	if (uid->name) {
		perl_gpgme_hv_store (hv, "name", 4, newSVpv (uid->name, 0));
	}

	if (uid->email) {
		perl_gpgme_hv_store (hv, "email", 5, newSVpv (uid->email, 0));
	}

	if (uid->comment) {
		perl_gpgme_hv_store (hv, "comment", 7, newSVpv (uid->comment, 0));
	}

	if (uid->signatures) {
		perl_gpgme_hv_store (hv, "signatures", 10, perl_gpgme_array_ref_from_signatures (uid->signatures));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_array_ref_from_signatures (gpgme_key_sig_t sig) {
	SV *sv;
	AV *av;
	gpgme_key_sig_t i;

	av = newAV ();

	for (i = sig; i != NULL; i = i->next) {
		av_push (av, perl_gpgme_hashref_from_signature (i));
	}

	sv = newRV_noinc ((SV *)av);
	return sv;
}

SV *
perl_gpgme_hashref_from_signature (gpgme_key_sig_t sig) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	perl_gpgme_hv_store (hv, "revoked", 7, newSVuv (sig->revoked));
	perl_gpgme_hv_store (hv, "expired", 7, newSVuv (sig->expired));
	perl_gpgme_hv_store (hv, "invalid", 7, newSVuv (sig->invalid));
	perl_gpgme_hv_store (hv, "exportable", 10, newSVuv (sig->exportable));
	perl_gpgme_hv_store (hv, "pubkey_algo", 11, perl_gpgme_pubkey_algo_to_string (sig->pubkey_algo));

	if (sig->keyid) {
		perl_gpgme_hv_store (hv, "keyid", 5, newSVpv (sig->keyid, 0));
	}

	perl_gpgme_hv_store (hv, "timestamp", 9, newSViv (sig->timestamp)); /* FIXME: long int vs. IV? */
	perl_gpgme_hv_store (hv, "expires", 7, newSViv (sig->expires)); /* ditto */

	if (sig->status != GPG_ERR_NO_ERROR) {
		perl_gpgme_hv_store (hv, "status", 6, newSVpvf ("%s: %s", gpgme_strsource (sig->status), gpgme_strerror (sig->status)));
	}

	if (sig->uid) {
		perl_gpgme_hv_store (hv, "uid", 3, newSVpv (sig->uid, 0));
	}

	if (sig->name) {
		perl_gpgme_hv_store (hv, "name", 4, newSVpv (sig->name, 0));
	}

	if (sig->email) {
		perl_gpgme_hv_store (hv, "email", 5, newSVpv (sig->email, 0));
	}

	if (sig->comment) {
		perl_gpgme_hv_store (hv, "comment", 7, newSVpv (sig->comment, 0));
	}

	/* FIXME: really export this? */
	perl_gpgme_hv_store (hv, "sig_class", 9, newSVuv (sig->sig_class));

	if (sig->notations) {
		perl_gpgme_hv_store (hv, "notations", 9, perl_gpgme_array_ref_from_notations (sig->notations));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_array_ref_from_notations (gpgme_sig_notation_t notations) {
	SV *sv;
	AV *av;
	gpgme_sig_notation_t i;

	av = newAV ();

	for (i = notations; i != NULL; i = i->next) {
		av_push (av, perl_gpgme_hashref_from_notation (i));
	}

	sv = newRV_noinc ((SV *)av);
	return sv;
}

SV *
perl_gpgme_hashref_from_notation (gpgme_sig_notation_t notation) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	if (notation->name) {
		perl_gpgme_hv_store (hv, "name", 4, newSVpv (notation->name, notation->name_len));
	}

	if (notation->value) {
		perl_gpgme_hv_store (hv, "value", 5, newSVpv (notation->value, notation->value_len));
	}

	perl_gpgme_hv_store (hv, "flags", 5, perl_gpgme_avref_from_notation_flags (notation->flags));

	perl_gpgme_hv_store (hv, "human_readable", 14, newSVuv (notation->human_readable));
	perl_gpgme_hv_store (hv, "critical", 8, newSVuv (notation->critical));

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_avref_from_notation_flags (gpgme_sig_notation_flags_t flags) {
	SV *sv;
	AV *av;

	av = newAV ();

	if (flags & GPGME_SIG_NOTATION_HUMAN_READABLE) {
		av_push (av, newSVpv ("human-readable", 0));
	}

	if (flags & GPGME_SIG_NOTATION_CRITICAL) {
		av_push (av, newSVpv ("critical", 0));
	}

	sv = newRV_inc ((SV *)av);
	return sv;
}

SV *
perl_gpgme_validity_to_string (gpgme_validity_t validity) {
	SV *ret;

	switch (validity) {
		case GPGME_VALIDITY_UNKNOWN:
			ret = newSVpvn ("unknown", 7);
			break;
		case GPGME_VALIDITY_UNDEFINED:
			ret = newSVpvn ("undefined", 9);
			break;
		case GPGME_VALIDITY_NEVER:
			ret = newSVpvn ("never", 5);
			break;
		case GPGME_VALIDITY_MARGINAL:
			ret = newSVpvn ("marginal", 8);
			break;
		case GPGME_VALIDITY_FULL:
			ret = newSVpvn ("full", 4);
			break;
		case GPGME_VALIDITY_ULTIMATE:
			ret = newSVpvn ("ultimate", 8);
			break;
		default:
			ret = &PL_sv_undef;
	}

	return ret;
}

SV *
perl_gpgme_hashref_from_verify_result (gpgme_verify_result_t result) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	if (result->file_name) {
		perl_gpgme_hv_store (hv, "file_name", 9, newSVpv (result->file_name, 0));
	}

	if (result->signatures) {
		perl_gpgme_hv_store (hv, "signatures", 10, perl_gpgme_array_ref_from_verify_signatures (result->signatures));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_array_ref_from_verify_signatures (gpgme_signature_t sig) {
	SV *sv;
	AV *av;
	gpgme_signature_t i;

	av = newAV ();

	for (i = sig; i != NULL; i = i->next) {
		av_push (av, perl_gpgme_hashref_from_verify_signature (i));
	}

	sv = newRV_noinc ((SV *)av);
	return sv;
}

SV *
perl_gpgme_hashref_from_verify_signature (gpgme_signature_t sig) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	perl_gpgme_hv_store (hv, "summary", 7, perl_gpgme_sigsum_to_string (sig->summary));

	if (sig->fpr) {
		perl_gpgme_hv_store (hv, "fpr", 3, newSVpv (sig->fpr, 0));
	}

	if (sig->status != GPG_ERR_NO_ERROR) {
		perl_gpgme_hv_store (hv, "status", 6, newSVpvf ("%s: %s", gpgme_strsource (sig->status), gpgme_strerror (sig->status)));
	}

	perl_gpgme_hv_store (hv, "notations", 9, perl_gpgme_array_ref_from_notations (sig->notations));

	perl_gpgme_hv_store (hv, "timestamp", 9, newSVuv (sig->timestamp)); /* FIXME: long uint vs. UV */
	perl_gpgme_hv_store (hv, "exp_timestamp", 13, newSVuv (sig->exp_timestamp)); /* ditto */
	perl_gpgme_hv_store (hv, "wrong_key_usage", 15, newSVuv (sig->wrong_key_usage));
	perl_gpgme_hv_store (hv, "pka_trust", 9, newSVuv (sig->pka_trust));

	perl_gpgme_hv_store (hv, "validity", 8, perl_gpgme_validity_to_string (sig->validity));

	if (sig->validity_reason != GPG_ERR_NO_ERROR) {
		perl_gpgme_hv_store (hv, "validity_reason", 15, newSVpvf ("%s: %s", gpgme_strsource (sig->status), gpgme_strerror (sig->status)));
	}

	perl_gpgme_hv_store (hv, "pubkey_algo", 11, perl_gpgme_pubkey_algo_to_string (sig->pubkey_algo));
	perl_gpgme_hv_store (hv, "hash_algo", 9, perl_gpgme_hash_algo_to_string (sig->hash_algo));

	if (sig->pka_address) {
		perl_gpgme_hv_store (hv, "pka_address", 11, newSVpv (sig->pka_address, 0));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_sigsum_to_string (gpgme_sigsum_t summary) {
	SV *sv;
	AV *av;

	av = newAV ();

	if (summary & GPGME_SIGSUM_VALID) {
		av_push (av, newSVpv ("valid", 0));
	}

	if (summary & GPGME_SIGSUM_GREEN) {
		av_push (av, newSVpv ("green", 0));
	}

	if (summary & GPGME_SIGSUM_RED) {
		av_push (av, newSVpv ("red", 0));
	}

	if (summary & GPGME_SIGSUM_KEY_REVOKED) {
		av_push (av, newSVpv ("key-revoked", 0));
	}

	if (summary & GPGME_SIGSUM_KEY_EXPIRED) {
		av_push (av, newSVpv ("key-expired", 0));
	}

	if (summary & GPGME_SIGSUM_SIG_EXPIRED) {
		av_push (av, newSVpv ("sig-expired", 0));
	}

	if (summary & GPGME_SIGSUM_CRL_MISSING) {
		av_push (av, newSVpv ("crl-missing", 0));
	}

	if (summary & GPGME_SIGSUM_CRL_TOO_OLD) {
		av_push (av, newSVpv ("crl-too-old", 0));
	}

	if (summary & GPGME_SIGSUM_BAD_POLICY) {
		av_push (av, newSVpv ("bad-policy", 0));
	}

	if (summary & GPGME_SIGSUM_SYS_ERROR) {
		av_push (av, newSVpv ("sys-error", 0));
	}

	sv = newRV_noinc ((SV *)av);
	return sv;
}

SV *
perl_gpgme_hash_algo_to_string (gpgme_hash_algo_t algo) {
	const char *name = gpgme_hash_algo_name (algo);

	if (!name) {
		return &PL_sv_undef;
	}

	return newSVpv (name, 0);
}

SV *
perl_gpgme_hashref_from_trust_item (gpgme_trust_item_t item) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	if (item->keyid) {
		perl_gpgme_hv_store (hv, "keyid", 5, newSVpv (item->keyid, 0));
	}

	perl_gpgme_hv_store (hv, "type", 4, newSVpv (item->type == 1 ? "key" : "uid", 0));
	perl_gpgme_hv_store (hv, "level", 5, newSViv (item->level));

	if (item->type == 1 && item->owner_trust) {
		perl_gpgme_hv_store (hv, "owner_trust", 11, newSVpv (item->owner_trust, 0));
	}

	if (item->validity) {
		perl_gpgme_hv_store (hv, "validity", 8, newSVpv (item->validity, 0));
	}

	if (item->type == 2 && item->name) {
		perl_gpgme_hv_store (hv, "name", 4, newSVpv (item->name, 0));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}

SV *
perl_gpgme_sv_from_status_code (gpgme_status_code_t status) {
	int i;
	SV *ret = NULL;

	for (i = 0; i < sizeof (perl_gpgme_status_code_map) / sizeof (perl_gpgme_status_code_map[0]); i++) {
		perl_gpgme_status_code_map_t map = perl_gpgme_status_code_map[i];

		if (map.status == status) {
			ret = newSVpv (map.string, 0);
			break;
		}
	}

	if (!ret) {
		croak ("unknown status code");
	}

	return ret;
}

SV *
perl_gpgme_genkey_result_to_sv (gpgme_genkey_result_t result) {
	SV *sv;
	HV *hv;

	hv = newHV ();

	perl_gpgme_hv_store (hv, "primary", 7, newSViv (result->primary));
	perl_gpgme_hv_store (hv, "sub", 3, newSViv (result->sub));

	if (result->fpr) {
		perl_gpgme_hv_store (hv, "fpr", 3, newSVpv (result->fpr, 0));
	}

	sv = newRV_noinc ((SV *)hv);
	return sv;
}
