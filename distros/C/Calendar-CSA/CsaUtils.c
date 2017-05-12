#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

  /*
  	Copyright (c) 1997 Kenneth Albanowski. All rights reserved.
	This program is free software; you can redistribute it and/or
	modify it under the same terms as Perl itself.
  */

extern int      _csa_iso8601_to_tick(char *, time_t *);
extern int      _csa_tick_to_iso8601(time_t, char *);
extern int      _csa_iso8601_to_range(char *, time_t *, time_t *);
extern int      _csa_range_to_iso8601(time_t, time_t, char *);
extern int      _csa_iso8601_to_duration(char *, time_t *);
extern int      _csa_duration_to_iso8601(time_t, char *);


#include <csa/csa.h>

#include "CsaUtils.h"

char * CsaError(int error)
{
	switch(error) {
	case CSA_E_AMBIGUOUS_USER:		return "AMBIGUOUS USER";
	case CSA_E_CALENDAR_EXISTS:		return "CALENDAR EXISTS";
	case CSA_E_CALENDAR_NOT_EXIST:		return "CALENDAR NOT EXIST";
	case CSA_E_CALLBACK_NOT_REGISTERED:	return "CALLBACK NOT REGISTERED";
	case CSA_E_DISK_FULL:			return "DISK FULL";
	case CSA_E_FAILURE:			return "FAILURE";
	case CSA_E_FILE_EXIST: 			return "FILE EXIST";
	case CSA_E_FILE_NOT_EXIST:		return "FILE NOT EXIST";
	case CSA_E_INSUFFICIENT_MEMORY:		return "INSUFFICIENT MEMORY";
	case CSA_E_INVALID_ATTRIBUTE:		return "INVALID ATTRIBUTE";
	case CSA_E_INVALID_ATTRIBUTE_VALUE:	return "INVALID ATTRIBUTE VALUE";
	case CSA_E_INVALID_CALENDAR_SERVICE:	return "INVALID CALENDAR SERVICE";
	case CSA_E_INVALID_CONFIGURATION:	return "INVALID CONFIGURATION";
	case CSA_E_INVALID_DATA_EXT:		return "INVALID DATA EXT";
	case CSA_E_INVALID_DATE_TIME:		return "INVALID DATE TIME";
	case CSA_E_INVALID_ENTRY_HANDLE:	return "INVALID ENTRY HANDLE";
	case CSA_E_INVALID_ENUM:		return "INVALID ENUM";
	case CSA_E_INVALID_FILE_NAME:		return "INVALID FILE NAME";
	case CSA_E_INVALID_FLAG:		return "INVALID FLAG";
	case CSA_E_INVALID_FUNCTION_EXT:	return "INVALID FUNCTION EXT";
	case CSA_E_INVALID_MEMORY:		return "INVALID MEMORY";
	case CSA_E_INVALID_PARAMETER:		return "INVALID PARAMETER";
	case CSA_E_INVALID_PASSWORD:		return "INVALID PASSWORD";
	case CSA_E_INVALID_RULE:		return "INVALID RULE";
	case CSA_E_INVALID_SESSION_HANDLE:	return "INVALID SESSION HANDLE";
	case CSA_E_INVALID_USER:		return "INVALID USER";
	case CSA_E_NO_AUTHORITY:		return "NO AUTHORITY";
	case CSA_E_NOT_SUPPORTED:		return "NOT SUPPORTED";
	case CSA_E_PASSWORD_REQUIRED:		return "PASSWORD REQUIRED";
	case CSA_E_READONLY:			return "READONLY";
	case CSA_E_SERVICE_UNAVAILABLE:		return "SERVICE UNAVAILABLE";
	case CSA_E_TEXT_TOO_LARGE:		return "TEXT TOO LARGE";
	case CSA_E_TOO_MANY_USERS:		return "TOO MANY USERS";
	case CSA_E_UNABLE_TO_OPEN_FILE:		return "UNABLE TO OPEN FILE";
	case CSA_E_UNSUPPORTED_ATTRIBUTE:	return "UNSUPPORTED ATTRIBUTE";
	case CSA_E_UNSUPPORTED_CHARACTER_SET:	return "UNSUPPORTED CHARACTER SET";
	case CSA_E_UNSUPPORTED_DATA_EXT:	return "UNSUPPORTED DATA EXT";
	case CSA_E_UNSUPPORTED_ENUM:		return "UNSUPPORTED ENUM";
	case CSA_E_UNSUPPORTED_FLAG:		return "UNSUPPORTED FLAG";
	case CSA_E_UNSUPPORTED_FUNCTION_EXT:	return "UNSUPPORTED FUNCTION EXT";
	case CSA_E_UNSUPPORTED_PARAMETER:	return "UNSUPPORTED PARAMETER";
	case CSA_E_UNSUPPORTED_VERSION:		return "UNSUPPORTED VERSION";
	case CSA_E_USER_NOT_FOUND:		return "USER NOT FOUND";
#ifdef CSA_E_TIME_ONLY    
	case CSA_E_TIME_ONLY:			return "TIME ONLY";
#endif	    
#ifdef  CSA_X_DT_E_BACKING_STORE_PROBLEM
	case CSA_X_DT_E_BACKING_STORE_PROBLEM:	return "X-DT BACKING STORE PROBLEM";
#endif
#ifdef  CSA_X_DT_E_ENTRY_NOT_FOUND
	case CSA_X_DT_E_ENTRY_NOT_FOUND:	return "X-DT ENTRY NOT FOUND";
#endif
#ifdef  CSA_X_DT_E_INVALID_SERVER_LOCATION
	case CSA_X_DT_E_INVALID_SERVER_LOCATION:return "X-DT INVALID SERVER LOCATION";
#endif
#ifdef  CSA_X_DT_E_SERVER_TIMEOUT
	case CSA_X_DT_E_SERVER_TIMEOUT:		return "X-DT SERVER TIMEOUT";
#endif
#ifdef  CSA_X_DT_E_SERVICE_NOT_REGISTERED
	case CSA_X_DT_E_SERVICE_NOT_REGISTERED:	return "X-DT SERVICE NOT REGISTERED";
#endif
	default:				return "UNKNOWN ERROR";

	}
}

