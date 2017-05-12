#ifdef __cpluscplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cpluscplus
}
#endif

#include "c/speedyb.c"

// XXX - these do not work....
#ifdef NDEBUG
#define LOG(fmt,...) printf( "%s() - " ## fmt ## "\n", __func__, __VA_ARGS__ );
#define LOG0(fmt) printf( "%s()\n", __func__ );
#else
#define LOG(fmt,...) ;
#define LOG0(fmt) ;
#endif // NDEBUG

typedef struct
{
    speedyb_reader_t  reader;
    bool              iter;
    bool              open;
} SPEEDYB;

MODULE = DB::SPEEDYB          PACKAGE = DB::SPEEDYB
## allows the INCLUDEs below to work

PROTOTYPES: DISABLE

SPEEDYB*
new( const char* CLASS )
CODE:
    LOG0(); // printf( "%s()\n", __func__ );
    RETVAL = calloc( 1, sizeof( SPEEDYB ));
    // XXX - eek.  no error-check on the calloc
    RETVAL->iter = FALSE;
    RETVAL->open = FALSE;
    // printf( "%s() - RETVAL => [%p]\n", __func__, RETVAL );
    LOG( "RETVAL => [%p]", RETVAL );
OUTPUT:
    RETVAL

void
DESTROY( SPEEDYB* THIS )
PPCODE:
    // printf( "%s() - THIS => [%p]\n", __func__, THIS );
    LOG( "THIS => [%p]", THIS );
    if (items != 1)
       croak("THIS");
    // XXX - eek.  no error-check on THIS (nullptr?)
    free( THIS );
    XSRETURN_UNDEF;

bool
open( SPEEDYB* THIS, char* db_filename )
PREINIT:
    speedyb_rc_t rv;
CODE:
    if ( items != 2 )
       croak("THIS, db_filename");
    if ( THIS->open )
        XSRETURN_UNDEF;
    // printf( "%s() - THIS => [%p]; db_filename => [%s]\n", __func__, THIS, db_filename );
    LOG( "THIS => [%p]; db_filename => [%s]", THIS, db_filename );
    rv = speedyb_open( &(THIS->reader), db_filename );
    THIS->open = (SPEEDYB_OK == rv) ? TRUE : FALSE;
    RETVAL = (SPEEDYB_OK == rv) ? 1 : 0;
OUTPUT:
    RETVAL

bool
close( SPEEDYB* THIS )
PREINIT:
    speedyb_rc_t rv;
CODE:
    if ( items != 1 )
       croak("THIS" );
    // printf( "%s() - THIS => [%p]; db_filename => [%s]\n", __func__, THIS, db_filename );
    LOG( "THIS => [%p]", THIS );
    rv = speedyb_close( &(THIS->reader));
    if (SPEEDYB_OK == rv)
        THIS->open = FALSE;
    RETVAL = (SPEEDYB_OK == rv) ? 1 : 0;
OUTPUT:
    RETVAL

void
get( SPEEDYB* THIS, char* key )
PREINIT:
    speedyb_rc_t rv;
    char* val;
    uint len;
PPCODE:
    // printf( "%s() - THIS => [%p]; key => [%s]\n", __func__, THIS, key );
    LOG( "THIS => [%p]; key => [%s]", THIS, key );
    if ( ! THIS->open )
       croak("DB::SPEEDYB::get() - not open; aborting" );
    rv = speedyb_get( &(THIS->reader), key, strlen(key), &val, &len );
    if ( SPEEDYB_OK != rv )
        XSRETURN_UNDEF;
    // printf( "%s() - THIS => [%p]; val => [%d] [%s]\n", __func__, THIS, len, val );
    LOG( "THIS => [%p]; val => [%d] [%s]", THIS, len, val );
    ST(0) = sv_newmortal();
    sv_setpvn( ST(0), val, len );
    XSRETURN(1);
 
void
each( SPEEDYB* THIS )
PREINIT:
    speedyb_rc_t rv;
    char* key;
    uint klen;
    char* val;
    uint vlen;
PPCODE:
    //  printf( "%s() - THIS => [%p]\n", __func__, THIS );
    LOG( "THIS => [%p]", THIS );
    if ( ! THIS->open )
       croak("DB::SPEEDYB::each() - not open; aborting" );
    if ( ! THIS->iter )
    {
        rv = speedyb_iterate_init( &(THIS->reader));
	if ( SPEEDYB_OK != rv )
	{
	    THIS->iter = FALSE;
	    XSRETURN_UNDEF;
        }
	else
            THIS->iter = TRUE;
    }
    rv = speedyb_iterate_next( &(THIS->reader), &key, &klen, &val, &vlen );
    // XXX - when do we reset the iterator state?
    //        THIS->iter = false;
    //  fprintf( stderr, "%s() - rv => [%d]\n", __func__, rv );
    LOG( "rv => [%d]; key => [%d] [%s]; val => [%d] [%s]", rv, klen, key, vlen, val );
    if ( SPEEDYB_OK != rv )
    {
        THIS->iter = FALSE;
        XSRETURN_EMPTY;
    }
    //  else if ( 0 == klen )
    //  {
    //      THIS->iter = FALSE;
    //      XSRETURN_EMPTY;
    //  }
    else
    {
        //  fprintf( stderr, "%s() - rv => [%d]; key => [%d] [%s]; val => [%d] [%s]\n", __func__, rv, klen, key, vlen, val );
	XPUSHs( sv_2mortal( newSVpv( key, klen )));
	XPUSHs( sv_2mortal( newSVpv( val, vlen )));
	XSRETURN(2);
    }
    XSRETURN_YES;
 
void
count( SPEEDYB* THIS )
PREINIT:
    speedyb_rc_t rv;
    uint nkeys;
PPCODE:
    // printf( "%s() - THIS => [%p]\n", __func__, THIS );
    LOG( "THIS => [%p]\n", THIS );
    if ( ! THIS->open )
       croak("DB::SPEEDYB::count() - not open; aborting" );
    rv = speedyb_get_num_keys( &(THIS->reader), &nkeys );
    if ( SPEEDYB_OK != rv )
        XSRETURN_UNDEF;
    ST(0) = sv_newmortal();
    sv_setiv( ST(0), nkeys );
    XSRETURN(1);

##	speedyb_rc_t
##	RC_OK()
##	CODE:
##	    RETVAL = SPEEDYB_OK;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_DONE()
##	CODE:
##	    RETVAL = SPEEDYB_DONE;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_EOPEN()
##	CODE:
##	    RETVAL = SPEEDYB_EOPEN;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_EIO()
##	CODE:
##	    RETVAL = SPEEDYB_EIO;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_EMAGIC()
##	CODE:
##	    RETVAL = SPEEDYB_EMAGIC;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_EVER()
##	CODE:
##	    RETVAL = SPEEDYB_EVER;
##	OUTPUT:
##	    RETVAL
##	
##	speedyb_rc_t
##	RC_ENXKEY()
##	CODE:
##	    RETVAL = SPEEDYB_ENXKEY;
##	OUTPUT:
##	    RETVAL
