/* @(#) CodeBase.xs -- Perl5 CodeBase module 
 * @(#) $Id: CodeBase.xs,v 1.5 1999/08/10 09:49:31 andrew Exp $
 * 
 * Copyright (C) 1996-1999 Andrew Ford and Ford & Mason Ltd.  All rights reserved.
 *
 * You may distribute under the terms of the Perl "Artistic" License,
 * as specified in the README file.
 *
 * This module provides an interface between Perl 5 and the 
 * Codebase XBASE access functions.  
 *
 */


/* Perl includes */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "limits.h"

/* CodeBase includes */

#undef TRUE
#undef FALSE
#include "d4all.h"




/* CodeBase 6.x renamed many API functions to use capitalization
 * rather than underscores to separate words within a name.
 * If compiling against CodeBase 5.1 map the new names to the old.
 */

#if S4VERSION < 6000

   #define c4trimN(a, b)                     (c4trim_n(a, b))

   #define code4calcCreate(a, b, c)          (expr4calc_create(a, b, c))
   #define code4calcReset(a)                 (expr4calc_reset(a))
   #define code4close(a)                     (d4close_all(a))
   #define code4data(a, b)                   (d4data(a, b))
   #define code4exit(a)                      (e4exit(a))
   #define code4flush(a)                     (d4flush_files(a))
   #define code4init(a)                      (d4init(a))
   #define code4initUndo(a)                  (d4init_undo(a))
   #define code4optStart(a)                  (d4opt_start(a))
   #define code4optSuspend(a)                (d4opt_suspend(a))
   #define code4unlock(a)                    (d4unlock_files(a))

   #define d4aliasSet(a, b)                  (d4alias_set(a, b))
   #define d4appendBlank(a)                  (d4append_blank(a))
   #define d4appendStart(a, b)               (d4append_start(a, b))
   #define d4fieldInfo(a)                    (d4field_info(a))
   #define d4fieldJ(a, b)                    (d4field_j(a, b))
   #define d4fieldNumber(a, b)               (d4field_number(a, b))
   #define d4flushData(a)                    (d4flush_data(a))
   #define d4freeBlocks(a)                   (d4free_blocks(a))
   #define d4goBof(a)                        (d4go_bof(a))
   #define d4goData(a, b)                    (d4go_data(a, b))
   #define d4goEof(a)                        (d4go_eof(a))
   #define d4lockAll(a)                      (d4lock_all(a))
   #define d4lockAppend(a)                   (d4lock_append(a))
   #define d4lockFile(a)                     (d4lock_file(a))
   #define d4lockIndex(a)                    (d4lock_index(a))
   #define d4lockTest(a, b)                  (d4lock_test(a, b))
   #define d4lockTestAppend(a)               (d4lock_test_append(a))
   #define d4lockTestFile(a)                 (d4lock_test_file(a))
   #define d4memoCompress(a)                 (d4memo_compress(a))
   #define d4numFields(a)                    (d4num_fields(a))
   #define d4optimizeWrite(a, b)             (d4optimize_write(a, b))
   #define d4packData(a)                     (d4pack_data(a))
   #define d4positionSet(a, b)               (d4position_set(a, b))
   #define d4recCount(a)                     (d4reccount(a))
   #define d4recNo(a)                        (d4recno(a))
   #define d4recPosition(a, b)               (d4record_position(a, b))
   #define d4recWidth(a)                     (d4record_width(a))
   #define d4refreshRecord(a)                (d4refresh_record(a))
   #define d4seekDouble(a, b)                (d4seek_double(a, b))
   #define d4seekN(a, b, c)                  (d4seek_n(a, b, c))
   #define d4tagDefault(a)                   (d4tag_default(a))
   #define d4tagNext(a, b)                   (d4tag_next(a, b))
   #define d4tagPrev(a, b)                   (d4tag_prev(a, b))
   #define d4tagSelect(a, b)                 (d4tag_select(a, b))
   #define d4tagSelected(a)                  (d4tag_selected(a))
   #define d4writeData(a, b)                 (d4write_data(a, b))
   #define d4writeKeys(a, b)                 (d4write_keys(a, b))
   #define d4zapData(a, b, c)                (d4zap_data(a, b, c))

   #define date4formatMdx(a)                 (date4format_mdx(a))
   #define date4formatMdx2(a, b)             (date4format_mdx2(a, b))
   #define date4timeNow(a)                   (date4time_now(a))

   #define error4exitTest(a)                 (e4exit_test(a))
   #define error4code(a)                     (e4code(a))
   #define error4set(a, b)                   (e4set(a, b))

   #define expr4calcDelete(a)                (expr4calc_delete(a))
   #define expr4calcLookup(a, b, c)          (expr4calc_lookup(a, b, c))
   #define expr4calcMassage(a)               (expr4calc_massage(a))
   #define expr4calcModify(a, b)             (expr4calc_modify(a, b))
   #define expr4calcNameChange(a, b, c)      (expr4calc_name_change(a, b, c))
   #define expr4keyConvert(a, b, c, d)       (expr4key_convert(a, b, c, d))
   #define expr4keyLen(a)                    (expr4key_len(a))

   #define f4assignChar(a, b)                (f4assign_char(a, b))
   #define f4assignDouble(a, b)              (f4assign_double(a, b))
   #define f4assignField(a, b)               (f4assign_field(a, b))
   #define f4assignInt(a, b)                 (f4assign_int(a, b))
   #define f4assignLong(a, b)                (f4assign_long(a, b))
   #define f4assignN(a, b, c)                (f4assign_n(a, b, c))
   #define f4assignPtr(a)                    (f4assign_ptr(a))
   #define f4memoAssign(a, b)                (f4memo_assign(a, b))
   #define f4memoAssignN(a, b, c)            (f4memo_assign_n(a, b, c))
   #define f4memoFree(a)                     (f4memo_free(a))
   #define f4memoLen(a)                      (f4memo_len(a))
   #define f4memoNcpy(a, b, c)               (f4memo_ncpy(a, b, c))
   #define f4memoPtr(a)                      (f4memo_ptr(a))
   #define f4memoSetLen(a, b)                (f4memo_set_len(a, b))
   #define f4memoStr(a)                      (f4memo_str(a))

   #define file4lenSet(a, b)                 (file4len_set(a, b))
   #define file4lockHook(a, b, c, d, e)      (file4lock_hook(a, b, c, d, e))
   #define file4optimizeWrite(a, b)          (file4optimize_write(a, b))
   #define file4readAll(a, b, c, d)          (file4read_all(a, b, c, d))
   #define file4readError(a)                 (file4read_error(a))
   #define file4seqRead(a, b, c)             (file4seq_read(a, b, c))
   #define file4seqReadAll(a, b, c)          (file4seq_read_all(a, b, c))
   #define file4seqReadInit(a, b, c, d, e)   (file4seq_read_init(a, b, c, d, e))
   #define file4seqWrite(a, b, c)            (file4seq_write(a, b, c))
   #define file4seqWriteFlush(a)             (file4seq_write_flush(a))
   #define file4seqWriteInit(a, b, c, d, e)  (file4seq_write_init(a, b, c, d, e))
   #define file4seqWriteRepeat(a, b, c)      (file4seq_write_repeat(a, b, c))

   #define i4tagAdd(a, b)                    (i4add_tag(a, b))
   #define i4tagInfo(a)                      (i4tag_info(a))

   #define l4addAfter(a, b, c)               (l4add_after(a, b, c))
   #define l4addBefore(a, b, c)              (l4add_before(a, b, c))

   #define relate4createSlave(a, b, c, d)    (relate4create_slave(a, b, c, d))
   #define relate4doAll(a)                   (relate4do(a))
   #define relate4doOne(a)                   (relate4do_one(a))
   #define relate4errorAction(a, b)          (relate4error_action(a, b))
   #define relate4freeRelate(a, b)           (relate4free_relate(a, b))
   #define relate4matchLen(a, b)             (relate4match_len(a, b))
   #define relate4querySet(a, b)             (relate4query_set(a, b))
   #define relate4skipEnable(a, b)           (relate4skip_enable(a, b))
   #define relate4sortSet(a, b)              (relate4sort_set(a, b))
   #define sort4assignCmp(a, b)              (sort4assign_cmp(a, b))
   #define sort4getInit(a)                   (sort4get_init(a))

   #define t4uniqueSet(a, b)                 (t4unique_set(a, b))

   #define u4allocAgain(a, b, c, d)          (u4alloc_again(a, b, c, d))
   #define u4allocEr(a, b)                   (u4alloc_er(a, b))
   #define u4allocFree(a, b)                 (u4alloc_free(a, b))
   #define u4nameChar(a)                     (u4name_char(a))
   #define u4nameExt(a, b, c, d)             (u4name_ext(a, b, c, d))
   #define u4namePiece(a, b, c, d, e)        (u4name_piece(a, b, c, d, e))
   #define u4ptrEqual(a, b)                  (u4ptr_equal(a, b))


   /* CODE4 structure members that have been renamed */

   #define accessMode	exclusive
	#define OPEN4DENY_NONE 	FALSE	/* shared -- others can read and write */
	#define OPEN4DENY_WRITE	TRUE	/* shared -- others can read but not write */
                                        /* CodeBase 5.1 is not so subtle */
	#define OPEN4DENY_RW	TRUE	/* exclusive */
   #define autoOpen	auto_open
   #define readOnly	read_only
   #define errorCode	error_code
   #define lockAttempts lock_attempts


   /* DATA4 structure members now accessed via functions */

   #define d4fileName(a)	((a)->file.name)

   /* TAG4 structure members now accessed via functions */

   #define t4alias(a)		((a)->alias)
   #define t4expr(a)		((a)->expr)


