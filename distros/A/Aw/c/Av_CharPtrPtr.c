#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Av_CharPtrPtr.h"  /* XS_*_charPtrPtr() */
#ifdef __cplusplus
}
#endif

#ifdef  PERL5004_COMPAT
# define PL_na na
#endif /* PERL5004_COMPAT */



AV *
hashToArray ( HV * hv )
{
HE* entry;
SV* sv;
AV* av;
int i, n;
char *key, *value, *keyValue;


	av = newAV();
	n     = hv_iterinit ( hv );


	for ( i=0; i<n; i++ ) { 
		entry = hv_iternext ( hv );
		key   = HeKEY(entry);
		value = SvPV (HeVAL ( entry ), PL_na);

		keyValue = (char *)safemalloc ( sizeof (char) * ( strlen(key) + strlen(value) + 2) );
		sprintf ( keyValue, "%s=%s", key, value );
		sv = newSVpv ( keyValue, 0);
		av_push ( av, sv );
	}

	return ( av );
}



/* Used by the INPUT typemap for char**.
 * Will convert a Perl AV* (containing strings) to a C char**.
 */
char **
XS_unpack_charPtrPtr( rv )
SV *rv;
{
	AV *av;
	SV **ssv;
	char **s;
	int avlen;
	int x;

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVAV) )
		av = (AV*)SvRV(rv);
	else if ( SvTYPE(SvRV(rv)) == SVt_PVHV ) {
		/* we were passed a properties hash reference */
		av = hashToArray ( (HV*)SvRV(rv) );
	} else {
		warn("XS_unpack_charPtrPtr: rv was not an AV ref");
		return( (char**)NULL );
	}

	/* is it empty? */
	avlen = av_len(av);
	if( avlen < 0 ){
		warn("XS_unpack_charPtrPtr: array was empty");
		return( (char**)NULL );
	}

	/* av_len+2 == number of strings, plus 1 for an end-of-array sentinel.
	 */
	s = (char **)safemalloc( sizeof(char*) * (avlen + 2) );
	if( s == NULL ){
		warn("XS_unpack_charPtrPtr: unable to malloc char**");
		return( (char**)NULL );
	}
	for( x = 0; x <= avlen; ++x ){
		ssv = av_fetch( av, x, 0 );
		if( ssv != NULL ){
			if( SvPOK( *ssv ) ){
				s[x] = (char *)safemalloc( SvCUR(*ssv) + 1 );
				if( s[x] == NULL )
					warn("XS_unpack_charPtrPtr: unable to malloc char*");
				else
					strcpy( s[x], SvPV( *ssv, PL_na ) );
			}
			else
				warn("XS_unpack_charPtrPtr: array elem %d was not a string.", x );
		}
		else
			s[x] = (char*)NULL;
	}
	s[x] = (char*)NULL; /* sentinel */
	return( s );
}

/* Used by the OUTPUT typemap for char**.
 * Will convert a C char** to a Perl AV*.
 */
void
#ifdef PERL58_COMPAT
  XS_pack_charPtrPtr( st, s, n )
  SV *st;
  char **s;
  int n;
#else
  XS_pack_charPtrPtr( st, s )
  SV *st;
  char **s;
#endif /* PERL58_COMPAT */
{
	AV *av = newAV();
	SV *sv;
	char **c;

	for( c = s; *c != NULL; ++c ){
		sv = newSVpv( *c, 0 );
		av_push( av, sv );
	}
	free ( s );
	sv = newSVrv( st, NULL );	/* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );	/* discard */
	SvRV( st ) = (SV*)av;	/* make stack RV point at our AV */
}


/* cleanup the temporary char** from XS_unpack_charPtrPtr */
void
XS_release_charPtrPtr(s)
char **s;
{
	char **c;
	for( c = s; *c != NULL; ++c )
		Safefree( *c );
	Safefree( s );
}

