use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

my $first = $array->indexOf('one');

is($first, 0);

my $third = $array->indexOf('three');

is($third, 2);

my $nope = $array->indexOf('five');

is($nope, -1);


done_testing;
