#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <rados/librados.h>

#include "const-c.inc"

#if !defined(_STDINT_H) && !defined(__WORDSIZE)
// stdint.h and bits/types.h also have these:
typedef unsigned long long uint64_t;
typedef unsigned int       uint32_t;
#endif

MODULE = Ceph::Rados		PACKAGE = Ceph::Rados

INCLUDE: const-xs.inc

rados_t
create(id)
    const char *     id
  PREINIT:
    rados_t          cluster;
    int              err;
  INIT:
    New( 0, cluster, 1, rados_t );
  CODE:
    err = rados_create(&cluster, id);
    if (err < 0)
        croak("cannot create a cluster handle: %s", strerror(-err));
    RETVAL = cluster;
  OUTPUT:
    RETVAL

int
set_config_file(cluster, path = NULL)
    rados_t *        cluster
    const char *     path
  PREINIT:
    int              err;
  CODE:
    err = rados_conf_read_file(cluster, path);
    if (err < 0)
        croak("cannot read config file '%s': %s", path, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

int
set_config_option(cluster, option, value)
    rados_t          cluster
    const char *     option
    const char *     value
  PREINIT:
    int              err;
  CODE:
    err = rados_conf_set(cluster, option, value);
    if (err < 0)
        croak("cannot set config option '%s': %s", option, strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

int
connect(cluster)
    rados_t          cluster
  PREINIT:
    int              err;
  CODE:
    err = rados_connect(cluster);
    if (err < 0)
        croak("cannot connect to cluster: %s", strerror(-err));
    RETVAL = err == 0;
  OUTPUT:
    RETVAL

void
shutdown(cluster)
    rados_t          cluster
  CODE:
    rados_shutdown(cluster);

INCLUDE: XS/IO.xs
INCLUDE: XS/List.xs

