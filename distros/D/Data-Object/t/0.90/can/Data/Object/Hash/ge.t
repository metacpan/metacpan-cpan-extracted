use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  # given $hash

  $hash->ge; # exception thrown

=description

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=signature

ge(Any $arg1) : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

ok !eval { $data->ge() };

ok 1 and done_testing;
