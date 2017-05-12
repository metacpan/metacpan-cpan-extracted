#include <gcrypt.h>

/////////////////////////////////////////
//  CRYPT-OTR PERL FUNCTIONS
////////////////////////////////////////


int crypt_otr_init(  )
{		
	OTRL_INIT;
	/* It's ambiguous whether or not you need to include the following
   * commented line, but the plugin works with it commented out,
   * and the pidgin OTR plugin doesn't call it anywhere. */
	//otrl_sm_init();
}

CryptOTRUserState crypt_otr_create_user( char* in_root, char* account_name, char* protocol )
{
	char* temp_keyfile;
	char* temp_fingerprintfile;
	CryptOTRUserState crypt_state = crypt_otr_create_new_userstate();

	crypt_state->root = strdup( in_root );
	crypt_state->otrl_state = otrl_userstate_create();	
	
	temp_keyfile = malloc( (strlen(in_root) + 
                                strlen(PRIVKEY_FILE_NAME) +
                                strlen(account_name) +
                                strlen(protocol) +
                                3 + 1)*sizeof(char) ); // +1 for null termination

	temp_fingerprintfile =  malloc( (strlen(in_root) + 
                                         strlen(STORE_FILE_NAME) +
                                         strlen(account_name) +
                                         strlen(protocol) + 
                                         3 + 1)*sizeof(char) ); // +1 for null termination
		
	sprintf( temp_keyfile, "%s/%s-%s-%s", in_root, PRIVKEY_FILE_NAME, account_name, protocol);
	sprintf( temp_fingerprintfile, "%s/%s-%s-%s", in_root, STORE_FILE_NAME, account_name, protocol);
				
	crypt_state->keyfile = temp_keyfile;
	crypt_state->fprfile = temp_fingerprintfile;
	
	return crypt_state;
}

/* load private key from file, or create new one
 * (this may block for several minutes while generating a key) */
void crypt_otr_load_privkey( CryptOTRUserState in_state, const char* in_account, const char* in_proto, int in_max ) {
  if (in_state->privkey_loaded)
    return;

  in_state->privkey_loaded = 1;

  gcry_error_t res = otrl_privkey_read( in_state->otrl_state, in_state->keyfile );

  if( res || ! otrl_privkey_find(in_state->otrl_state, in_account, in_proto) ) {
    printf( "Could not read OTR key from %s\n", in_state->keyfile);
    crypt_otr_create_privkey( in_state, in_account, in_proto );
  }
  else {
    printf( "Loaded private key file from %s\n", in_state->keyfile );
  }
}

void crypt_otr_establish( CryptOTRUserState in_state, char* in_account, char* in_proto, int in_max, 
					 char* in_username ) {		
  
  crypt_otr_load_privkey( in_state, in_account, in_proto, in_max );
  crypt_otr_startstop(in_state, in_account, in_proto, in_username, 1 );
}


void crypt_otr_disconnect( CryptOTRUserState in_state, char* in_account, char* in_proto, int in_max, 
					  char* in_username )
{
	crypt_otr_startstop(in_state, in_account, in_proto, in_username, 0 );
}


SV* crypt_otr_process_sending( CryptOTRUserState crypt_state, char* in_account, char* in_proto, int in_max, 
						 char* who, char* sv_message )
{
	char* newmessage = NULL;
	char* message = strdup( sv_message );
	OtrlUserState userstate = crypt_state->otrl_state;
	int err;
		
	if( !who || !message )
		return newSVpv( NULL, 0 );

	err = otrl_message_sending( userstate, &otr_ops, crypt_state, 
						   in_account, in_proto, who, 
						   message, NULL, &newmessage, NULL, NULL);

	if( err && (newmessage == NULL) ) {
		/* Be *sure* not to send out plaintext */
		char* ourm = strdup( "" );
		free( message );
		message = ourm;
	} else if ( newmessage ) {
		/* Fragment the message if necessary, and send all but the last
		 * fragment over the network.  The client will send the last
		 * fragment for us. */
		ConnContext* context = otrl_context_find( userstate, who, in_account, 
										  in_proto, 0, NULL, NULL, NULL );
		
		free( message );
		message = NULL;
		err = otrl_message_fragment_and_send(&otr_ops, crypt_state, context,
									  newmessage, OTRL_FRAGMENT_SEND_ALL_BUT_LAST, &message);

		// Checking for errors
		if (err) {
            crypt_otr_print_error_code("fragmenting and sending message", err);
		}
		
		otrl_message_free(newmessage);
	}

	return newSVpv( message, 0 );
}

/* returns plaintext if successful.
 * returns status boolean in should_discard.
 * if should_discard is true, this was an internal OTR protocol
 *     message and should be ignored by the application.
 */
