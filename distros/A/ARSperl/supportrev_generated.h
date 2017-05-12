
#ifndef __supportrev_generated_h_
#define __supportrev_generated_h_

#undef EXTERN
#ifndef __supportrev_generated_c_
# define EXTERN extern
#else
# define EXTERN 
#endif

#include "ar.h"
#include "arstruct.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <limits.h>


#if AR_CURRENT_API_VERSION >= 13
EXTERN int rev_ARActiveLinkSvcActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARActiveLinkSvcActionStruct *p );
#endif

EXTERN int rev_ARAttachLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARAttachLimitsStruct *p );

#if AR_CURRENT_API_VERSION >= 12
EXTERN int rev_ARAuditInfoStruct( ARControlStruct *ctrl, HV *h, char *k, ARAuditInfoStruct *p );
#endif

EXTERN int rev_ARAutomationStruct( ARControlStruct *ctrl, HV *h, char *k, ARAutomationStruct *p );



#if AR_CURRENT_API_VERSION >= 11
EXTERN int rev_ARBulkEntryReturn( ARControlStruct *ctrl, HV *h, char *k, ARBulkEntryReturn *p );
#endif
#if AR_CURRENT_API_VERSION >= 11
EXTERN int rev_ARBulkEntryReturnList( ARControlStruct *ctrl, HV *h, char *k, ARBulkEntryReturnList *p );
#endif

EXTERN int rev_ARCOMMethodList( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodList *p );


EXTERN int rev_ARCOMMethodParmList( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodParmList *p );


EXTERN int rev_ARCOMMethodParmStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodParmStruct *p );


EXTERN int rev_ARCOMMethodStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMMethodStruct *p );


EXTERN int rev_ARCOMValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARCOMValueStruct *p );


EXTERN int rev_ARCallGuideStruct( ARControlStruct *ctrl, HV *h, char *k, ARCallGuideStruct *p );


EXTERN int rev_ARCharLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharLimitsStruct *p );


EXTERN int rev_ARCharMenuDDFieldStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDFieldStruct *p );


EXTERN int rev_ARCharMenuDDFormStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDFormStruct *p );


EXTERN int rev_ARCharMenuDDStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuDDStruct *p );


EXTERN int rev_ARCharMenuFileStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuFileStruct *p );


EXTERN int rev_ARCharMenuList( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuList *p );


EXTERN int rev_ARCharMenuQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuQueryStruct *p );


EXTERN int rev_ARCharMenuSQLStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuSQLStruct *p );


EXTERN int rev_ARCharMenuSSStruct( ARControlStruct *ctrl, HV *h, char *k, ARCharMenuSSStruct *p );


EXTERN int rev_ARCloseWndStruct( ARControlStruct *ctrl, HV *h, char *k, ARCloseWndStruct *p );


EXTERN int rev_ARColumnLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARColumnLimitsStruct *p );


EXTERN int rev_ARCommitChangesStruct( ARControlStruct *ctrl, HV *h, char *k, ARCommitChangesStruct *p );


EXTERN int rev_ARCompoundSchema( ARControlStruct *ctrl, HV *h, char *k, ARCompoundSchema *p );


EXTERN int rev_ARCompoundSchemaList( ARControlStruct *ctrl, HV *h, char *k, ARCompoundSchemaList *p );


EXTERN int rev_ARContainerOwnerObj( ARControlStruct *ctrl, HV *h, char *k, ARContainerOwnerObj *p );


EXTERN int rev_ARContainerOwnerObjList( ARControlStruct *ctrl, HV *h, char *k, ARContainerOwnerObjList *p );

#if AR_CURRENT_API_VERSION >= 9
#endif
#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARCurrencyDetailList( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyDetailList *p );
#endif
#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARCurrencyDetailStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyDetailStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARCurrencyLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyLimitsStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARCurrencyPartStruct *p );
#endif

EXTERN int rev_ARDDEStruct( ARControlStruct *ctrl, HV *h, char *k, ARDDEStruct *p );

#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARDateLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDateLimitsStruct *p );
#endif

EXTERN int rev_ARDayStruct( ARControlStruct *ctrl, HV *h, char *k, ARDayStruct *p );


EXTERN int rev_ARDecimalLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDecimalLimitsStruct *p );


EXTERN int rev_ARDiaryLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARDiaryLimitsStruct *p );

#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_ARDisplayLimits( ARControlStruct *ctrl, HV *h, char *k, ARDisplayLimits *p );
#endif

