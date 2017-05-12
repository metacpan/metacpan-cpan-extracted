/*
$Header: /cvsroot/arsperl/ARSperl/ARS.xs,v 1.127 2011/07/29 13:05:27 tstapff Exp $

    ARSperl - An ARS v2 - v5 / Perl5 Integration Kit

    Copyright (C) 1995-2003
	Joel Murphy, jmurphy@acsu.buffalo.edu
        Jeff Murphy, jcmurphy@acsu.buffalo.edu

    This program is free software; you can redistribute it and/or modify
    it under the terms as Perl itself. 
    
    Refer to the file called "Artistic" that accompanies the source 
    distribution of ARSperl (or the one that accompanies the source 
    distribution of Perl itself) for a full description.
 
    Comments to:  arsperl@arsperl.org
                  (this is a *mailing list* and you must be
                   a subscriber before posting)


    http://www.arsperl.org

*/

#include "support.h"
#include "supportrev.h"
#include "supportrev_generated.h"

#if AR_EXPORT_VERSION < 3
#define AR_LIST_SCHEMA_ALL 1 
#endif


#if defined(ARSPERL_UNDEF_MALLOC) && defined(malloc)
 #undef malloc
 #undef calloc
 #undef realloc
 #undef free
#endif


MODULE = ARS		PACKAGE = ARS		PREFIX = ARS

PROTOTYPES: ENABLE

int
isa_int(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvIOKp(ST(0));
	}
	OUTPUT:
	RETVAL

int
isa_float(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvNOKp(ST(0));
	}
	OUTPUT:
	RETVAL

int
isa_string(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvPOKp(ST(0));
	}
	OUTPUT:
	RETVAL

HV *
ars_perl_qualifier(ctrl, in)
	ARControlStruct *	ctrl
	ARQualifierStruct *	in
	CODE:
	{
	  RETVAL = perl_qualifier(ctrl, in);
	}
	OUTPUT:
	RETVAL

ARQualifierStruct *
ars_qualifier_ptr(ctrl, in)
	ARControlStruct *	ctrl
	SV * in
	CODE:
	{
	  ARQualifierStruct *qual;
	  HV *h_dummy;
	  HV *h;
	  int rv = 0;	  

	  AMALLOCNN(qual, 1, ARQualifierStruct);
	  (void) ARError_reset();

	  if( SvTYPE(SvRV(in)) != SVt_PVHV ){
		  ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARQualifierStruct: not a hash value" );
		  RETVAL = NULL;
		  goto ars_qualifier_ptr_end;
	  }
	  h = (HV* ) SvRV((SV*) in);
	  if( ! SvTRUE(hv_scalar(h)) ){
		  RETVAL = qual;
		  goto ars_qualifier_ptr_end;
	  }

	  h_dummy = newHV();
	  SvREFCNT_inc( in );
	  hv_store( h_dummy, "_", 1, in, 0 );
	  rv += rev_ARQualifierStruct( ctrl, h_dummy, "_", qual );
	  hv_undef( h_dummy );

	  if( rv == 0 ){
		  RETVAL = qual;
	  }else{
		  ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL );
		  RETVAL = NULL;
		  FreeARQualifierStruct(qual, TRUE);
	  }
	  ars_qualifier_ptr_end:;
	}
	OUTPUT:
	RETVAL


ARQualifierStruct *
ars_LoadQualifier(ctrl,schema,qualstring,displayTag=NULL)
	ARControlStruct *	ctrl
	char *			schema
	char *			qualstring
	char *			displayTag
	CODE:
	{
		int                ret = 0;
		ARStatusList       status;
		ARQualifierStruct *qual;
		AMALLOCNN(qual, 1, ARQualifierStruct);
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
		ret = ARLoadARQualifierStruct(ctrl, schema, displayTag, qualstring, qual, &status);
#ifdef PROFILE
		((ars_ctrl *)ctrl)->queries++;
#endif
		if (! ARError( ret, status)) {
			RETVAL = qual;
		} else {
			RETVAL = NULL;
			FreeARQualifierStruct(qual, TRUE);
		}
	}
	OUTPUT:
	RETVAL

void
__ars_Termination()
	CODE:
	{
#if AR_EXPORT_VERSION <= 3
	  int          ret;
#endif
	  ARStatusList status;
	  
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION <= 3
	  ret = ARTermination(&status);
	  if (ARError( ret, status)) {
	    warn("failed in ARTermination\n");
	  }
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "__ars_Termination() is only available when compiled against ARS <= 3.2");
#endif
	}

void
__ars_init()
	CODE:
	{
#if AR_EXPORT_VERSION <= 3
	  int          ret;
#endif
	  ARStatusList status;
	
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION <= 3
	  ret = ARInitialization(&status);
	  if (ARError( ret, status)) {
	    croak("unable to initialize ARS module");
	  }
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "__ars_init() is only available when compiled against ARS <= 3.2");
#endif
	}

int
ars_APIVersion()
	CODE:
	{
		RETVAL = AR_CURRENT_API_VERSION;
	}
	OUTPUT:
	RETVAL

int
ars_SetServerPort(ctrl, name, port, progNum)
	ARControlStruct *	ctrl
	char *			name
	int			port
	int			progNum
	CODE:
	{
		int 		ret = 0;
		ARStatusList	status;

		RETVAL = 0;
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
#if AR_EXPORT_VERSION >= 4
		ret = ARSetServerPort(ctrl, name, port, progNum, &status);
		if (! ARError(ret, status)) {
			RETVAL = 1;
		}
#else
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
		"ars_SetServerPort() is only available in ARS >= 4.x");
#endif
	}
	OUTPUT:
	RETVAL

ARControlStruct *
ars_Login(server, username, password, lang=NULL, authString=NULL, tcpport=0, rpcnumber=0, ...)
	char *		server
	char *		username
	char *		password
	char *		lang
	char *		authString
	unsigned int  	tcpport
	unsigned int  	rpcnumber
	CODE:
	{
		int              ret = 0, s_ok = 1;
		int              staticParams = 7;
		ARStatusList     status;
		ARServerNameList serverList;
		ARControlStruct *ctrl;
#ifdef PROFILE
		struct timeval   tv;
#endif

		DBG( ("ars_Login(%s, %s, %s, %s, %s, %d, %d)\n", 
			SAFEPRT(server),
			SAFEPRT(username),
			SAFEPRT(password),
			SAFEPRT(lang),
			SAFEPRT(authString),
			tcpport,
			rpcnumber) 
		    );

		RETVAL = NULL;
		Zero(&status, 1, ARStatusList);
		Zero(&serverList, 1, ARServerNameList);
		(void) ARError_reset();  
#ifdef PROFILE
	  /* XXX
	     This is something of a hack... a safemalloc will always
	     complain about differing structures.  However, it's 
	     pretty deep into the code.  Perhaps a static would be cleaner?
	  */
		ctrl = (ARControlStruct *)MALLOCNN(sizeof(ars_ctrl));
		Zero(ctrl, 1, ars_ctrl);
		((ars_ctrl *)ctrl)->queries = 0;
		((ars_ctrl *)ctrl)->startTime = 0;
		((ars_ctrl *)ctrl)->endTime = 0;
#else
		DBG( ("safemalloc ARControlStruct\n") );
		ctrl = (ARControlStruct *)safemalloc(sizeof(ARControlStruct));
		/* DBG( ("malloc ARControlStruct\n") );
		ctrl = (ARControlStruct *)MALLOCNN(sizeof(ARControlStruct)); */
		Zero(ctrl, 1, ARControlStruct);
#endif
#ifdef PROFILE
		if (gettimeofday(&tv, 0) != -1)
			((ars_ctrl *)ctrl)->startTime = tv.tv_sec;
		else
			perror("gettimeofday");
#endif
		ctrl->cacheId = 0;
#if AR_EXPORT_VERSION >= 4
	 	ctrl->sessionId = 0;
#endif
		ctrl->operationTime = 0;
		strncpy(ctrl->user, username, sizeof(ctrl->user));
		ctrl->user[sizeof(ctrl->user)-1] = 0;
		strncpy(ctrl->password, password, sizeof(ctrl->password));
		ctrl->password[sizeof(ctrl->password)-1] = 0;
#ifndef AR_MAX_LOCALE_SIZE
		/* 6.0.1 and 6.3 are AR_EXPORT_VERSION = 8L but 6.3 does not
	         * contain the language field
	         */
		ctrl->language[0] = 0;
		if ( CVLD(lang) ) {
			strncpy(ctrl->language, lang, AR_MAX_LANG_SIZE);
		}
#else 
		ctrl->localeInfo.locale[0] = 0;
		if ( CVLD(lang) ) {
			strncpy(ctrl->localeInfo.locale, lang, AR_MAX_LANG_SIZE);
		}

		if( items > staticParams ){
			int i;
			HV *h;

			if( (items - staticParams) % 2 ){
				(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
#ifdef PROFILE
				AP_FREE(ctrl); /* invalid, cleanup */
#else
				safefree(ctrl);
#endif
				goto ar_login_end;
			}

			h = newHV();			
			for( i = staticParams; i < items; i+=2 ){
				hv_store_ent( h, newSVsv(ST(i)), newSVsv(ST(i+1)), 0 );
			}

			if( hv_exists(h,"charSet",7) ){
				strncpy( ctrl->localeInfo.charSet, SvPV_nolen( *(hv_fetch(h,"charSet",7,0)) ), AR_MAX_LANG_SIZE );
			}
			if( hv_exists(h,"timeZone",8) ){
				strncpy( ctrl->localeInfo.timeZone, SvPV_nolen( *(hv_fetch(h,"timeZone",8,0)) ), AR_MAX_LOCALE_SIZE );
			}
			if( hv_exists(h,"customDateFormat",16) ){
				strncpy( ctrl->localeInfo.customDateFormat, SvPV_nolen( *(hv_fetch(h,"customDateFormat",16,0)) ), AR_MAX_FORMAT_SIZE );
			}
			if( hv_exists(h,"customTimeFormat",16) ){
				strncpy( ctrl->localeInfo.customTimeFormat, SvPV_nolen( *(hv_fetch(h,"customTimeFormat",16,0)) ), AR_MAX_FORMAT_SIZE );
			}
			if( hv_exists(h,"separators",10) ){
				strncpy( ctrl->localeInfo.separators, SvPV_nolen( *(hv_fetch(h,"separators",10,0)) ), AR_MAX_LANG_SIZE );
			}

			hv_undef( h );
		}
#endif
#if AR_EXPORT_VERSION >= 7L
		ctrl->authString[0] = 0;
		if ( CVLD(authString) ) {
			strncpy(ctrl->authString, authString, AR_MAX_NAME_SIZE);
		}
#endif
#if AR_EXPORT_VERSION >= 4
		/* call ARInitialization */
		ret = ARInitialization(ctrl, &status);

		if(ARError(ret, status)) {
			DBG( ("ARInitialization failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
#ifdef PROFILE
			AP_FREE(ctrl);
#else
			safefree(ctrl);
#endif
			goto ar_login_end;
		}

		/*
		printf( "ctrl->localeInfo.customDateFormat <%s>\n", ctrl->localeInfo.customDateFormat );
		printf( "ctrl->localeInfo.separators <%s>\n",       ctrl->localeInfo.separators );
		*/
#endif

		if (!server || !*server) {
			DBG( ("no server given. picking one.\n") );
#if AR_EXPORT_VERSION >= 4
	  		ret = ARGetListServer(ctrl, &serverList, &status);
#else
	  		ret = ARGetListServer(&serverList, &status);
#endif
	  		if (ARError( ret, status)) {
				ARTermination(ctrl, &status);
				ARError(ret, status);
#ifdef PROFILE
				AP_FREE(ctrl); /* invalid, cleanup */
#else
				safefree(ctrl);
#endif
				
				DBG( ("ARGetListServer failed %d\n", ret) );
	   			goto ar_login_end;
	  		}
			status.numItems = 0;
	  		if (serverList.numItems == 0) {
				DBG( ("serverList is empty.\n") );
	     			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_NO_SERVERS);
				ARTermination(ctrl, &status);
				ARError(ret, status);
#ifdef PROFILE
				AP_FREE(ctrl); /* invalid, cleanup */
#else
				safefree(ctrl);
#endif
				goto ar_login_end;
	    		}
	    		server = serverList.nameList[0];
			DBG( ("changing s_ok to 0, picked server %s\n",
				SAFEPRT(server)) );
	    		s_ok = 0;
	  	}
	  	strncpy(ctrl->server, server, sizeof(ctrl->server));
	 	ctrl->server[sizeof(ctrl->server)-1] = 0;

		/* set the tcp/rpc port if given */

		ret = ARSetServerPort(ctrl, ctrl->server, tcpport, rpcnumber,
					&status);
		if (ARError(ret, status)) {
			DBG( ("ARSetServerPort failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
#ifdef PROFILE
			AP_FREE(ctrl);
#else
			safefree(ctrl);
#endif
			RETVAL = NULL;
 			goto ar_login_end;
		}

	  	/* finally, check to see if the user id is valid */

	  	ret = ARVerifyUser(ctrl, NULL, NULL, NULL, &status);
	  	if(ARError( ret, status)) {
			DBG( ("ARVerifyUser failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
#ifdef PROFILE
			AP_FREE(ctrl); /* invalid, cleanup */
#else
			safefree(ctrl);
#endif
			RETVAL = NULL;
	  	} else {
	  		RETVAL = ctrl; /* valid, return ctrl struct */
	  	}

	  	if(s_ok == 0) {
			DBG( ("s_ok == 0, cleaning ServerNameList\n") );
	  		FreeARServerNameList(&serverList, FALSE);
	  	}
	ar_login_end:;
		DBG( ("finished.\n") );
	}
	OUTPUT:
	RETVAL

HV*
ars_VerifyUser(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
		int ret = 0;
		ARBoolean	adminFlag  = 0,
				subAdminFlag = 0,
				customFlag   = 0; 
		ARStatusList status;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);

		ret = ARVerifyUser( ctrl, &adminFlag, &subAdminFlag, &customFlag, &status );

		/* printf( "ret = %d, adminFlag = %d, subAdminFlag = %d, customFlag = %d\n",
			ret, adminFlag, subAdminFlag, customFlag ); */

		if(! ARError(ret, status)) {
		    RETVAL = newHV();
		    sv_2mortal( (SV*) RETVAL );

			hv_store( RETVAL, "adminFlag",    strlen("adminFlag"),    newSViv(adminFlag),    0);
			hv_store( RETVAL, "subAdminFlag", strlen("subAdminFlag"), newSViv(subAdminFlag), 0);
			hv_store( RETVAL, "customFlag",   strlen("customFlag"),   newSViv(customFlag),   0);
		}else{
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

void
ars_GetControlStructFields(ctrl)
	ARControlStruct *	ctrl
	PPCODE:
	{
	   (void) ARError_reset();
	   if(!ctrl) return;
	   XPUSHs(sv_2mortal(newSViv(ctrl->cacheId)));
	   XPUSHs(sv_2mortal(newSViv(ctrl->operationTime)));
	   XPUSHs(sv_2mortal(newSVpv(ctrl->user, 0)));
	   XPUSHs(sv_2mortal(newSVpv(ctrl->password, 0)));
#ifndef AR_MAX_LOCALE_SIZE
	   XPUSHs(sv_2mortal(newSVpv(ctrl->language, 0)));
#else
	   XPUSHs(sv_2mortal(newSVpv(ctrl->localeInfo.locale, 0)));
#endif
	   XPUSHs(sv_2mortal(newSVpv(ctrl->server, 0)));
	   XPUSHs(sv_2mortal(newSViv(ctrl->sessionId)));
#if AR_EXPORT_VERSION >= 7
	   XPUSHs(sv_2mortal(newSVpv(ctrl->authString, 0)));
#endif
	}

SV *
ars_GetCurrentServer(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = NULL;
	  (void) ARError_reset();
	  if(ctrl && ctrl->server) {
	    RETVAL = newSVpv( ctrl->server, strlen(ctrl->server) );
	  } 
	}
	OUTPUT:
	RETVAL

HV *
ars_GetProfileInfo(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  (void) ARError_reset();
#ifdef PROFILE
	  hv_store(RETVAL,  "queries", strlen("queries") , 
	  	   newSViv(((ars_ctrl *)ctrl)->queries), 0);
	  hv_store(RETVAL,  "startTime", strlen("startTime") , 
		   newSViv(((ars_ctrl *)ctrl)->startTime), 0);
#else /* profiling not compiled in */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_OPT_NA, 
			     "Optional profiling code not compiled into this build of ARSperl");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_Logoff(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
		int          ret = 0;
		ARStatusList status;
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
		if (!ctrl) return;
#if AR_EXPORT_VERSION >= 4
		ret = ARTermination(ctrl, &status);
#else
		ret = ARTermination(&status);
#endif
		(void) ARError( ret, status);
		/*AP_FREE(ctrl); let DESTROY free it*/
	}

void
ars_GetListField(control,schema,changedsince=0,fieldType=AR_FIELD_TYPE_ALL)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	unsigned long		fieldType
	PPCODE:
	{
	  ARInternalIdList idlist;
	  ARStatusList     status;
	  int              ret = 0;
	  unsigned int     i = 0;
	  (void) ARError_reset();
	  Zero(&idlist, 1, ARInternalIdList);
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control,schema,
	  			fieldType,
	  			changedsince,
#if AR_CURRENT_API_VERSION >= 17
				NULL,   /* &objPropList (undocumented by BMC) */
#endif
	  			&idlist,
	  			&status);
#else
	  ret = ARGetListField(control,schema,changedsince,&idlist,&status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i<idlist.numItems; i++)
	      XPUSHs(sv_2mortal(newSViv(idlist.internalIdList[i])));
	    FreeARInternalIdList(&idlist,FALSE);
	  }
	}

void
ars_GetFieldByName(control,schema,field_name)
	ARControlStruct *	control
	char *			schema
	char *			field_name
	PPCODE:
	{
	  int              ret = 0;
	  unsigned int     loop = 0;
	  ARInternalIdList idList;
	  ARStatusList     status;
	  ARNameType       fieldName;
	  (void) ARError_reset();
	  Zero(&idList, 1, ARInternalIdList);
	  Zero(&status, 1, ARStatusList);
	  ret = ARGetListField(control, schema,
	  			AR_FIELD_TYPE_ALL, 
	  			(ARTimestamp)0,
#if AR_CURRENT_API_VERSION >= 17
				NULL,   /* &objPropList (undocumented by BMC) */
#endif
	  			&idList,
	  			&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
#if AR_CURRENT_API_VERSION >= 17
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#elif AR_CURRENT_API_VERSION >= 12
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError( ret, status))
	        break;
	      if (strcmp(field_name, fieldName) == 0){
		    XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
		    break;
	      }
	    }
	    FreeARInternalIdList(&idList, FALSE);
	  }
	}

void
ars_GetFieldTable(ctrl,schema)
	ARControlStruct *	ctrl
	char *			schema
	PPCODE:
	{
	  int              ret = 0;
	  unsigned int     loop = 0;
	  HV   *fields, *h;
	  char *hkey;
	  SV   *hval, **hvalName;
	  I32  klen;

	  (void) ARError_reset();

	  fields = fieldcache_get_schema_fields( ctrl, schema, TRUE );
	  if( ! fields ){
		goto get_fieldtable_end;
	  }

	  hv_iterinit( fields );
	  while( (hval = hv_iternextsv(fields,&hkey,&klen)) ){
		if( strcmp(hkey,"0") == 0 )  continue;
		h = (HV* ) SvRV(hval);
		hvalName = hv_fetch( h, "name", 4, 0 );
		XPUSHs( sv_2mortal(newSVsv(*hvalName)) );
		XPUSHs( sv_2mortal(newSVpv(hkey,0)) );
	  }

	  get_fieldtable_end:;
	  if( ! fields ){
	    XSRETURN_UNDEF;
	  }
	}

SV *
ars_CreateEntry(ctrl,schema,...)
	ARControlStruct *	ctrl
	char *			schema
	CODE:
	{
	  int               a = 0, 
			    i = 0,
			    c = (items - 2) / 2;
	  AREntryIdType     entryId;
	  ARFieldValueList  fieldList;
	  ARInternalIdList  getFieldIds; 
	  ARStatusList      status;
	  int               ret = 0, rv = 0;
	  unsigned int      dataType = 0, j = 0;
	  HV               *cacheFields;
	  
	  RETVAL=NULL;
	  (void) ARError_reset();
	  Zero(&entryId, 1, AREntryIdType);
	  Zero(&fieldList, 1, ARFieldValueList);
	  Zero(&getFieldIds, 1, ARInternalIdList);
	  Zero(&status, 1, ARStatusList);
	  if (((items - 2) % 2) || c < 1) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {

	    cacheFields = fieldcache_get_schema_fields( ctrl, schema, FALSE );
	    if( ! cacheFields ){
	      goto create_entry_end;
	    }

	    fieldList.numItems = c;
	    AMALLOCNN(fieldList.fieldValueList,c,ARFieldValueStruct);

	    getFieldIds.numItems = 0;
	    getFieldIds.internalIdList = NULL;

	    /* try to get data type from field cache, collect fieldIds which are not cached */
	    for (i=0; i<c; ++i) {
	      ARInternalId fieldId;
	      a = i*2+2;
	      fieldId = fieldList.fieldValueList[i].fieldId = SvIV(ST(a));

	      dataType = fieldcache_get_data_type( cacheFields, fieldId );
	      if (dataType <= AR_DATA_TYPE_MAX_TYPE) {
	        /* printf( "%s [%d] found in cache\n", schema, fieldId ); fflush(stdout); */ /* _DEBUG_ */
	        if (sv_to_ARValue(ctrl, ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
	          goto create_entry_end;
	        }
		  }else{
		    if( getFieldIds.numItems == 0 ){
	          AMALLOCNN(getFieldIds.internalIdList,c,ARInternalId);
	        }
	        /* printf( "%s [%d] collect for loading\n", schema, fieldId ); fflush(stdout); */ /* _DEBUG_ */
            getFieldIds.internalIdList[getFieldIds.numItems] = fieldId;
		  	++getFieldIds.numItems;
		  }
	    }

	    /* load missing fields into cache */
	    if( getFieldIds.numItems > 0 ){
	      /* printf( "--- load missing fields ---\n" ); fflush(stdout); */ /* _DEBUG_ */
	      /* if( fieldcache_load_schema(ctrl,schema,&getFieldIds,NULL) != AR_RETURN_OK ){ */
	      if( fieldcache_load_schema(ctrl,schema,&getFieldIds,NULL) > AR_RETURN_WARNING ){
	        goto create_entry_end;
	      }
	    }

	    /* now get data type from the freshly cached fields */
	    i = 0;
	    for (j=0; j<getFieldIds.numItems; ++j) {
	      ARInternalId fieldId = getFieldIds.internalIdList[j];
	      while(fieldId != fieldList.fieldValueList[i].fieldId) ++i;
	      a = i*2+2;

	      dataType = fieldcache_get_data_type( cacheFields, fieldId );
	      if (dataType <= AR_DATA_TYPE_MAX_TYPE) {
	        /* printf( "%s [%d] freshly loaded\n", schema, fieldId ); fflush(stdout); */ /* _DEBUG_ */
	        if (sv_to_ARValue(ctrl, ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
	          goto create_entry_end;
	        }
		  }else{
		    char errTxt[256];
	        sprintf( errTxt, "Failed to fetch field %d from hash", fieldId );
	        ARError_add(AR_RETURN_ERROR, AP_ERR_FIELD_TYPE);
	        ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE, errTxt );
	        goto create_entry_end;
		  }
	    }
	    /* printf( "--------------------\n" ); fflush(stdout); */ /* _DEBUG_ */

	    ret = ARCreateEntry(ctrl, schema, &fieldList, entryId, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (! ARError( ret, status)) rv = 1;
	  create_entry_end:;
	    if(rv == 0) {
	      RETVAL = newSVsv(&PL_sv_undef);
	    } else {
	      RETVAL = newSVpv( entryId, strlen(entryId) );
	    }
			AP_FREE(fieldList.fieldValueList);
	    if( getFieldIds.internalIdList != NULL ) AP_FREE(getFieldIds.internalIdList);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteEntry(ctrl,schema,entry_id)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	CODE:
	{
	  int            ret = 0;
	  ARStatusList   status;
#if AR_EXPORT_VERSION >= 3
	  AREntryIdList  entryList;

	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0)
		goto delete_fail;
	  ret = ARDeleteEntry(ctrl, schema, &entryList, 0, &status);
	  if (entryList.entryIdList) AP_FREE(entryList.entryIdList);
#else /* ARS 2 */
	  RETVAL = 0; /* assume error */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
		goto delete_fail;
	  }
	  ret = ARDeleteEntry(ctrl, schema, entry_id, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError(ret, status))
	    RETVAL = 0;
	  else
	    RETVAL = 1;
	delete_fail:;
	}
	OUTPUT:
	RETVAL

void
ars_GetEntryBLOB(ctrl,schema,entry_id,field_id,locType,locFile=NULL)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	ARInternalId		field_id
	int 			locType
	char *			locFile
	PPCODE:
	{
		ARStatusList    status;
		AREntryIdList   entryList;
#if AR_EXPORT_VERSION >= 4
		ARLocStruct     loc;
#endif
		int		ret = 0;

		(void) ARError_reset();
		Zero(&entryList, 1, AREntryIdList);
		Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 4
		/* build entryList */
	 	ret = perl_BuildEntryList(ctrl, &entryList, entry_id);
		if(ret)
			goto get_entryblob_end;
		switch(locType) {
		case AR_LOC_FILENAME:
			if(locFile == NULL) {
				ARError_add(AR_RETURN_ERROR,
					AP_ERR_USAGE,
					"locFile parameter required when specifying AR_LOC_FILENAME");
				goto get_entryblob_end;
			}
			loc.locType    = AR_LOC_FILENAME;
			loc.u.filename = strdup(locFile); /* strdup(locFile) ? i'm not completely sure
							which to use. will FreeARLocStruct call
							free(loc.locType)? i'm assuming it will.
							Purify doesnt complain, so i'm going 
							to leave this alone. */
			break;
		case AR_LOC_BUFFER:
			loc.locType       = AR_LOC_BUFFER;
			loc.u.buf.bufSize = 0;
			break;
		default:
			ARError_add(AR_RETURN_ERROR,
				AP_ERR_USAGE,
				"locType parameter is required.");
			goto get_entryblob_end;
			break;
		}
		ret = ARGetEntryBLOB(ctrl, schema, &entryList, field_id, 
				     &loc, &status);
		if(!ARError(ret, status)) {
			if(locType == AR_LOC_BUFFER)
#if PERL_PATCHLEVEL_IS >= 6
				XPUSHs(sv_2mortal(newSVpvn((const char *)
					loc.u.buf.buffer, 
					loc.u.buf.bufSize)));
#else
				XPUSHs(sv_2mortal(newSVpvn(
					loc.u.buf.buffer, 
					loc.u.buf.bufSize)));
#endif
			else
				XPUSHs(sv_2mortal(newSViv(1)));
		} else
			XPUSHs(&PL_sv_undef);
		if (entryList.entryIdList) AP_FREE(entryList.entryIdList);
		switch (loc.locType)
		{
		case AR_LOC_FILENAME:
			AP_FREE(loc.u.filename);
			break;
		case AR_LOC_BUFFER:
			FreeARLocStruct(&loc, FALSE);
			break;
		}
#else /* pre ARS-4.0 */
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_GetEntryBLOB() is only available > ARS4.x");
		XPUSHs(&PL_sv_undef);
#endif
	get_entryblob_end:;
	}

void
ars_GetEntry(ctrl,schema,entry_id,...)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	PPCODE:
	{
	  int               ret = 0;
	  unsigned int      c = items - 3, i;
	  ARInternalIdList  idList;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
#if AR_EXPORT_VERSION >= 3
	  AREntryIdList     entryList;
#endif

	  (void) ARError_reset();
	  Zero(&idList, 1, ARInternalIdList);
	  Zero(&fieldList, 1, ARFieldValueList);
	  Zero(&status, 1, ARStatusList);
	  if (c < 1) {
	    idList.numItems = 0; /* get all fields */
	  } else {
	    idList.numItems = c;
	    idList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
	    if (!idList.internalIdList)
	      goto get_entry_end;
	    for (i=0; i<c; i++)
	      idList.internalIdList[i] = SvIV(ST(i+3));
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0)
		goto get_entry_end;

	  ret = ARGetEntry(ctrl, schema, &entryList, &idList, &fieldList, &status);
		if (entryList.entryIdList) AP_FREE(entryList.entryIdList);
#else /* ARS 2 */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
		goto get_entry_cleanup;
	  }
	  ret = ARGetEntry(ctrl, schema, entry_id, &idList, &fieldList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
	    goto get_entry_cleanup;
	  }
	  
	  if(fieldList.numItems < 1) {
	    goto get_entry_cleanup;
 	  }
	  for (i=0; i<fieldList.numItems; i++) {
	    XPUSHs(sv_2mortal(newSViv(fieldList.fieldValueList[i].fieldId)));
	    XPUSHs(sv_2mortal(perl_ARValueStruct(ctrl,
		&fieldList.fieldValueList[i].value)));
	  }
	  FreeARFieldValueList(&fieldList,FALSE);
	get_entry_cleanup:;
	  if (idList.internalIdList) AP_FREE(idList.internalIdList);
	get_entry_end:;
	}

void
ars_GetListEntry(ctrl,schema,qualifier,maxRetrieve=0,firstRetrieve=0,...)
	ARControlStruct *	ctrl
	char *			schema
	ARQualifierStruct *	qualifier
	int			maxRetrieve
	int			firstRetrieve
	PPCODE:
	{
	  unsigned int     c = (items - 5) / 2;
	  unsigned int     i = 0;
	  int              field_off    = 5;
	  int              staticParams = field_off;
	  ARSortList       sortList;
	  AREntryListList  entryList;
	  ARStatusList     status;
	  int              ret = 0;
#if AR_EXPORT_VERSION >= 3
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV              *getListFields_array;
	
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  Zero(&entryList, 1, AREntryListList);
	  Zero(&sortList, 1, ARSortList);

	  if ((items - staticParams) % 2) {
		/* odd number of arguments, so argument after maxRetrieve is
		optional getListFields (an array of hash refs) */
	
		if (SvROK(ST(field_off)) &&
			(getListFields_array = (AV *)SvRV(ST(field_off))) &&
			SvTYPE(getListFields_array) == SVt_PVAV) {
	
			getList                = &getListFields;
			getListFields.numItems = av_len(getListFields_array) + 1;
			AMALLOCNN(getListFields.fieldsList, getListFields.numItems,
				AREntryListFieldStruct);
	
			/* set query field list */
			for (i = 0 ; i < getListFields.numItems ; i++) {
				SV **array_entry, **hash_entry;
				HV *field_hash;
	
				/* get hash from array */
				if ((array_entry = av_fetch(getListFields_array, i, 0)) &&
					SvROK(*array_entry) &&
					SvTYPE(field_hash = (HV*)SvRV(*array_entry)) == SVt_PVHV) {
	
					/* get fieldId, columnWidth and separator from hash */
					if (! (hash_entry = hv_fetch(field_hash, "fieldId", strlen("fieldId"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					getListFields.fieldsList[i].fieldId = SvIV(*hash_entry);
					if (! (hash_entry = hv_fetch(field_hash, "columnWidth",
							strlen("columnWidth"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					getListFields.fieldsList[i].columnWidth = SvIV(*hash_entry);
					if (! (hash_entry = hv_fetch(field_hash,  "separator",
							strlen("separator"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					strncpy(getListFields.fieldsList[i].separator,
						SvPV(*hash_entry, PL_na),
						sizeof(getListFields.fieldsList[i].separator));
				}
			}
		} else {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_LFLDS_TYPE);
			goto getlistentry_end;
		}
		/* increase the offset of the first sortList field by one */
		field_off ++;
	  }
#else  /* ARS 2 */
	  Zero(&status, 1,ARStatusList);
	  (void) ARError_reset();
	  if ((items - staticParms) % 2) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		goto getlistentry_end;
	  }
#endif /* if ARS >= 3 */
	
	  /* build sortList */
	  Zero(&sortList, 1, ARSortList);
	  if (c) {
	  	sortList.numItems = c;
          	AMALLOCNN(sortList.sortList, c,  ARSortStruct);
	  	for ( i = 0 ; i < c ; i++) {
			sortList.sortList[i].fieldId   = SvIV(ST(i*2+field_off));
			sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  	}
	  }
#if AR_EXPORT_VERSION >= 8L
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				firstRetrieve, maxRetrieve, FALSE, &entryList, 
				NULL, &status);
#elif AR_EXPORT_VERSION >= 6
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				firstRetrieve, maxRetrieve, &entryList, 
				NULL, &status);
#elif AR_EXPORT_VERSION >= 3
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				maxRetrieve, &entryList, NULL, &status);
#else
	  ret = ARGetListEntry(ctrl, schema, qualifier, &sortList, 
				maxRetrieve, &entryList, NULL, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
		goto getlistentry_end;
	  }
	  for (i = 0 ; i < entryList.numItems ; i++) {
#if AR_EXPORT_VERSION >= 3
		if (entryList.entryList[i].entryId.numItems == 1) {
			/* only one entryId -- so just return its value to be compatible
			   with ars 2 */
			XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId.entryIdList[0], 0)));
		} else {
			/* more than one entry -- this must be a join schema. merge
			 * the list into a single entry-id to keep things
			 * consistent.
			 */
			unsigned int   entry = 0;
			char *joinId     = (char *)NULL;
			char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
	
			for ( entry = 0 ; entry < entryList.entryList[i].entryId.numItems ; entry++) {
				joinId = strappend(joinId, 
					entryList.entryList[i].entryId.entryIdList[entry]);
				if(entry < entryList.entryList[i].entryId.numItems-1)
					joinId = strappend(joinId, joinSep);
			}
			XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
			AP_FREE(joinId);
		}
#else /* ARS 2 */
		XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId, 0)));
#endif
		XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].shortDesc, 0)));
	  }
	getlistentry_end:;
	  FreeARSortList(&sortList, FALSE);
	  FreeAREntryListList(&entryList,FALSE);
	}

void
ars_GetListSchema(ctrl,changedsince=0,schemaType=AR_LIST_SCHEMA_ALL,fieldPropList=NULL,name=NULL,fieldIdList=NULL)
	ARControlStruct *	ctrl
	unsigned int		changedsince
	unsigned int		schemaType
	char *			name
	AV *			fieldIdList
	ARPropList *		fieldPropList
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
	  unsigned int i = 0;
	  int          ret = 0;
#if AR_EXPORT_VERSION >= 8L
	  ARPropList propList;
#endif
#if AR_EXPORT_VERSION >= 6
	  ARInternalIdList idList;

	  Zero(&idList, 1, ARInternalIdList);	  
#endif
#if AR_EXPORT_VERSION >= 8L
	  Zero(&propList, 1, ARPropList);
#endif
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 6
	  if (fieldIdList && (SvTYPE(fieldIdList) == SVt_PVAV)) {
		idList.numItems = av_len(fieldIdList) + 1;
		AMALLOCNN(idList.internalIdList, idList.numItems, ARInternalId);
		for (i = 0 ; i < idList.numItems ; i++ ) {
			SV **array_entry;
			if ((array_entry = av_fetch(fieldIdList, i, 0)) &&
			    SvROK(*array_entry)                         &&
		 	    (SvTYPE(*array_entry) == SVt_PVIV) ) {
				idList.internalIdList[i] = (unsigned long) (SvIV(*array_entry));
			} 
		}
	  }
#endif
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListSchema(ctrl, changedsince, schemaType, name, 
# if AR_EXPORT_VERSION >= 8L
				&idList, &propList,
# elif AR_EXPORT_VERSION >= 6 && AR_EXPORT_VERSION < 8L
				&idList,
# endif
				&nameList, &status);
#else
	  ret = ARGetListSchema(ctrl, changedsince, 
				&nameList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    for (i=0; i<nameList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    }
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListContainer(ctrl,changedSince=0,attributes=0,...)
	ARControlStruct *	ctrl
	ARTimestamp		changedSince
	unsigned int		attributes
	PPCODE:
	{
	  ARStatusList 		status;
	  int          		i, ret, rv = 0;

	  (void) ARError_reset();	  
	  Zero(&status, 1, ARStatusList);

	  if(items < 1 || items > 200){  /* don't overflow clist[] */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }else{
	  	ARContainerTypeList	containerTypes;
		int			count;
		int clist[256];
		ARContainerOwnerObjList ownerObjList;
# if AR_EXPORT_VERSION >= 8L
		ARPropList		propList;
# endif
		ARContainerInfoList	conList;

		Zero(&containerTypes, 1, ARContainerTypeList);
		Zero(&ownerObjList, 1, ARContainerOwnerObjList);
# if AR_EXPORT_VERSION >= 8L
		Zero(&propList, 1, ARPropList);
# endif
		Zero(&conList, 1, ARContainerInfoList);

		count = 0;

		if( items >= 4 ){
			SV* st3 = ST(3);
			if( SvROK(st3) && SvTYPE(SvRV(st3)) == SVt_PVAV ){
				HV *h_dummy = newHV();
				SvREFCNT_inc( st3 );
				hv_store( h_dummy, "_", 1, st3, 0 );
				rv += rev_ARContainerOwnerObjList( ctrl, h_dummy, "_", &ownerObjList );
				hv_undef( h_dummy );
			}else{
				clist[count++] = SvIV(st3);
			}
		}

		for(i = 4 ; i < items ; ++i){
			clist[count++] = SvIV(ST(i));
		}
		containerTypes.numItems = count;
		containerTypes.type = clist; 

		if( rv == 0 ){
			ret = ARGetListContainer(ctrl, changedSince,
					&containerTypes,
					attributes,
					&ownerObjList,
# if AR_EXPORT_VERSION >= 8L
					&propList,
# endif
					&conList, &status);
		}else{
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
		}

		if( rv == 0 && !ARError(ret, status)) {
			unsigned int i;
		    for(i = 0 ; i < conList.numItems ; i++) {
	        	HV 			*conInfo = newHV();
			ARContainerOwnerObjList	 cOwnerObjList;

	        	hv_store(conInfo,  "containerType", strlen("containerType") , 
				newSVpv(ContainerTypeMap[conList.conInfoList[i].type].name, 0), 0);
	        	hv_store(conInfo,  "containerName", strlen("containerName") , 
				newSVpv(conList.conInfoList[i].name, 0), 0);
			cOwnerObjList = conList.conInfoList[i].ownerList;
			hv_store(conInfo,  "ownerObjList", strlen("ownerObjList") ,
		     		perl_AROwnerObjList(ctrl, &cOwnerObjList), 0);
	        	XPUSHs(sv_2mortal(newRV_noinc((SV *)conInfo)));
		    }
		}
        /* Don't try to FreeAR this, because clist[] is a stack variable */ 
		/* FreeARContainerTypeList(&containerTypes, FALSE); */

		FreeARContainerInfoList(&conList, FALSE);
		FreeARContainerOwnerObjList(&ownerObjList, FALSE);
# if AR_EXPORT_VERSION >= 8L
		FreeARPropList(&propList, FALSE);
# endif
	  }
	}

HV *
ars_GetContainer(control,name)
	ARControlStruct *	control
	char *			name
	CODE:
	{
	  ARStatusList            status;
	  int                     ret;
	  ARReferenceTypeList     refTypes;
	  ARPermissionList        assignedGroupList;
	  ARPermissionList        groupList;
	  ARInternalIdList        adminGroupList;
	  ARContainerOwnerObjList ownerObjList;
	  char                   *label = CPNULL;
	  char                   *description = CPNULL;
	  unsigned int            type;
	  ARReferenceList         references;
	  char                   *helpText = CPNULL;
	  ARAccessNameType        owner;
	  ARTimestamp             timestamp;
	  ARAccessNameType        lastChanged;
	  char                   *changeDiary = CPNULL;
	  ARPropList              objPropList;
	  int            tlist[] = {ARREF_ALL};
	  /* int                     i; */
	  ARDiaryList             diaryList;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  Zero(&refTypes, 1, ARReferenceTypeList);
	  Zero(&assignedGroupList, 1, ARPermissionList);
	  Zero(&groupList, 1, ARPermissionList);
	  Zero(&adminGroupList, 1, ARInternalIdList);
	  Zero(&ownerObjList, 1, ARContainerOwnerObjList);
	  Zero(&references, 1, ARReferenceList);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&diaryList, 1, ARDiaryList);

	  refTypes.numItems = 1;
	  refTypes.refType = tlist;

	  ret = ARGetContainer(control, name,
			       &refTypes, 
#if AR_CURRENT_API_VERSION >= 17
			       &assignedGroupList,
#endif
			       &groupList, &adminGroupList,
			       &ownerObjList, 
			       &label, &description,
			       &type, &references, &helpText,
			       owner, &timestamp, lastChanged, &changeDiary, 
			       &objPropList, 
				   &status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  if (!ARError( ret,status)) {
	    AV *rtypeList = newAV(), *rnameList = newAV();

	    hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
		     perl_ARPropList(control, &objPropList), 0);
#if AR_CURRENT_API_VERSION >= 17
	    hv_store(RETVAL,  "assignedGroupList", strlen("assignedGroupList") ,
		     perl_ARPermissionList(control, &assignedGroupList, PERMTYPE_SCHEMA), 0);
#endif
	    hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARPermissionList(control, &groupList, PERMTYPE_SCHEMA), 0);
	    hv_store(RETVAL,  "adminList", strlen("adminList") ,
		     perl_ARList(control, (ARList *)&adminGroupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
	    hv_store(RETVAL,  "ownerObjList", strlen("ownerObjList") ,
		     perl_AROwnerObjList(control, &ownerObjList), 0);
	    if (helpText)
	      hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "type", strlen("type") ,
			    newSVpv( ContainerTypeMap[type].name, strlen(ContainerTypeMap[type].name) ) ,
			    0);
	    hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") ,
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
		ret = ARDecodeDiary(control, changeDiary, &diaryList, &status);
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(control, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
	    hv_store(RETVAL,  "referenceList", strlen("referenceList") ,
		     perl_ARReferenceList(control, &references), 0);
	    if (label)
	      hv_store(RETVAL,  "label", strlen("label") , newSVpv(label, 0), 0);
	    if (description)
	      hv_store(RETVAL,  "description", strlen("description") , newSVpv(description, 0), 0);
	    hv_store(RETVAL,  "numReferences", strlen("numReferences") , newSViv(references.numItems), 0);

	    FreeARPermissionList(&groupList,FALSE);
	    FreeARInternalIdList(&adminGroupList,FALSE);
	    FreeARContainerOwnerObjList(&ownerObjList,FALSE);
	    FreeARReferenceList(&references,FALSE);
	    FreeARPropList(&objPropList, FALSE);
	    if(helpText)
	      	arsperl_FreeARTextString(helpText);
	    if(changeDiary)
	      	arsperl_FreeARTextString(changeDiary);
	    if(label)
	      	arsperl_FreeARTextString(label);
	    if(description)
	      	arsperl_FreeARTextString(description);
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetListServer()
	PPCODE:
	{
	  ARServerNameList serverList;
	  ARStatusList     status;
	  int              ret = 0;
          unsigned int     i = 0;
	  ARControlStruct  ctrl;

	  (void) ARError_reset();  
	  Zero(&serverList, 1, ARServerNameList);
	  Zero(&status, 1, ARStatusList);
	  Zero(&ctrl, 1, ARControlStruct);
#if AR_EXPORT_VERSION >= 4
	  /* this function can be called without a control struct 
	   * (or even before a control struct is available).
	   * we will create a bogus control struct, initialize it
	   * and execute the function. this seems to work fine.
	   */
	  ARInitialization(&ctrl, &status);
	  ret = ARGetListServer(&ctrl, &serverList, &status);
#else
	  ret = ARGetListServer(&serverList, &status);
#endif
	  if (! ARError( ret, status)) {
	    for (i=0; i<serverList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(serverList.nameList[i], 0)));
	    }
	    FreeARServerNameList(&serverList,FALSE);
	  }
	}

HV *
ars_GetActiveLink(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int              ret = 0;
	  unsigned int     order = 0;
	  ARInternalIdList assignedGroupList;
	  ARInternalIdList groupList;
	  unsigned int     executeMask  = 0;
	  ARInternalId     controlField;
	  ARInternalId     focusField;
	  unsigned int     enable = 0;
	  ARActiveLinkActionList actionList;
	  ARActiveLinkActionList elseList;
	  ARWorkflowConnectStruct  schemaList;
	  ARPropList       objPropList;
	  char            *helpText = CPNULL;
	  ARTimestamp      timestamp;
	  ARAccessNameType    owner;
	  ARAccessNameType    lastChanged;
	  char            *changeDiary = CPNULL;
	  ARStatusList     status;
	  SV              *ref;
	  ARQualifierStruct *query;
	  ARDiaryList      diaryList;

	  AMALLOCNN(query,1,ARQualifierStruct);

	  (void) ARError_reset();
	  Zero(&assignedGroupList, 1, ARInternalIdList);
	  Zero(&groupList, 1, ARInternalIdList);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  Zero(&diaryList, 1, ARDiaryList);
	  Zero(&status, 1, ARStatusList);
	  Zero(&actionList, 1, ARActiveLinkActionList);
	  Zero(&elseList, 1, ARActiveLinkActionList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&objPropList, 1, ARPropList);

	  ret = ARGetActiveLink(ctrl, name, &order, 
				&schemaList,  /* new in 4.5 */
#if AR_CURRENT_API_VERSION >= 17
				&assignedGroupList,
#endif
				&groupList,
				&executeMask, &controlField, &focusField,
				&enable, query, &actionList, &elseList, &helpText,
				&timestamp, owner, lastChanged, &changeDiary, 
				&objPropList, /* new in 4.5 */
#if AR_CURRENT_API_VERSION >= 14
				NULL,         /* errorActlinkOptions, reserved for future use */
				NULL,         /* errorActlinkName,    reserved for future use */
#endif
				&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif

	  if (!ARError( ret,status)) {
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );	  	  
		hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		hv_store(RETVAL,  "order", strlen("order") , newSViv(order),0);
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
#if AR_CURRENT_API_VERSION >= 17
		hv_store(RETVAL,  "assignedGroupList", strlen("assignedGroupList") ,
		     perl_ARList( ctrl, 
				 (ARList *)&assignedGroupList,
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)), 0);
#endif
		hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARList( ctrl, 
				 (ARList *)&groupList,
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)), 0);
		hv_store(RETVAL,  "executeMask", strlen("executeMask") , newSViv(executeMask),0);
		hv_store(RETVAL,  "focusField", strlen("focusField") , newSViv(focusField), 0);
		hv_store(RETVAL,  "controlField", strlen("controlField") , 
			newSViv(controlField), 0);
		hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
		/* a bit of a hack -- makes blessed reference to qualifier */
		ref = newSViv(0);
		sv_setref_pv(ref, "ARQualifierStructPtr", (void*)query);
		hv_store(RETVAL,  "query", strlen("query") , ref, 0);
		hv_store(RETVAL,  "actionList", strlen("actionList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
		hv_store(RETVAL,  "elseList", strlen("elseList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
		if (helpText)
			hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText,0), 0);
		hv_store(RETVAL,  "timestamp", strlen("timestamp") ,  newSViv(timestamp), 0);
		hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner,0), 0);
		hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged,0), 0);
		if (changeDiary) {
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
			if (!ARError(ret, status)) {
				hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
					perl_ARList(ctrl, (ARList *)&diaryList,
						    (ARS_fn)perl_diary,
						    sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	    }
	    FreeARInternalIdList(&groupList,FALSE);
	    FreeARActiveLinkActionList(&actionList,FALSE);
	    FreeARActiveLinkActionList(&elseList,FALSE);
	    FreeARWorkflowConnectStruct(&schemaList, FALSE);
	    FreeARPropList(&objPropList, FALSE);
	    if(helpText) arsperl_FreeARTextString(helpText);
	    if(changeDiary) arsperl_FreeARTextString(changeDiary);
	  
	    }else{
      XSRETURN_UNDEF;
	  }
	}
	OUTPUT:
	RETVAL



