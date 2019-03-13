use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_rdr

=usage

  my $_formulate_rdr = $self->_formulate_rdr();

=description

The _formulate_rdr function returns settings for the reader directive.

=signature

_formulate_rdr(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Role';

my $data = 'Data::Object::Config::Role';

can_ok $data, '_formulate_rdr';

ok 1 and done_testing;
