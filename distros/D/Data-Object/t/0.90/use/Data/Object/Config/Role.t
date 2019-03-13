use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Config::Role

=abstract

Data-Object Role Configuration

=synopsis

  package Pointable;

  use Data::Object::Role;
  use Data::Object::Config::Role;

  has 'x';
  has 'y';

  1;

=description

Data::Object::Config::Role modifies the consuming package with behaviors
useful in defining roles. Specifically, this package wraps the C<has>
attribute keyword functions and adds enhancements which as documented in
L<Data::Object::Role>.

=cut

use_ok "Data::Object::Config::Role";

ok 1 and done_testing;
