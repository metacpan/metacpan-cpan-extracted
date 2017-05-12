package Catalyst::Plugin::Two;

use strict;
use warnings;

sub setup {
  Test::More::ok(1, "Catalyst::Plugin::Two->setup called");

  shift->NEXT::setup(@_);
}

sub plugin_two { __PACKAGE__ };

1;
