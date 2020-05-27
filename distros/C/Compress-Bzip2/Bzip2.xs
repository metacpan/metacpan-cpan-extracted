/* Bzip2.xs -- Bzip2 bindings for Perl5 -- -*- mode: c -*- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <bzlib.h>

#include "const-c.inc"

typedef unsigned char   Bool;

#define True  ((Bool)1)
#define False ((Bool)0)

#define BZ_IO_EOF       (-100)

#define BZERRNO	"Compress::Bzip2::bzerrno"
int global_bzip_errno = 0;

#define BZ_SETERR(obj, eee, infomsg) bzfile_seterror(obj, eee, infomsg)

#define OPEN_STATUS_ISCLOSED 0
#define OPEN_STATUS_READ 1
#define OPEN_STATUS_WRITE 2
#define OPEN_STATUS_WRITESTREAM 3
#define OPEN_STATUS_READSTREAM 4

typedef struct bzFile_s {
  bz_stream strm;
  PerlIO*   handle;
  int       bzip_errno;

  char      bufferOfCompressed[BZ_MAX_UNUSED];
  int       nCompressed;
  int       compressedOffset_addmore;
  int       compressedOffset_takeout;

  char      bufferOfHolding[BZ_MAX_UNUSED];
  int       nHolding;

  char      bufferOfLines[BZ_MAX_UNUSED];
  int       bufferOffset;
  int       nBufferBytes;

  char*     streamBuf;
  int       streamBufSize;
  int       streamBufLen;
  int       streamBufOffset;

  int       open_status;
  int       run_progress;
  int       io_error;
  Bool      pending_io_error;

  Bool      allowUncompressedRead;
  Bool      notCompressed;
  int       scan_BZh9;
  char      BZh9[5];
  int       BZh9_count;

  int       verbosity;
  int       small;
  int       blockSize100k;
  int       workFactor;

  long      total_in;
  long      total_out;
} bzFile ;

typedef bzFile* Compress__Bzip2;

#ifdef CAN_PROTOTYPE
void bzfile_streambuf_set( bzFile* obj, char* buffer, int bufsize );
int bzfile_closeread( bzFile* obj, int abandon );
int bzfile_closewrite( bzFile* obj, int abandon );
int bzfile_read( bzFile* obj, char *bufferOfUncompress, int nUncompress );
#else
void bzfile_streambuf_set( );
int bzfile_closeread( );
int bzfile_closewrite( );
int bzfile_read( );
#endif


static SV* 
#ifdef CAN_PROTOTYPE
deRef(SV * sv, char * string)
#else
deRef(sv, string)
SV * sv ;
char * string;
#endif
{
  SV *last_sv = NULL;

  while(SvROK(sv) && sv != last_sv) {
    last_sv = sv;
    sv = SvRV(sv) ;
    switch(SvTYPE(sv)) {
    case SVt_PVAV:
    case SVt_PVHV:
    case SVt_PVCV:
      croak("%s: buffer parameter is not a SCALAR reference", string);
      break;
    default:
      ;
    }
    /*    if (SvROK(sv))
	  croak("%s: buffer parameter is a reference to a reference", string) ;*/
  }

  if (!SvOK(sv)) croak("%s: buffer parameter is not a SCALAR reference", string);
     /*sv = newSVpv("", 0);*/

  return sv ;
}

static char *bzerrorstrings[] = {
       "OK"
      ,"SEQUENCE_ERROR"
      ,"PARAM_ERROR"
      ,"MEM_ERROR"
      ,"DATA_ERROR"
      ,"DATA_ERROR_MAGIC"
      ,"IO_ERROR"
      ,"UNEXPECTED_EOF"
      ,"OUTBUFF_FULL"
      ,"CONFIG_ERROR"
      ,"???"   /* for future */
      ,"???"   /* for future */
      ,"???"   /* for future */
      ,"???"   /* for future */
      ,"???"   /* for future */
      ,"???"   /* for future */
};


/* memory allocator */
static void*
#ifdef CAN_PROTOTYPE
bzmemalloc(void* opaque, int n, int m)
#else
bzalloc(opaque,n,m) void* opaque; int n; int m;
#endif
{
  New(0,opaque,n*m,char);
  return opaque;
}

/* memory deallocator */
static void
#ifdef CAN_PROTOTYPE
bzmemfree(void* opaque, void* p)
#else
bzfree(opaque, p) void* opaque; void* p;
#endif
{
  Safefree(p);
}

int
#ifdef CAN_PROTOTYPE
bzfile_seterror(bzFile* obj, int error_num, char *error_info)
#else
bzfile_seterror(obj, error_num, error_info)
bzFile* obj;
int error_num;
char* error_info;
#endif
{
  char *errstr ;
  SV * bzerror_sv = perl_get_sv(BZERRNO, FALSE) ;

  global_bzip_errno = error_num;
  sv_setiv(bzerror_sv, error_num) ; /* set the integer part of the perl thing */

  errstr = error_num * -1 < 0 || error_num * -1 > 9 ? "Unknown" : (char *) bzerrorstrings[ error_num * -1 ];

  if ( obj != NULL ) {
    obj->bzip_errno = error_num;
    obj->io_error = error_num == BZ_IO_ERROR ? errno : 0;
  }

  /* set the string part of the perl thing */
  if ( error_info == NULL ) {
    if (error_num == BZ_IO_ERROR)
      sv_setpvf(bzerror_sv, "%s (%d): %d %s", errstr, error_num, errno, Strerror(errno));
    else
      sv_setpvf(bzerror_sv, "%s (%d)", errstr, error_num);
  }
  else {
    if (error_num == BZ_IO_ERROR)
      sv_setpvf(bzerror_sv, "%s (%d): %s - %d %s", errstr, error_num, error_info, errno, Strerror(errno));
    else
      sv_setpvf(bzerror_sv, "%s (%d): %s", errstr, error_num, error_info);
  }

  SvIOK_on(bzerror_sv) ;	/* say "I AM INTEGER (too)" */

  return error_num;
}

