
////////////////////////////////////////////////
// PRIVATE NON-CALLBACK, NON-PERL FUNCTIONS
///////////////////////////////////////////////

static void
crypt_otr_inject_message( CryptOTRUserState crypt_state, const char* account, const char* protocol, const char* recipient, const char* message )
{	
  if (! crypt_state->inject_cb) return;

	dSP;
		
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( account, 0 )));
	XPUSHs( sv_2mortal( newSVpv( protocol, 0 )));
	XPUSHs( sv_2mortal( newSVpv( recipient, 0 )));
	XPUSHs( sv_2mortal( newSVpv( message, 0 )));
	PUTBACK;

	call_sv( crypt_state->inject_cb, G_DISCARD );
	
	FREETMPS;
	LEAVE;
}

static int 
crypt_otr_display_otr_message( CryptOTRUserState crypt_state, const char* accountname, 
						 const char* protocol, const char* username, 
						 const char* message )
{
  if (! crypt_state->system_message_cb) return;

	dSP;
	int num_items_on_stack;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( accountname, 0 )));
	XPUSHs( sv_2mortal( newSVpv( protocol, 0 )));
	XPUSHs( sv_2mortal( newSVpv( username, 0 )));
	XPUSHs( sv_2mortal( newSVpv( message, 0 )));
	PUTBACK;

	num_items_on_stack = call_sv( crypt_state->system_message_cb, G_DISCARD );
	
	FREETMPS;
	LEAVE;
	
	return num_items_on_stack == 0 ? 1 : 0;
}


void crypt_otr_notify( CryptOTRUserState crypt_state, OtrlNotifyLevel level, 
				   const char* accountname, const char* protocol, const char* username, 
				   const char* title, const char* primary, const char* secondary )
{
	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( accountname, 0 ))); 
	XPUSHs( sv_2mortal( newSVpv( protocol, 0 )));
	XPUSHs( sv_2mortal( newSVpv( username, 0 )));
	XPUSHs( sv_2mortal( newSVpv( title, 0 )));
	XPUSHs( sv_2mortal( newSVpv( primary, 0 )));
	XPUSHs( sv_2mortal( newSVpv( secondary, 0 )));
	PUTBACK;

	switch (level) {
	case OTRL_NOTIFY_ERROR:
      if ( crypt_state->error_cb )
		call_sv( crypt_state->error_cb, G_DISCARD );
      break;
	case OTRL_NOTIFY_WARNING:
      if ( crypt_state->warning_cb )
        call_sv( crypt_state->warning_cb, G_DISCARD );
      break;
	case OTRL_NOTIFY_INFO:
      if ( crypt_state->info_cb )
		call_sv( crypt_state->info_cb, G_DISCARD );
      break;
	}
	
	FREETMPS;
	LEAVE;
}


void crypt_otr_notify_new_fingerprint( CryptOTRUserState crypt_state, const char* accountname, const char* protocol, const char* username, unsigned char fingerprint[20] )
{
  if (! crypt_state->new_fpr_cb) return;

	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( accountname, 0 )));
	XPUSHs( sv_2mortal( newSVpv( protocol, 0 )));
	XPUSHs( sv_2mortal( newSVpv( username, 0 )));
	XPUSHs( sv_2mortal( newSVpv( fingerprint, 20 )));
	PUTBACK;

	call_sv( crypt_state->new_fpr_cb, G_DISCARD );
	
	FREETMPS;
	LEAVE;
}

/* This function notifies of both authentication questions
 * and requests.
 */
void crypt_otr_smp_notify( CryptOTRUserState crypt_state, SMPNotifyType notify, 
					  char* protocol, char* username,
					  char* question )
{
  if (! crypt_state->smp_request_cb) return;

	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( protocol, 0 )));
	XPUSHs( sv_2mortal( newSVpv( username, 0 )));
	XPUSHs( sv_2mortal( newSVpv( question, 0 )));
	PUTBACK;

	call_sv( crypt_state->smp_request_cb, G_DISCARD );
	
	FREETMPS;
	LEAVE;
}

