use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Number

=abstract

Data-Object Number Class

=synopsis

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=description

Data::Object::Number provides routines for operating on Perl 5 numeric
data. Number methods work on data that meets the criteria for being a number. A
number holds and manipulates an arbitrary sequence of bytes, typically
representing numberic characters (0-9). Users of numbers should be aware of the
methods that modify the number itself as opposed to returning a new number.
Unless stated, it may be safe to assume that the following methods copy, modify
and return new numbers based on their function.

=cut

use_ok "Data::Object::Number";

ok 1 and done_testing;
