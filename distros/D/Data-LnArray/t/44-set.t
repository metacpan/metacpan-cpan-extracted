use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

is($array->set(1, 'kaput')->get(1), 'kaput');

done_testing;
