#!perl -w

use strict;
use Test::More;
use FindBin qw($Bin);

use File::Path qw(rmtree);

use Any::Moose::Convert;

chdir $Bin or die "Cannot chdir to $Bin: $!";

mouse2moose 'testing_mouse';

require_ok 'moose/testing_mouse/MyMooseB.pm';

isa_ok(MyMooseB->new, 'Moose::Object');
is(MyMooseB->new->foo, 42);

ok !exists $INC{'Benchmark.pm'};

ok(MyMooseB->my_load("Benchmark"));
ok(!MyMooseB->my_load("Benchmark"));

ok(MyMooseB->is_metaclass(MyMooseB->meta));
ok(!MyMooseB->is_metaclass(MyMooseB->new));

isa_ok(MyMooseB->get_metaclass('MyMooseB'),
    'Moose::Meta::Class');

ok exists $INC{'Benchmark.pm'};

ok !exists $INC{'Mouse.pm'}, 'Moose is not loaded';

rmtree 'moose';

done_testing;
