use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_type

=usage

  my $plans = config_type;

=description

The config_type function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Type>.

=signature

config_type() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_type';

my $config = Data::Object::Config::config_type();

is_deeply $config->[0], ['use', 'Data::Object::Class'];
is_deeply $config->[1], ['use', 'Data::Object::ClassHas'];
is_deeply $config->[2], ['call', 'extends', 'Data::Object::Kind'];

ok 1 and done_testing;