void crypt_otr_process_receiving( CryptOTRUserState crypt_state, const char* in_accountname,
                                  const char* in_protocol, int in_max, const char* who,
                                  const char* message, SV** out_plaintext, short *out_should_discard )
{
  SV* ret;
  char* ret_message = NULL;
	OtrlTLV* tlvs = NULL;
	OtrlTLV* tlv = NULL;
	OtrlUserState userstate = crypt_state->otrl_state;
	ConnContext* context;
	NextExpectedSMP nextMsg;

  *out_should_discard = 0;

	if( !who || !message ) {
    *out_plaintext = newSVpvn(NULL, 0);
    return;
  }

	*out_should_discard = otrl_message_receiving( userstate, &otr_ops, crypt_state, 
                                                in_accountname, in_protocol, who, message,
                                                &ret_message, &tlvs, NULL, NULL );

	tlv = otrl_tlv_find( tlvs, OTRL_TLV_DISCONNECTED );
	if( tlv ) {
		/* Notify the user that the other side disconnected */
		crypt_otr_handle_disconnection(crypt_state, who);
	}

	/* Keep track of our current progress in the Socialist Millionaires'
	 * Protocol. */
	context = otrl_context_find( userstate, who, 
                               in_accountname, in_protocol, 0, NULL, NULL, NULL );

	if( context ) {
		nextMsg = context->smstate->nextExpected;

		if( context->smstate->sm_prog_state == OTRL_SMP_PROG_CHEATED ) {
			crypt_otr_abort_smp_context( crypt_state, context );
			context->smstate->nextExpected = OTRL_SMP_EXPECT1;
			context->smstate->sm_prog_state = OTRL_SMP_PROG_OK;
		} else {
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP1Q);
			if (tlv) {
				if (nextMsg != OTRL_SMP_EXPECT1)
					crypt_otr_abort_smp_context( crypt_state, context);
				else {
					char *question = (char *)tlv->data;
					char *eoq = memchr(question, '\0', tlv->len);
					if (eoq) {
						crypt_otr_ask_socialist_millionaires(crypt_state, in_accountname, in_protocol,
                                                 context, question, 1);
					}
				}
			}
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP1);
			if (tlv) {
				if (nextMsg != OTRL_SMP_EXPECT1)
					crypt_otr_abort_smp_context(crypt_state, context);
				else {
					crypt_otr_ask_socialist_millionaires(crypt_state, in_accountname, in_protocol,
                                               context, NULL, 1 );
				}
			}
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP2);
			if (tlv) {
				if (nextMsg != OTRL_SMP_EXPECT2)
					crypt_otr_abort_smp_context(crypt_state, context);
				else {
					crypt_otr_notify_socialist_millionaires_status( crypt_state, in_accountname, in_protocol,
                                                          context, 2 );
					context->smstate->nextExpected = OTRL_SMP_EXPECT4;
				}
			}
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP3);
			if (tlv) {
				if (nextMsg != OTRL_SMP_EXPECT3)
					crypt_otr_abort_smp_context(crypt_state, context);
				else {
					crypt_otr_notify_socialist_millionaires_status( crypt_state, in_accountname, in_protocol, 
                                                          context, 3 );
					context->smstate->nextExpected = OTRL_SMP_EXPECT1;
				}
			}
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP4);
			if (tlv) {
				if (nextMsg != OTRL_SMP_EXPECT4)
					crypt_otr_abort_smp_context(crypt_state, context);
				else {
					crypt_otr_notify_socialist_millionaires_status( crypt_state, in_accountname, in_protocol,
                                                          context, 3 );
					context->smstate->nextExpected = OTRL_SMP_EXPECT1;
				}
			}
			tlv = otrl_tlv_find(tlvs, OTRL_TLV_SMP_ABORT);
			if (tlv) {				
				context->smstate->nextExpected = OTRL_SMP_EXPECT1;
			}
		}
	}

	otrl_tlv_free(tlvs);

  /* copy message */
	ret = newSVpv(ret_message, 0);
  *out_plaintext = ret;

  /* we are responsible for freeing ret_message */
  if (ret_message) otrl_message_free(ret_message);
}

/* Start the Socialist Millionaires' Protocol over the current connection,
 * using the given initial secret, and optionally a question to pass to
 * the buddy. */
void crypt_otr_start_smp( CryptOTRUserState crypt_state, char* in_accountname, char* in_protocol, int in_max,
					 char* who, char* secret )
{
	ConnContext* ctx = crypt_otr_get_context( crypt_state, in_accountname, in_protocol, who );

	otrl_message_initiate_smp(crypt_state->otrl_state, &otr_ops, crypt_state,
						 ctx, secret, strlen(secret) );
}


