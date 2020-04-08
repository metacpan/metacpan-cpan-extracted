use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(1, 2, 3, 4);

$array = $array->map(sub { $_[0] + 10 });

is($array->[0], 11);

done_testing;
