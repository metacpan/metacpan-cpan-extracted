/*
 * Loop.xs - root XS file.
 *
 * Thin wrapper (the Chandra pattern): pull in the C implementation headers,
 * then splice the per-component XS fragments via INCLUDE: so xsubpp compiles
 * them all into one Loop.c / Loop.o - no EUMM subdir-object trouble.
 *
 *   include/  - the C core (future, DBI executor, object dispatch)
 *   xs/       - the XS fragments, one per package
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dbil_future.h"   /* DBIx::Loop::Future (C)             */
#include "dbil_run.h"      /* run one DBI statement from C       */
#include "dbil_vt.h"       /* pure-C loop seam (adapter vtable)  */
#include "dbil_pool.h"     /* Backend B: forked worker pool      */
#include "dbil_txn.h"      /* transactions pinned to a pool slot */
#include "dbil_native.h"   /* Backend A: native fd async (Pg)    */
#include "dbil_hm.h"       /* Hyperman adapter over its C ABI    */
#include "dbil_loop.h"     /* driver-name, capability, dispatch  */

MODULE = DBIx::Loop        PACKAGE = DBIx::Loop

INCLUDE: xs/loop.xs
INCLUDE: xs/future.xs
INCLUDE: xs/txn.xs
INCLUDE: xs/loop_hyperman.xs
