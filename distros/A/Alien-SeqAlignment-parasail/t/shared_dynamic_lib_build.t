use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::SeqAlignment::parasail;

alien_ok 'Alien::SeqAlignment::parasail';
## test we can link to  XS code that returns one of 
## the non zero constants defined in the edlib.h header
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  ok $module->version;
};
## could we find two symbols in the shared library?
ffi_ok { symbols => ['parasail_matrix_create', 'parasail_matrix_lookup'] };
done_testing;


__DATA__
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <parasail.h>
 
int
version(const char *class)
{
  return PARASAIL_INS ;
}
 
MODULE = TA_MODULE PACKAGE = TA_MODULE
 
int version(class);
    const char *class;
