use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

ok($array->push('five'));
is($array->length, 5);

done_testing;
