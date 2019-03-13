use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Config::Signatures

=abstract

Data-Object Signatures Configuration

=synopsis

  use Data::Object::Config::Signatures;

  fun hello (Str $name) {
    return "Hello $name, how are you?";
  }

=description

Data::Object::Config::Signatures is a subclass of L<Type::Tiny::Signatures> providing
method and function signatures supporting all the type constraints provided by
L<Data::Object::Config::Type>.

=cut

use_ok "Data::Object::Config::Signatures";

ok 1 and done_testing;
