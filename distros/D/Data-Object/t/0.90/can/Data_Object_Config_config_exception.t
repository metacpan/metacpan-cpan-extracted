use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config_exception

=usage

  my $plans = config_exception;

=description

The config_exception function returns plans for configuring the package to be a
L<Data::Object::Class> which extends L<Data::Object::Exception>.

=signature

config_exception() : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config_exception';

my $config = Data::Object::Config::config_exception();

is_deeply $config->[0], ['use', 'Data::Object::Class'];
is_deeply $config->[1], ['use', 'Data::Object::ClassHas'];
is_deeply $config->[2], ['call', 'extends', 'Data::Object::Exception'];

ok 1 and done_testing;
