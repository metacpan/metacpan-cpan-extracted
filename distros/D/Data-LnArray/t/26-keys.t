use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my @in = $array->keys();
is_deeply(\@in, [0, 1, 2, 3]);

done_testing;
