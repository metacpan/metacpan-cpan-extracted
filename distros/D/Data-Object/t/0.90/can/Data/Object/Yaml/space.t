use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

space

=usage

  # given $yaml

  my $space = $yaml->space();

  # YAML::Tiny

=description

The space method returns a L<Data::Object::Space> object for the C<origin>.

=signature

space() : Object

=type

method

=cut

# TESTING

use Data::Object::Yaml;

can_ok 'Data::Object::Yaml', 'space';

ok 1 and done_testing;