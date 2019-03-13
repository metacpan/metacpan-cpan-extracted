use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

unpack

=usage

  my $unpack = $func->unpack();

=description

Returns a list of positional args from the named args.

=signature

unpack() : (Any)

=type

method

=cut

# TESTING

use_ok 'Data::Object::Func';

my $data = 'Data::Object::Func';

can_ok $data, 'unpack';

ok 1 and done_testing;
