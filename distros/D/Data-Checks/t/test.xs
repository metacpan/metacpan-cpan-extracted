/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "DataChecks.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "optree-additions.c.inc"

MODULE = t::test    PACKAGE = t::test

TYPEMAP: <<HERE
struct DataChecks_Checker * T_PTR
HERE

struct DataChecks_Checker *make_checkdata(SV *checkspec, SV *name, SV *constraint = &PL_sv_undef)
  CODE:
    RETVAL = make_checkdata(checkspec);
    gen_assertmess(RETVAL, name, constraint);
  OUTPUT:
    RETVAL

void free_checkdata(struct DataChecks_Checker *checker);

bool check_value(struct DataChecks_Checker *checker, SV *value)

void assert_value(struct DataChecks_Checker *checker, SV *value)

SV *make_asserter_sub(struct DataChecks_Checker *checker)
  CODE:
  {
    if(!PL_parser) {
      /* We need to generate just enough of a PL_parser to keep newSTATEOP()
       * happy, otherwise it will SIGSEGV
       */
      SAVEVPTR(PL_parser);
      Newxz(PL_parser, 1, yy_parser);
      SAVEFREEPV(PL_parser);

      PL_parser->copline = NOLINE;
      PL_parser->preambling = NOLINE;
    }

    I32 floorix = start_subparse(FALSE, 0);
    OP *body = make_assertop(checker, newSLUGOP(0));
    CV *cv = newATTRSUB(floorix, NULL, NULL, NULL, body);
    RETVAL = newRV_noinc((SV *)cv);
  }
  OUTPUT:
    RETVAL

BOOT:
  boot_data_checks(0);
