#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* as Perl is compiled with -Kllm_case_lower we need the following define: */
#define lmsup1 LMSUP1
#include <lms.h>

/* check constants used in LMS.pm against those in lms.h: */
#include "lms_asserts.h"

/* -------------------------------------------------------------------- */
/* constants and local datatypes:					*/
/* -------------------------------------------------------------------- */

#define MAX_NORMAL_BUFFER_LENGTH (32 * 1024)
#define RECORD_HEADER_LENGTH 4
struct normalRecord_t
{
    short		total_length;
    unsigned char	reserved;
    unsigned char	record_type;
    char		content[MAX_NORMAL_BUFFER_LENGTH-RECORD_HEADER_LENGTH];
};

#define MAX_EXTRA_BUFFER_LENGTH (256 * 1024)
struct extraRecord_t
{
    char		content[MAX_EXTRA_BUFFER_LENGTH];
};

/* -------------------------------------------------------------------- */
/* macros to guarantee the correct size of strings:			*/
/* -------------------------------------------------------------------- */

#define KEY(key) key, (sizeof(key)-1)
#define FIELD(field) field, (sizeof(field)-1)

/* -------------------------------------------------------------------- */
/* macros to (hopefully) improve readability and comprehensibility of	*/
/* the code:								*/
/* -------------------------------------------------------------------- */

/* ToDo: sv_2mortal after each hv_fetch??? */

#define GET_INTEGER_FROM_HASH(variable,hash,key) \
	l_pScalarValue = hv_fetch(hash, KEY(key), 0); \
	if (l_pScalarValue == NULL  ||  *l_pScalarValue == NULL) \
	  XSRETURN_UNDEF; \
	variable = SvIV(*l_pScalarValue)
#define GET_STRING_FROM_HASH(variable,hash,key) \
	l_pScalarValue = hv_fetch(hash, KEY(key), 0); \
	if (l_pScalarValue == NULL  ||  *l_pScalarValue == NULL) \
	  XSRETURN_UNDEF; \
	strfill(variable, SvPV(*l_pScalarValue, l_iDummy), sizeof(variable))
#define GET_OPTIONAL_CHAR_FROM_HASH(variable,hash,key) \
	l_pScalarValue = hv_fetch(hash, KEY(key), 0); \
	if (l_pScalarValue != NULL  &&  *l_pScalarValue != NULL) \
	  strfill(&(variable), SvPV(*l_pScalarValue, l_iDummy), 1)
#define GET_OPTIONAL_INTEGER_FROM_HASH(variable,hash,key) \
	l_pScalarValue = hv_fetch(hash, KEY(key), 0); \
	if (l_pScalarValue != NULL  &&  *l_pScalarValue != NULL) \
	  variable = SvIV(*l_pScalarValue)
#define GET_OPTIONAL_STRING_FROM_HASH(variable,hash,key) \
	l_pScalarValue = hv_fetch(hash, KEY(key), 0); \
	if (l_pScalarValue != NULL  &&  *l_pScalarValue != NULL) \
	  strfill(variable, SvPV(*l_pScalarValue, l_iDummy), sizeof(variable))
#define PUT_CHAR_INTO_HASH(variable,hash,key) \
	if (NULL == hv_store(hash, KEY(key), newSVpv(&(variable), 1), 0)) \
	  XSRETURN_UNDEF
#define PUT_INTEGER_INTO_HASH(variable,hash,key) \
	if (NULL == hv_store(hash, KEY(key), newSViv(variable), 0)) \
	  XSRETURN_UNDEF
/* trailing blanks in strings are removed for this one: */
#define PUT_STRING_INTO_HASH(variable,hash,key) \
	if (NULL == hv_store(hash, KEY(key), \
			     newSVpv_trimmed(FIELD(variable)), 0)) \
	  XSRETURN_UNDEF
/* not used yet:
#define PUT_UNTRIMMED_STRING_INTO_HASH(variable,hash,key) \
	if (NULL == hv_store(hash, KEY(key), \
			     newSVpv(FIELD(variable)), 0)) \
	  XSRETURN_UNDEF
*/

/************************************************************************/
/* global lock for TOC ID (for multi threaded access to LMS TOC):	*/
/* We use a poor man's semaphor here as a real mutex produces massive	*/
/* system overhead.							*/
/************************************************************************/
#define MAX_TOC_ID 10
int g_toc_semaphor = 0;
int g_toc_id_used[MAX_TOC_ID] = { 0, 0, 0, 0, 0,  0, 0, 0, 0, 0 };

