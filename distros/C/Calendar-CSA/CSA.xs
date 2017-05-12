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
  
/*#define CSA_DEBUG */

#include <csa/csa.h>

#include "CsaUtils.h"

#define safe_malloc Csa_safe_malloc
#define safe_calloc Csa_safe_calloc

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

int max_callback = 0;

AV *callbacks, *callback_mode;

void callback_handler(
				CSA_session_handle session,
				CSA_flags reason,
				CSA_buffer call_data,
				CSA_buffer client_data,
				CSA_extension *callback_extensions)
{
	int callback = (int)client_data;
	SV ** arg = av_fetch(callbacks, callback, 0);
	AV * args = (AV*)SvRV(*arg);
	int i,j;
	dSP;
	PUSHMARK(sp);
	for(i=1;i<=av_len(args);i++)
		XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
	{
#ifdef CSA_DEBUG
		printf("Dealing with callback type %d, tag %d\n", reason, callback);
#endif
		if (reason & CSA_CB_CALENDAR_LOGON) {
			CSA_logon_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("CALENDAR LOGON", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
		}
		if (reason & CSA_CB_CALENDAR_DELETED) {
			CSA_calendar_deleted_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("CALENDAR DELETED", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
		}
		if (reason & CSA_CB_CALENDAR_ATTRIBUTE_UPDATED) {
			CSA_calendar_attr_update_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("CALENDAR ATTRIBUTE UPDATED", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
			for (j=0;j<data->number_attributes;j++)
				XPUSHs(sv_2mortal(newSVpv(data->attribute_names[j], 0)));
		}
		if (reason & CSA_CB_ENTRY_ADDED) {
			CSA_add_entry_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("ENTRY ADDED", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
			XPUSHs(sv_2mortal(newSVCSA_opaque_data(&data->added_entry_id)));
		}
		if (reason & CSA_CB_ENTRY_DELETED) {
			CSA_delete_entry_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("ENTRY DELETED", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
			XPUSHs(sv_2mortal(newSVCSA_opaque_data(&data->deleted_entry_id)));
			XPUSHs(sv_2mortal(newSVCSA_SCOPE(data->scope)));
			XPUSHs(sv_2mortal(newSVISO_date_time(data->date_and_time,0)));
		}
		if (reason & CSA_CB_ENTRY_UPDATED) {
			CSA_update_entry_callback_data * data = call_data;
			XPUSHs(sv_2mortal(newSVpv("ENTRY UPDATED", 0)));
			XPUSHs(sv_2mortal(newSVCSA_calendar_user(data->user)));
			XPUSHs(sv_2mortal(newSVCSA_opaque_data(&data->old_entry_id)));
			XPUSHs(sv_2mortal(newSVCSA_opaque_data(&data->new_entry_id)));
			XPUSHs(sv_2mortal(newSVCSA_SCOPE(data->scope)));
			XPUSHs(sv_2mortal(newSVISO_date_time(data->date_and_time,0)));
		}
	}
	PUTBACK ;
	perl_call_sv(*av_fetch(args, 0, 0), G_DISCARD);
}

typedef struct Calendar__CSA__Session_t {
	CSA_session_handle	session;
	int	shorten;
	int iso_times;
	int connected;
} * Calendar__CSA__Session;

typedef struct Calendar__CSA__Entry_t {
	SV	* session_sv;
	Calendar__CSA__Session	session;
	CSA_entry_handle	entry;
} * Calendar__CSA__Entry;

typedef struct Calendar__CSA__EntryList_t {
	SV	* session_sv;
	Calendar__CSA__Session	session;
	int 	count;
	CSA_entry_handle	*list;
} * Calendar__CSA__EntryList;



SV * newSVCSA_reminder_reference(CSA_reminder_reference * rem, Calendar__CSA__Session parent, SV * parent_sv)
{
        HV * u;
        SV * r;
        if (!rem)
                return newSVsv(&sv_undef);
        u = newHV();
        if (rem->run_time)
                hv_store(u, "run_time", 8, newSVpv(rem->run_time, 0), 0);
        if (rem->snooze_time)
                hv_store(u, "snooze_time", 11, newSVpv(rem->snooze_time, 0), 0);
        hv_store(u, "repeat_count", 12, newSViv(rem->repeat_count), 0);
        if (rem->attribute_name)
                hv_store(u, "attribute_name", 14, newSVpv(rem->attribute_name, 0), 0);
        if (rem->entry) {
        		SV * e = newSVsv(&sv_undef);
        		Calendar__CSA__Entry entry = safe_malloc(sizeof(struct Calendar__CSA__Entry_t));
        		entry->entry = rem->entry;
        		entry->session = parent;
        		entry->session_sv = SvREFCNT_inc(parent_sv);
				sv_setref_pv(e, "Calendar::CSA::Entry", (void*)entry);
                hv_store(u, "entry", 5, e, 0);
        }
        r = newRV((SV*)u);
        SvREFCNT_dec(u);
        return r;
}

char *
constantstr(name, arg)
	char * name;
	int arg;
{
	errno=0;
#ifdef CSA_SUBTYPE_APPOINTMENT
	if(strEQ(name, "SUBTYPE_APPOINTMENT")) return CSA_SUBTYPE_APPOINTMENT;
#endif
#ifdef CSA_SUBTYPE_CLASS
	if(strEQ(name, "SUBTYPE_CLASS")) return CSA_SUBTYPE_CLASS;
#endif
#ifdef CSA_SUBTYPE_HOLIDAY
	if(strEQ(name, "SUBTYPE_HOLIDAY")) return CSA_SUBTYPE_HOLIDAY;
#endif
#ifdef CSA_SUBTYPE_MISCELLANEOUS
	if(strEQ(name, "SUBTYPE_MISCELLANEOUS")) return CSA_SUBTYPE_MISCELLANEOUS;
#endif
#ifdef CSA_SUBTYPE_PHONE_CALL
	if(strEQ(name, "SUBTYPE_PHONE_CALL")) return CSA_SUBTYPE_PHONE_CALL;
#endif
#ifdef CSA_SUBTYPE_SICK_DAY
	if(strEQ(name, "SUBTYPE_SICK_DAY")) return CSA_SUBTYPE_SICK_DAY;
#endif
#ifdef CSA_SUBTYPE_SPECIAL_OCCASION
	if(strEQ(name, "SUBTYPE_SPECIAL_OCCASION")) return CSA_SUBTYPE_SPECIAL_OCCASION;
#endif
#ifdef CSA_SUBTYPE_TRAVEL
	if(strEQ(name, "SUBTYPE_TRAVEL")) return CSA_SUBTYPE_TRAVEL;
#endif
#ifdef CSA_SUBTYPE_VACATION
	if(strEQ(name, "SUBTYPE_VACATION")) return CSA_SUBTYPE_VACATION;
#endif
#ifdef CSA_CAL_ATTR_ACCESS_LIST
	if(strEQ(name, "CAL_ATTR_ACCESS_LIST")) return CSA_CAL_ATTR_ACCESS_LIST;
#endif
#ifdef CSA_CAL_ATTR_CALENDAR_NAME
	if(strEQ(name, "CAL_ATTR_CALENDAR_NAME")) return CSA_CAL_ATTR_CALENDAR_NAME;
#endif
#ifdef CSA_CAL_ATTR_CALENDAR_OWNER
	if(strEQ(name, "CAL_ATTR_CALENDAR_OWNER")) return CSA_CAL_ATTR_CALENDAR_OWNER;
#endif
#ifdef CSA_CAL_ATTR_CALENDAR_SIZE
	if(strEQ(name, "CAL_ATTR_CALENDAR_SIZE")) return CSA_CAL_ATTR_CALENDAR_SIZE;
#endif
#ifdef CSA_CAL_ATTR_CHARACTER_SET
	if(strEQ(name, "CAL_ATTR_CHARACTER_SET")) return CSA_CAL_ATTR_CHARACTER_SET;
#endif
#ifdef CSA_CAL_ATTR_COUNTRY
	if(strEQ(name, "CAL_ATTR_COUNTRY")) return CSA_CAL_ATTR_COUNTRY;
#endif
#ifdef CSA_CAL_ATTR_DATE_CREATED
	if(strEQ(name, "CAL_ATTR_DATE_CREATED")) return CSA_CAL_ATTR_DATE_CREATED;
#endif
#ifdef CSA_CAL_ATTR_LANGUAGE
	if(strEQ(name, "CAL_ATTR_LANGUAGE")) return CSA_CAL_ATTR_LANGUAGE;
#endif
#ifdef CSA_CAL_ATTR_NUMBER_ENTRIES
	if(strEQ(name, "CAL_ATTR_NUMBER_ENTRIES")) return CSA_CAL_ATTR_NUMBER_ENTRIES;
#endif
#ifdef CSA_CAL_ATTR_PRODUCT_IDENTIFIER
	if(strEQ(name, "CAL_ATTR_PRODUCT_IDENTIFIER")) return CSA_CAL_ATTR_PRODUCT_IDENTIFIER;
#endif
#ifdef CSA_CAL_ATTR_TIME_ZONE
	if(strEQ(name, "CAL_ATTR_TIME_ZONE")) return CSA_CAL_ATTR_TIME_ZONE;
#endif
#ifdef CSA_CAL_ATTR_VERSION
	if(strEQ(name, "CAL_ATTR_VERSION")) return CSA_CAL_ATTR_VERSION;
#endif
#ifdef CSA_CAL_ATTR_WORK_SCHEDULE
	if(strEQ(name, "CAL_ATTR_WORK_SCHEDULE")) return CSA_CAL_ATTR_WORK_SCHEDULE;
#endif
#ifdef CSA_ENTRY_ATTR_ATTENDEE_LIST
	if(strEQ(name, "ENTRY_ATTR_ATTENDEE_LIST")) return CSA_ENTRY_ATTR_ATTENDEE_LIST;
#endif
#ifdef CSA_ENTRY_ATTR_AUDIO_REMINDER
	if(strEQ(name, "ENTRY_ATTR_AUDIO_REMINDER")) return CSA_ENTRY_ATTR_AUDIO_REMINDER;
#endif
#ifdef CSA_ENTRY_ATTR_CLASSIFICATION
	if(strEQ(name, "ENTRY_ATTR_CLASSIFICATION")) return CSA_ENTRY_ATTR_CLASSIFICATION;
#endif
#ifdef CSA_ENTRY_ATTR_DATE_COMPLETED
	if(strEQ(name, "ENTRY_ATTR_DATE_COMPLETED")) return CSA_ENTRY_ATTR_DATE_COMPLETED;
#endif
#ifdef CSA_ENTRY_ATTR_DATE_CREATED
	if(strEQ(name, "ENTRY_ATTR_DATE_CREATED")) return CSA_ENTRY_ATTR_DATE_CREATED;
#endif
#ifdef CSA_ENTRY_ATTR_DESCRIPTION
	if(strEQ(name, "ENTRY_ATTR_DESCRIPTION")) return CSA_ENTRY_ATTR_DESCRIPTION;
#endif
#ifdef CSA_ENTRY_ATTR_DUE_DATE
	if(strEQ(name, "ENTRY_ATTR_DUE_DATE")) return CSA_ENTRY_ATTR_DUE_DATE;
#endif
#ifdef CSA_ENTRY_ATTR_END_DATE
	if(strEQ(name, "ENTRY_ATTR_END_DATE")) return CSA_ENTRY_ATTR_END_DATE;
#endif
#ifdef CSA_ENTRY_ATTR_EXCEPTION_DATES
	if(strEQ(name, "ENTRY_ATTR_EXCEPTION_DATES")) return CSA_ENTRY_ATTR_EXCEPTION_DATES;
#endif
#ifdef CSA_ENTRY_ATTR_EXCEPTION_RULE
	if(strEQ(name, "ENTRY_ATTR_EXCEPTION_RULE")) return CSA_ENTRY_ATTR_EXCEPTION_RULE;
#endif
#ifdef CSA_ENTRY_ATTR_FLASHING_REMINDER
	if(strEQ(name, "ENTRY_ATTR_FLASHING_REMINDER")) return CSA_ENTRY_ATTR_FLASHING_REMINDER;
#endif
#ifdef CSA_ENTRY_ATTR_LAST_UPDATE
	if(strEQ(name, "ENTRY_ATTR_LAST_UPDATE")) return CSA_ENTRY_ATTR_LAST_UPDATE;
#endif
#ifdef CSA_ENTRY_ATTR_MAIL_REMINDER
	if(strEQ(name, "ENTRY_ATTR_MAIL_REMINDER")) return CSA_ENTRY_ATTR_MAIL_REMINDER;
#endif
#ifdef CSA_ENTRY_ATTR_NUMBER_RECURRENCES
	if(strEQ(name, "ENTRY_ATTR_NUMBER_RECURRENCES")) return CSA_ENTRY_ATTR_NUMBER_RECURRENCES;
#endif
#ifdef CSA_ENTRY_ATTR_ORGANIZER
	if(strEQ(name, "ENTRY_ATTR_ORGANIZER")) return CSA_ENTRY_ATTR_ORGANIZER;
#endif
#ifdef CSA_ENTRY_ATTR_POPUP_REMINDER
	if(strEQ(name, "ENTRY_ATTR_POPUP_REMINDER")) return CSA_ENTRY_ATTR_POPUP_REMINDER;
#endif
#ifdef CSA_ENTRY_ATTR_PRIORITY
	if(strEQ(name, "ENTRY_ATTR_PRIORITY")) return CSA_ENTRY_ATTR_PRIORITY;
#endif
#ifdef CSA_ENTRY_ATTR_RECURRENCE_RULE
	if(strEQ(name, "ENTRY_ATTR_RECURRENCE_RULE")) return CSA_ENTRY_ATTR_RECURRENCE_RULE;
#endif
#ifdef CSA_ENTRY_ATTR_RECURRING_DATES
	if(strEQ(name, "ENTRY_ATTR_RECURRING_DATES")) return CSA_ENTRY_ATTR_RECURRING_DATES;
#endif
#ifdef CSA_ENTRY_ATTR_REFERENCE_IDENTIFIER
	if(strEQ(name, "ENTRY_ATTR_REFERENCE_IDENTIFIER")) return CSA_ENTRY_ATTR_REFERENCE_IDENTIFIER;
#endif
#ifdef CSA_ENTRY_ATTR_SEQUENCE_NUMBER
	if(strEQ(name, "ENTRY_ATTR_SEQUENCE_NUMBER")) return CSA_ENTRY_ATTR_SEQUENCE_NUMBER;
#endif
#ifdef CSA_ENTRY_ATTR_SPONSOR
	if(strEQ(name, "ENTRY_ATTR_SPONSOR")) return CSA_ENTRY_ATTR_SPONSOR;
#endif
#ifdef CSA_ENTRY_ATTR_START_DATE
	if(strEQ(name, "ENTRY_ATTR_START_DATE")) return CSA_ENTRY_ATTR_START_DATE;
#endif
#ifdef CSA_ENTRY_ATTR_STATUS
	if(strEQ(name, "ENTRY_ATTR_STATUS")) return CSA_ENTRY_ATTR_STATUS;
#endif
#ifdef CSA_ENTRY_ATTR_SUBTYPE
	if(strEQ(name, "ENTRY_ATTR_SUBTYPE")) return CSA_ENTRY_ATTR_SUBTYPE;
#endif
#ifdef CSA_ENTRY_ATTR_SUMMARY
	if(strEQ(name, "ENTRY_ATTR_SUMMARY")) return CSA_ENTRY_ATTR_SUMMARY;
#endif
#ifdef CSA_ENTRY_ATTR_TIME_TRANSPARENCY
	if(strEQ(name, "ENTRY_ATTR_TIME_TRANSPARENCY")) return CSA_ENTRY_ATTR_TIME_TRANSPARENCY;
#endif
#ifdef CSA_ENTRY_ATTR_TYPE
	if(strEQ(name, "ENTRY_ATTR_TYPE")) return CSA_ENTRY_ATTR_TYPE;
#endif
#ifdef CSA_SUBTYPE_MEETING
	if(strEQ(name, "SUBTYPE_MEETING")) return CSA_SUBTYPE_MEETING;
#endif
#ifdef CSA_X_DT_CAL_ATTR_CAL_DELIMITER
	if(strEQ(name, "X_DT_CAL_ATTR_CAL_DELIMITER")) return CSA_X_DT_CAL_ATTR_CAL_DELIMITER;
#endif
#ifdef CSA_X_DT_CAL_ATTR_DATA_VERSION
	if(strEQ(name, "X_DT_CAL_ATTR_DATA_VERSION")) return CSA_X_DT_CAL_ATTR_DATA_VERSION;
#endif
#ifdef CSA_X_DT_CAL_ATTR_SERVER_VERSION
	if(strEQ(name, "X_DT_CAL_ATTR_SERVER_VERSION")) return CSA_X_DT_CAL_ATTR_SERVER_VERSION;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_ENTRY_DELIMITER
	if(strEQ(name, "X_DT_ENTRY_ATTR_ENTRY_DELIMITER")) return CSA_X_DT_ENTRY_ATTR_ENTRY_DELIMITER;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_INTERVAL
	if(strEQ(name, "X_DT_ENTRY_ATTR_REPEAT_INTERVAL")) return CSA_X_DT_ENTRY_ATTR_REPEAT_INTERVAL;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM
	if(strEQ(name, "X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM")) return CSA_X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_TIMES
	if(strEQ(name, "X_DT_ENTRY_ATTR_REPEAT_TIMES")) return CSA_X_DT_ENTRY_ATTR_REPEAT_TIMES;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_TYPE
	if(strEQ(name, "X_DT_ENTRY_ATTR_REPEAT_TYPE")) return CSA_X_DT_ENTRY_ATTR_REPEAT_TYPE;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_SEQUENCE_END_DATE
	if(strEQ(name, "X_DT_ENTRY_ATTR_SEQUENCE_END_DATE")) return CSA_X_DT_ENTRY_ATTR_SEQUENCE_END_DATE;
#endif
#ifdef CSA_X_DT_ENTRY_ATTR_SHOWTIME
	if(strEQ(name, "X_DT_ENTRY_ATTR_SHOWTIME")) return CSA_X_DT_ENTRY_ATTR_SHOWTIME;
#endif
	errno = EINVAL;
	return 0;
}

static long
constantint(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "CSA_CLASS_CONFIDENTIAL"))
#ifdef CSA_CLASS_CONFIDENTIAL
	    return CSA_CLASS_CONFIDENTIAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_CLASS_PRIVATE"))
#ifdef CSA_CLASS_PRIVATE
	    return CSA_CLASS_PRIVATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_CLASS_PUBLIC"))
#ifdef CSA_CLASS_PUBLIC
	    return CSA_CLASS_PUBLIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_ERROR_IMPL_MASK"))
#ifdef CSA_ERROR_IMPL_MASK
	    return CSA_ERROR_IMPL_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_ERROR_RSV_MASK"))
#ifdef CSA_ERROR_RSV_MASK
	    return CSA_ERROR_RSV_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_EXT_LAST_ELEMENT"))
#ifdef CSA_EXT_LAST_ELEMENT
	    return CSA_EXT_LAST_ELEMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_EXT_OUTPUT"))
#ifdef CSA_EXT_OUTPUT
	    return CSA_EXT_OUTPUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_EXT_REQUIRED"))
#ifdef CSA_EXT_REQUIRED
	    return CSA_EXT_REQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_ORGANIZER_RIGHTS"))
#ifdef CSA_ORGANIZER_RIGHTS
	    return CSA_ORGANIZER_RIGHTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_OWNER_RIGHTS"))
#ifdef CSA_OWNER_RIGHTS
	    return CSA_OWNER_RIGHTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_SPONSOR_RIGHTS"))
#ifdef CSA_SPONSOR_RIGHTS
	    return CSA_SPONSOR_RIGHTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_TYPE_EVENT"))
#ifdef CSA_TYPE_EVENT
	    return CSA_TYPE_EVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_TYPE_MEMO"))
#ifdef CSA_TYPE_MEMO
	    return CSA_TYPE_MEMO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_TYPE_TODO"))
#ifdef CSA_TYPE_TODO
	    return CSA_TYPE_TODO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_XS_BLT"))
#ifdef CSA_XS_BLT
	    return CSA_XS_BLT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_XS_COM"))
#ifdef CSA_XS_COM
	    return CSA_XS_COM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_XS_DT"))
#ifdef CSA_XS_DT
	    return CSA_XS_DT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_ADD_DEFINE_ENTRY_UI"))
#ifdef CSA_X_ADD_DEFINE_ENTRY_UI
	    return CSA_X_ADD_DEFINE_ENTRY_UI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_DATA_EXT_SUPPORTED"))
#ifdef CSA_X_COM_DATA_EXT_SUPPORTED
	    return CSA_X_COM_DATA_EXT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_FUNC_EXT_SUPPORTED"))
#ifdef CSA_X_COM_FUNC_EXT_SUPPORTED
	    return CSA_X_COM_FUNC_EXT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_NOT_SUPPORTED"))
#ifdef CSA_X_COM_NOT_SUPPORTED
	    return CSA_X_COM_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_SUPPORTED"))
#ifdef CSA_X_COM_SUPPORTED
	    return CSA_X_COM_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_SUPPORT_EXT"))
#ifdef CSA_X_COM_SUPPORT_EXT
	    return CSA_X_COM_SUPPORT_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_COM_SUP_EXCLUDE"))
#ifdef CSA_X_COM_SUP_EXCLUDE
	    return CSA_X_COM_SUP_EXCLUDE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_BROWSE_ACCESS"))
#ifdef CSA_X_DT_BROWSE_ACCESS
	    return CSA_X_DT_BROWSE_ACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_CAL_ATTR_CAL_DELIMITER_I"))
#ifdef CSA_X_DT_CAL_ATTR_CAL_DELIMITER_I
	    return CSA_X_DT_CAL_ATTR_CAL_DELIMITER_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_CAL_ATTR_DATA_VERSION_I"))
#ifdef CSA_X_DT_CAL_ATTR_DATA_VERSION_I
	    return CSA_X_DT_CAL_ATTR_DATA_VERSION_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_CAL_ATTR_SERVER_VERSION_I"))
#ifdef CSA_X_DT_CAL_ATTR_SERVER_VERSION_I
	    return CSA_X_DT_CAL_ATTR_SERVER_VERSION_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_DELETE_ACCESS"))
#ifdef CSA_X_DT_DELETE_ACCESS
	    return CSA_X_DT_DELETE_ACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_DT_REPEAT_FOREVER"))
#ifdef CSA_X_DT_DT_REPEAT_FOREVER
	    return CSA_X_DT_DT_REPEAT_FOREVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_CHARACTER_SET_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_CHARACTER_SET_I
	    return CSA_X_DT_ENTRY_ATTR_CHARACTER_SET_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_ENTRY_DELIMITER_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_ENTRY_DELIMITER_I
	    return CSA_X_DT_ENTRY_ATTR_ENTRY_DELIMITER_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_REPEAT_INTERVAL_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_INTERVAL_I
	    return CSA_X_DT_ENTRY_ATTR_REPEAT_INTERVAL_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM_I
	    return CSA_X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_REPEAT_TIMES_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_TIMES_I
	    return CSA_X_DT_ENTRY_ATTR_REPEAT_TIMES_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_REPEAT_TYPE_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_REPEAT_TYPE_I
	    return CSA_X_DT_ENTRY_ATTR_REPEAT_TYPE_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_SEQUENCE_END_DATE_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_SEQUENCE_END_DATE_I
	    return CSA_X_DT_ENTRY_ATTR_SEQUENCE_END_DATE_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_ENTRY_ATTR_SHOWTIME_I"))
#ifdef CSA_X_DT_ENTRY_ATTR_SHOWTIME_I
	    return CSA_X_DT_ENTRY_ATTR_SHOWTIME_I;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_BACKING_STORE_PROBLEM"))
#ifdef CSA_X_DT_E_BACKING_STORE_PROBLEM
	    return CSA_X_DT_E_BACKING_STORE_PROBLEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_ENTRY_NOT_FOUND"))
#ifdef CSA_X_DT_E_ENTRY_NOT_FOUND
	    return CSA_X_DT_E_ENTRY_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_INVALID_SERVER_LOCATION"))
#ifdef CSA_X_DT_E_INVALID_SERVER_LOCATION
	    return CSA_X_DT_E_INVALID_SERVER_LOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_MT_UNSAFE"))
#ifdef CSA_X_DT_E_MT_UNSAFE
	    return CSA_X_DT_E_MT_UNSAFE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_SERVER_TIMEOUT"))
#ifdef CSA_X_DT_E_SERVER_TIMEOUT
	    return CSA_X_DT_E_SERVER_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_E_SERVICE_NOT_REGISTERED"))
#ifdef CSA_X_DT_E_SERVICE_NOT_REGISTERED
	    return CSA_X_DT_E_SERVICE_NOT_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_GET_CAL_CHARSET_EXT"))
#ifdef CSA_X_DT_GET_CAL_CHARSET_EXT
	    return CSA_X_DT_GET_CAL_CHARSET_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_GET_DATA_VERSION_EXT"))
#ifdef CSA_X_DT_GET_DATA_VERSION_EXT
	    return CSA_X_DT_GET_DATA_VERSION_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_GET_SERVER_VERSION_EXT"))
#ifdef CSA_X_DT_GET_SERVER_VERSION_EXT
	    return CSA_X_DT_GET_SERVER_VERSION_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_GET_USER_ACCESS_EXT"))
#ifdef CSA_X_DT_GET_USER_ACCESS_EXT
	    return CSA_X_DT_GET_USER_ACCESS_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_INSERT_ACCESS"))
#ifdef CSA_X_DT_INSERT_ACCESS
	    return CSA_X_DT_INSERT_ACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_BIWEEKLY"))
#ifdef CSA_X_DT_REPEAT_BIWEEKLY
	    return CSA_X_DT_REPEAT_BIWEEKLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_DAILY"))
#ifdef CSA_X_DT_REPEAT_DAILY
	    return CSA_X_DT_REPEAT_DAILY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_EVERY_NDAY"))
#ifdef CSA_X_DT_REPEAT_EVERY_NDAY
	    return CSA_X_DT_REPEAT_EVERY_NDAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_EVERY_NMONTH"))
#ifdef CSA_X_DT_REPEAT_EVERY_NMONTH
	    return CSA_X_DT_REPEAT_EVERY_NMONTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_EVERY_NWEEK"))
#ifdef CSA_X_DT_REPEAT_EVERY_NWEEK
	    return CSA_X_DT_REPEAT_EVERY_NWEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_MONTHLY_BY_DATE"))
#ifdef CSA_X_DT_REPEAT_MONTHLY_BY_DATE
	    return CSA_X_DT_REPEAT_MONTHLY_BY_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_MONTHLY_BY_WEEKDAY"))
#ifdef CSA_X_DT_REPEAT_MONTHLY_BY_WEEKDAY
	    return CSA_X_DT_REPEAT_MONTHLY_BY_WEEKDAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_MONWEDFRI"))
#ifdef CSA_X_DT_REPEAT_MONWEDFRI
	    return CSA_X_DT_REPEAT_MONWEDFRI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_MON_TO_FRI"))
#ifdef CSA_X_DT_REPEAT_MON_TO_FRI
	    return CSA_X_DT_REPEAT_MON_TO_FRI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_ONETIME"))
#ifdef CSA_X_DT_REPEAT_ONETIME
	    return CSA_X_DT_REPEAT_ONETIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_OTHER"))
#ifdef CSA_X_DT_REPEAT_OTHER
	    return CSA_X_DT_REPEAT_OTHER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_OTHER_MONTHLY"))
#ifdef CSA_X_DT_REPEAT_OTHER_MONTHLY
	    return CSA_X_DT_REPEAT_OTHER_MONTHLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_OTHER_WEEKLY"))
#ifdef CSA_X_DT_REPEAT_OTHER_WEEKLY
	    return CSA_X_DT_REPEAT_OTHER_WEEKLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_OTHER_YEARLY"))
#ifdef CSA_X_DT_REPEAT_OTHER_YEARLY
	    return CSA_X_DT_REPEAT_OTHER_YEARLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_TUETHUR"))
#ifdef CSA_X_DT_REPEAT_TUETHUR
	    return CSA_X_DT_REPEAT_TUETHUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_WEEKDAYCOMBO"))
#ifdef CSA_X_DT_REPEAT_WEEKDAYCOMBO
	    return CSA_X_DT_REPEAT_WEEKDAYCOMBO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_WEEKLY"))
#ifdef CSA_X_DT_REPEAT_WEEKLY
	    return CSA_X_DT_REPEAT_WEEKLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_REPEAT_YEARLY"))
#ifdef CSA_X_DT_REPEAT_YEARLY
	    return CSA_X_DT_REPEAT_YEARLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_STATUS_ACTIVE"))
#ifdef CSA_X_DT_STATUS_ACTIVE
	    return CSA_X_DT_STATUS_ACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_STATUS_ADD_PENDING"))
#ifdef CSA_X_DT_STATUS_ADD_PENDING
	    return CSA_X_DT_STATUS_ADD_PENDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_STATUS_CANCELLED"))
#ifdef CSA_X_DT_STATUS_CANCELLED
	    return CSA_X_DT_STATUS_CANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_STATUS_COMMITTED"))
#ifdef CSA_X_DT_STATUS_COMMITTED
	    return CSA_X_DT_STATUS_COMMITTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_STATUS_DELETE_PENDING"))
#ifdef CSA_X_DT_STATUS_DELETE_PENDING
	    return CSA_X_DT_STATUS_DELETE_PENDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_DT_TYPE_OTHER"))
#ifdef CSA_X_DT_TYPE_OTHER
	    return CSA_X_DT_TYPE_OTHER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_ERROR_UI_ALLOWED"))
#ifdef CSA_X_ERROR_UI_ALLOWED
	    return CSA_X_ERROR_UI_ALLOWED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_LOGON_UI_ALLOWED"))
#ifdef CSA_X_LOGON_UI_ALLOWED
	    return CSA_X_LOGON_UI_ALLOWED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_LOOKUP_ADDRESSING_UI"))
#ifdef CSA_X_LOOKUP_ADDRESSING_UI
	    return CSA_X_LOOKUP_ADDRESSING_UI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_LOOKUP_DETAILS_UI"))
#ifdef CSA_X_LOOKUP_DETAILS_UI
	    return CSA_X_LOOKUP_DETAILS_UI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_LOOKUP_RESOLVE_UI"))
#ifdef CSA_X_LOOKUP_RESOLVE_UI
	    return CSA_X_LOOKUP_RESOLVE_UI;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_UI_ID_EXT"))
#ifdef CSA_X_UI_ID_EXT
	    return CSA_X_UI_ID_EXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CSA_X_XT_APP_CONTEXT_EXT"))
#ifdef CSA_X_XT_APP_CONTEXT_EXT
	    return CSA_X_XT_APP_CONTEXT_EXT;
#else
	    goto not_there;
#endif
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


static struct opts configs[] = {
	{CSA_CONFIG_CHARACTER_SET, "CHARACTER SET"},
	{CSA_CONFIG_LINE_TERM, "LINE TERM"},
	{CSA_CONFIG_DEFAULT_SERVICE, "DEFAULT SERVICE"},
	{CSA_CONFIG_DEFAULT_USER, "DEFAULT USER"},
	{CSA_CONFIG_REQ_PASSWORD, "REQ PASSWORD"},
	{CSA_CONFIG_REQ_SERVICE, "REQ SERVICE"},
	{CSA_CONFIG_REQ_USER, "REQ USER"},
	{CSA_CONFIG_UI_AVAIL, "UI AVAIL"},
	{CSA_CONFIG_VER_IMPLEM, "VER IMPLEM"},
	{CSA_CONFIG_VER_SPEC, "VER SPEC"},
	{0,0}
};


MODULE = Calendar::CSA		PACKAGE = Calendar::CSA

SV *
constant(name, arg)
	char *	name
	int	arg
	CODE:
	{
		char * s;
		s = constantstr(name, arg);
		if (s)
			RETVAL = newSVpv(s, 0);
		else {
			RETVAL = newSViv(constantint(name,arg));
		}
	}
	OUTPUT:
	RETVAL


void
add_calendar(user, ...)
	SV *	user
	CODE:
	{
		int i, j, err;
		CSA_calendar_user u;
		CSA_attribute * csa_attrs;
		
		if ((items-1)%2)
			croak("attributes must be paired names and values");

		SvCSA_calendar_user(user, &u);	
		
		if (items>1) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-1)/2), 1);
			for(j=0,i=1;i<items;j++,i+=2) {
				csa_attrs[j].name = lengthen(SvPV(ST(i),na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
			}
		} else
			csa_attrs = 0;

		err = csa_add_calendar((CSA_session_handle)NULL, &u, (items-1)/2, csa_attrs, NULL);
		
		if (csa_attrs)
			free(csa_attrs);
		
		if (err)
			CsaCroak("add_calendar", err);
	}

Calendar::CSA::Session
logon(service=0, user=0, password=0, charset=0)
	char *	service
	SV *	user
	char *	password
	char *	charset
	CODE:
	{
		Calendar__CSA__Session session = safe_calloc(sizeof(struct Calendar__CSA__Session_t),1);
		CSA_return_code ret;
		CSA_calendar_user cu;
	
		if (service && !strlen(service))
			service = 0;
		
		ret =
		csa_logon(service,
			  SvCSA_calendar_user(user, &cu),
			  password,
			  charset, 
			  "-//XAPIA/CSA/VERSION1/NONSGML CSA Version 1//EN",
			  &session->session,
			  NULL);
	
		session->iso_times = 1;

		if (ret != CSA_SUCCESS)
		{
			free(session);
			CsaCroak("logon", ret);
		}
		
		session->connected = 1;
		RETVAL = session;
	}
	OUTPUT:
	RETVAL

void
list_calendars(service=0)
	char *	service
	PPCODE:
	{
		CSA_calendar_user *result;
		CSA_uint32 number;
		int err,i;
		SV ** s;
		HV * u;
		
		number = 0;
		
		err = csa_list_calendars(service, &number, &result, NULL);

		if (err)
			CsaCroak("list_calendars", err);
		
		if (result) {
			for(i=0;i<number;i++) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVpv(result[i].calendar_address,0)));
			}
			csa_free(result);
		}
	}

