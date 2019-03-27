use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::Comparison

=abstract

Data-Object Comparison Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::Comparison';

=description

Data::Object::Rule::Comparison provides routines for operating on Perl 5 data
objects which meet the criteria for being comparable.

=cut

use_ok "Data::Object::Rule::Comparison";

ok 1 and done_testing;
