use Test::More;
use Array::Objectify;

my $array = Array::Objectify->new('abc', { a => 1, b => 2, c => 3 }, [ { a => 1 }, {b => 2}, {c => 3} ]);

ok($array->[0] = 'def');
is($array->[0], 'def');
is(shift @{$array}, 'def');
ok(unshift @{$array}, 'def');
is($array->[0], 'def');
ok(push @{$array}, 'xyz');
is(pop @{$array}, 'xyz');



ok(!(undef @{$array}));


done_testing();
