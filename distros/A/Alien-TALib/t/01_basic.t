use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::TALib;


alien_diag 'Alien::TALib';
alien_ok 'Alien::TALib';

my $version_re = qr/^[0-9.]+(?:-dev)?/;

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ta_libc.h"

const char* version(const char* class) {
  return TA_GetVersionString();
}

MODULE = main PACKAGE = main

const char* version(class);
  const char *class;

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  like $module->version, $version_re, 'version string';
};

subtest "FFI" => sub {
  plan skip_all => 'Upstream library currently does not support DLL export for FFI'
    if $^O eq 'MSWin32';
  ffi_ok { symbols => ['TA_GetVersionString'] }, with_subtest {
    my $ffi = shift;
    my $get_version = $ffi->function(TA_GetVersionString => [] => 'string');
    like $get_version->call(), $version_re, 'version string';
  };
};

done_testing;
