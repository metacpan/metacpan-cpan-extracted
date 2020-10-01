#!/usr/bin/perl
# 000_platform.t - check for supported platform (Linux only due to cgroups requirement of containers)

use strict;
use warnings;
use Config;

use Test::More tests => 1;                      # last test to print

is($Config{osname}, "linux", "Container::Buildah only runs on Linux due to containers dependency on cgroups");

1;