HV *
ars_GetFilter(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int          ret;
	  unsigned int order;
	  unsigned int opSet;
	  unsigned int enable;
	  char        *helpText = CPNULL;
	  char        *changeDiary = CPNULL;
	  ARFilterActionList actionList;
	  ARFilterActionList elseList;
	  ARTimestamp timestamp;
	  ARAccessNameType  owner;
	  ARAccessNameType  lastChanged;
	  ARStatusList status;
	  SV         *ref;
	  ARQualifierStruct *query;
	  ARDiaryList      diaryList;
	  ARWorkflowConnectStruct  schemaList;
	  ARPropList       objPropList;
#if AR_CURRENT_API_VERSION >= 13
	  unsigned int errorFilterOptions;
	  ARNameType   errorFilterName;
#endif

	  AMALLOCNN(query,1,ARQualifierStruct);

	  (void) ARError_reset();
	  Zero(&actionList, 1, ARFilterActionList);
	  Zero(&elseList, 1, ARFilterActionList);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  Zero(&diaryList, 1, ARDiaryList);
	  Zero(&status, 1,ARStatusList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&objPropList, 1, ARPropList);
#if AR_CURRENT_API_VERSION >= 13
	  Zero(&errorFilterName, 1,ARNameType);
#endif
	  ret = ARGetFilter(ctrl, name, &order, 
			    &schemaList,
			    &opSet, &enable, 
			    query, &actionList, &elseList, &helpText,
			    &timestamp, owner, lastChanged, &changeDiary,
			    &objPropList,
#if AR_CURRENT_API_VERSION >= 13
			    &errorFilterOptions,
			    errorFilterName,
#endif
			    &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (!ARError( ret,status)) {
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	    hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
	    hv_store(RETVAL,  "order", strlen("order") , newSViv(order), 0);
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
	    hv_store(RETVAL,  "opSet", strlen("opSet") , newSViv(opSet), 0);
	    hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
	    /* a bit of a hack -- makes blessed reference to qualifier */
	    ref = newSViv(0);
	    sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	    hv_store(RETVAL,  "query", strlen("query") , ref, 0);
	    hv_store(RETVAL,  "actionList", strlen("actionList") , 
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
	    hv_store(RETVAL,  "elseList", strlen("elseList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
	    if(helpText)
		hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
#if AR_CURRENT_API_VERSION >= 13
	    hv_store(RETVAL,  "errorFilterOptions", strlen("errorFilterOptions") , newSViv(errorFilterOptions), 0);
	    hv_store(RETVAL,  "errorFilterName",    strlen("errorFilterName") ,    newSVpv(errorFilterName, 0), 0);
#endif
	    FreeARFilterActionList(&actionList,FALSE);
	    FreeARFilterActionList(&elseList,FALSE);
	    FreeARWorkflowConnectStruct(&schemaList, FALSE);
	    FreeARPropList(&objPropList, FALSE);
	    if(helpText) {
	      	AP_FREE(helpText);
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
	  }else{
	  XSRETURN_UNDEF;
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetServerStatistics(ctrl,...)
	ARControlStruct *	ctrl
	PPCODE:
	{
	  ARServerInfoRequestList requestList;
	  ARServerInfoList        serverInfo;
	  int                     i = 0, ret = 0;
          unsigned int            ui = 0;
	  ARStatusList            status;

	  (void) ARError_reset();
	  Zero(&requestList, 1, ARServerInfoRequestList);
	  Zero(&serverInfo, 1, ARServerInfoList);
	  Zero(&status, 1, ARStatusList);
	  if(items < 1) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
		requestList.numItems = items - 1;
		AMALLOCNN(requestList.requestList,(items-1),unsigned int);
		if(requestList.requestList) {
			for(i=1; i<items; i++) {
				requestList.requestList[i-1] = SvIV(ST(i));
			}
			ret = ARGetServerStatistics(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (!ARError(ret, status)) {
				for(ui=0; ui<serverInfo.numItems; ui++) {
					XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].operation)));
					switch(serverInfo.serverInfoList[ui].value.dataType) {
					case AR_DATA_TYPE_ENUM:
					case AR_DATA_TYPE_TIME:
					case AR_DATA_TYPE_BITMASK:
					case AR_DATA_TYPE_INTEGER:
						XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].value.u.intVal)));
						break;
					case AR_DATA_TYPE_REAL:
						XPUSHs(sv_2mortal(newSVnv(serverInfo.serverInfoList[ui].value.u.realVal)));
						break;
					case AR_DATA_TYPE_CHAR:
						XPUSHs(sv_2mortal(newSVpv(serverInfo.serverInfoList[ui].value.u.charVal,
							strlen(serverInfo.serverInfoList[ui].value.u.charVal))));
						break;
					}
				}
			}
			FreeARServerInfoList(&serverInfo, FALSE);
			FreeARServerInfoRequestList(&requestList, FALSE);
		} else {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_MALLOC);
		} 
	  }
	}


HV *
ars_GetCharMenu(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  unsigned int       refreshCode = 0;
	  ARCharMenuStruct   menuDefn;
	  char	            *helpText = CPNULL;
	  ARTimestamp	     timestamp;
	  ARAccessNameType	     owner;
	  ARAccessNameType	     lastChanged;
	  char		    *changeDiary = CPNULL;
	  ARStatusList	     status;
	  int                ret = 0, i = 0;
	  HV		    *menuDef = newHV();
	  /* SV		    *ref; */
	  ARDiaryList        diaryList;
	  ARPropList         objPropList;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&menuDefn, 1, ARCharMenuStruct);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  Zero(&diaryList, 1, ARDiaryList);
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  ret = ARGetCharMenu(ctrl, name, &refreshCode, &menuDefn, &helpText, 
			      &timestamp, owner, lastChanged, &changeDiary, 
			      &objPropList,
			      &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
		hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		if(helpText)
			hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText,0), 0);
		hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
		hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
		hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	        if (changeDiary) {
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
			if (!ARError(ret, status)) {
				hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
					perl_ARList(ctrl, (ARList *)&diaryList,
					(ARS_fn)perl_diary,
					sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	        }
		for(i = 0; CharMenuTypeMap[i].number != TYPEMAP_LAST; i++) {
			if (CharMenuTypeMap[i].number == menuDefn.menuType)
				break;
		}
		hv_store(RETVAL,  "menuType", strlen("menuType") , 
			   /* PRE-1.68: newSViv(menuDefn.menuType) */
			newSVpv( CharMenuTypeMap[i].name, strlen(CharMenuTypeMap[i].name) )
			, 0);
		hv_store(RETVAL,  "refreshCode", strlen("refreshCode") , 
			perl_MenuRefreshCode2Str(ctrl, refreshCode), 0);
		switch(menuDefn.menuType) {
		case AR_CHAR_MENU_LIST:
			/* hv_store(menuDef,  "charMenuList", strlen("charMenuList") , 
				perl_ARCharMenuList(ctrl,&(menuDefn.u.menuList)), 0 );
			hv_store(RETVAL,  "menuList", strlen("menuList") , 
				newRV_noinc((SV *)menuDef), 0); */

			hv_store(RETVAL,  "menuList", strlen("menuList") , 
				perl_ARCharMenuList(ctrl,&(menuDefn.u.menuList)), 0);
			break;
		case AR_CHAR_MENU_QUERY:
			hv_store(menuDef,  "schema", strlen("schema") , 
				newSVpv(menuDefn.u.menuQuery.schema, 0), 0);
			hv_store(menuDef,  "server", strlen("server") , 
				newSVpv(menuDefn.u.menuQuery.server, 0), 0);
#if AR_EXPORT_VERSION >= 6
			{
				int lfn = 0;
				AV *a = newAV();
				while (lfn < AR_MAX_LEVELS_DYNAMIC_MENU) {
					if ( menuDefn.u.menuQuery.labelField[lfn] ) {
						av_push(a, newSViv(menuDefn.u.menuQuery.labelField[lfn]));
					} else {
						av_push(a, newSVsv(&PL_sv_undef));
					}
					lfn++;
				}
				hv_store(menuDef, "labelField", strlen("labelField"),
					 newRV_noinc((SV *) a), 0);
			}
#else
			{
				AV *a = newAV();
				av_push(a, newSViv(menuDefn.u.menuQuery.labelField));
				hv_store(menuDef, "labelField", strlen("labelField"),
					newRV_noinc((SV *)a), 0);
			}
#endif
			hv_store(menuDef,  "valueField", strlen("valueField") ,
				newSViv(menuDefn.u.menuQuery.valueField), 0);
			hv_store(menuDef,  "sortOnLabel", strlen("sortOnLabel") ,
				newSViv(menuDefn.u.menuQuery.sortOnLabel), 0);
			/* ref = newSViv(0);
			sv_setref_pv(ref, "ARQualifierStructPtr", 
				dup_qualifier(ctrl,
					(void *)&(menuDefn.u.menuQuery.qualifier)));
			hv_store(menuDef,  "qualifier", strlen("qualifier") , ref, 0); */
			hv_store( menuDef, "qualifier", strlen("qualifier"),
				newRV_inc((SV*) perl_qualifier(ctrl,&(menuDefn.u.menuQuery.qualifier))), 0 );

			hv_store(RETVAL,  "menuQuery", strlen("menuQuery") , 
				newRV_noinc((SV *)menuDef), 0);
			break;
		case AR_CHAR_MENU_FILE:
			hv_store(menuDef,  "fileLocation", strlen("fileLocation") , 
				newSViv(menuDefn.u.menuFile.fileLocation), 0);
			hv_store(menuDef,  "filename", strlen("filename") , 
				newSVpv(menuDefn.u.menuFile.filename, 0), 0);
			hv_store(RETVAL,  "menuFile", strlen("menuFile") ,
				newRV_noinc((SV *)menuDef), 0);
			break;
#ifndef ARS20
		case AR_CHAR_MENU_SQL:
			hv_store(menuDef,  "server", strlen("server") , 
				newSVpv(menuDefn.u.menuSQL.server, 0), 0);
			hv_store(menuDef,  "sqlCommand", strlen("sqlCommand") , 
				newSVpv(menuDefn.u.menuSQL.sqlCommand, 0), 0);
#if AR_EXPORT_VERSION >= 6
			{
				int lfn = 0;
				AV *a = newAV();
				while (lfn < AR_MAX_LEVELS_DYNAMIC_MENU) {
					if ( menuDefn.u.menuSQL.labelIndex[lfn] ) {
						av_push(a, newSViv(menuDefn.u.menuSQL.labelIndex[lfn]));
					} else {
						av_push(a, newSVsv(&PL_sv_undef));
					}
					lfn++;
				}
				hv_store(menuDef, "labelIndex", strlen("labelIndex"),
					 newRV_noinc((SV *) a), 0);
			}
#else
			hv_store(menuDef,  "labelIndex", strlen("labelIndex") , 
				newSViv(menuDefn.u.menuSQL.labelIndex), 0);
#endif
			hv_store(menuDef,  "valueIndex", strlen("valueIndex") , 
				newSViv(menuDefn.u.menuSQL.valueIndex), 0);
			hv_store(RETVAL,  "menuSQL", strlen("menuSQL") , 
				newRV_noinc((SV *)menuDef), 0);
			break;
# if AR_EXPORT_VERSION >= 6
		case AR_CHAR_MENU_DATA_DICTIONARY:
			hv_store(menuDef,  "server", strlen("server") , 
				newSVpv(menuDefn.u.menuDD.server, 0), 0);
			hv_store(menuDef,  "nameType", strlen("nameType") , 
				newSViv(menuDefn.u.menuDD.nameType), 0);
			hv_store(menuDef,  "valueFormat", strlen("valueFormat") , 
				newSViv(menuDefn.u.menuDD.valueFormat), 0);
			hv_store(menuDef,  "structType", strlen("structType") , 
				newSViv(menuDefn.u.menuDD.structType), 0);
			switch(menuDefn.u.menuDD.structType) {
			case AR_CHAR_MENU_DD_FORM:
				hv_store(menuDef,  "schemaType", strlen("schemaType") , 
					newSViv(menuDefn.u.menuDD.u.formDefn.schemaType), 0);
				if(menuDefn.u.menuDD.u.formDefn.includeHidden)
					hv_store(menuDef,  "includeHidden", strlen("includeHidden") , 
						newSVpv("true", 0), 0);
				else
					hv_store(menuDef,  "includeHidden", strlen("includeHidden") , 
						newSVpv("false", 0), 0);
				break;
			case AR_CHAR_MENU_DD_FIELD:
				hv_store(menuDef,  "fieldType", strlen("fieldType") , 
					newSViv(menuDefn.u.menuDD.u.fieldDefn.fieldType), 0);
				hv_store(menuDef,  "schema", strlen("schema") , 
					newSVpv(menuDefn.u.menuDD.u.fieldDefn.schema, 0), 0);
				break;
			}
			hv_store(RETVAL,  "menuDD", strlen("menuDD") , 
				newRV_noinc((SV *)menuDef), 0);
			break;
# endif
#endif
		}
		FreeARPropList(&objPropList, FALSE);
		FreeARCharMenuStruct(&menuDefn, FALSE);
		if (helpText) {
		  	AP_FREE(helpText);
		}
		if (changeDiary) {
		  	AP_FREE(changeDiary);
		}
	  }else{
	  XSRETURN_UNDEF;
	  }
	}
	OUTPUT:
	RETVAL

