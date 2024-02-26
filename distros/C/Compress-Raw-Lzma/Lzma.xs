/* Filename: Lzma.xs
 * Author  : Paul Marquess, <pmqs@cpan.org>
 * Created : 14th March 2009
 * Version : 2.000
 *
 *   Copyright (c) 2009-2024 Paul Marquess. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "lzma.h"

#define NEED_sv_2pv_nolen
#include "ppport.h"


#if PERL_VERSION < 18

/* Proposed fix for https://github.com/Dual-Life/Devel-PPPort/issues/231 */

#  ifdef sv_2pv
#    undef sv_2pv
#  endif

#  if defined(__GNUC__) && !defined(PERL_GCC_BRACE_GROUPS_FORBIDDEN)
#    define sv_2pv(sv, lp) ({ SV *_sv_2pv = (sv); SvPOKp(_sv_2pv) ? ((*(lp) = SvCUR(_sv_2pv)), SvPVX(_sv_2pv)) : Perl_sv_2pv(aTHX_ _sv_2pv, (lp)); })
#  else
#    define sv_2pv(sv, lp) (SvPOKp(sv) ? ((*(lp) = SvCUR(sv)), SvPVX(sv)) : Perl_sv_2pv(aTHX_ (sv), (lp)))
#  endif

#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 8 || (PERL_VERSION == 8 && PERL_SUBVERSION < 4 ))

#    ifdef SvPVbyte_force
#        undef SvPVbyte_force
#    endif

#    define SvPVbyte_force(sv,lp) SvPV_force(sv,lp)

#endif

#ifndef SvPVbyte_nolen
#    define SvPVbyte_nolen SvPV_nolen
#endif

#if PERL_REVISION == 5 && (PERL_VERSION >= 8 || (PERL_VERSION == 8 && PERL_SUBVERSION < 4 ))
#    define UTF8_AVAILABLE
#endif

typedef int                     DualType ;
typedef int                     int_undef ;

typedef unsigned long           uLong;
typedef unsigned int            uInt;

typedef struct di_stream {
    int      flags ;
#define FLAG_APPEND_OUTPUT      1
#define FLAG_CONSUME_INPUT      8
#define FLAG_LIMIT_OUTPUT       16

    //bool     is_tainted;
    bool        forZip;
    void*       extraAddress ;
    lzma_stream stream ;

    lzma_filter filters[LZMA_FILTERS_MAX + 1];
    SV* sv_filters[LZMA_FILTERS_MAX];

    uInt     bufsize;
    int      last_error ;

    uint64_t    bytesInflated ;
    uint64_t    compressedBytes ;
    uint64_t    uncompressedBytes ;

} di_stream;

typedef struct di_filter {
    lzma_filter filter;
    SV* dict;
} di_filter;

typedef di_stream * deflateStream ;
typedef di_stream * Compress__Raw__Lzma ;
typedef di_stream * Compress__Raw__Lzma__Encoder ;
typedef di_stream * Compress__Raw__Lzma__Decoder ;

typedef di_filter * Lzma__Filter ;
typedef di_filter * Lzma__Filter__Lzma;
typedef di_filter * Lzma__Filter__BCJ ;
typedef di_filter * Lzma__Filter__Delta ;
typedef di_filter * Lzma__Filter__SubBlock ;

typedef di_stream * inflateStream ;
typedef lzma_options_lzma * Compress__Raw__Lzma__Options;

#define COMPRESS_CLASS    "Compress::Raw::Lzma::Encoder"
#define UNCOMPRESS_CLASS  "Compress::Raw::Lzma::Decoder"

#define ZMALLOC(to, typ) (((to) = (typ *)safemalloc(sizeof(typ))), \
                                Zero((to),1,typ))

#define setDefaultOptions(options) \
    {	\
		Zero((options),1,lzma_options_lzma); \
		(options)->dict_size        = LZMA_DICT_SIZE_DEFAULT;	\
		(options)->preset_dict      = NULL;	\
		(options)->preset_dict_size = 0;	\
		(options)->lc               = LZMA_LC_DEFAULT;	\
		(options)->lp               = LZMA_LP_DEFAULT;	\
		(options)->pb               = LZMA_PB_DEFAULT;	\
		(options)->mode             = LZMA_MODE_NORMAL;	\
		(options)->nice_len         = 64;	\
		(options)->mf               = LZMA_MF_BT4;	\
		(options)->depth            = 0;	\
    }


#if 0
#if sizeof(unsigned long) >= 8
  #define IN_u64(arg) (unsigned long)SvUV(arg)
  #define OUT_u64(arg, var) sv_setuv(arg, (IV)var)
#else
  #define IN_u64(arg) 	if (SvOK($arg))
            $var = ($type)SvPVbyte_nolen($arg);
	else
            $var = NULL ;

  #define OUT_u64(arg, var) sv_setpv((SV*)arg, var);
#endif
#endif


/*** Tainting ***/


#define isTainted(sv) ( SvTAINTED(sv) || (SvROK(sv) ? SvTAINTED(SvRV(sv)) : FALSE))
#define rememberTainting(sv) STMT_START { s->is_tainted |= isTainted(sv); } STMT_END
#define setTainted(sv) STMT_START { SvTAINTED_on(sv); } STMT_END

