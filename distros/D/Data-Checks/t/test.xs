/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "DataChecks.h"

MODULE = t::test    PACKAGE = t::test

TYPEMAP: <<HERE
struct DataChecks_Checker * T_PTR
HERE

struct DataChecks_Checker *make_checkdata(SV *checkspec, SV *name, SV *constraint)
  CODE:
    RETVAL = make_checkdata(checkspec);
    gen_assertmess(RETVAL, name, constraint);
  OUTPUT:
    RETVAL

void free_checkdata(struct DataChecks_Checker *checker);

bool check_value(struct DataChecks_Checker *checker, SV *value)

void assert_value(struct DataChecks_Checker *checker, SV *value)

BOOT:
  boot_data_checks(0);
