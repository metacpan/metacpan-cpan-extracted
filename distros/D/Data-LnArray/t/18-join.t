use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my $first = $array->join(',');

is($first, 'one,two,three,four');

done_testing;