void crypt_otr_handle_connected(CryptOTRUserState crypt_state, ConnContext* context)
{	
	char* username = context->username;
	TrustLevel level;

	level = crypt_otr_context_to_trust(context);

	switch(level) {
	case TRUST_PRIVATE:
		crypt_otr_handle_trusted_connection( crypt_state, username );
		break;

	case TRUST_UNVERIFIED:
		crypt_otr_handle_unverified_connection( crypt_state, username );
		break;

	default:
		/* This last case should never happen, since we know
		 * we're in ENCRYPTED. */
		perror( "ERROR -- Unencrypted conversation started\n" );
		break;
	}
}


void crypt_otr_callback_one_string( CV* callback_sub, char* username )
{
  if (! callback_sub)
    return;

	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs( sv_2mortal( newSVpv( username, 0 ))); 
	PUTBACK;

	call_sv( callback_sub, G_DISCARD );
	
	FREETMPS;
	LEAVE;
}

/* Send the username, basically saying that a trusted conversation has been started with username */
void crypt_otr_handle_trusted_connection( CryptOTRUserState crypt_state, char* username )
{
	crypt_otr_callback_one_string( crypt_state->connected_cb, username );
} 

/* Send the username, basically saying that an unverified conversation has been started with username */
void crypt_otr_handle_unverified_connection( CryptOTRUserState crypt_state, char* username )
{
	crypt_otr_callback_one_string( crypt_state->unverified_cb, username );
}

/* Send the username, saying that a conversation has ended  with username */
void crypt_otr_handle_disconnection( CryptOTRUserState crypt_state, char* username )
{
	crypt_otr_callback_one_string( crypt_state->disconnected_cb, username );
}

/* Send the username, saying that is still connected  with username */
void crypt_otr_handle_stillconnected( CryptOTRUserState crypt_state, char* username )
{
	crypt_otr_callback_one_string( crypt_state->stillconnected_cb, username );
}

/* Find the trust level of the conversation, given its context */
int crypt_otr_context_to_trust(ConnContext *context)
{
  TrustLevel level = TRUST_NOT_PRIVATE;

  if (context && context->msgstate == OTRL_MSGSTATE_ENCRYPTED) {
    if (context->active_fingerprint->trust &&
        context->active_fingerprint->trust[0] != '\0') {
	    level = TRUST_PRIVATE;
    } else {
	    level = TRUST_UNVERIFIED;
    }
  } else if (context && context->msgstate == OTRL_MSGSTATE_FINISHED) {
    level = TRUST_FINISHED;
  }

  return level;
}

/* Generate a private key for the given accountname/protocol */
void crypt_otr_create_privkey( CryptOTRUserState crypt_state, const char* accountname, const char* protocol  )						
{
  int key_error;
	OtrlUserState userstate = crypt_state->otrl_state;
	char* keyfile = crypt_state->keyfile;	

	printf( "Generating new OTR key for %s.\nThis may take a while... (like several minutes srsly)\n", accountname);

	key_error = otrl_privkey_generate( userstate, keyfile, accountname, protocol );

	if( key_error ) {
		printf("***********************************\n");
		printf("OTR key generation failed!  Please ensure the following path is writable: %s\n", keyfile);
		printf("***********************************\n");
	}
	else {
		printf("OTR key generated.\n");
	}   
}

 
void crypt_otr_startstop( CryptOTRUserState crypt_state, char* accountname, char* protocol, char* username, int start )
{	
	char* msg = NULL;
	ConnContext* ctx = crypt_otr_get_context( crypt_state, accountname, protocol, username );
	
	OtrlUserState userstate = crypt_state->otrl_state;

	if( !userstate || !ctx )
		return;
	
	/* Let the user know that the conversation has been disconnected */
	if( start && ctx->msgstate == OTRL_MSGSTATE_ENCRYPTED )
		crypt_otr_message_disconnect( crypt_state, ctx );

	if( start ) {
		OtrlPolicy policy = policy_cb( NULL, ctx );

		// Todo: check policy here to make sure it is set to encrypted
		//       now, policy doesn't mean anything.
			
		msg = otrl_proto_default_query_msg( ctx->accountname, policy );

		inject_message_cb( crypt_state, ctx->accountname, ctx->protocol, ctx->username, msg );
	
		free( msg );
	}
	else
		crypt_otr_message_disconnect( crypt_state, ctx );
}

