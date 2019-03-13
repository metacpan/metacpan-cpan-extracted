use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hex

=usage

  # given '0xaf'

  string->hex; # 175

=description

The hex method returns the value resulting from interpreting the string as a
hex string. This method returns a data type object to be determined after
execution.

=signature

hex() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('0xaf');

is_deeply $data->hex(), 175;

ok 1 and done_testing;
