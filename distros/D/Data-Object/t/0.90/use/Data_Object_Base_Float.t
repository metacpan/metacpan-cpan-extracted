use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Float

=abstract

Data-Object Abstract Float Class

=synopsis

  package My::Float;

  use parent 'Data::Object::Base::Float';

  my $float = My::Float->new(9.9999);

=description

Data::Object::Base::Float provides routines for operating on Perl 5
floating-point data.

=cut

use_ok "Data::Object::Base::Float";

ok 1 and done_testing;
