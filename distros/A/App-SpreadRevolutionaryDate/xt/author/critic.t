#!perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2023 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use strict;
use warnings;

use Test::Perl::Critic (-profile => "perlcritic.rc") x!! -e "perlcritic.rc";
all_critic_ok();
