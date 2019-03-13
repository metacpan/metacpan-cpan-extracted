use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each

=usage

  # given {1..8}

  $hash->each(sub{
      my $key   = shift; # 1
      my $value = shift; # 2
  });

=description

The each method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key and value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Hash> object.

=signature

each(CodeRef $arg1, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

is_deeply $data->each(sub { [@_] }), $data;

ok 1 and done_testing;
