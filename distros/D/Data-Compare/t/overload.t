use strict;
use warnings;
use lib 't/lib';
use SpecialClass;

use Data::Compare;
use Test::More tests=>2;

ok(!Compare(SpecialClass->new(str=>'bar'),
            SpecialClass->new(str=>'bar',num=>15)),
   'String overload does not fool it');

ok(!Compare(SpecialClass->new(str=>'bar',num=>15),
            SpecialClass->new(str=>'boo',num=>15)),
   'Numeric overload does not fool it');
