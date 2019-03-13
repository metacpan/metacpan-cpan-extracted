use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  my $ge = $self->ge();

=description

The ge method returns truthy if argument is greater or equal to the object data.

=signature

ge(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->ge() };

ok 1 and done_testing;
