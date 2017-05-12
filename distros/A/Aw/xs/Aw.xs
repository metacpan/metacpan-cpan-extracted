/* This is part of the Aw:: Perl module.  A Perl interface to the ActiveWorks(tm) 
   libraries.  Copyright (C) 1999-2000 Daniel Yacob.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <awadapter.h>
#include <aweb.h>
#include <adapter_log.h>

#if ( AW_VERSION_31 || AW_VERSION_40 )
#  include <adapter_sessions.h>
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

#include <awfilter.h>

/* Theses are required only for the constant routine */

#include "messages.h"
#include <awlicense.h>

/* includes for Aw.xs */

#include <awxs.h>
#include <awxs.m>
#include <awxs.def>

#include "Av_CharPtrPtr.h"
#include "exttypes.h"
#include "HashToEvent.h"
#include "EventToHash.h"
#include "TypeDefToHash.h"
#include "Util.h"



BrokerBoolean BrokerCallbackFunc ( BrokerClient cbClient, BrokerEvent cbEvent, void * vcb );


/*  gErr is an internal err tracker, its value is always the last BrokerError
 *  created.  Since we can not throw exceptions and not all routines will
 *  return errors on failure (creation of a new object returns undef on failure
 *  and sometimes (clients) we want to know why) we on occasion need this.
 *
 *  We can check values of the last error thru calls to Aw::Error methods
 *  without any arguements:
 *
 *   if ( Aw::Error::getCode == AW_ERROR_CLIENT_EXISTS )
 *
 */
BrokerError gErr = AW_NO_ERROR;
char * gErrMsg   = NULL;
int gErrCode     = 0;
awaBool gWarn    = awaFalse;



/*  gHandle is an auxilarly AdapterHandle pointer to simple ALIASed code
 *  where both xsAdapter and xsAdapterUtil datatypes get used.  Using the
 *  "global handle" should reduce the code size overall as numerous local
 *  handle pointers need not be created.
 *
 */
awAdapterHandle * gHandle = NULL;


static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AW_AUTO_SIZE"))
#ifdef AW_AUTO_SIZE
	    return AW_AUTO_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ACK_NONE"))
#ifdef AW_ACK_NONE
	    return AW_ACK_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ACK_AUTOMATIC"))
#ifdef AW_ACK_AUTOMATIC
	    return AW_ACK_AUTOMATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ACK_THROUGH"))
#ifdef AW_ACK_THROUGH
	    return AW_ACK_THROUGH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ACK_SELECTIVE"))
#ifdef AW_ACK_SELECTIVE
	    return AW_ACK_SELECTIVE;
#else
	    goto not_there;
#endif
    switch (name[3]) {
    case 'C':
	if (strEQ(name, "AW_CONNECT_STATE_CONNECTED"))
#ifdef AW_CONNECT_STATE_CONNECTED
	    return AW_CONNECT_STATE_CONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_CONNECT_STATE_DISCONNECTED"))
#ifdef AW_CONNECT_STATE_DISCONNECTED
	    return AW_CONNECT_STATE_DISCONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_CONNECT_STATE_RECONNECTED"))
#ifdef AW_CONNECT_STATE_RECONNECTED
	    return AW_CONNECT_STATE_RECONNECTED;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "AW_ENCRYPT_LEVEL_NO_ENCRYPTION"))
#ifdef AW_ENCRYPT_LEVEL_NO_ENCRYPTION
	    return AW_ENCRYPT_LEVEL_NO_ENCRYPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ENCRYPT_LEVEL_US_DOMESTIC"))
#ifdef AW_ENCRYPT_LEVEL_US_DOMESTIC
	    return AW_ENCRYPT_LEVEL_US_DOMESTIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ENCRYPT_LEVEL_US_EXPORT"))
#ifdef AW_ENCRYPT_LEVEL_US_EXPORT
	    return AW_ENCRYPT_LEVEL_US_EXPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ENTIRE_SEQUENCE"))
#ifdef AW_ENTIRE_SEQUENCE
	    return AW_ENTIRE_SEQUENCE;
#else
	    goto not_there;
#endif
    switch (name[9]) {
    case 'B':
	if (strEQ(name, "AW_ERROR_BAD_STATE"))
#ifdef AW_ERROR_BAD_STATE
	    return AW_ERROR_BAD_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_BROKER_EXISTS"))
#ifdef AW_ERROR_BROKER_EXISTS
	    return AW_ERROR_BROKER_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_BROKER_FAILURE"))
#ifdef AW_ERROR_BROKER_FAILURE
	    return AW_ERROR_BROKER_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_BROKER_NOT_RUNNING"))
#ifdef AW_ERROR_BROKER_NOT_RUNNING
	    return AW_ERROR_BROKER_NOT_RUNNING;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	if (strEQ(name, "AW_ERROR_CLIENT_CONTENTION"))
#ifdef AW_ERROR_CLIENT_CONTENTION
	    return AW_ERROR_CLIENT_CONTENTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_CLIENT_EXISTS"))
#ifdef AW_ERROR_CLIENT_EXISTS
	    return AW_ERROR_CLIENT_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_CLIENT_GROUP_EXISTS"))
#ifdef AW_ERROR_CLIENT_GROUP_EXISTS
	    return AW_ERROR_CLIENT_GROUP_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_COMM_FAILURE"))
#ifdef AW_ERROR_COMM_FAILURE
	    return AW_ERROR_COMM_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_CONNECTION_CLOSED"))
#ifdef AW_ERROR_CONNECTION_CLOSED
	    return AW_ERROR_CONNECTION_CLOSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_CORRUPT"))
#ifdef AW_ERROR_CORRUPT
	    return AW_ERROR_CORRUPT;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "AW_ERROR_DEPENDENCY"))
#ifdef AW_ERROR_DEPENDENCY
	    return AW_ERROR_DEPENDENCY;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "AW_ERROR_FIELD_NOT_FOUND"))
#ifdef AW_ERROR_FIELD_NOT_FOUND
	    return AW_ERROR_FIELD_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_FIELD_TYPE_MISMATCH"))
#ifdef AW_ERROR_FIELD_TYPE_MISMATCH
	    return AW_ERROR_FIELD_TYPE_MISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_FILE_NOT_FOUND"))
#ifdef AW_ERROR_FILE_NOT_FOUND
	    return AW_ERROR_FILE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_FILTER_PARSE"))
#ifdef AW_ERROR_FILTER_PARSE
	    return AW_ERROR_FILTER_PARSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_FILTER_RUNTIME"))
#ifdef AW_ERROR_FILTER_RUNTIME
	    return AW_ERROR_FILTER_RUNTIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_FORMAT"))
#ifdef AW_ERROR_FORMAT
	    return AW_ERROR_FORMAT;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	if (strEQ(name, "AW_ERROR_HOST_NOT_FOUND"))
#ifdef AW_ERROR_HOST_NOT_FOUND
	    return AW_ERROR_HOST_NOT_FOUND;
#else
	    goto not_there;
#endif
	break;
    case 'I':
	if (strEQ(name, "AW_ERROR_INCOMPATIBLE_VERSION"))
#ifdef AW_ERROR_INCOMPATIBLE_VERSION
	    return AW_ERROR_INCOMPATIBLE_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INPUT_PARSE"))
#ifdef AW_ERROR_INPUT_PARSE
	    return AW_ERROR_INPUT_PARSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INTERRUPTED"))
#ifdef AW_ERROR_INTERRUPTED
	    return AW_ERROR_INTERRUPTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_ACCESS_LIST"))
#ifdef AW_ERROR_INVALID_ACCESS_LIST
	    return AW_ERROR_INVALID_ACCESS_LIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_ACKNOWLEDGEMENT"))
#ifdef AW_ERROR_INVALID_ACKNOWLEDGEMENT
	    return AW_ERROR_INVALID_ACKNOWLEDGEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_BROKER_NAME"))
#ifdef AW_ERROR_INVALID_BROKER_NAME
	    return AW_ERROR_INVALID_BROKER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_CLIENT"))
#ifdef AW_ERROR_INVALID_CLIENT
	    return AW_ERROR_INVALID_CLIENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_CLIENT_GROUP_NAME"))
#ifdef AW_ERROR_INVALID_CLIENT_GROUP_NAME
	    return AW_ERROR_INVALID_CLIENT_GROUP_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_CLIENT_ID"))
#ifdef AW_ERROR_INVALID_CLIENT_ID
	    return AW_ERROR_INVALID_CLIENT_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_DESCRIPTOR"))
#ifdef AW_ERROR_INVALID_DESCRIPTOR
	    return AW_ERROR_INVALID_DESCRIPTOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_EVENT"))
#ifdef AW_ERROR_INVALID_EVENT
	    return AW_ERROR_INVALID_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_EVENT_TYPE_NAME"))
#ifdef AW_ERROR_INVALID_EVENT_TYPE_NAME
	    return AW_ERROR_INVALID_EVENT_TYPE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_FIELD_NAME"))
#ifdef AW_ERROR_INVALID_FIELD_NAME
	    return AW_ERROR_INVALID_FIELD_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_FILTER"))
#ifdef AW_ERROR_INVALID_FILTER
	    return AW_ERROR_INVALID_FILTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_LICENSE"))
#ifdef AW_ERROR_INVALID_LICENSE
	    return AW_ERROR_INVALID_LICENSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_LOG_CONFIG"))
#ifdef AW_ERROR_INVALID_LOG_CONFIG
	    return AW_ERROR_INVALID_LOG_CONFIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_NAME"))
#ifdef AW_ERROR_INVALID_NAME
	    return AW_ERROR_INVALID_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_PERMISSION"))
#ifdef AW_ERROR_INVALID_PERMISSION
	    return AW_ERROR_INVALID_PERMISSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_PLATFORM_KEY"))
#ifdef AW_ERROR_INVALID_PLATFORM_KEY
	    return AW_ERROR_INVALID_PLATFORM_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_PORT"))
#ifdef AW_ERROR_INVALID_PORT
	    return AW_ERROR_INVALID_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_SUBSCRIPTION"))
#ifdef AW_ERROR_INVALID_SUBSCRIPTION
	    return AW_ERROR_INVALID_SUBSCRIPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_TERRITORY_NAME"))
#ifdef AW_ERROR_INVALID_TERRITORY_NAME
	    return AW_ERROR_INVALID_TERRITORY_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_TYPE"))
#ifdef AW_ERROR_INVALID_TYPE
	    return AW_ERROR_INVALID_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_TYPECACHE"))
#ifdef AW_ERROR_INVALID_TYPECACHE
	    return AW_ERROR_INVALID_TYPECACHE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_INVALID_TYPEDEF"))
#ifdef AW_ERROR_INVALID_TYPEDEF
	    return AW_ERROR_INVALID_TYPEDEF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_IN_TERRITORY"))
#ifdef AW_ERROR_IN_TERRITORY
	    return AW_ERROR_IN_TERRITORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_NOT_IMPLEMENTED"))
#ifdef AW_ERROR_NOT_IMPLEMENTED
	    return AW_ERROR_NOT_IMPLEMENTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_NOT_IN_TERRITORY"))
#ifdef AW_ERROR_NOT_IN_TERRITORY
	    return AW_ERROR_NOT_IN_TERRITORY;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "AW_ERROR_NO_MEMORY"))
#ifdef AW_ERROR_NO_MEMORY
	    return AW_ERROR_NO_MEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_NO_PERMISSION"))
#ifdef AW_ERROR_NO_PERMISSION
	    return AW_ERROR_NO_PERMISSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_NULL_PARAM"))
#ifdef AW_ERROR_NULL_PARAM
	    return AW_ERROR_NULL_PARAM;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "AW_ERROR_OUT_OF_RANGE"))
#ifdef AW_ERROR_OUT_OF_RANGE
	    return AW_ERROR_OUT_OF_RANGE;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "AW_ERROR_PROTOCOL"))
#ifdef AW_ERROR_PROTOCOL
	    return AW_ERROR_PROTOCOL;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "AW_ERROR_SECURITY"))
#ifdef AW_ERROR_SECURITY
	    return AW_ERROR_SECURITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_SUBSCRIPTION_EXISTS"))
#ifdef AW_ERROR_SUBSCRIPTION_EXISTS
	    return AW_ERROR_SUBSCRIPTION_EXISTS;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "AW_ERROR_TIMEOUT"))
#ifdef AW_ERROR_TIMEOUT
	    return AW_ERROR_TIMEOUT;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	if (strEQ(name, "AW_ERROR_UNKNOWN"))
#ifdef AW_ERROR_UNKNOWN
	    return AW_ERROR_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_BROKER_NAME"))
#ifdef AW_ERROR_UNKNOWN_BROKER_NAME
	    return AW_ERROR_UNKNOWN_BROKER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_CLIENT_GROUP"))
#ifdef AW_ERROR_UNKNOWN_CLIENT_GROUP
	    return AW_ERROR_UNKNOWN_CLIENT_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_CLIENT_ID"))
#ifdef AW_ERROR_UNKNOWN_CLIENT_ID
	    return AW_ERROR_UNKNOWN_CLIENT_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_EVENT_TYPE"))
#ifdef AW_ERROR_UNKNOWN_EVENT_TYPE
	    return AW_ERROR_UNKNOWN_EVENT_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_INFOSET"))
#ifdef AW_ERROR_UNKNOWN_INFOSET
	    return AW_ERROR_UNKNOWN_INFOSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_KEY"))
#ifdef AW_ERROR_UNKNOWN_KEY
	    return AW_ERROR_UNKNOWN_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_NAME"))
#ifdef AW_ERROR_UNKNOWN_NAME
	    return AW_ERROR_UNKNOWN_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_SERVER"))
#ifdef AW_ERROR_UNKNOWN_SERVER
	    return AW_ERROR_UNKNOWN_SERVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_SESSION_ID"))
#ifdef AW_ERROR_UNKNOWN_SESSION_ID
	    return AW_ERROR_UNKNOWN_SESSION_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_ERROR_UNKNOWN_TERRITORY"))
#ifdef AW_ERROR_UNKNOWN_TERRITORY
	    return AW_ERROR_UNKNOWN_TERRITORY;
#else
	    goto not_there;
#endif
	}
	break;
    case 'I':
	if (strEQ(name, "AW_INFINITE"))
#ifdef AW_INFINITE
	    return AW_INFINITE;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "AW_NO_ERROR"))
#ifdef AW_NO_ERROR
	    return ((double)0x00000000);
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_NO_SHARE_LIMIT"))
#ifdef AW_NO_SHARE_LIMIT
	    return AW_NO_SHARE_LIMIT;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	if (strEQ(name, "AW_PLATFORM_AIX"))
#ifdef AW_PLATFORM_AIX
	    return AW_PLATFORM_AIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_ANY"))
#ifdef AW_PLATFORM_ANY
	    return AW_PLATFORM_ANY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_DEC"))
#ifdef AW_PLATFORM_DEC
	    return AW_PLATFORM_DEC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_HPUX"))
#ifdef AW_PLATFORM_HPUX
	    return AW_PLATFORM_HPUX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_IRIX"))
#ifdef AW_PLATFORM_IRIX
	    return AW_PLATFORM_IRIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_SOLARIS"))
#ifdef AW_PLATFORM_SOLARIS
	    return AW_PLATFORM_SOLARIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_PLATFORM_WINDOWS"))
#ifdef AW_PLATFORM_WINDOWS
	    return AW_PLATFORM_WINDOWS;
#else
	    goto not_there;
#endif
	break;
    case 'R':
	if (strEQ(name, "AW_REPLY_FLAG_CONTINUE"))
#ifdef AW_REPLY_FLAG_CONTINUE
	    return AW_REPLY_FLAG_CONTINUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_REPLY_FLAG_END"))
#ifdef AW_REPLY_FLAG_END
	    return AW_REPLY_FLAG_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_REPLY_FLAG_START"))
#ifdef AW_REPLY_FLAG_START
	    return AW_REPLY_FLAG_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_REPLY_FLAG_START_AND_END"))
#ifdef AW_REPLY_FLAG_START_AND_END
	    return AW_REPLY_FLAG_START_AND_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_RETRIEVE_ALL"))
#ifdef AW_RETRIEVE_ALL
	    return AW_RETRIEVE_ALL;
#else
	    goto not_there;
#endif
	break;
    case 'S':
/*
	if (strEQ(name, "AW_SHARED_ORDER_NONE"))
#ifdef AW_SHARED_ORDER_NONE
	    return AW_SHARED_ORDER_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SHARED_ORDER_BY_PUBLISHER"))
#ifdef AW_SHARED_ORDER_BY_PUBLISHER
	    return AW_SHARED_ORDER_BY_PUBLISHER;
#else
	    goto not_there;
#endif
*/
	if (strEQ(name, "AW_STORAGE_GUARANTEED"))
#ifdef AW_STORAGE_GUARANTEED
	    return AW_STORAGE_GUARANTEED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_STORAGE_PERSISTENT"))
#ifdef AW_STORAGE_PERSISTENT
	    return AW_STORAGE_PERSISTENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_STORAGE_VOLATILE"))
#ifdef AW_STORAGE_VOLATILE
	    return AW_STORAGE_VOLATILE;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "AW_TRANSACTION_LEVEL_ANY"))
#ifdef AW_TRANSACTION_LEVEL_ANY
	    return AW_TRANSACTION_LEVEL_ANY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_LEVEL_BASIC"))
#ifdef AW_TRANSACTION_LEVEL_BASIC
	    return AW_TRANSACTION_LEVEL_BASIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_LEVEL_CONVERSATIONAL"))
#ifdef AW_TRANSACTION_LEVEL_CONVERSATIONAL
	    return AW_TRANSACTION_LEVEL_CONVERSATIONAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_LEVEL_NONE"))
#ifdef AW_TRANSACTION_LEVEL_NONE
	    return AW_TRANSACTION_LEVEL_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_LEVEL_PSEUDO"))
#ifdef AW_TRANSACTION_LEVEL_PSEUDO
	    return AW_TRANSACTION_LEVEL_PSEUDO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_MODE_COMMIT"))
#ifdef AW_TRANSACTION_MODE_COMMIT
	    return AW_TRANSACTION_MODE_COMMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_MODE_ROLLBACK"))
#ifdef AW_TRANSACTION_MODE_ROLLBACK
	    return AW_TRANSACTION_MODE_ROLLBACK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRANSACTION_MODE_SAVEPOINT"))
#ifdef AW_TRANSACTION_MODE_SAVEPOINT
	    return AW_TRANSACTION_MODE_SAVEPOINT;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	break;
    case 'V':
	if (strEQ(name, "AW_VALIDATE_BAD_LICENSE"))
#ifdef AW_VALIDATE_BAD_LICENSE
	    return AW_VALIDATE_BAD_LICENSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VALIDATE_BAD_PLATFORM"))
#ifdef AW_VALIDATE_BAD_PLATFORM
	    return AW_VALIDATE_BAD_PLATFORM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VALIDATE_BAD_PRODUCT"))
#ifdef AW_VALIDATE_BAD_PRODUCT
	    return AW_VALIDATE_BAD_PRODUCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VALIDATE_BAD_VERSION"))
#ifdef AW_VALIDATE_BAD_VERSION
	    return AW_VALIDATE_BAD_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VALIDATE_EXPIRED"))
#ifdef AW_VALIDATE_EXPIRED
	    return AW_VALIDATE_EXPIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VALIDATE_OKAY"))
#ifdef AW_VALIDATE_OKAY
	    return AW_VALIDATE_OKAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_VERSION"))
#ifdef AW_VERSION
	    return AW_VERSION;
#else
	    goto not_there;
#endif
	break;
    }
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "CAT_ADAPTER"))
#ifdef CAT_ADAPTER
	    return CAT_ADAPTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_APPLICATION"))
#ifdef CAT_APPLICATION
	    return CAT_APPLICATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_BROKER"))
#ifdef CAT_BROKER
	    return CAT_BROKER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_DEBUG"))
#ifdef CAT_DEBUG
	    return CAT_DEBUG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_FILLER10"))
#ifdef CAT_FILLER10
	    return CAT_FILLER10;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_FILLER9"))
#ifdef CAT_FILLER9
	    return CAT_FILLER9;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_KERNEL"))
#ifdef CAT_KERNEL
	    return CAT_KERNEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_MONITOR"))
#ifdef CAT_MONITOR
	    return CAT_MONITOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_SYSTEM"))
#ifdef CAT_SYSTEM
	    return CAT_SYSTEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CAT_TIMEOUT"))
#ifdef CAT_TIMEOUT
	    return CAT_TIMEOUT;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DEFAULT_TRANSACTION_TIMEOUT"))
#ifdef DEFAULT_TRANSACTION_TIMEOUT
	    return DEFAULT_TRANSACTION_TIMEOUT;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "ERR_ADAPTER_SUBS"))
#ifdef ERR_ADAPTER_SUBS
	    return ERR_ADAPTER_SUBS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_BAD_LICENSE"))
#ifdef ERR_BAD_LICENSE
	    return ERR_BAD_LICENSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_CREATE_CLIENT"))
#ifdef ERR_CREATE_CLIENT
	    return ERR_CREATE_CLIENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_GET_ADAPTER_INFO"))
#ifdef ERR_GET_ADAPTER_INFO
	    return ERR_GET_ADAPTER_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_GET_EVENTS"))
#ifdef ERR_GET_EVENTS
	    return ERR_GET_EVENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_LICENSE_BAD_PLATFORM"))
#ifdef ERR_LICENSE_BAD_PLATFORM
	    return ERR_LICENSE_BAD_PLATFORM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_LICENSE_BAD_PRODUCT"))
#ifdef ERR_LICENSE_BAD_PRODUCT
	    return ERR_LICENSE_BAD_PRODUCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_LICENSE_BAD_VERSION"))
#ifdef ERR_LICENSE_BAD_VERSION
	    return ERR_LICENSE_BAD_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_LICENSE_EXPIRED"))
#ifdef ERR_LICENSE_EXPIRED
	    return ERR_LICENSE_EXPIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_LICENSE_WILL_EXPIRE"))
#ifdef ERR_LICENSE_WILL_EXPIRE
	    return ERR_LICENSE_WILL_EXPIRE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_PANIC"))
#ifdef ERR_PANIC
	    return ERR_PANIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_PUBLISH_ADAPTER_ERROR"))
#ifdef ERR_PUBLISH_ADAPTER_ERROR
	    return ERR_PUBLISH_ADAPTER_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_PUBLISH_STATUS"))
#ifdef ERR_PUBLISH_STATUS
	    return ERR_PUBLISH_STATUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_SSL_DESCRIPTOR"))
#ifdef ERR_SSL_DESCRIPTOR
	    return ERR_SSL_DESCRIPTOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERR_SUBSCRIPTION_ERROR"))
#ifdef ERR_SUBSCRIPTION_ERROR
	    return ERR_SUBSCRIPTION_ERROR;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "FIELD_TYPE_BOOLEAN"))
#ifdef FIELD_TYPE_BOOLEAN
	    return FIELD_TYPE_BOOLEAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_BYTE"))
#ifdef FIELD_TYPE_BYTE
	    return FIELD_TYPE_BYTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_CHAR"))
#ifdef FIELD_TYPE_CHAR
	    return FIELD_TYPE_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_DATE"))
#ifdef FIELD_TYPE_DATE
	    return FIELD_TYPE_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_DOUBLE"))
#ifdef FIELD_TYPE_DOUBLE
	    return FIELD_TYPE_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_EVENT"))
#ifdef FIELD_TYPE_EVENT
	    return FIELD_TYPE_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_FLOAT"))
#ifdef FIELD_TYPE_FLOAT
	    return FIELD_TYPE_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_INT"))
#ifdef FIELD_TYPE_INT
	    return FIELD_TYPE_INT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_LONG"))
#ifdef FIELD_TYPE_LONG
	    return FIELD_TYPE_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_SEQUENCE"))
#ifdef FIELD_TYPE_SEQUENCE
	    return FIELD_TYPE_SEQUENCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_SHORT"))
#ifdef FIELD_TYPE_SHORT
	    return FIELD_TYPE_SHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_STRING"))
#ifdef FIELD_TYPE_STRING
	    return FIELD_TYPE_STRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_STRUCT"))
#ifdef FIELD_TYPE_STRUCT
	    return FIELD_TYPE_STRUCT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_UNICODE_CHAR"))
#ifdef FIELD_TYPE_UNICODE_CHAR
	    return FIELD_TYPE_UNICODE_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_UNICODE_STRING"))
#ifdef FIELD_TYPE_UNICODE_STRING
	    return FIELD_TYPE_UNICODE_STRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIELD_TYPE_UNKNOWN"))
#ifdef FIELD_TYPE_UNKNOWN
	    return FIELD_TYPE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FORWARD_ERROR_REQUEST"))
#ifdef FORWARD_ERROR_REQUEST
	    return FORWARD_ERROR_REQUEST;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	if (strEQ(name, "GENERIC_ALERT"))
#ifdef GENERIC_ALERT
	    return GENERIC_ALERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GENERIC_INFO"))
#ifdef GENERIC_INFO
	    return GENERIC_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "GENERIC_WARNING"))
#ifdef GENERIC_WARNING
	    return GENERIC_WARNING;
#else
	    goto not_there;
#endif
	break;
    case 'H':
	break;
    case 'I':
	if (strEQ(name, "INFO_ADD_NOTIFY_EVENT"))
#ifdef INFO_ADD_NOTIFY_EVENT
	    return INFO_ADD_NOTIFY_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_ADD_REQUEST_EVENT"))
#ifdef INFO_ADD_REQUEST_EVENT
	    return INFO_ADD_REQUEST_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_CLEANUP_EVENTTYPE"))
#ifdef INFO_CLEANUP_EVENTTYPE
	    return INFO_CLEANUP_EVENTTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_FORWARD_REQUEST"))
#ifdef INFO_FORWARD_REQUEST
	    return INFO_FORWARD_REQUEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_PROCESS_PUBLICATION"))
#ifdef INFO_PROCESS_PUBLICATION
	    return INFO_PROCESS_PUBLICATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_RECEIVED_REQUEST"))
#ifdef INFO_RECEIVED_REQUEST
	    return INFO_RECEIVED_REQUEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INFO_TEST_BROKER"))
#ifdef INFO_TEST_BROKER
	    return INFO_TEST_BROKER;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MSG_CREATE_EVENT"))
#ifdef MSG_CREATE_EVENT
	    return MSG_CREATE_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_DELIVER_ERROR"))
#ifdef MSG_DELIVER_ERROR
	    return MSG_DELIVER_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_DELIVER_REPLY_ERROR"))
#ifdef MSG_DELIVER_REPLY_ERROR
	    return MSG_DELIVER_REPLY_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_DELIVER_STATUS"))
#ifdef MSG_DELIVER_STATUS
	    return MSG_DELIVER_STATUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FIELD_SET_ERROR"))
#ifdef MSG_FIELD_SET_ERROR
	    return MSG_FIELD_SET_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FIELD_SET_NOT_SUPPORTED"))
#ifdef MSG_FIELD_SET_NOT_SUPPORTED
	    return MSG_FIELD_SET_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FIELD_SET_NO_FORMAT"))
#ifdef MSG_FIELD_SET_NO_FORMAT
	    return MSG_FIELD_SET_NO_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FORMAT_ERROR"))
#ifdef MSG_FORMAT_ERROR
	    return MSG_FORMAT_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FORWARD_SET_FIELDS"))
#ifdef MSG_FORWARD_SET_FIELDS
	    return MSG_FORWARD_SET_FIELDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_FORWARD_TO_SESSION"))
#ifdef MSG_FORWARD_TO_SESSION
	    return MSG_FORWARD_TO_SESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_GET_EVENT_FIELD"))
#ifdef MSG_GET_EVENT_FIELD
	    return MSG_GET_EVENT_FIELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_GET_FAMILY_NAMES"))
#ifdef MSG_GET_FAMILY_NAMES
	    return MSG_GET_FAMILY_NAMES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_INFOSET_ENTRY_ERROR"))
#ifdef MSG_INFOSET_ENTRY_ERROR
	    return MSG_INFOSET_ENTRY_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_INFOSET_ENTRY_MISSING"))
#ifdef MSG_INFOSET_ENTRY_MISSING
	    return MSG_INFOSET_ENTRY_MISSING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NOTIFICATION_NOT_SUPPORTED"))
#ifdef MSG_NOTIFICATION_NOT_SUPPORTED
	    return MSG_NOTIFICATION_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_CAN_PUBLISH"))
#ifdef MSG_NO_CAN_PUBLISH
	    return MSG_NO_CAN_PUBLISH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_CAN_PUBLISH_REPLY"))
