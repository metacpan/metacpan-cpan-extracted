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
_pool_required_alignment(io)
    rados_ioctx_t    io
  PREINIT:
    const char *     buf;
    int              res;
  CODE:
    res = rados_ioctx_pool_required_alignment(io);
    RETVAL = res;
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
