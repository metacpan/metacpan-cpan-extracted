/* This file is part of the Classic::Perl module.
 * See http://search.cpan.org/dist/Classic-Perl/ */

/* This should never actually be loaded. It is simply here in case this
   becomes an XS module for perl versions < 5.12. In that case, we don’t
   want installation directories changing between versions, as that causes
   a whole mess of problems. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Classic::Perl      PACKAGE = Classic::Perl
