
////////////////////////////////////
// Utilities
///////////////////////////////////

/*  expandFilename(filename)
 * Expand "~/" with the $HOME env. variable in a file name.
 * The caller must free the string after use.
 */
char *expand_filename(const char *fname)
{
	char* buffer;

	if (!fname)
		return NULL;
	if (!strncmp(fname, "~/", 2)) {
		char *homedir = getenv("HOME");
		if (homedir){
			int new_size = strlen( homedir ) + strlen( fname ); // subtrat 1 for the ~, add 1 for the \0
			buffer = malloc( (new_size ) * sizeof( char ) ); 
			sprintf(buffer, "%s%s", homedir, fname + sizeof(char) ); // remove the ~		   
			return buffer;
		}
	}
	return strdup(fname);
}

void dumpState( CryptOTRUserState crypt_state  )
{
	printf( "CryptOTRUserState:\nptr=>%i\nroot=>%s\nkeyfile=>%s\nfprfile=>%s\nmax_size=>%i\n\ninject_cb=>%i\nsystem_message_cb=>%i\n%i\n%i\n%i\n%i\n%i\n%i\n%i\n%i\n\n",
		   crypt_state->otrl_state,
		   crypt_state->root,
		   crypt_state->keyfile,
		   crypt_state->fprfile,
		   crypt_state->max_size,

		   crypt_state->inject_cb,
		   crypt_state->system_message_cb,
		   crypt_state->connected_cb,
		   crypt_state->unverified_cb,
		   crypt_state->disconnected_cb,
		   crypt_state->stillconnected_cb,
		   crypt_state->error_cb,
		   crypt_state->warning_cb,
		   crypt_state->info_cb,
		   crypt_state->new_fpr_cb );
}
