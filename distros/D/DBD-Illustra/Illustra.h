/*##############################################################################
#
#   File name: Illustra.xs
#   Project: DBD::Illustra
#   Description: 
#
#   Author: Peter Haworth
#   Date created: 17/07/1998
#
#   sccs version: 1.3    last changed: 08/12/98
#
#   Copyright (c) 1998 Institute of Physics Publishing
#   You may distribute under the terms of the Artistic License,
#   as distributed with Perl, with the exception that it cannot be placed
#   on a CD-ROM or similar media for commercial distribution without the
#   prior approval of the author.
#
##############################################################################*/

/* mi.h defines ARGS for internal header stuff, which conflicts with perls
 * definition of ARGS. However, ARGS is only used internally in mi.h,
 * so we can undef it safely
 */
#include <mi.h>
#undef ARGS

#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>

#include "dbdimp.h"

#include <dbd_xsh.h>


