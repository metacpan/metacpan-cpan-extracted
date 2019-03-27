use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String

=abstract

Data-Object String Class

=synopsis

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=description

Data::Object::String provides routines for operating on Perl 5 string
data. String methods work on data that meets the criteria for being a string. A
string holds and manipulates an arbitrary sequence of bytes, typically
representing characters. Users of strings should be aware of the methods that
modify the string itself as opposed to returning a new string. Unless stated, it
may be safe to assume that the following methods copy, modify and return new
strings based on their function.

=cut

use_ok "Data::Object::String";

ok 1 and done_testing;
