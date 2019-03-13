use 5.014;

use strict;
use warnings;

use Test::More;

=name

do

=abstract

Minimalist Perl Development Framework

=synopsis

  package Cli;

  use do cli;

  has 'user';

  method main(:$args) {
    say "Hello @{[$self->user]}, how are you?";
  }

  method specs(:$args) {
    'user|u=s'
  }

  run Cli;

=description

The "do" module is focused on simplicity and productivity. It encapsulates the
Data-Object framework features, is minimalist, and is designed for scripting.

=cut

use_ok "do";

ok 1 and done_testing;
