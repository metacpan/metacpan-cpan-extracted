use Test2::V0 -no_srand => 1;
use Test::Alien 0.12;
use Alien::Libbz2;

alien_ok 'Alien::Libbz2';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  ok $module->version;
  note 'version = ', $module->version;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <bzlib.h>

const char *
version(const char *class)
{
  return BZ2_bzlibVersion();
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
    const char *class;