int
accept_numeric_enumerations(set=&sv_undef)
	SV *	set
	CODE:
	{
		RETVAL = Csa_accept_numeric_enumerations;
		if (set && SvOK(set))
			Csa_accept_numeric_enumerations = SvTRUE(set);
	}
	OUTPUT:
	RETVAL

int
generate_numeric_enumerations(set=&sv_undef)
	SV *	set
	CODE:
	{
		RETVAL = Csa_generate_numeric_enumerations;
		if (set && SvOK(set))
			Csa_generate_numeric_enumerations = SvTRUE(set);
	}
	OUTPUT:
	RETVAL


MODULE = Calendar::CSA		PACKAGE = Calendar::CSA::Session

void
DESTROY(session)	
	Calendar::CSA::Session	session
	CODE:
	if (session->connected)
		csa_logoff(session->session, NULL);
	free(session);

void
logoff(session)
	Calendar::CSA::Session	session
	CODE:
	{
		int error = csa_logoff(session->session, NULL);
		if (error != CSA_SUCCESS)
			CsaCroak("logoff", error);
		session->connected = 0;
	}
	OUTPUT:

int
short_entry_names(session, set=&sv_undef)
	Calendar::CSA::Session	session
	SV *	set
	CODE:
	{
		RETVAL = session->shorten;
		if (set && SvOK(set))
			session->shorten = SvTRUE(set);
	}
	OUTPUT:
	RETVAL

