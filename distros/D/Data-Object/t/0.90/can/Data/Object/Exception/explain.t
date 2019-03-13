use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

explain

=usage

  my $explain = $exception->explain();

=description

Returns a complete stack trace if the exception was thrown.

=signature

explain() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Exception';

my $data = 'Data::Object::Exception';

can_ok $data, 'explain';

ok 1 and done_testing;
