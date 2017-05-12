#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "avs.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AVS_ADDDOC_IO_ERR"))
#ifdef AVS_ADDDOC_IO_ERR
	    return AVS_ADDDOC_IO_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_BADARGS_ERR"))
#ifdef AVS_BADARGS_ERR
	    return AVS_BADARGS_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_CHARSET_ASCII8"))
#ifdef AVS_CHARSET_ASCII8
	    return AVS_CHARSET_ASCII8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_CHARSET_LATIN1"))
#ifdef AVS_CHARSET_LATIN1
	    return AVS_CHARSET_LATIN1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_CHARSET_UTF8"))
#ifdef AVS_CHARSET_UTF8
	    return AVS_CHARSET_UTF8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_COMPACT_IO_ERR"))
#ifdef AVS_COMPACT_IO_ERR
	    return AVS_COMPACT_IO_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_COUNTS_ERR"))
#ifdef AVS_COUNTS_ERR
	    return AVS_COUNTS_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DATE_ERR"))
#ifdef AVS_DATE_ERR
	    return AVS_DATE_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOCDATA_ERR"))
#ifdef AVS_DOCDATA_ERR
	    return AVS_DOCDATA_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOCID_ERR"))
#ifdef AVS_DOCID_ERR
	    return AVS_DOCID_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOCLIST_ERR"))
#ifdef AVS_DOCLIST_ERR
	    return AVS_DOCLIST_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOC_EXISTS"))
#ifdef AVS_DOC_EXISTS
	    return AVS_DOC_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOC_LIMIT_ERR"))
#ifdef AVS_DOC_LIMIT_ERR
	    return AVS_DOC_LIMIT_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_DOC_NOTFOUND"))
#ifdef AVS_DOC_NOTFOUND
	    return AVS_DOC_NOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_FIELD_ERR"))
#ifdef AVS_FIELD_ERR
	    return AVS_FIELD_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_FILTER_ERR"))
#ifdef AVS_FILTER_ERR
	    return AVS_FILTER_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_GETDATA_ERR"))
#ifdef AVS_GETDATA_ERR
	    return AVS_GETDATA_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_INDEX_ERR"))
#ifdef AVS_INDEX_ERR
	    return AVS_INDEX_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_LICENSE_EXPIRED"))
#ifdef AVS_LICENSE_EXPIRED
	    return AVS_LICENSE_EXPIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_LOCK_ERR"))
#ifdef AVS_LOCK_ERR
	    return AVS_LOCK_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MALLOC_ERR"))
#ifdef AVS_MALLOC_ERR
	    return AVS_MALLOC_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MAX_BUCKETS"))
#ifdef AVS_MAX_BUCKETS
	    return AVS_MAX_BUCKETS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MAX_DOCDATA"))
#ifdef AVS_MAX_DOCDATA
	    return AVS_MAX_DOCDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MAX_DOCID"))
#ifdef AVS_MAX_DOCID
	    return AVS_MAX_DOCID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MAX_TIERS"))
#ifdef AVS_MAX_TIERS
	    return AVS_MAX_TIERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MAX_WORDSIZE"))
#ifdef AVS_MAX_WORDSIZE
	    return AVS_MAX_WORDSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MKSTABLE_IO_ERR"))
#ifdef AVS_MKSTABLE_IO_ERR
	    return AVS_MKSTABLE_IO_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_MKVIS_IO_ERR"))
#ifdef AVS_MKVIS_IO_ERR
	    return AVS_MKVIS_IO_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_NOMORE_WORDS"))
#ifdef AVS_NOMORE_WORDS
	    return AVS_NOMORE_WORDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OK"))
#ifdef AVS_OK
	    return AVS_OK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPEN_ERR"))
#ifdef AVS_OPEN_ERR
	    return AVS_OPEN_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_RANKBYDATE"))
#ifdef AVS_OPTION_RANKBYDATE
	    return AVS_OPTION_RANKBYDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_SEARCHBYDATE"))
#ifdef AVS_OPTION_SEARCHBYDATE
	    return AVS_OPTION_SEARCHBYDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_SEARCHSINCE"))
#ifdef AVS_OPTION_SEARCHSINCE
	    return AVS_OPTION_SEARCHSINCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_NOBLOCK"))
#ifdef AVS_OPTION_NOBLOCK
	    return AVS_OPTION_NOBLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_INDEX_CJK_CHARS_AS_WORDS"))
#ifdef AVS_OPTION_INDEX_CJK_CHARS_AS_WORDS
	    return AVS_OPTION_INDEX_CJK_CHARS_AS_WORDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPTION_NOPROXIMITY"))
