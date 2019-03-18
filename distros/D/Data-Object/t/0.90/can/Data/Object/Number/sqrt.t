use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

sqrt

=usage

  # given 12345

  $number->sqrt; # 111.108055513541

=description

The sqrt method returns the positive square root of the number. This method
returns a data type object to be determined after execution.

=signature

sqrt(Int $arg1) : IntObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12345);

like $data->sqrt(), qr/111.10805/;

ok 1 and done_testing;
