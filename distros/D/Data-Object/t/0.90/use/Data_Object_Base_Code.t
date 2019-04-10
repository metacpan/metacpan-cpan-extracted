use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Code

=abstract

Data-Object Abstract Code Class

=synopsis

  package My::Code;

  use parent 'Data::Object::Base::Code';

  my $code = My::Code->new(sub { shift + 1 });

=description

Data::Object::Base::Code provides routines for operating on Perl 5 code
references.

=cut

use_ok "Data::Object::Base::Code";

ok 1 and done_testing;