#ifdef AVS_OPTION_NOPROXIMITY
	    return AVS_OPTION_NOPROXIMITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_OPT_FLAGS_RANK_TO_BOOL"))
#ifdef AVS_OPT_FLAGS_RANK_TO_BOOL
	    return AVS_OPT_FLAGS_RANK_TO_BOOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_PARSE_ERR"))
#ifdef AVS_PARSE_ERR
	    return AVS_PARSE_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_PARSE_SGML"))
#ifdef AVS_PARSE_SGML
	    return AVS_PARSE_SGML;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_RESULTNUM_ERR"))
#ifdef AVS_RESULTNUM_ERR
	    return AVS_RESULTNUM_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_SEARCH_ERR"))
#ifdef AVS_SEARCH_ERR
	    return AVS_SEARCH_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_STARTDOC_ERR"))
#ifdef AVS_STARTDOC_ERR
	    return AVS_STARTDOC_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_SYNC_ERR"))
#ifdef AVS_SYNC_ERR
	    return AVS_SYNC_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_UNK_EXCEPTION_ERR"))
#ifdef AVS_UNK_EXCEPTION_ERR
	    return AVS_UNK_EXCEPTION_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_UPDATE_ERR"))
#ifdef AVS_UPDATE_ERR
	    return AVS_UPDATE_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AVS_VERSION_ERR"))
#ifdef AVS_VERSION_ERR
	    return AVS_VERSION_ERR;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	break;
    case 'C':
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
	if (strEQ(name, "IN"))
#ifdef IN
	    return IN;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "OUT"))
#ifdef OUT
	    return OUT;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "VALTYPE_NAME_LEN"))
#ifdef VALTYPE_NAME_LEN
	    return VALTYPE_NAME_LEN;
#else
	    goto not_there;
#endif
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = AltaVista::PerlSDK		PACKAGE = AltaVista::PerlSDK		
PROTOTYPES: ENABLE

double
constant(name,arg)
	char *		name
	int		arg

int
avs_adddate(idx, yr, mo, da, startloc)
	avs_idxHdl_t idx
	int yr
	int mo
	int da
	long startloc

int
avs_addfield(idx, pFname, startloc, endloc)	
	avs_idxHdl_t idx
	char *pFname
	long startloc
	long endloc

int
avs_addliteral (idx, pWord, loc)
	avs_idxHdl_t idx
	char *pWord
	long loc

int
avs_addvalue (idx, valtype, value, loc)
  	avs_idxHdl_t idx
	avs_valtype_t valtype
	unsigned long value
	long loc

int
avs_addword(idx, pWords, loc, pNumWords)
	avs_idxHdl_t idx
	char *pWords
	long loc
	long &pNumWords
	OUTPUT:
	RETVAL
	pNumWords

int
avs_buildmode(idx)
	avs_idxHdl_t idx

int
avs_buildmode_ex(idx, ntiers)
	avs_idxHdl_t idx
	int ntiers

int
avs_close(idx)
	avs_idxHdl_t idx
	
int
avs_compact(idx, bMore_p)
	avs_idxHdl_t idx
	int &bMore_p
   OUTPUT:
     RETVAL
     bMore_p
	
int
avs_compactionneeded (idx)
	avs_idxHdl_t idx


int
avs_compact_minor(idx, bMore_p)
	avs_idxHdl_t idx
	int &bMore_p
   OUTPUT:
     RETVAL
     bMore_p
	
int
avs_count(idx, pWordPrefix, pCountsHdl)
     avs_idxHdl_t idx
     char *pWordPrefix
     avs_countsHdl_t &pCountsHdl = NO_INIT

   OUTPUT:
     pCountsHdl
     RETVAL

int
avs_count_close(CountsHdl)
     avs_countsHdl_t CountsHdl

int
avs_count_getcount(CountsHdl)
     avs_countsHdl_t CountsHdl

char *
avs_count_getword(CountsHdl)
     avs_countsHdl_t CountsHdl

int
avs_countnext(CountsHdl)
     avs_countsHdl_t CountsHdl

void
avs_default_options(pOptions)
     avs_options_p_t pOptions
   CODE:
     avs_default_options(pOptions);
   OUTPUT:
     pOptions

int
avs_define_valtype(name, minval, maxval, valtype_p)
     char * name
     unsigned long minval
     unsigned long maxval
     avs_valtype_t valtype_p = NO_INIT
   CODE:
     RETVAL = avs_define_valtype(name, minval, maxval, NULL, &valtype_p);
   OUTPUT:
     RETVAL
     valtype_p

