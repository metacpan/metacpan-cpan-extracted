use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

defined

=usage

  # given $string

  $string->defined; # 1

=description

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
number object.

=signature

defined() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::String';

my $data = Data::Object::String->new('hello world');

is_deeply $data->defined(), 1;

ok 1 and done_testing;
