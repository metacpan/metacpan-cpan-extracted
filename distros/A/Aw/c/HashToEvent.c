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


#include "awadapter.h"
#include "aweb.h"

#include "awxs.h"
#include "awxs.def"

#include "exttypes.h"

#include "Util.h"
#include "HashToEvent.h"

BrokerEvent hashToEvent ( BrokerEvent event, char * field_name, HV* hv );


BrokerError
awxsSetField ( BrokerEvent event, char * field_name, short field_type, SV* sv, BrokerEvent rootEvent, char * full_field_name )
{
BrokerError err = AW_NO_ERROR;


#if	AWXS_DEBUG
	printf ("    Hello from awxsSetField[%i]\n", field_type);
	if ( full_field_name )
		printf ( "     Struct Member: %s/%s\n", field_name, full_field_name );
	else
		printf ( "     Struct Member: %s/root\n", field_name );
#endif /* DEBUG */

	if ( sv == NULL )
		awSetField ( event, field_name, field_type, NULL );
	else switch ( field_type )
	  {
		case FIELD_TYPE_BOOLEAN:
			{
			BrokerBoolean value = (BrokerBoolean)SvUV( sv );
			err = awSetBooleanField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_BYTE:
			{
			BrokerByte value = (BrokerByte)SvUV( sv );
			err = awSetByteField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_CHAR:
			{
			char value = (unsigned char)*SvPV( sv, PL_na );
			err = awSetCharField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_DATE:
			{
			BrokerDate * date = (BrokerDate *)SvIV((SV*)SvRV( sv ));
			err = awSetDateField ( event, field_name, *date );
			}
			break;

		case FIELD_TYPE_DOUBLE:
			{
			double value = (double)SvNV( sv );
			err = awSetDoubleField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_FLOAT:
			{
			float value = (float)SvNV( sv );
			err = awSetFloatField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_INT:
			{
			int value = (int)SvIV( sv );
			err = awSetIntegerField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_LONG:
			{
			BrokerLong value;
			value = awBrokerLongFromString ( longlong_to_string ( SvLLV( sv ) ) );
			err = awSetLongField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_SHORT:
			{
			short value = (short)SvIV( sv );
			err = awSetShortField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_STRING:
			{
			char * value = (unsigned char *)SvPV( sv, PL_na );
			err = awSetStringField ( event, field_name, value );
			}
			break;

		case FIELD_TYPE_SEQUENCE:
			err = awxsSetSequenceField ( event, field_name, field_type, 0, 0, (AV*) SvRV(sv), rootEvent, full_field_name );
			break;

		case FIELD_TYPE_STRUCT:
			{
			BrokerEvent hEvent;
			if ( !rootEvent ) {
				rootEvent       = event;
				full_field_name = field_name;
			}

			hEvent
			= ( sv_isobject ( sv ) && sv_derived_from ( sv, "Aw::Event" ) )
			  ? ((xsBrokerEvent *)SvIV((SV*)SvRV( sv )))->event
			  : setStructFieldFromEvent ( event, full_field_name, (HV*)SvRV(sv), rootEvent )
			;
			err = awSetStructFieldFromEvent ( event, field_name, hEvent );
			}
			break;

		case FIELD_TYPE_UNICODE_CHAR:
			{
			char * utf8ch = (unsigned char *)SvPV( sv, PL_na );
			charUC *ucCh;
			ucCh = awUTF8toUC ( utf8ch );
			err  = awSetUCCharField ( event, field_name, ucCh[0] );
			}
			break;

		case FIELD_TYPE_UNICODE_STRING:
			{
			char * value = (unsigned char *)SvPV( sv, PL_na );
			err = awSetUCStringFieldAsUTF8 ( event, field_name, value );
			}
			break;

		default:
		case FIELD_TYPE_UNKNOWN:
#if 0
			errMsg = setErrMsg ( 1, "Unknown Field Type" );
#ifdef AWXS_WARNS
			if ( myWarn )
				warn ( errMsg );
#endif /* AWXS_WARNS */
#endif
			break;
		  }

#if    AWXS_DEBUG
	printf ("        GoodBye from awxsSetField\n" );
#endif /* DEBUG */

	return ( err );

}



BrokerError
awxsSetSequenceField ( BrokerEvent event, char * field_name, short field_type, int src_offset, int dest_offset, AV* av, BrokerEvent rootEvent, char * full_field_name )
{
int i, n;
SV ** sv;
void * value;
BrokerError err = AW_NO_ERROR;

int * iValue;
short * sValue;
float * fValue;
double * dValue;
unsigned char ** stValue;
charUC * ucValue;
charUC ** ucstValue;
BrokerByte * byValue;
BrokerLong * blValue;
BrokerDate * bdValue;
unsigned char * cValue;
BrokerBoolean * boValue;
BrokerEvent * eValue = NULL;
char * orig_field_name = NULL;
short seq_field_type;
int * ix;

#if    AWXS_DEBUG
	printf ("    Hello from awxsSetSequenceField[%i]\n", field_type);
#endif /* DEBUG */


	orig_field_name = strdup ( field_name );
	if ( field_type == FIELD_TYPE_SEQUENCE ) {
		field_name = stradd ( field_name, "[]" );
		if ( rootEvent )
		  {
			/*  Any time we "get" info it has to be from the original event
			 *  using the fully qualified structure path
                         */
			full_field_name = stradd ( full_field_name, "[]" );
#if    AWXS_DEBUG
			printf ( "  Has Root:  %s\n", full_field_name );
#endif /* DEBUG */
			awGetEventFieldType ( rootEvent, full_field_name, &seq_field_type);
		  }
		else
			awGetEventFieldType ( event, field_name, &seq_field_type);
		field_type = seq_field_type;
#if    AWXS_DEBUG
		printf ( "  %s => %i\n", field_name, field_type );
#endif /* DEBUG */
	}


	if ( av == NULL ) {
		err = awSetSequenceField ( event, orig_field_name, field_type, src_offset, dest_offset, 0, NULL );
		return ( err );
	}

	
	n  = av_len ( av ) + 1;

#if    AWXS_DEBUG
	printf ( "  %i elements of type %i\n", n, field_type );
#endif /* DEBUG */

	switch (field_type)
	  {
		case FIELD_TYPE_BOOLEAN:
			value = boValue = (BrokerBoolean *)safemalloc ( n * sizeof( BrokerBoolean ) );
			break;

		case FIELD_TYPE_BYTE:
	   		value = byValue = (BrokerByte *)safemalloc ( n * sizeof( BrokerByte ) );
			break;

		case FIELD_TYPE_CHAR:
			value = cValue = (unsigned char *)safemalloc ( n * sizeof( char ) );
			break;

		case FIELD_TYPE_INT:
			// printf ( "Mallocing %d Elements.\n", n );
			value = iValue = (int *)safemalloc ( (n+1) * sizeof( int ) );
			break;

		case FIELD_TYPE_LONG:
			value = blValue = (BrokerLong *)safemalloc ( n * sizeof( BrokerLong ) );
			break;

		case FIELD_TYPE_SHORT:
			value = sValue = (short *)safemalloc ( n * sizeof( short ) );
			break;

		case FIELD_TYPE_DATE:
	   		value = bdValue = (BrokerDate *)safemalloc ( n * sizeof( BrokerDate ) );
			break;

		case FIELD_TYPE_DOUBLE:
			value = dValue = (double *)safemalloc ( n * sizeof( double ) );
			break;

		case FIELD_TYPE_FLOAT:
			value = fValue = (float *)safemalloc ( n * sizeof( float ) );
			break;

		case FIELD_TYPE_STRING:
			value = stValue = (unsigned char **)safemalloc ( n * sizeof( char * ) );
			break;

		case FIELD_TYPE_STRUCT:
			eValue = (BrokerEvent *)safemalloc ( n * sizeof( BrokerEvent ) );
			break;

		case FIELD_TYPE_UNICODE_CHAR:
			value = ucValue = (charUC *)safemalloc ( n * sizeof( charUC ) );
			break;

		case FIELD_TYPE_UNICODE_STRING:
			value = ucstValue = (charUC **)safemalloc ( n * sizeof( charUC *) );
		default:
			break;
	  }



	for ( i=0; i<n; i++ ) {
		sv = av_fetch ( av, i, 0 );
		switch (field_type)
		  {
			case FIELD_TYPE_BOOLEAN:
				boValue[i] = (BrokerBoolean)SvUV(*sv);
				break;

			case FIELD_TYPE_BYTE:
		   		byValue[i] = (BrokerByte)SvUV(*sv);
				break;

			case FIELD_TYPE_CHAR:
				cValue[i] =* (unsigned char *)SvPV(*sv,PL_na);
				break;

			case FIELD_TYPE_INT:
				iValue[i] = (int)SvIV(*sv);
				break;

			case FIELD_TYPE_LONG:
				blValue[i] = awBrokerLongFromString ( longlong_to_string ( SvLLV(*sv) ) );
				break;

			case FIELD_TYPE_SHORT:
				sValue[i] = (short)SvIV(*sv);
				break;

			case FIELD_TYPE_DATE:
		   		bdValue[i] =* (BrokerDate *)SvIV((SV*)SvRV( *sv ));
				break;

			case FIELD_TYPE_DOUBLE:
				dValue[i] = (double)SvNV(*sv);
				break;

			case FIELD_TYPE_FLOAT:
				fValue[i] = (float)SvNV(*sv);
				break;

			case FIELD_TYPE_STRING:
				stValue[i] = (unsigned char *)SvPV(*sv,PL_na);
				break;

			case FIELD_TYPE_STRUCT:
				if ( SvROK( *sv ) && (SvTYPE(SvRV( *sv )) != SVt_PVHV) ) {
					printf ( "SV is NOT an HV is a %i!\n", SvTYPE( SvRV(*sv) ) );
				 
					exit (1);
				} 
				if ( !rootEvent ) {
					rootEvent       = event;
					full_field_name = field_name;
				}
				eValue[i]
				= ( sv_isobject ( *sv ) && sv_derived_from ( *sv, "Aw::Event" ) )
			  	  ? ((xsBrokerEvent *)SvIV((SV*)SvRV( *sv )))->event
			  	  : setStructFieldFromEvent ( event, full_field_name, (HV*)SvRV(*sv), rootEvent )
				;
				break;

			case FIELD_TYPE_UNICODE_CHAR:
				{
				char * utf8Ch;
				charUC * ucCh;
				utf8Ch = (unsigned char *)SvPV(*sv,PL_na);
				ucCh = awUTF8toUC( utf8Ch );
				ucValue[i] = ucCh[0];
				Safefree ( ucCh );
				}
				break;

			case FIELD_TYPE_UNICODE_STRING:
				ucstValue[i] = awUTF8toUC( (unsigned char *)SvPV(*sv,PL_na) );
				break;

			case FIELD_TYPE_SEQUENCE:
				return ( awxsSetSequenceField ( event, field_name, field_type, src_offset, dest_offset, av, rootEvent, full_field_name ) );
				break;

			default:
				break;
		  }
	}




	if ( field_type == FIELD_TYPE_STRUCT )
	  {
		err = awSetStructSeqFieldFromEvents ( event, orig_field_name, src_offset, dest_offset, n, eValue );

		for ( i = 0; i<n; i++ )
		 	awDeleteEvent ( eValue[i] );

		Safefree ( eValue );
	  }
	else
	  {
		err = awSetSequenceField ( event, orig_field_name, field_type, src_offset, dest_offset, n, value );
		Safefree ( value );
	  }


	return ( err );


}



BrokerEvent
hashToEvent ( BrokerEvent Event, char * field_name, HV* hv )
{
BrokerEvent * myStruct;
BrokerError err = AW_NO_ERROR;
int i, n;
char *key, *value;
HE *entry;


// printf ("      Hello from hashToEvent\n" );


	myStruct = (BrokerEvent *) safemalloc ( sizeof(BrokerEvent) );
	err = awNewBrokerEvent ( NULL, "Dumb::MiniMeEvent", myStruct );


	hv_iterinit ( hv );
	n = HvKEYS( hv );
	
// printf ("        n = %i\n", n );
					
	for ( i=0; i<n; i++ ) { 
		entry = hv_iternext ( hv );
		key   = HeKEY(entry);
		value = SvPV (HeVAL ( entry ), PL_na);
		// printf ( "      %s => %s\n", key, value );
		err   = awSetStringField ( *myStruct, key, value ); 
	}

// printf ("        GoodBye from hashToEvent\n" );
	return ( *myStruct );

}



BrokerEvent
setStructFieldFromEvent ( BrokerEvent event, char * full_field_name, HV * hv, BrokerEvent rootEvent )
{
int i, n;
HE *entry;
SV* value;
char * key;
short field_type;
BrokerError err = AW_NO_ERROR;
BrokerEvent * childEvent;
char * member_name;



	if ( rootEvent == NULL )
		rootEvent = event;

#if    AWXS_DEBUG
	printf ( "        Hello from setStructFieldFromEvent [%s]\n", full_field_name );
#endif /* DEBUG */


	childEvent = (BrokerEvent *) safemalloc ( sizeof(BrokerEvent) );
	err = awNewBrokerEvent ( NULL, "Dumb::MiniMeEvent", childEvent );

	full_field_name = stradd ( full_field_name, "." );


	hv_iterinit ( hv );
	n = HvKEYS( hv );


	for ( i=0; i<n; i++ )
	  {
		entry = hv_iternext ( hv );
		key   = HeKEY ( entry );
		value = HeVAL ( entry );
		
		member_name = stradd ( full_field_name, key );
		awGetEventFieldType ( rootEvent, member_name, &field_type );

		if ( field_type == FIELD_TYPE_SEQUENCE )
			awxsSetSequenceField ( *childEvent, key, field_type, 0, 0, (AV*)SvRV(value), rootEvent, member_name );
		else
			{
			if ( value == NULL )
				warn ( "      >>Field Value is NULL %s\n", key );
			else
				awxsSetField ( *childEvent, key, field_type, value, rootEvent, member_name );
			}

		Safefree ( member_name );
	  }


#if    AWXS_DEBUG
	printf ( "        GoodBye from setStructFieldFromEvent\n" );
#endif /* DEBUG */

	return ( *childEvent );
}



void
hashWalk ( HV * hv )
{
int i, n;
char *key, *value;
HE *entry;
SV *sv;

	printf ( "In hashWalk\n" );
	hv_iterinit ( hv );
	n = HvKEYS( hv );
	printf ( "n = %i\n", n );

	for ( i=0; i<n; i++ ) { 
		entry = hv_iternext ( hv );
		key   = HeKEY(entry);
		printf ( "  %s => ", key );
		sv = HeVAL ( entry );
		if ( SvROK( sv ) && (SvTYPE(SvRV( sv )) == SVt_PVHV) )
		  hashWalk ( (HV*)SvRV(sv) );	
		else
		  value = SvPV ( sv, PL_na);
		printf ( "  %s\n", value );
	}


}



BrokerError
awxsSetEventFromHash ( BrokerEvent event, HV * hv )
{
int i, n;
HE *entry;
SV* value;
char * key;
short field_type;
BrokerError err = AW_NO_ERROR;



#if    AWXS_DEBUG
	printf ( "        Hello from setEventFromHash \n" );
#endif /* DEBUG */


	hv_iterinit ( hv );
	n = HvKEYS ( hv );

#if    AWXS_DEBUG
	printf ( "          %i Hash Elements\n", n );
#endif /* DEBUG */


	for ( i=0; i<n; i++ )
	  {
		entry = hv_iternext ( hv );
		key   = HeKEY ( entry );
		value = HeVAL ( entry );
		
		awGetEventFieldType ( event, key, &field_type );

		if ( field_type == FIELD_TYPE_SEQUENCE )
			err = awxsSetSequenceField ( event, key, field_type, 0, 0, (AV*)SvRV(value), NULL, NULL );
		else
			{
			if ( value == NULL )
				warn ( "      >>Field Value is NULL %s\n", key );
			else
				err = awxsSetField ( event, key, field_type, value, NULL, NULL );
			}

	  }


#if    AWXS_DEBUG
	printf ( "        GoodBye from setEventFromHash\n" );
#endif /* DEBUG */

	return ( err );
}
