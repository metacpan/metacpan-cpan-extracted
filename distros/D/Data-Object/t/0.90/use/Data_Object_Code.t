use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Code

=abstract

Data-Object Code Class

=synopsis

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { shift + 1 });

=description

Data::Object::Code provides routines for operating on Perl 5 code
references. Code methods work on code references.

=cut

use_ok "Data::Object::Code";

ok 1 and done_testing;
