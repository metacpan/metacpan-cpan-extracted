use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new();
my $of = $array->of(qw/one two three four/);

is($of->length, 4);

done_testing;