#else /* CodeBase 6.x */

   /* The 5.1 construct is easier to use */

   #define t4key(a)             (tfile4key((a)->tagFile ))

#endif



/* The following constants are not defined. */

#define CB_MAX_TAGS		 47
#define CB_MAX_FIELDS		128
#define CB_MAX_STR_FIELD_LEN	254
#define CB_MAX_NUM_FIELD_LEN	 19
#define	CB_DATE_FIELD_LEN	  8
#define	CB_LOG_FIELD_LEN	  1
#define	CB_MEMO_FIELD_LEN	 10


#if defined(CB_ENABLE_TRACING)
FILE	*cb_trace_file = NULL;
int	cb_trace_level = 0;
#define CB_TRACE(level, args)		if (cb_trace_level >= (level)) { cb_trace args; } else
#define CB_DUMP(level,psv, limit)	if (cb_trace_level >= (level)) { cb_dump(psv, limit); } else
#else
#define CB_TRACE(level, args)
#define CB_DUMP(level, psv, limit)
#endif


#define SELF		SvPV(ST(0),na)


/* STREQ and SUBSTREQ define tests for equality of two strings and two
   substrings respectively. */

#define STREQ(a, b)		(strcmp((a), (b)) == 0)
#define SUBSTREQ(a, b, n)	(strncmp((a), (b), (n)) == 0)
#define ISTREQ(a, b)		(strcasecmp((a), (b)) == 0)
#define ISUBSTREQ(a, b, n)	(strncasecmp((a), (b), (n)) == 0)


#ifndef MAX
    #define MAX(x,y)		((x) >= (y) ? (x) : (y))
#endif
#ifndef MIN
    #define MIN(x,y)		((x) <  (y) ? (x) : (y))
#endif
#ifndef ABS
    #define ABS(x)		((x) >=  0  ? (x) : -(x))
#endif


#define CB_SUCCESS			0
#define CB_ERROR_START			10000
#define CB_ERR_INVALID_USAGE		(CB_ERROR_START + 1)
#define CB_ERR_TOO_MANY_FIELDS		(CB_ERROR_START + 2)
#define CB_ERR_INVALID_FIELDTYPE	(CB_ERROR_START + 3)
#define CB_ERR_BAD_HANDLE		(CB_ERROR_START + 4)


/* TYPE DEFINITIONS
 *
 * FCB is a "file control block" containing a pointer to a CodeBase
 * DATA4 file control structure, and a reference count.  Queries also 
 * store pointers to file control blocks, so reference counting has to
 * be done to prevent the files being closed early.
 */

typedef int	Boolean;

typedef struct {
    DATA4	*data4;
    int         refcount;
} FCB;
typedef FCB	CodeBase__File;
typedef FCB     CodeBase__Record;

typedef struct {
    enum { Q_FCB, Q_REL } type;
    enum { Q_UNDEFINED, Q_AT_START, Q_INPROGRESS, Q_AT_END } status;
    Boolean          descending;
    RELATE4          *rel;
    FCB              *fcb;
} CodeBase__Query;

static int	active_fcbs = 0;	/* Count of active FCBs */
static int	cb_exiting = 0;		/* Flag that we are exiting */
static CODE4	cb_state;		/* CodeBase state structure. */
static int	cb_errno;		/* CodeBase error number */
static Boolean	cb_trim_option = FALSE;


/* Some operating systems have not always had str[n]casecmp */

#if defined(NEED_STRCASECMP)
#define strcasecmp(a,b)     cb_strcasecmp(a,b) 
#define strncasecmp(a,b,n)  cb_strncasecmp(a,b,n) 

/*
 *  Case insensitive comparison of two strings
 */
int
cb_strcasecmp(const char *s1, const char *s2)
{
    for (;; s1++, s2++) 
    {
	register char	c1 = tolower(*s1);
	register char	c2 = tolower(*s2);
	
	if (c1 != c2 || c1 == 0) 
	{
	    return (c1 - c2);
	}
    }
    return 0;
}

/*
 *  Case insensitive comparison of first n chars of two strings
 */
int
cb_strncasecmp(const char *s1, const char *s2, size_t n)
{
    for (;n-- > 0; s1++, s2++) 
    {
	register char	c1 = tolower(*s1);
	register char	c2 = tolower(*s2);
	
	if (c1 != c2 || c1 == 0) 
	{
	    return (c1 - c2);
	}
    }
    return 0;
}


#endif /* defined(NEED_STRCASECMP) */


#if defined(CB_ENABLE_TRACING)
static void
cb_trace(char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	if (cb_trace_file == NULL)
	{
	    cb_trace_file = stderr;
	    
	}
	vfprintf(cb_trace_file, format, ap);
	va_end(ap);
}

static void
cb_dump(void *sv, int limit)
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    PUSHs((SV *)sv);
    PUSHs(sv_2mortal(newSViv(limit)));
    PUTBACK;
    perl_call_pv("Devel::Peek::Dump", G_DISCARD);
}
#endif


/* Return the effective length of a field. */

static int
field_len(FIELD4 *field)
{
    int  flen = f4memoLen(field);
   
    if (cb_trim_option)
    {
        char	*sptr = f4memoPtr(field);
	char    *eptr = sptr + flen;

	while (eptr > sptr && isspace(*(eptr-1))) { eptr--; }
	flen = eptr - sptr;
   }
   return flen;
}



static Boolean
set_field_value(FIELD4 *field, SV *value)
{
 /* static	days_per_month[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }; */
    char	*str_param;
    Boolean	retval = TRUE;
    size_t	param_len;
    char	field_type = f4type(field);
    char	logical_val;
    char	time_buf[16];
    long	time_now;
    Boolean	relative_date;
    long	relative_offset;
    struct tm	*tm;

    switch (field_type)
    {
    case r4str:
	str_param = SvPV(value,	param_len);
	f4assignN(field, str_param, param_len);
	break;

    case r4date:	    
	str_param = SvPV(value, param_len);
	relative_date   = FALSE;
	relative_offset = 0;
	if      (ISTREQ(str_param, "TODAY"))
	{
	    relative_date = TRUE;
	}
	else if (ISTREQ(str_param, "YESTERDAY"))
	{
	    relative_date   = TRUE;
	    relative_offset = -1;
	}
	else if (ISTREQ(str_param, "TOMORROW"))
	{
	    relative_date   = TRUE;
	    relative_offset = 1;
	}
	else if ((str_param[0] == '+') || (str_param[0] == '-'))
	{
	    relative_date   = TRUE;
	    relative_offset = strtol(str_param, NULL, 10);
	}
	if (relative_date)
	{
	    time(&time_now);
	    if (   (relative_offset < 0)
		&& (-relative_offset > (time_now / 86400)))
	    {
		time_now = 0;
	    }
	    else if (   (relative_offset > 0)
		     && (relative_offset > (LONG_MAX - time_now) / 86400))
	    {
		time_now = LONG_MAX;
	    }
	    else
	    {
	    	time_now += relative_offset * 86400;
	    }
	    tm = localtime(&time_now);
	    sprintf(time_buf, "%04d%02d%02d", 
		    tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday);
	    str_param = time_buf;
	    param_len = 8;
	}
	f4assignN(field, str_param, param_len);
	break;

    case r4log:
	str_param = SvPV(value, na);
	logical_val = str_param[0];
	f4assignChar(field, logical_val);
	break;

    case r4memo:
	str_param = SvPV(value, param_len);
	f4memoAssignN(field, str_param, param_len);
	break;

    case r4num:
	f4assignDouble(field, SvNV(value));
	break;
    
    default:
	break;
    }
    return retval;
}


/* Codebase callback to set the error code. 
 * Note the name and parameters changed between CodeBase 5.1 and 6.x
 */

