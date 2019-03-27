use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parent

=usage

  my $parent = $data->parent();

=description

The parent method represents the type expression (or parent type) that its type
should derive from.

=signature

parent() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'parent';

ok 1 and done_testing;
