use Test2::V0;
use Test::Alien;
use Alien::Sodium;

alien_ok 'Alien::Sodium';
my $xs = {xs => do { local $/; <DATA> },};

xs_ok $xs, with_subtest {
  my $version = SodiumTest::sodium_version_string();
  ok $version, 'version returns okay';
  note "version=$version";
};

done_testing;

__END__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sodium.h>

MODULE = SodiumTest PACKAGE = SodiumTest

const char *
sodium_version_string()
