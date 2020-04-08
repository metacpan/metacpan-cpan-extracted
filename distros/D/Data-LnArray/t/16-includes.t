use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my $first = $array->includes('one');

is($$first, 1);

done_testing;
