# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
use Test::More;
use strict;
use warnings;

our $VERSION = q[477.1.4];

eval {
  require Test::Pod;
  Test::Pod->import();
};
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

