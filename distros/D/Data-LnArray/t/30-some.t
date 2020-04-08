use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);
my $first = $array->some(sub { $_[0] ne 'ten' });
is($$first, 1);
my $second = $array->some(sub { return $_[0] eq 'ten' });
is($$second, 0);

done_testing;
