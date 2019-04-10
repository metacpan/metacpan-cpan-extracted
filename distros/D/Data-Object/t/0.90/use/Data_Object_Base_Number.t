use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Number

=abstract

Data-Object Abstract Number Class

=synopsis

  package My::Number;

  use parent 'Data::Object::Base::Number';

  my $number = My::Number->new(1_000_000);

=description

Data::Object::Base::Number provides routines for operating on Perl 5 numeric
data.

=cut

use_ok "Data::Object::Base::Number";

ok 1 and done_testing;
