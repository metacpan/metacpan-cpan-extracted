use Test2::Bundle::Extended;
use Test::Alien;
use Alien::xz;

alien_ok 'Alien::xz';

xs_ok do { local $/; <DATA> }, with_subtest {
  my $version = lzma::lzma_version_string();
  ok $version;
  note "version = $version";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <lzma.h>

MODULE = lzma PACKAGE = lzma

const char *
lzma_version_string()
