use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new();
my $of = $array->of(qw/one two three four/);

is($of->length, 4);

done_testing;