#ifdef MSG_NO_CAN_PUBLISH_REPLY
	    return MSG_NO_CAN_PUBLISH_REPLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_CAN_SUBSCRIBE"))
#ifdef MSG_NO_CAN_SUBSCRIBE
	    return MSG_NO_CAN_SUBSCRIBE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_CAN_SUBSCRIBE_REPLY"))
#ifdef MSG_NO_CAN_SUBSCRIBE_REPLY
	    return MSG_NO_CAN_SUBSCRIBE_REPLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_REFRESH_FAMILY"))
#ifdef MSG_NO_REFRESH_FAMILY
	    return MSG_NO_REFRESH_FAMILY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_TRANS_ID"))
#ifdef MSG_NO_TRANS_ID
	    return MSG_NO_TRANS_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_TRANS_MODE"))
#ifdef MSG_NO_TRANS_MODE
	    return MSG_NO_TRANS_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_TYPE_DEF"))
#ifdef MSG_NO_TYPE_DEF
	    return MSG_NO_TYPE_DEF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_NO_TYPE_DEF_REPLY"))
#ifdef MSG_NO_TYPE_DEF_REPLY
	    return MSG_NO_TYPE_DEF_REPLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_PUBLISH_ERROR"))
#ifdef MSG_PUBLISH_ERROR
	    return MSG_PUBLISH_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_PUBLISH_REPLY_ERROR"))
#ifdef MSG_PUBLISH_REPLY_ERROR
	    return MSG_PUBLISH_REPLY_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_RETRIEVE_EVENT_TYPES"))
#ifdef MSG_RETRIEVE_EVENT_TYPES
	    return MSG_RETRIEVE_EVENT_TYPES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_SET_EVENT_FIELD"))
#ifdef MSG_SET_EVENT_FIELD
	    return MSG_SET_EVENT_FIELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_SUBSCRIPTION_ERROR"))
#ifdef MSG_SUBSCRIPTION_ERROR
	    return MSG_SUBSCRIPTION_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANSACTION_COMMIT_MISSING"))
#ifdef MSG_TRANSACTION_COMMIT_MISSING
	    return MSG_TRANSACTION_COMMIT_MISSING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANSACTION_MODIFIED"))
#ifdef MSG_TRANSACTION_MODIFIED
	    return MSG_TRANSACTION_MODIFIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANSACTION_NOACK"))
#ifdef MSG_TRANSACTION_NOACK
	    return MSG_TRANSACTION_NOACK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANSACTION_TIMEOUT"))
#ifdef MSG_TRANSACTION_TIMEOUT
	    return MSG_TRANSACTION_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANS_LEVEL_MISMATCH"))
#ifdef MSG_TRANS_LEVEL_MISMATCH
	    return MSG_TRANS_LEVEL_MISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANS_MODE_NOT_SUPPORTED"))
#ifdef MSG_TRANS_MODE_NOT_SUPPORTED
	    return MSG_TRANS_MODE_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MSG_TRANS_NOT_ACTIVE"))
#ifdef MSG_TRANS_NOT_ACTIVE
	    return MSG_TRANS_NOT_ACTIVE;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "PLACE_HOLDER1"))
#ifdef PLACE_HOLDER1
	    return PLACE_HOLDER1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER10"))
#ifdef PLACE_HOLDER10
	    return PLACE_HOLDER10;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER11"))
#ifdef PLACE_HOLDER11
	    return PLACE_HOLDER11;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER12"))
#ifdef PLACE_HOLDER12
	    return PLACE_HOLDER12;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER13"))
#ifdef PLACE_HOLDER13
	    return PLACE_HOLDER13;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER14"))
#ifdef PLACE_HOLDER14
	    return PLACE_HOLDER14;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER15"))
#ifdef PLACE_HOLDER15
	    return PLACE_HOLDER15;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER16"))
#ifdef PLACE_HOLDER16
	    return PLACE_HOLDER16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER2"))
#ifdef PLACE_HOLDER2
	    return PLACE_HOLDER2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER3"))
#ifdef PLACE_HOLDER3
	    return PLACE_HOLDER3;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER34"))
#ifdef PLACE_HOLDER34
	    return PLACE_HOLDER34;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER35"))
#ifdef PLACE_HOLDER35
	    return PLACE_HOLDER35;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER36"))
#ifdef PLACE_HOLDER36
	    return PLACE_HOLDER36;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER37"))
#ifdef PLACE_HOLDER37
	    return PLACE_HOLDER37;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER38"))
#ifdef PLACE_HOLDER38
	    return PLACE_HOLDER38;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER4"))
#ifdef PLACE_HOLDER4
	    return PLACE_HOLDER4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER5"))
#ifdef PLACE_HOLDER5
	    return PLACE_HOLDER5;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER6"))
#ifdef PLACE_HOLDER6
	    return PLACE_HOLDER6;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER7"))
#ifdef PLACE_HOLDER7
	    return PLACE_HOLDER7;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER8"))
#ifdef PLACE_HOLDER8
	    return PLACE_HOLDER8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "PLACE_HOLDER9"))
#ifdef PLACE_HOLDER9
	    return PLACE_HOLDER9;
#else
	    goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
   }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


char **
unshiftAndAvCharPtrPtr ( AV * strings, char * element )
{
char ** returnString;
int i = 0;
SV ** sv;
char * string;


	int count       = av_len ( strings ) + 2;
	returnString    = (char **)safemalloc ( count * sizeof( char * ) );

	returnString[0] = strdup ( element );

	for ( i=1; i<count; i++ ) {
		sv = av_fetch ( strings, i-1, 0 );  /* non mortal sv, so no leak */
		string = (char *)SvPV(*sv, PL_na);
		returnString[i] = strdup ( string );
	}

	return ( returnString );

}



#ifdef  NO_STRDUP
char *
strdup ( char * source )
{
char * target;

	target = (char *)safemalloc ( sizeof(char) * ( strlen(source) + 1 ) );

	strcpy ( target, source );

	return ( target );
}
#endif /* NO_STRDUP */



awAdapterProperties *
awxsHashToProperties ( HV * hv )
{
awAdapterProperties * props = awNewAdapterProperties ();
char *key;
HE *entry;
SV *sv;
int i, n;


	hv_iterinit ( hv );
	n = HvKEYS( hv );

	for ( i=0; i<n; i++ ) {
		entry = hv_iternext ( hv );
		key   = HeKEY ( entry );
		sv    = HeVAL ( entry );
#if !( AW_VERSION_31 || AW_VERSION_40 )
		if ( !strcmp ( key, "adaptercount" )
		     || !strcmp ( key, "adapterId" )
		     || !strcmp ( key, "brokerCheckInterval" )
		   ) {
			awAdapterSetIntegerProperty (props, key, (int)SvIV ( sv ) );
		}
		else if ( !strcmp ( key, "eventlog" )
			  || !strcmp ( key, "info" )
			  // || !strcmp ( key, "debug" )
			  || !strcmp ( key, "log_printf" )
			  || !strcmp ( key, "quiet" )
			  || !strcmp ( key, "sslEncrypted" )
			  || !strcmp ( key, "warning" )

			) {
			awAdapterSetBooleanProperty (props, key, (BrokerBoolean)SvIV ( sv ) );
		}
		else {
			if ( !strcmp ( key, "clientId" ) )
				key[6] = 'i';
			else if ( !strcmp ( key, "clientGroup" ) )
				key[6] = 'g';
			awAdapterSetProperty (props, key, SvPV ( sv, PL_na ) );
		}
#else
		awAdapterSetProperty (props, key, SvPV ( sv, PL_na ) );
#endif /* AW_VERSION_30 */
	}

	return ( props );
}


/**
 *   Forget this for now, there doesn't appear  to be
 *   a function for returning property datatypes anyway
 *
HV *
awxsPropertiesToHash ( awAdapterProperties * props )
{
HV * hv = newHV();

	bValue = awGetBooleanProperty ( key );
	iValue = awGetIntegerProperty ( key );
	strValue = awGetProperty ( key );

	sv = boolSV ( ((BrokerBoolean *)value)[i] );
	sv = newSViv ( *(IV*)((int*)value+i) );
	sv = newSVpv ( (char*)value, 0 );

	hv_store ( hv, key, strlen ( key ), sv, 0 );

	return ( newRV_noinc((SV*) hv) );
}

*/

/******************************************************************************\
**
**			BEGIN OF CALLBACK FUNCTIONS
**
**  These functions will each call the Perl method of the "self" adapter.
**
\******************************************************************************/


SV * OneAdapterRef;
xsAdapter * OneAdapter;

SV * OneAdapterETRef;
xsAdapterEventType * OneAdapterET;


awaBool
setupEvent ( awAdapterHandle * handle, awaBool allAdapters, awaBool canSubscribe, awaBool canPublish )
{
dSP;
SV *edsv, *resv;
awaBool i;
xsAdapterEventType * eventDef;
xsBrokerEvent * requestEvent;


	if (! (OneAdapter->firstCB & AWXS_SETUPEVENT) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_SETUPEVENT;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("setupEvent", 10)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return ( awaTrue );
		}
		else
			OneAdapter->callback |= AWXS_SETUPEVENT;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_SETUPEVENT) )
		return ( awaTrue );


	OneAdapter->handle = handle;


	eventDef = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
	if ( eventDef == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	eventDef->err    = AW_NO_ERROR;
	eventDef->errMsg = NULL;
	eventDef->Warn   = gWarn;

	eventDef->adapterET = handle->eventDef;
	edsv = sv_newmortal();
	sv_setref_pv( edsv, "Aw::EventType", (void*)eventDef );


	requestEvent = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
	if ( requestEvent == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	requestEvent->err    = AW_NO_ERROR;
	requestEvent->errMsg = NULL;
	requestEvent->Warn   = gWarn;

	requestEvent->event = handle->requestEvent;
	resv = sv_newmortal();
	sv_setref_pv( resv, "Aw::Event", (void*)requestEvent );


	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	XPUSHs(resv);
	XPUSHs(edsv);
	XPUSHs(sv_2mortal(newSViv(allAdapters)));
	XPUSHs(sv_2mortal(newSViv(canSubscribe)));
	XPUSHs(sv_2mortal(newSViv(canPublish)));
	PUTBACK;

	/* printf ("Hello From setupEvent Callback\n"); */
	perl_call_method( "setupEvent", G_SCALAR );

	SPAGAIN;
	PUTBACK;

	i = POPi;

	FREETMPS;
	LEAVE;	

	OneAdapter->handle = NULL;

	return ( i );

}


BrokerBoolean
processRequest ( awAdapterHandle * handle )
{
dSP;
SV *edsv, *resv;
xsAdapterEventType * eventDef;
xsBrokerEvent * requestEvent;


	if (! (OneAdapter->firstCB & AWXS_PROCESSREQUEST) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_PROCESSREQUEST;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("processRequest", 14)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return ( awaTrue );
		}
		else
			OneAdapter->callback |= AWXS_PROCESSREQUEST;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_PROCESSREQUEST) )
		return ( awaTrue );


	OneAdapter->handle = handle;


	eventDef = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
	if ( eventDef == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	eventDef->err    = AW_NO_ERROR;
	eventDef->errMsg = NULL;
	eventDef->Warn   = gWarn;

	eventDef->adapterET = handle->eventDef;
	edsv = sv_newmortal();
	sv_setref_pv( edsv, "Aw::EventType", (void*)eventDef );


	requestEvent = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
	if ( requestEvent == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	requestEvent->err    = AW_NO_ERROR;
	requestEvent->errMsg = NULL;
	requestEvent->Warn   = gWarn;

	requestEvent->event = handle->requestEvent;
	resv = sv_newmortal();
	sv_setref_pv( resv, "Aw::Event", (void*)requestEvent );


	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	XPUSHs(resv);
	XPUSHs(edsv);
	PUTBACK;

	/* printf ("Hello From processRequest Callback\n"); */
	perl_call_method( "processRequest", G_SCALAR );

	
	SPAGAIN;
	PUTBACK;

	OneAdapter->handle  = NULL;
	eventDef->adapterET = NULL;
	requestEvent->event = NULL;

/*
 * seems to be a bad idea with Perl 5.005, check again with 5.004 
 * 
	if ( SvREFCNT ( resv ) )
		SvREFCNT_dec ( resv );
	if ( SvREFCNT ( edsv ) )
		SvREFCNT_dec ( edsv );
*/

	return ( POPi );

}


void
cleanupEventType ( awAdapterHandle * handle )
{
dSP;
SV *edsv, *resv;
xsAdapterEventType * eventDef;
xsBrokerEvent * requestEvent;


	if (! (OneAdapter->firstCB & AWXS_CLEANUPEVENTTYPE) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_CLEANUPEVENTTYPE;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("cleanupEventType", 16)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return;
		}
		else
			OneAdapter->callback |= AWXS_CLEANUPEVENTTYPE;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_CLEANUPEVENTTYPE) )
		return;


	OneAdapter->handle = handle;

	eventDef = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
	if ( eventDef == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return;
	}
	/* initialize the error cleanly */
	eventDef->err    = AW_NO_ERROR;
	eventDef->errMsg = NULL;
	eventDef->Warn   = gWarn;

	eventDef->adapterET = handle->eventDef;
	edsv = sv_newmortal();
	sv_setref_pv( edsv, "Aw::EventType", (void*)eventDef );


	requestEvent = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
	if ( requestEvent == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return;
	}
	/* initialize the error cleanly */
	requestEvent->err    = AW_NO_ERROR;
	requestEvent->errMsg = NULL;
	requestEvent->Warn   = gWarn;

	requestEvent->event = handle->requestEvent;
	resv = sv_newmortal();
	sv_setref_pv( resv, "Aw::Event", (void*)requestEvent );

	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	XPUSHs(resv);
	XPUSHs(edsv);
	PUTBACK;

	/* printf ("Hello From cleanupEventType Callback\n"); */
	perl_call_method( "cleanupEventType", G_VOID );

	SPAGAIN;
	PUTBACK;

	OneAdapter->handle = NULL;

}



void
beginSetup ( awAdapterHandle * handle )
{
dSP;


	if (! (OneAdapter->firstCB & AWXS_BEGINSETUP) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_BEGINSETUP;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("beginSetup", 10)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return;
		}
		else
			OneAdapter->callback |= AWXS_BEGINSETUP;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_BEGINSETUP) )
		return;


	OneAdapter->handle = handle;

	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	PUTBACK;

	/* printf ("Hello From beginSetup Callback\n"); */
	perl_call_method( "beginSetup", G_VOID );


	OneAdapter->handle = NULL;

}



void
endSetup ( awAdapterHandle * handle )
{
dSP;


	if (! (OneAdapter->firstCB & AWXS_ENDSETUP) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_ENDSETUP;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("endSetup", 8)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return;
		}
		else
			OneAdapter->callback |= AWXS_ENDSETUP;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_ENDSETUP) )
		return;


	OneAdapter->handle = handle;

	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	PUTBACK;

	/* printf ("Hello From endSetup Callback\n"); */
	perl_call_method( "endSetup", G_VOID );

	OneAdapter->handle = NULL;

}



awaBool
processPublication ( awAdapterHandle * handle )
{
dSP;
awaBool i;
SV * sv;
xsAdapterEventType * eventDef;


	if (! (OneAdapter->firstCB & AWXS_PROCESSPUBLICATION) ) {
		OneAdapter->firstCB |= AWXS_PROCESSPUBLICATION;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("processPublication", 18)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return ( awaTrue );
		}
		else
			OneAdapter->callback |= AWXS_PROCESSPUBLICATION;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_PROCESSPUBLICATION) )
		return ( awaTrue );


	OneAdapter->handle = handle; 

	eventDef = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
	if ( eventDef == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
 		return awaFalse;
	}
	/* initialize the error cleanly */
	eventDef->err    = AW_NO_ERROR;
	eventDef->errMsg = NULL;

	eventDef->adapterET = handle->eventDef;

	sv = sv_newmortal();
	sv_setref_pv( sv, "Aw::EventType", (void*)eventDef );


	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	XPUSHs(sv);
	PUTBACK;

	/* printf ("Hello From processPublication Callback\n"); */
	i = perl_call_method ( "processPublication", G_SCALAR );

	SPAGAIN;
	PUTBACK;

	OneAdapter->handle  = NULL;
	eventDef->adapterET = NULL;

	if ( SvREFCNT ( sv ) )
		SvREFCNT_dec ( sv );

	return ( POPi );
}



awaBool
beginTransaction ( awAdapterHandle * handle )
{
dSP;
awaBool i;


	if (! (OneAdapter->firstCB & AWXS_BEGINTRANSACTION) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_BEGINTRANSACTION;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("beginTransaction", 16)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return ( awaTrue );
		}
		else
			OneAdapter->callback |= AWXS_BEGINTRANSACTION;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_BEGINTRANSACTION) )
		return ( awaTrue );


	OneAdapter->handle = handle;


	ENTER;
	SAVETMPS;

	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	if ( handle->transactionId )
		XPUSHs(sv_2mortal(newSVpv(handle->transactionId, 0)));
	else 
		XPUSHs( Nullsv );
		// XPUSHs( sv_2mortal( Nullsv ) );
	PUTBACK;

	/* printf ("Hello From beginTransaction Callback\n"); */
	perl_call_method( "beginTransaction", G_SCALAR );

	SPAGAIN;
	PUTBACK;

	i = (awaBool)POPi;

	FREETMPS;
	LEAVE;

	OneAdapter->handle = NULL;

	return ( i );

}



awaBool
endTransaction ( awAdapterHandle * handle, int commitMode )
{
dSP;
awaBool i;


	if (! (OneAdapter->firstCB & AWXS_ENDTRANSACTION) ) {
		SV * sv;
		OneAdapter->firstCB |= AWXS_ENDTRANSACTION;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("endTransaction", 14)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );
		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return ( awaTrue );
		}
		else
			OneAdapter->callback |= AWXS_ENDTRANSACTION;

		FREETMPS;
		LEAVE;
		/* printf ( "  SvTRUE endTransaction[%d]\n", OneAdapter->firstCB & AWXS_ENDTRANSACTION ); */
	}
	else if (! (OneAdapter->callback & AWXS_ENDTRANSACTION) )
		return ( awaTrue );


	OneAdapter->handle = handle;


	ENTER;
	SAVETMPS;

	PUSHMARK(sp);
	XPUSHs(OneAdapterRef);
	if ( handle->transactionId )
		XPUSHs(sv_2mortal(newSVpv(handle->transactionId, 0)));
	else 
		XPUSHs( Nullsv );
		// XPUSHs( sv_2mortal( Nullsv ) );
	XPUSHs(sv_2mortal(newSViv(commitMode)));
	PUTBACK;

	/* printf ("Hello From endTransaction Callback\n"); */
	perl_call_method( "endTransaction", G_SCALAR );

	SPAGAIN;
	PUTBACK;

	i = POPi;

	FREETMPS;
	LEAVE;

	OneAdapter->handle = NULL;

	return ( i );

}



void
userDataDelete ( void *userData )
{
dSP;


	if (! (OneAdapterET->callback & AWXS_CALLBACKTEST) ) {
		SV * sv;
		OneAdapterET->callback |= AWXS_CALLBACKTEST;
		ENTER;
		SAVETMPS;

		PUSHMARK(sp);
		XPUSHs(OneAdapterRef);
		XPUSHs(sv_2mortal(newSVpv("userDataDelete", 14)));
		PUTBACK;

		perl_call_method( "can", G_SCALAR );

		SPAGAIN;
		PUTBACK;

		sv = POPs;
		if (! SvTRUE( sv ) ) {
			FREETMPS;
			LEAVE;
			return;
		}
		else
			OneAdapterET->callback |= AWXS_USERDATADELETE;

		FREETMPS;
		LEAVE;
	}
	else if (! (OneAdapter->callback & AWXS_USERDATADELETE) )
		return;



	PUSHMARK(sp);
	/*
	 *  worry about this later when we have a real example of
	 *  "userData".  Presumably the userData pointer is going to
	 *  point to an HV.
	 *
	 *  XPUSHs(userData);
	 */
	XPUSHs(OneAdapterETRef);
	XPUSHs((SV*)userData);  /* assume were were passed an SV */
	PUTBACK;

	/* printf ("Hello From userDataDelete Callback\n"); */
	perl_call_method( "userDataDelete", G_VOID );

}


/*
 *  This could fail if the ->self reference was consumed by Perl's
 *  garbage collector before the callback is made.  Won't know till
 *  we try it...
 */
