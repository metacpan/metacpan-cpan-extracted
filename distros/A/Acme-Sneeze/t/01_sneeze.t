use strict;

package Foo;
use Acme::Sneeze;
sub new { bless {}, shift }

package Bar;

use Test::More 'no_plan';

my $foo = Foo->new;
isa_ok $foo, 'Foo';

$foo->sneeze;
isa_ok $foo, 'Bar';
