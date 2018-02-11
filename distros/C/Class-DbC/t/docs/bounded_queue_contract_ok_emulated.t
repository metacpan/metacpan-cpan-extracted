use strict;
use warnings;
use Test::Lib;
use Test::More;
use Example::Contract::BoundedQueue;

my $governed = 'Example::BoundedQueue';
eval "require $governed";

my $emulation = Example::Contract::BoundedQueue::->govern($governed, { emulate => 1 });
isnt $emulation, $governed;
# use MOP::Class;
# use Data::Dump 'pp'; 
# warn pp( MOP::Class->new($emulation)->mro );
isa_ok $emulation, $governed;

my $q = $emulation->new(3);

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
