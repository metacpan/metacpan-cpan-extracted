
//void crypt_otr_set_userstate( OtrlUserState in_userstate ) { crypt_otr_userstate = in_userstate; }
//void crypt_otr_set_keyfile	( CryptOTRUserState in_state, char* in_keyfile ) 	{ in_state->keyfile = in_keyfile; }
//void crypt_otr_set_fprfile	( CryptOTRUserState in_state, char* in_fprfile ) 	{ in_state->fprfile = in_fprfile; }
//void crypt_otr_set_root		( CryptOTRUserState in_state, char* in_root ) 	{ in_state->root = in_root; }
//void crypt_otr_set_max_message_size ( CryptOTRUserState in_state, int in_max_size ) { in_state->max_size = in_max_size; }



// Callback setters
#define CRYPT_OTR_INSTALL_CALLBACK(userstate_cb, perl_cb) SvREFCNT_inc(perl_cb); userstate_cb = perl_cb;

void crypt_otr_set_inject_cb( CryptOTRUserState in_state, CV* in_inject_cb ){ CRYPT_OTR_INSTALL_CALLBACK( in_state->inject_cb, in_inject_cb ); }
void crypt_otr_set_system_message_cb( CryptOTRUserState in_state, CV* in_sys_mes_cb ){ CRYPT_OTR_INSTALL_CALLBACK(in_state->system_message_cb, in_sys_mes_cb); }
void crypt_otr_set_connected_cb( CryptOTRUserState in_state, CV* in_connected_cb ){ CRYPT_OTR_INSTALL_CALLBACK( in_state->connected_cb, in_connected_cb); }
void crypt_otr_set_unverified_cb( CryptOTRUserState in_state, CV* in_unver_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->unverified_cb, in_unver_cb); }
void crypt_otr_set_disconnected_cb( CryptOTRUserState in_state, CV* in_disconnected_cb ){ CRYPT_OTR_INSTALL_CALLBACK( in_state->disconnected_cb, in_disconnected_cb); }
void crypt_otr_set_stillconnected_cb( CryptOTRUserState in_state, CV* in_still_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->stillconnected_cb, in_still_cb); }
void crypt_otr_set_error_cb( CryptOTRUserState in_state, CV* in_error_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->error_cb, in_error_cb); }
void crypt_otr_set_warning_cb( CryptOTRUserState in_state, CV* in_warning_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->warning_cb, in_warning_cb); }
void crypt_otr_set_info_cb( CryptOTRUserState in_state, CV* in_info_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->info_cb, in_info_cb); }
void crypt_otr_set_new_fpr_cb( CryptOTRUserState in_state, CV* in_fpr_cb ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->new_fpr_cb, in_fpr_cb); }
void crypt_otr_set_smp_request_cb( CryptOTRUserState in_state, CV* in_smp ) { CRYPT_OTR_INSTALL_CALLBACK( in_state->smp_request_cb, in_smp); } 
