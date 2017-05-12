#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <PAM_config.h>

#if defined( HAVE_SECURITY_PAM_APPL_H )
# include <security/pam_appl.h>
#else
# if defined( HAVE_PAM_PAM_APPL_H )
#   include <pam/pam_appl.h>
# endif
#endif

/* 
   Description of the macros used by this file.

   | If your PAM library has the pam_get/putenv functions (PAM versions 
   | after 0.54) the following macro should be defined.
   |
   #define HAVE_PAM_GETENV

   | The following macro activates a workaround for a bug in the solaris 2.6
   | PAM library by setting a pointer to the perl conversation function
   | before every call to a pam function
   |
   #define STATIC_CONV_FUNC
*/


/* this is now determined from configure script */


#if defined( sun ) || defined( __hpux )

  #define CONST_VOID	void
  #define CONST_STRUCT	struct

#else

  #define CONST_STRUCT	const struct
  #define CONST_VOID	const void

#endif

struct perl_pam_data {
  SV* conv_func;
  SV* delay_func;
};

typedef struct pam_conv sPamConv;
typedef struct pam_response sPamResponse;
typedef struct perl_pam_data sPerlPamData;

/* 
 * Gets conv_struct->appdata_ptr and casts it as a sPerlPamData
 */
static sPerlPamData* 
get_perl_pam_data(pamh)
pam_handle_t *pamh;
{
    int res;
    sPamConv *cs;
    res = pam_get_item(pamh, PAM_CONV, (CONST_VOID **)&cs);
    if (res != PAM_SUCCESS || cs == NULL || cs->appdata_ptr == NULL)
        croak("Error in getting pam data!");
    else
        return (sPerlPamData*)cs->appdata_ptr;
}


#ifdef STATIC_CONV_FUNC

    static sPerlPamData *static_perl_pam_data = NULL;

    #define SET_CONV_FUNC(pamh) static_perl_pam_data = get_perl_pam_data(pamh)

#else

    #define SET_CONV_FUNC(pamh)

#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


static int
my_conv_func(num_msg, msg, resp, appdata_ptr)
        int num_msg;
        CONST_STRUCT pam_message **msg;
        sPamResponse **resp;
        void *appdata_ptr;
{
        int i,res_cnt,res;
	STRLEN len;
        sPamResponse *reply = NULL;
        SV *strSV;
        char *str;
        dSP;
	
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);
        for (i = 0; i < num_msg; i++) {
	#ifdef sun
            XPUSHs(sv_2mortal(newSViv((*msg)[i].msg_style)));
            XPUSHs(sv_2mortal(newSVpv((*msg)[i].msg, 0)));
	#else
            XPUSHs(sv_2mortal(newSViv((msg[i])->msg_style)));
            XPUSHs(sv_2mortal(newSVpv((msg[i])->msg, 0)));
	#endif
        }
        PUTBACK;

#ifdef STATIC_CONV_FUNC
	appdata_ptr = static_perl_pam_data;
#endif
	if ( !SvTRUE(((sPerlPamData*)appdata_ptr)->conv_func) )
	    croak("Calling empty conversation function!");
        res_cnt = 
	  perl_call_sv(((sPerlPamData*)appdata_ptr)->conv_func, G_ARRAY);

        SPAGAIN;
	
        if (res_cnt == 1) { // only return code
	  res = POPi;
	  reply = NULL;
        } 
	else if (res_cnt == 2*num_msg + 1) {
	    res = POPi;
	    res_cnt--;
	    if (res_cnt > 0) {
		res_cnt /= 2;
        	reply = malloc( res_cnt * sizeof(sPamResponse));
        	for (i = res_cnt - 1; i >= 0; i--) {
        	    strSV = POPs;
        	    str = SvPV(strSV, len);
        	    reply[i].resp_retcode = POPi;
		    reply[i].resp = malloc(len+1);
		    memcpy(reply[i].resp, str, len);
		    reply[i].resp[len] = 0;
/*
		printf("Code %d and str %s\n",  reply[i].resp_retcode, 
						reply[i].resp);
*/
           	}
	    }
        } 
        else {
	  croak("The output list of the PAM conversation function"
		" must have twice the size of the input list plus one!");
	  res = PAM_CONV_ERR;
	}

        PUTBACK;

        FREETMPS;
        LEAVE;

	*resp = reply;
	return res;
}


