use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Detract

=abstract

Data-Object Detract Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Detract';

=description

Data::Object::Role::Detract provides routines for operating on Perl 5
data objects which meet the criteria for being detractable.

=cut

use_ok "Data::Object::Role::Detract";

ok 1 and done_testing;
