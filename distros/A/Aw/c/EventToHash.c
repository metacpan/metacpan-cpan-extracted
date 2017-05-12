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


#include <awadapter.h>
#include <aweb.h>

#include <awxs.h>
#include <awxs.def>

#include "exttypes.h"

#include "EventToHash.h"

extern BrokerError gErr;


BrokerError
awxsSetHashFromEvent ( BrokerEvent event, HV * hv )
{
char **Keys;
int i, numKeys;
SV * sv;
BrokerBoolean isSet;


	gErr = awGetFieldNames (event, NULL, &numKeys, &Keys);

	if ( gErr != AW_NO_ERROR )
		return ( gErr );



	for ( i = 0; i < numKeys; i++ ) {
		/*
		 *  Don't even create a key if the field is unset.
		 */
		gErr = awIsEventFieldSet ( event, Keys[i], &isSet );
		if ( gErr != AW_NO_ERROR )
			break;
		if ( isSet == awaFalse )
			continue;

		sv = getSV ( event, Keys[i] );

		if ( gErr != AW_NO_ERROR )
			break;

		hv_store ( hv, Keys[i], strlen ( Keys[i] ), sv, 0 );
	}

	free ( Keys );

	return ( gErr );

}



SV *
getHV ( BrokerEvent event, char * key )
{
HV * hv;
BrokerEvent newEvent;


	hv = newHV();
	gErr = awGetStructFieldAsEvent ( event, key, &newEvent );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	awxsSetHashFromEvent ( newEvent, hv );

	free ( newEvent );

	return ( newRV_noinc((SV*) hv) );
}



SV *
_getAV ( BrokerEvent event, char * key, int offset, int max_n )
{
AV * av;
int i, numKeys;
short type;
void * seqValue;
SV * sv;


	av = newAV();
	gErr = awGetSequenceField ( event, key, offset, max_n, &type, &numKeys, &seqValue );

	if ( gErr != AW_NO_ERROR ) {
		warn ( "ERROR %s", awErrorToCompleteString ( gErr ) );
		return ( Nullsv );
	}

  	for ( i = 0; i < numKeys; i++ ) {
		sv = getValueI ( type, seqValue, i );
		av_push( av, sv );
	}

	free ( seqValue );

	return ( newRV_noinc((SV*) av) );
}



SV *
getSV ( BrokerEvent event, char * key )
{
SV * sv;
short type;
void * value;


	gErr = awGetEventFieldType ( event, key, &type );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	if ( type == FIELD_TYPE_SEQUENCE )
		return ( getAV( event, key ) );

	if ( type == FIELD_TYPE_STRUCT )
		return ( getHV( event, key ) );

	gErr = awGetField ( event, key, &type, &value );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	sv = getValue ( type, value );

	free ( value );

	return ( sv );
}



SV *
_getValue ( short type, void * value, int i, bool array )
{
SV * sv;

	switch ( type )
	  {
		/*
		 *  NOTE:  If there is later a problem using the void *
		 *  then the awGet<type>Field functions can be used in
		 *  these cases.
		 *
		 */
		case FIELD_TYPE_BOOLEAN:
			sv = boolSV ( ((BrokerBoolean *)value)[i] );
			break;

		case FIELD_TYPE_BYTE:
			sv = newSViv ( (IV)((BrokerByte*)value)[i]  );
			// sv = newSViv ( *(IV*)((BrokerByte*)value+i)  );
			break;

		case FIELD_TYPE_CHAR:
	  		sv = newSVpv ( (char*)value+i, 1 );
			break;

		case FIELD_TYPE_INT:
			sv = newSViv ( *(IV*)((int*)value+i)  );
			// sv = newSViv ( *((IV*)(&((int*)value)[i])) ); // indentical
			break;

		case FIELD_TYPE_LONG:
			{
			char blString[24];
	  		sv = ll_from_longlong ( longlong_from_string ( awBrokerLongToString( *((BrokerLong*)value), blString ) ) );
			}
			break;

		case FIELD_TYPE_SHORT:
			sv = sv_newmortal();
	  		sv_setuv ( sv, (UV)(((short *)value)[i]) );
			SvREFCNT_inc(sv);
			break;

		case FIELD_TYPE_DATE:
			sv = sv_newmortal();
			{
			BrokerDate * bd = (BrokerDate *)safemalloc ( sizeof (BrokerDate) );
			memcpy ( bd, ((BrokerDate*)value+i), sizeof(BrokerDate) );
			sv_setref_pv( sv, "Aw::Date", (void*)bd );
			}
			SvREFCNT_inc(sv);
			break;

		case FIELD_TYPE_DOUBLE:
			sv = newSVnv ( *((double*)value+i)  );
			break;

		case FIELD_TYPE_FLOAT:
			sv = newSVnv ( *((float*)value+i)  );
			break;

		case FIELD_TYPE_STRING:
			if (array)
	  			sv = newSVpv ( *(((char**)value)+i), 0 );
	  			// sv = newSVpv ( *(&((char**)value)[i]), 0 ); identical
			else
	  			sv = newSVpv ( (char*)value, 0 );
			break;

		case FIELD_TYPE_UNICODE_STRING:
			{
			char * utf8St;
			if (array)
				utf8St = awUCtoUTF8 ( ((charUC**)value)[i] );
			else
				utf8St = awUCtoUTF8 ( (charUC*)value );
  			sv = newSVpv ( utf8St, 0 );
			}
			break;

		case FIELD_TYPE_STRUCT:
			{
			HV * hv = newHV();
			awxsSetHashFromEvent ( ((BrokerEvent*)value)[i], hv );
			sv = newRV_noinc((SV*) hv);
			}
			break;

		case FIELD_TYPE_UNICODE_CHAR:
			{
			char * utf8Ch;
			charUC ucCh[2];
			ucCh[0] = ((charUC*)value)[i];
			ucCh[1] = (charUC)NULL;
			utf8Ch  = awUCtoUTF8 ( ucCh );
	  		sv = newSVpv ( utf8Ch, 0 );
			}
			break;
	  }


	return ( sv );
}
