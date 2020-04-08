use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my $i = 1;
my %hash = $array->forEach(sub {
	return ($_ => $i++);
});

is_deeply(\%hash, {
	one => 1,
	two => 2,
	three => 3,
	four => 4
});

done_testing;