SV *
ars_ExpandCharMenu2(ctrl,name,qual=NULL)
	ARControlStruct *	ctrl
	char *			name
	ARQualifierStruct *     qual
	CODE:
	{
		ARCharMenuStruct menuDefn;
		ARStatusList     status;
		int              ret;

		RETVAL = &PL_sv_undef;
		(void) ARError_reset();
		Zero(&menuDefn, 1, ARCharMenuStruct);
		Zero(&status, 1,ARStatusList);
		DBG( ("-> ARGetCharMenu\n") );
		ret = ARGetCharMenu(ctrl, name, NULL, &menuDefn, 
					NULL, NULL, NULL, NULL, NULL, 
#if AR_EXPORT_VERSION >= 5
			      		NULL,
#endif
			     		&status);
		DBG( ("<- ARGetCharMenu\n") );
#ifdef PROFILE
		((ars_ctrl *)ctrl)->queries++;
#endif
		if (! ARError(ret, status)) {
			DBG( ("-> perl_expandARCharMenuStruct\n") );
			RETVAL = perl_expandARCharMenuStruct(ctrl, 
							     &menuDefn);
			DBG( ("<- perl_expandARCharMenuStruct\n") );
			FreeARCharMenuStruct(&menuDefn, FALSE);
			DBG( ("after Free\n") );
		}
	}
	OUTPUT:
	RETVAL

HV *
ars_GetSchema(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList         status;
	  int                  ret = 0;
	  ARPermissionList     assignedGroupList;
	  ARPermissionList     groupList;
#if AR_EXPORT_VERSION >= 8L
	  ARSchemaInheritanceList inheritanceList;
	  ARArchiveInfoStruct infoStruct;
#endif
#if AR_EXPORT_VERSION >= 9L
      ARAuditInfoStruct    auditInfo;
#endif
	  ARInternalIdList     adminGroupList;
	  AREntryListFieldList getListFields;
	  ARIndexList          indexList;
	  char                *helpText = CPNULL;
	  ARTimestamp          timestamp;
	  ARAccessNameType           owner;
	  ARAccessNameType           lastChanged;
	  char                *changeDiary = CPNULL;
	  ARDiaryList          diaryList;
	  ARCompoundSchema     schema;
	  ARSortList           sortList;
	  ARPropList           objPropList;
	  ARNameType           defaultVui;

	  (void) ARError_reset();
	  Zero(&status, 1,  ARStatusList);
	  Zero(&assignedGroupList, 1, ARPermissionList);
	  Zero(&groupList, 1, ARPermissionList);
	  Zero(&adminGroupList, 1, ARInternalIdList);
	  Zero(&getListFields, 1, AREntryListFieldList);
	  Zero(&indexList, 1, ARIndexList);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  Zero(&diaryList, 1, ARDiaryList);
	  Zero(&schema, 1, ARCompoundSchema);
	  Zero(&sortList, 1, ARSortList);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&defaultVui, 1, ARNameType);
#if AR_EXPORT_VERSION >= 8L
	  Zero(&inheritanceList, 1, ARSchemaInheritanceList);
	  Zero(&infoStruct, 1, ARArchiveInfoStruct);
#endif
#if AR_EXPORT_VERSION >= 9L
	  Zero(&auditInfo, 1, ARAuditInfoStruct);
#endif
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );

	  ret = ARGetSchema(ctrl, name, &schema, 
#if AR_EXPORT_VERSION >= 8L
                &inheritanceList,
#endif
#if AR_CURRENT_API_VERSION >= 17
			    &assignedGroupList,
#endif
			    &groupList, &adminGroupList, &getListFields, 
			    &sortList, &indexList, 
#if AR_EXPORT_VERSION >= 8L
                            &infoStruct,
#endif
#if AR_EXPORT_VERSION >= 9L
                            &auditInfo,
#endif
			    defaultVui,
			    &helpText, &timestamp, owner, 
			    lastChanged, &changeDiary, 
			    &objPropList,
			    &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (!ARError( ret,status)) {
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			 perl_ARPropList(ctrl, &objPropList), 0);
#endif
#if AR_EXPORT_VERSION >= 6
		hv_store(RETVAL, "defaultVui", strlen("defaultVui"),
			newSVpv(defaultVui, 0), 0);			
#endif
#if AR_CURRENT_API_VERSION >= 17
	    hv_store(RETVAL,  "assignedGroupList", strlen("assignedGroupList") ,
		     perl_ARPermissionList(ctrl, &assignedGroupList, PERMTYPE_SCHEMA), 0);
#endif
	    hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARPermissionList(ctrl, &groupList, PERMTYPE_SCHEMA), 0);
	    hv_store(RETVAL,  "adminList", strlen("adminList") ,
		     perl_ARList(ctrl, (ARList *)&adminGroupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
	    hv_store(RETVAL,  "getListFields", strlen("getListFields") ,
		     perl_ARList(ctrl, (ARList *)&getListFields,
				 (ARS_fn)perl_AREntryListFieldStruct,
				 sizeof(AREntryListFieldStruct)),0);
	    hv_store(RETVAL,  "indexList", strlen("indexList") ,
		     perl_ARList(ctrl, (ARList *)&indexList,
				 (ARS_fn)perl_ARIndexStruct,
				 sizeof(ARIndexStruct)), 0);
	    if (helpText)
	      hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") ,
		     newSVpv(lastChanged, 0), 0);
	    hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
	    if (changeDiary) {
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }

	    hv_store(RETVAL,  "schema", strlen("schema") , 
			perl_ARCompoundSchema(ctrl, &schema), 0);
	    hv_store(RETVAL,  "sortList", strlen("sortList") , 
			perl_ARSortList(ctrl, &sortList), 0);
#if AR_EXPORT_VERSION >= 8L
	    hv_store(RETVAL,  "archiveInfo", strlen("archiveInfo") , 
			perl_ARArchiveInfoStruct(ctrl, &infoStruct), 0);
#endif
#if AR_EXPORT_VERSION >= 9L
	    hv_store(RETVAL, "auditInfo", strlen("auditInfo") , 
			perl_ARAuditInfoStruct(ctrl, &auditInfo), 0);
#endif
	    FreeARPermissionList(&groupList,FALSE);
	    FreeARInternalIdList(&adminGroupList,FALSE);
	    FreeAREntryListFieldList(&getListFields,FALSE);
	    FreeARIndexList(&indexList,FALSE);
	    if(helpText) {
	      	AP_FREE(helpText);
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
	    FreeARCompoundSchema(&schema,FALSE);
	    FreeARSortList(&sortList,FALSE);
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetListActiveLink(ctrl,schema=NULL,changedSince=0)
	ARControlStruct *	ctrl
	char *			schema
	int			changedSince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
          ARPropList   propList;
	  int          ret = 0;
          unsigned int i = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&nameList, 1, ARNameList);
	  Zero(&propList, 1, ARPropList);
#if AR_EXPORT_VERSION >= 8L
	  Zero(&propList, 1, ARPropList);
#endif
	  ret=ARGetListActiveLink(ctrl,schema,changedSince,
#if AR_EXPORT_VERSION >= 8L
                     &propList,
#endif
                     &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i],0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

HV *
ars_GetField(ctrl,schema,id)
	ARControlStruct *	ctrl
	char *			schema
	unsigned long		id
	CODE:
	{
	  int                   ret;
	  ARStatusList          Status;
	  unsigned int          dataType, option, createMode;
#if AR_CURRENT_API_VERSION >= 12
	  unsigned int          fieldOption;
#endif
	  ARValueStruct         defaultVal;
	  ARPermissionList      assignedGroupList;
	  ARPermissionList      permissions;
	  ARFieldLimitStruct    limit;
	  ARNameType            fieldName;
	  ARFieldMappingStruct  fieldMap;
	  ARDisplayInstanceList displayList;
	  char                 *helpText = CPNULL;
	  ARTimestamp           timestamp;
	  ARAccessNameType            owner;
	  ARAccessNameType            lastChanged;
	  char                 *changeDiary = CPNULL;
	  ARDiaryList           diaryList;
	  ARPropList            objPropList;

	  (void) ARError_reset();
	  Zero(&Status,      1, ARStatusList);
	  Zero(&defaultVal,  1, ARValueStruct);
	  Zero(&assignedGroupList, 1, ARPermissionList);
	  Zero(&permissions, 1, ARPermissionList);
	  Zero(&limit,       1, ARFieldLimitStruct);

	  Zero(fieldName,    1, ARNameType);
	  Zero(&fieldMap,    1, ARFieldMappingStruct);
	  Zero(&displayList, 1, ARDisplayInstanceList);

	  Zero(&timestamp,   1, ARTimestamp);
	  Zero(owner,        1, ARAccessNameType);
	  Zero(lastChanged,  1, ARAccessNameType);
	  Zero(&diaryList,   1, ARDiaryList);
	  Zero(&objPropList, 1, ARPropList);
#if AR_CURRENT_API_VERSION >= 17
	  ret = ARGetFieldCached(ctrl, schema, id, fieldName, &fieldMap, &dataType, &option, &createMode, &fieldOption, &defaultVal, &assignedGroupList, &permissions, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &objPropList, &Status);
#elif AR_CURRENT_API_VERSION >= 12
	  ret = ARGetFieldCached(ctrl, schema, id, fieldName, &fieldMap, &dataType, &option, &createMode, &fieldOption, &defaultVal, &permissions, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#else
	  ret = ARGetFieldCached(ctrl, schema, id, fieldName, &fieldMap, &dataType, &option, &createMode, &defaultVal, &permissions, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, Status)) {
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	    /* store field id for convenience */
	    hv_store(RETVAL,  "fieldId", strlen("fieldId") , newSViv(id), 0);
	    if (createMode == AR_FIELD_OPEN_AT_CREATE)
	      hv_store(RETVAL,  "createMode", strlen("createMode") , newSVpv("open",0), 0);
	    else
	      hv_store(RETVAL,  "createMode", strlen("createMode") ,
		       newSVpv("protected",0), 0);
	    hv_store(RETVAL,  "option", strlen("option") , newSViv(option), 0);
#if AR_CURRENT_API_VERSION >= 12
	    hv_store(RETVAL,  "fieldOption", strlen("fieldOption") , newSViv(fieldOption), 0);
#endif
	    hv_store(RETVAL,  "dataType", strlen("dataType") ,
		     perl_dataType_names(ctrl, &dataType), 0);
	    hv_store(RETVAL,  "defaultVal", strlen("defaultVal") ,
		     perl_ARValueStruct(ctrl, &defaultVal), 0);
#if AR_CURRENT_API_VERSION >= 17
	    hv_store(RETVAL,  "assignedGroupList", strlen("assignedGroupList") , 
		     perl_ARPermissionList(ctrl, &assignedGroupList, PERMTYPE_FIELD), 0);
#endif
	    hv_store(RETVAL,  "permissions", strlen("permissions") , 
		     perl_ARPermissionList(ctrl, &permissions, PERMTYPE_FIELD), 0);

	    hv_store(RETVAL,  "limit", strlen("limit") , 
		     perl_ARFieldLimitStruct(ctrl, &limit), 0);
	    hv_store(RETVAL,  "fieldName", strlen("fieldName") , 
		     newSVpv(fieldName, 0), 0);
	    hv_store(RETVAL,  "fieldMap", strlen("fieldMap") ,
		     perl_ARFieldMappingStruct(ctrl, &fieldMap), 0);
	    hv_store(RETVAL,  "displayInstanceList", strlen("displayInstanceList") ,
		     perl_ARDisplayInstanceList(ctrl, &displayList), 0);
	    if (helpText)
	      hv_store(RETVAL,  "helpText", strlen("helpText") ,
		       newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , 
		     newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") ,
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") ,
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &Status);
		if (!ARError(ret, Status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
	    FreeARFieldLimitStruct(&limit,FALSE);
	    FreeARDisplayInstanceList(&displayList,FALSE);
	    if(helpText) {
	      	/* AP_FREE(helpText);   */ /* TS 20060207 disabled bc of memory errors with 5.8.8 */
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
	  }else{
	   XSRETURN_UNDEF;
	  }
	}
	OUTPUT:
	RETVAL


HV*
ars_GetImage(ctrl,name)
	ARControlStruct *       ctrl
    ARNameType              name
	CODE:
	{
	  ARStatusList         status;
#if AR_CURRENT_API_VERSION >= 14
	  unsigned int         enable =  0;
	  ARImageDataStruct    content;
	  char                *imageType;
	  ARTimestamp          timestamp;
	  char                *checkSum = CPNULL;
	  char                *description = CPNULL;
	  char                *helpText    = CPNULL;
	  ARAccessNameType     owner;
	  ARAccessNameType     lastChanged;
      char                *changeDiary = CPNULL;
	  ARPropList           objPropList;
	  ARDiaryList           diaryList;
	  int                  ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&content, 1, ARImageDataStruct);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&diaryList,   1, ARDiaryList);

	  ret = ARGetImage(ctrl, name, 
		 		&content,
		 		&imageType,
		 		&timestamp,
		 		&checkSum,
		 		&description,
		 		&helpText,
		 		owner,
		 		lastChanged,
		 		&changeDiary,
		 		&objPropList,
		 		&status );

	  if(!ARError( ret, status)) {
	  	RETVAL = newHV();
	    sv_2mortal( (SV*) RETVAL );
	    hv_store(RETVAL,  "name", strlen("name"), newSVpv(name, 0), 0);
		hv_store(RETVAL,  "imageData", strlen("imageData"),
			perl_ARImageDataStruct(ctrl, &content), 0);
	    hv_store(RETVAL,  "imageType", strlen("imageType"), newSVpv(imageType, 0), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "checkSum", strlen("checkSum") , newSVpv(checkSum, 0), 0);
	    if( description ){
	      hv_store(RETVAL,  "description", strlen("description") , newSVpv(description, 0), 0);
	    }
	    if( helpText ){
	      hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    }
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	    if( changeDiary ){
		  ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
		  if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, 
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		  }
	    }

	    if(helpText)    {  AP_FREE(helpText);  }
	    if(changeDiary) {  AP_FREE(changeDiary);  }
	    if(imageType)   {  AP_FREE(imageType);  }
	    if(checkSum)    { 	AP_FREE(checkSum);  }
	    if(description) {  AP_FREE(description);  }
	    FreeARImageDataStruct(&content, FALSE);
	    FreeARPropList(&objPropList, FALSE);
	  }else{
	    XSRETURN_UNDEF;
	  }
#else	/* prior to ARS 7.5 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_GetImage() is only available in ARS >= 7.5");
	  XSRETURN_UNDEF;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_SetEntry(ctrl,schema,entry_id,getTime,...)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	unsigned long		getTime
	CODE:
	{
	  int              a = 0, i = 0, c = (items - 4) / 2;
	  int              offset = 4;
	  ARFieldValueList fieldList;
	  ARInternalIdList getFieldIds;
	  ARStatusList     status;
	  int              ret = 0;
	  unsigned int     dataType = 0, j = 0;
	  unsigned int     option = AR_JOIN_SETOPTION_NONE;
	  AREntryIdList    entryList;
	  HV              *cacheFields;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&fieldList, 1, ARFieldValueList);
	  Zero(&getFieldIds, 1, ARInternalIdList);
	  Zero(&entryList, 1,AREntryIdList);
	  RETVAL = 0; /* assume error */
	  if ((items - 4) % 2) {
	    option = SvIV(ST(offset));
	    offset ++;
	  }
	  if (c < 1) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto set_entry_exit;
	  }

	  cacheFields = fieldcache_get_schema_fields( ctrl, schema, FALSE );
	  if( ! cacheFields ){
	    goto set_entry_exit;
	  }

	  fieldList.numItems = c;
	  AMALLOCNN(fieldList.fieldValueList,c,ARFieldValueStruct);

	  getFieldIds.numItems = 0;
	  getFieldIds.internalIdList = NULL;

	  for (i=0; i<c; i++) {
	    ARInternalId fieldId;
	    a = i*2+offset;
	    fieldId = fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	    
	    if (! SvOK(ST(a+1))) {
	      /* pass a NULL */
	      fieldList.fieldValueList[i].value.dataType = AR_DATA_TYPE_NULL;
	    }else{
	      /* determine data type and pass value */
	      dataType = fieldcache_get_data_type( cacheFields, fieldId );
	      if (dataType <= AR_DATA_TYPE_MAX_TYPE) {
	        if (sv_to_ARValue(ctrl, ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
		      goto set_entry_end;
	        }
	      }else{
	    	   if( getFieldIds.numItems == 0 ){
	          AMALLOCNN(getFieldIds.internalIdList,c,ARInternalId);
	        }
	        /* printf( "%s [%d] collect for loading\n", schema, fieldId ); fflush(stdout); */ /* _DEBUG_ */
            getFieldIds.internalIdList[getFieldIds.numItems] = fieldId;
	        ++getFieldIds.numItems;
	    	 }
	    }
	  }

	  /* load missing fields into cache */
	  if( getFieldIds.numItems > 0 ){
	    /* printf( "--- load missing fields ---\n" ); fflush(stdout); */ /* _DEBUG_ */
	    /* if( fieldcache_load_schema(ctrl,schema,&getFieldIds,NULL) != AR_RETURN_OK ){ */
	    if( fieldcache_load_schema(ctrl,schema,&getFieldIds,NULL) > AR_RETURN_WARNING ){
	      goto set_entry_end;
	    }
	  }

	  /* now get data type from the freshly cached fields */
	  i = 0;
	  for (j=0; j<getFieldIds.numItems; ++j) {
	    ARInternalId fieldId = getFieldIds.internalIdList[j];
	    while(fieldId != fieldList.fieldValueList[i].fieldId) ++i;
	    a = i*2+offset;

	    dataType = fieldcache_get_data_type( cacheFields, fieldId );
	    if (dataType <= AR_DATA_TYPE_MAX_TYPE) {
	      /* printf( "%s [%d] freshly loaded\n", schema, fieldId ); fflush(stdout); */ /* _DEBUG_ */
	      if (sv_to_ARValue(ctrl, ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
	        goto set_entry_end;
	      }
		}else{
		  char errTxt[256];
	      sprintf( errTxt, "Failed to fetch field %d from hash", fieldId );
	      ARError_add(AR_RETURN_ERROR, AP_ERR_FIELD_TYPE);
	      ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE, errTxt );
	      goto set_entry_end;
		}
	  }
	  /* printf( "--------------------\n" ); fflush(stdout); */ /* _DEBUG_ */


	  /* build entryList */
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0){
		goto set_entry_end;
	  }

	  ret = ARSetEntry(ctrl, schema, &entryList, &fieldList, getTime, option, &status);
	  if (entryList.entryIdList) AP_FREE(entryList.entryIdList);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    RETVAL = 1;
	  }
	set_entry_end:;
	  if (fieldList.fieldValueList) AP_FREE(fieldList.fieldValueList);
	set_entry_exit:;
	}
	OUTPUT:
	RETVAL

SV *
ars_Export(ctrl,displayTag,vuiType,...)
	ARControlStruct *	ctrl
	char *			displayTag
	unsigned int		vuiType
	CODE:
	{
		int              ret = 0, i = 0, a = 0, c = (items - 3) / 2, ok = 1;
		ARStructItemList structItems;
		char            *buf = CPNULL;
		ARStatusList     status;
#if AR_CURRENT_API_VERSION >= 17
		unsigned int     exportOption = AR_EXPORT_DEFAULT;   /* TODO: support this as ars_Export() argument */
#endif
#if AR_EXPORT_VERSION >= 8L
		ARWorkflowLockStruct workflowLockStruct;
#endif
	  
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&structItems, 1, ARStructItemList);
#if AR_EXPORT_VERSION >= 8L
		Zero(&workflowLockStruct, 1, ARWorkflowLockStruct);
#endif
		RETVAL = &PL_sv_undef;
		if ( (items % 2 == 0) || (c < 1) ) {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
			ok = 0;
		} else {
			structItems.numItems = c;
			AMALLOCNN(structItems.structItemList, c, ARStructItemStruct);
			for (i = 0 ; i < c ; i++) {
				unsigned int et = 0;
				a  = i * 2 + 3;
				et = caseLookUpTypeNumber((TypeMapStruct *) 
							     StructItemTypeMap,
							   SvPV(ST(a), PL_na) 
							 );
				if(et == TYPEMAP_LAST) {
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EXP);
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
						SvPV(ST(a), PL_na) );
					ok = 0;
				} else {
					structItems.structItemList[i].type = et;
					/* printf( "structItems.structItemList[i].type <%d>\n", structItems.structItemList[i].type ); */ /* _DEBUG_ */
					strncpy(structItems.structItemList[i].name,
						SvPV(ST(a+1), PL_na), 
						sizeof(ARNameType) );
					structItems.structItemList[i].name[sizeof(ARNameType)-1] = '\0';
					/* printf( "structItems.structItemList[i].name <%s>\n", structItems.structItemList[i].name ); */ /* _DEBUG_ */
				}
			}
		}
#if AR_EXPORT_VERSION >= 8L
			workflowLockStruct.lockType = 0;
			workflowLockStruct.lockKey[0] = '\0';
#endif

		if(ok) {
			ret = ARExport(ctrl, &structItems, displayTag, 
#if AR_EXPORT_VERSION >= 6
				       vuiType,
#endif
#if AR_CURRENT_API_VERSION >= 17
					   exportOption,	
#endif
#if AR_EXPORT_VERSION >= 8L
					   &workflowLockStruct,
#endif
				       &buf, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (! ARError(ret, status) ) {
				RETVAL = newSVpv(buf, 0);
			}
		} 
		if(buf) arsperl_FreeARTextString(buf);
		AP_FREE(structItems.structItemList);
	}
	OUTPUT:
	RETVAL

int
ars_Import(ctrl,importOption=AR_IMPORT_OPT_CREATE,importBuf,...)
	ARControlStruct *	ctrl
	char *			importBuf
	unsigned int            importOption
	CODE:
	{
		int               ret = 1, i = 0, a = 0, c = (items - 2) / 2, ok = 1;
		ARStructItemList *structItems = NULL;
		char             *objectModificationLogLabel = NULL;
		ARStatusList      status;

		(void) ARError_reset();	  
		Zero(&status, 1,ARStatusList);
		RETVAL = 0;
		if ((items-3) % 2) {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
			ok = 0;
		} else {
			if (c > 0) {
				AMALLOCNN(structItems, c, ARStructItemList);
				structItems->numItems = c;
				AMALLOCNN(structItems->structItemList, c,
				     ARStructItemStruct);
				for (i = 0; i < c; i++) {
					unsigned int et = 0;
					a  = i*2+3;
					et = caseLookUpTypeNumber((TypeMapStruct *) 
								     StructItemTypeMap,
								   SvPV(ST(a), PL_na) 
								 );
					if(et == TYPEMAP_LAST) {
						(void) ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_IMP);
						(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
								   SvPV(ST(a), PL_na) );
						ok = 0;
					} else {
						structItems->structItemList[i].type = et;
						strncpy(structItems->structItemList[i].name,
							SvPV(ST(a+1), PL_na), 
							sizeof(ARNameType) );
						structItems->structItemList[i].name[sizeof(ARNameType)-1] = '\0';
					}
				}
			}
		}

		if(ok) {
			ret = ARImport(ctrl, structItems, importBuf, 
#if AR_EXPORT_VERSION >= 5
				       importOption,
#endif
#if AR_CURRENT_API_VERSION >= 17
				       objectModificationLogLabel,
#endif
				       &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (ARError(ret, status)) {
				RETVAL = 0;
			} else {
				RETVAL = 1;
			}
		} else {
			RETVAL = 0;
		}
		if (structItems != NULL)
		{
			AP_FREE(structItems->structItemList);
			AP_FREE(structItems);
		}
	}
	OUTPUT:
	RETVAL

