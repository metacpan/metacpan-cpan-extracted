use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

self

=usage

  my $self = $code->self();

=description

The self method returns the calling object (noop).

=signature

self() : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub{ time });

ok ref($data->self()) eq 'Data::Object::Code';

ok 1 and done_testing;