void CsaCroak(char * routine, int err)
{
	croak("Csa %s failed: %s (%d)", routine, CsaError(err), err);
}		

static void * alloc_temp(int size)
{
	SV * s = sv_2mortal(newSVpv("",0));
	SvGROW(s, size);
	return SvPV(s, na);
}


void CroakOpts(char * name, char * value, struct opts * o)
{
	SV * result = sv_newmortal();
	char buffer[40];
	int i;
	
	sv_catpv(result, "invalid ");
	sv_catpv(result, name);
	sv_catpv(result, " ");
	sv_catpv(result, value);
	sv_catpv(result, ", expecting");
	for(i=0;o[i].name;i++) {
		if (i==0)
			sv_catpv(result," '");
		else if (o[i+1].name)
			sv_catpv(result,"', '");
		else
			sv_catpv(result,"', or '");
		sv_catpv(result, o[i].name);
	}
	sv_catpv(result,"'");
	croak(SvPV(result, na));
}

int Csa_accept_numeric_enumerations = 0;
int Csa_generate_numeric_enumerations = 0;

long SvOpt(SV * name, char * optname, struct opts * o) 
{
	int i;
	char * n = SvPV(name, na);
	for(i=0;o[i].name;i++) 
		if (strEQ(o[i].name, n))
			return o[i].value;
	if (Csa_accept_numeric_enumerations && SvIOKp(name))
		return SvIV(name);
	CroakOpts(optname, n, o);
}

SV * newSVOpt(long value, char * optname, struct opts * o) 
{
	int i;
	if (Csa_generate_numeric_enumerations)
		return newSViv(value);
	for(i=0;o[i].name;i++)
		if (o[i].value == value)
			return newSVpv(o[i].name, 0);
	croak("invalid %s value %d", optname, value);
}

long SvOptFlags(SV * name, char * optname, struct opts * o) 
{
	int i;
	int val=0;
	if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVAV)) {
		AV * r = (AV*)SvRV(name);
		for(i=0;i<=av_len(r);i++)
			val |= SvOpt(*av_fetch(r, i, 0), optname, o);
	} else if (SvRV(name) && (SvTYPE(SvRV(name)) == SVt_PVHV)) {
		HV * r = (HV*)SvRV(name);
		/* This is bad, as we don't catch members with invalid names */
		for(i=0;o[i].name;i++) {
			SV ** s = hv_fetch(r, o[i].name, strlen(o[i].name), 0);
			if (s && SvOK(*s) && SvTRUE(*s))
				val |= o[i].value;
		}
	} else
		val |= SvOpt(name, optname, o);
	return val;
}

SV * newSVOptFlags(long value, char * optname, struct opts * o, int hash) 
{
	SV * result;
	if (Csa_generate_numeric_enumerations)
		return newSViv(value);
	if (hash) {
		HV * h = newHV();
		int i;
		result = newRV((SV*)h);
		SvREFCNT_dec(h);
		for(i=0;o[i].name;i++)
			if ((value & o[i].value) == o[i].value) {
				hv_store(h, o[i].name, strlen(o[i].name), newSViv(1), 0);
				value &= ~o[i].value;
			}
	} else {
		AV * a = newAV();
		int i;
		result = newRV((SV*)a);
		SvREFCNT_dec(a);
		for(i=0;o[i].name;i++)
			if ((value & o[i].value) == o[i].value) {
				av_push(a, newSVpv(o[i].name, 0));
				value &= ~o[i].value;
			}
	}
	return result;
}

static struct opts attributes[] = {
	{CSA_VALUE_BOOLEAN, "BOOLEAN"},
	{CSA_VALUE_ENUMERATED, "ENUMERATED"},
	{CSA_VALUE_FLAGS, "FLAGS"},
	{CSA_VALUE_SINT32, "SINT32"},
	{CSA_VALUE_UINT32, "UINT32"},
	{CSA_VALUE_STRING, "STRING"},
	{CSA_VALUE_CALENDAR_USER, "CALENDAR USER"},
	{CSA_VALUE_DATE_TIME, "DATE TIME"},
	{CSA_VALUE_DATE_TIME_RANGE, "DATE TIME RANGE"},
	{CSA_VALUE_TIME_DURATION, "TIME DURATION"},
	{CSA_VALUE_ACCESS_LIST, "ACCESS LIST"},
	{CSA_VALUE_ATTENDEE_LIST, "ATTENDEE LIST"},
	{CSA_VALUE_DATE_TIME_LIST, "DATE TIME LIST"},
	{CSA_VALUE_REMINDER, "REMINDER"},
	{CSA_VALUE_OPAQUE_DATA, "OPAQUE DATA"},
	{0,0}
};

