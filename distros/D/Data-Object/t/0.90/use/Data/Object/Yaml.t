use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Yaml

=abstract

Data-Object Yaml Class

=synopsis

  use Data::Object::Yaml;

  my $yaml = Data::Object::Yaml->new;

  my $data = $yaml->from($arg);

=description

Data::Object::Yaml provides methods for reading and writing YAML data.

=cut

use_ok "Data::Object::Yaml";

ok 1 and done_testing;
