use Test::More;
use Array::Objectify;

my $array = Array::Objectify->new('abc', { a => 1, b => 2, c => 3 }, [ { a => 1 }, {b => 2}, {c => 3} ]);

is($array->[0], 'abc');
is($array->[1]->a, 1);
is($array->[1]->b, 2);
is($array->[1]->c, 3);
is($array->[2]->[0]->a, 1);
is($array->[2]->[1]->b, 2);
is($array->[2]->[2]->c, 3);
is(scalar @{$array}, 3);
push @{$array}, { d => 1 };
is(scalar @{$array}, 4);
is($array->[3]->d, 1);

done_testing();