static struct opts scopes[] = {
	{CSA_SCOPE_ALL, "ALL"},
	{CSA_SCOPE_ONE, "ONE"},
	{CSA_SCOPE_FORWARD, "FORWARD"},
	{0, 0}
};

SV * newSVCSA_SCOPE(int scope) { return newSVOpt(scope, "scope", scopes); }
int SvCSA_SCOPE(SV * name) { return SvOpt(name, "scope", scopes); }

static struct opts lineterms[] = {
	{CSA_LINE_TERM_CRLF, "CRLF"},
	{CSA_LINE_TERM_LF, "LF"},
	{CSA_LINE_TERM_CR, "CR"},
	{0, 0}
};

SV * newSVCSA_LINE_TERM(int value) { return newSVOpt(value, "line term", lineterms); }
int SvCSA_LINE_TERM(SV * name) { return SvOpt(name, "line term", lineterms); }

static struct opts requires[] = {
	{CSA_REQUIRED_NO, "NO"},
	{CSA_REQUIRED_OPT, "OPT"},
	{CSA_REQUIRED_YES, "YES"},
	{0, 0}
};


SV * newSVCSA_REQUIRED(int value) { return newSVOpt(value, "required", requires); }
int SvCSA_REQUIRED(SV * name) { return SvOpt(name, "required", requires); }

static struct opts types[] = {
	{CSA_USER_TYPE_INDIVIDUAL, "INDIVIDUAL"},
	{CSA_USER_TYPE_GROUP, "GROUP"},
	{CSA_USER_TYPE_RESOURCE, "RESOURCE"},
	{0, 0}
};

SV * newSVCSA_USER_TYPE(int type) { return newSVOpt(type, "type", types); }
int SvCSA_USER_TYPE(SV * name) { return SvOpt(name, "type", types); }

static struct opts lookups[] = {
	{CSA_LOOKUP_RESOLVE_PREFIX_SEARCH, "PREFIX SEARCH"},
	{CSA_LOOKUP_RESOLVE_IDENTITY, "IDENTITY"},
	{0, 0}
};

SV * newSVCSA_LOOKUP(int value) { return newSVOpt(value, "lookup", lookups); }
int SvCSA_LOOKUP(SV * name) { return SvOpt(name, "lookup", lookups); }

static struct opts matches[] = {
	{CSA_MATCH_ANY, 			"ANY"},
	{CSA_MATCH_EQUAL_TO,			"EQUAL TO"},
	{CSA_MATCH_NOT_EQUAL_TO,		"NOT EQUAL TO"},
	{CSA_MATCH_GREATER_THAN,		"GREATER THAN"},
	{CSA_MATCH_LESS_THAN,			"LESS THAN"},
	{CSA_MATCH_GREATER_THAN_OR_EQUAL_TO,	"GREATER THAN OR EQUAL TO"},
	{CSA_MATCH_LESS_THAN_OR_EQUAL_TO,	"LESS THAN OR EQUAL TO"},
	{CSA_MATCH_CONTAIN,			"CONTAIN"},
	{CSA_MATCH_ANY, 			"*"},
	{CSA_MATCH_EQUAL_TO, 			"=="},
	{CSA_MATCH_NOT_EQUAL_TO, 		"!="},
	{CSA_MATCH_NOT_EQUAL_TO, 		"<>"},
	{CSA_MATCH_GREATER_THAN, 		">"},
	{CSA_MATCH_LESS_THAN, 			"<"},
	{CSA_MATCH_GREATER_THAN_OR_EQUAL_TO, 	">="},
	{CSA_MATCH_LESS_THAN_OR_EQUAL_TO, 	"<="},
	{CSA_MATCH_CONTAIN,			"//"},
	{0, 0}
};

SV * newSVCSA_MATCH(int match) { return newSVOpt(match, "match", matches); }
int SvCSA_MATCH(SV * name) { return SvOpt(name, "match", matches); }

SV * newSVISO_date_time(char * value, int doiso)
{
	if (doiso)
		return newSVpv(value, 0);
	else {
		time_t tick;
		if (_csa_iso8601_to_tick(value, &tick))
			return newSVsv(&sv_undef);
		else
			return newSViv(tick);
	}
}
SV * newSVISO_date_time_range(char * value, int doiso)
{
	if (doiso)
		return newSVpv(value, 0);
	else {
		time_t tick1,tick2;
		AV * l;
		SV * result;
		if (_csa_iso8601_to_range(value, &tick1, &tick2))
			return newSVsv(&sv_undef);
		l = newAV();
		av_push(l, newSViv(tick1));
		av_push(l, newSViv(tick2));
		result = newRV((SV*)l);
		SvREFCNT_dec(l);
		return result;
	}
}
SV * newSVISO_time_duration(char * value, int doiso)
{
	if (doiso)
		return newSVpv(value, 0);
	else {
		time_t tick;
		if (_csa_iso8601_to_duration(value, &tick))
			return newSVsv(&sv_undef);
		return newSViv(tick);
	}
}

