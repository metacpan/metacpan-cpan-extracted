

///////////////////////////////////
// CALLBACKS
//////////////////////////////////

/* Return the OTR policy for the given context. */
static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
	return OTRL_POLICY_DEFAULT; 
}

static const char *protocol_name_cb(void *opdata, const char *protocol)
{
	return strdup(protocol);
}

static void protocol_name_free_cb(void *opdata, char *protocol_name)
{
	free( protocol_name );
}

static void create_privkey_cb(CryptOTRUserState opdata, const char *accountname,
	const char *protocol)
{
  /* loads a private key if one is present, otherwise it will
   * generate a new key */
  crypt_otr_load_privkey(opdata, accountname, protocol, 0);
}

/* Report whether you think the given user is online.  Return 1 if
 * you think he is, 0 if you think he isn't, -1 if you're not sure.
 * If you return 1, messages such as heartbeats or other
 * notifications may be sent to the user, which could result in "not
 * logged in" errors if you're wrong. */
static int is_logged_in_cb(void *opdata, const char *accountname,
	const char *protocol, const char *recipient)
{
	return 1; // Maybe -1, though for now we will always assume there is a proper connection
}

/* Send the given IM to the given recipient from the given
 * accountname/protocol. */
static void inject_message_cb( CryptOTRUserState opdata, const char *accountname,
	const char *protocol, const char *recipient, const char *message)
{    
	crypt_otr_inject_message(opdata, accountname, protocol, recipient, message);
}


/* Display a notification message for a particular accountname /
 * protocol / username conversation. */
static void notify_cb(CryptOTRUserState opdata, OtrlNotifyLevel level,
				  const char *accountname, const char *protocol, const char *username,
				  const char *title, const char *primary, const char *secondary)
{
	crypt_otr_notify( opdata, level, accountname, protocol, username, title, primary, secondary );
}


/* Display an OTR control message for a particular accountname /
 * protocol / username conversation.  Return 0 if you are able to
 * successfully display it.  If you return non-0 (or if this
 * function is NULL), the control message will be displayed inline,
 * as a received message, or else by using the above notify()
 * callback. */
static int display_otr_message_cb(CryptOTRUserState opdata, const char *accountname,
						    const char *protocol, const char *username, const char *msg)
{
	return crypt_otr_display_otr_message(opdata, accountname, protocol, username, msg);
}

/* When the list of ConnContexts changes (including a change in
 * state), this is called so the UI can be updated. */
static void update_context_list_cb(void *opdata)
{
	// There is no UI so there is nothing to do here
}

static void confirm_fingerprint_cb(CryptOTRUserState opdata, OtrlUserState us,
	const char *accountname, const char *protocol, const char *username,
	unsigned char fingerprint[20])
{
	unsigned char readable[45];

	otrl_privkey_hash_to_human(readable, fingerprint);

	crypt_otr_new_fingerprint( opdata, accountname, protocol, username, readable );
}

static void write_fingerprints_cb( CryptOTRUserState opdata)
{
	otrl_privkey_write_fingerprints( opdata->otrl_state, opdata->fprfile );
}

static void gone_secure_cb(CryptOTRUserState opdata, ConnContext *context)
{
	crypt_otr_handle_connected(opdata, context);
}

static void gone_insecure_cb(CryptOTRUserState opdata, ConnContext *context)
{
	crypt_otr_handle_disconnection(opdata, context->username);
}

static void still_secure_cb(CryptOTRUserState opdata, ConnContext *context, int is_reply)
{
    if (is_reply == 0) {
	    crypt_otr_handle_stillconnected(opdata, context->username);
    }
}

static void log_message_cb(void *opdata, const char *message)
{
    printf("otr: %s", message);
}

static int max_message_size_cb(CryptOTRUserState opdata, ConnContext *context)
{
	return opdata->max_size;
}

static OtrlMessageAppOps otr_ops = {
	policy_cb,
	create_privkey_cb,
	is_logged_in_cb,
	inject_message_cb,
	notify_cb,
	display_otr_message_cb,
	update_context_list_cb,
	protocol_name_cb,
	protocol_name_free_cb,
	confirm_fingerprint_cb,
	write_fingerprints_cb,
	gone_secure_cb,
	gone_insecure_cb,
	still_secure_cb,
	log_message_cb,
	max_message_size_cb,
	NULL,
	NULL
};