int
avs_define_valtype_multiple(name, minval, maxval, numvalues, valtype_p)
	char * name
	unsigned long minval
	unsigned long maxval
	int numvalues
	avs_valtype_t valtype_p = NO_INIT
	CODE:
	RETVAL = avs_define_valtype_multiple(name, minval, maxval, numvalues, NULL, &valtype_p);
	OUTPUT:
	RETVAL
	valtype_p

int
avs_deletedocid(idx, pDocId, pCount)
     avs_idxHdl_t idx
     char *pDocId
     int &pCount
   OUTPUT:
     RETVAL
     pCount

int
avs_enddoc(idx)
	avs_idxHdl_t idx

char *
avs_errmsg(code)
	int code

int
avs_getindexmode(idx)
	avs_idxHdl_t idx

int
avs_getindexversion(idx)
	avs_idxHdl_t idx

int
avs_getindexversion_counts_v(countsHdl)
     avs_countsHdl_t countsHdl

int
avs_getindexversion_search_v(searchHdl)
     avs_searchHdl_t searchHdl

int
avs_getmaxloc(idx, pMaxloc)
	avs_idxHdl_t idx
	long &pMaxloc
	OUTPUT:
	RETVAL
	pMaxloc

int
avs_getsearchresults(searchHdl, resultNum)
	avs_searchHdl_t searchHdl
        int resultNum

int
avs_getsearchterms(psearchHdl, termNum, term, count)
     avs_searchHdl_t psearchHdl
     int termNum
     char *term
     long count
   PREINIT:
     long i;
     char *p;
   CODE:
     RETVAL = avs_getsearchterms(psearchHdl, termNum, &p, &i);
     if (RETVAL == 0) {
       count = i;
       term = strdup(p);
     }
   OUTPUT:
     term
     count
     RETVAL

int
avs_getsearchversion(searchHdl, searchversion)
     avs_searchHdl_t searchHdl
     char * searchversion
   OUTPUT:
     searchversion
     RETVAL

int
avs_licenseinfo(key, expDate, docLimit)
	char *key
	time_t &expDate
	long &docLimit
	OUTPUT:
	RETVAL
	expDate
	docLimit

avs_valtype_t
avs_lookup_valtype (name)
     char *name

int
avs_makestable(idx)
	avs_idxHdl_t idx

int
avs_open(parameters, path, mode, idx)
	avs_parameters_t * parameters
	char * path
	char * mode
	avs_idxHdl_t idx = NO_INIT
	PREINIT:
		avs_parameters_t myparms = AVS_PARAMETERS_INIT;
	CODE:
		RETVAL = avs_open(parameters, path, mode, &idx);
	OUTPUT:
	idx
	RETVAL

int
avs_querymode(idx)
	avs_idxHdl_t idx

void
avs_release_valtypes()

int
avs_release_valtype(valtype_p)
	avs_valtype_t valtype_p

int
avs_search(idx, pQuery, pBoolQuery, pOptions, pDocsFound, pDocsReturned, pTermCount, pSearchHdl)
	avs_idxHdl_t idx
	char *pQuery
	char *pBoolQuery
	avs_options_p_t pOptions
	long &pDocsFound = NO_INIT;
	long &pDocsReturned = NO_INIT;
	long &pTermCount = NO_INIT;
	avs_searchHdl_t &pSearchHdl = NO_INIT;
	OUTPUT:
	RETVAL
        pDocsFound
        pDocsReturned
        pTermCount
        pSearchHdl
	
int
avs_search_close (pSearchHdl)
	avs_searchHdl_t pSearchHdl

int
avs_search_ex(idx, pQuery, pBoolQuery, pOptions, searchsince, pDocsFound, pDocsReturned, pTermCount, pSearchHdl)
	avs_idxHdl_t idx
	char *pQuery
	char *pBoolQuery
	avs_options_p_t pOptions
	char *searchsince
	long &pDocsFound = NO_INIT;
	long &pDocsReturned = NO_INIT;
	long &pTermCount = NO_INIT;
	avs_searchHdl_t &pSearchHdl = NO_INIT;
	OUTPUT:
	RETVAL
        pDocsFound
        pDocsReturned
        pTermCount
        pSearchHdl
	