/*
 * We must also handle setting a delay function with a prototype:
 *
 *     void (*delay_fn)(int retval, unsigned usec_delay, void *appdata_ptr);
 *
 * by a call to pam_set_item(pamh, PAM_FAIL_DELAY, fail_delay);
 *
 * Works only on Linux-PAM >= 0.68
 */
static void
my_delay_func(status, delay, appdata_ptr)
int status;
unsigned int delay;
void *appdata_ptr;
{
    dSP ;

    if (appdata_ptr == NULL)
        croak("Empty perl pam data");
    if (!SvTRUE(((sPerlPamData*)appdata_ptr)->delay_func))
        croak("Calling empty delay function!");
    
    /* printf("st: %d, dl: %d\n",status,delay); */

    PUSHMARK(sp) ;
    XPUSHs(sv_2mortal(newSViv(status)));
    XPUSHs(sv_2mortal(newSViv(delay)));
    PUTBACK ;

    perl_call_sv(((sPerlPamData*)appdata_ptr)->delay_func, 
		 G_VOID | G_DISCARD);
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;

    if (strncmp(name, "PAM_", 4) == 0) {
      name = &name[4];
      /* error codes */
      if (strcmp(name, "SUCCESS") == 0)
	  return PAM_SUCCESS;
      else if (strcmp(name, "OPEN_ERR") == 0)
	  return PAM_OPEN_ERR;
      else if (strcmp(name, "SYMBOL_ERR") == 0)
	  return PAM_SYMBOL_ERR;
      else if (strcmp(name, "SERVICE_ERR") == 0)
	  return PAM_SERVICE_ERR;
      else if (strcmp(name, "SYSTEM_ERR") == 0)
	  return PAM_SYSTEM_ERR;
      else if (strcmp(name, "BUF_ERR") == 0)
	  return PAM_BUF_ERR;
      else if (strcmp(name, "PERM_DENIED") == 0)
	  return PAM_PERM_DENIED;
      else if (strcmp(name, "AUTH_ERR") == 0)
	  return PAM_AUTH_ERR;
      else if (strcmp(name, "CRED_INSUFFICIENT") == 0)
	  return PAM_CRED_INSUFFICIENT;
      else if (strcmp(name, "AUTHINFO_UNAVAIL") == 0)
	  return PAM_AUTHINFO_UNAVAIL;
      else if (strcmp(name, "USER_UNKNOWN") == 0)
	  return PAM_USER_UNKNOWN;
      else if (strcmp(name, "MAXTRIES") == 0)
	  return PAM_MAXTRIES;
      else if (strcmp(name, "NEW_AUTHTOK_REQD") == 0 ||
	       strcmp(name, "AUTHTOKEN_REQD") == 0)
      #if defined(HAVE_PAM_NEW_AUTHTOK_REQD)
	  return PAM_NEW_AUTHTOK_REQD;
      #elif defined(HAVE_PAM_AUTHTOKEN_REQD)
          return PAM_AUTHTOKEN_REQD;       /* Old Linux-PAM */
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "ACCT_EXPIRED") == 0)
	  return PAM_ACCT_EXPIRED;
      else if (strcmp(name, "SESSION_ERR") == 0)
	  return PAM_SESSION_ERR;
      else if (strcmp(name, "CRED_UNAVAIL") == 0)
	  return PAM_CRED_UNAVAIL;
      else if (strcmp(name, "CRED_EXPIRED") == 0)
	  return PAM_CRED_EXPIRED;
      else if (strcmp(name, "CRED_ERR") == 0)
	  return PAM_CRED_ERR;
      else if (strcmp(name, "NO_MODULE_DATA") == 0)
	  return PAM_NO_MODULE_DATA;
      else if (strcmp(name, "CONV_ERR") == 0)
	  return PAM_CONV_ERR;
      else if (strcmp(name, "AUTHTOK_ERR") == 0)
	  return PAM_AUTHTOK_ERR;
      else if (strcmp(name, "AUTHTOK_RECOVER_ERR") == 0 ||
	       strcmp(name, "AUTHTOK_RECOVERY_ERR") == 0)
      #if defined(HAVE_PAM_AUTHTOK_RECOVER_ERR)    /* Linux-PAM   */
	  return PAM_AUTHTOK_RECOVER_ERR;
      #elif defined(HAVE_PAM_AUTHTOK_RECOVERY_ERR) /* Solaris PAM */
	  return PAM_AUTHTOK_RECOVERY_ERR;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "AUTHTOK_LOCK_BUSY") == 0)
	  return PAM_AUTHTOK_LOCK_BUSY;
      else if (strcmp(name, "AUTHTOK_DISABLE_AGING") == 0)
	  return PAM_AUTHTOK_DISABLE_AGING;
      else if (strcmp(name, "TRY_AGAIN") == 0)
	  return PAM_TRY_AGAIN;
      else if (strcmp(name, "IGNORE") == 0)
	  return PAM_IGNORE;
      else if (strcmp(name, "ABORT") == 0)
	  return PAM_ABORT;
      else if (strcmp(name, "AUTHTOK_EXPIRED") == 0)
      #if defined(HAVE_PAM_AUTHTOK_EXPIRED)
	  return PAM_AUTHTOK_EXPIRED;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "MODULE_UNKNOWN") == 0)
      #if defined(HAVE_PAM_MODULE_UNKNOWN)  /* Linux-PAM only */
	  return PAM_MODULE_UNKNOWN;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "BAD_ITEM") == 0)
      #if defined(HAVE_PAM_BAD_ITEM)
	  return PAM_BAD_ITEM;
      #else
	  goto not_there;
      #endif

      /* New Linux-PAM return codes */
      else if (strcmp(name, "CONV_AGAIN") == 0)
      #if defined(HAVE_PAM_CONV_AGAIN)
	  return PAM_CONV_AGAIN;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "INCOMPLETE") == 0)
      #if defined(HAVE_PAM_INCOMPLETE)
	  return PAM_INCOMPLETE;
      #else
	  goto not_there;
      #endif

      /* set/get_item constants */
      else if (strcmp(name, "SERVICE") == 0)
	  return PAM_SERVICE;
      else if (strcmp(name, "USER") == 0)
	  return PAM_USER;
      else if (strcmp(name, "TTY") == 0)
	  return PAM_TTY;
      else if (strcmp(name, "RHOST") == 0)
	  return PAM_RHOST;
      else if (strcmp(name, "CONV") == 0)
	  return PAM_CONV;
      /* module flags */
      /*
      else if (strcmp(name, "AUTHTOK") == 0)
	  return PAM_CONV;
      else if (strcmp(name, "OLDAUTHTOK") == 0)
	  return PAM_CONV;
      */
      else if (strcmp(name, "RUSER") == 0)
	  return PAM_RUSER;
      else if (strcmp(name, "USER_PROMPT") == 0)
	  return PAM_USER_PROMPT;
      else if (strcmp(name, "FAIL_DELAY") == 0)
      #if defined(HAVE_PAM_FAIL_DELAY)
	  return PAM_FAIL_DELAY;
      #else
	  goto not_there;
      #endif

      /* global flag */
      else if (strcmp(name, "SILENT") == 0)
	  return PAM_SILENT;
      /* pam_authenticate falgs */
      else if (strcmp(name, "DISALLOW_NULL_AUTHTOK") == 0)
	  return PAM_DISALLOW_NULL_AUTHTOK;
      /* pam_set_cred flags */
      else if (strcmp(name, "ESTABLISH_CRED") == 0 ||
	       strcmp(name, "CRED_ESTABLISH") == 0)
      #if defined(HAVE_PAM_ESTABLISH_CRED)
	  return PAM_ESTABLISH_CRED;
      #elif defined(HAVE_PAM_CRED_ESTABLISH)   /* Old Linux-PAM */
	  return PAM_CRED_ESTABLISH;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "DELETE_CRED") == 0 ||
	       strcmp(name, "CRED_DELETE") == 0)
      #if defined(HAVE_PAM_DELETE_CRED)
	  return PAM_DELETE_CRED;
      #elif defined(HAVE_PAM_CRED_DELETE)       /* Old Linux-PAM */
	  return PAM_CRED_DELETE;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "REINITIALIZE_CRED") == 0 ||
	       strcmp(name, "CRED_REINITIALIZE") == 0)
      #if defined(HAVE_PAM_REINITIALIZE_CRED)
	  return PAM_REINITIALIZE_CRED;
      #elif defined(HAVE_PAM_CRED_REINITIALIZE)
	  return PAM_CRED_REINITIALIZE;    /* Old Linux-PAM */
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "REFRESH_CRED") == 0 ||
	       strcmp(name, "CRED_REFRESH") == 0)
      #if defined(HAVE_PAM_REFRESH_CRED)
	  return PAM_REFRESH_CRED;
      #elif defined(HAVE_PAM_CRED_REFRESH)
	  return PAM_CRED_REFRESH;         /* Old Linux-PAM */
      #else
	  goto not_there;
      #endif
      /* pam_chauthtok flags */
      else if (strcmp(name, "CHANGE_EXPIRED_AUTHTOK") == 0)
	  return PAM_CHANGE_EXPIRED_AUTHTOK;

      /* message style constants */
      else if (strcmp(name, "PROMPT_ECHO_OFF") == 0)
	  return PAM_PROMPT_ECHO_OFF;
      else if (strcmp(name, "PROMPT_ECHO_ON") == 0)
	  return PAM_PROMPT_ECHO_ON;
      else if (strcmp(name, "ERROR_MSG") == 0)
	  return PAM_ERROR_MSG;
      else if (strcmp(name, "TEXT_INFO") == 0)
	  return PAM_TEXT_INFO;
      else if (strcmp(name, "RADIO_TYPE") == 0)
      #if defined(HAVE_PAM_RADIO_TYPE)
	  return PAM_RADIO_TYPE;
      #else
	  goto not_there;
      #endif
      else if (strcmp(name, "BINARY_PROMPT") == 0)
      #if defined(HAVE_PAM_BINARY_PROMPT)
	  return PAM_BINARY_PROMPT;
      #else
	  goto not_there;
      #endif

      /* I'm not sure if these are really needed... */
      /*
      else if (strcmp(name, "MAX_MSG_SIZE") == 0)
	  return PAM_MAX_MSG_SIZE;
      else if (strcmp(name, "MAX_RESP_SIZE") == 0)
	  return PAM_MAX_RESP_SIZE;
      */
    } 
    else if (strncmp(name, "HAVE_PAM_", 9) == 0) {
      name = &name[9];

      if (strcmp(name, "FAIL_DELAY") == 0)
      #if defined(HAVE_PAM_FAIL_DELAY)
	  return 1;
      #else
	  return 0;
      #endif
      else if (strcmp(name, "ENV_FUNCTIONS") == 0)
      #if defined(HAVE_PAM_GETENV)
	  return 1;
      #else
	  return 0;
      #endif
      /*
      else if (strcmp(name, "HAVE_PAM_SYSTEM_LOG") == 0)
      #if defined(HAVE_PAM_SYSTEM_LOG)
	  return 1;
      #else
	  return 0;
      #endif
      */
    }

    errno = EINVAL;
    return 0;

