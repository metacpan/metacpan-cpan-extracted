use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_path

=usage

  # given $filepath

  my $path = data_path($filepath);

=description

The data_path function returns a L<Data::Object::Path> object for the given
path.

=signature

data_path(Any @args) : Any

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok 'Data::Object::Export', 'data_path';

ok 1 and done_testing;