int
unix_times(session, set=&sv_undef)
	Calendar::CSA::Session	session
	SV *	set
	CODE:
	{
		RETVAL = !session->iso_times;
		if (set && SvOK(set))
			session->iso_times = !SvTRUE(set);
	}
	OUTPUT:
	RETVAL

void
look_up(session, users, flags=0)
	Calendar::CSA::Session	session
	SV *	users
	SV *	flags
	PPCODE:
	{
		CSA_calendar_user user, *result;
		CSA_uint32 number;
		int err,i;

		SvCSA_calendar_user(users, &user);

		number = 1;
		
		err = csa_look_up(session->session, &user, SvCSA_LOOKUP(flags), &number, &result, NULL);

		if (err)
			CsaCroak("look_up", err);
			
		for(i=0;i<number;i++) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVCSA_calendar_user(result+i)));
		}
		
		csa_free(result);
	}

void
query_configuration(session, item)
	Calendar::CSA::Session	session
	SV *	item
	PPCODE:
	{
		CSA_calendar_user user, *result;
		CSA_uint32 number;
		int err=0,i;
		i = SvOpt(item, "configuration item", configs);
		switch (i) {
		case CSA_CONFIG_CHARACTER_SET:
		  {
			char ** data;
			err = csa_query_configuration(session->session, CSA_CONFIG_CHARACTER_SET, (void**)&data, NULL);
			if (err) goto done;
			csa_free(data);
			while (data && *data) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVpv(*data, 0)));
				data++;
			}
			break;
		  }
		case CSA_CONFIG_LINE_TERM:
		  {
			CSA_enum data;
			err = csa_query_configuration(session->session, i, (void**)&data, NULL);
			if (err) goto done;
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVCSA_LINE_TERM(data)));
			break;
		  }
		case CSA_CONFIG_DEFAULT_SERVICE:
		case CSA_CONFIG_DEFAULT_USER:
		case CSA_CONFIG_VER_IMPLEM:
		case CSA_CONFIG_VER_SPEC:
		  {
			CSA_string data;
			err = csa_query_configuration(session->session, i, (void**)&data, NULL);
			if (err) goto done;
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(data ? newSVpv(data,0) : newSVsv(&sv_undef)));
			csa_free(data);
			break;
		  }
		case CSA_CONFIG_REQ_PASSWORD:
		case CSA_CONFIG_REQ_SERVICE:
		case CSA_CONFIG_REQ_USER:
		  {
			CSA_enum data;
			err = csa_query_configuration(session->session, i, (void**)&data, NULL);
			if (err) goto done;
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVCSA_REQUIRED(data)));
			break;
		  }
		case CSA_CONFIG_UI_AVAIL:
		  {
			CSA_boolean data;
			err = csa_query_configuration(session->session, i, (void**)&data, NULL);
			if (err) goto done;
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSViv(data)));
			break;
		  }
		default:
			croak("unhandled configuration query");
		}

    done:
		if (err)
			CsaCroak("query_configuration", err);
	}

