use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my $first = $array->findIndex(sub { $_[0] eq 'ten' });
is($first, undef);
my $second = $array->findIndex(sub { return $_[0] eq 'one' });
is($second, 0);

done_testing;