void
ars_GetListFilter(control,schema=NULL,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
#if AR_EXPORT_VERSION >= 8L
	  ARPropList   propList;
#endif
	  int          ret = 0;
	  unsigned int i = 0;

	  (void) ARError_reset();
#if AR_EXPORT_VERSION >= 8L
	  Zero(&propList, 1, ARPropList);
#endif
	  Zero(&nameList, 1, ARNameList);
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListFilter(control,schema,changedsince,
#if AR_EXPORT_VERSION >= 8L
                               &propList,
#endif
                               &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i < nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListEscalation(control,schema=NULL,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
	  ARPropList   propList;
	  int          ret = 0;
	  unsigned int i = 0;

	  (void) ARError_reset();
#if AR_EXPORT_VERSION >= 8L
	  Zero(&propList, 1,ARPropList);
#endif
	  Zero(&nameList, 1, ARNameList);
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListEscalation(control,schema,changedsince,
#if AR_EXPORT_VERSION >= 8L
                                    &propList,
#endif
                                    &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListCharMenu(control,changedsince=0)
	ARControlStruct *	control
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
#if AR_EXPORT_VERSION >= 8L
          ARPropList   propList;
#endif
          ARNameList   schemaNameList;
          ARNameList   actLinkNameList;
	  int          ret = 0;
          unsigned int i = 0;

	  (void) ARError_reset();
#if AR_EXPORT_VERSION >= 8L
	  Zero(&propList, 1, ARPropList);
#endif
	  Zero(&status, 1, ARStatusList);
	  Zero(&schemaNameList, 1, ARNameList);
	  Zero(&actLinkNameList, 1, ARNameList);
	  Zero(&nameList, 1, ARNameList);
	  ret = ARGetListCharMenu(control,changedsince,
#if AR_EXPORT_VERSION >= 8L
                                  &schemaNameList, &actLinkNameList, &propList,
#endif
                                  &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif

	  if (!ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListImage(ctrl,schema=NULL,changedSince=0,imageType=NULL)
	ARControlStruct *       ctrl
    SV *                    schema
	ARTimestamp		           changedSince
	char *                  imageType
	PPCODE:
	{
	  ARStatusList     status;
#if AR_CURRENT_API_VERSION >= 14
	  ARNameList       schemaList;
	  ARNameList      *schemaListPtr = NULL;
	  ARNameList       nameList;
	  ARPropList       propList;
	  int              ret = 0, rv = 0;
	  unsigned int     i = 0;

	  (void) ARError_reset();
	  Zero(&propList, 1, ARPropList);
	  Zero(&schemaList, 1, ARNameList);
	  Zero(&nameList, 1, ARNameList);
	  Zero(&status, 1,ARStatusList);

	  if( schema == NULL ){
	    /* do nothing */
	  }else if( SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVAV ){
	    HV *h_dummy = newHV();
	    SvREFCNT_inc( schema );
	    hv_store( h_dummy, "_", 1, schema, 0 );
	    rv += rev_ARNameList( ctrl, h_dummy, "_", &schemaList );
	    hv_undef( h_dummy );
	    schemaListPtr = &schemaList;
	  }else if( SvPOK(schema) ){
	    STRLEN len = 0;
	    char *str = SvPV( schema, len );
	    if( len > 0 ){
	      schemaList.numItems = 1;
	      schemaList.nameList = (ARNameType*) MALLOCNN(sizeof(ARNameType) * 1);
	      strncpy( schemaList.nameList[0], str, AR_MAX_NAME_SIZE );
	    }
	    schemaListPtr = &schemaList;
	  }

	  if( rv == 0 ){
	    ret = ARGetListImage( ctrl,
	    		    schemaListPtr,
	    		    changedSince,
	    		    imageType,
#if AR_CURRENT_API_VERSION >= 19
	    		    &propList, // at the moment we don't want to search for specific properties
#endif
	    		    &nameList,
	    		    &status );
	  }else{
		  ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }

	  if (rv == 0 && !ARError( ret,status)) {
	    for (i=0; i < nameList.numItems; i++){
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    }
	    FreeARNameList(&nameList,FALSE);
	  }
	  FreeARNameList(&schemaList,FALSE);
#else	/* prior to ARS 7.5 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_GetListImage() is only available in ARS >= 7.5");
#endif
	}






int
ars_DeleteActiveLink(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(name)) {
		ret = ARDeleteActiveLink(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                         0,
#endif
#if AR_CURRENT_API_VERSION >= 17
                                         objectModificationLogLabel,
#endif
                                         &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif		
	        if(!ARError(ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteVUI(ctrl, schema, vuiId)
	ARControlStruct *	ctrl
	char *			schema
	ARInternalId		vuiId
	CODE:
	{
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
#if AR_EXPORT_VERSION >= 3
	  if(ctrl && CVLD(schema)) {
		ret = ARDeleteVUI(ctrl, schema,
		        vuiId,
		        &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "DeleteVUI() is only available in ARS3.x");
#endif
	}
	OUTPUT:
	RETVAL


int
ars_DeleteCharMenu(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteCharMenu(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                       0,
#endif
#if AR_CURRENT_API_VERSION >= 17
                                       objectModificationLogLabel,
#endif
                                       &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteEscalation(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteEscalation(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                         0,
#endif
#if AR_CURRENT_API_VERSION >= 17
                                         objectModificationLogLabel,
#endif
                                         &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteField(ctrl, schema, fieldId, deleteOption=0)
	ARControlStruct *	ctrl
	char * 			schema
	ARInternalId		fieldId
	unsigned int		deleteOption
	CODE:
	{
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(schema) && IVLD(deleteOption, 0, 2)) {
		ret = ARDeleteField(ctrl, schema,
		        fieldId,
		        deleteOption,
		        &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteFilter(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteFilter(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                     0,
#endif
#if AR_CURRENT_API_VERSION >= 17
                                     objectModificationLogLabel,
#endif
                                     &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteContainer(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteContainer( ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                     0,
#endif
#if AR_CURRENT_API_VERSION >= 17
                                     objectModificationLogLabel,
#endif
                                     &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteSchema(ctrl, name, deleteOption)
	ARControlStruct *	ctrl
	char *			name
	unsigned int 		deleteOption
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(name)) {
		ret = ARDeleteSchema(ctrl, name,
		        deleteOption,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
		        &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status))
			RETVAL = 1;
	  } else
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	}
	OUTPUT:
	RETVAL

int
ars_DeleteMultipleFields(ctrl, schema, deleteOption, ...)
	ARControlStruct	*	ctrl
	char *			schema
	unsigned int		deleteOption
	CODE:
	{
	  int              i = 0, ret = 0, c = (items - 3);
	  ARStatusList     status;
	  ARInternalIdList fieldList;

	  RETVAL = 0; /* assume error */
	  Zero(&status, 1,ARStatusList);
	  Zero(&fieldList, 1, ARInternalIdList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  if(items < 4)
	     (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  else {
	     /* slurp in each fieldId and put it in a list */
	     fieldList.numItems = c;
	     fieldList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
	     for(i = 0; i < c; i++) {
		fieldList.internalIdList[i] = SvIV(ST(i + 3));
	     }
	     ret = ARDeleteMultipleFields(ctrl, schema,
		        &fieldList,
		        deleteOption,
		        &status);
#ifdef PROFILE
	     ((ars_ctrl *)ctrl)->queries++;
#endif
	     if(!ARError( ret, status))
		RETVAL = 1;
	     FreeARInternalIdList(&fieldList, FALSE);
	  }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_DeleteImage(ctrl, name, updateRef=FALSE)
	ARControlStruct *       ctrl
    char *                  name
    ARBoolean               updateRef
	CODE:
	{
	  char        *objectModificationLogLabel = NULL;
	  ARStatusList status;
#if AR_CURRENT_API_VERSION >= 14
	  int          ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;

	  if(ctrl && name && *name) {
		ret = ARDeleteImage(ctrl, name,
		        updateRef,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
		        &status);
		if( !ARError( ret, status) ){
			RETVAL = 1;
		}
	  }else{
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
#else	/* prior to ARS 7.5 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_DeleteImage() is only available in ARS >= 7.5");
	  XSRETURN_UNDEF;
#endif
	}
	OUTPUT:
	RETVAL




void
ars_ExecuteProcess(ctrl, command, runOption=0)
	ARControlStruct *	ctrl
	char *			command
	int			runOption
	PPCODE:
	{
	 ARStatusList status;
	 int          returnStatus = 0;
	 char        *returnString;
	 int          ret = 0;

	 (void) ARError_reset();
	 Zero(&status, 1,ARStatusList);
#if AR_EXPORT_VERSION >= 3
	 if(ctrl && CVLD(command)) {
		if(runOption == 0)
			ret = ARExecuteProcess(ctrl, command, &returnStatus, &returnString, &status);
		else
			ret = ARExecuteProcess(ctrl, command, NULL, NULL, &status);
	 }
#ifdef PROFILE
	 ((ars_ctrl *)ctrl)->queries++;
#endif
	 /* if all went well, and user requested synchronous processing 
	  * then we push the returnStatus and returnString back out to them.
	  * if they requested async, then we just push a 1 to indicate that the
	  * command to the API was successfully handled (and foo || die constructs
	  * will work correctly).
	  */
	 if(!ARError( ret, status)) {
		if(runOption == 0) {
			XPUSHs(sv_2mortal(newSViv(returnStatus)));
			XPUSHs(sv_2mortal(newSVpv(returnString, 0)));
			if(returnString) AP_FREE(returnString);
		} else {
			XPUSHs(sv_2mortal(newSViv(1)));
		}
	 }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}


HV *
ars_GetEscalation(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList         status;
	  AREscalationTmStruct escalationTm;
	  unsigned int         enable =  0;
	  ARFilterActionList   actionList;
	  ARFilterActionList   elseList;
	  char                *helpText = CPNULL;
	  ARTimestamp          timestamp;
	  ARAccessNameType     owner;
	  ARAccessNameType     lastChanged;
      char                *changeDiary = CPNULL;
	  SV                  *ref;
	  int                  ret;
	  ARQualifierStruct   *query = MALLOCNN(sizeof(ARQualifierStruct));
	  ARDiaryList          diaryList;
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;


	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&escalationTm, 1, AREscalationTmStruct);
	  Zero(&actionList, 1,ARFilterActionList);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  Zero(&diaryList, 1, ARDiaryList);
	  Zero(&elseList, 1,ARFilterActionList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&objPropList, 1, ARPropList);

	  ret = ARGetEscalation(ctrl, name, &escalationTm, &schemaList, &enable,
			query, &actionList, &elseList, &helpText, &timestamp,
			owner, lastChanged, &changeDiary, &objPropList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	  	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	     hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
	     hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
	     hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	     if(helpText)
	        hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	     hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	     hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, 
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     ref = newSViv(0);
	     sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	     hv_store(RETVAL,  "query", strlen("query") , ref, 0);
	     hv_store(RETVAL,  "actionList", strlen("actionList") ,
			perl_ARList(ctrl,
				(ARList *)&actionList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
	     hv_store(RETVAL,  "elseList", strlen("elseList") , 
			perl_ARList( ctrl,
				(ARList *)&elseList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
	     hv_store(RETVAL,  "TmType", strlen("TmType") , 
			newSViv(escalationTm.escalationTmType), 0);
	     switch(escalationTm.escalationTmType) {
	     case AR_ESCALATION_TYPE_INTERVAL:
		hv_store(RETVAL,  "TmInterval", strlen("TmInterval") , 
			newSViv(escalationTm.u.interval), 0);
		break;
	     case AR_ESCALATION_TYPE_TIMEMARK:
		hv_store(RETVAL,  "TmMonthDayMask", strlen("TmMonthDayMask") ,
			newSViv(escalationTm.u.date.monthday), 0);
		hv_store(RETVAL,  "TmWeekDayMask", strlen("TmWeekDayMask") ,
			newSViv(escalationTm.u.date.weekday), 0);
		hv_store(RETVAL,  "TmHourMask", strlen("TmHourMask") ,
			newSViv(escalationTm.u.date.hourmask), 0);
		hv_store(RETVAL,  "TmMinute", strlen("TmMinute") ,
			newSViv(escalationTm.u.date.minute), 0);
		break;
	     }
	     FreeARFilterActionList(&actionList, FALSE);
	     FreeARFilterActionList(&elseList, FALSE);
	     FreeARWorkflowConnectStruct(&schemaList, FALSE);
	     FreeARPropList(&objPropList, FALSE);
	     if(helpText) {
	       	arsperl_FreeARTextString(helpText);
	     }
	     if(changeDiary) {
	       	arsperl_FreeARTextString(changeDiary);
	     }
	  }else{
	   XSRETURN_UNDEF;
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetFullTextInfo(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  ARFullTextInfoRequestList requestList;
	  ARFullTextInfoList        fullTextInfo;
	  ARStatusList              status;
	  int                       ret = 0;
	  unsigned int rlist[] = {AR_FULLTEXTINFO_COLLECTION_DIR,
			 	  AR_FULLTEXTINFO_STOPWORD,
				  AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH,
			 	  AR_FULLTEXTINFO_STATE,
			 	  AR_FULLTEXTINFO_FTS_MATCH_OP };

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&requestList, 1, ARFullTextInfoRequestList);
	  Zero(&fullTextInfo, 1, ARFullTextInfoList);
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  requestList.numItems = 5;
	  requestList.requestList = rlist;
	  ret = ARGetFullTextInfo(ctrl, &requestList, &fullTextInfo, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
             unsigned int i, v;
	     AV *a = newAV();

	     for(i = 0; i < fullTextInfo.numItems ; i++) {
	        switch(fullTextInfo.fullTextInfoList[i].infoType) {
		case AR_FULLTEXTINFO_STOPWORD:
		   for(v = 0; v < fullTextInfo.fullTextInfoList[i].u.valueList.numItems ; v++) {
		      av_push(a, perl_ARValueStruct(ctrl,
			&(fullTextInfo.fullTextInfoList[i].u.valueList.valueList[v])));
		   }
		   hv_store(RETVAL,  "StopWords", strlen("StopWords") , newRV_noinc((SV *)a), 0);
		   break;
		case AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH:
		   hv_store(RETVAL,  "CaseSensitive", strlen("CaseSensitive") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_COLLECTION_DIR:
		   hv_store(RETVAL,  "CollectionDir", strlen("CollectionDir") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_FTS_MATCH_OP:
		   hv_store(RETVAL,  "MatchOp", strlen("MatchOp") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_STATE:
		   hv_store(RETVAL,  "State", strlen("State") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		}
	     }
             FreeARFullTextInfoList(&fullTextInfo, FALSE);
	  }
	}
	OUTPUT:
	RETVAL



#ifdef GETLISTGROUP_OLD_STYLE

HV *
ars_GetListGroup(ctrl, userName=NULL,password=NULL)
	ARControlStruct *	ctrl
	char *			userName
	char *			password
	CODE:
	{
	  ARStatusList    status;
	  ARGroupInfoList groupList;
	  int             ret = 0;
          unsigned int    i = 0, v = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&groupList, 1, ARGroupInfoList);
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  ret = ARGetListGroup(ctrl, userName, 
#if AR_EXPORT_VERSION >= 6
			       password,
#endif
			       &groupList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	    AV *gidList = newAV(), *gtypeList = newAV(), 
	       *gnameListList = newAV(), *gnameList;

	    for(i = 0; i < groupList.numItems; i++) {
		av_push(gidList, newSViv(groupList.groupList[i].groupId));
		av_push(gtypeList, newSViv(groupList.groupList[i].groupType));
		gnameList = newAV();
		for(v = 0; v < groupList.groupList[i].groupName.numItems ; v++) {
		   av_push(gnameList, newSVpv(groupList.groupList[i].groupName.nameList[v], 0));
		}
		av_push(gnameListList, newRV_noinc((SV *)gnameList));
	    }

	    hv_store(RETVAL,  "groupId", strlen("groupId") , newRV_noinc((SV *)gidList), 0);
	    hv_store(RETVAL,  "groupType", strlen("groupType") , newRV_noinc((SV *)gtypeList), 0);
	    hv_store(RETVAL,  "groupName", strlen("groupName") , newRV_noinc((SV *)gnameListList), 0);
	 
	    FreeARGroupInfoList(&groupList, FALSE);
	  }
	}
	OUTPUT:
	RETVAL

#else

void
ars_GetListGroup(ctrl, userName=NULL,password=NULL)
	ARControlStruct  *	ctrl
	char *			       userName
	char *			       password
	PPCODE:
	{
	  ARStatusList    status;
	  ARGroupInfoList groupList;
	  int             ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&groupList, 1, ARGroupInfoList);

	  ret = ARGetListGroup(ctrl, userName, 
#if AR_EXPORT_VERSION >= 6
			       password,
#endif
			       &groupList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
      if(!ARError( ret, status)) {
        unsigned int i;
	    for(i = 0; i < groupList.numItems; i++) {
          unsigned int v;
        	 HV *groupInfo = newHV();
          AV *gnameList = newAV();

          for(v = 0; v < groupList.groupList[i].groupName.numItems ; v++) {
             av_push(gnameList, newSVpv(groupList.groupList[i].groupName.nameList[v], 0));
          }
          hv_store(groupInfo, "groupId",   7, newSViv(groupList.groupList[i].groupId), 0);
          hv_store(groupInfo, "groupType", 9, newSViv(groupList.groupList[i].groupType), 0);
          hv_store(groupInfo, "groupName", 9, newRV_noinc((SV *)gnameList), 0);
#if AR_CURRENT_API_VERSION >= 10
          hv_store(groupInfo, "groupCategory", 13, newSViv(groupList.groupList[i].groupCategory), 0);
#endif     

          XPUSHs(sv_2mortal(newRV_noinc((SV *)groupInfo)));
        }
	  }

      FreeARGroupInfoList(&groupList, FALSE);
	}

#endif


void
ars_GetListRole(ctrl, applicationName, userName=NULL,password=NULL)
    ARControlStruct * ctrl
    ARNameType        applicationName
    char *            userName
    char *            password
    PPCODE:
    {
#if AR_EXPORT_VERSION >= 8L
      ARStatusList    status;
      ARRoleInfoList  roleList;
      int             ret = 0;

      (void) ARError_reset();
      Zero(&status, 1,ARStatusList);
      Zero(&roleList, 1, ARRoleInfoList);

      ret = ARGetListRole(ctrl,
                   applicationName, 
                   userName, 
                   password,
                   &roleList, &status);

      if(!ARError( ret, status)) {
        unsigned int i;
	    for(i = 0; i < roleList.numItems; i++) {
          HV *roleInfo = newHV();

          hv_store(roleInfo, "roleId",   6, newSViv(roleList.roleList[i].roleId), 0);
          hv_store(roleInfo, "roleType", 8, newSViv(roleList.roleList[i].roleType), 0);
          hv_store(roleInfo, "roleName", 8, newSVpv(roleList.roleList[i].roleName,0), 0);
     
          XPUSHs(sv_2mortal(newRV_noinc((SV *)roleInfo)));
        }     
      }
      FreeARRoleInfoList(&roleList, FALSE);
#else /* < 6.0 */
      XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
      (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
            "ars_GetListRole() is only available in ARS >= 6.0");
#endif
    }


void
ars_GetListLicense(ctrl, licenseType=NULL)
    ARControlStruct *  ctrl
    char *             licenseType
    PPCODE:
    {
#if AR_EXPORT_VERSION >= 6L
      ARStatusList       status;
      ARLicenseInfoList  licList;
      int                ret = 0;

      (void) ARError_reset();
      Zero(&status, 1,ARStatusList);
      Zero(&licList, 1, ARLicenseInfoList);

      ret = ARGetListLicense(ctrl,
                   licenseType, 
                   &licList, &status);

      if(!ARError( ret, status)) {
        unsigned int i;
	    for(i = 0; i < licList.numItems; i++) {
          HV *licInfo = newHV();

          hv_store(licInfo, "licKey",  6, newSVpv(licList.licenseInfoList[i].licKey,0), 0);
          hv_store(licInfo, "licType", 8, newSVpv(licList.licenseInfoList[i].licType,0), 0);
          hv_store(licInfo, "licSubtype", 10, newSVpv(licList.licenseInfoList[i].licSubtype,0), 0);
          hv_store(licInfo, "issuedDate", 10, 
            perl_ARLicenseDateStruct(ctrl, &(licList.licenseInfoList[i].issuedDate)), 0);
          hv_store(licInfo, "expireDate", 10,
            perl_ARLicenseDateStruct(ctrl, &(licList.licenseInfoList[i].expireDate)), 0);
          hv_store(licInfo, "hostId", 6, newSVpv(licList.licenseInfoList[i].hostId,0), 0);
          hv_store(licInfo, "numLicenses", 11, newSViv(licList.licenseInfoList[i].numLicenses), 0);
          hv_store(licInfo, "tokenList", 9, newSVpv(licList.licenseInfoList[i].tokenList,0), 0);
          hv_store(licInfo, "comment", 7, newSVpv(licList.licenseInfoList[i].comment,0), 0);
     
          XPUSHs(sv_2mortal(newRV_noinc((SV *)licInfo)));
        }     
      }
      FreeARLicenseInfoList(&licList, FALSE);
#else /* < 6.0 */
      XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
      (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
            "ars_GetListLicense() is only available in ARS >= 5.0");
#endif
    }


HV *
ars_GetListSQL(ctrl, sqlCommand, maxRetrieve=AR_NO_MAX_LIST_RETRIEVE)
	ARControlStruct *	ctrl
	char *			sqlCommand
	unsigned int		maxRetrieve
	PPCODE:
	{
	  ARStatusList    status;
	  ARValueListList valueListList;
	  unsigned int    numMatches = 0;
	  int             ret = 0;

	  (void) ARError_reset();
	  RETVAL = NULL;
	  Zero(&status, 1, ARStatusList);
	  Zero(&valueListList, 1, ARValueListList);
#ifndef ARS20
	  ret = ARGetListSQL(ctrl, sqlCommand, maxRetrieve, &valueListList, 
			     &numMatches, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     unsigned int  row, col;
	     AV  *ra = newAV(), *ca;
	     RETVAL = newHV();

	     hv_store(RETVAL,  "numMatches", strlen("numMatches") , newSViv(numMatches), 0);
	     for(row = 0; row < valueListList.numItems ; row++) {
		ca = newAV();
		for(col = 0; col < valueListList.valueListList[row].numItems;
		    col++) 
		{
		   av_push(ca, perl_ARValueStruct(ctrl,
			&(valueListList.valueListList[row].valueList[col])));
		}
		av_push(ra, newRV_noinc((SV *)ca));
	     }
	     hv_store(RETVAL,  "rows", strlen("rows") , newRV_noinc((SV *)ra), 0);
	     FreeARValueListList(&valueListList, FALSE);
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in pre-2.1 ARS");
#endif
	  if(RETVAL != NULL) {
			XPUSHs(sv_2mortal(newRV_noinc((SV *)RETVAL)));
	  } else {
			XPUSHs(sv_2mortal(newSViv(0)));
	  }
	}

void
ars_GetListUser(ctrl, userListType=AR_USER_LIST_MYSELF,changedSince=0)
	ARControlStruct *	ctrl
	unsigned int		userListType
	ARTimestamp		changedSince
	PPCODE:
	{
	  ARStatusList   status;
	  ARUserInfoList userList;
	  int            ret = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&userList, 1, ARUserInfoList);
	  ret = ARGetListUser(ctrl, userListType, 
#if AR_EXPORT_VERSION >= 6
				changedSince,
#endif
				&userList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     unsigned int i, j;
	     for(i = 0; i < userList.numItems; i++) {
	        HV *userInfo           = newHV();
		AV *licenseTag         = newAV(),
		   *licenseType        = newAV(),
		   *currentLicenseType = newAV();

	        hv_store(userInfo,  "userName", strlen("userName") , 
			newSVpv(userList.userList[i].userName, 0), 0);
		hv_store(userInfo,  "connectTime", strlen("connectTime") ,
			newSViv(userList.userList[i].connectTime), 0);
		hv_store(userInfo,  "lastAccess", strlen("lastAccess") ,
			newSViv(userList.userList[i].lastAccess), 0);
		hv_store(userInfo,  "defaultNotifyMech", strlen("defaultNotifyMech") ,
			newSViv(userList.userList[i].defaultNotifyMech), 0);
		hv_store(userInfo,  "emailAddr", strlen("emailAddr") ,
			newSVpv(userList.userList[i].emailAddr, 0), 0);

		for(j = 0; j < userList.userList[i].licenseInfo.numItems; j++) {
		   av_push(licenseTag, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseTag));
		   av_push(licenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseType));
		   av_push(currentLicenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].currentLicenseType));
		}
		hv_store(userInfo,  "licenseTag", strlen("licenseTag") , newRV_noinc((SV *)licenseTag), 0);
		hv_store(userInfo,  "licenseType", strlen("licenseType") , newRV_noinc((SV *)licenseType), 0);
		hv_store(userInfo,  "currentLicenseType", strlen("currentLicenseType") , newRV_noinc((SV *)currentLicenseType), 0);
	        XPUSHs(sv_2mortal(newRV_noinc((SV *)userInfo)));
	     }
	     FreeARUserInfoList(&userList, FALSE);
	  }
	}

void
ars_GetListVUI(ctrl, schema, changedSince=0)
	ARControlStruct *	ctrl
	char *			schema
	unsigned int		changedSince
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 3
	  ARStatusList     status;
	  ARInternalIdList idList;
	  int              ret = 0;
      unsigned int     i = 0;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&idList, 1, ARInternalIdList);

	  ret = ARGetListVUI(ctrl, schema, 
				changedSince,
#if AR_CURRENT_API_VERSION >= 17
				NULL,     /* &objPropList (undocumented by BMC) */
#endif
				&idList,
				&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	    for(i = 0 ; i < idList.numItems ; i++) {
		XPUSHs(sv_2mortal(newSViv(idList.internalIdList[i])));
	    }
	  }
	  FreeARInternalIdList(&idList, FALSE);
#else /* ars 2.x */
	  (void) ARError_reset();
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}

void
ars_SetServerInfo(ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
		ARStatusList     status;
		ARServerInfoList serverInfo;
		int		 ret = 0, i = 0, count = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&serverInfo, 1, ARServerInfoList);

		if((items == 1) || ((items % 2) == 0)) { 
			(void) ARError_add(AR_RETURN_ERROR, 
					   AP_ERR_BAD_ARGS);
		} else {
			unsigned int infoType, j = 0;
			char         buf[256];

			serverInfo.numItems = (items - 1) / 2;
			serverInfo.serverInfoList = MALLOCNN(serverInfo.numItems * sizeof(ARServerInfoStruct));
			/* Zero(serverInfo.serverInfoList, 1, ARServerInfoStruct); # happens already in MALLOCNN */

			for(j = 0 ; j < serverInfo.numItems ; ++j) {
				i = 2 * j + 1;

				infoType = lookUpServerInfoTypeHint(SvIV(ST(i)));
				serverInfo.serverInfoList[j].operation = SvIV(ST(i));
				serverInfo.serverInfoList[j].value.dataType = infoType;

				switch(infoType) {
				case AR_DATA_TYPE_CHAR:
					serverInfo.serverInfoList[j].value.u.charVal = strdup(SvPV(ST(i+1), PL_na));
					break;
				case AR_DATA_TYPE_INTEGER:
					serverInfo.serverInfoList[j].value.u.intVal = SvIV(ST(i+1));
					break;
				default:
					sprintf( buf, "(%d) type = %d", serverInfo.serverInfoList[j].operation, serverInfo.serverInfoList[j].value.dataType );
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS, 
						buf);
					FreeARServerInfoList(&serverInfo, FALSE);
					XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
					goto SetServerInfo_fail;
				}
			}
			ret = ARSetServerInfo(ctrl, &serverInfo, &status);
			FreeARServerInfoList(&serverInfo, FALSE);
			if(ARError(ret, status)) {
				XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
			} else {
				XPUSHs(sv_2mortal(newSViv(1))); /* OK */
			}
		}
	SetServerInfo_fail:;
	}

void
ars_GetServerInfo(ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
	  ARStatusList            status;
	  ARServerInfoRequestList requestList;
	  ARServerInfoList        serverInfo;
	  int                     ret = 0;
          int                     i  = 0;
          unsigned int            ui = 0, count = 0;
	  unsigned int            rlist[AR_MAX_SERVER_INFO_USED];

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&requestList, 1, ARServerInfoRequestList);
	  Zero(&serverInfo, 1, ARServerInfoList);
	  count = 0;
	  if(items == 1) { /* none specified.. fetch all */
	     for(i = 0; i < AR_MAX_SERVER_INFO_USED ; i++) {
	        /* we'll exclude ones that can't be retrieved to avoid errors */
	        switch(i+1) {
	           case AR_SERVER_INFO_DB_PASSWORD:
#if AR_CURRENT_API_VERSION < 17
	           case 332:
	           case 331:
	           case 330:
	           case 329:
	           case 328:
	           case 327:
	           case 326:
	           case 325:
#endif
	           break;
	        default:
	           rlist[count++] = i+1;
	        }
         }
	  }else if(items > AR_MAX_SERVER_INFO_USED + 1) {
	    ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }else { /* user has asked for specific ones */
	     for(i = 1 ; i < items ; i++) {
	        rlist[count++] = SvIV(ST(i));
	     }
	  }
	  if(count > 0) {
	     requestList.numItems = count;
	     requestList.requestList = rlist;
	     ret = ARGetServerInfo(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
	     ((ars_ctrl *)ctrl)->queries++;
#endif
	     if(!ARError( ret, status)) {
	        for(ui = 0 ; ui < serverInfo.numItems ; ui++) {
		/* provided we have a mapping for the operation code, 
		 * push out it's translation. else push out the code itself
		 */
		   if(serverInfo.serverInfoList[ui].operation <= AR_MAX_SERVER_INFO_USED) {
		      /* printf( "%d %s: data type = %d\n", serverInfo.serverInfoList[ui].operation, ServerInfoMap[serverInfo.serverInfoList[ui].operation].name, serverInfo.serverInfoList[ui].value.dataType ); */
	  	      XPUSHs(sv_2mortal(newSVpv(ServerInfoMap[serverInfo.serverInfoList[ui].operation].name, 0)));
		   } else {
		      XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].operation)));
		   }
		      XPUSHs(sv_2mortal(perl_ARValueStruct(ctrl,
			&(serverInfo.serverInfoList[ui].value))));
	        }
	     }
	    FreeARServerInfoList(&serverInfo, FALSE);
	  }
	}

HV *
ars_GetVUI(ctrl, schema, vuiId)
	ARControlStruct *	ctrl
	char *			schema
	ARInternalId		vuiId
	CODE:
	{
#if AR_EXPORT_VERSION >= 3
	  ARStatusList status;
	  ARNameType   vuiName;
	  ARPropList   dPropList;
	  char        *helpText = CPNULL;
	  ARTimestamp  timestamp;
	  ARAccessNameType   owner;
	  ARAccessNameType   lastChanged;
	  char        *changeDiary = CPNULL;
	  int          ret = 0;
	  ARDiaryList  diaryList;
	  ARPropList   objPropList;
# if AR_EXPORT_VERSION >= 6
	  unsigned int vuiType = 0;
	  ARLocaleType locale;
	  Zero(locale, 1, ARLocaleType);
# endif
	  RETVAL = newHV();
	  sv_2mortal( (SV*) RETVAL );
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(vuiName, 1, ARNameType);
	  Zero(&dPropList, 1, ARPropList);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&timestamp, 1, ARTimestamp);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(lastChanged, 1, ARAccessNameType);
	  ret = ARGetVUI(ctrl, schema, vuiId, vuiName,
# if AR_EXPORT_VERSION >= 6
			 locale, &vuiType,
# endif
			 &dPropList, &helpText, 
			 &timestamp, owner, lastChanged, &changeDiary,
#if AR_CURRENT_API_VERSION >= 17
			 &objPropList,
#endif
			 &status);
# ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
# endif
	  if(!ARError( ret, status)) {
# if AR_EXPORT_VERSION >= 6
	     hv_store(RETVAL, "locale", strlen("locale"), newSVpv(locale, 0), 0);
	     hv_store(RETVAL, "vuiType", strlen("vuiType"), newSViv(vuiType), 0);
# endif
	     hv_store(RETVAL,  "schema", strlen("schema") , newSVpv(schema, 0), 0);
	     hv_store(RETVAL,  "vuiId", strlen("vuiId") , newSViv(vuiId), 0);
	     hv_store(RETVAL,  "vuiName", strlen("vuiName") , newSVpv(vuiName, 0), 0);
	     hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	     if(helpText)
	        hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	     hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl,
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	     hv_store(RETVAL,  "props", strlen("props") ,
		 perl_ARList( ctrl,
			    (ARList *)&dPropList,
			    (ARS_fn)perl_ARPropStruct,
			    sizeof(ARPropStruct)), 0);
	     hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
		 perl_ARList( ctrl,
			    (ARList *)&objPropList,
			    (ARS_fn)perl_ARPropStruct,
			    sizeof(ARPropStruct)), 0);
	  }
	  FreeARPropList(&dPropList, FALSE);
	  FreeARPropList(&objPropList, FALSE);
	  if(helpText) {
	    	AP_FREE(helpText);
	  }
	  if(changeDiary) {
	    	AP_FREE(changeDiary);
	  }
#else /* ars 2.x */
	  (void) ARError_reset();
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
	  RETVAL = newHV();
#endif

	}
	OUTPUT:
	RETVAL



int
ars_CreateCharMenu( ctrl, menuDefRef, removeFlag=TRUE )
	ARControlStruct *	ctrl
	SV * menuDefRef
	ARBoolean removeFlag;

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		ARNameType name;
		int ret = 0, rv = 0;
		unsigned int refreshCode;
		char *refreshCodeStr = NULL;
		char *menuTypeStr = NULL;
		ARCharMenuStruct arMenuDef;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList objPropList;
	    char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *menuDef = NULL;
		SV **pSvTemp;

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(&arMenuDef, 1,ARCharMenuStruct);
		Zero(owner, 1,ARAccessNameType);
		Zero(&objPropList, 1,ARPropList);
		Zero(&status, 1,ARStatusList);

		if( SvROK(menuDefRef) && SvTYPE(SvRV(menuDefRef)) == SVt_PVHV ){
			menuDef = (HV*) SvRV(menuDefRef);
		}else{
			croak("usage: ars_CreateCharMenu(...)");
		}

		rv += strcpyHVal( menuDef, "name", name, AR_MAX_NAME_SIZE );

		/* rv += uintcpyHVal( menuDef, "refreshCode", &type ); */
		rv += strmakHVal( menuDef, "refreshCode", &refreshCodeStr );
		refreshCode = revTypeName( (TypeMapStruct*)CharMenuRefreshCodeTypeMap, refreshCodeStr );
		if( refreshCode == TYPEMAP_LAST ){
			ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
					"ars_CreateCharMenu: refreshCode key invalid. key follows:");
			ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
					refreshCodeStr ? refreshCodeStr : "[key null]" );
		}
		if( refreshCodeStr != NULL ){  AP_FREE(refreshCodeStr);  }

		rv += strmakHVal( menuDef, "menuType", &menuTypeStr );
		arMenuDef.menuType = revTypeName( (TypeMapStruct*)CharMenuTypeMap, menuTypeStr );
		if( arMenuDef.menuType == TYPEMAP_LAST ){
			ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
					"ars_CreateCharMenu: menuType key invalid. key follows:");
			ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
					menuTypeStr ? menuTypeStr : "[key null]" );
		}
		if( menuTypeStr != NULL ){  AP_FREE(menuTypeStr);  }

		switch( arMenuDef.menuType ){
		case AR_CHAR_MENU_LIST:
			pSvTemp = hv_fetch( menuDef, "menuList", strlen("menuList") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuList( ctrl, menuDef, "menuList", &(arMenuDef.u.menuList) );
			}
			break;
		case AR_CHAR_MENU_QUERY:
			pSvTemp = hv_fetch( menuDef, "menuQuery", strlen("menuQuery") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuQueryStruct( ctrl, menuDef, "menuQuery", &(arMenuDef.u.menuQuery) );
			}
			break;
		case AR_CHAR_MENU_FILE:
			pSvTemp = hv_fetch( menuDef, "menuFile", strlen("menuFile") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuFileStruct( ctrl, menuDef, "menuFile", &(arMenuDef.u.menuFile) );
			}
			break;
		case AR_CHAR_MENU_SQL:
			pSvTemp = hv_fetch( menuDef, "menuSQL", strlen("menuSQL") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuSQLStruct( ctrl, menuDef, "menuSQL", &(arMenuDef.u.menuSQL) );
			}
			break;
		case AR_CHAR_MENU_SS:
			pSvTemp = hv_fetch( menuDef, "menuSS", strlen("menuSS") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuSSStruct( ctrl, menuDef, "menuSS", &(arMenuDef.u.menuSS) );
			}
			break;
		case AR_CHAR_MENU_DATA_DICTIONARY:
			pSvTemp = hv_fetch( menuDef, "menuDD", strlen("menuDD") , 0 );
			if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
				rv += rev_ARCharMenuDDStruct( ctrl, menuDef, "menuDD", &(arMenuDef.u.menuDD) );
			}
			break;
		}

		objPropList.numItems = 0;
		objPropList.props = NULL;
		pSvTemp = hv_fetch( menuDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARPropList( ctrl, menuDef, "objPropList", &objPropList );
		}

		if( hv_exists(menuDef,"helpText",8) ){
			rv += strmakHVal( menuDef, "helpText", &helpText ); 
		}
		if( hv_exists(menuDef,"owner",5) ){
			rv += strcpyHVal( menuDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(menuDef,"changeDiary",11) ){
			rv += strmakHVal( menuDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARCreateCharMenu( ctrl,
				name,
				refreshCode,
				&arMenuDef,
				helpText,
				owner,
				changeDiary,
				&objPropList,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		FreeARCharMenuStruct( &arMenuDef, FALSE );
		FreeARPropList( &objPropList, FALSE );
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateCharMenu() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL




int
ars_SetCharMenu( ctrl, name, menuDefRef, removeFlag=TRUE )
	ARControlStruct *	ctrl
	ARNameType name
	SV * menuDefRef
	ARBoolean removeFlag;

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType newName;
		char *newNamePtr = NULL;
		unsigned int refreshCode;
		unsigned int *refreshCodePtr = NULL;
		char *refreshCodeStr = NULL;
		char *menuTypeStr = NULL;
		ARCharMenuStruct *arMenuDef = NULL;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *menuDef = NULL;
		SV **pSvTemp;

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(menuDefRef) && SvTYPE(SvRV(menuDefRef)) == SVt_PVHV ){
			menuDef = (HV*) SvRV(menuDefRef);
		}else{
			croak("usage: ars_SetCharMenu(...)");
		}

		if( hv_exists(menuDef,"name",4) ){
			rv += strcpyHVal( menuDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		
		if( hv_exists(menuDef,"refreshCode",4) ){
			/* rv += uintcpyHVal( menuDef, "refreshCode", &refreshCode ); */

			rv += strmakHVal( menuDef, "refreshCode", &refreshCodeStr );
			refreshCode = revTypeName( (TypeMapStruct*)CharMenuRefreshCodeTypeMap, refreshCodeStr );
			if( refreshCode == TYPEMAP_LAST ){
				ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
						"ars_CreateCharMenu: refreshCode key invalid. key follows:");
				ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
						refreshCodeStr ? refreshCodeStr : "[key null]" );
			}
			if( refreshCodeStr != NULL ){  AP_FREE(refreshCodeStr);  }

			refreshCodePtr = &refreshCode;
		}

		if( hv_exists(menuDef,"menuType",4) ){
			/* rv += uintcpyHVal( menuDef, "menuType", &menuType ); */
			arMenuDef = (ARCharMenuStruct*) MALLOCNN( sizeof(ARCharMenuStruct) );

			rv += strmakHVal( menuDef, "menuType", &menuTypeStr );
			arMenuDef->menuType = revTypeName( (TypeMapStruct*)CharMenuTypeMap, menuTypeStr );
			if( arMenuDef->menuType == TYPEMAP_LAST ){
				ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
						"ars_CreateCharMenu: menuType key invalid. key follows:");
				ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
						menuTypeStr ? menuTypeStr : "[key null]" );
			}
			if( menuTypeStr != NULL ){  AP_FREE(menuTypeStr);  }

			switch( arMenuDef->menuType ){
			case AR_CHAR_MENU_LIST:
				pSvTemp = hv_fetch( menuDef, "menuList", strlen("menuList") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuList( ctrl, menuDef, "menuList", &(arMenuDef->u.menuList) );
				}
				break;
			case AR_CHAR_MENU_QUERY:
				pSvTemp = hv_fetch( menuDef, "menuQuery", strlen("menuQuery") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuQueryStruct( ctrl, menuDef, "menuQuery", &(arMenuDef->u.menuQuery) );
				}
				break;
			case AR_CHAR_MENU_FILE:
				pSvTemp = hv_fetch( menuDef, "menuFile", strlen("menuFile") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuFileStruct( ctrl, menuDef, "menuFile", &(arMenuDef->u.menuFile) );
				}
				break;
			case AR_CHAR_MENU_SQL:
				pSvTemp = hv_fetch( menuDef, "menuSQL", strlen("menuSQL") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuSQLStruct( ctrl, menuDef, "menuSQL", &(arMenuDef->u.menuSQL) );
				}
				break;
			case AR_CHAR_MENU_SS:
				pSvTemp = hv_fetch( menuDef, "menuSS", strlen("menuSS") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuSSStruct( ctrl, menuDef, "menuSS", &(arMenuDef->u.menuSS) );
				}
				break;
			case AR_CHAR_MENU_DATA_DICTIONARY:
				pSvTemp = hv_fetch( menuDef, "menuDD", strlen("menuDD") , 0 );
				if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
					rv += rev_ARCharMenuDDStruct( ctrl, menuDef, "menuDD", &(arMenuDef->u.menuDD) );
				}
				break;
			}
		}

		pSvTemp = hv_fetch( menuDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, menuDef, "objPropList", objPropList );
		}

		if( hv_exists(menuDef,"helpText",8) ){
			rv += strmakHVal( menuDef, "helpText", &helpText ); 
		}
		if( hv_exists(menuDef,"owner",5) ){
			rv += strcpyHVal( menuDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(menuDef,"changeDiary",11) ){
			rv += strmakHVal( menuDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARSetCharMenu( ctrl,
				name,
				newNamePtr,
				refreshCodePtr,
				arMenuDef,
				helpText,
				owner,
				changeDiary,
				objPropList,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		if( arMenuDef != NULL ){
			FreeARCharMenuStruct( arMenuDef, TRUE );
		}
		if( objPropList != NULL ){
			FreeARPropList( objPropList, TRUE );
		}
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports SetCharMenu() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


#define STR_TEMP_SIZE  30

int
ars_CreateField( ctrl, schema, fieldDefRef, reservedIdOK=0 )
	ARControlStruct *	ctrl
	ARNameType schema
	SV * fieldDefRef
	ARBoolean reservedIdOK

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARInternalId fieldId;
		ARNameType fieldName;
		ARFieldMappingStruct fieldMap;
		unsigned int dataType;
		unsigned int option;
		unsigned int createMode = AR_FIELD_PROTECTED_AT_CREATE;
#if AR_EXPORT_VERSION >= 9L
		unsigned int fieldOption;
#endif
		ARValueStruct *defaultVal = NULL;
		ARPermissionList permissions;
		ARFieldLimitStruct *limit = NULL;
		ARDisplayInstanceList dInstanceList;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		ARStatusList status;
		HV *fieldDef = NULL;
		SV **pSvTemp;
		char strTemp[STR_TEMP_SIZE+1];

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(owner, 1,ARAccessNameType);
		Zero(fieldName, 1,ARNameType);
		Zero(&status, 1,ARStatusList);
		Zero(&fieldMap, 1,ARFieldMappingStruct);
		Zero(&permissions, 1,ARPermissionList);
		Zero(&dInstanceList, 1, ARDisplayInstanceList);

		if( SvROK(fieldDefRef) && SvTYPE(SvRV(fieldDefRef)) == SVt_PVHV ){
			fieldDef = (HV*) SvRV(fieldDefRef);
		}else{
			croak("usage: ars_CreateField(...)");
		}

		rv += ulongcpyHVal( fieldDef, "fieldId", &fieldId );
		rv += strcpyHVal( fieldDef, "fieldName", fieldName, AR_MAX_NAME_SIZE ); 

		fieldMap.fieldType = AR_FIELD_REGULAR;
		rv += rev_ARFieldMappingStruct( ctrl, fieldDef, "fieldMap", &fieldMap ); 

		rv += strcpyHVal( fieldDef, "dataType", strTemp, STR_TEMP_SIZE ); 
		dataType = caseLookUpTypeNumber( (TypeMapStruct*) DataTypeMap, strTemp );

		rv += uintcpyHVal( fieldDef, "option", &option ); 

		rv += strcpyHVal( fieldDef, "createMode", strTemp, STR_TEMP_SIZE ); 
		if( !strncmp(strTemp,"open",STR_TEMP_SIZE) ){
			createMode = AR_FIELD_OPEN_AT_CREATE;
		}else if( !strncmp(strTemp,"protected",STR_TEMP_SIZE) ){
			createMode = AR_FIELD_PROTECTED_AT_CREATE;
		}else{
			 ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
					"ars_CreateField: invalid createmode:");
			 ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
					 strTemp ? strTemp : "n/a");
		}
#if AR_EXPORT_VERSION >= 9L
		rv += uintcpyHVal( fieldDef, "fieldOption", &fieldOption ); 
#endif
		pSvTemp = hv_fetch( fieldDef, "defaultVal", strlen("defaultVal") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			defaultVal = (ARValueStruct*) MALLOCNN( sizeof(ARValueStruct) );
			rv += rev_ARValueStruct( ctrl, fieldDef, "defaultVal", "dataType", defaultVal );
		}

		permissions.numItems = 0;
		permissions.permissionList = NULL;
		rv += rev_ARPermissionList( ctrl, fieldDef, "permissions", &permissions ); 

		pSvTemp = hv_fetch( fieldDef, "limit", strlen("limit") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			limit = (ARFieldLimitStruct*) MALLOCNN( sizeof(ARFieldLimitStruct) );
			/* rv += rev_ARFieldLimitStruct( ctrl, fieldDef, "limit", "dataType", limit ); */
			rv += rev_ARFieldLimitStruct( ctrl, fieldDef, "limit", limit );
		}
#if AR_CURRENT_API_VERSION >= 17
		pSvTemp = hv_fetch( fieldDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			/* rv += rev_ARPropList( ctrl, fieldDef, "objPropList", "dataType", objPropList ); */
			rv += rev_ARPropList( ctrl, fieldDef, "objPropList", objPropList );
		}
#endif
		rv += rev_ARDisplayInstanceList( ctrl, fieldDef, "displayInstanceList", &dInstanceList );

		if( hv_exists(fieldDef,"helpText",8) ){
			rv += strmakHVal( fieldDef, "helpText", &helpText ); 
		}
		if( hv_exists(fieldDef,"owner",5) ){
			rv += strcpyHVal( fieldDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}

		if( hv_exists(fieldDef,"changeDiary",11) ){
			rv += strmakHVal( fieldDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARCreateField( ctrl,
				schema,
				&fieldId,
				reservedIdOK,
				fieldName,
				&fieldMap,
				dataType,
				option,
				createMode,
#if AR_EXPORT_VERSION >= 9L
				fieldOption,
#endif
				defaultVal,
				&permissions,
				limit,
				&dInstanceList,
				helpText,
				owner,
				changeDiary,
#if AR_CURRENT_API_VERSION >= 17
				objPropList,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : fieldId;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		if( defaultVal != NULL ){
			FreeARValueStruct( defaultVal, TRUE );
		}
		FreeARPermissionList( &permissions, FALSE );
		if( limit != NULL ){
			FreeARFieldLimitStruct( limit, TRUE );
		}
		FreeARDisplayInstanceList( &dInstanceList, FALSE );
		/*
		FreeARStatusList( &status, FALSE );
		printf( "-- FreeARStatusList -- OK\n" );  // _DEBUG_
		*/
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateField() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_SetField( ctrl, schema, fieldId, fieldDefRef )
	ARControlStruct *	ctrl
	ARNameType schema
	ARInternalId fieldId
	SV * fieldDefRef

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType fieldName;
		char *fieldNamePtr = NULL;
		ARFieldMappingStruct *fieldMap = NULL;
		unsigned int *option = NULL;
		unsigned int *createMode = NULL;
#if AR_EXPORT_VERSION >= 9L
		unsigned int *fieldOption = NULL;
#endif
		ARValueStruct *defaultVal = NULL;
		ARPermissionList *permissions = NULL;
		ARFieldLimitStruct *limit = NULL;
		ARDisplayInstanceList *dInstanceList = NULL;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *ownerPtr = NULL;
#if AR_EXPORT_VERSION >= 9L
		unsigned int	setFieldOptions = 0;
#endif
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		ARStatusList status;
		HV *fieldDef = NULL;
		SV **pSvTemp;
		char strTemp[STR_TEMP_SIZE+1];

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(fieldName, 1,ARNameType);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(fieldDefRef) && SvTYPE(SvRV(fieldDefRef)) == SVt_PVHV ){
			fieldDef = (HV*) SvRV(fieldDefRef);
		}else{
			croak("usage: ars_SetField(...)");
		}

		/* rv += ulongcpyHVal( fieldDef, "fieldId", &fieldId ); */

		pSvTemp = hv_fetch( fieldDef, "fieldName", strlen("fieldName") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += strcpyHVal( fieldDef, "fieldName", fieldName, AR_MAX_NAME_SIZE ); 
			fieldNamePtr = fieldName;
		}

		pSvTemp = hv_fetch( fieldDef, "fieldMap", strlen("fieldMap") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			fieldMap = (ARFieldMappingStruct*) MALLOCNN( sizeof(ARFieldMappingStruct) );
			rv += rev_ARFieldMappingStruct( ctrl, fieldDef, "fieldMap", fieldMap ); 
		}

		pSvTemp = hv_fetch( fieldDef, "option", strlen("option") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			option = (unsigned int*) MALLOCNN( sizeof(unsigned int) );
			rv += uintcpyHVal( fieldDef, "option", option ); 
		}

		pSvTemp = hv_fetch( fieldDef, "createMode", strlen("createMode") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			createMode = (unsigned int*) MALLOCNN( sizeof(unsigned int) );
			rv += strcpyHVal( fieldDef, "createMode", strTemp, STR_TEMP_SIZE ); 
			if( !strncmp(strTemp,"open",STR_TEMP_SIZE) ){
				*createMode = AR_FIELD_OPEN_AT_CREATE;
			}else if( !strncmp(strTemp,"protected",STR_TEMP_SIZE) ){
				*createMode = AR_FIELD_PROTECTED_AT_CREATE;
			}else{
				 ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
						"ars_CreateField: invalid createmode:");
				 ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
						 strTemp ? strTemp : "n/a");
			}
		}
#if AR_EXPORT_VERSION >= 9L
		pSvTemp = hv_fetch( fieldDef, "fieldOption", strlen("fieldOption") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			fieldOption = (unsigned int*) MALLOCNN( sizeof(unsigned int) );
			rv += uintcpyHVal( fieldDef, "fieldOption", fieldOption ); 
		}
#endif
		pSvTemp = hv_fetch( fieldDef, "defaultVal", strlen("defaultVal") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			defaultVal = (ARValueStruct*) MALLOCNN( sizeof(ARValueStruct) );
			rv += rev_ARValueStruct( ctrl, fieldDef, "defaultVal", "dataType", defaultVal );
		}

		pSvTemp = hv_fetch( fieldDef, "permissions", strlen("permissions") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			permissions = (ARPermissionList*) MALLOCNN( sizeof(ARPermissionList) );
			rv += rev_ARPermissionList( ctrl, fieldDef, "permissions", permissions ); 
		}

		pSvTemp = hv_fetch( fieldDef, "limit", strlen("limit") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			limit = (ARFieldLimitStruct*) MALLOCNN( sizeof(ARFieldLimitStruct) );
			/* rv += rev_ARFieldLimitStruct( ctrl, fieldDef, "limit", "dataType", limit ); */
			rv += rev_ARFieldLimitStruct( ctrl, fieldDef, "limit", limit );
		}
#if AR_CURRENT_API_VERSION >= 17
		pSvTemp = hv_fetch( fieldDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			/* rv += rev_ARPropList( ctrl, fieldDef, "objPropList", "dataType", objPropList ); */
			rv += rev_ARPropList( ctrl, fieldDef, "objPropList", objPropList );
		}
#endif
		pSvTemp = hv_fetch( fieldDef, "displayInstanceList", strlen("displayInstanceList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			dInstanceList = (ARDisplayInstanceList*) MALLOCNN( sizeof(ARDisplayInstanceList) );
			rv += rev_ARDisplayInstanceList( ctrl, fieldDef, "displayInstanceList", dInstanceList );
		}

		if( hv_exists(fieldDef,"helpText",8) ){
			rv += strmakHVal( fieldDef, "helpText", &helpText ); 
		}
		if( hv_exists(fieldDef,"owner",5) ){
			rv += strcpyHVal( fieldDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
			ownerPtr = owner;
		}
#if AR_EXPORT_VERSION >= 9L
		pSvTemp = hv_fetch( fieldDef, "setFieldOptions", strlen("setFieldOptions") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += uintcpyHVal( fieldDef, "setFieldOptions", &setFieldOptions );
		}
#endif
		if( hv_exists(fieldDef,"changeDiary",11) ){
			rv += strmakHVal( fieldDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARSetField( ctrl,
				schema,
				fieldId,
				fieldNamePtr,
				fieldMap,
				option,
				createMode,
#if AR_EXPORT_VERSION >= 9L
				fieldOption,
#endif
				defaultVal,
				permissions,
				limit,
				dInstanceList,
				helpText,
				ownerPtr,
				changeDiary,
#if AR_EXPORT_VERSION >= 9L
				setFieldOptions,
#endif
#if AR_CURRENT_API_VERSION >= 17
				objPropList,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : fieldId;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}
		
	    if( createMode != NULL ){
			AP_FREE( createMode );
		}
	    if( option != NULL ){
			AP_FREE( option );
		}
	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		if( defaultVal != NULL ){
			FreeARValueStruct( defaultVal, TRUE );
		}
		if( permissions != NULL ){
			FreeARPermissionList( permissions, TRUE );
		}
		if( limit != NULL ){
			FreeARFieldLimitStruct( limit, TRUE );
		}
		if( dInstanceList != NULL ){
			FreeARDisplayInstanceList( dInstanceList, TRUE );
		}
		/*
		FreeARStatusList( &status, FALSE );
		printf( "-- FreeARStatusList -- OK\n" );  // _DEBUG_
		*/
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports SetField() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_CreateSchema( ctrl, schemaDefRef )
	ARControlStruct *	ctrl
	SV * schemaDefRef

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType name;
		ARCompoundSchema compoundSchema;
		ARPermissionList groupList;
		ARInternalIdList admingrpList;
		AREntryListFieldList getListFields;
		ARSortList sortList;
		ARIndexList indexList;
#if AR_EXPORT_VERSION >= 8L
		ARArchiveInfoStruct *archiveInfo = NULL;
#endif
#if AR_EXPORT_VERSION >= 9L
		ARAuditInfoStruct *auditInfo = NULL;
#endif
		ARNameType defaultVui;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *schemaDef = NULL;
		SV **pSvTemp;
		/* char strTemp[STR_TEMP_SIZE+1]; */

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(name, 1,ARNameType);
		Zero(&compoundSchema, 1,ARCompoundSchema);
		Zero(&groupList, 1,ARPermissionList);
		Zero(&admingrpList, 1,ARInternalIdList);
		Zero(&getListFields, 1,AREntryListFieldList);
		Zero(&sortList, 1,ARSortList);
		Zero(&indexList, 1,ARIndexList);
		Zero(defaultVui, 1,ARNameType);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(schemaDefRef) && SvTYPE(SvRV(schemaDefRef)) == SVt_PVHV ){
			schemaDef = (HV*) SvRV(schemaDefRef);
		}else{
			croak("usage: ars_CreateSchema(...)");
		}

		rv += strcpyHVal( schemaDef, "name", name, AR_MAX_NAME_SIZE );

		compoundSchema.schemaType = AR_SCHEMA_REGULAR;
		pSvTemp = hv_fetch( schemaDef, "schema", strlen("schema") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARCompoundSchema( ctrl, schemaDef, "schema", &compoundSchema ); 
		}

		groupList.numItems = 0;
		groupList.permissionList = NULL;
		pSvTemp = hv_fetch( schemaDef, "groupList", strlen("groupList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARPermissionList( ctrl, schemaDef, "groupList", &groupList ); 
		}

		admingrpList.numItems = 0;
		admingrpList.internalIdList = NULL;
		pSvTemp = hv_fetch( schemaDef, "adminList", strlen("adminList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARInternalIdList( ctrl, schemaDef, "adminList", &admingrpList ); 
		}

		getListFields.numItems = 0;
		getListFields.fieldsList = NULL;
		pSvTemp = hv_fetch( schemaDef, "getListFields", strlen("getListFields") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_AREntryListFieldList( ctrl, schemaDef, "getListFields", &getListFields ); 
		}
		
		sortList.numItems = 0;
		sortList.sortList = NULL;
		pSvTemp = hv_fetch( schemaDef, "sortList", strlen("sortList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARSortList( ctrl, schemaDef, "sortList", &sortList ); 
		}

		indexList.numItems = 0;
		indexList.indexList = NULL;
		pSvTemp = hv_fetch( schemaDef, "indexList", strlen("indexList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARIndexList( ctrl, schemaDef, "indexList", &indexList ); 
		}
#if AR_EXPORT_VERSION >= 8L
		pSvTemp = hv_fetch( schemaDef, "archiveInfo", strlen("archiveInfo") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			archiveInfo = (ARArchiveInfoStruct*) MALLOCNN( sizeof(ARArchiveInfoStruct) );
			rv += rev_ARArchiveInfoStruct( ctrl, schemaDef, "archiveInfo", archiveInfo );
		}
#endif
#if AR_EXPORT_VERSION >= 9L
		pSvTemp = hv_fetch( schemaDef, "auditInfo", strlen("auditInfo") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			auditInfo = (ARAuditInfoStruct*) MALLOCNN( sizeof(ARAuditInfoStruct) );
			rv += rev_ARAuditInfoStruct( ctrl, schemaDef, "auditInfo", auditInfo );
		}
#endif
		rv += strcpyHVal( schemaDef, "defaultVui", defaultVui, AR_MAX_NAME_SIZE ); 

		if( hv_exists(schemaDef,"helpText",8) ){
			rv += strmakHVal( schemaDef, "helpText", &helpText ); 
		}
		if( hv_exists(schemaDef,"owner",5) ){
			rv += strcpyHVal( schemaDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(schemaDef,"changeDiary",11) ){
			rv += strmakHVal( schemaDef, "changeDiary", &changeDiary );
		}

		pSvTemp = hv_fetch( schemaDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, schemaDef, "objPropList", objPropList );
		}

		if( rv == 0 ){
			ret = ARCreateSchema( ctrl,
				name,
				&compoundSchema,
#if AR_EXPORT_VERSION >= 8L
				NULL,           /* schemaInheritanceList, reserved for future use */
#endif
				&groupList,
				&admingrpList,
				&getListFields,
				&sortList,
				&indexList,
#if AR_EXPORT_VERSION >= 8L
				archiveInfo,
#endif
#if AR_EXPORT_VERSION >= 9L
				auditInfo,
#endif
				defaultVui,
				helpText,
				owner,
				changeDiary,
				objPropList,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

		if( helpText != NULL ){
			AP_FREE( helpText );
		}
		if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		FreeARCompoundSchema( &compoundSchema, FALSE ); // TODO: we need our own free routine
		AP_FREE(groupList.permissionList);
		AP_FREE(admingrpList.internalIdList);
		AP_FREE(getListFields.fieldsList);
		AP_FREE(sortList.sortList);
		AP_FREE(indexList.indexList);
#if AR_EXPORT_VERSION >= 8L
		if( archiveInfo != NULL ){
			FreeARArchiveInfoStruct( archiveInfo, TRUE ); // TODO: we need our own free routine
		}
#endif
		if( objPropList != NULL ){
			FreeARPropList( objPropList, TRUE ); // TODO: we need our own free routine
		}
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateSchema() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL




int
ars_SetSchema( ctrl, name, schemaDefRef )
	ARControlStruct *	ctrl
	ARNameType name
	SV * schemaDefRef

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType newName;
		char *newNamePtr = NULL;
		ARCompoundSchema *compoundSchema = NULL;
		ARPermissionList *groupList = NULL;
		ARInternalIdList *admingrpList = NULL;
		AREntryListFieldList *getListFields = NULL;
		ARSortList *sortList = NULL;
		ARIndexList *indexList = NULL;
#if AR_EXPORT_VERSION >= 8L
		ARArchiveInfoStruct *archiveInfo = NULL;
#endif
#if AR_EXPORT_VERSION >= 9L
		ARAuditInfoStruct *auditInfo = NULL;
#endif
		ARNameType defaultVui;
		char *defaultVuiPtr = NULL;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *ownerPtr = NULL; 
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *schemaDef = NULL;
		SV **pSvTemp;
		/* char strTemp[STR_TEMP_SIZE+1]; */

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(newName, 1,ARNameType);
		Zero(defaultVui, 1,ARNameType);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(schemaDefRef) && SvTYPE(SvRV(schemaDefRef)) == SVt_PVHV ){
			schemaDef = (HV*) SvRV(schemaDefRef);
		}else{
			croak("usage: ars_SetSchema(...)");
		}


		if( hv_exists(schemaDef,"name",4) ){
			rv += strcpyHVal( schemaDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		
		pSvTemp = hv_fetch( schemaDef, "schema", strlen("schema") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			compoundSchema = (ARCompoundSchema*) MALLOCNN( sizeof(ARCompoundSchema) );
			rv += rev_ARCompoundSchema( ctrl, schemaDef, "schema", compoundSchema ); 
		}

		pSvTemp = hv_fetch( schemaDef, "groupList", strlen("groupList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			groupList = (ARPermissionList*) MALLOCNN( sizeof(ARPermissionList) );
			rv += rev_ARPermissionList( ctrl, schemaDef, "groupList", groupList ); 
		}

		pSvTemp = hv_fetch( schemaDef, "adminList", strlen("adminList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			admingrpList = (ARInternalIdList*) MALLOCNN( sizeof(ARInternalIdList) );
			rv += rev_ARInternalIdList( ctrl, schemaDef, "adminList", admingrpList ); 
		}

		pSvTemp = hv_fetch( schemaDef, "getListFields", strlen("getListFields") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			getListFields = (AREntryListFieldList*) MALLOCNN( sizeof(AREntryListFieldList) );
			rv += rev_AREntryListFieldList( ctrl, schemaDef, "getListFields", getListFields ); 
		}
		
		pSvTemp = hv_fetch( schemaDef, "sortList", strlen("sortList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			sortList = (ARSortList*) MALLOCNN( sizeof(ARSortList) );
			rv += rev_ARSortList( ctrl, schemaDef, "sortList", sortList ); 
		}

		pSvTemp = hv_fetch( schemaDef, "indexList", strlen("indexList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			indexList = (ARIndexList*) MALLOCNN( sizeof(ARIndexList) );
			rv += rev_ARIndexList( ctrl, schemaDef, "indexList", indexList ); 
		}
#if AR_EXPORT_VERSION >= 8L
		pSvTemp = hv_fetch( schemaDef, "archiveInfo", strlen("archiveInfo") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			archiveInfo = (ARArchiveInfoStruct*) MALLOCNN( sizeof(ARArchiveInfoStruct) );
			rv += rev_ARArchiveInfoStruct( ctrl, schemaDef, "archiveInfo", archiveInfo );
		}
#endif
#if AR_EXPORT_VERSION >= 9L
		pSvTemp = hv_fetch( schemaDef, "auditInfo", strlen("auditInfo") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			auditInfo = (ARAuditInfoStruct*) MALLOCNN( sizeof(ARAuditInfoStruct) );
			rv += rev_ARAuditInfoStruct( ctrl, schemaDef, "auditInfo", auditInfo );
		}
#endif
		if( hv_exists(schemaDef,"defaultVui",10) ){
			rv += strcpyHVal( schemaDef, "defaultVui", defaultVui, AR_MAX_NAME_SIZE ); 
			defaultVuiPtr = defaultVui;
		}

		if( hv_exists(schemaDef,"helpText",8) ){
			rv += strmakHVal( schemaDef, "helpText", &helpText ); 
		}
		if( hv_exists(schemaDef,"owner",5) ){
			rv += strcpyHVal( schemaDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
			ownerPtr = owner;
		}
		if( hv_exists(schemaDef,"changeDiary",11) ){
			rv += strmakHVal( schemaDef, "changeDiary", &changeDiary );
		}

		pSvTemp = hv_fetch( schemaDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, schemaDef, "objPropList", objPropList );
		}


		if( rv == 0 ){
			ret = ARSetSchema( ctrl,
				name,
				newNamePtr,
				compoundSchema,
#if AR_EXPORT_VERSION >= 8L
				NULL,           /* schemaInheritanceList, reserved for future use */
#endif
				groupList,
				admingrpList,
				getListFields,
				sortList,
				indexList,
#if AR_EXPORT_VERSION >= 8L
				archiveInfo,
#endif
#if AR_EXPORT_VERSION >= 9L
				auditInfo,
#endif
				defaultVuiPtr,
				helpText,
				ownerPtr,
				changeDiary,
				objPropList,
#if AR_EXPORT_VERSION >= 8L
				0,              /* setOption, reserved for future use */
#endif
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		if( compoundSchema != NULL ){
			FreeARCompoundSchema( compoundSchema, TRUE );
		}
		if( groupList != NULL ){
			FreeARPermissionList( groupList, TRUE );
		}
		if( admingrpList != NULL ){
			FreeARInternalIdList( admingrpList, TRUE );
		}
		if( getListFields != NULL ){
			FreeAREntryListFieldList( getListFields, TRUE );
		}
		if( sortList != NULL ){
			FreeARSortList( sortList, TRUE );
		}
		if( indexList != NULL ){
			FreeARIndexList( indexList, TRUE );
		}
#if AR_EXPORT_VERSION >= 8L
		if( archiveInfo != NULL ){
			FreeARArchiveInfoStruct( archiveInfo, TRUE );
		}
#endif
		if( objPropList != NULL ){
			FreeARPropList( objPropList, TRUE );
		}
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports SetSchema() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_CreateVUI( ctrl, schemaName, vuiDefRef )
	ARControlStruct *	ctrl
	ARNameType schemaName
	SV * vuiDefRef

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARInternalId vuiId = 0;
		ARNameType vuiName;
		ARLocaleType locale;
		unsigned int vuiType;
		ARPropList dPropList;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList objPropList;
		ARStatusList status;
		HV *vuiDef = NULL;
		SV **pSvTemp;

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(vuiName, 1,ARNameType);
		Zero(locale, 1,ARLocaleType);
		Zero(&dPropList, 1,ARPropList);
		Zero(&objPropList, 1,ARPropList);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(vuiDefRef) && SvTYPE(SvRV(vuiDefRef)) == SVt_PVHV ){
			vuiDef = (HV*) SvRV(vuiDefRef);
		}else{
			croak("usage: ars_CreateVUI(...)");
		}


		rv += ulongcpyHVal( vuiDef, "vuiId", &vuiId ); 
		rv += strcpyHVal( vuiDef, "vuiName", vuiName, AR_MAX_NAME_SIZE ); 
#if AR_CURRENT_API_VERSION >= 11
		rv += strcpyHVal( vuiDef, "locale", locale, AR_MAX_LOCALE_SIZE ); 
#else
		rv += strcpyHVal( vuiDef, "locale", locale, AR_MAX_LANG_SIZE ); 
#endif
		rv += uintcpyHVal( vuiDef, "vuiType", &vuiType ); 

		dPropList.numItems = 0;
		dPropList.props = NULL;
		pSvTemp = hv_fetch( vuiDef, "props", strlen("props") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			/* dPropList.props = (ARPropStruct*) MALLOCNN( sizeof(ARPropStruct) ); */
			rv += rev_ARPropList( ctrl, vuiDef, "props", &dPropList );
		}
#if AR_CURRENT_API_VERSION >= 17
		objPropList.numItems = 0;
		objPropList.props = NULL;
		pSvTemp = hv_fetch( vuiDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			/* objPropList.props = (ARPropStruct*) MALLOCNN( sizeof(ARPropStruct) ); */
			rv += rev_ARPropList( ctrl, vuiDef, "objPropList", &objPropList );
		}
#endif
		if( hv_exists(vuiDef,"helpText",8) ){
			rv += strmakHVal( vuiDef, "helpText", &helpText ); 
		}
		if( hv_exists(vuiDef,"owner",5) ){
			rv += strcpyHVal( vuiDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(vuiDef,"changeDiary",11) ){
			rv += strmakHVal( vuiDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARCreateVUI( ctrl,
				schemaName,
				&vuiId,
				vuiName,
				locale,
				vuiType,
				&dPropList,
				helpText,
				owner,
				changeDiary,
#if AR_CURRENT_API_VERSION >= 17
				&objPropList,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		FreeARPropList( &dPropList, FALSE );
		FreeARPropList( &objPropList, FALSE );
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateVUI() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_SetVUI( ctrl, schemaName, vuiId, vuiDefRef )
	ARControlStruct *	ctrl
	ARNameType schemaName
	ARInternalId vuiId
	SV * vuiDefRef

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType vuiName;
		char *vuiNamePtr = NULL;
		ARLocaleType locale;
		char *localePtr = NULL;
		unsigned int vuiType;
		unsigned int *vuiTypePtr = NULL;
		ARPropList *dPropList = NULL;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *ownerPtr = NULL;
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		ARStatusList status;
		HV *vuiDef = NULL;
		SV **pSvTemp;

		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(vuiName, 1,ARNameType);
		Zero(locale, 1,ARLocaleType);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);


		if( SvROK(vuiDefRef) && SvTYPE(SvRV(vuiDefRef)) == SVt_PVHV ){
			vuiDef = (HV*) SvRV(vuiDefRef);
		}else{
			croak("usage: ars_SetVUI(...)");
		}


		/* rv += ulongcpyHVal( vuiDef, "vuiId", &vuiId ); */

		
		if( hv_exists(vuiDef,"vuiName",7) ){
			rv += strcpyHVal( vuiDef, "vuiName", vuiName, AR_MAX_NAME_SIZE ); 
			vuiNamePtr = vuiName;
		}
		if( hv_exists(vuiDef,"locale",6) ){
#if AR_CURRENT_API_VERSION >= 11
			rv += strcpyHVal( vuiDef, "locale", locale, AR_MAX_LOCALE_SIZE );
#else
			rv += strcpyHVal( vuiDef, "locale", locale, AR_MAX_LANG_SIZE );
#endif
			localePtr = locale;
		}
		
		if( hv_exists(vuiDef,"vuiType",7) ){
			rv += uintcpyHVal( vuiDef, "vuiType", &vuiType ); 
			vuiTypePtr = &vuiType;
		}


		pSvTemp = hv_fetch( vuiDef, "props", strlen("props") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			dPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, vuiDef, "props", dPropList );
		}
#if AR_CURRENT_API_VERSION >= 17
		pSvTemp = hv_fetch( vuiDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, vuiDef, "objPropList", objPropList );
		}
#endif
		if( hv_exists(vuiDef,"helpText",8) ){
			rv += strmakHVal( vuiDef, "helpText", &helpText ); 
		}
		
		if( hv_exists(vuiDef,"owner",5) ){
			rv += strcpyHVal( vuiDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE );
			ownerPtr = owner;
		}
		if( hv_exists(vuiDef,"changeDiary",11) ){
			rv += strmakHVal( vuiDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARSetVUI( ctrl,
				schemaName,
				vuiId,
				vuiNamePtr,
				localePtr,
				vuiTypePtr,
				dPropList,
				helpText,
				owner,
				changeDiary,
#if AR_CURRENT_API_VERSION >= 17
				objPropList,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		FreeARPropList( dPropList, TRUE );
		FreeARPropList( objPropList, TRUE );
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports SetVUI() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL




int
ars_CreateContainer( ctrl, containerDefRef, removeFlag=TRUE )
	ARControlStruct *	ctrl
	SV * containerDefRef
	ARBoolean removeFlag;

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType name;
		ARPermissionList groupList;
		ARInternalIdList admingrpList;
		ARContainerOwnerObjList ownerObjList;
		char *label = NULL;
		char *description = NULL;
		char *typeStr = NULL;
		unsigned int type;
		ARReferenceList references;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList objPropList;
		char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *containerDef = NULL;
		SV **pSvTemp;


		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(name, 1,ARNameType);
		Zero(&groupList, 1,ARPermissionList);
		Zero(&admingrpList, 1,ARInternalIdList);
		Zero(&ownerObjList, 1,ARContainerOwnerObjList);
		Zero(&references, 1,ARReferenceList);
		Zero(owner, 1,ARAccessNameType);
		Zero(&objPropList, 1,ARPropList);
		Zero(&status, 1,ARStatusList);

		if( SvROK(containerDefRef) && SvTYPE(SvRV(containerDefRef)) == SVt_PVHV ){
			containerDef = (HV*) SvRV(containerDefRef);
		}else{
			croak("usage: ars_CreateContainer(...)");
		}

		rv += strcpyHVal( containerDef, "name", name, AR_MAX_NAME_SIZE );

		/* rv += uintcpyHVal( containerDef, "type", &type ); */
		rv += strmakHVal( containerDef, "type", &typeStr );
		type = revTypeName( (TypeMapStruct*)ContainerTypeMap, typeStr );
		if( type == TYPEMAP_LAST ){
			ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
					"ars_CreateContainer: type key invalid. key follows:");
			ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
					typeStr ? typeStr : "[key null]" );
		}
		if( typeStr != NULL ){  AP_FREE(typeStr);  }

		groupList.numItems = 0;
		groupList.permissionList = NULL;
		pSvTemp = hv_fetch( containerDef, "groupList", strlen("groupList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARPermissionList( ctrl, containerDef, "groupList", &groupList );
		}

		admingrpList.numItems = 0;
		admingrpList.internalIdList = NULL;
		pSvTemp = hv_fetch( containerDef, "adminList", strlen("adminList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARInternalIdList( ctrl, containerDef, "adminList", &admingrpList );
		}

		ownerObjList.numItems = 0;
		ownerObjList.ownerObjList = NULL;
		pSvTemp = hv_fetch( containerDef, "ownerObjList", strlen("ownerObjList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARContainerOwnerObjList( ctrl, containerDef, "ownerObjList", &ownerObjList );
		}

		objPropList.numItems = 0;
		objPropList.props = NULL;
		pSvTemp = hv_fetch( containerDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARPropList( ctrl, containerDef, "objPropList", &objPropList );
		}

		references.numItems = 0;
		references.referenceList = NULL;
		pSvTemp = hv_fetch( containerDef, "referenceList", strlen("referenceList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			rv += rev_ARReferenceList( ctrl, containerDef, "referenceList", &references );
		}

		if( hv_exists(containerDef,"label",5) ){
			rv += strmakHVal( containerDef, "label", &label ); 
		}
		if( hv_exists(containerDef,"description",11) ){
			rv += strmakHVal( containerDef, "description", &description ); 
		}
		if( hv_exists(containerDef,"helpText",8) ){
			rv += strmakHVal( containerDef, "helpText", &helpText ); 
		}
		if( hv_exists(containerDef,"owner",5) ){
			rv += strcpyHVal( containerDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(containerDef,"changeDiary",11) ){
			rv += strmakHVal( containerDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARCreateContainer( ctrl,
				name,
				&groupList,
				&admingrpList,
				&ownerObjList,
				label,
				description,
				type,
				&references,
				removeFlag,
				helpText,
				owner,
				changeDiary,
				&objPropList,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( label != NULL ){
			AP_FREE( label );
		}
	    if( description != NULL ){
			AP_FREE( description );
		}
	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		FreeARPermissionList( &groupList, FALSE );
		FreeARInternalIdList( &admingrpList, FALSE );
		FreeARContainerOwnerObjList( &ownerObjList, FALSE );
		FreeARReferenceList( &references, FALSE );
		FreeARPropList( &objPropList, FALSE );
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL




int
ars_SetContainer( ctrl, name, containerDefRef, removeFlag=TRUE )
	ARControlStruct *	ctrl
	ARNameType name
	SV * containerDefRef
	ARBoolean removeFlag;

	CODE:
	{
#if AR_EXPORT_VERSION >= 6L
		int ret = 0, rv = 0;
		ARNameType newName;
		char *newNamePtr = NULL;
		ARPermissionList *groupList = NULL;
		ARInternalIdList *admingrpList = NULL;
		ARContainerOwnerObjList *ownerObjList = NULL;
		char *label = NULL;
		char *description = NULL;
		char *typeStr = NULL;
		unsigned int type;
		unsigned int *typePtr = NULL;
		ARReferenceList *references = NULL;
		char *helpText = NULL;
		ARAccessNameType owner;
		char *changeDiary = NULL;
		ARPropList *objPropList = NULL;
		char *objectModificationLogLabel = NULL;
		ARStatusList status;
		HV *containerDef = NULL;
		SV **pSvTemp;


		RETVAL = 0; /* assume error */
		(void) ARError_reset();
		Zero(newName, 1,ARNameType);
		Zero(owner, 1,ARAccessNameType);
		Zero(&status, 1,ARStatusList);

		if( SvROK(containerDefRef) && SvTYPE(SvRV(containerDefRef)) == SVt_PVHV ){
			containerDef = (HV*) SvRV(containerDefRef);
		}else{
			croak("usage: ars_SetContainer(...)");
		}

		if( hv_exists(containerDef,"name",4) ){
			rv += strcpyHVal( containerDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		
		if( hv_exists(containerDef,"type",4) ){
			/* rv += uintcpyHVal( containerDef, "type", &type ); */

			rv += strmakHVal( containerDef, "type", &typeStr );
			type = revTypeName( (TypeMapStruct*)ContainerTypeMap, typeStr );
			if( type == TYPEMAP_LAST ){
				ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
						"ars_CreateContainer: type key invalid. key follows:");
				ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
						typeStr ? typeStr : "[key null]" );
			}
			if( typeStr != NULL ){  AP_FREE(typeStr);  }

			typePtr = &type;
		}

		pSvTemp = hv_fetch( containerDef, "groupList", strlen("groupList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			groupList = (ARPermissionList*) MALLOCNN( sizeof(ARPermissionList) );
			rv += rev_ARPermissionList( ctrl, containerDef, "groupList", groupList );
		}

		pSvTemp = hv_fetch( containerDef, "adminList", strlen("adminList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			admingrpList = (ARInternalIdList*) MALLOCNN( sizeof(ARInternalIdList) );
			rv += rev_ARInternalIdList( ctrl, containerDef, "adminList", admingrpList );
		}

		pSvTemp = hv_fetch( containerDef, "ownerObjList", strlen("ownerObjList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			ownerObjList = (ARContainerOwnerObjList*) MALLOCNN( sizeof(ARContainerOwnerObjList) );
			rv += rev_ARContainerOwnerObjList( ctrl, containerDef, "ownerObjList", ownerObjList );
		}

		pSvTemp = hv_fetch( containerDef, "objPropList", strlen("objPropList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			objPropList = (ARPropList*) MALLOCNN( sizeof(ARPropList) );
			rv += rev_ARPropList( ctrl, containerDef, "objPropList", objPropList );
		}

		pSvTemp = hv_fetch( containerDef, "referenceList", strlen("referenceList") , 0 );
		if( pSvTemp && *pSvTemp && SvTYPE(*pSvTemp) != SVt_NULL ){
			references = (ARReferenceList*) MALLOCNN( sizeof(ARReferenceList) );
			rv += rev_ARReferenceList( ctrl, containerDef, "referenceList", references );
		}

		if( hv_exists(containerDef,"label",5) ){
			rv += strmakHVal( containerDef, "label", &label ); 
		}
		if( hv_exists(containerDef,"description",11) ){
			rv += strmakHVal( containerDef, "description", &description ); 
		}
		if( hv_exists(containerDef,"helpText",8) ){
			rv += strmakHVal( containerDef, "helpText", &helpText ); 
		}
		if( hv_exists(containerDef,"owner",5) ){
			rv += strcpyHVal( containerDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE ); 
		}
		if( hv_exists(containerDef,"changeDiary",11) ){
			rv += strmakHVal( containerDef, "changeDiary", &changeDiary );
		}

		if( rv == 0 ){
			ret = ARSetContainer( ctrl,
				name,
				newNamePtr,
				groupList,
				admingrpList,
				ownerObjList,
				label,
				description,
				typePtr,
				references,
				removeFlag,
				helpText,
				owner,
				changeDiary,
				objPropList,
#if AR_CURRENT_API_VERSION >= 17
			    objectModificationLogLabel,
#endif
				&status );

			RETVAL = ARError(ret,status) ? 0 : 1;
		}else{ 
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
			RETVAL = 0;
		}

	    if( label != NULL ){
			AP_FREE( label );
		}
	    if( description != NULL ){
			AP_FREE( description );
		}
	    if( helpText != NULL ){
			AP_FREE( helpText );
		}
	    if( changeDiary != NULL ){
			AP_FREE( changeDiary );
		}
		if( groupList != NULL ){
			FreeARPermissionList( groupList, TRUE );
		}
		if( admingrpList != NULL ){
			FreeARInternalIdList( admingrpList, TRUE );
		}
		if( ownerObjList != NULL ){
			FreeARContainerOwnerObjList( ownerObjList, TRUE );
		}
		if( references != NULL ){
			FreeARReferenceList( references, TRUE );
		}
		if( objPropList != NULL ){
			FreeARPropList( objPropList, TRUE );
		}
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports SetContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL



int
ars_CreateActiveLink(ctrl, alDefRef)
	ARControlStruct *	ctrl
	SV *			alDefRef
	CODE:
	{
	  int                    ret = 0, rv = 0;
	  ARNameType             schema, name;
	  ARInternalIdList       groupList;
	  unsigned int           executeMask, order;
#if AR_EXPORT_VERSION >= 3
	  ARInternalId           controlField = 0;
	  ARInternalId           focusField = 0;
#else /* 2.x */
	  ARInternalId           field = 0;
	  ARDisplayList          displayList;
#endif
	  unsigned int           enable = 0;
	  ARQualifierStruct     *query;
	  ARActiveLinkActionList actionList;
#if AR_EXPORT_VERSION >= 3
	  ARActiveLinkActionList elseList;
#endif
	  char                  *helpText = CPNULL;
	  ARAccessNameType       owner;
	  char                  *changeDiary = CPNULL;
	  char                  *objectModificationLogLabel = NULL;
	  ARStatusList           status;
#if AR_EXPORT_VERSION >= 5
	  ARNameList              schemaNameList;
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;
#endif
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(schema, 1, ARNameType);
	  Zero(name, 1, ARNameType);
	  Zero(&groupList, 1,ARInternalIdList);
	  Zero(&actionList, 1,ARActiveLinkActionList);
	  Zero(owner, 1, ARAccessNameType);
#if AR_EXPORT_VERSION >= 3
	  Zero(&elseList, 1,ARActiveLinkActionList);
#else
	  Zero(&displayList, 1,ARDisplayList);
#endif
#if AR_EXPORT_VERSION >= 5
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&schemaNameList, 1, ARNameList);
	  schemaList.type = AR_WORKFLOW_CONN_SCHEMA_LIST;
	  schemaList.u.schemaList = &schemaNameList;
#endif
	  if(SvTYPE((SV *)SvRV(alDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *alDef = (HV *)SvRV(alDefRef);
		SV **qhv = hv_fetch(alDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if(qhv && *qhv && SvROK(*qhv)) {
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, alDef, "query", query ); */
		} else {
			query = (ARQualifierStruct *)NULL;
		}
		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		rv += strcpyHVal( alDef, "name", name, AR_MAX_NAME_SIZE);
#if AR_EXPORT_VERSION >= 5
		rv += rev_ARNameList( ctrl, alDef, "schemaList", schemaList.u.schemaList );
#else
		rv += strcpyHVal( alDef, "schema", schema, AR_MAX_NAME_SIZE);
#endif
		rv += uintcpyHVal( alDef, "order", &order);
		rv += rev_ARInternalIdList(ctrl, alDef, "groupList", &groupList);
		rv += uintcpyHVal( alDef, "executeMask", &executeMask);
		rv += uintcpyHVal( alDef, "enable", &enable);

		if(hv_exists(alDef,  "owner", strlen("owner") ))
			rv += strcpyHVal( alDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
		else
			strncpy(owner, ctrl->user, sizeof(ARAccessNameType));

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(alDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( alDef, "changeDiary", &changeDiary);
		if(hv_exists(alDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( alDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		rv += rev_ARActiveLinkActionList(ctrl, alDef, "actionList", 
						&actionList);
#if AR_EXPORT_VERSION >= 3
		rv += rev_ARActiveLinkActionList(ctrl, alDef, "elseList", 
						&elseList);
		if((executeMask & AR_EXECUTE_ON_RETURN)
		|| (executeMask & AR_EXECUTE_ON_MENU_CHOICE)
#if AR_EXPORT_VERSION >= 4
		|| (executeMask & AR_EXECUTE_ON_GAIN_FOCUS)
		|| (executeMask & AR_EXECUTE_ON_LOSE_FOCUS)
#endif
		)
			rv += ulongcpyHVal( alDef, "focusField", 
					&focusField);
		if(executeMask & AR_EXECUTE_ON_BUTTON) 
			rv += ulongcpyHVal( alDef, "controlField",
					&controlField);
#else /* 2.x */
		if((executeMask & AR_EXECUTE_ON_RETURN) || 
		   (executeMask & AR_EXECUTE_ON_MENU_CHOICE))
			rv += ulongcpyHVal( alDef, "field", &field);
		if(executeMask & AR_EXECUTE_ON_BUTTON)
			rv += rev_ARDisplayList(ctrl,  alDef, "displayList", 
					&displayList);
#endif
#if AR_EXPORT_VERSION >= 5
		if(hv_exists(alDef,  "objPropList", strlen("objPropList") ))
			rv += rev_ARPropList(ctrl, alDef, "objPropList",
					     &objPropList);
#endif
		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * active link.
		 */
		if(rv == 0) {
#if AR_EXPORT_VERSION >= 5
		   ret = ARCreateActiveLink(ctrl, name, order, &schemaList, 
					    &groupList, executeMask,
					    &controlField, &focusField, 
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary, 
					    &objPropList,
#if AR_CURRENT_API_VERSION >= 14
						0,            /* errorActlinkOptions, reserved for future use */
						NULL,         /* errorActlinkName,    reserved for future use */
#endif
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
#elif AR_EXPORT_VERSION >= 3
		   ret = ARCreateActiveLink(ctrl, name, order, schema, 
					    &groupList, executeMask,
					    &controlField, &focusField, 
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary,
					    &status);
#else /* 2.x */
#endif
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  FreeARInternalIdList(&groupList, FALSE);
	  FreeARActiveLinkActionList(&actionList, FALSE);
#if AR_EXPORT_VERSION >= 3
	  FreeARActiveLinkActionList(&elseList, FALSE);
#else /* 2.x */
	  FreeARDisplayList(&displayList, FALSE);
#endif
#if AR_EXPORT_VERSION >= 5
	  FreeARPropList(&objPropList, FALSE);
	  FreeARNameList(&schemaNameList, FALSE);
#endif
	}
	OUTPUT:
	RETVAL


int
ars_SetActiveLink(ctrl, name, objDefRef)
	ARControlStruct *	ctrl
	ARNameType  name
	SV *			objDefRef
	CODE:
	{
#if AR_EXPORT_VERSION >= 5
	  int                      ret = 0, rv = 0;
	  ARNameType               newName;
	  char                    *newNamePtr = NULL;
	  ARInternalIdList        *groupList  = NULL;
	  unsigned int            *executeMask = NULL;
	  unsigned int            *order = NULL;
	  ARInternalId            *controlField = NULL;
	  ARInternalId            *focusField = NULL;
	  unsigned int            *enable = NULL;
	  ARQualifierStruct       *query = NULL;
	  ARActiveLinkActionList  *actionList = NULL;
	  ARActiveLinkActionList  *elseList   = NULL;
	  char                    *helpText = CPNULL;
	  ARAccessNameType         owner;
	  char                    *ownerPtr = NULL;
	  char                    *changeDiary = CPNULL;
	  char                    *objectModificationLogLabel = NULL;
	  ARStatusList             status;
	  ARWorkflowConnectStruct  *schemaList = NULL;
	  ARPropList               *objPropList = NULL;
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(newName, 1, ARNameType);
	  Zero(owner, 1, ARAccessNameType);

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);
		SV **qhv = hv_fetch(objDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if( qhv && *qhv && SvROK(*qhv) ){
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, objDef, "query", query ); */
		}

		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		if( hv_exists(objDef,"name",4) ){
			rv += strcpyHVal( objDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		if( hv_exists(objDef,"schemaList",10) ){
			schemaList = (ARWorkflowConnectStruct*) MALLOCNN(sizeof(ARWorkflowConnectStruct));
			schemaList->type = AR_WORKFLOW_CONN_SCHEMA_LIST;
			schemaList->u.schemaList = (ARNameList*) MALLOCNN( sizeof(ARNameList) );
			rv += rev_ARNameList( ctrl, objDef, "schemaList", schemaList->u.schemaList );
		}
		if( hv_exists(objDef,"order",5) ){
			order = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "order", order );
		}
		if( hv_exists(objDef,"groupList",9) ){
			groupList = (ARInternalIdList*) MALLOCNN(sizeof(ARInternalIdList));
			rv += rev_ARInternalIdList(ctrl, objDef, "groupList", groupList);
		}
		if( hv_exists(objDef,"executeMask",11) ){
			executeMask = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "executeMask", executeMask);
		}
		if( hv_exists(objDef,"enable",6) ){
			enable = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "enable", enable);
		}

		if(hv_exists(objDef,  "owner", strlen("owner") )){
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
			ownerPtr = owner;
		}

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		if(hv_exists(objDef,  "actionList", strlen("actionList") )){
			actionList = (ARActiveLinkActionList*) MALLOCNN(sizeof(ARActiveLinkActionList));
			rv += rev_ARActiveLinkActionList(ctrl, objDef, "actionList", actionList);
		}

		if(hv_exists(objDef,  "elseList", strlen("elseList") )){
			elseList = (ARActiveLinkActionList*) MALLOCNN(sizeof(ARActiveLinkActionList));
			rv += rev_ARActiveLinkActionList(ctrl, objDef, "elseList", elseList);
		}

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") )){
			objPropList = (ARPropList*) MALLOCNN(sizeof(ARPropList));
			rv += rev_ARPropList(ctrl, objDef, "objPropList", objPropList);
		}

		if( executeMask != NULL ){
			if((*executeMask & AR_EXECUTE_ON_RETURN) || 
			   (*executeMask & AR_EXECUTE_ON_MENU_CHOICE)) {
				focusField = (ARInternalId*) MALLOCNN(sizeof(ARInternalId));
				rv += ulongcpyHVal( objDef, "focusField", focusField);
			}
			if(*executeMask & AR_EXECUTE_ON_BUTTON) { 
				controlField = (ARInternalId*) MALLOCNN(sizeof(ARInternalId));
				rv += ulongcpyHVal( objDef, "controlField", controlField);
			}
		}

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to modify the workflow object
		 */
		if(rv == 0) {
		   ret = ARSetActiveLink(ctrl, name, newNamePtr, order, schemaList, 
					    groupList, executeMask,
					    controlField, focusField, 
					    enable, query,
					    actionList, elseList, 
					    helpText, ownerPtr, changeDiary, 
					    objPropList,
#if AR_CURRENT_API_VERSION >= 14
						NULL,         /* errorActlinkOptions, reserved for future use */
						NULL,         /* errorActlinkName,    reserved for future use */
#endif
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }

	  if( order != NULL )        {  AP_FREE(order);  }
	  if( executeMask != NULL )  {  AP_FREE(executeMask);  }
	  if( enable != NULL )       {  AP_FREE(enable);  }
	  if( focusField != NULL )   { AP_FREE(focusField);  }
	  if( controlField != NULL ) { AP_FREE(controlField);  }

	  /* if( query != NULL )       { FreeARARQualifierStruct( query, TRUE );  } */
	  if( schemaList != NULL )   { FreeARWorkflowConnectStruct( schemaList, TRUE );  }
	  if( groupList != NULL )    { FreeARInternalIdList( groupList, TRUE );  }
	  if( actionList != NULL )   { FreeARActiveLinkActionList( actionList, TRUE );  }
	  if( elseList != NULL )     { FreeARActiveLinkActionList( elseList, TRUE );  }
	  if( objPropList != NULL )  { FreeARPropList( objPropList, TRUE );  }
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


int
ars_CreateFilter(ctrl, objDefRef)
	ARControlStruct *	ctrl
	SV *			objDefRef
	CODE:
	{
#if AR_EXPORT_VERSION >= 5
	  int                    ret = 0, rv = 0;
	  ARNameType             schema, name;
	  unsigned int           opSet, order;
	  unsigned int           enable = 0;
	  ARQualifierStruct     *query;
	  ARFilterActionList     actionList;
	  ARFilterActionList     elseList;
	  char                  *helpText = CPNULL;
	  ARAccessNameType       owner;
	  char                  *changeDiary = CPNULL;
	  char                  *objectModificationLogLabel = NULL;
	  ARStatusList           status;
	  ARNameList              schemaNameList;
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;
#if AR_CURRENT_API_VERSION >= 13
	  unsigned int           errorFilterOptions = 0;
	  ARNameType             errorFilterName;
#endif
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(schema, 1, ARNameType);
	  Zero(name, 1, ARNameType);
	  Zero(&actionList, 1,ARFilterActionList);
	  Zero(&elseList, 1,ARFilterActionList);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&schemaNameList, 1, ARNameList);
#if AR_CURRENT_API_VERSION >= 13
	  Zero(errorFilterName, 1, ARNameType);
#endif
	  schemaList.type = AR_WORKFLOW_CONN_SCHEMA_LIST;
	  schemaList.u.schemaList = &schemaNameList;

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);
		SV **qhv = hv_fetch(objDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if(qhv && *qhv && SvROK(*qhv)) {
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, objDef, "query", query ); */
		} else {
			query = (ARQualifierStruct *)NULL;
		}
		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		rv += strcpyHVal( objDef, "name", name, AR_MAX_NAME_SIZE);
		rv += rev_ARNameList( ctrl, objDef, "schemaList", schemaList.u.schemaList );
		rv += uintcpyHVal( objDef, "order", &order);
		rv += uintcpyHVal( objDef, "opSet", &opSet);
		rv += uintcpyHVal( objDef, "enable", &enable);
		
		if(hv_exists(objDef,  "owner", strlen("owner") ))
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
		else
			strncpy(owner, ctrl->user, sizeof(ARAccessNameType));
		
		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		rv += rev_ARFilterActionList(ctrl, objDef, "actionList", 
						&actionList);

		rv += rev_ARFilterActionList(ctrl, objDef, "elseList", 
						&elseList);

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") ))
			rv += rev_ARPropList(ctrl, objDef, "objPropList",
					     &objPropList);
#if AR_CURRENT_API_VERSION >= 13
		if( hv_exists(objDef, "errorFilterOptions", strlen("errorFilterOptions")) )
			rv += uintcpyHVal( objDef, "errorFilterOptions", &errorFilterOptions );

		if( hv_exists(objDef, "errorFilterName", strlen("errorFilterName")) )
			rv += strcpyHVal( objDef, "errorFilterName", errorFilterName, AR_MAX_NAME_SIZE );
#endif

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * filter.
		 */
		if(rv == 0) {
		   ret = ARCreateFilter(ctrl, name, order, &schemaList, 
					    opSet,
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary, 
					    &objPropList,
#if AR_CURRENT_API_VERSION >= 13
					    errorFilterOptions,
					    errorFilterName,
#endif
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  FreeARFilterActionList(&actionList, FALSE);
	  FreeARFilterActionList(&elseList, FALSE);
	  FreeARPropList(&objPropList, FALSE);
	  FreeARNameList(&schemaNameList, FALSE);
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


int
ars_SetFilter(ctrl, name, objDefRef)
	ARControlStruct *	ctrl
	ARNameType  name
	SV *			objDefRef
	CODE:
	{
#if AR_EXPORT_VERSION >= 5
	  int                      ret = 0, rv = 0;
	  ARNameType               newName;
	  char                    *newNamePtr = NULL;
	  unsigned int            *opSet = NULL;
	  unsigned int            *order = NULL;
	  unsigned int            *enable = NULL;
	  ARQualifierStruct       *query = NULL;
	  ARFilterActionList      *actionList = NULL;
	  ARFilterActionList      *elseList   = NULL;
	  char                    *helpText = CPNULL;
	  ARAccessNameType         owner;
	  char                    *ownerPtr = NULL;
	  char                    *changeDiary = CPNULL;
	  char                    *objectModificationLogLabel = NULL;
	  ARStatusList             status;
	  ARWorkflowConnectStruct  *schemaList = NULL;
	  ARPropList               *objPropList = NULL;
#if AR_CURRENT_API_VERSION >= 13
	  unsigned int           *errorFilterOptions = NULL;
	  ARNameType              errorFilterName;
	  char                   *errorFilterNamePtr = NULL;
#endif
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(newName, 1, ARNameType);
	  Zero(owner, 1, ARAccessNameType);
#if AR_CURRENT_API_VERSION >= 13
	  Zero(errorFilterName, 1, ARNameType);
#endif

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);
		SV **qhv = hv_fetch(objDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if( qhv && *qhv && SvROK(*qhv) ){
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, objDef, "query", query ); */
		}

		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		if( hv_exists(objDef,"name",4) ){
			rv += strcpyHVal( objDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		if( hv_exists(objDef,"schemaList",10) ){
			schemaList = (ARWorkflowConnectStruct*) MALLOCNN(sizeof(ARWorkflowConnectStruct));
			schemaList->type = AR_WORKFLOW_CONN_SCHEMA_LIST;
			schemaList->u.schemaList = (ARNameList*) MALLOCNN( sizeof(ARNameList) );
			rv += rev_ARNameList( ctrl, objDef, "schemaList", schemaList->u.schemaList );
		}
		if( hv_exists(objDef,"order",5) ){
			order = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "order", order );
		}
		if( hv_exists(objDef,"opSet",5) ){
			opSet = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "opSet", opSet);
		}
		if( hv_exists(objDef,"enable",6) ){
			enable = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "enable", enable);
		}

		if(hv_exists(objDef,  "owner", strlen("owner") )){
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
			ownerPtr = owner;
		}

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		if(hv_exists(objDef,  "actionList", strlen("actionList") )){
			actionList = (ARFilterActionList*) MALLOCNN(sizeof(ARFilterActionList));
			rv += rev_ARFilterActionList(ctrl, objDef, "actionList", actionList);
		}

		if(hv_exists(objDef,  "elseList", strlen("elseList") )){
			elseList = (ARFilterActionList*) MALLOCNN(sizeof(ARFilterActionList));
			rv += rev_ARFilterActionList(ctrl, objDef, "elseList", elseList);
		}

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") )){
			objPropList = (ARPropList*) MALLOCNN(sizeof(ARPropList));
			rv += rev_ARPropList(ctrl, objDef, "objPropList", objPropList);
		}
#if AR_CURRENT_API_VERSION >= 13
		if( hv_exists(objDef,"errorFilterOptions",18) ){
			errorFilterOptions = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "errorFilterOptions", errorFilterOptions);
		}

		if(hv_exists(objDef, "errorFilterName", strlen("errorFilterName") )){
			rv += strcpyHVal( objDef, "errorFilterName", errorFilterName, AR_MAX_NAME_SIZE);
			errorFilterNamePtr = errorFilterName;
		}
#endif

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to modify the workflow object
		 */
		if(rv == 0) {
		   ret = ARSetFilter(ctrl, name, newNamePtr, order, schemaList, 
					    opSet,
					    enable, query,
					    actionList, elseList, 
					    helpText, ownerPtr, changeDiary, 
					    objPropList, 
#if AR_CURRENT_API_VERSION >= 13
					    errorFilterOptions,
					    errorFilterNamePtr,
#endif
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }

	  if( order != NULL )        {  AP_FREE(order);  }
	  if( enable != NULL )       {  AP_FREE(enable);  }

	  /* if( query != NULL )       { FreeARARQualifierStruct( query, TRUE );  } */
	  if( schemaList != NULL )   { FreeARWorkflowConnectStruct( schemaList, TRUE );  }
	  if( actionList != NULL )   { FreeARFilterActionList( actionList, TRUE );  }
	  if( elseList != NULL )     { FreeARFilterActionList( elseList, TRUE );  }
	  if( objPropList != NULL )  { FreeARPropList( objPropList, TRUE );  }
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


int
ars_CreateEscalation(ctrl, objDefRef)
	ARControlStruct *	ctrl
	SV *			objDefRef
	CODE:
	{
#if AR_EXPORT_VERSION >= 5
	  int                    ret = 0, rv = 0;
	  ARNameType             name;
	  unsigned int           enable = 0;
	  AREscalationTmStruct   escalationTm;
	  ARQualifierStruct     *query;
	  ARFilterActionList     actionList;
	  ARFilterActionList     elseList;
	  char                  *helpText = CPNULL;
	  ARAccessNameType       owner;
	  char                  *changeDiary = CPNULL;
	  char                  *objectModificationLogLabel = NULL;
	  ARStatusList           status;
	  ARNameList              schemaNameList;
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(name, 1, ARNameType);
	  Zero(&actionList, 1,ARFilterActionList);
	  Zero(&elseList, 1,ARFilterActionList);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  Zero(&schemaNameList, 1, ARNameList);
	  Zero(&escalationTm, 1, AREscalationTmStruct);
	  schemaList.type = AR_WORKFLOW_CONN_SCHEMA_LIST;
	  schemaList.u.schemaList = &schemaNameList;

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);
		SV **qhv = hv_fetch(objDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if(qhv && *qhv && SvROK(*qhv)) {
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, objDef, "query", query ); */
		} else {
			query = (ARQualifierStruct *)NULL;
		}
		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		rv += strcpyHVal( objDef, "name", name, AR_MAX_NAME_SIZE);
		rv += rev_ARNameList( ctrl, objDef, "schemaList", schemaList.u.schemaList );
		rv += uintcpyHVal( objDef, "enable", &enable);


		/* rv += rev_AREscalationTmStruct( ctrl, objDef, "escalationTm", &escalationTm ); */
		rv += uintcpyHVal( objDef, "TmType", &(escalationTm.escalationTmType) );
		switch( escalationTm.escalationTmType ){
		case AR_ESCALATION_TYPE_INTERVAL:
			rv += longcpyHVal( objDef, "TmInterval", &(escalationTm.u.interval) );
			break;
		case AR_ESCALATION_TYPE_TIMEMARK:
			rv += longcpyHVal( objDef,  "TmMonthDayMask", &(escalationTm.u.date.monthday) );
			rv += longcpyHVal( objDef,  "TmWeekDayMask",  &(escalationTm.u.date.weekday) );
			rv += longcpyHVal( objDef,  "TmHourMask",     &(escalationTm.u.date.hourmask) );
			rv += uintcpyHVal( objDef, "TmMinute",       &(escalationTm.u.date.minute) );
			break;
		default:
			rv += (-1);	
		}

		if(hv_exists(objDef,  "owner", strlen("owner") ))
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
		else
			strncpy(owner, ctrl->user, sizeof(ARAccessNameType));

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		rv += rev_ARFilterActionList(ctrl, objDef, "actionList", 
						&actionList);

		rv += rev_ARFilterActionList(ctrl, objDef, "elseList", 
						&elseList);

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") ))
			rv += rev_ARPropList(ctrl, objDef, "objPropList",
					     &objPropList);

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * escalation.
		 */
		if(rv == 0) {
		   ret = ARCreateEscalation(ctrl, name, 
					    &escalationTm,
						&schemaList, 
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary, 
					    &objPropList,
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  FreeARFilterActionList(&actionList, FALSE);
	  FreeARFilterActionList(&elseList, FALSE);
	  FreeARPropList(&objPropList, FALSE);
	  FreeARNameList(&schemaNameList, FALSE);
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


int
ars_SetEscalation(ctrl, name, objDefRef)
	ARControlStruct *	ctrl
	ARNameType  name
	SV *			objDefRef
	CODE:
	{
#if AR_EXPORT_VERSION >= 5
	  int                      ret = 0, rv = 0;
	  ARNameType               newName;
	  char                    *newNamePtr = NULL;
	  AREscalationTmStruct    *escalationTm = NULL;
	  unsigned int            *enable = NULL;
	  ARQualifierStruct       *query = NULL;
	  ARFilterActionList      *actionList = NULL;
	  ARFilterActionList      *elseList   = NULL;
	  char                    *helpText = CPNULL;
	  ARAccessNameType         owner;
	  char                    *ownerPtr = NULL;
	  char                    *changeDiary = CPNULL;
	  char                    *objectModificationLogLabel = NULL;
	  ARStatusList             status;
	  ARWorkflowConnectStruct  *schemaList = NULL;
	  ARPropList               *objPropList = NULL;
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(newName, 1, ARNameType);
	  Zero(owner, 1, ARAccessNameType);

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);
		SV **qhv = hv_fetch(objDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if( qhv && *qhv && SvROK(*qhv) ){
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
			/* query = (ARQualifierStruct*) MALLOCNN( sizeof(ARQualifierStruct) );
			rv += rev_ARQualifierStruct( ctrl, objDef, "query", query ); */
		}

		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		if( hv_exists(objDef,"name",4) ){
			rv += strcpyHVal( objDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		if( hv_exists(objDef,"schemaList",10) ){
			schemaList = (ARWorkflowConnectStruct*) MALLOCNN(sizeof(ARWorkflowConnectStruct));
			schemaList->type = AR_WORKFLOW_CONN_SCHEMA_LIST;
			schemaList->u.schemaList = (ARNameList*) MALLOCNN( sizeof(ARNameList) );
			rv += rev_ARNameList( ctrl, objDef, "schemaList", schemaList->u.schemaList );
		}
		if( hv_exists(objDef,"enable",6) ){
			enable = (unsigned int*) MALLOCNN(sizeof(unsigned int));
			rv += uintcpyHVal( objDef, "enable", enable);
		}

		if( hv_exists(objDef,"TmInterval",10) ){
			escalationTm = (AREscalationTmStruct*) MALLOCNN(sizeof(AREscalationTmStruct));
			escalationTm->escalationTmType = AR_ESCALATION_TYPE_INTERVAL;
			rv += longcpyHVal( objDef, "TmInterval", &(escalationTm->u.interval) );
		}else if( hv_exists(objDef,"TmHourMask",10) ){
			escalationTm = (AREscalationTmStruct*) MALLOCNN(sizeof(AREscalationTmStruct));
			escalationTm->escalationTmType = AR_ESCALATION_TYPE_TIMEMARK;
			rv += longcpyHVal( objDef,  "TmMonthDayMask", &(escalationTm->u.date.monthday) );
			rv += longcpyHVal( objDef,  "TmWeekDayMask",  &(escalationTm->u.date.weekday) );
			rv += longcpyHVal( objDef,  "TmHourMask",     &(escalationTm->u.date.hourmask) );
			rv += uintcpyHVal( objDef, "TmMinute",       &(escalationTm->u.date.minute) );
		}

		if(hv_exists(objDef,  "owner", strlen("owner") )){
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
			ownerPtr = owner;
		}

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		if(hv_exists(objDef,  "actionList", strlen("actionList") )){
			actionList = (ARFilterActionList*) MALLOCNN(sizeof(ARFilterActionList));
			rv += rev_ARFilterActionList(ctrl, objDef, "actionList", actionList);
		}

		if(hv_exists(objDef,  "elseList", strlen("elseList") )){
			elseList = (ARFilterActionList*) MALLOCNN(sizeof(ARFilterActionList));
			rv += rev_ARFilterActionList(ctrl, objDef, "elseList", elseList);
		}

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") )){
			objPropList = (ARPropList*) MALLOCNN(sizeof(ARPropList));
			rv += rev_ARPropList(ctrl, objDef, "objPropList", objPropList);
		}

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to modify the workflow object
		 */
		if(rv == 0) {
		   ret = ARSetEscalation(ctrl, name, newNamePtr, 
					    escalationTm,
		   				schemaList, 
					    enable, query,
					    actionList, elseList, 
					    helpText, ownerPtr, changeDiary, 
					    objPropList,
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }

	  if( enable != NULL )       {  AP_FREE(enable);  }

	  /* if( query != NULL )       { FreeARARQualifierStruct( query, TRUE );  } */
	  if( schemaList != NULL )   { FreeARWorkflowConnectStruct( schemaList, TRUE );  }
	  if( actionList != NULL )   { FreeARFilterActionList( actionList, TRUE );  }
	  if( elseList != NULL )     { FreeARFilterActionList( elseList, TRUE );  }
	  if( objPropList != NULL )  { FreeARPropList( objPropList, TRUE );  }
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ARSperl supports CreateContainer() only for ARSystem >= 5.0");
      RETVAL = AR_RETURN_ERROR;
#endif
	}
	OUTPUT:
	RETVAL


int
ars_CreateImage(ctrl, objDefRef)
	ARControlStruct *       ctrl
    SV *                    objDefRef
	CODE:
	{
	  ARStatusList           status;
#if AR_CURRENT_API_VERSION >= 14
	  int                    ret = 0, rv = 0;
	  ARNameType             name;
	  ARImageDataStruct      imageBuf;
	  char                  *imageType   = CPNULL;
	  char                  *description = CPNULL;
	  char                  *helpText    = CPNULL;
	  ARAccessNameType       owner;
	  char                  *changeDiary = CPNULL;
	  ARPropList             objPropList;
	  char                  *objectModificationLogLabel = NULL;
  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(name, 1, ARNameType);
	  Zero(&imageBuf, 1,ARImageDataStruct);
	  Zero(owner, 1, ARAccessNameType);
	  Zero(&objPropList, 1, ARPropList);

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);

		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		rv += strcpyHVal( objDef, "name", name, AR_MAX_NAME_SIZE);
		rv += rev_ARImageDataStruct( ctrl, objDef, "imageData", &imageBuf );
		rv += strmakHVal( objDef, "imageType", &imageType);

		if(hv_exists(objDef, "description", strlen("description") ))
			rv += strmakHVal( objDef, "description", &description);
		
		if(hv_exists(objDef,  "owner", strlen("owner") ))
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
		else
			strncpy(owner, ctrl->user, sizeof(ARAccessNameType));
		
		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		if(hv_exists(objDef,  "objPropList", strlen("objPropList") ))
			rv += rev_ARPropList(ctrl, objDef, "objPropList",
					     &objPropList);

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * image.
		 */
		if( rv == 0 ){
		   ret = ARCreateImage( ctrl, name,
					    &imageBuf, 
					    imageType,
					    description,
					    helpText, owner, changeDiary, 
					    &objPropList,
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		}else{
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
		}
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  if (description) {
	    	AP_FREE(description);
	  }
	  if (imageType) {
	    	AP_FREE(description);
	  }
	  FreeARImageDataStruct(&imageBuf, FALSE);
	  FreeARPropList(&objPropList, FALSE);
#else	/* prior to ARS 7.5 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_CreateImage() is only available in ARS >= 7.5");
	  XSRETURN_UNDEF;
#endif
	}
	OUTPUT:
	RETVAL

int
ars_SetImage(ctrl, name, objDefRef)
	ARControlStruct *       ctrl
    ARNameType              name
    SV *                    objDefRef
	CODE:
	{
	  ARStatusList           status;
#if AR_CURRENT_API_VERSION >= 14
	  int                    ret = 0, rv = 0;
	  ARNameType             newName;
	  char                  *newNamePtr  = NULL;
	  ARImageDataStruct     *imageBuf    = NULL;
	  char                  *imageType   = CPNULL;
	  char                  *description = CPNULL;
	  char                  *helpText    = CPNULL;
	  ARAccessNameType       owner;
	  char                  *ownerPtr    = NULL;
	  char                  *changeDiary = CPNULL;
	  ARPropList            *objPropList = NULL;
	  char                  *objectModificationLogLabel = NULL;
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(newName, 1, ARNameType);
	  Zero(owner, 1, ARAccessNameType);

	  if(SvTYPE((SV *)SvRV(objDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *objDef = (HV *)SvRV(objDefRef);

		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		if( hv_exists(objDef,"name",4) ){
			rv += strcpyHVal( objDef, "name", newName, AR_MAX_NAME_SIZE ); 
			newNamePtr = newName;
		}
		if(hv_exists(objDef,  "owner", strlen("owner") )){
			rv += strcpyHVal( objDef, "owner", owner, AR_MAX_ACCESS_NAME_SIZE);
			ownerPtr = owner;
		}

		if(hv_exists(objDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( objDef, "changeDiary", &changeDiary);
		if(hv_exists(objDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( objDef, "helpText", &helpText);

		if(hv_exists(objDef,  "imageType", strlen("imageType") ))
			rv += strmakHVal( objDef, "imageType", &imageType);

		if(hv_exists(objDef,  "imageData", strlen("imageData") )){
			imageBuf = (ARImageDataStruct*) MALLOCNN(sizeof(ARImageDataStruct));
			rv += rev_ARImageDataStruct(ctrl, objDef, "imageData", imageBuf);
		}

		if(hv_exists(objDef, "description", strlen("description") ))
			rv += strmakHVal( objDef, "description", &description);
		
		if(hv_exists(objDef,  "objPropList", strlen("objPropList") )){
			objPropList = (ARPropList*) MALLOCNN(sizeof(ARPropList));
			rv += rev_ARPropList(ctrl, objDef, "objPropList", objPropList);
		}

		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * image.
		 */
		if( rv == 0 ){
		   ret = ARSetImage( ctrl, name,
		   			    newNamePtr,
					    imageBuf, 
					    imageType,
					    description,
					    helpText, owner, changeDiary, 
					    objPropList,
#if AR_CURRENT_API_VERSION >= 17
					    objectModificationLogLabel,
#endif
					    &status);
		   if(!ARError( ret, status))
			   RETVAL = 1;
		}else{
		  ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
		}
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  if (description) {
	    	AP_FREE(description);
	  }
	  if (imageType) {
	    	AP_FREE(description);
	  }
	  if( imageBuf != NULL )     { FreeARImageDataStruct(imageBuf, TRUE); }
	  if( objPropList != NULL )  { FreeARPropList(objPropList, TRUE);     }
#else	/* prior to ARS 7.5 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_SetImage() is only available in ARS >= 7.5");
	  XSRETURN_UNDEF;
#endif
	}
	OUTPUT:
	RETVAL




char *
ars_MergeEntry(ctrl, schema, mergeType, ...)
	ARControlStruct *	ctrl
	char *			schema
	unsigned int		mergeType
	CODE:
	{
	  int              a, i, c = (items - 3) / 2;
	  ARFieldValueList fieldList;
	  ARStatusList     status;
	  int              ret = 0;
	  unsigned int     dataType = 0;
	  AREntryIdType    entryId;

	  (void) ARError_reset();
	  Zero(&status,    1, ARStatusList);
	  Zero(&fieldList, 1, ARFieldValueList);
	  Zero(&entryId, 1, AREntryIdType);
	  RETVAL = "";

	  if ((items - 3) % 2 || c < 1) {
	  	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  	goto merge_entry_exit;
	  }

	  fieldList.numItems = c;
	  AMALLOCNN(fieldList.fieldValueList, c, ARFieldValueStruct);

	  for (i = 0; i < c; i++) {
	  	a = i*2 + 3;
	  	fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	  	if (! SvOK(ST(a+1))) {
	  		/* pass a NULL */
	  		fieldList.fieldValueList[i].value.dataType = 
				AR_DATA_TYPE_NULL;
	  	} else {
#if AR_CURRENT_API_VERSION >= 17
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, 
				NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#elif AR_EXPORT_VERSION >= 9
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, 
				NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#elif AR_EXPORT_VERSION >= 3
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, 
				NULL, NULL, &dataType, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, &dataType,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, &status);
#endif
	  		if (ARError( ret, status)) {
				DBG( ("GetFieldCached failed %d\n", ret) );
				goto merge_entry_end;
	   		}
	   		if (sv_to_ARValue(ctrl, ST(a+1), dataType, 
				&fieldList.fieldValueList[i].value) < 0) {
				DBG( ("failed to convert to ARValue struct stack %d\n", a+1) );
				goto merge_entry_end;
	  		}
	  	}
	  }

	  ret = ARMergeEntry(ctrl, schema, &fieldList, mergeType, 
#if AR_CURRENT_API_VERSION >= 18
			NULL,     /* ARQualifier *query            */
			0,        /* unsigned int multimatchOption */
#endif
			entryId, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif	  
	  if (! ARError( ret, status)) {
		DBG( ("MergeEntry returned %d\n", ret) );
		DBG( ("entryId %s\n", SAFEPRT(entryId)) );
	  	RETVAL = entryId;
	  }

	merge_entry_end:;
	if (fieldList.fieldValueList) AP_FREE(fieldList.fieldValueList);
	merge_entry_exit:;
	}
	OUTPUT:
	RETVAL

void
ars_GetMultipleEntries(ctrl,schema,...)
	ARControlStruct *       ctrl
	char *                  schema
	PPCODE:
	{
	int               ret = 0;
    unsigned int      c = items - 3, i;
	AREntryIdListList entryList;
	ARInternalIdList  idList;
	ARFieldValueListList  fieldList;
	ARBooleanList     existList;
	ARStatusList      status;
	AV               *entryList_array;

	entryList.entryIdList = NULL;
	idList.internalIdList = NULL;
	fieldList.valueListList = NULL;
	existList.booleanList = NULL;
	(void) ARError_reset();
	Zero(&status, 1, ARStatusList);
	Zero(&entryList, 1, AREntryIdListList);
	Zero(&idList, 1, ARInternalIdList);
	Zero(&fieldList, 1, ARFieldValueListList);
	Zero(&existList, 1, ARBooleanList);
	/*
	 * build list of field Id's
	 */
	if (c < 1) {
		idList.numItems = 0; /* get all fields */
	} else {
		idList.numItems = c;
		idList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
		for (i=0; i<c; i++)
			idList.internalIdList[i] = SvIV(ST(i+3));
	}
	/*
	 * build list of entry Id's
	 */
	if ( SvROK(ST(2)) &&
		(entryList_array = (AV *)SvRV(ST(2))) &&
		(SvTYPE(entryList_array) == SVt_PVAV) ) {

		entryList.numItems = av_len(entryList_array) + 1;
		/* Newz(777,entryList.entryIdList,entryList.numItems,AREntryIdList); */
		entryList.entryIdList = 
			MALLOCNN( entryList.numItems * sizeof(AREntryIdList) );

		for (i=0; i<entryList.numItems; i++) {
			SV **array_entry;
			if (! (array_entry = av_fetch(entryList_array, i, 0))) {
				(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
				FreeAREntryIdListList(&entryList,FALSE);
				goto get_mentry_cleanup;
			}
			if( perl_BuildEntryList(ctrl, 
				&entryList.entryIdList[i],
				SvPV(*array_entry, PL_na)) != 0 ) {

				FreeAREntryIdListList(&entryList,FALSE);
				goto get_mentry_cleanup;
			}
		}
	} else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID );
		goto get_mentry_cleanup;
	}
	/*
	 * do API call
	 */
	ret = ARGetMultipleEntries(ctrl, schema, &entryList, &idList, 
				   &existList, &fieldList, &status);
#ifdef PROFILE
	((ars_ctrl *)ctrl)->queries++;
#endif
	if (ARError( ret, status)) {
		goto get_mentry_cleanup;
	}
	if(fieldList.numItems < 1) {
		goto get_mentry_cleanup;
	}
	/*
	 * build PERL copy of returned entries
	 */
	for (i=0; i < entryList.numItems; i++) {
		HV * fieldValue_hash;
		unsigned int field;
		char intstr[12];
		/*
		 * push entryID onto list
		 */
		if (entryList.entryIdList[i].numItems == 1) {
			/* only one entryId -- so just return its value to be compatible
			with ars 2 */
			XPUSHs(sv_2mortal(newSVpv(entryList.entryIdList[i].entryIdList[0], 0)));
		} else {
			/* more than one entry -- this must be a join schema. merge
			 * the list into a single entry-id to keep things
			 * consistent. */
			unsigned int   entry;
			char *joinId = (char *)NULL;
			char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
			for (entry=0; entry < entryList.entryIdList[i].numItems; entry++) {
				joinId = strappend(joinId, entryList.entryIdList[i].entryIdList[entry]);
				if(entry < entryList.entryIdList[i].numItems-1)
				joinId = strappend(joinId, joinSep);
			}
			XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
		}
		/*
		 * push field/value hash reference onto list
		 */
		if ( existList.booleanList[i] ) {
			fieldValue_hash = newHV();
			/* sv_2mortal( (SV *)fieldValue_hash ); */
			for (field=0; field < fieldList.valueListList[i].numItems; field++) {
				sprintf(intstr,"%ld",fieldList.valueListList[i].fieldValueList[field].fieldId);
				hv_store( fieldValue_hash,
					intstr, strlen(intstr),
					perl_ARValueStruct(ctrl,&fieldList.valueListList[i].fieldValueList[field].value),
					0 );
			}
			XPUSHs( sv_2mortal( newRV_noinc((SV *)fieldValue_hash) ) );
		} else {
			XPUSHs(&PL_sv_undef);
		}
	}
	get_mentry_cleanup:;
	FreeARInternalIdList(&idList, FALSE);
	FreeAREntryIdListList(&entryList, FALSE);
	FreeARFieldValueListList(&fieldList, FALSE);
	FreeARBooleanList(&existList, FALSE);
	}


void
ars_GetListEntryWithFields(ctrl,schema,qualifier,maxRetrieve=0,firstRetrieve=0,...)
	ARControlStruct *       ctrl
	char *                  schema
	ARQualifierStruct *     qualifier
	unsigned int            firstRetrieve
	unsigned int            maxRetrieve
	PPCODE:
	{
	  ARStatusList     status;
	  unsigned int              c = (items - 5) / 2, i;
	  int              field_off = 5;
	  ARSortList       sortList;
	  AREntryListFieldValueList  entryFieldValueList;
	  int              ret = 0;
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV              *getListFields_array;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  Zero(&sortList, 1, ARSortList);
	  Zero(&entryFieldValueList, 1, AREntryListFieldValueList);
	  Zero(&getListFields, 1, AREntryListFieldList);

	  sortList.sortList = NULL;
	  getListFields.fieldsList = NULL;
	  entryFieldValueList.entryList = NULL;
	  if ((items - 5) % 2) {
	    /* odd number of arguments, so argument after maxRetrieve is
	       optional getListFields (an array of hash refs) */
	    if ( SvROK(ST(field_off)) &&
	         (getListFields_array = (AV *)SvRV(ST(field_off))) &&
	         (SvTYPE(getListFields_array) == SVt_PVAV) ) {
	      getList = &getListFields;
	      getListFields.numItems = av_len(getListFields_array) + 1;
	      DBG( ("getListFields.numItems=%d\n", getListFields.numItems) );
	      /* Newz(777,getListFields.fieldsList, getListFields.numItems,AREntryListFieldStruct); */
	      getListFields.fieldsList = MALLOCNN( sizeof(AREntryListFieldStruct) * getListFields.numItems );
	      /* set query field list */
	      for (i=0; i<getListFields.numItems; i++) {
	        SV **array_entry;
	        /* get fieldID from array */
	        if (! (array_entry = av_fetch(getListFields_array, i, 0))) {
	          (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
	          goto getlistentry_end;
	        }
	        getListFields.fieldsList[i].fieldId = SvIV(*array_entry);
	        getListFields.fieldsList[i].columnWidth = 1;
	        strncpy(getListFields.fieldsList[i].separator, " ", 2 );
	        DBG( ("i=%d, fieldId=%d, columnWidth=%d, separator=\"%s\"\n", i,
	             getListFields.fieldsList[i].fieldId,
	             getListFields.fieldsList[i].columnWidth,
	             getListFields.fieldsList[i].separator) );
	      }
	    } else {
	      (void) ARError_add( AR_RETURN_ERROR, AP_ERR_LFLDS_TYPE);
	      goto getlistentry_end;
	    }
	    /* increase the offset of the first sortList field by one */
	    field_off ++;
	  }
	  /* build sortList */
	  sortList.numItems = c;
	  /* Newz(777,sortList.sortList, c,  ARSortStruct); */
	  sortList.sortList = MALLOCNN( sizeof(ARSortStruct) * c );
	  for (i=0; i<c; i++) {
	    sortList.sortList[i].fieldId = SvIV(ST(i*2+field_off));
	    sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  }
	  ret = ARGetListEntryWithFields(ctrl, schema, qualifier, 
		getList, &sortList, 
#if AR_EXPORT_VERSION >= 6
		firstRetrieve,
#endif
		maxRetrieve, 
#if AR_EXPORT_VERSION >= 8L
                FALSE,
#endif
		&entryFieldValueList, NULL, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
	    goto getlistentry_end;
	  }
	  for (i=0; i < entryFieldValueList.numItems; i++) {
	    HV * fieldValue_hash = newHV();
	    unsigned int field;
	    char intstr[12];
	    if (entryFieldValueList.entryList[i].entryId.numItems == 1) {
	      /* only one entryId -- so just return its value to be compatible
	         with ars 2 */
	      XPUSHs(sv_2mortal(newSVpv(entryFieldValueList.entryList[i].entryId.entryIdList[0], 0)));
	    } else {
	      /* more than one entry -- this must be a join schema. merge
	       * the list into a single entry-id to keep things
	       * consistent. */
	      unsigned int   entry;
	      char *joinId = (char *)NULL;
	      char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
	      for (entry=0; entry < entryFieldValueList.entryList[i].entryId.numItems; entry++) {
	        joinId = strappend(joinId, entryFieldValueList.entryList[i].entryId.entryIdList[entry]);
	        if(entry < entryFieldValueList.entryList[i].entryId.numItems-1)
	        joinId = strappend(joinId, joinSep);
	      }
	      XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
	    }
	    for (field=0; field < entryFieldValueList.entryList[i].entryValues->numItems; field++) {
	      sprintf(intstr,"%ld",entryFieldValueList.entryList[i].entryValues->fieldValueList[field].fieldId);
	      hv_store( fieldValue_hash,
	                intstr, strlen(intstr),
	                perl_ARValueStruct(ctrl,&entryFieldValueList.entryList[i].entryValues->fieldValueList[field].value),
	                0 );
	    }
	    XPUSHs( sv_2mortal( newRV_noinc((SV *)fieldValue_hash) ) );
	  }
	  getlistentry_end:
	  FreeAREntryListFieldValueList( &entryFieldValueList,FALSE );
	  FreeARSortList( &sortList, FALSE );
	  FreeAREntryListFieldList( &getListFields, FALSE );
	}


void
ars_GetListEntryWithMultiSchemaFields(ctrl,schema,qualifier=NULL,maxRetrieve=0,firstRetrieve=0,fields=NULL,...)
	ARControlStruct *    ctrl
	SV *                 schema
	SV *                 qualifier
	unsigned int         firstRetrieve
	unsigned int         maxRetrieve
	SV *                 fields
	PPCODE:
	{
	ARStatusList     status;
#if AR_CURRENT_API_VERSION >= 14
#if AR_CURRENT_API_VERSION >= 17
	ARMultiSchemaFuncQueryFromList   queryFromList;
	ARMultiSchemaFieldFuncList       getListFields;
	ARMultiSchemaFieldFuncValueListList  entryFieldValueList;
	ARMultiSchemaFieldIdList         *groupBy = NULL;   /* TODO: support as function argument */
	ARMultiSchemaFuncQualifierStruct *having  = NULL;   /* TODO: support as function argument */
#else
	ARMultiSchemaQueryFromList       queryFromList;
	ARMultiSchemaFieldIdList         getListFields;
	ARMultiSchemaFieldValueListList  entryFieldValueList;
#endif
	ARMultiSchemaQualifierStruct     qualifierStruct;
	ARMultiSchemaSortList            sortList;
	unsigned int                     i;
	int                              i2, field_off = 6;
	int                              ret = 0, rv = 0;
	HV                               *hDummy;

	/* printf( "\n\n!!!! ars_GetListEntryWithMultiSchemaFields(): experimental implementation, not really working yet !!!!\n\n" ); */

	(void) ARError_reset();
#if AR_CURRENT_API_VERSION >= 17
	Zero( &queryFromList, 1, ARMultiSchemaFuncQueryFromList );
	Zero( &getListFields, 1, ARMultiSchemaFieldFuncList );
	Zero( &entryFieldValueList, 1, ARMultiSchemaFieldFuncValueListList );
#else
	Zero( &queryFromList, 1, ARMultiSchemaQueryFromList );
	Zero( &getListFields, 1, ARMultiSchemaFieldIdList );
	Zero( &entryFieldValueList, 1, ARMultiSchemaFieldValueListList );
#endif
	Zero( &qualifierStruct, 1, ARMultiSchemaQualifierStruct );
	Zero( &sortList, 1, ARMultiSchemaSortList );
	Zero( &status, 1, ARStatusList );

	hDummy = newHV();

	if( !( SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVAV ) ){
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "QueryFromList must be an ARRAY reference" );
		goto getlistentry_multischema_end;
	}
	hv_store( hDummy, "queryFromList", 13, newSVsv(schema), 0 );
#if AR_CURRENT_API_VERSION >= 17
	rv += rev_ARMultiSchemaFuncQueryFromList( ctrl, hDummy, "queryFromList", &queryFromList );
#else
	rv += rev_ARMultiSchemaQueryFromList( ctrl, hDummy, "queryFromList", &queryFromList );
#endif
	if( qualifier && SvOK(qualifier) ){
		if( !( SvROK(qualifier) && SvTYPE(SvRV(qualifier)) == SVt_PVHV ) ){
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "Qualifier must be a HASH reference" );
			goto getlistentry_multischema_end;
		}
		hv_store( hDummy, "qualifierStruct", 15, newSVsv(qualifier), 0 );
		rv += rev_ARMultiSchemaQualifierStruct( ctrl, hDummy, "qualifierStruct", &qualifierStruct );
	}

	if( fields && SvOK(fields) ){
		if( !( SvROK(fields) && SvTYPE(SvRV(fields)) == SVt_PVAV ) ){
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "GetListFields must be an ARRAY reference" );
			goto getlistentry_multischema_end;
		}
		hv_store( hDummy, "getListFields", 13, newSVsv(fields), 0 );
#if AR_CURRENT_API_VERSION >= 17
		rv += rev_ARMultiSchemaFieldFuncList( ctrl, hDummy, "getListFields", &getListFields );
#else
		rv += rev_ARMultiSchemaFieldIdList( ctrl, hDummy, "getListFields", &getListFields );
#endif
	}

	if( items > field_off ){
		int arg, c = (items - field_off) / 2;
		if( (items - field_off) % 2 ){
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_GENERAL, "Odd number of SortList arguments" );
			goto getlistentry_multischema_end;
		}

		sortList.numItems = c;
		sortList.listPtr = MALLOCNN( sizeof(ARMultiSchemaSortStruct) * c );
		for( i2 = 0; i2 < c; ++i2 ){
			arg = field_off + i2 * 2;
			hv_store( hDummy, "_", 1, newSVsv(ST(arg)), 0 );
			rv += rev_ARMultiSchemaFieldIdStruct( ctrl, hDummy, "_", &(sortList.listPtr[i2].fieldId) );
			sortList.listPtr[i2].sortOrder = SvUV(ST(arg+1));
		}
	}


	if( rv != 0 ){
		ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL );
		goto getlistentry_multischema_end;
	}

	ret = ARGetListEntryWithMultiSchemaFields( ctrl,
		&queryFromList,
		&getListFields,
		&qualifierStruct, 
		&sortList, 
		firstRetrieve,
		maxRetrieve, 
		FALSE,
#if AR_CURRENT_API_VERSION >= 17
		groupBy,
		having,
#endif
		&entryFieldValueList,
		NULL,                  /* TODO: numMatches */
		&status );
#ifdef PROFILE
	((ars_ctrl *)ctrl)->queries++;
#endif
	if( ARError( ret, status) ){
		goto getlistentry_multischema_end;
	}
#if AR_CURRENT_API_VERSION >= 17
	for( i = 0; i < entryFieldValueList.numItems; ++i ){
		HV * fieldValue_hash = newHV();
		unsigned int field;
		char keyStr[AR_MAX_NAME_SIZE + 1 + 12 + 1 + 12 + 1];

		for( field = 0; field < entryFieldValueList.listPtr[i].numItems; ++field ){
			ARMultiSchemaFieldFuncValueStruct *valPtr = &(entryFieldValueList.listPtr[i].listPtr[field]);
			sprintf( keyStr, "%s.%ld.%ld", valPtr->fieldId.queryFromAlias, valPtr->fieldId.fieldId, valPtr->fieldId.funcId );
			hv_store( fieldValue_hash,
				keyStr, strlen(keyStr),
				perl_ARValueStruct(ctrl, &(valPtr->value)),
				0 );
		}
		XPUSHs( sv_2mortal( newRV_noinc((SV *)fieldValue_hash) ) );
	}
#else
	for( i = 0; i < entryFieldValueList.numItems; ++i ){
		HV * fieldValue_hash = newHV();
		unsigned int field;
		char keyStr[AR_MAX_NAME_SIZE + 1 + 12 + 1];

		for( field = 0; field < entryFieldValueList.listPtr[i].numItems; ++field ){
			ARMultiSchemaFieldValueStruct *valPtr = &(entryFieldValueList.listPtr[i].listPtr[field]);
			sprintf( keyStr, "%s.%ld", valPtr->fieldId.queryFromAlias, valPtr->fieldId.fieldId );
			hv_store( fieldValue_hash,
				keyStr, strlen(keyStr),
				perl_ARValueStruct(ctrl, &(valPtr->value)),
				0 );
		}
		XPUSHs( sv_2mortal( newRV_noinc((SV *)fieldValue_hash) ) );
	}
#endif

	getlistentry_multischema_end:
	hv_undef( hDummy );
#if AR_CURRENT_API_VERSION >= 17
	FreeARMultiSchemaFieldFuncList( &getListFields, FALSE );
	FreeARMultiSchemaFieldFuncValueListList( &entryFieldValueList, FALSE );
#else
	FreeARMultiSchemaFieldIdList( &getListFields, FALSE );
	FreeARMultiSchemaFieldValueListList( &entryFieldValueList, FALSE );
#endif
	FreeARMultiSchemaSortList( &sortList, FALSE );
#else	/* prior to ARS 7.5 */
	(void) ARError_reset();
	Zero(&status, 1, ARStatusList);
	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	"ars_GetListEntryWithMultiSchemaFields() is only available in ARS >= 7.5");
#endif
	}



void
ars_SetLogging( ctrl, logTypeMask_arg, ...)
	ARControlStruct *	ctrl
	unsigned long     logTypeMask_arg
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 5
		ARStatusList     status;
#if AR_CURRENT_API_VERSION >= 14
		ARULong32        whereToWriteMask = AR_WRITE_TO_STATUS_LIST;
		ARULong32        logTypeMask      = logTypeMask_arg;
#else
		unsigned long    whereToWriteMask = AR_WRITE_TO_STATUS_LIST;
		unsigned long    logTypeMask      = logTypeMask_arg;
#endif
		int	             ret;
		FILE             *logFilePtr = NULL;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);

		logFilePtr = get_logging_file_ptr();
		/* printf( "GET logging_file_ptr = %p\n", logFilePtr ); */

		if( items > 2 && logTypeMask != 0 ){
			char *fileName;
			STRLEN len;
			fileName = SvPV(ST(2),len);

			if( logFilePtr != NULL ){
				fclose( logFilePtr );
				logFilePtr = NULL;
			}

			whereToWriteMask = AR_WRITE_TO_FILE;
			logFilePtr = fopen( fileName, "a" );

			if( logFilePtr == NULL ){
				char buf[2048];
				sprintf( buf, "Cannot open file: %s", fileName );
				(void) ARError_add( AR_RETURN_ERROR, AP_ERR_INV_ARGS, buf);
				XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
				goto SetLogging_fail;
			}
			set_logging_file_ptr( logFilePtr );
			/* printf( "SET logging_file_ptr = %p\n", logFilePtr ); */
		}

		ret = ARSetLogging( ctrl, logTypeMask, whereToWriteMask, logFilePtr, &status );

		if( logTypeMask == 0 && logFilePtr != NULL ){
			fclose( logFilePtr );
			set_logging_file_ptr( NULL );
		}

		if(ARError(ret, status)) {
			XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		} else {
			XPUSHs(sv_2mortal(newSViv(1))); /* OK */
		}
	SetLogging_fail:;
#else /* < 4.5 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"SetLogging() is only available in ARSystem >= 4.5");
#endif
	}


void
ars_SetSessionConfiguration( ctrl, variableId, value )
	ARControlStruct *	ctrl
	unsigned int      variableId
	long              value
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 6
		ARStatusList     status;
		ARValueStruct    variableValue;
		int	             ret;
		char             numToCharBuf[32];

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);

		variableValue.dataType = AR_DATA_TYPE_INTEGER;
		variableValue.u.intVal = value;
		
		if (variableId == 12 || variableId == 13)
		{
			// just a quick and dirty solution because those variables need to be characters
			sprintf(numToCharBuf, "%ld", value);
			variableValue.dataType = AR_DATA_TYPE_CHAR;
			variableValue.u.charVal = numToCharBuf;
		}

		ret = ARSetSessionConfiguration( ctrl, variableId, &variableValue, &status );

		if(ARError(ret, status)) {
			XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		} else {
			XPUSHs(sv_2mortal(newSViv(1))); /* OK */
		}
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"SetSessionConfiguration() is only available in ARSystem >= 5.0");
#endif
	}


void
ars_SetImpersonatedUser( ctrl, impersonatedUser )
	ARControlStruct *	ctrl
	ARAccessNameType  impersonatedUser
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 9
		ARStatusList     status;
		int	             ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);

		if( strcmp("",impersonatedUser) == 0 ){
			ret = ARSetImpersonatedUser( ctrl, NULL, &status );
		}else{
			ret = ARSetImpersonatedUser( ctrl, impersonatedUser, &status );
		}

		if(ARError(ret, status)) {
			XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		} else {
			XPUSHs(sv_2mortal(newSViv(1))); /* OK */
		}
#else /* < 7.0 */
		XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			  "SetImpersonatedUser() is only available in ARSystem >= 7.0");
#endif
	}





void
ars_BeginBulkEntryTransaction( ctrl )
	ARControlStruct *	ctrl
	PPCODE:
	{
#if AR_CURRENT_API_VERSION >= 11
		ARStatusList     status;
		int	             ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);

		ret = ARBeginBulkEntryTransaction( ctrl, &status );

		if( ARError(ret, status) ){
			XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		}else{
			XPUSHs(sv_2mortal(newSViv(1))); /* OK */
		}
#else /* < 6.3 */
		XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"BeginBulkEntryTransaction() is only available in ARSystem >= 6.3");
#endif
	}



void
ars_EndBulkEntryTransaction( ctrl, actionType )
	ARControlStruct *	ctrl
	unsigned int      actionType
	PPCODE:
	{
#if AR_CURRENT_API_VERSION >= 11
		int	             ret;
		ARStatusList     status;
		ARBulkEntryReturnList returnList;
		unsigned int i;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&returnList, 1, ARBulkEntryReturnList);

		ret = AREndBulkEntryTransaction( ctrl, actionType, &returnList, &status );

		ARError( ret, status );

		for( i = 0; i < returnList.numItems; i++ ){
			XPUSHs( sv_2mortal( perl_ARBulkEntryReturn(ctrl,&(returnList.entryReturnList[i])) ) );
		}

		FreeARBulkEntryReturnList(&returnList, FALSE);
#else /* < 6.3 */
		XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"BeginBulkEntryTransaction() is only available in ARSystem >= 6.3");
#endif
	}


void
ars_Signal( ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
#if AR_CURRENT_API_VERSION >= 9
		int	             ret;
		ARSignalList     signalList;
		ARStatusList     status;
		unsigned int     c = (items - 1) / 2, i = 0, a = 0, ok = 1;

		(void) ARError_reset();
		Zero(&signalList, 1, ARSignalList);
		Zero(&status, 1, ARStatusList);

		if( ((items - 1) % 2) || c < 1 ){
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		}else{
			signalList.numItems = c;
			AMALLOCNN(signalList.signalList,c,ARSignalStruct);
			for( i = 0; i < c; ++i ){
				int st;
				a = i * 2 + 1;

				st = caseLookUpTypeNumber((TypeMapStruct *) 
					SignalTypeMap,
					SvPV(ST(a), PL_na) 
				);
				if( st == TYPEMAP_LAST ){
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_TYPEMAP);
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
						SvPV(ST(a), PL_na) );
					ok = 0;
				}else{
					signalList.signalList[i].signalType = st;
					signalList.signalList[i].sigArgument = SvPV(ST(a+1),PL_na);
				}
			}
		}

		if( ok ){
			ret = ARSignal( ctrl, &signalList, &status );
		}

		if( !ok || ARError(ret, status) ){
			XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		}else{
			XPUSHs(sv_2mortal(newSViv(1))); /* OK */
		}

		FreeARSignalList(&signalList, FALSE);
#else /* < 5.1 */
		XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_Signal() is only supported for ARSystem >= 5.1");
#endif
	}


SV *
ars_GetTextForErrorMessage(msgId)
	int  msgId
	CODE:
	{
		char *msgTxt = NULL;
		(void) ARError_reset();

		msgTxt = ARGetTextForErrorMessage( msgId );
		if( msgTxt != NULL ){
			RETVAL = newSVpv( msgTxt, 0 );
			free( msgTxt );
		}else{
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


void
ars_ValidateMultipleLicenses(ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
		ARStatusList            status;
		ARLicenseNameList       licNameList;
		ARLicenseValidList      licValidList;
		int                     ret = 0;
		unsigned int            ui = 0, count = 0;
		unsigned int            c = items - 1, i = 0, a = 0, ok = 1;

		(void) ARError_reset();
		Zero(&status, 1,ARStatusList);
		Zero(&licNameList, 1, ARLicenseNameList);
		Zero(&licValidList, 1, ARLicenseValidList);
		if( items > 1){
			licNameList.numItems = c;
			AMALLOCNN(licNameList.nameList,c,ARLicenseNameType);
			for( i = 0; i < c; ++i ){
				a = i + 1;
				strncpy( licNameList.nameList[i], SvPV(ST(a),PL_na), AR_MAX_LICENSE_NAME_SIZE );
			}
		}else{
			ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
			ok = 0;
		}

		if( ok  ){
			ret = ARValidateMultipleLicenses(ctrl, &licNameList, &licValidList, &status);

			if( !ARError(ret,status) ){
				if( licNameList.numItems != licValidList.numItems ){
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_RETURN);
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE, "licNameList.numItems != licValidList.numItems");
				}

				for( ui = 0; ui < licValidList.numItems; ++ui ){
					XPUSHs( sv_2mortal( newSVpv(licNameList.nameList[ui],0) ) );
					XPUSHs( sv_2mortal( perl_ARLicenseValidStruct(ctrl,&(licValidList.licenseValidateInfoList[ui])) ) );
				}
			}
		}
		FreeARLicenseNameList(&licNameList, FALSE);
		FreeARLicenseValidList(&licValidList, FALSE);
	}


int
ars_DateToJulianDate(ctrl, year, month, day)
	ARControlStruct *	ctrl
	int         year;
	int         month;
	int         day;
	CODE:
	{
#if AR_CURRENT_API_VERSION >= 9
		int     ret = 0;
		int     jd  = 0;
		ARDateStruct  date;
		ARStatusList  status;

		(void) ARError_reset();
		Zero(&date, 1, ARDateStruct);
		Zero(&status, 1, ARStatusList);

		date.year  = year;
		date.month = month;
		date.day   = day;

		ret = ARDateToJulianDate(ctrl, &date, &jd, &status);
		if (! ARError( ret, status)) {
			RETVAL = jd;
		}else{
			XSRETURN_UNDEF;
		}
#else /* < 5.1 */
		RETVAL = NULL; /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_DateToJulianDate() is only supported for ARSystem >= 5.1");
#endif
	}
	OUTPUT:
	RETVAL


SV *
ars_GetServerCharSet( ctrl )
	ARControlStruct *	ctrl
	CODE:
	{
#if AR_CURRENT_API_VERSION >= 12
		char          charSet[AR_MAX_LANG_SIZE+1];
		ARStatusList  status;
		int           ret = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = NULL;

		ret = ARGetServerCharSet( ctrl, charSet, &status );
		if( ! ARError(ret,status) ){
			RETVAL = newSVpv( charSet, 0 );
		}
#else /* < 7.0 */
		RETVAL = NULL; /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_GetServerCharSet() is only available in ARSystem >= 7.0");
#endif
	}
	OUTPUT:
	RETVAL


SV *
ars_GetClientCharSet( ctrl )
	ARControlStruct *	ctrl
	CODE:
	{
#if AR_CURRENT_API_VERSION >= 12
		char          charSet[AR_MAX_LANG_SIZE+1];
		ARStatusList  status;
		int           ret = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = NULL;

		ret = ARGetClientCharSet( ctrl, charSet, &status );
		if( ! ARError(ret,status) ){
			RETVAL = newSVpv( charSet, 0 );
		}
#else /* < 7.0 */
		RETVAL = NULL; /* ERR */
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_GetClientCharSet() is only available in ARSystem >= 7.0");
#endif
	}
	OUTPUT:
	RETVAL



###################################################
# ALERT ROUTINES

int
ars_RegisterForAlerts(ctrl, clientPort, registrationFlags=0)
	ARControlStruct *	ctrl
	int			clientPort
	unsigned int		registrationFlags
	CODE:
	{
		ARStatusList status;
		int          ret = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = 0;
#if AR_EXPORT_VERSION >= 6
		ret = ARRegisterForAlerts(ctrl, clientPort, 
				registrationFlags, &status);
		if( !ARError(ret, status) ) {
			RETVAL = 1;
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"RegisterForAlerts() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_DeregisterForAlerts(ctrl,clientPort)
	ARControlStruct *	ctrl
	int			clientPort
	CODE:
	{
		ARStatusList status;
		int          ret = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = 0;
#if AR_EXPORT_VERSION >= 6
		ret = ARDeregisterForAlerts(ctrl, clientPort, 
					    &status);
		if( !ARError(ret, status) ) {
			RETVAL = 1;
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"DeregisterForAlerts() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_GetListAlertUser(ctrl)
	ARControlStruct *	ctrl
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 6
		ARStatusList     status;
		ARAccessNameList userList;
		int              ret = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
	 	Zero(&userList, 1, ARAccessNameList);
		ret = ARGetListAlertUser(ctrl, &userList,
					 &status);
		if( !ARError(ret, status) ) {
			if (userList.numItems > 0) {
				unsigned int i = 0;
				while(i < userList.numItems) {
					XPUSHs(sv_2mortal(newSVpvn(userList.nameList[i++], 
							AR_MAX_NAME_SIZE)));
				}
			}
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetListAlertUser() is only available in ARSystem >= 5.0");
	  XPUSHs(sv_2mortal(&PL_sv_undef));
#endif
	}

SV *
ars_GetAlertCount(ctrl,qualifier=NULL)
	ARControlStruct *	ctrl
	ARQualifierStruct *	qualifier
	CODE:
	{
		ARStatusList     status;
		int              ret = 0;
		unsigned int	 count = 0;

		RETVAL=newSVsv(&PL_sv_undef);
#if AR_EXPORT_VERSION >= 6
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		ret = ARGetAlertCount(ctrl, qualifier, &count,
				      &status);
		if( !ARError(ret, status) ) {
			/* RETVAL=sv_2mortal(newSViv(count)); */
			RETVAL = newSViv(count);
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetAlertCount() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

HV *
ars_DecodeAlertMessage(ctrl,message,messageLen)
	ARControlStruct *	ctrl
	unsigned char *		message
	unsigned int		messageLen
	CODE:
	{
		ARStatusList     status;
		int              ret = 0;
		ARTimestamp      timestamp;
		unsigned int	 sourceType = 0;
		unsigned int	 priority = 0;
		char 		*alertText  = CPNULL;
		char		*sourceTag  = CPNULL;
		char		*serverName = CPNULL;
		char		*serverAddr = CPNULL;
		char		*formName   = CPNULL;
		char 		*objId      = CPNULL;

		RETVAL=newHV();
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&timestamp, 1, ARTimestamp);
#if AR_EXPORT_VERSION >= 6
		ret = ARDecodeAlertMessage(ctrl, message, messageLen,
					&timestamp,
					&sourceType,
					&priority,
					&alertText,
					&sourceTag,
					&serverName,
#if AR_EXPORT_VERSION >= 7L
					&serverAddr,
#endif
					&formName,
					&objId,
					&status);

		if( !ARError(ret, status) ) {
			hv_store(RETVAL, "timestamp", strlen("timestamp"),
				newSViv(timestamp), 0);
			hv_store(RETVAL, "sourceType", strlen("sourceType"),
				newSViv(sourceType), 0);
			hv_store(RETVAL, "priority", strlen("priority"),
				newSViv(priority), 0);

			hv_store(RETVAL, "alertText", strlen("alertText"),
				newSVpv(alertText, 0), 0);
			hv_store(RETVAL, "sourceTag", strlen("sourceTag"),
				newSVpv(sourceTag, 0), 0);
			hv_store(RETVAL, "serverName", strlen("serverName"),
				newSVpv(serverName, 0), 0);
			hv_store(RETVAL, "serverAddr", strlen("serverAddr"),
				newSVpv(serverAddr, 0), 0);
			hv_store(RETVAL, "formName", strlen("formName"),
				newSVpv(formName, 0), 0);
		}

		if (alertText)  AP_FREE(alertText);
		if (sourceTag)  AP_FREE(sourceTag);
		if (serverName) AP_FREE(serverName);
		if (serverAddr) AP_FREE(serverAddr);
		if (formName)   AP_FREE(formName);
		if (objId)	AP_FREE(objId);
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetAlertCount() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

SV *
ars_CreateAlertEvent(ctrl,user,alertText,priority,sourceTag,serverName,formName,objectId)
	ARControlStruct *	ctrl
	char            *	user
	char *			alertText
	int			priority
	ARNameType		sourceTag
	ARServerNameType	serverName
	ARNameType		formName
	char *			objectId
	CODE:
	{
		ARStatusList     status;
		int              ret = 0;
		AREntryIdType	 entryId;

		RETVAL=newSVsv(&PL_sv_undef);
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&entryId, 1, AREntryIdType);
#if AR_EXPORT_VERSION >= 6
		ret = ARCreateAlertEvent(ctrl, 
					user,
					alertText,
					priority,
					sourceTag,
					serverName,
					formName,
					objectId,
					entryId,
					&status);

		if( !ARError(ret, status) ) {
			RETVAL=newSVpvn(entryId, AR_MAX_ENTRYID_SIZE);
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"CreateAlertEvent() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

SV *
ars_GetSessionConfiguration(ctrl,variableId)
	ARControlStruct* ctrl
	unsigned int variableId
	CODE:
	{
#if AR_EXPORT_VERSION >= 6
		int              ret = 0;
		ARStatusList     status;
		ARValueStruct    varValue;
		Zero(&status, 1, ARStatusList);
		Zero(&varValue, 1, ARValueStruct);
		
		ret = ARGetSessionConfiguration(ctrl, variableId, &varValue, &status);
		
		if( !ARError(ret, status) ) {
			RETVAL = perl_ARValueStruct(ctrl, &varValue);
		}
		else
		{
			RETVAL = &PL_sv_undef;
		}
		FreeARValueStruct(&varValue, FALSE);
#else /* < 5.0 */
	  XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetSessionConfiguration() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

#
# Destructors for Blessed C structures
#

MODULE = ARS		PACKAGE = ARControlStructPtr

void
DESTROY(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
		ARStatusList status;
		int rv = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		DBG( ("control struct destructor\n") );
# if AR_EXPORT_VERSION >= 4
		rv = ARTermination(ctrl, &status);
# else
		rv = ARTermination(&status);
# endif /* AR_EXPORT_VERSION */
		(void) ARError(rv, status);
#ifdef PROFILE
		AP_FREE(ctrl);
#else
		safefree(ctrl);
#endif
	}


char *
field_cache_key(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  char     server_tag[100];
	  sprintf( server_tag, "%s:%p", ctrl->server, ctrl );
	  RETVAL = server_tag;
	}
	OUTPUT:
	RETVAL


MODULE = ARS		PACKAGE = ARQualifierStructPtr

void
DESTROY(qual)
	ARQualifierStruct *	qual
	CODE:
	{
		DBG( ("arqualifierstruct destructor (%p)\n", qual) );
		FreeARQualifierStruct(qual, FALSE);
		AP_FREE(qual);
	}
