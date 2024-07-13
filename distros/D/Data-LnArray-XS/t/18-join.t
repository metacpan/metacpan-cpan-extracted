use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my $first = $array->join(',');

is($first, 'one,two,three,four');

$array = Data::LnArray::XS->new(1, 2, 3, 4);

$first = $array->join(',');
is($first, '1,2,3,4');

done_testing;
