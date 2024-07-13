use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two one three four/);

my $first = $array->lastIndexOf('one');

is($first, 2);

done_testing;
