use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::LZ4;

alien_diag 'Alien::LZ4';
alien_ok 'Alien::LZ4';

if(0) { # not building lz4 for now
run_ok([ qw(lz4 --version) ])
  ->success
  ->out_like(qr/LZ4 command line interface/);
}

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "lz4.h"

const char* version(const char* class) {
  return LZ4_versionString();
}

MODULE = main PACKAGE = main

const char* version(class);
  const char *class;

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  is $module->version, Alien::LZ4->version, 'version string';
};

ffi_ok { symbols => [ 'LZ4_versionString' ] }, with_subtest {
  my $ffi = shift;
  my $get_version = $ffi->function(LZ4_versionString => [] => 'string');
  is $get_version->call(), Alien::LZ4->version, 'version string';
};

done_testing;