/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* lock the poor man's semaphor:					*/
/* -------------------------------------------------------------------- */
/* Parameter: -								*/
/* Result   : 1 if semaphor got locked, 0 otherwise			*/
/************************************************************************/
int lock_semaphor()		/* invariant (proof for correctness): */
{
    int l_iCountdown = 10;	/* g_toc_semaphor >= 0 */
    ++g_toc_semaphor;		/* g_toc_semaphor >= 1 */
    while (1 < g_toc_semaphor)	/*			  g_toc_semaphor>1 */
    {				/* g_toc_semaphor >= 1 */
	--g_toc_semaphor;	/* g_toc_semaphor >= 0 */
	if (--l_iCountdown <= 0)
	  return 0;
	sleep(1);		/* g_toc_semaphor >= 0 */
	++g_toc_semaphor;	/* g_toc_semaphor >= 1 */
    }				/* g_toc_semaphor>=1 || ! g_toc_semaphor>1 */
    return 1;			/* g_toc_semaphor == 1 */
}
/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* unlock the poor man's semaphor:					*/
/* -------------------------------------------------------------------- */
/* Parameter: -								*/
/* Result   : -								*/
/************************************************************************/
void unlock_semaphor()
{
    --g_toc_semaphor;
}

/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* get a unique TOC ID (for multi threaded access to LMS TOC):		*/
/* -------------------------------------------------------------------- */
/* Parameter: -								*/
/* Result   : 0 (if no ID is free) or an ID (1..MAX_TOC_ID)		*/
/************************************************************************/
int get_toc_id()
{
    int l_iID = 0;
    if (lock_semaphor())
    {
	/* find (backwards) first free TOC ID: */
	for (l_iID = MAX_TOC_ID; l_iID > 0; --l_iID)
	{
	    if (0 == g_toc_id_used[ l_iID - 1 ])
	    {
		g_toc_id_used[ l_iID - 1 ] = 1;
		break;
	    }
	}
	unlock_semaphor();
    }
    return l_iID;
}

/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* release the unique TOC ID reserved with get_toc_id:			*/
/* -------------------------------------------------------------------- */
/* Parameter: p_iID: TOC ID eserved with get_toc_id			*/
/* Result   : -								*/
/************************************************************************/
void release_toc_id(int p_iID)
{
    g_toc_id_used[ p_iID - 1 ] = 0;
}

