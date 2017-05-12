// Perl includes
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// ICS includes should be normally in /opt/ics/include
#include <stdio.h>
#include "ics.h"
#include <stdlib.h>

MODULE = CyberSource PACKAGE = CyberSource

PROTOTYPES: ENABLE

void
ics_send( request )
	SV *request;
PPCODE:
	ics_msg *icsorder;
	ics_msg *res;
	char *rcode;
	int status = -1;

	HV* hash;
	HE* hash_entry;
	int num_keys, i;
	SV* sv_key;
	SV* sv_val;

	icsorder = ics_init(0);

	/* Now we'll get the hash containing our request */
	if ( !SvROK( request ) )
		croak("hash_ref is not a reference");

	hash = (HV*)SvRV( request );

	num_keys = hv_iterinit(hash);

	for (i = 0; i < num_keys; i++) {
		hash_entry = hv_iternext( hash );
		sv_key = hv_iterkeysv( hash_entry );
		sv_val = hv_iterval( hash, hash_entry );
		ics_fadd( icsorder,
			SvPV(sv_key, PL_na), 
			SvPV(sv_val, PL_na)
			);
	}

	/* Send the message to the ics server and handle results */
	printf("-- request --\n");
	ics_print(icsorder);
	res = ics_send(icsorder);
	printf("-- response --\n");
	ics_print( res );
	printf("-- processing : %d entries --\n", ics_fcount(res) );

	/* Put result into returning hash */
	for ( i=0 ; i < ics_fcount(res) ; i++ ) {
		PUSHs( sv_2mortal(newSVpvf( ics_fname( res, i ) )) );
		PUSHs( sv_2mortal(newSVpvf( ics_fget( res, i ) )) );
	}
	printf("-- finished : %d entries --\n", i );

	ics_destroy(icsorder);
	ics_destroy(res);

