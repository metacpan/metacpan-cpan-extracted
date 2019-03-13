use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

space

=usage

  # given $json

  my $space = $json->space();

  # JSON::Tiny

=description

The space method returns a L<Data::Object::Space> object for the C<origin>.

=signature

space() : Object

=type

method

=cut

# TESTING

use Data::Object::Json;

can_ok 'Data::Object::Json', 'space';

ok 1 and done_testing;