char * SvISO_date_time(SV * value, char * buffer)
{
	if (!value || !SvOK(value))
		return 0;
		
	if (!buffer)
		buffer = alloc_temp(64);

	if (SvIOKp(value) || SvNOKp(value)) {
		_csa_tick_to_iso8601(SvIV(value), buffer);
	} else {
		strncpy(buffer, SvPV(value, na), 63);
		buffer[63] = '\0';
		if (strlen(buffer)==0)
			return 0;
	}
	
	return buffer;
}
char * SvISO_date_time_range(SV * value, char  *buffer)
{
	if (!value || !SvOK(value))
		return 0;

	if (!buffer)
		buffer = alloc_temp(64);
	
	if (SvRV(value)) {
		time_t t1,t2;
		AV * a = (AV*)SvRV(value);
		t1 = SvIV(*av_fetch(a,0,0));
		t2 = SvIV(*av_fetch(a,1,0));
		_csa_range_to_iso8601(t1, t2, buffer);
	} else {
		strncpy(buffer, SvPV(value, na), 63);
		buffer[63] = '\0';
		if (strlen(buffer)==0)
			return 0;
	}
	return buffer;
}
char * SvISO_time_duration(SV * value, char * buffer)
{
	if (!value || !SvOK(value))
		return 0;

	if (!buffer)
		buffer = alloc_temp(64);

	if (SvIOKp(value) || SvNOKp(value)) {
		_csa_duration_to_iso8601(SvIV(value), buffer);
	} else {
		strncpy(buffer, SvPV(value, na), 63);
		buffer[63] = '\0';
		
		if (strlen(buffer)==0)
			return 0;
	}
	
	return buffer;
}


SV * newSVCSA_calendar_user(CSA_calendar_user * user)
{
	HV * u;
	SV * r;
	if (!user)
		return newSVsv(&sv_undef);
	u = newHV();
	if (user->user_name)
		hv_store(u, "user_name", 9, newSVpv(user->user_name,0), 0);
	if (user->calendar_address)
		hv_store(u, "calendar_address", 16, newSVpv(user->calendar_address,0), 0);
	if (user->calendar_address ||
		user->user_name ||
		user->user_type)
		hv_store(u, "user_type", 9, newSVCSA_USER_TYPE(user->user_type), 0);
	r = newRV((SV*)u);
	SvREFCNT_dec(u);
	return r;
}

CSA_calendar_user * SvCSA_calendar_user(SV * user, CSA_calendar_user * target)
{
	HV * u = (HV*)SvRV(user);
	SV ** s;
	
	if (!user || !SvOK(user))
		return 0;
	
	if (!target)
		target = alloc_temp(sizeof(CSA_calendar_user));

	if ((s=hv_fetch(u, "user_name", 9, 0)) && SvOK(*s))
		target->user_name = SvPV(*s, na);
	else
		target->user_name = 0;
	if ((s=hv_fetch(u, "calendar_address", 16, 0)) && SvOK(*s))
		target->calendar_address = SvPV(*s, na);
	else
		target->calendar_address = 0;
	if ((s=hv_fetch(u, "user_type", 9, 0)) && SvOK(*s))
		target->user_type = SvCSA_USER_TYPE(*s);
	else
		target->user_type = 0;
	return target;
}

static struct opts rights[] = {
	{CSA_FREE_TIME_SEARCH, "FREE TIME SEARCH"},
	{CSA_VIEW_PUBLIC_ENTRIES, "VIEW PUBLIC ENTRIES"},
	{CSA_INSERT_PUBLIC_ENTRIES, "INSERT PUBLIC ENTRIES"},
	{CSA_INSERT_CONFIDENTIAL_ENTRIES, "INSERT CONFIDENTIAL ENTRIES"},
	{CSA_INSERT_PRIVATE_ENTRIES, "INSERT PRIVATE ENTRIES"},
	{CSA_CHANGE_PUBLIC_ENTRIES, "CHANGE PUBLIC ENTRIES"},
	{CSA_CHANGE_CONFIDENTIAL_ENTRIES, "CHANGE CONFIDENTIAL ENTRIES"},
	{CSA_CHANGE_PRIVATE_ENTRIES, "CHANGE PRIVATE ENTRIES"},
	{CSA_VIEW_CALENDAR_ATTRIBUTES, "VIEW CALENDAR ATTRIBUTES"},
	{CSA_INSERT_CALENDAR_ATTRIBUTES, "INSERT CALENDAR ATTRIBUTES"},
	{CSA_CHANGE_CALENDAR_ATTRIBUTES, "CHANGE CALENDAR ATTRIBUTES"},
	{CSA_ORGANIZER_RIGHTS, "ORGANIZER RIGHTS"},
	{CSA_OWNER_RIGHTS, "OWNER RIGHTS"},
	{0, 0}
};