int
avs_search_genrank (idx, pBoolQuery, pRankTerms, pRankSetup, pOptions, searchsince, pDocsFound, pDocsReturned, pSearchHdl)
        avs_idxHdl_t idx
        char *pBoolQuery
        char *pRankTerms
        char *searchsince
        int pRankSetup
        avs_options_p_t pOptions
        long pDocsFound = NO_INIT;
        long pDocsReturned = NO_INIT;
        avs_searchHdl_t pSearchHdl = NO_INIT;
        CODE:
        RETVAL = avs_search_genrank(idx, pBoolQuery, pRankTerms,
                                    NULL, pOptions, searchsince,
                                    &pDocsFound, &pDocsReturned,
                                    &pSearchHdl);
        OUTPUT:
        pDocsFound
        pDocsReturned
        pSearchHdl
        RETVAL

char *
avs_search_getdata(searchHdl)
	avs_searchHdl_t searchHdl

int
avs_search_getdatalen(searchHdl)
	avs_searchHdl_t searchHdl



void
avs_search_getdate(psearchHdl, year, month, day)
     avs_searchHdl_t psearchHdl
     int &year
     int &month
     int &day
   OUTPUT:
     year
     month
     day

char *
avs_search_getdocid(searchHdl)
	avs_searchHdl_t searchHdl
	PREINIT:
		char *p;
	CODE:
		p = avs_search_getdocid(searchHdl);
		RETVAL = strdup(p);
	OUTPUT:
	RETVAL

int
avs_search_getdocidlen(searchHdl)
	avs_searchHdl_t searchHdl

char *
avs_search_getrelevance(psearchHdl)
     avs_searchHdl_t psearchHdl
   PREINIT:
     char p[20];
     float f;
   CODE:
     f = avs_search_getrelevance(psearchHdl);
     sprintf(p, "%f", f);
     RETVAL = strdup(p);
   OUTPUT:
     RETVAL

int
avs_setdocdata(idx, pDocData, len)
     	avs_idxHdl_t idx
        char *pDocData
	int len
   CODE:
     RETVAL = avs_setdocdata(idx, pDocData, len);
   OUTPUT:
     RETVAL

int
avs_setdocdate(idx, year, month, day)
     	avs_idxHdl_t idx
	int year
	int month
	int day

int
avs_setdocdatetime(idx, year, month, day, hour, minute, second)
     avs_idxHdl_t idx
     int year
     int month
     int day
     int hour
     int minute
     int second

void
avs_setparseflags(idx, parseflags)
     avs_idxHdl_t idx
     int parseflags

int
avs_setrankval(idx, valtype, value)
     avs_idxHdl_t idx
     avs_valtype_t valtype
     unsigned long value

int
avs_startdoc(idx, pDocId, flags, pStartLoc)
	avs_idxHdl_t idx
	char *pDocId
	int flags
	long &pStartLoc
	OUTPUT:
	RETVAL
	pStartLoc

void
avs_timer(current)
     unsigned long current

int
avs_total_docs(idx, pDoccount)
	avs_idxHdl_t idx
	long &pDoccount
	OUTPUT:
	RETVAL
	pDoccount

AV *
avs_version(license_key)
	char * license_key
     PREINIT:
        AV *arr;
        const char **lines;
     CODE:
	arr = newAV();
        lines = avs_version(license_key);
        while (*lines != 0) {
            av_push(arr, newSVpv(strdup(*lines), 0));
            lines++;
        }
        RETVAL = (AV *) arr;
     OUTPUT:
        RETVAL

avs_options_p_t
avs_create_options(limit, timeout, flags)
	long limit
	int timeout
	int flags
	CODE:
	RETVAL = malloc(sizeof(struct avs_options));
	RETVAL->limit = limit;
	RETVAL->timeout = timeout;
	RETVAL->flags = flags;
	OUTPUT:
	RETVAL

avs_parameters_t *
avs_create_parameters(_interface_version, license, ignored_thresh, chars_before_wildcard, unlimited_wild_words, indexformat, cache_threshold, options, charset, ntiers, nbuckets)
	char * _interface_version
	char * license
	int ignored_thresh
	int chars_before_wildcard
	int unlimited_wild_words
	int indexformat
	long cache_threshold
	int options
	int charset
	int ntiers
	int nbuckets
	CODE:
	RETVAL = malloc(sizeof(struct avs_parameters));
	RETVAL->_interface_version = _interface_version;
	RETVAL->license = license;
	RETVAL->ignored_thresh = ignored_thresh;
	RETVAL->chars_before_wildcard = chars_before_wildcard;
	RETVAL->unlimited_wild_words = unlimited_wild_words;
	RETVAL->indexformat = indexformat;
	RETVAL->cache_threshold = cache_threshold;
	RETVAL->options = options;
	RETVAL->charset = charset;
	RETVAL->ntiers = ntiers;
	RETVAL->nbuckets = nbuckets;
	OUTPUT:
	RETVAL
