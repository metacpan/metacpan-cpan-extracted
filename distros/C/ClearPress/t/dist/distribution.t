# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use lib qw(t/lib);
use Net::LDAP;

our $VERSION = q[477.1.4];

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import(); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
