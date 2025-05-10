use Const::XS qw/all/;
use Test::More;

eval {
	const my %broke => ( 'a' => 1, 'b' );
};

like($@, qr/Odd number of elements in hash assignment/, 'Odd number of elements in hash assignment');

if ($] >= 5.016) {
	eval "
		const my \$direct = 'abc';
	";

	like($@, qr/No value for readonly variable/, 'No value for readonly variable');
} else {
	diag explain 'Skip: Type of arg 1 to must be one of [$@%]';
}

done_testing();
