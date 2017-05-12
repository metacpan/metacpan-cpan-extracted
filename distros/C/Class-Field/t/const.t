use strict;
use lib (-e 't' ? 't' : 'test'), 'inc';

use Test::More tests => 4;

package Foo;
use base 'TestFieldBase';
use Class::Field 'const';

const 'this' => 'Charming Man';

package main;

ok defined(&Foo::const),
    'const is exported';

ok not(defined &Foo::field),
    'field is not exported';

my $foo = Foo->new;

is $foo->this, 'Charming Man',
    'const returns value';

$foo->this('is your life');

is $foo->this, 'Charming Man',
    'const remains constant';
