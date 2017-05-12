package Catalyst::Plugin::Three;

use strict;
use warnings;

sub setup {
  Test::More::ok(1, "Catalyst::Plugin::Three->setup called");

  shift->next::method(@_);
}

sub plugin_three { __PACKAGE__ };

1;
