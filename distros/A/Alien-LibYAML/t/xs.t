use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Alien;
use Alien::LibYAML;

alien_ok 'Alien::LibYAML';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
  my $version = YamlTest::yaml_get_version_string();
  ok $version;
  note "version = $version";
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <yaml.h>

MODULE = YamlTest PACKAGE = YamlTest

const char *
yaml_get_version_string()
