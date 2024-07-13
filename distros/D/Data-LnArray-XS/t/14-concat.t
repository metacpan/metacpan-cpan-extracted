use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my $second = Data::LnArray::XS->new(1, 2, 3, 4);
ok($array->concat($second));
is($array->length, 8);

done_testing;