#define taintedStack(x) ( FALSE || items >= x && isTainted(ST(x-1)) )
/* #define taintedStack(items) ( isTainted(ST(items-1)) ) */
#define taintedStack_1   ( taintedStack(1) )
#define taintedStack_2   ( taintedStack_1 || taintedStack(2) )
#define taintedStack_3   ( taintedStack_2 || taintedStack(3) )
#define taintedStack_4   ( taintedStack_3 || taintedStack(4) )
#define taintedStack_5   ( taintedStack_4 || taintedStack(5) )
#define taintedStack_6   ( taintedStack_5 || taintedStack(6) )
#define taintedStack_7   ( taintedStack_6 || taintedStack(7) )
#define taintedStack_8   ( taintedStack_7 || taintedStack(8) )

#define getTaint1 ( s->is_tainted = s->is_tainted || taintedStack_1 )
#define getTaint2 ( s->is_tainted = s->is_tainted || taintedStack_2 )
#define getTaint3 ( s->is_tainted = s->is_tainted || taintedStack_3 )
#define getTaint4 ( s->is_tainted = s->is_tainted || taintedStack_4 )
#define getTaint5 ( s->is_tainted = s->is_tainted || taintedStack_5 )
#define getTaint6 ( s->is_tainted = s->is_tainted || taintedStack_6 )
#define getTaint7 ( s->is_tainted = s->is_tainted || taintedStack_7 )
#define getTaint8 ( s->is_tainted = s->is_tainted || taintedStack_8 )

/*** End Tainting ***/


//static const char * const my_l_errmsg[] = {
static const char my_l_errmsg[][34] = {
    "OK",		                            /* LZMA_OK                  = 0 */
    "End of stream",		                /* LZMA_STREAM_END          = 1 */
    "No integrity check",                   /* LZMA_NO_CHECK       	    = 2 */
    "Cannot calculate integrity check",	    /* LZMA_UNSUPPORTED_CHECK   = 3 */
    "Integrity check type available",       /* LZMA_GET_CHECK           = 4 */
    "Cannot allocate memory",		        /* LZMA_MEM_ERROR           = 5 */
    "Memory usage limit was reached",		/* LZMA_MEMLIMIT_ERROR      = 6 */
    "File format not recognized",		    /* LZMA_FORMAT_ERROR        = 7 */
    "Invalid or unsupported options",		/* LZMA_OPTIONS_ERROR       = 8 */
    "Data is corrupt",		                /* LZMA_DATA_ERROR          = 9 */
    "No progress is possible",		        /* LZMA_BUF_ERROR           = 10 */
    "Programming error",                    /* LZMA_PROG_ERROR          = 11 */
    ""};

#define setDUALstatus(var, err)                                         \
                sv_setnv(var, (double)err) ;                            \
                sv_setpv(var, ((err) ? GetErrorString(err) : "")) ;     \
                SvNOK_on(var);


#if defined(__SYMBIAN32__)
# define NO_WRITEABLE_DATA
#endif

#define TRACE_DEFAULT 0

#ifdef NO_WRITEABLE_DATA
#  define trace TRACE_DEFAULT
#else
  static int trace = TRACE_DEFAULT ;
#endif

/* Dodge PerlIO hiding of these functions. */
#undef printf

#if 1
#define getInnerObject(x) (*av_fetch((AV*)SvRV(x), 0, FALSE))
#else
#define getInnerObject(x) ((SV*)SvRV(sv))
#endif

static char *
#ifdef CAN_PROTOTYPE
GetErrorString(int error_no)
#else
GetErrorString(error_no)
int error_no ;
#endif
{
    dTHX;
    char * errstr ;

    errstr = (char*) my_l_errmsg[error_no];

    return errstr ;
}

#if 0
static void
#ifdef CAN_PROTOTYPE
DispHex(void * ptr, int length)
#else
DispHex(ptr, length)
    void * ptr;
    int length;
#endif
{
    char * p = (char*)ptr;
    int i;
    for (i = 0; i < length; ++i) {
        printf(" %02x", 0xFF & *(p+i));
    }
}

static void
#ifdef CAN_PROTOTYPE
DispStream(di_stream * s, SV* sv, const char * message)
#else
DispStream(s, message)
    di_stream * s;
    const char * message;
#endif
{
    dTHX;

#if 0
    if (! trace)
        return ;
#endif

#define EnDis(f) (s->flags & f ? "Enabled" : "Disabled")

    printf("DispStream 0x%p", s) ;
    if (message)
        printf("- %s \n", message) ;
    printf("\n") ;

    if (sv) {
        sv_dump(sv);
        printf("\n") ;
    }

    if (!s)  {
        printf("    stream pointer is NULL\n");
    }
    else     {
        printf("    stream           0x%p\n", &(s->stream));
        printf("           next_in   0x%p", s->stream.next_in);
        if (s->stream.next_in){
            printf(" =>");
            DispHex((void*)s->stream.next_in, 4);
        }
        printf("\n");

        printf("           next_out  0x%p", s->stream.next_out);
        if (s->stream.next_out){
            printf(" =>");
            DispHex((void*)s->stream.next_out, 4);
        }
        printf("\n");

        printf("           avail_in  %lu\n",  (unsigned long)s->stream.avail_in);
        printf("           avail_out %lu\n",  (unsigned long)s->stream.avail_out);
        printf("    bufsize          %lu\n",  (unsigned long)s->bufsize);
        printf("    flags            0x%x\n", s->flags);
        printf("           APPEND    %s\n",   EnDis(FLAG_APPEND_OUTPUT));
        printf("           CONSUME   %s\n",   EnDis(FLAG_CONSUME_INPUT));
        printf("           LIMIT     %s\n",   EnDis(FLAG_LIMIT_OUTPUT));

        printf("\n");

    }
}
#endif

