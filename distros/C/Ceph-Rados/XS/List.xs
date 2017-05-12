#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <rados/librados.h>

MODULE = Ceph::Rados    	PACKAGE = Ceph::Rados::List

rados_list_ctx_t
open_ctx(io)
    rados_ioctx_t    io
  PREINIT:
    rados_list_ctx_t ctx;
    int              err;
  INIT:
    New( 0, ctx, 1, rados_list_ctx_t );
  CODE:
    err = rados_objects_list_open(io, &ctx);
    if (err < 0)
        croak("cannot open object list: %s", strerror(-err));
    RETVAL = ctx;
  OUTPUT:
    RETVAL

uint32_t
pos(ctx)
    rados_list_ctx_t ctx
  CODE:
    RETVAL = rados_objects_list_get_pg_hash_position(ctx);
  OUTPUT:
    RETVAL

uint32_t
seek(ctx, pos)
    rados_list_ctx_t ctx
    uint32_t         pos
  CODE:
    RETVAL = rados_objects_list_seek(ctx, pos);
  OUTPUT:
    RETVAL

SV *
next(ctx)
    rados_list_ctx_t ctx
  PREINIT:
    const char *     entry;
    const char *     key;
    int              err;
  CODE:
    err = rados_objects_list_next(ctx, &entry, &key);
    if (err == -ENOENT) {
        RETVAL = &PL_sv_undef;
    } else if (err < 0) {
        croak("cannot open object list: %s", strerror(-err));
    } else {
        RETVAL = newSVpv(entry, 0);
    }
  OUTPUT:
    RETVAL

void
close(ctx)
    rados_list_ctx_t ctx
  CODE:
    rados_objects_list_close(ctx);