static void crypt_otr_message_disconnect( CryptOTRUserState crypt_state,  ConnContext* ctx )
{	
	OtrlUserState userstate = crypt_state->otrl_state;
	
	if( ctx->msgstate == OTRL_MSGSTATE_ENCRYPTED )
		gone_insecure_cb( crypt_state, ctx );

	otrl_message_disconnect( userstate, &otr_ops, crypt_state, ctx->accountname, ctx->protocol, ctx->username );
}

/* Looks up the context
 * Accountname = you
 * Username = them  */
ConnContext* crypt_otr_get_context( CryptOTRUserState crypt_state, char* accountname, char* protocol, char* username )
{
	int null = 0;
	ConnContext* ctx;
	OtrlUserState userstate = crypt_state->otrl_state;
	
	/* Finds the context.  The fifth parameter is true, so it creates a context if one didn't exist already. */
	/* username = them
	 * accountname = your accountname
	 */
	ctx = otrl_context_find( userstate, username, accountname, protocol, 1, &null, NULL, NULL );

	return ctx;
}

void crypt_otr_new_fingerprint( CryptOTRUserState crypt_state, const char* accountname, const char* protocol, const char* username, unsigned char *fingerprint )
{
	if( crypt_state->new_fpr_cb )
		crypt_otr_notify_new_fingerprint( crypt_state, accountname, protocol,
                                      username, fingerprint );
} 


void crypt_otr_notify_socialist_millionaires_status( CryptOTRUserState crypt_state, char* accountname, char* protocol,
                                                     ConnContext* context,
                                                     int progress )
{
	if( progress > 2 ){
		TrustLevel level = crypt_otr_context_to_trust(context);

		if( level == TRUST_PRIVATE ){
			crypt_otr_handle_trusted_connection( crypt_state, context->username );
		}
	}
	
	char* prog = malloc( strlen("SMP progress level = ") + 2 );
	sprintf( prog, "SMP progress level = %i", progress);	

	crypt_otr_notify( crypt_state, OTRL_NOTIFY_INFO,
                    accountname, protocol, context->username,
                    "Socialist Millionaires Protocol", "Status Update", prog);

	free( prog );
}


void crypt_otr_ask_socialist_millionaires( CryptOTRUserState crypt_state, char* accountname, char* protocol,
								   ConnContext* context, char* question, int responder)
{
	if( context == NULL ) return;
	
	if( responder && question ){
		crypt_otr_smp_notify( crypt_state, SMP_REQUEST_SECRET_Q,
						  protocol, context->username, question);
	} else {
		crypt_otr_smp_notify( crypt_state, SMP_REQUEST_SECRET,
						  protocol, context->username, NULL );
	}
} 


void crypt_otr_abort_smp_context( CryptOTRUserState crypt_state, ConnContext* context )
{
	otrl_message_abort_smp(crypt_state->otrl_state, &otr_ops, crypt_state, context);
}


CryptOTRUserState crypt_otr_create_new_userstate(){
	CryptOTRUserState crypt_state  = malloc( sizeof( struct crypt_otr_user_state ) );

  crypt_state->privkey_loaded = 0;
	crypt_state->otrl_state = NULL;
	crypt_state->root = NULL;
	crypt_state->keyfile = NULL;
	crypt_state->fprfile = NULL;
	crypt_state->max_size = CRYPT_OTR_MAX_SIZE;
	
	crypt_state->inject_cb = NULL;
	crypt_state->system_message_cb = NULL;
	crypt_state->connected_cb = NULL;
	crypt_state->unverified_cb = NULL;
	crypt_state->disconnected_cb = NULL;
	crypt_state->stillconnected_cb = NULL;
	crypt_state->error_cb = NULL;
	crypt_state->warning_cb = NULL;
	crypt_state->info_cb = NULL;
	crypt_state->new_fpr_cb = NULL;
	crypt_state->smp_request_cb = NULL;

	return crypt_state;
}


void crypt_otr_print_error_code(char* err_string, gcry_error_t err){
  printf("\n******************\nOTR ERROR IN: %s (%d)\n******************\n\n", err_string, gcry_err_code(err));
}

void crypt_otr_print_error(char* err_string){
  printf("\n******************\nOTR UNKNOWN ERROR IN: %s\n******************\n\n", err_string);
}
