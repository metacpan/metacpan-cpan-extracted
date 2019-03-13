use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

list

=usage

  =pod help

  Example content

  =cut

  # given $data

  $data->list('pod');

  # [,...]

=description

The list method returns metadata for each pod-like section that matches the
given string.

=signature

list(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'list';

ok 1 and done_testing;
