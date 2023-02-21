use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::zstd;

alien_diag 'Alien::zstd';
alien_ok 'Alien::zstd';

run_ok([ qw(zstd --version) ])
  ->success
  ->out_like(qr/zstd command line interface|Zstandard CLI/);

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "zstd.h"

const char* version(const char* class) {
  return ZSTD_versionString();
}

MODULE = main PACKAGE = main

const char* version(class);
  const char *class;

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  is $module->version, Alien::zstd->version, 'version string';
};

ffi_ok { symbols => [ 'ZSTD_versionString' ] }, with_subtest {
  my $ffi = shift;
  my $get_version = $ffi->function(ZSTD_versionString => [] => 'string');
  is $get_version->call(), Alien::zstd->version, 'version string';
};

done_testing;
