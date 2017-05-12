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



#include <admin/awadmin.h>
#include <admin/awaccess.h>
#include <admin/awetadm.h>
#include <admin/awlog.h>
#include <admin/awserver.h>

#include <aweb.h>
#include <awadapter.h>
#include <awxs.h>
#include <admin/adminxs.h>
#include <admin/adminxs.def>

#include "Util.h"
#include "HashToTypeDef.h"



BrokerError
awxsSetFieldType ( BrokerAdminTypeDef type_def, char * field_name, SV * value )
{
BrokerError err = AW_NO_ERROR;
short field_type;


	field_type = (short)SvIV(value);

	err = awSetAdminTypeDefFieldType ( type_def, field_name, field_type, NULL );

	return ( err );
}



BrokerError
awxsSetSequenceFieldType ( BrokerAdminTypeDef type_def, char * field_name, AV* av )
{
BrokerError err = AW_NO_ERROR;
char * orig_field_name = NULL;
SV **value;


	field_name = stradd ( field_name, "[]" );

	value = av_fetch ( av, 0, 0 );

	if ( SvTYPE(*value) == SVt_RV && SvTYPE(SvRV(*value)) == SVt_PVHV )
		err = awxsSetStructFieldType ( type_def, field_name, (HV*)SvRV(*value) );
	else if ( sv_isobject(*value) && (SvTYPE(SvRV(*value)) == SVt_PVMG) )
		err = awxsSetFieldDef ( type_def, field_name, SvRV(*value) );
	else
		err = awxsSetFieldType ( type_def, field_name, *value );

	return ( err );
}



BrokerError
awxsSetStructFieldType ( BrokerAdminTypeDef type_def, char * field_name, HV* hv )
{
BrokerError err = AW_NO_ERROR;


	err = awSetAdminTypeDefFieldType ( type_def, field_name, FIELD_TYPE_STRUCT, NULL );

	if ( err == AW_NO_ERROR ) {
		field_name = stradd ( field_name, "." );

		err = awxsNavigateHash ( type_def, field_name, hv );
	}

	return ( err );
}



BrokerError
awxsSetFieldDef ( BrokerAdminTypeDef type_def, char * field_name, SV* object )
{
BrokerError err = AW_NO_ERROR;
xsBrokerAdminTypeDef * field_def;


	field_def = (xsBrokerAdminTypeDef *)SvIV(object);

	err = awSetAdminTypeDefFieldDef ( type_def, field_name, field_def->type_def );

	return ( err );
}



BrokerError
awxsSetEventTypeDefFromHash ( BrokerAdminTypeDef type_def, HV * hv )
{
BrokerError err = AW_NO_ERROR;
int testStorage;


	if ( awGetAdminTypeDefStorageType ( type_def, &testStorage ) == AW_NO_ERROR ) {
		  
	SV** value;
	int storage = AW_STORAGE_VOLATILE; // default

	value = hv_fetch ( hv, "_name", 5, 0 );
	if ( value != NULL )
		err = awSetAdminTypeDefTypeName ( type_def, (char *)SvPV(*value, PL_na) );

	value = hv_fetch ( hv, "_timeToLive",  11, 0 );
	if ( value != NULL )
		err = awSetAdminTypeDefTimeToLive  ( type_def, (int)SvIV(*value) );

	value = hv_fetch ( hv, "_storageType", 12, 0 );
	if ( value != NULL ) {
		int storage;
		if ( SvTYPE(*value) == SVt_PV ) {
		char * string = (char *)SvPV(*value, PL_na);

			if (! strcmp (string, "Persistent" ) )
				storage = AW_STORAGE_PERSISTENT;
			else if (! strcmp (string, "Guaranteed" ) )
				storage = AW_STORAGE_GUARANTEED;
		}
		else
			storage = (int)SvIV(*value);

		err = awSetAdminTypeDefStorageType ( type_def, storage );
		if ( err != AW_NO_ERROR )
			return ( err );
	}

	value = hv_fetch ( hv, "_description", 12, 0 );
	if ( value != NULL )
		err = awSetAdminTypeDefDescription ( type_def, (char *)SvPV(*value, PL_na) );


	}

	err = awxsNavigateHash ( type_def, NULL, hv );
	return ( err );
}



BrokerError
awxsNavigateHash ( BrokerAdminTypeDef type_def, char * root_field_name, HV * hv )
{
int i, n;
HE *entry;
SV* value;
char * key;
char * field_name = NULL;
BrokerError err = AW_NO_ERROR;



#if    AWXS_DEBUG
	printf ( "        Hello from awxsSetEventTypeDefFromHash \n" );
#endif /* DEBUG */


	hv_iterinit ( hv );
	n = HvKEYS ( hv );

#if    AWXS_DEBUG
	printf ( "          %i Hash Elements\n", n );
#endif /* DEBUG */


	for ( i=0; i<n; i++ )
	  {
		if ( err != AW_NO_ERROR )
			return ( err );

		entry = hv_iternext ( hv );
		key   = HeKEY ( entry );
		value = HeVAL ( entry );

		if ( key[0] == '_' )
			continue;

		field_name = ( root_field_name == NULL ) ? key : stradd ( root_field_name, key );
		
		if ( value == NULL )
			warn ( "      >>Field Defintion for %s is NULL, skipped.\n", key );
		else if ( SvTYPE(value) == SVt_RV ) {
			if ( SvTYPE(SvRV(value)) == SVt_PVAV )
				err = awxsSetSequenceFieldType ( type_def, field_name, (AV*)SvRV(value) );
			else if ( SvTYPE(SvRV(value)) == SVt_PVHV )
				err = awxsSetStructFieldType   ( type_def, field_name, (HV*)SvRV(value) );
			else if ( sv_isobject(value) && (SvTYPE(SvRV(value)) == SVt_PVMG) )
				err = awxsSetFieldDef ( type_def, field_name, SvRV(value) );
			else
				warn ( "      >>Unknown reference value for %s, skipped.\n", key );
		}
		// the below is required, for reasons unknown, in the perl debugger:
		else if ( sv_isobject(value) && (SvTYPE(value) == SVt_PVMG) )
			err = awxsSetFieldDef ( type_def, field_name, SvRV(value) );
		else
			err = awxsSetFieldType ( type_def, field_name, value );

		field_name = root_field_name;
	  }


#if    AWXS_DEBUG
	printf ( "        GoodBye from setEventTypeDefFromHash\n" );
#endif /* DEBUG */

	return ( err );
}