BrokerBoolean
BrokerCallbackFunc ( BrokerClient cbClient, BrokerEvent cbEvent, void * vcb )
{
dSP;
SV *esv, *csv;
xsCallBackStruct * cb;
xsBrokerEvent  * event;
xsBrokerClient * client;


	cb = (xsCallBackStruct *)vcb;


	event = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
	if ( event == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new broker event" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	event->err    = AW_NO_ERROR;
	event->errMsg = NULL;
	event->Warn   = gWarn;

	event->event = cbEvent;
	esv = sv_newmortal();
	sv_setref_pv( esv, "Aw::Event", (void*)event );


	client = (xsBrokerClient *)safemalloc ( sizeof(xsBrokerClient) );
	if ( event == NULL ) {
		setErrMsg ( &gErrMsg, 1, "unable to malloc new broker client" );
#ifdef AWXS_WARNS
		if ( gWarn )
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
 		return awaFalse;
	}
	/* initialize the error cleanly */
	client->err    = AW_NO_ERROR;
	client->errMsg = NULL;
	client->Warn   = gWarn;

	client->client = cbClient;
	csv = sv_newmortal();
	sv_setref_pv( csv, "Aw::Client", (void*)client );


	PUSHMARK(sp);
	XPUSHs( cb->self );
	XPUSHs( cb->data );
	XPUSHs( csv );
	XPUSHs( esv );
	PUTBACK;

	perl_call_method( cb->method, G_SCALAR );

	SPAGAIN;
	PUTBACK;

	return ( POPi );

}



void
BrokerConnectionCallbackFunc ( BrokerClient cbClient, int connect_status, void * vcb )
{
dSP;
SV *esv, *csv;
xsCallBackStruct * cb;
xsBrokerClient * client;


	cb = (xsCallBackStruct *)vcb;

	ENTER;
	SAVETMPS;

	PUSHMARK(sp);
	XPUSHs( cb->self );
	XPUSHs(sv_2mortal(newSViv(connect_status)));
	XPUSHs( cb->data );
	PUTBACK;

	/* Not checking method with "can", assume for now if method was registered that it exists */
	perl_call_method( cb->method, G_SCALAR );

	SPAGAIN;
	PUTBACK;

	FREETMPS;
	LEAVE;

}

/******************************************************************************\
**
**			END OF CALLBACK FUNCTIONS
**
\******************************************************************************/


/*
#=============================================================================*/

MODULE = Aw			PACKAGE = Aw

#===============================================================================


PROTOTYPES: DISABLE



BOOT:

	if ( (int)SvIV(perl_get_sv("Aw::SPAM", FALSE)) )
		printf ( "\nAw %s [%s] (c) <Yacob@wMUsers.Com>\n\n" ,
			 (char *)SvPV(perl_get_sv("Aw::VERSION", FALSE), PL_na),
			 (char *)SvPV(perl_get_sv("Aw::VERSION_NAME", FALSE), PL_na) );


double
constant ( name, arg )
	char *		name
	int		arg



int
getDiagnostics ( )

	CODE:
		RETVAL = awGetDiagnostics();

	OUTPUT:
	RETVAL



void
setDiagnostics ( diag )
	int diag

	CODE:
		awSetDiagnostics ( diag );



void
setWarnAll ( onOff )
	awaBool onOff

	CODE:
		gWarn = onOff;

void
showHash ( hash )
	HV* hash

	CODE:
		hashWalk (hash);

int
refcnt ( sv )

	CODE:
		RETVAL = SvREFCNT ( ST(0) );

	OUTPUT:
	RETVAL

void
free ( sv )

	CODE:
		//
		// decrement to 1 and not 0.  gc should kick in when we return
		// to script space.
		//
		while ( SvREFCNT ( ST(0) ) > 1 ) {
			SvREFCNT_dec ( ST(0) );
		}	



#===============================================================================

MODULE = Aw			PACKAGE = Aw::BaseClass

#===============================================================================

#===============================================================================
#  Aw::BaseClass
#      ::DESTROY
#      ::err   			ala Mysql::
#      ::errmsg			ala Mysql::
#      ::error
#      ::getErrCode
#      ::setErrMsg
#      ::getWarn
#      ::setWarn
#      ::hello
#      ::catch
#      ::throw
#      ::toString
#===============================================================================



void
DESTROY ( self )

	ALIAS:
		Aw::Adapter::DESTROY              =  1
		Aw::EventType::DESTROY            =  2
		Aw::Log::DESTROY                  =  3
		Aw::Util::DESTROY                 =  4
		Aw::Client::DESTROY               =  5
		Aw::ConnectionDescriptor::DESTROY =  6
		Aw::Date::DESTROY                 =  7
		Aw::Error::DESTROY                =  8
		Aw::Event::DESTROY                =  9
		Aw::Filter::DESTROY               = 10
		Aw::Format::DESTROY               = 11
		Aw::SSLCertificate::DESTROY       = 12
		Aw::Subscription::DESTROY         = 13
		Aw::TypeDef::DESTROY              = 14
		Aw::TypeDefCache::DESTROY         = 15
		Aw::License::DESTROY              = 16
		Aw::Replies::DESTROY              = 17

	CODE:
		switch ( ix ) 
		  {
			case  1: /* Adapter */
				{
				xsAdapter * self = AWXS_ADAPTER(0);
				awDeleteAdapter ( self->adapter );
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Adapter!" );
#endif /* AWXS_DEBUG */
				Safefree ( self );
				}
				break;

			case  2: /* AdapterET */
				/* awDeleteAdapterET ( self->adapterET );  DON'T DO THIS!! */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::EventType!" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_ADAPTEREVENTTYPE(0) );
				break;

			case  3: /* Aw::Log */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Log!" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_ADAPTERLOG(0) );
				break;

			case  4: /* AdapterUtil */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Util!\n" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_ADAPTERUTIL(0) );
				break;

			case  5: /* Client */
				{
				xsBrokerClient * self = AWXS_BROKERCLIENT(0);
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Client!\n" );
#endif /* AWXS_DEBUG */
				awDestroyClient ( self->client );
				Safefree ( self );
				}
				break;

			case  6: /* ConnectionDescription */
				{
				xsBrokerConnectionDescriptor * self = AWXS_BROKERCONNECTIONDESC(0);
				awDeleteDescriptor ( self->desc );
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::ConnectionDescriptor!" );
#endif /* AWXS_DEBUG */
				Safefree ( self );
				}
				break;

			case  7: /* Date */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Date!" );
#endif /* AWXS_DEBUG */
				awDeleteDate ( AWXS_BROKERDATE(0) );
				break;

			case  8: /* Error */
				{
				xsBrokerError * self = AWXS_BROKERERROR(0);
				awDeleteError ( self->err );
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Error!" );
#endif /* AWXS_DEBUG */
				Safefree ( self );
				}
				break;

			case  9: /* Event */
				{
				xsBrokerEvent * self = AWXS_BROKEREVENT(0);
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Event!" );
#endif /* AWXS_DEBUG */
				if ( self->deleteOk )
					awDeleteEvent ( self->event );
				Safefree ( self );
				}
				break;

			case 10: /* Filter */
				{
				xsBrokerFilter * self = AWXS_BROKERFILTER(0);
				awDeleteFilter ( self->filter );
				Safefree ( self );
				}
				break;

			case 11: /* Format */
				{
				xsBrokerFormat * self = AWXS_BROKERFORMAT(0);
				awEventFormatFree ( self->tokens );
				Safefree ( self );
				}
				break;

			case 12: /* SSLCertificate */
				Safefree ( AWXS_BROKERSSLCERTIFICATE(0) );
				break;

			case 13: /* Subscription */
				Safefree ( AWXS_BROKERSUBSCRIPTION(0) );
				break;

			case 14: /* TypeDef */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::TypeDef!" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_BROKERTYPEDEF(0) );
				break;

			case 15: /* TypeDefCache */
				Safefree ( AWXS_BROKERTYPEDEFCACHE(0) );
				break;

			case 16: /* License */
				Safefree ( AWXS_ADAPTERLICENSE(0) );
				break;

			case 17: /* Replies */
				Safefree ( AWXS_ADAPTERREPLIES(0) );
				break;

			default:
#ifdef    AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }



awaBool
err ( ... )

	ALIAS:
		Aw::err                       =  0
		Aw::Adapter::err              =  1
		Aw::EventType::err            =  2
		Aw::Util::err                 =  3
		Aw::Client::err               =  4
		Aw::ConnectionDescriptor::err =  5
		Aw::Event::err                =  6
		Aw::Error::err                =  7
		Aw::Filter::err               =  8
		Aw::Format::err               =  9
		Aw::TypeDef::err              = 10
		Aw::TypeDefCache::err         = 11

	CODE:
		BrokerError err = NULL;


		switch ( ix ) 
		  {
			case 0:
				err = gErr;
				break;

			case 1:
				err = AWXS_ADAPTER(0)->err;
				break;

			case 2:
				err = AWXS_ADAPTEREVENTTYPE(0)->err;
				break;

			case 3:
				err = AWXS_ADAPTERUTIL(0)->err;
				break;

			case 4:
				err = AWXS_BROKERCLIENT(0)->err;
				break;

			case 5:
				err = AWXS_BROKERCONNECTIONDESC(0)->err;
				break;

			case 6:
				err = AWXS_BROKEREVENT(0)->err;
				break;

			case 7:
				err = AWXS_BROKERERROR(0)->err;
				break;

			case 8:
				err = AWXS_BROKERFILTER(0)->err;
				break;

			case 9:
				err = AWXS_BROKERFORMAT(0)->err;
				break;

			case 10:
				err = AWXS_BROKERTYPEDEF(0)->err;
				break;

			case 11:
				err = AWXS_BROKERTYPEDEFCACHE(0)->err;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

		RETVAL = ( err != AW_NO_ERROR || gErrMsg ) ? awaTrue : awaFalse;

	OUTPUT:
	RETVAL



char *
errmsg ( ... )

	ALIAS:
		Aw::errmsg                          =  0
		Aw::Adapter::errmsg                 =  1
		Aw::EventType::errmsg               =  2
		Aw::Util::errmsg                    =  3
		Aw::Client::errmsg                  =  4
		Aw::ConnectionDescriptor::errmsg    =  5
		Aw::Event::errmsg                   =  6
		Aw::Error::errmsg                   =  7
		Aw::Filter::errmsg                  =  8
		Aw::Format::errmsg                  =  9
		Aw::TypeDef::errmsg                 = 10
		Aw::TypeDefCache::errmsg            = 11

		Aw::getErrMsg                       = 100
		Aw::Adapter::getErrMsg              = 101
		Aw::EventType::getErrMsg            = 102
		Aw::Util::getErrMsg                 = 103
		Aw::Client::getErrMsg               = 104
		Aw::ConnectionDescriptor::getErrMsg = 105
		Aw::Event::getErrMsg                = 106
		Aw::Error::getErrMsg                = 107
		Aw::Filter::getErrMsg               = 108
		Aw::Format::getErrMsg               = 109
		Aw::TypeDef::getErrMsg              = 110
		Aw::TypeDefCache::getErrMsg         = 111


	CODE:
		BrokerError err = AW_NO_ERROR;
		char * errMsg   = NULL;


		switch ( ix ) 
		  {
			case 0:
			case 100:
				err    = gErr;
				errMsg = gErrMsg;
				break;

			case 1:
			case 101:
				err    = AWXS_ADAPTER(0)->err;
				errMsg = AWXS_ADAPTER(0)->errMsg;
				break;

			case 2:
			case 102:
				err    = AWXS_ADAPTEREVENTTYPE(0)->err;
				errMsg = AWXS_ADAPTEREVENTTYPE(0)->errMsg;
				break;

			case 3:
			case 103:
				err    = AWXS_ADAPTERUTIL(0)->err;
				errMsg = AWXS_ADAPTERUTIL(0)->errMsg;
				break;

			case 4:
			case 104:
				err    = AWXS_BROKERCLIENT(0)->err;
				errMsg = AWXS_BROKERCLIENT(0)->errMsg;
				break;

			case 5:
			case 105:
				err    = AWXS_BROKERCONNECTIONDESC(0)->err;
				errMsg = AWXS_BROKERCONNECTIONDESC(0)->errMsg;
				break;

			case 6:
			case 106:
				err    = AWXS_BROKEREVENT(0)->err;
				errMsg = AWXS_BROKEREVENT(0)->errMsg;
				break;

			case 7:
			case 107:
				err    = AWXS_BROKERERROR(0)->err;
				errMsg = AWXS_BROKERERROR(0)->errMsg;
				break;

			case 8:
			case 108:
				err    = AWXS_BROKERFILTER(0)->err;
				errMsg = AWXS_BROKERFILTER(0)->errMsg;
				break;

			case 9:
			case 109:
				err    = AWXS_BROKERFORMAT(0)->err;
				errMsg = AWXS_BROKERFORMAT(0)->errMsg;
				break;

			case 10:
			case 110:
				err    = AWXS_BROKERTYPEDEF(0)->err;
				errMsg = AWXS_BROKERTYPEDEF(0)->errMsg;
				break;

			case 11:
			case 111:
				err    = AWXS_BROKERTYPEDEFCACHE(0)->err;
				errMsg = AWXS_BROKERTYPEDEFCACHE(0)->errMsg;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }


		/* if ( err == AW_NO_ERROR && errMsg ) */
		if ( errMsg )
			RETVAL = errMsg;
		else if ( err != AW_NO_ERROR )
			RETVAL = awErrorToCompleteString ( err );

		if ( RETVAL == NULL )
			XSRETURN_UNDEF;


	OUTPUT:
	RETVAL



void
setErrMsg ( self, newErrMsg )
	char * newErrMsg

	ALIAS:
		Aw::setErrMsg                       =  0
		Aw::Adapter::setErrMsg              =  1
		Aw::EventType::setErrMsg            =  2
		Aw::Util::setErrMsg                 =  3
		Aw::Client::setErrMsg               =  4
		Aw::ConnectionDescriptor::setErrMsg =  5
		Aw::Event::setErrMsg                =  6
		Aw::Error::setErrMsg                =  7
		Aw::Filter::setErrMsg               =  8
		Aw::Format::setErrMsg               =  9
		Aw::TypeDef::setErrMsg              = 10
		Aw::TypeDefCache::setErrMsg         = 11

	CODE:
		char ** errMsg;

		switch ( ix ) 
		  {
			case 0:
				errMsg =& gErrMsg;
				break;

			case 1:
				errMsg =& AWXS_ADAPTER(0)->errMsg;
				break;

			case 2:
				errMsg =& AWXS_ADAPTEREVENTTYPE(0)->errMsg;
				break;

			case 3:
				errMsg =& AWXS_ADAPTERUTIL(0)->errMsg;
				break;

			case 4:
				errMsg =& AWXS_BROKERCLIENT(0)->errMsg;
				break;

			case 5:
				errMsg =& AWXS_BROKERCONNECTIONDESC(0)->errMsg;
				break;

			case 6:
				errMsg =& AWXS_BROKEREVENT(0)->errMsg;
				break;

			case 7:
				errMsg =& AWXS_BROKERERROR(0)->errMsg;
				break;

			case 8:
				errMsg =& AWXS_BROKERFILTER(0)->errMsg;
				break;

			case 9:
				errMsg =& AWXS_BROKERFORMAT(0)->errMsg;
				break;

			case 10:
				errMsg =& AWXS_BROKERTYPEDEF(0)->errMsg;
				break;

			case 11:
				errMsg =& AWXS_BROKERTYPEDEFCACHE(0)->errMsg;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

		if ( *errMsg )
			Safefree ( *errMsg );

		gErrMsg = *errMsg = strdup ( newErrMsg );



void
throw ( self, newErrCode )
	int newErrCode

	ALIAS:
		Aw::throw                       =  0
		Aw::Adapter::throw              =  1
		Aw::EventType::throw            =  2
		Aw::Util::throw                 =  3
		Aw::Client::throw               =  4
		Aw::ConnectionDescriptor::throw =  5
		Aw::Event::throw                =  6
		Aw::Error::throw                =  7
		Aw::Filter::throw               =  8
		Aw::Format::throw               =  9
		Aw::TypeDef::throw              = 10
		Aw::TypeDefCache::throw         = 11

	PREINIT:
		char * strErrCode;

	CODE:
		gErrCode = newErrCode;
		strErrCode = (char *)safemalloc ( 8 * sizeof (char) );
		sprintf ( strErrCode, "%i", gErrCode );
		sv_setpv ( perl_get_sv("@",0), strErrCode );
		Safefree ( strErrCode );



int
catch ( ... )

	ALIAS:
		Aw::catch                       =  0
		Aw::Adapter::catch              =  1
		Aw::EventType::catch            =  2
		Aw::Util::catch                 =  3
		Aw::Client::catch               =  4
		Aw::ConnectionDescriptor::catch =  5
		Aw::Event::catch                =  6
		Aw::Error::catch                =  7
		Aw::Filter::catch               =  8
		Aw::Format::catch               =  9
		Aw::TypeDef::catch              = 10
		Aw::TypeDefCache::catch         = 11

	CODE:
		if ( items == 1 || (items == 2 && !SvOK(ST(1)) ) ) {
			if ( gErrCode == (int)AW_NO_ERROR )
				XSRETURN_UNDEF;

			RETVAL = gErrCode;
			/*
			   insert here a switch to do awGetErrorCode ( self->err )
			   or make a $self->getErrorCode method that works on self->err
			*/
		}
		else if ( SvTYPE(ST(1)) == SVt_PV ) {
			char *	exception = (char *)SvPV(ST(1),PL_na);
			RETVAL = ( strstr (gErrMsg, exception) ) ? awaTrue : awaFalse;
		}
		else {
			int exception = (int)SvIV(ST(1));
			RETVAL = ( exception == gErrCode ) ? awaTrue : awaFalse;
		}


	OUTPUT:
	RETVAL



int
getErrCode ( ... )

	ALIAS:
		Aw::getErrCode                       =  0
		Aw::Adapter::getErrCode              =  1
		Aw::EventType::getErrCode            =  2
		Aw::Util::getErrCode                 =  3
		Aw::Client::getErrCode               =  4
		Aw::ConnectionDescriptor::getErrCode =  5
		Aw::Event::getErrCode                =  6
		Aw::Filter::getErrCode               =  7
		Aw::Format::getErrCode               =  8
		Aw::TypeDef::getErrCode              =  9
		Aw::TypeDefCache::getErrCode         = 10


	CODE:


		switch ( ix ) 
		  {
			case 0:
				RETVAL = awGetErrorCode ( gErr );
				break;

			case 1:
				RETVAL = awGetErrorCode ( AWXS_ADAPTER(0)->err );
				break;

			case 2:
				RETVAL = awGetErrorCode ( AWXS_ADAPTEREVENTTYPE(0)->err );
				break;

			case 3:
				RETVAL = awGetErrorCode ( AWXS_ADAPTERUTIL(0)->err );
				break;

			case 4:
				RETVAL = awGetErrorCode ( AWXS_BROKERCLIENT(0)->err );
				break;

			case 5:
				RETVAL = awGetErrorCode ( AWXS_BROKERCONNECTIONDESC(0)->err );
				break;

			case 6:
				RETVAL = awGetErrorCode ( AWXS_BROKEREVENT(0)->err );
				break;

			case 7:
				RETVAL = awGetErrorCode ( AWXS_BROKERFILTER(0)->err );
				break;

			case 8:
				RETVAL = awGetErrorCode ( AWXS_BROKERFORMAT(0)->err );
				break;

			case 9:
				RETVAL = awGetErrorCode ( AWXS_BROKERTYPEDEF(0)->err );
				break;

			case 10:
				RETVAL = awGetErrorCode ( AWXS_BROKERTYPEDEFCACHE(0)->err );
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }


	OUTPUT:
	RETVAL



Aw::Error
error ( ... )

	ALIAS:
		Aw::error                       =  0
		Aw::Adapter::error              =  1
		Aw::EventType::error            =  2
		Aw::Util::error                 =  3
		Aw::Client::error               =  4
		Aw::ConnectionDescriptor::error =  5
		Aw::Event::error                =  6
		Aw::Filter::error               =  7
		Aw::Format::error               =  8
		Aw::TypeDef::error              =  9
		Aw::TypeDefCache::error         = 10

	PREINIT:
		char CLASS[] = "Aw::Error";

	CODE:
		RETVAL = (xsBrokerError *)safemalloc ( sizeof(xsBrokerError) );
		if ( RETVAL == NULL ) {
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( "unable to malloc new error" );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}


		switch ( ix ) 
		  {
			case 0:
				RETVAL->err = gErr;
				break;

			case 1:
				RETVAL->err = AWXS_ADAPTER(0)->err;
				break;

			case 2:
				RETVAL->err = AWXS_ADAPTEREVENTTYPE(0)->err;
				break;

			case 3:
				RETVAL->err = AWXS_ADAPTERUTIL(0)->err;
				break;

			case 4:
				RETVAL->err = AWXS_BROKERCLIENT(0)->err;
				break;

			case 5:
				RETVAL->err = AWXS_BROKERCONNECTIONDESC(0)->err;
				break;

			case 6:
				RETVAL->err = AWXS_BROKEREVENT(0)->err;
				break;

			case 7:
				RETVAL->err = AWXS_BROKERFILTER(0)->err;
				break;

			case 8:
				RETVAL->err = AWXS_BROKERFORMAT(0)->err;
				break;

			case 9:
				RETVAL->err = AWXS_BROKERTYPEDEF(0)->err;
				break;

			case 10:
				RETVAL->err = AWXS_BROKERTYPEDEFCACHE(0)->err;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

	OUTPUT:
	RETVAL



int
getWarn ( self )

	ALIAS:
		Aw::getWarn                       =  0
		Aw::Adapter::getWarn              =  1
		Aw::EventType::getWarn            =  2
		Aw::Util::getWarn                 =  3
		Aw::Client::getWarn               =  4
		Aw::ConnectionDescriptor::getWarn =  5
		Aw::Event::getWarn                =  6
		Aw::Error::getWarn                =  7
		Aw::Filter::getWarn               =  8
		Aw::Format::getWarn               =  9
		Aw::TypeDef::getWarn              = 10
		Aw::TypeDefCache::getWarn         = 11

	CODE:
		switch ( ix ) 
		  {
			case 0:
				RETVAL = (int)gWarn;
				break;

			case 1:
				RETVAL = (int)AWXS_ADAPTER(0)->Warn;
				break;

			case 2:
				RETVAL = (int)AWXS_ADAPTEREVENTTYPE(0)->Warn;
				break;

			case 3:
				RETVAL = (int)AWXS_ADAPTERUTIL(0)->Warn;
				break;

			case 4:
				RETVAL = (int)AWXS_BROKERCLIENT(0)->Warn;
				break;

			case 5:
				RETVAL = (int)AWXS_BROKERCONNECTIONDESC(0)->Warn;
				break;

			case 6:
				RETVAL = (int)AWXS_BROKEREVENT(0)->Warn;
				break;

			case 7:
				RETVAL = (int)AWXS_BROKERERROR(0)->Warn;
				break;

			case 8:
				RETVAL = (int)AWXS_BROKERFILTER(0)->Warn;
				break;

			case 9:
				RETVAL = (int)AWXS_BROKERFORMAT(0)->Warn;
				break;

			case 10:
				RETVAL = (int)AWXS_BROKERTYPEDEF(0)->Warn;
				break;

			case 11:
				RETVAL = (int)AWXS_BROKERTYPEDEFCACHE(0)->Warn;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

	OUTPUT:
	RETVAL



void
setWarn ( self, level )
	int level

	ALIAS:
		Aw::setWarn                       =  0
		Aw::Adapter::setWarn              =  1
		Aw::EventType::setWarn            =  2
		Aw::Util::setWarn                 =  3
		Aw::Client::setWarn               =  4
		Aw::ConnectionDescriptor::setWarn =  5
		Aw::Event::setWarn                =  6
		Aw::Error::setWarn                =  7
		Aw::Filter::setWarn               =  8
		Aw::Format::setWarn               =  9
		Aw::TypeDef::setWarn              = 10
		Aw::TypeDefCache::setWarn         = 11

	CODE:
		switch ( ix ) 
		  {
			case 0:
				gWarn = level;
				break;

			case 1:
				AWXS_ADAPTER(0)->Warn = level;
				break;

			case 2:
				AWXS_ADAPTEREVENTTYPE(0)->Warn = level;
				break;

			case 3:
				AWXS_ADAPTERUTIL(0)->Warn = level;
				break;

			case 4:
				AWXS_BROKERCLIENT(0)->Warn = level;
				break;

			case 5:
				AWXS_BROKERCONNECTIONDESC(0)->Warn = level;
				break;

			case 6:
				AWXS_BROKEREVENT(0)->Warn = level;
				break;

			case 7:
				AWXS_BROKERERROR(0)->Warn = level;
				break;

			case 8:
				AWXS_BROKERFILTER(0)->Warn = level;
				break;

			case 9:
				AWXS_BROKERFORMAT(0)->Warn = level;
				break;

			case 10:
				AWXS_BROKERTYPEDEF(0)->Warn = level;
				break;

			case 11:
				AWXS_BROKERTYPEDEFCACHE(0)->Warn = level;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }



void
warn ( self, ... )

	ALIAS:
		Aw::warn                       =  0
		Aw::Adapter::warn              =  1
		Aw::EventType::warn            =  2
		Aw::Util::warn                 =  3
		Aw::Client::warn               =  4
		Aw::ConnectionDescriptor::warn =  5
		Aw::Event::warn                =  6
		Aw::Error::warn                =  7
		Aw::Filter::warn               =  8
		Aw::Format::warn               =  9
		Aw::TypeDef::warn              = 10
		Aw::TypeDefCache::warn         = 11

	CODE:
		BrokerError err = NULL;
		char * errMsg   = NULL;
		char Warn;


		switch ( ix ) 
		  {
			case 0:
				err    = gErr;
				errMsg = gErrMsg;
				Warn   = gWarn;
				break;

			case 1:
				err    = AWXS_ADAPTER(0)->err;
				errMsg = AWXS_ADAPTER(0)->errMsg;
				Warn   = AWXS_ADAPTER(0)->Warn;
				break;

			case 2:
				err    = AWXS_ADAPTEREVENTTYPE(0)->err;
				errMsg = AWXS_ADAPTEREVENTTYPE(0)->errMsg;
				Warn   = AWXS_ADAPTEREVENTTYPE(0)->Warn;
				break;

			case 3:
				err    = AWXS_ADAPTERUTIL(0)->err;
				errMsg = AWXS_ADAPTERUTIL(0)->errMsg;
				Warn   = AWXS_ADAPTERUTIL(0)->Warn;
				break;

			case 4:
				err    = AWXS_BROKERCLIENT(0)->err;
				errMsg = AWXS_BROKERCLIENT(0)->errMsg;
				Warn   = AWXS_BROKERCLIENT(0)->Warn;
				break;

			case 5:
				err    = AWXS_BROKERCONNECTIONDESC(0)->err;
				errMsg = AWXS_BROKERCONNECTIONDESC(0)->errMsg;
				Warn   = AWXS_BROKERCONNECTIONDESC(0)->Warn;
				break;

			case 6:
				err    = AWXS_BROKEREVENT(0)->err;
				errMsg = AWXS_BROKEREVENT(0)->errMsg;
				Warn   = AWXS_BROKEREVENT(0)->Warn;
				break;

			case 7:
				err    = AWXS_BROKERERROR(0)->err;
				errMsg = AWXS_BROKERERROR(0)->errMsg;
				Warn   = AWXS_BROKERERROR(0)->Warn;
				break;

			case 8:
				err    = AWXS_BROKERFILTER(0)->err;
				errMsg = AWXS_BROKERFILTER(0)->errMsg;
				Warn   = AWXS_BROKERFILTER(0)->Warn;
				break;

			case 9:
				err    = AWXS_BROKERFORMAT(0)->err;
				errMsg = AWXS_BROKERFORMAT(0)->errMsg;
				Warn   = AWXS_BROKERFORMAT(0)->Warn;
				break;

			case 10:
				err    = AWXS_BROKERTYPEDEF(0)->err;
				errMsg = AWXS_BROKERTYPEDEF(0)->errMsg;
				Warn   = AWXS_BROKERTYPEDEF(0)->Warn;
				break;

			case 11:
				err    = AWXS_BROKERTYPEDEFCACHE(0)->err;
				errMsg = AWXS_BROKERTYPEDEFCACHE(0)->errMsg;
				Warn   = AWXS_BROKERTYPEDEFCACHE(0)->Warn;
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }


		/* if we are passed a warn, it over rides the pre-set value */
		if ( ix == 0 && items == 1 )
			Warn = (int)SvIV( ST(0) );
		else if ( items == 2 )
			Warn = (int)SvIV( ST(1) );


		if ( Warn ) {
			/* our own internal err message over rides Aw error messages */
			if ( errMsg )
				warn ( errMsg );
			else if (Warn == 1 && err != AW_NO_ERROR )
				errMsg = awErrorToString ( err );          /* hopefully NULL if AW_NO_ERROR */
			else if (Warn == 2 && err != AW_NO_ERROR )
				errMsg = awErrorToCompleteString ( err );  /* hopefully NULL if AW_NO_ERROR */

			if ( errMsg )
				warn ( errMsg ); 
		}




char *
hello ( self )

	ALIAS:
		Aw::Adapter::hello              =  1
		Aw::EventType::hello            =  2
		Aw::Log::hello                  =  3
		Aw::Util::hello                 =  4
		Aw::Client::hello               =  5
		Aw::ConnectionDescriptor::hello =  6
		Aw::Date::hello                 =  7
		Aw::Event::hello                =  8
		Aw::Error::hello                =  9
		Aw::Filter::hello               = 10
		Aw::Format::hello               = 11
		Aw::Replies::hello              = 12
		Aw::SSLCertificate::hello       = 13
		Aw::Subscription::hello         = 14
		Aw::TypeDef::hello              = 15
		Aw::TypeDefCache::hello         = 16

	CODE:
		RETVAL = strdup ( "  hello" );

	OUTPUT:
	RETVAL



char *
toString ( ... )

	ALIAS:
		Aw::Client::toString               = 1
		Aw::ConnectionDescriptor::toString = 2
		Aw::Date::toString                 = 3
		Aw::Error::toString                = 4
		Aw::Event::toString                = 5
		Aw::Filter::toString               = 6
		Aw::SSLCertifiate::toString        = 7
		Aw::TypeDef::toString              = 8

	CODE:
		/*  note, we haven't cleared the error here */

		switch ( ix ) 
		  {
			case 1:
				RETVAL = awClientToString ( AWXS_BROKERCLIENT(0)->client );
				break;

			case 2:
				RETVAL = awDescriptorToString ( AWXS_BROKERCONNECTIONDESC(0)->desc );
				break;

			case 3:
				RETVAL = awDateToString ( AWXS_BROKERDATE(0) );
				break;

			case 4:
				RETVAL = (items)
				       ? awErrorToString ( AWXS_BROKERERROR(0)->err )
				       : awErrorToString ( gErr )
				       ;
				break;

			case 5:
				RETVAL = awEventToString ( AWXS_BROKEREVENT(0)->event );
				break;

			case 6:
				RETVAL = awFilterToString ( AWXS_BROKERFILTER(0)->filter );
				break;

			case 7:
				RETVAL = (items)
				       ? awSSLCertificateToIndentedString ( AWXS_BROKERSSLCERTIFICATE(0), (int)SvIV (ST(1)) )
				       : awSSLCertificateToString ( AWXS_BROKERSSLCERTIFICATE(0) )
				       ;
				break;

			case 8:
				RETVAL = awTypeDefToString ( AWXS_BROKERTYPEDEF(0)->type_def );
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

		if ( RETVAL == NULL )
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Adapter

#===============================================================================

#===============================================================================
#  Aw::Adapter
#    ::new
#    ::DESTROY-A
#
#    ::addEvent			Java CADK 7-14
#    ::connectTest			Java CADK 7-16
#    ::checkPublication		Java CADK 7-16
#    ::createClient			Java CADK 7-17
#    ::deliverErrorEvent		Java CADK 7-18
#    ::getAdapterEventName-A		Java CADK 7-19
#    ::getAdapterInfo		Java CADK 7-19
#    ::getAdapterType		Java CADK 7-20
#    ::getAdapterVersion-A		   C CADK
#    ::getAdminClient		Java CADK 7-20
#    ::getBroker-A			Java CADK 7-20
#    ::getBrokerClient-A		Java CADK 7-20
#    ::getBrokerHost-A		Java CADK 7-20
#    ::getBrokerName-A		Java CADK 7-20
#    ::getClient-A 			Java CADK 7-21
#    ::getClientGroup-A		Java CADK 7-21
#    ::getClientId-A			Java CADK 7-21
#    ::getClientName-A		   C CADK
#    ::getEventDef			Java CADK 7-21
#    ::getEventDefs			Java CADK 7-21
#    ::getEvents			Java CADK 7-22
#    ::getPublishWaitTime		Java CADK 7-22
#    ::init				Java CADK 7-23
#    ::initStatusSubscriptions	Java CADK 7-23
#    ::isConnectTest			Java CADK 7-23
#    ::isMaster              	Java CADK 7-24
#    ::loadProperties		Java CADK 7-24
#    ::publishStatus-A		Java CADK 7-26
#    ::removeEvent			Java CADK 7-26
#    ::setConnectionDescriptorSSL	Java CADK 7-27
#    ::setStatusProperty		Java CADK 7-28
#
#    ::err-A   			ala Mysql::
#    ::errmsg-A			ala Mysql::
#    ::error-A
#
#	Routines for working while $self is in callback space:
#	-----------------------------------------------------
#    ::createEvent-A            Java CADK 7-91
#    ::deliverAckReplyEvent-A   Java CADK 7-92
#    ::deliverReplyEvent-A      Java CADK 7-93
#    ::getEventTypeDef          Java CADK 7-94
#    ::getStringField-A         Java CADK 7-96 / Java-I 15-118
#    ::newSubscription-A        Java CADK 7-99
#    ::publish-A                Java CADK 7-99/7-100
#    ::requestEvent-A           Perl CADK :-)
#    ::setEventField-A          Java CADK 7-100
#    ::setStringField-A         Java CADK 7-101
#===============================================================================



Aw::Adapter
_new ( CLASS, version, ... )
	char * CLASS
	char * version

	PREINIT:
		awAdapterProperties * awProperties = NULL;
		int argc = 0;
		char ** argv;

	CODE:
		RETVAL = (xsAdapter *)safemalloc ( sizeof(xsAdapter) );	
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "Aw::Adapter::new:  unable to malloc new adapter" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err      = AW_NO_ERROR;
		RETVAL->errMsg   = NULL;
		RETVAL->Warn     = gWarn;

		RETVAL->handle   = NULL;
		RETVAL->callback = 0x0;
		RETVAL->firstCB  = 0x0;


   		if( SvROK(ST(2)) && (SvTYPE(SvRV(ST(2))) == SVt_PVHV) )
			awProperties = awxsHashToProperties ( (HV*)SvRV( ST(2) ) );
		else {
			int i;
			argv = XS_unpack_charPtrPtr ( ST(2) ); 
			argc = av_len ( (AV*)SvRV( ST(2) ) ) + 1;

			awProperties = awAdapterLoadProperties ( argc, argv );

			XS_release_charPtrPtr ( argv );

			if ( awProperties == NULL )
				XSRETURN_UNDEF;
		}

		if ( awProperties ) {
			/* start logging */
			awAdapterInitLogging ( awProperties );

			/* create the adapter structure */
			RETVAL->adapter = awAdapterCreate ( awProperties, version );
		}
		else {
			RETVAL->adapter = NULL;
		}

		/* register our callbacks */
		RETVAL->adapter->setupEventFunction         =& setupEvent;
		RETVAL->adapter->processRequestFunction     =& processRequest;
		RETVAL->adapter->cleanupEventTypeFunction   =& cleanupEventType;
		RETVAL->adapter->beginSetupFunction         =& beginSetup;
		RETVAL->adapter->endSetupFunction           =& endSetup;
		RETVAL->adapter->processPublicationFunction =& processPublication;
		RETVAL->adapter->beginTransactionFunction   =& beginTransaction;
		RETVAL->adapter->endTransactionFunction     =& endTransaction;

	OUTPUT:
	RETVAL



void
addEvent ( self, event )
	Aw::Adapter self
	Aw::EventType event

	CODE:
		AWXS_CLEARERROR

		awAdapterAddEvent ( self->adapter, event->adapterET );



void
checkPublications ( self )
	Aw::Adapter self

	CODE:
		AWXS_CLEARERROR

		awAdapterCheckPublications ( self->adapter );



awaBool
createAdapterClient ( self, stateShare )
	Aw::Adapter self
	awaBool stateShare

	PREINIT:
		awaBool keepShareState;

	CODE:
		AWXS_CLEARERROR

		keepShareState = self->adapter->useSharedState;
		self->adapter->useSharedState = stateShare;

		gErr = self->err = awAdapterCreateClient ( self->adapter );

		AWXS_CHECKSETERROR

		self->adapter->useSharedState = keepShareState;

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
createClient ( self )
	Aw::Adapter self

	ALIAS:
		Aw::Adapter::publishStatus = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awAdapterPublishStatus ( self->adapter )
		  : awAdapterCreateClient  ( self->adapter )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



void
_deliverErrorEvent ( self, category, msgId, strings )
	Aw::Adapter self
	int category
	int msgId
	char ** strings

	PREINIT:
		int n;

	CODE:
		AWXS_CLEARERROR

		n = av_len ( (AV*)SvRV( ST(3) ) );

		switch ( n )
		  {
			case  0:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0] );
				break;

			case  1:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0], strings[1] );
				break;

			case  2:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0], strings[1], strings[2] );
				break;

			case  3:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0], strings[1], strings[2], strings[3] );
				break;

			case  4:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0], strings[1], strings[2], strings[3], strings[4] );
				break;

			default:
				awAdapterDeliverErrorEvent ( self->handle, category, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5] );
				break;
		  }

	CLEANUP:
		XS_release_charPtrPtr ( strings );