void* my_alloc (void* opaque, size_t items, size_t size)
{
    PERL_UNUSED_VAR(opaque);
    return safemalloc(items * size);
}

void my_free (void* opaque, void* ptr)
{
    PERL_UNUSED_VAR(opaque);
    safefree(ptr);

    return;
}

static di_stream *
#ifdef CAN_PROTOTYPE
InitStream(void)
#else
InitStream()
#endif
{
    dTHX;
    di_stream *s ;
    lzma_allocator * allocator;

    ZMALLOC(s, di_stream) ;

    /* lzma_memory_usage(lzma_preset_lzma, TRUE); */

    ZMALLOC(allocator, lzma_allocator) ;
    allocator->alloc = my_alloc;
    allocator->free = my_free;
    s->stream.allocator = allocator;

    return s ;

}

static void
#ifdef CAN_PROTOTYPE
PostInitStream(di_stream * s, int flags, int bufsize)
#else
PostInitStream(s, flags, bufsize)
    di_stream *s ;
    int flags ;
    int bufsize;
#endif
{
    s->bufsize  = bufsize;
    s->last_error = LZMA_OK ;
    s->flags    = flags ;
}

bool
setupFilters(di_stream* s, AV* filters, const char* properties)
{
    dTHX;
    int i = 0;

    if (properties) {
        s->filters[0].id = LZMA_FILTER_LZMA1;

        if (lzma_properties_decode(&s->filters[0], s->stream.allocator,
                (const uint8_t*)properties, 5) != LZMA_OK)
            return FALSE;

        s->extraAddress = (void*)s->filters[0].options;

        ++i;
    }
    else {
        AV*   f = filters;
        int	count = av_len(f)  ;

        for (i = 0; i <= count; ++i)
        {
            SV * fptr = (SV*) * av_fetch(f, i, FALSE) ;
            IV tmp = SvIV((SV*)SvRV(fptr));
            di_filter* filter = INT2PTR(di_filter*, tmp);

            /* Keep a reference to the filter so it doesn't get destroyed */
            s->sv_filters[i] = newSVsv(fptr) ;

            s->filters[i].id = filter->filter.id;
            s->filters[i].options = filter->filter.options;
        }
    }

    /* Terminate the filter list */
    s->filters[i].id = LZMA_VLI_UNKNOWN ;
    return TRUE;
}

void
destroyStream(di_stream * s)
{
    dTHX;
    if (s)
    {
        int i;

        if (s->extraAddress)
            Safefree(s->extraAddress) ;

	    if (s->stream.allocator)
    	    Safefree(s->stream.allocator);

        for (i = 0; i < LZMA_FILTERS_MAX; ++i)
        {
            if (s->sv_filters[i])
                SvREFCNT_dec(s->sv_filters[i]);
        }

        Safefree(s) ;
    }
}

static SV*
#ifdef CAN_PROTOTYPE
deRef(SV * sv, char * string)
#else
deRef(sv, string)
SV * sv ;
char * string;
#endif
{
    dTHX;
    SvGETMAGIC(sv);

    if (SvROK(sv)) {
        sv = SvRV(sv) ;
        SvGETMAGIC(sv);
        switch(SvTYPE(sv)) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV:
                croak("%s: buffer parameter is not a SCALAR reference", string);
            default:
                break;
        }
        if (SvROK(sv))
            croak("%s: buffer parameter is a reference to a reference", string) ;
    }

    if (!SvOK(sv)) {
        sv = sv_2mortal(newSVpv("", 0));
    }

    return sv ;
}

static SV*
#ifdef CAN_PROTOTYPE
deRef_l(SV * sv, char * string)
#else
deRef_l(sv, string)
SV * sv ;
char * string ;
#endif
{
    dTHX;
    bool wipe = 0 ;
    STRLEN na;

    SvGETMAGIC(sv);
    wipe = ! SvOK(sv) ;

    if (SvROK(sv)) {
        sv = SvRV(sv) ;
        SvGETMAGIC(sv);
        wipe = ! SvOK(sv) ;

        switch(SvTYPE(sv)) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV:
                croak("%s: buffer parameter is not a SCALAR reference", string);
            default:
                break;
        }
        if (SvROK(sv))
            croak("%s: buffer parameter is a reference to a reference", string) ;
    }

    if (SvREADONLY(sv) && PL_curcop != &PL_compiling)
        croak("%s: buffer parameter is read-only", string);

    SvUPGRADE(sv, SVt_PV);

    if (wipe)
        sv_setpv(sv, "") ;
    else
        (void)SvPVbyte_force(sv, na) ;

    return sv ;
}




#if 0
static lzma_filter all_filters[LZMA_FILTERS_MAX + 1];

//static lzma_options_filter lzma->filters[8];
static size_t filters_count = 0;
static size_t preset_number = 6 ;
static size_t opt_memory = 1024 * 1024 * 1000 ;
#endif