SV * newSVCSA_access_rights(CSA_access_rights * right)
{
	HV * u;
	SV * r;
	int i;
	if (!right)
		return newSVsv(&sv_undef);
	u = newHV();
	hv_store(u, "user", 4, newSVCSA_calendar_user(right->user), 0);
	hv_store(u, "rights", 6, newSVOptFlags(right->rights, "rights", rights, 1), 0);
	r = newRV((SV*)u);
	SvREFCNT_dec(u);
	return r;
}

CSA_access_rights * SvCSA_access_rights(SV * data, CSA_access_rights * target)
{	
	HV * h;
	SV ** s;
	int i;
	
	if (!data || !SvOK(data))
		return 0;
		
	if (!target)
		target = alloc_temp(sizeof(CSA_access_rights));

	h = (HV*)SvRV(data);
	
	if ((s = hv_fetch(h, "user", 4, 0)) && SvOK(*s))
		target->user = SvCSA_calendar_user(*s, 0);
	else
		target->user = 0;
	target->rights = 0;
	if ((s = hv_fetch(h, "rights", 6, 0)) && SvOK(*s))
		target->rights = SvOptFlags(*s, "rights", rights);
	return target;
}

SV * newSVCSA_access_list(CSA_access_list list)
{	
	AV * l;
	SV * r;
	CSA_access_rights * right;
	if (!list)
		return newSVsv(&sv_undef);
	l = newAV();
	for(right = list; right; right=right->next)
		av_push(l, newSVCSA_access_rights(right));
	r = newRV((SV*)l);
	SvREFCNT_dec(l);
	return r;
}

CSA_access_list SvCSA_access_list(SV * data, CSA_access_list list)
{	
	AV * l;
	int i;

	if (!data || !SvOK(data))
		return 0;

	l = (AV*)SvRV(data);
	
	if (av_len(l)==-1)
		return 0;

	if (!list)
		list = alloc_temp(sizeof(CSA_access_rights)* (av_len(l)+1));

	for(i=0;i<=av_len(l);i++) {
		SvCSA_access_rights(*av_fetch(l, i, 0), list);
		list->next = list+i+1;
	}
	if (i)
		(list+i-1)->next = 0;
	
	return list;
}

static struct opts statuses[] = {
	{CSA_STATUS_ACCEPTED, "ACCEPTED"},
	{CSA_STATUS_NEEDS_ACTION, "NEEDS ACTION"},
	{CSA_STATUS_SENT, "SENT"},
	{CSA_STATUS_TENTATIVE, "TENTATIVE"},
	{CSA_STATUS_CONFIRMED, "CONFIRMED"},
	{CSA_STATUS_REJECTED, "REJECTED"},
	{CSA_STATUS_COMPLETED, "COMPLETED"},
	{CSA_STATUS_DELEGATED, "DELEGATED"},
#ifdef CSA_X_DT_STATUS_ACTIVE
	{CSA_X_DT_STATUS_ACTIVE, "X-DT ACTIVE"},	
#endif
#ifdef CSA_X_DT_STATUS_DELETE_PENDING
	{CSA_X_DT_STATUS_DELETE_PENDING, "X-DT DELETE PENDING"},	
#endif
#ifdef CSA_X_DT_STATUS_ADD_PENDING
	{CSA_X_DT_STATUS_ADD_PENDING, "X-DT ADD PENDING"},	
#endif
#ifdef CSA_X_DT_STATUS_COMMITTED
	{CSA_X_DT_STATUS_COMMITTED, "X-DT COMMITTED"},	
#endif
#ifdef CSA_X_DT_STATUS_CANCELLED
	{CSA_X_DT_STATUS_CANCELLED, "X-DT CANCELLED"},	
#endif
	{0, 0}
};

static struct opts priorities[] = {
	{CSA_FOR_YOUR_INFORMATION, "FOR YOUR INFORMATION"},
	{CSA_ATTENDANCE_REQUESTED, "ATTENDANCE REQUESTED"},
	{CSA_ATTENDANCE_REQUIRED, "ATTENDANCE REQUIRED"},
	{CSA_IMMEDIATE_RESPONSE, "IMMEDIATE RESPONSE"},
	{0, 0}
};

SV * newSVCSA_attendee(CSA_attendee * attendee)
{
	HV * u;
	HV * flags;
	SV * r;
	int i;
	if (!attendee)
		return newSVsv(&sv_undef);
	u = newHV();
	flags = newHV();
	hv_store(u, "attendee", 8, newSVCSA_calendar_user(&attendee->attendee), 0);
	hv_store(u, "rsvp_requested", 14, newSViv(attendee->rsvp_requested),0);
	hv_store(u, "status", 6, newSVOpt(attendee->status, "status", statuses), 0);
	hv_store(u, "priority", 8, newSVOpt(attendee->status, "priority", priorities), 0);
	r = newRV((SV*)u);
	SvREFCNT_dec(u);
	return r;
}

