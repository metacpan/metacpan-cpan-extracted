#!/usr/bin/env perl
use Test::More;

use_ok('Acme::Urinal');

my $u = Acme::Urinal->new(8);
isa_ok($u, 'Acme::Urinal');
can_ok($u, qw( new pick_one pick look leave ));

is_deeply([ $u->pick_one ], [ 1, 1, 5 ]);
is_deeply([ $u->pick_one ], [ 3, 3, 5 ]);
is_deeply([ $u->pick_one ], [ 5, 5, 5 ]);
is_deeply([ $u->pick_one ], [ 7, 7, 4 ]);
is_deeply([ $u->pick_one ], [ 2, 2, 2 ]);
is_deeply([ $u->pick_one ], [ 4, 4, 2 ]);
is_deeply([ $u->pick_one ], [ 6, 6, 2 ]);
is_deeply([ $u->pick_one ], [ 0, 0, 1 ]);
is($u->pick_one, undef);

$u->leave(3);
$u->leave(4);
is(scalar $u->pick_one, 4);

$u->leave(2);
$u->leave(1);
is(scalar $u->pick_one, 2);

$u->leave(5);
$u->leave(6);
$u->leave(7);
is_deeply([ $u->pick(6) ], [ 6, 5 ]);
is_deeply([ $u->pick(7) ], [ 7, 1 ]);

is(scalar $u->look(5), 5);
is_deeply([ $u->look(5) ], [ 5, 2 ]);
is_deeply([ $u->look(7) ], [ 7, 0 ]);

eval {
    $u->pick(7);
};
like($@, qr{The resource at index 7 is already in use});

eval {
    $u->leave(1);
};
like($@, qr{The resource at index 1 is not currently in use});

eval {
    Acme::Urinal->new('X');
};
like($@, qr{incorrect argument});

done_testing;
