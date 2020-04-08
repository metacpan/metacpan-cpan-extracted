use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my $second = Data::LnArray->new(1, 2, 3, 4);
ok($array->concat($second));
is($array->length, 8);

done_testing;
