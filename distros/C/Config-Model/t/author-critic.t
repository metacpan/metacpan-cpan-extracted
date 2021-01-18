#!perl
#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

use Test::Perl::Critic (-profile => "perlcritic.rc") x!! -e "perlcritic.rc";
all_critic_ok();