#if 0
static void
set_compression_settings(lzma_data * lzma)
{
	lzma->preset_default = lzma->filters_count == 0;
    size_t i;

	if (lzma->preset_default) {
		lzma->filters[0].id = LZMA_FILTER_LZMA1;
		lzma->filters[0].options = (lzma_options_lzma *)(
				lzma_preset_lzma + lzma->preset_number);
		lzma->filters_count = 1;
	}

	// Terminate the filter options array.
	lzma->filters[lzma->filters_count].id = UINT64_MAX;

	// Optimize the filter chain a little by removing all
	// Copy filters.
	for (i = 0; lzma->filters[i].id != UINT64_MAX; ++i) {
		while (lzma->filters[i].id == LZMA_FILTER_COPY) {
			size_t j = i;
			do {
				lzma->filters[j] = lzma->filters[j + 1];
			} while (lzma->filters[++j].id != UINT64_MAX);
		}
	}

	const uint32_t memory_limit = opt_memory / (1024 * 1024) + 1;
	uint32_t memory_usage = lzma_memory_usage(lzma->filters, TRUE);

	// Don't go over the memory limits when the default
	// setting is used.
	if (preset_default) {
		while (memory_usage > memory_limit) {
			if (lzma->preset_number == 0) {
				croak("Memory usage limit is too "
						"small for any internal "
						"filter preset");
				exit(-1);
			}

			--lzma->preset_number;
			lzma->filters[0].options = (lzma_options_lzma *)(
					lzma_preset_lzma
					+ lzma->preset_number);
			memory_usage = lzma_memory_usage(lzma->filters,
					TRUE);
		}
	} else {
		if (memory_usage > memory_limit) {
			croak("Memory usage limit is too small "
					"for the given filter setup");
			exit(-1);
		}
	}

	// Limit the number of worked threads so that memory usage
	// limit isn't exceeded.
	// FIXME: Probably should use bytes instead of mebibytes for
	// memory_usage and memory_limit.
	if (memory_usage == 0)
		memory_usage = 1;

#if 0
	size_t thread_limit = memory_limit / memory_usage;
	if (thread_limit == 0)
		thread_limit = 1;

	if (opt_threads > thread_limit)
		opt_threads = thread_limit;
#endif

	return;
}
#endif

lzma_ret
#ifdef CAN_PROTOTYPE
addZipProperties(di_stream* s, SV* output)
#else
addZipProperties(s, output)
di_stream* s;
SV* output ;
#endif
{
    dTHX;
    uint32_t size;
    int cur_length =  SvCUR(output) ;
    lzma_ret status = lzma_properties_size(&size, &s->filters[0]);
    uint8_t *props ;

    if (status != LZMA_OK)
        return status;


    Sv_Grow(output, SvLEN(output) + size + 4) ;
    props = (uint8_t*) SvPVbyte_nolen(output) + cur_length;

    *props = (uint8_t)LZMA_VERSION_MAJOR ; ++ props;
    *props = (uint8_t)LZMA_VERSION_MINOR ; ++ props;
    *props = size ; ++ props;
    *props = 0 ; ++ props;

    status = lzma_properties_encode(&s->filters[0], props);
    SvCUR_set(output, cur_length + size + 4);

    s->forZip = FALSE ;

    return status ;
}


#include "constants.h"

MODULE = Compress::Raw::Lzma PACKAGE = Compress::Raw::Lzma

REQUIRE:	1.924
PROTOTYPES:	DISABLE

INCLUDE: constants.xs

BOOT:
    {
        PERL_UNUSED_VAR(trace);
    }



MODULE = Compress::Raw::Lzma PACKAGE = Compress::Raw::Lzma PREFIX = MY_

#define MY_LZMA_VERSION() LZMA_VERSION
uint32_t
MY_LZMA_VERSION()

uint32_t
lzma_version_number()

const char *
lzma_version_string()

#define MY_LZMA_VERSION_STRING() LZMA_VERSION_STRING
const char *
MY_LZMA_VERSION_STRING()

#define MY_LZMA_FILTER_LZMA1() LZMA_FILTER_LZMA1
uint64_t
MY_LZMA_FILTER_LZMA1()

#define MY_LZMA_BACKWARD_SIZE_MAX() LZMA_BACKWARD_SIZE_MAX
uint64_t
MY_LZMA_BACKWARD_SIZE_MAX()

lzma_bool
lzma_mf_is_supported(match_finder)
    lzma_match_finder match_finder

lzma_bool
lzma_mode_is_supported(mode)
    lzma_mode mode

lzma_bool
lzma_check_is_supported(check)
    lzma_check check

uint32_t
lzma_check_size(check)
    lzma_check check

size_t
lzma_stream_buffer_bound(uncompressed_size)
    size_t uncompressed_size

lzma_bool
lzma_filter_encoder_is_supported(id)
    lzma_vli id

lzma_bool
lzma_filter_decoder_is_supported(id)
    lzma_vli id

uint64_t
lzma_easy_encoder_memusage(preset)
    uint32_t preset

uint64_t
lzma_easy_decoder_memusage(preset)
    uint32_t preset

void
lzma_alone_encoder(Class, flags, bufsize, filters)
    const char * Class
    int flags
    uLong bufsize
    AV* filters
  PPCODE:
  {
    lzma_ret err = LZMA_OK;
    deflateStream s = NULL;

    if ((s = InitStream() )) {
        setupFilters(s, filters, NULL);
        err = lzma_alone_encoder ( &(s->stream), (const lzma_options_lzma*)s->filters[0].options );

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
        }
        else {
            PostInitStream(s, flags, bufsize) ;
            //s->is_tainted = is_tainted;
        }
    }
    else {
        err = LZMA_MEM_ERROR ;
        s = NULL;
    }

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }

void
lzma_raw_encoder(Class, flags, bufsize, filters, forZip)
    const char * Class
    int flags
    uLong bufsize
    AV* filters
    bool forZip
  PPCODE:
  {
    lzma_ret err = LZMA_OK;
    deflateStream s = NULL;
    if ((s = InitStream() )) {
        setupFilters(s, filters, NULL);

        s->forZip = forZip ;
        err = lzma_raw_encoder ( &(s->stream), (const lzma_filter*)&s->filters );

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
        }
        else {
            PostInitStream(s, flags, bufsize) ;
            //s->is_tainted = is_tainted;
        }
    }
    else {
        err = LZMA_MEM_ERROR ;
        s = NULL;
    }

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }

void
lzma_stream_encoder(Class, flags, bufsize, filters, check=LZMA_CHECK_CRC32)
    const char * Class
    int flags
    uLong bufsize
    AV* filters
    lzma_check check
  PPCODE:
  {
    lzma_ret err = LZMA_OK;
    deflateStream s = NULL;

    if ((s = InitStream() )) {
        setupFilters(s, filters, NULL);

        err = lzma_stream_encoder ( &(s->stream), (const lzma_filter*)&s->filters, check );

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
        }
        else {
            PostInitStream(s, flags, bufsize) ;
            //s->is_tainted = is_tainted;
        }
    }
    else {
        err = LZMA_MEM_ERROR ;
        s = NULL;
    }

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }


void
lzma_easy_encoder(Class, flags, bufsize, preset=LZMA_PRESET_DEFAULT, check=LZMA_CHECK_CRC32)
    const char * Class
    int flags
    int preset
    lzma_check check
    uLong bufsize
  PPCODE:
  {
    lzma_ret err = LZMA_OK;
    deflateStream s = NULL;

    if ((s = InitStream())) {
        err = lzma_easy_encoder ( &(s->stream), preset, check);

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
        }
        else {
            PostInitStream(s, flags, bufsize) ;
            //s->is_tainted = is_tainted;
        }
    }
    else {
        err = LZMA_MEM_ERROR ;
        s = NULL;
    }

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }



MODULE = Compress::Raw::Lzma::Encoder PACKAGE = Compress::Raw::Lzma::Encoder


void
DESTROY(s)
    Compress::Raw::Lzma::Encoder	s
  CODE:
    lzma_end(&s->stream) ;
    destroyStream(s) ;



DualType
code (s, buf, output)
    Compress::Raw::Lzma::Encoder	s
    SV *	buf
    SV * 	output
    uInt	cur_length = NO_INIT
    uInt	increment = NO_INIT
    lzma_ret	RETVAL = LZMA_OK;
    uInt   bufinc = NO_INIT
    //bool is_tainted  = getTaint3;
    STRLEN    origlen = NO_INIT
  CODE:
    bufinc = s->bufsize;

    /* If the input buffer is a reference, dereference it */
    buf = deRef(buf, (char*)"code") ;

    /* initialise the input buffer */
#ifdef UTF8_AVAILABLE
    if (DO_UTF8(buf) && !sv_utf8_downgrade(buf, 1))
         croak("Wide character in " COMPRESS_CLASS "::code input parameter");
#endif
    s->stream.next_in = (uint8_t*)SvPV_nomg(buf, origlen) ;
    s->stream.avail_in = origlen;

    //if (is_tainted)
        //setTainted(output);
    /* and retrieve the output buffer */
    output = deRef_l(output, (char*)"code") ;
#ifdef UTF8_AVAILABLE
    if (DO_UTF8(output) && !sv_utf8_downgrade(output, 1))
         croak("Wide character in " COMPRESS_CLASS "::code output parameter");
#endif

    if((s->flags & FLAG_APPEND_OUTPUT) == FLAG_APPEND_OUTPUT) {
        SvOOK_off(output);
    } else {
        SvCUR_set(output, 0);
    }

    if (s->forZip)
        addZipProperties(s, output) ;

    cur_length =  SvCUR(output) ;
    s->stream.next_out = (uint8_t*) SvPVX(output) + cur_length;
    increment =  SvLEN(output) -  cur_length;
    s->stream.avail_out =  increment;
    while (s->stream.avail_in != 0) {

        if (s->stream.avail_out == 0) {
	    /* out of space in the output buffer so make it bigger */
            s->stream.next_out = (uint8_t*)Sv_Grow(output, SvLEN(output) + bufinc) ;
            cur_length += increment ;
            s->stream.next_out += cur_length ;
            increment = bufinc ;
            s->stream.avail_out = increment;
            bufinc *= 2 ;
        }

        RETVAL = lzma_code(&(s->stream), LZMA_RUN);

        if (RETVAL == LZMA_STREAM_END)
            break;
        if (RETVAL != LZMA_OK)
            break;

        /* if (RETVAL == LZMA_BUF_ERROR) { */

            if (s->stream.avail_out == 0)
                continue ;
            if (s->stream.avail_in == 0) {
                RETVAL = LZMA_OK ;
                break ;
            }


        if (RETVAL != LZMA_OK)
            break;
    }

    s->compressedBytes    += cur_length + increment - s->stream.avail_out ;
    s->uncompressedBytes  += origlen - s->stream.avail_in  ;

    s->last_error = RETVAL ;
    if (RETVAL == LZMA_OK) {
        SvPOK_only(output);
        SvCUR_set(output, cur_length + increment - s->stream.avail_out) ;
        SvSETMAGIC(output);
    }
    OUTPUT:
	RETVAL