/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* create a new string SV with a trimmed end (blank at the end are	*/
/* removed):								*/
/* -------------------------------------------------------------------- */
/* Parameter: p_pString: the string hasn't to be null terminated	*/
/*	      p_iLastIndex: last index of the string (MUST be applied)	*/
/* Result   : -								*/
/************************************************************************/
SV* newSVpv_trimmed(char* p_pString, int p_iLastIndex)
{
    while(p_iLastIndex >= 0  &&  ' ' == p_pString[p_iLastIndex])
      --p_iLastIndex;
    /* BEWARE: len == 0 has a special meaning (compute length)
       for newSVpv(str, len)!!! */
    return p_iLastIndex < 0 ? newSVpv("", 0)
	: newSVpv(p_pString, p_iLastIndex + 1);
}


/************************************************************************/
/* Description:								*/
/* -------------------------------------------------------------------- */
/* copies returncode and message codes to the Perl accessor object	*/
/* -------------------------------------------------------------------- */
/* Parameter: p_LMS_ControlBlock: pointer to control block		*/
/*	      p_Accessor: accessor object				*/
/* Result   : 1 if everything was OK					*/
/************************************************************************/
int copy_returncodes(const struct lmsc_cb* const p_pLMS_ControlBlock,
		     HV* const p_pAccessor)
{
    if (NULL == hv_store(p_pAccessor, KEY("return_code"),
			 newSViv(p_pLMS_ControlBlock->retcode), 0))
	return 0;
    if (NULL == hv_store(p_pAccessor, KEY("plam_message"),
			 newSViv(p_pLMS_ControlBlock->plam_msg), 0))
	return 0;
    if (NULL == hv_store(p_pAccessor, KEY("lms_message"),
			 newSViv(p_pLMS_ControlBlock->lms_msg), 0))
	return 0;
    if (NULL == hv_store(p_pAccessor, KEY("dms_message"),
			 newSViv(p_pLMS_ControlBlock->dms_msg), 0))
	return 0;
    return 1;
}

/************************************************************************/
/* (undocumented ;-) debugging functions, they may be deleted anytime:	*/
/************************************************************************/
void debug_cb(const struct lmsc_cb* const cb)
{                               /* debug_cb(&l_LMS_ControlBlock); */
    fprintf(stderr,
	    "CB:\tscbvers\t\t\"%2.2s\"\n\tfunction\t0x%X\n\tsubcode\t\t'%c'\n"
	    "\tacc\t\t%d (0x%X)\n\tretcode\t\t0x%X\n\tlms_msg\t\tLMS%04hd\n"
	    "\tdms_msg\t\tDMS%04hd\n\tplam_msg\tPLA%04hd\n"
	    "\tlmsvers\t\t\"%0.12s\"\n\tdestroy\t\t'%c'\n"
	    "\tfcb\t\t'%c'\n\trkey\t\t'%c'\n\toverwrite\t'%c'\n"
	    "\tcolumn\t\t%hd\n\tline\t\t%hd\n\tprot_ind\t'%c'\n"
	    "\tattr\t\t'%c'\n\tinfo\t\t'%c'\n\tld_return\t'%c'\n",
	    cb->scbvers, cb->function, cb->subcode, cb->acc, cb->acc,
	    (int) cb->retcode, cb->lms_msg, cb->dms_msg, cb->plam_msg,
	    cb->lmsvers, cb->destroy, cb->fcb, cb->rkey, cb->overwrite,
	    cb->column, cb->line, cb->prot_ind, cb->attr, cb->info,
	    cb->ld_return);
}
void debug_ed(const struct lmsc_ed* const ed)
{                               /* debug_ld(&l_LMS_LibraryDescriptor); */
    fprintf(stderr,
	    "ED:\ttyp\t\t\"%0.8s\"\n\tname\t\t\"%0.64s\"\n"
	    "\tversion\t\t\"%0.24s\"\n\tstore_form\t'%c'\n"
	    "\tuser_date\t\"%0.14s\"\n\tuser_time\t\"%0.8s\"\n",
	    ed->typ, ed->name, ed->version, ed->store_form,
	    ed->user_date, ed->user_time);
}
void debug_ld(const struct lmsc_ld* const ld)
{                               /* debug_ed(&l_LMS_ElementDescriptor); */
    fprintf(stderr,
	    "LD:\tlink\t\t\"%0.8s\"\n\tmax_name_len\t%hd\n"
	    "\tname\t\t\"%0.54s\"\n",
	    ld->link, ld->max_name_len, ld->name);
}
void debug_rd(const struct lmsc_rd* const rd)
{                               /* debug_rd(&l_LMS_RecordDescriptor); */
    fprintf(stderr,
	    "RD:\trec_acc_id\t%d (0x%X)\n\tbuffer_len\t%d\n"
	    "\trecord_len\t%d\n\trecord_type\t\'%c' (0x%X)\n"
	    "\trecord_num\t%d\n",
	    rd->rec_acc_id, rd->rec_acc_id, rd->buffer_len, rd->record_len,
            rd->record_type, (int) rd->record_type, rd->record_num);
}
void debug_er(struct normalRecord_t* const er)
{                               /* debug_er(&l_Record); */
    er->content[er->total_length - RECORD_HEADER_LENGTH] = 0;
    fprintf(stderr,
	    "ER:\ttotal_length\t%d\n\trecord_type\t\'%c' (0x%X)\n"
	    "\tcontent\t\t%s\n",
	    er->total_length, er->record_type, (int) er->record_type,
            er->content);
}

/************************************************************************/
/* XS code starting here:						*/
/************************************************************************/

MODULE = BS2000::LMS		PACKAGE = BS2000::LMS		

PROTOTYPES: ENABLE


 ########################################################################
 # call:								#
 #	lms_assertions();						#
 # parameters:								#
 #	-								#
 # description:								#
 #	This function does some internal checks.			#
 # returns:								#
 #	-								#
 ########################################################################
void
lms_assertions()
    PREINIT:
	int l_iErrors = 0;
    CODE:
	if (sizeof(struct normalRecord_t) != MAX_NORMAL_BUFFER_LENGTH)
	{
	    fputs("alignment mismatch / wrong size in normalRecord_t\n",
                  stderr);
	    l_iErrors++;
	}
	if (sizeof(struct normalRecord_t) != MAX_NORMAL_BUFFER_LENGTH)
	{
	    fputs("alignment mismatch / wrong size in normalRecord_t\n",
                  stderr);
	    l_iErrors++;
	}
	if (l_iErrors > 0)
	  exit(-1);


 ########################################################################
 # call:								#
 #	lms_init($rAccessor);						#
 # parameters:								#
 #	$rAccessor	reference to (yet unblessed) accessor object	#
 # description:								#
 #	This function initialises the LMS subroutine interface (INIT).	#
 # returns:								#
 #		new access ID						#
 #	or	-1 in case of PLAM / LMS / DMS errors			#
 #	or	undef in case of internal errors			#
 ########################################################################
int
lms_init(HV* p_pAccessor)
    PROTOTYPE: \%;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	SV** l_pScalarValue;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
    CODE:
	/* call library function: */
	l_LMS_ControlBlock.function = LMSUP_INIT;
	l_LMS_ControlBlock.subcode = LMSUP_UNUSED;
	lmsup1(&l_LMS_ControlBlock);
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	PUT_STRING_INTO_HASH(l_LMS_ControlBlock.lmsvers,
			     p_pAccessor, "lms_version");
	/* return access ID: */
	RETVAL = l_LMS_ControlBlock.acc;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_end($rAccessor);						#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 # description:								#
 #	This function closes the LMS subroutine interface (END).	#
 # returns:								#
 #		0							#
 #	or	-1 in case of PLAM / LMS / DMS errors			#
 #	or	undef in case of internal errors			#
 ########################################################################
int
lms_end(HV* p_pAccessor)
    PROTOTYPE: \%;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	SV** l_pScalarValue;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
    CODE:
	/* call library function: */
	l_LMS_ControlBlock.function = LMSUP_END;
	l_LMS_ControlBlock.subcode = LMSUP_UNUSED;
	lmsup1(&l_LMS_ControlBlock);
	/* set normal return values: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	/* set return code: */
	RETVAL = (l_LMS_ControlBlock.retcode == 0  &&
		  l_LMS_ControlBlock.acc == -1) ? 0 : -1;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_list($rAccessor, $rSelector);				#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$rSelector	reference to hash with selection criterias	#
 # description:								#
 #	This function returns a table of contents of a LMS library.	#
 # returns:								#
 #		array of hashes with table of contents			#
 #	or	undef in case of errors					#
 ########################################################################
AV*
lms_list(HV* p_pAccessor, HV* p_pSelector)
    PROTOTYPE: \%\%;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_ld l_LMS_LibraryDescriptor = lmsc_ld_proto;
	struct lmsc_em l_LMS_ElementMask = lmsc_em_proto;
	struct lmsc_ei l_LMS_ElementInformation = lmsc_ei_proto;
	SV** l_pScalarValue;
	STRLEN l_iDummy;
	int l_iTOC_ID_Number;
	unsigned int l_uiMode;
	unsigned int l_uiFromIndex = 0;
	unsigned int l_uiToIndex = UINT_MAX;
	unsigned int l_uiIndex = 0;
	AV* l_pTOCArray = newAV();
	HV* l_pTOCElementHash;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.ld_return = 'Y';
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.name,
			     p_pAccessor, "name");
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.link,
			     p_pAccessor, "link_name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.name,
				      p_pSelector, "name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.typ,
				      p_pSelector, "type");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.version,
				      p_pSelector, "version");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.user_date,
				      p_pSelector, "user_date");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.user_time,
				      p_pSelector, "user_time");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.crea_date,
				      p_pSelector, "creation_date");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.crea_time,
				      p_pSelector, "creation_time");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.modif_date,
				      p_pSelector, "modification_date");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.modif_time,
				      p_pSelector, "modification_time");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.access_date,
				      p_pSelector, "access_date");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementMask.access_time,
				      p_pSelector, "access_time");
	l_pScalarValue = hv_fetch(p_pSelector, KEY("mode_set"), 0);
	if (l_pScalarValue != NULL  &&  *l_pScalarValue != NULL)
	{
	    l_uiMode = SvIV(*l_pScalarValue);
	    if (l_uiMode & 0400) l_LMS_ElementMask.p_read_own = LMSUP_YES;
	    if (l_uiMode & 0200) l_LMS_ElementMask.p_writ_own = LMSUP_YES;
	    if (l_uiMode & 0100) l_LMS_ElementMask.p_exec_own = LMSUP_YES;
	    if (l_uiMode & 0040) l_LMS_ElementMask.p_read_grp = LMSUP_YES;
	    if (l_uiMode & 0020) l_LMS_ElementMask.p_writ_grp = LMSUP_YES;
	    if (l_uiMode & 0010) l_LMS_ElementMask.p_exec_grp = LMSUP_YES;
	    if (l_uiMode & 0004) l_LMS_ElementMask.p_read_oth = LMSUP_YES;
	    if (l_uiMode & 0002) l_LMS_ElementMask.p_writ_oth = LMSUP_YES;
	    if (l_uiMode & 0001) l_LMS_ElementMask.p_exec_oth = LMSUP_YES;
	}
	l_pScalarValue = hv_fetch(p_pSelector, KEY("mode_unset"), 0);
	if (l_pScalarValue != NULL  &&  *l_pScalarValue != NULL)
	{
	    l_uiMode = SvIV(*l_pScalarValue);
	    if (l_uiMode & 0400) l_LMS_ElementMask.p_read_own = LMSUP_NO;
	    if (l_uiMode & 0200) l_LMS_ElementMask.p_writ_own = LMSUP_NO;
	    if (l_uiMode & 0100) l_LMS_ElementMask.p_exec_own = LMSUP_NO;
	    if (l_uiMode & 0040) l_LMS_ElementMask.p_read_grp = LMSUP_NO;
	    if (l_uiMode & 0020) l_LMS_ElementMask.p_writ_grp = LMSUP_NO;
	    if (l_uiMode & 0010) l_LMS_ElementMask.p_exec_grp = LMSUP_NO;
	    if (l_uiMode & 0004) l_LMS_ElementMask.p_read_oth = LMSUP_NO;
	    if (l_uiMode & 0002) l_LMS_ElementMask.p_writ_oth = LMSUP_NO;
	    if (l_uiMode & 0001) l_LMS_ElementMask.p_exec_oth = LMSUP_NO;
	}
	GET_OPTIONAL_CHAR_FROM_HASH(l_LMS_ElementMask.hold_state,
				    p_pSelector, "hold_state");
	GET_OPTIONAL_INTEGER_FROM_HASH(l_LMS_ElementMask.e_size_min,
				       p_pSelector, "min_element_size");
	GET_OPTIONAL_INTEGER_FROM_HASH(l_LMS_ElementMask.e_size_max,
				       p_pSelector, "max_element_size");
	GET_OPTIONAL_INTEGER_FROM_HASH(l_uiFromIndex,
				       p_pSelector, "from_index");
	GET_OPTIONAL_INTEGER_FROM_HASH(l_uiToIndex,
				       p_pSelector, "to_index");
    CODE:
	/* get unique TOC ID (for multi threading): */
	l_iTOC_ID_Number = get_toc_id();
	if (0 >= l_iTOC_ID_Number)
	  XSRETURN_UNDEF;
	/* first call to library function: */
	l_LMS_ControlBlock.function = LMSUP_TOCPRIM;
	l_LMS_ControlBlock.subcode = LMSUP_LONG;
	do{
	    l_LMS_ElementInformation = lmsc_ei_proto;
	    lmsup1(&l_LMS_ControlBlock,
		   &l_iTOC_ID_Number,
		   &l_LMS_ElementInformation,
		   &l_LMS_LibraryDescriptor,
		   &l_LMS_ElementMask);
	    /* only return valid elements of the selected index range: */
	    if (l_LMS_ControlBlock.retcode == LMSUP_OK  &&
		l_uiIndex >= l_uiFromIndex  &&  l_uiIndex <= l_uiToIndex)
	    {
		/* generate new hash and fill it: */
		l_pTOCElementHash = newHV();
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.typ,
				     l_pTOCElementHash, "type");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.name,
				     l_pTOCElementHash, "name");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.version,
				     l_pTOCElementHash, "version");
		PUT_CHAR_INTO_HASH(l_LMS_ElementInformation.store_form,
				   l_pTOCElementHash, "storage_form");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.sec_name,
				     l_pTOCElementHash, "secondary_name");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.sec_attr,
				     l_pTOCElementHash, "secondary_attribute");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.user_date,
				     l_pTOCElementHash, "user_date");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.user_time,
				     l_pTOCElementHash, "user_time");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.crea_date,
				     l_pTOCElementHash, "creation_date");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.crea_time,
				     l_pTOCElementHash, "creation_time");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.modif_date,
				     l_pTOCElementHash, "modification_date");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.modif_time,
				     l_pTOCElementHash, "modification_time");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.access_date,
				     l_pTOCElementHash, "access_date");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.access_time,
				     l_pTOCElementHash, "access_time");
		l_uiMode  = (LMSUP_NO!=l_LMS_ElementInformation.p_read_own)<<8;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_writ_own)<<7;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_exec_own)<<6;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_read_grp)<<5;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_writ_grp)<<4;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_exec_grp)<<3;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_read_oth)<<2;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_writ_oth)<<1;
		l_uiMode |= (LMSUP_NO!=l_LMS_ElementInformation.p_exec_oth);
		PUT_INTEGER_INTO_HASH(l_uiMode, l_pTOCElementHash, "mode");
		PUT_CHAR_INTO_HASH(l_LMS_ElementInformation.hold_state,
				   l_pTOCElementHash, "hold_state");
		PUT_STRING_INTO_HASH(l_LMS_ElementInformation.holder,
				     l_pTOCElementHash, "holder");
		PUT_INTEGER_INTO_HASH(l_LMS_ElementInformation.element_size,
				      l_pTOCElementHash, "element_size");
		/* generate reference to hash and store it in array (no
		   reference counters are incremented here!); the cast here is
		   allowed and neccessary: */
		av_push(l_pTOCArray, newRV_noinc( (SV*) l_pTOCElementHash));
	    }
	    /* every loop after first must use LMSUP_TOC: */
	    if (0 == l_uiIndex)
	      l_LMS_ControlBlock.function = LMSUP_TOC;
	    l_uiIndex++;
	}
	while(l_LMS_ControlBlock.retcode == LMSUP_OK);
	/* release TOC ID (always!!!): */
	release_toc_id(l_iTOC_ID_Number);
	/* set normal return values: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	if (l_LMS_ControlBlock.retcode != LMSUP_OK  &&
	    l_LMS_ControlBlock.retcode != LMSUP_EOF)
	  XSRETURN_UNDEF;
	/* set return code: */
	RETVAL = l_pTOCArray;
    OUTPUT:
	RETVAL
    CLEANUP:
	/* give up reference to AV (see CookBookA/Ex4 for details): */
	SvREFCNT_dec(RETVAL);


 ########################################################################
 # call:								#
 #	lms_open_get($rAccessor, $rElementDescr);			#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$rElementDescr	reference to hash with element description	#
 # description:								#
 #	This function opens a library element for reading.		#
 # returns:								#
 #		new access ID						#
 #	or	undef in case of errors					#
 ########################################################################
