/* -*- c -*-
 * Perl bindings for the libkafs PAG functions.
 *
 * This is an XS source file, suitable for processing by xsubpp, that
 * generates Perl bindings for the PAG functions in the libkafs library or any
 * similar library that provides the same interface.  The module exports those
 * functions to Perl without the k_* prefix, since Perl already has good
 * namespace management for imports.
 *
 * Written by Russ Allbery <rra@cpan.org>
 * Copyright 2013
 *     The Board of Trustees of the Leland Stanford Junior University
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <glue/config.h>
#include <portable/kafs.h>
#include <portable/system.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <errno.h>

/* XS code below this point. */

MODULE = AFS::PAG       PACKAGE = AFS::PAG

PROTOTYPES: DISABLE

void
hasafs()
  PPCODE:
    if (k_hasafs())
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;


void
haspag()
  PPCODE:
    if (k_haspag())
        XSRETURN_YES;
    else
        XSRETURN_UNDEF;


void
setpag()
  PPCODE:
    if (k_setpag() == 0)
        XSRETURN_YES;
    else
        croak("PAG creation failed: %s", strerror(errno));


void
unlog()
  PPCODE:
    if (k_unlog() == 0)
        XSRETURN_YES;
    else
        croak("Token deletion failed: %s", strerror(errno));
