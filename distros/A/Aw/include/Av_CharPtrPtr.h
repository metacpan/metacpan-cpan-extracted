#ifndef AV_CHARPTRPTR_H
#define AV_CHARPTRPTR_H 1


char ** XS_unpack_charPtrPtr _(( SV *rv ));
void XS_release_charPtrPtr _(( char **s ));
AV * hashToArray ( HV * hv );

#ifdef PERL58_COMPAT
  void XS_pack_charPtrPtr _(( SV *st, char **s, int n ));
#else
  void XS_pack_charPtrPtr _(( SV *st, char **s ));
#endif /* PERL58_COMPAT */


#endif /* AV_CHARPTRPTR_H */
