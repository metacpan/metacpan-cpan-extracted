use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

$array = $array->copyWithin(0, 2);

is($array->[0], 'three');
is($array->[1], 'four');
is($array->length, 4);

my $array = Data::LnArray->new(qw/one two three four/);

$array = $array->copyWithin(0, 2, 3);

is($array->[0], 'three');
is($array->[1], 'two');

my $array = Data::LnArray->new(1, 2, 3, 4, 5);

$array = $array->copyWithin(-2, -3, -1);

is_deeply([@$array], [1, 2, 3, 3, 4]);



done_testing;