awaBool
destroyClient ( self )
	Aw::Adapter self

	CODE:
		AWXS_CLEARERROR

		if ( self->adapter->brokerClient ) {
			gErr = self->err = awDisconnectClient ( self->adapter->brokerClient );
			if ( self->err == AW_NO_ERROR );
				gErr = self->err = awDestroyClient ( self->adapter->brokerClient );
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL


Aw::Event
getAdapterInfo ( self )
	Aw::Adapter self

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "Aw::Adapter::getAdapterInfo:  unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->event = awAdapterGetAdapterInfo ( self->adapter );

	OUTPUT:
	RETVAL



char *
getAdapterType ( self )
	Aw::Adapter self

	ALIAS:
		Aw::Adapter::getAdapterVersion    = 1
		Aw::Adapter::getBroker            = 2
		Aw::Adapter::getBrokerHost        = 3
		Aw::Adapter::getBrokerName        = 4
		Aw::Adapter::getClientGroup       = 5
		Aw::Adapter::getClientId          = 6
		Aw::Adapter::getClientName        = 7
		Aw::Adapter::getAdapterEventName  = 8
		
	CODE:
		AWXS_CLEARERROR

		RETVAL 
		= (ix==4)
		  ? self->adapter->brokerName                                // 4
		  : (ix>4)
		    ? (ix>6)
		      ? (ix==8)
		        ? awGetEventTypeName ( self->adapter->adapterInfo )  // 8
		        : self->adapter->clientName                          // 7
		      : (ix==6)
		        ? self->adapter->clientId                            // 6
		        : self->adapter->clientGroup                         // 5
		    : (ix>2)
		      ? (ix==3)
		        ? self->adapter->brokerHost                          // 3
		        : self->adapter->broker                              // 2
		      : (ix)
		        ? self->adapter->adapterVersion                      // 1
		        : self->adapter->adapterType                         // 0
		;

	OUTPUT:
	RETVAL



Aw::Client
getAdminClient ( self )
	Aw::Adapter self

	ALIAS:
		#   I don't know the difference here
		Aw::Adapter::getClient       = 1
		Aw::Adapter::getBrokerClient = 2

	PREINIT:
		char CLASS[] = "Aw::Client";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerClient *)safemalloc ( sizeof(xsBrokerClient) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "Aw::Adapter::getAdminClient:  unable to malloc new adapter" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->client
		= (ix)
		  ? self->adapter->brokerClient
		  : self->adapter->adminClient
		;

	OUTPUT:
	RETVAL



Aw::EventType
getEventDef ( self, ... )
	Aw::Adapter self
	
	ALIAS:
		Aw::Adapter::eventDef = 1

	PREINIT:
		char CLASS[] = "Aw::EventType";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->adapterET
		= (ix)
		  ? self->handle->eventDef
		  : awAdapterGetEventDef ( self->adapter, (char *)SvPV ( ST(1), PL_na ) )
		;

	OUTPUT:
	RETVAL



AV *
getEventDefsRef ( self )
	Aw::Adapter self

	PREINIT:
		int n;

	CODE:
		AWXS_CLEARERROR

		if ( self->adapter->eventDefs == NULL )
			XSRETURN_UNDEF;

		n = awVectorSize ( self->adapter->eventDefs );

		/* convert to an AV of xsBrokerTypeDefs */
		{
		SV *sv;
		int i;
		xsAdapterEventType * eventDef;

		RETVAL = newAV();

		for ( i = 0; i<n; i++ ) {
			eventDef = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
			if ( eventDef == NULL ) {
				setErrMsg ( &gErrMsg, 1, "Aw::Adapter::getEventDefs: unable to malloc new adapter event" );
#ifdef AWXS_WARNS
				if ( self->Warn )
					warn ( self->errMsg );
#endif /* AWXS_WARNS */
				XSRETURN_UNDEF;
			}
			/* initialize the error cleanly */
			eventDef->err    = AW_NO_ERROR;
			eventDef->errMsg = NULL;
			eventDef->Warn   = gWarn;

			memcpy ( eventDef->adapterET, awVectorGet ( self->adapter->eventDefs, i ), sizeof (awAdapterEventType) );
			sv = sv_newmortal();
			sv_setref_pv( sv, "Aw::EventType", (void*)eventDef );
			SvREFCNT_inc(sv);
			av_push( RETVAL, sv );
		}

		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



awaBool
getEvents ( self )
	Aw::Adapter self

	CODE:
		AWXS_CLEARERROR

		OneAdapter    = self;
		OneAdapterRef = ST(0);

		gErr = self->err = awAdapterGetEvents ( self->adapter );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



int
getPublishWaitTime ( self )
	Aw::Adapter self

	CODE:
		AWXS_CLEARERROR

		RETVAL = awAdapterGetPublishWaitTime ( self->adapter );

	OUTPUT:
	RETVAL



awaBool
init ( self )
	Aw::Adapter self

	ALIAS:
		Aw::Adapter::connectTest        = 1
		Aw::Adapter::isConnectTest      = 2
		Aw::Adapter::isMaster           = 3
		Aw::Adapter::initSessions       = 4
		Aw::Adapter::isSessions         = 5
		Aw::Adapter::isSessionManager   = 6
		Aw::Adapter::usesSessionManager = 7

	CODE:
		AWXS_CLEARERROR
#if !( AW_VERSION_31 || AW_VERSION_40 )
		if ( ix > 3 ) {
			warn ( "'*Session' methods available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
			XSRETURN_UNDEF;
		}
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

		RETVAL
		= (ix>3)
		  ? (ix>5)
		    ? (ix==7)
		      ? awAdapterUsesSessionManager ( self->adapter )     // 7
                      : awAdapterIsSessionManager ( self->adapter )       // 6
		    : (ix>4)
		      ? awAdapterIsSessions ( self->adapter )             // 5
                      : awAdapterInitSessions ( self->adapter )           // 4
		  : (ix>1)
		    ? (ix==3)
		      ? awAdapterIsMaster ( self->adapter )               // 3
		      : awAdapterIsConnectTest ( self->adapter )          // 2
		    : (ix)
		      ? (awaBool) awAdapterConnectTest ( self->adapter )  // 1
		      : awAdapterInit ( self->adapter )                   // 0
		;

	OUTPUT:
	RETVAL



awaBool
initStatusSubscriptions ( self )
	Aw::Adapter self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awAdapterInitStatusSubscriptions ( self->adapter );

		if ( self->err == AW_NO_ERROR )
			gErr = self->err = awAdapterPublishStatus ( self->adapter );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
_loadProperties ( self, ... )
	Aw::Adapter self

	PREINIT:
		awAdapterProperties * awProperties = NULL;
		int argc = 0;
		char ** argv;
		
	CODE:
		AWXS_CLEARERROR

   		if( SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV) )
			awProperties = awxsHashToProperties ( (HV*)SvRV( ST(2) ) );
		else {
			int i;
			argv = XS_unpack_charPtrPtr ( ST(1) ); 
			argc = av_len ( (AV*)SvRV( ST(1) ) ) + 1;

			awProperties = awAdapterLoadProperties ( argc, argv );

			XS_release_charPtrPtr ( argv );

			if ( awProperties == NULL )
				XSRETURN_UNDEF;
		}

		/* start logging -in Java loading does logging also... */
		awAdapterInitLogging ( awProperties );

		RETVAL = awaTrue;

	OUTPUT:
	RETVAL



void
removeEvent ( self, event_name )
	Aw::Adapter self
	char * event_name

	CODE:
		AWXS_CLEARERROR
		awAdapterRemoveEvent ( self->adapter, event_name );



awaBool
setConnectionDescriptorSSL ( self, desc )
	Aw::Adapter self
	Aw::ConnectionDescriptor desc

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awAdapterSetDescriptorSSL ( self->adapter, desc->desc );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



void
setStatusProperty ( self, propertyName )
	Aw::Adapter self
	char * propertyName

	CODE:
		AWXS_CLEARERROR
		awAdapterSetStatusProperty ( self->adapter, propertyName );



void
verifyLicense ( self, licenseKeyPrefix )
	Aw::Adapter self
	char * licenseKeyPrefix 

	CODE:
		AWXS_CLEARERROR
		awAdapterVerifyLicense ( self->adapter, licenseKeyPrefix );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Client

#===============================================================================

#===============================================================================
#  Aw::Client
#	::new
#	::DESTROY-A
#
#	::acknowledge			Java-I 15-8
#	::acknowledgeThrough		Java-I 15-9
#	::beginTransaction		Java-I 15-10
#	::cancelSubscription		Java-I 15-13
#	::canPublish			Java-I 15-16
#	::canSubscribe-A		Java-I 15-16
#	::clearQueue			Java-I 15-17
#	::deliver			Java-I 15-18/19
#	::deliverAckReplyEvent		Java-I 15-20
#	::deliverErrorReplyEvent	Java-I 15-22
#	::deliverNullReplyEvent		Java-I 15-23
#	::deliverReplyEvent		Java-I 15-27
#	::deliverReplyEvents		Java-I 15-28
#	::deliverRequestAndWait		Java-I 15-29
#	::disconnect			Java-I 15-31
#	::dispatch			Java-I 15-32
#	::doesSubscriptionExist 	Java-I 15-33
#	::endTransaction		Java-I 15-34
#	::getApplicationName		Java-I 15-35
#	::getBrokerHost			Java-I 15-35
#	::getBrokerName			Java-I 15-36
#	::getBrokerPort			Java-I 15-36
#	::getCanPublishNames		Java-I 15-37
#	::getCanSubscribeNames-A	Java-I 15-38
#	::getCanPublishTypeDefs		Java-I 15-37
#	::getCanSubscribeTypeDefs	Java-I 15-38
#	::getClientGroup		Java-I 15-39
#	::getClientId			Java-I 15-39
#	::getClientInfoset		Java-I 15-40
#	::getClientSSLEncryptionLevel	Java-I 15-40
#	::getConnectionDescriptor	Java-I 15-41
#	::getDefaultBrokerPort		Java-I 15-41
#	::getDefaultClientTimeOut	   C?
#	::getTerritoryName		Java-I 15-55
#	::getEvent			Java-I 15-42
#	::getEvents			Java-I 15-43 XX
#	::getEventTypeInfosetNames-A	Java-I 15-49
#	::getEventTypeNames-A		Java-I 15-50
#	::getFamilyNames-A
#	::getFamilyEventTypeNames-A
#	::getLastPublishSequenceNumber	Java-I 15-52
#	::getPlatformInfo		Java-I 15-52
#	::getPlatformInfoKeys		Java-I 15-52
#	::getQueueLength		Java-I 15-53
#	::getScopeNames-A		Java-I 15-54
#	::getScopeEventTypeNames-A	   C?
#	::getStateShareLimit		Java-I 15-54
#	::interruptDispatch		Java-I 15-56
#	::interruptGetEvents		Java-I 15-56
#	::isClientPending		Java-I 15-57
#	::isConnected			Java-I 15-57
#	::isPending			Java-I 15-58
#	::mainLoop			Java-I 15-58
#	::makeSubId			Java-I 15-59
#	::makeTag 			Java-I 15-59
#	::makeTransactionId		Java-I 15-59
#	::makeUniqueSubId		Java-I 15-60
#	::newOrReconnect-A		Java-I 15-60
#	::newSubscription		Java-I 15-64
#	::prime				Java-I 15-68
#	::primeAllClients		Java-I 15-68
#	::publish			Java-I 15-69
#	::reconnect			Java-I 15-72
#	::setStateShareLimit	Java-I 15-80
#	::stopMainLoop			Java-I 15-80
#	::toString			Java-I 15-81
#	::threadedCallBacks		Java-I 15-81
#	::cancellCallbacks		Java-I 15-12
#	::cancelCallbackForSubId-A	Java-I 15-11
#	::cancelCallbackForTag-A	Java-I 15-12
#
#       ::err-A				ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::Client
_new ( CLASS, broker_host, broker_name, client_id, client_group, app_name, ... )
	char * CLASS
	char * broker_host;
	char * broker_name;
	char * client_id;
	char * client_group;
	char * app_name;

	ALIAS:
		Aw::Client::_newOrReconnect = 1

	PREINIT:
		BrokerConnectionDescriptor myDesc = NULL;
		
	CODE:
		RETVAL = (xsBrokerClient *)safemalloc ( sizeof(xsBrokerClient) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new client" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;


		if ( client_id[0] == '\0' )
			client_id = NULL;
		if ( broker_name[0] == '\0' )
			broker_name = NULL;

		if ( items == 7 && ( sv_isobject(ST(6)) && (SvTYPE(SvRV(ST(6))) == SVt_PVMG) ) )
			myDesc = AWXS_BROKERCONNECTIONDESC(6)->desc;

		gErr = RETVAL->err
		= ( ix )
		  ? awNewOrReconnectBrokerClient ( broker_host, broker_name, client_id, client_group, app_name, myDesc, &RETVAL->client )
		  : awNewBrokerClient ( broker_host, broker_name, client_id, client_group, app_name, myDesc, &RETVAL->client )
		;


		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new event %s", awErrorToCompleteString ( RETVAL->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
			warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



awaBool
acknowledge ( self, seqn )
	Aw::Client self
	CORBA::LongLong seqn

	ALIAS:
		Aw::Client::acknowledgeThrough = 1

	PREINIT:
		BrokerLong blValue;	

	CODE:
		AWXS_CLEARERROR

		blValue = awBrokerLongFromString ( longlong_to_string ( seqn ) );
		
		gErr = self->err
		= (ix)
		  ? awAcknowledgeThrough ( self->client, blValue )
		  : awAcknowledge ( self->client, blValue )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



int
_beginTransaction ( self, transaction_id, required_level, participants )
	Aw::Client self
	char * transaction_id
	int required_level
	char ** participants

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awBeginTransaction ( self->client, transaction_id, required_level, (items-3), participants, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( participants );



awaBool
cancellCallbacks ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::cancelCallbackForSubId =  1
		Aw::Client::cancelCallbackForTag   =  2
		Aw::Client::clearQue               =  3
		Aw::Client::disconnect             =  4
		Aw::Client::dispatch               =  5
		Aw::Client::interruptGetEvents     =  6
		Aw::Client::interruptDispatch      =  7
		Aw::Client::mainLoop               =  8
		Aw::Client::prime                  =  9
		Aw::Client::primeAllClients        = 10
		Aw::Client::stopMainLoop           = 11
		Aw::Client::threadedCallBacks      = 12

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix>6)
		  ? (ix>9)
                    ? (ix>10)
		      ? (ix>11)
                        ? awThreadedCallbacks ( (BrokerBoolean)SvIV( ST(1) ) )           // 12
		        : awStopMainLoop ()                                              // 11
                      : awPrimeAllClients ()                                             // 10
		    : (ix>7)
		      ? (ix>8)
		        ? awPrimeClient ( self->client )                                 //  9
                        : awMainLoop ()                                                  //  8
	              : awInterruptDispatch ()                                           //  7
		  : (ix==6)
		    ? awInterruptGetEvents ( self->client )                              //  6
		    : (ix>2)
		      ? (ix>3)
		        ? (ix>4)
		          ? awDispatch ( (int)SvIV(ST(1)) )                              //  5
		          : awDisconnectClient ( self->client )                          //  4
		        : awClearClientQueue ( self->client )                            //  3
		      : (ix>0)
		        ? (ix>1)
		          ? awCancelCallbackForTag ( self->client, (int)SvIV(ST(1)) )    //  2
		          : awCancelCallbackForSubId ( self->client, (int)SvIV(ST(1)) )  //  1
		        : awCancelCallbacks ( self->client )                             //  0
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
_cancelSubscription ( self, event_type_name, filter )
	Aw::Client self
	char * event_type_name
	char * filter

	ALIAS:
		Aw::Client::doesSubscriptionExist = 1
		Aw::Client::setPlatformInfo       = 2

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? (ix-1)
		    ? awSetPlatformInfo ( event_type_name, filter )
		    : awDoesSubscriptionExist ( self->client, event_type_name, filter, &bRV )
		  : awCancelSubscription ( self->client, event_type_name, filter )
		;

		AWXS_CHECKSETERROR

		RETVAL
		= (ix == 1)
		  ? (awaBool) bRV
		  : ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue
		;

	OUTPUT:
	RETVAL



awaBool
_cancelSubscriptions ( self, ... )
	Aw::Client self

	PREINIT:
		int i;

	CODE:
		AWXS_CLEARERROR

		for (i=1; i<items; i++)
			if ( self->err == AW_NO_ERROR )
				gErr = self->err =
				awCancelSubscriptionFromStruct ( self->client, AWXS_BROKERSUBSCRIPTION(i) );
			else
				awCancelSubscriptionFromStruct ( self->client, AWXS_BROKERSUBSCRIPTION(i) );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;
		
	OUTPUT:
	RETVAL



awaBool
canPublish ( self, event_type_name )
	Aw::Client self
	char * event_type_name

	ALIAS:
		Aw::Client::canSubscribe = 1

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? awCanSubscribe ( self->client, event_type_name, &RETVAL )
		  : awCanPublish   ( self->client, event_type_name, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN
		
	OUTPUT:
	RETVAL



awaBool
deliver ( self, dest_id, ... )
	Aw::Client self
	char * dest_id

	PREINIT:
		int i, n;
		AV * av = NULL;
		BrokerEvent ** events;

	CODE:
		AWXS_CLEARERROR
		
		if ( SvTYPE(SvRV(ST(2))) == SVt_PVAV ) {
			/* we were passed a properties array ref */
			av = (AV*)SvRV( ST(2) );
			n  = av_len ( av ) + 1;

		} else if ( items == 3 ) {
			gErr = self->err = awDeliverEvent ( self->client, dest_id, AWXS_BROKEREVENT(2)->event );
		} else {
			/* we were passed a properties array */
			n = items - 2;
			av = av_make ( n, &ST(2) );
		}
		

		if ( av ) {
			SV ** sv;
			events = (BrokerEvent **) safemalloc ( n * sizeof (BrokerEvent *) );
			for ( i = 0; i<n; i++ ) {
				sv = av_fetch ( av, i, 0 );
				events[i] =& ((xsBrokerEvent *)SvIV((SV*)SvRV( *sv )))->event;
			}
			gErr = self->err = awDeliverEvents ( self->client, dest_id, n, *events );
			av_undef ( av );

			Safefree ( events );

		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
deliverAckReplyEvent ( self, request_event, publish_seqn )
	Aw::Client self
	Aw::Event request_event
	CORBA::LongLong publish_seqn

	PREINIT:
		BrokerLong blValue;

	CODE:
		AWXS_CLEARERROR
		
		blValue = awBrokerLongFromString ( longlong_to_string ( publish_seqn ) );
		
		gErr = self->err = awDeliverAckReplyEvent ( self->client, request_event->event, blValue );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
deliverNullReplyEvent ( self, request_event, reply_event_type_name, publish_seqn )
	Aw::Client self
	Aw::Event request_event
	char * reply_event_type_name
	CORBA::LongLong publish_seqn

	PREINIT:
		BrokerLong blValue;

	CODE:
		AWXS_CLEARERROR
		
		blValue = awBrokerLongFromString ( longlong_to_string ( publish_seqn ) );
		
		gErr = self->err = awDeliverNullReplyEvent ( self->client, request_event->event, reply_event_type_name, blValue );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



int
deliverPartialReplyEvents ( self, request_event, ... )
	Aw::Client self
	Aw::Event request_event

	ALIAS:
		Aw::Client::deliverReplyEvents = 1

	PREINIT:
		int i, n;
		int flag;
		AV * av = NULL;
		BrokerEvent ** events;

	CODE:
		AWXS_CLEARERROR
		
		flag = (int)SvIV(ST(items-1));

		if ( SvTYPE(SvRV(ST(2))) == SVt_PVAV ) {
			/* we were passed a properties array ref */
			av = (AV*)SvRV( ST(2) );
			n  = av_len ( av ) + 1;

		} else {
			/* we were passed a properties array */
			n = items - 3;
			av = av_make ( n, &ST(2) );
		}
		

		if ( av ) {
			SV ** sv;
			events = (BrokerEvent **) malloc ( n * sizeof (BrokerEvent *) );
			for ( i = 0; i<n; i++ ) {
				sv = av_fetch ( av, i, 0 );
				events[i] =& ((xsBrokerEvent *)SvIV((SV*)SvRV( *sv )))->event;
			}

			gErr = self->err 
			= (ix)
			  ? awDeliverReplyEvents ( self->client, request_event->event, n, *events )
			  : awDeliverPartialReplyEvents ( self->client, request_event->event, n, *events, flag, &RETVAL )
			;

			av_undef ( av );
			Safefree ( events );

		}


		if ( self->err != AW_NO_ERROR || av == NULL ) {
			if ( av )
				Safefree ( av );

			AWXS_CHECKSETERROR

			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



awaBool
_deliverReplyEvent ( self, request_event, reply_event )
	Aw::Client self
	Aw::Event request_event
	Aw::Event reply_event

	ALIAS:
		Aw::Client::deliverErrorReplyEvent = 1

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? awDeliverErrorReplyEvent ( self->client, request_event->event, reply_event->event )
		  : awDeliverReplyEvent ( self->client, request_event->event, reply_event->event )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



AV *
deliverRequestAndWaitRef ( self, dest_id, event, msecs )
	Aw::Client self
	char * dest_id
	Aw::Event event
	int msecs

	PREINIT:
		BrokerEvent * reply_events;
		int n;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awDeliverRequestAndWait ( self->client, dest_id, event->event, msecs, &n, &reply_events );

		AWXS_CHECKSETERROR


		/* now convert reply_events into an AV */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
				if ( ev == NULL ) {
					self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
					if ( self->Warn )
						warn ( self->errMsg );
#endif /* AWXS_WARNS */
					continue;
				}
				ev->err      = NULL;
				ev->errMsg   = NULL;
				ev->Warn     = gWarn;
				ev->deleteOk = 0;

				ev->event    = reply_events[i];
				
				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::Event", (void*)ev );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}
	
	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



int
endTransaction ( self, transaction_id, mode )
	Aw::Client self
	char * transaction_id
	int mode

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awEndTransaction ( self->client, transaction_id, mode, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



AV *
getAccessLabelRef ( self )
	Aw::Client self

	PREINIT:
		int n;
		short ** labels;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetClientAccessLabel ( self->client, &n, labels );

		AWXS_CHECKSETERROR_RETURN

		
		{	/* convert shorts into AV */
		SV *sv;
		int i;
			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				sv = newSViv( *labels[i] );
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		free ( labels ); // free policy is not detailed in the C Platform Vol. 1 p 15-58
                                 // nor in awclient.h, assume it is a block
		SvREFCNT_dec ( RETVAL );



Aw::SSLCertificate
getBrokerSSLCertificate ( self )
	Aw::Client self

	PREINIT:
		char CLASS[] = "Aw::SSLCertificate";

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetBrokerSSLCertificate ( self->client, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
getBrokerVersionNumber ( self )
	Aw::Client self

	CODE:
		AWXS_CLEARERROR
#if ( AW_VERSION_31 || AW_VERSION_40 )

		gErr = self->err = awGetBrokerVersionNumber ( self->client, &RETVAL );

		AWXS_CHECKSETERROR_RETURN
#else
		warn ( "'getBrokerVersionNumber' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
	RETVAL



char **
getCanPublishNamesRef ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::getCanSubscribeNamesRef     = 1
		Aw::Client::getEventTypeInfosetNamesRef = 2
		Aw::Client::getEventTypeNamesRef        = 3
		Aw::Client::getFamilyEventTypeNamesRef  = 4
		Aw::Client::getFamilyNamesRef           = 5
		Aw::Client::getPlatformInfoKeysRef      = 6
		Aw::Client::getScopeEventTypeNamesRef   = 7
		Aw::Client::getScopeNamesRef            = 8

	PREINIT:
		int count_charPtrPtr;
		char * field_name = NULL;

	CODE:
		AWXS_CLEARERROR
		
		if ( items == 2 )
			field_name = (char *)SvPV ( ST(1), PL_na );

		gErr = self->err 
		= (ix==4)
#ifdef AW_COMPATIBLE
		  ? awGetFamilyEventTypeNames ( self->client, field_name, &count_charPtrPtr, &RETVAL )
#else
		  ? (BrokerError)AW_ERROR_INCOMPATIBLE_VERSION 
#endif /* AW_COMPATIBLE */
		  : (ix>4)
		    ? (ix>6)
		      ? (ix==8)
		        ? awGetScopeNames ( self->client, &count_charPtrPtr, &RETVAL )
		        : awGetScopeEventTypeNames ( self->client, field_name, &count_charPtrPtr, &RETVAL )
		      : (ix==6)
		        ? awGetPlatformInfoKeys ( &count_charPtrPtr, &RETVAL )
#ifdef AW_COMPATIBLE
		        : awGetFamilyNames ( self->client, &count_charPtrPtr, &RETVAL )
#else
		        : (BrokerError)AW_ERROR_INCOMPATIBLE_VERSION 
#endif /* AW_COMPATIBLE */
		    : (ix>2)
		      ? (ix==3)
		        ? awGetEventTypeNames ( self->client, &count_charPtrPtr, &RETVAL )
		        : awGetEventTypeInfosetNames ( self->client, field_name, &count_charPtrPtr, &RETVAL )
		      : (ix)
		        ? awGetCanSubscribeNames ( self->client, &count_charPtrPtr, &RETVAL )
		        : awGetCanPublishNames ( self->client, &count_charPtrPtr, &RETVAL )
		;
	
		AWXS_CHECKSETERROR_RETURN
		
	OUTPUT:
	RETVAL



AV *
getCanPublishTypeDefsRef ( self )
	Aw::Client self

	ALIAS:
		Aw::Client::getCanSubscribeTypeDefs = 1

	PREINIT:
		BrokerTypeDef * typeDefs;
		int n;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? awGetCanSubscribeTypeDefs ( self->client, &n, &typeDefs )
		  : awGetCanPublishTypeDefs   ( self->client, &n, &typeDefs )
		;
	
		AWXS_CHECKSETERROR_RETURN

		/* convert to an AV of xsBrokerTypeDefs */
		{
		SV *sv;
		int i;
		xsBrokerTypeDef * typeDef;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				typeDef = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
				if ( typeDef == NULL ) {
					self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new type def" );
#ifdef AWXS_WARNS
					if ( self->Warn )
						warn ( self->errMsg );
#endif /* AWXS_WARNS */
					XSRETURN_UNDEF;
				}
				/* initialize the error cleanly */
				typeDef->err    = AW_NO_ERROR;
				typeDef->errMsg = NULL;
				typeDef->Warn   = gWarn;
				memcpy ( typeDef->type_def, typeDefs[i], sizeof(BrokerTypeDef) );

				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::TypeDef", (void*)typeDef );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( typeDefs );



CORBA::LongLong
getClientLastPublishSequenceNumber ( self )
	Aw::Client self

	PREINIT:
		BrokerLong blValue;
		char blString[24];

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientLastPublishSequenceNumber ( self->client, &blValue );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = longlong_from_string ( awBrokerLongToString( blValue, blString ) );

	OUTPUT:
	RETVAL



Aw::ConnectionDescriptor
getConnectionDescriptor ( self )
	Aw::Client self

	PREINIT:
		char CLASS[] = "Aw::ConnectionDescriptor";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerConnectionDescriptor *)safemalloc ( sizeof(xsBrokerConnectionDescriptor) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new connection descriptor copy" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetClientConnectionDescriptor ( self->client, &RETVAL->desc );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
getDefaultBrokerPort ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::setDefaultClientTimeOut = 1
		Aw::Client::makeSubId               = 2
		Aw::Client::makeTag                 = 3

	CODE:
		AWXS_CLEARERROR
		
		RETVAL
		= (ix>=2)
		  ? (ix-2)
		    ? awMakeTag ( self->client )
		    : awMakeSubId ( self->client )
		  : (ix)
		    ? awSetDefaultClientTimeout ( (int)SvIV( ST(1) ) )
		    : awGetDefaultBrokerPort ()
		;

	OUTPUT:
	RETVAL



AV *
getSubscriptionsRef ( self )
	Aw::Client self

	PREINIT:
		int n;
		BrokerSubscription * subs;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetSubscriptions ( self->client, &n, &subs );

		AWXS_CHECKSETERROR_RETURN

		{		/* now convert subs into an AV */
		SV *sv;
		int i;
		BrokerSubscription * sub;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				sv = sv_newmortal();
				sub = (BrokerSubscription *) safemalloc ( sizeof(BrokerSubscription) );
				sub->sub_id = subs[i].sub_id;
				sub->event_type_name = strdup ( subs[i].event_type_name );
				sub->filter = strdup ( subs[i].filter );
				sv_setref_pv( sv, "Aw::Subscription", sub );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( subs );



Aw::Event
getEvent ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::getClientInfoset = 1

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		RETVAL->err      = NULL;
		RETVAL->errMsg   = NULL;
		RETVAL->Warn     = gWarn;
		RETVAL->deleteOk = 0;

		gErr = self->err
		= (ix)
		  ? awGetClientInfoset( self->client, &RETVAL->event )
		  : awGetEvent ( self->client, (int)SvIV(ST(1)), &RETVAL->event )
		;

		if ( self->err != AW_NO_ERROR ) {
			self->errMsg = setErrMsg ( &gErrMsg, 2, "unable to instantiate new event %s", awErrorToCompleteString ( self->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



AV *
getEventsRef ( self, max_events, msecs, ... )
	Aw::Client self
	int max_events
	int msecs

	ALIAS:
		Aw::Client::getEventsWithAckRef = 1

	PREINIT:
		int n;
		BrokerEvent * events;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awGetEventsWithAck ( self->client, max_events, awBrokerLongFromString ( longlong_to_string ( SvLLV (ST(3)) ) ), msecs, &n, &events )
		  : awGetEvents ( self->client, max_events, msecs, &n, &events )
		;

		AWXS_CHECKSETERROR_RETURN


		/* convert to an AV of xsBrokerEvents */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

		RETVAL = newAV();

		for ( i = 0; i<n; i++ ) {
			ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
			if ( ev == NULL ) {
				self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
				if ( self->Warn )
					warn ( self->errMsg );
#endif /* AWXS_WARNS */
				continue;
			}
			/* initialize the error cleanly */
			ev->err      = AW_NO_ERROR;
			ev->errMsg   = NULL;
			ev->Warn     = gWarn;
			ev->deleteOk = 0;

			ev->event = events[i];

			sv = sv_newmortal();
			sv_setref_pv( sv, "Aw::Event", (void*)ev );
			SvREFCNT_inc(sv);
			av_push( RETVAL, sv );
		}  /* for */
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



Aw::TypeDef
getEventTypeDef ( self, event_type_name )
	Aw::Client self
	char * event_type_name

	PREINIT:
		char CLASS[] = "Aw::TypeDef";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new type def" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetEventTypeDef ( self->client, event_type_name, &RETVAL->type_def );

		if ( self->err != AW_NO_ERROR ) {
			self->errMsg = setErrMsg ( &gErrMsg, 2, "unable to instantiate new event %s", awErrorToCompleteString ( self->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



AV *
getEventTypeDefsRef ( self, event_type_names )
	Aw::Client self
	char ** event_type_names
	
	PREINIT:
		int n;
		BrokerTypeDef * typeDefs;

	CODE:
		AWXS_CLEARERROR
		
		n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;
		gErr = self->err = awGetEventTypeDefs ( self->client, n, event_type_names, &typeDefs );

		AWXS_CHECKSETERROR_RETURN


		/* convert to an AV of xsBrokerTypeDefs */
		{
		SV *sv;
		int i;
		xsBrokerTypeDef * typeDef;

		RETVAL = newAV();

		for ( i = 0; i<n; i++ ) {
			typeDef = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
			if ( typeDef == NULL ) {
				setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
				if ( self->Warn || gWarn )
					warn ( gErrMsg );
#endif /* AWXS_WARNS */
				XSRETURN_UNDEF;
			}
			/* initialize the error cleanly */
			typeDef->err    = AW_NO_ERROR;
			typeDef->errMsg = NULL;
			typeDef->Warn   = gWarn;

			typeDef->type_def = typeDefs[i];

			sv = sv_newmortal();
			sv_setref_pv( sv, "Aw::TypeDef", (void*)typeDef );
			SvREFCNT_inc(sv);
			av_push( RETVAL, sv );
		}  /* for */
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( event_type_names );
		free ( typeDefs );



AV *
getFds ( self )
	Aw::Event self

	PREINIT:
		int n, *ints;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetFds( &n, &ints );

		AWXS_CHECKSETERROR_RETURN
		

		{
		SV *sv;
		int i;
			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				sv = newSViv( ints[i] );
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( ints );



awaBool
isClientPending ( self )
	Aw::Client self

	PREINIT:
		BrokerBoolean bRV;

	ALIAS:
		Aw::Client::isPending = 1
		
	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? awIsPending ( &bRV )
		  : awIsClientPending ( self->client, &bRV )
		;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



awaBool
isConnected ( self )
	Aw::Client self

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = awIsClientConnected ( self->client );

	OUTPUT:
	RETVAL



char *
makeTransactionId ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::getApplicationName                  = 1
		Aw::Client::getBrokerHost                       = 2
		Aw::Client::getBrokerName                       = 3
		Aw::Client::getClientGroup                      = 4
		Aw::Client::getClientId                         = 5
		Aw::Client::getPlatformInfo                     = 6
		Aw::Client::getTerritoryName                    = 7
		Aw::Client::getSSLBrokerIssuerDistinguishedName = 8
		Aw::Client::getSSLBrokerDistinguishedName       = 9

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= 
#ifdef AW_COMPATIBLE 
		  (ix>=8)
		  ? (ix==9)
		    ? awGetClientSSLBrokerIssuerDistinguishedName ( self->client, &RETVAL ) // 9
		    : awGetClientSSLBrokerDistinguishedName ( self->client, &RETVAL ) // 8
		  : 
#endif /* AW_COMPATIBLE */
		    (ix>=4)
		    ? (ix>=6)
		      ? (ix==7)
		        ? awGetClientTerritoryName ( self->client, &RETVAL )       // 7
		        : awGetPlatformInfo ( (char *)SvPV(ST(1),PL_na), &RETVAL ) // 6
		      : (ix==5)
		        ? awGetClientId ( self->client, &RETVAL )                  // 5
		        : awGetClientGroup ( self->client, &RETVAL )               // 4
		    : (ix>=2)
		      ? (ix==3)
		        ? awGetClientBrokerName ( self->client, &RETVAL )          // 3
		        : awGetClientBrokerHost ( self->client, &RETVAL )          // 2
		      : (ix)
		        ? awGetClientApplicationName ( self->client, &RETVAL )     // 1
		        : awMakeTransactionId ( self->client, &RETVAL )            // 0
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
makeUniqueSubId ( self )
	Aw::Client self

	ALIAS:
		Aw::Client::getBrokerPort               = 1
		Aw::Client::getFd                       = 2
		Aw::Client::getQueueLength              = 3
		Aw::Client::getSSLEncryptionLevel       = 4
		Aw::Client::getStateShareLimit          = 5

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		 = (ix>3)
		   ? (ix==5)
		     ? awGetClientStateShareLimit ( self->client, &RETVAL )     // 5
		     : awGetClientSSLEncryptionLevel ( self->client, &RETVAL )  // 4
		   : (ix>1)
		     ? (ix==3)
		       ? awGetClientQueueLength ( self->client, &RETVAL )       // 3
		       : awGetFd ( self->client, &RETVAL )                      // 2
		     : (ix)
		       ? awGetClientBrokerPort ( self->client, &RETVAL )        // 1
		       : awMakeUniqueSubId     ( self->client, &RETVAL )        // 0
		 ;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



char *
nameTest ( self )
	Aw::Client self

	CODE:
		RETVAL = GvNAME(CvGV(cv)) ;

	OUTPUT:
	RETVAL



awaBool
_newSubscription ( self, event_type_name, filter, ... )
	char * event_type_name
	char * filter

	ALIAS:
		Aw::Adapter::newSubscription = 1
		Aw::Util::newSubscription    = 2

	PREINIT:
		xsBrokerEvent * requestEvent;
		xsAdapterEventType * requestDef;

	CODE:
		if ( isdigit(filter[0]) )
			*filter = atoi ( filter );

		if ( ix ) {
			if ( items > 3 ) {
				requestEvent = AWXS_BROKEREVENT(3);

			} else {
				requestEvent = (xsBrokerEvent *)safemalloc ( sizeof (xsBrokerEvent) );
				requestEvent->event = 0;
			}
			if ( items > 4) {
				requestDef = AWXS_ADAPTEREVENTTYPE(4);
			} else {
				requestDef = (xsAdapterEventType *)safemalloc ( sizeof (xsAdapterEventType) );
				requestDef->adapterET = 0;
			}

		}

		if ( ix == 1 ) {
			awAdapterHandle handle;
			xsAdapter * self = AWXS_ADAPTER(0);

			awAdapterInitHandle ( &handle, self->adapter, requestEvent->event, requestDef->adapterET );

			gErr = self->err = awAdapterNewSubscription ( &handle, event_type_name, filter ); 

		} else if ( ix == 2 ) {
			xsAdapterUtil * self = AWXS_ADAPTERUTIL(0);
			if ( items > 3 )
				awAdapterInitHandle ( self->handle, self->adapter, requestEvent->event, requestDef->adapterET );

				gErr = self->err = awAdapterNewSubscription ( self->handle, event_type_name, filter );

		} else {
			xsBrokerClient * self = AWXS_BROKERCLIENT(0);
			gErr = self->err = awNewSubscription ( self->client, event_type_name, filter );
			if ( self->err != AW_NO_ERROR ) {
				self->errMsg = setErrMsg ( &gErrMsg, 3, "Could not create subscription for \"%s\": %s\n", event_type_name, awErrorToCompleteString ( self->err ) );
				if ( self->Warn || gWarn )
					warn ( self->errMsg );
			}

		}

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;
	
	OUTPUT:
	RETVAL



awaBool
newSubscriptionWithId ( self, sub_id, event_type_name, ... )
	Aw::Client self
	int sub_id
	char * event_type_name

	PREINIT:
		char * filter = 0x0;

	CODE:
		AWXS_CLEARERROR

		if (items == 4) {
			filter = (char *)SvPV ( ST(3), PL_na );
			if ( isdigit(filter[0]) )
		  		*filter = atoi ( filter );
		}

		gErr = self->err = awNewSubscriptionWithId ( self->client, sub_id, event_type_name, filter );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;
	
	OUTPUT:
	RETVAL



awaBool
newSubscriptionFromStruct ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::newSubscriptionFromStructs = 1
		
	PREINIT:
		AV * av = NULL;
		SV ** sv;
		int i, n;
		BrokerSubscription * subs;

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV )
			av = (AV*)SvRV( ST(1) );
		else if ( items > 2 )
			av = av_make ( (items-1), &ST(1) );
		else
			subs = AWXS_BROKERSUBSCRIPTION(1);

		if ( av ) {
			n = av_len ( av ) + 1;

			/* Convert AV into Array of BrokerEvents */

			subs = (BrokerSubscription *)safemalloc ( n * sizeof(BrokerSubscription) );

			for (i=0; i<n; i++) {
				sv = av_fetch ( av, i, 0 );
				subs[i] =* ((BrokerSubscription *)SvIV( *sv ) );
			}
		}

		gErr = self->err
		= (ix)
		  ? awNewSubscriptionsFromStructs ( self->client, n, subs )
		  : awNewSubscriptionFromStruct ( self->client, subs )
		;

		if ( av )
			Safefree ( subs );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;
	
	OUTPUT:
	RETVAL



awaBool
publish ( self, event )
	Aw::Client self
	Aw::Event event

	ALIAS:	
		Aw::Client::publishEvents    = 1
		Aw::Client::setClientInfoset = 2

	PREINIT:
		AV * av = NULL;
		SV ** sv;
		int i, n;
		char * event_type_name;
		BrokerEvent * events;

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV )
			av = (AV*)SvRV( ST(1) );
		else if ( items > 2 )
			av = av_make ( (items-1), &ST(1) );
		else
			events =& AWXS_BROKEREVENT(1)->event;


		if ( av ) {
			n = av_len ( av ) + 1;

			/* Convert AV into Array of BrokerEvents */

			events = (BrokerEvent *)safemalloc ( n * sizeof(BrokerEvent) );

			for (i=0; i<n; i++) {
				sv = av_fetch ( av, i, 0 );
				events[i] = ((xsBrokerEvent *)SvIV( *sv ) )->event;
			}
		}


		gErr = self->err
		= (ix)
		  ? (ix-1)
		    ? awSetClientInfoset ( self->client, *events )
		    : awPublishEvents ( self->client, n, events )
		  : awPublishEvent ( self->client, *events )
		;

		AWXS_CHECKSETERROR


		if ( !ix && self->err != AW_NO_ERROR ) {
			event_type_name = awGetEventTypeName ( *events );

			self->errMsg = setErrMsg ( &gErrMsg, 3, "Could not publish event %s : %s\n", event_type_name, awErrorToCompleteString ( self->err ) );
			if ( self->Warn || gWarn )
				warn ( gErrMsg );
			free ( event_type_name );
		}

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		if ( av )
			Safefree ( events );



awaBool
_publishEventsWithAck ( self, ... )
	Aw::Client self

	ALIAS:
		Aw::Client::_deliverEventsWithAck = 1

	PREINIT:
		int i, n, n_acks, ack_type;
		char * dest_id;
		AV * av = NULL;
		AV * eventsAV;
		AV * ack_seqnAV;
		SV ** sv;
		BrokerLong * ack_seqn;
		BrokerEvent ** events;

	CODE:
		AWXS_CLEARERROR
#if ( AW_VERSION_31 || AW_VERSION_40 )

		if ( ix )
			dest_id = (char *)SvPV ( ST(1), PL_na );
		eventsAV   = (AV*)SvRV( ST(1+ix) );
		ack_type   = (int)SvIV( ST(2+ix) );
		ack_seqnAV = (AV*)SvRV( ST(3+ix) );
		
		n      = av_len ( eventsAV )   + 1;
		n_acks = av_len ( ack_seqnAV ) + 1;
		
		events = (BrokerEvent **) malloc ( n * sizeof (BrokerEvent *) );
		for ( i = 0; i<n; i++ ) {
			sv = av_fetch ( eventsAV, i, 0 );
			events[i] =& ((xsBrokerEvent *)SvIV((SV*)SvRV( *sv )))->event;
		}
		ack_seqn = (BrokerLong *) malloc ( n_acks * sizeof (BrokerLong) );
		for ( i = 0; i<n; i++ ) {
			sv = av_fetch ( ack_seqnAV, i, 0 );
			ack_seqn[i] = awBrokerLongFromString ( longlong_to_string ( SvLLV( *sv ) ) );
		}

		gErr = self->err
		= ( ix )
		  ? awDeliverEventsWithAck ( self->client, dest_id, n, *events, ack_type, n_acks, ack_seqn )
		  : awPublishEventsWithAck ( self->client, n, *events, ack_type, n_acks, ack_seqn )
		;

		AWXS_CHECKSETERROR

		Safefree ( events );
		Safefree ( ack_seqn );


		if ( self->err != AW_NO_ERROR || av == NULL ) {
			if ( av )
				Safefree ( av );

			XSRETURN_UNDEF;
		}
#else
		warn ( "'publishEventsWithAck/deliverEventsWithAck' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */


	OUTPUT:
	RETVAL



AV *
publishRequestAndWaitRef ( self, event, msecs )
	Aw::Client self
	Aw::Event event
	int msecs

	PREINIT:
		int n;
		BrokerEvent * reply_events;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awPublishRequestAndWait ( self->client, event->event, msecs, &n, &reply_events );

		if ( self->err != AW_NO_ERROR ) {
			printf ("%s\n", awErrorToCompleteString ( gErr ) );
			XSRETURN_UNDEF;
		}


		/* now convert reply_events into an AV */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
				if ( ev == NULL ) {
					self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
					if ( self->Warn )
						warn ( self->errMsg );
#endif /* AWXS_WARNS */
					continue;
				}
				ev->err      = NULL;
				ev->errMsg   = NULL;
				ev->Warn     = gWarn;
				ev->deleteOk = 0;

				ev->event    = reply_events[i];
				
				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::Event", (void*)ev );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );

			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



# this could be ALIASed to new
#
Aw::Client
_reconnect ( CLASS, broker_host, broker_name, client_id, ... )
	char * CLASS
	char * broker_host
	char * broker_name
	char * client_id

	PREINIT:
		BrokerConnectionDescriptor myDesc = NULL;

	CODE:
		RETVAL = (xsBrokerClient *)safemalloc ( sizeof(xsBrokerClient) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new client" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;


		if ( broker_name[0] == '\0' )
			broker_name = NULL;

		if ( items == 5 && ( sv_isobject(ST(4)) && (SvTYPE(SvRV(ST(4))) == SVt_PVMG) ) )
			myDesc = AWXS_BROKERCONNECTIONDESC(4)->desc;


		gErr = RETVAL->err = awReconnectBrokerClient(broker_host, broker_name, client_id, myDesc, &RETVAL->client);

		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new event %s", awErrorToCompleteString ( RETVAL->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



awaBool
registerCallback ( self, method, ... )
	Aw::Client self
	char * method

	ALIAS:
		Aw::Client::registerConnectionCallback = 1

	PREINIT:
		xsCallBackStruct * cb;

	CODE:
		AWXS_CLEARERROR
		
		cb = (xsCallBackStruct *) malloc ( sizeof (xsCallBackStruct) );
		cb->self   = ST(0);
		cb->data   = (ix) ? ST(2) : Nullsv;
		cb->id     = 0;
		cb->method = strdup ( method );

		gErr = self->err
		= (ix)
		  ? awRegisterClientConnectionCallback ( self->client, BrokerConnectionCallbackFunc, cb )
		  : awRegisterCallback ( self->client, BrokerCallbackFunc, cb )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
registerCallbackForTag ( self, tag, cancel_when_done, method, client_data )
	Aw::Client self
	int tag
	awaBool cancel_when_done
	char * method
	SV * client_data

	PREINIT:
		xsCallBackStruct * cb;

	CODE:
		AWXS_CLEARERROR
		
		cb = (xsCallBackStruct *) malloc ( sizeof (xsCallBackStruct) );
		cb->self   = ST(0);
		cb->data   = client_data;
		cb->id     = tag;
		cb->method = strdup ( method );

		gErr = self->err = awRegisterCallbackForTag ( self->client, tag, cancel_when_done, BrokerCallbackFunc, cb );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
registerCallbackForSubId ( self, sub_id, method, client_data )
	Aw::Client self
	int sub_id
	char * method
	SV * client_data

	PREINIT:
		xsCallBackStruct * cb;

	CODE:
		AWXS_CLEARERROR
		
		cb = (xsCallBackStruct *) malloc ( sizeof (xsCallBackStruct) );
		cb->self   = ST(0);
		cb->data   = client_data;
		cb->id     = sub_id;
		cb->method = strdup ( method );

		gErr = self->err = awRegisterCallbackForSubId ( self->client, sub_id, BrokerCallbackFunc, cb );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setClientAutomaticControlLabel ( self, enabled )
	Aw::Client self
	awaBool enabled

	CODE:
		AWXS_CLEARERROR
		
		gErr   = self->err = awSetClientAutomaticControlLabel ( self->client, (BrokerBoolean) enabled );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setStateShareLimit ( self, limit )
	Aw::Client self
	int limit

	CODE:
		AWXS_CLEARERROR
		
		gErr   = self->err = awSetClientStateShareLimit ( self->client, limit );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



Aw::Event
getEventTypeInfoset ( self, event_type_name, infoset_name )
	Aw::Client self
	char * event_type_name
	char * infoset_name

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetEventTypeInfoset ( self->client, event_type_name, infoset_name, &RETVAL->event );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



AV *
getEventTypeInfosetsRef ( self, event_type_name, infoset_names )
	Aw::Client self
	char *event_type_name
	char ** infoset_names

	PREINIT:
		int n;
		BrokerEvent * events;

	CODE:
		AWXS_CLEARERROR
		
		n = av_len ( (AV*)SvRV( ST(2) ) ) + 1;

		gErr = self->err = awGetEventTypeInfosets ( self->client, event_type_name, &n, infoset_names, &events );

		AWXS_CHECKSETERROR_RETURN

		/* now convert reply_events into an AV */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
				if ( ev == NULL ) {
					self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
					if ( self->Warn )
						warn ( self->errMsg );
#endif /* AWXS_WARNS */
					continue;
				}
				ev->err      = NULL;
				ev->errMsg   = NULL;
				ev->Warn     = gWarn;
				ev->deleteOk = 0;

				ev->event    = events[i];
				
				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::Event", (void*)ev );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( infoset_names );
		SvREFCNT_dec ( RETVAL );




#===============================================================================

MODULE = Aw			PACKAGE = Aw::ConnectionDescriptor

#===============================================================================

#===============================================================================
#  Aw::ConnectionDescriptor
#	::new
#	::DESTROY-A
#
#	::copy
#	::getAccessLabelHint		Java-I 15-84
#	::getAutomaticReconnect		Java-I 15-85
#	::getConnectionShare		Java-I 15-85
#	::getSSLCertificate		Java-I 15-86
#	::getSSLCertificateDns		Java-I 15-87
#	::getSSLCertificateFile		Java-I 15-87
#	::getSSLDistinguishedName	Java-I 15-88
#	::getSSLEncrypted		Java-I 15-88
#	::getSSLEncryptionLevel		Java-I 15-88
#	::getSSLRootDns			Java-I 15-89
#	::getStateShare			Java-I 15-89
#	::setAccessLabelHint		Java-I 15-90
#	::setAutomaticReconnect		Java-I 15-90
#	::setConnectionShare		Java-I 15-91
#	::setSSLCertificate		Java-I 15-91
#	::setSSLEncrypted		Java-I 15-92
#	::setStateShare			Java-I 15-93
#	::toString-A			Java-I 15-93
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::ConnectionDescriptor
new ( CLASS )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerConnectionDescriptor *)safemalloc ( sizeof(xsBrokerConnectionDescriptor) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new connection descriptor" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->desc = awNewBrokerConnectionDescriptor ();

	OUTPUT:
	RETVAL



Aw::ConnectionDescriptor
copy ( self )
	Aw::ConnectionDescriptor self

	PREINIT:
		char CLASS[] = "Aw::TypeDef";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerConnectionDescriptor *)safemalloc ( sizeof(xsBrokerConnectionDescriptor) );

		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new connection descriptor copy" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->desc = awCopyDescriptor ( self->desc );

	OUTPUT:
	RETVAL



char *
getAccessLabelHint ( self )
	Aw::ConnectionDescriptor self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetDescriptorAccessLabelHint ( self->desc, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



# 
#   hrm, maybe this should be an HV*?
# 
AV *
getSSLCertificateRef ( self )
	Aw::ConnectionDescriptor self

	PREINIT:
		char * certificate_file;
		char * distinguished_name;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetDescriptorSSLCertificate ( self->desc, &certificate_file, &distinguished_name );

		AWXS_CHECKSETERROR_RETURN

		{
		SV *sv;
		RETVAL = newAV();
			
			sv = newSVpv( certificate_file, 0 );
			av_push( RETVAL, sv );

			sv = newSVpv( distinguished_name, 0 );
			av_push( RETVAL, sv );
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( certificate_file );
		free ( distinguished_name );



char *
getSSLCertificateFile ( self )
	Aw::ConnectionDescriptor self

	PREINIT:
		char * distinguished_name;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetDescriptorSSLCertificate ( self->desc, &RETVAL, &distinguished_name );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( distinguished_name );



char *
getSSLDistinguishedName ( self )
	Aw::ConnectionDescriptor self

	PREINIT:
		char * certificate_file;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetDescriptorSSLCertificate ( self->desc, &certificate_file, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( certificate_file );



int
getSSLEncryptionLevel ( self )
	Aw::ConnectionDescriptor self

	CODE:
		AWXS_CLEARERROR

		RETVAL = awGetSSLEncryptionLevel ();

	OUTPUT:
	RETVAL



AV *
getSSLCertificateDnsRef ( self, certificate_file, password )
	Aw::ConnectionDescriptor self
	char *certificate_file
	char *password

	ALIAS:
		Aw::ConnectionDescriptor::getSSLRootDnsRef = 1

	PREINIT:
		int n;
		char ** distinguished_names;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awGetSSLRootDns ( certificate_file, password, &n, &distinguished_names )
		  : awGetSSLCertificateDns ( certificate_file, password, &n, &distinguished_names )
		;


		AWXS_CHECKSETERROR_RETURN

		{
		SV *sv;
		int i;
			RETVAL = newAV();
			sv = newSViv( n );
			av_push( RETVAL, sv );

			for ( i = 0; i<n; i++ ) {
				sv = newSVpv( distinguished_names[i], 0 );
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( distinguished_names );



awaBool
getStateShare ( self )
	Aw::ConnectionDescriptor self

	ALIAS:
		Aw::ConnectionDescriptor::getSSLEncrypted       = 1
		Aw::ConnectionDescriptor::getAutomaticReconnect = 2
		Aw::ConnectionDescriptor::getConnectionShare    = 3

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (ix>=2)
		  ? (ix-2)
	        ? awGetDescriptorConnectionShare ( self->desc, &bRV )           // 3
		    : awGetDescriptorAutomaticReconnect ( self->desc, &bRV )    // 2
		  : (ix)
		    ? awGetDescriptorSSLEncrypted ( self->desc, &bRV )          // 1
		    : awGetDescriptorStateShare ( self->desc, &bRV )            // 0
		;

		AWXS_CHECKSETERROR

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



awaBool
setAccessLabelHint ( self, hint )
	Aw::ConnectionDescriptor self
	char * hint

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetDescriptorAccessLabelHint ( self->desc, hint );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setSSLCertificate ( self, certificate_file, password, distinguished_name )
	Aw::ConnectionDescriptor self
	char *certificate_file
	char *password
	char *distinguished_name

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetDescriptorSSLCertificate ( self->desc, certificate_file, password, distinguished_name );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setStateShare ( self, value )
	Aw::ConnectionDescriptor self
	awaBool value

	ALIAS:
		Aw::ConnectionDescriptor::setSSLEncrypted       = 1
		Aw::ConnectionDescriptor::setAutomaticReconnect = 2
		Aw::ConnectionDescriptor::setConnectionShare    = 3

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix>=2)
		  ? (ix-2)
		    ? awSetDescriptorConnectionShare ( self->desc, (BrokerBoolean)value )
		    : awSetDescriptorAutomaticReconnect ( self->desc, (BrokerBoolean)value )
		  : (ix)
		    ? awSetDescriptorSSLEncrypted ( self->desc, (BrokerBoolean)value )
		    : awSetDescriptorStateShare ( self->desc, (BrokerBoolean)value )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char *
getSharedEventOrdering ( self )
	Aw::ConnectionDescriptor self

	CODE:
		AWXS_CLEARERROR
#if ( AW_VERSION_31 || AW_VERSION_40 )

		gErr = self->err = awGetDescriptorSharedEventOrdering ( self->desc, &RETVAL );

		AWXS_CHECKSETERROR_RETURN
#else
		warn ( "'getBrokerVersionNumber' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
	RETVAL



awaBool
setSharedEventOrdering ( self, ordering )
	Aw::ConnectionDescriptor self
	char * ordering

	CODE:
		AWXS_CLEARERROR
#if ( AW_VERSION_31 || AW_VERSION_40 )
		gErr = self->err = awSetDescriptorSharedEventOrdering ( self->desc, ordering );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;
#else
		warn ( "'getBrokerVersionNumber' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
	RETVAL


#===============================================================================

MODULE = Aw			PACKAGE = Aw::Date

#===============================================================================

#===============================================================================
#  Aw::Date
#	::new
#	::DESTROY-A
#
#	::clear				Java-I 15-96
#	::clearDate			   C
#	::clearTime			Java-I 15-96
#	::compareTo			Java-I 15-97
#	::equals-A			Java-I 15-97
#	::setDate			Java-I 15-99
#	::setDateCtime			(Not in Java API)
#	::setDateTime			Java-I 15-145
#	::setTime			Java-I 15-100
#	::toString-A			Java-I 15-100
#===============================================================================



Aw::Date
new ( CLASS )
	char * CLASS

	CODE:
		if ( items == 1 )
			RETVAL = awNewEmptyBrokerDate ();
		else {
			int yr = (int)SvIV( ST(1) );
			int mo = (int)SvIV( ST(2) );
			int dy = (int)SvIV( ST(3) );
			int hr = (int)SvIV( ST(4) );
			int m  = (int)SvIV( ST(5) );
			int s  = (int)SvIV( ST(6) );
			int ms = (int)SvIV( ST(7) );
			RETVAL = awNewBrokerDate ( yr, mo, dy, hr, m, s, ms );
		}

	OUTPUT:
	RETVAL



void
clear ( self )
	Aw::Date self

	ALIAS:
		Aw::Date::clearDate = 1
		Aw::Date::clearTime = 2

	CODE:
		if (ix < 2)
			awClearDate ( self );
		else if ( ix != 1 )
			awClearTime ( self );



int
compareTo ( self, date )
	Aw::Date self
	Aw::Date date

	ALIAS:
		Aw::Date::equals = 1

	CODE:
		RETVAL = awCompareDate ( self, date );
		if (ix) {
			if ( RETVAL == 0 ) {
				RETVAL = 1;  /* awaTrue */
			} else {
				RETVAL = 0;  /* awaFalse */
			}
		}

	OUTPUT:
	RETVAL



time_t
getDateCtime ( self )
	Aw::Date self

	CODE:
		gErr = awGetDateCtime ( self, &RETVAL );
	
		if ( gErr != AW_NO_ERROR )
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



void
setDate ( self, yr, mo, dy )
	Aw::Date self
	int yr
	int mo
	int dy

	CODE:
		awSetDate ( self, yr, mo, dy );



void
setDateCtime ( self, t )
	Aw::Date self
	time_t t

	CODE:
		awSetDateCtime ( self, t );



void
setDateTime ( self, yr, mo, dy, hr, m, s, ms )
	Aw::Date self
	int yr
	int mo
	int dy
	int hr
	int m
	int s
	int ms

	CODE:
		awSetDateTime ( self, yr, mo, dy, hr, m, s, ms );



void
setTime ( self,  hr, m, s, ms )
	Aw::Date self
	int hr
	int m
	int s
	int ms

	CODE:
		awSetTime ( self, hr, m, s, ms );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Error

#===============================================================================

#===============================================================================
#  Aw::Error
#	::new
#	::DESTROY-A
#
#	::getCode			Java-I 15-147
#	::getMinorCode-A		Java-I 15-148
#	::toString-A			Java-I 15-149
#	::toCompleteString		Java-I 15-149
#	::delete			C CADK  6-54
#	::last
#	::setCurrent
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#===============================================================================



Aw::Error
new ( CLASS )
	char * CLASS

	ALIAS:
		Aw::Error::last = 1

	CODE:
		RETVAL = (xsBrokerError *)safemalloc ( sizeof(xsBrokerError) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new error" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = (ix) ? awCopyError ( gErr ) : NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

	OUTPUT:
	RETVAL



int
getCode ( ... )

	ALIAS:	
		Aw::Error::getMinorCode = 1

	CODE:
		RETVAL
		= (ix)
		  ? (items)
		    ? awGetErrorMinorCode ( AWXS_BROKERERROR(0)->err )
		    : awGetErrorMinorCode ( gErr )

		  : (items)
		    ? awGetErrorCode ( AWXS_BROKERERROR(0)->err )
		    : awGetErrorCode ( gErr )
		;
	
	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::Error self

	CODE:
		awDeleteError ( self->err );



int
getDiagnostics ( self )
	Aw::Error self

	CODE:
		RETVAL = awGetDiagnostics();

	OUTPUT:
	RETVAL



void
setCurrent ( self, ... )
	Aw::Error self

	CODE:
		if ( items == 2 ) {
			awDeleteError ( self->err );
			self->err = awCopyError ( AWXS_BROKERERROR(1)->err );
		}

		if ( self->err == NULL )
			return;

		awSetCurrentError ( self->err );
		gErr = self->err;



void
setDiagnostics ( self, diag )
	Aw::Error self
	int diag

	CODE:
		awSetDiagnostics ( diag );



char *
toCompleteString ( ... )

	CODE:
		RETVAL
		= (items)
		  ? awErrorToCompleteString ( AWXS_BROKERERROR(0)->err )
		  : awErrorToCompleteString ( gErr )
		;
	
	
	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Event

#===============================================================================

#===============================================================================
#  Aw::Event
#	::new
#	::DESTROY-A
#
#	::clear 			Java-I 15-103
#	::clearField			Java-I 15-104
#	::getBaseName			Java-I 15-110
#	::getBooleanField		Java-I 15-110
#	::getByteField			Java-I 15-111
#	::getCharField			Java-I 15-111
#	::getClient			Java-I 15-111
#	::getDateField			Java-I 15-111  
#	::getDoubleField		Java-I 15-111
#	::getEventId			Java-I 15-112
#	::getField			Java-I 15-112
#	::getFieldNames			Java-I 15-113
#	::getFieldType-A		Java-I 15-113
#	::getFloatField			Java-I 15-114
#	::getStringField		Java-I 15-118
#	::getSubscriptionIds		Java-I 15-121
#	::getTag 			Java-I 15-121
#	::getTypeDef			Java-I 15-122
#	::getTypeName			Java-I 15-122
#	::getBaseName-A			     C
#	::getFamilyName-A		     C
#	::getScopeName-A		     C
#	::getUCCharField		Java-I 15-122
#	::getUCStringField		Java-I 15-122
#
#	::isAckReply			Java-I 15-123
#	::isErrorReply			Java-I 15-123
#	::isFieldSet			Java-I 15-124
#	::isLastReply			Java-I 15-124
#	::isNullReply			Java-I 15-124
#
#	::setBooleanField
#	::setByteField
#	::setCharField
#	::setDateField 			Java-I 15-125
#	::setDoubleField
#	::setField			Java-I 15-130
#	::setFloatField
#	::setIntegerField
#	::setLongField			Java-I 15-133
#	::setShortField
#	::setStringField		Java-I 15-138
#	::setStringFieldToSubstring
#	::setUCCharField
#	::setUCStringField
#	::setUCStringFieldToSubstring
#	::setTag 			Java-I 15-142
#
#	::toFormattedString		Java-I 15-145
#	::toString-A			Java-I 15-145
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#	::error-A
#===============================================================================



Aw::Event
_new ( CLASS, client, event_type_name, ... )
	char * CLASS
	Aw::Client client
	char * event_type_name


	CODE:
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = RETVAL->err = awNewBrokerEvent ( client->client, event_type_name, &RETVAL->event );

		AWXS_CHECKSETERROR_RETURN

		if ( items == 4 )
		  {
			HV * hv;

    			if( SvROK(ST(3)) && (SvTYPE(SvRV(ST(3))) == SVt_PVHV) )
			        hv = (HV*)SvRV( ST(3) );
			    else {
			        warn( "Aw::Event::new() -- hv is not an HV reference" );
			        XSRETURN_UNDEF;
			    };

			gErr = RETVAL->err = awxsSetEventFromHash ( RETVAL->event, hv );
		  }

		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new event: %s", awErrorToCompleteString ( RETVAL->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



awaBool
clear ( self )
	Aw::Event self

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awClearEvent ( self->event );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
clearField ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awClearEventField ( self->event, field_name );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::Event self

	CODE:
		awDeleteEvent ( self->event );



Aw::Event
fromBinData ( self, client, data, size )
	Aw::Event self
	Aw::Client client
	char * data
	int size

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err =  awEventFromBinData ( client->client, data, size, &RETVAL->event );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
getBooleanField ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetBooleanField ( self->event, field_name, &bRV );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



char
getByteField ( self, field_name )
	Aw::Event self
	char * field_name

	ALIAS:
		Aw::Event::getCharField = 1

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err
		= (ix)
		  ? awGetCharField ( self->event, field_name, &RETVAL )
		  : awGetByteField ( self->event, field_name, &RETVAL )
		;
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



Aw::Client
getClient ( self )
	Aw::Event self

	PREINIT:
		char CLASS[] = "Aw::Client";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerClient *)safemalloc ( sizeof(BrokerClient) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new date" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetEventClient ( self->event, &RETVAL->client );

		AWXS_CHECKSETERROR

		if ( RETVAL == NULL ) {
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



Aw::Date
getDateField ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		char CLASS[] = "Aw::Date";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (BrokerDate *)safemalloc ( sizeof(BrokerDate) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new date" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		gErr = self->err = awGetDateField ( self->event, field_name, RETVAL );

		if ( self->err != AW_NO_ERROR ) {
			sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



double
getDoubleField ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetDoubleField ( self->event, field_name, &RETVAL );
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



CORBA::LongLong
getEventId ( self )
	Aw::Event self

	ALIAS:
		Aw::Event::getReceiptSequenceNumber = 1

	PREINIT:
		BrokerLong blValue;
		char blString[24];
		
	CODE:
		AWXS_CLEARERROR
		

		blValue
		= (ix)
		  ? awGetEventReceiptSequenceNumber ( self->event )
		  : awGetEventId ( self->event )
		;

		RETVAL = longlong_from_string ( awBrokerLongToString( blValue, blString ) );

	OUTPUT:
	RETVAL



SV *
getFieldRef ( self, field_name )
	Aw::Event self
	char * field_name


	CODE:
		AWXS_CLEARERROR
		
		RETVAL = getSV ( self->event, field_name );

		if ( RETVAL == Nullsv ) {
			// gErr = self->err = getEventToHashErr(); 
			AWXS_CHECKSETERROR_RETURN
		}

	OUTPUT:
	RETVAL



float
getFloatField ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetFloatField ( self->event, field_name, &RETVAL );
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



char **
getFieldNamesRef ( self, ... )

	ALIAS:
		Aw::TypeDef::getFieldNamesRef = 1

	PREINIT:
		int count_charPtrPtr;
		char *  field_name = NULL;

	CODE:
		
		if ( items == 2 )
			field_name = (char *)SvPV ( ST(1), PL_na );

		if ( ix ) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
			gErr
			= self->err
			= awGetTypeDefFieldNames ( self->type_def, field_name, &count_charPtrPtr, &RETVAL );
		} else {
			xsBrokerEvent * self = AWXS_BROKEREVENT(0);
			AWXS_CLEARERROR
			gErr
			= self->err
			= awGetFieldNames ( self->event, field_name, &count_charPtrPtr, &RETVAL );
		}

	
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
getIntegerField ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetIntegerField ( self->event, field_name, &RETVAL );
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



CORBA::LongLong
getLongField ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		BrokerLong blValue;
		char blString[24];
		
	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetLongField ( self->event, field_name, &blValue );

		RETVAL = longlong_from_string ( awBrokerLongToString( blValue, blString ) );
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



CORBA::LongLong
getPublishSequenceNumber ( self )
	Aw::Event self

	PREINIT:
		BrokerLong blValue;
		char blString[24];

	CODE:
		AWXS_CLEARERROR
		
		blValue = awGetEventPublishSequenceNumber ( self->event );
		RETVAL  = longlong_from_string ( awBrokerLongToString( blValue, blString ) );

	OUTPUT:
	RETVAL



int
getSequenceFieldSize ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		gErr = self->err = awGetSequenceFieldSize ( self->event, field_name, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



SV *
getSequenceFieldRef ( self, field_name, ... )
	Aw::Event self
	char * field_name

	ALIAS:
		Aw::Event::getBooleanSeqFieldRef  = FIELD_TYPE_BOOLEAN
		Aw::Event::getByteSeqFieldRef     = FIELD_TYPE_BYTE
		Aw::Event::getCharSeqFieldRef     = FIELD_TYPE_CHAR
		Aw::Event::getDateSeqFieldRef     = FIELD_TYPE_DATE
		Aw::Event::getDoubleSeqFieldRef   = FIELD_TYPE_DOUBLE
		Aw::Event::getFloatSeqFieldRef    = FIELD_TYPE_FLOAT
		Aw::Event::getIntegerSeqFieldRef  = FIELD_TYPE_INT
		Aw::Event::getLongSeqFieldRef     = FIELD_TYPE_LONG
		Aw::Event::getShortSeqFieldRef    = FIELD_TYPE_SHORT
		Aw::Event::getStringSeqFieldRef   = FIELD_TYPE_STRING
		Aw::Event::getUCCharSeqFieldRef   = FIELD_TYPE_UNICODE_CHAR
		Aw::Event::getUCStringSeqFieldRef = FIELD_TYPE_UNICODE_STRING

	PREINIT:
		int offset = 0;
		int max_n  = AW_ENTIRE_SEQUENCE;

	CODE:
		AWXS_CLEARERROR
		
		if ( items >= 3 )
			offset = (int)SvIV ( ST(2) );
		if ( items == 4 )
			max_n  = (int)SvIV ( ST(3) );

		RETVAL = getAVN ( self->event, field_name, offset, max_n );

		if ( RETVAL == Nullsv ) {
			// gErr = self->err = getEventToHashErr(); 
			AWXS_CHECKSETERROR_RETURN
		}

	OUTPUT:
	RETVAL



short
getShortField ( self, field_name )
	Aw::Event self
	char * field_name

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetShortField ( self->event, field_name, &RETVAL );
		
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



####################################################################
#
#  Yet another style for working with multiple classes:
#    Using cases, class definition is specified in INPUT
# 
#  My least preferred method, the cases can not share common code. 
# 
####################################################################
char *
getStringField ( self, field_name )

	CASE:	ix == 1
		ALIAS:
			Aw::Adapter::getStringField = 1

		INPUT:  # could break in future if not in INPUT
			Aw::Adapter self;
			char * field_name;

		PREINIT:
			awaBool test;

		CODE:
			AWXS_CLEARERROR
		
			test = awAdapterGetStringField ( self->handle, field_name, &RETVAL );
		
			if ( test == awaFalse )
				XSRETURN_UNDEF;

		OUTPUT:
		RETVAL

	CASE:	ix == 2
		ALIAS:
			Aw::Util::getStringField = 2

		INPUT:
			Aw::Util self;
			char * field_name;

		PREINIT:
			awaBool test;

		CODE:
			AWXS_CLEARERROR
		
			test = awAdapterGetStringField ( self->handle, field_name, &RETVAL );
		
			if ( test == awaFalse )
				XSRETURN_UNDEF;

		OUTPUT:
		RETVAL

	CASE:
		INPUT:
			Aw::Event self;
			char * field_name;

		CODE:
			AWXS_CLEARERROR
		
			gErr = self->err = awGetStringField ( self->event, field_name, &RETVAL );

			AWXS_CHECKSETERROR_RETURN

		OUTPUT:
		RETVAL



Aw::Event
getStructFieldAsEvent ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetStructFieldAsEvent ( self->event, field_name, &RETVAL->event );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



AV *
getStructSeqFieldAsEventsRef ( self, field_name, offset, ... )
	Aw::Event self
	char * field_name
	int offset

	PREINIT:
		int n;
		int max_n = AW_ENTIRE_SEQUENCE;
		BrokerEvent * events;

	CODE:
		AWXS_CLEARERROR
		
		if ( items == 4 )
			max_n = (int)SvIV( ST(3) );

		gErr = self->err = awGetStructSeqFieldAsEvents ( self->event, field_name, offset, max_n, &n, &events );

		AWXS_CHECKSETERROR_RETURN

		/* now convert reply_events into an AV */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
				if ( ev == NULL ) {
					self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
					if ( self->Warn )
						warn ( self->errMsg );
#endif /* AWXS_WARNS */
					continue;
				}
				ev->err      = NULL;
				ev->errMsg   = NULL;
				ev->Warn     = gWarn;
				ev->deleteOk = 0;

				ev->event    = events[i];
				
				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::Event", (void*)ev );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



AV *
getSubscriptionIdsRef ( self )
	Aw::Event self

	PREINIT:
		int n, *ints;

	CODE:
		AWXS_CLEARERROR

		ints = awGetSubscriptionIds ( self->event, &n );

		if ( ints == NULL ) {
			self->errMsg
			= ( n )
			  ? setErrMsg ( &gErrMsg, 1, "Event was created locally." )
			  : setErrMsg ( &gErrMsg, 1, "Event was delivered by broker.  Delivered events are not matched to subscriptions." )
			;
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */

			XSRETURN_UNDEF;
		}

		{
		SV *sv;
		int i;
			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				sv = newSViv( ints[i] );
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );
		free ( ints );



int
getTag ( self )
	Aw::Event self

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetEventTag ( self->event, &RETVAL );
		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



Aw::TypeDef
getTypeDef ( self )
	Aw::Event self

	PREINIT:
		char CLASS[] = "Aw::TypeDef";

	CODE:
		AWXS_CLEARERROR
		
		RETVAL = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new type def" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetTypeDefFromEvent ( self->event, &RETVAL->type_def );
		if ( self->err != AW_NO_ERROR ) {
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
getTypeName ( self )
	Aw::Event self

	ALIAS:
		Aw::Event::getBaseName   = 1
		Aw::Event::getFamilyName = 2
		Aw::Event::getScopeName  = 3

	CODE:
		AWXS_CLEARERROR
		
		RETVAL
		= (ix>=2)
		  ? (ix-2)
		    ? awGetEventTypeScopeName ( self->event )
#ifdef AW_COMPATIBLE
		    : awGetEventTypeFamilyName ( self->event )
#else
		    : NULL
#endif /* AW_COMPATIBLE */
		  : (ix)
		    ? awGetEventTypeBaseName ( self->event)
		    : awGetEventTypeName ( self->event )
		;

	OUTPUT:
	RETVAL



char *
getUCStringField ( self, field_name )
	Aw::Event self
	char * field_name


	ALIAS:
		Aw::Event::getUCStringFieldAsA = 1

	CODE:
		AWXS_CLEARERROR
		
		if ( ix ) {
#if ( AW_VERSION_31 || AW_VERSION_40 )
			gErr = self->err = awGetUCStringFieldAsA ( self->event, field_name, &RETVAL );
#else
			warn ( "'getUCStringFieldAsA' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
			XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */
		} else {
			gErr = self->err = awGetUCStringFieldAsUTF8 ( self->event, field_name, &RETVAL );
		}
		
		if ( self->err != AW_NO_ERROR ) {
			sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
getUCCharField ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		charUC uc[2];

	CODE:
		AWXS_CLEARERROR

		uc[0] = uc[1] = (charUC)NULL;
		
		gErr = self->err = awGetUCCharField ( self->event, field_name, &uc[0] );
		
		AWXS_CHECKSETERROR_RETURN

		RETVAL = awUCtoUTF8 ( uc );

	OUTPUT:
	RETVAL



awaBool
isFieldSet ( self, field_name )
	Aw::Event self
	char * field_name

	PREINIT:
		BrokerBoolean is_set;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awIsEventFieldSet ( self->event, field_name, &is_set );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = ( is_set ) ? awaTrue : awaFalse ;

	OUTPUT:
	RETVAL



awaBool
isAckReply ( self )
	Aw::Event self

	ALIAS:
		Aw::Event::isErrorReply = 1
		Aw::Event::isLastReply  = 2
		Aw::Event::isNullReply  = 3

	CODE:
		AWXS_CLEARERROR

		RETVAL
		= (ix>=2)
		  ? (ix-2)
		    ? awIsNullReplyEvent ( self->event )
		    : awIsLastReplyEvent ( self->event )
		  : (ix)
		    ? awIsErrorReplyEvent ( self->event )
		    : awIsAckReplyEvent ( self->event )
		;

	OUTPUT:
	RETVAL



awaBool
_setField ( self, field_name, value )
	Aw::Event self
	char * field_name

	ALIAS:
		Aw::Event::setBooleanField  = FIELD_TYPE_BOOLEAN
		Aw::Event::setByteField     = FIELD_TYPE_BYTE
		Aw::Event::setCharField     = FIELD_TYPE_CHAR
		Aw::Event::setDateField     = FIELD_TYPE_DATE
		Aw::Event::setDoubleField   = FIELD_TYPE_DOUBLE
		Aw::Event::setFloatField    = FIELD_TYPE_FLOAT
		Aw::Event::setIntegerField  = FIELD_TYPE_INT
		Aw::Event::setLongField     = FIELD_TYPE_LONG
		Aw::Event::setShortField    = FIELD_TYPE_SHORT
		Aw::Event::setStringField   = FIELD_TYPE_STRING
		Aw::Event::setUCCharField   = FIELD_TYPE_UNICODE_CHAR
		Aw::Event::setUCStringField = FIELD_TYPE_UNICODE_STRING

	PREINIT:
		short field_type = ix ;

	CODE:
		AWXS_CLEARERROR


		if ( !ix )
			gErr = self->err = awGetEventFieldType ( self->event, field_name, &field_type );

		if ( gErr == AW_NO_ERROR )
			gErr = self->err = awxsSetField ( self->event, field_name, field_type, ST(2), NULL, NULL );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setUCStringFieldAsA ( self, field_name, value )
	Aw::Event self
	char * field_name
	char * value

	CODE:
		AWXS_CLEARERROR
#if ( AW_VERSION_31 || AW_VERSION_40 )

		gErr = self->err = awSetUCStringFieldAsA( self->event, field_name, value);

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;
#else
		warn ( "'setUCSTringFieldAsA' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
	RETVAL



awaBool
setPublishSequenceNumber ( self, seqn )
	Aw::Event self
	CORBA::LongLong seqn

	PREINIT:
		BrokerLong blValue;

	CODE:
		AWXS_CLEARERROR
		
		blValue = awBrokerLongFromString ( longlong_to_string ( seqn ) );
		gErr = self->err = awSetEventPublishSequenceNumber ( self->event, blValue );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setSequenceField ( self, field_name, ... )
	Aw::Event self
	char * field_name

	ALIAS:
		Aw::Event::setBooleanSeqField  = FIELD_TYPE_BOOLEAN
		Aw::Event::setByteSeqField     = FIELD_TYPE_BYTE
		Aw::Event::setCharSeqField     = FIELD_TYPE_CHAR
		Aw::Event::setDateSeqField     = FIELD_TYPE_DATE
		Aw::Event::setDoubleSeqField   = FIELD_TYPE_DOUBLE
		Aw::Event::setFloatSeqField    = FIELD_TYPE_FLOAT
		Aw::Event::setIntegerSeqField  = FIELD_TYPE_INT
		Aw::Event::setLongSeqField     = FIELD_TYPE_LONG
		Aw::Event::setShortSeqField    = FIELD_TYPE_SHORT
		Aw::Event::setStringSeqField   = FIELD_TYPE_STRING
		Aw::Event::setUCCharSeqField   = FIELD_TYPE_UNICODE_CHAR
		Aw::Event::setUCStringSeqField = FIELD_TYPE_UNICODE_STRING

	PREINIT:
		short field_type;
		int src_offset  = 0;
		int dest_offset = 0;
		SV ** sv;
		AV  * av;
		int startArray = 2;  /* generally as the 3rd arguement */
		void * value;

	CODE:
		AWXS_CLEARERROR

		if (! ix ) {
			/* this is setSequenceField */
			gErr = self->err = awGetEventFieldType ( self->event, field_name, &field_type );
		} else {
			/* one of the aliases */
			field_type = ix;
		}

		if ( --items > startArray ) {
			src_offset  = (int)SvIV ( ST(2) );
			startArray++;
		}
		if ( items > startArray ) {
			dest_offset = (int)SvIV ( ST(3) );
			startArray++;
		}


		if ( SvTYPE(SvRV(ST(startArray))) == SVt_PVAV )
			av = (AV*)SvRV( ST(startArray) );
		else 
			av = av_make ( (items+1-startArray) , &ST(startArray) );

		gErr = self->err = awxsSetSequenceField ( self->event, field_name, field_type, src_offset, dest_offset, av, NULL, NULL );


		if ( self->err != AW_NO_ERROR ) {
			sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );
			warn ( "Error Found!!" );
			warn ( awErrorToCompleteString( self->err ) );
		}

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;


	OUTPUT:
	RETVAL



awaBool
setStructFieldFromEvent ( self, field_name, value )
	Aw::Event self
	char * field_name
	Aw::Event value

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetStructFieldFromEvent ( self->event, field_name, value->event );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setStructSeqFieldFromEvents ( self, field_name, ... )
	Aw::Event self
	char * field_name

	PREINIT:
		BrokerEvent * events;
		AV * av;
		SV ** sv;
		int src_offset  = 0;
		int dest_offset = 0;
		int i, n;
		int startArray = 2;  /* generally as the 3rd arguement */

	CODE:
		AWXS_CLEARERROR

		if ( --items > startArray ) {
			src_offset  = (int)SvIV ( ST(2) );
			startArray++;
		}
		if ( items > startArray ) {
			dest_offset = (int)SvIV ( ST(3) );
			startArray++;
		}

		if ( SvTYPE(SvRV(ST(startArray))) == SVt_PVAV )
			av = (AV*)SvRV( ST(startArray) );
		else 
			av = av_make ( (items+1-startArray) , &ST(startArray) );

		n  = av_len ( av ) + 1;


		/* Convert AV into Array of BrokerEvents */

		events = (BrokerEvent *)safemalloc ( n * sizeof(BrokerEvent) );
		for (i=0; i<n; i++) {
			sv = av_fetch ( av, i, 0 );
			events[i] = ((xsBrokerEvent *)SvIV( *sv ) )->event;
		}


		gErr = self->err = awSetStructSeqFieldFromEvents ( self->event, field_name, src_offset, dest_offset, n, events );

		AWXS_CHECKSETERROR

		Safefree ( events );

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
init ( self, data )
	Aw::Event self
	HV * data

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awxsSetEventFromHash ( self->event, data );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setStringFieldToSubstring ( self, field_name, char_offset, nc, value )
	Aw::Event self
	char * field_name
	int char_offset
	int nc
	char * value

	ALIAS:
		Aw::Event::setUCStringFieldToSubstring = 1

	PREINIT:
		charUC * uc = NULL;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awSetUCStringFieldToSubstring ( self->event, field_name, char_offset, nc, uc = awUTF8toUC( value ) )
		  : awSetStringFieldToSubstring ( self->event, field_name, char_offset, nc, value )
		;

		if ( uc )
			Safefree ( uc );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setTag ( self, tag )
	Aw::Event self
	int tag

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetEventTag ( self->event, tag );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char *
toBinData ( self )
	Aw::Event self

	PREINIT:
		int size;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awEventToBinData ( self->event, &RETVAL, &size );
		/* "size" is supposed to be a return value in C but not in
		   Java so I am skipping it here.  Also the array structure is
		   unclear to me (byte offsets) so I am just returning a string
		   for now */
		if ( self->err != AW_NO_ERROR ) {
			sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
toFormattedString ( self, format_string )
	Aw::Event self
	char * format_string

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awEventToFormattedString ( self->event, format_string, &RETVAL );
		if ( self->err != AW_NO_ERROR ) {
			sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



awaBool
setSequenceFieldSize ( self, field_name, size )
	Aw::Event self
	char * field_name
	int size

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetSequenceFieldSize ( self->event, field_name, size ); 

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char *
stringFromANSI ( self, string )
	Aw::Event self
	char * string

	CODE:
		AWXS_CLEARERROR

		RETVAL = awAtoUTF8 ( string );

	OUTPUT:
	RETVAL



char *
stringToANSI ( self, utf8String)
	Aw::Event self
	char * utf8String

	CODE:
		AWXS_CLEARERROR

		RETVAL = awUTF8toA ( utf8String );

	OUTPUT:
	RETVAL



HV *
toHashRef ( self )
	Aw::Event self

	CODE:
		AWXS_CLEARERROR

		RETVAL = newHV();

		gErr = self->err = awxsSetHashFromEvent ( self->event, RETVAL );

		hv_store ( RETVAL, "_name", 5, newSVpv ( awGetEventTypeName(self->event), 0), 0 );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



awaBool
validate ( self, client )
	Aw::Event self
	Aw::Client client

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awValidateEvent ( client->client, self->event );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::EventType

#===============================================================================

#===============================================================================
#  Aw::EventType
#	::new
#	::DESTROY-A
#
#	::delete
#	::isAutoCleanup			Java CADK 7-38
#	::isPublish			Java CADK 7-38
#	::isPublishReply-A		Java CADK 7-39
#	::publishInterval		Java CADK 7-41    ("setPublishInterval")
#	::publishReply			Java CADK 7-34/41 ("get/setPublishReply")
#	::name				Java CADK 7-34    ("getName")
#	::needsAck			Java CADK 7-39
#	::nextPublish			Java CADK 7-34	  ("get/(set)NextPublish")
#	::reply				Java CADK 7-35/41 ("getReplyName"/"setReply")
#	::setNextPublish		Java CADK 7-41
#	::subscriptionFilter		Java CADK 7-37/42 ("get/setSubscriptionFilter
#
#       ::err-A                      	ala Mysql::
#       ::errmsg-A                   	ala Mysql::
#	::error-A
#===============================================================================



Aw::EventType
new ( CLASS, event_type_name )
	char * CLASS
	char * event_type_name

	CODE:
		RETVAL = (xsAdapterEventType *)safemalloc ( sizeof(xsAdapterEventType) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter event" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;
		RETVAL->callback = 0x0;

		RETVAL->adapterET = awNewAdapterET ( event_type_name );

		RETVAL->adapterET->userDataDeleteFunction =& userDataDelete;

	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::EventType self

	CODE:
		AWXS_CLEARERROR

		OneAdapterET    = self;
		OneAdapterETRef = ST(0);
		awDeleteAdapterET ( self->adapterET );


awVector *
getInfoSets ( self )
	Aw::EventType self

	ALIAS:
		Aw::EventType::infoSets = 1

	CODE:
		AWXS_CLEARERROR

		RETVAL = self->adapterET->infoSets;

	OUTPUT:
	RETVAL



int
getMaxResults ( self )
	Aw::EventType self

	ALIAS:
		Aw::EventType::maxResults = 1

	CODE:
		AWXS_CLEARERROR

		RETVAL = self->adapterET->maxResults;

	OUTPUT:
	RETVAL



awaBool
isAutoCleanup ( self )
	Aw::EventType self

	CODE:
		AWXS_CLEARERROR

		RETVAL = self->adapterET->autoCleanup; 

	OUTPUT:
	RETVAL



awaBool
isPublish ( self, ... )
	Aw::EventType self

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			self->adapterET->isPublish = (unsigned char)SvUV( ST(1) );

		RETVAL = self->adapterET->isPublish; 

	OUTPUT:
	RETVAL



#
#  awNewAdapterET sets this variable, we don't touch it!
#
char *
getName ( self )
	Aw::EventType self

	ALIAS:
		Aw::EventType::name = 1

	CODE:
		AWXS_CLEARERROR

		RETVAL = self->adapterET->name; 

	OUTPUT:
	RETVAL



awaBool
needsAck ( self )
	Aw::EventType self

	CODE:
		AWXS_CLEARERROR

		RETVAL = self->adapterET->needsAck; 

	OUTPUT:
	RETVAL



awaBool
newSubscription ( self, client )
	Aw::EventType self
	Aw::Client client

	CODE:
		gErr = self->err = awNewSubscription ( client->client, self->adapterET->name, self->adapterET->subscriptionFilter );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

		{
#ifdef AWXS_WARNS
			if ( RETVAL && self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
		}

	OUTPUT:
	RETVAL



int
getPublishInterval ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::publishInterval = 1

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			/* self->adapterET->publishInterval = (int)SvIV( ST(1) ); */
			awAdapterETSetPublishInterval ( self->adapterET, (int)SvIV( ST(1) ) );

		RETVAL = self->adapterET->publishInterval; 

	OUTPUT:
	RETVAL



void
setPublishInterval ( self, ... )
	Aw::EventType self

	PREINIT:
		int interval;

	CODE:
		interval
		= ( items > 1 )
		  ? (int)SvIV( ST(1) )
		  : 0
		;

		awAdapterETSetPublishInterval ( self->adapterET, interval );



awaBool
isPublishReply ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::publishReply  = 1

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			self->adapterET->publishReply = (awaBool)SvIV( ST(1) );

		RETVAL = self->adapterET->publishReply; 

	OUTPUT:
	RETVAL



void
setPublishReply ( self, publishReply )
	Aw::EventType self
	awaBool publishReply

	CODE:
		self->adapterET->publishReply = publishReply;



char *
getReplyName ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::replyName = 1

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			awAdapterETSetReply ( self->adapterET, (char *)SvPV( ST(1), PL_na ) );

		RETVAL = self->adapterET->replyName; 

	OUTPUT:
	RETVAL



awaBool
hasReply ( self )
	Aw::EventType self

	CODE:
		if ( self->adapterET->replyName == NULL )
			RETVAL = awaFalse;

		if (! strcmp( self->adapterET->replyName, "Adapter::ack" ) )
			XSRETURN_UNDEF;
		else
			RETVAL = awaTrue;

	OUTPUT:
	RETVAL



void
setReply ( self, replyName )
	Aw::EventType self
	char * replyName


	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			awAdapterETSetReply ( self->adapterET, replyName );



char *
getErrorRequestTo ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::errorRequestTo = 1

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 ) {
			if ( self->adapterET->errorRequestsTo )
				Safefree ( self->adapterET->errorRequestsTo );

			self->adapterET->errorRequestsTo = strdup ( (char *)SvPV( ST(1), PL_na ) );
		}

		RETVAL = self->adapterET->errorRequestsTo;

	OUTPUT:
	RETVAL



void
setErrorRequestTo ( self, to )
	Aw::EventType self
	char * to

	CODE:
		AWXS_CLEARERROR

		self->adapterET->errorRequestsTo = strdup ( to );



time_t
getNextPublish ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::nextPublish = 1

	PREINIT:
		time_t t;

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 )
			self->adapterET->nextPublish = (time_t)SvNV( ST(1) );

		RETVAL = self->adapterET->nextPublish; 

	OUTPUT:
	RETVAL




void
setNextPublish ( self )
	Aw::EventType self

	CODE:
		AWXS_CLEARERROR
		awAdapterETSetNextPublish ( self->adapterET );



char *
getSubscriptionFilter ( self, ... )
	Aw::EventType self

	ALIAS:
		Aw::EventType::subscriptionFilter = 1

	CODE:
		AWXS_CLEARERROR

		if ( items > 1 ) {
			char * filter = (char *)SvPV( ST(1), PL_na );
			if ( self->adapterET->subscriptionFilter )
				Safefree ( self->adapterET->subscriptionFilter );
			self->adapterET->subscriptionFilter = strdup ( filter );
		}

		RETVAL = self->adapterET->subscriptionFilter; 

	OUTPUT:
	RETVAL



#
#  Here for those insisting on a voide return type
#
void
setSubscriptionFilter ( self, filter )
	Aw::EventType self
	char * filter


	CODE:
		AWXS_CLEARERROR

		if ( self->adapterET->subscriptionFilter )
			Safefree ( self->adapterET->subscriptionFilter );

		self->adapterET->subscriptionFilter = strdup ( filter );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Filter

#===============================================================================

#===============================================================================
#  Aw::Filter
#	::new
#	::DESTROY-A
#
#	::getEventTypeName		Java-I 15-152
#	::getFilterString-A		Java-I 15-153
#	::match				Java-I 15-153
#	::toString-A			Java-I 15-153
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::Filter
new ( CLASS, client, event_type_name, filter_string )
	char * CLASS
	Aw::Client client
	char * event_type_name
	char * filter_string

	CODE:
		RETVAL = (xsBrokerFilter *)safemalloc ( sizeof(xsBrokerFilter) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new filter" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = RETVAL->err = awNewBrokerFilter ( client->client, event_type_name, filter_string, &RETVAL->filter);

		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 1, "filter creation failed" );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		RETVAL->event_type_name = strdup ( event_type_name );
		RETVAL->filter_string = strdup ( filter_string );

	OUTPUT:
	RETVAL


char *
getEventTypeName ( self )
	Aw::Filter self

	ALIAS:
		Aw::Filter::getFilterString = 1

	CODE:
		AWXS_CLEARERROR

		RETVAL
		= (ix)
		  ? self->filter_string
		  : self->event_type_name
		;

	OUTPUT:
	RETVAL



awaBool
match ( self, event )
	Aw::Filter self
	Aw::Event event

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awMatchFilter ( self->filter, event->event, &bRV);

		if ( self->err != AW_NO_ERROR ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to instantiate new event %s", awErrorToCompleteString ( self->err ) );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Format

#===============================================================================

#===============================================================================
#  Aw::Format
#	::new
#	::DESTROY-A
#
#	::assemble			Java-I 15-156
#	::format			Java-I 15-157
#	::formatBindVariable		Java-I 15-157
#	::free				     C
#	::getTokenCount			Java-I 15-158
#	::preparse			Java-I 15-159
#	::setFormatMode			Java-I 15-160
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::Format
new ( CLASS, ... )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerFormat *)safemalloc ( sizeof(xsBrokerFormat) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new format" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		if ( items == 3 ) {
			char * format_string = (char *)SvPV(ST(2), PL_na);
			if ( RETVAL->format_string )
				Safefree ( RETVAL->format_string );

			RETVAL->format_string = strdup ( format_string );

			RETVAL->event =& AWXS_BROKEREVENT(1)->event;
		} else if ( items == 2 ) {
			if ( sv_isobject ( ST(1) ) && sv_derived_from ( ST(1), "Aw::Event" ) )
				RETVAL->event =& AWXS_BROKEREVENT(1)->event;
			else {
				char * format_string = (char *)SvPV(ST(1), PL_na);
				if ( RETVAL->format_string )
					Safefree ( RETVAL->format_string );

				RETVAL->format_string = strdup ( format_string );
			}
		}

	OUTPUT:
	RETVAL



char *
assemble ( self, ... )
	Aw::Format self

	CODE:
		AWXS_CLEARERROR

		if (items == 2)
			self->event =& AWXS_BROKEREVENT(1)->event;

		gErr = self->err = awEventFormatAssemble ( *self->event, self->tokens, &RETVAL);

		if ( self->err != AW_NO_ERROR ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to instantiate new event %s", awErrorToCompleteString ( self->err ) );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
format ( self, ... )
	Aw::Format self

	PREINIT:
		char * format_string;

	CODE:
		AWXS_CLEARERROR

		if ( items == 2 ) {
			self->event =& AWXS_BROKEREVENT(1)->event;

			format_string = (char *)SvPV(ST(2), PL_na);
			if ( self->format_string )
				Safefree ( self->format_string );

			self->format_string = strdup ( format_string );
		} else if ( items ) {
			if ( sv_isobject ( ST(1) ) && sv_derived_from ( ST(1), "Aw::Event" ) )
				self->event =& AWXS_BROKEREVENT(1)->event;
			else {
				format_string = (char *)SvPV(ST(1), PL_na);
				if ( self->format_string )
					Safefree ( self->format_string );

				self->format_string = strdup ( format_string );
			}
		}

		gErr = self->err = awEventToFormattedString ( *self->event, self->format_string, &RETVAL );

		AWXS_CHECKSETERROR

	OUTPUT:
	RETVAL



char *
formatBindVariable ( self, index, place_holder_name )
	Aw::Format self
	int index
	char * place_holder_name

	CODE:
		AWXS_CLEARERROR

		RETVAL = awEventFormatBindVariable ( self->tokens, index, &place_holder_name );

	OUTPUT:
	RETVAL
	place_holder_name



void
free ( self )
	Aw::Format self

	CODE:
		AWXS_CLEARERROR

		awEventFormatFree ( self->tokens );



int
getTokenCount ( self )
	Aw::Format self

	CODE:
		AWXS_CLEARERROR

		RETVAL = awEventFormatTokens ( self->tokens );

	OUTPUT:
	RETVAL



char *
preparse ( self, ... )
	Aw::Format self

	CODE:
		AWXS_CLEARERROR

		if ( items ) {
			char * format_string = (char *)SvPV(ST(1), PL_na);
			if ( self->format_string )
				Safefree ( self->format_string );

			self->format_string = strdup ( format_string );
		}
		self->tokens = awEventFormatPreparse ( self->format_string );

	OUTPUT:
	RETVAL



awaBool
setFormatMode ( self, format_option, mode )
	Aw::Format self
	char * format_option
	char * mode

	CODE:
		AWXS_CLEARERROR

		RETVAL = (awaBool) awSetFormatMode ( format_option, mode );

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::License

#===============================================================================

#===============================================================================
#  Aw::Log
#	::new
#	::DESTROY-A
#
#	::getExpiration
#	::getFlags
#	::getMajorVersion
#	::getMinorVersion
#	::getPlatform
#	::getProduct
#	::getSerialNumber
#	::verify				Java CADK 7-67
#===============================================================================



Aw::License
new ( CLASS, license_string )
	char * CLASS
	char * license_string

	CODE:
		RETVAL = (xsAdapterLicense *)safemalloc ( sizeof(xsAdapterLicense) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new license" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		RETVAL->license_string = strdup ( RETVAL->license_string );

	OUTPUT:
	RETVAL



time_t
getExpiration ( self )
	Aw::License self

	CODE:
		RETVAL = awGetLicenseExpiration ( self->license_string );

	OUTPUT:
	RETVAL



char **
getFlagsRef ( self )
	Aw::License self

	PREINIT:
		int count_charPtrPtr = 0;  /* we don't know License Flags length */

	CODE:
		RETVAL = awGetLicenseFlags ( self->license_string );

	OUTPUT:
	RETVAL



int
getPlatform ( self )
	Aw::License self

	ALIAS:
		Aw::Licence::getMajorVersion = 1
		Aw::Licence::getMinorVersion = 2
		Aw::Licence::getSerialNumber = 3

	CODE:
		RETVAL
		= (ix>=2)
		  ? (ix-2)
		    ? awGetLicenseSerialNumber ( self->license_string )
		    : awGetLicenseMinorVersion ( self->license_string )
		  : (ix)
		    ? awGetLicenseMajorVersion ( self->license_string )
		    : awGetLicensePlatform ( self->license_string )
		;

	OUTPUT:
	RETVAL



char *
getProduct ( self )
	Aw::License self

	CODE:
		RETVAL = awGetLicenseProduct ( self->license_string );

	OUTPUT:
	RETVAL



int
verify ( self, ... )
	Aw::License self

	PREINIT:
		char * product;
		int version_major;
		int version_minor;

	CODE:
		product
		= (items>1)
		  ? (char *)SvPV ( ST(1), PL_na )
		  : awGetLicenseProduct ( self->license_string )
		;

		version_major
		= (items>2)
		  ? (int)SvIV ( ST(2) )
		  : awGetLicenseMajorVersion ( self->license_string )
		;

		version_minor
		= (items==4)
		  ? (int)SvIV ( ST(3) )
		  : awGetLicenseMinorVersion ( self->license_string )
		;

		RETVAL = awValidateLicense ( self->license_string, product, version_major, version_minor );

	OUTPUT:
		RETVAL

	CLEANUP:
		if ( items == 1 )
			free ( product );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Log

#===============================================================================

#===============================================================================
#  Aw::Log
#	::new
#	::DESTROY-A
#
#	::alert				Java CADK 7-69
#	::beQuiet			Java CADK 7-68
#	::doPrintf			Java CADK 7-68
#	::getMessage			Java CADK 7-71
#	::getOptionList			Java CADK 7-72
#	::info-A			Java CADK 7-74
#	::init				Java CADK 7-74
#	::isDebug			Java CADK 7-74
#	::isDoPrintf			Java CADK 7-74
#	::isInfo			Java CADK 7-74
#	::isQuiet			Java CADK 7-75
#	::setDebug			Java CADK 7-79
#	::start-A			Java CADK 7-81
#	::startLogging			Java CADK 7-81
#	::warning-A			Java CADK 7-82
#===============================================================================



Aw::Log
new ( CLASS, ... )
	char * CLASS

	CODE:
		RETVAL = (xsAdapterLog *)safemalloc ( sizeof(xsAdapterLog) );	

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter log" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		RETVAL->maxMessageSize = 2048;

		if ( items == 2 )
			/*  for now work only with a property object and not an
			 *  array or array ref of properties
			 */
   			if ( SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV) )
				awAdapterInitLogging ( awxsHashToProperties ( (HV*)SvRV( ST(1) ) ) );
			else
				warn ( "Arg 2 is not a hash reference.");

	OUTPUT:
	RETVAL



# void
# alert ( self, category, msgNumber, ... )
# 	Aw::Log self
# 	int category
# 	int msgNumber
# 
# 	ALIAS: 
# 		Aw::Log::info    = 1
# 		Aw::Log::warning = 2
# 
# 	PREINIT:
# 	AWPublic extern void (*(ixFuncs[3]))() = { awAdapterAlert, awAdapterInfo, awAdapterWarning };
# 	// void (*(ixFuncs[3]))() = { awAdapterAlert, awAdapterInfo, awAdapterWarning };
# 
# 	CODE:
# 		switch ( items )
# 		{
# 		  case 4:
# 			// (*ixFuncs)[ix] ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ) );
# 			(*ixFuncs)[ix] ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ) );
# 			break;
# 
# 		  case 5:
# 			(*ixFuncs)[ix] ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ) );
# 			break;
# 
# 		  case 6:
# 			(*ixFuncs)[ix] ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ), (char *)SvPV ( ST(5), PL_na ));
# 			break;
# 
# 		  default:
# 			break;
# 		}



void
alert ( self, category, msgNumber, ... )
	Aw::Log self
 	int category
 	int msgNumber
 
 
 	CODE:
 		switch ( items )
 		{
 		  case 4:
 			awAdapterAlert ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ) );
 			break;
 
 		  case 5:
 			awAdapterAlert ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ) );
 			break;
 
 		  case 6:
 			awAdapterAlert ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ), (char *)SvPV ( ST(5), PL_na ));
 			break;
 
 		  default:
 			break;
 		}



void
info ( self, category, msgNumber, ... )
	Aw::Log self
 	int category
 	int msgNumber
 
 
 	CODE:
 		switch ( items )
 		{
 		  case 4:
 			awAdapterInfo ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ) );
 			break;
 
 		  case 5:
 			awAdapterInfo ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ) );
 			break;
 
 		  case 6:
 			awAdapterInfo ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ), (char *)SvPV ( ST(5), PL_na ));
 			break;
 
 		  default:
 			break;
		}



void
warning ( self, category, msgNumber, ... )
	Aw::Log self
 	int category
 	int msgNumber
 
 
 	CODE:
 		switch ( items )
 		{
 		  case 4:
 			awAdapterWarning ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ) );
 			break;
 
 		  case 5:
 			awAdapterWarning ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ) );
 			break;
 
 		  case 6:
 			awAdapterWarning ( category, msgNumber, (char *)SvPV ( ST(3), PL_na ), (char *)SvPV ( ST(4), PL_na ), (char *)SvPV ( ST(5), PL_na ));
 			break;
 
 		  default:
 			break;
		}



int
beQuiet ( self, ... )
	Aw::Log  self

	CODE:
		if ( items == 2 ) {
			self->beQuiet = (int)SvIV( ST(1) );
			awAdapterSetQuiet ( self->beQuiet );
		}
		RETVAL = self->beQuiet = awAdapterBeQuiet ();

	OUTPUT:
	RETVAL



awaBool
doPrintf ( self, ... )
	Aw::Log  self

	CODE:
		if ( items == 2 )
			self->doPrintf = (awaBool)SvIV( ST(1) );

		RETVAL = self->doPrintf = awAdapterDoLogPrintf ();

	OUTPUT:
	RETVAL



char *
_getMessage ( self, msgId, strings )
	Aw::Log  self
	int msgId
	char ** strings

	PREINIT:
		/* va_list ap; */
		int n;

	CODE:
		n = av_len ( (AV*)SvRV( ST(2) ) ) + 1;

		RETVAL = (char *)safemalloc ( ( self->maxMessageSize ) * sizeof(char) );
		memset ( RETVAL, 0, (self->maxMessageSize) );

		/* Don't think we're getting this back out of the CV type...
		 * va_start ( ap, ST(1) );
		 * AwAdapterGetMessages_va ( RETVAL, maxMessageSize, msgId, ap );
		 * va_end (ap);
		 */
		
		/* look for a C equivalent for "eval" */
		switch (n)
		  {
			case  1:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0] );
				break;

			case  2:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1] );
				break;

			case  3:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2] );
				break;

			case  4:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3] );
				break;

			case  5:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4] );
				break;

			case  6:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5] );
				break;

			case  7:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5], strings[6] );
				break;

			case  8:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5], strings[6], strings[7] );
				break;

			case  9:
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5], strings[6], strings[7], strings[8] );
				break;

			default:  /* except for 0 */
			case 10:  /* 10 is the limit of the C API */
				awAdapterGetMessage ( RETVAL, self->maxMessageSize, msgId, strings[0], strings[1], strings[2], strings[3], strings[4], strings[5], strings[6], strings[7], strings[8], strings[9] );
				break;
		  }

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( strings );



char *
getOptionList ( self )
	Aw::Log  self

	CODE:
		RETVAL = awAdapterLoggingOptionList ();

	OUTPUT:
	RETVAL



void
init ( self, properties )
	Aw::Log  self
	HV * properties

	CODE:
		awAdapterInitLogging ( awxsHashToProperties (properties) );



awaBool
isDebug ( self )
	Aw::Log self

	CODE:
		RETVAL = awAdapterDoDebug ();

	OUTPUT:
	RETVAL



awaBool
isDoPrintf ( self )
	Aw::Log self

	CODE:
		RETVAL = self->doPrintf = awAdapterDoLogPrintf ();

	OUTPUT:
	RETVAL



awaBool
isInfo ( self )
	Aw::Log self

	CODE:
		RETVAL = awAdapterIsInfo ();

	OUTPUT:
	RETVAL



awaBool
isQuiet ( self )
	Aw::Log self

	CODE:
		RETVAL = self->beQuiet = awAdapterBeQuiet ();

	OUTPUT:
	RETVAL



short
maxMessageSize ( self, ... )
	Aw::Log self

 	ALIAS: 
 		Aw::Log::getMessageSize = 1
 		Aw::Log::setMessageSize = 2

	CODE:

		if ( items )
			self->maxMessageSize = (short)SvIV(ST(1));

		RETVAL = self->maxMessageSize;

	OUTPUT:
	RETVAL



void
setDebug ( self, debug )
	Aw::Log self
	int debug

	CODE:
		awAdapterSetDebug ( debug );



#
#  Note in the Java API (CADK 7-80/81) the awAdapterPropteries is an optional
#  arguement
#
void
startLogging ( self, progName, ... )
	Aw::Log self
	char * progName

	ALIAS:
		Aw::Log::start = 1

	CODE:
		if ( items == 3 ) {
#if ( AW_VERSION_31 || AW_VERSION_40 )
			warn ( "'startLogging' does not support property setting in AW v3.1+.");
#else
   			if( SvROK(ST(2)) && (SvTYPE(SvRV(ST(2))) == SVt_PVHV) )
				awAdapterSetLoggingProperties ( awxsHashToProperties ( (HV*)SvRV( ST(2) ) ) );
			else
				warn ( "Arg 3 is not a hash reference.");
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */
		}

		awAdapterStartLogging ( progName );



int
parseOptions ( self, progName, argv )
	Aw::Log self
	char * progName
	char ** argv

	CODE:
#if ( AW_VERSION_31 || AW_VERSION_40 )
		warn ( "'parseOptions' is not supported in AW v3.1+.");
#else
		{
 		int size = av_len ( (AV*)SvRV( ST(2) ) ) + 1;
 		RETVAL = awAdapterParseLoggingOption ( progName, &size, &argv );
		}
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( argv );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::TypeDef

#===============================================================================

#===============================================================================
#  Aw::TypeDef
#	::new
#	::DESTROY-A
#
#	::getBaseTypeName-A		Java-I 15-167
#	::getBrokerHost			Java-I 15-167
#	::getBrokerName-A		Java-I 15-167
#	::getBrokerPort			Java-I 15-168
#	::getDescription-A		Java-I 15-168
#	::getFamilyNames		   C
#	::getFieldDef			Java-I 15-169
#	::getFieldNames-A		Java-I 15-169
#	::getFieldType			Java-I 15-170
#	::getScopeTypeName-A		Java-I 15-170
#	::getStorageType-A		Java-I 15-171
#	::getTerritoryName-A		Java-I 15-171
#	::getTimeToLive			Java-I 15-171
#	::getTypeName-A			Java-I 15-171
#	::toString-A
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::TypeDef
new ( CLASS, agent )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new type def" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		// this doesn't make sense, items is always 2, do a strcmp from the object name

		if ( items == 2 ) {
			xsBrokerEvent * event = AWXS_BROKEREVENT(1);
			gErr = RETVAL->err = awGetTypeDefFromEvent ( event->event, &RETVAL->type_def );
		} else {
			xsBrokerClient * client = AWXS_BROKERCLIENT(1);
			char * event_type_name  = (char *)SvPV( ST(2), PL_na );

			gErr = RETVAL->err = awGetEventTypeDef ( client->client, event_type_name, &RETVAL->type_def );
		}
		if ( RETVAL->err != AW_NO_ERROR ) {
			Safefree ( RETVAL );
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
getBrokerHost ( self )
	Aw::TypeDef self

	ALIAS:
		Aw::TypeDef::getBrokerName     = 1
		Aw::TypeDef::getDescription    = 2
		Aw::TypeDef::getTerritoryName  = 3

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix>=2)
		  ? (ix-2)
		    ? awGetTypeDefTerritoryName ( self->type_def, &RETVAL )
		    : awGetTypeDefDescription ( self->type_def, &RETVAL )
		  : (ix)
		    ? awGetTypeDefBrokerName ( self->type_def, &RETVAL )
		    : awGetTypeDefBrokerHost ( self->type_def,  &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
getBrokerPort ( self )
	Aw::TypeDef self

	ALIAS:
		Aw::TypeDef::getStorageType = 1
		Aw::TypeDef::getTimeToLive  = 2

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		     = ( ix )
		       ? (ix-1)
		         ? awGetTypeDefTimeToLive ( self->type_def, &RETVAL )
		         : awGetTypeDefStorageType ( self->type_def, &RETVAL )
		       : awGetTypeDefBrokerPort ( self->type_def, &RETVAL )
		     ;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



Aw::TypeDef
getFieldDef ( self, field_name )
	Aw::TypeDef self
	char * field_name

	PREINIT:
		char CLASS[] = "Aw::TypeDef";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
		if ( RETVAL == NULL ) {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new type def" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gErr = self->err = awGetTypeDefFieldDef ( self->type_def, field_name, &RETVAL->type_def );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



short
getFieldType ( self, field_name )

	CASE:	ix == 1
		ALIAS:
			Aw::Event::getFieldType = 1

		INPUT:
			Aw::Event self;
			char * field_name;

		CODE:
			AWXS_CLEARERROR

			gErr = self->err = awGetEventFieldType ( self->event, field_name, &RETVAL );

			AWXS_CHECKSETERROR_RETURN

		OUTPUT:
		RETVAL

	CASE:
		INPUT:
			Aw::TypeDef self;
			char * field_name;

		CODE:
			AWXS_CLEARERROR

			gErr = self->err = awGetTypeDefFieldType ( self->type_def, field_name, &RETVAL );
			AWXS_CHECKSETERROR_RETURN

		OUTPUT:
		RETVAL



char *
getTypeName ( self )
	Aw::TypeDef self

	ALIAS:
		Aw::TypeDef::getBaseTypeName  = 1
		Aw::TypeDef::getScopeTypeName = 2
		Aw::TypeDef::getFamilyName    = 3

	CODE:
		AWXS_CLEARERROR

		RETVAL
		= (ix>=2)
		  ? (ix-2)
#ifdef AW_COMPATIBLE
		    ? awGetTypeDefFamilyName ( self->type_def )
#else
		    ? NULL	
#endif /* AW_COMPATIBLE */
		    : awGetTypeDefScopeName ( self->type_def )
		  : (ix)
		    ? awGetTypeDefBaseName ( self->type_def )
		    : awGetTypeDefTypeName ( self->type_def )
		;


		if ( ix == 3 )
#ifndef AW_COMPATIBLE
			{	
			self->errMsg = setErrMsg ( &gErrMsg, 1, "getFamilyName not available: AW_COMPATIBLE was set to false at compile time." );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			}	
#else
		ix = ix;  /* this is really stupid but the #ifndef can't go
					 above the if ( ix == 3 ) line.  Try again later. */
#endif /* AW_COMPATIBLE */

		if ( RETVAL == NULL )
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



HV *
toHashRef ( self )
	Aw::TypeDef self

	PREINIT:
		char * string = NULL;
		int number;

	CODE:
		AWXS_CLEARERROR

		RETVAL = newHV();

		gErr = self->err = awxsSetHashFromTypeDef ( self->type_def, RETVAL );

		AWXS_CHECKSETERROR_RETURN

		hv_store ( RETVAL, "_name", 5, newSVpv ( awGetTypeDefTypeName(self->type_def), 0), 0 );

	        gErr = self->err = awGetTypeDefTimeToLive ( self->type_def, &number );
		AWXS_CHECKSETERROR
		if ( self->err == AW_NO_ERROR )
			hv_store ( RETVAL, "_timeToLive", 11, newSViv ( number ), 0 );

	        gErr = self->err = awGetTypeDefStorageType ( self->type_def, &number );
		AWXS_CHECKSETERROR
		if ( self->err == AW_NO_ERROR )
			hv_store ( RETVAL, "_storageType", 12, newSViv ( number ), 0 );

	        gErr = self->err = awGetTypeDefDescription ( self->type_def, &string );
		AWXS_CHECKSETERROR
		if ( self->err == AW_NO_ERROR && string != NULL && string[0] != '\0' )
			hv_store ( RETVAL, "_description", 12, newSVpv ( string, 0), 0 );


	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::TypeDefCache

#===============================================================================

#===============================================================================
#  Aw::TypeDefCache
#	::new
#	::DESTROY-A
#
#	::flushCache			Java-I 15-165
#	::lockCache			Java-I 15-165
#	::unlockCache			Java-I 15-165
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#       ::error-A
#===============================================================================



Aw::TypeDefCache
new ( CLASS, ... )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerTypeDefCache *)safemalloc ( sizeof(xsBrokerTypeDefCache) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new type def cache" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->client = NULL;


		if ( items == 2 ) /* we should test to make sure ST(1) is really a client... */
			RETVAL->client =& AWXS_BROKERCLIENT(1)->client;

	OUTPUT:
	RETVAL



awaBool
flushCache ( self, ... )
	Aw::TypeDefCache self

	CODE:
		AWXS_CLEARERROR

		if ( items == 2 ) /* we should test to make sure ST(1) is really a client... */
			self->client =& AWXS_BROKERCLIENT(1)->client;

		if ( self->client )
			gErr = self->err = awFlushTypeDefCache ( *self->client );
		else {
			self->errMsg = setErrMsg ( &gErrMsg, 1, "(cache)->client is NULL" );
#ifdef AWXS_WARNS
			if ( self->Warn )
				warn ( self->errMsg );
#endif /* AWXS_WARNS */
			gErr = self->err = AW_NO_ERROR;
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



void
lockCache ( self )
	Aw::TypeDefCache self

	CODE:
		AWXS_CLEARERROR

		awLockTypeDefCache ();



void
unlockCache ( self )
	Aw::TypeDefCache self

	CODE:
		AWXS_CLEARERROR

		awUnlockTypeDefCache ();



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Replies

#===============================================================================

#===============================================================================
#  Aw::Replies
#	::new
#	::DESTROY-A
#
#	::add/::addReplyEvent		Java CADK 7-90
#	::cancel			C CADK 7-67
#	::finish/::finishReplies	Java CADK 7-90
#	::start				C CADK
#===============================================================================



Aw::Replies
new ( CLASS, adapter )
	char * CLASS
	Aw::Adapter adapter

	CODE:
		RETVAL = (xsAdapterReplies *)safemalloc ( sizeof(xsAdapterReplies) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new replies" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		RETVAL->handle = adapter->handle;

		// ??  read adapter_helper.h
		//     also destroy maybe should call finish
		// awAdapterReplyEventsStart ( self->handle, batchSize );

	OUTPUT:
	RETVAL



awaBool
addReplyEvent ( self, replyEvent )
	Aw::Replies self
	Aw::Event replyEvent

	ALIAS:
		Aw::Replies::add = 1

	CODE:
		RETVAL = self->eventsAddOk = awAdapterReplyEventsAdd ( self->handle, replyEvent->event );

	OUTPUT:
	RETVAL



void
cancel ( self )
	Aw::Replies self

	CODE:
		awAdapterReplyEventsCancel ( self->handle );



awaBool
finishReplies ( self )
	Aw::Replies self

	ALIAS:
		Aw::Replies::finish = 1

	CODE:
		RETVAL = self->finishOk = awAdapterReplyEventsFinish ( self->handle );

	OUTPUT:
	RETVAL



void
start ( self, batchSize )
	Aw::Replies self
	int batchSize

	CODE:
		awAdapterReplyEventsStart ( self->handle, batchSize );



#===============================================================================

MODULE = Aw			PACKAGE = Aw::SSLCertificate

#===============================================================================

#===============================================================================
#  Aw::SSLCertificate
#	::new
#	::DESTROY-A
#
#	::getBeginDate
#	::getDistinguishedName
#	::getEndDate-A
#	::getIssuerDistinguishedName-A
#	::getStatus
#	::toString-A			   C ??
#===============================================================================



Aw::SSLCertificate
new ( CLASS, certificate_file, password, distinguished_name )
	char * CLASS
	char * certificate_file
	char * password
	char * distinguished_name

	CODE:
		awGetSSLCertificate ( certificate_file, password, distinguished_name, &RETVAL );

	OUTPUT:
	RETVAL



Aw::Date
getBeginDate ( self )
	Aw::SSLCertificate self

	ALIAS:
		Aw::SSLCertificate::getEndDate = 1
		Aw::SSLCertificate::end_date   = 2
		Aw::SSLCertificate::begin_date = 3

	PREINIT:
		char CLASS[] = "Aw::Date";

	CODE:
		RETVAL = (BrokerDate *)safemalloc ( sizeof(BrokerDate) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new date" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		
		if (ix%2) {
			memcpy ( RETVAL, &self->end_date, sizeof (BrokerDate) );
		} else {
			memcpy ( RETVAL, &self->begin_date, sizeof (BrokerDate) );
		}

	OUTPUT:
	RETVAL



char *
getDistinguishedName ( self )
	Aw::SSLCertificate self

	ALIAS:
		Aw::SSLCertificate::distinguished_name         = 1
		Aw::SSLCertificate::getIssuerDistinguishedName = 2
		Aw::SSLCertificate::getStatus                  = 3
		Aw::SSLCertificate::issuer_distinguished_name  = 4
		Aw::SSLCertificate::status                     = 5

	CODE:
		RETVAL
		= (ix>1)
		  ? (ix%2)
		    ? self->status
		    : self->issuer_distinguished_name
		  : self->distinguished_name;
		;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Subscription

#===============================================================================

#===============================================================================
#  Aw::Subscription
#	::new
#	::DESTROY-A
#
#	::getEventTypeName
#	::getFilter
#	::getSubId
#===============================================================================



Aw::Subscription
new ( CLASS, ... )
	char * CLASS

	CODE:
		RETVAL = (BrokerSubscription *)safemalloc ( sizeof(BrokerSubscription) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new filter" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		if ( items > 1 ) {
			char * event_type_name = NULL;
			char * filter          = NULL;
			int    offset          = 0;

			if ( items == 3 )
				++offset;

			RETVAL->sub_id
			= ( offset )
			  ? (int)SvIV (ST(1)) 
			  : 0
			;

			event_type_name  = (char *)SvPV( ST(1 + offset), PL_na );
			filter           = (char *)SvPV( ST(2 + offset), PL_na );

		
			RETVAL->event_type_name = strdup ( event_type_name );
			RETVAL->filter = strdup ( filter );
		}

	OUTPUT:
	RETVAL



char *
getEventTypeName ( self )
	Aw::Subscription self

	ALIAS:
		Aw::Subscription::getFilter       = 1
		Aw::Subscription::filter          = 3
		Aw::Subscription::event_type_name = 2

	CODE:
		if ( ix%2 ) {
#ifdef AW_UNICODE
			RETVAL = awUCtoUTF8 ( self->filter );
#else
			RETVAL = self->filter;
#endif /* AW_UNICODE */
		} else {
#ifdef AW_UNICODE
			RETVAL = awUCtoUTF8 ( self->event_type_name );
#else
			RETVAL = self->event_type_name;
#endif /* AW_UNICODE */
		}

	OUTPUT:
	RETVAL



int
getSubId ( self )
	Aw::Subscription self

	ALIAS:
		Aw::Subscription::sub_id = 1 

	CODE:
		RETVAL = self->sub_id;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw			PACKAGE = Aw::Util

#===============================================================================

#===============================================================================
#  Aw::Util
#	::new
#	::DESTROY-A
#
#	::clearEventField    		Java CADK 7-91
#	::createEvent    		Java CADK 7-91
#	::createTypedEvent    		   C CADK 6-26
#	::deliverAckReplyEvent		Java CADK 7-92
#	::deliverNullReplyEvent		Java CADK 7-92
#	::deliverPartialReplyEvent	Java CADK 7-92
#	::deliverReplyEvent 		Java CADK 7-93
#	::deliverReplyEvents 		Java CADK 7-93 XX
#	::getBooleanField		Java CADK 7-94 XX
#	::getEventTypeDef		Java CADK 7-94
#	::getIntegerField		Java CADK 7-95 XX
#	::getIntegerSeqField		Java CADK 7-95 XX
#	::getStringField-A		Java CADK 7-96
#	::getStringSeqField		Java CADK 7-97 XX
#	::getStructSeqFieldAsEvents	Java CADK 7-98 XX
#	::initHandle		   	   C CADK 6-41
#	::isEventFieldSet		Java CADK 7-98
#	::newSubscription-A		Java CADK 7-99
#	::publish-A			Java CADK 7-99/7-100
#	::setEventField			Java CADK 7-100
#	::setStringField		Java CADK 7-101
#	::setupEventVerify		Java CADK 7-101 XX
#	::toFormattedString		Java CADK 7-102
#
#       ::err-A   			ala Mysql::
#       ::errmsg-A			ala Mysql::
#	::error-A
#===============================================================================



Aw::Util
new ( CLASS, adapter, ... )
	char  * CLASS
	Aw::Adapter adapter;

	CODE:
		RETVAL = (xsAdapterUtil *)safemalloc ( sizeof(xsAdapterUtil) );

		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter util" );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		printf ("Items = %i\n", items);

		RETVAL->adapter = adapter->adapter;
		/*
		 * Some AdapterUtil routines assume a call back handle, others
		 * need a purely new and temporary general purpose handle
		 * (as in the InitHandle -> NewSubscription sequence.
		 *
		 * Those that can _only_ work with a call back handle should
		 * be methods of Adapter and elliminated from AdapterUtil.
		 * Determine which routines these are and remove them later.
		 *
		 *
		 *
		 * RETVAL->handle  = adapter->handle;
		 */

		if ( items > 2 ) {
			/*  
			 *  we are doing init at the same time
			 */ 
			xsBrokerEvent * requestEvent;
			xsAdapterEventType * requestDef;

		
			requestEvent = ( ST(2) )
					? AWXS_BROKEREVENT(2)
					: 0
					;
			requestDef = ( ST(3) )
					? AWXS_ADAPTEREVENTTYPE(3)
					: 0
					;

			RETVAL->handle = (awAdapterHandle *)safemalloc ( sizeof(awAdapterHandle) );
			if ( RETVAL->handle == NULL ) {
				Safefree (RETVAL);
				setErrMsg ( &gErrMsg, 1, "unable to malloc new adapter util" );
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( gErrMsg );
#endif /* AWXS_WARNS */
				XSRETURN_UNDEF;
			}

			awAdapterInitHandle ( RETVAL->handle, RETVAL->adapter, requestEvent->event, requestDef->adapterET );
		}

	OUTPUT:
	RETVAL



Aw::Event
createEvent ( self, ... )

	ALIAS:
		Aw::Adapter::createEvent      = 1
		Aw::Util::createTypedEvent    = 2
		Aw::Adapter::createTypedEvent = 3
		Aw::Adapter::requestEvent     = 4

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:
		AWXS_HANDLE_CLEARERROR(2)
		
		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			if (ix && ix != 2)
				AWXS_ADAPTER(0)->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
			else
				AWXS_ADAPTERUTIL(0)->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if (ix && ix != 2) {
				if ( AWXS_ADAPTER(0)->Warn )
					warn ( AWXS_ADAPTER(0)->errMsg );
			} else {
				if ( AWXS_ADAPTERUTIL(0)->Warn )
					warn ( AWXS_ADAPTERUTIL(0)->errMsg );
			}
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gHandle
		= (ix && ix != 2)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;


		RETVAL->event
		= (ix<4)
		  ? (ix<2)
		    ? awAdapterCreateEvent ( gHandle, (char *)SvPV( ST(1), PL_na) )
		    : awAdapterCreateTypedEvent ( gHandle, (char *)SvPV( ST(1), PL_na) )
		  : gHandle->requestEvent
		;


		if ( gHandle == NULL || RETVAL->event == NULL ) {
			Safefree ( RETVAL );
			if (ix && ix != 2)
				AWXS_ADAPTER(0)->errMsg = setErrMsg ( &gErrMsg, 1, "requestEvent: Null Handle" );
			else
				AWXS_ADAPTERUTIL(0)->errMsg = setErrMsg ( &gErrMsg, 1, "requestEvent: Null Handle" );
#ifdef AWXS_WARNS
			if (ix && ix != 2) {
				if ( AWXS_ADAPTER(0)->Warn )
					warn ( AWXS_ADAPTER(0)->errMsg );
			} else {
				if ( AWXS_ADAPTERUTIL(0)->Warn )
					warn ( AWXS_ADAPTERUTIL(0)->errMsg );
			}
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}


		if ( items == 3 )
		  {
			HV * hv;

    			if( SvROK(ST(2)) && (SvTYPE(SvRV(ST(2))) == SVt_PVHV) )
			        hv = (HV*)SvRV( ST(2) );
			    else {
			        warn( "Aw::Event::new() -- hv is not an HV reference" );
			        XSRETURN_UNDEF;
			    };

			gErr = RETVAL->err = awxsSetEventFromHash ( RETVAL->event, hv );

			if ( RETVAL->err != AW_NO_ERROR ) {
				setErrMsg ( &gErrMsg, 2, "unable to instantiate new event: %s", awErrorToCompleteString ( RETVAL->err ) );
				Safefree ( RETVAL );
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( gErrMsg );
#endif /* AWXS_WARNS */
				XSRETURN_UNDEF;
			}

		  }


		RETVAL->deleteOk = (ix==2) ? 0 : 1;

	OUTPUT:
	RETVAL



awaBool
deliverAckReplyEvent ( self )

	ALIAS:
		Aw::Adapter::deliverAckReplyEvent  = 1
		Aw::Util::deliverNullReplyEvent    = 2
		Aw::Adapter::deliverNullReplyEvent = 3

	CODE:
		AWXS_HANDLE_CLEARERROR(2)
		
		gHandle
		= (ix%2)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL
		= (ix<2)
		  ? awAdapterDeliverAckReplyEvent  ( gHandle )
		  : awAdapterDeliverNullReplyEvent ( gHandle )
		;

	OUTPUT:
	RETVAL



awaBool
deliverPartialReplyEvent ( self, replyEvent, record, isLast, replyToken )
	Aw::Event replyEvent
	int record
	awaBool isLast
	int replyToken

	ALIAS:
		Aw::Adapter::deliverPartialReplyEvent = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterDeliverPartialReplyEvent ( gHandle, replyEvent->event, record, isLast, &replyToken );

	OUTPUT:
	RETVAL



#
#  Yet another style for working with multiple classes:
#    Unwrap class within if { }s
# 
awaBool
deliverReplyEvent ( self, event )
	Aw::Event event

	ALIAS:
		Aw::Adapter::deliverReplyEvent = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterDeliverReplyEvent ( gHandle, event->event );

	OUTPUT:
	RETVAL



awaBool
dispatchToSession ( self )

	ALIAS:
		Aw::Adapter::dispatchToSession = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
#if ( AW_VERSION_31 || AW_VERSION_40 )

		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterDispatchToSession ( gHandle );
#else
		warn ( "'dispatchToSessions' available in AW v3.1+.  Recompile Aw.xs if you have reached this warning in error.");
		XSRETURN_UNDEF;
#endif /* ( AW_VERSION_31 || AW_VERSION_40 ) */

	OUTPUT:
	RETVAL



####################################################################
#
#  Yet another style for working with multiple classes:
#    Using cases, class definition is specified in INPUT
# 
#  This is my preferred method when not many self->references are required.
#
####################################################################
Aw::TypeDef
getEventTypeDef ( self, event_name )
	char * event_name

	ALIAS:
		Aw::Adapter::getEventTypeDef = 1

	PREINIT:
		char CLASS[] = "Aw::EventType";
		awaBool test;

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		RETVAL = (xsBrokerTypeDef *)safemalloc ( sizeof(xsBrokerTypeDef) );
		if ( RETVAL == NULL ) {
			if (ix)
				AWXS_ADAPTER(0)->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
			else
				AWXS_ADAPTERUTIL(0)->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
			if (ix) {
				if ( AWXS_ADAPTER(0)->Warn )
					warn ( AWXS_ADAPTER(0)->errMsg );
			} else {
				if ( AWXS_ADAPTERUTIL(0)->Warn )
					warn ( AWXS_ADAPTERUTIL(0)->errMsg );
			}
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = AW_NO_ERROR;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		test = awAdapterGetEventTypeDef ( gHandle, event_name, &RETVAL->type_def );
		
		if ( test == awaFalse ) {
			setErrMsg ( &gErrMsg, 1, "::getEventTypeDef:  awAdapterGetEventTypeDef failed, reason unknown" );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}	

	OUTPUT:
	RETVAL



awaBool
getBooleanInfo ( self, field_name, ... )
	char * field_name

	ALIAS:
		Aw::Adapter::getBooleanInfo   = 1
		Aw::EventType::getBooleanInfo = 2

	PREINIT:
		awaBool test;

	CODE:
		if (ix < 2) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}
		
		test
		= (ix)
		  ? awAdapterETInfoGetBooleanReq ( gHandle, field_name, &RETVAL )
		  : awAdapterETInfoGetBoolean ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &RETVAL )
		;

		if ( test == awaFalse ) {
			if ( items == 3 )
				RETVAL = (awaBool)SvIV ( ST(2) );
			else
				XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



int
getIntegerInfo ( self, field_name, ... )
	char * field_name

	ALIAS:
		Aw::Adapter::getIntegerInfo   = 1
		Aw::EventType::getIntegerInfo = 2

	PREINIT:
		awaBool test;

	CODE:
		if (ix < 2) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}

		test
		= (ix < 2)
		  ? awAdapterETInfoGetIntegerReq ( gHandle, field_name, &RETVAL )
		  : awAdapterETInfoGetInteger ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &RETVAL )
		;

		if ( test == awaFalse ) {
			if ( items == 3 )
				RETVAL = (int)SvIV ( ST(2) );
			else
				XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char *
getStringInfo ( self, field_name, ... )
	char * field_name

	ALIAS:
		Aw::Adapter::getStringInfo           = 1
		Aw::Util::getUCStringInfoAsA         = 2
		Aw::Adapter::getUCStringInfoAsA      = 3
		Aw::Util::getUCStringInfoAsUTF8      = 4
		Aw::Adapter::getUCStringInfoAsUTF8   = 5

		Aw::EventType::getStringInfo         = 6
		Aw::EventType::getUCStringInfoAsA    = 7
		Aw::EventType::getUCStringInfoAsUTF8 = 8

	PREINIT:
		awaBool test;

	CODE:
		if (ix < 6) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}
		
		test
		= (ix > 6)
		  ? (ix==8)
		    ? awAdapterETInfoGetUCStringAsUTF8A ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &RETVAL )
		    : (ix-6)
		      ? awAdapterETInfoGetUCStringAsA ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &RETVAL )
		      : awAdapterETInfoGetString ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &RETVAL )


		  : (ix > 1)
		    ? (ix > 3)
		      ? awAdapterETInfoGetUCStringAsUTF8Req ( gHandle, field_name, &RETVAL )
		      : awAdapterETInfoGetUCStringAsAReq ( gHandle, field_name, &RETVAL )

		    : awAdapterETInfoGetStringReq ( gHandle, field_name, &RETVAL )
		;

		if ( test == awaFalse ) {
			if ( items == 3 )
				RETVAL = (char *)SvPV ( ST(2), PL_na );
			else
				XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



char **
getStringSeqInfoRef ( self, field_name )
	char * field_name

	ALIAS:
		Aw::Adapter::getStringSeqInfoRef           = 1
		Aw::Util::getUCStringSeqInfoAsARef         = 2
		Aw::Adapter::getUCStringSeqInfoAsARef      = 3
		Aw::Util::getUCStringSeqInfoAsUTF8Ref      = 4
		Aw::Adapter::getUCStringSeqInfoAsUTF8Ref   = 5

		Aw::EventType::getStringSeqInfoRef         = 6
		Aw::EventType::getUCStringSeqInfoAsARef    = 7
		Aw::EventType::getUCStringSeqInfoAsUTF8Ref = 8

	PREINIT:
		awaBool test;
		int count_charPtrPtr;

	CODE:
		if (ix < 6) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}
		
		test
		= (ix > 6)
		  ? (ix==8)
		    ? awAdapterETInfoGetUCStringSeqAsUTF8 ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &count_charPtrPtr, &RETVAL )
		    : (ix-6)
		      ? awAdapterETInfoGetUCStringSeqAsA ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &count_charPtrPtr, &RETVAL )
		      : awAdapterETInfoGetStringSeq ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &count_charPtrPtr, &RETVAL )


		  : (ix > 1)
		    ? (ix > 3)
		      ? awAdapterETInfoGetUCStringSeqAsUTF8Req ( gHandle, field_name, &count_charPtrPtr, &RETVAL )
		      : awAdapterETInfoGetUCStringSeqAsAReq ( gHandle, field_name, &count_charPtrPtr, &RETVAL )

		    : awAdapterETInfoGetStringSeqReq ( gHandle, field_name, &count_charPtrPtr, &RETVAL )
		;

		if ( test == awaFalse )
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



