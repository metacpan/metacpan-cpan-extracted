use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Regexp

=abstract

Data-Object Regexp Class

=synopsis

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

=description

Data::Object::Regexp provides routines for operating on Perl 5 regular
expressions. Data::Object::Regexp methods work on data that meets the criteria
for being a regular expression.

=cut

use_ok "Data::Object::Regexp";

ok 1 and done_testing;
