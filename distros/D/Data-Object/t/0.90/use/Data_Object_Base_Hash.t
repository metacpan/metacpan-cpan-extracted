use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Hash

=abstract

Data-Object Abstract Hash Class

=synopsis

  package My::Hash;

  use parent 'Data::Object::Base::Hash';

  my $hash = My::Hash->new({1..4});

=description

Data::Object::Base::Hash provides routines for operating on Perl 5 hash
references.

=cut

use_ok "Data::Object::Base::Hash";

ok 1 and done_testing;
