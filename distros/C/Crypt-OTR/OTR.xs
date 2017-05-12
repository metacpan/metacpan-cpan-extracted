#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "crypt-otr.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = Crypt::OTR		PACKAGE = Crypt::OTR		

INCLUDE: const-xs.inc


void
crypt_otr_init( )

void
crypt_otr_cleanup(  IN CryptOTRUserState perl_state )

CryptOTRUserState 
crypt_otr_create_user( IN char* perl_root, IN char* perl_account, IN char* perl_proto  )
	OUTPUT:
		RETVAL

void 
crypt_otr_load_privkey( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )

void 
crypt_otr_establish( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_username )

void
crypt_otr_disconnect( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_username )

SV*
crypt_otr_process_sending( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_username, IN char* perl_message )	
	OUTPUT:
		RETVAL

void
crypt_otr_process_receiving( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_who, IN char* perl_message, OUTLIST SV* out_plaintext, OUTLIST short out_should_discard )

void
crypt_otr_start_smp( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_who, IN char* perl_secret )

void
crypt_otr_start_smp_q( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_who, IN char* perl_secret, IN char* perl_question )

void
crypt_otr_continue_smp( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_who, IN char* perl_secret )

void
crypt_otr_abort_smp( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_who )


void 
crypt_otr_set_inject_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_system_message_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_connected_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_unverified_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_stillconnected_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_disconnected_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_error_cb( IN CryptOTRUserState perl_state, IN CV* perl_set ) 

void 
crypt_otr_set_warning_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_info_cb( IN CryptOTRUserState perl_state, IN CV* perl_set )

void 
crypt_otr_set_new_fpr_cb( IN CryptOTRUserState perl_state, IN CV* perl_set ) 

void 
crypt_otr_set_smp_request_cb( IN CryptOTRUserState perl_state, IN CV* perl_set ) 

SV*
crypt_otr_get_keyfile( IN CryptOTRUserState perl_state )
	OUTPUT:
		RETVAL

SV*
crypt_otr_get_fprfile( IN CryptOTRUserState perl_state )
	OUTPUT:
		RETVAL

SV*
crypt_otr_sign( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* perl_msg_hash )
	OUTPUT:

		RETVAL

unsigned short
crypt_otr_verify( IN char* perl_msg_hash, IN char* perl_sig, IN char* pubkey_data, IN unsigned int pubkey_size, IN unsigned short pubkey_type )
	OUTPUT:
		RETVAL

SV*
crypt_otr_get_pubkey_str( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
        OUTPUT:
                RETVAL

char*
crypt_otr_get_pubkey_data( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
        OUTPUT:
                RETVAL

unsigned short
crypt_otr_get_pubkey_type( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
        OUTPUT:
                RETVAL

unsigned int
crypt_otr_get_pubkey_size( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
        OUTPUT:
                RETVAL

char*
crypt_otr_get_privkey_fingerprint( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
	OUTPUT:
		RETVAL

char*
crypt_otr_get_privkey_fingerprint_raw( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max )
	OUTPUT:
		RETVAL

int
crypt_otr_read_fingerprints( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* file_path)
	OUTPUT:
		RETVAL

int
crypt_otr_write_fingerprints( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max, IN char* file_path)
	OUTPUT:
		RETVAL

void
crypt_otr_forget_all( IN CryptOTRUserState perl_state, IN char* perl_account, IN char* perl_proto, IN int perl_max)



