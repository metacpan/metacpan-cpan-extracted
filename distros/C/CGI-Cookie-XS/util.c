#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

char** XS_unpack_charPtrPtr(SV* arg) {
  AV* avref;
  char** array;
  STRLEN len;
  SV** elem;
  int i;

  if(!SvROK(arg))
    croak("XS_unpack_charPtrPtr: arg is not a reference");
  if( SvTYPE(SvRV(arg)) != SVt_PVAV)
    croak("XS_unpack_charPtrPtr: arg is not an array");
  avref = (AV*)SvRV(arg);
  len = av_len( avref) + 1;
  array = (char **) SvPVX( sv_2mortal( NEWSV(0, (len +1) * sizeof( char*) )));
  for(i = 0; i < len; i++ ) {
    elem = av_fetch( avref, i, 0);
    array[i] = (char *) SvPV( *elem, PL_na);
  }
  array[len] = NULL;
  return array;
}

void XS_pack_charPtrPtr( SV* arg, char** array, int count) {
  int i;
  AV* avref;

  avref = (AV*) sv_2mortal((SV*) newAV() );
  for( i = 0; i < count; i++) {
    av_push(avref, newSVpv(array[i], strlen(array[i])) );
  }
  SvSetSV( arg, newRV((SV*) avref) );
}

