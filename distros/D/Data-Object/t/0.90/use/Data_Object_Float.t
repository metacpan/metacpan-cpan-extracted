use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Float

=abstract

Data-Object Float Class

=synopsis

  use Data::Object::Float;

  my $float = Data::Object::Float->new(9.9999);

=description

Data::Object::Float provides routines for operating on Perl 5
floating-point data. Float methods work on data that meets the criteria for
being a floating-point number. A float holds and manipulates an arbitrary
sequence of bytes, typically representing numberic characters with decimals.
Users of floats should be aware of the methods that modify the float itself as
opposed to returning a new float. Unless stated, it may be safe to assume that
the following methods copy, modify and return new floats based on their
function.

=cut

use_ok "Data::Object::Float";

ok 1 and done_testing;
