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

/* includes for Admin.xs */

#include <admin/awadmin.h>
#include <admin/awaccess.h>
#include <admin/awetadm.h>
#include <admin/awlog.h>
#include <admin/awserver.h>


/* includes for Aw.xs */

#include <awxs.h>
#include <awxs.m>
#include <awxs.def>

#include <admin/adminxs.h>
#include <admin/adminxs.m>
#include <admin/adminxs.def>


#include "Av_CharPtrPtr.h"
#include "exttypes.h"
#include "Util.h"
#include "HashToTypeDef.h"

typedef HV * Aw__Info;


BrokerError gErr = AW_NO_ERROR;
char * gErrMsg   = NULL;
int gErrCode     = 0;
awaBool gWarn    = awaFalse;


SV * getBrokerClientSessions ( BrokerClientSession * sessions, int num_sessions );
void BrokerServerConnectionCallbackFunc ( BrokerServerClient cbClient, int connect_status, void * vcb );



static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AW_AUTH_TYPE_NONE"))
#ifdef AW_AUTH_TYPE_NONE
	    return AW_AUTH_TYPE_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_AUTH_TYPE_SSL"))
#ifdef AW_AUTH_TYPE_SSL
	    return AW_AUTH_TYPE_SSL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_LIFECYCLE_DESTROY_ON_DISCONNECT"))
#ifdef AW_LIFECYCLE_DESTROY_ON_DISCONNECT
	    return AW_LIFECYCLE_DESTROY_ON_DISCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_LIFECYCLE_EXPLICIT_DESTROY"))
#ifdef AW_LIFECYCLE_EXPLICIT_DESTROY
	    return AW_LIFECYCLE_EXPLICIT_DESTROY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_LOG_ALL_ENTRIES"))
#ifdef AW_SERVER_LOG_ALL_ENTRIES
	    return AW_SERVER_LOG_ALL_ENTRIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_LOG_MESSAGE_ALERT"))
#ifdef AW_SERVER_LOG_MESSAGE_ALERT
	    return AW_SERVER_LOG_MESSAGE_ALERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_LOG_MESSAGE_INFO"))
#ifdef AW_SERVER_LOG_MESSAGE_INFO
	    return AW_SERVER_LOG_MESSAGE_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_LOG_MESSAGE_UNKNOWN"))
#ifdef AW_SERVER_LOG_MESSAGE_UNKNOWN
	    return AW_SERVER_LOG_MESSAGE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_LOG_MESSAGE_WARNING"))
#ifdef AW_SERVER_LOG_MESSAGE_WARNING
	    return AW_SERVER_LOG_MESSAGE_WARNING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_STATUS_ERROR"))
#ifdef AW_SERVER_STATUS_ERROR
	    return AW_SERVER_STATUS_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_STATUS_RUNNING"))
#ifdef AW_SERVER_STATUS_RUNNING
	    return AW_SERVER_STATUS_RUNNING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_STATUS_STARTING"))
#ifdef AW_SERVER_STATUS_STARTING
	    return AW_SERVER_STATUS_STARTING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_STATUS_STOPPED"))
#ifdef AW_SERVER_STATUS_STOPPED
	    return AW_SERVER_STATUS_STOPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SERVER_STATUS_STOPPING"))
#ifdef AW_SERVER_STATUS_STOPPING
	    return AW_SERVER_STATUS_STOPPING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SSL_STATUS_DISABLED"))
#ifdef AW_SSL_STATUS_DISABLED
	    return AW_SSL_STATUS_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SSL_STATUS_ENABLED"))
#ifdef AW_SSL_STATUS_ENABLED
	    return AW_SSL_STATUS_ENABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SSL_STATUS_ERROR"))
#ifdef AW_SSL_STATUS_ERROR
	    return AW_SSL_STATUS_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_SSL_STATUS_NOT_SUPPORTED"))
#ifdef AW_SSL_STATUS_NOT_SUPPORTED
	    return AW_SSL_STATUS_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_BROKER_ADDED"))
#ifdef AW_TRACE_BROKER_ADDED
	    return AW_TRACE_BROKER_ADDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_BROKER_REMOVED"))
#ifdef AW_TRACE_BROKER_REMOVED
	    return AW_TRACE_BROKER_REMOVED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_CLIENT_CONNECT"))
#ifdef AW_TRACE_CLIENT_CONNECT
	    return AW_TRACE_CLIENT_CONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_CLIENT_CREATE"))
#ifdef AW_TRACE_CLIENT_CREATE
	    return AW_TRACE_CLIENT_CREATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_CLIENT_DESTROY"))
#ifdef AW_TRACE_CLIENT_DESTROY
	    return AW_TRACE_CLIENT_DESTROY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_CLIENT_DISCONNECT"))
#ifdef AW_TRACE_CLIENT_DISCONNECT
	    return AW_TRACE_CLIENT_DISCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_EVENT_DROP"))
#ifdef AW_TRACE_EVENT_DROP
	    return AW_TRACE_EVENT_DROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_EVENT_ENQUEUE"))
#ifdef AW_TRACE_EVENT_ENQUEUE
	    return AW_TRACE_EVENT_ENQUEUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_EVENT_PUBLISH"))
#ifdef AW_TRACE_EVENT_PUBLISH
	    return AW_TRACE_EVENT_PUBLISH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_EVENT_RECEIVE"))
#ifdef AW_TRACE_EVENT_RECEIVE
	    return AW_TRACE_EVENT_RECEIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AW_TRACE_OTHER"))
#ifdef AW_TRACE_OTHER
	    return AW_TRACE_OTHER;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
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



SV *
getBrokerClientSessions ( BrokerClientSession * sessions, int num_sessions )
{
AV * av;
HV * hv;
SV * sv;
int i;

	av = newAV();

	for ( i = 0; i < num_sessions ; i++ ) {
		hv = newHV();

		hv_store ( hv, "session_id",        10, newSViv ( (int)sessions[i].session_id ), 0 );
		hv_store ( hv, "connection_id",     13, newSViv ( (int)sessions[i].connection_id ), 0 );

		// why the hell did this start SIGBUSing?
		// sv_setuv_mg ( sv, (UV)sessions[i].ip_address );
		// hv_store ( hv, "ip_address",        10, sv, 0 );

		hv_store ( hv, "ip_address",        10, newSViv( (unsigned int)sessions[i].ip_address ), 0 );
		hv_store ( hv, "port",               4, newSViv ( (int)sessions[i].port ), 0 );
		hv_store ( hv, "encrypt_level",     13, newSViv ( (int)sessions[i].encrypt_level ), 0 );
		hv_store ( hv, "num_platform_info", 17, newSViv ( (int)sessions[i].num_platform_info ), 0 );


		if ( sessions[i].encrypt_protocol != NULL )
			hv_store ( hv, "encrypt_protocol", 16, newSVpv ( (char *)sessions[i].encrypt_protocol, 0 ), 0 );
		if ( sessions[i].encrypt_version != NULL )
			hv_store ( hv, "encrypt_version",  15, newSVpv ( (char *)sessions[i].encrypt_version, 0 ), 0 );
		if ( sessions[i].auth_protocol != NULL )
			hv_store ( hv, "auth_protocol",    13, newSVpv ( (char *)sessions[i].auth_protocol, 0 ), 0 );
		if ( sessions[i].auth_version != NULL )
			hv_store ( hv, "auth_version",     12, newSVpv ( (char *)sessions[i].auth_version, 0 ), 0 );


		/* if ( sessions[i].ssl_certificate.serial_number != NULL ) { segfaults */
		if ( sessions[i].ssl_certificate.begin_date.year ) {
			sv = sv_newmortal();
			SvREFCNT_inc(sv);
			sv_setref_pv( sv, "Aw::SSLCertificate", (void*)&sessions[i].ssl_certificate );
			hv_store ( hv, "ssl_certificate", 15, sv, 0 );
		}

		sv = sv_newmortal();
		SvREFCNT_inc(sv);
		sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&sessions[i].connect_time) );
		hv_store ( hv, "connect_time", 12, sv, 0 );

		sv = sv_newmortal();
		SvREFCNT_inc(sv);
		sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&sessions[i].create_time) );
		hv_store ( hv, "create_time", 11, sv, 0 );

		sv = sv_newmortal();
		SvREFCNT_inc(sv);
		sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&sessions[i].last_activity_time) );
		hv_store ( hv, "last_activity_time", 18, sv, 0 );

		if ( sessions[i].num_platform_info ) {
			int j;
			HV * hi;
			hi = newHV();

			for ( j = 0; j < sessions[i].num_platform_info; j++ ) {
				hv_store ( hi, 
				   sessions[i].platform_info_keys[j],
				   strlen(sessions[i].platform_info_keys[j]),
				   newSVpv ( (char *)sessions[i].platform_info_values[j], 0 ),
				   0 );
			}
			hv_store ( hv, "platform_info", 13, newRV_noinc((SV*)hi), 0 );
		}

		av_push( av, newRV_noinc((SV*) hv) );
	}

	return ( newRV((SV*)av) ); // do not, not, not use newRV_noinc here!
}