not_there:
    errno = ENOSYS;
    return 0;
}


MODULE = Authen::PAM	PACKAGE = Authen::PAM

PROTOTYPES: ENABLE


double
constant(name,arg)
	char	*name
	int	arg


int
_pam_start(service_name, user_sv, func, pamh)
	const char *service_name
	SV *user_sv
	SV *func
	pam_handle_t *pamh = NO_INIT
	PREINIT:
	  sPamConv conv_st;
	  const char *user;
	CODE:
	  user = SvOK(user_sv) ? SvPV_nolen(user_sv) : NULL;

	  conv_st.conv = my_conv_func;
	  conv_st.appdata_ptr = malloc(sizeof(sPerlPamData));
	  ((sPerlPamData*)conv_st.appdata_ptr)->conv_func = newSVsv(func);
	  ((sPerlPamData*)conv_st.appdata_ptr)->delay_func = newSViv(0);

	  RETVAL = pam_start(service_name, user, &conv_st, &pamh);
        OUTPUT:
	  pamh
	  RETVAL

int
pam_end(pamh, pam_status=PAM_SUCCESS)
	pam_handle_t *pamh
	int	pam_status
	PREINIT:
	  sPerlPamData *data;
	  int res;
	CODE:
	  data = get_perl_pam_data(pamh);
          SvREFCNT_dec(data->conv_func); 
          SvREFCNT_dec(data->delay_func); 
	  free(data);

          RETVAL = pam_end(pamh, pam_status);
	OUTPUT:
	RETVAL