int
lms_open_get(HV* p_pAccessor, HV* p_pElementDescriptor)
    PROTOTYPE: \%\%;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_ld l_LMS_LibraryDescriptor = lmsc_ld_proto;
	struct lmsc_ed l_LMS_ElementDescriptor = lmsc_ed_proto;
	struct lmsc_rd l_LMS_RecordDescriptor = lmsc_rd_proto;
	SV** l_pScalarValue;
	STRLEN l_iDummy;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.function = LMSUP_OPEN_GET;
	l_LMS_ControlBlock.subcode = LMSUP_UNUSED;
	l_LMS_ControlBlock.ld_return = 'N';
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.name,
			     p_pAccessor, "name");
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.link,
			     p_pAccessor, "link_name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.name,
				      p_pElementDescriptor, "name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.typ,
				      p_pElementDescriptor, "type");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.version,
				      p_pElementDescriptor, "version");
    CODE:
	/* call library function: */
	lmsup1(&l_LMS_ControlBlock,
	       &l_LMS_RecordDescriptor,
	       &l_LMS_LibraryDescriptor,
	       &l_LMS_ElementDescriptor);
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	if (l_LMS_ControlBlock.retcode != LMSUP_OK)
	  XSRETURN_UNDEF;
	/* return record access ID: */
	RETVAL = l_LMS_RecordDescriptor.rec_acc_id;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_open_put($rAccessor, $rElementDescr);			#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$rElementDescr	reference to hash with element description	#
 # description:								#
 #	This function opens a library element for reading.		#
 # returns:								#
 #		new access ID						#
 #	or	undef in case of errors					#
 ########################################################################