DualType
flush(s, output, f=LZMA_FINISH)
    Compress::Raw::Lzma::Encoder	s
    SV * output
    uInt	cur_length = NO_INIT
    uInt	increment = NO_INIT
    uInt    bufinc = NO_INIT
    lzma_ret	RETVAL = LZMA_OK;
    lzma_action     f
    //bool is_tainted = getTaint2;
  CODE:
    //if (is_tainted)
        //setTainted(output);
    bufinc = s->bufsize;

    s->stream.avail_in = 0; /* should be zero already anyway */

    /* retrieve the output buffer */
    output = deRef_l(output, (char*)"flush") ;
#ifdef UTF8_AVAILABLE
    if (DO_UTF8(output) && !sv_utf8_downgrade(output, 1))
         croak("Wide character in " COMPRESS_CLASS "::flush input parameter");
#endif
    if((s->flags & FLAG_APPEND_OUTPUT) == FLAG_APPEND_OUTPUT) {
        SvOOK_off(output);
    } else {
        SvCUR_set(output, 0);
    }

    if (s->forZip)
        addZipProperties(s, output) ;

    cur_length =  SvCUR(output) ;
    s->stream.next_out = (uint8_t*) SvPVX(output) + cur_length;
    increment =  SvLEN(output) -  cur_length;
    s->stream.avail_out =  increment;

    for (;;) {
        if (s->stream.avail_out == 0) {
	    /* consumed all the available output, so extend it */
            s->stream.next_out = (uint8_t*)Sv_Grow(output, SvLEN(output) + bufinc) ;
            cur_length += increment ;
            s->stream.next_out += cur_length ;
            increment = bufinc ;
            s->stream.avail_out = increment;
            bufinc *= 2 ;
        }

        RETVAL = lzma_code(&(s->stream), f);

        /* deflate has finished flushing only when it hasn't used up
         * all the available space in the output buffer:
         */
        /* if (s->stream.avail_out != 0 || RETVAL < 0 ) */
        if (RETVAL != LZMA_OK)
            break;
    }

    /* TODO -- ??? */
    /* RETVAL =  (RETVAL == LZMA_STREAM_END ? LZMA_OK : RETVAL) ; */
    s->last_error = RETVAL ;

    s->compressedBytes    += cur_length + increment - s->stream.avail_out ;

    if (RETVAL == LZMA_STREAM_END) {
        SvPOK_only(output);
        SvCUR_set(output, cur_length + increment - s->stream.avail_out) ;
        SvSETMAGIC(output);
    }
    OUTPUT:
	RETVAL


uLong
compressedBytes(s)
    Compress::Raw::Lzma::Encoder	s
    CODE:
        //bool is_tainted = getTaint1;
        RETVAL = s->compressedBytes;
  OUTPUT:
	RETVAL

uLong
uncompressedBytes(s)
    Compress::Raw::Lzma::Encoder	s
    CODE:
        //bool is_tainted = getTaint1;
        RETVAL = s->uncompressedBytes;
  OUTPUT:
	RETVAL



MODULE = Compress::Raw::Lzma PACKAGE = Compress::Raw::Lzma

void
lzma_auto_decoder(Class, flags, bufsize, memlimit=UINT64_MAX, fl=0)
    const char* Class
    int flags
    int fl
    uint64_t memlimit
    uLong bufsize
  ALIAS:
    lzma_stream_decoder = 1
    lzma_alone_decoder  = 2
  PPCODE:
  {
    int err = LZMA_OK ;
    inflateStream s = NULL;
    if ((s = InitStream() )) {
        if (ix == 0)
            err = lzma_auto_decoder ( &(s->stream), memlimit, fl );
        else if (ix == 1)
            err = lzma_stream_decoder ( &(s->stream), memlimit, fl );
        else if (ix == 2)
            err = lzma_alone_decoder ( &(s->stream), memlimit );

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
	}
	if (s) {
            //s->is_tainted = is_tainted;
	    PostInitStream(s, flags, bufsize) ;
        }
    }
    else
        err = LZMA_MEM_ERROR ;

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }

void
lzma_raw_decoder(Class, flags, bufsize, filters, properties)
    const char* Class
    int flags
    uLong bufsize
    AV* filters
    const char* properties
  PPCODE:
  {
    int err = LZMA_OK ;
    inflateStream s = NULL;
    if ((s = InitStream() )) {

        if (! setupFilters(s, filters, properties)) {
            Safefree(s) ;
            s = NULL ;
        }

        err = lzma_raw_decoder ( &(s->stream), (const lzma_filter*)&s->filters );

        if (err != LZMA_OK) {
            Safefree(s) ;
            s = NULL ;
	}
	if (s) {
            //s->is_tainted = is_tainted;
	    PostInitStream(s, flags, bufsize) ;
        }
    }
    else
        err = LZMA_MEM_ERROR ;

    {
        SV* obj = sv_setref_pv(sv_newmortal(), Class, (void*)s);
        //if (is_tainted)
            //setTainted(obj);
        XPUSHs(obj);
    }
    if (GIMME_V == G_ARRAY) {
        SV * sv = sv_2mortal(newSViv(err)) ;
        setDUALstatus(sv, err);
        //if (is_tainted)
            //setTainted(sv);
        XPUSHs(sv) ;
    }
  }

