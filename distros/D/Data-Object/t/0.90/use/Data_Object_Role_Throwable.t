use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Throwable

=abstract

Data-Object Throwable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Throwable';

=description

Data::Object::Role::Throwable provides routines for operating on Perl 5
data objects which meet the criteria for being throwable.

=cut

use_ok "Data::Object::Role::Throwable";

ok 1 and done_testing;
