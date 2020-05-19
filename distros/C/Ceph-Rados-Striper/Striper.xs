#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <rados/librados.h>
#include <radosstriper/libradosstriper.h>

#include "const-c.inc"

MODULE = Ceph::Rados::Striper		PACKAGE = Ceph::Rados::Striper

INCLUDE: const-xs.inc

rados_striper_t
create(io)
    rados_ioctx_t *  io
  PREINIT:
    rados_striper_t  striper;
    int              err;
  INIT:
    New( 0, striper, 1, rados_striper_t );
  CODE:
    err = rados_striper_create(io, &striper);
    if (err < 0)
        croak("cannot create rados striper: %s", strerror(-err));
    RETVAL = striper;
  OUTPUT:
    RETVAL

int
_object_layout(striper, stripe_unit, stripe_count, object_size)
    rados_striper_t  striper
    unsigned int     stripe_unit
    unsigned int     stripe_count
    unsigned int     object_size
  PREINIT:
    int              err;
  CODE:
    err = rados_striper_set_object_layout_stripe_unit(striper, stripe_unit);
    if (err < 0)
        croak("cannot set rados stripe unit to %i: %s", stripe_unit, strerror(-err));
    err = rados_striper_set_object_layout_stripe_count(striper, stripe_count);
    if (err < 0)
        croak("cannot set rados stripe count to %i: %s", stripe_count, strerror(-err));
    err = rados_striper_set_object_layout_object_size(striper, object_size);
    if (err < 0)
        croak("cannot set rados object size to %i: %s", object_size, strerror(-err));
    RETVAL = err;
  OUTPUT:
    RETVAL

int
_write(striper, soid, data, len, off)
    rados_striper_t  striper
    const char *     soid
    SV *             data
    size_t           len
    uint64_t         off
  PREINIT:
    const char *     buf;
    int              err;
  CODE:
    buf = (const char *)SvPV_nolen(data);
    err = rados_striper_write(striper, soid, buf, len, off);
    if (err < 0)
        croak("cannot write striped object '%s': %s", soid, strerror(-err));
    RETVAL = (err == 0) || (err == len);
  OUTPUT:
    RETVAL

uint64_t
_write_from_fh(striper, soid, fh, psize)
    rados_striper_t  striper
    const char *     soid
    SV *             fh
    int              psize
  PREINIT:
    char *           buf;
    size_t           len;
    int              err;
    uint64_t         off;
  INIT:
    PerlIO *  io     = IoIFP(sv_2io(fh));
    int       retlen = 0;
    int       chk_sz = 1024 * 1024;
    Newx(buf, chk_sz, char);
  CODE:
    //printf("preparing to write from FH to %s\n", soid);
    for (off=0; off<psize; off+=chk_sz) {
        len = psize < off + chk_sz ? psize % chk_sz : chk_sz;
        err = PerlIO_read(io, buf, len);
        if (err < 0)
            croak("cannot read from filehandle: %s", strerror(-err));
        //printf("writing %i bytes from FH to %s\n", len, soid);
        err = rados_striper_read(striper, soid, buf, len, off);
        if (err < 0)
            croak("cannot write striped object '%s': %s", soid, strerror(-err));
        retlen += len;
    }
    //printf("wrote %i bytes from FH to %s\n", retlen, soid);
    RETVAL = retlen;
  OUTPUT:
    RETVAL

int
_append(striper, soid, data, len)
    rados_striper_t  striper
    const char *     soid
    SV *             data
    size_t           len
  PREINIT:
    const char *     buf;
    int              err;
  CODE:
    buf = (const char *)SvPV(data, len);
    err = rados_striper_append(striper, soid, buf, len);
    if (err < 0)
        croak("cannot append to striped object '%s': %s", soid, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

void
_stat(striper, soid)
    rados_striper_t  striper
    const char *     soid
  PREINIT:
    size_t           psize;
    time_t           pmtime;
    int              err;
  PPCODE:
    err = rados_striper_stat(striper, soid, &psize, &pmtime);
    if (err < 0)
        croak("cannot stat object '%s': %s", soid, strerror(-err));
    XPUSHs(sv_2mortal(newSVuv(psize)));
    XPUSHs(sv_2mortal(newSVuv(pmtime)));

SV *
_read(striper, soid, len, off = 0)
    rados_striper_t  striper
    const char *     soid
    size_t           len
    uint64_t         off
  PREINIT:
    char *           buf;
    int              retlen;
  INIT:
    Newx(buf, len, char);
  CODE:
    retlen = rados_striper_read(striper, soid, buf, len, off);
    if (retlen < 0)
        croak("cannot read object '%s': %s", soid, strerror(-retlen));
    RETVAL = newSVpv(buf, retlen);
  OUTPUT:
    RETVAL

int
_read_to_fh(striper, soid, fh)
    rados_striper_t  striper
    const char *     soid
    SV *             fh
  PREINIT:
    char *           buf;
    size_t           len;
    size_t           psize;
    time_t           pmtime;
    int              err;
    uint64_t         off;
  INIT:
    PerlIO *  io     = IoOFP(sv_2io(fh));
    int       chk_sz = 1024 * 1024;
    Newx(buf, chk_sz, char);
  CODE:
    // stat and determine read length
    err = rados_striper_stat(striper, soid, &psize, &pmtime);
    if (err < 0)
        croak("cannot stat object '%s': %s", soid, strerror(-err));
    //printf("preparing to write from %s to FH, %i bytes\n", soid, psize);
    for (off=0; off<psize; off+=chk_sz) {
        len = psize < off + chk_sz ? psize % chk_sz : chk_sz;
        //printf("Reading %i bytes, offset %i, of %i total from striper\n", len, off, psize);
        err = rados_striper_read(striper, soid, buf, len, off);
        if (err < 0)
            croak("cannot read object '%s': %s", soid, strerror(-err));
        //printf("Writing %i bytes to FH\n", len);
        err = PerlIO_write(io, buf, len);
        if (err < 0)
            croak("cannot write to filehandle: %s", strerror(-err));
    }
    if (err < 0)
        croak("cannot read object '%s': %s", soid, strerror(-err));
    RETVAL = err;
  OUTPUT:
    RETVAL


int
remove(striper, soid)
    rados_striper_t  striper
    const char *     soid
  PREINIT:
    int              err;
  CODE:
    err = rados_striper_remove(striper, soid);
    if (err < 0)
        croak("cannot remove striped object '%s': %s", soid, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

void
destroy(striper)
    rados_striper_t  striper
  CODE:
    rados_striper_destroy(striper);
