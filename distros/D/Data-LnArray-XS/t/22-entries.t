use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my %first = $array->entries;

is($first{0}, 'one');

done_testing;
