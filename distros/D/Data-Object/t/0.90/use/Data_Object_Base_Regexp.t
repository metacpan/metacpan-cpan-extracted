use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Regexp

=abstract

Data-Object Abstract Regexp Class

=synopsis

  package My::Regexp;

  use parent 'Data::Object::Base::Regexp';

  my $re = My::Regexp->new(qr(\w+));

=description

Data::Object::Base::Regexp provides routines for operating on Perl 5 regular
expressions.

=cut

use_ok "Data::Object::Base::Regexp";

ok 1 and done_testing;