int
lms_open_put(HV* p_pAccessor, HV* p_pElementDescriptor)
    PROTOTYPE: \%\%;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_ld l_LMS_LibraryDescriptor = lmsc_ld_proto;
	struct lmsc_ed l_LMS_ElementDescriptor = lmsc_ed_proto;
	struct lmsc_ed l_LMS_DummyElementDescriptor = lmsc_ed_proto;
	struct lmsc_rd l_LMS_RecordDescriptor = lmsc_rd_proto;
	SV** l_pScalarValue;
	STRLEN l_iDummy;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.function = LMSUP_OPEN_PUT;
	l_LMS_ControlBlock.subcode = LMSUP_UNUSED;
	l_LMS_ControlBlock.ld_return = 'N';
	l_LMS_ControlBlock.destroy = 'N';
	l_LMS_ControlBlock.overwrite = 'Y';
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.name,
			     p_pAccessor, "name");
	GET_STRING_FROM_HASH(l_LMS_LibraryDescriptor.link,
			     p_pAccessor, "link_name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.name,
				      p_pElementDescriptor, "name");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.typ,
				      p_pElementDescriptor, "type");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.version,
				      p_pElementDescriptor, "version");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.user_date,
				      p_pElementDescriptor, "user_date");
	GET_OPTIONAL_STRING_FROM_HASH(l_LMS_ElementDescriptor.user_time,
				      p_pElementDescriptor, "user_time");
	l_LMS_ElementDescriptor.store_form = LMSUP_FULL;
    CODE:
	/* call library function: */
	lmsup1(&l_LMS_ControlBlock,
	       &l_LMS_RecordDescriptor,
	       &l_LMS_LibraryDescriptor,
	       &l_LMS_ElementDescriptor,
	       &l_LMS_DummyElementDescriptor);
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	if (l_LMS_ControlBlock.retcode != LMSUP_OK)
	  XSRETURN_UNDEF;
	/* return record access ID: */
	RETVAL = l_LMS_RecordDescriptor.rec_acc_id;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_read($rAccessor, $AccessID, $rContent, $ExtraLong);		#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$AccessID	record access ID for open library element	#
 #	$rContent	reference to scalar getting the content		#
 #	$ExtraLong	flag: 1 for record type B			#
 # description:								#
 #	This function normally reads the next record of up to 32764	#
 #	bytes (32 KB - 4) from a library element.  If the Flag		#
 #	p_fExtraLong is set, the next record is a record of type B	#
 #	with up to 256 KB and is also read completely.			#
 # returns:								#
 #		number of bytes read into rContent (>=0)		#
 #	or	undef in case of errors					#
 ########################################################################
