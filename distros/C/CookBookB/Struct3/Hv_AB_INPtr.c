#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AB_IN.h"
#include "Hv_AB_INPtr.h"

#ifdef __cplusplus
}
#endif

/* Will convert a Perl HV* to a C AB_IN* */
AB_IN *
XS_unpack_AB_INPtr( rv )
SV *rv;
{
	HV *hv;
	SV **ssv;
	AB_IN *abin;

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVHV) )
		hv = (HV*)SvRV(rv);
	else{
		warn("XS_unpack_AB_INPtr: rv was not an HV ref");
		return( (AB_IN*)NULL );
	}

	abin = (AB_IN*)safemalloc( sizeof( AB_IN ) );
	if( abin == NULL ){
		warn("XS_unpack_AB_INPtr: unable to malloc AB_IN");
		return( (AB_IN*)NULL);
	}
	abin->szDescription[0] = '\0';
	abin->lTrackId = 0;

	/* Pull lTrackId from hash */
	ssv = hv_fetch( hv, "lTrackId", 8, 0 );
	if( ssv != NULL ){
		if( SvIOK( *ssv ) )
			abin->lTrackId = (long)SvIV( *ssv );
		else{
			warn("XS_unpack_AB_INPtr: hash elem lTrackId was not IOK");
		}
	}
	else
		warn("XS_unpack_AB_INPtr: hash elem lTrackId was null");

	/* Pull szDescription from hash */
	ssv = hv_fetch( hv, "szDescription", 13, 0 );
	if( ssv != NULL ){
		if( SvPOK( *ssv ) )
			strcpy( abin->szDescription, SvPV(*ssv,na) );
		else{
			warn("XS_unpack_AB_INPtr: hash elem szDescription was not POK");
		}
	}
	else
		warn("XS_unpack_AB_INPtr: hash elem szDescription was null");

	return( abin );
}

/* Will convert a C AB_IN* to a Perl HV* */
void
XS_pack_AB_INPtr( st, abin )
SV *st;
AB_IN *abin;
{
	HV *hv = newHV();
	SV *sv;

	/* put lTrackId into hash */
	sv = newSViv( abin->lTrackId );
	if( hv_store( hv, "lTrackId", 8, sv, 0 ) == NULL ){
		warn("XS_pack_AB_INPtr: failed to store lTrackId elem");
	}
	/* put szDescription into hash */
	sv = newSVpv( abin->szDescription, 0 );
	if( hv_store( hv, "szDescription", 13, sv, 0 ) == NULL ){
		warn("XS_pack_AB_INPtr: failed to store szDescription elem");
	}

	sv = newSVrv( st, NULL );	/* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );	/* discard */
	SvRV( st ) = (SV*)hv;	/* make stack RV point at our HV */
}
