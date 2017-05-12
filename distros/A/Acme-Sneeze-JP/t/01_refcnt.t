use strict;
use Scalar::Util;


package Foo;
use Acme::Sneeze::JP;

my $dest;
sub DESTROY { $dest++ }

package main;
use Test::More tests => 1;

eval {
    my $foo = bless {}, "Foo";
    $foo->sneeze;
};

ok !$dest;