#ifdef CAN_PROTOTYPE
PerlIO* bzfile_getiohandle( bzFile *obj ) {
#else
PerlIO* bzfile_getiohandle( obj ) bzFile *obj; {
#endif
  return obj->handle;
}

#ifdef CAN_PROTOTYPE
Bool bzfile_error( bzFile *obj ) {
#else
Bool bzfile_error( obj ) bzFile *obj; {
#endif
  return obj != NULL ? ( obj->bzip_errno ? True : False ) : global_bzip_errno ? True : False;
}

#ifdef CAN_PROTOTYPE
int bzfile_geterrno( bzFile *obj ) {
#else
int bzfile_geterrno( obj ) bzFile *obj; {
#endif
  return obj == NULL ? global_bzip_errno : obj->bzip_errno;
}

#ifdef CAN_PROTOTYPE
const char *bzfile_geterrstr( bzFile *obj ) {
#else
const char *bzfile_geterrstr( obj ) bzFile *obj; {
#endif
  int error_num = obj == NULL ? global_bzip_errno : obj->bzip_errno;
  char *errstr = error_num * -1 < 0 || error_num * -1 > 9 ? "Unknown" : (char *) bzerrorstrings[ error_num * -1 ];
  return errstr;
}

#ifdef CAN_PROTOTYPE
Bool bzfile_eof( bzFile *obj ) {
#else
Bool bzfile_eof( obj ) bzFile *obj; {
#endif
  return obj == NULL ? False :
    obj->bzip_errno == BZ_UNEXPECTED_EOF ? True :
    obj->bzip_errno == BZ_OK && obj->pending_io_error && obj->io_error == BZ_IO_EOF ? True :
    obj->bzip_errno != BZ_IO_ERROR ? False :
    obj->io_error == BZ_IO_EOF ? True : False;
}

#ifdef CAN_PROTOTYPE
long bzfile_total_in( bzFile *obj ) {
#else
long bzfile_total_in( obj ) bzFile *obj; {
#endif
  return obj == NULL ? 0 : obj->total_in;
}

#ifdef CAN_PROTOTYPE
long bzfile_total_out( bzFile *obj ) {
#else
long bzfile_total_out( obj ) bzFile *obj; {
#endif
  return obj == NULL ? 0 : obj->total_out;
}

#ifdef CAN_PROTOTYPE
long bzfile_clear_totals( bzFile *obj ) {
#else
long bzfile_clear_totals( obj ) bzFile *obj; {
#endif
  if (obj) {
    obj->total_in = 0;
    obj->total_out = 0;
  }
  return 0;
}

#ifdef CAN_PROTOTYPE
int bzfile_clearerr( bzFile *obj ) {
#else
int bzfile_clearerr( obj ) bzFile *obj; {
#endif
  int error_num = obj == NULL ? global_bzip_errno : obj->bzip_errno;
  int clear_flag = 1;

  if ( error_num == BZ_IO_ERROR ) {
    if (obj)
      PerlIO_clearerr( obj->handle );
  }
  else if ( error_num == BZ_SEQUENCE_ERROR ) {
    /* program error */
  }
  else if ( error_num == BZ_PARAM_ERROR ) {
    /* program error */
  }
  else if ( error_num == BZ_MEM_ERROR ) {
    clear_flag = 0;		/* must close */
  }
  else if ( error_num == BZ_DATA_ERROR ) {
    clear_flag = 0;		/* must close or flush */
  }
  else if ( error_num == BZ_DATA_ERROR_MAGIC ) {
    clear_flag = 0;		/* must close or flush */
  }
  else if ( error_num == BZ_UNEXPECTED_EOF ) {
    clear_flag = 0;		/* must close */
  }
  else if ( error_num == BZ_OUTBUFF_FULL ) {
  }
  else if ( error_num == BZ_CONFIG_ERROR ) {
    clear_flag = 0;		/* we don't like the version of bzlib */
  }
  else if ( error_num == BZ_OK ) {
    if ( obj && obj->pending_io_error ) {
      if ( obj->io_error == BZ_IO_EOF ) {
	PerlIO_clearerr( obj->handle );
	clear_flag = 0;
      }
    }
    else {
      clear_flag = 0;		/* this is a state, not an error */
      return 1;			/* but return success anyways */
    }
  }
  else if ( error_num == BZ_RUN_OK ) {
    clear_flag = 0;		/* this is a state, not an error */
  }
  else if ( error_num == BZ_FLUSH_OK ) {
    clear_flag = 0;		/* this is a state, not an error */
  }
  else if ( error_num == BZ_FINISH_OK ) {
    clear_flag = 0;		/* this is a state, not an error */
  }
  else if ( error_num == BZ_STREAM_END ) {
    clear_flag = 0;		/* this is a state, not an error */
  }

  if ( clear_flag ) {
    if ( obj ) {
      obj->bzip_errno = 0;
      obj->io_error = 0;
      obj->pending_io_error = False;
    }

    global_bzip_errno = 0;
  }

  return clear_flag;
}

#ifdef CAN_PROTOTYPE
bzFile* bzfile_new( int verbosity, int small, int blockSize100k, int workFactor ) {
#else
bzFile* bzfile_new( verbosity, small, blockSize100k, workFactor )
  int verbosity; int small; int blockSize100k; int workFactor; {
#endif
  bzFile* obj = NULL;

  /* creates a new bzFile object */
  /* sets parameters */

  if (small != 0 && small != 1) {
    BZ_SETERR(NULL, BZ_PARAM_ERROR, "bzfile_new small out of range");
    return NULL;
  }
  if (verbosity < 0 || verbosity > 4) {
    BZ_SETERR(NULL, BZ_PARAM_ERROR, "bzfile_new verbosity out of range");
    return NULL;
  }

  Newz(idthing, obj, 1, bzFile);
  if (!obj) {
    BZ_SETERR(NULL, BZ_IO_ERROR, NULL);
    die( "Out of memory");
    return NULL;
  }

  BZ_SETERR(obj, BZ_OK, NULL);

  obj->open_status   = OPEN_STATUS_ISCLOSED;
  obj->run_progress  = 0;
  obj->io_error      = 0;
  obj->pending_io_error = False;
  obj->handle        = NULL;
  obj->nCompressed   = 0;
  obj->compressedOffset_addmore = 0;
  obj->compressedOffset_takeout = 0;
  obj->verbosity     = verbosity;
  obj->small         = small;
  obj->blockSize100k = blockSize100k;
  obj->workFactor    = workFactor;

  obj->bufferOffset  = 0;
  obj->nBufferBytes  = 0;

  obj->bzip_errno    = 0;
   
  obj->total_in      = 0;
  obj->total_out     = 0;

  obj->strm.bzalloc  = bzmemalloc;
  obj->strm.bzfree   = bzmemfree;
  obj->strm.opaque   = NULL;

  obj->allowUncompressedRead = False;

  bzfile_streambuf_set( obj, NULL, 0 );

  if (obj->verbosity >= 4)
    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_new(%d,%d,%d,%d) called %p\n", verbosity, small, blockSize100k, workFactor, obj);

  return obj;   
}

#ifdef CAN_PROTOTYPE
void bzfile_free( bzFile* obj ) {
#else
void bzfile_free( obj ) bzFile* obj; {
#endif
  if ( obj != NULL ) Safefree((void*) obj);
}

/* query and/or set param setting of bzFile */
/* param may be verbosity, small, blockSize100k or workFactor */
/* if setting is -1, the param is not changed, but the current value is returned */
/* returns -1 on error */
#ifdef CAN_PROTOTYPE
int bzfile_setparams( bzFile* obj, char* param, int setting ) {
#else
int bzfile_setparams( obj, param, setting ) bzFile* obj; char* param; int setting; {
#endif
  int savsetting = -1;

  if ( param[0] == '-' ) param++;
  if ( param[0] == '-' ) param++;

  if ( strEQ( param, "verbosity" ) ) {
    savsetting = obj->verbosity;

    if ( setting >= 0 && setting <= 4 )
      obj->verbosity = setting;
    else if ( setting != -1 ) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
      savsetting = -1;
    }
  }
  else if ( strEQ( param, "buffer" ) ) {
    savsetting = BZ_MAX_UNUSED;
  }
  else if ( strEQ( param, "small" ) ) {
    savsetting = obj->small;

    if ( setting == 0 || setting == 1 )
      obj->small = setting;
    else if ( setting != -1 ) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
      savsetting = -1;
    }
  }
  else if ( strEQ( param, "blockSize100k" ) || strEQ( param, "level" ) ) {
    savsetting = obj->blockSize100k;

    if ( setting >= 1 && setting <= 9 )
      obj->blockSize100k = setting;
    else if ( setting != -1 ) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
      savsetting = -1;
    }
  }
  else if ( strEQ( param, "workFactor" ) ) {
    savsetting = obj->workFactor;

    if ( setting >= 0 && setting <= 250 )
      obj->workFactor = setting;
    else if ( setting != -1 ) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
      savsetting = -1;
    }
  }
  else if ( strEQ( param, "readUncompressed" ) ) {
    savsetting = obj->allowUncompressedRead ? 1 : 0;

    if ( setting >= 0 && setting <= 1 )
      obj->allowUncompressedRead = setting ? True : False;
    else if ( setting != -1 ) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
      savsetting = -1;
    }
  }
  else {
    BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
    savsetting = -1;
  }

  if (obj->verbosity>1) {
    if ( savsetting == -1 )
      PerlIO_printf(PerlIO_stderr(), "debug: bzfile_setparams invalid param %s => %d\n", param, setting);
    else
      if ( setting == -1 )
	PerlIO_printf(PerlIO_stderr(), "debug: bzfile_setparams query %s is %d\n", param, savsetting);
      else
	PerlIO_printf(PerlIO_stderr(), "debug: bzfile_setparams set %s (is %d) => %d\n", param, savsetting, setting);
  }
  return savsetting;
}

#ifdef CAN_PROTOTYPE
bzFile* bzfile_open( char *filename, char *mode, bzFile *obj ) {
#else
bzFile* bzfile_open( filename, mode, obj ) char *filename; char *mode; bzFile *obj; {
#endif
  PerlIO *io;

  io = PerlIO_open( filename, mode );
  if ( io == NULL ) {
    BZ_SETERR(obj, BZ_IO_ERROR, NULL);

    if (obj && obj->verbosity > 0) warn( "Error: PerlIO_open( %s, %s ) failed: %s\n", filename, mode, Strerror(errno) );

    return NULL;
  }

#if defined(_WIN32) || defined(OS2) || defined(MSDOS) || defined(__CYGWIN__) || defined(WIN32)
  PerlIO_binmode(aTHX_ io, mode[0]=='w' ? '>' : '<', O_BINARY, Nullch);
#endif

  if ( obj == NULL ) obj = bzfile_new( 0, 0, 9, 0 );

  obj->handle = io;
  obj->open_status = mode && mode[0] == 'w' ? OPEN_STATUS_WRITE : OPEN_STATUS_READ;

  if (obj->verbosity>=2)
    PerlIO_printf(PerlIO_stderr(), "Info: PerlIO_open( %s, %s ) succeeded, obj=%p\n", filename, mode, obj );

  return obj;
}

#ifdef CAN_PROTOTYPE
bzFile* bzfile_fdopen( PerlIO *io, char *mode, bzFile *obj ) {
#else
bzFile* bzfile_fdopen( io, mode, obj ) PerlIO *io; char *mode; bzFile *obj; {
#endif

  if ( io == NULL ) {
    BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);
    return NULL;
  }

#if defined(_WIN32) || defined(OS2) || defined(MSDOS) || defined(__CYGWIN__) || defined(WIN32)
  PerlIO_binmode(aTHX_ io, mode[0]=='w' ? '>' : '<', O_BINARY, Nullch);
#endif

  if ( obj == NULL ) obj = bzfile_new( 0, 0, 9, 0 );

  obj->handle = io;
  obj->open_status = mode && mode[0] == 'w' ? OPEN_STATUS_WRITE : OPEN_STATUS_READ;

  return obj;
}

#ifdef CAN_PROTOTYPE
bzFile* bzfile_openstream( char *mode, bzFile *obj ) {
#else
bzFile* bzfile_openstream( mode, obj ) char *mode; bzFile *obj; {
#endif
  if ( obj == NULL ) obj = bzfile_new( 0, 0, 1, 0 );
  if ( obj == NULL ) return NULL;

  obj->open_status = mode && mode[0] == 'w' ? OPEN_STATUS_WRITESTREAM : OPEN_STATUS_READSTREAM;

  return obj;
}

#ifdef CAN_PROTOTYPE
void bzfile_streambuf_deposit( bzFile* obj, char* buffer, int buflen ) {
#else
void bzfile_streambuf_deposit( obj, buffer, buflen ) bzFile* obj; char* buffer; int buflen; {
#endif
  /* inflate */
  /* insert compressed data into reading stream */
  obj->streamBuf = buffer;
  obj->streamBufSize = buflen;
  obj->streamBufLen = buflen;
  obj->streamBufOffset = 0;
}

#ifdef CAN_PROTOTYPE
int bzfile_streambuf_read( bzFile* obj, char* out, int outlen ) {
#else
int bzfile_streambuf_read( obj, out, outlen ) bzFile* obj; char* out; int outlen; {
#endif
  /* inflate */
  /* read compressed data from buffer */
  char *in;
  int i;
  int n = obj->streamBufLen - obj->streamBufOffset;

  if (obj->verbosity>=4)
    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_streambuf_read( %p, %d ), buffer %p, sz=%d, len=%d, offset=%d\n",
		  out, outlen, obj->streamBuf, obj->streamBufSize, obj->streamBufLen, obj->streamBufOffset );

  if ( n <= 0 ) {
    /* EAGAIN */
    errno = EAGAIN;
    return -1;
  }

  in = obj->streamBuf + obj->streamBufOffset;

  for ( i=0; i<outlen && i<n; i++)
    *out++ = *in++;

  obj->streamBufOffset += i;

  return i;
}

#ifdef CAN_PROTOTYPE
void bzfile_streambuf_set( bzFile* obj, char* buffer, int bufsize ) {
#else
void bzfile_streambuf_set( obj, buffer, bufsize ) bzFile* obj; char* buffer; int bufsize; {
#endif
  /* deflate */
  obj->streamBuf = buffer;
  obj->streamBufSize = bufsize;
  obj->streamBufLen = 0;
  obj->streamBufOffset = 0;
}

#ifdef CAN_PROTOTYPE
int bzfile_streambuf_write( bzFile* obj, char* in, int inlen ) {
#else
int bzfile_streambuf_write( obj, in, inlen ) bzFile* obj; char* in; int inlen; {
#endif
  /* deflate */
  /* write compressed data to buffer */

  char *out;
  int i;
  int available_space = obj->streamBufSize - obj->streamBufLen;

  if (obj->verbosity>=4)
    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_streambuf_write( %p, %d ), buffer %p, sz=%d, len=%d, offset=%d\n",
		  in, inlen, obj->streamBuf, obj->streamBufSize, obj->streamBufLen, obj->streamBufOffset );

  if ( available_space <= 0 ) {
    errno = EAGAIN;
    return -1;	/* EAGAIN */
  }

  out = obj->streamBuf + obj->streamBufOffset;

  for ( i=0; i<inlen && i<available_space; i++)
    *out++ = *in++;

  obj->streamBufLen += i;

  return i;
}

#ifdef CAN_PROTOTYPE
int bzfile_streambuf_collect( bzFile* obj, char* out, int outlen ) {
#else
int bzfile_streambuf_collect( obj, out, outlen ) bzFile* obj; char* out; int outlen; {
#endif
  /* deflate */
  /* pull collected compressed data from buffer */
  int ret;

  ret = bzfile_streambuf_read( obj, out, outlen );

  if ( ret == -1 ) {
    /* got all the data out, reset the counters */
    obj->streamBufLen = 0;
    obj->streamBufOffset = 0;
  }

  return ret;
}

/* success: 0 returned */
/* failure: -1 returned, global error set */
/* other error: -2 returned, global error already set */
#ifdef CAN_PROTOTYPE
int bzfile_flush( bzFile* obj ) {
#else
int bzfile_flush( obj ) bzFile* obj; {
#endif
  int error_num = bzfile_geterrno( obj );
  int tracker;
  int compressed_bytes_count;

  if ( obj == NULL ) return 0;
  if ( obj->run_progress == 0 || obj->run_progress == 10 ) return 0;

  if (obj->verbosity>=4)
    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_flush called, error_num=%d, open_status %d\n",
		  error_num, obj->open_status);

  if ( error_num == BZ_OK ) {
  }
  else if ( error_num == BZ_IO_ERROR ) {
    if ( obj->io_error == EAGAIN || obj->io_error == EINTR ) {
      obj->io_error = 0;
      BZ_SETERR(obj, BZ_OK, NULL);
    }
    else if ( obj->io_error == BZ_IO_EOF ) {
      PerlIO_clearerr( obj->handle );
    }
    else {
      return -2;
    }
  }
  else if ( error_num == BZ_DATA_ERROR ) {
    /* a read error */
  }
  else if ( error_num == BZ_UNEXPECTED_EOF ) {
    /* a read error */
  }
  else if ( error_num == BZ_OUTBUFF_FULL ) {
    /* only when compressing or decompressing a buffer */
    return -2;
  }
  else {
    return -2;
  }

  if (obj->open_status == OPEN_STATUS_WRITE || obj->open_status == OPEN_STATUS_WRITESTREAM) {
    int ret = BZ_OK;

    while (True) {
      obj->strm.next_out = obj->bufferOfCompressed + obj->compressedOffset_addmore;
      obj->strm.avail_out = sizeof(obj->bufferOfCompressed) - obj->compressedOffset_addmore;

      if (obj->verbosity>=4)
	PerlIO_printf(PerlIO_stderr(), "debug: bzfile_flush: call to BZ2_bzCompress with avail_in %d, next_in %p, avail_out %d, next_out %p, run_progress %d\n",
		      obj->strm.avail_in, obj->strm.next_in, obj->strm.avail_out, obj->strm.next_out, obj->run_progress);

      compressed_bytes_count = obj->strm.avail_out;
      tracker = obj->strm.avail_in;

      if ( obj->strm.avail_out <= 0 || obj->run_progress > 2 )
	ret = obj->run_progress <= 2 ? BZ_FLUSH_OK : BZ_RUN_OK;
      else {
	ret = BZ2_bzCompress( &(obj->strm), BZ_FLUSH );
	if ( ret == BZ_RUN_OK ) obj->run_progress = 3;
      }

      if (ret != BZ_RUN_OK && ret != BZ_FLUSH_OK) {
	BZ_SETERR(obj, ret, NULL);

	if (obj->verbosity>1)
	  warn("Error: bzfile_flush, BZ2_bzCompress error %d, strm is %p, strm.state is %p, in state %d\n",
	       ret, &(obj->strm), obj->strm.state, *((int*)obj->strm.state));

	return -1;
      }

      obj->total_in += tracker - obj->strm.avail_in;
      compressed_bytes_count -= obj->strm.avail_out;
      obj->compressedOffset_addmore += compressed_bytes_count;
      obj->nCompressed += compressed_bytes_count;

      if (obj->verbosity>=4)
	PerlIO_printf(PerlIO_stderr(), "debug: bzfile_flush BZ2_bzCompress, took in %d, put out %d bytes, ret %d\n",
		      tracker-obj->strm.avail_in, compressed_bytes_count, ret);

      if ( obj->nCompressed ) {
	int n, n2;

	n = obj->nCompressed;

	while ( n > 0 ) {
	  if ( obj->open_status == OPEN_STATUS_WRITESTREAM )
	    n2 = bzfile_streambuf_write( obj, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	  else
	    if ( obj->handle )
	      n2 = PerlIO_write( obj->handle, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	    else
	      n2 = n;

	  if ( n2==-1 ) {
	    BZ_SETERR(obj, BZ_IO_ERROR, NULL);

	    if ( errno != EINTR && errno != EAGAIN ) {
	      if (obj->verbosity>0)
		warn("Error: bzfile_flush io error %d '%s'\n", errno, Strerror(errno));
	    }
	    else {
	      if (obj->verbosity>=4)
		PerlIO_printf(PerlIO_stderr(), "debug: bzfile_flush: file write error %s\n", Strerror(errno));
	    }

	    return -1;
	  }
	  else {
	    if (obj->verbosity>=4)
	      PerlIO_printf(PerlIO_stderr(), "debug: bzfile_flush: file write took in %d, put out %d\n", n, n2);

	    obj->compressedOffset_takeout += n2;
	    obj->nCompressed -= n2;
	    n -= n2;

	    obj->total_out += n2;
	  }
	}

	obj->nCompressed = 0;
	obj->compressedOffset_addmore = 0;
	obj->compressedOffset_takeout = 0;
      }

      if (obj->verbosity>1)
	PerlIO_printf(PerlIO_stderr(), "Info: bzfile_flush ret %d, total written %ld\n", ret, obj->total_out );

      if (ret == BZ_RUN_OK) {
	obj->run_progress = 1;
	break;
      }
    }

    if ( obj->handle && !PerlIO_error( obj->handle ) ) {
      /* ok, we got bzip flushed out, now flush out the IO buffers themselves */
      if ( -1 == PerlIO_flush( obj->handle ) ) {
	BZ_SETERR(obj, BZ_IO_ERROR, NULL);
	return -1;
      }
    }
  }
  else {
    /* decompressing from a read IO handle */

    obj->nBufferBytes = 0;	/* toss getreadline data */
    /* can't flush the file handle, that will cause the compression stream to break up */
    /* the program will be unable to uncompress subsequent data, up to the next checkpoint */

    if ( error_num == BZ_DATA_ERROR ) {
      /* a read error */
      /* could look ahead for that 49 bit pattern ... */
      return -2;		/* for now */
    }
    else if ( error_num == BZ_UNEXPECTED_EOF ) {
      return -2;
    }
  }

  return 0;
}

#ifdef CAN_PROTOTYPE
int bzfile_close( bzFile* obj, int abandon ) {
#else
int bzfile_close( obj, abandon ) bzFile* obj; int abandon; {
#endif
  /* returns zero on success, -1 on error */
  int ret;

  if ( obj->open_status == OPEN_STATUS_ISCLOSED ) {
    BZ_SETERR(obj, BZ_SEQUENCE_ERROR, NULL);
    return -1;
  }

  if (obj->open_status == OPEN_STATUS_WRITE || obj->open_status == OPEN_STATUS_WRITESTREAM)
    ret = bzfile_closewrite( obj, abandon );
  else
    ret = bzfile_closeread( obj, abandon );

  if ( ret == BZ_OK ) obj->open_status = OPEN_STATUS_ISCLOSED;

  return ret != BZ_OK ? -1 : 0;
}

#ifdef CAN_PROTOTYPE
int bzfile_closeread( bzFile* obj, int abandon ) {
#else
int bzfile_closeread( obj, abandon ) bzFile* obj; int abandon; {
#endif
  int ret = BZ_OK;

  if (obj->open_status == OPEN_STATUS_WRITE || obj->open_status == OPEN_STATUS_WRITESTREAM)
    return BZ_SETERR(obj, BZ_SEQUENCE_ERROR, NULL);

  if ( obj->run_progress!=0 && obj->run_progress!=10 )
    ret = BZ2_bzDecompressEnd( &(obj->strm) );

  obj->run_progress = 0;
  obj->nBufferBytes = 0;	/* toss getreadline data */
  obj->pending_io_error = False;

  if ( obj->handle )
    if ( 0 != PerlIO_close( obj->handle ) )
      ret = BZ_SETERR(obj, BZ_IO_ERROR, NULL);

  return BZ_SETERR(obj, ret, NULL);
}

#ifdef CAN_PROTOTYPE
int bzfile_closewrite( bzFile* obj, int abandon ) {
#else
int bzfile_closewrite( obj, abandon ) bzFile* obj; int abandon; {
#endif
  int error_num = bzfile_geterrno( obj );
  int ret = BZ_OK;
  int tracker;
  int compressed_bytes_count;

  if (obj->verbosity>=2)
    PerlIO_printf(PerlIO_stderr(), "Info: bzfile_closewrite called, abandon=%d, error_num=%d, open_status %d\n",
		  abandon, error_num, obj->open_status);

  if ( obj == NULL ) return BZ_SETERR(NULL, BZ_OK, NULL);
  if (obj->open_status != OPEN_STATUS_WRITE && obj->open_status != OPEN_STATUS_WRITESTREAM)
    return BZ_SETERR(obj, BZ_SEQUENCE_ERROR, NULL);

  if ( error_num == BZ_OK ) {
  }
  else if ( error_num == BZ_IO_ERROR ) {
    if ( obj->io_error == EAGAIN || obj->io_error == EINTR ) {
      obj->io_error = 0;
      BZ_SETERR(obj, BZ_OK, NULL);
    }
    else if ( !abandon )
      return error_num;
  }
  else if ( error_num == BZ_DATA_ERROR ) {
    /* a read error */
    if ( !abandon ) return error_num;
  }
  else if ( error_num == BZ_UNEXPECTED_EOF ) {
    /* a read error */
    if ( !abandon ) return error_num;
  }
  else if ( error_num == BZ_OUTBUFF_FULL ) {
    /* only when compressing or decompressing a buffer */
    if ( !abandon ) return error_num;
  }
  else {
    if ( !abandon ) return error_num;
  }

  if ( obj->run_progress!=0 ) {
    if ( !abandon ) {
      while (True) {
	obj->strm.next_out = obj->bufferOfCompressed + obj->compressedOffset_addmore;
	obj->strm.avail_out = sizeof(obj->bufferOfCompressed) - obj->compressedOffset_addmore;

	if (obj->verbosity>=4)
	  PerlIO_printf(PerlIO_stderr(), "debug: bzfile_closewrite: call to BZ2_bzCompress with avail_in %d, next_in %p, avail_out %d, next_out %p, run_progress %d\n",
			obj->strm.avail_in, obj->strm.next_in, obj->strm.avail_out, obj->strm.next_out, obj->run_progress);

	compressed_bytes_count = obj->strm.avail_out;
	tracker = obj->strm.avail_in;

	if ( obj->strm.avail_out <= 0 || obj->run_progress > 2 )
	  ret = obj->run_progress <= 2 ? BZ_FINISH_OK : BZ_STREAM_END;
	else {
	  ret = BZ2_bzCompress( &(obj->strm), BZ_FINISH );
	  if ( ret == BZ_STREAM_END ) obj->run_progress = 9;
	}

	if (ret != BZ_FINISH_OK && ret != BZ_STREAM_END) {
	  BZ_SETERR(obj, ret, NULL);
	  if (obj->verbosity>=1)
	    PerlIO_printf(PerlIO_stderr(), "Warning: bzfile_closewrite BZ2_bzCompress error %d\n", ret);
	  return ret;
	}

	obj->total_in += tracker - obj->strm.avail_in;
	compressed_bytes_count -= obj->strm.avail_out;
	obj->compressedOffset_addmore += compressed_bytes_count;
	obj->nCompressed += compressed_bytes_count;

	if (obj->verbosity>=4)
	  PerlIO_printf(PerlIO_stderr(), "debug: bzfile_closewrite BZ2_bzCompress, took in %d, put out %d bytes, ret %d\n",
			tracker-obj->strm.avail_in, compressed_bytes_count, ret);

	if ( obj->nCompressed ) {
	  int n, n2;

	  n = obj->nCompressed;
	  
	  while ( n > 0 ) {
	    if ( obj->open_status == OPEN_STATUS_WRITESTREAM )
	      n2 = bzfile_streambuf_write( obj, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	    else
	      if ( obj->handle )
		n2 = PerlIO_write( obj->handle, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	      else
		n2 = n;

	    if ( n2==-1 ) {
	      BZ_SETERR(obj, BZ_IO_ERROR, NULL);

	      if ( errno != EINTR && errno != EAGAIN ) {
		if (obj->verbosity>0)
		  warn("Error: bzfile_closewrite io error %d '%s'\n", errno, Strerror(errno));
	      }
	      else {
		if (obj->verbosity>=4)
		  PerlIO_printf(PerlIO_stderr(), "debug: bzfile_closewrite: file write error %s\n", Strerror(errno));
	      }

	      return BZ_IO_ERROR;
	    }
	    else {
	      if (obj->verbosity>=4)
		PerlIO_printf(PerlIO_stderr(), "debug: bzfile_closewrite: file write took in %d, put out %d\n", n, n2);

	      obj->compressedOffset_takeout += n2;
	      obj->nCompressed -= n2;
	      n -= n2;

	      obj->total_out += n2;
	    }
	  }

	  obj->nCompressed = 0;
	  obj->compressedOffset_addmore = 0;
	  obj->compressedOffset_takeout = 0;
	}

	if (obj->verbosity>1)
	  PerlIO_printf(PerlIO_stderr(), "Info: bzfile_closewrite ret %d, total written %ld\n", ret, obj->total_out );

	if (ret == BZ_STREAM_END) break;
      }
    }

    ret = BZ2_bzCompressEnd ( &(obj->strm) );
    obj->run_progress = 0;
  }

  obj->pending_io_error = False;

  if ( obj->handle )
    if ( 0 != PerlIO_close( obj->handle ) )
      ret = BZ_SETERR(obj, BZ_IO_ERROR, NULL);

  return BZ_SETERR(obj, ret, NULL);
}

#ifdef CAN_PROTOTYPE
int bzfile_readline( bzFile* obj, char *lineOfUncompress, int maxLineLength ) {
#else
int bzfile_readline( obj, lineOfUncompress, maxLineLength ) bzFile* obj; char *lineOfUncompress; int maxLineLength; {
#endif
  int n = 0;
  char *p = NULL;
  int bytes_read = 0;
  char lastch = 0;
  int error_num = 0;
  int done_flag = 0;

  if ( maxLineLength>0 ) lineOfUncompress[0]=0;

  while ( !done_flag && bytes_read < maxLineLength && lastch != '\n' ) {
    if ( obj->nBufferBytes - obj->bufferOffset > 0 ) {
      n = obj->nBufferBytes - obj->bufferOffset;
      p = obj->bufferOfLines + obj->bufferOffset;
    }
    else {
      n = bzfile_read( obj, obj->bufferOfLines, sizeof(obj->bufferOfLines) );
      if ( n < 0 ) {
	error_num = bzfile_geterrno( obj );

	if ( error_num == BZ_IO_ERROR ) {
	  if ( obj->io_error == EINTR || obj->io_error == EAGAIN )
	    continue;
	  done_flag = 1;
	}
	else if ( error_num == BZ_UNEXPECTED_EOF ) {
	  done_flag = 1;
	}
	else {
	  done_flag = 1;
	}
      }
      else if ( n == 0 ) {
	done_flag = 1;
      }

      p = obj->bufferOfLines;
      obj->bufferOffset = 0;
      obj->nBufferBytes = n;
      n = 0;
    }

    if ( obj->nBufferBytes - obj->bufferOffset > 0 ) {
      lastch = *p;
      *lineOfUncompress++ = lastch;
      bytes_read++;
      obj->bufferOffset++;
    }
  }

  if ( done_flag && bytes_read <= 0 && error_num ) return -1;

  if ( maxLineLength>bytes_read ) lineOfUncompress[bytes_read]=0;

  return bytes_read;
}

#ifdef CAN_PROTOTYPE
int bzfile_read_notCompressed( bz_stream* strm, int *scan_BZh9 ) {
#else
int bzfile_read_notCompressed( strm, scan_BZh9 ) bz_stream* strm; int *scan_BZh9; {
#endif
  char ch;

  while ( strm->avail_in>0 && strm->avail_out>0 ) {
    ch = *(strm->next_out++) = *(strm->next_in++);
    strm->avail_in--;
    strm->avail_out--;
    switch (*scan_BZh9) {
    case 0: if ( ch=='B' ) *scan_BZh9=1; break;
    case 1: *scan_BZh9 = ch=='Z' ? 2 : 0; break;
    case 2: *scan_BZh9 = ch=='h' ? 3 : 0; break;
    case 3: *scan_BZh9 = ch-'0'>=1 && ch-'0'<=9 ? ch : 0; break;
    }
  }

  if ( *scan_BZh9 > 4 ) return BZ_DATA_ERROR_MAGIC;

  return BZ_OK;
}

#ifdef CAN_PROTOTYPE
int bzfile_read( bzFile* obj, char *bufferOfUncompress, int nUncompress ) {
#else
int bzfile_read( obj, bufferOfUncompress, nUncompress ) bzFile* obj; char *bufferOfUncompress; int nUncompress; {
#endif
  int ret;
  int tracker, rewind_mark;
  int bytes_uncompressed_count;
  int error_num = bzfile_geterrno( obj );

  if (obj == NULL || bufferOfUncompress == NULL || nUncompress < 0) {
    BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);

    if ( obj != NULL && obj->verbosity>1 ) {
      if ( bufferOfUncompress == NULL ) warn("Error: bzfile_read buf is NULL\n");
      if ( nUncompress < 0 ) warn("Error: bzfile_read n is negative %d\n", nUncompress);
    }

    return -1;
  }
  if (obj->verbosity>=4)
    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_read(obj, %p, %d) obj->open_status=%d\n",
		  bufferOfUncompress, nUncompress, obj->open_status);

  if (obj->open_status == OPEN_STATUS_WRITE || obj->open_status == OPEN_STATUS_WRITESTREAM) {
    BZ_SETERR(obj, BZ_SEQUENCE_ERROR, NULL);

    if ( obj->verbosity>1 ) warn("Error: bzfile_read attempted on a writing stream\n");

    return -1;
  }

  if ( error_num == BZ_OK ) {
    if ( obj->pending_io_error ) {
      if ( obj->io_error == BZ_UNEXPECTED_EOF ) {
	obj->io_error = 0;
	BZ_SETERR(obj, BZ_UNEXPECTED_EOF, NULL);
      }
      else if ( obj->io_error == BZ_IO_EOF ) {
	return 0;
      }
      else {
	errno = obj->io_error;
	obj->io_error = 0;
	BZ_SETERR(obj, BZ_IO_ERROR, NULL);
      }

      obj->pending_io_error = False;
      return -1;
    }
  }
  else if ( error_num == BZ_IO_ERROR ) {
    if ( obj->io_error == EINTR || obj->io_error == EAGAIN ) {
      obj->io_error=0;
      BZ_SETERR(obj, BZ_OK, NULL);
    }
    else
      return -2;
  }
  else if ( error_num == BZ_DATA_ERROR ) {
    /* a read error */
    return -2;
  }
  else if ( error_num == BZ_UNEXPECTED_EOF ) {
    /* a read error */
    return -2;
  }
  else {
    return -2;
  }

  if (nUncompress == 0) return 0;

  BZ_SETERR(obj, BZ_OK, NULL);

  obj->nHolding = 0;
  bytes_uncompressed_count = 0;

  /********************
   * note: obj->run_progress is used to detect proper end of file 
   * an end of file that doesn't have an end-of-stream marker is INVALID and a result of data corruption
   * so, here's the run_progress settings:
   * 0: stream has never been initialized, a call to BZ2_bzDecompressInit is necessary.
   * 1: stream has just been initialized, for the first time.  No data has yet been read.
   * 2: stream has been initialized, data has been read from the file handle.
   * in the middle of processing what is probably a LARGE file:
   * 10: an end of stream marker has been seen, and BZ2_bzDecompressEnd has been called.
   *     before the stream can be used again, a call to BZ2_bzDecompressInit must be made.
   * 11: ready to read more data - BZ2_bzDecompressInit has been called (but no data has been read yet)
   * 12: stream has been initialized, data has been read.
   * the sequence of changes is
   * 0 => 1 => 2 => 10 => 11 => 12
   * A FILE EOF, or PerlIO EOF, is only valid when run_progress is 0 or 10, ie when no data has been read,
   * or just after we've received a valid end-of-stream marker.
   */

  while (True) {
    if ( obj->nBufferBytes - obj->bufferOffset > 0 ) {
      char *p, *s;
      int i,n;

      p = obj->bufferOfLines + obj->bufferOffset; /* point to next byte */
      n = obj->nBufferBytes - obj->bufferOffset; /* count of bytes ready to go */

      /* move as much as we can to the Uncompress hopper */
      for (i=0; i<n && bytes_uncompressed_count+i < nUncompress; i++) bufferOfUncompress[bytes_uncompressed_count+i] = *p++;
      bytes_uncompressed_count+=i;

      n -= i;			/* update number of bytes still to go */
      for (s = obj->bufferOfLines; i < n; i++) *s++ = *p++; /* move remaining bytes to top of the buffer */
      obj->nBufferBytes = n;
      obj->bufferOffset = 0;

      if (bytes_uncompressed_count >= nUncompress) {
	BZ_SETERR(obj, BZ_OK, NULL);
	return bytes_uncompressed_count;
      }
    }

    obj->strm.avail_out = nUncompress - bytes_uncompressed_count;
    obj->strm.next_out = bufferOfUncompress + bytes_uncompressed_count;

    if (obj->strm.avail_in == 0) {
      char *buf = obj->bufferOfCompressed;
      int bufln = sizeof(obj->bufferOfCompressed);

      char *p;
      int i,n;

      if ( obj->nHolding ) {
	/* move held bytes into the hopper */
	p = obj->bufferOfHolding;
	n = obj->nHolding;

	for (i=0; i<n; i++) buf[i] = *p++;
	obj->nHolding = 0;
      }
      else if ( obj->BZh9_count ) {
	/* move header bytes into the hopper */
	p = obj->BZh9;
	n = obj->BZh9_count;

	for (i=0; i<n; i++) buf[i] = *p++;
	obj->BZh9_count = 0;
      }
      else {
	if ( obj->open_status == OPEN_STATUS_READSTREAM )
	  n = bzfile_streambuf_read( obj, buf, bufln );
	else
	  n = PerlIO_read( obj->handle, buf, bufln );

	if (obj->verbosity>=4)
	  PerlIO_printf(PerlIO_stderr(), "debug: bzfile_read file read got %d bytes\n", n);

	if ( n == -1 ) {
	  if ( bytes_uncompressed_count ) {
	    obj->pending_io_error = True;
	    obj->io_error = errno;
	    n = 0;
	  }
	  else {
	    BZ_SETERR(obj, BZ_IO_ERROR, NULL);
	    return -1;
	  }
	}
	else if ( n == 0 ) {
	  /* end of file */
	}
      }

      obj->total_in += n;
      obj->strm.avail_in = obj->nCompressed = n;
      obj->strm.next_in = obj->bufferOfCompressed;
    }

    if ( obj->strm.avail_in == 0 ) {
      /* still zero bytes in the input hopper?  why? ... */
      if ( !obj->pending_io_error ) {
	if ( obj->run_progress != 0 && obj->run_progress != 10 ) {
	  if ( !bytes_uncompressed_count ) {
	    BZ_SETERR(obj, BZ_UNEXPECTED_EOF, NULL);

	    if (obj->verbosity>=2) {
	      PerlIO_printf(PerlIO_stderr(), "debug: bzfile_read got an unexpected EOF, run_progress=%d, avail_in=%d, avail_out=%d\n",
			    obj->run_progress,
			    obj->strm.avail_in,
			    obj->strm.avail_out
			    );
	    }

	    return -1;
	  }
	    
	  /* hold off on the BZ_UNEXPECTED_EOF until the caller gets their data */
	  obj->pending_io_error = True;
	  obj->io_error = BZ_UNEXPECTED_EOF;

	  if (obj->verbosity>=2) {
	    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_read got an unexpected EOF, run_progress=%d, set pending with %d bytes to go, avail_in=%d, avail_out=%d\n",
			  obj->run_progress,
			  bytes_uncompressed_count,
			  obj->strm.avail_in,
			  obj->strm.avail_out
			  );
	  }
	}
	else {
	  obj->pending_io_error = True;
	  obj->io_error = BZ_IO_EOF;

	  if (obj->verbosity>=2) {
	    PerlIO_printf(PerlIO_stderr(), "debug: bzfile_read got an EOF, run_progress=%d, set pending with %d bytes to go, avail_in=%d, avail_out=%d\n",
			  obj->run_progress,
			  bytes_uncompressed_count,
			  obj->strm.avail_in,
			  obj->strm.avail_out
			  );
	  }
	}
      }
      /* if no io_error is pending, this is a proper end of file */
      return bytes_uncompressed_count;
    }
    else {
      if ( obj->run_progress == 1 || obj->run_progress == 11 ) {
	/* indicate we have data to uncompress */
	obj->run_progress = obj->run_progress == 1 ? 2 : 12;
      } else if ( obj->run_progress == 0 || obj->run_progress == 10 ) {
	ret = BZ2_bzDecompressInit ( &(obj->strm), obj->verbosity, obj->small );

	if (ret != BZ_OK) {
	  if (obj->verbosity>1) {
	    warn("Error: bzfile_read: BZ2_bzDecompressInit error %d on %d, %d\n",
		 ret, obj->verbosity, obj->small);
	  }

	  BZ_SETERR(obj, ret, NULL);
	  return -1;
	}

	obj->run_progress = obj->run_progress == 0 ? 1 : 11;
	obj->notCompressed = False;
      }

      rewind_mark = obj->strm.avail_in;
      tracker = obj->strm.avail_out;
      if ( obj->notCompressed )
	ret = bzfile_read_notCompressed( &(obj->strm), &(obj->scan_BZh9) );
      else
	ret = BZ2_bzDecompress( &(obj->strm) );

      if (obj->verbosity>=4) {
	PerlIO_printf(PerlIO_stderr(), "\ndebug: bzfile_read BZ2_bzDecompress ret %d, run_progress=%d, avail_in=%d/%d, avail_out=%d/%d\n",
		      ret,
		      obj->run_progress,
		      rewind_mark,
		      obj->strm.avail_in,
		      tracker,
		      obj->strm.avail_out
		      );
      }

      if (ret != BZ_OK && ret != BZ_STREAM_END) {
	if ( ret != BZ_DATA_ERROR_MAGIC || !obj->allowUncompressedRead ) {
	  BZ_SETERR(obj, ret, NULL);

	  if (obj->verbosity>1)
	    warn("Error: bzfile_read, BZ2_bzDecompress error %d, strm is %p, strm.state is %p, in state %d\n",
		 ret, &(obj->strm), obj->strm.state, *((int*)obj->strm.state));

	  return -1;
	}
	else if ( !obj->notCompressed ) {
	  /* a compressed stream that turns out not to be compressed */
	  obj->strm.avail_in = rewind_mark;
	  obj->notCompressed = True;
	  obj->scan_BZh9 = 0;

	  ret = BZ2_bzDecompressEnd( &(obj->strm) );
	  obj->run_progress = 0;

	  ret = bzfile_read_notCompressed( &(obj->strm), &(obj->scan_BZh9) );
	}
	else {
	  /* an uncompressed stream that turns out to be compressed actually */
	  obj->BZh9[0] = 'B';
	  obj->BZh9[1] = 'Z';
	  obj->BZh9[2] = 'h';
	  obj->BZh9[3] = obj->scan_BZh9;
	  obj->BZh9[4] = 0;
	  obj->BZh9_count = 4;

	  continue;
	}
      }

      obj->total_out += tracker - obj->strm.avail_out;
      bytes_uncompressed_count += tracker - obj->strm.avail_out;

      if (ret == BZ_STREAM_END) {
	char *p;
	int i,n;

	/* move unused bytes to another place */
	p = obj->strm.next_in;
	n = obj->strm.avail_in;
	for (i=0; i<n; i++) obj->bufferOfHolding[i] = *p++;
	obj->nHolding = n;

	ret = BZ2_bzDecompressEnd( &(obj->strm) );

	obj->run_progress = 10;

	obj->nCompressed = 0;
	obj->strm.avail_in = 0;
	obj->strm.next_in = obj->bufferOfCompressed;
      }
    }

    if (bytes_uncompressed_count >= nUncompress) {
      BZ_SETERR(obj, BZ_OK, NULL);
      return bytes_uncompressed_count;
    }

    /* obj->strm.avail_out > 0 */
    /* need to read more to fill the output hopper, keep going */
  }
}

#ifdef CAN_PROTOTYPE
int bzfile_write( bzFile* obj, char *bufferOfUncompressed, int nUncompressed ) {
#else
int bzfile_write( obj, bufferOfUncompressed, nUncompressed ) bzFile* obj; char *bufferOfUncompressed; int nUncompressed; {
#endif
  int ret;
  int tracker;
  int bytes_compressed_count = 0;
  int compressed_bytes_count = 0;
  int error_num = bzfile_geterrno( obj );

  if (obj == NULL || bufferOfUncompressed == NULL || nUncompressed < 0) {
    BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);

    if ( obj != NULL && obj->verbosity>1 ) {
      if ( bufferOfUncompressed == NULL ) warn("Error: bzfile_write buf is NULL\n");
      if ( nUncompressed < 0 ) warn("Error: bzfile_write n is negative %d\n", nUncompressed);
    }

    return -1;
  }

  if (obj->open_status != OPEN_STATUS_WRITE && obj->open_status != OPEN_STATUS_WRITESTREAM) {
    BZ_SETERR(obj, BZ_SEQUENCE_ERROR, NULL);

    if ( obj->verbosity>1 ) warn("Error: bzfile_write attempted on a reading stream\n");

    return -1;
  }

  if ( error_num == BZ_OK ) {
    if ( obj->pending_io_error ) {
      errno = obj->io_error;
      obj->io_error = 0;
      BZ_SETERR(obj, BZ_IO_ERROR, NULL);

      obj->pending_io_error = False;
      return -1;
    }
  }
  else if ( error_num == BZ_IO_ERROR ) {
    if ( obj->io_error == EINTR || obj->io_error == EAGAIN ) {
      obj->io_error=0;
      BZ_SETERR(obj, BZ_OK, NULL);
    }
    else
      return -2;
  }
  else {
    return -2;
  }

  while (True) {
    if ( obj->run_progress == 0 ) {
      ret = BZ2_bzCompressInit ( &(obj->strm), obj->blockSize100k, obj->verbosity, obj->workFactor );

      if (ret != BZ_OK) {
	BZ_SETERR(obj, ret, NULL);

	if (obj->verbosity>1)
	  warn("Error: bzfile_write: BZ2_bzCompressInit error %d on %d, %d, %d\n",
	       ret, obj->blockSize100k, obj->verbosity, obj->workFactor);

	return -1;
      }

      obj->run_progress = 1;
    }

    obj->strm.avail_in = nUncompressed - bytes_compressed_count;
    obj->strm.next_in = bufferOfUncompressed + bytes_compressed_count;

    obj->strm.avail_out = sizeof(obj->bufferOfCompressed) - obj->compressedOffset_addmore;
    obj->strm.next_out = obj->bufferOfCompressed + obj->compressedOffset_addmore;

    if (obj->verbosity>=4)
      PerlIO_printf(PerlIO_stderr(), "debug: bzfile_write: call to BZ2_bzCompress with avail_in %d, next_in %p, avail_out %d, next_out %p\n",
		    obj->strm.avail_in, obj->strm.next_in, obj->strm.avail_out, obj->strm.next_out);

    compressed_bytes_count = obj->strm.avail_out;

    tracker = obj->strm.avail_in;
    if ( tracker == 0 )
      return nUncompressed;

    /* indicate we have data to compress */
    if ( obj->run_progress == 1 && tracker > 0 ) obj->run_progress = 2;

    if ( obj->strm.avail_out <= 0 )
      ret = BZ_RUN_OK;
    else
      ret = BZ2_bzCompress ( &(obj->strm), BZ_RUN ) ;

    obj->total_in += tracker - obj->strm.avail_in;
    bytes_compressed_count += tracker - obj->strm.avail_in;

    compressed_bytes_count -= obj->strm.avail_out;
    obj->compressedOffset_addmore += compressed_bytes_count;
    obj->nCompressed += compressed_bytes_count;

    if (ret != BZ_RUN_OK) {
      BZ_SETERR(obj, ret, NULL);

      if (obj->verbosity>1)
	warn("Error: bzfile_write, BZ2_bzCompress error %d, strm is %p, strm.state is %p, in state %d\n",
	     ret, &(obj->strm), obj->strm.state, *((int*)obj->strm.state));

      return -1;
    }

    if (obj->verbosity>=4)
      PerlIO_printf(PerlIO_stderr(), "debug: bzfile_write: BZ2_bzCompress took in %d, put out %d \n",
		    tracker-obj->strm.avail_in, compressed_bytes_count);

    if ( obj->nCompressed ) {
      int n, n2;

      n = obj->nCompressed;

      while ( n > 0 ) {
	if ( obj->open_status == OPEN_STATUS_WRITESTREAM )
	  n2 = bzfile_streambuf_write( obj, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	else
	  if ( obj->handle )
	    n2 = PerlIO_write( obj->handle, obj->bufferOfCompressed + obj->compressedOffset_takeout, n );
	  else
	    n2 = n;

	if ( n2==-1 ) {
	  if ( bytes_compressed_count ) {
	    obj->pending_io_error = True;
	    obj->io_error = errno;

	    if ( errno != EINTR && errno != EAGAIN ) {
	      if (obj->verbosity>0)
		warn("Error: bzfile_write file write error %d '%s'\n", errno, Strerror(errno));
	    }
	    else {
	      if (obj->verbosity>=4)
		PerlIO_printf(PerlIO_stderr(), "debug: bzfile_write file write error pending %d '%s'\n", errno, Strerror(errno));
	    }

	    return bytes_compressed_count;
	  }
	  else {
	    BZ_SETERR(obj, BZ_IO_ERROR, NULL);

	    if ( errno != EINTR && errno != EAGAIN ) {
	      if (obj->verbosity>0)
		warn("Error: bzfile_write io error %d '%s'\n", errno, Strerror(errno));
	    }
	    else {
	      if (obj->verbosity>=4)
		PerlIO_printf(PerlIO_stderr(), "debug: bzfile_write: file write error %d '%s'\n", errno, Strerror(errno));
	    }

	    return -1;
	  }
	}
	else {
	  if (obj->verbosity>=4) PerlIO_printf(PerlIO_stderr(), "debug: bzfile_write: file write took in %d, put out %d\n", n, n2);

	  obj->compressedOffset_takeout += n2;
	  obj->nCompressed -= n2;
	  n -= n2;

	  obj->total_out += n2;
	}
      }

      obj->nCompressed = 0;
      obj->compressedOffset_takeout = 0;
      obj->compressedOffset_addmore = 0;
    }

    if (bytes_compressed_count == nUncompressed) {
      BZ_SETERR(obj, BZ_OK, NULL);
      return nUncompressed;
    }
  }
}

/***********************************************************************
 * XSUB start
 ***********************************************************************/

MODULE = Compress::Bzip2   PACKAGE = Compress::Bzip2	PREFIX = MY_

INCLUDE: const-xs.inc

REQUIRE:	0.0
PROTOTYPES:	ENABLE

BOOT:
    if (BZ2_bzlibVersion()[0] != '1')
	croak("Compress::Bzip2 needs bzlib version 1.x, not %s\n", BZ2_bzlibVersion()) ;

    {
        /* Create the $bzerror scalar */
        SV * bzerror_sv = perl_get_sv(BZERRNO, GV_ADDMULTI) ;
        sv_setiv(bzerror_sv, 0) ;
        sv_setpv(bzerror_sv, "") ;
        SvIOK_on(bzerror_sv) ;
    }

void
MY_new(...)

  PROTOTYPE: @

  INIT:
    bzFile* obj;
    SV *perlobj;
    char *class, *param;
    STRLEN lnclass, lnparam;
    int setting;

  PPCODE:
  {
    int i;

    perlobj = NULL;
    obj = NULL;
    if ( items == 0 ) {
      class = "Compress::Bzip2";
    }
    else if ( SvPOK( ST(0) ) ) {
      /* this is the name of a class */
      class = (char *) SvPV( ST(0), lnclass );
    }
    else if ( SvROK( ST(0) ) ) {
      if (sv_derived_from(ST(0), "Compress::Bzip2")) {
	IV tmp = SvIV((SV*)SvRV(ST(0)));
	perlobj = ST(0);
	obj = INT2PTR(bzFile*, tmp);
      }
    }

    if ( obj == NULL ) {
      obj = bzfile_new( 0, 0, 9, 0 );

      perlobj = newSV(0);
      sv_setref_iv( perlobj, class, PTR2IV(obj) );
      sv_2mortal(perlobj);
    }

    if ( obj == NULL )
      XSRETURN_UNDEF;

    for (i=1; i<items-1; i+=2) {
      param = (char*) SvPV( ST(i), lnparam );
      setting = SvIV( ST(i+1) );
      bzfile_setparams( obj, param, setting );
    }

    PUSHs(perlobj);
  }

void
DESTROY(obj)
  Compress::Bzip2 obj

  CODE:
  {
    if (!obj)
      XSRETURN_UNDEF;
    if (obj->verbosity >= 1)
      PerlIO_printf(PerlIO_stderr(), "debug: DESTROY on %p\n", obj);
    bzfile_close( obj, 0 );
    bzfile_free( obj );
  }

char *
MY_bzlibversion()

  PROTOTYPE:

  CODE:
    RETVAL = (char *) BZ2_bzlibVersion();

  OUTPUT:
    RETVAL


int
MY_bz_seterror(error_num, error_str)
  int error_num;
  char *error_str;

  PROTOTYPE: $$

  CODE:
  {
    SV * bzerror_sv = perl_get_sv(BZERRNO, GV_ADDMULTI);
    sv_setiv(bzerror_sv, error_num);
    sv_setpv(bzerror_sv, error_str);
    SvIOK_on(bzerror_sv);

    RETVAL = error_num;
  }

  OUTPUT:
    RETVAL

SV *
memBzip(sv, level = 6)
  SV* sv;
  int level

  PROTOTYPE: $;$

  ALIAS:
    compress = 1

  PREINIT:
	STRLEN		len;
	unsigned char *	in;
	unsigned char *	out;
	unsigned int	in_len;
	unsigned int	out_len;
	unsigned int	new_len;
	int		err;

  CODE:
  {
    if ( !SvOK(sv) )
      croak(ix==1 ? "compress: buffer is undef" : "memBzip: buffer is undef");;

    sv = deRef(sv, ix==1 ? "compress" : "memBzip");

    in = (unsigned char*) SvPV(sv, len);
    in_len = len;

    /* use an extra 1% + 600 bytes (see libbz2 documentation) */
    out_len = in_len + ( in_len + 99 ) / 100 + 600;
    RETVAL = newSV(5+out_len);
    SvPOK_only(RETVAL);

    out = (unsigned char*)SvPVX(RETVAL);
    new_len = out_len;

    out[0] = 0xf0;
    err = BZ2_bzBuffToBuffCompress((char*)out+5,&new_len,(char*)in,in_len,level,0,240);

    if (err != BZ_OK || new_len > out_len) {
      SvREFCNT_dec(RETVAL);
      BZ_SETERR(NULL, err, ix==1 ? "compress" : "memBzip");
      XSRETURN_UNDEF;
    }

    SvCUR_set(RETVAL,5+new_len);
    out[1] = (in_len >> 24) & 0xff;
    out[2] = (in_len >> 16) & 0xff;
    out[3] = (in_len >>  8) & 0xff;
    out[4] = (in_len >>  0) & 0xff;
  }

  OUTPUT:
    RETVAL

SV *
memBunzip(sv)
  SV* sv

  PROTOTYPE: $

  ALIAS:
    decompress = 1

  PREINIT:
    STRLEN		len;
    unsigned char *	in;
    unsigned char *	out;
    unsigned int	in_len;
    unsigned int        out_len;
    unsigned int	new_len;
    int			err;
    int 		noprefix = 0;

  CODE:
  {
    if ( !SvOK(sv) )
      croak(ix==1 ? "decompress: buffer is undef" : "memBunzip: buffer is undef");;

    sv = deRef(sv, ix==1 ? "decompress" : "memBunzip");

    in = (unsigned char*)SvPV(sv, len);
    if (len < 5 + 3 || in[0] < 0xf0 || in[0] > 0xf1) {
      if (len > 16 && in[0] == 'B' && in[1] == 'Z' && in[2] == 'h') {
	in_len = len;
	out_len = len * 5; /* guess uncompressed size */
	noprefix = 1;
	RETVAL = newSV(len * 10);
      } else {
	warn("invalid buffer (too short %ld or bad marker %d)",(long)len,in[0]);
	XSRETURN_UNDEF;
      }
    } else {
      in_len = len - 5;
      out_len = (in[1] << 24) | (in[2] << 16) | (in[3] << 8) | in[4];
      RETVAL = newSV(out_len > 0 ? out_len : 1);
    }
    SvPOK_only(RETVAL);
    out = (unsigned char*)SvPVX(RETVAL);
    new_len = out_len;
    err = BZ2_bzBuffToBuffDecompress((char*)out,&new_len,
      noprefix ? (char*)in:(char *)in+5, in_len,0,0);
    while (noprefix && (err == BZ_OUTBUFF_FULL)) {
      new_len = SvLEN(RETVAL) * 2;
      SvGROW(RETVAL, new_len);
      err = BZ2_bzBuffToBuffDecompress((char*)out,&new_len,
				       (char *)in,in_len,0,0);
    }
    if (err != BZ_OK) {
      SvREFCNT_dec(RETVAL);
      BZ_SETERR(NULL, err, ix==1 ? "decompress" : "memBunzip");
      XSRETURN_UNDEF;
    }
    if (!noprefix && new_len != out_len) {
      SvREFCNT_dec(RETVAL);
      BZ_SETERR(NULL, err, ix==1 ? "decompress" : "memBunzip");
      XSRETURN_UNDEF;
    }
    SvCUR_set(RETVAL, new_len);
  }

  OUTPUT:
    RETVAL

void
MY_bzopen(...)

## xxx->bzopen( $filename or filehandle, $mode )

  PROTOTYPE: $$;$

  INIT:
    PerlIO *io;
    char *filename, *mode, *class;
    STRLEN ln, lnfilename, lnclass;

    bzFile* obj;
    SV *perlobj;

  PPCODE:
  {
    int i;

    perlobj=NULL;
    obj=NULL;
    if ( items == 2 ) {
      class = "Compress::Bzip2";
    }
    else if ( SvPOK( ST(0) ) ) {
      /* this is the name of a class */
      class = (char *) SvPV( ST(0), lnclass );
    }
    else if ( SvROK( ST(0) ) ) {
      if (sv_derived_from(ST(0), "Compress::Bzip2")) {
	IV tmp = SvIV((SV*)SvRV(ST(0)));
	perlobj = ST(0);
	obj = INT2PTR(bzFile*, tmp);
      }
    }

    i = items==3 ? 2 : 1;
    mode = (char *) SvPV(ST(i), ln);
    if (ln==0) {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);

      if ( obj && obj->verbosity>1 ) warn( "Error: invalid file mode for bzopen %s", mode );

      XSRETURN_UNDEF;
    }

    i = items==3 ? 1 : 0;
    if ( SvPOK( ST(i) ) ) {
      /* is the first argument a filename string or a filehandle?? */
      filename = (char *) SvPV(ST(i), lnfilename);
      if (lnfilename==0)
	XSRETURN_UNDEF;

      filename[lnfilename]=0;

      obj = bzfile_open( filename, mode, obj );
    }
    else if ( SvROK( ST(i) ) || SVt_PVIO == SvTYPE( ST(i) ) ) {
      /* a reference or an IO handle */
      if ( mode && mode[0] == 'w' ) {
	io = IoOFP(sv_2io( ST(i) ));
      }
      else {
	io = IoIFP(sv_2io( ST(i) ));
      }

      obj = bzfile_fdopen( io, mode, obj );
    }
    else {
      BZ_SETERR(obj, BZ_PARAM_ERROR, NULL);

      if ( obj && obj->verbosity>1 ) warn( "Error: invalid file or handle for bzopen" );

      XSRETURN_UNDEF;
    }

    if ( obj == NULL )
      XSRETURN_UNDEF;

    if ( perlobj == NULL ) {
      perlobj = newSV(0);
      sv_setref_iv( perlobj, class, PTR2IV(obj) );
      sv_2mortal(perlobj);
    }

    PUSHs(perlobj);
  }

void
MY_bzclose(obj, abandon=0)
  Compress::Bzip2 obj
  int abandon

  PROTOTYPE: $;$

  PPCODE:
  {
    int i, ret, amt_collected;
    char *inp;
    int error_flag = 0;

    if ( obj->open_status != OPEN_STATUS_READSTREAM && obj->open_status != OPEN_STATUS_WRITESTREAM ) {
      ret = bzfile_close( obj, abandon );
      XPUSHs(sv_2mortal(newSViv(ret)));
    }
    else {
      char *firstp, *outp;
      SV *outbuf = NULL;
      STRLEN outbufl = 0;

      char collect_buffer[10000];

      while ( !error_flag ) {
	ret = bzfile_close( obj, abandon );

	if ( obj->open_status == OPEN_STATUS_READSTREAM ) break;

	if ( ret == -1 && errno != EAGAIN ) {
	  error_flag =1;
	  break;
	}

	if ( obj->verbosity>=4 )
	  PerlIO_printf(PerlIO_stderr(), "debug: bzstreamclose, bzfile_close returned %d, errno is %d %s\n", ret, errno, Strerror(errno));
      
	while ( -1 != ( amt_collected = bzfile_streambuf_collect( obj, collect_buffer, sizeof(collect_buffer) ) ) ) {
	  if ( obj->verbosity>=4 )
	    PerlIO_printf(PerlIO_stderr(), "debug: bzstreamclose, bzfile_streambuf_collect returned %d bytes\n", amt_collected);

	  /* put the stuff into the SV output buffer */
	  if ( outbuf == NULL ) {
	    outbuf = newSVpv( collect_buffer, amt_collected );
	    outbufl = amt_collected;
	    firstp = SvPV_nolen( outbuf );
	    outp = firstp;
	  }
	  else {
	    outbufl += amt_collected;
	    SvGROW( outbuf, outbufl );
	    firstp = SvPV_nolen( outbuf );
	    outp = SvEND( outbuf );
	  }
	
	  for ( inp=collect_buffer, i=0; i<amt_collected; i++ ) *outp++ = *inp++;
	  SvCUR_set( outbuf, outp-firstp) ;
	}
	if ( errno != EAGAIN )
	  error_flag = 1;

	if ( ret == 0 ) break;
      }

      if (outbuf==NULL) {
	if ( error_flag )
	  XPUSHs(sv_newmortal());
	else
	  XPUSHs(sv_2mortal(newSVpv("",0)));
      }
      else
        XPUSHs(sv_2mortal(outbuf));

      if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
    }
  }

void
MY_bzflush(obj, flag=0)
  Compress::Bzip2 obj
  int flag

  PROTOTYPE: $;$

  PPCODE:
  {
    int i, ret, amt_collected;
    char *inp;

    if ( obj->open_status != OPEN_STATUS_READSTREAM && obj->open_status != OPEN_STATUS_WRITESTREAM ) {
      ret = !flag || flag!=BZ_FINISH ? bzfile_flush( obj ) : bzfile_close( obj, 0 );
      XPUSHs(sv_2mortal(newSViv(ret)));
    }
    else {
      char *firstp, *outp;
      SV *outbuf = NULL;
      STRLEN outbufl = 0;

      char collect_buffer[10000];

      while ( True ) {
	ret = !flag || flag!=BZ_FLUSH ? bzfile_flush( obj ) : bzfile_close( obj, 0 );

	if ( obj->open_status == OPEN_STATUS_READSTREAM ) break;

	while ( -1 != ( amt_collected = bzfile_streambuf_collect( obj, collect_buffer, sizeof(collect_buffer) ) ) ) {
	  if ( obj->verbosity>=4 )
	    PerlIO_printf(PerlIO_stderr(), "debug: bzstreamflush, bzfile_streambuf_collect returned %d bytes\n", amt_collected);

	  /* put the stuff into the SV output buffer */
	  if ( outbuf == NULL ) {
	    outbuf = newSVpv( collect_buffer, amt_collected );
	    outbufl = amt_collected;
	    firstp = SvPV_nolen( outbuf );
	    outp = firstp;
	  }
	  else {
	    outbufl += amt_collected;
	    SvGROW( outbuf, outbufl );
	    firstp = SvPV_nolen( outbuf );
	    outp = SvEND( outbuf );
	  }
	
	  for ( inp=collect_buffer, i=0; i<amt_collected; i++ ) *outp++ = *inp++;
	  SvCUR_set( outbuf, outp-firstp) ;
	}

	if ( ret != -1 ) break;
      }

      if (outbuf==NULL)
	XPUSHs(sv_newmortal());
      else
	XPUSHs(sv_2mortal(outbuf));

      if (GIMME == G_ARRAY) 
	XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
    }
  }

SV*
MY_bzerror(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
  {
    int err_num;
    err_num = bzfile_geterrno( obj );

    if ( err_num == 0 )
      XSRETURN_NO;

    RETVAL = newSViv( err_num );

    sv_setiv(RETVAL, err_num) ;
    sv_setpv(RETVAL, (char*) bzfile_geterrstr( obj ));
    SvIOK_on(RETVAL);		/* say "IAM integer (too)" */
  }

  OUTPUT:
    RETVAL

int
MY_bzclearerr(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
  {
    if ( obj && bzfile_clearerr( obj ) )
      RETVAL = 1;
    else
      RETVAL = 0;
  }

  OUTPUT:
    RETVAL

SV*
MY_bzeof(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
  {
    if ( bzfile_eof( obj ) )
      XSRETURN_YES;
    else
      XSRETURN_NO;
  }

long
MY_total_in(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
    RETVAL = bzfile_total_in( obj );

  OUTPUT:
    RETVAL

long
MY_total_out(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
    RETVAL = bzfile_total_out( obj );

  OUTPUT:
    RETVAL

int
MY_bzsetparams(obj, param, setting = -1)
  Compress::Bzip2 obj
  char* param
  int setting

  PROTOTYPE: $$;$

  CODE:
    RETVAL = bzfile_setparams( obj, param, setting );

  OUTPUT:
    RETVAL

int
MY_bzread(obj, buf, len=4096)
  Compress::Bzip2 obj
  unsigned int len
  SV *buf

  PROTOTYPE: $$;$

  CODE:
  {
    if (SvREADONLY(buf) && PL_curcop != &PL_compiling)
      croak("bzread: buffer parameter is read-only");
    SvUPGRADE(buf, SVt_PV);
    SvPOK_only(buf);
    SvCUR_set(buf, 0);

    if (len) {
      char* bufp = SvGROW(buf, len+1);

      RETVAL = bzfile_read( obj, bufp, len);

      if (RETVAL >= 0) {
	SvCUR_set(buf, RETVAL) ;
	*SvEND(buf) = '\0';
      }
    }
    else {
      RETVAL  = 0;
    }
  }

  OUTPUT:
    RETVAL
    buf


int
MY_bzreadline(obj, buf, len=4096)
  Compress::Bzip2 obj
  unsigned int len
  SV *buf

  PROTOTYPE: $$;$

  CODE:
  {
    if (SvREADONLY(buf) && PL_curcop != &PL_compiling)
      croak("bzreadline: buffer parameter is read-only");
    SvUPGRADE(buf, SVt_PV);
    SvPOK_only(buf);
    SvCUR_set(buf, 0);

    if (len) {
      char* bufp = SvGROW(buf, len+1);

      RETVAL = bzfile_readline( obj, bufp, len);

      if (RETVAL >= 0) {
	SvCUR_set(buf, RETVAL) ;
	*SvEND(buf) = '\0';
      }
    }
    else {
      RETVAL  = 0;
    }
  }

  OUTPUT:
    RETVAL
    buf

int
MY_bzwrite(obj, buf, limit=0)
  Compress::Bzip2 obj
  SV *buf
  SV *limit

  PROTOTYPE: $$;$

  CODE:
  {
    char *bufp;
    STRLEN len;

    if ( SvTRUE(limit) ) {
      len = SvUV(limit);
      SvGROW( buf, len );
      bufp = SvPV_nolen(buf);
    }
    else
      bufp = SvPV(buf, len);

    RETVAL = bzfile_write( obj, bufp, len);

    if ( RETVAL >= 0 )
      SvCUR_set( buf, RETVAL );
  }

  OUTPUT:
    RETVAL

void
bzdeflateInit(...)

  PROTOTYPE: @

  ALIAS:
    compress_init = 1

  INIT:
    bzFile* obj = NULL;
    SV *perlobj = NULL;
    char *param;
    STRLEN lnparam;
    int setting;

  PPCODE:
  {
    int i;

    if (items % 2) croak("Compress::Bzip2::%s has odd parameter count", ix==0 ? "bzdeflateInit" : "compress_init");

    obj = bzfile_new( 0, 0, 1, 0 );
    bzfile_openstream( "w", obj );

    perlobj = newSV(0);
    sv_setref_iv( perlobj, "Compress::Bzip2", PTR2IV(obj) );
    sv_2mortal(perlobj);

    if ( obj == NULL ) {
      XPUSHs(sv_newmortal());
      if (GIMME == G_ARRAY) 
	XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
    }
    else {
      for (i=0; i<items-1; i+=2) {
	param = (char*) SvPV( ST(i), lnparam );
	setting = SvIV( ST(i+1) );
	bzfile_setparams( obj, param, setting );
      }

      bzfile_streambuf_set( obj, (char*) obj->bufferOfHolding, sizeof( obj->bufferOfHolding ) );

      XPUSHs(perlobj);
      if (GIMME == G_ARRAY) 
	XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
    }
  }

void
MY_bzdeflate(obj, buffer)
  Compress::Bzip2 obj
  SV *buffer

  PROTOTYPE: $$

  PPCODE:
  {
    char *firstp, *outp;
    SV *outbuf = NULL;
    STRLEN outbufl = 0;

    char *bufp, *inp;
    STRLEN bufl;

    STRLEN bytes_to_go;

    char collect_buffer[1000];
    int i, amt_written, amt_collected;
    int error_flag = 0;

    bufp = (char*) SvPV( buffer, bufl );

    for ( bytes_to_go = bufl; bytes_to_go>0; ) {
      amt_written = bzfile_write( obj, bufp, bytes_to_go );

      if ( amt_written == -1 ) {
	if ( errno != EAGAIN )
	  error_flag =1;
	else {
	  while ( -1 != ( amt_collected = bzfile_streambuf_collect( obj, collect_buffer, sizeof(collect_buffer) ) ) ) {
	    /* put the stuff into the SV output buffer */
	    if ( outbuf == NULL ) {
	      outbuf = newSVpv( collect_buffer, amt_collected );
	      outbufl = amt_collected;
	      firstp = SvPV_nolen( outbuf );
	      outp = firstp;
	    }
	    else {
	      outbufl += amt_collected;
	      SvGROW( outbuf, outbufl );
	      firstp = SvPV_nolen( outbuf );
	      outp = SvEND( outbuf );
	    }

	    for ( inp=collect_buffer, i=0; i<amt_collected; i++ ) *outp++ = *inp++;
	    SvCUR_set( outbuf, outp-firstp) ;

	    if ( obj->verbosity>=4 )
	      PerlIO_printf(PerlIO_stderr(), "debug: bzdeflate collected %d, outbuf is now %ld\n",
			    amt_collected, (long)(outp-firstp));
	  }

	  if ( errno != EAGAIN ) error_flag = 1;
	}
      }
      else {
	bytes_to_go -= amt_written;
	bufp += amt_written;
      }
    }

    while ( -1 != ( amt_collected = bzfile_streambuf_collect( obj, collect_buffer, sizeof(collect_buffer) ) ) ) {
      /* put the stuff into the SV output buffer */
      if ( outbuf == NULL ) {
	outbuf = newSVpv( collect_buffer, amt_collected );
	outbufl = amt_collected;
	firstp = SvPV_nolen( outbuf );
	outp = firstp;
      }
      else {
	outbufl += amt_collected;
	SvGROW( outbuf, outbufl );
	firstp = SvPV_nolen( outbuf );
	outp = SvEND( outbuf );
      }
	
      for ( inp=collect_buffer, i=0; i<amt_collected; i++ ) *outp++ = *inp++;
      SvCUR_set( outbuf, outp-firstp) ;

      if ( obj->verbosity>=4 )
	PerlIO_printf(PerlIO_stderr(), "debug: bzdeflate collected %d, outbuf is now %ld\n",
		      amt_collected, (long)(outp-firstp));
    }

    if ( errno != EAGAIN ) error_flag = 1;

    if (outbuf==NULL) {
      if ( error_flag )
	XPUSHs(sv_newmortal());
      else
	XPUSHs(sv_2mortal(newSVpv("",0)));
    }
    else
      XPUSHs(sv_2mortal(outbuf));

    if (GIMME == G_ARRAY) 
      XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
  }


void
bzinflateInit(...)

  PROTOTYPE: @

  ALIAS:
    decompress_init = 1

  INIT:
    bzFile* obj = NULL;
    SV *perlobj = NULL;
    char *param;
    STRLEN lnparam;
    int setting;

  PPCODE:
  {
    int i;

    if (items % 2)
      croak("Compress::Bzip2::%s has odd parameter count", ix==0 ? "bzinflateInit" : "decompress_init");

    obj = bzfile_new( 0, 0, 1, 0 );
    bzfile_openstream( "r", obj );
    if ( obj == NULL ) {
      XPUSHs(sv_newmortal());
      if (GIMME == G_ARRAY) 
	XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
    }

    perlobj = newSV(0);
    sv_setref_iv( perlobj, "Compress::Bzip2", PTR2IV(obj) );

    for (i=0; i < items; i+=2) {
      param = (char*) SvPV( ST(i), lnparam );
      setting = SvIV( ST(i+1) );
      bzfile_setparams( obj, param, setting );
    }

    XPUSHs(sv_2mortal(perlobj));
    if (GIMME == G_ARRAY) 
      XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
  }

void
MY_bzinflate(obj, buffer)
  Compress::Bzip2 obj
  SV *buffer

  PROTOTYPE: $$

  PPCODE:
  {
    char *firstp, *outp;
    SV *outbuf = NULL;
    STRLEN outbufl = 0;

    STRLEN bufl;
    char collect_buffer[1000];
    int i, amt_collected;
    char *bufp, *inp;
    int error_flag = 0;

    if (SvTYPE(buffer) == SVt_RV)
      buffer = SvRV(buffer);
    bufp = (char*) SvPV( buffer, bufl );
    bzfile_streambuf_deposit( obj, bufp, bufl );

    while ( ( amt_collected = bzfile_read( obj, collect_buffer, sizeof(collect_buffer) ) ) >= 0 ) {
      if ( obj->verbosity>=4 )
	PerlIO_printf(PerlIO_stderr(), "debug: bzinflate, bzfile_read returned %d bytes\n", amt_collected);

      /* put the stuff into the SV output buffer */
      if ( outbuf == NULL ) {
	outbuf = newSVpv( collect_buffer, amt_collected );
	outbufl = amt_collected;
	firstp = SvPV_nolen( outbuf );
	outp = firstp;
      }
      else {
	outbufl += amt_collected;
	SvGROW( outbuf, outbufl );
	firstp = SvPV_nolen( outbuf );
	outp = SvEND( outbuf );
      }
	
      for ( inp=collect_buffer, i=0; i<amt_collected; i++ ) *outp++ = *inp++;
      SvCUR_set( outbuf, outp-firstp) ;
    }

    if ( errno != EAGAIN ) error_flag = 1;

    if (outbuf==NULL) {
      if ( error_flag )
	XPUSHs(sv_newmortal());
      else
	XPUSHs(sv_2mortal(newSVpv("",0)));
    }
    else
      XPUSHs(sv_2mortal(outbuf));

    if (GIMME == G_ARRAY) 
      XPUSHs(sv_2mortal(newSViv(global_bzip_errno)));
  }


## $stream->prefix: Compress::Bzip2 1.03 compatibility function
## ... only call this for a compress/deflate stream 

SV*
MY_prefix(obj)
  Compress::Bzip2 obj

  CODE:
  { 
    if (obj->strm.total_in_hi32)
      XSRETURN_UNDEF;
    else {
      unsigned int in_len = obj->strm.total_in_lo32;
      char out[6];

      out[0] = 0xf0;
      out[1] = (in_len >> 24) & 0xff;
      out[2] = (in_len >> 16) & 0xff;
      out[3] = (in_len >>  8) & 0xff;
      out[4] = (in_len >>  0) & 0xff;
      out[5] = 0;

      RETVAL = newSVpvn(out,5);
    }
  }

  OUTPUT:
    RETVAL

int
MY_is_write(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
    RETVAL = obj->open_status == OPEN_STATUS_WRITE || obj->open_status == OPEN_STATUS_WRITESTREAM ? 1 : 0;

  OUTPUT:
    RETVAL 

int
MY_is_read(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
    RETVAL = obj->open_status == OPEN_STATUS_READ || obj->open_status == OPEN_STATUS_READSTREAM ? 1 : 0;

  OUTPUT:
    RETVAL 

int
MY_is_stream(obj)
  Compress::Bzip2 obj

  PROTOTYPE: $

  CODE:
    RETVAL = obj->open_status == OPEN_STATUS_WRITESTREAM || obj->open_status == OPEN_STATUS_READSTREAM ? 1 : 0;

  OUTPUT:
    RETVAL 
