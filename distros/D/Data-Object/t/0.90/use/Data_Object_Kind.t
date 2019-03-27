use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Kind

=abstract

Data-Object Kind Class

=synopsis

  use parent 'Data::Object::Kind';

=description

Data::Object::Kind is an abstract base class that mostly provides identity and
classification for L<Data::Object> classes, and common routines for operating
on any type of Data-Object object.

=cut

use_ok "Data::Object::Kind";

ok 1 and done_testing;
