use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my $first = $array->shift;

is($first, 'one');
is($array->length, 3);

done_testing;
