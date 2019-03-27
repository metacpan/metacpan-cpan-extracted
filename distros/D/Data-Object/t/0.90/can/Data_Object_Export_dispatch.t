use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dispatch

=usage

  my $dispatch = dispatch('main');

  # $dispatch->('run') calls main::run

=description

The dispatch function return a Data::Object::Dispatch object which is a handle
that let's you call into other packages.

=signature

dispatch(Str $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'dispatch';

ok 1 and done_testing;
