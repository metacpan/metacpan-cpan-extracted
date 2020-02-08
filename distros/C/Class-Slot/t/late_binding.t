BEGIN{ $ENV{CLASS_SLOT_NO_XS} = 1 };

package P1;
use Class::Slot;
use Types::Standard -types;
slot x => Int, rw => 1;
slot y => Int, rw => 1;
1;

package main;
use Test2::V0;
no warnings 'once';

eval q{
package P2;
use Class::Slot;
use Types::Standard -types;
use parent -norequire, 'P1';
slot z => Int, rw => 1;
1;
};

ok my $p = P2->new(x => 10, y => 10, z => 10), 'ctor';
ok $p->isa('P1'), 'isa';
is \@P2::SLOTS, [qw(x y z)], '@SLOTS';

done_testing;
