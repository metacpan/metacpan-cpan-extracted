use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::List

=abstract

Data-Object List Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::List';

=description

Data::Object::Rule::List provides routines for operating on Perl 5 data
objects which meet the criteria for being considered lists.

=cut

use_ok "Data::Object::Rule::List";

ok 1 and done_testing;
