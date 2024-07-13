use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

my $first = $array->shift;

is($first, 'one');
is($array->length, 3);

done_testing;
