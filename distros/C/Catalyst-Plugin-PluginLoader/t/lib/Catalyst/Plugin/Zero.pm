package Catalyst::Plugin::Zero;

use strict;
use warnings;

sub setup {
  Test::More::ok(1, "Catalyst::Plugin::Zero->setup called");

  shift->next::method(@_);
}

sub plugin_zero { __PACKAGE__ };

1;
