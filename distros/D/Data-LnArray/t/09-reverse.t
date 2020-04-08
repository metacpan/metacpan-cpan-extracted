use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my @array = $array->reverse->retrieve;

is($array[3], 'one');
is($array[2], 'two');
is($array[1], 'three');
is($array[0], 'four');

done_testing;
