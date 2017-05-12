// ACE4.xs
//
// Glue between ACE.pm and ACE/Server client API
// Copyright (C) 2001 Open System Consultants
// Author Mike McCauley mikem@open.com.au
// $Id: ACE4.xs,v 1.2 2011/12/29 06:03:24 mikem Exp $


#include "ace.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = Authen::ACE4		PACKAGE = Authen::ACE4

PROTOTYPES: ENABLE

int
constant()
  PROTOTYPE:
  ALIAS:
    ACE_SUCCESS = ACE_SUCCESS
    ACE_ERR_INVALID_HANDLE = ACE_ERR_INVALID_HANDLE
    ACE_CHECK_INVALID_HANDLE = ACE_CHECK_INVALID_HANDLE
    ACE_CLOSE_INVALID_HANDLE = ACE_CLOSE_INVALID_HANDLE
    ACE_PROCESSING = ACE_PROCESSING
    ACE_CFGFILE_NOT_FOUND = ACE_CFGFILE_NOT_FOUND
    ACE_CFGFILE_READ_FAIL = ACE_CFGFILE_READ_FAIL
    ACE_EVENT_CREATE_FAIL = ACE_EVENT_CREATE_FAIL
    ACE_SEMAPHORE_CREATE_FAIL = ACE_SEMAPHORE_CREATE_FAIL
    ACE_THREAD_CREATE_FAIL = ACE_THREAD_CREATE_FAIL
    ACE_SOCKET_LIB_NOT_FOUND = ACE_SOCKET_LIB_NOT_FOUND
    ACE_PTHREAD_FAIL = ACE_PTHREAD_FAIL
    ACE_PTHREAD_CREATE_FAIL = ACE_PTHREAD_CREATE_FAIL
    ACE_PTHREADATTR_FAIL = ACE_PTHREADATTR_FAIL
    ACE_PTHREADATTR_CREATE_FAIL = ACE_PTHREADATTR_CREATE_FAIL
    ACE_PTHREADCONDVAR_CREATE_FAIL = ACE_PTHREADCONDVAR_CREATE_FAIL
    ACE_PTHREADMUTEX_CREATE_FAIL = ACE_PTHREADMUTEX_CREATE_FAIL 
    ACE_NET_SEND_PACKET_FAIL = ACE_NET_SEND_PACKET_FAIL
    ACE_NET_WAITING_TIMEOUT = ACE_NET_WAITING_TIMEOUT
    ACE_INIT_NO_RESOURCE = ACE_INIT_NO_RESOURCE
    ACE_INIT_SOCKET_FAIL = ACE_INIT_SOCKET_FAIL
    ACE_INIT_SYNCRONIZE_FAIL = ACE_INIT_SYNCRONIZE_FAIL
    ACE_CHECK_PIN_REQ_NOT_KNOWN = ACE_CHECK_PIN_REQ_NOT_KNOWN
    ACE_NOT_ENOUGH_STORAGE = ACE_NOT_ENOUGH_STORAGE
    ACE_INVALID_ARG = ACE_INVALID_ARG
    ACE_UNDEFINED_USERNAME = ACE_UNDEFINED_USERNAME
    ACE_UNDEFINED_PASSCODE = ACE_UNDEFINED_PASSCODE
    ACE_UNDEFINED_NEXT_PASSCODE = ACE_UNDEFINED_NEXT_PASSCODE
    ACE_UNDEFINED_PIN = ACE_UNDEFINED_PIN
    ACE_UNDEFINED_CLIENTADDR = ACE_UNDEFINED_CLIENTADDR

    ACM_OK = ACM_OK
    ACM_ACCESS_DENIED = ACM_ACCESS_DENIED
    ACM_NEXT_CODE_REQUIRED = ACM_NEXT_CODE_REQUIRED
    ACM_NEXT_CODE_BAD = ACM_NEXT_CODE_BAD
    ACM_NEW_PIN_REQUIRED = ACM_NEW_PIN_REQUIRED
    ACM_NEW_PIN_ACCEPTED = ACM_NEW_PIN_ACCEPTED
    ACM_NEW_PIN_REJECTED = ACM_NEW_PIN_REJECTED
    ACM_SHELL_OK = ACM_SHELL_OK
    ACM_SHELL_BAD = ACM_SHELL_BAD
    ACM_TIME_OK = ACM_TIME_OK
    ACM_SUSPECT_ACK = ACM_SUSPECT_ACK
    ACM_LOG_ACK = ACM_LOG_ACK

  CODE:
    RETVAL = ix;
  OUTPUT:
    RETVAL

SD_BOOL
AceInitialize()
	CODE:
#if defined UNIX || SD_VERSION >= 5
    // Not present on NT in Version 4
    RETVAL = AceInitialize();
#endif
	OUTPUT:
	RETVAL