#if S4VERSION < 6000
void
e4hook(CODE4 *c4, int err_code, char *desc1, char *desc2, char *desc3)
{
    CB_TRACE(1, ("e4hook(%d, \"%s\", \"%s\", \"%s\") errno=%d\n", 
		 err_code, desc1, desc2, desc3, cb_state.errorCode));
    cb_errno = err_code;
}
#else
void 
error4hook(CODE4 *c4, int err_code, long err_code2, 
	   const char *desc1, const char *desc2, const char *desc3)
{
    CB_TRACE(1, ("error4hook(%d, \"%s\", \"%s\", \"%s\") errno=%d\n", 
		 err_code, desc1, desc2, desc3, cb_state.errorCode));
    cb_errno = err_code;
    error4set(&cb_state, 0);
}
#endif


/*****************************************************************************
**                                                                          **
**    XSUBS                                                                 **
**                                                                          **
*****************************************************************************/

void 
cb_uninit(void)
{
    if (active_fcbs) {
        cb_exiting = 1;
    }
    else {
        code4initUndo(&cb_state);
    }
}

/* An FCB refers to a CodeBase DATA4 structure, but it may be in use
 * in a number of places (i.e. as the value returned from a query), so
 * a reference count is maintained and the file only closed when it
 * reaches zero.  If that happens and the program is exiting, then
 * cb_uninit is called to ensure the transaction log (for CodeBase 6) is
 * closed properly.
 */
void
close_fcb(FCB *fcb) 
{
    if (--fcb->refcount == 0) {
        d4close(fcb->data4);
	free(fcb);
	if (--active_fcbs == 0 && cb_exiting) {
	    cb_uninit();
	}
    }
}




MODULE = CodeBase		PACKAGE = CodeBase

PROTOTYPES:	ENABLE

BOOT:
	code4init(&cb_state);
	atexit(cb_uninit);


##############################################################################
#
# CONSTRUCTORS: open and create
#
# $file = CodeBase::open("filename", $option, ...)
#	Open file / constructor function - opens the specified file

CodeBase::File *
open(filename, ...)
    char	*filename

 PREINIT:
    char	*option;
    int		option_no;

 CODE:
    CB_TRACE(1, ("open(\"%s\")\n", filename));
    cb_errno = CB_SUCCESS;
    cb_state.accessMode = OPEN4DENY_NONE;
    cb_state.autoOpen   = TRUE;
    cb_state.readOnly   = FALSE;
    if (items > 1)
    {
	for (option_no = 1; option_no < items; option_no++)
	{
	    option = (char *)SvPV(ST(option_no), na);
	    if (   (strcasecmp(option, "readonly") == 0)
		|| (strcasecmp(option, "ro") == 0))
	    {
		CB_TRACE(1, ("  open: readonly\n"));
		cb_state.readOnly = TRUE;
	    }
	    else if (   ISTREQ(option, "no_index")
		     || ISTREQ(option, "noindex"))
	    {
		CB_TRACE(1, ("  open: noindex\n"));
		cb_state.autoOpen = FALSE;
	    }
	    else if (   (strcasecmp(option, "exclusive") == 0)
		     || (strcasecmp(option, "x") == 0))
	    {
		CB_TRACE(1, ("  open: exclusive\n"));
		cb_state.accessMode = OPEN4DENY_RW;
	    }
	}	    
    }
   
    if (!(RETVAL = malloc(sizeof(FCB)))) {
        croak("out of memory");
    }
    RETVAL->refcount = 1;
    RETVAL->data4 = d4open(&cb_state, filename);
    cb_state.accessMode = OPEN4DENY_NONE;
    cb_state.autoOpen   = TRUE;
    cb_state.readOnly   = FALSE;
    if (RETVAL->data4 == NULL) {
        free(RETVAL);
        XSRETURN_UNDEF;
    }
    active_fcbs++;
    CB_TRACE(1, ("open returns %p (errno = %d/%d)\n", RETVAL, cb_errno, cb_state.errorCode));

 OUTPUT:
    RETVAL


# $fh = CodeBase::create($file, @fielddefs)
# $fh = CodeBase::create($file, $fielddefref, $tagdefref)

CodeBase::File *
create(filename, ...)
    char	*filename

 PREINIT:
    int		arg_no;
    int		field_no;
    FIELD4INFO	field_info[CB_MAX_FIELDS + 1];
    FIELD4INFO  *fip;
    long	field_len;
    long	n_decimals;
    char	*spec;

 CODE:
    CB_TRACE(1, ("create(\"%s\")\n", filename));
    cb_errno = CB_SUCCESS;

    /* There should be at least one field, i.e. at least three items
     * and the number of items should be odd.
     */
    if (items < 3 || ((items - 1) & 1))
    {
	cb_errno = CB_ERR_INVALID_USAGE;
	XSRETURN_UNDEF;
    }

    /* Loop through the pairs of parameters building up the field info
     * array.
     */
    for (arg_no = 1, field_no = 0, fip = field_info;
	 arg_no < items && field_no < CB_MAX_FIELDS;
	 arg_no += 2, field_no++, fip++)
    {
	fip->name = SvPV(ST(arg_no), na);
	spec      = SvPV(ST(arg_no+1), na);

	CB_TRACE(1, ("    \"%-10s\"  %s\n", fip->name, spec));

	fip->type = *spec++;
	fip->len  = 0;
	fip->dec  = 0;

	switch (fip->type)
	{
        case r4str:
	    if (   !isdigit(*spec)
		|| ((fip->len = strtol(spec, &spec, 10)) > CB_MAX_STR_FIELD_LEN))
	    {
		CB_TRACE(1, ("Invalid string field\n"));
		cb_errno = CB_ERR_INVALID_FIELDTYPE;
	    }
	    break;
	    
	case r4date:
	    fip->len = CB_DATE_FIELD_LEN;
	    break;

	case r4log:
	    fip->len = CB_LOG_FIELD_LEN;
	    break;
	    
	case r4memo:
	    fip->len = CB_MEMO_FIELD_LEN;
	    break;
	
	case r4num:
	case 'F':
            n_decimals = 0;
	    if (   !isdigit(*spec)
		|| ((field_len = strtol(spec, &spec, 10)) < 0)
		|| (field_len > CB_MAX_NUM_FIELD_LEN)
		|| (   (*spec == '.')
		    && (   ((n_decimals = strtol(++spec, &spec, 10)) < 0)
			|| (n_decimals > field_len - 2))))
	    {
		CB_TRACE(1, ("Invalid numeric field\n"));
		cb_errno = CB_ERR_INVALID_FIELDTYPE;	    
	    }
	    else 
	    {
                fip->len = field_len;
		fip->dec  = n_decimals;
            }
	    break;

	default:
	    CB_TRACE(1, ("Invalid field type\n"));
	    cb_errno = CB_ERR_INVALID_FIELDTYPE;
	}
	
	if (cb_errno)
	{
	    XSRETURN_UNDEF;
	}
    }
    fip->name = 0;
    fip->type = 0;
    fip->len  = 0;
    fip->dec  = 0;
    
    cb_state.accessMode = OPEN4DENY_RW;
    cb_state.readOnly   = FALSE;
    if (!(RETVAL = malloc(sizeof(FCB)))) {
        croak("out of memory");
    }
    RETVAL->refcount = 1;
    RETVAL->data4 = d4create(&cb_state, filename, field_info, NULL);
    cb_state.autoOpen = TRUE;
    cb_state.accessMode = OPEN4DENY_NONE;
    if (RETVAL->data4 == NULL) {
        free(RETVAL);
        XSRETURN_UNDEF;
    }
    active_fcbs++;
    CB_TRACE(1, ("create returns %p\n", RETVAL));

 OUTPUT:
    RETVAL


#if S4VERSION >= 6000

MODULE = CodeBase		PACKAGE = CodeBase::Log

void
open(filename=NULL, username=NULL)
    char	*filename
    char	*username

 CODE:
    if (code4logOpen(&cb_state, filename, username) != r4success) {
	XSRETURN_UNDEF;
    }
    XSRETURN_YES;


void
create(filename=NULL, username=NULL)
    char	*filename
    char	*username

 CODE:
    if (code4logCreate(&cb_state, filename, username) != r4success) {
	XSRETURN_UNDEF;
    }
    XSRETURN_YES;


char *
filename()

 CODE:
    (const char *)RETVAL = code4logFileName(&cb_state);

 OUTPUT:
    RETVAL



MODULE = CodeBase		PACKAGE = CodeBase::Transaction

int
status(void)

 CODE:
    RETVAL = code4tranStatus(&cb_state);

 OUTPUT:
    RETVAL


void
start(void)

 CODE:
    if (code4tranStart(&cb_state) != r4success)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
commit(void)

 CODE:
    if (code4tranCommit(&cb_state) != r4success)
        XSRETURN_UNDEF;
    XSRETURN_YES;

void
rollback(void)

 CODE:
    if (code4tranRollback(&cb_state) != r4success)
        XSRETURN_UNDEF;
    XSRETURN_YES;

