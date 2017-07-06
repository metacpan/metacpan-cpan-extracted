#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Requires {
    Moose => 0,
};

use Class::Inspector;
use Class::Unload;

use lib 't/lib';
use MooseClass;

ok( Class::Inspector->loaded('MooseClass'), 'MooseClass loaded');
ok( Class::MOP::does_metaclass_exist('MooseClass'), 'MooseClass metaclass exists');

Class::Unload->unload('MooseClass');

ok( ! Class::Inspector->loaded('MooseClass'), 'MooseClass unloaded');
ok( ! Class::MOP::does_metaclass_exist('MooseClass'), 'MooseClass metaclass removed');

done_testing;