void
BrokerServerConnectionCallbackFunc ( BrokerServerClient cbClient, int connect_status, void * vcb )
{
dSP;
SV *esv, *csv;
xsCallBackStruct * cb;
xsServerClient * client;


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



/*
#=============================================================================*/

MODULE = Aw		PACKAGE = Aw::Info

#===============================================================================

char *
toString ( info, ... )
	Aw::Info info

	PREINIT:
		char * type;
		SV ** sv;
		int indent_level = 0;

	CODE:
		if ( items-1 )
			indent_level = (int)SvIV(ST(1));

		sv   = hv_fetch ( info, "_type", 5, 0 );
		type = (char *)SvPV(*sv, PL_na);


		if ( indent_level ) {
		if ( !strcmp ( type, "BrokerClientInfo" ) ) {
			BrokerClientInfo * client_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_info = (BrokerClientInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awClientInfoToIndentedString ( client_info, indent_level );
		}
		else if ( !strcmp ( type, "BrokerClientGroupInfo" ) ) {
			BrokerClientGroupInfo * client_group_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_group_info = (BrokerClientGroupInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awClientGroupInfoToIndentedString( client_group_info, indent_level );
		}
#ifdef AWXS_WARNS
		else if ( gWarn ) {
			char * warning = (char *)safemalloc ( 128 * sizeof (char) );
			sprintf ( warning, "No 'toIndentString' method for Aw::Info type: %s", type );
			warn ( warning );
			Safefree (warning);
		}
#endif /* AWXS_WARNS */
		}
		else {
		if ( !strcmp ( type, "BrokerClientInfo" ) ) {
			BrokerClientInfo * client_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_info = (BrokerClientInfo *) SvIV((SV*)SvRV( *sv ));
			// RETVAL = awClientInfoToString ( client_info );
			RETVAL = awClientInfoToCompleteString ( client_info );
		}
		else if ( !strcmp ( type, "BrokerClientGroupInfo" ) ) {
			BrokerClientGroupInfo * client_group_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_group_info = (BrokerClientGroupInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awClientGroupInfoToString( client_group_info );
		}
		else if ( !strcmp ( type, "BrokerTerritoryInfo" ) ) {
			BrokerTerritoryInfo * territory_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			territory_info = (BrokerTerritoryInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awTerritoryInfoToString( territory_info );
		}
		else if ( !strcmp ( type, "BrokerTerritoryGatewayInfo" ) ) {
			BrokerTerritoryGatewayInfo * gateway_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			gateway_info = (BrokerTerritoryGatewayInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awTerritoryGatewayInfoToString( gateway_info );
		}
		else if ( !strcmp ( type, "BrokerSharedEventTypeInfo" ) ) {
			BrokerSharedEventTypeInfo * shared_et_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			shared_et_info = (BrokerSharedEventTypeInfo *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awSharedEventTypeInfoToString( shared_et_info );
		}
		else if ( !strcmp ( type, "BrokerServerLogEntry" ) ) {
			BrokerServerLogEntry * entry;
			sv = hv_fetch ( info, "_info", 5, 0 );
			entry = (BrokerServerLogEntry *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awServerLogEntryToString( entry );
		}
		else if ( !strcmp ( type, "BrokerTraceEvent" ) ) {
			BrokerTraceEvent * trace_event;
			sv = hv_fetch ( info, "_info", 5, 0 );
			trace_event = (BrokerTraceEvent *) SvIV((SV*)SvRV( *sv ));
			RETVAL = awTraceEventToString( trace_event );
		}
#ifdef AWXS_WARNS
		else if ( gWarn ) {
			char * warning = (char *)safemalloc ( 64 * sizeof (char) );
			sprintf ( warning, "Unknown Aw::Info type: %s", type );
			warn ( warning );
			Safefree (warning);
		}
#endif /* AWXS_WARNS */
		}
		

	OUTPUT:
	RETVAL



void
DESTROY ( info )
	Aw::Info info

	PREINIT:
		char * type;
		SV ** sv;

	CODE:
		sv   = hv_fetch ( info, "_type", 5, 0 );
		type = (char *)SvPV(*sv, PL_na);

		// fprintf ( stderr, "Destroying Aw::Info[%s]\n", type );

		if ( !strcmp ( type, "BrokerClientInfo" ) ) {
			BrokerClientInfo * client_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_info = (BrokerClientInfo *) SvIV((SV*)SvRV( *sv ));
			free (client_info);
		}
		else if ( !strcmp ( type, "BrokerClientGroupInfo" ) ) {
			BrokerClientGroupInfo * client_group_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			client_group_info = (BrokerClientGroupInfo *) SvIV((SV*)SvRV( *sv ));
			free (client_group_info);
		}
		else if ( !strcmp ( type, "BrokerTerritoryInfo" ) ) {
			BrokerTerritoryInfo * territory_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			territory_info = (BrokerTerritoryInfo *) SvIV((SV*)SvRV( *sv ));
			free (territory_info);
		}
		else if ( !strcmp ( type, "BrokerTerritoryGatewayInfo" ) ) {
			BrokerTerritoryGatewayInfo * gateway_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			gateway_info = (BrokerTerritoryGatewayInfo *) SvIV((SV*)SvRV( *sv ));
			free( gateway_info );
		}
		else if ( !strcmp ( type, "BrokerSharedEventTypeInfo" ) ) {
			BrokerSharedEventTypeInfo * shared_et_info;
			sv = hv_fetch ( info, "_info", 5, 0 );
			shared_et_info = (BrokerSharedEventTypeInfo *) SvIV((SV*)SvRV( *sv ));
			free( shared_et_info );
		}
		else if ( !strcmp ( type, "BrokerServerLogEntry" ) ) {
			BrokerServerLogEntry * entry;
			sv = hv_fetch ( info, "_info", 5, 0 );
			entry = (BrokerServerLogEntry *) SvIV((SV*)SvRV( *sv ));
			free( entry );
		}
		else if ( !strcmp ( type, "BrokerTraceEvent" ) ) {
			BrokerTraceEvent * trace_event;
			sv = hv_fetch ( info, "_info", 5, 0 );
			trace_event = (BrokerTraceEvent *) SvIV((SV*)SvRV( *sv ));
			free( trace_event );
		}



#=============================================================================*/

MODULE = Aw::Admin		PACKAGE = Aw::Admin

#===============================================================================

PROTOTYPES: DISABLE


BOOT:

	if ( (int)SvIV(perl_get_sv("Aw::Admin::SPAM", FALSE)) )
		printf ( "\nAw::Admin %s [%s] (c) <Yacob@wMUsers.Com>\n\n" ,
			 (char *)SvPV(perl_get_sv("Aw::Admin::VERSION", FALSE), PL_na),
			 (char *)SvPV(perl_get_sv("Aw::Admin::VERSION_NAME", FALSE), PL_na) );



double
constant(name,arg)
	char *		name
	int		arg



void
setWarnAll ( onOff )
	awaBool onOff

	CODE:
		gWarn = onOff;



#===============================================================================

MODULE = Aw::Admin		PACKAGE = Aw::Admin::BaseClass

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
		Aw::Admin::AccessControlList::DESTROY =  1
		Aw::Admin::LogConfig::DESTROY         =  2
		Aw::Admin::ServerClient::DESTROY      =  3
		Aw::Admin::TypeDef::DESTROY           =  4

	CODE:
		switch ( ix ) 
		  {
			case  1: /* AccessControlList */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Admin::AccessControlList!" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_ACCESSCONTROLLIST(0) );
				break;

			case  2: /* LogConfig */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Admin::LongConfig!" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_BROKERLOGCONFIG(0) );
				break;

			case  3: /* ServerClient */
				{
				xsServerClient * self = AWXS_SERVERCLIENT(0);
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Admin::ServerClient!" );
#endif /* AWXS_DEBUG */
				awDestroyServerClient ( self->server_client );
				Safefree ( self );
				}
				break;

			case  4: /* TypeDef */
#ifdef    AWXS_DEBUG
				warn ( "Freeing Aw::Admin::TypeDef!\n" );
#endif /* AWXS_DEBUG */
				Safefree ( AWXS_BROKERADMINTYPEDEF(0) );
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
		Aw::Admin::err                    =  0
		Aw::Admin::AccessControlList::err =  1
		Aw::Admin::LogConfig::err         =  2
		Aw::Admin::ServerClient::err      =  3
		Aw::Admin::TypeDef::err           =  4

	CODE:
		BrokerError err = NULL;


		switch ( ix ) 
		  {
			case 0:
				err = gErr;
				break;

			case 1:
				err = AWXS_ACCESSCONTROLLIST(0)->err;
				break;

			case 2:
				err = AWXS_BROKERLOGCONFIG(0)->err;
				break;

			case 3:
				err = AWXS_SERVERCLIENT(0)->err;
				break;

			case 4:
				err = AWXS_BROKERADMINTYPEDEF(0)->err;
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
		Aw::Admin::errmsg                       =  0
		Aw::Admin::AccessControlList::errmsg    =  1
		Aw::Admin::LogConfig::errmsg            =  2
		Aw::Admin::ServerClient::errmsg         =  3
		Aw::Admin::TypeDef::errmsg              =  4

		Aw::Admin::getErrMsg                    =  100
		Aw::Admin::AccessControlList::getErrMsg =  101
		Aw::Admin::LogConfig::getErrMsg         =  102
		Aw::Admin::ServerClient::getErrMsg      =  103
		Aw::Admin::TypeDef::getErrMsg           =  104

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
				err    = AWXS_ACCESSCONTROLLIST(0)->err;
				errMsg = AWXS_ACCESSCONTROLLIST(0)->errMsg;
				break;

			case 2:
			case 102:
				err    = AWXS_BROKERLOGCONFIG(0)->err;
				errMsg = AWXS_BROKERLOGCONFIG(0)->errMsg;
				break;

			case 3:
			case 103:
				err    = AWXS_SERVERCLIENT(0)->err;
				errMsg = AWXS_SERVERCLIENT(0)->errMsg;
				break;

			case 4:
			case 104:
				err    = AWXS_BROKERADMINTYPEDEF(0)->err;
				errMsg = AWXS_BROKERADMINTYPEDEF(0)->errMsg;
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
			RETVAL = awErrorToCompleteString ( err );  /* hopefully NULL if AW_NO_ERROR */

		if ( RETVAL == NULL )
			XSRETURN_UNDEF;


	OUTPUT:
	RETVAL



void
setErrMsg ( self, newErrMsg )
	char * newErrMsg

	ALIAS:
		Aw::Admin::setErrMsg                    =  0
		Aw::Admin::AccessControlList::setErrMsg =  1
		Aw::Admin::LogConfig::setErrMsg         =  2
		Aw::Admin::ServerClient::setErrMsg      =  3
		Aw::Admin::TypeDef::setErrMsg           =  4

	CODE:
		char ** errMsg;

		switch ( ix ) 
		  {
			case 0:
				errMsg =& gErrMsg;
				break;

			case 1:
				errMsg =& AWXS_ACCESSCONTROLLIST(0)->errMsg;
				break;

			case 2:
				errMsg =& AWXS_BROKERLOGCONFIG(0)->errMsg;
				break;

			case 3:
				errMsg =& AWXS_SERVERCLIENT(0)->errMsg;
				break;

			case 4:
				errMsg =& AWXS_BROKERADMINTYPEDEF(0)->errMsg;
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
		Aw::Admin::throw                    =  0
		Aw::Admin::AccessControlList::throw =  1
		Aw::Admin::LogConfig::throw         =  2
		Aw::Admin::ServerClient::throw      =  3
		Aw::Admin::TypeDef::throw           =  4

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
		Aw::Admin::catch                    =  0
		Aw::Admin::AccessControlList::catch =  1
		Aw::Admin::LogConfig::catch         =  2
		Aw::Admin::ServerClient::catch      =  3
		Aw::Admin::TypeDef::catch           =  4

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
		Aw::Admin::getErrCode                    =  0
		Aw::Admin::AccessControlList::getErrCode =  1
		Aw::Admin::LogConfig::getErrCode         =  2
		Aw::Admin::ServerClient::getErrCode      =  3
		Aw::Admin::TypeDef::getErrCode           =  4

	CODE:
		switch ( ix ) 
		  {
			case 0:
				RETVAL = awGetErrorCode ( gErr );
				break;

			case 1:
				RETVAL = awGetErrorCode ( AWXS_ACCESSCONTROLLIST(0)->err );
				break;

			case 2:
				RETVAL = awGetErrorCode ( AWXS_BROKERLOGCONFIG(0)->err );
				break;

			case 3:
				RETVAL = awGetErrorCode ( AWXS_SERVERCLIENT(0)->err );
				break;

			case 4:
				RETVAL = awGetErrorCode ( AWXS_BROKERADMINTYPEDEF(0)->err );
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
		Aw::Admin::error                    =  0
		Aw::Admin::AccessControlList::error =  1
		Aw::Admin::LogConfig::error         =  2
		Aw::Admin::ServerClient::error      =  3
		Aw::Admin::TypeDef::error           =  4

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
				RETVAL->err = AWXS_ACCESSCONTROLLIST(0)->err;
				break;

			case 2:
				RETVAL->err = AWXS_BROKERLOGCONFIG(0)->err;
				break;

			case 3:
				RETVAL->err = AWXS_SERVERCLIENT(0)->err;
				break;

			case 4:
				RETVAL->err = AWXS_BROKERADMINTYPEDEF(0)->err;
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
		Aw::Admin::getWarn                    =  0
		Aw::Admin::AccessControlList::getWarn =  1
		Aw::Admin::LogConfig::getWarn         =  2
		Aw::Admin::ServerClient::getWarn      =  3
		Aw::Admin::TypeDef::getWarn           =  4

	CODE:
		switch ( ix ) 
		  {
			case 0:
				RETVAL = (int)gWarn;
				break;

			case 1:
				RETVAL = (int)AWXS_ACCESSCONTROLLIST(0)->Warn;
				break;

			case 2:
				RETVAL = (int)AWXS_BROKERLOGCONFIG(0)->Warn;
				break;

			case 3:
				RETVAL = (int)AWXS_SERVERCLIENT(0)->Warn;
				break;

			case 4:
				RETVAL = (int)AWXS_BROKERADMINTYPEDEF(0)->Warn;
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
		Aw::Admin::setWarn                    =  0
		Aw::Admin::AccessControlList::setWarn =  1
		Aw::Admin::LogConfig::setWarn         =  2
		Aw::Admin::ServerClient::setWarn      =  3
		Aw::Admin::TypeDef::setWarn           =  4

	CODE:
		switch ( ix ) 
		  {
			case 0:
				gWarn = level;
				break;

			case 1:
				AWXS_ACCESSCONTROLLIST(0)->Warn = level;
				break;

			case 2:
				AWXS_BROKERLOGCONFIG(0)->Warn = level;
				break;

			case 3:
				AWXS_SERVERCLIENT(0)->Warn = level;
				break;

			case 4:
				AWXS_BROKERADMINTYPEDEF(0)->Warn = level;
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
		Aw::Admin::warn                    =  0
		Aw::Admin::AccessControlList::warn =  1
		Aw::Admin::LogConfig::warn         =  2
		Aw::Admin::ServerClient::warn      =  3
		Aw::Admin::TypeDef::warn           =  4


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
				err    = AWXS_ACCESSCONTROLLIST(0)->err;
				errMsg = AWXS_ACCESSCONTROLLIST(0)->errMsg;
				Warn   = AWXS_ACCESSCONTROLLIST(0)->Warn;
				break;

			case 2:
				err    = AWXS_BROKERLOGCONFIG(0)->err;
				errMsg = AWXS_BROKERLOGCONFIG(0)->errMsg;
				Warn   = AWXS_BROKERLOGCONFIG(0)->Warn;
				break;

			case 3:
				err    = AWXS_SERVERCLIENT(0)->err;
				errMsg = AWXS_SERVERCLIENT(0)->errMsg;
				Warn   = AWXS_SERVERCLIENT(0)->Warn;
				break;

			case 4:
				err    = AWXS_BROKERADMINTYPEDEF(0)->err;
				errMsg = AWXS_BROKERADMINTYPEDEF(0)->errMsg;
				Warn   = AWXS_BROKERADMINTYPEDEF(0)->Warn;
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
		Aw::Admin::AccessControlList::hello =  1
		Aw::Admin::LogConfig::hello         =  2
		Aw::Admin::ServerClient::hello      =  3
		Aw::Admin::TypeDef::hello           =  4

	CODE:
		RETVAL = strdup ( "  hello" );

	OUTPUT:
	RETVAL



char *
toString ( ... )

	ALIAS:
		Aw::AccessControlList::toString   = 1
		Aw::Admin::LogConfig::toString    = 2
		Aw::Admin::ServerClient::toString = 3
		Aw::Admin::TypeDef::toString      = 4

	CODE:
		/*  note, we haven't cleared the error here */

		if ( items-1 )
		switch ( ix ) 
		  {
			case 1:
				{
				int indent_level = 0;
				char * name = NULL;

				if ( SvTYPE(ST(1)) == SVt_IV )
					name = (char *)SvPV(ST(1),PL_na);
				else
					indent_level = (int)SvIV(ST(1));

				if ( items == 3 ) {
					if ( SvTYPE(ST(2)) == SVt_IV )
						name = (char *)SvPV(ST(2),PL_na);
					else
						indent_level = (int)SvIV(ST(2));
				}

				RETVAL = awACLToIndentedString ( AWXS_ACCESSCONTROLLIST(0)->acl, indent_level, name );
				}
				break;

			case 2:
				RETVAL = awLogConfigToIndentedString ( AWXS_BROKERLOGCONFIG(0)->log_config, (int)SvIV(ST(1)) );
				break;

			case 4:
				RETVAL = awAdminTypeDefToIndentedString ( AWXS_BROKERADMINTYPEDEF(0)->type_def, (int)SvIV(ST(1)) );
				break;

			default:
#ifdef AWXS_WARNS
				if ( gWarn )
					warn ( "You need an Alias here: %i", ix );
#endif /* AWXS_WARNS */
				break;
		  }

		else switch ( ix ) 

		  {
			case 1:
				RETVAL = awACLToString ( AWXS_ACCESSCONTROLLIST(0)->acl );
				break;

			case 2:
				RETVAL = awLogConfigToString ( AWXS_BROKERLOGCONFIG(0)->log_config );
				break;

			case 3:
				RETVAL = awServerClientToString ( AWXS_SERVERCLIENT(0)->server_client );
				break;

			case 4:
				RETVAL = awAdminTypeDefToString ( AWXS_BROKERADMINTYPEDEF(0)->type_def );

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

MODULE = Aw::Admin		PACKAGE = Aw::Admin::AccessControlList

#===============================================================================

Aw::Admin::AccessControlList
new ( CLASS )
	char * CLASS

	CODE:
		RETVAL = (xsAccessControlList *)safemalloc ( sizeof(xsAccessControlList) );
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

		              /* this casting was required but seems suspicious */
		RETVAL->acl = (BrokerAccessControlList) awNewBrokerAccessControlList ( );

	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::Admin::AccessControlList self

	CODE:
		awDeleteAccessControlList ( self->acl );



Aw::Admin::AccessControlList
copy ( self )
	Aw::Admin::AccessControlList self

	PREINIT:
		char CLASS[] = "Aw::Admin::AccessControlList";

	CODE:
		RETVAL = (xsAccessControlList *)safemalloc ( sizeof(xsAccessControlList) );
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

		              /* this casting was required but seems suspicious */
		RETVAL->acl = (BrokerAccessControlList) awCopyBrokerAccessControlList ( self->acl );

	OUTPUT:
	RETVAL



char **
getAuthNamesRef ( self )
	Aw::Admin::AccessControlList self

	ALIAS:
		Aw::Admin::AccessControlList::getUserNamesRef = 1

	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (ix)
		  ? awGetACLUserNames  ( self->acl, &count_charPtrPtr, &RETVAL )
		  : awGetACLAuthNames  ( self->acl, &count_charPtrPtr, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
getAuthNameState ( self, name )
	Aw::Admin::AccessControlList self
	char * name

	ALIAS:
		Aw::Admin::AccessControlList::getUserNameState = 1

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (ix)
		  ? awGetACLUserNameState ( self->acl, name, &bRV )
		  : awGetACLAuthNameState ( self->acl, name, &bRV )
		;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



awaBool
setAuthNames ( self, names )
	Aw::Admin::AccessControlList self
	char ** names

	ALIAS:
		Aw::Admin::AccessControlList::setUserNames = 1

	PREINIT:
		int n;

	CODE:
		AWXS_CLEARERROR

		n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;

		gErr = self->err 
		= (ix)
		  ? awSetACLAuthNames ( self->acl, n, names )
		  : awSetACLUserNames ( self->acl, n, names )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;
	
	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( names );



awaBool
setAuthNameState ( self, ... )
	Aw::Admin::AccessControlList self

	PREINIT:
		int n = 0;
		char ** names;
		awaBool is_allowed;

	ALIAS:
		Aw::Admin::AccessControlList::setUserNameState = 1

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
			names = XS_unpack_charPtrPtr ( ST(1) ); 
			n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;
		}

		gErr = self->err 
		= (ix)
		  ? (n)
		    ? awSetACLUserNameStates ( self->acl, n, names, (BrokerBoolean) is_allowed )
		    : awSetACLUserNameState  ( self->acl, (char *)SvPV ( ST(1), PL_na ), (BrokerBoolean) is_allowed )
		  : (n)
		    ? awSetACLAuthNameStates ( self->acl, n, names, (BrokerBoolean) is_allowed )
		    : awSetACLAuthNameState  ( self->acl, (char *)SvPV ( ST(1), PL_na ), (BrokerBoolean) is_allowed )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;
	
	OUTPUT:
		RETVAL

	CLEANUP:
		if ( n )
			XS_release_charPtrPtr ( names );



#===============================================================================

MODULE = Aw::Admin		PACKAGE = Aw::Admin::TypeDef

#===============================================================================

Aw::Admin::TypeDef
new ( CLASS, ... )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );
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

		// this is grotesque but i'm in a hurry...
		if ( items == 4 )  { // the full monty
			gErr = RETVAL->err = awNewBrokerAdminTypeDef ( (char *)SvPV(ST(1),PL_na), (short)SvIV(ST(2)), &RETVAL->type_def );

			if ( gErr == AW_NO_ERROR )
				gErr = RETVAL->err = awxsSetEventTypeDefFromHash ( RETVAL->type_def, (HV*)SvRV(ST(3)) );
		}
		else if ( items == 3 ) {
			if ( SvTYPE(ST(2)) == SVt_RV && SvTYPE(SvRV(ST(2))) == SVt_PVHV ) {
				if ( SvTYPE(ST(1)) == SVt_IV )
					gErr = RETVAL->err = awNewBrokerAdminTypeDef ( NULL, FIELD_TYPE_STRUCT, &RETVAL->type_def );
				else if ( SvTYPE(ST(1)) == SVt_PV )
					gErr = RETVAL->err = awNewBrokerAdminTypeDef ( (char *)SvPV(ST(1),PL_na), FIELD_TYPE_EVENT, &RETVAL->type_def );
				else
		        		warn( "Aw:Admin::TypeDefEvent::new() -- inappropriate args." );

				if ( gErr == AW_NO_ERROR )
					gErr = RETVAL->err = awxsSetEventTypeDefFromHash ( RETVAL->type_def, (HV*)SvRV(ST(2)) );
			}
			else
				gErr = RETVAL->err = awNewBrokerAdminTypeDef ( (char *)SvPV(ST(1),PL_na), (short)SvIV(ST(2)), &RETVAL->type_def );
		}
		else if ( items == 2 ) {
			if ( SvTYPE(ST(1)) == SVt_RV && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
				gErr = RETVAL->err = awNewBrokerAdminTypeDef ( "Change::Me", FIELD_TYPE_EVENT, &RETVAL->type_def );
				if ( gErr == AW_NO_ERROR )
					gErr = RETVAL->err = awxsSetEventTypeDefFromHash ( RETVAL->type_def, (HV*)SvRV(ST(1)) );
			}
			else if ( SvTYPE(ST(1)) == SVt_IV )
				gErr = RETVAL->err = awNewBrokerAdminTypeDef ( NULL, (short)SvIV(ST(1)), &RETVAL->type_def );
			else if ( SvTYPE(ST(1)) == SVt_PV )
				// default is an event type?
				gErr = RETVAL->err = awNewBrokerAdminTypeDef ( (char *)SvPV(ST(1),PL_na), FIELD_TYPE_EVENT, &RETVAL->type_def );
			else
		        	warn( "Aw:Admin::TypeDefEvent::new() -- inappropriate args." );
		}
		else if ( sv_isobject ( ST(1) ) ) {
			if ( sv_derived_from ( ST(1), "Aw::Admin::TypeDef" ) )
				RETVAL->type_def = awCopyBrokerAdminTypeDef ( AWXS_BROKERADMINTYPEDEF(1)->type_def );
			else if ( sv_derived_from ( ST(1), "Aw::TypeDef" ) )
				RETVAL->type_def = awCopyBrokerTypeDef ( AWXS_BROKERTYPEDEF(1)->type_def );
			else
			        warn( "Aw:Admin::TypeDefEvent::new() -- Arg 2 is not an Aw::TypeDef or Aw::Admin::TypeDef reference." );
		}
		else	// only structs can be anonymous
			gErr = RETVAL->err = awNewBrokerAdminTypeDef ( NULL, FIELD_TYPE_STRUCT, &RETVAL->type_def );


		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new Aw::Admin::TypeDef %s", awErrorToCompleteString ( RETVAL->err ) );
			Safefree ( RETVAL );
#ifdef AWXS_WARNS
			if ( gWarn )
				warn ( gErrMsg );
#endif /* AWXS_WARNS */
			XSRETURN_UNDEF;
		}

	OUTPUT:
	RETVAL



Aw::Admin::TypeDef
copy ( self )
	Aw::Admin::TypeDef self

	PREINIT:
		char CLASS[] = "Aw::Admin::TypeDef";

	CODE:
		RETVAL = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );
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

		RETVAL->type_def = awCopyBrokerAdminTypeDef ( self->type_def );

	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::Admin::TypeDef self

	ALIAS:
		Aw::Admin::TypeDef::clearModificationFlag = 1
		Aw::Admin::TypeDef::setModificationFlag   = 2

	CODE:
		AWXS_CLEARERROR

		if (ix) {
		  if (ix-1)
		    awSetAdminTypeDefModificationFlag ( self->type_def );
		  else
		    awClearAdminTypeDefModificationFlag ( self->type_def );
		}
		else
		  awDeleteAdminTypeDef ( self->type_def );

		

Aw::Admin::TypeDef
getFieldDef ( self, field_name )
	Aw::Admin::TypeDef self
	char * field_name

	PREINIT:
		char CLASS[] = "Aw::Admin::TypeDef";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new Aw::Admin::TypeDef" );
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

		gErr = self->err = awGetAdminTypeDefFieldDef ( self->type_def, (char *)SvPV(ST(1),PL_na), &RETVAL->type_def );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setDescription ( self, string )
	Aw::Admin::TypeDef self
	char * string

	ALIAS:
		Aw::Admin::TypeDef::setTypeName = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= ( ix )
		    ? awSetAdminTypeDefTypeName ( self->type_def, string )
		    : awSetAdminTypeDefDescription ( self->type_def, string )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char *
getBaseTypeName ( self )
	Aw::Admin::TypeDef self

	ALIAS:
		Aw::Admin::TypeDef::getScopeTypeName = 1
		Aw::Admin::TypeDef::getTypeName      = 2

	CODE:
		AWXS_CLEARERROR

		RETVAL
		= ( ix )
		  ? (ix-1)
		    ? awGetAdminTypeDefTypeName  ( self->type_def )
		    : awGetAdminTypeDefScopeName ( self->type_def )
		  : awGetAdminTypeDefBaseName    ( self->type_def )
		;

	OUTPUT:
	RETVAL



char *
getDescription ( self )
	Aw::Admin::TypeDef self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetAdminTypeDefDescription ( self->type_def, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



int
getTimeToLive ( self )
	Aw::Admin::TypeDef self

	ALIAS:
		Aw::Admin::TypeDef::getStorageType = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= ( ix )
		  ? awGetAdminTypeDefTimeToLive  ( self->type_def, &RETVAL ) 
		  : awGetAdminTypeDefStorageType ( self->type_def, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setTimeToLive ( self, number )
	Aw::Admin::TypeDef self
	int number

	ALIAS:
		Aw::Admin::TypeDef::setStorageType = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= ( ix )
		  ? awSetAdminTypeDefStorageType ( self->type_def, number )
		  : awSetAdminTypeDefTimeToLive  ( self->type_def, number ) 
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



short
getFieldType ( self, field_name )
	Aw::Admin::TypeDef self
	char * field_name
	
	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetAdminTypeDefFieldType ( self->type_def, field_name, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



char **
getFieldNamesRef ( self, field_name )
	Aw::Admin::TypeDef self
	char * field_name
	
	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetAdminTypeDefFieldNames ( self->type_def, field_name, &count_charPtrPtr, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
orderFields ( self, field_name, field_names )
	Aw::Admin::TypeDef self
	char * field_name
	char ** field_names
	
	PREINIT:
		int n;

	CODE:
		AWXS_CLEARERROR

		n = av_len ( (AV*)SvRV( ST(2) ) ) + 1;
		
		gErr = self->err = awOrderAdminTypeDefFields ( self->type_def, field_name, n, field_names );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( field_names );



awaBool
setFieldType ( self, field_name, field_type )
	Aw::Admin::TypeDef self
	char * field_name
	short field_type
	
	CODE:
		AWXS_CLEARERROR

		// the last arg is "Currently not used and should be set to NULL" C Platform Vol 2 9-141
		gErr = self->err = awSetAdminTypeDefFieldType ( self->type_def, field_name, field_type, NULL );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
insertFieldDef ( self, field_name, index, field_def )
	Aw::Admin::TypeDef self
	char * field_name
	int index
	Aw::Admin::TypeDef field_def
	
	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awInsertAdminTypeDefFieldDef ( self->type_def, field_name, index, field_def->type_def );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setFieldDef ( self, field_name, field_def )
	Aw::Admin::TypeDef self
	char * field_name
	
	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= ( SvTYPE(ST(2)) == SVt_RV && SvTYPE(SvRV(ST(2))) == SVt_PVHV ) 
		  ? awxsSetStructFieldType ( self->type_def, field_name, (HV*)SvRV(ST(2)) )
		  : awSetAdminTypeDefFieldDef ( self->type_def, field_name, AWXS_BROKERADMINTYPEDEF(2)->type_def )
		;
				
		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
renameField ( self, old_field_name, new_field_name )
	Aw::Admin::TypeDef self
	char * old_field_name
	char * new_field_name
	
	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awRenameAdminTypeDefField ( self->type_def, old_field_name, new_field_name );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
hasBeenModified ( self )
	Aw::Admin::TypeDef self

	ALIAS:
		Aw::Admin::TypeDef::isSystemDefined = 1

	CODE:
		AWXS_CLEARERROR

		if (ix) {
			gErr = self->err = awIsAdminTypeDefSystemDefined ( self->type_def, &RETVAL );
			AWXS_CHECKSETERROR_RETURN
		}
		else
			RETVAL = awHasAdminTypeDefBeenModified ( self->type_def );


	OUTPUT:
	RETVAL



awaBool
clearField ( self, ... )
	Aw::Admin::TypeDef self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (items-1)
		  ? awClearAdminTypeDefField ( self->type_def, (char *)SvPV( ST(1), PL_na ) )
		  : awClearAdminTypeDefFields ( self->type_def )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw::Admin		PACKAGE = Aw::Admin::LogConfig

#===============================================================================

Aw::Admin::LogConfig
new ( CLASS )
	char * CLASS

	CODE:
		RETVAL = (xsBrokerLogConfig *)safemalloc ( sizeof(xsBrokerLogConfig) );
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

		RETVAL->log_config = awNewBrokerLogConfig ();

	OUTPUT:
	RETVAL



void
delete ( self )
	Aw::Admin::LogConfig self

	CODE:
		awDeleteLogConfig ( self->log_config );



Aw::Admin::LogConfig
copy ( self )
	Aw::Admin::LogConfig self

	PREINIT:
		char CLASS[] = "Aw::Admin::LogConfig";

	CODE:
		RETVAL = (xsBrokerLogConfig *)safemalloc ( sizeof(xsBrokerLogConfig) );
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

		RETVAL->log_config = awCopyBrokerLogConfig ( self->log_config );

	OUTPUT:
	RETVAL



HV *
_getOutput ( self, code )
	Aw::Admin::LogConfig self
	char * code

	ALIAS:
		Aw::Admin::LogConfig::_getTopic = 1

	PREINIT:
		BrokerBoolean enabled;
		char * value;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (ix)
		  ? awGetLogOutput ( self->log_config, code, &enabled, &value )
		  : awGetLogTopic  ( self->log_config, code, &enabled, &value )
		;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		hv_store ( RETVAL, "code",    4, newSVpv ( code, 0 ), 0 );
		hv_store ( RETVAL, "enabled", 7, newSViv ( (int)enabled ), 0 );
		hv_store ( RETVAL, "value",   5, newSVpv ( value, 0 ), 0 );

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( value );
		SvREFCNT_dec( RETVAL );



awaBool
setOutput ( self, ... )
	Aw::Admin::LogConfig self

	ALIAS:
		Aw::Admin::LogConfig::setTopic = 1

	PREINIT:
		HV * hv;
		SV ** sv;

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
			AV * av = (AV*)SvRV( ST(1) );
			int i, n;
			BrokerLogConfigEntry * log_things;

			n = av_len ( av ) + 1;

			log_things = (BrokerLogConfigEntry *)safemalloc ( sizeof(BrokerLogConfigEntry)*n );

			for ( i = 0; i < n; i++ ) {	
				sv = av_fetch ( av, i, 0 );
				hv = (HV*)SvRV(*sv);
	
				sv                    = hv_fetch ( hv, "code", 4, 0 );
				log_things[i].code    = (char *)SvPV(*sv, PL_na);
	
				sv                    = hv_fetch ( hv, "enabled", 7, 0 );
				log_things[i].enabled = (BrokerBoolean)SvIV(*sv);
	
				sv                    = hv_fetch ( hv, "value", 5, 0 );
				log_things[i].value   = (char *)SvPV(*sv, PL_na);
			}

			gErr = self->err 
			= (ix)
			  ? awSetLogOutputs ( self->log_config, n, log_things )
			  : awSetLogTopics  ( self->log_config, n, log_things )
			;

			Safefree ( log_things );
		}
		else {
			char * code;
			BrokerBoolean enabled;
			char * value;

			hv = (HV*)SvRV( ST(2) );

			sv      = hv_fetch ( hv, "code", 4, 0 );
			code    = (char *)SvPV(*sv, PL_na);

			sv      = hv_fetch ( hv, "enabled", 7, 0 );
			enabled = (BrokerBoolean)SvIV(*sv);

			sv      = hv_fetch ( hv, "value", 5, 0 );
			value   = (char *)SvPV(*sv, PL_na);

			gErr = self->err 
			= (ix)
			  ? awSetLogOutput ( self->log_config, code, enabled, value )
			  : awSetLogTopic  ( self->log_config, code, enabled, value )
			;

			// do not free "code" and "value"
		}

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



AV *
getOutputsRef ( self )
	Aw::Admin::LogConfig self

	ALIAS:
		Aw::Admin::LogConfig::getTopicsRef = 1

	PREINIT:
		int i, n;
		BrokerLogConfigEntry * log_things;
		HV * hv;
		SV * sv;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (ix)
		  ? awGetLogOutputs ( self->log_config, &n, &log_things )
		  : awGetLogTopics  ( self->log_config, &n, &log_things )
		;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			hv_store ( hv, "code", 4, newSVpv ( log_things[i].code, 0 ), 0 );
			hv_store ( hv, "enabled", 7, newSViv ( (int)log_things[i].enabled ), 0 );
			hv_store ( hv, "value", 5, newSVpv ( log_things[i].value, 0 ), 0 );

			av_push( RETVAL, newRV_noinc((SV*) hv) );
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		Safefree ( log_things );
		SvREFCNT_dec( RETVAL );



awaBool
clearOutput ( self, ... )
	Aw::Admin::LogConfig self

	ALIAS:  # plurals for java compatibility
		Aw::Admin::LogConfig::clearTopic   = 1
		Aw::Admin::LogConfig::clearOutputs = 2
		Aw::Admin::LogConfig::clearTopics  = 3

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= (items-1)
		  ? (ix%2)
		    ? awClearLogTopic   ( self->log_config, (char *)SvPV( ST(1), PL_na ) )
		    : awClearLogOutput  ( self->log_config, (char *)SvPV( ST(1), PL_na ) )
		  : (ix%2)
		    ? awClearLogTopics  ( self->log_config )
		    : awClearLogOutputs ( self->log_config )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw::Admin		PACKAGE = Aw::Admin::ServerClient

#===============================================================================

Aw::Admin::ServerClient
new ( CLASS, broker_host, ... )
	char * CLASS
	char * broker_host


	PREINIT:
		BrokerConnectionDescriptor myDesc = NULL;

	CODE:
		RETVAL = (xsServerClient *)safemalloc ( sizeof(xsServerClient) );
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

		if ( items == 3 && ( sv_isobject(ST(2)) && (SvTYPE(SvRV(ST(2))) == SVt_PVMG) ) )
			myDesc = AWXS_BROKERCONNECTIONDESC(2)->desc;

		gErr = RETVAL->err = awNewBrokerServerClient ( broker_host, myDesc, &RETVAL->server_client );

		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new Aw::Admin::ServerClient %s", awErrorToCompleteString ( RETVAL->err ) );
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



Aw::Admin::AccessControlList
getAdminACL ( self )
	Aw::Admin::ServerClient self

	PREINIT:
		char CLASS[] = "Aw::Admin::AccessControlList";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsAccessControlList *)safemalloc ( sizeof(xsAccessControlList) );
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

		gErr = self->err = awGetServerAdminACL ( self->server_client, &RETVAL->acl );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setAdminACL ( self, acl )
	Aw::Admin::ServerClient self
	Aw::Admin::AccessControlList acl

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetServerAdminACL ( self->server_client, acl->acl );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char **
getDNsFromCertFileRef ( self, certificate_file, password )
	Aw::Admin::ServerClient self
	char * certificate_file
	char * password

	ALIAS:
		Aw::Admin::ServerClient::getRootDNsFromCertFile = 1
		
	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awGetServerDNsFromCertFile     ( self->server_client, certificate_file, password, &count_charPtrPtr, &RETVAL )
		  : awGetServerRootDNsFromCertFile ( self->server_client, certificate_file, password, &count_charPtrPtr, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



HV *
getActiveSSLConfig ( self )
	Aw::Admin::ServerClient self

	ALIAS:
		Aw::Admin::ServerClient::getActiveProcessInfo = 1
		Aw::Admin::ServerClient::getSavedSSLConfig    = 2
		Aw::Admin::ServerClient::getSSLStatus         = 3

	PREINIT:
		char * string1;
		char * string2;
		char * string3;
		int status;
		int level;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix>=2)
		  ? (ix-2)
		    ? awGetServerSSLStatus         ( self->server_client, &status,  &level,   &string1 )
		    : awGetServerSavedSSLConfig    ( self->server_client, &string1, &string2, &string3 )
		  : (ix) 
		    ? awGetServerActiveProcessInfo ( self->server_client, &string1, &string2 )
		    : awGetServerActiveSSLConfig   ( self->server_client, &string1, &string2, &string3 )
		;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		switch (ix) {
			case 0:
			case 2:
				hv_store ( RETVAL, "certificate_file", 16, newSVpv ( string1, 0 ), 0 );
				hv_store ( RETVAL, "distinguished_name", 18, newSVpv ( string2, 0 ), 0 );
				hv_store ( RETVAL, "issuer_distinguished_name", 25, newSVpv ( string3, 0 ), 0 );
				break;
                            
			case 1:
				hv_store ( RETVAL, "executable_name", 15, newSVpv ( string1, 0 ), 0 );
				hv_store ( RETVAL, "data_directory", 14, newSVpv ( string2, 0 ), 0 );
				break;
                                         
			case 3:
				hv_store ( RETVAL, "status", 6, newSViv ( (int)status ), 0 );
				hv_store ( RETVAL, "level",  5, newSViv ( (int)level ), 0 );
				hv_store ( RETVAL, "error_string", 12, newSVpv ( string1, 0 ), 0 );
				break;
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( string1 );
		free ( string2 );
		free ( string3 );



awaBool
setSSLConfig ( self, new_config )
	Aw::Admin::ServerClient self
	HV * new_config

	PREINIT:
		char * certificate_file;
		char * password;
		char * distinguished_name;
		SV  ** sv;
	
	CODE:
		sv                 = hv_fetch ( new_config, "certificate_file", 16, 0 );
		certificate_file   = (char *)SvPV(*sv, PL_na);

		sv                 = hv_fetch ( new_config, "password", 8, 0 );
		password           = (char *)SvPV(*sv, PL_na);

		sv                 = hv_fetch ( new_config, "distinguished_name", 18, 0 );
		distinguished_name = (char *)SvPV(*sv, PL_na);
	
		gErr = self->err = awSetServerSSLConfig ( self->server_client, certificate_file, password, distinguished_name );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( certificate_file );
		free ( password );
		free ( distinguished_name );



Aw::Admin::LogConfig
getLogConfig ( self )
	Aw::Admin::ServerClient self

	PREINIT:
		char CLASS[] = "Aw::Admin::LogConfig";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerLogConfig *)safemalloc ( sizeof(xsBrokerLogConfig) );
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

		gErr = self->err = awGetServerLogConfig ( self->server_client, &RETVAL->log_config );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setLogConfig ( self, log_config )
	Aw::Admin::ServerClient self
	Aw::Admin::LogConfig log_config

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetServerLogConfig ( self->server_client, log_config->log_config );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



HV *
getLogStatus ( self )
	Aw::Admin::ServerClient self

	PREINIT:
		BrokerServerLogInfo * info;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetServerLogStatus ( self->server_client, info );

		AWXS_CHECKSETERROR_RETURN

		{
		SV * sv;

		RETVAL = newHV();

		sv = sv_newmortal();
		sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&info->first_entry) );
		SvREFCNT_inc(sv);
		hv_store ( RETVAL, "first_entry", 11, sv, 0 );

		sv = sv_newmortal();
		sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&info->last_entry) );
		SvREFCNT_inc(sv);
		hv_store ( RETVAL, "last_entry", 10, sv, 0 );

		hv_store ( RETVAL, "num_entries", 11, newSViv ( (int)info->num_entries ), 0 );
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( info );
		SvREFCNT_dec( RETVAL );



AV *
getLogEntriesRef ( self, first_entry, locale )
	Aw::Admin::ServerClient self
	Aw::Date first_entry
	char * locale

	PREINIT:
		int n;
		BrokerServerLogEntry * entries;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetServerLogEntries ( self->server_client, *first_entry, locale, &n, &entries );

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;
		BrokerServerLogEntry * entry;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {
			hv = newHV();

			entry = (BrokerServerLogEntry *)malloc ( sizeof(BrokerServerLogEntry) );
			memcpy ( entry, &entries[i], sizeof(BrokerServerLogEntry) );

			hv_store ( hv, "_type",           5, newSVpv ( "BrokerServerLogEntry", 20 ), 0 );
			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)entry );

			hv_store ( hv, "_info",           5, sv, 0 );

			sv = sv_newmortal();
			sv_setref_pv( sv, "Aw::Date", (void*)awCopyDate(&entries[i].time_stamp) );
			SvREFCNT_inc(sv);
			hv_store ( hv, "time_stamp",     10, sv, 0 );

			hv_store ( hv, "entry_type",     10, newSViv ( (int)entries[i].entry_type ), 0 );
			hv_store ( hv, "entry_msg_id",   12, newSViv ( (int)entries[i].entry_msg_id ), 0 );
			hv_store ( hv, "entry_msg_text", 14, newSVpv ( entries[i].entry_msg_text, 0 ), 0 );

			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
			free ( &entries[i] ); // C Platform Vol 2 is hosed on page 9-94
			                      // hopefully this is what they mean, otherwise 
			                      // free just enteries[0] at the end.
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		SvREFCNT_dec( RETVAL );



awaBool
pruneLog ( self, older_than )
	Aw::Admin::ServerClient self
	Aw::Date older_than

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awPruneServerLog ( self->server_client, *older_than );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



int
getActivePort ( self, ... )
	Aw::Admin::ServerClient self

	ALIAS:
		Aw::Admin::ServerClient::getVersionNumber    = 1
		Aw::Admin::ServerClient::getProcessRunStatus = 2

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix == 2)
		  ? awGetServerProcessRunStatus ( (char *)SvPV( ST(1), PL_na ), &RETVAL )
		  : (ix)
		    ? awGetServerVersionNumber  ( self->server_client, &RETVAL )
		    : awGetServerActivePort     ( self->server_client, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
startProcess ( ... )

	CODE:
		if (gErrMsg != NULL)
			Safefree(gErrMsg);

		gErr     = AW_NO_ERROR;
		gErrMsg  = NULL;
		gErrCode = 0x0;
		sv_setpv ( perl_get_sv("@",0), "" );

		gErr = awStartServerProcess ( (char *)SvPV( ST(items-1), PL_na ) );

		if (items-1) 
			AWXS_SERVERCLIENT(0)->err = gErr;

		AWXS_CHECKSETERROR_RETURN

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
stopProcess ( self )
	Aw::Admin::ServerClient self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awStopServerProcess  ( self->server_client );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
createBroker ( self, broker_name, description, is_default )
	Aw::Admin::ServerClient self
	char * broker_name
	char * description
	awaBool is_default

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awCreateBroker ( self->server_client, broker_name, description, (BrokerBoolean) is_default );

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



AV *
getBrokersRef ( self )
	Aw::Admin::ServerClient self

	PREINIT:
		int n;
		BrokerInfo * broker_infos;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetServerBrokers ( self->server_client, &n, &broker_infos );

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		int i;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			if ( broker_infos[i].territory_name )
				hv_store ( hv, "territory_name", 14, newSVpv ( broker_infos[i].territory_name, 0 ), 0 );
			hv_store ( hv, "broker_host", 11, newSVpv ( broker_infos[i].broker_host, 0 ), 0 );
			hv_store ( hv, "broker_name", 11, newSVpv ( broker_infos[i].broker_name, 0 ), 0 );

			if ( broker_infos[i].description )
				hv_store ( hv, "description", 11, newSVpv ( broker_infos[i].description, 0 ), 0 );
			
			av_push( RETVAL, newRV_noinc((SV*) hv) );
		
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( broker_infos );
		SvREFCNT_dec( RETVAL );



awaBool
registerConnectionCallback ( self, method, client_data )
	Aw::Admin::ServerClient self
	char * method
	SV * client_data

	PREINIT:
		xsCallBackStruct * cb;

	CODE:
		AWXS_CLEARERROR
		
		cb = (xsCallBackStruct *) malloc ( sizeof (xsCallBackStruct) );
		cb->self   = ST(0);
		cb->data   = client_data;
		cb->id     = 0;
		cb->method = strdup ( method );

		gErr = self->err = awRegisterServerConnectionCallback ( self->server_client, BrokerServerConnectionCallbackFunc, cb );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



Aw::Event
getStats ( self )
	Aw::Admin::ServerClient self

	ALIAS:
		Aw::Admin::ServerClient::getUsageStats = 1
	
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
		  ? awGetServerStats      ( self->server_client, &RETVAL->event )
		  : awGetServerUsageStats ( self->server_client, &RETVAL->event )
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



char *
getHostName ( self )
	Aw::Admin::ServerClient self

	ALIAS:
		Aw::Admin::ServerClient::getDefaultBrokerName = 1
		Aw::Admin::ServerClient::getDescription       = 2
		Aw::Admin::ServerClient::getLicense           = 3
		Aw::Admin::ServerClient::getVersion           = 4

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= ( ix == 4 )
		  ? awGetServerVersion ( self->server_client, &RETVAL )
		  : ( ix > 3 )
		    ? ( ix == 3 )
		      ? awGetServerLicense ( self->server_client, &RETVAL )
		      : awGetServerDescription ( self->server_client, &RETVAL )
		    : ( ix ) 
		      ? awGetServerDefaultBrokerName ( self->server_client, &RETVAL )
		      : awGetServerClientHostName ( self->server_client, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setDefaultBrokerName ( self, string )
	Aw::Admin::ServerClient self
	char * string

	ALIAS:
		Aw::Admin::ServerClient::setDescription = 1
		Aw::Admin::ServerClient::setLicense     = 2

	CODE:
		AWXS_CLEARERROR

		gErr = self->err 
		= ( ix )
		  ? (ix-1)
		    ? awSetServerLicense ( self->server_client, string )
		    : awSetServerDescription ( self->server_client, string )
		  : awSetServerDefaultBrokerName ( self->server_client, string )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( gErr == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



#===============================================================================

MODULE = Aw::Admin		PACKAGE = Aw::Admin::Client

#===============================================================================


awaBool
createClient ( self, client_id, client_group, app_name, user_name, authenticator_name, ... )
	Aw::Admin::Client self
	char * client_id
	char * client_group
	char * app_name
	char * user_name
	char * authenticator_name


	PREINIT:
		BrokerConnectionDescriptor myDesc = NULL;

	CODE:
		if ( user_name[0] == '\0' )
			user_name = NULL;
		if ( authenticator_name[0] == '\0' )
			authenticator_name = NULL;

		if ( items == 7 && ( sv_isobject(ST(6)) && (SvTYPE(SvRV(ST(6))) == SVt_PVMG) ) )
			myDesc = AWXS_BROKERCONNECTIONDESC(6)->desc;

		gErr = self->err = awCreateClient ( self->client, client_id, client_group, app_name, user_name, authenticator_name, myDesc );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
destroyBroker ( self )
	Aw::Admin::Client self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awDestroyBroker ( self->client );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
releaseChangeLock ( self )
	Aw::Admin::Client self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awReleaseBrokerChangeLock ( self->client );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
createClientGroup ( self, client_group_name, life_cycle, storage_type )
	Aw::Admin::Client self
	char * client_group_name
	int life_cycle
	int storage_type

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awCreateClientGroup ( self->client, client_group_name, life_cycle, storage_type );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char **
getClientGroupNamesRef ( self )
	Aw::Admin::Client self

	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientGroupNames ( self->client, &count_charPtrPtr, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



char **
getClientGroupCanPublishListRef ( self, string )
	Aw::Admin::Client self
	char * string

	ALIAS:
		Aw::Admin::Client::getClientGroupCanSubscribeListRef   = 1
		Aw::Admin::Client::getClientGroupsWhichCanPublishRef   = 2
		Aw::Admin::Client::getClientGroupsWhichCanSubscribeRef = 3
		Aw::Admin::Client::getClientIdsByClientGroupRef        = 4
		Aw::Admin::Client::getClientIdsWhichAreSubscribedRef   = 5

	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix>3)
		  ? (ix==5)
		    ? awGetClientIdsWhichAreSubscribed     ( self->client, string, &count_charPtrPtr, &RETVAL )
		    : awGetClientIdsByClientGroup          ( self->client, string, &count_charPtrPtr, &RETVAL )
		  : (ix>1)
		    ? (ix==3)
		      ? awGetClientGroupsWhichCanSubscribe ( self->client, string, &count_charPtrPtr, &RETVAL )
		      : awGetClientGroupsWhichCanPublish   ( self->client, string, &count_charPtrPtr, &RETVAL )
		    : (ix)
		      ? awGetClientGroupCanSubscribeList   ( self->client, string, &count_charPtrPtr, &RETVAL )
		      : awGetClientGroupCanPublishList     ( self->client, string, &count_charPtrPtr, &RETVAL )
		;

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



char **
getClientIdsRef ( self )
	Aw::Admin::Client self

	PREINIT:
		int count_charPtrPtr;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientIds ( self->client, &count_charPtrPtr, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
setClientGroupAccessLabelRequired ( self, string, ... )
	Aw::Admin::Client self
	char * string

	ALIAS:
		Aw::Admin::Client::setClientStateShareLimitById           = 1
		Aw::Admin::Client::setClientGroupRequiredEncryption       = 2
		Aw::Admin::Client::setClientLastPublishSequenceNumberById = 3

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix>1)
		  ? (ix==3)
		    ? awSetClientLastPublishSequenceNumberById ( self->client, string, awBrokerLongFromString ( longlong_to_string ( SvLLV (ST(2)) ) ) )
		    : awSetClientGroupRequiredEncryption  ( self->client, string, (int)SvIV(ST(2)) )
		  : (ix)
                    ? awSetClientStateShareLimitById      ( self->client, string, (int)SvIV(ST(2)) )
		    : awSetClientGroupAccessLabelRequired ( self->client, string, (BrokerBoolean)SvIV(ST(2)) )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setClientGroupDescription ( self, client_group_name, description )
	Aw::Admin::Client self
	char * client_group_name
	char * description

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetClientGroupDescription ( self->client, client_group_name, description );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setClientGroupCanPublishList ( self, client_group_name, event_type_names )
	Aw::Admin::Client self
	char * client_group_name
	char ** event_type_names

	ALIAS:
		Aw::Admin::Client::setClientGroupCanSubscribeList = 1

	PREINIT:
		int n;

	CODE:
		AWXS_CLEARERROR

		n = av_len ( (AV*)SvRV( ST(2) ) ) + 1;

		gErr = self->err
		= (ix)
		  ? awSetClientGroupCanSubscribeList ( self->client, client_group_name, n, event_type_names )
		  : awSetClientGroupCanPublishList   ( self->client, client_group_name, n, event_type_names )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( event_type_names );



awaBool
setBrokerDescription ( self, description )
	Aw::Admin::Client self
	char * description

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetBrokerDescription ( self->client, description );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
destroyClientById ( self, client_ids )
	Aw::Admin::Client self

	ALIAS:
		Aw::Admin::Client::disconnectClientById = 1
	
	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
			char ** client_ids  = XS_unpack_charPtrPtr ( ST(1) );
			int n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;
			int i;

			if (ix)
				for ( i = 0; i<n; i++ )
		    			awDisconnectClientById ( self->client, client_ids[i] );
			else
				for ( i = 0; i<n; i++ )
			  		awDestroyClientById ( self->client, client_ids[i] );

			XS_release_charPtrPtr ( client_ids );
		}
		else {
			if (ix)
				awDisconnectClientById ( self->client, SvPV( ST(1), PL_na ) );
			else
				awDestroyClientById    ( self->client, SvPV( ST(1), PL_na ) );
		}

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
disconnectClientSessionById ( self, client_id, session_id )
	Aw::Admin::Client self
	char * client_id
	int session_id

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awDisconnectClientSessionById ( self->client, client_id, session_id );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
doesSubscriptionExistById ( self, client_id, event_type_name, filter )
	Aw::Admin::Client self
	char * client_id
	char * event_type_name
	char * filter

	PREINIT:
		BrokerBoolean bRV;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awDoesSubscriptionExistById ( self->client, client_id, event_type_name, filter, &bRV );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = (awaBool)bRV;

	OUTPUT:
	RETVAL



awaBool
createClientSubscriptionById ( self, client_id, subs )
	Aw::Admin::Client self
	char * client_id

	ALIAS:  # plurals for java compatibility
		Aw::Admin::Client::destroyClientSubscriptionById  = 1
		Aw::Admin::Client::createClientSubscriptionsById  = 2
		Aw::Admin::Client::destroyClientSubscriptionsById = 3

	PREINIT:
		int i, n = 0;
		BrokerSubscription * subs;

	CODE:
		AWXS_CLEARERROR


		if ( SvTYPE(SvRV(ST(2))) == SVt_PVAV ) {
			AV * av = (AV*)SvRV( ST(1) );
			SV ** sv;

			n = av_len ( av ) + 1;

			subs = (BrokerSubscription *)safemalloc ( sizeof(BrokerSubscription)*n );

			for ( i = 0; i < n; i++ ) {
				sv = av_fetch ( av, i, 0 );
				memcpy ( &subs[i], ((BrokerSubscription *)SvIV((SV*)SvRV( *sv ))), sizeof(BrokerSubscription) );
			}

			gErr = self->err
			= (ix%2)
			  ? awDestroyClientSubscriptionsById ( self->client, client_id, n, subs )
			  : awCreateClientSubscriptionsById  ( self->client, client_id, n, subs )
			;
		}
		else {
			subs = AWXS_BROKERSUBSCRIPTION(2);

			gErr = self->err
			= (ix%2)
			  ? awDestroyClientSubscriptionById ( self->client, client_id, subs )
			  : awCreateClientSubscriptionById  ( self->client, client_id, subs )
			;
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		if ( n )
			for ( i = 0; i < n; i++ )
				Safefree ( &subs[i] );



AV *
getClientSubscriptionsByIdRef ( self, client_id )
	Aw::Admin::Client self
	char * client_id

	PREINIT:
		int n;
		BrokerSubscription * subs;

	CODE:
		AWXS_CLEARERROR
		
		gErr = self->err = awGetClientSubscriptionsById ( self->client, client_id, &n, &subs );

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
		free (subs);
		SvREFCNT_dec( RETVAL );



Aw::Event
getBrokerStats ( self, ... )
	Aw::Admin::Client self

	ALIAS:
		Aw::Admin::Client::getClientInfosetById     = 1
		Aw::Admin::Client::getClientGroupStats      = 2
		Aw::Admin::Client::getClientStatsById       = 3
		Aw::Admin::Client::getEventTypeStats        = 4
		Aw::Admin::Client::getTerritoryGatewayStats = 5
		Aw::Admin::Client::getTerritoryStats        = 6

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
		 = (ix>4)
		   ? (ix==6)
		     ? awGetTerritoryStats        ( self->client, &RETVAL->event )                               // 6
		     : awGetTerritoryGatewayStats ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->event ) // 5
		   : (ix>2)
		     ? (ix==4)
		       ? awGetEventTypeStats      ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->event ) // 4
		       : awGetClientStatsById     ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->event ) // 3
		     : (ix==2)
		       ? awGetClientGroupStats    ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->event ) // 2
		       : (ix)
		         ? awGetClientInfosetById ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->event ) // 1
		         : awGetBrokerStats       ( self->client, &RETVAL->event )                               // 0
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



awaBool
setEventTypeInfoset ( self, event_type_name, infosets, ... )
	Aw::Admin::Client self
	char * event_type_name

	ALIAS:  # java compatibility
		Aw::Admin::Client::setEventTypeInfosets = 1

	PREINIT:
		int i, n = 0;
		BrokerEvent * infosets;

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(2))) == SVt_PVAV ) {
			AV * av = (AV*)SvRV( ST(2) );
			SV ** sv;

			n = av_len ( av ) + 1;

			infosets = (BrokerEvent *) safemalloc ( sizeof(BrokerEvent)*n );

			for ( i = 0; i < n; i++ ) {
				sv = av_fetch ( av, i, 0 );
				memcpy ( &infosets[i], ( (xsBrokerEvent *)SvIV((SV*)SvRV( *sv )) )->event, sizeof(BrokerEvent) );
			}

			gErr = self->err = awSetEventTypeInfosets ( self->client, event_type_name, n, infosets );
		}
		else {
			char * infoset_name = NULL;

			infosets =& AWXS_BROKEREVENT(items-1)->event;

			if ( items == 4 )
				infoset_name = (char *)SvPV( ST(3), PL_na );

			gErr = self->err = awSetEventTypeInfoset ( self->client, event_type_name, infoset_name, *infosets );
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		if ( n )
			for ( i = 0; i < n; i++ )
				Safefree ( infosets[i] );



awaBool
setClientInfosetById ( self, client_id, infoset )
	Aw::Admin::Client self
	char * client_id
	Aw::Event infoset


	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetClientInfosetById ( self->client, client_id, infoset->event );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
destroyClientGroup ( self, event_type_names, force_destroy )
	Aw::Admin::Client self
	awaBool force_destroy

	ALIAS:
		Aw::Admin::Client::destroyEventType  = 1
		Aw::Admin::Client::destroyEventTypes = 2

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
			char ** event_type_names  = XS_unpack_charPtrPtr ( ST(2) );
			int n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;
			int i;

			if ( ix )
				gErr = self->err = awDestroyEventTypes ( self->client, n, event_type_names, (BrokerBoolean) force_destroy );
			else {
				for ( i = 0; i<n; i++ )
			  		awDestroyClientGroup ( self->client, event_type_names[i], (BrokerBoolean) force_destroy );
			}

			XS_release_charPtrPtr ( event_type_names );
		}
		else {
			gErr = self->err
			= (ix)
			  ? awDestroyEventType   ( self->client, SvPV( ST(1), PL_na ), (BrokerBoolean) force_destroy )
			  : awDestroyClientGroup ( self->client, SvPV( ST(1), PL_na ), (BrokerBoolean) force_destroy )
			;
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



Aw::Admin::TypeDef
_getEventAdminTypeDef ( self, event_type_name )
	Aw::Admin::Client self
	char * event_type_name

	PREINIT:
		char CLASS[] = "Aw::Admin::TypeDef";

	CODE:
		AWXS_CLEARERROR

		RETVAL = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new Aw::Admin::TypeDef" );
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

		gErr = self->err = awGetEventAdminTypeDef ( self->client, event_type_name, &RETVAL->type_def );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



AV *
getEventAdminTypeDefsRef ( self, event_type_names )
	Aw::Admin::Client self
	char ** event_type_names

	PREINIT:
		int n;
		BrokerAdminTypeDef * type_defs;

	CODE:
		AWXS_CLEARERROR

		n = av_len ( (AV*)SvRV( ST(1) ) ) + 1;

		gErr = self->err = awGetEventAdminTypeDefs ( self->client, &n, event_type_names, &type_defs );

		AWXS_CHECKSETERROR_RETURN
		
		{
		SV *sv;
		int i;
		xsBrokerAdminTypeDef * type_def;

			RETVAL = newAV();

			for ( i = 0; i<n; i++ ) {
				sv = sv_newmortal();

				type_def = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );

				if ( type_def == NULL ) {
					setErrMsg ( &gErrMsg, 1, "unable to malloc new client" );
#ifdef AWXS_WARNS
					if ( gWarn )
						warn ( gErrMsg );
#endif /* AWXS_WARNS */
					XSRETURN_UNDEF;
				}
				/* initialize the error cleanly */
				type_def->err      =  AW_NO_ERROR;
				type_def->errMsg   =  NULL;
				type_def->Warn     =  gWarn;
				type_def->type_def =  type_defs[i];

				sv_setref_pv( sv, "Aw::Admin::TypeDef", (void*)type_def );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}

		}


	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( event_type_names );
		SvREFCNT_dec( RETVAL );



AV *
getEventAdminTypeDefsByScopeRef ( self, scope_name )
	Aw::Admin::Client self
	char * scope_name

	PREINIT:
		int n;
		BrokerAdminTypeDef * type_defs;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetEventAdminTypeDefsByScope ( self->client, scope_name, &n, &type_defs );

		AWXS_CHECKSETERROR_RETURN
		
		{
		SV *sv;
		int i;
		xsBrokerAdminTypeDef * type_def;

			RETVAL = newAV();

			for ( i = 0; i<n; i++ ) {
				sv = sv_newmortal();

				type_def = (xsBrokerAdminTypeDef *)safemalloc ( sizeof(xsBrokerAdminTypeDef) );

				if ( type_def == NULL ) {
					setErrMsg ( &gErrMsg, 1, "unable to malloc new client" );
#ifdef AWXS_WARNS
					if ( gWarn )
						warn ( gErrMsg );
#endif /* AWXS_WARNS */
					XSRETURN_UNDEF;
				}
				/* initialize the error cleanly */
				type_def->err      =  AW_NO_ERROR;
				type_def->errMsg   =  NULL;
				type_def->Warn     =  gWarn;
				type_def->type_def =  type_defs[i];

				sv_setref_pv( sv, "Aw::Admin::TypeDef", (void*)type_defs );
				SvREFCNT_inc(sv);
				av_push( RETVAL, sv );
			}	
		}

	OUTPUT:
		RETVAL

	CLEANUP:
		SvREFCNT_dec( RETVAL );



awaBool
setEventAdminTypeDef ( self, typeDefs )
	Aw::Admin::Client self

	ALIAS:  # java compatibility
		Aw::Admin::Client::setEventAdminTypeDefs = 1

	PREINIT:
		int i, n = 0;
		BrokerAdminTypeDef * typeDefs;

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(1))) == SVt_PVAV ) {
			AV * av = (AV*)SvRV( ST(1) );
			SV ** sv;

			n = av_len ( av ) + 1;
			typeDefs = (BrokerAdminTypeDef *)safemalloc ( sizeof(BrokerAdminTypeDef)*n );

			for ( i = 0; i < n; i++ ) {
				sv = av_fetch ( av, i, 0 );
				memcpy ( &typeDefs[i], ( (xsBrokerAdminTypeDef *)SvIV((SV*)SvRV( *sv )) )->type_def, sizeof(BrokerAdminTypeDef) );
			}

			gErr = self->err = awSetEventAdminTypeDefs ( self->client, n, typeDefs );
		}
		else {
			typeDefs =& AWXS_BROKERADMINTYPEDEF(1)->type_def;
			gErr = self->err = awSetEventAdminTypeDef ( self->client, AWXS_BROKERADMINTYPEDEF(1)->type_def );
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		if ( n )
			for ( i = 0; i < n; i++ )
				Safefree ( typeDefs[i] );



awaBool
destroyEventTypeInfosets ( self, event_type_name, infoset_names )
	Aw::Admin::Client self
	char * event_type_name

	ALIAS:  # java compatibility
		Aw::Admin::destroyEventTypeInfosets = 1

	CODE:
		AWXS_CLEARERROR

		if ( SvTYPE(SvRV(ST(2))) == SVt_PVAV ) {
			char ** infoset_names  = XS_unpack_charPtrPtr ( ST(2) );
			int n = av_len ( (AV*)SvRV( ST(2) ) ) + 1;

			gErr = self->err = awDestroyEventTypeInfosets ( self->client, event_type_name, n, infoset_names );

			XS_release_charPtrPtr ( infoset_names );
		}
		else {
			gErr = self->err = awDestroyEventTypeInfoset ( self->client, event_type_name, (char *)SvPV( ST(1), PL_na ) );
		}

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setTerritoryGatewaySecurity ( self, territory_name, auth_type, encrypt_level )
	Aw::Admin::Client self
	char * territory_name
	int auth_type
	int encrypt_level

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetTerritoryGatewaySecurity ( self->client, territory_name, auth_type, encrypt_level );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



char *
getBrokerDescription ( self )
	Aw::Admin::Client self

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetBrokerDescription ( self->client, &RETVAL );

		AWXS_CHECKSETERROR_RETURN

	OUTPUT:
	RETVAL



awaBool
leaveTerritory ( self, number, ... )
	Aw::Admin::Client self
	int number

	ALIAS:
		Aw::Admin::Client::setTerritorySecurity = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awLeaveTerritory       ( self->client, number, (BrokerBoolean)SvIV(ST(2)) )
		  : awSetTerritorySecurity ( self->client, number, (int)SvIV(ST(2)) )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



Aw::Admin::AccessControlList
getTerritoryACL ( self, ... )
	Aw::Admin::Client self

	ALIAS:
		Aw::Admin::Client::getClientGroupACL      = 1
		Aw::Admin::Client::getTerritoryGatewayACL = 2

	PREINIT:
		char CLASS[] = "Aw::Admin::AccessControlList";

	CODE:
		  
		AWXS_CLEARERROR

		RETVAL = (xsAccessControlList *)safemalloc ( sizeof(xsAccessControlList) );
		if ( RETVAL == NULL ) {
			setErrMsg ( &gErrMsg, 1, "unable to malloc new acl" );
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

		gErr = RETVAL->err
		= (ix-1)
		  ? awGetTerritoryGatewayACL ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->acl )
		  : (ix)
		    ? awGetClientGroupACL    ( self->client, (char *)SvPV( ST(1), PL_na ), &RETVAL->acl )
		    : awGetTerritoryACL      ( self->client, &RETVAL->acl )
		;

		if ( RETVAL->err != AW_NO_ERROR ) {
			setErrMsg ( &gErrMsg, 2, "unable to instantiate new Aw::Admin::AccessControlList %s", awErrorToCompleteString ( RETVAL->err ) );
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
setTerritoryACL ( self, acl )
	Aw::Admin::Client self
	Aw::Admin::AccessControlList acl

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awSetTerritoryACL ( self->client, acl->acl );

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
setClientGroupACL ( self, string, acl )
	Aw::Admin::Client self
	char * string
	Aw::Admin::AccessControlList acl

	ALIAS:
		Aw::Admin::Client::setTerritoryGatewayACL = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awSetTerritoryGatewayACL ( self->client, string, acl->acl )
		  : awSetClientGroupACL ( self->client, string, acl->acl )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
clearClientQueueById ( self, string )
	Aw::Admin::Client self
	char * string

	ALIAS:
		Aw::Admin::Client::destroyTerritoryGateway = 1
		Aw::Admin::Client::createTerritory         = 2

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? (ix-1)
		    ? awDestroyTerritoryGateway ( self->client, string )
		    : awCreateTerritory ( self->client, string )
		  : awClearClientQueueById ( self->client, string )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



awaBool
createTerritoryGateway ( self, string1, string2, ... )
	Aw::Admin::Client self
	char * string1
	char * string2

	ALIAS:
		Aw::Admin::Client::removeBrokerFromTerritory = 1

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awRemoveBrokerFromTerritory ( self->client, string1, string2 )
		  : awCreateTerritoryGateway ( self->client, string1, string2, (char *)SvPV ( ST(1), PL_na ) )
		;

		AWXS_CHECKSETERROR

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
	RETVAL



AV *
getBrokersInTerritoryRef ( self )
	Aw::Admin::Client self

	PREINIT:
		int n;
		BrokerInfo * broker_infos;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetBrokersInTerritory ( self->client, &n, &broker_infos );

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			hv_store ( hv, "territory_name", 14, newSVpv ( broker_infos[i].territory_name, 0 ), 0 );
			hv_store ( hv, "broker_host", 11, newSVpv ( broker_infos[i].broker_host, 0 ), 0 );
			hv_store ( hv, "broker_name", 11, newSVpv ( broker_infos[i].broker_name, 0 ), 0 );
			hv_store ( hv, "description", 11, newSVpv ( broker_infos[i].description, 0 ), 0 );
			
			av_push( RETVAL, newRV_noinc((SV*) hv) );

		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( broker_infos );
		SvREFCNT_dec( RETVAL );



AV *
getAllTerritoryGatewaysRef ( self )
	Aw::Admin::Client self

	ALIAS:
		Aw::Admin::Client::getLocalTerritoryGateways = 1

	PREINIT:
		int n;
		BrokerTerritoryGatewayInfo * infos;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err
		= (ix)
		  ? awGetLocalTerritoryGateways ( self->client, &n, &infos )
		  : awGetAllTerritoryGateways   ( self->client, &n, &infos )
		;

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;
		BrokerTerritoryGatewayInfo * info;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			info = (BrokerTerritoryGatewayInfo *)malloc ( sizeof(BrokerTerritoryGatewayInfo) );
			memcpy ( info, &infos[i], sizeof(BrokerTerritoryGatewayInfo) );

			hv_store ( hv, "_type",                      5, newSVpv ( "BrokerTerritoryGatewayInfo", 26 ), 0 );

			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)info );

			hv_store ( hv, "_info",                      5, sv, 0 );

			hv_store ( hv, "gateway_host_name",         17, newSVpv ( infos[i].gateway_host_name, 0 ), 0 );
			hv_store ( hv, "gateway_broker_name",       19, newSVpv ( infos[i].gateway_broker_name, 0 ), 0 );
			hv_store ( hv, "remote_territory_name",     21, newSVpv ( infos[i].remote_territory_name, 0 ), 0 );
			hv_store ( hv, "remote_host_name",          16, newSVpv ( infos[i].remote_host_name, 0 ), 0 );
			hv_store ( hv, "remote_broker_name",        18, newSVpv ( infos[i].remote_broker_name, 0 ), 0 );
			hv_store ( hv, "remote_broker_description", 25, newSVpv ( infos[i].remote_broker_description, 0 ), 0 );
			hv_store ( hv, "auth_type",                  9, newSViv ( (int)infos[i].auth_type ), 0 );
			hv_store ( hv, "encrypt_level",             13, newSViv ( (int)infos[i].encrypt_level ), 0 );
			hv_store ( hv, "is_local",                   8, newSViv ( (awaBool)infos[i].is_local ), 0 );
			hv_store ( hv, "is_complete",               11, newSViv ( (awaBool)infos[i].is_complete ), 0 );

			hv_store ( hv, "num_accessible_territories", 26, newSViv ( (int)infos[i].num_accessible_territories ), 0 );

			sv = sv_newmortal();
#ifdef PERL58_COMPAT
			XS_pack_charPtrPtr ( sv, infos[i].accessible_territories, infos[i].num_accessible_territories );
#else
			XS_pack_charPtrPtr ( sv, infos[i].accessible_territories );
#endif /* PERL58_COMPAT */
			hv_store ( hv, "accessible_territories", 22, sv, 0 );
			
			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
		
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( infos ); // free policy is not detailed in the C Platform Vol. 2 p 9-52
                                // nor in awadmin.h, assume it follows awGetBrokersInTerritory
	                        // check this, doh! we don't have any gateways...
		SvREFCNT_dec( RETVAL );



awaBool
setTerritoryGatewaySharedEventTypes ( self, territory_name, av )
	Aw::Admin::Client self
	char * territory_name
	AV * av
	

	PREINIT:
		int i, n;
		HV * hv;
		SV ** sv;
		BrokerSharedEventTypeInfo * infos;
	
	CODE:
		AWXS_CLEARERROR

		n     = av_len ( av ) + 1;
		infos = (BrokerSharedEventTypeInfo *)safemalloc ( sizeof(BrokerSharedEventTypeInfo)*n );	

		for ( i = 0; i < n; i++ ) {
			sv = av_fetch ( av, i, 0 );
			hv = (HV*)SvRV(*sv);

			sv                        = hv_fetch ( hv, "event_type_name",  15, 0 );
			infos[i].event_type_name  = (char *)SvPV(*sv, PL_na);

			sv                        = hv_fetch ( hv, "subscribe_filter", 16, 0 );
			infos[i].subscribe_filter = (char *)SvPV(*sv, PL_na);

			sv                        = hv_fetch ( hv, "accept_publish",   14, 0 );
			infos[i].accept_publish   = (BrokerBoolean)SvIV(*sv);

			sv                        = hv_fetch ( hv, "accept_subscribe", 16, 0 );
			infos[i].accept_subscribe = (BrokerBoolean)SvIV(*sv);

			sv                        = hv_fetch ( hv, "is_synchronized",  15, 0 );
			infos[i].is_synchronized   = (BrokerBoolean)SvIV(*sv);
		}

		AWXS_CHECKSETERROR

		gErr = self->err = awSetTerritoryGatewaySharedEventTypes ( self->client, territory_name, n, infos );

		RETVAL = ( self->err == AW_NO_ERROR ) ? awaFalse : awaTrue;

	OUTPUT:
		RETVAL

	CLEANUP:
		Safefree ( infos );



Aw::Info
_getClientInfoById ( self, client_id )
	Aw::Admin::Client self
	char * client_id

	PREINIT:
		int n;
		BrokerClientInfo * info;
		char blString[24];
		SV * sv;
		char CLASS[] = "Aw::Info";

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientInfoById ( self->client, client_id, &info );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		hv_store ( RETVAL, "_type",                  5, newSVpv ( "BrokerClientInfo", 16 ), 0 );

		sv = NEWSV ( 0, 0 );
		sv_setref_pv( sv, Nullch, (void*)info );

		hv_store ( RETVAL, "_info",                  5, sv, 0 );


		hv_store ( RETVAL, "client_id",              9, newSVpv ( (char *)info->client_id, 0 ), 0 );
		hv_store ( RETVAL, "client_group",          12, newSVpv ( (char *)info->client_group, 0 ), 0 );
		hv_store ( RETVAL, "app_name",               8, newSVpv ( (char *)info->app_name, 0 ), 0 );

		hv_store ( RETVAL, "shared_event_ordering", 21, newSVpv ( (char *)info->shared_event_ordering, 0 ), 0 );

		if ( info->user_name )
		hv_store ( RETVAL, "user_name",              9, newSVpv ( (char *)info->user_name, 0 ), 0 );
		if ( info->authenticator_name )
		hv_store ( RETVAL, "authenticator_name",    18, newSVpv ( (char *)info->authenticator_name, 0 ), 0 );


		hv_store ( RETVAL, "can_share_state",       15, newSViv ( (awaBool)info->can_share_state ), 0 );
		hv_store ( RETVAL, "state_share_limit",     17, newSViv ( (int)info->state_share_limit ), 0 );

		sv = sv_newmortal();
		sv_setuv ( sv, (UV)((short *)info->access_label) );
		SvREFCNT_inc(sv);

		hv_store ( RETVAL, "access_label",          12, sv, 0 );

		hv_store ( RETVAL, "num_sessions",          12, newSViv ( (int)info->num_sessions ), 0 );
		hv_store ( RETVAL, "num_access_labels",     17, newSViv ( (int)info->num_access_labels ), 0 );

		hv_store ( RETVAL, "high_pub_seqn", 13, 
			   ll_from_longlong ( longlong_from_string ( awBrokerLongToString( info->high_pub_seqn, blString ) ) ), 0 );

		if ( info->num_sessions )
			hv_store ( RETVAL, "sessions",    8, getBrokerClientSessions ( info->sessions, info->num_sessions ), 0 );

	OUTPUT:
	RETVAL



AV *
getClientInfosByIdRef ( self, client_ids, ... )
	Aw::Admin::Client self
	char ** client_ids

	PREINIT:
		int n;
		BrokerClientInfo ** infos;

	CODE:
		AWXS_CLEARERROR

		if ( items == 3 )
			n = (int)SvIV(ST(2));

		gErr = self->err = awGetClientInfosById ( self->client, &n, client_ids, &infos );

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;
		BrokerClientInfo * info;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			info = (BrokerClientInfo *)malloc ( sizeof(BrokerClientInfo) );
			memcpy ( info, &infos[i], sizeof(BrokerClientInfo) );


			hv_store ( hv, "_type",                  5, newSVpv ( "BrokerClientInfo", 16 ), 0 );

			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)info );

			hv_store ( hv, "_info",                  5, sv, 0 );

			hv_store ( hv, "client_id",              9, newSVpv ( (char *)infos[i]->client_id, 0 ), 0 );
			hv_store ( hv, "client_group",          12, newSVpv ( (char *)infos[i]->client_group, 0 ), 0 );
			hv_store ( hv, "app_name",               8, newSVpv ( (char *)infos[i]->app_name, 0 ), 0 );

			hv_store ( hv, "shared_event_ordering", 19, newSVpv ( (char *)infos[i]->shared_event_ordering, 0 ), 0 );

			if ( infos[i]->user_name )
				hv_store ( hv, "user_name",              9, newSVpv ( (char *)infos[i]->user_name, 0 ), 0 );
			if ( infos[i]->authenticator_name )
				hv_store ( hv, "authenticator_name",    18, newSVpv ( (char *)infos[i]->authenticator_name, 0 ), 0 );
			hv_store ( hv, "state_share_limit",     17, newSViv ( (int)infos[i]->state_share_limit ), 0 );
			hv_store ( hv, "num_access_labels",     17, newSViv ( (int)infos[i]->num_access_labels ), 0 );
			hv_store ( hv, "num_sessions",          12, newSViv ( (int)infos[i]->num_sessions ), 0 );

			hv_store ( hv, "sessions",              21, getBrokerClientSessions ( infos[i]->sessions, infos[i]->num_sessions ), 0 );
			

			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
		
		}

		}


	OUTPUT:
		RETVAL

	CLEANUP:
		XS_release_charPtrPtr ( client_ids );
		free ( infos );
		SvREFCNT_dec( RETVAL );



