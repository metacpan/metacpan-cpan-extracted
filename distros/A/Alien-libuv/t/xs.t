use Test2::V0;
use Test::Alien;
use Alien::libuv;

alien_ok 'Alien::libuv';
xs_ok do { local $/; <DATA> }, with_subtest {
  my $version = UVTest::uv_version_string();
  ok $version, 'version returns okay';
  note "version=$version";
};

done_testing;

__END__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <uv.h>

MODULE = UVTest PACKAGE = UVTest

const char *
uv_version_string()


