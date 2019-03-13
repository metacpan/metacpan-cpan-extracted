use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Config::Class

=abstract

Data-Object Class Configuration

=synopsis

  package Point;

  use Data::Object::Class;
  use Data::Object::Config::Class;

  has 'x';
  has 'y';

  1;

=description

Data::Object::Config::Class modifies the consuming package with behaviors
useful in defining classes. Specifically, this package wraps the C<has>
attribute keyword functions and adds enhancements which as documented in
L<Data::Object::Class>.

=cut

use_ok "Data::Object::Config::Class";

ok 1 and done_testing;
