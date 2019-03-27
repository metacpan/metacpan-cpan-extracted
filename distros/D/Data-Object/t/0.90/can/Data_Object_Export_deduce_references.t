use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce_references

=usage

  # given $data

  deduce_references($data);

=description

The deduce_references function returns a Data::Object object based on the type
of argument reference provided.

=signature

deduce_references(Any $arg1) : Int

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'deduce_references';

ok 1 and done_testing;
