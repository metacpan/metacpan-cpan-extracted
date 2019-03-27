use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

load

=usage

  # given 'List::Util';

  $package = load 'List::Util'; # List::Util if loaded

=description

The load function attempts to dynamically load a module and either dies or
returns the package name of the loaded module.

=signature

load(Str $arg1) : ClassName

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'load';

ok 1 and done_testing;
