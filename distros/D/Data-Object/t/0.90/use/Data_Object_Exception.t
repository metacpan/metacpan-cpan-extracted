use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Exception

=abstract

Data-Object Exception Class

=synopsis

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  $exception->throw('Something went wrong');

=description

Data::Object::Exception provides functionality for creating, throwing,
catching, and introspecting exception objects.

=cut

use_ok "Data::Object::Exception";

ok 1 and done_testing;