int
lms_read(HV* p_pAccessor, int p_iRAccessID, SV* p_pContent, int p_fExtraLong=0)
    PROTOTYPE: \%$\$$;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_rd l_LMS_RecordDescriptor = lmsc_rd_proto;
	SV** l_pScalarValue;
	int l_iRecordLength = 0;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.function = LMSUP_GET;
	l_LMS_ControlBlock.subcode = LMSUP_SEQ;
	l_LMS_ControlBlock.ld_return = 'N'; /* undocumented, but mandatory! */
	l_LMS_RecordDescriptor.rec_acc_id = p_iRAccessID;
    CODE:
	/* call library function: */
	if (!p_fExtraLong)
	{
	    /* read normal records != record type 'B': */
	    struct normalRecord_t l_Record;
	    l_LMS_RecordDescriptor.buffer_len = MAX_NORMAL_BUFFER_LENGTH;
	    lmsup1(&l_LMS_ControlBlock,
		   &l_LMS_RecordDescriptor,
		   &l_Record);
	    /* copy record: */
	    if (l_LMS_ControlBlock.retcode == LMSUP_OK)
	    {
		l_iRecordLength =
		    l_LMS_RecordDescriptor.record_len - RECORD_HEADER_LENGTH;
		if (l_iRecordLength < 0	 ||
		    l_iRecordLength
		    > MAX_NORMAL_BUFFER_LENGTH - RECORD_HEADER_LENGTH)
		  XSRETURN_UNDEF; /* this should never happen */
		sv_setpvn(SvRV(p_pContent), l_Record.content, l_iRecordLength);
	    }
	}
	else
	{
	    /* read extra records of record type 'B': */
	    struct extraRecord_t l_Record;
	    l_LMS_RecordDescriptor.buffer_len = MAX_EXTRA_BUFFER_LENGTH;
	    lmsup1(&l_LMS_ControlBlock,
		   &l_LMS_RecordDescriptor,
		   &l_Record);
	    /* copy record: */
	    if (l_LMS_ControlBlock.retcode == LMSUP_OK)
	    {
		l_iRecordLength = l_LMS_RecordDescriptor.record_len;
		if (l_iRecordLength < 0	 ||
		    l_iRecordLength > MAX_EXTRA_BUFFER_LENGTH)
		  XSRETURN_UNDEF; /* this should never happen */
		sv_setpvn(SvRV(p_pContent), l_Record.content, l_iRecordLength);
	    }
	}
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	if (l_LMS_ControlBlock.retcode != LMSUP_OK  &&
            l_LMS_ControlBlock.retcode != LMSUP_EOF)
	  RETVAL = -1;
	else
	  RETVAL = l_iRecordLength;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_write($rAccessor, $AccessID, $rContent);			#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$AccessID	record access ID for open library element	#
 #	$rContent	reference to scalar containing the data		#
 # description:								#
 #	This function normally writes the next record of up to 32764	#
 #	bytes (32 KB - 4) from a library element.  If the Flag		#
 #	p_fExtraLong is set, the next record is a record of type B	#
 #	with up to 256 KB and is also write completely.			#
 # returns:								#
 #		number of bytes write into rContent (>=0)		#
 #	or	undef in case of errors					#
 ########################################################################
