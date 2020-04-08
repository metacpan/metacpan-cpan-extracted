use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

is($array->length, 4);

done_testing;
