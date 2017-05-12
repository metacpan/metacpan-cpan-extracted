#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AB_IN.h"
#include "Av_AB_INPtr.h"

#ifdef __cplusplus
}
#endif

/* Will convert a Perl AV* to a C AB_IN*. */
AB_IN *
XS_unpack_AB_INPtr( rv )
SV *rv;
{
	AV *av;
	SV **ssv;
	int avlen;
	AB_IN *abin;

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVAV) )
		av = (AV*)SvRV(rv);
	else{
		warn("XS_unpack_AB_INPtr: rv was not an AV ref");
		return( (AB_IN*)NULL );
	}

	avlen = av_len( av );
	if( avlen != 1 ){
		warn("XS_unpack_AB_INPtr: array must have exactly two elements");
		return( (AB_IN*)NULL );
	}

	abin = (AB_IN*)safemalloc( sizeof( AB_IN ) );
	if( abin == NULL ){
		warn("XS_unpack_AB_INPtr: unable to malloc AB_IN");
		return( (AB_IN*)NULL );
	}
	abin->szDescription[0] = '\0';
	abin->lTrackId = 0;

	/* Pull lTrackId from array */
	ssv = av_fetch( av, 0, 0 );
	if( ssv != NULL ){
		if( SvIOK( *ssv ) )
			abin->lTrackId = (long)SvIV( *ssv );
		else
			warn("XS_unpack_AB_INPtr: array elem zero was not IOK");
	}
	else
		warn("XS_unpack_AB_INPtr: array elem zero was null");

	/* Pull szDescription from array */
	ssv = av_fetch( av, 1, 0 );
	if( ssv != NULL ){
		if( SvPOK( *ssv ) )
			strcpy( abin->szDescription, SvPV(*ssv,na) );
		else
			warn("XS_unpack_AB_INPtr: array elem zero was not POK");
	}
	else
		warn("XS_unpack_AB_INPtr: array elem one was null");

	return( abin );
}

/* Will convert a C AB_IN* to a Perl AV*. */
void
XS_pack_AB_INPtr( st, abin )
SV *st;
AB_IN *abin;
{
	AV *av = newAV();
	SV *sv;

	/* put lTrackId into elem 0 */
	sv = newSViv( abin->lTrackId );
	if( av_store( av, 0, sv ) == NULL ){
		warn("XS_pack_AB_INPtr: failed to store elem zero");
	}
	/* put szDescription into elem 1 */
	sv = newSVpv( abin->szDescription, 0 );
	if( av_store( av, 1, sv ) == NULL ){
		warn("XS_pack_AB_INPtr: failed to store elem one");
	}

	sv = newSVrv( st, NULL );	/* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );	/* discard */
	SvRV( st ) = (SV*)av;	/* make stack RV point at our AV */
}
