use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Config

=abstract

Data-Object Package Configuration

=synopsis

  use Data::Object::Config;

=description

Data::Object::Config is used to configure the consuming package based on
arguments passed to the import statement.

=cut

use_ok "Data::Object::Config";

ok 1 and done_testing;
