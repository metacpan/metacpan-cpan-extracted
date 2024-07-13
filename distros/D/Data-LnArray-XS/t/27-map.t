use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(1, 2, 3, 4);

$array = $array->map(sub { $_[0] + 10 });

is($array->[0], 11);

$array = $array->map(sub { 'test', $_[0] });

is($array->[0], 'test');

done_testing;
