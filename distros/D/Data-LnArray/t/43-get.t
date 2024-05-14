use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

is($array->get(1), 'two');

done_testing;
