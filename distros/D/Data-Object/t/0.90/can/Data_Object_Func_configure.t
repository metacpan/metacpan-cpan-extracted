use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

configure

=usage

  my $configure = $func->configure();

=description

Converts positional args to named args.

=signature

configure(ClassName $arg1, Any @args) : HashRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Func';

my $data = 'Data::Object::Func';

can_ok $data, 'configure';

ok 1 and done_testing;
