package MyApp::Plugin::One;

use strict;
use warnings;

sub setup {
  Test::More::ok(1, "MyApp::Plugin::One->setup called");

  shift->next::method(@_);
}

sub plugin_one { __PACKAGE__ };

1;
