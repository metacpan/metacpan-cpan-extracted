#include "perl_gpgme.h"

MODULE = Crypt::GpgME::Key	PACKAGE = Crypt::GpgME::Key

PROTOTYPES: ENABLE

void
DESTROY (key)
		gpgme_key_t key
	CODE:
		gpgme_key_unref (key);

unsigned int
revoked (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->revoked;
	OUTPUT:
		RETVAL

unsigned int
expired (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->expired;
	OUTPUT:
		RETVAL

unsigned int
disabled (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->disabled;
	OUTPUT:
		RETVAL

unsigned int
invalid (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->invalid;
	OUTPUT:
		RETVAL

unsigned int
can_encrypt (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->can_encrypt;
	OUTPUT:
		RETVAL

unsigned int
can_sign (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->can_sign;
	OUTPUT:
		RETVAL

unsigned int
can_certify (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->can_certify;
	OUTPUT:
		RETVAL

unsigned int
secret (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->secret;
	OUTPUT:
		RETVAL

unsigned int
can_authenticate (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->can_authenticate;
	OUTPUT:
		RETVAL

unsigned int
is_qualified (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->is_qualified;
	OUTPUT:
		RETVAL

gpgme_protocol_t
protocol (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->protocol;
	OUTPUT:
		RETVAL

#TODO: croak if field has no meaning with the current protocol?

char *
issuer_serial (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->issuer_serial;
	OUTPUT:
		RETVAL

char *
issuer_name (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->issuer_name;
	OUTPUT:
		RETVAL

char *
chain_id (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->chain_id;
	OUTPUT:
		RETVAL

gpgme_validity_t
owner_trust (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->owner_trust;
	OUTPUT:
		RETVAL

void
subkeys (key)
		gpgme_key_t key
	PREINIT:
		gpgme_subkey_t i;
	PPCODE:
		for (i = key->subkeys; i != NULL; i = i->next) {
			XPUSHs (sv_2mortal (perl_gpgme_hashref_from_subkey (i)));
		}

void
uids (key)
		gpgme_key_t key
	PREINIT:
		gpgme_user_id_t i;
	PPCODE:
		for (i = key->uids; i != NULL; i = i->next) {
			XPUSHs (sv_2mortal (perl_gpgme_hashref_from_uid (i)));
		}

gpgme_keylist_mode_t
keylist_mode (key)
		gpgme_key_t key
	CODE:
		RETVAL = key->keylist_mode;
	OUTPUT:
		RETVAL
