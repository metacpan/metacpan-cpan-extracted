use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Json

=abstract

Data-Object Json Class

=synopsis

  use Data::Object::Json;

  my $json = Data::Object::Json->new;

  my $data = $json->from($arg);

=description

Data::Object::Json provides methods for reading and writing JSON data.

=cut

use_ok "Data::Object::Json";

ok 1 and done_testing;
