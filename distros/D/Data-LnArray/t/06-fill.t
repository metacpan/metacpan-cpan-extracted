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

my $array = Data::LnArray->new(qw/one two three/);

$array = $array->fill('one', -1, -1);

is_deeply($array, [qw/one two one/]);

done_testing;
