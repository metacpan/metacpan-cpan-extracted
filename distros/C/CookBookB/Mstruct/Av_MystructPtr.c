#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Mstruct.h"
#include "Av_MystructPtr.h"

#ifdef __cplusplus
}
#endif

/* Will convert a C Mystruct* to a Perl AV*. */
void
XS_pack_MystructPtr( st, pMystruct )
SV *st;
Mystruct *pMystruct;
{
	AV *av = newAV();
	AV *iav = newAV();
	SV *sv;

	/* put mymember1 into elem 0 */
	sv = newSViv( pMystruct->mymember1 );
	if( av_store( av, 0, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem zero");
	}
	/* put mymember2 into elem 1 */
	sv = newSViv( pMystruct->mymember2 );
	if( av_store( av, 1, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem one");
	}

	/* put ref for Data[] array into elem 2 */
	sv = newRV( (SV*)iav );
	SvREFCNT_dec( iav ); /* compensate */
	if( av_store( av, 2, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem two");
	}

	/* put Data into elem 3 */
	sv = newSViv( *(pMystruct->Data) );
	if( av_store( av, 3, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem three");
	}


	/* Copy Data[] array */

	/* put iData[0] into iav elem 0 */
	sv = newSViv( pMystruct->iData[0] );
	if( av_store( iav, 0, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store iav elem zero");
	}
	/* put iData[1] into iav elem 1 */
	sv = newSViv( pMystruct->iData[1] );
	if( av_store( iav, 1, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store iav elem one");
	}
	/* put iData[2] into iav elem 2 */
	sv = newSViv( pMystruct->iData[2] );
	if( av_store( iav, 2, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store iav elem two");
	}

	sv = newSVrv( st, NULL );       /* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );     /* discard */
	SvRV( st ) = (SV*)av;   /* make stack RV point at our AV */
}

/* Will copy a C Mystruct* to an existing Perl AV*.
 */
void
Packav( av, pMystruct )
AV *av;
Mystruct *pMystruct;
{
	SV *sv;

	/* put mymember1 into elem 0 */
	sv = newSViv( pMystruct->mymember1 );
	if( av_store( av, 0, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem zero");
	}
	/* put mymember2 into elem 1 */
	sv = newSViv( pMystruct->mymember2 );
	if( av_store( av, 1, sv ) == NULL ){
		warn("XS_pack_MystructPtr: failed to store elem one");
	}
}