Aw::Info
_getClientGroupInfo ( self, client_group_name )
	Aw::Admin::Client self
	char * client_group_name

	PREINIT:
		int n;
		BrokerClientGroupInfo * info;
		SV * sv;
		char CLASS[] = "Aw::Info";

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientGroupInfo  ( self->client, client_group_name, &info );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		hv_store ( RETVAL, "_type",                  5, newSVpv ( "BrokerClientGroupInfo", 21 ), 0 );

		sv = NEWSV ( 0, 0 );
		sv_setref_pv( sv, Nullch, (void*)info );

		hv_store ( RETVAL, "_info",                  5, sv, 0 );

		hv_store ( RETVAL, "name",                   4, newSVpv ( (char*)info->name, 0 ), 0 );
		hv_store ( RETVAL, "description",           11, newSVpv ( (char*)info->description, 0 ), 0 );

		hv_store ( RETVAL, "life_cyle",              9, newSViv ( (int)info->life_cycle ), 0 );
		hv_store ( RETVAL, "storage_type",          12, newSViv ( (int)info->storage_type ), 0 );
		hv_store ( RETVAL, "required_encryption",   19, newSViv ( (int)info->required_encryption ), 0 );

		hv_store ( RETVAL, "access_label_required", 21, newSViv ( (BrokerBoolean)info->access_label_required ), 0 );
		hv_store ( RETVAL, "is_system_defined",     17, newSViv ( (BrokerBoolean)info->is_system_defined ), 0 );

	OUTPUT:
	RETVAL