/* Start the Socialist Millionaires' Protocol over the current connection,
 * using the given initial secret, and optionally a question to pass to
 * the buddy. */
void crypt_otr_start_smp_q( CryptOTRUserState crypt_state, char* in_accountname, char* in_protocol, int in_max,
					 char* who, char* secret, char* question )
{
	ConnContext* ctx = crypt_otr_get_context( crypt_state, in_accountname, in_protocol, who );

	otrl_message_initiate_smp_q(crypt_state->otrl_state, &otr_ops, crypt_state,
						   ctx, question, secret, strlen(secret));
}

/* Continue the Socialist Millionaires' Protocol over the current connection,
 * using the given initial secret (ie finish step 2). */
void crypt_otr_continue_smp( CryptOTRUserState crypt_state, char* in_accountname, char* in_protocol, int in_max,
					    char* who, const unsigned char *secret )
{
	ConnContext* ctx = crypt_otr_get_context( crypt_state, in_accountname, in_protocol, who );

	otrl_message_respond_smp(crypt_state->otrl_state, &otr_ops, crypt_state,
						ctx, secret, strlen(secret) );
}

/* Abort the SMP protocol.  Used when malformed or unexpected messages
 * are received. */
void crypt_otr_abort_smp( CryptOTRUserState crypt_state, char* in_accountname, char* in_protocol, int in_max,
					 char* who )
{
	ConnContext* ctx = crypt_otr_get_context( crypt_state, in_accountname, in_protocol, who );

	otrl_message_abort_smp(crypt_state->otrl_state, &otr_ops, crypt_state, ctx);
}


////////////////////////////////////////////////
// ACCESSORS
///////////////////////////////////////////////


SV* crypt_otr_get_keyfile( CryptOTRUserState in_state ) { return newSVpv( in_state->keyfile, 0 ); }
SV* crypt_otr_get_fprfile( CryptOTRUserState in_state ) { return newSVpv( in_state->fprfile, 0 ); }

OtrlPrivKey* crypt_otr_get_privkey( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  crypt_otr_load_privkey( in_state, account, proto, maxsize );  // try to ensure a privkey is loaded
  return otrl_privkey_find( in_state->otrl_state, account, proto );
}

char* crypt_otr_get_pubkey_data( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  OtrlPrivKey* privkey = crypt_otr_get_privkey(in_state, account, proto, maxsize);
  return privkey->pubkey_data;
}
size_t crypt_otr_get_pubkey_size( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  OtrlPrivKey* privkey = crypt_otr_get_privkey(in_state, account, proto, maxsize);
  return privkey->pubkey_datalen;
}
unsigned short crypt_otr_get_pubkey_type( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  OtrlPrivKey* privkey = crypt_otr_get_privkey(in_state, account, proto, maxsize);
  return privkey->pubkey_type;
}

SV* crypt_otr_get_privkey_fingerprint( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
	
	char* fpr_ptr;
	char fingerprint[45];
	
	printf("About to call otrl_privkey_fingerprint\n");
	fpr_ptr = otrl_privkey_fingerprint(in_state->otrl_state, fingerprint, account, proto);
	printf("Done calling otrl_privkey_fingerprint\n");
	
    if (fpr_ptr) {
      SV *sig_sv = newSVpvn(fingerprint, 0);
      return sig_sv;
	}
	
	crypt_otr_print_error("Getting fingerprint");
	return newSVpvn(NULL, 0);
}

SV* crypt_otr_get_privkey_fingerprint_raw( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  char* fpr_ptr;
  char hash[20];

  fpr_ptr = otrl_privkey_fingerprint_raw(in_state->otrl_state, hash, account, proto);

  if (fpr_ptr){
    SV *sig_sv = newSVpvn(hash, 0);
    return sig_sv;
  } 

  crypt_otr_print_error("Getting fingerprint raw");

  return newSVpvn(NULL, 0);
}

/* Read the fingerprint store from a file on disk into the 
 * OtrlUserState stored in given CryptOTRUserState
 */
int crypt_otr_read_fingerprints( CryptOTRUserState in_state, char* account, char* proto, int maxsize, char* file_path) {
	return otrl_privkey_read_fingerprints( in_state->otrl_state, file_path, NULL, NULL);
}

/* Write the fingerprint store from a given CryptOTRUserState OtrUserState to a file on disk. */
int crypt_otr_write_fingerprints( CryptOTRUserState in_state, char* account, char* proto, int maxsize, char* file_path) {
	return otrl_privkey_write_fingerprints( in_state->otrl_state, file_path);
}

