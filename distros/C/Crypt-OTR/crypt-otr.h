
// There is a struct name conflict with perl.h
#define context otr_context
#include <libotr/context.h>
#undef context

#include <libotr/proto.h>
#include <libotr/message.h>
#include <libotr/privkey.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PRIVKEY_FILE_NAME "otr.private_key"
#define STORE_FILE_NAME "otr.fingerprints"

// max message size
const unsigned int CRYPT_OTR_MAX_SIZE = 65535;

typedef struct crypt_otr_user_state* CryptOTRUserState;

struct crypt_otr_user_state {
	OtrlUserState otrl_state;
	char* root;
	char* keyfile;
	char* fprfile;	
	unsigned int max_size;
    unsigned short privkey_loaded;

	CV* inject_cb;
	CV* system_message_cb;
	CV* connected_cb;
	CV* unverified_cb;
	CV* disconnected_cb;
	CV* stillconnected_cb;
	CV* error_cb;
	CV* warning_cb;
	CV* info_cb;
	CV* new_fpr_cb;
	CV* smp_request_cb;
};

typedef enum {
	SMP_PROGRESS,
	SMP_ESTABLISHED,
	SMP_REQUEST_SECRET,
	SMP_REQUEST_SECRET_Q
} SMPNotifyType;

void crypt_otr_store_callback( CV* struct_callback, CV* perl_callback );

char *expand_filename(const char *fname);

void 		crypt_otr_handle_connected(CryptOTRUserState in_state, ConnContext* context);
void 		crypt_otr_handle_trusted_connection( CryptOTRUserState in_state,  char* username );
void 		crypt_otr_handle_unverified_connection( CryptOTRUserState in_state, char* username );
void 		crypt_otr_handle_disconnection( CryptOTRUserState in_state, char* username );
void 		crypt_otr_handle_stillconnected( CryptOTRUserState in_state, char* username );

static int 	crypt_otr_display_otr_message( CryptOTRUserState crypt_state, const char* accountname, const char* protocol, const char* username, const char* message );
static void 	crypt_otr_inject_message( CryptOTRUserState crypt_state, const char* account, const char* protocol, const char* recipient, const char* message );

void crypt_otr_process_receiving( CryptOTRUserState crypt_state, const char* in_accountname, const char* in_protocol, int in_max, 
                                  const char* who, const char* message, SV**, short *out_should_discard );

void crypt_otr_notify( CryptOTRUserState crypt_state, OtrlNotifyLevel level, const char* accountname, const char* protocol, const char* username, const char* title, const char* primary, const char* secondary );

static void 	crypt_otr_message_disconnect( CryptOTRUserState crypt_state, ConnContext* ctx );
ConnContext* 	crypt_otr_get_context( CryptOTRUserState crypt_state, char* accountname, char* protocol, char* username );
void 		crypt_otr_create_privkey( CryptOTRUserState crypt_state, const char *accountname, const char *protocol);
void crypt_otr_load_privkey( CryptOTRUserState in_state, const char* in_account, const char* in_proto, int in_max );

void process_sending_im( char* who, char* message );

void crypt_otr_print_error_code(char* err_string, gcry_error_t err);
void crypt_otr_print_error(char* err_string);

/* Callbacks */
void crypt_otr_new_fingerprint( CryptOTRUserState crypt_state, const char* accountname, const char* protocol, const char* username, unsigned char *fingerprint );
static OtrlPolicy 	policy_cb(void *opdata, ConnContext *context);
static const char *	protocol_name_cb(void *opdata, const char *protocol);
static void 		protocol_name_free_cb(void *opdata, char *protocol_name);
static void 		create_privkey_cb(CryptOTRUserState opdata, const char *accountname,
							   const char *protocol);
static int 		is_logged_in_cb(void *opdata, const char *accountname,
							 const char *protocol, const char *recipient);
static void 		inject_message_cb(CryptOTRUserState opdata, const char *accountname,
							   const char *protocol, const char *recipient, const char *message);
static void 		notify_cb(CryptOTRUserState opdata, OtrlNotifyLevel level,
						const char *accountname, const char *protocol, const char *username,
						const char *title, const char *primary, const char *secondary);
static int 		display_otr_message_cb(CryptOTRUserState opdata, const char *accountname, const char *protocol, const char *username, const char *msg);
static void 		update_context_list_cb(void *opdata);
static void 		confirm_fingerprint_cb(CryptOTRUserState opdata, OtrlUserState us, const char *accountname, const char *protocol, const char *username, unsigned char fingerprint[20]);
static void 		write_fingerprints_cb(CryptOTRUserState opdata);
static void 		gone_secure_cb(CryptOTRUserState opdata, ConnContext *context);
static void 		gone_insecure_cb(CryptOTRUserState opdata, ConnContext *context);
static void 		still_secure_cb(CryptOTRUserState opdata, ConnContext *context, int is_reply);
static void 		log_message_cb(void *opdata, const char *message);
static int 		max_message_size_cb(CryptOTRUserState opdata, ConnContext *context);

typedef enum {
    TRUST_NOT_PRIVATE,
    TRUST_UNVERIFIED,
    TRUST_PRIVATE,
    TRUST_FINISHED
} TrustLevel;

int crypt_otr_context_to_trust(ConnContext *context);


/* Accessors */

CryptOTRUserState get_state( SV* sv_state );


#include "crypt-otr-utils.c"
#include "crypt-otr-members.c"
#include "crypt-otr-callbacks.c"
#include "crypt-otr-private.c"
#include "crypt-otr-perl.c"