int
lms_write(HV* p_pAccessor, int p_iRAccessID, SV* p_pContent)
    PROTOTYPE: \%$\$;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_rd l_LMS_RecordDescriptor = lmsc_rd_proto;
	char* l_pData;
	STRLEN l_iDataLength;
	struct normalRecord_t l_Record;
	SV** l_pScalarValue;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.function = LMSUP_PUT;
	l_LMS_ControlBlock.subcode = LMSUP_UNUSED;
	l_LMS_ControlBlock.ld_return = 'N'; /* undocumented, but mandatory! */
	l_LMS_RecordDescriptor.rec_acc_id = p_iRAccessID;
	l_pData = SvPV(p_pContent, l_iDataLength);
	if (l_iDataLength > MAX_NORMAL_BUFFER_LENGTH - RECORD_HEADER_LENGTH)
	{
	    l_LMS_ControlBlock.retcode = LMSUP_TRUNC;
	    XSRETURN_UNDEF;
	}
	l_LMS_RecordDescriptor.record_len =
	  l_iDataLength + RECORD_HEADER_LENGTH;
	l_Record.reserved = 0;
	memcpy(l_Record.content, l_pData, l_iDataLength);
	l_Record.total_length = l_iDataLength + RECORD_HEADER_LENGTH;
	l_Record.record_type = l_LMS_RecordDescriptor.record_type;
    CODE:
	/* call library function: */
	lmsup1(&l_LMS_ControlBlock,
	       &l_LMS_RecordDescriptor,
	       &l_Record);
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  XSRETURN_UNDEF;
	if (l_LMS_ControlBlock.retcode != LMSUP_OK)
	  RETVAL = -1;
	else
	  RETVAL = l_iDataLength;
    OUTPUT:
	RETVAL


 ########################################################################
 # call:								#
 #	lms_close($rAccessor, $AccessID, $Write);			#
 # parameters:								#
 #	$rAccessor	reference to accessor object			#
 #	$AccessID	record access ID for open library element	#
 #	$WriteFlag	flag: 1 for "commit write", 0 for "reset"	#
 # description:								#
 #	This function closes a library element.	 If the element has	#
 #	been opened for writing and the parameter p_fWrite is true,	#
 #	the element is written.	 Otherwise changes are ignored.		#
 # returns:								#
 #		1							#
 #	or	0 in case of errors					#
 ########################################################################