Aw::Event
findFieldInfo ( self, field_name )
	char * field_name

	ALIAS:
		Aw::Adapter::findFieldInfo   = 1
		Aw::EventType::findFieldInfo = 2

	PREINIT:
		char CLASS[] = "Aw::Event";

	CODE:

		if (ix < 2) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}

		RETVAL = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );	
		if ( RETVAL == NULL ) {
			// self->errMsg = setErrMsg ( &gErrMsg, 1, "Aw::Adapter::getAdapterInfo:  unable to malloc new event" );
			setErrMsg ( &gErrMsg, 1, "Aw::Adapter::getAdapterInfo:  unable to malloc new event" );
#ifdef AWXS_WARNS
			// if ( self->Warn )
			// 	warn ( self->errMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}
		/* initialize the error cleanly */
		RETVAL->err    = NULL;
		RETVAL->errMsg = NULL;
		RETVAL->Warn   = gWarn;

		RETVAL->event
		= (ix < 2)
		  ? awAdapterETInfoFindFieldReq ( gHandle, field_name )
		  : awAdapterETInfoFindField ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name )
		;
		if ( !RETVAL->event ) 
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



AV *
getStructSeqInfoRef ( self, field_name )
	char * field_name

	ALIAS:
		Aw::Adapter::getStructSeqInfoRef   = 1
		Aw::EventType::getStructSeqInfoRef = 2

	PREINIT:
		int n;
		awaBool test;
		BrokerEvent * events;

	CODE:
		if (ix < 2) {
			xsBrokerTypeDef * self = AWXS_BROKERTYPEDEF(0);
			AWXS_CLEARERROR
		}
		else {
			AWXS_HANDLE_CLEARERROR(0)
			gHandle
			= (ix)
			  ? AWXS_ADAPTER(0)->handle
			  : AWXS_ADAPTERUTIL(0)->handle
			;
		}
		
		test
		= (ix < 2)
		  ? awAdapterETInfoGetStructSeqAsEventsReq ( gHandle, field_name, &n, &events )
		  : awAdapterETInfoGetStructSeqAsEvents ( AWXS_ADAPTEREVENTTYPE(0)->adapterET, field_name, &n, &events )
		;


		if ( test == awaFalse )
			XSRETURN_UNDEF;


		/* now convert reply_events into an AV */
		{
		SV *sv;
		int i;
		xsBrokerEvent * ev;

			RETVAL = newAV();
			for ( i = 0; i<n; i++ ) {
				ev = (xsBrokerEvent *)safemalloc ( sizeof(xsBrokerEvent) );
				if ( ev == NULL ) {
					// self->errMsg = setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
					setErrMsg ( &gErrMsg, 1, "unable to malloc new event" );
#ifdef AWXS_WARNS
					// if ( self->Warn )
						// warn ( self->errMsg );
#endif /* AWXS_WARNS */
					continue;
				}
				ev->err      = NULL;
				ev->errMsg   = NULL;
				ev->Warn     = gWarn;
				ev->deleteOk = 0;

				ev->event    = events[i];
				
				sv = sv_newmortal();
				sv_setref_pv( sv, "Aw::Event", (void*)ev );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}
		}

	OUTPUT:
		RETVAL
	
	CLEANUP:
		SvREFCNT_dec ( RETVAL );



