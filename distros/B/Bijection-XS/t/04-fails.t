use Test::More;
use Bijection::XS qw/all/;

my $bi = eval { biject(-10) };
like($@, qr/id to encode must be an integer and non-negative/, 'error 0.1');

$bi = eval { biject(-1) };
like($@, qr/id to encode must be an integer and non-negative/, 'error -1');

done_testing(2);

1;
