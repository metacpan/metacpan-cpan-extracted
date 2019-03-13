use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

config

=usage

  my $plans = config;

=description

The config function returns plans for configuring a package with the standard
L<Data::Object> setup.

=signature

config(ArrayRef $arg1) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'config';

my $config = Data::Object::Config::config();

is_deeply $config->[0], ['use', 'strict'];
is_deeply $config->[1], ['use', 'warnings'];
is_deeply $config->[2], ['use', 'feature', 'say'];
is_deeply $config->[3], ['use', 'feature', 'state'];
is_deeply $config->[4], ['use', 'Data::Object::Config::Library'];
is_deeply $config->[5], ['use', 'Data::Object::Config::Signatures'];
is_deeply $config->[6], ['use', 'Data::Object::Export'];

ok 1 and done_testing;