void
list_calendar_attributes(session)
	Calendar::CSA::Session	session
	PPCODE:
	{
		CSA_attribute_reference *result;
		CSA_uint32 number;
		int err,i;
		SV ** s;
		HV * u;
		
		number = 0;
		
		err = csa_list_calendar_attributes(session->session, &number, &result, NULL);

		if (err)
			CsaCroak("list_calendar_attributes", err);
		
		if (result) {
			for(i=0;i<number;i++) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVpv(shorten(result[i], session->shorten),0)));
			}
			csa_free(result);
		}
	}

void
read_calendar_attributes(session, ...)
	Calendar::CSA::Session	session
	PPCODE:
	{
		int i, j, err;
		int flags=0;
		CSA_uint32 count;
		CSA_attribute * result;
		CSA_attribute_reference * csa_names;
		if (items>1) {
			csa_names = safe_calloc(sizeof(CSA_attribute_reference)*(items-1),1);
			for(i=1;i<items;i++)
				csa_names[i-1] = lengthen(SvPV(ST(i), na));
		} else {
			csa_names = 0;
		}

		err = csa_read_calendar_attributes(session->session, items-1, csa_names, &count, &result, NULL);
		
		if (csa_names)
			free(csa_names);
		
		if (err)
			CsaCroak("read_calendar_attributes", err);
		
		if (result) {
			for(i=0;i<count;i++) {
				EXTEND(sp, 2);
				PUSHs(sv_2mortal(newSVpv(shorten(result[i].name,session->shorten), 0)));
				PUSHs(sv_2mortal(newSVCSA_attribute_value(result[i].value, session->shorten, session->iso_times)));
			}
			csa_free(result);
		}
	}

