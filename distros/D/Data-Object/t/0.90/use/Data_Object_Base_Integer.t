use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Integer

=abstract

Data-Object Abstract Integer Class

=synopsis

  package My::Integer;

  use parent 'Data::Object::Base::Integer';

  my $integer = My::Integer->new(9);

=description

Data::Object::Base::Integer provides routines for operating on Perl 5 integer
data.

=cut

use_ok "Data::Object::Base::Integer";

ok 1 and done_testing;
