use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

my $last = $array->pop;

is($last, 'four');
is($array->length, 3);

done_testing;
