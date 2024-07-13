use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

$array = $array->copyWithin(0, 2, 4);

is($array->[0], 'three');
is($array->[1], 'four');
is($array->length, 4);

my $array = Data::LnArray::XS->new(qw/one two three four/);

$array = $array->copyWithin(0, 2, 3);

is($array->[0], 'three');
is($array->[1], 'two');

my $array = Data::LnArray::XS->new(1, 2, 3, 4, 5);

$array = $array->copyWithin(-2, -3, -1);

is_deeply([@$array], [1, 2, 3, 3, 4]);

my $array = Data::LnArray::XS->new(1, 2, 3, 4, 5);

$array = $array->copyWithin(1, 6, 2);
is_deeply($array, [1,2,3,4,5]);

done_testing;
