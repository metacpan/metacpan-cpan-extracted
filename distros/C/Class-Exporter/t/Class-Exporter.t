#!/usr/bin/perl -w

use lib qw(t/lib);
use strict;

# Meanwhile, in another piece of code!
package Bar;
use Test::More tests=>4;
use_ok('Class::Exporter');
use MagicNumber qw(magic_number); # exports magic_number

ok(3==magic_number, 'basic exporting'); # prints 3
magic_number(7);
ok(7==magic_number, 'maintaining state'); # prints 7

# Each package gets its own instance of the object. This ensures that
# two packages both using your module via import semantics don't mess
# with each other.

package Baz;
use Test::More;
use MagicNumber; # exports magic_number
ok(3==magic_number, 'different state across different packages'); # prints 3!
