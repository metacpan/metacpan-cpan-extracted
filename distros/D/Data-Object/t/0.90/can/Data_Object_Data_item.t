use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

item

=usage

  =pod help

  Example content

  =cut

  # given $data

  $data->item('help');

  # {,...}

=description

The item method returns metadata for the pod-like section that matches the
given string.

=signature

item(Str $arg1) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'item';

ok 1 and done_testing;
