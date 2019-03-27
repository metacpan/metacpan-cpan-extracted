use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Dumper

=abstract

Data-Object Dumper Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Dumper';

=description

Data::Object::Role::Dumper provides routines for operating on Perl 5 data
objects which meet the criteria for being dumpable.

=cut

use_ok "Data::Object::Role::Dumper";

ok 1 and done_testing;
