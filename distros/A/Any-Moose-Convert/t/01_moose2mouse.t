#!perl -w

use strict;
use Test::More;
use FindBin qw($Bin);

use Any::Moose::Convert;

use File::Path qw(rmtree);

chdir $Bin or die "Cannot chdir to $Bin: $!";

moose2mouse 'testing_moose';

require_ok 'mouse/testing_moose/MyMouseA.pm';

isa_ok(MyMouseA->new, 'Mouse::Object');
is(MyMouseA->new->foo, 42);

ok !exists $INC{'Benchmark.pm'};

ok(MyMouseA->my_load("Benchmark"));
ok(!MyMouseA->my_load("Benchmark"));

ok(MyMouseA->is_metaclass(MyMouseA->meta));
ok(!MyMouseA->is_metaclass(MyMouseA->new));

isa_ok(MyMouseA->get_metaclass('MyMouseA'),
    'Mouse::Meta::Class');

ok exists $INC{'Benchmark.pm'};

ok !exists $INC{'Moose.pm'}, 'Moose is not loaded';

rmtree 'mouse';

done_testing;
