#ifdef __cplusplus
extern "C" {
#endif
#include "ASAny.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* --- Variables --- */


DBISTATE_DECLARE;

MODULE = DBD::ASAny	PACKAGE = DBD::ASAny

I32
constant()
    PROTOTYPE:
    ALIAS:
	ASA_SMALLINT	= 500
	ASA_INT		= 496
	ASA_DECIMAL	= 484
	ASA_FLOAT	= 482
	ASA_DOUBLE	= 480
	ASA_DATE	= 384
	ASA_STRING	= 460
	ASA_FIXCHAR	= 452
	ASA_VARCHAR	= 448
	ASA_LONGVARCHAR	= 456
	ASA_TIME	= 388
	ASA_TIMESTAMP	= 392
	ASA_TIMESTAMP_STRUCT	= 390
	ASA_BINARY	= 524
	ASA_LONGBINARY	= 528
	ASA_VARIABLE	= 600
	ASA_TINYINT	= 604
	ASA_BIGINT	= 608
	ASA_UNSINT	= 612
	ASA_UNSSMALLINT	= 616
	ASA_UNSBIGINT	= 620
	ASA_BIT		= 624
    CODE:
	if( !ix ) {
	    char *what = GvNAME(CvGV(cv));
	    croak( "Unknown DBD::ASAny constant '%s'", what );
	} else {
	    RETVAL = ix;
	}
    OUTPUT:
	RETVAL

INCLUDE: ASAny.xsi

# end of ASAny.xs