int
pam_set_item(pamh, item_type, item)
	pam_handle_t *pamh
	int	item_type
	SV	*item
	PREINIT:
	  sPerlPamData *data;
	  int res;
	CODE:
	  if (item_type == PAM_CONV) {
	      data = get_perl_pam_data(pamh);
	      sv_setsv(data->conv_func, item);
	      RETVAL = PAM_SUCCESS;
	  }
#if defined(HAVE_PAM_FAIL_DELAY)
          else if (item_type == PAM_FAIL_DELAY) {
	      data = get_perl_pam_data(pamh);
	      sv_setsv(data->delay_func, item);
	      if (SvTRUE(item))
	          RETVAL = pam_set_item( pamh, item_type, my_delay_func);
	      else
	          RETVAL = pam_set_item( pamh, item_type, NULL);
	  }
#endif
	  else
#if (PERL_API_REVISION == 5 && PERL_API_VERSION >= 5)
	      RETVAL = pam_set_item( pamh, item_type, SvPV_nolen(item));
#else
	      RETVAL = pam_set_item( pamh, item_type, SvPV(item,na));
#endif
	OUTPUT:
	RETVAL
	
int
pam_get_item(pamh, item_type, item)
	pam_handle_t *pamh
	int	item_type
	SV	*item
	PREINIT:
	  char *c;
	  sPerlPamData *data;
	  int res;
	CODE:
	  if (item_type == PAM_CONV) {
	      data = get_perl_pam_data(pamh);
	      sv_setsv(item, data->conv_func);
	      RETVAL = PAM_SUCCESS;
	  }
