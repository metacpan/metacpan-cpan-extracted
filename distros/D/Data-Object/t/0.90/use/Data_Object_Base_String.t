use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::String

=abstract

Data-Object Abstract String Class

=synopsis

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

=description

Data::Object::Base::String provides routines for operating on Perl 5 string
data.

=cut

use_ok "Data::Object::Base::String";

ok 1 and done_testing;
