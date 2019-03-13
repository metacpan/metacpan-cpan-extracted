use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

prepare_call

=usage

  prepare_call($function, @args);

=description

The prepare_call function returns a call-plan for the arguments passed.

=signature

prepare_call(Str $arg1, Any @args) : ArrayRef

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config';

my $data = 'Data::Object::Config';

can_ok $data, 'prepare_call';

is_deeply Data::Object::Config::prepare_call(), ['call', undef];
is_deeply Data::Object::Config::prepare_call('with'), ['call', 'with'];
is_deeply Data::Object::Config::prepare_call('with', 'all'), ['call', 'with', 'all'];

ok 1 and done_testing;
