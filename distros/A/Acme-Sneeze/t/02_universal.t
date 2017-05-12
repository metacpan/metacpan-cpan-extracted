use strict;

package Foo;
sub new { bless {}, shift }

package Bar;

no warnings 'once';
require Acme::Sneeze;
*UNIVERSAL::sneeze = \&Acme::Sneeze::sneeze;

use Test::More 'no_plan';

my $foo = Foo->new;
isa_ok $foo, 'Foo';

$foo->sneeze;
isa_ok $foo, 'Bar';
