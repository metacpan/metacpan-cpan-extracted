use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

contents

=usage

  =pod help

  Example content

  =cut

  # given $data

  $data->contents('pod');

  # [,...]

=description

The contents method returns all pod-like sections that start with the given
string, e.g. C<pod> matches C<=pod foo>. This method returns an arrayref of
data for the matched sections.

=signature

contents(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'contents';

ok 1 and done_testing;
