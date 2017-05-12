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

#include "TypeDefToHash.h"
#include "Util.h"

extern BrokerError gErr;


BrokerError
awxsSetHashFromTypeDef ( BrokerTypeDef type_def, HV * hv )
{
char **Keys;
int i, numKeys;
SV * sv;


	gErr = awGetTypeDefFieldNames ( type_def, NULL, &numKeys, &Keys );

	if ( gErr != AW_NO_ERROR )
		return ( gErr );

	for ( i = 0; i < numKeys; i++ ) {
		sv = getFieldTypeAsSV ( type_def, Keys[i] );

		if ( gErr != AW_NO_ERROR )
			break;

		hv_store ( hv, Keys[i], strlen ( Keys[i] ), sv, 0 );
	}

	free ( Keys );

	return ( gErr );

}



SV *
getFieldTypeFromHV ( BrokerTypeDef type_def, char * key )
{
HV * hv;
BrokerTypeDef newTypeDef;


	hv = newHV();

	gErr = awGetTypeDefFieldDef ( type_def, key, &newTypeDef );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	gErr = awxsSetHashFromTypeDef ( newTypeDef, hv );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	return ( newRV_noinc((SV*) hv) );
}



SV *
getFieldTypeFromAV ( BrokerTypeDef type_def, char * key )
{
AV * av;
int numKeys;
short type;


	av = newAV();
	key = stradd ( key, "[]" );
	gErr = awGetTypeDefFieldType ( type_def, key, &type );

	if ( gErr != AW_NO_ERROR ) {
		warn ( "ERROR %s", awErrorToCompleteString ( gErr ) );
		return ( Nullsv );
	}

	if ( type == FIELD_TYPE_STRUCT )
		av_push ( av, getFieldTypeFromHV (type_def, key) );
	else
		av_push( av, newSViv ( type ) );


	return ( newRV_noinc((SV*) av) );
}



SV *
getFieldTypeAsSV ( BrokerTypeDef type_def, char * key )
{
short type;


	gErr = awGetTypeDefFieldType ( type_def, key, &type );

	if ( gErr != AW_NO_ERROR )
		return ( Nullsv );

	if ( type == FIELD_TYPE_SEQUENCE )
		return ( getFieldTypeFromAV( type_def, key ) );

	if ( type == FIELD_TYPE_STRUCT )
		return ( getFieldTypeFromHV( type_def, key ) );

	return ( newSViv ( (int)type ) );
}
