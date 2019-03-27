use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

library

=usage

  my $library = $data->library();

=description

The library method returns an instance of the type library instance.

=signature

library() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'library';

ok 1 and done_testing;