/* Forget all private keys for a given UserState */
void crypt_otr_forget_all( CryptOTRUserState in_state, char* account, char* proto, int maxsize) {
	otrl_privkey_forget_all(in_state->otrl_state);
}

////////////////////////////////////////////////
// SIGNING
///////////////////////////////////////////////

// would be nice to make this take a scalarref instead of a char*
SV* crypt_otr_sign( CryptOTRUserState in_state, char *account, char *proto, int maxsize, char *msghash ) {

	OtrlPrivKey *privkey = crypt_otr_get_privkey( in_state, account, proto, maxsize );
	if (! privkey) {
		perror("Could not find privkey\n");
		return NULL;
	}

	unsigned char *sig;
	size_t siglen;
	gcry_error_t sign_error;
	SV *sig_sv;

	sign_error = otrl_privkey_sign(&sig, &siglen, privkey, msghash, strlen(msghash));

	if (sign_error){
		// There has to be a better way to pass an error,
		// though string equality checking seems to be broken for the strings
		// passed to Perl through XS, oh well
    crypt_otr_print_error_code("Signing Data", sign_error);
	} else {
		// copy result, make SV
		sig_sv = newSVpvn(sig, siglen);
	}

	// Debugging printout
	//printf("\nSig:\n-->%s<--\n\n", sig);
	//printf("Sig length = %u\n", strlen(sig));
	//printf("Msg length = %u\n", strlen(msghash));

	// we are responsible for freeing the signature
	free(sig);

	return sig_sv;
}

SV* crypt_otr_get_pubkey_str( CryptOTRUserState in_state, char *account, char *proto, int maxsize ) {
  OtrlPrivKey *privkey = crypt_otr_get_privkey( in_state, account, proto, maxsize );
  SV *privkey_sv = newSVpvn(privkey->pubkey_data, privkey->pubkey_datalen);
  return privkey_sv;
}

unsigned int crypt_otr_verify( unsigned char *msghash, unsigned char *sig, unsigned char *pubkey_data,
                               size_t pubkey_length, unsigned short pubkey_type) {
	// Debugging printout
	// Checking to see that the signature didn't get corrupted from perl to c
	//printf("\nSig:\n-->%s<--\n\n", sig);
	// Checking to make sure this is 0, the only type 
	//printf("Privkey type:\n-->%u<--\n", pubkey_type);
	//printf("Sig length = %u\n", strlen(sig));
	//printf("Msg length = %u\n", strlen(msghash));

	// create s-expression object representing the public key
	gcry_sexp_t pubkey;

	gcry_sexp_new(&pubkey, pubkey_data, pubkey_length, 1);

	gcry_error_t err = otrl_privkey_verify( sig, strlen(sig), pubkey_type, pubkey, msghash, strlen(msghash) );

	if (err){
        crypt_otr_print_error_code("Verifying data", err);
	}
	
	gcry_sexp_release(pubkey);

	//  printf("type: %d err: %d, msg: %s\n", pubkey_type, err, gcry_strerror(err));
	return err == 0;
}


////////////////////////////////////////////////
// CLEANUP
///////////////////////////////////////////////


void crypt_otr_cleanup( CryptOTRUserState crypt_state ){
  if (crypt_state->inject_cb)
    SvREFCNT_dec(crypt_state->inject_cb);
  if (crypt_state->system_message_cb)
    SvREFCNT_dec(crypt_state->system_message_cb);
  if (crypt_state->connected_cb)
    SvREFCNT_dec(crypt_state->connected_cb);
  if (crypt_state->unverified_cb)
    SvREFCNT_dec(crypt_state->unverified_cb);
  if (crypt_state->disconnected_cb)
    SvREFCNT_dec(crypt_state->disconnected_cb);
  if (crypt_state->stillconnected_cb)
    SvREFCNT_dec(crypt_state->stillconnected_cb);
  if (crypt_state->error_cb)
    SvREFCNT_dec(crypt_state->error_cb);
  if (crypt_state->warning_cb)
    SvREFCNT_dec(crypt_state->warning_cb);
  if (crypt_state->info_cb)
    SvREFCNT_dec(crypt_state->info_cb);
  if (crypt_state->new_fpr_cb)
    SvREFCNT_dec(crypt_state->new_fpr_cb);
  if (crypt_state->smp_request_cb)
    SvREFCNT_dec(crypt_state->smp_request_cb);

  if (crypt_state->root)
    free( crypt_state->root );

  if (crypt_state->otrl_state)
    otrl_userstate_free( crypt_state->otrl_state );

  free( crypt_state->keyfile );
  free( crypt_state->fprfile );
  free( crypt_state );
}
