use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_tgr

=usage

  my $_formulate_tgr = $self->_formulate_tgr();

=description

The _formulate_tgr function returns settings for the trigger directive.

=signature

_formulate_tgr(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Role';

my $data = 'Data::Object::Config::Role';

can_ok $data, '_formulate_tgr';

ok 1 and done_testing;
