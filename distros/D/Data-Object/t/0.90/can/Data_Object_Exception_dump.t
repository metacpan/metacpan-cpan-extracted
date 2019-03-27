use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  my $dump = $exception->dump();

=description

The dump method returns a string representation of the underlying data.

=signature

dump() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Exception';

my $data = 'Data::Object::Exception';

can_ok $data, 'dump';

ok 1 and done_testing;
