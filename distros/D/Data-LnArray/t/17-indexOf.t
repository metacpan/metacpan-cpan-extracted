use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my $first = $array->indexOf('one');

is($first, 0);


done_testing;
