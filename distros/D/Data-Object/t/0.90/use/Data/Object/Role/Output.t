use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Output

=abstract

Data-Object Output Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Output';

=description

Data::Object::Role::Output provides routines for operating on Perl 5 data
objects which meet the criteria for being outputable.

=cut

use_ok "Data::Object::Role::Output";

ok 1 and done_testing;
