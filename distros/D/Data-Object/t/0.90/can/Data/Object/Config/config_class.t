use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_class

=usage

  my $plans = config_class;

=description

The config_class function returns plans for configuring the package to be a
L<Data::Object::Class>.

=signature

config_class() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_class';

my $config = Data::Object::Config::config_class();

is_deeply $config->[0], ['use', 'Data::Object::Class'];
is_deeply $config->[1], ['use', 'Data::Object::Config::Class', {replace=>1}, 'has'];

ok 1 and done_testing;
