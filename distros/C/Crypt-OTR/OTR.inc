#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "crypt-otr.h"

#include "ppport.h"



/* Global Data */

#define MY_CXT_KEY "Crypt::OTR::_guts" XS_VERSION

typedef struct {
    /* Put Global Data in here */
    OtrlUserState userstate;		/* you can access this elsewhere as MY_CXT.userstate */
	char* keyfile;
	char* fprfile;
	char* accountname; /* This is YOUR id.  OTR convention is that *username* is THEM */
	char* protocol;
	int* max_message_size;
	char* inject_cb; /* From this callback you get an encrypted version of your original message (sort of) */
	char* display_cb; 
	char* connected_cb; /* This callback is called when a context transitions to ENCRYPTED */
	char* disconnected_cb; /* This callback is called when a context transitions to PLAINTEXT */ 
	char* error_cb;
	char* warning_cb;
	char* info_cb;
	char* new_fpr_cb;
} my_cxt_t;

START_MY_CXT

#include "const-c.inc"

MODULE = Crypt::OTR		PACKAGE = Crypt::OTR		

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
     * to be initialised, do it here.
     */
	
	MY_CXT.userstate = NULL;
	MY_CXT.keyfile = NULL;
	MY_CXT.fprfile = NULL;
	MY_CXT.accountname = NULL;
	MY_CXT.protocol = NULL;
	MY_CXT.max_message_size = 32000; /* This is arbitrary. */
	
	MY_CXT.inject_cb = NULL;
	MY_CXT.display_cb = NULL;
	MY_CXT.connected_cb = NULL;
	MY_CXT.disconnected_cb = NULL;
	MY_CXT.error_cb = NULL;
	MY_CXT.warning_cb = NULL;
	MY_CXT.info_cb = NULL;
	MY_CXT.new_fpr_cb = NULL;
}



INCLUDE: "crypt-otr.inc"
