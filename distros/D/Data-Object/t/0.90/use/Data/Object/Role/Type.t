use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Type

=abstract

Data-Object Type Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Type';

=description

Data::Object::Role::Type provides routines for operating on Perl 5 data
objects which meet the criteria for being considered type objects.

=cut

use_ok "Data::Object::Role::Type";

ok 1 and done_testing;
