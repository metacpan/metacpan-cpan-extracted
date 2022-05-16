use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::zlib;

alien_diag 'Alien::zlib';
alien_ok 'Alien::zlib';

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "zlib.h"

const char* version(const char* class) {
  return zlibVersion();
}

MODULE = main PACKAGE = main

const char* version(class);
  const char *class;

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  is $module->version, Alien::zlib->version, 'version string';
};

ffi_ok { symbols => ['zlibVersion'] }, with_subtest {
  my $ffi = shift;
  my $get_version = $ffi->function(zlibVersion => [] => 'string');
  is $get_version->call(), Alien::zlib->version, 'version string';
};

done_testing;
