use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
my $first = $array->find(sub { $_[0] eq 'ten' });
is($first, undef);
my $second = $array->find(sub { return $_[0] eq 'one' });
is($second, 'one');
done_testing;
