use Test::More;

use Data::LnArray::XS;


my $array = Data::LnArray::XS->new(qw/one two three four/);

my $first = $array->sort(sub {
	$a cmp $b
});

is_deeply($first, [qw/
	four
	one
	three
	two
/]);

$array = Data::LnArray::XS->new(qw/one two three four/);

$first = $array->sort(sub {
	$b cmp $a
});

is_deeply($first, [qw/
	two
	three
	one
	four
/]);

done_testing;