MODULE = Compress::Raw::Lzma::Decoder PACKAGE = Compress::Raw::Lzma::Decoder

void
DESTROY(s)
    Compress::Raw::Lzma::Decoder	s
  CODE:
    lzma_end(&s->stream) ;
    destroyStream(s) ;


DualType
code (s, buf, output)
    Compress::Raw::Lzma::Decoder	s
    SV *	buf
    SV * 	output
    uInt	cur_length = 0;
    uInt	prefix_length = 0;
    uInt	increment = 0;
    uInt    bufinc = NO_INIT
    STRLEN  na = NO_INIT ;
    STRLEN  origlen = NO_INIT
  PREINIT:
#ifdef UTF8_AVAILABLE
    bool	out_utf8  = FALSE;
#endif
  CODE:
    //bool is_tainted = getTaint3;
    //if (is_tainted)
        //setTainted(output);
    bufinc = s->bufsize;
    /* If the buffer is a reference, dereference it */
    buf = deRef(buf, (char*)"inflate") ;

    if (s->flags & FLAG_CONSUME_INPUT) {
        if (SvREADONLY(buf))
            croak(UNCOMPRESS_CLASS "::code input parameter cannot be read-only when ConsumeInput is specified");
        SvPV_force(buf, na);
    }
#ifdef UTF8_AVAILABLE
    if (DO_UTF8(buf) && !sv_utf8_downgrade(buf, 1))
         croak("Wide character in " UNCOMPRESS_CLASS "::code input parameter");
#endif

    /* initialise the input buffer */
    s->stream.next_in = (uint8_t*)SvPV_nomg(buf, origlen) ;
    s->stream.avail_in = origlen;

    /* and retrieve the output buffer */
    output = deRef_l(output, (char*)"inflate") ;
#ifdef UTF8_AVAILABLE
    if (DO_UTF8(output))
         out_utf8 = TRUE ;
    if (DO_UTF8(output) && !sv_utf8_downgrade(output, 1))
         croak("Wide character in " UNCOMPRESS_CLASS "::code output parameter");
#endif
    if((s->flags & FLAG_APPEND_OUTPUT) == FLAG_APPEND_OUTPUT) {
        SvOOK_off(output);
    } else {
        SvCUR_set(output, 0);
    }


    /* Assume no output buffer - the code below will update if there is any available */
    s->stream.avail_out = 0;


    if (SvLEN(output)) {
        prefix_length = cur_length =  SvCUR(output) ;

        if (s->flags & FLAG_LIMIT_OUTPUT && SvLEN(output) - cur_length - 1 < bufinc)
        {
            Sv_Grow(output, bufinc + cur_length + 1) ;
        }

        /* Only setup the stream output pointers if there is spare
           capacity in the outout SV
        */
        if (SvLEN(output) > cur_length + 1)
        {
            s->stream.next_out = (uint8_t*) SvPVX(output) + cur_length;
            increment = SvLEN(output) -  cur_length - 1;
            s->stream.avail_out = increment;
        }
    }


    s->bytesInflated = 0;

    while (1) {

        if (s->stream.avail_out == 0) {
	    /* out of space in the output buffer so make it bigger */
            s->stream.next_out = (uint8_t*)Sv_Grow(output, SvLEN(output) + bufinc + 1) ;
            cur_length += increment ;
            s->stream.next_out += cur_length ;
            increment = bufinc ;
            s->stream.avail_out = increment;
            bufinc *= 2 ;
        }

        RETVAL = lzma_code(&(s->stream), LZMA_RUN);

        if (s->flags & FLAG_LIMIT_OUTPUT) {
            if (RETVAL == LZMA_BUF_ERROR && s->stream.avail_in == 0) {
                RETVAL = LZMA_OK ;
                //continue;
            }

            break;
        }

        if (RETVAL == LZMA_BUF_ERROR) {
            if (s->stream.avail_out == 0)
                continue ;
            if (s->stream.avail_in == 0) {
                RETVAL = LZMA_OK ;
                break ;
            }
        }

        if (RETVAL != LZMA_OK)
            break;
    }

    s->last_error = RETVAL ;
    if (RETVAL == LZMA_OK || RETVAL == LZMA_STREAM_END || RETVAL == LZMA_BUF_ERROR) {
	    unsigned in ;

        s->bytesInflated = cur_length + increment - s->stream.avail_out - prefix_length;
        s->uncompressedBytes += s->bytesInflated ;
        s->compressedBytes   += origlen - s->stream.avail_in  ;

        SvPOK_only(output);
        SvCUR_set(output, prefix_length + s->bytesInflated) ;
	*SvEND(output) = '\0';
#ifdef UTF8_AVAILABLE
        if (out_utf8)
            sv_utf8_upgrade(output);
#endif
        SvSETMAGIC(output);

	/* fix the input buffer */
	if (s->flags & FLAG_CONSUME_INPUT || s->flags & FLAG_LIMIT_OUTPUT) {
	    in = s->stream.avail_in ;
	    SvCUR_set(buf, in) ;
	    if (in)
	        Move(s->stream.next_in, SvPVX(buf), in, char) ;
            *SvEND(buf) = '\0';
            //if (is_tainted)
                //setTainted(buf);
            SvSETMAGIC(buf);
	}
    }
    OUTPUT:
	RETVAL

