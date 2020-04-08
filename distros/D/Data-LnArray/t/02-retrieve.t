use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my @array = $array->retrieve;

is($array[0], 'one');
is($array[1], 'two');
is($array[2], 'three');
is($array[3], 'four');

done_testing;
