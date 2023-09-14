use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::SeqAlignment::edlib;

alien_ok 'Alien::SeqAlignment::edlib';
## test we can link to  XS code that returns one of 
## the non zero constants defined in the edlib.h header
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  ok $module->version;
};
## is edlibAlign symbol found in the dynamic
## library?
ffi_ok { symbols => ['edlibAlign'] };
done_testing;


__DATA__
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <edlib.h>
 
int
version(const char *class)
{
  return EDLIB_STATUS_ERROR;
}
 
MODULE = TA_MODULE PACKAGE = TA_MODULE
 
int version(class);
    const char *class;