void
read_next_reminder(session, given_time, ...)
	Calendar::CSA::Session	session
	SV *	given_time
	PPCODE:
	{
		int i, j, err;
		int flags=0;
		CSA_uint32 count;
		CSA_reminder_reference * result;
		CSA_attribute_reference * csa_names;

		if (items>1) {
			csa_names = safe_calloc(sizeof(CSA_attribute_reference)*(items-1),1);
			for(i=1;i<items;i++)
				csa_names[i-1] = SvPV(ST(i), na);
		} else {
			csa_names = 0;
		}

		err = csa_read_next_reminder(session->session, items-1, csa_names, SvISO_date_time(given_time,0), &count, &result, NULL);
		
		if (csa_names)
			free(csa_names);
		
		if (err)
			CsaCroak("read_next_reminder", err);
		
		if (result) {
			for(i=0;i<count;i++) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVCSA_reminder_reference(result+i, session, ST(0))));
			}
			csa_free(result);
		}
	}

void
update_calendar_attributes(session, ...)
	Calendar::CSA::Session	session
	CODE:
	{
		int i,j, err;
		CSA_attribute * csa_attrs;
		if ((items-1)%2)
			croak("attributes must be paired names and values");
		if (items>1) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-1)/2), 1);
			for(j=0,i=1;i<items;j++,i+=2) {
				csa_attrs[j].name = lengthen(SvPV(ST(i),na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
			}
		} else
			csa_attrs = 0;

		err = csa_update_calendar_attributes(session->session, items-1, csa_attrs, NULL);
		
		if (csa_attrs)
			free(csa_attrs);
		
		if (err)
			CsaCroak("update_calendar_attributes", err);
	}