#if defined(HAVE_PAM_FAIL_DELAY)
          else if (item_type == PAM_FAIL_DELAY) {
	      data = get_perl_pam_data(pamh);
	      sv_setsv(item, data->delay_func);
	      RETVAL = PAM_SUCCESS;
 	  }
#endif
	  else {
	      RETVAL = pam_get_item( pamh, item_type, (CONST_VOID **)&c);
	      sv_setpv(item, c);
	  }
	OUTPUT:
	item
	RETVAL

const char *
pam_strerror(pamh, errnum)
	pam_handle_t *	pamh
	int	errnum
	CODE:
#if defined(PAM_STRERROR_NEEDS_PAMH)
	  RETVAL = pam_strerror(pamh, errnum);
#else
	  RETVAL = pam_strerror(errnum);
#endif
	OUTPUT:
	RETVAL

#if defined(HAVE_PAM_GETENV)
int
pam_putenv(pamh, name_value)
	pam_handle_t	*pamh
	const char	*name_value
	CODE:
	  RETVAL = pam_putenv(pamh, name_value);
	OUTPUT:
	RETVAL

const char *
pam_getenv(pamh, name)
	pam_handle_t	*pamh
	const char	*name
	CODE:
	  RETVAL = pam_getenv(pamh, name);
	OUTPUT:
	RETVAL

void
_pam_getenvlist(pamh)
	pam_handle_t *pamh
	PREINIT:
	  char **res;
	  int i;
	  int c;
	PPCODE:
	  res = pam_getenvlist(pamh);
	  c = 0;
	  while (res[c] != 0)
	      c++;
	  EXTEND(sp, c);
	  for (i = 0; i < c; i++)
	      PUSHs(sv_2mortal(newSVpv(res[i],0)));

#else

int
pam_putenv(pamh, name_value)
	pam_handle_t	*pamh
	const char	*name_value
	CODE:
	  not_here("pam_putenv");

const char *
pam_getenv(pamh, name)
	pam_handle_t	*pamh
	const char	*name
	CODE:
	  not_here("pam_getenv");


void
_pam_getenvlist(pamh)
	pam_handle_t *pamh
	CODE:
	  not_here("pam_getenvlist");

#endif


#if defined(HAVE_PAM_FAIL_DELAY)

int
pam_fail_delay(pamh, musec_delay)
	pam_handle_t *pamh
	unsigned int musec_delay
	CODE:
	  RETVAL = pam_fail_delay(pamh, musec_delay);
	OUTPUT:
	RETVAL

#else

void
pam_fail_delay(pamh, musec_delay)
	pam_handle_t *	pamh
	unsigned int	musec_delay
	CODE:
	  not_here("pam_fail_delay");

#endif


int
pam_authenticate(pamh, flags=0)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_authenticate(pamh,flags);
	OUTPUT:
	RETVAL

int
pam_setcred(pamh, flags)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_setcred(pamh,flags);
	OUTPUT:
	RETVAL

int
pam_acct_mgmt(pamh, flags=0)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_acct_mgmt(pamh,flags);
	OUTPUT:
	RETVAL

int
pam_open_session(pamh, flags=0)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_open_session(pamh,flags);
	OUTPUT:
	RETVAL

int
pam_close_session(pamh, flags=0)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_close_session(pamh, flags);
	OUTPUT:
	RETVAL

int
pam_chauthtok(pamh, flags=0)
	pam_handle_t *pamh
	int	flags
	CODE:
	  SET_CONV_FUNC(pamh);
	  RETVAL = pam_chauthtok(pamh, flags);
	OUTPUT:
	RETVAL
