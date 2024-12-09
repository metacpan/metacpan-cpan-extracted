#!perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2024 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use strict;
use warnings;
use Test::More;

foreach my $env_skip ( qw(
  SKIP_POD_LINKCHECK
) ){
  plan skip_all => "\$ENV{$env_skip} is set, skipping"
    if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
if ( $@ ) {
  plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
}
else {
  Test::Pod::LinkCheck->new->all_pod_ok;
}
