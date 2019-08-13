use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exception

=usage

  # given { message => 'Oops' }

  my $object = Data::Object->exception({ message => 'Oops' });

=description

The C<exception> constructor function returns a L<Data::Object::Exception>
object for given argument.

=signature

exception(HashRef $arg) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->exception({ message => 'Oops' });

isa_ok $object, 'Data::Object::Exception';

ok 1 and done_testing;
