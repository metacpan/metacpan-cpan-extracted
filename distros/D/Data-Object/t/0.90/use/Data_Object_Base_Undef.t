use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Undef

=abstract

Data-Object Abstract Undef Class

=synopsis

  package My::Undef;

  use parent 'Data::Object::Base::Undef';

  my $undef = My::Undef->new(undef);

=description

Data::Object::Base::Undef provides routines for operating on Perl 5 undefined
data.

=cut

use_ok "Data::Object::Base::Undef";

ok 1 and done_testing;