void
AceStartAuth(userID)
    char*		userID
	
  PPCODE:
    STRLEN      userIDLen;
    SDI_HANDLE	handle;
    SD_BOOL	moreData;
    SD_BOOL	echoFlag;
    SD_I32	respTimeout;
    SD_I32	nextRespLen;
    char	promptStr[512];
    SD_I32	promptStrLen = sizeof(promptStr);
    SD_ERROR	result;

    // Need the real length of the string
    userID = (char *)SvPV(ST(0), userIDLen);
    result = AceStartAuth(&handle, userID, userIDLen,
			  &moreData, &echoFlag, &respTimeout, 
			  &nextRespLen, promptStr, &promptStrLen);

    // Always push the result, and, if successful
    // the rest
    EXTEND(sp, 5);
    PUSHs(sv_2mortal(newSViv(result)));
    PUSHs(sv_2mortal(newSViv(handle)));
    PUSHs(sv_2mortal(newSViv(moreData)));
    PUSHs(sv_2mortal(newSViv(echoFlag)));
    PUSHs(sv_2mortal(newSViv(respTimeout)));
    PUSHs(sv_2mortal(newSViv(nextRespLen)));
    PUSHs(sv_2mortal(newSVpv(promptStr, strlen(promptStr))));


void
AceContinueAuth(handle, resp)
    int		handle
    char*	resp
	
    PPCODE:
    STRLEN      respLen;
    SD_BOOL	moreData;
    SD_BOOL	echoFlag;
    SD_I32	respTimeout;
    SD_I32	nextRespLen;
    char	promptStr[512];
    SD_I32	promptStrLen = sizeof(promptStr);
    SD_ERROR	result;

    // Need the real length of the string
    resp = (char *)SvPV(ST(1), respLen);
    result = AceContinueAuth(handle, resp, respLen,
			     &moreData, &echoFlag, &respTimeout, 
			     &nextRespLen, promptStr, &promptStrLen);

    // Always push the result, and, if successful
    // the rest
    EXTEND(sp, 5);
    PUSHs(sv_2mortal(newSViv(result)));
    EXTEND(sp, 4);
    PUSHs(sv_2mortal(newSViv(moreData)));
    PUSHs(sv_2mortal(newSViv(echoFlag)));
    PUSHs(sv_2mortal(newSViv(respTimeout)));
    PUSHs(sv_2mortal(newSViv(nextRespLen)));
    // Sigh: promptStrLen is unreliable with the 6.1 SDK and AM 7.1
    PUSHs(sv_2mortal(newSVpv(promptStr, strlen(promptStr))));


int
AceGetAuthenticationStatus(handle)
    int	handle

    PPCODE:
    SD_I32	authStatus = ACM_ACCESS_DENIED;
    RETVAL = AceGetAuthenticationStatus(handle, &authStatus);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(authStatus)));
    }
	
int
AceGetAlphanumeric(handle)
    int	handle

    PPCODE:
    char        val;
    RETVAL = AceGetAlphanumeric(handle, &val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(val)));
    }

int
AceGetMaxPinLen(handle)
    int	handle

    PPCODE:
    char        val;
    RETVAL = AceGetMaxPinLen(handle, &val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(val)));
    }

int
AceGetMinPinLen(handle)
    int	handle

    PPCODE:
    char        val;
    RETVAL = AceGetMinPinLen(handle, &val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(val)));
    }

int
AceGetShell(handle)
    int	handle

    PPCODE:
    char        val[512];
    RETVAL = AceGetShell(handle, val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
	PUSHs(sv_2mortal(newSVpv(val, strlen(val))));
    }

int
AceGetSystemPin(handle)
    int	handle

    PPCODE:
    char        val[512];
    RETVAL = AceGetSystemPin(handle, val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
	PUSHs(sv_2mortal(newSVpv(val, strlen(val))));
    }

int
AceGetTime(handle)
    int	handle

    PPCODE:
    INT32BIT   val;
    RETVAL = AceGetTime(handle, &val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(val)));
    }

int
AceGetUserSelectable(handle)
    int	handle

    PPCODE:
    char        val;
    RETVAL = AceGetUserSelectable(handle, &val);
    EXTEND(sp, 1);
    PUSHs(sv_2mortal(newSViv(RETVAL)));
    if (RETVAL == ACE_SUCCESS)
    {
    	EXTEND(sp, 1);
    	PUSHs(sv_2mortal(newSViv(val)));
    }

int
AceSetUserClientAddress(handle, address)
    int handle
    unsigned char* address


int
AceCloseAuth(handle)
    int	handle

MODULE = Authen::ACE4		PACKAGE = Authen::ACE4::Sync

int
SD_Init(sd)
	SDI_HANDLE	&sd
    OUTPUT:
	sd

int
SD_Check(sd, password="", username)
	SDI_HANDLE	sd
	char *		password
	char *		username

int 
SD_Next(sd, next)
	SDI_HANDLE	sd
	char *		next

int
SD_Pin(sd, pin)
	SDI_HANDLE	sd
	char *		pin

int
SD_Close(sd)
	SDI_HANDLE	sd
