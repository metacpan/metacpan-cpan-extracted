use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Dispatch

=abstract

Data-Object Dispatch Class

=synopsis

  use Data::Object::Dispatch;

  my $dispatch = Data::Object::Dispatch->new($package);

  $dispatch->call(@args);

=description

Data::Object::Dispatch creates dispatcher objects. A dispatcher is a closure
object which when called execute subroutines in a package, and can be curried.

=cut

# TESTING

use_ok 'Data::Object::Dispatch';

ok 1 and done_testing;
