use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new( [qw/1 2 3/], { a => "b" }, qw/one two three four/);

my $first = $array->includes('one');

is($$first, 1);

my $second = $array->includes('five');
is($$second, 0);

done_testing;
