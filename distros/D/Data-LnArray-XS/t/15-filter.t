use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);

my $first = $array->filter(sub {
	$_[0] ne 'one'
});

is_deeply($first, [qw/
	two
	three
	four
/]);

done_testing;
