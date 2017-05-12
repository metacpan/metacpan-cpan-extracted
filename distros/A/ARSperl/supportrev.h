/*
$Header: /cvsroot/arsperl/ARSperl/supportrev.h,v 1.19 2009/04/02 18:57:04 tstapff Exp $

    ARSperl - An ARS v2 - v5 / Perl5 Integration Kit

    Copyright (C) 1995-2003
	Joel Murphy, jmurphy@acsu.buffalo.edu
        Jeff Murphy, jcmurphy@acsu.buffalo.edu

    This program is free software; you can redistribute it and/or modify
    it under the terms as Perl itself. 
    
    Refer to the file called "Artistic" that accompanies the source distribution 
    of ARSperl (or the one that accompanies the source distribution of Perl
    itself) for a full description.
 
    Comments to:  arsperl@arsperl.org
                  (this is a *mailing list* and you must be
                   a subscriber before posting)

    Home Page: http://www.arsperl.org


*/

#ifndef __supportrev_h_
#define __supportrev_h_

#include "support.h"

#undef EXTERN
#ifndef __supportrev_c_
# define EXTERN extern
#else
# define EXTERN 
#endif

/* not defined in AR version 5.0.0 */
#ifndef AR_MAX_LEVELS_DYNAMIC_MENU
#define AR_MAX_LEVELS_DYNAMIC_MENU  5
#endif

EXTERN int  compmem(MEMCAST *m1, MEMCAST *m2, int size);
EXTERN int  copymem(MEMCAST *m1, MEMCAST *m2, int size);

EXTERN unsigned int revTypeName(TypeMapStruct *t, char *type);
EXTERN int strcpyHVal( HV *h, char *k, char *b, int len);
EXTERN int strmakHVal( HV *h, char *k, char **b);
EXTERN int intcpyHVal( HV *h, char *k, int *b);
EXTERN int uintcpyHVal( HV *h, char *k, unsigned int *b);
EXTERN int boolcpyHVal( HV *h, char *k, ARBoolean *b);
#if AR_CURRENT_API_VERSION >= 14
EXTERN int longcpyHVal( HV *h, char *k, ARLong32 *b);
EXTERN int ulongcpyHVal( HV *h, char *k, ARULong32 *b);
#else
EXTERN int longcpyHVal( HV *h, char *k, long *b);
EXTERN int ulongcpyHVal( HV *h, char *k, unsigned long *b);
#endif
EXTERN int rev_ARDisplayList(ARControlStruct *ctrl, 
			     HV *h, char *k, ARDisplayList *d);
EXTERN int rev_ARDisplayStruct(ARControlStruct *ctrl, 
			       HV *h, ARDisplayStruct *d);
EXTERN int rev_ARInternalIdList(ARControlStruct *ctrl, 
				HV *h, char *k, ARInternalIdList *il);
EXTERN int rev_ARActiveLinkActionList(ARControlStruct *ctrl, HV *h, char *k, 
				      ARActiveLinkActionList *al);
EXTERN int rev_ARFieldAssignList(ARControlStruct *ctrl,
				 HV *h, char *k, ARFieldAssignList *m);
EXTERN int rev_ARAssignStruct(ARControlStruct *ctrl,
			      HV *h, char *k, ARAssignStruct *m);
EXTERN int rev_ARValueStruct(ARControlStruct *ctrl,
			     HV *h, char *k, char *t, ARValueStruct *m);
EXTERN int rev_ARAssignFieldStruct(ARControlStruct *ctrl,
				   HV *h, char *k, ARAssignFieldStruct *m);
EXTERN int rev_ARStatHistoryValue(ARControlStruct *ctrl,
				  HV *h, char *k, ARStatHistoryValue *s);
EXTERN int rev_ARArithOpAssignStruct(ARControlStruct *ctrl,
				     HV *h, char *k, ARArithOpAssignStruct *s);
EXTERN int rev_ARFunctionAssignStruct(ARControlStruct *ctrl,
				      HV *h, char *k,
				      ARFunctionAssignStruct *s);
#ifdef ARS452
EXTERN int rev_ARFilterStatusStruct(ARControlStruct *ctrl,
			      HV *h, char *k, ARFilterStatusStruct *m);
#endif
EXTERN int rev_ARStatusStruct(ARControlStruct *ctrl,
			      HV *h, char *k, ARStatusStruct *m);
EXTERN int rev_ARFieldCharacteristics(ARControlStruct *ctrl,
				      HV *h, char *k, ARFieldCharacteristics *m);
EXTERN int rev_ARActiveLinkMacroStruct(ARControlStruct *ctrl,
				       HV *h, char *k, 
				       ARActiveLinkMacroStruct *m);
EXTERN int rev_ARMacroParmList(ARControlStruct *ctrl,
			       HV *h, char *k, ARMacroParmList *m);

#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARImageDataStruct(ARControlStruct * ctrl,
			  HV * h, char *k, ARImageDataStruct * b);
#endif

#if AR_EXPORT_VERSION >= 3
EXTERN int rev_ARByteList(ARControlStruct *ctrl,
			  HV *h, char *k, ARByteList *b);
EXTERN int rev_ARCoordList(ARControlStruct *ctrl,
			   HV *h, char *k, ARCoordList *m);
EXTERN int rev_ARPropList(ARControlStruct *ctrl,
			  HV *h, char *k, ARPropList *m);
EXTERN int rev_ARAssignSQLStruct(ARControlStruct *ctrl,
				 HV *h, char *k, ARAssignSQLStruct *s);
#endif

#if defined(_WIN32) && !defined(__GNUC__)
/* roll our own strcasecmp and strncasecmp for Win */

EXTERN int strcasecmp(char *s1, char *s2);

EXTERN int strncasecmp(char *s1, char *s2, size_t n);

EXTERN char* arsperl_strdup( char *s1 );

#define strdup arsperl_strdup

#endif /* def _WIN32 */


EXTERN int rev_ARDisplayInstanceList(ARControlStruct *ctrl,
			  HV *h, char *k, ARDisplayInstanceList *d);
EXTERN int rev_ARDisplayInstanceStruct(ARControlStruct *ctrl,
			  HV *h, ARDisplayInstanceStruct *d);
EXTERN int rev_ARPermissionList(ARControlStruct *ctrl,
			  HV *h, char *k, ARPermissionList *d);

EXTERN int rev_ARReferenceStruct( ARControlStruct *ctrl, HV *h, char *k, ARReferenceStruct *p );

EXTERN int rev_ARCharMenuItemStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuItemStruct *p );

#if AR_EXPORT_VERSION >= 4
EXTERN int
rev_ARMessageStruct(ARControlStruct * ctrl, 
                    HV * h, char *k, ARMessageStruct * m);
#endif

#if AR_EXPORT_VERSION >= 8L
EXTERN int rev_ARArchiveInfoStruct( ARControlStruct *ctrl, HV *h, char *k, ARArchiveInfoStruct *p );
#endif

EXTERN int rev_ARArithOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARArithOpStruct *p );


#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaFieldIdStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldIdStruct *p );
EXTERN int rev_ARMultiSchemaArithOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaArithOpStruct *p );
#endif


#endif /* __supportrev_h_ */

