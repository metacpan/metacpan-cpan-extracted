use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Integer

=abstract

Data-Object Integer Class

=synopsis

  use Data::Object::Integer;

  my $integer = Data::Object::Integer->new(9);

=description

Data::Object::Integer provides routines for operating on Perl 5 integer
data. Integer methods work on data that meets the criteria for being an integer.
An integer holds and manipulates an arbitrary sequence of bytes, typically
representing numeric characters. Users of integers should be aware of the
methods that modify the integer itself as opposed to returning a new integer.
Unless stated, it may be safe to assume that the following methods copy, modify
and return new integers based on their function.

=cut

use_ok "Data::Object::Integer";

ok 1 and done_testing;
