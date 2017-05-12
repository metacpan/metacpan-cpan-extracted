/* -*- mode: c -*-
 *
 * $Id: Writer.xs,v 1.2 2001/01/07 04:06:48 tai Exp $
 *
 */

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sndfile.h>

#include <pdl.h>
#include <pdlcore.h>

#include "header.h"

#define CLASSNAME "Audio::SoundFile::Writer"

#define CHECK_AND_INIT(self, hash, file, head) \
  if (! (sv_isobject(self) && sv_derived_from(self, CLASSNAME))) \
    XSRETURN_UNDEF; \
  if (SvTYPE(hash = (HV *)SvRV(self)) != SVt_PVHV)   \
    XSRETURN_UNDEF; \
  if ((file = hv_fetch(hash, "file", 4, 0)) == NULL) \
    XSRETURN_UNDEF; \
  if ((head = hv_fetch(hash, "head", 4, 0)) == NULL) \
    XSRETURN_UNDEF;

static Core *PDL;
SV          *PDL_addr;

MODULE = Audio::SoundFile::Writer    PACKAGE = Audio::SoundFile::Writer

SV *
new(name, path, href)
  char *name
  char *path
  SV   *href
PROTOTYPE: $$$
PREINIT:
  SF_INFO *info;
  SNDFILE *file;
  HV      *hash;
PPCODE:
{
  if ((info = Audio_SoundFile_Header_toSFinfo(aTHX_ href)) == NULL)
    XSRETURN_UNDEF;

  if ((file = sf_open(path, SFM_WRITE, info)) == NULL)
    XSRETURN_UNDEF;

  hash = newHV();
  hv_store(hash, "head", 4, href, 0);
  hv_store(hash, "file", 4, newSViv((IV)file), 0);

  XPUSHs(sv_bless(newRV_inc((SV *)hash), gv_stashpv(name, 0)));
  XSRETURN(1);
}

SV *
close(self)
  SV *self
PROTOTYPE: $
PREINIT:
  HV  *hash;
  SV **file;
  SV **head;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  XSRETURN_IV(sf_close((SNDFILE *)SvIV(*file)));
}

SV *
bseek(self, offset, whence)
  SV    *self
  off_t  offset
  int    whence
PROTOTYPE: $$$
PREINIT:
  SF_INFO *info;
  HV      *hash;
  SV     **file;
  SV     **head;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  info = Audio_SoundFile_Header_toSFinfo(aTHX_ *head);

  XSRETURN_IV(info->channels * sf_seek((SNDFILE *)SvIV(*file),
                                       info->channels * offset, whence));
}

SV *
fseek(self, offset, whence)
  SV    *self
  off_t  offset
  int    whence
PROTOTYPE: $$$
PREINIT:
  HV  *hash;
  SV **file;
  SV **head;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  XSRETURN_IV(sf_seek((SNDFILE *)SvIV(*file), offset, whence));
}

SV *
bwrite_raw(self, buff)
  SV *self
  SV *buff
PROTOTYPE: $$
PREINIT:
  HV    *hash;
  SV   **file;
  SV   **head;
  short *bptr;
  STRLEN blen;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  bptr = (short *)SvPV(buff, blen);
  blen = sf_write_short((SNDFILE *)SvIV(*file),
                        bptr, blen * sizeof(char) / sizeof(short));

  XSRETURN_IV(blen);
}

SV *
bwrite_pdl(self, buff)
  SV  *self
  pdl *buff
PROTOTYPE: $$
PREINIT:
  HV    *hash;
  SV   **file;
  SV   **head;
  size_t blen;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  blen = sf_write_short((SNDFILE *)SvIV(*file), buff->data, buff->nvals);

  XSRETURN_IV(blen);
}

SV *
fwrite_raw(self, buff)
  SV *self
  SV *buff
PROTOTYPE: $$
PPCODE:
{
  XSRETURN_UNDEF; /* FIXME: not yet implemented */
}

SV *
fwrite_pdl(self, buff)
  SV  *self
  pdl *buff
PROTOTYPE: $$
PPCODE:
{
  XSRETURN_UNDEF; /* FIXME: not yet implemented */
}

BOOT:
  PDL_addr = perl_get_sv("PDL::SHARE", FALSE);
  if (! PDL_addr)
     croak("This module requires use of PDL::Core first");
  PDL = (Core *)SvIV(PDL_addr);
