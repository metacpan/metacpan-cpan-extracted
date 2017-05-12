

  /*
	Copyright (c) 1997 Kenneth Albanowski. All rights reserved.
	This program is free software; you can redistribute it and/or
	modify it under the same terms as Perl itself.
  */

struct opts {
	int value;
	char * name;
};
void * Csa_safe_malloc(int size);
void * Csa_safe_calloc(int nelems, size_t elsize);
char * CsaError(int error);
void CsaCroak(char * routine, int err);
SV * newSVCSA_calendar_user(CSA_calendar_user * user);
CSA_calendar_user * SvCSA_calendar_user(SV * user, CSA_calendar_user * target);
SV * newSVCSA_access_rights(CSA_access_rights * right);
SV * newSVCSA_access_list(CSA_access_list list);
CSA_access_rights * SvCSA_access_rights(SV * data, CSA_access_rights * rights);
CSA_access_list SvCSA_access_list(SV * data, CSA_access_list list);
SV * newSVCSA_attendee(CSA_attendee * attendee);
SV * newSVCSA_attendee_list(CSA_attendee_list list);
SV * newSVCSA_date_time_list(CSA_date_time_list list, int doiso_times);
CSA_date_time_list SvCSA_date_time_list(SV * data, CSA_date_time_list target);
SV * newSVCSA_opaque_data(CSA_opaque_data * data);
CSA_opaque_data * SvCSA_opaque_data(SV * data, CSA_opaque_data * target);
SV * newSVCSA_reminder(CSA_reminder * rem, int doiso_times);
SV * newSVCSA_attribute_value(CSA_attribute_value * attr, int doshorten, int doiso_times);
CSA_attribute_value * SvCSA_attribute_value(SV * attr, CSA_attribute_value * target);
SV * newSVCSA_attribute(CSA_attribute * attr, int doshorten, int doiso_times);
CSA_attribute * SvCSA_attribute(SV * attr, CSA_attribute * target);
int decode_callback_mode(char * mode);
CSA_reminder * SvCSA_reminder(SV * data, CSA_reminder * target);
SV * newSVCSA_SCOPE(int scope);
int SvCSA_SCOPE(SV * name);
SV * newSVCSA_MATCH(int match);
int SvCSA_MATCH(SV * name);
SV * newSVCSA_USER_TYPE(int match);
int SvCSA_USER_TYPE(SV * name);
SV * newSVCSA_LOOKUP(int match);
int SvCSA_LOOKUP(SV * name);
SV * newSVCSA_REQUIRED(int match);
int SvCSA_REQUIRED(SV * name);
SV * newSVCSA_LINE_TERM(int match);
int SvCSA_LINE_TERM(SV * name);

long SvOpt(SV * name, char * optname, struct opts * o);
SV * newSVOpt(long value, char * optname, struct opts * o);

long SvOptFlags(SV * name, char * optname, struct opts * o);
SV * newSVOptFlags(long value, char * optname, struct opts * o, int hash);

char * lengthen(char * arg);
char * shorten(char * arg, int doit);

SV * newSVISO_date_time(char * value, int doiso);
SV * newSVISO_date_time_range(char * value, int doiso);
SV * newSVISO_time_duration(char * value, int doiso);
char * SvISO_date_time(SV * value, char * buffer);
char * SvISO_date_time_range(SV * value, char  *buffer);
char * SvISO_time_duration(SV * value, char * buffer);

extern int Csa_accept_numeric_enumerations;
extern int Csa_generate_numeric_enumerations;
