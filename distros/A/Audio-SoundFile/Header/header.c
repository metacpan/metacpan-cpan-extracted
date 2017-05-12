/* -*- mode: c -*-
 *
 * $Id: header.c,v 1.1 2001/01/06 18:39:17 tai Exp $
 *
 */

#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>

#include <sndfile.h>

#include "header.h"

SV *
Audio_SoundFile_Header_toObject(pTHX_ HV *hash, SF_INFO *info) {
  if (! sf_format_check(info))
    return &PL_sv_undef;

  hash = hash ? hash : newHV();

  hv_store(hash, "samplerate",  10, newSViv((IV)info->samplerate),  0);
  hv_store(hash, "samples",      7, newSViv((IV)info->frames),      0);
  hv_store(hash, "channels",     8, newSViv((IV)info->channels),    0);
  hv_store(hash, "format",       6, newSViv((IV)info->format),      0);
  hv_store(hash, "sections",     8, newSViv((IV)info->sections),    0);
  hv_store(hash, "seekable",     8, newSViv((IV)info->seekable),    0);

  return sv_bless(newRV_inc((SV *)hash),
                  gv_stashpv("Audio::SoundFile::Header", 1));
}

SF_INFO *
Audio_SoundFile_Header_toSFinfo(pTHX_ SV *self) {
  SF_INFO *info;
  HV      *hash;
  SV      *hval;
  char    *hkey;
  I32      klen;

  if (! (SvROK(self) && SvTYPE(hash = (HV *)SvRV(self)) == SVt_PVHV))
    return NULL;

  if ((info = (SF_INFO *)calloc(1, sizeof(SF_INFO))) != NULL) {
    hv_iterinit(hash);
    while (hval = hv_iternextsv(hash, &hkey, &klen)) {
      if      (strEQ(hkey, "samplerate"))  info->samplerate  = SvIV(hval);
      else if (strEQ(hkey, "samples"))     info->frames      = SvIV(hval);
      else if (strEQ(hkey, "channels"))    info->channels    = SvIV(hval);
      else if (strEQ(hkey, "format"))      info->format      = SvIV(hval);
      else if (strEQ(hkey, "sections"))    info->sections    = SvIV(hval);
      else if (strEQ(hkey, "seekable"))    info->seekable    = SvIV(hval);
      else
        warn("Ignoring unexpected parameter: %s\n", hkey);
    }
  }

  return sf_format_check(info) ? info : NULL;
}
