use Test::More;

use Data::LnArray;

my $array = Data::LnArray->new(qw/one two three four/);

my $first = $array->sort(sub {
	$a cmp $b
});

is_deeply($first, [qw/
	four
	one
	three
	two
/]);

done_testing;
