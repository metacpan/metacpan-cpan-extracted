use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my $first = $array->toString(',');

is($first, 'one,two,three,four');

done_testing;