SV * newSVCSA_attendee_list(CSA_attendee_list list)
{	
	AV * l;
	SV * r;
	CSA_attendee * attendee;
	if (!list)
		return newSVsv(&sv_undef);
	l = newAV();
	for(attendee = list; attendee; attendee = attendee->next)
		av_push(l, newSVCSA_attendee(attendee));
	r = newRV((SV*)l);
	SvREFCNT_dec(l);
	return r;
}

SV * newSVCSA_date_time_list(CSA_date_time_list list, int doiso_times)
{	
	AV * l;
	SV * r;
	CSA_date_time_entry * dt;
	if (!list)
		return newSVsv(&sv_undef);
	l = newAV();
	for(dt = list; dt; dt = dt->next)
		av_push(l, newSVISO_date_time(dt->date_time, doiso_times));
	r = newRV((SV*)l);
	SvREFCNT_dec(l);
	return r;
}

CSA_date_time_list SvCSA_date_time_list(SV * data, CSA_date_time_list target)
{	
	AV * l;
	int i;

	if (!data || !SvOK(data))
		return 0;

	l = (AV*)SvRV(data);
	
	if (av_len(l)<0)	
		return 0;
	
	if (!target)
		target = alloc_temp(sizeof(CSA_date_time_entry)*(av_len(l)+1));
	
	for(i=0;i<=av_len(l);i++) {
		(target+i)->date_time = SvISO_date_time(*av_fetch(l, i, 0), 0);
		(target+i)->next = target+i+1;
	}
	if (i)
		(target+i-1)->next = 0;
	
	return target;
}

SV * newSVCSA_opaque_data(CSA_opaque_data * data)
{	
	if (!data || !data->data)
		return newSVsv(&sv_undef);
	return newSVpv((char *)data->data, data->size);
}


CSA_opaque_data * SvCSA_opaque_data(SV * data, CSA_opaque_data * target)
{	
        unsigned int len;

	if (!data || !SvOK(data))
		return 0;

	if (!target)
		target = alloc_temp(sizeof(CSA_opaque_data));
	target->data = (CSA_uint8 *)SvPV(data, len);
	target->size = len;
	return target;
}

SV * newSVCSA_reminder(CSA_reminder * rem, int doiso_times)
{	
	HV * u;
	HV * flags;
	SV * r;
	int i;
	if (!rem)
		return newSVsv(&sv_undef);
	u = newHV();
	hv_store(u, "lead_time", 9, newSVISO_time_duration(rem->lead_time, doiso_times), 0);
	hv_store(u, "snooze_time", 11, newSVISO_time_duration(rem->snooze_time, doiso_times), 0);
	hv_store(u, "repeat_count", 12, newSViv(rem->repeat_count), 0);
	hv_store(u, "reminder_data", 13, newSVCSA_opaque_data(&rem->reminder_data), 0);
	r = newRV((SV*)u);
	SvREFCNT_dec(u);
	return r;
}

CSA_reminder * SvCSA_reminder(SV * data, CSA_reminder * target)
{	
	HV * h = (HV*)SvRV(data);
	SV ** s;
	int i;

	if (!data || !SvOK(data))
		return 0;

	if (!target)
		target = alloc_temp(sizeof(CSA_reminder));
	memset(target, 0, sizeof(CSA_reminder));
	
	if ((s=hv_fetch(h, "lead_time", 9, 0)) && SvOK(*s))
		target->lead_time = SvISO_time_duration(*s,0);
	else
		target->lead_time = 0;
	if ((s=hv_fetch(h, "snooze_time", 11, 0)) && SvOK(*s))
		target->snooze_time = SvISO_time_duration(*s,0);
	else
		target->snooze_time = 0;
	if ((s=hv_fetch(h, "repeat_count", 12, 0)) && SvOK(*s))
		target->repeat_count = SvIV(*s);
	else
		target->repeat_count = 0;
	if ((s=hv_fetch(h, "data", 4, 0)) && SvOK(*s))
		SvCSA_opaque_data(*s, &target->reminder_data);
		
	return target;
}


SV * newSVCSA_attribute_value(CSA_attribute_value * attr, int doshorten, int doiso_times)
{
	HV * h;
	SV * r;
	SV * type = 0;
	SV * value = 0;
	if (!attr)
		return newSVsv(&sv_undef);
	h = newHV();
	type = newSVOpt(attr->type, "attribute type", attributes);
	switch (attr->type) {
	case CSA_VALUE_BOOLEAN:
		value = newSViv(attr->item.boolean_value);
		break;
	case CSA_VALUE_ENUMERATED:
		value = newSViv(attr->item.enumerated_value);
		break;
	case CSA_VALUE_FLAGS:
		value = newSViv(attr->item.flags_value);
		break;
	case CSA_VALUE_SINT32:
		value = newSViv(attr->item.sint32_value);
		break;
	case CSA_VALUE_UINT32:
		value = newSViv(attr->item.uint32_value);
		break;
	case CSA_VALUE_STRING:
		value = newSVpv(shorten(attr->item.string_value, doshorten), 0);
		break;
	case CSA_VALUE_CALENDAR_USER:
		value = newSVCSA_calendar_user(attr->item.calendar_user_value);
		break;
	case CSA_VALUE_DATE_TIME:
		value = newSVISO_date_time(attr->item.date_time_value, doiso_times);
		break;
	case CSA_VALUE_DATE_TIME_RANGE:
		value = newSVISO_date_time_range(attr->item.date_time_range_value, doiso_times);
		break;
	case CSA_VALUE_TIME_DURATION:
		value = newSVISO_time_duration(attr->item.time_duration_value, doiso_times);
		break;
	case CSA_VALUE_ACCESS_LIST:
		value = newSVCSA_access_list(attr->item.access_list_value);
		break;
	case CSA_VALUE_DATE_TIME_LIST:
		value = newSVCSA_date_time_list(attr->item.date_time_list_value, doiso_times);
		break;
	case CSA_VALUE_REMINDER:
		value = newSVCSA_reminder(attr->item.reminder_value, doiso_times);
		break;
	case CSA_VALUE_OPAQUE_DATA:
		value = newSVCSA_opaque_data(attr->item.opaque_data_value);
		break;
	default:
		value = newSVsv(&sv_undef); /* unknown type */
	}
	hv_store(h, "type", 4, type, 0);
	hv_store(h, "value", 5, value, 0);
	r = newRV((SV*)h);
	SvREFCNT_dec(h);
	return r;
}

