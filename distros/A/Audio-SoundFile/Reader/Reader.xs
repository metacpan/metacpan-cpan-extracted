/* -*- mode: c -*-
 *
 * $Id: Reader.xs,v 1.2 2001/01/07 04:06:38 tai Exp $
 *
 */

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <sndfile.h>

#include <pdl.h>
#include <pdlcore.h>

#include "header.h"

#define CLASSNAME "Audio::SoundFile::Reader"

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

MODULE = Audio::SoundFile::Reader    PACKAGE = Audio::SoundFile::Reader

SV *
new(name, path, href)
  char *name
  char *path
  SV   *href
PROTOTYPE: $$$
PREINIT:
  SF_INFO  info;
  SNDFILE *file;
  SV      *self;
  HV      *hash;
  SV      *head;
PPCODE:
{
  if (! SvROK(href))
    XSRETURN_UNDEF;

  if ((file = sf_open(path, SFM_READ, &info)) == NULL)
    XSRETURN_UNDEF;

  if (! SvOK(head = Audio_SoundFile_Header_toObject(aTHX_ NULL, &info)))
    XSRETURN_UNDEF;

  sv_setsv(SvRV(href), head);

  hash = newHV();
  hv_store(hash, "head", 4, head, 0);
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

int
bread_raw(self, bref, blocks)
  SV     *self
  SV     *bref
  size_t  blocks
PROTOTYPE: $$$
PREINIT:
  HV    *hash;
  SV   **file;
  SV   **head;
  short *buff;
  size_t blen;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  buff = (short *)malloc(sizeof(short) * blocks);
  blen = sf_read_short((SNDFILE *)SvIV(*file), buff, blocks);

  if (blen > 0)
    sv_setpvn(SvRV(bref), (char *)buff, blen * sizeof(short) / sizeof(char));
  else
    sv_setsv(SvRV(bref), &PL_sv_undef);

  free(buff);

  XSRETURN_IV(blen);
}

int
bread_pdl(self, bref, blocks)
  SV  *self
  SV  *bref
  int  blocks
PROTOTYPE: $$$
PREINIT:
  HV    *hash;
  SV   **file;
  SV   **head;
  pdl   *newp;
  size_t blen;
PPCODE:
{
  CHECK_AND_INIT(self, hash, file, head);

  newp = PDL->create(PDL_PERM);
  newp->datatype = PDL_S;
  PDL->setdims(newp, (PDL_Long *)&blocks, 1);
  PDL->allocdata(newp);

  blen = sf_read_short((SNDFILE *)SvIV(*file), newp->data, blocks);

  if (blen > 0) {
    newp->nvals = blen;
    PDL->SetSV_PDL(SvRV(bref), newp);
  }
  else {
    PDL->destroy(newp);
    sv_setsv(SvRV(bref), &PL_sv_undef);
  }

  XSRETURN_IV(blen);
}

SV *
fread_raw(self, bref, frames)
  SV     *self
  SV     *bref
  size_t  frames
PROTOTYPE: $$$
PPCODE:
{
  XSRETURN_UNDEF; /* FIXME: not yet implemented */
}

SV *
fread_pdl(self, bref, frames)
  SV     *self
  SV     *bref
  size_t  frames
PROTOTYPE: $$$
PPCODE:
{
  XSRETURN_UNDEF; /* FIXME: not yet implemented */
}

BOOT:
  PDL_addr = perl_get_sv("PDL::SHARE", FALSE);
  if (! PDL_addr)
     croak("This module requires use of PDL::Core first");
  PDL = (Core *)SvIV(PDL_addr);
