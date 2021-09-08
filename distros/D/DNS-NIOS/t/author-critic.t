#!perl
#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#

BEGIN {
  unless ( $ENV{AUTHOR_TESTING} ) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit;
  }
}

use strict;
use warnings;

use Test::Perl::Critic ( -profile => "xt/perlcritic.rc" ) x
  !!-e "xt/perlcritic.rc";
all_critic_ok();
