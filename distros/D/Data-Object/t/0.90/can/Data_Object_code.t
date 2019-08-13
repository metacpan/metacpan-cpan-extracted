use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

code

=usage

  # given sub { shift + 1 }

  my $object = Data::Object->code(sub { $_[0] + 1 });

=description

The C<code> constructor function returns a L<Data::Object::Code> object for
given argument.

=signature

code(CodeRef $arg) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->code(sub { $_[0] + 1 });

isa_ok $object, 'Data::Object::Code';

ok 1 and done_testing;