void
add_calendar(session, user, ...)
	Calendar::CSA::Session	session
	SV *	user
	CODE:
	{
		int i, j, err;
		CSA_calendar_user u;
		CSA_attribute * csa_attrs;
		
		if ((items-2)%2)
			croak("attributes must be paired names and values");
		
		SvCSA_calendar_user(user, &u);	
		
		if (items>2) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-2)/2), 1);
			for(j=0,i=2;i<items;j++,i+=2) {
				csa_attrs[j].name = lengthen(SvPV(ST(i),na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
			}
		} else
			csa_attrs = 0;

		err = csa_add_calendar(session->session, &u, (items-2)/2, csa_attrs, NULL);
		
		if (csa_attrs)
			free(csa_attrs);
		
		if (err)
			CsaCroak("add_calendar", err);
	}

void
free_time_search(session, range, duration, calendar,...)
	Calendar::CSA::Session	session
	SV *	range
	SV *	duration
	SV *	calendar
	PPCODE:
	{
		int i, j, err;
		CSA_uint32 count;
		CSA_free_time * result;
		CSA_calendar_user * csa_users;
		if (items>3) {
			csa_users = safe_malloc(sizeof(CSA_calendar_user)*(items-3));
			for(i=3;i<items;i++)
				SvCSA_calendar_user(ST(i), &csa_users[i-3]);
		} else
			csa_users = 0;
			
		err = csa_free_time_search(session->session, SvISO_date_time_range(range,0), SvISO_time_duration(duration,0), items-3, csa_users, &result, NULL);
		
		if (csa_users)
			free(csa_users);
		
		if (err)
			CsaCroak("free_time_search", err);
		
		if (result) {
			for(i=0;i<result->number_free_time_data;i++) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVISO_date_time(result->free_time_data[i], 0)));
			}
			csa_free(result);
		}
	}


