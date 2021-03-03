use strict;
use warnings;

use Boundary::Types -types;
use Foo;

my $type = ImplOf['IFoo'];
my $foo = Foo->new;
$type->check($foo);