SV * newSVCSA_attribute(CSA_attribute * attr, int doshorten, int doiso_times)
{
	HV * h;
	SV * r;
	char * type = 0;
	SV * value = 0;
	if (!attr)
		return newSVsv(&sv_undef);
	h = newHV();
	hv_store(h, "name", 4, newSVpv(attr->name,0), 0);
	hv_store(h, "value", 5, newSVCSA_attribute_value(attr->value, doshorten, doiso_times), 0);
	
	r = newRV((SV*)h);
	SvREFCNT_dec(h);
	return r;
}

CSA_attribute_value * SvCSA_attribute_value(SV * attr, CSA_attribute_value * target)
{
	HV * h;
	SV * r;
	SV ** s;
	int type = 0;
	SV * value = 0;

	if (!attr || !SvOK(attr))
		return 0;

	if (SvTYPE(SvRV(attr)) != SVt_PVHV)
		croak("an attribute value must be a hash containing type and value keys");
		
	h = (HV*)SvRV(attr);
	if (!(s=hv_fetch(h, "type", 4, 0)) || !SvOK(*s))
		croak("an attribute value must be a hash containing type and value keys");
	
	type = SvOpt(*s, "attribute type", attributes);

	if (!(s=hv_fetch(h, "value", 5, 0)))
		croak("an attribute value must be a hash containing type and value keys");

	if (!target)
		target = alloc_temp(sizeof(CSA_attribute_value));
	
	target->type = type;
	switch (type) {
	case CSA_VALUE_BOOLEAN:
		target->item.boolean_value = SvIV(*s);
		break;
	case CSA_VALUE_ENUMERATED:
		target->item.enumerated_value = SvIV(*s);
		break;
	case CSA_VALUE_FLAGS:
		target->item.flags_value = SvIV(*s);
		break;
	case CSA_VALUE_SINT32:
		target->item.sint32_value = SvIV(*s);
		break;
	case CSA_VALUE_UINT32:
		target->item.uint32_value = SvIV(*s);
		break;
	case CSA_VALUE_STRING:
		target->item.string_value = lengthen(SvPV(*s, na));
		break;
	case CSA_VALUE_CALENDAR_USER:
		target->item.calendar_user_value = SvCSA_calendar_user(*s, 0);
		break;
	case CSA_VALUE_DATE_TIME:
		target->item.date_time_value = SvISO_date_time(*s, 0);
		break;
	case CSA_VALUE_DATE_TIME_RANGE:
		target->item.date_time_range_value = SvISO_date_time_range(*s, 0);
		break;
	case CSA_VALUE_TIME_DURATION:
		target->item.time_duration_value = SvISO_time_duration(*s, 0);
		break;
	case CSA_VALUE_ACCESS_LIST:
		target->item.access_list_value = SvCSA_access_list(*s, 0);
		break;
	case CSA_VALUE_DATE_TIME_LIST:
		target->item.date_time_list_value = SvCSA_date_time_list(*s, 0);
		break;
	case CSA_VALUE_REMINDER:
		target->item.reminder_value = SvCSA_reminder(*s, 0);
		break;
	case CSA_VALUE_OPAQUE_DATA:
		target->item.opaque_data_value = SvCSA_opaque_data(*s, 0);
		break;
	defaut:
		croak("unhandled attribute type");
	}
	return target;
}

CSA_attribute * SvCSA_attribute(SV * attr, CSA_attribute * target)
{
	HV * h;
	SV * r;
	SV ** s;
	char * type = 0;
	SV * value = 0;

	if (!attr || !SvOK(attr))
		return 0;
	
	if (!target)
		target = alloc_temp(sizeof(CSA_attribute));
	
	h = (HV*)SvRV(attr);
	if ((s=hv_fetch(h, "name", 4, 0)) && SvOK(*s))
		target->name = SvPV(*s, na);
	else
		croak("attribute must have name");
	if ((s=hv_fetch(h, "value", 5, 0)) && SvOK(*s))
		target->value = SvCSA_attribute_value(*s, 0);
	else
		croak("attribute must have value");
	
	return target;
}

