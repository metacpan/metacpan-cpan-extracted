use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Array

=abstract

Data-Object Array Class

=synopsis

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=description

Data::Object::Array provides routines for operating on Perl 5 array
references. Array methods work on array references. Users of these methods
should be aware of the methods that modify the array reference itself as opposed
to returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new array references based on
their function.

=cut

use_ok "Data::Object::Array";

ok 1 and done_testing;