EXTERN int rev_AREntryIdList( ARControlStruct *ctrl, HV *h, char *k, AREntryIdList *p );




EXTERN int rev_AREntryListFieldList( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldList *p );


EXTERN int rev_AREntryListFieldStruct( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldStruct *p );


EXTERN int rev_AREntryListFieldValueList( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldValueList *p );


EXTERN int rev_AREntryListFieldValueStruct( ARControlStruct *ctrl, HV *h, char *k, AREntryListFieldValueStruct *p );

#if AR_CURRENT_API_VERSION >= 11
EXTERN int rev_AREntryReturn( ARControlStruct *ctrl, HV *h, char *k, AREntryReturn *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_AREnumItemList( ARControlStruct *ctrl, HV *h, char *k, AREnumItemList *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_AREnumItemStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumItemStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_AREnumLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumLimitsStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_AREnumQueryStruct( ARControlStruct *ctrl, HV *h, char *k, AREnumQueryStruct *p );
#endif

EXTERN int rev_AREscalationTmStruct( ARControlStruct *ctrl, HV *h, char *k, AREscalationTmStruct *p );


EXTERN int rev_ARExitGuideStruct( ARControlStruct *ctrl, HV *h, char *k, ARExitGuideStruct *p );


EXTERN int rev_ARFieldLimitList( ARControlStruct *ctrl, HV *h, char *k, ARFieldLimitList *p );


EXTERN int rev_ARFieldLimitStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldLimitStruct *p );


EXTERN int rev_ARFieldMappingList( ARControlStruct *ctrl, HV *h, char *k, ARFieldMappingList *p );


EXTERN int rev_ARFieldMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldMappingStruct *p );


EXTERN int rev_ARFieldValueList( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueList *p );


EXTERN int rev_ARFieldValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueOrArithStruct *p );


EXTERN int rev_ARFieldValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARFieldValueStruct *p );


EXTERN int rev_ARFilterActionList( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionList *p );


EXTERN int rev_ARFilterActionNotify( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionNotify *p );

#if AR_CURRENT_API_VERSION >= 9
EXTERN int rev_ARFilterActionNotifyAdvanced( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionNotifyAdvanced *p );
#endif

EXTERN int rev_ARFilterActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARFilterActionStruct *p );


EXTERN int rev_ARGotoActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARGotoActionStruct *p );


EXTERN int rev_ARGotoGuideLabelStruct( ARControlStruct *ctrl, HV *h, char *k, ARGotoGuideLabelStruct *p );


EXTERN int rev_ARIndexList( ARControlStruct *ctrl, HV *h, char *k, ARIndexList *p );


EXTERN int rev_ARIndexStruct( ARControlStruct *ctrl, HV *h, char *k, ARIndexStruct *p );

#if AR_CURRENT_API_VERSION >= 10
EXTERN int rev_ARInheritanceMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARInheritanceMappingStruct *p );
#endif

EXTERN int rev_ARIntegerLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARIntegerLimitsStruct *p );




EXTERN int rev_ARJoinMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARJoinMappingStruct *p );


EXTERN int rev_ARJoinSchema( ARControlStruct *ctrl, HV *h, char *k, ARJoinSchema *p );


EXTERN int rev_ARLicenseDateStruct( ARControlStruct *ctrl, HV *h, char *k, ARLicenseDateStruct *p );


EXTERN int rev_ARLicenseValidStruct( ARControlStruct *ctrl, HV *h, char *k, ARLicenseValidStruct *p );



