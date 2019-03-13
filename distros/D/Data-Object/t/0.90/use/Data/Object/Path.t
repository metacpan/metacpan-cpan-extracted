use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Path

=abstract

Data-Object Path Class

=synopsis

  use Data::Object::Path;

  my $path = Data::Object::Path->new('/tmp/test.txt');

  $path->absolute;

=description

Data::Object::Path provides methods for manipulating file paths and
encapsulates the behavior of L<Path::Tiny>.

=cut

use_ok "Data::Object::Path";

ok 1 and done_testing;