#endif



##############################################################################
#
# File oriented methods
#
#	alias
#	filename
#	reccount
#	recsize
#	flush
# 	refresh
# 	lock
# 	unlock
# 	pack
#	DESTROY


MODULE = CodeBase		PACKAGE = CodeBase::FilePtr

# $alias = $fh->alias([$newalias])

char *
alias(self, newalias=NULL)
    CodeBase::File      *self
    char                *newalias

 CODE:
    if (newalias != NULL && newalias[0] != '\0') {
	d4aliasSet(self->data4, newalias);
    }
    RETVAL = (char *)d4alias(self->data4);

 OUTPUT:
    RETVAL


char *
filename(self)
    CodeBase::File      *self

 CODE:
    RETVAL = (char *)d4fileName(self->data4);

 OUTPUT:
    RETVAL


# $reccount = $file->reccount();
#
int
reccount(self)
    CodeBase::File	*self
    
 CODE:
    CB_TRACE(1, ("reccount(%s)\n", SvPV(ST(0),na)));
    cb_errno = CB_SUCCESS;
    RETVAL = d4recCount(self->data4);
    if (RETVAL < 0)
    {
	cb_errno = RETVAL;
	XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("reccount returns %d\n", RETVAL));

 OUTPUT:
    RETVAL
    

# $recwidth = $file->recsize();
#
int
recsize(self)
    CodeBase::File	*self
    
 CODE:
    CB_TRACE(1, ("recsize(%s)\n", SvPV(ST(0),na)));
    cb_errno = CB_SUCCESS;
    RETVAL = d4recWidth(self->data4);
    if (RETVAL < 0)
    {
	cb_errno = RETVAL;
	XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("recsize returns %d\n", RETVAL));

 OUTPUT:
    RETVAL