Aw::Info
getTerritoryInfo ( self )
	Aw::Admin::Client self

	PREINIT:
		BrokerTerritoryInfo * info;
		SV * sv;
		char CLASS[] = "Aw::Info";

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetTerritoryInfo ( self->client, &info );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		hv_store ( RETVAL, "_type",           5, newSVpv ( "BrokerTerritoryInfo", 19 ), 0 );

		sv = NEWSV ( 0, 0 );
		sv_setref_pv( sv, Nullch, (void*)info );

		hv_store ( RETVAL, "_info",           5, sv, 0 );

		hv_store ( RETVAL, "territory_name", 14, newSVpv ( (char*)info->territory_name, 0 ), 0 );
		hv_store ( RETVAL, "auth_type",       9, newSViv ( (int)info->auth_type     ), 0 );
		hv_store ( RETVAL, "encrypt_level",  13, newSViv ( (int)info->encrypt_level ), 0 );

	OUTPUT:
	RETVAL



AV *
getClientGroupInfos ( self, client_group_names )
	Aw::Admin::Client self
	char ** client_group_names

	PREINIT:
		int n;
		BrokerClientGroupInfo ** infos;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetClientGroupInfos ( self->client, &n, client_group_names, &infos );

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;
		BrokerClientInfo * info;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			info = (BrokerClientInfo *)malloc ( sizeof(BrokerClientGroupInfo) );
			memcpy ( info, &infos[i], sizeof(BrokerClientGroupInfo) );

			hv_store ( hv, "_type",                  5, newSVpv ( "BrokerClientGroupInfo", 16 ), 0 );

			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)info );

			hv_store ( hv, "_info",                  5, sv, 0 );

			hv_store ( hv, "name",                   4, newSVpv ( (char *)infos[i]->name, 0 ), 0 );
			hv_store ( hv, "description",           11, newSVpv ( (char *)infos[i]->description, 0 ), 0 );

			hv_store ( hv, "life_cycle",            10, newSViv ( (int)infos[i]->life_cycle ), 0 );
			hv_store ( hv, "storage_type",          12, newSViv ( (int)infos[i]->storage_type ), 0 );
			hv_store ( hv, "required_encryption",   19, newSViv ( (int)infos[i]->required_encryption ), 0 );

			hv_store ( hv, "is_system_defined",     17, newSViv ( (awaBool)infos[i]->is_system_defined ), 0 );
			hv_store ( hv, "access_label_required", 21, newSViv ( (awaBool)infos[i]->access_label_required ), 0 );

			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
		
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( infos );	
		XS_release_charPtrPtr ( client_group_names );
		SvREFCNT_dec( RETVAL );



