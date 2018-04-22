package P1;
use Class::Slot;
use Types::Standard -types;
slot x => Int, rw => 1;
slot y => Int, rw => 1;
1;

package P2;
use Class::Slot;
use Types::Standard -types;
use parent -norequire, 'P1';
slot z => Int, rw => 1;
1;

package P3;
use Class::Slot;
use Types::Standard -types;
use parent -norequire, 'P1';
slot x => StrMatch[qr/[13579]$/], rw => 0, req => 1;
slot y => StrMatch[qr/[13579]$/], rw => 1;
slot z => sub{1} & StrMatch[qr/[13579]$/], rw => 1; # ensure non-inlined types work
1;


package main;
use strict;
use warnings;
no warnings 'once';
use Test::More;

is_deeply \@P1::SLOTS, [qw(x y)],   'P1 @SLOTS';
is_deeply \@P2::SLOTS, [qw(x y z)], 'P2 @SLOTS';
is_deeply \@P3::SLOTS, [qw(x y z)], 'P3 @SLOTS';

ok my $p2 = P2->new(x => 10, y => 20, z => 30), 'ctor';
is $p2->x, 10, 'get slot: x';
is $p2->y, 20, 'get slot: y';
is $p2->z, 30, 'get slot: z';
ok $p2->isa('P2'), 'isa P2';
ok $p2->isa('P1'), 'isa P1';
ok do{ local $@; eval{ P2->new(x => 10, y => 20, z => 'foo') }; $@ }, 'ctor: dies on invalid slot type';
ok do{ local $@; eval{ P2->new(x => 'foo', y => 20, z => 30) }; $@ }, 'ctor: dies on invalid parent slot type';

ok(do{ local $@; eval{ P3->new(x => 10, y => 20, z => 30) }; $@ }, 'ctor: dies on stricter child type');

ok(P3->new(x => 'a7', y => '39', z => '0x35'), 'ctor: ok on less strict child type');
ok(do{ local $@; eval{ P3->new(y => '39', z => '0x35') }; $@ }, 'ctor: dies on stricter child req');
ok(do{ my $p = P3->new(x => 'a7', y => '39', z => '0x35'); local $@; eval{ $p->x(45) }; $@ }, 'setter: dies on stricter child rw');

done_testing;