# $file->flush([$tries])
#	flushes the data file an its index and memo files to disk
#	calls d4flush, which returns 0, r4locked or r4unique.
void
flush(self, ...)
    CodeBase::File	*self

 PREINIT:
 /* int		tries; */

 CODE:
    CB_TRACE(1, ("flush(\"%s\")\n",  SELF));
    cb_errno = d4flush(self->data4);
    if (cb_errno)
    {
        CB_TRACE(1, ("flush returns (errno = %d)\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("flush returns OK\n"));
    XSRETURN_YES;


# $file->refresh([$tries])

void
refresh(self, ...)
    CodeBase::File	*self

 PREINIT:
 /* int		tries; */

 CODE:
    CB_TRACE(1, ("refresh(\"%s\")\n",  SELF));
    cb_errno = d4refresh(self->data4);
    if (cb_errno)
    {
        CB_TRACE(1, ("refresh returns (errno = %d)\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("refresh returns OK\n"));
    XSRETURN_YES;



# $rc = $file->lock($what, $tries)
#
void
lock(self, what=".", tries=5)
    CodeBase::File	*self
    char	*what
    int		tries

 PREINIT:
    int		saved_attempts = cb_state.lockAttempts;
    long	recno;
    int		retval;

 CODE:
    CB_TRACE(1, ("lock(\"%s\", what=\"%s\", tries=%d)\n",  SELF, what, tries));
    cb_errno = CB_SUCCESS;
    cb_state.lockAttempts = tries;

    if (ISTREQ(what, "FILE"))
    {
        retval = d4lockAll(self->data4);
    }
    else
    {
        if (STREQ(what, "."))
        {
    	    recno = d4recNo(self->data4);
        }
        else
        {
	    recno = SvIV(ST(1));
        }
        retval = (d4lock(self->data4, recno) == 0);
    }

    cb_state.lockAttempts = saved_attempts;
    if (retval != 0)
    {
        cb_errno = retval;
        CB_TRACE(1, ("lock returns error %d\n", retval));
	XSRETURN_UNDEF;
    }

    CB_TRACE(1, ("lock returns OK\n"));
    XSRETURN_YES;



# $rc = $file->unlock()
#
void
unlock(self)
    CodeBase::File	*self

 CODE:
    CB_TRACE(1, ("unlock(\"%s\")\n", SELF));
    cb_errno = d4unlock(self->data4);
    if (cb_errno)
    {
        CB_TRACE(1, ("unlock returns (errno = %d)\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("unlock returns OK\n"));
    XSRETURN_YES;


# $file->pack([$compress_memo])
#	Pack removes all deleted reocords from the data file
#	and also reindexes open index files. an its index and memo files to disk
#	Calls d4pack, which returns 0, r4locked, r4unique or an error code < 0.
void
pack(self, compress_memo = FALSE)
    CodeBase::File	*self
    Boolean	compress_memo

 CODE:
    CB_TRACE(1, ("pack(\"%s\", %s)\n",  SELF, compress_memo ? "TRUE" : "FALSE"));
    cb_errno = CB_SUCCESS;
    if (   (d4pack(self->data4) != 0)
	|| (compress_memo
	    && (d4memoCompress(self->data4) != 0)))
    {
	CB_TRACE(1, ("pack returns error %d\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("close returns OK\n"));
    XSRETURN_YES;


void
zap(self, from, to, compress_memo=0)
    CodeBase::File      *self
    long                from
    long                to
    int                 compress_memo

 PREINIT:
    int			rc;

 CODE:
    if (from < 1 || to < 1 || from > to) {
        XSRETURN_UNDEF;
    }
    rc = d4zap(self->data4, from, to);
    if (rc == r4success || rc == r4unique) {
         if (compress_memo 
             && d4memoCompress(self->data4) != r4success) {
                XSRETURN_UNDEF;
         } 
    }
    XSRETURN_YES;


# Destructor function - closes the file

void
DESTROY(self)
    CodeBase::File	*self

 CODE:
    CB_TRACE(1, ("DESTROY(\"%s\")\n",  SELF));
    close_fcb(self);
    CB_TRACE(1, ("DESTROY returns (errno = %d)\n", cb_errno));

    


##############################################################################
#
# Record oriented functions:
#
#	recno
#	position
#	goto RECNO
#	skip COUNT
#	bof
#	eof
#	deleted
#	delete_record [ RECNO ]
#	new_record VALUES
#	replace_record VALUES

MODULE = CodeBase		PACKAGE = CodeBase::RecordPtr


# $recno = $file->recno();
#
int
recno(self)
    CodeBase::Record	*self
    
 CODE:
    CB_TRACE(1, ("recno(%s)\n", SvPV(ST(0),na)));
    cb_errno = CB_SUCCESS;
    RETVAL = d4recNo(self->data4);
    if (RETVAL < 0)
    {
	cb_errno = RETVAL;
	CB_TRACE(1, ("recno returns %d\n", RETVAL));
	XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("recno returns %d\n", RETVAL));

 OUTPUT:
    RETVAL
    


##############################################################################

# $pos = $fh->position([$pos])

double
position(self, ...)
    CodeBase::Record	*self

 PREINIT:
    double 		position;

 CODE:
    if (items > 1) 
    {
	position = SvNV(ST(1));
	if (position < 0) {
            position = 0;
        }
        else if (position > 1) {
            position = 1;
        }
	if (d4positionSet(self->data4, position) < 0) {
            XSRETURN_UNDEF;
        }
    }
    RETVAL = d4position(self->data4);

 OUTPUT:
    RETVAL



# $recno = $file->goto($recno)
# recno is numeric or TOP (or START or FIRST) or BOTTOM (or END or LAST)
# 
void
goto(self, recno)
    CodeBase::Record	*self
    SV			*recno;
    
 PREINIT:
    char	*recno_str;
    char	first_char;
    int		retval;

 CODE:
    cb_errno = CB_SUCCESS;
    recno_str = SvPV(recno, na);
    first_char = toupper(*recno_str);

    CB_TRACE(1, ("goto(\"%s\", %s)\n", SELF, recno_str));


    switch (first_char)
    {
    case 'T': /* Top */
    case 'S': /* Start */
    case 'F': /* First */
    case '<':
	retval = d4top(self->data4);
        break;

    case 'B': /* Bottom */
    case 'E': /* End */
    case 'L': /* Last */
    case '>': 
	retval = d4bottom(self->data4);
	break;
	
    default:
	retval = d4go(self->data4, SvIV(recno));
    }

    if (retval != 0)
    {
	if (retval > 0)
	{
	    cb_errno = retval;
	}
	CB_TRACE(1, ("goto returns error %d\n", cb_errno));
	XSRETURN_UNDEF;
    }
    
    CB_TRACE(1, ("goto returns OK\n"));
    XSRETURN_YES;



# $file->skip();
#	Skip forwards or backwards by a specified number of records in the order
#	of the current index (if one is open).  If n_recs is omitted then skip
#	moves forward one record.  The number of the new current record is returned.
#
#	This routine is equivalent to the dBASE SKIP command.
long
skip(self, n_recs=1)
    CodeBase::Record	*self
    int			n_recs

 CODE:
    CB_TRACE(1, ("skip(\"%s\", %d)\n", SELF, n_recs));
    cb_errno = CB_SUCCESS;

    RETVAL = d4skip(self->data4, n_recs);
    if (RETVAL != 0)
    {
	if (RETVAL > 0)
	{
	    cb_errno = RETVAL;
	}
	CB_TRACE(1, ("skip returns error %d\n", cb_errno));
	XSRETURN_UNDEF;
    }

    RETVAL = d4recNo(self->data4);
    CB_TRACE(1, ("skip returned %d\n", RETVAL));

 OUTPUT:
    RETVAL



# $file->bof();
# 	Test for beginning of file
void
bof(self)
    CodeBase::Record	*self

 CODE:
    cb_errno = CB_SUCCESS;
    if(d4bof(self->data4) <= 0)
    {
	XSRETURN_UNDEF;
    }
    XSRETURN_YES;



# $file->eof();
# 	Test for end of file
void
eof(self)
    CodeBase::Record	*self

 CODE:
    cb_errno = CB_SUCCESS;
    if (d4eof(self->data4) <= 0)
    {
	XSRETURN_UNDEF;
    }
    XSRETURN_YES;
    


# $file->deleted();
# 	Test whether a record is deleted
int
deleted(self, ...)
    CodeBase::Record	*self

 CODE:
    cb_errno = CB_SUCCESS;
    RETVAL = d4deleted(self->data4);

 OUTPUT:
    RETVAL



# $file->delete_record();
# 	Delete a record
void
delete_record(self, ...)
    CodeBase::Record	*self

 PREINIT:
    int		rec_no;

 CODE:
    CB_TRACE(1, ("delete_record(\"%s\"\n", SELF));
    cb_errno = CB_SUCCESS;
    if (items > 1)
    {
	rec_no = SvIV(ST(1));
	if (d4go(self->data4, rec_no) < 0)
	{
	    XSRETURN_UNDEF;
	}
    }
    d4delete(self->data4);
    CB_TRACE(1, ("delete_record returns OK\n"));
    XSRETURN_YES;



# $rc = $file->new_record(@values);
#	Create a new record with the field values specified.
#	Values must be supplied for all fields in the order in which the fields occur
#	in the record.  Note: Perl will silently  convert data from string to numeric
#	or vice versa.

Boolean
new_record(self, ...)
     CodeBase::Record	*self

 PREINIT:
    int		n_fields;
    int		field_no;
    HV		*hash = NULL;

 CODE:    
    CB_TRACE(1, ("new_record(\"%s\"", SELF));
    cb_errno = CB_SUCCESS;

    n_fields = d4numFields(self->data4);
    
    /* If there are only two arguments and the second is a hash then that argument is 
     * a hash of name--value pairs, which is not necessarily a complete set of fields.
     */
    if (items == 2 && SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV))
    {
	hash = (HV *)SvRV(ST(1));
    }
    else if (items - 1 < n_fields)
    {
	cb_errno = CB_ERR_INVALID_USAGE;
	CB_TRACE(1, ("...\nnew_record returns error %d (Too few fields, %d should be %d)\n",
		     cb_errno, items, n_fields + 1));
	XSRETURN_UNDEF;
    }

    /* Start a new record and ensure that it doesn't inherit the
     * record deletion flag state from the current record.  
     */

    cb_errno = d4appendStart(self->data4, FALSE);
    if (cb_errno)
    {
	CB_TRACE(1, ("...\nnew_record returns error %d (starting append)\n", cb_errno));
	XSRETURN_UNDEF;
    }

    /* If a hash was passed as the second argument, call d4blank as not all fields
     * will necessarily be set, otherwise there is no need because all field values
     * will be set.
     */
    if (hash)
    {
	d4blank(self->data4);
    }

    d4recall(self->data4);	/* Ensure the deletion mark is not set */

    if (hash == NULL)
    {
	/* from 1 .. n_fields!! */

	for (field_no = 1; field_no <= n_fields; field_no++) 
	{
	    CB_TRACE(1, (", %s", SvPV(ST(field_no), na)));
	    set_field_value(d4fieldJ(self->data4, field_no), ST(field_no));
	    if (cb_errno < 0)
            {
	       CB_TRACE(1, (") errno %d\n", cb_errno));
  	       XSRETURN_UNDEF;
            }
	}
    }
    else
    {
	char	field_name[12];
	char	*key;
	I32	keylen;
    	SV	*value;
	FIELD4	*field;

	for (hv_iterinit(hash); (value = hv_iternextsv(hash, &key, &keylen)); )
	{
	    strncpy(field_name, key, 11);
	    CB_TRACE(1, (", %s => %s", field_name, SvPV(value, na)));
	    
	    field = d4field(self->data4, field_name);
	    if (field == NULL)
	    {
		field_no = atoi(field_name);
		if ((field_no > 0) && (field_no <= n_fields))
		{
		    field = d4fieldJ(self->data4, field_no);
		}
	    }
	    if (field != NULL)
	    {
		set_field_value(field, value);
	    }
	    else if (cb_errno < 0)
            {
	       CB_TRACE(1, (") errno %d\n", cb_errno));
  	       XSRETURN_UNDEF;
            }

	}
    }
    CB_TRACE(1, (")\n"));

    cb_errno = d4append(self->data4);
    if (cb_errno)
    {
	CB_TRACE(1, ("new_record returns error %d\n", cb_errno));
	XSRETURN_UNDEF;
    }
    RETVAL = TRUE;
    CB_TRACE(1, ("new_record returns OK\n"));

 OUTPUT:
    RETVAL



# $rc = $file->replace_record(@field_values);
#	Replace the current record with the field values specified.
#
void
replace_record(self, ...)
    CodeBase::Record	*self

 PREINIT:
    int		n_fields;
    int		field_no;

 CODE:
    CB_TRACE(1, ("replace_record(\"%s\"", SELF));
    cb_errno = CB_SUCCESS;

    n_fields = d4numFields(self->data4);

    /* If there are only two arguments and the second is a hash then that argument is 
     * a hash of name--value pairs, which is not necessarily a complete set of fields.
     */
    if (d4recNo(self->data4) <= 0)
    {
	cb_errno = CB_ERR_INVALID_USAGE;
	CB_TRACE(1, ("...\nreplace_record returns %d\n", cb_errno));
	XSRETURN_UNDEF;
    }
    else if (items == 2 && SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV))
    {
	HV	*hash = (HV *)SvRV(ST(1));
	char	field_name[12];
	char	*key;
	I32	keylen;
    	SV	*value;
	FIELD4	*field;

	for (hv_iterinit(hash); (value = hv_iternextsv(hash, &key, &keylen)); )
	{
	    strncpy(field_name, key, 11);
	    CB_TRACE(1, (", %s => %s", field_name, SvPV(value, na)));
	    
	    field = d4field(self->data4, field_name);
	    if (field == NULL)
	    {
		field_no = atoi(field_name);
		if ((field_no > 0) && (field_no <= n_fields))
		{
		    field = d4fieldJ(self->data4, field_no);
		}
	    }
	    if (field != NULL)
	    {
		set_field_value(field, value);
	    }
	}
    }
    else
    {
	if (items - 1 < n_fields)
	{
	    cb_errno = CB_ERR_INVALID_USAGE;
	    CB_TRACE(1, ("...\nreplace_record returns %d\n", cb_errno));
	    XSRETURN_UNDEF;
	}

	/* from 1 .. n_fields!! */

	for (field_no = 1; field_no <= n_fields; field_no++) 
	{
	    CB_TRACE(1, (", %s", SvPV(ST(field_no), na)));
	    if (!set_field_value(d4fieldJ(self->data4, field_no), ST(field_no)))
	    {
		CB_TRACE(1, ("...\nreplace_record returns %d\n", cb_errno));
		XSRETURN_UNDEF;
	    }
	}
    }

    CB_TRACE(1, (")\nreplace_record returns OK\n"));
    XSRETURN_YES;


##############################################################################
#
# Field handling functions
#
#	fldcount
#	fieldinfo
#	names
#	type
#	fields
#	field($name)
#	set_field(name, value)

MODULE = CodeBase		PACKAGE = CodeBase::RecordPtr

# $fieldcount = $file->fldcount;
# 	Returns the number of fields
int
fldcount(self)
    CodeBase::Record	*self

 CODE:
    CB_TRACE(1, ("fldcount(\"%s\"\n", SELF));
    cb_errno = CB_SUCCESS;
    RETVAL = d4numFields(self->data4);
    CB_TRACE(1, ("fldcount returns %d\n", RETVAL));

 OUTPUT:
    RETVAL



# @fieldinfo = $file->fieldinfo();
# 	Returns a field info array suitable for use in creating a new 
#	database file.  This consists of alternating field name and type values.
void
fieldinfo(self)
     CodeBase::Record	*self

 PREINIT:
    int 	field_no;
    char	buffer[256];
    FIELD4	*field;
    char	field_type;
    int		n_fields;
	
 PPCODE:
    CB_TRACE(1, ("fieldinfo(\"%s\")\n", SELF));
    CB_TRACE(1, ("fieldinfo returns ("));
    cb_errno = CB_SUCCESS;

    n_fields = d4numFields(self->data4);
    
    EXTEND(sp, 2 * n_fields);

    for (field_no = 1; field_no <= n_fields; field_no++) 
    {
	field = d4fieldJ(self->data4, field_no);

	CB_TRACE(1, ("%s\"%s\"", (field_no > 1) ? ", " : "", f4name(field)));

	PUSHs(sv_2mortal(newSVpv((char *)f4name(field), 0)));

	switch (field_type = f4type(field))
	{
	case r4str:	    
	case r4date:	    
	case r4memo:
	    sprintf(buffer, "%c%d", field_type, f4len(field));
	    break;
		
	case r4num:
	    sprintf(buffer, "N%d.%d", f4len(field), f4decimals(field));
	    break;
		    
	default:
	    buffer[0] = field_type;
	    buffer[1] = '\0';
	    break;
	}
	CB_TRACE(1, ("=> \"%s\"", buffer));
	PUSHs(sv_2mortal(newSVpv(buffer, 0)));
    }
    CB_TRACE(1, (")\n"));


# @names = $file->names;
# 	Returns an array of field names
void
names(self)
    CodeBase::Record	*self

 PREINIT:
    const FIELD4	*field;
    const char		*field_name;
    int			field_no, n_fields;

 PPCODE:
    CB_TRACE(1, ("names(\"%s\"\n", SELF));
    cb_errno = CB_SUCCESS;
    n_fields = d4numFields(self->data4);
    CB_TRACE(1, ("names returns ("));
    EXTEND(sp, n_fields);
    for (field_no = 1; field_no <= n_fields; field_no++)
    {
	field      = d4fieldJ(self->data4, field_no);
	field_name = f4name(field);
	PUSHs(sv_2mortal(newSVpv((char *)field_name, 0)));
	CB_TRACE(1, ("%s%s", (field_no > 1 ? ", " : ""), field_name));
    }
    CB_TRACE(1, (")\n"));


    
# $type = $file->type($field_name);
#	Returns the type of a field. 
char *
type(self, name)
    CodeBase::Record	*self
    char	*name

 PREINIT:
    FIELD4	*field;
    char	field_type;
    char	buffer[256];

 CODE:
    CB_TRACE(1, ("type(\"%s\", \"%s\")\n", SELF, name));
    cb_errno = CB_SUCCESS;

    field = d4field(self->data4, name);
    if (field == NULL)
    {
	cb_errno = CB_ERR_INVALID_USAGE;
	XSRETURN_UNDEF;
    }

    switch (field_type = f4type(field))
    {
    case r4str:	    
    case r4date:	    
    case r4memo:
	sprintf(buffer, "%c%d", field_type, f4len(field));
	break;
	
    case r4num:
	sprintf(buffer, "N%d.%d", f4len(field), f4decimals(field));
	break;
		    
    default:
	buffer[0] = field_type;
	buffer[1] = '\0';
	break;
    }
    RETVAL = buffer;
    CB_TRACE(1, ("type returns \"%s\"\n", buffer));

 OUTPUT:
    RETVAL




# @fields = $file->fields([$field_name ...]);
#	Returns a list of field values.  If any field names are specified, the values of those
#	fields are returned in the order of the names, otherwise the values of all fields are
#	returned in the order they occur within a record.
void
fields(self, ...)
    CodeBase::Record	*self

 PREINIT:
    FIELD4	*field;
    int 	field_no;
    char	buffer[256];
    char	fieldtype;
    Boolean	only_named_fields = (items > 1);
    int		n_fields;

 PPCODE:
    CB_TRACE(1, ("values(\"%s\")\n", SvPV(ST(0),na)));
    CB_TRACE(1, ("values returns ("));
    cb_errno = CB_SUCCESS;
    n_fields = (only_named_fields ? items - 1 : d4numFields(self->data4));

    EXTEND(sp, n_fields);
    for (field_no = 1; field_no <= n_fields; field_no++) 
    {
	if (!only_named_fields) 
	{
	    field = d4fieldJ(self->data4, field_no);
	}
	else if (   SvOK(ST(field_no))
		 || ((field = d4field(self->data4, SvPV(ST(field_no), na))) == NULL))
	{
	    PUSHs(sv_newmortal());
	    continue;
	}

	switch (fieldtype = f4type(field))
	{
	case r4str:	    
	case r4date:	    
	case r4log:
	    CB_TRACE(1, ("%s\"%.*s\"", (field_no > 1 ? ", " : ""), 
			 field_len(field), f4ptr(field)));
	    XPUSHs(sv_2mortal(newSVpv(f4ptr(field), field_len(field))));
	    break;
		
	case r4memo:
	    CB_TRACE(1, ("%s\"%.*s\"", (field_no > 1 ? ", " : ""), 
			 field_len(field), f4memoPtr(field)));
	    XPUSHs(sv_2mortal(newSVpv(f4memoPtr(field), field_len(field))));
	    break;

	case r4num:
	    CB_TRACE(1, ("%s%f", (field_no > 1 ? ", " : ""), f4double(field)));
	    XPUSHs(sv_2mortal(newSVnv(f4double(field))));
	    break;
		    
	default:
	    buffer[0] = fieldtype;
	    buffer[1] = '\0';
	    break;
	}
    }
    CB_TRACE(1, (")\n"));





# $field = $file->field("field_name");
#
#	Interprete the second parameter as a field name.  If there is no field
#       of that name, try it as a field number.
#
void
field(self, field_name)
    CodeBase::Record	*self
    char	*field_name

 PREINIT:
    FIELD4	*field;
    int		field_no, n_fields;

 CODE:
    CB_TRACE(1, ("field(%s, %s)\n", SvPV(ST(0),na), field_name));
    cb_errno = CB_SUCCESS;
	    
    field = d4field(self->data4, field_name);
    if (field == NULL)
    {
	field_no = SvIV(ST(1));
	n_fields = d4numFields(self->data4);
	if ((field_no < 1) || (field_no > n_fields)
	   || ((field = d4fieldJ(self->data4, field_no)) == NULL))
	{
	    CB_TRACE(1, ("field returns error %d\n", cb_errno));
	    XSRETURN_UNDEF;
	}
    }
    
    ST(0) = sv_newmortal();
    switch (f4type(field))
    {
    case r4str:
    case r4date:
    case r4log:
        CB_TRACE(1, ("field returns \"%.*s%s\"\n",
		     MAX(field_len(field), 40), f4ptr(field),
		     field_len(field) > 40 ? "..." : ""));
	sv_setpvn(ST(0), f4ptr(field), field_len(field));
	break;

    case r4memo:
        CB_TRACE(1, ("field returns \"%.*s%s\"\n",
		     MAX(field_len(field), 40), f4ptr(field),
		     field_len(field) > 40 ? "..." : ""));
	sv_setpvn(ST(0), f4memoPtr(field), field_len(field));
	break;
	
    case r4num:
        CB_TRACE(1, ("field returns %f\n", f4double(field)));
	sv_setnv(ST(0), f4double(field));
	break;

    default:
	croak("Invalid field type encountered in dBASE file.");
    }


int
set_field(self, fieldname, value)
    CodeBase::Record	*self
    char	*fieldname
    SV		*value

# CATEGORY => "field"

 PREINIT:
    FIELD4	*field;
    
 CODE:
    CB_TRACE(1, ("set_field(%s, \"%s\", %s)\n", 
		 SELF, fieldname, SvPV(value, na)));
    cb_errno = CB_SUCCESS;
    
    field = d4field(self->data4, fieldname);
    if (field == NULL)
    {
	XSRETURN_UNDEF;
    }
    RETVAL = set_field_value(field, value);

 OUTPUT:
    RETVAL

    
##############################################################################
#
# Index handling functions
#
#	create_index FILENAME, TAGS
#	open_index [ FILENAME ]
#	check_indexes
#	reindex
#	tagcount
#	taginfo [ FILENAME ]
#	tags
#	set_tag [ TAGNAME ]
#	seek [ KEY ]

MODULE = CodeBase		PACKAGE = CodeBase::FilePtr

# $file->create_index(name, \@tags)
#
Boolean
create_index(self, name, taginfo)
    CodeBase::File	*self
    char	*name
    AV		*taginfo

 PREINIT:
    TAG4INFO	tag4info[CB_MAX_TAGS + 1];
    SV		**cur_element;
    HV		*hash;
    SV		**key;
    char	*value;
    int		n_tags;
    int		tag_no;

 CODE:
    CB_TRACE(1, ("create_index(\"%s\", \"%s\")\n", SELF, name));
    CB_DUMP(3, taginfo, 6);
    cb_errno = CB_SUCCESS;

    n_tags = av_len(taginfo) + 1;

    CB_TRACE(3, ("create_index: taginfo array length = %d)\n", n_tags));

    if (name && name[0] == '\0')
    {
	name = NULL;
    }

    if (n_tags > CB_MAX_TAGS)
    {
	warn("too many tags defined (only %s accepted)\n", CB_MAX_TAGS);
    }

    /* Loop through the taginfo Perl array.  
     */
    for (tag_no = 0; tag_no < n_tags; tag_no++)
    {
	/* Each element should be a reference to a hash. */

	cur_element = av_fetch(taginfo, tag_no, 0);
	if (!SvROK(*cur_element))
	{
	    CB_TRACE(1, ("create_index: tag %d value is not a ref", tag_no));
	    CB_DUMP(3, *cur_element, 6);
	    RETVAL = CB_ERR_INVALID_USAGE;
	    XSRETURN_UNDEF;
	}
	if (SvTYPE(hash = (HV*)SvRV(*cur_element)) != SVt_PVHV)
	{
	    CB_TRACE(1, ("create_index: tag %d ref is not a hash (%d)\n", tag_no, SvTYPE(hash)));
	    CB_DUMP(3, hash, 6);
	    RETVAL = CB_ERR_INVALID_USAGE;
	    XSRETURN_UNDEF;
	}


	/* We've got the hash for the current tag, it must contain entries
	 * for "name" and "expression".
	 */

	/* name => "<name>" */

	key = hv_fetch(hash, "name", 4, 0);
	if (key == NULL)
	{
	    CB_TRACE(1, ("create_index: tag %d does not have a \"name\" attribute\n", tag_no));
	    RETVAL = CB_ERR_INVALID_USAGE;
	    XSRETURN_UNDEF;
	}
	tag4info[tag_no].name = SvPV(*key, na);
	CB_TRACE(1, ("create_index: tag %d name=\"%s\"\n", tag_no, SvPV(*key, na)));


	/* expression => "<expression>" */

	key = hv_fetch(hash, "expression", 10, 0);
	if (key == NULL)
	{
	    CB_TRACE(1, ("create_index: tag %d does not have a \"expression\" attribute\n", tag_no));
	    RETVAL = CB_ERR_INVALID_USAGE;
	    XSRETURN_UNDEF;
	}
	tag4info[tag_no].expression = SvPV(*key, na);
	CB_TRACE(1, ("create_index: tag %d expr=\"%s\"\n", tag_no, SvPV(*key, na)));

	
	/* filter => "<expression>" (optional) */
	
	tag4info[tag_no].filter = NULL;
	key = hv_fetch(hash, "filter", 6, 0);
	if (key)
	{
	    tag4info[tag_no].filter = SvPV(*key, na);
	    CB_TRACE(1, ("create_index: tag %d filter=\"%s\"\n", tag_no, SvPV(*key, na)));
	}


	/* order => "descending" (optional/default=ascending) */
	
	tag4info[tag_no].descending = 0;
	key = hv_fetch(hash, "order", 5, 0);
	if (key)
	{
	    value = SvPV(*key, na);
	    CB_TRACE(1, ("create_index: tag %d order=\"%s\"\n", tag_no, value));
	    if (ISTREQ(value, "descending"))
	    {
		tag4info[tag_no].descending = r4descending;
	    }
	}


	/* duplicates => "keep" | "discard" (optional/default=error) */
	
	tag4info[tag_no].unique = e4unique;
	key = hv_fetch(hash, "duplicates", 9, 0);
	if (key)
	{
	    value = SvPV(*key, na);
	    CB_TRACE(1, ("create_index: tag %d duplicates=\"%s\"\n", tag_no, value));
	    if (ISTREQ(value, "keep"))
	    {
		tag4info[tag_no].unique = 0;
	    }
	    else if (ISTREQ(value, "discard"))
	    {
		tag4info[tag_no].unique = r4unique_continue;
	    }
	}
    }
    tag4info[tag_no].name = NULL;

    if (i4create(self->data4, name, tag4info) == NULL)
    {
	CB_TRACE(1, ("create_index error %d\n", cb_errno));
        XSRETURN_UNDEF;
    }

    CB_TRACE(1, ("create_index returns OK\n"));
    XSRETURN_YES;


# $file->open_index(name)
#
void
open_index(self, ...)
    CodeBase::File	*self

 PREINIT:
    char	*name;

 CODE:
    cb_errno = CB_SUCCESS;
    if (items == 1)
    {
	CB_TRACE(1, ("open_index(\"%s\")\n", SELF));
	name = NULL;
    }
    else
    {
	name = SvPV(ST(1), na);
	CB_TRACE(1, ("open_index(\"%s\", \"%s\")\n", SELF, name));
    }

    if (!i4open(self->data4, name))
    {
	CB_TRACE(1, ("open_index error %d\n", cb_errno));
	XSRETURN_UNDEF;
    }

    CB_TRACE(1, ("open_index returns OK\n"));
    XSRETURN_YES;


# $file->check_indexes()
#	Reindexes all index files open for the file.
#	Calls d4reindex, which returns 0, r4locked, r4unique or an error code < 0.
void
check_indexes(self)
    CodeBase::File	*self

 CODE:
    CB_TRACE(1, ("check_indexes(\"%s\")\n",  SELF));
    cb_errno = CB_SUCCESS;
    if (d4check(self->data4) != 0)
    {
	CB_TRACE(1, ("check_indexes returns error %d\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("check_indexes returns OK\n"));
    XSRETURN_YES;


# $file->reindex()
#	Reindexes all index files open for the file.
#	Calls d4reindex, which returns 0, r4locked, r4unique or an error code < 0.
void
reindex(self)
    CodeBase::File	*self

 CODE:
    CB_TRACE(1, ("reindex(\"%s\")\n",  SELF));
    cb_errno = CB_SUCCESS;
    if (d4reindex(self->data4) != 0)
    {
	CB_TRACE(1, ("reindex returns error %d\n", cb_errno));
        XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("reindex returns OK\n"));
    XSRETURN_YES;


##############################################################################
#
# $tagcount = $file->tagcount
#
#	Return number of tags associated with current index file.
#
int
tagcount(self)
    CodeBase::File	*self

 PREINIT:
    TAG4	*tag   = NULL;
    int		n_tags = 0;

 CODE:
    CB_TRACE(1, ("tagcount(\"%s\")\n", SELF));
    cb_errno = CB_SUCCESS;
    while ((tag = d4tagNext(self->data4, tag)) != NULL)
    {
	n_tags++;
    }
    CB_TRACE(1, ("tagcount returns %d\n", n_tags));
    RETVAL = n_tags;

 OUTPUT:
    RETVAL


# @taginfo = $file->taginfo
#
#	Return tags associated with current index file.
#
void
taginfo(self, index_name = NULL)
    CodeBase::File	*self
    char	*index_name

 PREINIT:
    INDEX4	*index;
    HV		*hash;
    SV		*ref;
    TAG4INFO	*tag4info;
    int		tag_no;
    char	*value;

 PPCODE:
#if S4VERSION < 6000
    if (index_name == NULL)
    {
	index_name = d4fileName(self->data4);
    }
#endif
    CB_TRACE(1, ("taginfo(\"%s\", \"%s\")\n", SELF, index_name));
    cb_errno = CB_SUCCESS;

    if (   ((index = d4index(self->data4, index_name)) == NULL)
	|| ((tag4info = i4tagInfo(index)) == NULL))
    {
	XSRETURN_UNDEF;
    }

    CB_TRACE(1, ("tags returns (\n"));
    for (tag_no = 0; tag4info->name; tag_no++, tag4info++)
    {
	hash = newHV();
	ref  = newRV((SV *)hash);
	PUSHs(ref);

	CB_TRACE(1, ("   { name => \"%s\", expression => \"%s\"",
		     tag4info->name, tag4info->expression));

	hv_store(hash, "name",        4, newSVpv((char *)tag4info->name, 0), 0);
	hv_store(hash, "expression", 10, newSVpv((char *)tag4info->expression, 0), 0);
	
	if (tag4info->filter && tag4info->filter[0])
	{
	    CB_TRACE(1, (", filter => \"%s\"", tag4info->filter));
	    hv_store(hash, "filter", 6, newSVpv((char *)tag4info->filter, 0), 0);
	}
	
	value = (tag4info->descending == r4descending) ? "DESCENDING" : "ASCENDING";
	CB_TRACE(1, (", order => \"%s\"", value));
	hv_store(hash, "order", 5, newSVpv(value, 0), 0);

	switch (tag4info->unique)
	{
	case e4unique:
	    value = "ERROR";
	    break;
	    
	case r4unique_continue:
	    value = "KEEP";
	    break;
	    
	case 0:
	    value = "DISCARD";
	    break;

        default:
   	    break;
	}
	
	CB_TRACE(1, (", duplicates => \"%s\" },\n", value));
	hv_store(hash, "duplicates", 10, newSVpv(value, 0), 0);

    }
    CB_TRACE(1, (")\n"));



#
# @tags = $file->tags
#
#	Return tags associated with current index file.
#
void
tags(self)
    CodeBase::File	*self

 PREINIT:
    TAG4	*tag   = NULL;
    int		n_tags = 0;

 PPCODE:
    CB_TRACE(1, ("tags(\"%s\")\n", SELF));
    CB_TRACE(1, ("tags returns ("));
    cb_errno = CB_SUCCESS;
    while ((tag = d4tagNext(self->data4, tag)) != NULL)
    {
	XPUSHs(sv_2mortal(newSVpv(t4alias(tag), 0)));
	CB_TRACE(1, ("%s%s", (n_tags++ ? ", " : ""), t4alias(tag)));
    }
    CB_TRACE(1, (")\n"));



# $rc = $file->set_tag([$tag]);
#	Set the current index tag.

void
set_tag(self, ...)
    CodeBase::File	*self
   
 PREINIT:
    TAG4	*tag;
    char 	*tag_name;

 CODE:
    cb_errno = CB_SUCCESS;
    if (items == 1)
    {
	CB_TRACE(1, ("set_tag(\"%s\")\n", SELF));
	d4tagSelect(self->data4, NULL);
	if (cb_errno)
	{
	    XSRETURN_UNDEF;
	}
    }
    else 
    {
	tag_name = SvPV(ST(1), na);
	CB_TRACE(1, ("set_tag(\"%s\", \"%s\")\n", SELF, tag_name));
	if (!(tag = d4tag(self->data4, tag_name)))
	{
	    XSRETURN_UNDEF;
	}
	d4tagSelect(self->data4, tag);
    }
    CB_TRACE(1, ("set_tag returns OK\n", SELF));
    XSRETURN_YES;


# $rec = $file->seek($key);
# 	Seek for a key match.
# 	Searches through the currently selected index for a match for the
#	supplied key.  If a match is found then the record number is returned,
#	otherwise the undefined values is returned and the error code can be
# 	retrieved with cb_errno.

int
seek(self, key)
    CodeBase::File	*self
    char	*key
    
 CODE:
    CB_TRACE(1, ("seek(\"%s\", \"%s\")\n", SELF, key));
    if ((cb_errno = d4seek(self->data4, key)) != 0)
    {
	CB_TRACE(1, ("seek returns undef (cb_errno=%d)\n", cb_errno));
	XSRETURN_UNDEF;
    }
    CB_TRACE(1, ("seek returns TRUE\n"));
    RETVAL = 1;

 OUTPUT:
    RETVAL





##############################################################################
#
# Query functions
#
#   $q = $fh->prepare_query(expr, sortexpr, desc)
#   $q->execute
#   while ($r = $q->next) {
#       # do something
#   }
#

MODULE = CodeBase		PACKAGE = CodeBase::FilePtr

# $q = $fh->prepare_query(expr [, sortexpr [, desc]])
#
# Builds a single file relation
#
#   relate4init, relate4querySet, relate4sortSet
#
CodeBase::Query *
prepare_query(self, expr, sortexpr=NULL, desc=0)
    CodeBase::File    *self
    char        *expr
    char        *sortexpr
    int         desc

 PREINIT:
    RELATE4     *rel;
    int		rc;

 CODE:
    if (!(RETVAL = malloc(sizeof(CodeBase__Query)))) {
        croak("out of memory");
    }
    if (!(RETVAL->rel = rel = relate4init(self->data4))) {
        free(RETVAL);
        croak("relate4init failed");
    }
    if ((rc = relate4querySet(rel, expr)) != r4success) {
        relate4free(rel, 0);
        free(RETVAL);
        croak("error in query expression");
    }
    if (sortexpr && sortexpr[0] && relate4sortSet(rel, sortexpr) != r4success) {
        relate4free(rel, 0);
        free(RETVAL);
        croak("error in sort expression");
    }

    /* The return value is a reference to the FCB passed in.  The
     * reference count is incremented, so that the file is not closed
     * on $fh->close if there is still a query open.
     */

    RETVAL->type       = Q_FCB;
    RETVAL->status     = Q_UNDEFINED;
    RETVAL->descending = desc;
    (RETVAL->fcb = self)->refcount++;

 OUTPUT:
    RETVAL


# Query methods

MODULE = CodeBase		PACKAGE = CodeBase::QueryPtr


# Destructor
# need to decrement reference count of the fh

void
DESTROY(self)
    CodeBase::Query *self

 CODE:
    relate4free(self->rel, 0);
    close_fcb(self->fcb);
    free(self);
        


# $q->execute

void
execute(self)
    CodeBase::Query *self

 CODE:
    self->status = Q_AT_START;
    XSRETURN_YES;


CodeBase::Record *
next(self, skip=1)
    CodeBase::Query *self
    int             skip

 PREINIT:
    int             rc;

 CODE:
    if (skip < 1) {
        croak("skip count must be positive");
    }
    switch (self->status) {
    case Q_UNDEFINED:
        croak("next called before start");

    case Q_AT_START:
        if (self->descending) {
            rc = relate4bottom(self->rel); 
        }
        else {
            rc = relate4top(self->rel);
        }
	/* if r4eof then there are no records in the file */
        if (rc == r4eof) XSRETURN_UNDEF;
            
	/* state is now INPROGRESS */
        self->status = Q_INPROGRESS;

	/* if skip is 1 then return the current record */

        if (rc == r4success && skip == 1) break;
	skip--;
        /* Drop through if not eof */

    case Q_INPROGRESS:
        if (self->descending) skip = -skip;
        rc = relate4skip(self->rel, skip);
	if (rc == r4bof || rc == r4eof) {
	   self->status = Q_AT_END;
	   XSRETURN_UNDEF;
        }
	break;

    case Q_AT_END:
	XSRETURN_UNDEF;
    }
    RETVAL = self->fcb;

 OUTPUT:
    RETVAL





##############################################################################
#
# Miscellaneous functions
#
#	option
#	errno
#	errmsg
#	libversion
#	dbformat

MODULE = CodeBase		PACKAGE = CodeBase

# CodeBase::option($option)
#
void
option(...)

 PREINIT:
    char	*option;
    int		option_no;

 CODE:
    for (option_no = 0; option_no < items; option_no++)
    {
        option = (char *)SvPV(ST(option_no), na);
	if (ISTREQ(option, "trim"))
	{
	    cb_trim_option = TRUE;
	}
	else if (   ISTREQ(option, "no_trim")
		 || ISTREQ(option, "notrim"))
	{
	    cb_trim_option = FALSE;
	}
#if defined(CB_ENABLE_TRACING)
	else if (ISUBSTREQ(option, "tracefile=", 10))
	{
	    fprintf(stderr, "Opening file\n\n");
	    cb_trace_file = fopen(option + 10, "a");
	}
	else if (ISUBSTREQ(option, "trace=", 6))
	{
	    cb_trace_level = atoi(option + 6);
	}
	else if (ISTREQ(option, "notrace"))
	{
	    cb_trace_level = 0;
	}
#endif
	else
	{
	    fprintf(stderr, "unknown option \"%s\"\n", option);
#if defined(CB_ENABLE_TRACING)
	    fprintf(stderr, "CB_ENABLE_TRACING defined\n");
#endif
	}
    }



int
errno()

 CODE:
    CB_TRACE(1, ("errno  returns %d\n", cb_errno));
    RETVAL = cb_errno;

 OUTPUT:
    RETVAL



char *
errmsg(errno = cb_errno)
    int		errno

  CODE:
    CB_TRACE(1, ("errmsg(%d) returns \"%s\"\n", cb_errno, e4text(errno)));
    RETVAL = (char *)e4text(errno);

  OUTPUT:
    RETVAL


# Version of the underlying CodeBase library

double
libversion()

 CODE:
    RETVAL = (double)S4VERSION / 1000;

 OUTPUT:
    RETVAL


# Database format the library is compiled for

char *
dbformat()

  CODE:
#if   defined(S4MDX)
    RETVAL = "dBASE IV";
#elif defined(S4FOX)
    RETVAL = "FoxPro";
#elif defined(S4CLIPPER)
    RETVAL = "Clipper";
#else
    #error invalid database type
#endif

  OUTPUT:
    RETVAL




# end
