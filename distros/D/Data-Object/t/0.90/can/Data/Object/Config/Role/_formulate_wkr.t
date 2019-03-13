use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_wkr

=usage

  my $_formulate_wkr = $self->_formulate_wkr();

=description

The _formulate_wkr function returns settings for the weak_ref directive.

=signature

_formulate_wkr(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Role';

my $data = 'Data::Object::Config::Role';

can_ok $data, '_formulate_wkr';

ok 1 and done_testing;