AV *
getTerritoryGatewaySharedEventTypesRef ( self, territory_name )
	Aw::Admin::Client self
	char * territory_name

	PREINIT:
		int n;
		BrokerSharedEventTypeInfo * infos;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetTerritoryGatewaySharedEventTypes( self->client, territory_name, &n, &infos);

		AWXS_CHECKSETERROR_RETURN

		{
		HV * hv;
		SV * sv;
		int i;
		BrokerSharedEventTypeInfo * info;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			info = (BrokerSharedEventTypeInfo *)malloc ( sizeof(BrokerSharedEventTypeInfo) );
			memcpy ( info, &infos[i], sizeof(BrokerSharedEventTypeInfo) );

			hv_store ( hv, "_type",             5, newSVpv ( "BrokerSharedEventTypeInfo", 25 ), 0 );

			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)info );

			hv_store ( hv, "_info",             5, sv, 0 );

			hv_store ( hv, "event_type_name",  15, newSVpv ( (char *)infos[i].event_type_name, 0 ), 0 );
			hv_store ( hv, "accept_publish",   14, newSViv ( (int)infos[i].accept_publish ), 0 );

			hv_store ( hv, "accept_subscribe", 16, newSViv ( (int)infos[i].accept_subscribe ), 0 );
			hv_store ( hv, "is_synchronized",  15, newSViv ( (int)infos[i].is_synchronized ), 0 );
			hv_store ( hv, "subscribe_filter", 16, newSVpv ( (char *)infos[i].subscribe_filter, 0 ), 0 );

			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
		
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( infos );	
		SvREFCNT_dec( RETVAL );



