# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
use Test::More;
use strict;
use warnings;

our $VERSION = q[477.1.2];

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

use lib qw(t/lib);# for Net::LDAP

all_pod_coverage_ok();
