use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my $first = $array->every(sub { $_[0] ne 'ten' });
is($$first, 1);
my $second = $array->every(sub { return $_[0] eq 'one' });
is($$second, 0);

done_testing;
