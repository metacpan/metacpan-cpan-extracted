use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base

=abstract

Data-Object Base Class

=synopsis

  use parent 'Data::Object::Base';

=description

Data::Object::Base is an abstract base class that mostly provides identity and
classification for L<Data::Object> classes, and common routines for operating
on any type of Data-Object object.

=cut

use_ok "Data::Object::Base";

ok 1 and done_testing;
