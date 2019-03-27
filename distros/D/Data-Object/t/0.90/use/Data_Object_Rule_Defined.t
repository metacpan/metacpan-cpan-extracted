use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::Defined

=abstract

Data-Object Defined Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::Defined';

=description

Data::Object::Rule::Defined provides routines for operating on Perl 5
data objects which meet the criteria for being defined.

=cut

use_ok "Data::Object::Rule::Defined";

ok 1 and done_testing;