HV *
acquireChangeLock ( self )
	Aw::Admin::Client self

	PREINIT:
		SV *sv;
		BrokerChangeLockInfo * info;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awAcquireBrokerChangeLock ( self->client, &info );

		AWXS_CHECKSETERROR_RETURN

		RETVAL = newHV();

		hv_store ( RETVAL, "acquired",    8, newSViv ( (awaBool)info->acquired ), 0 );
		hv_store ( RETVAL, "client_id",   9, newSVpv ( (char*)info->client_id, 0 ), 0 );
		hv_store ( RETVAL, "session_id", 10, newSViv ( (int)info->session_id ), 0 );

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( info );	
		SvREFCNT_dec( RETVAL );



AV *
getActivityTraces ( self, seqn, msecs )
	Aw::Admin::Client self
	int seqn
	int msecs

	PREINIT:
		int n;
		BrokerTraceEvent * traces;
		char blString[24];

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awGetActivityTraces ( self->client, seqn, msecs, &n, &traces );

		AWXS_CHECKSETERROR_RETURN


		{
		HV * hv;
		SV * sv;
		int i;
		BrokerTraceEvent * trace;

		RETVAL = newAV();

		for ( i = 0; i < n; i++ ) {	
			hv = newHV();

			trace = (BrokerTraceEvent *)malloc ( sizeof(BrokerTraceEvent) );
			memcpy ( trace, &traces[i], sizeof(BrokerTraceEvent) );

			hv_store ( hv, "_type",             5, newSVpv ( "BrokerTraceEvent", 16 ), 0 );

			sv = NEWSV ( 0, 0 );
			sv_setref_pv( sv, Nullch, (void*)trace );

			hv_store ( hv, "_info",             5, sv, 0 );

			hv_store ( hv, "seqn",              4, newSViv ( (int)traces[i].seqn ), 0 );
			hv_store ( hv, "key",               3, newSViv ( (int)traces[i].key ), 0 );
			hv_store ( hv, "tag",               3, newSViv ( (int)traces[i].tag ), 0 );
			hv_store ( hv, "ip_address",       10, newSViv ( (int)traces[i].ip_address ), 0 );
			hv_store ( hv, "session_id",       10, newSViv ( (int)traces[i].session_id ), 0 );
			hv_store ( hv, "session_count",    13, newSViv ( (int)traces[i].session_count ), 0 );
			hv_store ( hv, "encrypt_level",    13, newSViv ( (int)traces[i].encrypt_level ), 0 );

			hv_store ( hv, "has_tag",           7, newSViv ( (awaBool)traces[i].has_tag ), 0 );
			hv_store ( hv, "is_authenticated", 16, newSViv ( (awaBool)traces[i].is_authenticated ), 0 );

			hv_store ( hv, "event_id", 9, 
				   ll_from_longlong ( longlong_from_string ( awBrokerLongToString( traces[i].event_id, blString ) ) ), 0 );

			hv_store ( hv, "dest_client_id",   14, newSVpv ( (char*)traces[i].dest_client_id, 0 ), 0 );
			hv_store ( hv, "broker_name",      11, newSVpv ( (char*)traces[i].broker_name, 0 ), 0 );
			hv_store ( hv, "broker_host",      11, newSVpv ( (char*)traces[i].broker_host, 0 ), 0 );
			hv_store ( hv, "app_name",          8, newSVpv ( (char*)traces[i].app_name, 0 ), 0 );
			hv_store ( hv, "client_group",     12, newSVpv ( (char*)traces[i].client_group, 0 ), 0 );
			hv_store ( hv, "event_type_name",  15, newSVpv ( (char*)traces[i].event_type_name, 0 ), 0 );
			av_push( RETVAL, sv_bless( newRV_noinc((SV*)hv), gv_stashpv("Aw::Info",1) ) );
		
		}

		}

	OUTPUT:
		RETVAL

	CLEANUP:
		free ( traces );	
		SvREFCNT_dec( RETVAL );