#if AR_CURRENT_API_VERSION >= 14 && AR_CURRENT_API_VERSION <= 14
EXTERN int rev_ARMultiSchemaCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaCurrencyPartStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFieldFuncList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncList *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFieldFuncStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFieldFuncValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldFuncValueOrArithStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaFieldIdList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldIdList *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaFieldValueOrArithStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFieldValueOrArithStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncArithOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncArithOpStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncCurrencyPartStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncCurrencyPartStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQualifierStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncQueryFromList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQueryFromList *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncQueryFromStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncQueryFromStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncRelOpStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaFuncStatHistoryValue( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaFuncStatHistoryValue *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaNestedFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaNestedFuncQueryStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaNestedQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaNestedQueryStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQualifierStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaQueryFromList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQueryFromList *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaQueryFromStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaQueryFromStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaRecursiveFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRecursiveFuncQueryStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaRecursiveQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRecursiveQueryStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaRelOpStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaSortList( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaSortList *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaSortStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaSortStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaStatHistoryValue( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaStatHistoryValue *p );
#endif
#if AR_CURRENT_API_VERSION >= 17
EXTERN int rev_ARMultiSchemaValueSetFuncQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaValueSetFuncQueryStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 14
EXTERN int rev_ARMultiSchemaValueSetQueryStruct( ARControlStruct *ctrl, HV *h, char *k, ARMultiSchemaValueSetQueryStruct *p );
#endif

EXTERN int rev_ARNameList( ARControlStruct *ctrl, HV *h, char *k, ARNameList *p );




EXTERN int rev_AROpenDlgStruct( ARControlStruct *ctrl, HV *h, char *k, AROpenDlgStruct *p );

#if AR_CURRENT_API_VERSION >= 10
EXTERN int rev_ARPushFieldsActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsActionStruct *p );
#endif

EXTERN int rev_ARPushFieldsList( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsList *p );


EXTERN int rev_ARPushFieldsStruct( ARControlStruct *ctrl, HV *h, char *k, ARPushFieldsStruct *p );


EXTERN int rev_ARQualifierList( ARControlStruct *ctrl, HV *h, char *k, ARQualifierList *p );


EXTERN int rev_ARQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARQualifierStruct *p );


EXTERN int rev_ARQualifierStruct( ARControlStruct *ctrl, HV *h, char *k, ARQualifierStruct *p );


EXTERN int rev_ARQueryValueStruct( ARControlStruct *ctrl, HV *h, char *k, ARQueryValueStruct *p );


EXTERN int rev_ARRealLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARRealLimitsStruct *p );


EXTERN int rev_ARReferenceList( ARControlStruct *ctrl, HV *h, char *k, ARReferenceList *p );


EXTERN int rev_ARRelOpStruct( ARControlStruct *ctrl, HV *h, char *k, ARRelOpStruct *p );


EXTERN int rev_ARSQLStruct( ARControlStruct *ctrl, HV *h, char *k, ARSQLStruct *p );



#if AR_CURRENT_API_VERSION >= 10
EXTERN int rev_ARSetFieldsActionStruct( ARControlStruct *ctrl, HV *h, char *k, ARSetFieldsActionStruct *p );
#endif

EXTERN int rev_ARSortList( ARControlStruct *ctrl, HV *h, char *k, ARSortList *p );


EXTERN int rev_ARSortStruct( ARControlStruct *ctrl, HV *h, char *k, ARSortStruct *p );


EXTERN int rev_ARStatHistoryValue( ARControlStruct *ctrl, HV *h, char *k, ARStatHistoryValue *p );


EXTERN int rev_ARStatusList( ARControlStruct *ctrl, HV *h, char *k, ARStatusList *p );


EXTERN int rev_ARTableLimitsStruct( ARControlStruct *ctrl, HV *h, char *k, ARTableLimitsStruct *p );




EXTERN int rev_ARUnsignedIntList( ARControlStruct *ctrl, HV *h, char *k, ARUnsignedIntList *p );


EXTERN int rev_ARValueList( ARControlStruct *ctrl, HV *h, char *k, ARValueList *p );


EXTERN int rev_ARValueStruct( ARControlStruct *ctrl, HV *h, char *k, char *t, ARValueStruct *p );

#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_ARVendorMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARVendorMappingStruct *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_ARVendorSchema( ARControlStruct *ctrl, HV *h, char *k, ARVendorSchema *p );
#endif
#if AR_CURRENT_API_VERSION >= 8
EXTERN int rev_ARViewLimits( ARControlStruct *ctrl, HV *h, char *k, ARViewLimits *p );
#endif

EXTERN int rev_ARViewMappingStruct( ARControlStruct *ctrl, HV *h, char *k, ARViewMappingStruct *p );


EXTERN int rev_ARViewSchema( ARControlStruct *ctrl, HV *h, char *k, ARViewSchema *p );


EXTERN int rev_ARWaitStruct( ARControlStruct *ctrl, HV *h, char *k, ARWaitStruct *p );

#if AR_CURRENT_API_VERSION >= 11
EXTERN int rev_ARXMLEntryReturn( ARControlStruct *ctrl, HV *h, char *k, ARXMLEntryReturn *p );
#endif

void copyIntArray( int size, int *dst, SV* src );
void copyUIntArray( int size, ARInternalId *dst, SV* src );

#endif /* __supportrev_generated_h_ */