void
delete_calendar(session)
	Calendar::CSA::Session	session
	CODE:
	{
		int err = csa_delete_calendar(session->session, NULL);
		if (err)
			CsaCroak("delete_calendar", err);
	}


int
register_callback(session, mode, callback, ...)
	Calendar::CSA::Session	session
	SV *	mode
	SV *	callback
	CODE:
	{
		int i;
		int flags=0;
		AV * args;
		if (SvROK(mode) && (SvTYPE(SvRV(mode)) == SVt_PVAV)) {
			args = (AV*)SvRV(mode);
			for (i=0;i<=av_len(args);i++)
				flags |= SvCSA_callback_mode(*av_fetch(args, i, 0));
		} else {
			flags = SvCSA_callback_mode(mode);
		}

		i = csa_register_callback(session->session, flags, callback_handler, (void*)(max_callback+1), NULL);
		if (i)
			CsaCroak("register_callback", i);
		max_callback++;
#ifdef CSA_DEBUG
		printf("Registered callback %d with action %d\n", max_callback, flags);
#endif
		args = newAV();
		for(i=2;i<items;i++)
			av_push(args, newSVsv(ST(i)));
		av_store(callbacks, max_callback, newRV((SV*)args));
		SvREFCNT_dec(args);
		av_store(callback_mode, max_callback, newSViv(flags));
		RETVAL = max_callback;
	}
	OUTPUT:
	RETVAL

void
call_callbacks(session, mode, ...)
	Calendar::CSA::Session	session
	SV *	mode
	CODE:
	{
		int i,j;
		int flags=0;
		AV * args;
		for(j=1;j<items;j++)
			if (SvROK(mode) && (SvTYPE(SvRV(mode)) == SVt_PVAV)) {
				args = (AV*)SvRV(mode);
				for (i=0;i<=av_len(args);i++)
					flags |= SvCSA_callback_mode(*av_fetch(args, i, 0));
			} else {
				flags |= SvCSA_callback_mode(mode);
			}
		i = csa_call_callbacks(session->session, flags, NULL);
		if (i)
			CsaCroak("call_callbacks", i);
	}

void
unregister_callback(session, tag)
	Calendar::CSA::Session	session
	int	tag
	CODE:
	{
		SV ** s = av_fetch(callback_mode, tag, 0);
		if (*s) {
			int flags = SvIV(*s);
			int i;
			i = csa_unregister_callback(session->session, flags, callback_handler, (void*)(tag), NULL);
			if (i)
				CsaCroak("unregister_callback", i);
			av_store(callbacks, tag, newSVsv(&sv_undef));
			av_store(callback_mode, tag, newSVsv(&sv_undef));
		}
	}

void
x_process_updates(session)
	Calendar::CSA::Session	session
	CODE:
	/*csa_x_process_updates(session->session);*/

Calendar::CSA::Entry
add_entry(session, ...)
	Calendar::CSA::Session	session
	CODE:
	{
		int i, j = 0, err;
		CSA_uint32 count;
		CSA_attribute * result;
		CSA_entry_handle new_entry;
		CSA_attribute * csa_attrs;
		Calendar__CSA__Entry entry;

		if ((items-1)%2)
			croak("attributes must be paired names and values");
		if (items>1) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-1)/2), 1);

			for(j=0,i=1;i<items;j++,i+=2) {
				csa_attrs[j].name = lengthen(SvPV(ST(i),na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
			}
		} else
			csa_attrs = 0;

		/*for(i=0;i<j;i++) {
			char c;
			fprintf(stderr, "attribute %d name is %s\n", i, csa_attrs[i].name);
			fprintf(stderr, "attribute %d value is %d\n", i, csa_attrs[i].value);
			c = *(char*)csa_attrs[i].value;
		}*/

		err = csa_add_entry(session->session, j, csa_attrs, &new_entry, NULL);
		
		if (csa_attrs)
			free(csa_attrs);

		if (err)
			CsaCroak("add_entry", err);
		
		entry = safe_malloc(sizeof(struct Calendar__CSA__Entry_t));
		entry->session_sv = newRV(SvRV(ST(0)));
		entry->session = session;
		entry->entry = new_entry;
		
		RETVAL = entry;
	}
	OUTPUT:
	RETVAL