static struct opts cb_modes[] = {
	{CSA_CB_CALENDAR_LOGON, "CALENDAR LOGON"},
	{CSA_CB_CALENDAR_DELETED, "CALENDAR DELETED"},
	{CSA_CB_CALENDAR_ATTRIBUTE_UPDATED, "CALENDAR ATTRIBUTE UPDATED"},
	{CSA_CB_ENTRY_ADDED, "ENTRY ADDED"},
	{CSA_CB_ENTRY_DELETED, "ENTRY DELETED"},
	{CSA_CB_ENTRY_UPDATED, "ENTRY UPDATED"},
	{0, 0}
};

int SvCSA_callback_mode(SV * mode) { return SvOpt(mode, "callback mode", cb_modes); }

static struct {char *l; char *s; } short_names[] = {
	{"-//XAPIA/CSA/CALATTR//NONSGML Access List//EN", "Access List"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Calendar Name//EN", "Calendar Name"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Calendar Owner//EN", "Calendar Owner"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Calendar Size//EN", "Calendar Size"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Character Set//EN", "Character Set"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Country//EN", "Country"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Date Created//EN", "Date Created"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Language//EN", "Language"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Number Entries//EN", "Number Entries"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Product Identifier//EN", "Product Identifier"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Time Zone//EN", "Time Zone"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Version//EN", "Version"},
	{"-//XAPIA/CSA/CALATTR//NONSGML Work Schedule//EN", "Work Schedule"},
	{"-//CDE_XAPIA_PRIVATE/CSA/CALATTR//NONSGML Server Version//EN", "Server Version"},
	{"-//CDE_XAPIA_PRIVATE/CSA/CALATTR//NONSGML Data Version//EN", "Data Version"},
	{"-//CDE_XAPIA_PRIVATE/CSA/CALATTR//NONSGML Calendar Delimiter//EN", "Calendar Delimiter"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Attendee List//EN", "Attendee List"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Audio Reminder//EN", "Audio Reminder"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Classification//EN", "Classification"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Date Completed//EN", "Date Completed"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Date Created//EN", "Date Created"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Description//EN", "Description"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Due Date//EN", "Due Date"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML End Date//EN", "End Date"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Exception Dates//EN", "Exception Dates"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Exception Rule//EN", "Exception Rule"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Flashing Reminder//EN", "Flashing Reminder"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Last Update//EN", "Last Update"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Mail Reminder//EN", "Mail Reminder"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Number Recurrences//EN", "Number Recurrences"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Organizer//EN", "Organizer"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Popup Reminder//EN", "Popup Reminder"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Priority//EN", "Priority"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Recurrence Rule//EN", "Recurrence Rule"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Recurring Dates//EN", "Recurring Dates"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Reference Identifier//EN", "Reference Identifier"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Sequence Number//EN", "Sequence Number"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Sponsor//EN", "Sponsor"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Start Date//EN", "Start Date"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Status//EN", "Status"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Subtype//EN", "Subtype"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Summary//EN", "Summary"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Time Transparency//EN", "Time Transparency"},
	{"-//XAPIA/CSA/ENTRYATTR//NONSGML Type//EN", "Type"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Show Time//EN", "Show Time"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Repeat Type//EN", "Repeat Type"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Repeat Times//EN", "Repeat Times"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Repeat Interval//EN", "Repeat Interval"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Sequence End Date//EN", "Sequence End Date"},
	{"-//CDE_XAPIA_PRIVATE/CSA/ENTRYATTR//NONSGML Entry Delimiter//EN", "Entry Delimiter"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Appointment//EN", "Subtype Appointment"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Class//EN", "Subtype Class"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Holiday//EN", "Subtype Holiday"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Meeting//EN", "Subtype Meeting"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Miscellaneous//EN", "Subtype Miscellaneous"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Phone Call//EN", "Subtype Phone Call"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Sick Day//EN", "Subtype Sick Day"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Special Occasion//EN", "Subtype Special Occasion"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Travel//EN", "Subtype Travel"},
	{"-//XAPIA/CSA/SUBTYPE//NONSGML Subtype Vacation//EN", "Subtype Vacation"},
	{0,0}
};

char * shorten(char * arg, int doit)
{
	if (!doit)	
		return arg;
	else {
		int i;
		for(i=0;short_names[i].l;i++)
			if (strEQ(short_names[i].l,arg))
				return short_names[i].s;
		return arg;
	}
}

char * lengthen(char * arg)
{
	int i;
	for(i=0;short_names[i].s;i++)
		if (strEQ(short_names[i].s,arg))
			return short_names[i].l;
	return arg;
}

void * Csa_safe_calloc(int nelem, size_t elsize)
{
    void *ptr;

    ptr = calloc(nelem, elsize);

    if (ptr == NULL)
    {
	croak("out of memory");
    }

    return ptr;
}

void * Csa_safe_malloc(int size)
{
    void *ptr;
    
    ptr = malloc(size);

    if (ptr == NULL)
    {
	croak("out of memory");
    }

    return ptr;
}