void
initHandle ( self, adapter, event, adapterET )
	Aw::Util self
	Aw::Adapter adapter
	Aw::Event event
	Aw::EventType adapterET

	CODE:
		AWXS_CLEARERROR
		
		awAdapterInitHandle ( self->handle, adapter->adapter, event->event, adapterET->adapterET );



awaBool
publish ( self, event )
	Aw::Event event

	ALIAS:
		Aw::Adapter::publish = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
	  	  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterPublishEvent ( gHandle, event->event );

	OUTPUT:
	RETVAL



awaBool
setEventField (self, event, field_name, typeDef, value)
	Aw::Event event
	char * field_name
	Aw::TypeDef typeDef
	char * value

	ALIAS:
		Aw::Adapter::setEventField = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		RETVAL
		= (ix)
		  ? awAdapterSetEventField ( event->event, field_name, typeDef->type_def, value, &AWXS_ADAPTER(0)->err )
		  : awAdapterSetEventField ( event->event, field_name, typeDef->type_def, value, &AWXS_ADAPTERUTIL(0)->err )
		;

	OUTPUT:
	RETVAL



awaBool
setStringField ( self, event, field_name, value )
	Aw::Event event
	char * field_name
	char * value

	ALIAS:
		Aw::Adapter::setStringField = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterSetStringField ( gHandle, event->event, field_name, value );

	OUTPUT:
	RETVAL