HV *
joinTerritory ( self, broker_host, broker_name )
	Aw::Admin::Client self
	char * broker_host
	char * broker_name

	PREINIT:
		BrokerJoinFailureInfo * failure_info = NULL;
		SV * sv;

	CODE:
		AWXS_CLEARERROR

		gErr = self->err = awJoinTerritory ( self->client, broker_host, broker_name, &failure_info );

		// return undef on success
		//
		if ( gErr == AW_NO_ERROR )
			XSRETURN_UNDEF;

		sv_setpv ( perl_get_sv("@",0), awErrorToCompleteString ( gErr ) );

		if ( failure_info == NULL )
			XSRETURN_UNDEF;

		RETVAL = newHV();

		sv = sv_newmortal();
#ifdef PERL58_COMPAT
		XS_pack_charPtrPtr ( sv, failure_info->event_type_names, failure_info->num_event_type_names );
#else
		XS_pack_charPtrPtr ( sv, failure_info->event_type_names );
#endif /* PERL58_COMPAT */
		hv_store ( RETVAL, "event_type_names",       16, sv, 0 );

		sv = sv_newmortal();
#ifdef PERL58_COMPAT
		XS_pack_charPtrPtr ( sv, failure_info->client_group_names, failure_info->num_client_group_names );
#else
		XS_pack_charPtrPtr ( sv, failure_info->client_group_names );
#endif /* PERL58_COMPAT */
		hv_store ( RETVAL, "client_group_names",     18, sv, 0 );

		hv_store ( RETVAL, "num_client_group_names", 22, newSViv ( (int)failure_info->num_client_group_names ), 0 );
		hv_store ( RETVAL, "num_event_type_names",   20, newSViv ( (int)failure_info->num_event_type_names ), 0 );


	OUTPUT:
		RETVAL

	CLEANUP:
		free ( failure_info );	
		SvREFCNT_dec( RETVAL );
