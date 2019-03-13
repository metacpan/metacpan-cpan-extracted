use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  my $defined = $self->defined();

=description

The defined method returns truthy for defined data.

=signature

defined() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

is_deeply $data->defined(), 1;

ok 1 and done_testing;