awaBool
setFieldFromString ( self, event, field_name, typeDef, value )
	Aw::Event event
	char * field_name
	Aw::TypeDef typeDef
	char * value

	ALIAS:
		Aw::Adapter::setFieldFromString = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterSetFieldFromString ( gHandle, event->event, field_name, typeDef->type_def, value );

	OUTPUT:
	RETVAL



awaBool
setupEventVerify ( self, canSubscribe, canPublish, supportsNotification )
	awaBool	canSubscribe
	awaBool	canPublish
	awaBool supportsNotification

	ALIAS:
		Aw::Adapter::setupEventVerify = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		RETVAL = awAdapterSetupEventVerify ( gHandle, canSubscribe, canPublish, supportsNotification );

	OUTPUT:
	RETVAL



awaBool
isEventFieldSet ( self, event, field_name )
	char * field_name
	Aw::Event event

	ALIAS:
		Aw::Adapter::isEventFieldSet = 1

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		RETVAL = awAdapterIsEventFieldSet ( event->event, field_name );

	OUTPUT:
	RETVAL



char *
toFormattedString ( self, format )
	char * format

	ALIAS:
		Aw::Adapter::toFormattedString = 1

	PREINIT:
		awaBool test;

	CODE:
		AWXS_HANDLE_CLEARERROR(0)
		
		gHandle
		= (ix)
		  ? AWXS_ADAPTER(0)->handle
		  : AWXS_ADAPTERUTIL(0)->handle
		;

		test = awAdapterToFormattedString ( gHandle, format, &RETVAL );
		
		if ( test == awaFalse )
			XSRETURN_UNDEF;

	OUTPUT:
	RETVAL



void
setDateTimeFormat ( self, format )
	char * format

	ALIAS:
		Aw::Date::setDateTimeFormat = 1

	CODE:
		awAdapterSetDateTimeFormat ( format );



#===============================================================================
#
#	End of Module
#
#===============================================================================
