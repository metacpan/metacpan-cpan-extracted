#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* ShiftEND ( SV* cvrv ) ;
SV* ENDBlockCount () ;

SV* ShiftEND ( SV* cvrv )
{
	SV *cv, *cve, *len ;
	void* tp ;

	if ( SvIV( ENDBlockCount() ) == 0 )
		return &PL_sv_undef ;
	
	cv = SvRV( cvrv ) ;
	cve = av_shift( PL_Iendav ) ;

/*
 *	ModPerl seems to copy elements off of the PL_Iendav array.
 *	Then empties the array the first time elements are executed.
 *      Although we can't seem to empty the array before ModPerl has a
 *	chance to replicate the elements, we will remove them off the 
 *	stack in case Postpone() is called twice before ModPerl empties
 *	this array.
 *
	SV** cve ;
	cve = av_fetch( PL_Iendav, SvIV(i), 0 ) ;
 */

	tp = cve->sv_any ;
	cve->sv_any = cv->sv_any ;
	cv->sv_any = tp ;

	return newSVsv( newRV_noinc( cv ) ) ;
}


SV* ENDBlockCount ()
{
	if ( PL_Iendav == NULL )
		return newSViv( 0 ) ;

	return newSViv( 1 +av_len( PL_Iendav ) ) ;
}


MODULE = Apache::ChildExit		PACKAGE = Apache::ChildExit		

PROTOTYPES: ENABLE

SV* 
ENDBlockCount()

SV* 
ShiftEND( cvrv )
	SV* cvrv
