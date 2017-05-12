/* -*- mode: c -*-
 *
 * $Id: Header.xs,v 1.1 2001/01/06 18:39:17 tai Exp $
 *
 */

#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>

#include <sndfile.h>

#include "header.h"

#define CLASSNAME "Audio::SoundFile::Header"

MODULE = Audio::SoundFile::Header    PACKAGE = Audio::SoundFile::Header

SV *
format_check(self)
  SV *self
PROTOTYPE: $
PREINIT:
  SF_INFO *info;
  HV      *hash;
  SV      *head;
PPCODE:
{
  if (! (sv_isobject(self) && sv_derived_from(self, CLASSNAME)))
    XSRETURN_UNDEF;

  if (SvTYPE(hash = (HV *)SvRV(self)) != SVt_PVHV)
    XSRETURN_UNDEF;

  if ((info = Audio_SoundFile_Header_toSFinfo(aTHX_ self)) != NULL) {
    head = Audio_SoundFile_Header_toObject(aTHX_ hash, info);
    free(info);
    if (SvOK(head))
      XSRETURN_YES;
  }

  XSRETURN_NO;
}
