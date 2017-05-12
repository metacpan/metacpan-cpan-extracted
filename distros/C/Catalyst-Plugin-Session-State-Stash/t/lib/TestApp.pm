package TestApp;
use strict;
use warnings;

use base qw/Catalyst/;

use Catalyst qw/
  Session
  Session::Store::Dummy
  Session::State::Stash
  /;

__PACKAGE__->setup;

1;
