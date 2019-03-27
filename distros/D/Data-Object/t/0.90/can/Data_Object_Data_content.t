use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

content

=usage

  =pod help

  Example content

  =cut

  # given $data

  $data->content('help');

  # Example content

=description

The content method returns the pod-like section where the name matches the
given string.

=signature

content(Str $arg1) : Str

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'content';

ok 1 and done_testing;
