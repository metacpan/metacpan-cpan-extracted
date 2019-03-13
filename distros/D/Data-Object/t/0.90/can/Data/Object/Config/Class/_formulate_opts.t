use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

_formulate_opts

=usage

  my $_formulate_opts = $self->_formulate_opts();

=description

The _formulate_opts function returns settings for the required directive.

=signature

_formulate_opt(HashRef $arg1, Str $arg2, Any $arg3) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Class';

my $data = 'Data::Object::Config::Class';

can_ok $data, '_formulate_opts';

ok 1 and done_testing;