uLong
compressedBytes(s)
    Compress::Raw::Lzma::Decoder	s
    CODE:
        //bool is_tainted = getTaint1;
        RETVAL = s->compressedBytes;
  OUTPUT:
	RETVAL

uLong
uncompressedBytes(s)
    Compress::Raw::Lzma::Decoder	s
    CODE:
        //bool is_tainted = getTaint1;
        RETVAL = s->uncompressedBytes;
  OUTPUT:
	RETVAL

MODULE = Lzma::Filter PACKAGE = Lzma::Filter

int
id(filter)
    Lzma::Filter    filter
  CODE:
    RETVAL = filter->filter.id;
  OUTPUT:
	RETVAL

void
DESTROY(s)
    Lzma::Filter s
  CODE:
    if (s->filter.options)
        Safefree(s->filter.options) ;
    if (s->dict)
        SvREFCNT_dec(s->dict);
    Safefree(s) ;


MODULE = Lzma::Filter::Lzma PACKAGE = Lzma::Filter::Lzma

Lzma::Filter::Lzma
_mk(want_lzma2, dict_size, lc, lp, pb, mode, nice_len, mf, depth, preset_dict)
    bool want_lzma2
    uint32_t dict_size
    uint32_t lc
    uint32_t lp
    uint32_t pb
    lzma_mode mode
    uint32_t nice_len
    lzma_match_finder mf
    uint32_t depth
    SV* preset_dict
    CODE:
        lzma_options_lzma* p;
        size_t preset_len = 0;
        ZMALLOC(RETVAL, di_filter) ;
        RETVAL->filter.id = want_lzma2 ? LZMA_FILTER_LZMA2 : LZMA_FILTER_LZMA1 ;
        ZMALLOC(RETVAL->filter.options, lzma_options_lzma) ;
        p = (lzma_options_lzma*)RETVAL->filter.options;
        setDefaultOptions(p);

        RETVAL->dict = newSVsv( deRef(preset_dict, (char*)"preset dict") );

        p->preset_dict = (const uint8_t*)SvPVbyte_force(RETVAL->dict,preset_len);
        p->preset_dict_size = preset_len;
        if ( p->preset_dict_size == 0 ) {
          SvREFCNT_dec(RETVAL->dict);
          p->preset_dict = NULL;
          RETVAL->dict = NULL;
        }

        p->dict_size = dict_size ;
        p->lc = lc ;
        p->lp = lp ;
        p->pb = pb ;
        p->mode = mode ;
        p->nice_len = nice_len ;
        p->mf = mf ;
        p->depth = depth ;
    OUTPUT:
        RETVAL

Lzma::Filter::Lzma
_mkPreset(want_lzma2, preset)
    bool want_lzma2
    uint32_t preset
    CODE:
        lzma_options_lzma* p;
        ZMALLOC(RETVAL, di_filter) ;
        RETVAL->filter.id = want_lzma2 ? LZMA_FILTER_LZMA2 : LZMA_FILTER_LZMA1 ;
        ZMALLOC(RETVAL->filter.options, lzma_options_lzma) ;
        p = (lzma_options_lzma*)RETVAL->filter.options;
        lzma_lzma_preset(p, preset);
    OUTPUT:
        RETVAL

MODULE = Lzma::Filter::BCJ PACKAGE = Lzma::Filter::BCJ

Lzma::Filter::BCJ
_mk(id, offset=0)
    int id
    int offset
    CODE:
        ZMALLOC(RETVAL, di_filter) ;
        ZMALLOC(RETVAL->filter.options, lzma_options_bcj) ;
        RETVAL->filter.id = id;
        ((lzma_options_bcj*)(RETVAL->filter.options))->start_offset = offset;
    OUTPUT:
        RETVAL

MODULE = Lzma::Filter::Delta PACKAGE = Lzma::Filter::Delta

Lzma::Filter::Delta
_mk(type=LZMA_DELTA_TYPE_BYTE, dist=LZMA_DELTA_DIST_MIN)
    lzma_delta_type type
    uint32_t dist
    CODE:
        ZMALLOC(RETVAL, di_filter) ;
        ZMALLOC(RETVAL->filter.options, lzma_options_delta) ;
        RETVAL->filter.id = LZMA_FILTER_DELTA;
        ((lzma_options_delta*)(RETVAL->filter.options))->type = type;
        ((lzma_options_delta*)(RETVAL->filter.options))->dist = dist;
    OUTPUT:
        RETVAL

MODULE = Compress::Raw::Lzma::Options PACKAGE = Compress::Raw::Lzma::Options

Compress::Raw::Lzma::Options
new()
    CODE:
        ZMALLOC(RETVAL, lzma_options_lzma) ;
        setDefaultOptions(RETVAL);
    OUTPUT:
        RETVAL

lzma_bool
lzma_lzma_preset(s, preset)
    Compress::Raw::Lzma::Options s
    uint32_t preset

void
DESTROY(s)
    Compress::Raw::Lzma::Options s
  CODE:
    Safefree(s) ;

MODULE = Compress::Raw::Lzma PACKAGE = Compress::Raw::Lzma
