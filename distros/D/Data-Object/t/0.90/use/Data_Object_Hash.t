use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash

=abstract

Data-Object Hash Class

=synopsis

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=description

Data::Object::Hash provides routines for operating on Perl 5 hash
references. Hash methods work on hash references. Users of these methods should
be aware of the methods that modify the array reference itself as opposed to
returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new hash references based on their
function.

=cut

use_ok "Data::Object::Hash";

ok 1 and done_testing;