void
list_entries(session, ...)
	Calendar::CSA::Session	session
	PPCODE:
	{
		int i, j=0, err;
		int flags=0;
		CSA_uint32 count;
		CSA_entry_handle *new_entries;
		CSA_attribute * csa_attrs;
		CSA_enum * csa_matches;
		Calendar__CSA__EntryList entrylist;
		
		if ((items-1)%2)
			croak("attributes must be paired names and values");
			
		if (items>1) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-1)/2), 1);
			csa_matches = safe_calloc(sizeof(CSA_enum)*((items-1)/2), 1);
			for(j=0,i=1;i<items;j++,i+=2) {
				SV * r;
				csa_matches[j] = CSA_MATCH_ANY;
				csa_attrs[j].name = lengthen(SvPV(ST(i),na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
				r = ST(i+1);

				if (r && SvOK(r) && SvRV(r) && (SvTYPE(SvRV(r))==SVt_PVHV)) {
					SV ** s = hv_fetch((HV*)SvRV(r), "match", 5, 0);
					if (s)
						if (SvOK(*s))
							csa_matches[j] = SvCSA_MATCH(*s);
				}
			}
		} else {
			csa_attrs = 0;
			csa_matches = 0;
		}
#ifdef CSA_DEBUG
		for(i=0;i<j;i++) {
			char *c;
			fprintf(stderr, "attribute %d name is %s\n", i, csa_attrs[i].name);
			fprintf(stderr, "attribute %d value is %d\n", i, csa_attrs[i].value);
			fprintf(stderr, "attribute %d match is %s\n", i, SvPV(newSVCSA_MATCH(csa_matches[i]),na));

			/* hack alert */
			c = csa_attrs[i].value->item.string_value;
			if (isascii(*c))
			{
				printf("\t%s\n", c);
			}
		}
#endif
		err = csa_list_entries(session->session, j, csa_attrs, csa_matches, &count, &new_entries, NULL);

		if (err)
			CsaCroak("list_entries", err);
		
		if (csa_attrs)
			free(csa_attrs);
		if (csa_matches)
			free(csa_matches);

		if (new_entries) {
			SV * result;

			entrylist = safe_malloc(sizeof(struct Calendar__CSA__EntryList_t));
			entrylist->count = count;
			entrylist->list = new_entries;
			entrylist->session_sv = newRV(SvRV(ST(0)));
			entrylist->session = session;

			result = sv_newmortal();
			sv_setref_pv(result, "Calendar::CSA::EntryList",
					(void *)entrylist);
			XPUSHs(result);
		}

	}

MODULE = Calendar::CSA		PACKAGE = Calendar::CSA::EntryList

void
DESTROY(entrylist)	
	Calendar::CSA::EntryList entrylist
	CODE:
	SvREFCNT_dec(entrylist->session_sv);
	if (entrylist->list)
		csa_free(entrylist->list);
	free(entrylist);

void
free(entrylist)	
	Calendar::CSA::EntryList entrylist
	CODE:
	if (entrylist->list)
		csa_free(entrylist->list);
	entrylist->list = 0;

AV *
entries(entrylist)
	Calendar::CSA::EntryList entrylist
	PPCODE:
	{
		int i;
		Calendar__CSA__Entry entry;
		SV *result;
		
		if (!entrylist->list)
			croak("Cannot retrieve entries from a freed EntryList");

		for(i=0;i<entrylist->count;i++) {
			entry = safe_malloc(sizeof(struct Calendar__CSA__Entry_t));
			entry->session_sv = newRV(SvRV(entrylist->session_sv));
			entry->session = entrylist->session;
			entry->entry = entrylist->list[i];
			result = sv_newmortal();
			sv_setref_pv(result, "Calendar::CSA::Entry", 
				     (void*)entry);
			XPUSHs(result);
		}
	}

MODULE = Calendar::CSA		PACKAGE = Calendar::CSA::Entry

void
DESTROY(entry)	
	Calendar::CSA::Entry	entry
	CODE:
	SvREFCNT_dec(entry->session_sv);
	free(entry);

void
delete_entry(entry, scope)
	Calendar::CSA::Entry	entry
	SV *	scope
	CODE:
	{
		int err;
		err = csa_delete_entry(entry->session->session, entry->entry, SvCSA_SCOPE(scope), NULL);
		if (err)
			CsaCroak("delete_entry", err);
	}	

void
read_entry_attributes(entry, ...)
	Calendar::CSA::Entry	entry
	PPCODE:
	{
		int i, j, err;
		CSA_uint32 count;
		CSA_attribute * result;
		CSA_attribute_reference * csa_names;
		if (items>1) {
			csa_names = safe_calloc(sizeof(CSA_attribute_reference)*(items-1),1);
			for(i=1;i<items;i++)
				csa_names[i-1] = lengthen(SvPV(ST(i), na));
		} else {
			csa_names = 0;
		}
			
		err = csa_read_entry_attributes(entry->session->session, entry->entry, items-1, csa_names, &count, &result, NULL);
		
		if (csa_names)
			free(csa_names);
		
		if (err)
			CsaCroak("read_entry_attributes", err);
		
		if (result) {
			EXTEND(sp, 2 * count);
			for(i=0;i<count;i++) {
				PUSHs(sv_2mortal(newSVpv(shorten(result[i].name,entry->session->shorten), 0)));
				PUSHs(sv_2mortal(newSVCSA_attribute_value(result[i].value, entry->session->shorten, entry->session->iso_times)));
			}
			csa_free(result);
		}
	}

void
update_entry_attributes(entry, scope, propagate, ...)
	Calendar::CSA::Entry	entry
	SV *	scope
	int	propagate
	CODE:
	{
		int i, j = 0, err;
		CSA_uint32 count;
		CSA_attribute * result;
		CSA_entry_handle new_entry;
		CSA_attribute * csa_attrs;
		
		if ((items-3)%2)
			croak("attributes must be paired names and values");
		if (items>3) {
			csa_attrs = safe_calloc(sizeof(CSA_attribute)*((items-3)/2),1);
			for(j=0,i=3;i<items;i+=2,j++) {
				csa_attrs[j].name = lengthen(SvPV(ST(i), na));
				csa_attrs[j].value = SvCSA_attribute_value(ST(i+1), 0);
			}
		} else
			csa_attrs = 0;

		err = csa_update_entry_attributes(entry->session->session, entry->entry, SvCSA_SCOPE(scope), propagate, j, csa_attrs, &new_entry, NULL);
		
		if (csa_attrs)
			free(csa_attrs);
		
		if (err)
			CsaCroak("update_entry_attributes", err);
			
		if (new_entry != 0)
			entry->entry = new_entry;
	}

void
list_entry_sequence(entry, range=&sv_undef, ...)
	Calendar::CSA::Entry	entry
	SV *	range
	PPCODE:
	{
		int i, j, err;
		int flags=0;
		CSA_uint32 count;
		CSA_attribute * result;
		CSA_entry_handle *new_entries;
		CSA_attribute csa_attr;
		Calendar__CSA__EntryList entrylist;
		
		err = csa_list_entry_sequence(entry->session->session, entry->entry, SvISO_date_time_range(range,0), &count, &new_entries, NULL);

		if (err)
			CsaCroak("list_entry_sequence", err);
		
		if (new_entries) {
			SV * result;

			entrylist = safe_malloc(sizeof(struct Calendar__CSA__EntryList_t));
			entrylist->count = count;
			entrylist->list = new_entries;
			entrylist->session_sv = newRV(SvRV(entry->session_sv));
			entrylist->session = entry->session;

			result = sv_newmortal();
			sv_setref_pv(result, 
				     "Calendar::CSA::EntryList",
				     (void *)entrylist);
			XPUSHs(result);
		}
	}

BOOT:
callbacks = newAV();
callback_mode = newAV();
{
	char buffer[54];
	_csa_range_to_iso8601(time(0),time(0)+20,buffer);
}
