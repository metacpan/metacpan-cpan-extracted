use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

is($array->set(1, 'kaput')->get(1), 'kaput');

done_testing;
