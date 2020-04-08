use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my %first = $array->entries;

is($first{0}, 'one');


done_testing;