int
lms_close(HV* p_pAccessor, int p_iRecordAccessID, int p_fWrite=0)
    PROTOTYPE: \%$$;
    PREINIT:
	struct lmsc_cb l_LMS_ControlBlock = lmsc_cb_proto;
	struct lmsc_rd l_LMS_RecordDescriptor = lmsc_rd_proto;
	SV** l_pScalarValue;
    INIT:
	GET_INTEGER_FROM_HASH(l_LMS_ControlBlock.acc, p_pAccessor,
			      "accessor_id");
	l_LMS_ControlBlock.function = LMSUP_CLOSE;
	l_LMS_ControlBlock.subcode = p_fWrite ? LMSUP_WRITE : LMSUP_RESET;
	l_LMS_ControlBlock.ld_return = 'N'; /* undocumented, but mandatory! */
	l_LMS_RecordDescriptor.rec_acc_id = p_iRecordAccessID;
    CODE:
	/* call library function: */
	lmsup1(&l_LMS_ControlBlock,
	       &l_LMS_RecordDescriptor);
	/* get normal return values and version in addition: */
	if (! copy_returncodes(&l_LMS_ControlBlock, p_pAccessor))
	  RETVAL = 0;
	else if (l_LMS_ControlBlock.retcode != LMSUP_OK)
	  RETVAL = 0;
	else
	  RETVAL = 1;
    OUTPUT:
	RETVAL
