use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

$array = $array->fill(0, 2);

is($array->[2], 0);
is($array->[3], 0);
is($array->length, 4);

my $array = Data::LnArray->new(qw/one two three four/);

$array = $array->fill('other', 2, 2);

is($array->[2], 'other');
is($array->[3], 'four');

done_testing;
