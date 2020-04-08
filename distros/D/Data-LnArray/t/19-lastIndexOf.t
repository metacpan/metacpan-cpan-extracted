use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two one three four/);

my $first = $array->lastIndexOf('one');

is($first, 2);

done_testing;
