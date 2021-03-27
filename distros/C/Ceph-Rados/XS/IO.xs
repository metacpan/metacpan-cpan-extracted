#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <rados/librados.h>

MODULE = Ceph::Rados    	PACKAGE = Ceph::Rados::IO

rados_ioctx_t
create(cluster, pool_name)
    rados_t *        cluster
    const char *     pool_name
  PREINIT:
    rados_ioctx_t    io;
    int              err;
  INIT:
    New( 0, io, 1, rados_ioctx_t );
  CODE:
    err = rados_ioctx_create(cluster, pool_name, &io);
    if (err < 0)
        croak("cannot open rados pool '%s': %s", pool_name, strerror(-err));
    RETVAL = io;
  OUTPUT:
    RETVAL

int
_write(io, oid, data, len, off)
    rados_ioctx_t    io
    const char *     oid
    SV *             data
    size_t           len
    uint64_t         off
  PREINIT:
    const char *     buf;
    int              err;
  CODE:
    buf = (const char *)SvPV_nolen(data);
    err = rados_write(io, oid, buf, len, off);
    if (err < 0)
        croak("cannot write object '%s': %s", oid, strerror(-err));
    RETVAL = (err == 0) || (err == len);
  OUTPUT:
    RETVAL

int
_write_from_fh(ioctx, oid, fh, psize, debug=false)
    rados_ioctx_t  ioctx
    const char *     oid
    SV *             fh
    uint64_t         psize
    bool             debug
  PREINIT:
    char *           buf;
    size_t           len;
    int              err;
    uint64_t         off;
  INIT:
    PerlIO *  io     = IoIFP(sv_2io(fh));
    uint64_t  retlen = 0;
    int       chk_sz = 1024 * 1024;
    Newx(buf, chk_sz, char);
  CODE:
    if (debug)
        printf("preparing to write from FH to %s\n", oid);
    for (off=0; off<psize; off+=chk_sz) {
        len = psize < off + chk_sz ? psize % chk_sz : chk_sz;
        err = PerlIO_read(io, buf, len);
        if (err < 0)
            croak("cannot read from filehandle: %s", strerror(-err));
        if (debug)
            printf("writing %" PRIu64 "-%" PRIu64 " / %" PRIu64 " bytes from FH to %s\n", off, off+len, psize, oid);
        err = rados_read(ioctx, oid, buf, len, off);
        if (err < 0)
            croak("cannot write striped object '%s': %s", oid, strerror(-err));
        retlen += len;
    }
    if (debug)
        printf("wrote %" PRIu64 " bytes from FH to %s\n", retlen, oid);
    RETVAL = retlen;
  OUTPUT:
    RETVAL

int
_append(io, oid, data, len)
    rados_ioctx_t    io
    const char *     oid
    SV *             data
    size_t           len
  PREINIT:
    const char *     buf;
    int              err;
  CODE:
    buf = (const char *)SvPV(data, len);
    err = rados_append(io, oid, buf, len);
    if (err < 0)
        croak("cannot append to object '%s': %s", oid, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

void
_stat(io, oid)
    rados_ioctx_t    io
    const char *     oid
  PREINIT:
    size_t           size;
    time_t           mtime;
    int              err;
  PPCODE:
    err = rados_stat(io, oid, &size, &mtime);
    if (err < 0)
        croak("cannot stat object '%s': %s", oid, strerror(-err));
    XPUSHs(sv_2mortal(newSVuv(size)));
    XPUSHs(sv_2mortal(newSVuv(mtime)));


SV *
_read(io, oid, len, off = 0)
    rados_ioctx_t    io
    const char *     oid
    size_t           len
    uint64_t         off
  PREINIT:
    char *           buf;
    int              retlen;
  INIT:
    Newx(buf, len, char);
  CODE:
    retlen = rados_read(io, oid, buf, len, off);
    if (retlen < 0)
        croak("cannot read object '%s': %s", oid, strerror(-retlen));
    RETVAL = newSVpv(buf, retlen);
  OUTPUT:
    RETVAL

int
_read_to_fh(ioctx, oid, fh, len = 0, off = 0, debug=false)
    rados_ioctx_t  ioctx
    const char *     oid
    SV *             fh
    size_t           len
    uint64_t         off
    bool             debug
  PREINIT:
    char *           buf;
    int              buflen;
    uint64_t         bufpos;
    size_t           psize;
    time_t           pmtime;
    int              err;
  INIT:
    PerlIO *  io     = IoOFP(sv_2io(fh));
    int       chk_sz = 1024 * 1024;
    Newx(buf, chk_sz, char);
  CODE:
    if ((0 == len) || debug) {
        // stat and determine read length
        err = rados_stat(ioctx, oid, &psize, &pmtime);
        if (err < 0)
            croak("cannot stat object '%s': %s", oid, strerror(-err));
    }
    if (0 == len)
        len = psize-off;
    if (debug)
        printf("preparing to write from %s to FH, %zu bytes\n", oid, len);
    for (bufpos=off; bufpos<len+off; bufpos+=chk_sz) {
        // logic is 'will bufpos move past ien+offnext cycle'
        buflen = len+off < bufpos+chk_sz ? len+off % chk_sz : chk_sz;
        if (debug)
            printf("Reading %u bytes, offset %" PRIu64 ", of %" PRIu64 "-%" PRIu64 "/%" PRIu64 " from striper\n", buflen, bufpos, off, len+off, psize);

        err = rados_read(ioctx, oid, buf, buflen, bufpos);
        if (err < 0)
            croak("cannot read object '%s': %s", oid, strerror(-err));
        if (debug)
            printf("Writing %zu bytes to FH\n", len);
        err = PerlIO_write(io, buf, buflen);
        if (err < 0)
            croak("cannot write to filehandle: %s", strerror(-err));
    }
    if (err < 0)
        croak("cannot read object '%s': %s", oid, strerror(-err));
    RETVAL = err;
  OUTPUT:
    RETVAL


uint64_t
_pool_required_alignment(io)
    rados_ioctx_t    io
  PREINIT:
    uint64_t         req;
    int              err;
  CODE:
    err = rados_ioctx_pool_required_alignment2(io, &req);
    if (err < 0)
        croak("cannot rados_ioctx_pool_required_alignment2(): %s", strerror(-err));
    RETVAL = req;
  OUTPUT:
    RETVAL

int
remove(io, oid)
    rados_ioctx_t    io
    const char *     oid
  PREINIT:
    int              err;
  CODE:
    err = rados_remove(io, oid);
    if (err < 0)
        croak("cannot remove object '%s': %s", oid, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

void
destroy(io)
    rados_ioctx_t    io
  CODE:
    rados_ioctx_destroy(io);
