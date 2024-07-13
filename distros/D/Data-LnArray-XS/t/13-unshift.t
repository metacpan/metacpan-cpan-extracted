use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
ok($array->unshift('five'));

is($array->length, 5);

done_testing;
