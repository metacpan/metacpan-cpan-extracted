use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

meth_settings

=usage

  my $meth_settings = meth_settings();

=description

The meth_settings function returns the method-keyword configuration.

=signature

meth_settings(Str $arg1, Object $arg2) : (Str, HashRef)

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Signatures';

my $data = 'Data::Object::Config::Signatures';

can_ok $data, 'meth_settings';

ok 1 and done_testing;
