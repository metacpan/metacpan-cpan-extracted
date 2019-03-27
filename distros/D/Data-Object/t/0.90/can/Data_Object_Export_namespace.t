use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

namespace

=usage

  # given Types::Standard

  namespace('App', 'Types::Standard');

=description

The namespace function registers a type library with a namespace in the
registry so that typed operations know where to look for type context-specific
constraints.

=signature

namespace(ClassName $arg1, ClassName $arg2) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'namespace';

ok 1 and done_testing;
